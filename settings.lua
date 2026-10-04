local _, AzerothCompendium = ...
local ICON = 133737
local acoset = nil
local classFilterSetting = nil
function AzerothCompendium:ToggleSettings()
    AzerothCompendium:OpenCompendiumSettings()
end

local function GetCollapsed(key)
    if key == nil then return nil end
    if type(ACOTAB) ~= "table" then return nil end
    if type(ACOTAB["COLLAPSED"]) ~= "table" then return nil end
    return ACOTAB["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
    if key == nil then return end
    if type(ACOTAB) ~= "table" then return end
    if type(ACOTAB["COLLAPSED"]) ~= "table" then ACOTAB["COLLAPSED"] = {} end
    if collapsed then
        ACOTAB["COLLAPSED"][key] = true
    else
        ACOTAB["COLLAPSED"][key] = nil
    end
end

local labels = {}
local minimapTooltip = {}
local function AddCategory(key, level, added)
    local header = acoset:AddCategory({
        ["label"] = "LID_" .. key,
        ["key"] = key,
        ["search"] = key,
        ["level"] = level,
        ["added"] = added
    })

    tinsert(labels, {header.Label, header.element, "LID_" .. key})
end

local function AddCheckbox(key, default, func, label)
    local checkbox = acoset:AddCheckbox({
        ["label"] = label or ("LID_" .. key),
        ["search"] = key,
        ["value"] = AzerothCompendium:GetConfig(key, default),
        ["func"] = function(value)
            AzerothCompendium:SV(ACOTAB, key, value)
            if func then func(value) end
        end
    })

    tinsert(labels, {checkbox.Label, checkbox.uiElement, label or ("LID_" .. key)})
    return checkbox
end

local function AddSharedCheckbox(key, label, added)
    local checkbox = acoset:AddCheckbox({
        ["label"] = label,
        ["search"] = key,
        ["value"] = AzerothCompendium:GetSharedOption(key),
        ["added"] = added,
        ["func"] = function(value) AzerothCompendium:SetSharedOption(key, value) end
    })

    tinsert(labels, {checkbox.Label, checkbox.uiElement, label})
    AzerothCompendium.WorldMap.checkboxes[key] = checkbox
end

function AzerothCompendium:RefreshSettingsLanguage()
    minimapTooltip[1] = {AzerothCompendium:GetCompendiumTooltipLabel("AzerothCompendium", 16), "v" .. AzerothCompendium:GetAddonVersion()}
    minimapTooltip[2] = {AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_OPENCOMPENDIUM")}
    minimapTooltip[3] = {AzerothCompendium:Trans("LID_RIGHTCLICK"), AzerothCompendium:Trans("LID_OPENSETTINGS")}
    for _, info in ipairs(labels) do
        local text = AzerothCompendium:Trans(info[3])
        info[1]:SetText(text)
        AzerothCompendium.UI:SetLabel(info[2], text)
    end

    if acoset and acoset.search and acoset.search.Hint then acoset.search.Hint:SetText(AzerothCompendium:Trans("LID_SEARCH")) end
    if acoset and acoset.language then acoset.language:SetValue(AzerothCompendium:GetLanguage()) end
    if acoset and acoset.scale then acoset.scale.Label:SetText(format("%s: %d%%", AzerothCompendium:Trans("LID_SCALE"), acoset.scale.value)) end
end

function AzerothCompendium:SyncSettingsScale()
    if acoset and acoset.scale then acoset.scale.slider:SetValue(floor(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1) * 100 + 0.5)) end
end

function AzerothCompendium:SyncSettingsFlavor()
    if acoset and acoset.flavor then acoset.flavor:SetValue(AzerothCompendium:GetFlavor()) end
end

function AzerothCompendium:SyncSettingsClassFilter()
    if classFilterSetting == nil then return end
    classFilterSetting:SetChecked(AzerothCompendium:GetConfig("CLASSFILTER", false) == true)
end

local function HandleSlash(args)
    local sub = strlower(strtrim(args or "")):gsub("%s+", " ")
    if sub == "settings" or sub == "options" or sub == "config" then
        AzerothCompendium:ToggleSettings()
    elseif sub == "debug help" then
        AzerothCompendium:PrintMapPinDebugHelp()
    elseif sub == "debug" then
        AzerothCompendium:ToggleMapPinDebug()
    else
        AzerothCompendium:ToggleCompendium()
    end
end

function AzerothCompendium:CreateCompendiumSettings(parent, target)
    if acoset ~= nil then return acoset end
    ACOTAB = ACOTAB or {}
    acoset = CreateFrame("Frame", "AzerothCompendiumSettings", parent)
    acoset:SetAllPoints(parent)
    AzerothCompendium.UI:ApplyWindow(acoset)
    acoset.leftInset = 8
    acoset.contentTrim = 44
    acoset.headerHeight = 0
    acoset.footerHeight = 0
    acoset.elements = {}
    acoset.count = 0
    acoset.categoryStack = {}
    acoset.searching = false
    acoset.layoutSuspended = false
    acoset.getCollapsed = GetCollapsed
    acoset.setCollapsed = SetCollapsed
    function acoset:UpdateBodyLayout()
        if self.header ~= nil then
            self.header:ClearAllPoints()
            self.header:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -8)
            self.header:SetPoint("TOPRIGHT", self, "TOPRIGHT", -24, -8)
            self.header:SetHeight(self.headerHeight)
        end

        if self.scrollFrame ~= nil and self.scrollInset ~= nil then
            self.scrollFrame:ClearAllPoints()
            self.scrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", self.scrollInset.left, -(12 + self.headerHeight))
            self.scrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", self.scrollInset.right, self.scrollInset.bottom)
        end
    end

    acoset.content = AzerothCompendium:CreateUIWindowScroll(acoset, "AzerothCompendiumSettings")
    acoset:HookScript("OnSizeChanged", function(sel)
        sel.contentWidth = max(1, sel:GetWidth() - sel.contentTrim)
        sel:Layout()
    end)

    acoset:HookScript("OnHide", function() AzerothCompendium.UI:CloseDropdowns() end)

    acoset:SuspendLayout()
    acoset:AddSearch()
    AddCategory("GENERAL")
    local languageChoices = {}
    for _, info in ipairs(AzerothCompendium.LANGUAGES) do
        tinsert(languageChoices, {label = info[1], value = info[2]})
    end

    acoset.language = acoset:AddDropdown({
        ["label"] = "LID_LANGUAGE",
        ["search"] = "LANGUAGE",
        ["choices"] = languageChoices,
        ["value"] = AzerothCompendium:GetLanguage(),
        ["func"] = function(value) AzerothCompendium:SetLanguage(value) end,
    })
    tinsert(labels, {acoset.language.Label, acoset.language.uiElement, "LID_LANGUAGE"})
    acoset.flavor = acoset:AddDropdown({
        ["label"] = "LID_FLAVOR",
        ["search"] = "FLAVOR",
        ["choices"] = {{label = "Classic Era", value = "classic_era"}, {label = "Forever", value = "forever"}},
        ["value"] = AzerothCompendium:GetFlavor(),
        ["func"] = function(value) AzerothCompendium:SetFlavor(value) end,
    })
    acoset.flavor:SetEnabled(not AzerothCompendium:IsClassicEraClient())
    tinsert(labels, {acoset.flavor.Label, acoset.flavor.uiElement, "LID_FLAVOR"})
    acoset.scale = acoset:AddSlider({
        ["label"] = AzerothCompendium:Trans("LID_SCALE") .. ": %d%%",
        ["search"] = "SCALE",
        ["commitOnRelease"] = true,
        ["min"] = 50,
        ["max"] = 150,
        ["step"] = 1,
        ["value"] = min(150, max(50, floor((tonumber(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1)) or 1) * 100 + 0.5))),
        ["func"] = function(value)
            local scale = AzerothCompendium:ApplyCompendiumScale(target, value / 100)
            local actual = floor(scale * 100 + 0.5)
            if actual < 50 then acoset.scale.slider:SetMinMaxValues(actual, 150) end
            if actual ~= value then acoset.scale.slider:SetValue(actual) end
            acoset.scale.Label:SetText(format("%s: %d%%", AzerothCompendium:Trans("LID_SCALE"), actual))
        end,
    })
    AddCheckbox("MMBTN", true, function()
        if ACOTAB["MMBTN"] then
            AzerothCompendium:ShowMMBtn("AzerothCompendium")
        else
            AzerothCompendium:HideMMBtn("AzerothCompendium")
        end
    end)

    AddCheckbox("SHOWCHANCE", true, function() AzerothCompendium:RefreshCompendium() end)
    classFilterSetting = AddCheckbox("CLASSFILTER", false, function(value) AzerothCompendium:SetClassFilter(value) end)
    AddCategory("MAPICONS", nil, "2026-10-04")
    AddCategory("INSTANCEENTRANCES", 2, "2026-10-04")
    AddSharedCheckbox("DUNGEONWORLDMAPPINS", "LID_WORLDMAPPINS", "2026-10-04")
    AddSharedCheckbox("DUNGEONMINIMAPPINS", "LID_MINIMAPPINS", "2026-10-04")
    AddCategory("MEETINGSTONES", 2, "2026-10-04")
    AddSharedCheckbox("MEETINGSTONEWORLDMAPPINS", "LID_WORLDMAPPINS", "2026-10-04")
    AddSharedCheckbox("MEETINGSTONEMINIMAPPINS", "LID_MINIMAPPINS", "2026-10-04")
    AddCategory("INSTANCEMAPS", 2, "2026-10-04")
    AddSharedCheckbox("INSTANCEPINS_BOSS", "LID_SHOWBOSSPINS", "2026-10-04")
    AddSharedCheckbox("INSTANCEPINS_ITEM", "LID_SHOWQUESTPINS", "2026-10-04")
    AddSharedCheckbox("INSTANCEPINS_ENTRANCE", "LID_SHOWENTRANCEPINS", "2026-10-04")
    AddSharedCheckbox("INSTANCEPINS_LEVEL", "LID_SHOWLEVELPINS", "2026-10-04")
    acoset:ResumeLayout()
    AzerothCompendium:RefreshSettingsLanguage()
    return acoset
