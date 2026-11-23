local _, AzerothCompendium = ...
local Widget = {}
AzerothCompendium.QuestWidget = Widget
Widget.config = {
    width = 320,
    height = 300,
    minWidth = 250,
    minHeight = 160,
    side = 12,
    top = 38,
    bottom = 22,
    gap = 6,
    dropdownH = 24,
    barH = 22,
    rowH = 38,
    collapsed = 30,
    collapsedModern = 40,
    scaleMin = 0.5,
    scaleMax = 1.5,
    scaleStep = 0.01,
}

Widget.statusIcons = {
    ready = "Interface\\GossipFrame\\ActiveQuestIcon",
    active = "Interface\\GossipFrame\\ActiveQuestIcon",
    open = "Interface\\GossipFrame\\AvailableQuestIcon",
}

Widget.statusOrder = {
    ready = 1,
    active = 2,
    open = 3,
}

local function GetMapName(mapID)
    if mapID == nil or C_Map == nil or C_Map.GetMapInfo == nil then return nil end
    local info = C_Map.GetMapInfo(mapID)

    return info and info.name
end

local function GetDifficultyColorCode(level)
    if type(level) == "number" and level > 0 and GetQuestDifficultyColor then
        local color = GetQuestDifficultyColor(level)
        if color then return format("|cff%02x%02x%02x", floor(color.r * 255 + 0.5), floor(color.g * 255 + 0.5), floor(color.b * 255 + 0.5)) end
    end

    return "|cffffd100"
end

function Widget:IsEnabled()
    return AzerothCompendium:GetConfig("QUESTWIDGET", false) == true
end

function Widget:SetEnabled(enabled)
    AzerothCompendium:SetConfig("QUESTWIDGET", enabled == true)
    if AzerothCompendium.SyncSettingsQuestWidget then AzerothCompendium:SyncSettingsQuestWidget() end
    self:UpdateVisibility()
end

function Widget:IsCollapsed()
    return AzerothCompendium:GetConfig("QUESTWIDGETCOLLAPSED", false) == true
end

function Widget:SetCollapsed(collapsed)
    AzerothCompendium:SetConfig("QUESTWIDGETCOLLAPSED", collapsed == true)
    self:Layout()
end

function Widget:IsZoneOnly()
    return AzerothCompendium:GetConfig("QUESTWIDGETZONEONLY", true) == true
end

function Widget:SetZoneOnly(zoneOnly)
    AzerothCompendium:SetConfig("QUESTWIDGETZONEONLY", zoneOnly == true)
    self:Refresh()
    self:RefreshEmbedded()
end

function Widget:GetSelectedInstanceID()
    if type(ACOTABPC) ~= "table" then return nil end

    return ACOTABPC.QUESTWIDGETINSTANCE
end

function Widget:SetSelectedInstanceID(id)
    if type(ACOTABPC) ~= "table" then return end
    ACOTABPC.QUESTWIDGETINSTANCE = id
    self:Refresh()
end

function Widget:GetPlayerLocation()
    local inInstance, instanceType = IsInInstance()
    local instanceID = nil
    if inInstance and (instanceType == "party" or instanceType == "raid") then instanceID = select(8, GetInstanceInfo()) end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    local mapSet = {}
    local zoneName = nil
    if mapID then
        mapSet[mapID] = true
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        if info then
            zoneName = info.name
            local mapType = info.mapType
            local types = Enum and Enum.UIMapType
            if info.parentMapID and info.parentMapID > 0 and (types == nil or mapType == types.Micro or mapType == types.Dungeon or mapType == types.Orphan) then mapSet[info.parentMapID] = true end
        end
    end

    if (zoneName == nil or zoneName == "") and GetRealZoneText then zoneName = GetRealZoneText() end
    if (zoneName == nil or zoneName == "") and GetZoneText then zoneName = GetZoneText() end

    return {
        instanceID = instanceID,
        mapID = mapID,
        mapSet = mapSet,
        zoneName = zoneName or "",
    }
end

function Widget:MatchesInstance(inst, instanceID)
    if inst == nil or instanceID == nil then return false end

    return inst.id == instanceID or inst.parentID == instanceID
end

function Widget:IsNodeLocked(node)
    while node and node.parents and #node.parents == 1 and node.parents[1].id == node.id do
        node = node.parents[1]
    end

    if node == nil then return false end
    local anyOf = {}
    for _, variantID in ipairs(AzerothCompendium:GetQuestVariants(node.id)) do
        for _, id in ipairs(AzerothCompendium.QUESTPREANY and AzerothCompendium.QUESTPREANY[variantID] or {}) do
            anyOf[AzerothCompendium:GetQuestCanonicalID(id, true)] = true
        end
    end

    local hasAny, anyDone = false, false
    for _, parent in ipairs(node.parents or {}) do
        local completed = AzerothCompendium:IsQuestCompleted(parent.id)
        if anyOf[parent.id] then
            hasAny = true
            if completed then anyDone = true end
        elseif not completed then
            return true
        end
    end

    return hasAny and not anyDone
end

function Widget:GetQuestObjectiveSummary(questID)
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and type(objectives) == "table" and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                if type(obj) == "table" and not obj.finished and type(obj.text) == "string" and obj.text ~= "" then return obj.text end
            end

            if type(objectives[1]) == "table" and type(objectives[1].text) == "string" and objectives[1].text ~= "" then return objectives[1].text end
        end
    end

    if GetQuestLogIndexByID and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local index = GetQuestLogIndexByID(questID)
        if index and index > 0 then
            local count = GetNumQuestLeaderBoards(index) or 0
            local first = nil
            for i = 1, count do
                local text, _, done = GetQuestLogLeaderBoard(i, index)
                if type(text) == "string" and text ~= "" then
                    first = first or text
                    if not done then return text end
                end
            end

            return first
        end
    end

    return nil
end

