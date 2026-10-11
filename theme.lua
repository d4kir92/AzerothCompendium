local _, AzerothCompendium = ...
local Theme = {}
AzerothCompendium.Theme = Theme
Theme.records = {}
Theme.roots = {}
Theme.MEDIA = "Interface\\AddOns\\AzerothCompendium\\media\\ui\\modern\\"
Theme.WHITE = "Interface\\Buttons\\WHITE8X8"
Theme.colors = {
    window = {0.067, 0.071, 0.082, 1},
    edge = {0.16, 0.17, 0.19, 1},
    panel = {0.094, 0.098, 0.114, 1},
    control = {0.125, 0.13, 0.15, 1},
    hover = {0.17, 0.18, 0.205, 1},
    selected = {0.2, 0.21, 0.245, 1},
    thumb = {0.3, 0.31, 0.35, 1},
    border = {0.22, 0.23, 0.26, 1},
    accent = {0.36, 0.78, 0.98, 1},
    accentDark = {0.13, 0.36, 0.48, 1},
    title = {1, 0.82, 0.2, 1},
    muted = {0.55, 0.56, 0.6, 1},
}

Theme.radius = {
    window = 8,
    panel = 6,
    control = 5,
    tab = 6,
}

Theme.FLATBACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

Theme.CORNERS = {{"TOPLEFT", 0, 0.5, 0, 0.5}, {"TOPRIGHT", 0.5, 1, 0, 0.5}, {"BOTTOMLEFT", 0, 0.5, 0.5, 1}, {"BOTTOMRIGHT", 0.5, 1, 0.5, 1}}
Theme.WINDOWKEYS = {"NineSlice", "Bg", "TopTileStreaks", "TitleBg", "PortraitContainer", "portrait", "PortraitFrame", "TopLeftCorner", "TopRightCorner", "TopBorder", "LeftBorder", "RightBorder", "BottomBorder", "BotLeftCorner", "BotRightCorner", "BottomLeftCorner", "BottomRightCorner", "BtnCornerLeft", "BtnCornerRight", "ButtonBottomBorder", "fallbackBackground"}
Theme.INSETKEYS = {"NineSlice", "Bg", "InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight", "InsetBorderTopLeft", "InsetBorderTopRight", "InsetBorderBottomLeft", "InsetBorderBottomRight"}
Theme.BUTTONKEYS = {"Left", "Middle", "Right", "Center", "Background"}
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

function Theme:SavePoints(region)
    local points = {}
    for index = 1, region:GetNumPoints() do
        points[index] = {region:GetPoint(index)}
    end
    return points
end

function Theme:RestorePoints(region, points)
    region:ClearAllPoints()
    for _, point in ipairs(points or {}) do
        region:SetPoint(unpack(point))
    end
end

function Theme:Piece(record, parent, layer, sublevel, file)
    local texture = parent:CreateTexture(nil, layer, nil, sublevel)
    texture:SetTexture(file)
    texture:Hide()
    tinsert(record.show, texture)
    return texture
end

function Theme:Anchor(parent)
    local anchor = parent:CreateTexture(nil, "BACKGROUND")
    anchor:SetSize(1, 1)
    return anchor
end

function Theme:Round(record, parent, layer, sublevel, color, radius, anchor, inset)
    anchor = anchor or parent
    inset = inset or 0
    local shape = {}
    local corners = {}
    for _, def in ipairs(self.CORNERS) do
        local corner = self:Piece(record, parent, layer, sublevel, self.MEDIA .. "circle")
        corner:SetSize(radius, radius)
        corner:SetTexCoord(def[2], def[3], def[4], def[5])
        corner:SetPoint(def[1], anchor, def[1], def[1]:find("LEFT") and inset or -inset, def[1]:find("TOP") and -inset or inset)
        corners[def[1]] = corner
        tinsert(shape, corner)
    end

    local top = self:Piece(record, parent, layer, sublevel, self.WHITE)
    top:SetPoint("TOPLEFT", corners.TOPLEFT, "TOPRIGHT")
    top:SetPoint("BOTTOMRIGHT", corners.TOPRIGHT, "BOTTOMLEFT")
    local bottom = self:Piece(record, parent, layer, sublevel, self.WHITE)
    bottom:SetPoint("TOPLEFT", corners.BOTTOMLEFT, "TOPRIGHT")
    bottom:SetPoint("BOTTOMRIGHT", corners.BOTTOMRIGHT, "BOTTOMLEFT")
    local middle = self:Piece(record, parent, layer, sublevel, self.WHITE)
    middle:SetPoint("TOPLEFT", corners.TOPLEFT, "BOTTOMLEFT")
    middle:SetPoint("BOTTOMRIGHT", corners.BOTTOMRIGHT, "TOPRIGHT")
    tinsert(shape, top)
    tinsert(shape, bottom)
    tinsert(shape, middle)
    self:Paint(shape, color)
    return shape
