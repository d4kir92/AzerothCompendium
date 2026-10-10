local _, AzerothCompendium = ...
local Theme = {}
AzerothCompendium.Theme = Theme
Theme.records = {}
Theme.roots = {}
Theme.colors = {
    window = {0.07, 0.07, 0.08, 0.97},
    title = {0.11, 0.11, 0.12, 1},
    panel = {0.1, 0.1, 0.11, 0.95},
    control = {0.15, 0.15, 0.17, 1},
    hover = {0.22, 0.22, 0.25, 1},
    thumb = {0.34, 0.34, 0.38, 1},
    border = {0.24, 0.24, 0.27, 1},
    accent = {0.33, 0.82, 1, 1},
}

Theme.FLATBACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

Theme.WINDOWKEYS = {"NineSlice", "Bg", "TopTileStreaks", "TitleBg", "PortraitContainer", "portrait", "PortraitFrame", "TopLeftCorner", "TopRightCorner", "TopBorder", "LeftBorder", "RightBorder", "BottomBorder", "BotLeftCorner", "BotRightCorner", "BottomLeftCorner", "BottomRightCorner", "BtnCornerLeft", "BtnCornerRight", "ButtonBottomBorder", "fallbackBackground"}
Theme.INSETKEYS = {"NineSlice", "Bg", "InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight", "InsetBorderTopLeft", "InsetBorderTopRight", "InsetBorderBottomLeft", "InsetBorderBottomRight"}
Theme.BUTTONKEYS = {"Left", "Middle", "Right", "Background"}
Theme.TEXTUREGETTERS = {"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture"}

function AzerothCompendium:GetDesign()
    if self:GetConfig("DESIGN", "default") == "modern" then return "modern" end
    return "default"
end

function AzerothCompendium:SetDesign(value)
    self:SetConfig("DESIGN", value == "modern" and "modern" or "default")
    Theme:Refresh()
end

function Theme:IsModern()
    return AzerothCompendium:GetDesign() == "modern"
end

function Theme:Child(frame, key)
    local value = frame[key]
    if value == nil and type(frame.GetName) == "function" then
        local name = frame:GetName()
        if name then value = _G[name .. key] end
    end

    if type(value) == "table" and type(value.SetAlpha) == "function" then return value end
    return nil
end

function Theme:NewRecord(frame)
    local record = {
        frame = frame,
        hide = {},
        alpha = {},
        show = {},
    }

    frame.acoTheme = record
    tinsert(self.records, record)
    return record
end

function Theme:Hide(record, region)
    if region == nil or record.alpha[region] ~= nil then return end
    record.alpha[region] = region:GetAlpha()
    tinsert(record.hide, region)
end

function Theme:HideKeys(record, frame, keys)
    for _, key in ipairs(keys) do
        self:Hide(record, self:Child(frame, key))
    end
end

function Theme:HideButtonTextures(record, button)
    for _, getter in ipairs(self.TEXTUREGETTERS) do
        if type(button[getter]) == "function" then self:Hide(record, button[getter](button)) end
    end
end

function Theme:Solid(record, parent, layer, sublevel, color)
    local texture = parent:CreateTexture(nil, layer, nil, sublevel)
    texture:SetColorTexture(unpack(color))
    texture:Hide()
    tinsert(record.show, texture)
    return texture
end

function Theme:Border(record, parent, color, anchor)
    anchor = anchor or parent
    local lines = {}
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local line = self:Solid(record, parent, "BORDER", 7, color)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetHeight(1)
            line:SetPoint(edge .. "LEFT", anchor, edge .. "LEFT")
            line:SetPoint(edge .. "RIGHT", anchor, edge .. "RIGHT")
        else
            line:SetWidth(1)
            line:SetPoint("TOP" .. edge, anchor, "TOP" .. edge)
            line:SetPoint("BOTTOM" .. edge, anchor, "BOTTOM" .. edge)
        end

        tinsert(lines, line)
    end
    return lines
end

function Theme:SetColor(textures, color)
    for _, texture in ipairs(textures) do
        texture:SetColorTexture(unpack(color))
    end
end

