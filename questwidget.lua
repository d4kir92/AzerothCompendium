local _, AzerothCompendium = ...
local Widget = {}
AzerothCompendium.QuestWidget = Widget
Widget.config = {
    width = 320,
    height = 300,
    minWidth = 250,
    minHeight = 160,
    side = 8,
    top = 34,
    bottom = 14,
    gap = 6,
    dropdownH = 22,
    barH = 20,
    rowH = 38,
    focusSize = 20,
    itemSize = 24,
    pinSize = 18,
    mapPinSize = 20,
    mapPinLevel = 2100,
    mapUpdateInterval = 0.05,
    lineGap = 2,
    padY = 5,
    collapsed = 32,
    scaleMin = 0.5,
    scaleMax = 1.5,
    scaleStep = 0.01,
}

Widget.pinAssets = {
    tracked = "Waypoint-MapPin-Tracked",
    untracked = "Waypoint-MapPin-Untracked",
    highlight = "Waypoint-MapPin-Highlight",
    fallback = 134269,
    mapIcon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
    mapQuestMark = "Interface\\GossipFrame\\AvailableQuestIcon",
    trackingCircle = "UI-QuestPoi-QuestNumber-SuperTracked",
}

Widget.mapPins = {}
Widget.mapPinState = {}
Widget.mapPinVersion = 0

Widget.statusIcons = {
    ready = "Interface\\GossipFrame\\ActiveQuestIcon",
    active = "Interface\\GossipFrame\\ActiveQuestIcon",
    open = "Interface\\GossipFrame\\AvailableQuestIcon",
}

Widget.poiAtlases = {
    normal = "UI-QuestPoi-QuestNumber",
    pushed = "UI-QuestPoi-QuestNumber-Pressed",
    focused = "UI-QuestPoi-QuestNumber-SuperTracked",
    focusedPushed = "UI-QuestPoi-QuestNumber-Pressed-SuperTracked",
    highlight = "UI-QuestPoi-InnerGlow",
    turnIn = "UI-QuestIcon-TurnIn-Normal",
    turnInFallback = "QuestTurnin",
}

Widget.statusOrder = {
    ready = 1,
    active = 2,
    open = 3,
}

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function InCombat()
    return InCombatLockdown ~= nil and InCombatLockdown() == true
end

local function HasAtlas(name)
    return name ~= nil and C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil and C_Texture.GetAtlasInfo(name) ~= nil
end

local function GetItemCountCompat(itemID, includeCharges)
    if itemID == nil then return 0 end
    local fn = C_Item and C_Item.GetItemCount or GetItemCount
    if fn == nil then return 0 end
    local ok, count = pcall(fn, itemID, false, includeCharges == true)
    if ok and type(count) == "number" and not IsSecret(count) then return count end

    return 0
end

local function GetItemIconCompat(itemID)
    if itemID == nil then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon and not IsSecret(icon) then return icon end
    end

    if GetItemIcon then
        local ok, icon = pcall(GetItemIcon, itemID)
        if ok and icon and not IsSecret(icon) then return icon end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetItemCooldownCompat(itemID, logIndex)
    if logIndex and logIndex > 0 and GetQuestLogSpecialItemCooldown then
        local ok, start, duration, enable = pcall(GetQuestLogSpecialItemCooldown, logIndex)
        if ok and type(start) == "number" and type(duration) == "number" and not IsSecret(start) and not IsSecret(duration) then
            return start, duration, enable
        end
    end

    local fn = (C_Container and C_Container.GetItemCooldown) or (C_Item and C_Item.GetItemCooldown) or GetItemCooldown
    if itemID and fn then
        local ok, start, duration, enable = pcall(fn, itemID)
        if ok and type(start) == "number" and type(duration) == "number" and not IsSecret(start) and not IsSecret(duration) then
            return start, duration, enable
        end
    end

    return 0, 0, 0
end

local function IsItemInRangeCompat(itemID)
    if itemID == nil or not UnitExists or not UnitExists("target") then return nil end
    if UnitIsFriend and InCombat() then
        local okF, isFriend = pcall(UnitIsFriend, "player", "target")
        if not okF or IsSecret(isFriend) or isFriend then return nil end
    end

    local fn = C_Item and C_Item.IsItemInRange or IsItemInRange
    if fn == nil then return nil end
    local ok, inRange = pcall(fn, itemID, "target")
    if not ok or IsSecret(inRange) then return nil end
    if inRange == true or inRange == 1 then return true end
    if inRange == false or inRange == 0 then return false end

    return nil
end

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
    if InCombat() then return end
    AzerothCompendium:SetConfig("QUESTWIDGETCOLLAPSED", collapsed == true)
    self:Layout()
end

function Widget:GetBackgroundAlpha()
    local value = tonumber(AzerothCompendium:GetConfig("QUESTWIDGETALPHA", 0.3))
    if value == nil then return 0.3 end

    return min(1, max(0, value))
end

function Widget:SetBackgroundAlpha(value)
    value = tonumber(value) or 0.3
    value = floor(min(1, max(0, value)) * 100 + 0.5) / 100
    AzerothCompendium:SetConfig("QUESTWIDGETALPHA", value)
    self:ApplyBackgroundAlpha()
end

function Widget:ApplyBackgroundAlpha()
    local frame = self.frame
    if frame == nil then return end
    local alpha = self:GetBackgroundAlpha()
    if frame.bg then frame.bg:SetAlpha(alpha) end
    for _, edge in ipairs(frame.borderEdges or {}) do
        edge:SetAlpha(alpha)
    end

    if frame.headerLine then frame.headerLine:SetAlpha(alpha) end
    if frame.list then
        frame.list.acoKeepLight = true
        if frame.list.contentBackground then frame.list.contentBackground:Hide() end
        if frame.list.border then frame.list.border:Hide() end
        if frame.list.borderOverlay then frame.list.borderOverlay:Hide() end
        if frame.list.rows then
            for _, row in ipairs(frame.list.rows) do
                if row.stripe then
                    row.stripe:SetAlpha(0)
                    row.stripe:Hide()
                end
            end
        end
    end
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
    if inst.id == instanceID or inst.parentID == instanceID then return true end
    local mapped = AzerothCompendium.WorldMap and AzerothCompendium.WorldMap.instanceMaps and AzerothCompendium.WorldMap.instanceMaps[instanceID]
    if mapped ~= nil then
        for _, id in ipairs(mapped) do
            if inst.id == id then return true end
        end
    end

    return false
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

function Widget:GetActiveQuestID(questID)
    for _, id in ipairs(AzerothCompendium:GetQuestVariants(questID)) do
        if C_QuestLog and C_QuestLog.IsOnQuest then
            local ok, active = pcall(C_QuestLog.IsOnQuest, id)
            if ok and active == true then return id end
        elseif GetQuestLogIndexByID then
            local ok, index = pcall(GetQuestLogIndexByID, id)
            if ok and type(index) == "number" and index > 0 then return id end
        end
    end

    return questID
end

function Widget:GetQuestLogIndex(questID)
    if questID == nil then return nil end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and type(index) == "number" and not IsSecret(index) and index > 0 then return index end
    end

    if GetQuestLogIndexByID then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and not IsSecret(index) and index > 0 then return index end
    end

    return nil
end

function Widget:GetQuestObjectives(questID)
    local list = {}
    if questID == nil then return list end
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and type(objectives) == "table" and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                if type(obj) == "table" and type(obj.text) == "string" and not IsSecret(obj.text) then
                    local text = obj.text:match("^%s*(.-)%s*$")
                    if text and text ~= "" then
                        local finished = not IsSecret(obj.finished) and obj.finished == true
                        tinsert(list, {
                            text = text,
                            finished = finished,
                        })
                    end
                end
            end

            if #list > 0 then return list end
        end
    end

    local index = self:GetQuestLogIndex(questID)
    if index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local okCount, count = pcall(GetNumQuestLeaderBoards, index)
        if okCount and type(count) == "number" and not IsSecret(count) then
            for i = 1, count do
                local okLine, text, _, done = pcall(GetQuestLogLeaderBoard, i, index)
                if okLine and type(text) == "string" and not IsSecret(text) then
                    local trimmed = text:match("^%s*(.-)%s*$")
                    if trimmed and trimmed ~= "" then
                        local finished = not IsSecret(done) and (done == true or done == 1)
                        tinsert(list, {
                            text = trimmed,
                            finished = finished,
                        })
                    end
                end
            end
        end
    end

    return list
end

function Widget:GetQuestObjectiveSummary(questID)
    local objectives = self:GetQuestObjectives(questID)
    for _, obj in ipairs(objectives) do
        if not obj.finished then return obj.text end
    end

    return objectives[1] and objectives[1].text or nil
end

function Widget:GetQuestUsableItem(activeID, logIndex, status)
    if status ~= "active" and status ~= "ready" then return nil end
    if GetQuestLogSpecialItemInfo == nil then return nil end
    logIndex = logIndex or self:GetQuestLogIndex(activeID)
    if logIndex == nil or logIndex <= 0 then return nil end
    local ok, link, texture, charges, showWhenComplete = pcall(GetQuestLogSpecialItemInfo, logIndex)
    if not ok or type(link) ~= "string" or IsSecret(link) then return nil end
    local itemID = tonumber(link:match("item:(%d+)"))
    if itemID == nil then return nil end
    if status == "ready" and (IsSecret(showWhenComplete) or not showWhenComplete) then return nil end
    if GetItemCountCompat(itemID, false) <= 0 then return nil end
    local count = GetItemCountCompat(itemID, true)
    if count <= 0 and type(charges) == "number" and not IsSecret(charges) then count = charges end

    return {
        itemID = itemID,
        texture = (not IsSecret(texture) and texture) or GetItemIconCompat(itemID),
        charges = count,
        logIndex = logIndex,
    }
end