end

function AzerothCompendium:InitSetting()
    if AzerothCompendium.settingsInitialized then return end
    AzerothCompendium.settingsInitialized = true
    ACOTAB = ACOTAB or {}
    AzerothCompendium:SetVersion(ICON, AzerothCompendium:GetAddonVersion())
    AzerothCompendium:SetAppendTab(ACOTAB)
    AzerothCompendium:RefreshSettingsLanguage()
    AzerothCompendium:OnLanguage(function() AzerothCompendium:RefreshSettingsLanguage() end)
    AzerothCompendium:CreateMinimapButton({
        ["name"] = "AzerothCompendium",
        ["icon"] = ICON,
        ["noalpha"] = true,
        ["dbtab"] = ACOTAB,
        ["vTT"] = minimapTooltip,
        ["funcL"] = function() AzerothCompendium:ToggleCompendium() end,
        ["funcR"] = function() AzerothCompendium:ToggleSettings() end,
        ["dbkey"] = "MMBTN"
    })

    if AzerothCompendium:GetConfig("MMBTN", true) then AzerothCompendium:ShowMMBtn("AzerothCompendium") end
    AzerothCompendium:AddSlash("azerothcompendium", HandleSlash)
    AzerothCompendium:AddSlash("ac", HandleSlash)
end

local loader = CreateFrame("FRAME")
AzerothCompendium:RegisterEvent(loader, "PLAYER_LOGIN")
loader:SetScript("OnEvent", function() AzerothCompendium:InitSetting() end)
