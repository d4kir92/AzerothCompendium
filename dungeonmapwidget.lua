local _, AzerothCompendium = ...
local MapWidget = {}
AzerothCompendium.DungeonMapWidget = MapWidget
MapWidget.config = {
    width = 360,
    height = 310,
    minWidth = 240,
    minHeight = 220,
    side = 10,
    top = 34,
    dropdownH = 24,
    dropdownGap = 6,
    bottom = 12,
    scaleMin = 0.5,
    scaleMax = 1.5,
    zoomMax = 4,
    zoomFactor = 1.25,
    media = "Interface\\AddOns\\AzerothCompendium\\media\\",
}

MapWidget.view = {
    zoom = 1,
    x = 0,
    y = 0,
    baseWidth = 0,
    baseHeight = 0,
}

MapWidget.selected = {}
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

function MapWidget:IsEnabled()
    return AzerothCompendium:GetConfig("DUNGEONMAPWIDGET", true) == true
end

function MapWidget:GetLastInstanceID()
    if type(ACOTABPC) == "table" and ACOTABPC.DUNGEONMAPWIDGETLAST ~= nil then return ACOTABPC.DUNGEONMAPWIDGETLAST end

    return AzerothCompendium:GetConfig("DUNGEONMAPWIDGETLAST", nil)
end

function MapWidget:SetLastInstanceID(id)
    if id == nil then return end
    ACOTABPC = ACOTABPC or {}
    ACOTABPC.DUNGEONMAPWIDGETLAST = id
    AzerothCompendium:SetConfig("DUNGEONMAPWIDGETLAST", id)
end

function MapWidget:GetCurrentInstance()
    if IsInInstance == nil or GetInstanceInfo == nil then return nil end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return nil end
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if IsSecret(name) or IsSecret(instanceID) or instanceID == nil then return nil end

    return instanceID, name
end

function MapWidget:GetAvailableInstances()
    local dungeons = {}
    local raids = {}
    local maps = AzerothCompendium.INSTANCEMAPS or {}
    for _, inst in ipairs(AzerothCompendium:GetInstances("dungeon")) do
        if maps[inst.id] ~= nil and #maps[inst.id] > 0 and AzerothCompendium:IsInstanceInFlavor(inst) then tinsert(dungeons, inst) end
    end

    for _, inst in ipairs(AzerothCompendium:GetInstances("raid")) do
        if maps[inst.id] ~= nil and #maps[inst.id] > 0 and AzerothCompendium:IsInstanceInFlavor(inst) then tinsert(raids, inst) end
    end

    return dungeons, raids
end

function MapWidget:FindInstanceByID(id)
    if id == nil then return nil end
    local dungeons, raids = self:GetAvailableInstances()
    for _, list in ipairs({dungeons, raids}) do
        for _, inst in ipairs(list) do
            if inst.id == id then return inst end
        end
    end

    local wm = AzerothCompendium.WorldMap
    local mapped = wm and wm.instanceMaps and wm.instanceMaps[id]
    if mapped ~= nil then
        for _, targetID in ipairs(mapped) do
            local inst = self:FindInstanceByID(targetID)
            if inst ~= nil then return inst end
        end
    end

    for _, list in ipairs({dungeons, raids}) do
        for _, inst in ipairs(list) do
            if inst.parentID == id then return inst end
        end
    end

    return nil
end

function MapWidget:GetLevelsForInstance(inst)
    if inst == nil then return nil end
    local list = AzerothCompendium.INSTANCEMAPS and AzerothCompendium.INSTANCEMAPS[inst.id]
    if list == nil or #list == 0 then return nil end
    local levels = {}
    for _, info in ipairs(list) do
        tinsert(levels, {
            ["file"] = info.file,
            ["key"] = info.id,
            ["name"] = info.name,
            ["width"] = info.width,
            ["height"] = info.height,
            ["fileWidth"] = info.fileWidth,
            ["fileHeight"] = info.fileHeight,
            ["source"] = info.source,
            ["inst"] = inst,
        })
    end

    return levels