function Widget:CanSuperTrack()
    return C_SuperTrack ~= nil and type(C_SuperTrack.SetSuperTrackedQuestID) == "function"
end

function Widget:GetSuperTrackedQuestID()
    if C_SuperTrack == nil or type(C_SuperTrack.GetSuperTrackedQuestID) ~= "function" then return 0 end
    local ok, questID = pcall(C_SuperTrack.GetSuperTrackedQuestID)
    if ok and type(questID) == "number" and not IsSecret(questID) and questID > 0 then return questID end

    return 0
end

function Widget:IsQuestFocused(activeID)
    return activeID ~= nil and activeID > 0 and self:GetSuperTrackedQuestID() == activeID
end

function Widget:ToggleQuestFocus(entry)
    if entry == nil or (entry.status ~= "active" and entry.status ~= "ready") then return false end
    if not self:CanSuperTrack() then return false end
    local activeID = entry.activeID or self:GetActiveQuestID(entry.id)
    if self:IsQuestFocused(activeID) then
        pcall(C_SuperTrack.SetSuperTrackedQuestID, 0)
    else
        pcall(C_SuperTrack.SetSuperTrackedQuestID, activeID)
    end

    self:UpdateAllFocusStates()

    return true
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
                local activeID = (status == "active" or status == "ready") and self:GetActiveQuestID(id) or id
                local logIndex = (status == "active" or status == "ready") and self:GetQuestLogIndex(activeID) or nil
                local objectives = (status == "active" or status == "ready") and self:GetQuestObjectives(activeID) or nil
                local questItem = (status == "active" or status == "ready") and self:GetQuestUsableItem(activeID, logIndex, status) or nil
                local target = self:ResolveTarget(inst, group, status)
                local match = self:IsTargetInLocation(inst, target, location)
                local entry = {
                    id = id,
                    activeID = activeID,
                    logIndex = logIndex,
                    inst = inst,
                    quest = group.quest,
                    name = group.nameIndex and format("%s (%d)", group.name, group.nameIndex) or group.name,
                    level = group.level or 0,
                    status = status,
                    section = status == "ready" and group.last.section or status == "active" and (group.objective and group.objective.section or group.last.section) or group.first.section,
                    target = target,
                    inZone = match,
                    objectives = objectives,
                    questItem = questItem,
                }

                entry.displayLines = self:BuildEntryLines(entry)
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
                    entry.displayLines = self:BuildEntryLines(entry)
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
        if InCombat() then return end
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
        if sizing == nil or InCombat() then
            StopSizing(sel)

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

function Widget:ShowQuestTooltip(row, anchor, isMapPin)
    local entry = row.entry
    if entry == nil or entry.isHeader then return end
    local id = entry.id
    GameTooltip:SetOwner(row, anchor or "ANCHOR_LEFT")
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
    if (entry.allMode or isMapPin) and entry.inst then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:GetInstanceName(entry.inst)), 1, 0.82, 0) end
    if entry.status == "active" or entry.status == "ready" then
        local objectives = self:GetQuestObjectives(entry.activeID or id)
        for _, obj in ipairs(objectives) do
            local line = obj.text:sub(1, 2) == "- " and obj.text or ("- " .. obj.text)
            if obj.finished then
                GameTooltip:AddLine(line, 0.25, 1, 0.25, true)
            else
                GameTooltip:AddLine(line, 0.92, 0.92, 0.92, true)
            end
        end
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
        if isMapPin and row.mapID and row.x and row.y then
            GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans("LID_SHOWENTRANCEMAP"), 0.9, 0.9, 0.9, 1, 0.82, 0)
        end
    elseif (target.mapID and target.x and target.y) or (isMapPin and row.mapID and row.x and row.y) then
        local hint = target.isTurnIn and "LID_QW_SHOWTURNIN" or (target.inside and "LID_SHOWENTRANCEMAP") or "LID_SHOWQUESTGIVER"
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans(hint), 0.9, 0.9, 0.9, 1, 0.82, 0)
    end

    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_RIGHTCLICK") .. ":"), AzerothCompendium:Trans("LID_QW_OPENINCOMPENDIUM"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:Show()
end

function Widget:IsCategoryCollapsed(key)
    if key == nil then return false end
    if type(ACOTABPC) == "table" and type(ACOTABPC.QUESTWIDGETCOLLAPSEDGROUPS) == "table" then return ACOTABPC.QUESTWIDGETCOLLAPSEDGROUPS[key] == true end

    return self.collapsedGroups ~= nil and self.collapsedGroups[key] == true
end

function Widget:ToggleCategoryCollapsed(key)
    if key == nil or InCombat() then return end
    local store
    if type(ACOTABPC) == "table" then
        if type(ACOTABPC.QUESTWIDGETCOLLAPSEDGROUPS) ~= "table" then ACOTABPC.QUESTWIDGETCOLLAPSEDGROUPS = {} end
        store = ACOTABPC.QUESTWIDGETCOLLAPSEDGROUPS
    else
        self.collapsedGroups = self.collapsedGroups or {}
        store = self.collapsedGroups
    end

    if store[key] then
        store[key] = nil
    else
        store[key] = true
    end

    self:Refresh()
    self:RefreshEmbedded()
end

function Widget:UpdateListScrollbar(scroller, inset)
    if scroller == nil or scroller.adjustingScroll or InCombat() then return end
    local viewport = scroller.GetViewport and scroller:GetViewport()
    if viewport == nil then return end
    inset = inset or 0
    local viewH = viewport:GetHeight() or 0
    local contentH = scroller.contentHeight or 0
    local needsScroll = viewH > 0 and contentH > viewH + 1
    if scroller.bar then
        if scroller.bar.SetHideIfUnscrollable then scroller.bar:SetHideIfUnscrollable(true) end
        scroller.bar:SetShown(needsScroll)
    end

    if scroller.scroll then
        local sb = scroller.scroll.ScrollBar or (scroller.scroll:GetName() and _G[scroller.scroll:GetName() .. "ScrollBar"])
        if sb and sb.SetShown then sb:SetShown(needsScroll) end
    end

    if scroller.lastNeedsScroll ~= needsScroll then
        scroller.lastNeedsScroll = needsScroll
        local rightOffset = needsScroll and (-18 - inset) or -inset
        viewport:ClearAllPoints()
        viewport:SetPoint("TOPLEFT", scroller, "TOPLEFT", inset, -inset)
        viewport:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", rightOffset, inset)
        if not scroller.adjustingScroll then
            scroller.adjustingScroll = true
            scroller:Refresh()
            scroller.adjustingScroll = nil
            local newViewH = viewport:GetHeight() or 0
            local newContentH = scroller.contentHeight or 0
            local stillNeeds = newViewH > 0 and newContentH > newViewH + 1
            if scroller.bar then scroller.bar:SetShown(stillNeeds) end
            if scroller.scroll then
                local sb = scroller.scroll.ScrollBar or (scroller.scroll:GetName() and _G[scroller.scroll:GetName() .. "ScrollBar"])
                if sb and sb.SetShown then sb:SetShown(stillNeeds) end
            end
        end
    end
end

function Widget:OnQuestClick(row, mouseButton)
    local entry = row.entry
    if entry == nil then return end
    if entry.isHeader then
        if mouseButton == "LeftButton" and entry.key then self:ToggleCategoryCollapsed(entry.key) end

        return
    end
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
    if entry.status == "ready" then
        if target and target.npc and target.npc ~= "" then return format("%s: %s", AzerothCompendium:Trans("LID_QW_TURNIN"), target.npc), 0.25, 1, 0.25 end

        return AzerothCompendium:Trans("LID_QW_TURNIN"), 0.25, 1, 0.25
    end

    if entry.status == "active" then
        return AzerothCompendium:Trans("LID_QUESTACTIVE"), 0.65, 0.85, 1
    end

    if target and target.npc and target.npc ~= "" then
        if entry.inZone then return format("%s: %s", AzerothCompendium:Trans("LID_QW_ACCEPT"), target.npc), 0.95, 0.88, 0.65 end

        return format("%s: %s", AzerothCompendium:Trans("LID_QW_ACCEPT"), target.npc), 0.72, 0.72, 0.76
    end

    if target and target.inside then return AzerothCompendium:Trans("LID_QUESTTREEINSTANCE"), 0.85, 0.75, 0.45 end
    if entry.inZone then return AzerothCompendium:Trans("LID_QW_ACCEPT"), 0.95, 0.88, 0.65 end

    return AzerothCompendium:Trans("LID_QW_ACCEPT"), 0.72, 0.72, 0.76
end

function Widget:GetEntryCategory(entry, allMode)
    if allMode then return entry.inst and AzerothCompendium:GetInstanceName(entry.inst) or AzerothCompendium:Trans("LID_DUNGEONS") end
    local target = entry.target
    if target and target.zone and target.zone ~= "" then return target.zone end
    if target and target.inside then return AzerothCompendium:Trans("LID_QUESTTREEINSTANCE") end

    return "-"
end

function Widget:BuildCategorizedList(entries, allMode)
    local groups = {}
    local byTitle = {}
    for _, entry in ipairs(entries or {}) do
        local title = self:GetEntryCategory(entry, allMode)
        local group = byTitle[title]
        if group == nil then
            group = {
                title = title,
                inZone = entry.inZone == true,
                minStatus = self.statusOrder[entry.status] or 9,
                minLevel = entry.inst and entry.inst.minLevel or 0,
                items = {},
            }

            byTitle[title] = group
            tinsert(groups, group)
        else
            if entry.inZone then group.inZone = true end
            local st = self.statusOrder[entry.status] or 9
            if st < group.minStatus then group.minStatus = st end
        end

        tinsert(group.items, entry)
    end

    table.sort(groups, function(a, b)
        if not allMode and a.inZone ~= b.inZone then return a.inZone end
        if a.minStatus ~= b.minStatus then return a.minStatus < b.minStatus end
        if allMode and a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end

        return a.title < b.title
    end)

    local result = {}
    for index, group in ipairs(groups) do
        local key = (allMode and "all:" or "zone:") .. group.title
        local collapsed = self:IsCategoryCollapsed(key)
        tinsert(result, {
            isHeader = true,
            key = key,
            title = group.title,
            count = #group.items,
            collapsed = collapsed,
            firstHeader = index == 1,
        })
        if not collapsed then
            for _, entry in ipairs(group.items) do
                tinsert(result, entry)
            end
        end
    end

    return result