function Theme:AddHover(frame, texture, isActive)
    frame:HookScript("OnEnter", function()
        if Theme:IsModern() and not (isActive and isActive()) then texture:SetColorTexture(unpack(Theme.colors.hover)) end
    end)

    frame:HookScript("OnLeave", function()
        if Theme:IsModern() and not (isActive and isActive()) then texture:SetColorTexture(unpack(Theme.colors.control)) end
    end)
end

function Theme:ApplyRecord(record, modern)
    for _, region in ipairs(record.hide) do
        region:SetAlpha(modern and 0 or record.alpha[region])
    end

    for _, region in ipairs(record.show) do
        region:SetShown(modern)
    end

    if record.update then record.update(modern) end
end

function Theme:SkinClose(record, close)
    self:HideButtonTextures(record, close)
    local label = close:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("CENTER", close, "CENTER", 0, 0)
    label:SetText("X")
    label:SetTextColor(0.85, 0.85, 0.85)
    label:Hide()
    tinsert(record.show, label)
    close:HookScript("OnEnter", function() label:SetTextColor(1, 0.35, 0.35) end)
    close:HookScript("OnLeave", function() label:SetTextColor(0.85, 0.85, 0.85) end)
end

function Theme:SkinWindow(frame)
    local record = self:NewRecord(frame)
    self:HideKeys(record, frame, self.WINDOWKEYS)
    local inset = self:Child(frame, "Inset")
    if inset then self:HideKeys(record, inset, self.INSETKEYS) end
    local background = self:Solid(record, frame, "BACKGROUND", -8, self.colors.window)
    background:SetAllPoints(frame)
    local title = self:Solid(record, frame, "BACKGROUND", -7, self.colors.title)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    title:SetHeight(24)
    local line = self:Solid(record, frame, "BACKGROUND", -6, self.colors.border)
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    line:SetHeight(1)
    self:Border(record, frame, self.colors.border)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -4)
    icon:SetTexture(AzerothCompendium:GetIcon())
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    tinsert(record.show, icon)
    local close = self:Child(frame, "CloseButton")
    if close then self:SkinClose(record, close) end
end

function Theme:SkinContent(frame)
    local record = self:NewRecord(frame)
    self:Hide(record, frame.contentBackground)
    self:Hide(record, frame.border)
    local background = self:Solid(record, frame, "BACKGROUND", -8, self.colors.panel)
    background:SetAllPoints(frame)
    self:Border(record, frame, self.colors.border)
end

function Theme:SkinTopTab(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, {"SquareBackground", "SquareBackgroundActive", "SquareBackgroundActiveGlow"})
    local parent = button.chrome or button
    local background = self:Solid(record, parent, "BACKGROUND", -8, self.colors.control)
    background:SetAllPoints(button)
    self:Border(record, parent, self.colors.border, button)
    local accent = self:Solid(record, parent, "OVERLAY", 7, self.colors.accent)
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
    accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    accent:SetHeight(2)
    local function IsSelected() return button.isSelected == true end
    record.buttonWidth, record.buttonHeight = button:GetSize()
    record.iconWidth, record.iconHeight = button.Icon:GetSize()
    record.update = function(modern)
        if modern and not record.unmasked then
            record.unmasked = pcall(button.Icon.RemoveMaskTexture, button.Icon, button.IconMask)
        elseif not modern and record.unmasked then
            record.unmasked = not pcall(button.Icon.AddMaskTexture, button.Icon, button.IconMask)
        end

        button.Icon:ClearAllPoints()
        if not modern then
            button:SetSize(record.buttonWidth, record.buttonHeight)
            button.Icon:SetSize(record.iconWidth, record.iconHeight)
            button.Icon:SetPoint("CENTER", button, "CENTER", button.questIcon and -2 or 0, button:GetIconYOffset(IsSelected()))
            return
        end

        local inner = (record.buttonHeight - 2) * (button.iconScale or 1)
        button:SetSize(record.buttonHeight, record.buttonHeight)
        button.Icon:SetSize(inner, inner)
        button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        accent:SetShown(IsSelected())
        background:SetColorTexture(unpack(IsSelected() and Theme.colors.hover or Theme.colors.control))
    end

    self:AddHover(button, background, IsSelected)
    hooksecurefunc(button, "SetTabSelected", function() if Theme:IsModern() then record.update(true) end end)
end