end

function MapWidget:GetLevels(instanceID)
    if instanceID == nil then return nil end
    local wm = AzerothCompendium.WorldMap
    if wm ~= nil and wm.GetLevels ~= nil then
        local levels = wm.GetLevels(instanceID)
        if levels ~= nil and #levels > 0 then return levels end
    end

    local inst = self:FindInstanceByID(instanceID)

    return self:GetLevelsForInstance(inst)
end

function MapWidget:FormatInstanceLabel(inst)
    if inst == nil then return "" end
    local name = AzerothCompendium:GetInstanceName(inst)
    if inst.minLevel and inst.maxLevel and inst.minLevel > 0 then return format("%s (%d-%d)", name, inst.minLevel, inst.maxLevel) end

    return name
end

function MapWidget:SelectInstanceByID(id, fromZone, fallbackName)
    local levels = fromZone and self:GetLevels(id) or nil
    local inst = self:FindInstanceByID(id)
    if levels == nil and inst ~= nil then levels = self:GetLevelsForInstance(inst) end
    if levels == nil or #levels == 0 then return false end
    local key = inst and inst.id or id
    self.activeID = key
    self.selectedInst = inst or (levels[1] and levels[1].inst)
    if fromZone and fallbackName ~= nil and (inst == nil or inst.id ~= id) then
        self.instanceName = fallbackName
    else
        self.instanceName = self.selectedInst and AzerothCompendium:GetInstanceName(self.selectedInst) or fallbackName
    end

    self.levels = levels
    self.levelIndex = self.selected[key] or 1
    if self.levelIndex > #levels then self.levelIndex = 1 end
    self:SetLastInstanceID(key)
    self:ResetView()
    self:Refresh()

    return true
end

function MapWidget:EnsureInstanceLoaded()
    if self.levels ~= nil and #self.levels > 0 then return true end
    local instanceID, name = self:GetCurrentInstance()
    if instanceID ~= nil and self:SelectInstanceByID(instanceID, true, name) then return true end
    local lastID = self:GetLastInstanceID()
    if lastID ~= nil and self:SelectInstanceByID(lastID, false) then return true end
    local dungeons, raids = self:GetAvailableInstances()
    local fallback = dungeons[1] or raids[1]
    if fallback ~= nil then return self:SelectInstanceByID(fallback.id, false) end

    return false
end

function MapWidget:ResetView()
    self.view.zoom = 1
    self.view.x = 0
    self.view.y = 0
    self.view.drag = nil
end

function MapWidget:GetCursorOffset()
    local viewport = self.frame and self.frame.viewport
    if viewport == nil then return nil end
    local scale = viewport:GetEffectiveScale()
    local centerX, centerY = viewport:GetCenter()
    if scale == nil or scale <= 0 or centerX == nil then return nil end
    local cursorX, cursorY = GetCursorPosition()

    return cursorX / scale - centerX, cursorY / scale - centerY
end

function MapWidget:ApplyView()
    local frame = self.frame
    if frame == nil or frame.art == nil or frame.viewport == nil then return end
    local view = self.view
    local vw = frame.viewport:GetWidth() or 0
    local vh = frame.viewport:GetHeight() or 0
    if vw <= 0 or vh <= 0 or view.baseWidth <= 0 or view.baseHeight <= 0 then return end
    local width = view.baseWidth * view.zoom
    local height = view.baseHeight * view.zoom
    local maxX = max(0, (width - vw) / 2)
    local maxY = max(0, (height - vh) / 2)
    view.x = min(maxX, max(-maxX, view.x))
    view.y = min(maxY, max(-maxY, view.y))
    frame.art:SetSize(width, height)
    frame.art:ClearAllPoints()
    frame.art:SetPoint("CENTER", frame.viewport, "CENTER", view.x, view.y)
    self:RefreshPins()
    self:UpdatePlayerArrow()
end