end

function Widget:BuildEntryLines(entry)
    local lines = {}
    if entry.status == "active" then
        local objectives = entry.objectives
        if type(objectives) == "table" and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                local text = obj.text:sub(1, 2) == "- " and obj.text or ("- " .. obj.text)
                if obj.finished then
                    tinsert(lines, {text, 0.25, 1, 0.25})
                else
                    tinsert(lines, {text, 0.92, 0.92, 0.92})
                end
            end
        else
            local text, r, g, b = self:FormatRowSubtext(entry)
            tinsert(lines, {text, r, g, b})
        end

        return lines
    end

    if entry.status == "ready" then
        local objectives = entry.objectives
        if type(objectives) == "table" and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                local text = obj.text:sub(1, 2) == "- " and obj.text or ("- " .. obj.text)
                tinsert(lines, {text, 0.25, 1, 0.25})
            end
        end

        local text, r, g, b = self:FormatRowSubtext(entry)
        tinsert(lines, {text, r, g, b})

        return lines
    end

    local text, r, g, b = self:FormatRowSubtext(entry)
    tinsert(lines, {text, r, g, b})

    return lines
end

function Widget:ReleaseEmbeddedItemOverlay()
    local overlay = self.embeddedItemOverlay
    if overlay == nil or InCombat() then return end
    local owner = overlay.owner
    overlay.owner = nil
    overlay:SetAttribute("type1", nil)
    overlay:SetAttribute("item1", nil)
    overlay:Hide()
    if owner and owner.row and owner.row.UnlockHighlight then owner.row:UnlockHighlight() end
end

function Widget:AttachEmbeddedItemOverlay(button)
    if button == nil or button.itemID == nil or InCombat() then return end
    local overlay = self.embeddedItemOverlay
    if overlay == nil then
        overlay = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
        overlay:SetFrameStrata("FULLSCREEN_DIALOG")
        if SecureActionButton_ShouldUseOnKeyDown then
            overlay:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        else
            overlay:RegisterForClicks("LeftButtonUp")
        end

        overlay:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        overlay:SetScript("OnEnter", function(sel)
            local owner = sel.owner
            if owner == nil then return end
            if owner.row and owner.row.LockHighlight then owner.row:LockHighlight() end
            local onEnter = owner:GetScript("OnEnter")
            if onEnter then onEnter(owner, true) end
        end)

        overlay:SetScript("OnLeave", function(sel)
            local owner = sel.owner
            Widget:ReleaseEmbeddedItemOverlay()
            local onLeave = owner and owner:GetScript("OnLeave")
            if onLeave then onLeave(owner) end
        end)

        overlay:SetScript("OnUpdate", function(sel)
            local owner = sel.owner
            if owner == nil or not owner:IsVisible() or not owner:IsMouseOver() then
                Widget:ReleaseEmbeddedItemOverlay()
                local onLeave = owner and owner:GetScript("OnLeave")
                if onLeave then onLeave(owner) end
            end
        end)

        overlay:RegisterEvent("PLAYER_REGEN_DISABLED")
        overlay:SetScript("OnEvent", function() Widget:ReleaseEmbeddedItemOverlay() end)
        overlay:Hide()
        self.embeddedItemOverlay = overlay
    end

    overlay.owner = button
    overlay:SetAttribute("type1", "item")
    overlay:SetAttribute("item1", "item:" .. button.itemID)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(button)
    overlay:Show()
end

function Widget:ForEachVisibleRow(fn)
    if self.frame and self.frame:IsShown() and self.frame.list and self.frame.list.rows then
        for _, row in ipairs(self.frame.list.rows) do
            if row:IsShown() and row.entry then fn(row) end
        end
    end

    for _, pane in ipairs(self.embeddedViews or {}) do
        if pane:IsShown() and pane.list and pane.list.rows then
            for _, row in ipairs(pane.list.rows) do
                if row:IsShown() and row.entry then fn(row) end
            end
        end
    end
end

function Widget:UpdateAllFocusStates()
    self:ForEachVisibleRow(function(row)
        if row.UpdateFocusState then row:UpdateFocusState() end
    end)
end

function Widget:UpdateAllPinStates()
    self:ForEachVisibleRow(function(row)
        if row.UpdatePinState then row:UpdatePinState() end
    end)
end

function Widget:GetPinStore(create)
    if type(ACOTABPC) == "table" then
        if type(ACOTABPC.QUESTWIDGETPINS) ~= "table" then
            if not create then return nil end
            ACOTABPC.QUESTWIDGETPINS = {}
        end

        return ACOTABPC.QUESTWIDGETPINS
    end

    if create and self.pinnedQuests == nil then self.pinnedQuests = {} end

    return self.pinnedQuests
end

function Widget:IsQuestPinned(questID)
    if questID == nil then return false end
    local store = self:GetPinStore(false)

    return store ~= nil and store[questID] ~= nil
end

function Widget:ResolvePinLocation(entry)
    if entry == nil then return nil end
    local target = entry.target
    if target and type(target.mapID) == "number" and target.mapID > 0 and type(target.x) == "number" and type(target.y) == "number" and (target.x > 0 or target.y > 0) then
        return target.mapID, target.x, target.y
    end

    local mapID, x, y = AzerothCompendium:GetQuestGiverLocation(entry.id)
    if type(mapID) == "number" and mapID > 0 and type(x) == "number" and type(y) == "number" and (x > 0 or y > 0) then
        return mapID, x, y
    end

    local entrance = nil
    if target and target.instanceTarget then
        entrance = AzerothCompendium.INSTANCEENTRANCES and AzerothCompendium.INSTANCEENTRANCES[target.instanceTarget]
        if entrance == nil then
            local targetInst = AzerothCompendium:GetInstanceByID(target.instanceTarget)
            if targetInst then entrance = AzerothCompendium:GetInstanceEntrance(targetInst) end
        end
    end

    if entrance == nil and entry.inst then entrance = AzerothCompendium:GetInstanceEntrance(entry.inst) end
    if entrance and type(entrance[1]) == "number" and entrance[1] > 0 and type(entrance[2]) == "number" and type(entrance[3]) == "number" then
        return entrance[1], entrance[2], entrance[3]
    end

    return nil
end

function Widget:InvalidateMapPins()
    self.mapPinVersion = (self.mapPinVersion or 0) + 1
    self.resolvedMapPoints = nil
end

function Widget:ToggleQuestPin(entry)
    if entry == nil or entry.id == nil then return false end
    local store = self:GetPinStore(true)
    if store[entry.id] ~= nil then
        store[entry.id] = nil
    else
        local mapID = self:ResolvePinLocation(entry)
        if mapID == nil then return false end
        store[entry.id] = entry.inst and entry.inst.id or true
    end

    self:UpdateAllPinStates()
    self:InvalidateMapPins()
    self:UpdateMapPins()

    return true
end

function Widget:UpdateAllItemCooldowns()
    self:ForEachVisibleRow(function(row)
        if row.itemBtn and row.itemBtn.itemID then row.itemBtn:UpdateCooldown() end
    end)
end

function Widget:UpdateAllItemCharges()
    self:ForEachVisibleRow(function(row)
        if row.itemBtn and row.itemBtn.itemID then row.itemBtn:UpdateCharges() end
    end)
end

function Widget:UpdateAllItemRanges()
    self:ForEachVisibleRow(function(row)
        if row.itemBtn and row.itemBtn.itemID then row.itemBtn:UpdateRange() end
    end)
end

function Widget:RefreshInCombat()
    self:ForEachVisibleRow(function(row)
        local entry = row.entry
        if entry == nil or entry.isHeader then return end
        if entry.status == "active" or entry.status == "ready" then
            entry.objectives = self:GetQuestObjectives(entry.activeID or entry.id)
            entry.displayLines = self:BuildEntryLines(entry)
            local lines = entry.displayLines or {}
            for i, line in ipairs(lines) do
                local fs = row.lines and row.lines[i]
                if fs then
                    fs:SetText(line[1])
                    fs:SetTextColor(line[2], line[3], line[4])
                end
            end
        end

        if row.UpdateFocusState then row:UpdateFocusState() end
        if row.UpdatePinState then row:UpdatePinState() end
        if row.itemBtn and row.itemBtn.itemID then
            row.itemBtn:UpdateCooldown()
            row.itemBtn:UpdateCharges()
            row.itemBtn:UpdateRange()
        end
    end)
end

