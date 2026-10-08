TabSystemButtonArtMixinFallback = {}
local MEDIA = "Interface\\AddOns\\AzerothCompendium\\media\\ui\\"
local FALLBACK_TEXTURES = {
    ["SquareMask"] = {"Interface\\Buttons\\WHITE8X8"},
    ["spellbook-Tab-Frame-C60"] = {MEDIA .. "spellbooktab", 43, 38, 1 / 64, 44 / 64, 1 / 128, 39 / 128},
    ["spellbook-Tab-Frame-Glow-C60"] = {MEDIA .. "spellbooktab", 43, 38, 1 / 64, 44 / 64, 41 / 128, 79 / 128},
    ["spellbook-Tab-Frame-glow-gradient-C60"] = {MEDIA .. "spellbooktab", 43, 38, 1 / 64, 44 / 64, 81 / 128, 119 / 128},
    ["common-sidetab-c60"] = {MEDIA .. "sidetab", 55, 60, 1 / 128, 56 / 128, 1 / 128, 61 / 128},
    ["common-sidetab-hover-c60"] = {MEDIA .. "sidetab", 55, 60, 1 / 128, 56 / 128, 63 / 128, 123 / 128},
    ["common-sidetab-selected-c60"] = {MEDIA .. "sidetab", 55, 60, 58 / 128, 113 / 128, 1 / 128, 61 / 128},
    ["common-sidetab-mask-c60"] = {MEDIA .. "sidetabmask", 55, 60},
}

local ATLASES = {
    {"LeftActive", "uiframe-activetab-left"},
    {"RightActive", "uiframe-activetab-right"},
    {"MiddleActive", "_uiframe-activetab-center"},
    {"Left", "uiframe-tab-left"},
    {"Right", "uiframe-tab-right"},
    {"Middle", "_uiframe-tab-center"},
    {"LeftHighlight", "uiframe-tab-left"},
    {"MiddleHighlight", "_uiframe-tab-center"},
    {"RightHighlight", "uiframe-tab-right"},
    {"IconMask", "SquareMask"},
}

local function HasAtlas(atlas)
    if C_Texture and C_Texture.GetAtlasInfo then return C_Texture.GetAtlasInfo(atlas) ~= nil end
    if GetAtlasInfo then return GetAtlasInfo(atlas) ~= nil end
    return false
end

function TabSystemButtonArtMixinFallback.SetAtlasOrTexture(texture, atlas, useAtlasSize)
    if HasAtlas(atlas) then
        texture:SetAtlas(atlas, useAtlasSize)
        return true
    end

    local info = FALLBACK_TEXTURES[atlas]
    if info then
        texture:SetTexture(info[1])
        if info[4] then texture:SetTexCoord(info[4], info[5], info[6], info[7]) end
        if useAtlasSize and info[2] then texture:SetSize(info[2], info[3]) end
    end
    return false
end

function TabSystemButtonArtMixinFallback:OnLoad()
    for _, info in ipairs(ATLASES) do
        local texture = self[info[1]]
        if texture then TabSystemButtonArtMixinFallback.SetAtlasOrTexture(texture, info[2], info[2] ~= "SquareMask") end
    end
end

function TabSystemButtonArtMixinFallback:HandleRotation()
    if self.isTabOnTop then
        for _, texture in ipairs(self.RotatedTextures) do
            texture:ClearAllPoints()
            texture:SetRotation(math.pi)
        end

        self.RightActive:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -7, 0)
        self.LeftActive:SetPoint("BOTTOMRIGHT")
        self.MiddleActive:SetPoint("LEFT", self.RightActive, "RIGHT")
        self.MiddleActive:SetPoint("RIGHT", self.LeftActive, "LEFT")
        self.Right:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -6, 0)
        self.Left:SetPoint("BOTTOMRIGHT")
        self.Middle:SetPoint("LEFT", self.Right, "RIGHT")
        self.Middle:SetPoint("RIGHT", self.Left, "LEFT")
        self.LeftHighlight:SetPoint("TOPRIGHT", self.Left)
        self.RightHighlight:SetPoint("TOPLEFT", self.Right)
        self.MiddleHighlight:SetPoint("LEFT", self.Middle, "LEFT")
        self.MiddleHighlight:SetPoint("RIGHT", self.Middle, "RIGHT")
    end
end

function TabSystemButtonArtMixinFallback:GetTextYOffset(isSelected)
    local offset = self.textOffsetY or 0
    if self.isTabOnTop then
        offset = offset + (isSelected and 0 or -3)
    else
        offset = offset + (isSelected and -3 or 2)
    end
    return offset
end