function MapWidget:UpdatePlayerArrow()
    if AzerothCompendium.UpdateInstancePosArrow == nil then return end
    local frame = self.frame
    if frame == nil or not frame:IsShown() or frame.art == nil or not frame.art:IsShown() then
        AzerothCompendium:HideInstancePosArrow(self.posArrow, "AC_MapWidget")
        return
    end

    local info = self.levels and self.levels[self.levelIndex or 1]
    if info == nil then
        AzerothCompendium:HideInstancePosArrow(self.posArrow, "AC_MapWidget")
        return
    end

    local enabled = AzerothCompendium.GetSharedOption == nil or AzerothCompendium:GetSharedOption("INSTANCEPLAYERPOS")
    if not enabled then
        AzerothCompendium:HideInstancePosArrow(self.posArrow, "AC_MapWidget")
        return
    end

    if self.posArrow == nil then self.posArrow = AzerothCompendium:CreateInstancePosArrow(frame.viewport, frame.viewport:GetFrameLevel() + 700, 20) end
    AzerothCompendium:UpdateInstancePosArrow(self.posArrow, frame.art, info.file, "AC_MapWidget", true)
end

function MapWidget:LayoutArt()
    local frame = self.frame
    local info = self.levels and self.levels[self.levelIndex or 1]
    if frame == nil or frame.viewport == nil or info == nil then return end
    local vw = frame.viewport:GetWidth() or 0
    local vh = frame.viewport:GetHeight() or 0
    if vw <= 0 or vh <= 0 then return end
    local aw = info.width or 1024
    local ah = info.height or 683
    local ratio = ah / aw
    local width = vw
    local height = vw * ratio
    if height > vh then
        height = vh
        width = vh / ratio
    end

    self.view.baseWidth = width
    self.view.baseHeight = height
    self:ApplyView()
end

function MapWidget:FindLevelIndex(key)
    for index, level in ipairs(self.levels or {}) do
        if level.key == key then return index end
    end

    return nil
end

function MapWidget:SelectLevel(index)
    if self.levels == nil or index == nil or index < 1 or index > #self.levels then return end
    self.levelIndex = index
    if self.activeID ~= nil then self.selected[self.activeID] = index end
    self:ResetView()
    self:Refresh()
end

function MapWidget:SavePosition()
    local frame = self.frame
    if frame == nil then return end
    local left, top = frame:GetLeft(), frame:GetTop()
    if left == nil or top == nil then return end
    AzerothCompendium:SetConfig("DUNGEONMAPWIDGETPOS", {left, top})
end

function MapWidget:RestorePosition()
    local frame = self.frame
    local pos = AzerothCompendium:GetConfig("DUNGEONMAPWIDGETPOS", nil)
    frame:ClearAllPoints()
    if type(pos) == "table" and pos[1] and pos[2] then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
    else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -80, -320)
    end
end

function MapWidget:SaveSize()
    local frame = self.frame
    if frame == nil then return end
    AzerothCompendium:SetConfig("DUNGEONMAPWIDGETSIZE", {floor(frame:GetWidth() + 0.5), floor(frame:GetHeight() + 0.5)})
    AzerothCompendium:SetConfig("DUNGEONMAPWIDGETSCALE", frame:GetScale())
    self:SavePosition()
end

function MapWidget:GetSavedSize()
    local size = AzerothCompendium:GetConfig("DUNGEONMAPWIDGETSIZE", nil)
    if type(size) == "table" and size[1] and size[2] then return size[1], size[2] end

    return self.config.width, self.config.height
end

function MapWidget:ApplyScale(value)
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

