local _, AzerothCompendium = ...
local Welcome = {}
AzerothCompendium.Welcome = Welcome
Welcome.WIDTH = 440
Welcome.PADDING = 20
Welcome.BUTTONHEIGHT = 22
Welcome.SPACING = 4
Welcome.DESIGNS = {{"LID_DESIGNMODERN", "modern"}, {"LID_DESIGNMATERIALDARK", "materialdark"}, {"LID_DESIGNMATERIALLIGHT", "materiallight"}, {"LID_DESIGNFOREVER", "forever"}}

function Welcome:SetSelected(button, selected)
    button.acoSelected = selected
    if selected then
        button:LockHighlight()
    else
        button:UnlockHighlight()
    end

    AzerothCompendium.Theme:UpdateFrame(button)
end

function Welcome:UpdateSelection()
    local frame = self.frame
    if frame == nil then return end
    local lang = AzerothCompendium:GetLanguage()
    for _, button in ipairs(frame.languageButtons) do
        self:SetSelected(button, button.value == lang)
    end

    local design = AzerothCompendium:GetDesign()
    for _, button in ipairs(frame.designButtons) do
        self:SetSelected(button, button.value == design)
    end

    frame.spoiler:SetChecked(type(ACOTABPC) == "table" and ACOTABPC.SPOILERFREE == true)
end