function Widget:CreateQuestRow(parent, secureItems)
    local c = self.config
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(c.rowH)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.highlightTex = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlightTex:SetAllPoints()
    row.highlightTex:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.highlightTex:SetBlendMode("ADD")
    row.headerIcon = row:CreateTexture(nil, "ARTWORK")
    row.headerIcon:SetSize(12, 12)
    row.headerIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -5)
    row.headerIcon:Hide()
    row.headerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.headerText:SetPoint("LEFT", row.headerIcon, "RIGHT", 4, 0)
    row.headerText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.headerText:SetJustifyH("LEFT")
    row.headerText:SetWordWrap(false)
    row.headerText:SetTextColor(0.94, 0.80, 0.56)
    row.headerText:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -6)
    local focusBtn = CreateFrame("Button", nil, row)
    focusBtn:SetSize(c.focusSize, c.focusSize)
    focusBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -4)
    focusBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    focusBtn:RegisterForClicks("LeftButtonUp")
    focusBtn.useAtlas = HasAtlas(self.poiAtlases.normal) and HasAtlas(self.poiAtlases.focused)
    if focusBtn.useAtlas then
        focusBtn.normalTex = focusBtn:CreateTexture(nil, "ARTWORK")
        focusBtn.normalTex:SetAllPoints()
        focusBtn:SetNormalTexture(focusBtn.normalTex)
        focusBtn.pushedTex = focusBtn:CreateTexture(nil, "ARTWORK")
        focusBtn.pushedTex:SetAllPoints()
        focusBtn:SetPushedTexture(focusBtn.pushedTex)
        focusBtn.highlightTex = focusBtn:CreateTexture(nil, "OVERLAY")
        focusBtn.highlightTex:SetAllPoints()
        if HasAtlas(self.poiAtlases.highlight) then
            focusBtn.highlightTex:SetAtlas(self.poiAtlases.highlight)
        else
            focusBtn.highlightTex:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        end

        focusBtn:SetHighlightTexture(focusBtn.highlightTex, "ADD")
    else
        focusBtn.fallbackRing = focusBtn:CreateTexture(nil, "BACKGROUND")
        focusBtn.fallbackRing:SetAllPoints()
        focusBtn.fallbackRing:SetTexture("Interface\\Buttons\\WHITE8X8")
        focusBtn.fallbackRing:SetVertexColor(0.85, 0.68, 0.2, 0.9)
        focusBtn.fallbackFill = focusBtn:CreateTexture(nil, "ARTWORK")
        focusBtn.fallbackFill:SetPoint("TOPLEFT", focusBtn, "TOPLEFT", 1, -1)
        focusBtn.fallbackFill:SetPoint("BOTTOMRIGHT", focusBtn, "BOTTOMRIGHT", -1, 1)
        focusBtn.fallbackFill:SetTexture("Interface\\Buttons\\WHITE8X8")
        if focusBtn.CreateMaskTexture then
            local mask = focusBtn:CreateMaskTexture()
            mask:SetAllPoints(focusBtn)
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            focusBtn.fallbackRing:AddMaskTexture(mask)
            focusBtn.fallbackFill:AddMaskTexture(mask)
        end

        focusBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    end

    focusBtn.turnInIcon = focusBtn:CreateTexture(nil, "ARTWORK", nil, 2)
    focusBtn.turnInIcon:SetSize(12, 12)
    focusBtn.turnInIcon:SetPoint("CENTER", focusBtn, "CENTER", 0, 0)
    if HasAtlas(self.poiAtlases.turnIn) then
        focusBtn.turnInIcon:SetAtlas(self.poiAtlases.turnIn)
    elseif HasAtlas(self.poiAtlases.turnInFallback) then
        focusBtn.turnInIcon:SetAtlas(self.poiAtlases.turnInFallback)
    else
        focusBtn.turnInIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    end

    focusBtn.turnInIcon:Hide()
    focusBtn.dots = focusBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    focusBtn.dots:SetPoint("CENTER", focusBtn, "CENTER", 0, 3)
    focusBtn.dots:SetText("...")
    focusBtn.dots:Hide()
    focusBtn:Hide()
    focusBtn:SetScript("OnClick", function()
        if row.entry and Widget:ToggleQuestFocus(row.entry) and GameTooltip:IsOwned(focusBtn) then focusBtn:GetScript("OnEnter")(focusBtn) end
    end)

    focusBtn:SetScript("OnEnter", function(sel)
        if row.entry == nil then return end
        row:LockHighlight()
        local focused = Widget:IsQuestFocused(row.entry.activeID or row.entry.id)
        GameTooltip:SetOwner(sel, "ANCHOR_LEFT")
        GameTooltip:SetText(AzerothCompendium:Trans(focused and "LID_QW_UNFOCUSQUEST" or "LID_QW_FOCUSQUEST"), 1, 0.82, 0)
        GameTooltip:Show()
    end)

    focusBtn:SetScript("OnLeave", function()
        row:UnlockHighlight()
        AzerothCompendium:HideGameTooltip()
    end)

    row.focusBtn = focusBtn
    local itemBtn = CreateFrame("Button", nil, row, secureItems and "SecureActionButtonTemplate" or nil)
    itemBtn.row = row
    itemBtn.secure = secureItems == true
    itemBtn:SetSize(c.itemSize, c.itemSize)
    itemBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -5)
    itemBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    if secureItems then
        if SecureActionButton_ShouldUseOnKeyDown then
            itemBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        else
            itemBtn:RegisterForClicks("LeftButtonUp")
        end
    end

    itemBtn.border = itemBtn:CreateTexture(nil, "BACKGROUND")
    itemBtn.border:SetAllPoints()
    itemBtn.border:SetTexture("Interface\\Buttons\\WHITE8X8")
    itemBtn.border:SetVertexColor(0.38, 0.32, 0.2, 0.95)
    itemBtn.icon = itemBtn:CreateTexture(nil, "ARTWORK")
    itemBtn.icon:SetPoint("TOPLEFT", itemBtn, "TOPLEFT", 1, -1)
    itemBtn.icon:SetPoint("BOTTOMRIGHT", itemBtn, "BOTTOMRIGHT", -1, 1)
    itemBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    itemBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local cooldown = CreateFrame("Cooldown", nil, itemBtn, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", itemBtn, "TOPLEFT", 1, -1)
    cooldown:SetPoint("BOTTOMRIGHT", itemBtn, "BOTTOMRIGHT", -1, 1)
    cooldown:Hide()
    itemBtn.cooldown = cooldown
    itemBtn.count = itemBtn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    itemBtn.count:SetPoint("BOTTOMRIGHT", itemBtn, "BOTTOMRIGHT", -1, 1)
    itemBtn.count:SetJustifyH("RIGHT")
    itemBtn.range = itemBtn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    itemBtn.range:SetPoint("TOPRIGHT", itemBtn, "TOPRIGHT", 1, 1)
    itemBtn.range:SetText(RANGE_INDICATOR or "•")
    itemBtn.range:SetAlpha(0)
    itemBtn.rangeTimer = 0
    function itemBtn:UpdateCooldown()
        if self.itemID == nil then
            self.cooldown:Hide()

            return
        end

        local start, duration, enable = GetItemCooldownCompat(self.itemID, self.logIndex)
        if enable ~= 0 and duration and duration > 0 and start and start > 0 then
            self.cooldown:SetCooldown(start, duration)
            self.cooldown:Show()
        else
            self.cooldown:Hide()
        end
    end

    function itemBtn:UpdateCharges()
        if self.itemID == nil then
            self.count:SetText("")

            return
        end

        local count = GetItemCountCompat(self.itemID, true)
        self.count:SetText(count > 1 and tostring(count) or "")
    end

    function itemBtn:UpdateRange()
        if self.itemID == nil then
            self.range:SetAlpha(0)

            return
        end

        local inRange = IsItemInRangeCompat(self.itemID)
        if inRange == false then
            self.range:SetTextColor(1, 0.15, 0.15)
            self.range:SetAlpha(1)
        elseif inRange == true then
            self.range:SetTextColor(0.75, 0.75, 0.75)
            self.range:SetAlpha(1)
        else
            self.range:SetAlpha(0)
        end
    end

    itemBtn:SetScript("OnEnter", function(sel, fromOverlay)
        if sel.itemID == nil then return end
        row:LockHighlight()
        local centerX = select(1, sel:GetCenter()) or 0
        local mid = (GetScreenWidth and GetScreenWidth() or UIParent:GetWidth() or 1000) / 2
        GameTooltip:SetOwner(sel, centerX < mid and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(sel.itemID)
        else
            GameTooltip:SetHyperlink("item:" .. sel.itemID)
        end

        GameTooltip:Show()
        if not sel.secure and not fromOverlay then Widget:AttachEmbeddedItemOverlay(sel) end
    end)

    itemBtn:SetScript("OnLeave", function()
        row:UnlockHighlight()
        AzerothCompendium:HideGameTooltip()
    end)

    itemBtn:SetScript("OnUpdate", function(sel, elapsed)
        if sel.itemID == nil or not UnitExists or not UnitExists("target") then
            sel.rangeTimer = 0
            sel.range:SetAlpha(0)

            return
        end

        sel.rangeTimer = sel.rangeTimer - elapsed
        if sel.rangeTimer <= 0 then
            sel.rangeTimer = 0.3
            sel:UpdateRange()
        end
    end)

    itemBtn:Hide()
    row.itemBtn = itemBtn
    local pinBtn = CreateFrame("Button", nil, row)
    pinBtn:SetSize(c.pinSize, c.pinSize)
    pinBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -5)
    pinBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    pinBtn:RegisterForClicks("LeftButtonUp")
    pinBtn.icon = pinBtn:CreateTexture(nil, "ARTWORK")
    pinBtn.icon:SetAllPoints()
    pinBtn.highlightTex = pinBtn:CreateTexture(nil, "HIGHLIGHT")
    pinBtn.highlightTex:SetAllPoints()
    if HasAtlas(self.pinAssets.highlight) then
        pinBtn.highlightTex:SetAtlas(self.pinAssets.highlight)
    else
        pinBtn.highlightTex:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    end

    pinBtn.highlightTex:SetBlendMode("ADD")
    pinBtn:SetScript("OnClick", function()
        if row.entry and Widget:ToggleQuestPin(row.entry) and GameTooltip:IsOwned(pinBtn) then pinBtn:GetScript("OnEnter")(pinBtn) end
    end)

    pinBtn:SetScript("OnEnter", function(sel)
        if row.entry == nil then return end
        row:LockHighlight()
        local pinned = Widget:IsQuestPinned(row.entry.id)
        local centerX = select(1, sel:GetCenter()) or 0
        local mid = (GetScreenWidth and GetScreenWidth() or UIParent:GetWidth() or 1000) / 2
        GameTooltip:SetOwner(sel, centerX < mid and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
        GameTooltip:SetText(AzerothCompendium:Trans(pinned and "LID_QW_UNPINMAP" or "LID_QW_PINMAP"), 1, 0.82, 0)
        GameTooltip:Show()
    end)

    pinBtn:SetScript("OnLeave", function()
        row:UnlockHighlight()
        AzerothCompendium:HideGameTooltip()
    end)

    pinBtn:Hide()
    row.pinBtn = pinBtn
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -c.padY)
    row.title:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(true)
    row.lines = {}
    function row:GetLine(index)
        local fs = self.lines[index]
        if fs == nil then
            fs = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            self.lines[index] = fs
        end

        return fs
    end

    function row:UpdatePinState()
        local entry = self.entry
        if entry == nil or not self.pinBtn:IsShown() then return end
        local pinned = Widget:IsQuestPinned(entry.id)
        local assets = Widget.pinAssets
        local icon = self.pinBtn.icon
        if pinned then
            if HasAtlas(assets.tracked) then
                icon:SetAtlas(assets.tracked)
                icon:SetVertexColor(1, 1, 1, 1)
            elseif HasAtlas(assets.untracked) then
                icon:SetAtlas(assets.untracked)
                icon:SetVertexColor(1, 0.85, 0.15, 1)
            else
                icon:SetTexture(assets.fallback)
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                icon:SetVertexColor(1, 0.85, 0.15, 1)
            end

            if icon.SetDesaturated then icon:SetDesaturated(false) end
            icon:SetAlpha(1)
        else
            if HasAtlas(assets.untracked) then
                icon:SetAtlas(assets.untracked)
            else
                icon:SetTexture(assets.fallback)
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            end

            icon:SetVertexColor(0.8, 0.8, 0.8, 1)
            if icon.SetDesaturated then icon:SetDesaturated(true) end
            icon:SetAlpha(0.45)
        end
    end

    function row:UpdateFocusState()
        local entry = self.entry
        if entry == nil or not self.focusBtn:IsShown() then return end
        local focused = Widget:IsQuestFocused(entry.activeID or entry.id)
        local atlases = Widget.poiAtlases
        if self.focusBtn.useAtlas then
            self.focusBtn.normalTex:SetAtlas(focused and atlases.focused or atlases.normal)
            self.focusBtn.pushedTex:SetAtlas(focused and atlases.focusedPushed or atlases.pushed)
        elseif self.focusBtn.fallbackFill then
            if focused then
                self.focusBtn.fallbackFill:SetVertexColor(0.95, 0.78, 0.14, 1)
                self.focusBtn.fallbackRing:SetVertexColor(1, 0.9, 0.35, 1)
            else
                self.focusBtn.fallbackFill:SetVertexColor(0.38, 0.07, 0.07, 1)
                self.focusBtn.fallbackRing:SetVertexColor(0.75, 0.58, 0.18, 0.9)
            end
        end

        if entry.status == "ready" then
            self.focusBtn.turnInIcon:Show()
            self.focusBtn.dots:Hide()
        else
            self.focusBtn.turnInIcon:Hide()
            self.focusBtn.dots:Show()
            if focused then
                self.focusBtn.dots:SetTextColor(0.08, 0.05, 0.02)
            else
                self.focusBtn.dots:SetTextColor(0.95, 0.90, 0.80)
            end
        end
    end

    function row:GetRowHeight(entry, width)
        if entry and entry.isHeader then return entry.firstHeader and 20 or 26 end
        local hasPin = Widget:ResolvePinLocation(entry) ~= nil
        local rightPad = 6
        if hasPin then rightPad = rightPad + c.pinSize + 4 end
        if entry.questItem then rightPad = rightPad + c.itemSize + 6 end
        local textW = max(80, (width or 240) - 30 - rightPad)
        local color = GetDifficultyColorCode(entry.level)
        local prefix = entry.level > 0 and format("[%d] ", entry.level) or ""
        self.title:SetWidth(textW)
        self.title:SetText(color .. prefix .. (entry.name or "") .. "|r")
        local h = c.padY + max(13, ceil(self.title:GetStringHeight() or 13))
        local displayLines = entry.displayLines or Widget:BuildEntryLines(entry)
        for i, line in ipairs(displayLines) do
            local fs = self:GetLine(i)
            fs:SetWidth(textW)
            fs:SetText(line[1])
            h = h + c.lineGap + max(12, ceil(fs:GetStringHeight() or 12))
        end

        h = h + c.padY
        local minH = entry.questItem and (c.itemSize + c.padY * 2) or 28

        return max(minH, h)
    end

    row:SetScript("OnEnter", function(sel) Widget:ShowQuestTooltip(sel) end)
    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel, button) Widget:OnQuestClick(sel, button) end)
    function row:Update(entry)
        self.entry = entry
        if entry.isHeader then
            self.highlightTex:SetAlpha(0.45)
            self.icon:Hide()
            self.focusBtn:Hide()
            self.pinBtn:Hide()
            self.title:Hide()
            for _, fs in ipairs(self.lines) do
                fs:Hide()
            end

            if not (self.itemBtn.secure and InCombat()) then
                self.itemBtn.itemID = nil
                self.itemBtn.logIndex = nil
                if self.itemBtn.secure then
                    self.itemBtn:SetAttribute("type1", nil)
                    self.itemBtn:SetAttribute("item1", nil)
                end

                self.itemBtn:Hide()
            end

            local topY = entry.firstHeader and -3 or -9
            self.headerIcon:ClearAllPoints()
            self.headerIcon:SetPoint("TOPLEFT", self, "TOPLEFT", 4, topY)
            AzerothCompendium.Theme:SetCollapseIcon(self.headerIcon, entry.collapsed == true)
            self.headerIcon:Show()
            self.headerText:ClearAllPoints()
            self.headerText:SetPoint("LEFT", self.headerIcon, "RIGHT", 4, 0)
            self.headerText:SetPoint("RIGHT", self, "RIGHT", -6, 0)
            if entry.collapsed and entry.count then
                self.headerText:SetText(format("%s (%d)", entry.title or "", entry.count))
            else
                self.headerText:SetText(entry.title or "")
            end

            self.headerText:Show()
            if self.stripe then
                self.stripe:SetAlpha(0)
                self.stripe:Hide()
            end

            return
        end

        self.highlightTex:SetAlpha(1)
        self.headerIcon:Hide()
        self.headerText:Hide()
        self.title:Show()
        local hasPin = Widget:ResolvePinLocation(entry) ~= nil
        local rightPad = 6
        if hasPin then rightPad = rightPad + c.pinSize + 4 end
        if entry.questItem then rightPad = rightPad + c.itemSize + 6 end
        if hasPin then
            self.pinBtn:Show()
            self:UpdatePinState()
        else
            self.pinBtn:Hide()
        end

        local showFocus = Widget:CanSuperTrack() and (entry.status == "active" or entry.status == "ready")
        if showFocus then
            self.icon:Hide()
            self.focusBtn:Show()
            self:UpdateFocusState()
        else
            self.focusBtn:Hide()
            self.icon:SetTexture(Widget.statusIcons[entry.status] or Widget.statusIcons.open)
            if self.icon.SetDesaturated then self.icon:SetDesaturated(entry.status == "active") end
            self.icon:Show()
        end

        self.title:ClearAllPoints()
        self.title:SetPoint("TOPLEFT", self, "TOPLEFT", 30, -c.padY)
        self.title:SetPoint("RIGHT", self, "RIGHT", -rightPad, 0)
        local color = GetDifficultyColorCode(entry.level)
        local prefix = entry.level > 0 and format("[%d] ", entry.level) or ""
        self.title:SetText(color .. prefix .. (entry.name or "") .. "|r")
        local displayLines = entry.displayLines or Widget:BuildEntryLines(entry)
        local anchor = self.title
        for i, line in ipairs(displayLines) do
            local fs = self:GetLine(i)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", i == 1 and 2 or 0, -c.lineGap)
            fs:SetPoint("RIGHT", self, "RIGHT", -rightPad, 0)
            fs:SetText(line[1])
            fs:SetTextColor(line[2], line[3], line[4])
            fs:Show()
            anchor = fs
        end

        for i = #displayLines + 1, #self.lines do
            self.lines[i]:Hide()
        end

        local item = entry.questItem
        if not (self.itemBtn.secure and InCombat()) then
            if item and item.itemID then
                self.itemBtn:ClearAllPoints()
                self.itemBtn:SetPoint("TOPRIGHT", self, "TOPRIGHT", hasPin and -(6 + c.pinSize + 4) or -6, -5)
                self.itemBtn.itemID = item.itemID
                self.itemBtn.logIndex = item.logIndex
                self.itemBtn.icon:SetTexture(item.texture or GetItemIconCompat(item.itemID))
                if self.itemBtn.secure then
                    self.itemBtn:SetAttribute("type1", "item")
                    self.itemBtn:SetAttribute("item1", "item:" .. item.itemID)
                end

                self.itemBtn:UpdateCooldown()
                self.itemBtn:UpdateCharges()
                self.itemBtn:UpdateRange()
                self.itemBtn:Show()
            else
                self.itemBtn.itemID = nil
                self.itemBtn.logIndex = nil
                if self.itemBtn.secure then
                    self.itemBtn:SetAttribute("type1", nil)
                    self.itemBtn:SetAttribute("item1", nil)
                end

                self.itemBtn:Hide()
            end
        end

        if self.stripe then
            if Widget.frame and Widget.frame.list and self:GetParent() == Widget.frame.list.content then
                self.stripe:SetAlpha(0)
                self.stripe:Hide()
            else
                self.stripe:SetAlpha(1)
                self.stripe:Show()
            end
        end
    end

    return row