function TabSystemButtonArtMixinFallback:GetIconYOffset(isSelected)
    return 0
end

function TabSystemButtonArtMixinFallback:SetTabSelected(isSelected)
    self.isSelected = isSelected
    if self.squareMode then
        self.SquareBackground:SetShown(not isSelected)
        self.SquareBackgroundActive:SetShown(isSelected)
        self.SquareBackgroundActiveGlow:SetShown(isSelected)
    else
        self.Left:SetShown(not isSelected)
        self.Middle:SetShown(not isSelected)
        self.Right:SetShown(not isSelected)
        self.LeftActive:SetShown(isSelected)
        self.MiddleActive:SetShown(isSelected)
        self.RightActive:SetShown(isSelected)
    end

    local selectedFontObject = self.selectedFontObject or GameFontHighlightSmall
    local unselectedFontObject = self.unselectedFontObject or GameFontNormalSmall
    self:SetNormalFontObject(isSelected and selectedFontObject or unselectedFontObject)
    self:SetEnabled(not isSelected and not self:IsForceDisabled())
    self.Text:SetPoint("CENTER", self, "CENTER", 0, self:GetTextYOffset(isSelected))
    self.Icon:SetPoint("CENTER", self, "CENTER", 0, self:GetIconYOffset(isSelected))
    local tooltip = GetAppropriateTooltip and GetAppropriateTooltip() or GameTooltip
    if tooltip:IsOwned(self) then tooltip:Hide() end
end

function TabSystemButtonArtMixinFallback:SetTabWidth(width)
    self:SetWidth(width)
end

function TabSystemButtonArtMixinFallback:SetTabHeight(height)
    for _, texture in ipairs(self.RotatedTextures) do
        texture:SetHeight(height)
    end
end

function TabSystemButtonArtMixinFallback:IsForceDisabled()
    return false, nil
end

function TabSystemButtonArtMixinFallback:SetSquareMode(enabled)
    self.squareMode = enabled
    if enabled then
        self.Left:Hide()
        self.Middle:Hide()
        self.Right:Hide()
        self.LeftActive:Hide()
        self.MiddleActive:Hide()
        self.RightActive:Hide()
        self.LeftHighlight:Hide()
        self.MiddleHighlight:Hide()
        self.RightHighlight:Hide()
        TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.SquareBackground, "spellbook-Tab-Frame-C60", true)
        TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.SquareBackgroundActive, "spellbook-Tab-Frame-Glow-C60", true)
        TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.SquareBackgroundActiveGlow, "spellbook-Tab-Frame-glow-gradient-C60", true)
    else
        self.SquareBackground:Hide()
        self.SquareBackgroundActive:Hide()
        self.SquareBackgroundActiveGlow:Hide()
    end

    self:SetTabSelected(self.isSelected)
end

LargeSideTabButtonMixinFallback = {}
function LargeSideTabButtonMixinFallback:OnLoad()
    TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.Background, "common-sidetab-c60", true)
    TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.Mask, "common-sidetab-mask-c60", true)
    TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.SelectedTexture, "common-sidetab-selected-c60", true)
    TabSystemButtonArtMixinFallback.SetAtlasOrTexture(self.HighlightTexture, "common-sidetab-hover-c60", true)
    self.Icon:AddMaskTexture(self.Mask)
    self:SetSize(55, 55)
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("CENTER", -4, 0)
    self.SelectedTexture:Hide()
end

function LargeSideTabButtonMixinFallback:OnMouseDown(button)
    if button == "LeftButton" then self.Icon:SetPoint("CENTER", -3, -1) end
end

function LargeSideTabButtonMixinFallback:OnMouseUp(button, upInside)
    if button == "LeftButton" then
        self.Icon:SetPoint("CENTER", -4, 0)
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end
    end

    if self.customMouseUpHandler then self.customMouseUpHandler(self, button, upInside) end
end

function LargeSideTabButtonMixinFallback:SetCustomOnMouseUpHandler(handler)
    self.customMouseUpHandler = handler
end

function LargeSideTabButtonMixinFallback:SetFillToInterior(fillToInterior, extent)
    self.fillToInterior = fillToInterior
    self.interiorExtent = extent
    self:UpdateIconInterior()
end

function LargeSideTabButtonMixinFallback:UpdateIconInterior()
    if self.fillToInterior then
        local extent = self.interiorExtent or 50
        self.Icon:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
        self.Icon:SetSize(extent, extent)
    end
end

function LargeSideTabButtonMixinFallback:SetChecked(checked)
    self.SelectedTexture:SetShown(checked)
    self:UpdateIconInterior()
end