function Widget:ResolveTarget(inst, group, status)
    local id = group.id
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[id]
    local ender = AzerothCompendium.QUESTENDERS and AzerothCompendium.QUESTENDERS[id]
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[id]
    local target = {
        inside = false,
        mapID = nil,
        x = nil,
        y = nil,
        npc = nil,
        zone = nil,
        instanceTarget = nil,
        isTurnIn = status == "ready",
    }

    if status == "ready" then
        if ender then
            target.npc = ender[5]
            if ender[7] ~= nil then
                target.inside = true
                target.instanceTarget = ender[7]
                target.zone = AzerothCompendium:GetQuestGiverInstanceName(ender[7]) or AzerothCompendium:GetInstanceName(inst)
            else
                target.mapID, target.x, target.y = ender[1], ender[2], ender[3]
                target.zone = GetMapName(ender[1])
            end
        elseif group.last.section == 3 then
            target.inside = true
            target.instanceTarget = inst.id
            target.zone = AzerothCompendium:GetInstanceName(inst)
        elseif giver then
            target.npc = giver[5]
            local mapID, x, y, instanceID = AzerothCompendium:GetQuestGiverLocation(id)
            target.mapID, target.x, target.y = mapID, x, y
            target.zone = AzerothCompendium:GetQuestGiverInstanceName(instanceID) or GetMapName(mapID)
            if instanceID then
                target.inside = AzerothCompendium:IsQuestStartInInstance(id)
                target.instanceTarget = instanceID
            end
        end

        return target
    end

    if status == "active" then
        local objNode = group.objective or group.last
        if objNode.section == 3 or (AzerothCompendium.QUESTINSIDE and AzerothCompendium.QUESTINSIDE[id] == true) then
            target.inside = true
            target.instanceTarget = inst.id
            target.zone = AzerothCompendium:GetInstanceName(inst)
            local entrance = AzerothCompendium:GetInstanceEntrance(inst)
            if entrance then target.mapID, target.x, target.y = entrance[1], entrance[2], entrance[3] end

            return target
        end

        if giver then
            local mapID, x, y, instanceID = AzerothCompendium:GetQuestGiverLocation(id)
            target.npc = giver[5]
            target.mapID, target.x, target.y = mapID, x, y
            target.zone = AzerothCompendium:GetQuestGiverInstanceName(instanceID) or GetMapName(mapID)
        elseif ender and ender[1] then
            target.npc = ender[5]
            target.mapID, target.x, target.y = ender[1], ender[2], ender[3]
            target.zone = GetMapName(ender[1])
        end

        return target
    end

    if AzerothCompendium:IsQuestStartInInstance(id) or group.first.section == 3 then
        target.inside = true
        target.instanceTarget = inst.id
        target.npc = startItem and startItem[2] or (giver and giver[5])
        target.zone = AzerothCompendium:GetInstanceName(inst)

        return target
    end

    if giver then
        local mapID, x, y, instanceID = AzerothCompendium:GetQuestGiverLocation(id)
        target.mapID, target.x, target.y = mapID, x, y
        target.npc = startItem and (startItem[2] or giver[5]) or giver[5]
        target.zone = AzerothCompendium:GetQuestGiverInstanceName(instanceID) or GetMapName(mapID)
        if instanceID then target.instanceTarget = instanceID end
    end

    return target
end

function Widget:IsTargetInLocation(inst, target, location)
    if location == nil then return false end
    if location.instanceID then
        if target.inside and self:MatchesInstance(inst, location.instanceID) then return true end
        if target.instanceTarget and (target.instanceTarget == location.instanceID or self:MatchesInstance(AzerothCompendium:GetInstanceByID(target.instanceTarget), location.instanceID)) then return true end

        return false
    end

    if target.inside then return false end
    if target.mapID and location.mapSet[target.mapID] then return true end

    return false
end

function Widget:CollectActionable(inst, location)
    local all = {}
    local inZone = {}
    local lowLevel = 0
    local total = 0
    local completed = 0
    if inst == nil then return all, inZone, lowLevel, total, completed end
    local graph = AzerothCompendium:GetInstanceQuestGraph(inst, nil, nil, true)
    local byID = {}
    local order = {}
    for _, node in ipairs(graph) do
        local group = byID[node.id]
        if group == nil then
            group = {
                id = node.id,
                quest = node.quest,
                name = node.name,
                nameIndex = node.nameIndex,
                level = node.level,
                first = node,
                last = node,
                objective = nil,
                section = node.section,
            }

            byID[node.id] = group
            tinsert(order, group)
        else
            if node.section < group.first.section then group.first = node end
            if node.section > group.last.section then group.last = node end
            if node.section < group.section then group.section = node.section end
        end

        if node.phases and node.phases.objective then group.objective = node end
    end

    local playerLevel = UnitLevel and UnitLevel("player") or 0
    for _, group in ipairs(order) do
        total = total + 1
        local id = group.id
        if AzerothCompendium:IsQuestCompleted(id) then
            completed = completed + 1
        else
            local status = nil
            if AzerothCompendium:IsQuestReadyForTurnIn(id) then
                status = "ready"
            elseif AzerothCompendium:IsQuestActive(id) then
                status = "active"
            elseif not self:IsNodeLocked(group.first) then
                local requiredLevel = AzerothCompendium:GetQuestRequiredLevel(group.quest or id)
                if type(requiredLevel) == "number" and playerLevel > 0 and playerLevel < requiredLevel then
                    lowLevel = lowLevel + 1
                else
                    status = "open"
                end
            end

            if status then
                local target = self:ResolveTarget(inst, group, status)
                local match = self:IsTargetInLocation(inst, target, location)
                local entry = {
                    id = id,
                    inst = inst,
                    quest = group.quest,
                    name = group.nameIndex and format("%s (%d)", group.name, group.nameIndex) or group.name,
                    level = group.level or 0,
                    status = status,
                    section = status == "ready" and group.last.section or status == "active" and (group.objective and group.objective.section or group.last.section) or group.first.section,
                    target = target,
                    inZone = match,
                }

                tinsert(all, entry)
                if match then tinsert(inZone, entry) end
            end
        end
    end

    local function SortEntries(a, b)
        if a.inZone ~= b.inZone then return a.inZone end
        local sa, sb = self.statusOrder[a.status] or 9, self.statusOrder[b.status] or 9
        if sa ~= sb then return sa < sb end
        if a.section ~= b.section then return a.section < b.section end
        if a.level ~= b.level then return a.level < b.level end
        if a.name ~= b.name then return (a.name or "") < (b.name or "") end

        return a.id < b.id
    end

    table.sort(all, SortEntries)
    table.sort(inZone, SortEntries)

    return all, inZone, lowLevel, total, completed
end

function Widget:GetAvailableInstances()
    local dungeons = {}
    local raids = {}
    for _, inst in ipairs(AzerothCompendium:GetInstances("dungeon")) do
        if #AzerothCompendium:GetInstanceQuests(inst, true) > 0 then tinsert(dungeons, inst) end
    end

    for _, inst in ipairs(AzerothCompendium:GetInstances("raid")) do
        if #AzerothCompendium:GetInstanceQuests(inst, true) > 0 then tinsert(raids, inst) end
    end

    return dungeons, raids
end

function Widget:GetZoneMatches(location, dungeons, raids)
    local matches = {}
    for _, list in ipairs({dungeons, raids}) do
        for _, inst in ipairs(list) do
            local _, inZone = self:CollectActionable(inst, location)
            if #inZone > 0 then
                tinsert(matches, {
                    inst = inst,
                    count = #inZone
                })
            end
        end
    end

    return matches