end

function Widget:CreateSettingsPopover()
    if self.settingsPopover then return self.settingsPopover end
    local pop = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    pop:SetSize(220, 74)
    pop:SetFrameStrata("DIALOG")
    pop:SetClampedToScreen(true)
    pop:EnableMouse(true)
    if pop.SetBackdrop then
        pop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        pop:SetBackdropColor(0.08, 0.09, 0.11, 0.96)
        pop:SetBackdropBorderColor(0.32, 0.34, 0.38, 1)
    else
        local bg = pop:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.09, 0.11, 0.96)
    end

    pop.label = pop:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pop.label:SetPoint("TOPLEFT", pop, "TOPLEFT", 12, -12)
    pop.label:SetJustifyH("LEFT")
    pop.valueText = pop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pop.valueText:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -12, -12)
    pop.valueText:SetJustifyH("RIGHT")
    local function UpdateValueText(pct)
        pop.valueText:SetText(format("%d%%", floor(pct + 0.5)))
    end

    local ok, slider = pcall(CreateFrame, "Frame", nil, pop, "MinimalSliderWithSteppersTemplate")
    if ok and slider and type(slider.Init) == "function" and type(slider.RegisterCallback) == "function" and slider.Slider then
        slider:SetPoint("TOPLEFT", pop, "TOPLEFT", 10, -34)
        slider:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -10, -34)
        slider:SetHeight(24)
        slider:Init(floor(self:GetBackgroundAlpha() * 100 + 0.5), 0, 100, 100, {})
        slider:RegisterCallback("OnValueChanged", function(_, value)
            if pop.updating then return end
            UpdateValueText(value)
            Widget:SetBackgroundAlpha(value / 100)
        end, pop)

        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel", function(sel, delta)
            local cur = sel.Slider:GetValue() or 0
            sel.Slider:SetValue(min(100, max(0, cur + delta * 5)))
        end)

        pop.slider = slider
        pop.SetSliderPercent = function(pct)
            pop.updating = true
            if slider.SetValue then
                slider:SetValue(pct)
            elseif slider.Slider then
                slider.Slider:SetValue(pct)
            end

            UpdateValueText(pct)
            pop.updating = nil
        end
    else
        local fallback = CreateFrame("Slider", nil, pop, AzerothCompendium:CheckTemplates("OptionsSliderTemplate") and "OptionsSliderTemplate" or nil)
        fallback:SetPoint("TOPLEFT", pop, "TOPLEFT", 14, -40)
        fallback:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -14, -40)
        fallback:SetHeight(18)
        fallback:SetOrientation("HORIZONTAL")
        fallback:SetMinMaxValues(0, 100)
        fallback:SetValueStep(1)
        if fallback.SetObeyStepOnDrag then fallback:SetObeyStepOnDrag(true) end
        if fallback.Low then fallback.Low:SetText("") end
        if fallback.High then fallback.High:SetText("") end
        if fallback.Text then fallback.Text:SetText("") end
        fallback:SetScript("OnValueChanged", function(_, value)
            if pop.updating then return end
            UpdateValueText(value)
            Widget:SetBackgroundAlpha(value / 100)
        end)

        pop.slider = fallback
        pop.SetSliderPercent = function(pct)
            pop.updating = true
            fallback:SetValue(pct)
            UpdateValueText(pct)
            pop.updating = nil
        end
    end

    pop:SetScript("OnEvent", function(sel, event, button)
        if event == "GLOBAL_MOUSE_DOWN" and button == "LeftButton" and sel:IsShown() then
            if sel:IsMouseOver() then return end
            if Widget.frame and Widget.frame.settingsButton and Widget.frame.settingsButton:IsMouseOver() then return end
            sel:Hide()
        end
    end)

    pop:SetScript("OnShow", function(sel)
        pcall(sel.RegisterEvent, sel, "GLOBAL_MOUSE_DOWN")
    end)

    pop:SetScript("OnHide", function(sel)
        pcall(sel.UnregisterEvent, sel, "GLOBAL_MOUSE_DOWN")
    end)

    pop:Hide()
    pop.acoTheme = {}
    if AzerothCompendium.Theme and AzerothCompendium.Theme.RegisterRoot then AzerothCompendium.Theme:RegisterRoot(pop) end
    self.settingsPopover = pop

    return pop