end

function Theme:Paint(shape, color)
    for _, piece in ipairs(shape) do
        piece:SetVertexColor(unpack(color))
    end
end

function Theme:ShowShape(shape, shown)
    for _, piece in ipairs(shape) do
        piece:SetShown(shown)
    end
end

function Theme:Bar(record, parent, target, side)
    local anchor = self:Anchor(parent)
    if side == "BOTTOM" then
        anchor:SetHeight(3)
        anchor:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 7, -1)
        anchor:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", -7, -1)
        return self:Round(record, parent, "OVERLAY", 7, self.colors.accent, 1.5, anchor)
    end

    anchor:SetWidth(3)
    if side == "LEFT" then
        anchor:SetPoint("TOPRIGHT", target, "TOPLEFT", -4, -8)
        anchor:SetPoint("BOTTOMRIGHT", target, "BOTTOMLEFT", -4, 8)
    else
        anchor:SetPoint("TOPLEFT", target, "TOPRIGHT", 4, -8)
        anchor:SetPoint("BOTTOMLEFT", target, "BOTTOMRIGHT", 4, 8)
    end
    return self:Round(record, parent, "OVERLAY", 7, self.colors.accent, 1.5, anchor)
end

function Theme:SwapMask(record, icon, original, modern)
    if record.mask == nil and modern then
        local holder = icon:GetParent()
        local ok, mask = pcall(holder.CreateMaskTexture, holder)
        if ok and mask then
            mask:SetTexture(self.MEDIA .. "roundmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(icon)
            record.mask = mask
        else
            record.mask = false
        end
    end

    if record.masked == modern then return end
    record.masked = modern
    if original then pcall(modern and icon.RemoveMaskTexture or icon.AddMaskTexture, icon, original) end
    if record.mask then pcall(modern and icon.AddMaskTexture or icon.RemoveMaskTexture, icon, record.mask) end
end

function Theme:AddHover(frame, shape, isActive, idle)
    frame:HookScript("OnEnter", function()
        if Theme:IsModern() and not (isActive and isActive()) then Theme:Paint(shape, Theme.colors.hover) end
    end)

    frame:HookScript("OnLeave", function()
        if Theme:IsModern() and not (isActive and isActive()) then Theme:Paint(shape, idle or Theme.colors.control) end
    end)
end

function Theme:HideFrames(record, frame, keys)
    record.frames = record.frames or {}
    record.shown = record.shown or {}
    for _, key in ipairs(keys) do
        local region = self:Child(frame, key)
        if region and region.IsObjectType and region:IsObjectType("Frame") and record.shown[region] == nil then
            record.shown[region] = region:IsShown()
            tinsert(record.frames, region)
        end
    end
end

function Theme:ApplyRecord(record, modern)
    for _, region in ipairs(record.hide) do
        region:SetAlpha(modern and 0 or record.alpha[region])
    end

    for _, region in ipairs(record.frames or {}) do
        region:SetShown(not modern and record.shown[region])
    end

    for _, region in ipairs(record.show) do
        region:SetShown(modern)
    end

    if record.update then record.update(modern) end
end

function Theme:UpdateFrame(frame)
    local record = frame and frame.acoTheme
    if record and record.update and self:IsModern() then record.update(true) end
end

function Theme:SkinClose(record, close)
    self:HideButtonTextures(record, close)
    local hover = self:Round(record, close, "BACKGROUND", -8, self.colors.hover, self.radius.control)
    self:ShowShape(hover, false)
    local cross = self:Piece(record, close, "OVERLAY", 0, self.MEDIA .. "close")
    cross:SetSize(20, 20)
    cross:SetPoint("CENTER", close, "CENTER", 0, 0)
    cross:SetVertexColor(unpack(self.colors.muted))
    close:HookScript("OnEnter", function()
        if not Theme:IsModern() then return end
        Theme:ShowShape(hover, true)
        cross:SetVertexColor(1, 0.4, 0.4)
    end)
    close:HookScript("OnLeave", function()
        if not Theme:IsModern() then return end
        Theme:ShowShape(hover, false)
        cross:SetVertexColor(unpack(Theme.colors.muted))
    end)
    return hover
end

function Theme:GetTitleText(frame)
    if type(frame.GetTitleText) == "function" then
        local ok, title = pcall(frame.GetTitleText, frame)
        if ok and title then return title end
    end

    if type(frame.TitleContainer) == "table" and frame.TitleContainer.TitleText then return frame.TitleContainer.TitleText end
    if frame.TitleText then return frame.TitleText end
    local name = frame:GetName()
    return name and _G[name .. "TitleText"] or nil
end

function Theme:SkinWindow(frame)
    local record = self:NewRecord(frame)
    self:HideKeys(record, frame, self.WINDOWKEYS)
    self:HideFrames(record, frame, self.WINDOWKEYS)
    local inset = self:Child(frame, "Inset")
    if inset then
        self:HideKeys(record, inset, self.INSETKEYS)
        self:HideFrames(record, inset, self.INSETKEYS)
    end
    self:Round(record, frame, "BACKGROUND", -8, self.colors.edge, self.radius.window)
    self:Round(record, frame, "BACKGROUND", -7, self.colors.window, self.radius.window - 1, frame, 1)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    icon:SetTexture(AzerothCompendium:GetIcon())
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    tinsert(record.show, icon)
    local title = self:GetTitleText(frame)
    local close = self:Child(frame, "CloseButton")
    local closeHover = close and self:SkinClose(record, close)
    if title then
        record.titlePoints = self:SavePoints(title)
        record.titleColor = {title:GetTextColor()}
    end

    if close then
        record.closePoints = self:SavePoints(close)
        record.closeWidth, record.closeHeight = close:GetSize()
    end

    record.update = function(modern)
        if title then
            if modern then
                title:ClearAllPoints()
                title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                title:SetTextColor(unpack(Theme.colors.title))
            else
                Theme:RestorePoints(title, record.titlePoints)
                title:SetTextColor(unpack(record.titleColor))
            end
        end

        if close then
            if modern then
                Theme:ShowShape(closeHover, false)
                close:ClearAllPoints()
                close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
                close:SetSize(24, 24)
            else
                Theme:RestorePoints(close, record.closePoints)
                close:SetSize(record.closeWidth, record.closeHeight)
            end
        end
    end
end

function Theme:SkinContent(frame)
    local record = self:NewRecord(frame)
    self:Hide(record, frame.contentBackground)
    self:Hide(record, frame.border)
    self:Round(record, frame, "BACKGROUND", -8, self.colors.panel, self.radius.panel)
end

function Theme:SkinTopTab(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, {"SquareBackground", "SquareBackgroundActive", "SquareBackgroundActiveGlow"})
    local parent = button.chrome or button
    local background = self:Round(record, parent, "BACKGROUND", -8, self.colors.control, self.radius.tab, button)
    local accent = self:Bar(record, parent, button, "BOTTOM")
    local function IsSelected() return button.isSelected == true end
    record.buttonWidth, record.buttonHeight = button:GetSize()
    record.iconWidth, record.iconHeight = button.Icon:GetSize()
    record.masked = false
    record.chromeLevel = parent:GetFrameLevel()
    record.update = function(modern)
        Theme:SwapMask(record, button.Icon, button.IconMask, modern)
        button.Icon:ClearAllPoints()
        if parent ~= button then parent:SetFrameLevel(modern and max(record.chromeLevel, button:GetFrameLevel() - 1) or record.chromeLevel) end
        if not modern then
            button:SetSize(record.buttonWidth, record.buttonHeight)
            button.Icon:SetSize(record.iconWidth, record.iconHeight)
            button.Icon:SetPoint("CENTER", button, "CENTER", button.questIcon and -2 or 0, button:GetIconYOffset(IsSelected()))
            return
        end

        local inner = 28 * (button.iconScale or 1)
        button:SetSize(32, 32)
        button.Icon:SetSize(inner, inner)
        button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        Theme:ShowShape(accent, IsSelected())
        Theme:Paint(background, IsSelected() and Theme.colors.selected or Theme.colors.control)
    end

    self:AddHover(button, background, IsSelected)
    hooksecurefunc(button, "SetTabSelected", function() if Theme:IsModern() then record.update(true) end end)
end

function Theme:SkinSideTab(tab)
    local record = self:NewRecord(tab)
    self:HideKeys(record, tab, {"Background", "SelectedTexture", "HighlightTexture"})
    local holder = self:Anchor(tab)
    holder:SetPoint("TOPLEFT", tab.Icon, "TOPLEFT", -2, 2)
    holder:SetPoint("BOTTOMRIGHT", tab.Icon, "BOTTOMRIGHT", 2, -2)
    local background = self:Round(record, tab, "BACKGROUND", -8, self.colors.control, self.radius.tab, holder)
    local accent = self:Bar(record, tab, holder, "RIGHT")
    record.checked = tab.SelectedTexture ~= nil and tab.SelectedTexture:IsShown()
    record.tabWidth, record.tabHeight = tab:GetSize()
    record.iconWidth, record.iconHeight = tab.Icon:GetSize()
    record.iconPoints = self:SavePoints(tab.Icon)
    record.masked = false
    local function Center()
        tab.Icon:ClearAllPoints()
        tab.Icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tab.Icon:SetSize(40, 40)
        tab.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    record.update = function(modern)
        Theme:SwapMask(record, tab.Icon, tab.Mask, modern)
        if not modern then
            tab:SetSize(record.tabWidth, record.tabHeight)
            tab.Icon:SetSize(record.iconWidth, record.iconHeight)
            Theme:RestorePoints(tab.Icon, record.iconPoints)
            if tab.UpdateIconInterior then tab:UpdateIconInterior() end
            return
        end

        tab:SetSize(48, 48)
        Center()
        Theme:ShowShape(accent, record.checked)
        Theme:Paint(background, record.checked and Theme.colors.selected or Theme.colors.control)
    end

    self:AddHover(tab, background, function() return record.checked end)
    if tab.UpdateIconInterior then hooksecurefunc(tab, "UpdateIconInterior", function() if Theme:IsModern() then Center() end end) end
    tab:HookScript("OnMouseDown", function() if Theme:IsModern() then Center() end end)
    tab:HookScript("OnMouseUp", function() if Theme:IsModern() then Center() end end)
    hooksecurefunc(tab, "SetChecked", function(_, checked)
        record.checked = checked == true
        if Theme:IsModern() then record.update(true) end
    end)
end

function Theme:SkinCheck(check)
    local record = self:NewRecord(check)
    self:HideButtonTextures(record, check)
    local inset = max(2, floor((check:GetWidth() or 0) * 0.18 + 0.5))
    local holder = self:Anchor(check)
    holder:SetPoint("TOPLEFT", check, "TOPLEFT", inset, -inset)
    holder:SetPoint("BOTTOMRIGHT", check, "BOTTOMRIGHT", -inset, inset)
    local border = self:Round(record, check, "BACKGROUND", -8, self.colors.border, 4, holder)
    local background = self:Round(record, check, "BACKGROUND", -7, self.colors.control, 3, holder, 1)
    self:Hide(record, check:GetCheckedTexture())
    if check.GetDisabledCheckedTexture then self:Hide(record, check:GetDisabledCheckedTexture()) end
    local mark = self:Piece(record, check, "OVERLAY", 7, self.MEDIA .. "check")
    mark:SetPoint("TOPLEFT", holder, "TOPLEFT", -1, 1)
    mark:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 1, -1)
    record.update = function(modern)
        if not modern then return end
        local isChecked = check:GetChecked() == true
        local enabled = not check.IsEnabled or check:IsEnabled()
        mark:SetShown(isChecked)
        mark:SetVertexColor(Theme.colors.accent[1], Theme.colors.accent[2], Theme.colors.accent[3], enabled and 1 or 0.45)
        Theme:Paint(border, isChecked and Theme.colors.accentDark or Theme.colors.border)
        Theme:Paint(background, isChecked and Theme.colors.accentDark or Theme.colors.control)
    end

    hooksecurefunc(check, "SetChecked", function() if Theme:IsModern() then record.update(true) end end)
    check:HookScript("OnClick", function() if Theme:IsModern() then record.update(true) end end)