function Theme:SkinSideTab(tab)
    local record = self:NewRecord(tab)
    self:HideKeys(record, tab, {"Background", "SelectedTexture", "HighlightTexture"})
    local background = self:Solid(record, tab, "BACKGROUND", -8, self.colors.control)
    background:SetPoint("TOPLEFT", tab.Icon, "TOPLEFT", -1, 1)
    background:SetPoint("BOTTOMRIGHT", tab.Icon, "BOTTOMRIGHT", 1, -1)
    self:Border(record, tab, self.colors.border, background)
    local accent = self:Solid(record, tab, "OVERLAY", 7, self.colors.accent)
    accent:SetPoint("TOPLEFT", background, "TOPLEFT", 1, -1)
    accent:SetPoint("BOTTOMLEFT", background, "BOTTOMLEFT", 1, 1)
    accent:SetWidth(2)
    record.checked = tab.SelectedTexture ~= nil and tab.SelectedTexture:IsShown()
    record.update = function(modern)
        if tab.Mask and tab.Icon then
            if modern and not record.unmasked then
                record.unmasked = pcall(tab.Icon.RemoveMaskTexture, tab.Icon, tab.Mask)
            elseif not modern and record.unmasked then
                record.unmasked = not pcall(tab.Icon.AddMaskTexture, tab.Icon, tab.Mask)
            end
        end

        if not modern then
            if tab.UpdateIconInterior then tab:UpdateIconInterior() end
            return
        end

        tab.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        accent:SetShown(record.checked)
        background:SetColorTexture(unpack(record.checked and Theme.colors.hover or Theme.colors.control))
    end

    self:AddHover(tab, background, function() return record.checked end)
    if tab.UpdateIconInterior then hooksecurefunc(tab, "UpdateIconInterior", function() if Theme:IsModern() then tab.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end end) end
    hooksecurefunc(tab, "SetChecked", function(_, checked)
        record.checked = checked == true
        if Theme:IsModern() then record.update(true) end
    end)
end

function Theme:SkinCheck(check)
    local record = self:NewRecord(check)
    self:HideButtonTextures(record, check)
    local inset = max(2, floor((check:GetWidth() or 0) * 0.18 + 0.5))
    local background = self:Solid(record, check, "BACKGROUND", -8, self.colors.control)
    background:SetPoint("TOPLEFT", check, "TOPLEFT", inset, -inset)
    background:SetPoint("BOTTOMRIGHT", check, "BOTTOMRIGHT", -inset, inset)
    self:Border(record, check, self.colors.border, background)
    local checked = check:GetCheckedTexture()
    record.update = function(modern)
        if checked == nil then return end
        if modern then
            checked:SetVertexColor(unpack(Theme.colors.accent))
        else
            checked:SetVertexColor(1, 1, 1, 1)
        end
    end
end

function Theme:SkinEdit(box)
    local record = self:NewRecord(box)
    self:HideKeys(record, box, {"Left", "Middle", "Right"})
    local background = self:Solid(record, box, "BACKGROUND", -8, self.colors.control)
    background:SetPoint("TOPLEFT", box, "TOPLEFT", -5, 0)
    background:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 0, 0)
    self:Border(record, box, self.colors.border, background)
end

function Theme:SkinButton(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, self.BUTTONKEYS)
    self:HideButtonTextures(record, button)
    local background = self:Solid(record, button, "BACKGROUND", -8, self.colors.control)
    background:SetAllPoints(button)
    self:Border(record, button, self.colors.border)
    self:AddHover(button, background)
end

function Theme:SkinScrollBar(bar)
    local record = self:NewRecord(bar)
    local track = bar.Track
    local thumb = track.Thumb or bar.Thumb
    for _, region in ipairs({track:GetRegions()}) do
        if region:GetObjectType() == "Texture" then self:Hide(record, region) end
    end

    local rail = self:Solid(record, track, "BACKGROUND", -8, self.colors.control)
    rail:SetPoint("TOP", track, "TOP", 0, 0)
    rail:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
    rail:SetWidth(4)
    if thumb then
        for _, region in ipairs({thumb:GetRegions()}) do
            if region:GetObjectType() == "Texture" then self:Hide(record, region) end
        end

        local fill = self:Solid(record, thumb, "ARTWORK", 0, self.colors.thumb)
        fill:SetPoint("TOP", thumb, "TOP", 0, 0)
        fill:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
        fill:SetWidth(6)
        if thumb.HookScript then
            thumb:HookScript("OnEnter", function() fill:SetColorTexture(unpack(Theme.colors.accent)) end)
            thumb:HookScript("OnLeave", function() fill:SetColorTexture(unpack(Theme.colors.thumb)) end)
        end
    end

    self:Hide(record, bar.Back)
    self:Hide(record, bar.Forward)