function Welcome:CreateChoices(parent, entries, columns, onClick)
    local panel = CreateFrame("Frame", nil, parent)
    AzerothCompendiumAPI.AddContentBorder(panel)
    local inner = self.WIDTH - self.PADDING * 2 - 12
    local width = (inner - self.SPACING * (columns - 1)) / columns
    local buttons = {}
    for index, entry in ipairs(entries) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        local column = (index - 1) % columns
        local row = floor((index - 1) / columns)
        button:SetSize(width, self.BUTTONHEIGHT)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 6 + column * (width + self.SPACING), -6 - row * (self.BUTTONHEIGHT + self.SPACING))
        button.value = entry[2]
        button.labelKey = entry[3]
        button:SetText(entry[1])
        button.acoSegment = function() return button.acoSelected == true end
        button:SetScript("OnClick", function() onClick(button.value) end)
        tinsert(buttons, button)
    end

    local rows = ceil(#entries / columns)
    panel:SetHeight(12 + rows * self.BUTTONHEIGHT + (rows - 1) * self.SPACING)

    return panel, buttons
end

function Welcome:GetLanguageLabel()
    local label = AzerothCompendium:Trans("LID_LANGUAGE")
    if label ~= "Language" then label = label .. " / Language" end

    return label
end

function Welcome:Relabel()
    local frame = self.frame
    local title = AzerothCompendium.Theme:GetTitleText(frame)
    if title then title:SetText(AzerothCompendium:Trans("LID_WELCOMETITLE")) end
    frame.intro:SetText(AzerothCompendium:Trans("LID_WELCOMETEXT"))
    frame.languageHeader:SetText(self:GetLanguageLabel())
    frame.designHeader:SetText(AzerothCompendium:Trans("LID_DESIGN"))
    frame.spoilerLabel:SetText(AzerothCompendium:Trans("LID_SPOILERFREE"))
    frame.spoilerHint:SetText(AzerothCompendium:Trans("LID_SPOILERFREEHINT"))
    frame.start:SetText(AzerothCompendium:Trans("LID_WELCOMESTART"))
    frame.start:SetWidth(max(140, frame.start:GetFontString():GetStringWidth() + 40))
    for _, button in ipairs(frame.designButtons) do
        button:SetText(AzerothCompendium:Trans(button.labelKey))
    end

    local height = 64 + frame.intro:GetStringHeight() + 14 + frame.languageHeader:GetStringHeight() + 6 + frame.languagePanel:GetHeight() + 14 + frame.designHeader:GetStringHeight() + 6 + frame.designPanel:GetHeight() + 12 + frame.spoiler:GetHeight() + 2 + frame.spoilerHint:GetStringHeight() + 20 + frame.start:GetHeight() + 30
    frame:SetHeight(height)
    self:UpdateSelection()
end

function Welcome:Create()
    if self.frame then return self.frame end
    local frame = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumWelcome", AzerothCompendium:Trans("LID_WELCOMETITLE"))
    self.frame = frame
    frame:SetWidth(self.WIDTH)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnHide", function() AzerothCompendium:SetConfig("WELCOMESHOWN", true) end)
    tinsert(UISpecialFrames, "AzerothCompendiumWelcome")
    frame.intro = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    frame.intro:SetPoint("TOPLEFT", frame, "TOPLEFT", self.PADDING, -64)
    frame.intro:SetWidth(self.WIDTH - self.PADDING * 2)
    frame.intro:SetJustifyH("LEFT")
    frame.intro:SetWordWrap(true)
    frame.languageHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.languageHeader:SetPoint("TOPLEFT", frame.intro, "BOTTOMLEFT", 0, -14)
    local languages = {}
    for _, info in ipairs(AzerothCompendium.LANGUAGES) do
        tinsert(languages, {info[1], info[2]})
    end

    frame.languagePanel, frame.languageButtons = self:CreateChoices(frame, languages, 3, function(value)
        AzerothCompendium:SetLanguage(value)
        if AzerothCompendium.SyncSettingsAppearance then AzerothCompendium:SyncSettingsAppearance() end
        Welcome:UpdateSelection()
    end)

    frame.languagePanel:SetPoint("TOPLEFT", frame.languageHeader, "BOTTOMLEFT", 0, -6)
    frame.languagePanel:SetPoint("RIGHT", frame, "RIGHT", -self.PADDING, 0)
    frame.designHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.designHeader:SetPoint("TOPLEFT", frame.languagePanel, "BOTTOMLEFT", 0, -14)
    local designs = {}
    for _, info in ipairs(self.DESIGNS) do
        tinsert(designs, {AzerothCompendium:Trans(info[1]), info[2], info[1]})
    end

    frame.designPanel, frame.designButtons = self:CreateChoices(frame, designs, 2, function(value)
        AzerothCompendium:SetDesign(value)
        if AzerothCompendium.SyncSettingsAppearance then AzerothCompendium:SyncSettingsAppearance() end
        Welcome:UpdateSelection()
    end)

    frame.designPanel:SetPoint("TOPLEFT", frame.designHeader, "BOTTOMLEFT", 0, -6)
    frame.designPanel:SetPoint("RIGHT", frame, "RIGHT", -self.PADDING, 0)
    frame.spoiler = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.spoiler:SetSize(24, 24)
    frame.spoiler:SetPoint("TOPLEFT", frame.designPanel, "BOTTOMLEFT", -2, -12)
    frame.spoiler:SetScript("OnClick", function(sel)
        ACOTABPC = ACOTABPC or {}
        ACOTABPC.SPOILERFREE = sel:GetChecked() == true
        if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
    end)

    frame.spoilerLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.spoilerLabel:SetPoint("LEFT", frame.spoiler, "RIGHT", 4, 0)
    frame.spoilerHint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    frame.spoilerHint:SetPoint("TOPLEFT", frame.spoiler, "BOTTOMLEFT", 30, -2)
    frame.spoilerHint:SetWidth(self.WIDTH - self.PADDING * 2 - 28)
    frame.spoilerHint:SetJustifyH("LEFT")
    frame.spoilerHint:SetWordWrap(true)
    frame.start = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.start:SetHeight(24)
    frame.start:SetPoint("BOTTOM", frame, "BOTTOM", 0, 30)
    frame.start:SetScript("OnClick", function() frame:Hide() end)
    AzerothCompendium:OnLanguage(function() Welcome:Relabel() end)

    return frame
end

function AzerothCompendium:ShowWelcome()
    local frame = Welcome:Create()
    Welcome:UpdateSelection()
    frame:Show()
    frame:Raise()
end

function Welcome:ShowOnce()
    if AzerothCompendium:GetConfig("WELCOMESHOWN", false) == true then return end
    local journal = _G.AzerothCompendiumFrame
    if journal == nil or not journal:IsShown() then return end
    if self.frame and self.frame:IsShown() then return end
    AzerothCompendium:ShowWelcome()
end

for _, name in ipairs({"ToggleCompendium", "OpenCompendium", "OpenCompendiumSettings"}) do
    hooksecurefunc(AzerothCompendium, name, function() Welcome:ShowOnce() end)
end