end

function Widget:ToggleSettingsPopover()
    local frame = self.frame
    if frame == nil or frame.settingsButton == nil then return end
    local pop = self:CreateSettingsPopover()
    if pop:IsShown() then
        pop:Hide()

        return
    end

    pop.label:SetText(AzerothCompendium:Trans("LID_QW_BGALPHA"))
    pop.SetSliderPercent(floor(self:GetBackgroundAlpha() * 100 + 0.5))
    pop:ClearAllPoints()
    pop:SetPoint("TOPRIGHT", frame.settingsButton, "BOTTOMRIGHT", 0, -6)
    pop:Show()
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
    local frame = CreateFrame("Frame", "AzerothCompendiumQuestWidget", UIParent)
    self.frame = frame
    frame.acoTheme = {}
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(false)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:RegisterForDrag("LeftButton")
    frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 1)
    local topEdge = frame:CreateTexture(nil, "BORDER")
    topEdge:SetHeight(1)
    topEdge:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topEdge:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topEdge:SetColorTexture(0, 0, 0, 0.9)
    local bottomEdge = frame:CreateTexture(nil, "BORDER")
    bottomEdge:SetHeight(1)
    bottomEdge:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottomEdge:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottomEdge:SetColorTexture(0, 0, 0, 0.9)
    local leftEdge = frame:CreateTexture(nil, "BORDER")
    leftEdge:SetWidth(1)
    leftEdge:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftEdge:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    leftEdge:SetColorTexture(0, 0, 0, 0.9)
    local rightEdge = frame:CreateTexture(nil, "BORDER")
    rightEdge:SetWidth(1)
    rightEdge:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rightEdge:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    rightEdge:SetColorTexture(0, 0, 0, 0.9)
    frame.borderEdges = {topEdge, bottomEdge, leftEdge, rightEdge}
    frame.headerLine = frame:CreateTexture(nil, "BORDER")
    frame.headerLine:SetHeight(1)
    frame.headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -31)
    frame.headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -31)
    frame.headerLine:SetColorTexture(1, 1, 1, 0.14)
    frame:SetScript("OnDragStart", function(sel)
        if InCombat() then return end
        sel:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(sel)
        if InCombat() then return end
        sel:StopMovingOrSizing()
        Widget:SavePosition()
        Widget:RestorePosition()
    end)

    frame:HookScript("OnHide", function()
        if Widget.settingsPopover then Widget.settingsPopover:Hide() end
    end)

    local width, height = self:GetSavedSize()
    frame:SetWidth(max(c.minWidth, width))
    frame.userHeight = max(c.minHeight, height)
    frame:SetScale(AzerothCompendium:GetConfig("QUESTWIDGETSCALE", 1) or 1)
    self:RestorePosition()
    frame.CloseButton = CreateFrame("Button", nil, frame)
    frame.CloseButton:SetSize(16, 16)
    frame.CloseButton:SetPoint("RIGHT", frame, "TOPRIGHT", -6, -16)
    frame.CloseButton:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.CloseButton.icon = frame.CloseButton:CreateTexture(nil, "ARTWORK")
    frame.CloseButton.icon:SetSize(16, 16)
    frame.CloseButton.icon:SetPoint("CENTER", frame.CloseButton, "CENTER", 0, 0)
    frame.CloseButton.icon:SetTexture("Interface\\AddOns\\AzerothCompendium\\media\\ui\\modern\\close")
    frame.CloseButton.icon:SetVertexColor(0.75, 0.75, 0.78)
    frame.CloseButton:SetScript("OnEnter", function(sel) sel.icon:SetVertexColor(1, 0.35, 0.35) end)
    frame.CloseButton:SetScript("OnLeave", function(sel) sel.icon:SetVertexColor(0.75, 0.75, 0.78) end)
    frame.CloseButton:SetScript("OnClick", function() Widget:Close() end)
    frame.toggle = CreateFrame("Button", nil, frame)
    frame.toggle:SetSize(16, 16)
    frame.toggle:SetPoint("RIGHT", frame.CloseButton, "LEFT", -4, 0)
    frame.toggle:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.toggle.icon = frame.toggle:CreateTexture(nil, "ARTWORK")
    frame.toggle.icon:SetAllPoints()
    frame.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    frame.toggle:SetScript("OnClick", function() Widget:SetCollapsed(not Widget:IsCollapsed()) end)
    frame.settingsButton = CreateFrame("Button", nil, frame)
    frame.settingsButton:SetSize(16, 16)
    frame.settingsButton:SetPoint("RIGHT", frame.toggle, "LEFT", -4, 0)
    frame.settingsButton:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.settingsButton.icon = frame.settingsButton:CreateTexture(nil, "ARTWORK")
    frame.settingsButton.icon:SetAllPoints()
    if HasAtlas("QuestLog-icon-setting") then
        frame.settingsButton.icon:SetAtlas("QuestLog-icon-setting")
    else
        frame.settingsButton.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    end

    frame.settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    frame.settingsButton:SetScript("OnClick", function() Widget:ToggleSettingsPopover() end)
    frame.settingsButton:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_SETTINGS"))
        GameTooltip:Show()
    end)

    frame.settingsButton:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    frame.openButton = CreateFrame("Button", nil, frame)
    frame.openButton:SetSize(16, 16)
    frame.openButton:SetPoint("RIGHT", frame.settingsButton, "LEFT", -4, 0)
    frame.openButton:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.openButton.icon = frame.openButton:CreateTexture(nil, "ARTWORK")
    frame.openButton.icon:SetAllPoints()
    frame.openButton.icon:SetTexture(AzerothCompendium:GetIcon())
    frame.openButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
    frame.dungeonDropdown = self:CreateDungeonDropdown(frame)
    frame.dungeonDropdown:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    frame.bar = CreateFrame("Frame", nil, frame.content)
    frame.bar:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.bar:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, 0)
    frame.bar:SetHeight(c.barH)
    frame.bar:EnableMouse(true)
    frame.bar:RegisterForDrag("LeftButton")
    frame.bar:SetScript("OnDragStart", function()
        if InCombat() then return end
        frame:StartMoving()
    end)

    frame.bar:SetScript("OnDragStop", function()
        if InCombat() then return end
        frame:StopMovingOrSizing()
        Widget:SavePosition()
        Widget:RestorePosition()
    end)

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
    frame.zoneLabel = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.zoneLabel:SetPoint("LEFT", frame.bar, "LEFT", 2, 0)
    frame.zoneLabel:SetPoint("RIGHT", frame.modeGroup, "LEFT", -6, 0)
    frame.zoneLabel:SetJustifyH("LEFT")
    frame.zoneLabel:SetWordWrap(false)
    frame.list = ui.CreateScroller(frame.content, c.rowH, function(parent) return Widget:CreateQuestRow(parent, true) end, 0, 0)
    frame.list.acoTheme = {}
    frame.list.acoKeepLight = true
    if frame.list.bar and frame.list.bar.SetHideIfUnscrollable then frame.list.bar:SetHideIfUnscrollable(true) end
    if hooksecurefunc and frame.list.UpdateScroll then
        hooksecurefunc(frame.list, "UpdateScroll", function(sel) Widget:UpdateListScrollbar(sel, 0) end)
    end

    if frame.list.contentBackground then frame.list.contentBackground:Hide() end
    if frame.list.border then frame.list.border:Hide() end
    if frame.list.borderOverlay then frame.list.borderOverlay:Hide() end
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
    if AzerothCompendium.Theme and AzerothCompendium.Theme.RegisterRoot then AzerothCompendium.Theme:RegisterRoot(frame) end
    self:ApplyBackgroundAlpha()
    AzerothCompendium:OnLanguage(function()
        if Widget.settingsPopover and Widget.settingsPopover.label then Widget.settingsPopover.label:SetText(AzerothCompendium:Trans("LID_QW_BGALPHA")) end
        Widget:Refresh()
    end)

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
    if frame == nil or frame.layingOut or InCombat() then return end
    frame.layingOut = true
    local c = self.config
    local collapsed = self:IsCollapsed()
    AzerothCompendium.Theme:SetCollapseIcon(frame.toggle.icon, collapsed)
    frame.content:SetShown(not collapsed)
    frame.grip:SetShown(not collapsed)
    frame.headerCount:SetShown(collapsed)
    if frame.headerLine then frame.headerLine:SetShown(not collapsed) end
    frame.dungeonDropdown:ClearAllPoints()
    frame.dungeonDropdown:SetHeight(c.dropdownH)
    frame.dungeonDropdown:SetPoint("LEFT", frame, "TOPLEFT", 6, -16)
    frame.dungeonDropdown:SetPoint("RIGHT", collapsed and frame.headerCount or frame.openButton, "LEFT", -6, 0)
    if collapsed then
        frame:SetHeight(c.collapsed)
        frame.layingOut = false
        self:ApplyBackgroundAlpha()

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
    self:ApplyBackgroundAlpha()
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
    if InCombat() then
        self.pendingCombatRefresh = true
        self:RefreshInCombat()

        return
    end

    local location = self:GetPlayerLocation()
    local inst, allMode = self:GetSelectedInstance(location)
    self.selectedInstance = inst
    self.allMode = allMode == true
    if frame.titleText then
        frame.titleText:SetText("")
        frame.titleText:Hide()
    end

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
    frame.list.data = self:BuildCategorizedList(shown, self.allMode)
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
    pane.list = ui.CreateScroller(pane, c.rowH, function(scrollerParent) return Widget:CreateQuestRow(scrollerParent, false) end, 0, 4)
    if pane.list.bar and pane.list.bar.SetHideIfUnscrollable then pane.list.bar:SetHideIfUnscrollable(true) end
    if hooksecurefunc and pane.list.UpdateScroll then
        hooksecurefunc(pane.list, "UpdateScroll", function(sel) Widget:UpdateListScrollbar(sel, 4) end)
    end
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
        self.list.data = Widget:BuildCategorizedList(shown, false)
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
    if InCombat() then
        self.pendingVisibility = true

        return
    end

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
    if self.frame and not InCombat() then
        self.frame:Show()
        self:Refresh()
    end