end

function Widget:CollectAllInZone(location)
    local dungeons, raids = self:GetAvailableInstances()
    local seen = {}
    local list = {}
    for _, group in ipairs({dungeons, raids}) do
        for _, inst in ipairs(group) do
            local _, inZone = self:CollectActionable(inst, location)
            for _, entry in ipairs(inZone) do
                if not seen[entry.id] then
                    seen[entry.id] = true
                    entry.allMode = true
                    tinsert(list, entry)
                end
            end
        end
    end

    table.sort(list, function(a, b)
        local sa, sb = self.statusOrder[a.status] or 9, self.statusOrder[b.status] or 9
        if sa ~= sb then return sa < sb end
        local la, lb = a.inst and a.inst.minLevel or 0, b.inst and b.inst.minLevel or 0
        if la ~= lb then return la < lb end
        if a.level ~= b.level then return a.level < b.level end
        if a.name ~= b.name then return (a.name or "") < (b.name or "") end

        return a.id < b.id
    end)

    return list
end

function Widget:GetSelectedInstance(location)
    local dungeons, raids = self:GetAvailableInstances()
    local savedID = self:GetSelectedInstanceID()
    if savedID == "all" then return nil, true end
    if savedID then
        for _, list in ipairs({dungeons, raids}) do
            for _, inst in ipairs(list) do
                if inst.id == savedID then return inst, false end
            end
        end
    end

    if location and location.instanceID then
        for _, list in ipairs({dungeons, raids}) do
            for _, inst in ipairs(list) do
                if self:MatchesInstance(inst, location.instanceID) then return inst, false end
            end
        end
    end

    return nil, true
end

function Widget:FormatInstanceLabel(inst)
    local name = AzerothCompendium:GetInstanceName(inst)
    if inst.minLevel and inst.maxLevel then return format("[%d-%d] %s", inst.minLevel, inst.maxLevel, name) end

    return name
end

function Widget:SavePosition()
    local frame = self.frame
    local left, top = frame:GetLeft(), frame:GetTop()
    if left == nil or top == nil then return end
    AzerothCompendium:SetConfig("QUESTWIDGETPOS", {left, top})
end

function Widget:RestorePosition()
    local frame = self.frame
    local pos = AzerothCompendium:GetConfig("QUESTWIDGETPOS", nil)
    frame:ClearAllPoints()
    if type(pos) == "table" and pos[1] and pos[2] then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
    else
        frame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -self.config.width - 80, -140)
    end
end

function Widget:GetSavedSize()
    local size = AzerothCompendium:GetConfig("QUESTWIDGETSIZE", nil)
    if type(size) ~= "table" then return self.config.width, self.config.height end

    return size[1] or self.config.width, size[2] or self.config.height
end

function Widget:SaveSize()
    local frame = self.frame
    if self:IsCollapsed() then
        local _, height = self:GetSavedSize()
        AzerothCompendium:SetConfig("QUESTWIDGETSIZE", {floor(frame:GetWidth() + 0.5), height})
    else
        AzerothCompendium:SetConfig("QUESTWIDGETSIZE", {floor(frame:GetWidth() + 0.5), floor(frame:GetHeight() + 0.5)})
    end

    AzerothCompendium:SetConfig("QUESTWIDGETSCALE", frame:GetScale())
    self:SavePosition()
end

function Widget:ApplyScale(value)
    local frame = self.frame
    local c = self.config
    value = min(c.scaleMax, max(c.scaleMin, value))
    local left, top = frame:GetLeft(), frame:GetTop()
    local oldScale = frame:GetEffectiveScale()
    frame:SetScale(value)
    if left ~= nil and top ~= nil then
        local scale = frame:GetEffectiveScale()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / scale, top * oldScale / scale)
    end
end

function Widget:CreateResizeGrip(frame)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    grip:SetFrameLevel(frame:GetFrameLevel() + 30)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_RESIZEWINDOW"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine((SHIFT_KEY_TEXT or "Shift") .. " + " .. AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_SCALE"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_RIGHTCLICK"), AzerothCompendium:Trans("LID_RESETSIZEANDSCALE"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:Show()
    end)

    grip:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    grip:SetScript("OnMouseDown", function(sel, button)
        if button == "RightButton" then
            sel.sizing = nil
            Widget:ApplyScale(1)
            frame:SetWidth(Widget.config.width)
            frame.userHeight = Widget.config.height
            AzerothCompendium:SetConfig("QUESTWIDGETSIZE", nil)
            AzerothCompendium:SetConfig("QUESTWIDGETSCALE", 1)
            Widget:Layout()
            Widget:SavePosition()

            return
        end

        if button ~= "LeftButton" then return end
        local left, top = frame:GetLeft(), frame:GetTop()
        if left == nil or top == nil then return end
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        local x, y = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        sel.sizing = {
            x = x / scale,
            y = y / scale,
            w = frame:GetWidth(),
            h = frame:GetHeight(),
            scaling = IsShiftKeyDown(),
            startScale = frame:GetScale(),
            effectiveScale = scale
        }

        sel:SetScript("OnUpdate", sel.OnSizingUpdate)
    end)

    local function StopSizing(sel)
        sel:SetScript("OnUpdate", nil)
        if sel.sizing == nil then return end
        sel.sizing = nil
        Widget:SaveSize()
    end

    grip:SetScript("OnMouseUp", StopSizing)
    grip:SetScript("OnHide", StopSizing)
    function grip.OnSizingUpdate(sel)
        local sizing = sel.sizing
        if sizing == nil then
            sel:SetScript("OnUpdate", nil)

            return
        end

        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            StopSizing(sel)

            return
        end

        local x, y = GetCursorPosition()
        local c = Widget.config
        if sizing.scaling then
            local w, h = sizing.w * sizing.effectiveScale, sizing.h * sizing.effectiveScale
            local dx, dy = x - sizing.x * sizing.effectiveScale, y - sizing.y * sizing.effectiveScale
            local value = sizing.startScale * (1 + (dx * w - dy * h) / (w * w + h * h))
            value = floor(value / c.scaleStep + 0.5) * c.scaleStep
            if value ~= frame:GetScale() then Widget:ApplyScale(value) end

            return
        end

        local scale = frame:GetEffectiveScale()
        frame:SetWidth(floor(max(c.minWidth, sizing.w + x / scale - sizing.x) + 0.5))
        frame.userHeight = floor(max(c.minHeight, sizing.h + sizing.y - y / scale) + 0.5)
        Widget:Layout()
    end

    return grip
