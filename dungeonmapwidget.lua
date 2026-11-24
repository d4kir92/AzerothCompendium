local _, AzerothCompendium = ...
local MapWidget = {}
AzerothCompendium.DungeonMapWidget = MapWidget
MapWidget.config = {
    width = 360,
    height = 280,
    minWidth = 240,
    minHeight = 200,
    side = 10,
    top = 34,
    bottom = 12,
    headerHeight = 24,
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

function MapWidget:GetCurrentInstance()
    if IsInInstance == nil or GetInstanceInfo == nil then return nil end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return nil end
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if IsSecret(name) or IsSecret(instanceID) or instanceID == nil then return nil end

    return instanceID, name
end

function MapWidget:GetLevels(instanceID)
    if instanceID == nil then return nil end
    local wm = AzerothCompendium.WorldMap
    if wm == nil or wm.GetLevels == nil then return nil end

    return wm.GetLevels(instanceID)
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
    if self.instanceID ~= nil then self.selected[self.instanceID] = index end
    self:ResetView()
    self:Refresh()
end

function MapWidget:StepLevel(delta)
    if self.levels == nil or #self.levels <= 1 then return end
    local nextIndex = (self.levelIndex or 1) + delta
    if nextIndex < 1 then
        nextIndex = #self.levels
    elseif nextIndex > #self.levels then
        nextIndex = 1
    end

    self:SelectLevel(nextIndex)
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

    self.pinSet:Update(rows, frame.art, 1)
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

function MapWidget:CreateFrame()
    if self.frame ~= nil then return self.frame end
    local c = self.config
    local frame = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumDungeonMapWidget", AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET"))
    frame.titleText = self:GetTitleRegion(frame)
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
    local levelBar = CreateFrame("Frame", nil, frame)
    levelBar:SetHeight(c.headerHeight)
    levelBar:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    levelBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -c.side, -c.top)
    local prevBtn = CreateFrame("Button", nil, levelBar, "UIPanelButtonTemplate")
    prevBtn:SetSize(24, 20)
    prevBtn:SetPoint("LEFT", levelBar, "LEFT", 0, 0)
    prevBtn:SetText("<")
    prevBtn:SetScript("OnClick", function() self:StepLevel(-1) end)
    local nextBtn = CreateFrame("Button", nil, levelBar, "UIPanelButtonTemplate")
    nextBtn:SetSize(24, 20)
    nextBtn:SetPoint("RIGHT", levelBar, "RIGHT", 0, 0)
    nextBtn:SetText(">")
    nextBtn:SetScript("OnClick", function() self:StepLevel(1) end)
    local levelText = levelBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
    levelText:SetPoint("RIGHT", nextBtn, "LEFT", -6, 0)
    levelText:SetJustifyH("CENTER")
    levelText:SetWordWrap(false)
    frame.levelBar = levelBar
    frame.levelText = levelText
    local viewport = CreateFrame("Frame", nil, frame)
    viewport:SetClipsChildren(true)
    viewport:EnableMouse(true)
    viewport:EnableMouseWheel(true)
    viewport:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    viewport:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    viewport.bg = viewport:CreateTexture(nil, "BACKGROUND")
    viewport.bg:SetAllPoints(viewport)
    viewport.bg:SetColorTexture(0.05, 0.05, 0.06, 0.85)
    local art = viewport:CreateTexture(nil, "ARTWORK")
    art:SetPoint("CENTER", viewport, "CENTER", 0, 0)
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

    viewport:SetScript("OnUpdate", function()
        local drag = self.view.drag
        if drag == nil then return end
        if not IsMouseButtonDown("LeftButton") then
            self.view.drag = nil

            return
        end

        local dx, dy = self:GetCursorOffset()
        if dx == nil then return end
        self.view.x = drag[3] + dx - drag[1]
        self.view.y = drag[4] + dy - drag[2]
        self:ApplyView()
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
    frame:SetScript("OnSizeChanged", function() self:LayoutArt() end)
    self.frame = frame
    self:RestorePosition()

    return frame
end

function MapWidget:Refresh()
    local frame = self.frame
    if frame == nil or not frame:IsShown() then return end
    local c = self.config
    local levels = self.levels
    if levels == nil or #levels == 0 then
        if frame.titleText then frame.titleText:SetText(AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET")) end
        frame.levelBar:Hide()
        frame.art:Hide()
        if self.pinSet ~= nil then self.pinSet:Hide() end

        return
    end

    local index = self.levelIndex or 1
    if index < 1 or index > #levels then index = 1 end
    self.levelIndex = index
    local info = levels[index]
    local title = self.instanceName or (info.inst and AzerothCompendium:GetInstanceName(info.inst)) or AzerothCompendium:Trans("LID_DUNGEONMAPWIDGET")
    if frame.titleText then frame.titleText:SetText(title) end
    local multi = #levels > 1
    frame.levelBar:SetShown(multi)
    frame.viewport:ClearAllPoints()
    frame.viewport:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -(c.top + (multi and c.headerHeight + 4 or 0)))
    frame.viewport:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    if multi then
        local wm = AzerothCompendium.WorldMap
        local label = wm and wm.GetLabel and wm.GetLabel(levels, info) or info.name or format("%d / %d", index, #levels)
        frame.levelText:SetText(label)
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
        self.instanceName = nil
        self.levels = nil
        self.closedFor = nil
        self.forced = false
        self:ResetView()
        self:UpdateVisibility()

        return
    end

    local changed = self.instanceID ~= instanceID
    self.instanceID = instanceID
    self.instanceName = name
    self.levels = self:GetLevels(instanceID)
    if changed then
        self.closedFor = nil
        self.forced = false
        self.levelIndex = self.selected[instanceID] or 1
        self:ResetView()
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

    local instanceID, name = self:GetCurrentInstance()
    if instanceID ~= nil then
        self.instanceID = instanceID
        self.instanceName = name
        self.levels = self:GetLevels(instanceID)
        self.levelIndex = self.selected[instanceID] or 1
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