end

function Theme:GetPlaceholder(box)
    local text = type(box.acoPlaceholder) == "function" and box.acoPlaceholder() or box.acoPlaceholder or ""
    return (text:gsub("[:%s]+$", ""))
end

function Theme:SkinEdit(box)
    local record = self:NewRecord(box)
    self:HideKeys(record, box, {"Left", "Middle", "Right"})
    local holder = self:Anchor(box)
    holder:SetPoint("TOPLEFT", box, "TOPLEFT", box.acoSearch and 0 or -5, 0)
    holder:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 0, 0)
    self:Round(record, box, "BACKGROUND", -8, self.colors.control, self.radius.control, holder)
    if not box.acoSearch then return end
    local icon = box:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", box, "LEFT", 9, -1)
    icon:SetVertexColor(0.75, 0.76, 0.8)
    icon:Hide()
    tinsert(record.show, icon)
    local placeholder = box:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", icon, "RIGHT", 7, 1)
    placeholder:SetPoint("RIGHT", box, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:Hide()
    record.insets = {box:GetTextInsets()}
    local function UpdatePlaceholder()
        local shown = Theme:IsModern() and (box:GetText() or "") == "" and not box:HasFocus()
        placeholder:SetText(Theme:GetPlaceholder(box))
        placeholder:SetShown(shown)
    end

    record.update = function(modern)
        if modern then
            box:SetTextInsets(30, 8, 0, 0)
        else
            box:SetTextInsets(unpack(record.insets))
        end

        UpdatePlaceholder()
    end

    box:HookScript("OnTextChanged", UpdatePlaceholder)
    box:HookScript("OnEditFocusGained", UpdatePlaceholder)
    box:HookScript("OnEditFocusLost", UpdatePlaceholder)
end

function Theme:SkinButton(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, self.BUTTONKEYS)
    self:HideButtonTextures(record, button)
    local background = self:Round(record, button, "BACKGROUND", -8, self.colors.control, self.radius.control)
    self:AddHover(button, background)
end

function Theme:SkinDropdown(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, self.BUTTONKEYS)
    self:HideKeys(record, button, {"Arrow"})
    self:HideButtonTextures(record, button)
    local background = self:Round(record, button, "BACKGROUND", -8, self.colors.control, self.radius.control)
    local chevron = self:Piece(record, button, "OVERLAY", 0, self.MEDIA .. "chevron")
    chevron:SetSize(16, 16)
    chevron:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    chevron:SetVertexColor(unpack(self.colors.muted))
    local text = button.Text or (button.GetFontString and button:GetFontString())
    if text then
        record.textColor = {text:GetTextColor()}
        record.textPoints = self:SavePoints(text)
    end

    record.update = function(modern)
        if text == nil then return end
        if modern then
            text:SetTextColor(0.9, 0.9, 0.92)
            text:ClearAllPoints()
            text:SetPoint("LEFT", button, "LEFT", 12, 0)
            text:SetPoint("RIGHT", chevron, "LEFT", -6, 0)
            text:SetJustifyH("LEFT")
        else
            text:SetTextColor(unpack(record.textColor))
            Theme:RestorePoints(text, record.textPoints)
        end
    end

    self:AddHover(button, background)
    button:HookScript("OnEnter", function() if Theme:IsModern() and text then text:SetTextColor(1, 1, 1) end end)
    button:HookScript("OnLeave", function() if Theme:IsModern() and text then text:SetTextColor(0.9, 0.9, 0.92) end end)
end

function Theme:SkinSegment(button)
    local record = self:NewRecord(button)
    self:HideKeys(record, button, self.BUTTONKEYS)
    self:HideKeys(record, button, {"Arrow"})
    self:HideButtonTextures(record, button)
    local pill = self:Round(record, button, "BACKGROUND", -6, self.colors.selected, self.radius.control)
    local hovered = false
    local function Selected() return button.acoSegment() == true end
    record.update = function(modern)
        if not modern then return end
        local selected = Selected()
        Theme:ShowShape(pill, selected or hovered)
        Theme:Paint(pill, selected and Theme.colors.selected or Theme.colors.hover)
    end

    button:HookScript("OnEnter", function()
        hovered = true
        if Theme:IsModern() then record.update(true) end
    end)

    button:HookScript("OnLeave", function()
        hovered = false
        if Theme:IsModern() then record.update(true) end
    end)
end

function Theme:SkinSegmentGroup(frame)
    local record = self:NewRecord(frame)
    self:Round(record, frame, "BACKGROUND", -8, self.colors.panel, self.radius.panel)
end

function Theme:SkinScrollBar(bar)
    local record = self:NewRecord(bar)
    local track = bar.Track
    local thumb = track.Thumb or bar.Thumb
    for _, region in ipairs({track:GetRegions()}) do
        if region:GetObjectType() == "Texture" then self:Hide(record, region) end
    end

    if thumb then
        for _, region in ipairs({thumb:GetRegions()}) do
            if region:GetObjectType() == "Texture" then self:Hide(record, region) end
        end

        local holder = self:Anchor(thumb)
        holder:SetWidth(6)
        holder:SetPoint("TOP", thumb, "TOP", 0, 0)
        holder:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
        local fill = self:Round(record, thumb, "ARTWORK", 0, self.colors.thumb, 3, holder)
        if thumb.HookScript then
            thumb:HookScript("OnEnter", function() Theme:Paint(fill, Theme.colors.accent) end)
            thumb:HookScript("OnLeave", function() Theme:Paint(fill, Theme.colors.thumb) end)
        end
    end

    self:Hide(record, bar.Back)
    self:Hide(record, bar.Forward)
end

function Theme:HideTextures(record, frame, keep)
    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= keep then self:Hide(record, region) end
    end
end

function Theme:Chevron(record, parent, rotation)
    local chevron = self:Piece(record, parent, "OVERLAY", 0, self.MEDIA .. "chevron")
    chevron:SetSize(14, 14)
    chevron:SetPoint("CENTER", parent, "CENTER", 0, 0)
    chevron:SetVertexColor(unpack(self.colors.muted))
    if rotation ~= 0 then pcall(chevron.SetRotation, chevron, rotation) end
    return chevron
end

function Theme:SkinStepper(button, rotation)
    if button == nil or button.acoTheme ~= nil then return end
    local record = self:NewRecord(button)
    self:HideTextures(record, button)
    self:HideButtonTextures(record, button)
    local background = self:Round(record, button, "BACKGROUND", -8, self.colors.control, self.radius.control)
    local chevron = self:Chevron(record, button, rotation)
    record.update = function(modern) if modern then chevron:SetAlpha(button:IsEnabled() and 1 or 0.35) end end
    button:HookScript("OnEnable", function() if Theme:IsModern() then record.update(true) end end)
    button:HookScript("OnDisable", function() if Theme:IsModern() then record.update(true) end end)
    self:AddHover(button, background)
    button:HookScript("OnEnter", function() if Theme:IsModern() then chevron:SetVertexColor(1, 1, 1) end end)
    button:HookScript("OnLeave", function() if Theme:IsModern() then chevron:SetVertexColor(unpack(Theme.colors.muted)) end end)
end

function Theme:SkinSteppers(frame, back, forward)
    self:NewRecord(frame)
    self:SkinStepper(back, -math.pi / 2)
    self:SkinStepper(forward, math.pi / 2)
end

function Theme:SkinSlider(frame)
    local slider = frame.Slider or frame
    self:SkinSteppers(frame, frame.Back, frame.Forward)
    local record = slider.acoTheme or self:NewRecord(slider)
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    self:HideTextures(record, slider)
    self:HideKeys(record, slider, {"Left", "Middle", "Right"})
    local track = self:Anchor(slider)
    track:SetHeight(4)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    self:Round(record, slider, "BACKGROUND", -8, self.colors.selected, 2, track)
    if thumb == nil then return end
    local fill = self:Anchor(slider)
    fill:SetHeight(4)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
    self:Round(record, slider, "BACKGROUND", -7, self.colors.accentDark, 2, fill)
    local handle = self:Anchor(slider)
    handle:SetSize(14, 14)
    handle:SetPoint("CENTER", thumb, "CENTER", 0, 0)
    self:Round(record, slider, "ARTWORK", 7, self.colors.accent, 7, handle)
end

function Theme:IsTexture(texture, file)
    local current = texture:GetTexture()
    if type(current) == "string" then return strlower(current):find(strlower(file:match("[^\\]+$")), 1, true) ~= nil end
    self.sample = self.sample or UIParent:CreateTexture(nil, "BACKGROUND")
    self.sample:SetTexture(file)
    return current ~= nil and current == self.sample:GetTexture()
end

function Theme:SkinCategory(header)
    local record = self:NewRecord(header)
    self:Hide(record, header.Icon)
    for _, region in ipairs({header:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "HIGHLIGHT" then self:Hide(record, region) end
    end

    local background = self:Round(record, header, "BACKGROUND", -8, self.colors.control, self.radius.control)
    local chevron = self:Piece(record, header, "OVERLAY", 7, self.MEDIA .. "chevron")
    chevron:SetSize(16, 16)
    chevron:SetPoint("CENTER", header.Icon, "CENTER", 0, 0)
    chevron:SetVertexColor(unpack(self.colors.muted))
    local collapsed = self:IsTexture(header.Icon, "Interface\\Buttons\\UI-PlusButton-Up")
    record.iconPoints = self:SavePoints(header.Icon)
    record.update = function(modern)
        if modern then
            header.Icon:ClearAllPoints()
            header.Icon:SetPoint("LEFT", header, "LEFT", 10, 0)
        else
            Theme:RestorePoints(header.Icon, record.iconPoints)
        end

        if modern then pcall(chevron.SetRotation, chevron, collapsed and math.pi / 2 or 0) end
    end

    self:AddHover(header, background)
    hooksecurefunc(header.Icon, "SetTexture", function(_, file)
        collapsed = type(file) == "string" and strlower(file):find("plus", 1, true) ~= nil
        if Theme:IsModern() then record.update(true) end
    end)
end

function Theme:SetCollapseIcon(texture, collapsed)
    if self:IsModern() then
        texture:SetTexture(self.MEDIA .. "chevron")
        texture:SetVertexColor(unpack(self.colors.muted))
        pcall(texture.SetRotation, texture, collapsed and math.pi / 2 or 0)
    else
        texture:SetTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        texture:SetVertexColor(1, 1, 1)
        pcall(texture.SetRotation, texture, 0)
    end
end

function Theme:IsCollapseButton(button)
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal == nil then return false end
    return self:IsTexture(normal, "Interface\\Buttons\\UI-PlusButton-Up") or self:IsTexture(normal, "Interface\\Buttons\\UI-MinusButton-Up")
end

function Theme:SkinCollapseButton(button)
    local record = self:NewRecord(button)
    local chevron = self:Piece(record, button, "OVERLAY", 7, self.MEDIA .. "chevron")
    chevron:SetSize(16, 16)
    chevron:SetPoint("CENTER", button, "CENTER", 0, 0)
    chevron:SetVertexColor(unpack(self.colors.muted))
    local collapsed = self:IsTexture(button:GetNormalTexture(), "Interface\\Buttons\\UI-PlusButton-Up")
    local function HideArt()
        for _, getter in ipairs(Theme.TEXTUREGETTERS) do
            local texture = button[getter] and button[getter](button)
            if texture then
                if record.alpha[texture] == nil then Theme:Hide(record, texture) end
                texture:SetAlpha(0)
            end
        end
    end

    record.update = function(modern)
        if not modern then return end
        HideArt()
        pcall(chevron.SetRotation, chevron, collapsed and math.pi / 2 or 0)
    end

    hooksecurefunc(button, "SetNormalTexture", function(_, file)
        collapsed = type(file) == "string" and strlower(file):find("plus", 1, true) ~= nil
        if Theme:IsModern() then record.update(true) end
    end)
    button:HookScript("OnEnter", function() if Theme:IsModern() then chevron:SetVertexColor(1, 1, 1) end end)
    button:HookScript("OnLeave", function() if Theme:IsModern() then chevron:SetVertexColor(unpack(Theme.colors.muted)) end end)
end

function Theme:SkinLegacyScrollBar(bar)
    local record = self:NewRecord(bar)
    local thumb = bar:GetThumbTexture()
    self:HideTextures(record, bar)
    for _, key in ipairs({"ScrollUpButton", "ScrollDownButton"}) do
        local button = self:Child(bar, key)
        if button then
            self:HideTextures(record, button)
            self:HideButtonTextures(record, button)
        end
    end

    if thumb == nil then return end
    local holder = self:Anchor(bar)
    holder:SetWidth(6)
    holder:SetPoint("TOP", thumb, "TOP", 0, -2)
    holder:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 2)
    self:Round(record, bar, "ARTWORK", 7, self.colors.thumb, 3, holder)
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
    self:Round(record, frame, "BACKGROUND", -8, self.colors.control, self.radius.control)
    record.update = function(modern)
        if modern then
            frame:SetBackdrop(nil)
        else
            frame:SetBackdrop(original)
            frame:SetBackdropColor(unpack(color))
            frame:SetBackdropBorderColor(unpack(borderColor))
        end
    end
end

function Theme:Detect(frame)
    if frame.acoTheme ~= nil then return end
    local kind = frame:GetObjectType()
    if type(frame.acoSegment) == "function" then return self:SkinSegment(frame) end
    if frame.acoSegmentGroup then return self:SkinSegmentGroup(frame) end
    if frame.contentBackground and frame.border then return self:SkinContent(frame) end
    if frame.chrome and frame.SquareBackground and frame.SetTabSelected then return self:SkinTopTab(frame) end
    if kind ~= "CheckButton" and frame.SelectedTexture and frame.Background and frame.Icon and frame.SetChecked then return self:SkinSideTab(frame) end
    if kind == "CheckButton" and frame.GetCheckedTexture and frame:GetCheckedTexture() then return self:SkinCheck(frame) end
    if kind == "EditBox" and self:Child(frame, "Left") and self:Child(frame, "Middle") and self:Child(frame, "Right") then return self:SkinEdit(frame) end
    if frame.Arrow and frame.Background and (frame.Text or frame.SetupMenu) then return self:SkinDropdown(frame) end
    if kind == "DropdownButton" and frame.Background then return self:SkinDropdown(frame) end
    if kind == "Button" and self:Child(frame, "Left") and self:Child(frame, "Right") and (self:Child(frame, "Middle") or self:Child(frame, "Center")) then return self:SkinButton(frame) end
    if frame.Track and frame.Back and frame.Forward then return self:SkinScrollBar(frame) end
    if frame.DecrementButton and frame.IncrementButton then return self:SkinSteppers(frame, frame.DecrementButton, frame.IncrementButton) end
    if frame.Back and frame.Forward and (frame.Slider or kind == "Slider") then return self:SkinSlider(frame) end
    if kind == "Slider" and self:Child(frame, "ScrollUpButton") and self:Child(frame, "ScrollDownButton") then return self:SkinLegacyScrollBar(frame) end
    if kind == "Slider" and frame:GetThumbTexture() then return self:SkinSlider(frame) end
    if kind == "Button" and self:IsCollapseButton(frame) then return self:SkinCollapseButton(frame) end
    if kind == "Button" and frame.Icon and frame.Label and frame:GetName() and frame:GetName():find("Category", 1, true) then return self:SkinCategory(frame) end
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

    if self.layoutModern ~= modern then
        self.layoutModern = modern
        if type(AzerothCompendium.ApplyCompendiumLayout) == "function" then AzerothCompendium:ApplyCompendiumLayout() end
    end

    if modern then
        for _, root in ipairs(self.roots) do
            self:Nudge(root)
        end
    end
end

function Theme:Nudge(frame)
    if frame.acoNudging or not frame:IsShown() or frame:GetNumPoints() == 0 then return end
    local points = self:SavePoints(frame)
    frame.acoNudging = true
    frame:ClearAllPoints()
    for _, point in ipairs(points) do
        frame:SetPoint(point[1], point[2], point[3], (point[4] or 0) + 0.01, point[5] or 0)
    end

    C_Timer.After(0, function()
        frame.acoNudging = nil
        Theme:RestorePoints(frame, points)
    end)
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
        if type(AzerothCompendium.RefreshModuleView) == "function" then hooksecurefunc(AzerothCompendium, "RefreshModuleView", function() if Theme:IsModern() then Theme:QueueRefresh() end end) end
    end

    self:QueueRefresh()
end