end

function Widget:ShowQuestTooltip(row)
    local entry = row.entry
    if entry == nil then return end
    local id = entry.id
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    local cached = C_TooltipInfo and C_TooltipInfo.GetHyperlink and C_TooltipInfo.GetHyperlink("quest:" .. id)
    if cached and cached.lines and #cached.lines > 0 then
        GameTooltip:SetHyperlink("quest:" .. id)
    else
        local title = entry.level > 0 and format("[%d] %s", entry.level, entry.name) or entry.name
        GameTooltip:AddLine(title, 1, 0.82, 0)
        if C_QuestLog and C_QuestLog.RequestLoadQuestByID then pcall(C_QuestLog.RequestLoadQuestByID, id) end
    end

    local statusKey = entry.status == "ready" and "LID_QUESTREADY" or entry.status == "active" and "LID_QUESTACTIVE" or "LID_QUESTNOTACCEPTED"
    local sr, sg, sb = 1, 0.82, 0
    if entry.status == "ready" then
        sr, sg, sb = 0.25, 1, 0.25
    elseif entry.status == "active" then
        sr, sg, sb = 0.5, 0.8, 1
    end

    GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans(statusKey)), sr, sg, sb)
    if entry.allMode and entry.inst then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:GetInstanceName(entry.inst)), 1, 0.82, 0) end
    if entry.status == "active" then
        local summary = self:GetQuestObjectiveSummary(id)
        if summary then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(summary), 0.9, 0.9, 0.9, true) end
    end

    local target = entry.target
    if target.npc or target.zone then
        local label = target.isTurnIn and AzerothCompendium:Trans("LID_QUESTENDER") or AzerothCompendium:Trans("LID_QUESTGIVER")
        local text = target.npc or target.zone
        if target.npc and target.zone then text = format("%s (%s)", target.npc, target.zone) end
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(label), text, 0.9, 0.9, 0.9, 1, 1, 1)
    end

    if target.inside and entry.status ~= "active" then
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_QUESTSTARTSININSTANCE"), entry.name)), 1, 0.82, 0)
    elseif target.mapID and target.x and target.y then
        local hint = target.isTurnIn and "LID_QW_SHOWTURNIN" or entry.status == "active" and target.inside and "LID_SHOWENTRANCEMAP" or "LID_SHOWQUESTGIVER"
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans(hint), 0.9, 0.9, 0.9, 1, 0.82, 0)
    end

    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_RIGHTCLICK") .. ":"), AzerothCompendium:Trans("LID_QW_OPENINCOMPENDIUM"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:Show()
end

function Widget:OnQuestClick(row, mouseButton)
    local entry = row.entry
    if entry == nil then return end
    if mouseButton == "RightButton" then
        if AzerothCompendium.OpenInstanceQuests then AzerothCompendium:OpenInstanceQuests(entry.inst.id, entry.id) end

        return
    end

    if IsShiftKeyDown() and ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() then
        local link = GetQuestLink and GetQuestLink(entry.id)
        if link and ChatEdit_InsertLink then
            ChatEdit_InsertLink(link)

            return
        end
    end

    local target = entry.target
    if target.inside and entry.status == "open" then
        AzerothCompendium:INFO(format(AzerothCompendium:Trans("LID_QUESTSTARTSININSTANCE"), entry.name))

        return
    end

    if target.mapID and target.x and target.y then
        local ok, reason = AzerothCompendium:SetMapWaypoint(target.mapID, target.x, target.y)
        if ok then
            AzerothCompendium:OpenWorldMapTo(target.mapID)
        else
            local message = reason == "combat" and "LID_WAYPOINTCOMBAT" or "LID_NOQUESTGIVER"
            AzerothCompendium:INFO(AzerothCompendium:Trans(message))
        end

        return
    end

    AzerothCompendium:INFO(AzerothCompendium:Trans("LID_NOQUESTGIVER"))
end

function Widget:FormatRowSubtext(entry)
    local target = entry.target
    local instName = entry.allMode and entry.inst and AzerothCompendium:GetInstanceName(entry.inst) or nil
    if entry.status == "ready" then
        local where = target.npc or target.zone or ""
        if instName then
            where = target.npc and format("%s · %s", target.npc, instName) or instName
        elseif target.npc and target.zone then
            where = format("%s (%s)", target.npc, target.zone)
        end

        return format("%s: %s", AzerothCompendium:Trans("LID_QW_TURNIN"), where), 0.25, 1, 0.25
    end

    if entry.status == "active" then
        local suffix = instName or target.zone
        local summary = self:GetQuestObjectiveSummary(entry.id)
        if summary then
            if suffix then return format("%s · %s", summary, suffix), 0.65, 0.85, 1 end

            return summary, 0.65, 0.85, 1
        end

        local where = suffix or AzerothCompendium:Trans("LID_QUESTACTIVE")

        return format("%s · %s", AzerothCompendium:Trans("LID_QUESTACTIVE"), where), 0.65, 0.85, 1
    end

    if target.inside then
        local text = AzerothCompendium:Trans("LID_QUESTTREEINSTANCE")
        if instName then text = format("%s · %s", text, instName) end

        return text, 0.85, 0.75, 0.45
    end

    local where = target.npc or target.zone or ""
    if instName then
        where = target.npc and format("%s · %s", target.npc, instName) or instName
    elseif target.npc and target.zone then
        where = format("%s (%s)", target.npc, target.zone)
    end

    if entry.inZone then return format("%s: %s", AzerothCompendium:Trans("LID_QW_ACCEPT"), where), 0.95, 0.88, 0.65 end

    return format("%s: %s", AzerothCompendium:Trans("LID_QW_ACCEPT"), where), 0.72, 0.72, 0.76
end

function Widget:CreateQuestRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(self.config.rowH)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 6)
    row.title:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    row.sub:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetWordWrap(false)
    row:SetScript("OnEnter", function(sel) Widget:ShowQuestTooltip(sel) end)
    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel, button) Widget:OnQuestClick(sel, button) end)
    function row:Update(entry)
        self.entry = entry
        self.icon:SetTexture(Widget.statusIcons[entry.status] or Widget.statusIcons.open)
        if self.icon.SetDesaturated then self.icon:SetDesaturated(entry.status == "active") end
        local color = GetDifficultyColorCode(entry.level)
        local prefix = entry.level > 0 and format("[%d] ", entry.level) or ""
        self.title:SetText(color .. prefix .. (entry.name or "") .. "|r")
        local text, r, g, b = Widget:FormatRowSubtext(entry)
        self.sub:SetText(text)
        self.sub:SetTextColor(r, g, b)
    end

    return row
