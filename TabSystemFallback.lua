TabSystemButtonArtMixinFallback = {}
local FALLBACK_TEXTURES = {
    ["SquareMask"] = "Interface\\Buttons\\WHITE8X8",
    ["spellbook-Tab-Frame-C60"] = "Interface\\SpellBook\\SpellBook-SkillLineTab",
    ["spellbook-Tab-Frame-Glow-C60"] = "Interface\\SpellBook\\SpellBook-SkillLineTab",
    ["spellbook-Tab-Frame-glow-gradient-C60"] = "Interface\\Buttons\\CheckButtonHilight",
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

    local file = FALLBACK_TEXTURES[atlas]
    if file then
        texture:SetTexture(file)
        if useAtlasSize then texture:SetSize(36, 36) end
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