end

function Widget:GetPinnedMapPoints()
    local store = self:GetPinStore(false)
    if store == nil or next(store) == nil then return {} end
    local version = self.mapPinVersion or 0
    if self.resolvedMapPoints and self.resolvedMapPointsVersion == version then return self.resolvedMapPoints end
    local byInst = {}
    local unknown = {}
    local completed = {}
    for questID, instID in pairs(store) do
        if type(questID) == "number" then
            if AzerothCompendium:IsQuestCompleted(questID) then
                tinsert(completed, questID)
            else
                local inst = type(instID) == "number" and AzerothCompendium:GetInstanceByID(instID) or nil
                if inst then
                    byInst[inst] = byInst[inst] or {}
                    byInst[inst][questID] = true
                else
                    unknown[questID] = true
                end
            end
        end
    end

    for _, questID in ipairs(completed) do
        store[questID] = nil
    end

    local resolved = {}
    local function AddFromInst(inst, wanted)
        local all = self:CollectActionable(inst, nil)
        for _, entry in ipairs(all) do
            if wanted[entry.id] and resolved[entry.id] == nil then
                local mapID, x, y = self:ResolvePinLocation(entry)
                if mapID then
                    resolved[entry.id] = {
                        entry = entry,
                        mapID = mapID,
                        x = x,
                        y = y,
                        nx = x / 100,
                        ny = y / 100,
                    }

                    store[entry.id] = inst.id
                end
            end
        end
    end

    for inst, wanted in pairs(byInst) do
        AddFromInst(inst, wanted)
    end

    if next(unknown) ~= nil then
        local dungeons, raids = self:GetAvailableInstances()
        for _, list in ipairs({dungeons, raids}) do
            for _, inst in ipairs(list) do
                if byInst[inst] == nil then
                    AddFromInst(inst, unknown)
                    for questID in pairs(resolved) do
                        unknown[questID] = nil
                    end

                    if next(unknown) == nil then break end
                end
            end

            if next(unknown) == nil then break end
        end
    end

    local points = {}
    for _, point in pairs(resolved) do
        tinsert(points, point)
    end

    table.sort(points, function(a, b) return a.entry.id < b.entry.id end)
    self.resolvedMapPoints = points
    self.resolvedMapPointsVersion = version

    return points
end

function Widget:ProjectMapPoint(point, mapID)
    if point.mapID == mapID then return point.nx, point.ny end
    if C_Map == nil or C_Map.GetMapRectOnMap == nil then return nil end
    local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(point.mapID, mapID)
    if minX == nil or maxX == nil or minY == nil or maxY == nil or maxX <= minX or maxY <= minY then return nil end
    local x = minX + point.nx * (maxX - minX)
    local y = minY + point.ny * (maxY - minY)
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

    return x, y
end

function Widget:GetWaypointFrameLevel()
    if WorldMapFrame == nil or WorldMapFrame.GetPinFrameLevelsManager == nil then return nil end
    local manager = WorldMapFrame:GetPinFrameLevelsManager()
    if manager == nil or manager.GetValidFrameLevel == nil then return nil end

    return manager:GetValidFrameLevel("PIN_FRAME_LEVEL_WAYPOINT_LOCATION")
end

function Widget:IsMapPinTracked(pin)
    if pin == nil or pin.mapID == nil or pin.x == nil or pin.y == nil then return false end
    if not AzerothCompendium:HasUserWaypoint() or not AzerothCompendium:IsWaypointTracked() then return false end
    local pos = AzerothCompendium:GetUserWaypointPositionForMap(pin.mapID)
    if pos == nil then return false end
    local x, y = pos:GetXY()
    if IsSecret(x) or IsSecret(y) or x == nil or y == nil then return false end

    return abs(x - pin.x / 100) < 0.001 and abs(y - pin.y / 100) < 0.001
end

function Widget:SetMapWaypointPinsHidden(hide)
    if WorldMapFrame == nil or WorldMapFrame.EnumeratePinsByTemplate == nil then return end
    for pin in WorldMapFrame:EnumeratePinsByTemplate("WaypointLocationPinTemplate") do
        if hide then
            pin:SetAlpha(0)
        elseif self.mapWaypointHidden then
            pin:SetAlpha(1)
        end
    end

    self.mapWaypointHidden = hide
end

function Widget:UpdateMapPinStyle(pin)
    if pin == nil or not pin:IsShown() then return false end
    local tracked = self:IsMapPinTracked(pin)
    local level = pin.baseLevel or pin:GetFrameLevel()
    if tracked then
        local wpLevel = self:GetWaypointFrameLevel()
        if wpLevel ~= nil and wpLevel >= level then level = wpLevel + 1 end
    end

    if pin:GetFrameLevel() ~= level then pin:SetFrameLevel(level) end
    if tracked then
        if self.pinAssets.trackingResolved == nil then
            local atlas = self.pinAssets.trackingCircle
            self.pinAssets.trackingResolved = (AzerothCompendium:FindAtlas({atlas}) or (AzerothCompendium:HasAtlasOrFallback(atlas) and atlas)) or false
        end

        if self.pinAssets.trackingResolved then
            AzerothCompendium:SetAtlasOrFallback(pin.circle, self.pinAssets.trackingResolved)
            pin.circle:Show()
        else
            pin.circle:Hide()
        end
    else
        pin.circle:Hide()
    end

    return tracked
end

function Widget:UpdateMapPinStyles()
    local anyTracked = false
    for _, pin in ipairs(self.mapPins) do
        if pin:IsShown() and self:UpdateMapPinStyle(pin) then anyTracked = true end
    end

    if anyTracked or self.mapWaypointHidden then self:SetMapWaypointPinsHidden(anyTracked) end