end

function Widget:BuildDropdownEntries()
    local location = self:GetPlayerLocation()
    local dungeons, raids = self:GetAvailableInstances()
    local matches = self:GetZoneMatches(location, dungeons, raids)
    local selected = self.selectedInstance
    local selectedID = not self.allMode and selected and selected.id or nil
    local sections = {}
    tinsert(sections, {
        title = nil,
        items = {
            {
                text = AzerothCompendium:Trans("LID_QW_ALLDUNGEONS"),
                id = "all",
                checked = self.allMode == true,
            }
        }
    })

    if #matches > 0 then
        local items = {}
        for _, match in ipairs(matches) do
            tinsert(items, {
                text = format("%s (%d)", self:FormatInstanceLabel(match.inst), match.count),
                id = match.inst.id,
                checked = match.inst.id == selectedID,
            })
        end

        tinsert(sections, {
            title = AzerothCompendium:Trans("LID_QW_INTHISZONE"),
            items = items,
        })
    end

    if #dungeons > 0 then
        local items = {}
        for _, inst in ipairs(dungeons) do
            tinsert(items, {
                text = self:FormatInstanceLabel(inst),
                id = inst.id,
                checked = inst.id == selectedID,
            })
        end

        tinsert(sections, {
            title = AzerothCompendium:Trans("LID_DUNGEONS"),
            items = items,
        })
    end

    if #raids > 0 then
        local items = {}
        for _, inst in ipairs(raids) do
            tinsert(items, {
                text = self:FormatInstanceLabel(inst),
                id = inst.id,
                checked = inst.id == selectedID,
            })
        end

        tinsert(sections, {
            title = AzerothCompendium:Trans("LID_RAIDS"),
            items = items,
        })
    end

    return sections
end

function Widget:CreateDungeonDropdown(parent)
    local modern = AzerothCompendium:CheckTemplates("WowStyle1DropdownTemplate")
    local dropdown = CreateFrame(modern and "DropdownButton" or "Button", nil, parent, modern and "WowStyle1DropdownTemplate" or "UIPanelButtonTemplate")
    dropdown:SetHeight(self.config.dropdownH)
    if modern and dropdown.SetupMenu then
        dropdown:SetupMenu(function(_, root)
            if root.SetScrollMode then root:SetScrollMode(320) end
            for _, section in ipairs(Widget:BuildDropdownEntries()) do
                if section.title then root:CreateTitle(section.title) end
                for _, item in ipairs(section.items) do
                    local id = item.id
                    root:CreateRadio(item.text, function() return (id == "all" and Widget.allMode == true) or (not Widget.allMode and Widget.selectedInstance and Widget.selectedInstance.id == id) end, function() Widget:SetSelectedInstanceID(id) end)
                end
            end
        end)
    else
        dropdown:SetScript("OnClick", function(sel)
            local entries = {}
            for _, section in ipairs(Widget:BuildDropdownEntries()) do
                if section.title then
                    tinsert(entries, {
                        text = section.title,
                        isTitle = true,
                        notCheckable = true,
                    })
                end

                for _, item in ipairs(section.items) do
                    local id = item.id
                    tinsert(entries, {
                        text = item.text,
                        checked = item.checked,
                        func = function() Widget:SetSelectedInstanceID(id) end,
                    })
                end
            end

            AzerothCompendium:ShowContextMenu(sel, entries)
        end)
    end

    return dropdown
end

function Widget:CreateFrame()
    if self.frame then return self.frame end
    local c = self.config
    local ui = AzerothCompendium.SharedUI
    local frame = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumQuestWidget", AzerothCompendium:Trans("LID_QW_TITLE"))
    self.frame = frame
    if ButtonFrameTemplate_HidePortrait then pcall(ButtonFrameTemplate_HidePortrait, frame) end
    if type(frame.Inset) == "table" then frame.Inset:Hide() end
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(false)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        Widget:SavePosition()
        Widget:RestorePosition()
    end)

    local width, height = self:GetSavedSize()
    frame:SetWidth(max(c.minWidth, width))
    frame.userHeight = max(c.minHeight, height)
    frame:SetScale(AzerothCompendium:GetConfig("QUESTWIDGETSCALE", 1) or 1)
    self:RestorePosition()
    frame.titleText = AzerothCompendium.Theme:GetTitleText(frame)
    if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() Widget:Close() end) end
    frame.toggle = CreateFrame("Button", nil, frame)
    frame.toggle:SetSize(16, 16)
    if frame.CloseButton then
        frame.toggle:SetPoint("RIGHT", frame.CloseButton, "LEFT", -2, 0)
    else
        frame.toggle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -4)
    end

    frame.toggle:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.toggle.icon = frame.toggle:CreateTexture(nil, "ARTWORK")
    frame.toggle.icon:SetAllPoints()
    frame.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    frame.toggle:SetScript("OnClick", function() Widget:SetCollapsed(not Widget:IsCollapsed()) end)
    frame.openButton = CreateFrame("Button", nil, frame)
    frame.openButton:SetSize(16, 16)
    frame.openButton:SetPoint("RIGHT", frame.toggle, "LEFT", -4, 0)
    frame.openButton:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.openButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Book_09")
    frame.openButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    frame.openButton:SetScript("OnClick", function()
        if Widget.selectedInstance and AzerothCompendium.OpenInstanceQuests then
            AzerothCompendium:OpenInstanceQuests(Widget.selectedInstance.id)
        else
            AzerothCompendium:OpenCompendium()
        end
    end)

    frame.openButton:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_QW_OPENINCOMPENDIUM"))
        GameTooltip:Show()
    end)

    frame.openButton:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    frame.headerCount = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.headerCount:SetPoint("RIGHT", frame.openButton, "LEFT", -6, 0)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    frame.dungeonDropdown = self:CreateDungeonDropdown(frame.content)
    frame.dungeonDropdown:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.dungeonDropdown:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, 0)
    frame.bar = CreateFrame("Frame", nil, frame.content)
    frame.bar:SetPoint("TOPLEFT", frame.dungeonDropdown, "BOTTOMLEFT", 0, -c.gap)
    frame.bar:SetPoint("TOPRIGHT", frame.dungeonDropdown, "BOTTOMRIGHT", 0, -c.gap)
    frame.bar:SetHeight(c.barH)
    frame.modeGroup = CreateFrame("Frame", nil, frame.bar)
    frame.modeGroup.acoSegmentGroup = true
    frame.modeGroup:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", 0, 0)
    frame.modeGroup:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 0, 0)
    frame.zoneOnlyBtn = CreateFrame("Button", nil, frame.modeGroup, "UIPanelButtonTemplate")
    frame.zoneOnlyBtn:SetHeight(c.barH)
    frame.zoneOnlyBtn:SetPoint("LEFT", frame.modeGroup, "LEFT", 0, 0)
    frame.zoneOnlyBtn.acoSegment = function() return Widget:IsZoneOnly() end
    frame.zoneOnlyBtn:SetScript("OnClick", function() Widget:SetZoneOnly(true) end)
    frame.allZonesBtn = CreateFrame("Button", nil, frame.modeGroup, "UIPanelButtonTemplate")
    frame.allZonesBtn:SetHeight(c.barH)
    frame.allZonesBtn:SetPoint("LEFT", frame.zoneOnlyBtn, "RIGHT", 2, 0)
    frame.allZonesBtn.acoSegment = function() return not Widget:IsZoneOnly() end
    frame.allZonesBtn:SetScript("OnClick", function() Widget:SetZoneOnly(false) end)
    frame.zoneFixedLabel = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.zoneFixedLabel:SetPoint("RIGHT", frame.bar, "RIGHT", -2, 0)
    frame.zoneFixedLabel:SetJustifyH("RIGHT")
    frame.zoneFixedLabel:SetWordWrap(false)
    frame.zoneFixedLabel:Hide()
    frame.zoneLabel = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.zoneLabel:SetPoint("LEFT", frame.bar, "LEFT", 2, 0)
    frame.zoneLabel:SetPoint("RIGHT", frame.modeGroup, "LEFT", -6, 0)
    frame.zoneLabel:SetJustifyH("LEFT")
    frame.zoneLabel:SetWordWrap(false)
    frame.list = ui.CreateScroller(frame.content, c.rowH, function(parent) return Widget:CreateQuestRow(parent) end, 0, 4)
    frame.list:SetPoint("TOPLEFT", frame.bar, "BOTTOMLEFT", 0, -c.gap)
    frame.list:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", 0, 0)
    frame.empty = frame.list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("CENTER", frame.list, "CENTER", 0, 12)
    frame.empty:SetJustifyH("CENTER")
    frame.empty:SetWordWrap(true)
    frame.showAllBtn = CreateFrame("Button", nil, frame.list, "UIPanelButtonTemplate")
    frame.showAllBtn:SetSize(120, 22)
    frame.showAllBtn:SetPoint("TOP", frame.empty, "BOTTOM", 0, -8)
    frame.showAllBtn:SetScript("OnClick", function() Widget:SetZoneOnly(false) end)
    frame.showAllBtn:Hide()
    frame.grip = self:CreateResizeGrip(frame)
    frame:Hide()
    AzerothCompendium:OnLanguage(function() Widget:Refresh() end)

    return frame
