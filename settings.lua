local _, AzerothCompendium = ...
local ICON = 133737
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 260
local acoset = nil
local classFilterSetting = nil

function AzerothCompendium:ToggleSettings()
    if acoset == nil then return end
    acoset:Toggle()
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

local function AddCategory(key, level)
    acoset:AddCategory({
        ["label"] = "LID_" .. key,
        ["key"] = key,
        ["search"] = key,
        ["level"] = level
    })
end

local function AddCheckbox(key, default, func, label)
    return acoset:AddCheckbox({
        ["label"] = label or ("LID_" .. key),
        ["search"] = key,
        ["value"] = AzerothCompendium:GetConfig(key, default),
        ["func"] = function(value)
            AzerothCompendium:SV(ACOTAB, key, value)
            if func then func(value) end
        end
    })
end

function AzerothCompendium:SyncSettingsClassFilter()
    if classFilterSetting == nil then return end
    classFilterSetting:SetChecked(AzerothCompendium:GetConfig("CLASSFILTER", false) == true)
end

local function HandleSlash(args)
    local sub = strlower(strtrim(args or ""))
    if sub == "settings" or sub == "options" or sub == "config" then
        AzerothCompendium:ToggleSettings()
    else
        AzerothCompendium:ToggleCompendium()
    end
end

function AzerothCompendium:InitSetting()
    if acoset ~= nil then return end
    ACOTAB = ACOTAB or {}
    AzerothCompendium:SetVersion(ICON, AzerothCompendium:GetAddonVersion())
    AzerothCompendium:SetAppendTab(ACOTAB)
    acoset = AzerothCompendium:CreateUIWindow({
        ["name"] = "AzerothCompendiumSettings",
        ["pTab"] = {"CENTER"},
        ["width"] = AzerothCompendium:GetConfig("WINDOWWIDTH", DEFAULT_WIDTH),
        ["height"] = AzerothCompendium:GetConfig("WINDOWHEIGHT", DEFAULT_HEIGHT),
        ["minWidth"] = 340,
        ["minHeight"] = 220,
        ["onResize"] = function(width, height)
            AzerothCompendium:SV(ACOTAB, "WINDOWWIDTH", width)
            AzerothCompendium:SV(ACOTAB, "WINDOWHEIGHT", height)
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T%d:16:16:0:0|t Azeroth Compendium v%s", ICON, AzerothCompendium:GetAddonVersion())
    })

    acoset:SuspendLayout()
    acoset:AddSearch()
    AddCategory("GENERAL")
    AddCheckbox("MMBTN", true, function()
        if ACOTAB["MMBTN"] then
            AzerothCompendium:ShowMMBtn("AzerothCompendium")
        else
            AzerothCompendium:HideMMBtn("AzerothCompendium")
        end
    end)

    AddCheckbox("SHOWCHANCE", true, function() AzerothCompendium:RefreshCompendium() end)
    classFilterSetting = AddCheckbox("CLASSFILTER", false, function(value) AzerothCompendium:SetClassFilter(value) end)
    acoset:ResumeLayout()
    AzerothCompendium:CreateMinimapButton({
        ["name"] = "AzerothCompendium",
        ["icon"] = ICON,
        ["noalpha"] = true,
        ["dbtab"] = ACOTAB,
        ["vTT"] = {
            {AzerothCompendium:GetCompendiumTooltipLabel("Azeroth Compendium", 16), "v" .. AzerothCompendium:GetAddonVersion()},
            {AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK")), AzerothCompendium:Trans("LID_OPENCOMPENDIUM")},
            {AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_RIGHTCLICK")), AzerothCompendium:Trans("LID_OPENSETTINGS")}
        },
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
