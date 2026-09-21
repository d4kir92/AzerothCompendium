local _, AzerothCompendium = ...
local ICON = 132115
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 260
local acoset = nil
local function GetTocVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata("AzerothCompendium", "Version") end
    if GetAddOnMetadata then return GetAddOnMetadata("AzerothCompendium", "Version") end

    return "0.0.0"
end

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
    acoset:AddCheckbox({
        ["label"] = label or ("LID_" .. key),
        ["search"] = key,
        ["value"] = AzerothCompendium:GetConfig(key, default),
        ["func"] = function(value)
            AzerothCompendium:SV(ACOTAB, key, value)
            if func then func() end
        end
    })
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
    AzerothCompendium:SetVersion(ICON, GetTocVersion())
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
        ["title"] = format("|T%d:16:16:0:0|t Azeroth Compendium v%s", ICON, GetTocVersion())
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
    AddCheckbox("CLASSFILTER", false, function() AzerothCompendium:RefreshCompendium() end)
    acoset:ResumeLayout()
    AzerothCompendium:CreateMinimapButton({
        ["name"] = "AzerothCompendium",
        ["icon"] = ICON,
        ["noalpha"] = true,
        ["dbtab"] = ACOTAB,
        ["vTT"] = {
            {format("|T%d:16:16:0:0|t Azeroth Compendium", ICON), "v" .. GetTocVersion()},
            {AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_OPENCOMPENDIUM")},
            {AzerothCompendium:Trans("LID_RIGHTCLICK"), AzerothCompendium:Trans("LID_OPENSETTINGS")}
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