end

function Widget:UpdateSegmentButtons()
    local frame = self.frame
    if frame == nil then return end
    local zoneText = AzerothCompendium:Trans("LID_QW_ZONEONLY")
    frame.zoneFixedLabel:SetText(zoneText)
    if self.allMode then
        frame.modeGroup:Hide()
        frame.zoneFixedLabel:Show()
        frame.zoneLabel:ClearAllPoints()
        frame.zoneLabel:SetPoint("LEFT", frame.bar, "LEFT", 2, 0)
        frame.zoneLabel:SetPoint("RIGHT", frame.zoneFixedLabel, "LEFT", -6, 0)

        return
    end

    frame.zoneFixedLabel:Hide()
    frame.modeGroup:Show()
    frame.zoneLabel:ClearAllPoints()
    frame.zoneLabel:SetPoint("LEFT", frame.bar, "LEFT", 2, 0)
    frame.zoneLabel:SetPoint("RIGHT", frame.modeGroup, "LEFT", -6, 0)
    local allText = AzerothCompendium:Trans("LID_QW_ALLZONES")
    frame.zoneOnlyBtn:SetText(zoneText)
    frame.allZonesBtn:SetText(allText)
    local zoneW = max(56, (frame.zoneOnlyBtn:GetFontString() and frame.zoneOnlyBtn:GetFontString():GetStringWidth() or 40) + 16)
    local allW = max(40, (frame.allZonesBtn:GetFontString() and frame.allZonesBtn:GetFontString():GetStringWidth() or 28) + 16)
    frame.zoneOnlyBtn:SetWidth(zoneW)
    frame.allZonesBtn:SetWidth(allW)
    frame.modeGroup:SetWidth(zoneW + allW + 2)
    local modern = AzerothCompendium.Theme:IsModern()
    local zoneOnly = self:IsZoneOnly()
    if zoneOnly then
        frame.zoneOnlyBtn:LockHighlight()
        frame.allZonesBtn:UnlockHighlight()
        frame.zoneOnlyBtn:SetNormalFontObject("GameFontHighlightSmall")
        frame.allZonesBtn:SetNormalFontObject(modern and "GameFontDisableSmall" or "GameFontNormalSmall")
    else
        frame.zoneOnlyBtn:UnlockHighlight()
        frame.allZonesBtn:LockHighlight()
        frame.zoneOnlyBtn:SetNormalFontObject(modern and "GameFontDisableSmall" or "GameFontNormalSmall")
        frame.allZonesBtn:SetNormalFontObject("GameFontHighlightSmall")
    end

    AzerothCompendium.Theme:UpdateFrame(frame.zoneOnlyBtn)
    AzerothCompendium.Theme:UpdateFrame(frame.allZonesBtn)
end

function Widget:Layout()
    local frame = self.frame
    if frame == nil or frame.layingOut then return end
    frame.layingOut = true
    local c = self.config
    local collapsed = self:IsCollapsed()
    local collapsedTitle = self.allMode and AzerothCompendium:Trans("LID_QW_ALLDUNGEONS") or (self.selectedInstance and AzerothCompendium:GetInstanceName(self.selectedInstance) or AzerothCompendium:Trans("LID_QW_SELECTDUNGEON"))
    if frame.titleText then frame.titleText:SetText(collapsed and collapsedTitle or AzerothCompendium:Trans("LID_QW_TITLE")) end
    AzerothCompendium.Theme:SetCollapseIcon(frame.toggle.icon, collapsed)
    frame.content:SetShown(not collapsed)
    frame.grip:SetShown(not collapsed)
    frame.headerCount:SetShown(collapsed)
    if collapsed then
        frame:SetHeight(AzerothCompendium.Theme:IsModern() and c.collapsedModern or c.collapsed)
        frame.layingOut = false

        return
    end

    if frame.SetResizeBounds then
        frame:SetResizeBounds(c.minWidth, c.minHeight, 0, 0)
    elseif frame.SetMinResize then
        frame:SetMinResize(c.minWidth, c.minHeight)
    end

    frame:SetHeight(max(c.minHeight, frame.userHeight or c.height))
    self:UpdateSegmentButtons()
    frame.empty:SetWidth(max(120, frame:GetWidth() - c.side * 2 - 24))
    frame.layingOut = false
    frame.list:Refresh()
