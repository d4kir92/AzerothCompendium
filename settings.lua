local _, DungeonJournal = ...
local ICON = 132115
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 260
local dujoset = nil
local function GetTocVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata("DungeonJournal", "Version") end
    if GetAddOnMetadata then return GetAddOnMetadata("DungeonJournal", "Version") end

    return "0.0.0"
end

function DungeonJournal:ToggleSettings()
    if dujoset == nil then return end
    dujoset:Toggle()
end

local function GetCollapsed(key)
    if key == nil then return nil end
    if type(DUJOTAB) ~= "table" then return nil end
    if type(DUJOTAB["COLLAPSED"]) ~= "table" then return nil end

    return DUJOTAB["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
    if key == nil then return end
    if type(DUJOTAB) ~= "table" then return end
    if type(DUJOTAB["COLLAPSED"]) ~= "table" then DUJOTAB["COLLAPSED"] = {} end
    if collapsed then
        DUJOTAB["COLLAPSED"][key] = true
    else
        DUJOTAB["COLLAPSED"][key] = nil
    end
end

local function AddCategory(key, level)
    dujoset:AddCategory({
        ["label"] = "LID_" .. key,
        ["key"] = key,
        ["search"] = key,
        ["level"] = level
    })
end

local function AddCheckbox(key, default, func, label)
    dujoset:AddCheckbox({
        ["label"] = label or ("LID_" .. key),
        ["search"] = key,
        ["value"] = DungeonJournal:GetConfig(key, default),
        ["func"] = function(value)
            DungeonJournal:SV(DUJOTAB, key, value)
            if func then func() end
        end
    })
end

local function HandleSlash(args)
    local sub = strlower(strtrim(args or ""))
    if sub == "settings" or sub == "options" or sub == "config" then
        DungeonJournal:ToggleSettings()
    else
        DungeonJournal:ToggleJournal()
    end
end

function DungeonJournal:InitSetting()
    if dujoset ~= nil then return end
    DUJOTAB = DUJOTAB or {}
    DungeonJournal:SetVersion(ICON, GetTocVersion())
    DungeonJournal:SetAppendTab(DUJOTAB)
    dujoset = DungeonJournal:CreateUIWindow({
        ["name"] = "DungeonJournalSettings",
        ["pTab"] = {"CENTER"},
        ["width"] = DungeonJournal:GetConfig("WINDOWWIDTH", DEFAULT_WIDTH),
        ["height"] = DungeonJournal:GetConfig("WINDOWHEIGHT", DEFAULT_HEIGHT),
        ["minWidth"] = 340,
        ["minHeight"] = 220,
        ["onResize"] = function(width, height)
            DungeonJournal:SV(DUJOTAB, "WINDOWWIDTH", width)
            DungeonJournal:SV(DUJOTAB, "WINDOWHEIGHT", height)
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T%d:16:16:0:0|t DungeonJournal v%s", ICON, GetTocVersion())
    })

    dujoset:SuspendLayout()
    dujoset:AddSearch()
    AddCategory("GENERAL")
    AddCheckbox("MMBTN", true, function()
        if DUJOTAB["MMBTN"] then
            DungeonJournal:ShowMMBtn("DungeonJournal")
        else
            DungeonJournal:HideMMBtn("DungeonJournal")
        end
    end)

    AddCheckbox("SHOWCHANCE", true, function() DungeonJournal:RefreshJournal() end)
    AddCheckbox("CLASSFILTER", false, function() DungeonJournal:RefreshJournal() end)
    dujoset:ResumeLayout()
    DungeonJournal:CreateMinimapButton({
        ["name"] = "DungeonJournal",
        ["icon"] = ICON,
        ["dbtab"] = DUJOTAB,
        ["vTT"] = {
            {format("|T%d:16:16:0:0|t DungeonJournal", ICON), "v" .. GetTocVersion()},
            {DungeonJournal:Trans("LID_LEFTCLICK"), DungeonJournal:Trans("LID_OPENJOURNAL")},
            {DungeonJournal:Trans("LID_RIGHTCLICK"), DungeonJournal:Trans("LID_OPENSETTINGS")}
        },
        ["funcL"] = function() DungeonJournal:ToggleJournal() end,
        ["funcR"] = function() DungeonJournal:ToggleSettings() end,
        ["dbkey"] = "MMBTN"
    })

    DungeonJournal:AddSlash("dungeonjournal", HandleSlash)
    DungeonJournal:AddSlash("dj", HandleSlash)
end

local loader = CreateFrame("FRAME")
DungeonJournal:RegisterEvent(loader, "PLAYER_LOGIN")
loader:SetScript("OnEvent", function() DungeonJournal:InitSetting() end)