end

function Theme:IsChromeBackdrop(frame)
    local ok, backdrop = pcall(frame.GetBackdrop, frame)
    if not ok or type(backdrop) ~= "table" or type(backdrop.edgeFile) ~= "string" then return false end
    local edge = strlower(backdrop.edgeFile)
    return edge:find("tooltip", 1, true) ~= nil or edge:find("dialogframe", 1, true) ~= nil
end

function Theme:SkinBackdrop(frame)
    local record = self:NewRecord(frame)
    local original = frame:GetBackdrop()
    local color = {frame:GetBackdropColor()}
    local borderColor = {frame:GetBackdropBorderColor()}
    record.update = function(modern)
        if modern then
            frame:SetBackdrop(Theme.FLATBACKDROP)
            frame:SetBackdropColor(unpack(Theme.colors.window))
        else
            frame:SetBackdrop(original)
            frame:SetBackdropColor(unpack(color))
        end

        frame:SetBackdropBorderColor(unpack(borderColor))
    end
end

function Theme:Detect(frame)
    if frame.acoTheme ~= nil then return end
    local kind = frame:GetObjectType()
    if frame.contentBackground and frame.border then return self:SkinContent(frame) end
    if frame.chrome and frame.SquareBackground and frame.SetTabSelected then return self:SkinTopTab(frame) end
    if kind ~= "CheckButton" and frame.SelectedTexture and frame.Background and frame.Icon and frame.SetChecked then return self:SkinSideTab(frame) end
    if kind == "CheckButton" and frame.GetCheckedTexture and frame:GetCheckedTexture() then return self:SkinCheck(frame) end
    if kind == "EditBox" and self:Child(frame, "Left") and self:Child(frame, "Middle") and self:Child(frame, "Right") then return self:SkinEdit(frame) end
    if kind == "DropdownButton" and frame.Background then return self:SkinButton(frame) end
    if kind == "Button" and self:Child(frame, "Left") and self:Child(frame, "Middle") and self:Child(frame, "Right") then return self:SkinButton(frame) end
    if frame.Track and frame.Back and frame.Forward then return self:SkinScrollBar(frame) end
    if frame.GetBackdrop and frame.SetBackdrop and self:IsChromeBackdrop(frame) then return self:SkinBackdrop(frame) end
end

function Theme:Scan(frame)
    if frame.IsForbidden and frame:IsForbidden() then return end
    self:Detect(frame)
    for _, child in ipairs({frame:GetChildren()}) do
        self:Scan(child)
    end
end

function Theme:Refresh()
    local modern = self:IsModern()
    if modern then
        for _, root in ipairs(self.roots) do
            if root.acoTheme == nil then self:SkinWindow(root) end
            self:Scan(root)
        end
    end

    for _, record in ipairs(self.records) do
        self:ApplyRecord(record, modern)
    end
end

function Theme:QueueRefresh()
    if self.queued then return end
    self.queued = true
    C_Timer.After(0, function()
        Theme.queued = false
        Theme:Refresh()
    end)
end

function Theme:RegisterRoot(frame)
    tinsert(self.roots, frame)
    local watcher = CreateFrame("Frame", nil, frame)
    watcher.elapsed = 0
    watcher:SetScript("OnShow", function() Theme:QueueRefresh() end)
    watcher:SetScript("OnUpdate", function(sel, delta)
        sel.elapsed = sel.elapsed + delta
        if sel.elapsed < 0.5 then return end
        sel.elapsed = 0
        if not Theme:IsModern() then return end
        local count = frame:GetNumChildren()
        if count == sel.count then return end
        sel.count = count
        Theme:QueueRefresh()
    end)

    if not self.hooked and type(AzerothCompendium.RefreshCompendium) == "function" then
        self.hooked = true
        hooksecurefunc(AzerothCompendium, "RefreshCompendium", function() if Theme:IsModern() then Theme:QueueRefresh() end end)
    end

    self:QueueRefresh()
end