end

function Widget:OnMapPinClick(pin, mouseButton)
    local entry = pin.entry
    if entry == nil then return end
    if mouseButton == "RightButton" then
        if AzerothCompendium.OpenInstanceQuests and entry.inst then AzerothCompendium:OpenInstanceQuests(entry.inst.id, entry.id) end

        return
    end

    if IsShiftKeyDown() and ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() then
        local link = GetQuestLink and GetQuestLink(entry.id)
        if link and ChatEdit_InsertLink then
            ChatEdit_InsertLink(link)

            return
        end
    end

    if pin.mapID and pin.x and pin.y then
        if InCombat() then
            AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT"))

            return
        end

        if self:IsMapPinTracked(pin) then
            AzerothCompendium:ClearUserWaypoint()
            AzerothCompendium:SetWaypointTracked(false)
            if SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_REMOVE then PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_REMOVE) end
            self:UpdateMapPinStyles()

            return
        end

        local ok, reason = AzerothCompendium:SetMapWaypoint(pin.mapID, pin.x, pin.y)
        if ok then
            if SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON then PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON) end
            self:UpdateMapPinStyles()
            if C_Timer and C_Timer.After then C_Timer.After(0, function() Widget:UpdateMapPinStyles() end) end
        else
            local message = reason == "combat" and "LID_WAYPOINTCOMBAT" or "LID_NOQUESTGIVER"
            AzerothCompendium:INFO(AzerothCompendium:Trans(message))
        end
    end
end

function Widget:CreateMapPin(parent)
    local pin = CreateFrame("Button", nil, parent)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin.circle = pin:CreateTexture(nil, "ARTWORK", nil, 0)
    pin.circle:SetPoint("CENTER")
    pin.circle:Hide()
    pin.icon = pin:CreateTexture(nil, "OVERLAY", nil, 1)
    pin.icon:SetAllPoints(pin)
    pin.icon:SetTexture(self.pinAssets.mapIcon)
    if pin.icon.SetDesaturated then pin.icon:SetDesaturated(true) end
    pin.icon:SetVertexColor(1, 0.85, 0.1, 1)
    pin.questMark = pin:CreateTexture(nil, "OVERLAY", nil, 2)
    pin.questMark:SetTexture(self.pinAssets.mapQuestMark)
    local highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(pin)
    highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    highlight:SetBlendMode("ADD")
    pin:SetScript("OnEnter", function(sel)
        if sel.entry == nil then return end
        Widget:ShowQuestTooltip(sel, "ANCHOR_RIGHT", true)
    end)

    pin:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    pin:SetScript("OnHide", function(sel) if GameTooltip:IsOwned(sel) then AzerothCompendium:HideGameTooltip() end end)
    pin:SetScript("OnClick", function(sel, button) Widget:OnMapPinClick(sel, button) end)

    return pin
end

function Widget:UpdateMapPins()
    local worldMap = AzerothCompendium.WorldMap
    local child = worldMap and worldMap.GetCanvas and worldMap.GetCanvas()
    if child == nil or WorldMapFrame == nil or WorldMapFrame.GetMapID == nil or not WorldMapFrame:IsShown() then return end
    local mapID = WorldMapFrame:GetMapID()
    local scale = child:GetScale()
    local poiScale = worldMap.GetPoiScale and worldMap.GetPoiScale() or 1
    local instanceOverlay = worldMap.map ~= nil and worldMap.map.IsShown ~= nil and worldMap.map:IsShown() or false
    local stitched = OpenMapAPI ~= nil and OpenMapAPI.IsStitched ~= nil and OpenMapAPI.IsStitched() or false
    local flavor = AzerothCompendium:GetFlavor()
    local version = self.mapPinVersion or 0
    local last = self.mapPinState
    if last.ready and last.mapID == mapID and abs((last.scale or 0) - (scale or 0)) < 0.00005 and abs((last.poiScale or 0) - poiScale) < 0.00005 and last.instanceOverlay == instanceOverlay and last.stitched == stitched and last.flavor == flavor and last.version == version then return end
    last.ready, last.mapID, last.scale, last.poiScale, last.instanceOverlay, last.stitched, last.flavor, last.version = true, mapID, scale, poiScale, instanceOverlay, stitched, flavor, version
    for _, pin in ipairs(self.mapPins) do
        pin:Hide()
    end

    if instanceOverlay or stitched or scale == nil or scale <= 0 then
        if self.mapWaypointHidden then self:SetMapWaypointPinsHidden(false) end

        return
    end

    local points = self:GetPinnedMapPoints()
    if #points == 0 then
        if self.mapWaypointHidden then self:SetMapWaypointPinsHidden(false) end

        return
    end

    local w = child:GetWidth()
    local h = child:GetHeight()
    if w == nil or h == nil or w <= 0 or h <= 0 then return end
    local size = self.config.mapPinSize * poiScale / scale
    local clusters = {}
    for _, point in ipairs(points) do
        local x, y = self:ProjectMapPoint(point, mapID)
        if x ~= nil then
            local cluster = nil
            for _, existing in ipairs(clusters) do
                if abs(existing.x - x) <= 0.004 and abs(existing.y - y) <= 0.004 then
                    cluster = existing
                    break
                end
            end

            if cluster == nil then
                cluster = {x = x, y = y, items = {}}
                tinsert(clusters, cluster)
            end

            tinsert(cluster.items, {point = point, x = x, y = y})
        end
    end

    local count = 0
    local twoPi = math.pi * 2
    local baseLevel = child:GetFrameLevel() + self.config.mapPinLevel
    for _, cluster in ipairs(clusters) do
        local total = #cluster.items
        for idx, item in ipairs(cluster.items) do
            count = count + 1
            local pin = self.mapPins[count]
            if pin == nil then
                pin = self:CreateMapPin(child)
                self.mapPins[count] = pin
            end

            local dx, dy = 0, 0
            if total > 1 then
                local angle = (idx - 1) * (twoPi / total)
                local radius = size * 0.48
                dx = math.cos(angle) * radius
                dy = math.sin(angle) * radius
            end

            pin.entry = item.point.entry
            pin.mapID = item.point.mapID
            pin.x = item.point.x
            pin.y = item.point.y
            pin.baseLevel = baseLevel
            pin:SetSize(size, size)
            pin.circle:SetSize(size * 1.35, size * 1.35)
            local markSize = size * 0.65
            pin.questMark:SetSize(markSize, markSize)
            pin.questMark:ClearAllPoints()
            pin.questMark:SetPoint("BOTTOM", pin, "TOP", 0, -size * 0.22)
            local pad = size * 0.18
            pin:SetHitRectInsets(-pad, -pad, -markSize * 0.6, -pad)
            pin:SetFrameLevel(baseLevel)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", child, "TOPLEFT", w * item.x + dx, -h * item.y + dy)
            pin:Show()
        end
    end

    self:UpdateMapPinStyles()
end

if AzerothCompendium.RegisterWaypointCallback then
    AzerothCompendium:RegisterWaypointCallback(function() Widget:UpdateMapPinStyles() end)
end

if AzerothCompendium.RegisterWaypointMarker then
    AzerothCompendium:RegisterWaypointMarker(function(mapID, x, y)
        for _, pin in ipairs(Widget.mapPins) do
            if pin:IsShown() and pin.mapID == mapID and pin.x ~= nil and pin.y ~= nil and abs(pin.x / 100 - x) < 0.001 and abs(pin.y / 100 - y) < 0.001 then return true end
        end

        return false
    end)
end

if WorldMapFrame ~= nil then
    WorldMapFrame:HookScript("OnShow", function()
        Widget:InvalidateMapPins()
        Widget:UpdateMapPins()
    end)

    local mapUpdater = CreateFrame("Frame", nil, WorldMapFrame)
    mapUpdater.elapsed = 0
    mapUpdater:SetScript("OnUpdate", function(sel, elapsed)
        sel.elapsed = sel.elapsed + elapsed
        if sel.elapsed < Widget.config.mapUpdateInterval then return end
        sel.elapsed = 0
        Widget:UpdateMapPins()
    end)
end

AzerothCompendium:OnLanguage(function() Widget:InvalidateMapPins() end)

function Widget:OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:InvalidateMapPins()
        self:UpdateVisibility()

        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if self.pendingVisibility then
            self.pendingVisibility = nil
            self.pendingCombatRefresh = nil
            self:UpdateVisibility()
        elseif self.pendingCombatRefresh then
            self.pendingCombatRefresh = nil
            self:Refresh()
            self:RefreshEmbedded()
        end

        return
    end

    if event == "SUPER_TRACKING_CHANGED" then
        self:UpdateAllFocusStates()

        return
    end

    if event == "BAG_UPDATE_COOLDOWN" then
        self:UpdateAllItemCooldowns()

        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        self:UpdateAllItemRanges()

        return
    end

    if event == "QUEST_LOG_UPDATE" or event == "QUEST_ACCEPTED" or event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" or event == "UNIT_QUEST_LOG_CHANGED" then
        self:InvalidateMapPins()
    end

    local hasEmbedded = false
    for _, pane in ipairs(self.embeddedViews or {}) do
        if pane:IsShown() then hasEmbedded = true end
    end

    if not ((self.frame and self.frame:IsShown()) or hasEmbedded) then return end
    if InCombat() then
        self.pendingCombatRefresh = true
        self:RefreshInCombat()
        if hasEmbedded then self:RefreshEmbedded() end

        return
    end

    self:QueueRefresh()
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "UNIT_QUEST_LOG_CHANGED", "PLAYER_LEVEL_UP", "SUPER_TRACKING_CHANGED", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "PLAYER_TARGET_CHANGED"}) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

eventFrame:SetScript("OnEvent", function(_, event) Widget:OnEvent(event) end)