end

function Widget:CollectOtherZones(entries)
    local seen = {}
    local names = {}
    for _, entry in ipairs(entries) do
        local name = entry.target and entry.target.zone
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            tinsert(names, name)
            if #names >= 3 then break end
        end
    end

    return table.concat(names, ", ")
end

function Widget:Refresh()
    local frame = self.frame
    if frame == nil or not frame:IsShown() then return end
    local location = self:GetPlayerLocation()
    local inst, allMode = self:GetSelectedInstance(location)
    self.selectedInstance = inst
    self.allMode = allMode == true
    local collapsedTitle = self.allMode and AzerothCompendium:Trans("LID_QW_ALLDUNGEONS") or (inst and AzerothCompendium:GetInstanceName(inst) or AzerothCompendium:Trans("LID_QW_SELECTDUNGEON"))
    if frame.titleText then frame.titleText:SetText(self:IsCollapsed() and collapsedTitle or AzerothCompendium:Trans("LID_QW_TITLE")) end
    if self.allMode then
        AzerothCompendium:SetDropdownText(frame.dungeonDropdown, AzerothCompendium:Trans("LID_QW_ALLDUNGEONS"))
    elseif inst then
        AzerothCompendium:SetDropdownText(frame.dungeonDropdown, self:FormatInstanceLabel(inst))
    else
        AzerothCompendium:SetDropdownText(frame.dungeonDropdown, AzerothCompendium:Trans("LID_QW_SELECTDUNGEON"))
    end

    frame.zoneLabel:SetText(location.zoneName ~= "" and location.zoneName or "-")
    local all, inZone, lowLevel, total, completed
    local shown
    local zoneOnly = self.allMode or self:IsZoneOnly()
    if self.allMode then
        shown = self:CollectAllInZone(location)
        all, inZone, lowLevel, total, completed = shown, shown, 0, #shown, 0
    else
        all, inZone, lowLevel, total, completed = self:CollectActionable(inst, location)
        shown = zoneOnly and inZone or all
    end

    frame.headerCount:SetText(tostring(#shown))
    frame.list.data = shown
    frame.showAllBtn:SetText(AzerothCompendium:Trans("LID_QW_SHOWALL"))
    if #shown == 0 then
        local text = ""
        local showButton = false
        if self.allMode then
            text = format(AzerothCompendium:Trans("LID_QW_NONEINZONEALL"), location.zoneName ~= "" and location.zoneName or "-")
        elseif inst == nil then
            text = AzerothCompendium:Trans("LID_QW_SELECTDUNGEON")
        elseif zoneOnly and #all > 0 then
            local zones = self:CollectOtherZones(all)
            if zones ~= "" then
                text = format(AzerothCompendium:Trans("LID_QW_NONEINZONEWITHOTHER"), location.zoneName ~= "" and location.zoneName or "-", #all, zones)
            else
                text = format(AzerothCompendium:Trans("LID_QW_NONEINZONE"), location.zoneName ~= "" and location.zoneName or "-", #all)
            end

            showButton = true
        elseif total > 0 and completed >= total then
            text = AzerothCompendium:Trans("LID_QW_ALLDONE")
        elseif lowLevel > 0 then
            text = AzerothCompendium:Trans("LID_QW_NOLEVELQUESTS")
        else
            text = AzerothCompendium:Trans("LID_QW_NOQUESTS")
        end

        frame.empty:ClearAllPoints()
        frame.empty:SetPoint("CENTER", frame.list, "CENTER", 0, showButton and 16 or 0)
        frame.empty:SetText(text)
        frame.empty:Show()
        frame.showAllBtn:SetShown(showButton)
    else
        frame.empty:Hide()
        frame.showAllBtn:Hide()
    end

    self:Layout()
    self:RefreshEmbedded()
end

function Widget:RefreshEmbedded()
    for _, pane in ipairs(self.embeddedViews or {}) do
        if pane:IsShown() then pane:Refresh() end
    end
end

function Widget:CreateEmbeddedView(parent, getInstance)
    local c = self.config
    local ui = AzerothCompendium.SharedUI
    local pane = CreateFrame("Frame", nil, parent)
    pane.bar = CreateFrame("Frame", nil, pane)
    pane.bar:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, 0)
    pane.bar:SetPoint("TOPRIGHT", pane, "TOPRIGHT", 0, 0)
    pane.bar:SetHeight(c.barH + 2)
    pane.openWidgetBtn = CreateFrame("Button", nil, pane.bar, "UIPanelButtonTemplate")
    pane.openWidgetBtn:SetHeight(c.barH)
    pane.openWidgetBtn:SetPoint("RIGHT", pane.bar, "RIGHT", 0, 0)
    pane.openWidgetBtn:SetScript("OnClick", function()
        local inst = getInstance()
        Widget:ShowForInstance(inst and inst.id or "all")
    end)

    pane.modeGroup = CreateFrame("Frame", nil, pane.bar)
    pane.modeGroup.acoSegmentGroup = true
    pane.modeGroup:SetPoint("RIGHT", pane.openWidgetBtn, "LEFT", -8, 0)
    pane.modeGroup:SetHeight(c.barH)
    pane.zoneOnlyBtn = CreateFrame("Button", nil, pane.modeGroup, "UIPanelButtonTemplate")
    pane.zoneOnlyBtn:SetHeight(c.barH)
    pane.zoneOnlyBtn:SetPoint("LEFT", pane.modeGroup, "LEFT", 0, 0)
    pane.zoneOnlyBtn.acoSegment = function() return Widget:IsZoneOnly() end
    pane.zoneOnlyBtn:SetScript("OnClick", function() Widget:SetZoneOnly(true) end)
    pane.allZonesBtn = CreateFrame("Button", nil, pane.modeGroup, "UIPanelButtonTemplate")
    pane.allZonesBtn:SetHeight(c.barH)
    pane.allZonesBtn:SetPoint("LEFT", pane.zoneOnlyBtn, "RIGHT", 2, 0)
    pane.allZonesBtn.acoSegment = function() return not Widget:IsZoneOnly() end
    pane.allZonesBtn:SetScript("OnClick", function() Widget:SetZoneOnly(false) end)
    pane.zoneLabel = pane.bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pane.zoneLabel:SetPoint("LEFT", pane.bar, "LEFT", 2, 0)
    pane.zoneLabel:SetPoint("RIGHT", pane.modeGroup, "LEFT", -8, 0)
    pane.zoneLabel:SetJustifyH("LEFT")
    pane.zoneLabel:SetWordWrap(false)
    pane.list = ui.CreateScroller(pane, c.rowH, function(scrollerParent) return Widget:CreateQuestRow(scrollerParent) end, 0, 4)
    pane.list:SetPoint("TOPLEFT", pane.bar, "BOTTOMLEFT", 0, -c.gap)
    pane.list:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", 0, 0)
    pane.empty = pane.list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    pane.empty:SetPoint("CENTER", pane.list, "CENTER", 0, 12)
    pane.empty:SetJustifyH("CENTER")
    pane.empty:SetWordWrap(true)
    pane.showAllBtn = CreateFrame("Button", nil, pane.list, "UIPanelButtonTemplate")
    pane.showAllBtn:SetSize(120, 22)
    pane.showAllBtn:SetPoint("TOP", pane.empty, "BOTTOM", 0, -8)
    pane.showAllBtn:SetScript("OnClick", function() Widget:SetZoneOnly(false) end)
    pane.showAllBtn:Hide()
    function pane:Refresh()
        local inst = getInstance()
        local location = Widget:GetPlayerLocation()
        self.openWidgetBtn:SetText(AzerothCompendium:Trans("LID_QW_OPENWIDGET"))
        local openW = max(100, (self.openWidgetBtn:GetFontString() and self.openWidgetBtn:GetFontString():GetStringWidth() or 80) + 22)
        self.openWidgetBtn:SetWidth(openW)
        local zoneText = AzerothCompendium:Trans("LID_QW_ZONEONLY")
        local allText = AzerothCompendium:Trans("LID_QW_ALLZONES")
        self.zoneOnlyBtn:SetText(zoneText)
        self.allZonesBtn:SetText(allText)
        local zoneW = max(56, (self.zoneOnlyBtn:GetFontString() and self.zoneOnlyBtn:GetFontString():GetStringWidth() or 40) + 16)
        local allW = max(40, (self.allZonesBtn:GetFontString() and self.allZonesBtn:GetFontString():GetStringWidth() or 28) + 16)
        self.zoneOnlyBtn:SetWidth(zoneW)
        self.allZonesBtn:SetWidth(allW)
        self.modeGroup:SetWidth(zoneW + allW + 2)
        local modern = AzerothCompendium.Theme:IsModern()
        local zoneOnly = Widget:IsZoneOnly()
        if zoneOnly then
            self.zoneOnlyBtn:LockHighlight()
            self.allZonesBtn:UnlockHighlight()
            self.zoneOnlyBtn:SetNormalFontObject("GameFontHighlightSmall")
            self.allZonesBtn:SetNormalFontObject(modern and "GameFontDisableSmall" or "GameFontNormalSmall")
        else
            self.zoneOnlyBtn:UnlockHighlight()
            self.allZonesBtn:LockHighlight()
            self.zoneOnlyBtn:SetNormalFontObject(modern and "GameFontDisableSmall" or "GameFontNormalSmall")
            self.allZonesBtn:SetNormalFontObject("GameFontHighlightSmall")
        end

        AzerothCompendium.Theme:UpdateFrame(self.zoneOnlyBtn)
        AzerothCompendium.Theme:UpdateFrame(self.allZonesBtn)
        self.zoneLabel:SetText(location.zoneName ~= "" and location.zoneName or "-")
        local all, inZone, lowLevel, total, completed = Widget:CollectActionable(inst, location)
        local shown = zoneOnly and inZone or all
        self.list.data = shown
        self.showAllBtn:SetText(AzerothCompendium:Trans("LID_QW_SHOWALL"))
        self.empty:SetWidth(max(160, (self:GetWidth() or 300) - 32))
        if #shown == 0 then
            local text = ""
            local showButton = false
            if inst == nil then
                text = AzerothCompendium:Trans("LID_QW_SELECTDUNGEON")
            elseif zoneOnly and #all > 0 then
                local zones = Widget:CollectOtherZones(all)
                if zones ~= "" then
                    text = format(AzerothCompendium:Trans("LID_QW_NONEINZONEWITHOTHER"), location.zoneName ~= "" and location.zoneName or "-", #all, zones)
                else
                    text = format(AzerothCompendium:Trans("LID_QW_NONEINZONE"), location.zoneName ~= "" and location.zoneName or "-", #all)
                end

                showButton = true
            elseif total > 0 and completed >= total then
                text = AzerothCompendium:Trans("LID_QW_ALLDONE")
            elseif lowLevel > 0 then
                text = AzerothCompendium:Trans("LID_QW_NOLEVELQUESTS")
            else
                text = AzerothCompendium:Trans("LID_QW_NOQUESTS")
            end

            self.empty:ClearAllPoints()
            self.empty:SetPoint("CENTER", self.list, "CENTER", 0, showButton and 16 or 0)
            self.empty:SetText(text)
            self.empty:Show()
            self.showAllBtn:SetShown(showButton)
        else
            self.empty:Hide()
            self.showAllBtn:Hide()
        end

        self.list:Refresh()
    end

    self.embeddedViews = self.embeddedViews or {}
    tinsert(self.embeddedViews, pane)
    AzerothCompendium:OnLanguage(function() if pane:IsShown() then pane:Refresh() end end)

    return pane
end

function Widget:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    C_Timer.After(0.15, function()
        Widget.refreshQueued = false
        Widget:Refresh()
        Widget:RefreshEmbedded()
    end)
end

function Widget:UpdateVisibility()
    if not self:IsEnabled() then
        if self.frame then self.frame:Hide() end

        return
    end

    self:CreateFrame():Show()
    self:Refresh()
end

function Widget:Close()
    self:SetEnabled(false)
end

function Widget:Toggle()
    self:SetEnabled(not self:IsEnabled())
end

function Widget:ShowForInstance(instID)
    if instID and type(ACOTABPC) == "table" then ACOTABPC.QUESTWIDGETINSTANCE = instID end
    self:SetEnabled(true)
    if self.frame then
        self.frame:Show()
        self:Refresh()
    end
end

function Widget:OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UpdateVisibility()

        return
    end

    local hasEmbedded = false
    for _, pane in ipairs(self.embeddedViews or {}) do
        if pane:IsShown() then hasEmbedded = true end
    end

    if (self.frame and self.frame:IsShown()) or hasEmbedded then self:QueueRefresh() end
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "UNIT_QUEST_LOG_CHANGED", "PLAYER_LEVEL_UP"}) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

eventFrame:SetScript("OnEvent", function(_, event) Widget:OnEvent(event) end)