function MapWidget:OnPinEnter(pin)
    local row = pin.row
    if row == nil then return end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    if row[1] == "boss" then
        GameTooltip:SetText(row[5] or "")
        if row[6] then GameTooltip:AddLine(format("%s %d", LEVEL or "Level", row[6]), 1, 1, 1) end
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_MAPPINBOSSHINT"), 0.6, 0.6, 0.6)
    elseif row[1] == "item" then
        if GameTooltip.SetItemByID ~= nil then
            GameTooltip:SetItemByID(row[4])
        else
            GameTooltip:SetHyperlink("item:" .. row[4])
        end
    elseif row[1] == "queststart" or row[1] == "questend" then
        GameTooltip:SetText(row[5] or "")
        GameTooltip:AddLine(AzerothCompendium:Trans(row[1] == "queststart" and "LID_MAPPINQUESTSTART" or "LID_MAPPINQUESTEND"), 1, 0.82, 0)
    elseif row[1] == "level" then
        local target = self.levels and self.levels[pin.level]
        local wm = AzerothCompendium.WorldMap
        GameTooltip:SetText(wm and wm.GetLabel and wm.GetLabel(self.levels, target) or (target and target.name) or "")
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_MAPPINLEVELHINT"), 0.6, 0.6, 0.6)
    else
        GameTooltip:SetText(AzerothCompendium:Trans("LID_ENTRANCE"))
    end

    GameTooltip:Show()
end

function MapWidget:OnPinLeave(pin)
    if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
end

function MapWidget:OnPinMouseUp(pin, button)
    if not pin:IsMouseOver() then return end
    if button == "RightButton" then
        self:ResetView()
        self:ApplyView()

        return
    end

    local row = pin.row
    if button ~= "LeftButton" or row == nil then return end
    if row[1] == "level" and pin.level ~= nil then
        self:OnPinLeave(pin)
        self:SelectLevel(pin.level)
    elseif row[1] == "boss" and AzerothCompendiumAPI ~= nil and AzerothCompendiumAPI.ShowBossLoot ~= nil then
        local info = self.levels and self.levels[self.levelIndex or 1]
        if info == nil or info.file == nil then return end
        self:OnPinLeave(pin)
        AzerothCompendiumAPI.ShowBossLoot(strmatch(info.file, "([^\\]+)$"), row[4])
    end
end

function MapWidget:RefreshPins()
    local frame = self.frame
    if frame == nil or not frame:IsShown() then return end
    local info = self.levels and self.levels[self.levelIndex or 1]
    if info == nil then
        if self.pinSet ~= nil then self.pinSet:Hide() end

        return
    end

    local wm = AzerothCompendium.WorldMap
    local rows = wm and wm.GetPins and wm.GetPins(info) or nil
    if rows == nil then
        if self.pinSet ~= nil then self.pinSet:Hide() end

        return
    end

    if self.pinSet == nil then
        self.pinSet = AzerothCompendium:CreateInstancePins(frame.viewport, {
            ["media"] = self.config.media,
            ["onEnter"] = function(pin) self:OnPinEnter(pin) end,
            ["onLeave"] = function(pin) self:OnPinLeave(pin) end,
            ["onMouseUp"] = function(pin, button) self:OnPinMouseUp(pin, button) end,
            ["getLevel"] = function(row) return self:FindLevelIndex(row[4]) end,
            ["isEnabled"] = function(kind) return AzerothCompendium.MapPins ~= nil and AzerothCompendium.MapPins.IsEnabled(kind) end,
            ["isQuestVisible"] = function(row) return AzerothCompendium.MapPins == nil or AzerothCompendium.MapPins.IsQuestPinVisible(row) end,
            ["isBossKilled"] = function(row) return AzerothCompendium.DungeonTracker ~= nil and AzerothCompendium.DungeonTracker:IsBossKilled(row[4]) end,
            ["getBossScale"] = function() return tonumber(AzerothCompendium:GetConfig("MAPPINS_BOSSSCALE", 1)) or 1 end,
        })
    end

    local artScale = AzerothCompendium.GetInstancePinArtScale ~= nil and AzerothCompendium:GetInstancePinArtScale(self.view.baseWidth, self.view.baseHeight) or 1
    self.pinSet:Update(rows, frame.art, 1, nil, artScale)
end

function MapWidget:GetTitleRegion(frame)
    if type(frame.GetTitleText) == "function" then
        local ok, title = pcall(frame.GetTitleText, frame)
        if ok and title then return title end
    end

    if type(frame.TitleContainer) == "table" and frame.TitleContainer.TitleText then return frame.TitleContainer.TitleText end
    if frame.TitleText then return frame.TitleText end

    return _G[frame:GetName() .. "TitleText"]
end

function MapWidget:BuildDropdownSections()
    local dungeons, raids = self:GetAvailableInstances()
    local sections = {}
    if #dungeons > 0 then
        local items = {}
        for _, inst in ipairs(dungeons) do
            tinsert(items, {
                text = self:FormatInstanceLabel(inst),
                id = inst.id,
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
            })
        end

        tinsert(sections, {
            title = AzerothCompendium:Trans("LID_RAIDS"),
            items = items,
        })
    end

    return sections
end

function MapWidget:CreateDungeonDropdown(parent)
    local modern = AzerothCompendium:CheckTemplates("WowStyle1DropdownTemplate")
    local dropdown = CreateFrame(modern and "DropdownButton" or "Button", nil, parent, modern and "WowStyle1DropdownTemplate" or "UIPanelButtonTemplate")
    dropdown:SetHeight(self.config.dropdownH)
    if modern and dropdown.SetupMenu then
        dropdown:SetupMenu(function(_, root)
            if root.SetScrollMode then root:SetScrollMode(320) end
            for _, section in ipairs(MapWidget:BuildDropdownSections()) do
                if section.title then root:CreateTitle(section.title) end
                for _, item in ipairs(section.items) do
                    local id = item.id
                    root:CreateRadio(item.text, function() return MapWidget.activeID == id end, function() MapWidget:SelectInstanceByID(id, false) end)
                end
            end
        end)
    else
        dropdown:SetScript("OnClick", function(sel)
            local entries = {}
            for _, section in ipairs(MapWidget:BuildDropdownSections()) do
                if section.title then
                    tinsert(entries, {
                        text = section.title,
                        isTitle = true,
                    })
                end

                for _, item in ipairs(section.items) do
                    local id = item.id
                    tinsert(entries, {
                        text = item.text,
                        checked = function() return MapWidget.activeID == id end,
                        func = function() MapWidget:SelectInstanceByID(id, false) end,
                    })
                end
            end

            AzerothCompendium:ShowContextMenu(sel, entries)
        end)
    end

    return dropdown
end

function MapWidget:CreateFrame()
    if self.frame ~= nil then return self.frame end
    local c = self.config
    local frame = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumDungeonMapWidget", AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET"))
    frame.titleText = self:GetTitleRegion(frame)
    AzerothCompendium:ApplyWidgetLayer(frame, "map")
    frame:SetToplevel(false)
    local width, height = self:GetSavedSize()
    frame:SetSize(width, height)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(c.minWidth, c.minHeight, 0, 0)
    elseif frame.SetMinResize then
        frame:SetMinResize(c.minWidth, c.minHeight)
    end

    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(sel) sel:StartMoving() end)
    frame:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        self:SavePosition()
    end)

    frame:SetScale(AzerothCompendium:GetConfig("DUNGEONMAPWIDGETSCALE", 1) or 1)
    if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() self:Close() end) end
    local dropdown = self:CreateDungeonDropdown(frame)
    dropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    dropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -c.side, -c.top)
    dropdown:SetFrameLevel(max(frame:GetFrameLevel() + 10, frame.NineSlice and frame.NineSlice:GetFrameLevel() + 2 or 0))
    frame.dropdown = dropdown
    local viewport = CreateFrame("Frame", nil, frame)
    viewport:SetClipsChildren(true)
    viewport:EnableMouse(true)
    viewport:EnableMouseWheel(true)
    viewport:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -(c.top + c.dropdownH + c.dropdownGap))
    viewport:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    viewport.bg = viewport:CreateTexture(nil, "BACKGROUND")
    viewport.bg:SetAllPoints(viewport)
    viewport.bg:SetColorTexture(0.05, 0.05, 0.06, 0.85)
    local art = viewport:CreateTexture(nil, "ARTWORK")
    art:SetPoint("CENTER", viewport, "CENTER", 0, 0)
    frame.levelPanel = AzerothCompendium:CreateInstanceLevelPanel(viewport, {
        ["getTitle"] = function() return AzerothCompendium:Trans("LID_MAPLEVELS") end,
        ["getLabel"] = function(levels, level)
            local wm = AzerothCompendium.WorldMap

            return wm and wm.GetLabel and wm.GetLabel(levels, level) or level.name or ""
        end,
        ["onSelect"] = function(index) self:SelectLevel(index) end,
        ["getPos"] = function() return AzerothCompendium:GetConfig("DUNGEONMAPWIDGETLEVELPOS", nil) end,
        ["setPos"] = function(pos) AzerothCompendium:SetConfig("DUNGEONMAPWIDGETLEVELPOS", pos) end,
        ["getCollapsed"] = function() return AzerothCompendium:GetConfig("DUNGEONMAPWIDGETLEVELCOLLAPSED", false) end,
        ["setCollapsed"] = function(collapsed) AzerothCompendium:SetConfig("DUNGEONMAPWIDGETLEVELCOLLAPSED", collapsed) end,
        ["getFrameLevel"] = function() return viewport:GetFrameLevel() + 1000 end,
    })

    viewport:SetScript("OnMouseWheel", function(_, delta)
        local view = self.view
        local zoom = min(c.zoomMax, max(1, view.zoom * c.zoomFactor ^ delta))
        if zoom == view.zoom then return end
        local dx, dy = self:GetCursorOffset()
        if dx ~= nil then
            local factor = zoom / view.zoom
            view.x = dx - (dx - view.x) * factor
            view.y = dy - (dy - view.y) * factor
        end

        view.zoom = zoom
        self:ApplyView()
    end)

    viewport:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            self:ResetView()
            self:ApplyView()

            return
        end

        if button ~= "LeftButton" or self.view.zoom <= 1 then return end
        local dx, dy = self:GetCursorOffset()
        if dx == nil then return end
        self.view.drag = {dx, dy, self.view.x, self.view.y}
    end)

    viewport:SetScript("OnUpdate", function(sel, elapsed)
        local drag = self.view.drag
        if drag ~= nil then
            if not IsMouseButtonDown("LeftButton") then
                self.view.drag = nil
            else
                local dx, dy = self:GetCursorOffset()
                if dx ~= nil then
                    self.view.x = drag[3] + dx - drag[1]
                    self.view.y = drag[4] + dy - drag[2]
                    self:ApplyView()
                end
            end
        end

        sel.posElapsed = (sel.posElapsed or 0) + elapsed
        if sel.posElapsed < 0.05 then return end
        sel.posElapsed = 0
        self:UpdatePlayerArrow()
    end)

    frame:HookScript("OnHide", function()
        if AzerothCompendium.HideInstancePosArrow ~= nil then AzerothCompendium:HideInstancePosArrow(self.posArrow, "AC_MapWidget") end
    end)

    frame.viewport = viewport
    frame.art = art
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(sel, button)
        if button == "RightButton" then
            if IsShiftKeyDown() then
                self:ApplyScale(1)
            else
                frame:SetSize(c.width, c.height)
            end

            self:SaveSize()
            self:LayoutArt()

            return
        end

        if button ~= "LeftButton" then return end
        if IsShiftKeyDown() then
            local startX = GetCursorPosition()
            local startScale = frame:GetScale()
            sel:SetScript("OnUpdate", function()
                local x = GetCursorPosition()
                self:ApplyScale(startScale * (1 + (x - startX) / 240))
            end)
        else
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    grip:SetScript("OnMouseUp", function(sel)
        sel:SetScript("OnUpdate", nil)
        frame:StopMovingOrSizing()
        self:SaveSize()
        self:LayoutArt()
    end)

    frame.grip = grip
    grip:SetFrameLevel(max(frame:GetFrameLevel() + 10, frame.NineSlice and frame.NineSlice:GetFrameLevel() + 2 or 0))
    frame:SetScript("OnSizeChanged", function()
        self:LayoutArt()
        if frame.levelPanel ~= nil and frame.levelPanel:IsShown() then frame.levelPanel:Layout() end
    end)

    self.frame = frame
    self:RestorePosition()

    return frame
end

function MapWidget:Refresh()
    local frame = self.frame
    if frame == nil or not frame:IsShown() then return end
    local levels = self.levels
    if levels == nil or #levels == 0 then
        if frame.titleText then frame.titleText:SetText(AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET")) end
        if frame.dropdown then AzerothCompendium:SetDropdownText(frame.dropdown, AzerothCompendium:Trans("LID_QW_SELECTDUNGEON")) end
        frame.levelPanel:Hide()
        frame.art:Hide()
        if self.pinSet ~= nil then self.pinSet:Hide() end
        if AzerothCompendium.HideInstancePosArrow ~= nil then AzerothCompendium:HideInstancePosArrow(self.posArrow, "AC_MapWidget") end

        return
    end

    local index = self.levelIndex or 1
    if index < 1 or index > #levels then index = 1 end
    self.levelIndex = index
    local info = levels[index]
    local title = self.instanceName or (info.inst and AzerothCompendium:GetInstanceName(info.inst)) or AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET")
    if frame.titleText then frame.titleText:SetText(AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET")) end
    if frame.dropdown then AzerothCompendium:SetDropdownText(frame.dropdown, title) end
    if #levels > 1 then
        frame.levelPanel:Refresh(levels, index)
        frame.levelPanel:Show()
    else
        frame.levelPanel:Hide()
    end

    local fw = info.fileWidth or 1024
    local fh = info.fileHeight or 1024
    local aw = info.width or 1024
    local ah = info.height or 683
    frame.art:SetTexture(info.file)
    frame.art:SetTexCoord(0, aw / fw, 0, ah / fh)
    frame.art:Show()
    self:LayoutArt()
end

function MapWidget:UpdateVisibility()
    local hasLevels = self.levels ~= nil and #self.levels > 0
    local show = hasLevels and (self.forced or (self:IsEnabled() and self.instanceID ~= nil and self.closedFor ~= self.instanceID))
    if not show then
        if self.frame ~= nil then self.frame:Hide() end

        return
    end

    self:CreateFrame():Show()
    self:Refresh()
end

function MapWidget:CheckZone()
    local instanceID, name = self:GetCurrentInstance()
    if instanceID == nil then
        self.instanceID = nil
        self.closedFor = nil
        if not self.forced then
            self.levels = nil
            self:ResetView()
        end

        self:UpdateVisibility()

        return
    end

    local changed = self.instanceID ~= instanceID
    self.instanceID = instanceID
    if changed then
        self.closedFor = nil
        self.forced = false
        if not self:SelectInstanceByID(instanceID, true, name) then
            self.levels = nil
            self:ResetView()
        end
    end

    self:UpdateVisibility()
end

function MapWidget:Close()
    if self.instanceID ~= nil then self.closedFor = self.instanceID end
    self.forced = false
    if self.frame ~= nil then self.frame:Hide() end
end

function MapWidget:Toggle()
    if self.frame ~= nil and self.frame:IsShown() then
        self:Close()

        return
    end

    if self:EnsureInstanceLoaded() then
        self.closedFor = nil
        self.forced = true
        self:UpdateVisibility()
    end
end

MapWidget.eventFrame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "QUEST_LOG_UPDATE"}) do
    pcall(MapWidget.eventFrame.RegisterEvent, MapWidget.eventFrame, event)
end

MapWidget.eventFrame:SetScript("OnEvent", function(_, event)
    if event == "QUEST_LOG_UPDATE" then
        MapWidget:RefreshPins()
    else
        MapWidget:CheckZone()
        if C_Timer and C_Timer.After then C_Timer.After(2, function() MapWidget:CheckZone() end) end
    end
end)
