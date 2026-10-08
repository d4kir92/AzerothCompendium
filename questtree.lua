local _, AzerothCompendium = ...
local NODE_MIN_W = 180
local NODE_MAX_W = 240
local NODE_PAD_X = 6
local NODE_PAD_TOP = 5
local NODE_PAD_BOTTOM = 5
local TITLE_H = 16
local TEXT_LINE_H = 13
local REWARD_LINE_H = 20
local STATUS_ICON_SIZE = 14
local GAP_X = 14
local GAP_Y = 22
local PAD = 10
local HEADER_H = 22
local BOX_GAP = 24
local EMPTY_H = 26
local ICON_SIZE = 16
local ICON_GAP = 3
local LINE_W = 2
local SCROLLBAR_W = 18
local BOTTOM_H = 22
local MINIMAL_BAR_W = 8
local MINIMAL_STEPPER_INSET = 19
local MINIMAL_STEPPER_W = 17
local MINIMAL_STEPPER_H = 11
local ZOOM_LABEL_W = 36
local HBAR_H = 12
local HBAR_MIN_THUMB = 30
local DRAG_THRESHOLD = 4
local WHEEL_STEP = 60
local QUEST_TAG_ATLAS_SIZE = 22
local QUEST_TAG_ATLAS_INSET = 4
local QUEST_TAG_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_Bone_Skull_02"
local QUEST_TAG_PLAIN_ATLASES = {
    ["questlog-questtypeicon-dungeon"] = true,
    ["questlog-questtypeicon-raid"] = true
}

local QUEST_TAG_ATLASES = {
    [81] = {"questlog-questtypeicon-dungeon", "Dungeon", "DungeonSkull", "Dungeon-Normal"},
    [62] = {"questlog-questtypeicon-raid", "questlog-questtypeicon-dungeon", "Raid", "Dungeon", "DungeonSkull", "Dungeon-Normal"}
}

local questTagIcons = {}
local function GetQuestTagIcon(tagID)
    local atlases = QUEST_TAG_ATLASES[tagID]
    if atlases == nil then return nil end
    if questTagIcons[tagID] == nil then
        questTagIcons[tagID] = {QUEST_TAG_DEFAULT_ICON, false}
        for _, atlas in ipairs(atlases) do
            if AzerothCompendium:AtlasExists(atlas) then
                questTagIcons[tagID] = {atlas, true, QUEST_TAG_PLAIN_ATLASES[atlas] == true}
                break
            end
        end
    end

    return questTagIcons[tagID]
end

function AzerothCompendium:GetQuestTagIcon(tagID)
    return GetQuestTagIcon(tagID)
end

local OUTSIDE_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local SECTION_COUNT = 4
local SECTION_TITLES = {"LID_QUESTTREEATTUNE", "LID_QUESTTREESTART", "LID_QUESTTREEINSTANCE", "LID_QUESTTREEAFTER"}
local SECTION_EMPTY = {"LID_NOENTRIES", "LID_QUESTTREENOSTART", "LID_NOENTRIES", "LID_QUESTTREENOAFTER"}
local KEY_LINE_H = 22
local KEY_OWNED_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"
local KEY_MISSING_ICON = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local ZOOM_MIN = 0.4
local ZOOM_MAX = 1.5
local ZOOM_BAR_STEP = 5
local ZOOM_BAR_W = 130
local LIST_ROW_H = 18
local LIST_INDENT = 14
local LIST_TOGGLE_SIZE = 14
local VIEW_BUTTON_W = 60
local PLUS_TEXTURE = "Interface\\Buttons\\UI-PlusButton-Up"
local MINUS_TEXTURE = "Interface\\Buttons\\UI-MinusButton-Up"
local STATUS_ICON = {
    ["complete"] = {"Interface\\RaidFrame\\ReadyCheck-Ready", false},
    ["ready"] = {"Interface\\GossipFrame\\ActiveQuestIcon", false},
    ["active"] = {"Interface\\GossipFrame\\ActiveQuestIcon", true},
    ["open"] = {"Interface\\GossipFrame\\AvailableQuestIcon", false},
    ["lowlevel"] = {"Interface\\GossipFrame\\AvailableQuestIcon", true},
    ["locked"] = {"Interface\\GossipFrame\\AvailableQuestIcon", true, {1, 0.2, 0.2}}
}

local STATUS_BORDER = {
    ["complete"] = {0.13, 0.75, 0.13, 1},
    ["ready"] = {1, 0.82, 0, 1},
    ["active"] = {0.7, 0.6, 0.25, 1},
    ["open"] = {0.35, 0.35, 0.38, 1},
    ["lowlevel"] = {0.35, 0.35, 0.38, 1},
    ["locked"] = {0.35, 0.35, 0.38, 1}
}

local STATUS_TEXT = {
    ["complete"] = "LID_QUESTCOMPLETE",
    ["ready"] = "LID_QUESTREADY",
    ["active"] = "LID_QUESTACTIVE",
    ["open"] = "LID_QUESTNOTACCEPTED",
    ["lowlevel"] = "LID_QUESTLOWLEVEL",
    ["locked"] = "LID_QUESTLOCKED"
}

local function IsQuestLocked(node)
    while node and node.parents and #node.parents == 1 and node.parents[1].id == node.id do
        node = node.parents[1]
    end

    if node == nil then return false end
    local anyOf = {}
    for _, variantID in ipairs(AzerothCompendium:GetQuestVariants(node.id)) do
        for _, id in ipairs(AzerothCompendium.QUESTPREANY and AzerothCompendium.QUESTPREANY[variantID] or {}) do
            anyOf[AzerothCompendium:GetQuestCanonicalID(id)] = true
        end
    end

    local hasAny, anyDone = false, false
    for _, parent in ipairs(node.parents or {}) do
        local completed = AzerothCompendium:IsQuestCompleted(parent.id)
        if anyOf[parent.id] then
            hasAny = true
            if completed then anyDone = true end
        elseif not completed then
            return true
        end
    end

    return hasAny and not anyDone
end

local function GetQuestStatus(questID, node)
    local status = "open"
    if AzerothCompendium:IsQuestCompleted(questID) then
        status = "complete"
    elseif AzerothCompendium:IsQuestReadyForTurnIn(questID) then
        status = "ready"
    elseif AzerothCompendium:IsQuestActive(questID) then
        status = "active"
    elseif IsQuestLocked(node) then
        status = "locked"
    else
        local requiredLevel = AzerothCompendium:GetQuestRequiredLevel(node and node.quest or questID)
        local playerLevel = UnitLevel and UnitLevel("player") or 0
        if type(requiredLevel) == "number" and playerLevel > 0 and playerLevel < requiredLevel then status = "lowlevel" end
    end

    local phases = node and node.phases
    if phases == nil or phases.turnin then return status end
    if status == "ready" then return "complete" end
    if status == "active" and not phases.objective then return "complete" end

    return status
end

local function IsGroupUnitOnQuest(unit, questID)
    if unit == "player" then return AzerothCompendium:IsQuestActive(questID) end
    if C_QuestLog and C_QuestLog.IsUnitOnQuest then
        local ok, onQuest = pcall(C_QuestLog.IsUnitOnQuest, unit, questID)
        if ok then return onQuest == true end
    end

    if IsUnitOnQuest and GetQuestLogIndexByID then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then
            local unitOk, onQuest = pcall(IsUnitOnQuest, index, unit)

            return unitOk and (onQuest == true or onQuest == 1)
        end
    end

    return false
end

local function GetGroupQuestCount(questID)
    if IsInGroup == nil or not IsInGroup() or GetNumGroupMembers == nil then return nil end
    local total = GetNumGroupMembers()
    if total <= 1 then return nil end
    local count = 0
    if IsInRaid and IsInRaid() then
        for index = 1, total do
            if IsGroupUnitOnQuest(UnitIsUnit("raid" .. index, "player") and "player" or "raid" .. index, questID) then count = count + 1 end
        end
    else
        if IsGroupUnitOnQuest("player", questID) then count = count + 1 end
        for index = 1, total - 1 do
            if IsGroupUnitOnQuest("party" .. index, questID) then count = count + 1 end
        end
    end

    return count, total
end

local function GetQuestDifficultyColorCode(level)
    return AzerothCompendium:GetColorCode(AzerothCompendium:GetLevelDifficultyColor(level, 1, 1, 1))
end

local function AddQuestStatusToTooltip(questID, quest, node)
    local status = GetQuestStatus(questID, node)
    local text = AzerothCompendium:Trans(STATUS_TEXT[status])
    local color = status == "locked" and {1, 0.3, 0.3} or (status == "open" or status == "lowlevel") and {0.65, 0.65, 0.65} or STATUS_BORDER[status]
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(_G.STATUS or "Status"), text, 0.9, 0.9, 0.9, color[1], color[2], color[3])
    quest = quest or AzerothCompendium:GetQuestDataByID(questID) or questID
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTREQUIREDLEVEL")), tostring(AzerothCompendium:GetQuestRequiredLevel(quest)), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTRECOMMENDEDLEVEL")), tostring(AzerothCompendium:GetQuestRecommendedLevel(quest)), 0.9, 0.9, 0.9, 1, 0.82, 0)
    local classText = AzerothCompendium:GetQuestClassText(questID)
    if classText then GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(_G.CLASS or "Class"), classText, 0.9, 0.9, 0.9, 1, 1, 1) end
    local variants = AzerothCompendium:GetQuestVariants(questID)
    if #variants > 1 then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTVARIANTS", nil, #variants)), 0.75, 0.75, 0.75, true) end
end

local function ShowQuestWowheadLink(questID)
    if IsShiftKeyDown == nil or not IsShiftKeyDown() then return false end
    local popup = AzerothCompendium.questWowheadPopup or _G.AzerothCompendiumQuestWowhead
    if popup == nil then popup = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumQuestWowhead", "Wowhead") end
    AzerothCompendium.questWowheadPopup = popup
    if popup.link == nil then
        popup:SetSize(520, 130)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("DIALOG")
        popup.link = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        popup.link:SetPoint("TOPLEFT", 24, -60)
        popup.link:SetPoint("TOPRIGHT", -24, -60)
        popup.link:SetHeight(24)
        popup.link:SetAutoFocus(false)
        popup.link:SetScript("OnEditFocusGained", function(sel) sel:HighlightText() end)
        popup.link:SetScript("OnMouseUp", function(sel) sel:HighlightText() end)
        popup.link:SetScript("OnEscapePressed", function() popup:Hide() end)
        popup.link:SetScript("OnEnterPressed", function() popup:Hide() end)
        popup:SetScript("OnHide", function(sel) sel.link:ClearFocus() end)
        popup.hint = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        popup.hint:SetPoint("TOP", popup.link, "BOTTOM", 0, -10)
        popup.hint:SetText("Ctrl+C")
    end

    popup.link:SetText("https://www.wowhead.com/" .. AzerothCompendium:GetWowheadBranch() .. "/quest=" .. questID)
    popup:Show()
    popup.link:SetFocus()
    popup.link:HighlightText()

    return true
end

local COIN_ICON = "%d|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"
local function GetMoneyText(money)
    local gold = floor(money / 10000)
    local silver = floor(money / 100) % 100
    local copper = money % 100
    local parts = {}
    if gold > 0 then tinsert(parts, format(COIN_ICON, gold, "Gold")) end
    if silver > 0 then tinsert(parts, format(COIN_ICON, silver, "Silver")) end
    if copper > 0 or #parts == 0 then tinsert(parts, format(COIN_ICON, copper, "Copper")) end

    return table.concat(parts, " ")
end

local function GetFactionName(factionID)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local data = C_Reputation.GetFactionDataByID(factionID)
        if type(data) == "table" and type(data.name) == "string" and data.name ~= "" then return data.name end
    end

    if GetFactionInfoByID then
        local name = GetFactionInfoByID(factionID)
        if type(name) == "string" and name ~= "" then return name end
    end

    return tostring(factionID)
end

local function GetMapName(uiMapID)
    if C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(uiMapID)
        if type(info) == "table" and type(info.name) == "string" then return info.name end
    end

    return nil
end

local function AddRewardItemsToTooltip(label, list)
    if list == nil or #list == 0 then return end
    GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(label), 1, 0.82, 0)
    for _, entry in ipairs(list) do
        local name, _, quality, _, icon = AzerothCompendium:GetItemDisplay(entry[1])
        local color = quality ~= nil and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        local text = format("|T%s:14:14:0:0|t %s", tostring(icon or 134400), name or AzerothCompendium:Trans("LID_LOADING"))
        if (entry[2] or 1) > 1 then text = text .. " x" .. entry[2] end
        if color then
            GameTooltip:AddLine(text, color.r, color.g, color.b)
        else
            GameTooltip:AddLine(text, 0.6, 0.6, 0.6)
        end
    end
end

local function AddRewardsToTooltip(questID)
    local rewards = AzerothCompendium:GetQuestRewards(questID)
    local xp = AzerothCompendium:GetQuestRewardXP(questID)
    if rewards == nil and xp <= 0 then return end
    rewards = rewards or {}
    GameTooltip:AddLine(" ")
    AddRewardItemsToTooltip(AzerothCompendium:Trans("LID_QUESTREWARDS"), rewards.items)
    AddRewardItemsToTooltip(AzerothCompendium:Trans("LID_QUESTCHOICE"), rewards.choices)
    if xp > 0 then GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTXP")), tostring(xp), 0.9, 0.9, 0.9, 0.6, 0.4, 1) end
    if rewards.money then GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(_G.MONEY or "Money"), GetMoneyText(rewards.money), 0.9, 0.9, 0.9, 1, 1, 1) end
    for _, entry in ipairs(rewards.rep or {}) do
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(GetFactionName(entry[1])), format("+%d %s", entry[2], _G.REPUTATION or "Reputation"), 0.9, 0.9, 0.9, 0.3, 0.8, 1)
    end
end

local function HasQuestTooltipData(questID)
    if C_TooltipInfo == nil or C_TooltipInfo.GetHyperlink == nil then return true end
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, "quest:" .. questID)

    return ok and type(data) == "table" and type(data.lines) == "table" and #data.lines > 0
end

local function RequestQuestData(questID)
    if C_QuestLog and C_QuestLog.RequestLoadQuestByID then pcall(C_QuestLog.RequestLoadQuestByID, questID) end
end

local function ShowNodeTooltip(button)
    local node = button.node
    if node == nil then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local shown = false
    if HasQuestTooltipData(node.id) then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "quest:" .. node.id) end
    if not shown or not GameTooltip:IsOwned(button) or GameTooltip:NumLines() == 0 then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(node.name, 1, 0.82, 0)
        RequestQuestData(node.id)
    end

    AddQuestStatusToTooltip(node.id, node.quest, node)
    if node.outside then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTOUTSIDE")), 1, 0.82, 0) end
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[node.id]
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
    if startItem then
        local name, link = AzerothCompendium:GetItemDisplay(startItem[1])
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format("%s: %s", _G.ITEM or "Item", link or name or startItem[2])), 1, 0.82, 0)
        if giver then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format("%s: %s", _G.SOURCE or "Source", giver[5])), 0.75, 0.75, 0.75) end
    elseif giver then
        local mapID, _, _, instanceID = AzerothCompendium:GetQuestGiverLocation(node.id)
        local mapName = AzerothCompendium:GetQuestGiverInstanceName(instanceID) or (mapID and GetMapName(mapID))
        local text = giver[5]
        if mapName then text = format("%s (%s)", text, mapName) end
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTGIVER")), text, 0.9, 0.9, 0.9, 1, 1, 1)
    end

    AddRewardsToTooltip(node.id)
    if AzerothCompendium:IsQuestStartInInstance(node.id) then
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_QUESTSTARTSININSTANCE"), node.name)), 1, 0.82, 0)
    elseif giver then
        local locationText = startItem and "LID_SHOWQUESTITEMSOURCE" or "LID_SHOWQUESTGIVER"
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans(locationText), 0.9, 0.9, 0.9, 1, 0.82, 0)
    end

    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_RIGHTCLICK") .. ":"), AzerothCompendium:Trans("LID_SHAREQUEST"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel((_G.SHIFT_KEY_TEXT or "Shift") .. " + " .. AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), "Wowhead", 0.9, 0.9, 0.9, 1, 0.82, 0)

    GameTooltip:Show()
end

local SHARE_ERRORS = {
    nogroup = "LID_SHAREQUESTNOGROUP",
    notinlog = "LID_SHAREQUESTNOTINLOG",
    notshareable = "LID_SHAREQUESTNOTSHAREABLE",
    unsupported = "LID_SHAREQUESTUNSUPPORTED",
}

local function OnNodeClick(button, mouseButton)
    local node = button.node
    if node == nil or button.tree.dragMoved then return end
    if mouseButton == "RightButton" then
        local shared, reason = AzerothCompendium:ShareQuest(node.id)
        if not shared then AzerothCompendium:INFO(format(AzerothCompendium:Trans(SHARE_ERRORS[reason] or "LID_SHAREQUESTNOTSHAREABLE"), node.name)) end

        return
    end

    if ShowQuestWowheadLink(node.id) then return end
    if AzerothCompendium:IsQuestStartInInstance(node.id) then
        AzerothCompendium:INFO(format(AzerothCompendium:Trans("LID_QUESTSTARTSININSTANCE"), node.name))

        return
    end

    local waypointSet, reason = AzerothCompendium:SetQuestWaypoint(node.id)
    if waypointSet then
        local mapID = AzerothCompendium:GetQuestGiverLocation(node.id)
        AzerothCompendium:OpenWorldMapTo(mapID)
    else
        local message = reason == "combat" and "LID_WAYPOINTCOMBAT" or "LID_NOQUESTGIVER"
        AzerothCompendium:INFO(AzerothCompendium:Trans(message))
    end
end

local function CreateBorder(frame, layer, sublevel)
    local edges = {}
    for index = 1, 4 do
        edges[index] = frame:CreateTexture(nil, layer, nil, sublevel)
    end

    edges[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges[1]:SetHeight(3)
    edges[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[2]:SetHeight(3)
    edges[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[3]:SetWidth(3)
    edges[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[4]:SetWidth(3)
    function edges:SetColor(r, g, b, a)
        for _, edge in ipairs(self) do
            edge:SetColorTexture(r, g, b, a)
        end
    end

    return edges
end

local function CreateRewardIcon(node)
    local button = CreateFrame("Button", nil, node)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button.qualityFrame = button:CreateTexture(nil, "BACKGROUND")
    button.qualityFrame:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button.qualityFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.qualityFrame:SetColorTexture(0.9, 0.75, 0.3, 0.9)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -2)
    button:SetScript("OnMouseDown", function(sel, mouseButton) node.tree:StartDrag(mouseButton) end)
    button:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(sel.itemID)
        else
            GameTooltip:SetHyperlink("item:" .. sel.itemID)
        end

        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans(sel.provided and "LID_QUESTPROVIDEDITEM" or sel.choice and "LID_QUESTCHOICE" or "LID_QUESTREWARDS")), 1, 0.82, 0)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    button:SetScript("OnClick", function(sel)
        local _, link = AzerothCompendium:GetItemDisplay(sel.itemID)
        if link and IsModifiedClick and IsModifiedClick() and HandleModifiedItemClick then HandleModifiedItemClick(link) end
    end)

    return button
end

local function CreateNode(canvas, tree)
    local node = CreateFrame("Button", nil, canvas)
    node.tree = tree
    node:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    node.background = node:CreateTexture(nil, "BACKGROUND")
    node.background:SetAllPoints(node)
    node.background:SetColorTexture(0.06, 0.06, 0.08, 0.95)
    node.border = CreateBorder(node, "BORDER", 0)
    local highlight = node:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(node)
    highlight:SetColorTexture(1, 1, 1, 0.08)
    node.statusIcon = node:CreateTexture(nil, "ARTWORK")
    node.statusIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    node.statusIcon:SetPoint("TOPLEFT", node, "TOPLEFT", NODE_PAD_X - 1, -NODE_PAD_TOP)
    node.title = node:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    node.tagIcon = node:CreateTexture(nil, "ARTWORK")
    node.tagIcon:Hide()
    node.title:SetPoint("LEFT", node.statusIcon, "RIGHT", 3, 0)
    node.outsideIcon = node:CreateTexture(nil, "ARTWORK")
    node.outsideIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    node.outsideIcon:SetPoint("TOPRIGHT", node, "TOPRIGHT", -NODE_PAD_X + 1, -NODE_PAD_TOP)
    node.outsideIcon:SetTexture(OUTSIDE_ICON)
    node.outsideIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    node.outsideIcon:Hide()
    node.groupText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.groupText:SetJustifyH("RIGHT")
    node.groupText:SetWordWrap(false)
    node.groupText:Hide()
    node.title:SetPoint("RIGHT", node, "RIGHT", -NODE_PAD_X, 0)
    node.title:SetJustifyH("LEFT")
    node.title:SetWordWrap(false)
    node.levelText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.levelText:SetJustifyH("LEFT")
    node.levelText:SetWordWrap(false)
    node.classText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.classText:SetJustifyH("RIGHT")
    node.classText:SetWordWrap(false)
    node.phaseText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.phaseText:SetJustifyH("LEFT")
    node.phaseText:SetWordWrap(false)
    node.phaseText:SetTextColor(0.75, 0.75, 0.75)
    node.rewardLabel = node:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    node.rewardLabel:SetJustifyH("LEFT")
    node.rewardLabel:SetText(AzerothCompendium:Trans("LID_QUESTREWARDS") .. ":")
    node.overflow = node:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    node.overflow:SetJustifyH("RIGHT")
    node.xpText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.xpText:SetJustifyH("LEFT")
    node.xpText:SetWordWrap(false)
    node.moneyText = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.moneyText:SetJustifyH("RIGHT")
    node.moneyText:SetWordWrap(false)
    node.icons = {}
    node.providedLabel = node:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    node.providedLabel:SetJustifyH("LEFT")
    node.providedIcon = CreateRewardIcon(node)
    node.providedIcon.provided = true
    node.providedName = node:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    node.providedName:SetJustifyH("LEFT")
    node.providedName:SetWordWrap(false)
    node:SetScript("OnEnter", function(sel)
        sel.tree:SetQuestHighlight(sel.node and sel.node.id)
        ShowNodeTooltip(sel)
    end)

    node:SetScript("OnLeave", function(sel)
        sel.tree:SetQuestHighlight(nil)
        AzerothCompendium:HideGameTooltip()
    end)
    node:SetScript("OnMouseDown", function(sel, mouseButton) sel.tree:StartDrag(mouseButton) end)
    node:SetScript("OnClick", OnNodeClick)

    return node
end

local function GetRewardEntries(questID)
    local rewards = AzerothCompendium:GetQuestRewards(questID)
    local entries = {}
    if rewards == nil then return entries, nil end
    for _, entry in ipairs(rewards.items or {}) do
        tinsert(entries, {entry[1], entry[2] or 1, false})
    end

    for _, entry in ipairs(rewards.choices or {}) do
        tinsert(entries, {entry[1], entry[2] or 1, true})
    end

    return entries, rewards
end

local function GetProvidedItem(questID)
    for _, attunement in pairs(AzerothCompendium.ATTUNEMENTS or {}) do
        if attunement.key ~= nil and attunement.opens == nil then
            for _, doneID in ipairs(attunement.done or {}) do
                if doneID == questID then return attunement.key end
            end
        end
    end

    return nil
end

local function GetNodeRequiredLevel(node)
    local level = AzerothCompendium:GetQuestRequiredLevel(node.quest or node.id)

    return type(level) == "number" and level > 0 and level or nil
end

local function GetPhaseText(node)
    local phases = node.phases
    if phases == nil then return nil end
    if phases.accept then
        local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
        if startItem then
            local name = AzerothCompendium:GetItemDisplay(startItem[1])
            return format("%s: %s", _G.ITEM or "Item", name or startItem[2])
        end

        local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[node.id]
        return giver and giver[5] and format("%s: %s", AzerothCompendium:Trans("LID_QUESTGIVER"), giver[5]) or nil
    end

    if phases.turnin then
        local ender = AzerothCompendium.QUESTENDERS and AzerothCompendium.QUESTENDERS[node.id]
        return ender and ender[5] and format("%s: %s", AzerothCompendium:Trans("LID_QUESTENDER"), ender[5]) or nil
    end

    return AzerothCompendium:Trans("LID_QUESTPHASEDO")
end

local function IsCompactNode(node)
    return node.phases ~= nil and not node.phases.turnin
end

local function GetNodeHeight(node)
    local height = NODE_PAD_TOP + TITLE_H + NODE_PAD_BOTTOM
    if GetPhaseText(node) then height = height + TEXT_LINE_H end
    if GetProvidedItem(node.id) then height = height + REWARD_LINE_H end
    if not IsCompactNode(node) then height = height + REWARD_LINE_H + TEXT_LINE_H end

    if GetNodeRequiredLevel(node) or AzerothCompendium:GetQuestClasses(node.id) then height = height + TEXT_LINE_H end

    return height
end

local function PlaceLine(region, button, y, height)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", button, "TOPLEFT", NODE_PAD_X, -y)
    region:SetPoint("TOPRIGHT", button, "TOPRIGHT", -NODE_PAD_X, -y)
    region:SetHeight(height)
end

local function UpdateNode(button, node, width)
    button.node = node
    button:SetSize(width, node.h)
    local status = GetQuestStatus(node.id, node)
    local statusIcon = STATUS_ICON[status]
    button.statusIcon:SetTexture(statusIcon[1])
    button.statusIcon:SetDesaturated(statusIcon[2])
    local tint = statusIcon[3]
    button.statusIcon:SetVertexColor(tint and tint[1] or 1, tint and tint[2] or 1, tint and tint[3] or 1)
    local color = GetQuestDifficultyColorCode(node.level)
    local prefix = ""
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
    if startItem then
        local _, _, _, _, icon = AzerothCompendium:GetItemDisplay(startItem[1])
        prefix = format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t ", tostring(icon or 134400), STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    end

    if node.outside then button.outsideIcon:Show() else button.outsideIcon:Hide() end
    local tagIcon = AzerothCompendium.QUESTTAGS and GetQuestTagIcon(AzerothCompendium.QUESTTAGS[node.id])
    button.title:ClearAllPoints()
    if tagIcon then
        button.tagIcon:ClearAllPoints()
        if tagIcon[3] then
            button.tagIcon:SetTexCoord(0, 1, 0, 1)
            button.tagIcon:SetAtlas(tagIcon[1])
            button.tagIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
            button.tagIcon:SetPoint("LEFT", button.statusIcon, "RIGHT", 3, 0)
            button.title:SetPoint("LEFT", button.tagIcon, "RIGHT", 3, 0)
        elseif tagIcon[2] then
            button.tagIcon:SetTexCoord(0, 1, 0, 1)
            button.tagIcon:SetAtlas(tagIcon[1])
            button.tagIcon:SetSize(QUEST_TAG_ATLAS_SIZE, QUEST_TAG_ATLAS_SIZE)
            button.tagIcon:SetPoint("LEFT", button.statusIcon, "RIGHT", 3 - QUEST_TAG_ATLAS_INSET, 0)
            button.title:SetPoint("LEFT", button.tagIcon, "RIGHT", 3 - QUEST_TAG_ATLAS_INSET, 0)
        else
            button.tagIcon:SetTexture(tagIcon[1])
            button.tagIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            button.tagIcon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
            button.tagIcon:SetPoint("LEFT", button.statusIcon, "RIGHT", 3, 0)
            button.title:SetPoint("LEFT", button.tagIcon, "RIGHT", 3, 0)
        end

        button.tagIcon:Show()
    else
        button.tagIcon:Hide()
        button.title:SetPoint("LEFT", button.statusIcon, "RIGHT", 3, 0)
    end

    local rightInset = node.outside and NODE_PAD_X + STATUS_ICON_SIZE + 3 or NODE_PAD_X
    local groupCount, groupTotal = GetGroupQuestCount(node.id)
    if groupCount then
        button.groupText:ClearAllPoints()
        button.groupText:SetPoint("RIGHT", button, "TOPRIGHT", -rightInset, -(NODE_PAD_TOP + STATUS_ICON_SIZE / 2))
        button.groupText:SetText(format("%d/%d", groupCount, groupTotal))
        if groupCount >= groupTotal then
            button.groupText:SetTextColor(0.4, 0.9, 0.4)
        elseif groupCount > 0 then
            button.groupText:SetTextColor(1, 0.82, 0)
        else
            button.groupText:SetTextColor(0.6, 0.6, 0.6)
        end

        button.groupText:Show()
        button.title:SetPoint("RIGHT", button.groupText, "LEFT", -4, 0)
    else
        button.groupText:Hide()
        button.title:SetPoint("RIGHT", button, "RIGHT", -rightInset, 0)
    end

    button.title:SetText(prefix .. color .. "[" .. node.level .. "] " .. node.name .. "|r")
    local border = STATUS_BORDER[status]
    button.border:SetColor(border[1], border[2], border[3], border[4])
    local y = NODE_PAD_TOP + TITLE_H
    local requiredLevel = GetNodeRequiredLevel(node)
    local classText = AzerothCompendium:GetQuestClassText(node.id)
    if requiredLevel then
        PlaceLine(button.levelText, button, y, TEXT_LINE_H)
        button.levelText:SetText(AzerothCompendium:Trans("LID_REQUIRESLEVEL", nil, requiredLevel))
        local playerLevel = UnitLevel and UnitLevel("player") or requiredLevel
        if playerLevel < requiredLevel then
            button.levelText:SetTextColor(1, 0.25, 0.25)
        else
            button.levelText:SetTextColor(0.75, 0.75, 0.75)
        end

        button.levelText:Show()
    else
        button.levelText:Hide()
    end

    if classText then
        PlaceLine(button.classText, button, y, TEXT_LINE_H)
        button.classText:SetText(classText)
        button.classText:Show()
    else
        button.classText:Hide()
    end

    if requiredLevel or classText then y = y + TEXT_LINE_H end

    local phaseText = GetPhaseText(node)
    if phaseText then
        PlaceLine(button.phaseText, button, y, TEXT_LINE_H)
        button.phaseText:SetText(phaseText)
        button.phaseText:Show()
        y = y + TEXT_LINE_H
    else
        button.phaseText:Hide()
    end

    local providedItem = GetProvidedItem(node.id)
    if providedItem then
        local name, _, quality, _, texture = AzerothCompendium:GetItemDisplay(providedItem)
        if name == nil and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(providedItem) end
        local itemColor = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        button.providedLabel:SetText(AzerothCompendium:Trans("LID_QUESTPROVIDEDITEM") .. ":")
        button.providedLabel:ClearAllPoints()
        button.providedLabel:SetPoint("LEFT", button, "TOPLEFT", NODE_PAD_X, -(y + REWARD_LINE_H / 2))
        button.providedLabel:Show()
        local icon = button.providedIcon
        icon.itemID = providedItem
        icon.icon:SetTexture(texture or 134400)
        icon.qualityFrame:SetColorTexture(itemColor and itemColor.r or 0.9, itemColor and itemColor.g or 0.75, itemColor and itemColor.b or 0.3, 0.9)
        icon.count:SetText("")
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", button.providedLabel, "RIGHT", 6, 0)
        icon:Show()
        button.providedName:ClearAllPoints()
        button.providedName:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        button.providedName:SetPoint("RIGHT", button, "RIGHT", -NODE_PAD_X, 0)
        button.providedName:SetText((itemColor and itemColor.hex or "") .. (name or ("Item " .. providedItem)) .. (itemColor and itemColor.hex and "|r" or ""))
        button.providedName:Show()
        y = y + REWARD_LINE_H
    else
        button.providedLabel:Hide()
        button.providedIcon:Hide()
        button.providedName:Hide()
    end

    if IsCompactNode(node) then
        button.rewardLabel:Hide()
        button.overflow:Hide()
        button.xpText:Hide()
        button.moneyText:Hide()
        for _, icon in ipairs(button.icons) do
            icon:Hide()
        end

        button:Show()

        return
    end

    button.xpText:Show()
    button.moneyText:Show()
    local entries, rewards = GetRewardEntries(node.id)
    local shown = 0
    button.rewardLabel:SetText(AzerothCompendium:Trans("LID_QUESTREWARDS") .. ":")
    button.rewardLabel:ClearAllPoints()
    button.rewardLabel:SetPoint("LEFT", button, "TOPLEFT", NODE_PAD_X, -(y + REWARD_LINE_H / 2))
    button.rewardLabel:Show()
    button.overflow:Hide()
    if #entries > 0 then
        local step = ICON_SIZE + ICON_GAP
        local free = width - 2 * NODE_PAD_X - (button.rewardLabel:GetStringWidth() or 0) - 6
        local capacity = max(1, floor((free + ICON_GAP) / step))
        shown = #entries
        if shown > capacity then shown = max(1, capacity - 1) end
        for index = 1, shown do
            local icon = button.icons[index]
            if icon == nil then
                icon = CreateRewardIcon(button)
                button.icons[index] = icon
            end

            local entry = entries[index]
            local _, _, quality, _, texture = AzerothCompendium:GetItemDisplay(entry[1])
            icon.itemID = entry[1]
            AzerothCompendium:UpdateWishlistStar(icon, icon.icon, entry[1])
            icon.choice = entry[3]
            icon.icon:SetTexture(texture or 134400)
            icon.count:SetText(entry[2] > 1 and entry[2] or "")
            local qualityColor = quality ~= nil and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            if qualityColor then
                icon.qualityFrame:SetColorTexture(qualityColor.r, qualityColor.g, qualityColor.b, 1)
            else
                icon.qualityFrame:SetColorTexture(0.4, 0.4, 0.4, 1)
            end
            icon:ClearAllPoints()
            icon:SetPoint("RIGHT", button, "TOPRIGHT", -NODE_PAD_X - (shown - index) * step, -(y + REWARD_LINE_H / 2))
            icon:Show()
        end

        if #entries > shown then
            button.overflow:ClearAllPoints()
            button.overflow:SetPoint("RIGHT", button.icons[1], "LEFT", -3, 0)
            button.overflow:SetText("+" .. (#entries - shown))
            button.overflow:Show()
        end
    end

    y = y + REWARD_LINE_H

    for index = shown + 1, #button.icons do
        button.icons[index]:Hide()
    end

    PlaceLine(button.xpText, button, y, TEXT_LINE_H)
    PlaceLine(button.moneyText, button, y, TEXT_LINE_H)
    local xp = AzerothCompendium:GetQuestRewardXP(node.id)
    local money = rewards and rewards.money or 0
    button.xpText:SetText(xp .. " " .. AzerothCompendium:Trans("LID_QUESTXPSHORT"))
    button.moneyText:SetText(GetMoneyText(money))
    if xp > 0 then button.xpText:SetTextColor(1, 1, 1) else button.xpText:SetTextColor(1, 0.25, 0.25) end
    if money > 0 then button.moneyText:SetTextColor(1, 1, 1) else button.moneyText:SetTextColor(1, 0.25, 0.25) end
    button:Show()
end

local function SortNodes(a, b)
    if a.level ~= b.level then return a.level < b.level end
    if a.name ~= b.name then return a.name < b.name end

    return a.id < b.id
end

local function ComputeLayers(nodes)
    for _, node in ipairs(nodes) do
        node.layer = nil
    end

    local Layer
    local function ParentLayer(parent, section, stack)
        if parent.section == section then return Layer(parent, stack) + 1 end
        if parent.section < section or stack[parent] then return 0 end
        stack[parent] = true
        local layer = 0
        for _, grandParent in ipairs(parent.parents) do
            layer = max(layer, ParentLayer(grandParent, section, stack))
        end

        stack[parent] = nil

        return layer
    end

    Layer = function(node, stack)
        if node.layer ~= nil then return node.layer end
        if stack[node] then return 0 end
        stack[node] = true
        local layer = 0
        for _, parent in ipairs(node.parents) do
            local parentLayer = ParentLayer(parent, node.section, stack)
            if parent.section > node.section then parentLayer = max(0, parentLayer - 1) end
            layer = max(layer, parentLayer)
        end

        stack[node] = nil
        node.layer = layer

        return layer
    end

    for _, node in ipairs(nodes) do
        Layer(node, {})
    end
end

local function BuildComponents(nodes)
    local owner = {}
    local components = {}
    for _, start in ipairs(nodes) do
        if owner[start] == nil then
            local component = {
                nodes = {},
                level = math.huge,
                hasTop = false
            }

            owner[start] = component
            local stack = {start}
            while #stack > 0 do
                local node = tremove(stack)
                tinsert(component.nodes, node)
                if node.section <= 2 then component.hasTop = true end
                if node.instance and node.level < component.level then component.level = node.level end
                for _, list in ipairs({node.parents, node.children}) do
                    for _, other in ipairs(list) do
                        if owner[other] == nil then
                            owner[other] = component
                            tinsert(stack, other)
                        end
                    end
                end
            end

            table.sort(component.nodes, SortNodes)
            tinsert(components, component)
        end
    end

    table.sort(components, function(a, b)
        if a.level ~= b.level then return a.level < b.level end

        return SortNodes(a.nodes[1], b.nodes[1])
    end)

    return components
end

local function ArrangeComponent(component)
    local layers = {}
    for section = 1, SECTION_COUNT do
        layers[section] = {}
    end

    for _, node in ipairs(component.nodes) do
        local list = layers[node.section]
        list[node.layer + 1] = list[node.layer + 1] or {}
        tinsert(list[node.layer + 1], node)
    end

    component.layers = {}
    for section = 1, SECTION_COUNT do
        component.layers[section] = #layers[section]
    end

    local placed = {}
    local width = 1
    for section = 1, SECTION_COUNT do
        for _, layer in ipairs(layers[section]) do
            for _, node in ipairs(layer) do
                local sum = 0
                local count = 0
                for _, parent in ipairs(node.parents) do
                    if placed[parent] then
                        sum = sum + parent.column
                        count = count + 1
                    end
                end

                node.desired = count > 0 and sum / count or nil
            end

            table.sort(layer, function(a, b)
                if (a.desired ~= nil) ~= (b.desired ~= nil) then return a.desired ~= nil end
                if a.desired ~= nil and a.desired ~= b.desired then return a.desired < b.desired end

                return SortNodes(a, b)
            end)

            local cursor = 0
            for _, node in ipairs(layer) do
                local column = cursor
                if node.desired ~= nil then column = max(cursor, floor(node.desired + 0.5)) end
                node.column = column
                cursor = column + 1
                placed[node] = true
                width = max(width, cursor)
            end
        end
    end

    component.width = width
end

local function CreateBox(canvas, titleText)
    local box = CreateFrame("Frame", nil, canvas)
    box.background = box:CreateTexture(nil, "BACKGROUND", nil, -8)
    box.background:SetAllPoints(box)
    box.background:SetColorTexture(0, 0, 0, 0.3)
    box.border = CreateBorder(box, "BACKGROUND", -6)
    box.border:SetColor(0.75, 0.6, 0.25, 0.7)
    box.title = box:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    box.title:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -5)
    box.title:SetPoint("TOPRIGHT", box, "TOPRIGHT", -8, -5)
    box.title:SetJustifyH("LEFT")
    box.title:SetWordWrap(false)
    box.title:SetText(titleText)
    box.empty = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    box.empty:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -HEADER_H - 2)
    box.empty:Hide()

    return box
end

local function GetScrollRange(scroll, horizontal)
    local child = scroll:GetScrollChild()
    local range = horizontal and scroll:GetHorizontalScrollRange() or scroll:GetVerticalScrollRange()
    if child then
        if horizontal then
            range = (child:GetWidth() or 0) - (scroll:GetWidth() or 0)
        else
            range = (child:GetHeight() or 0) - (scroll:GetHeight() or 0)
        end
    end

    if range == nil or range <= 1 then return 0 end

    return range
end

local function ClampScroll(scroll, horizontal, value)
    return min(GetScrollRange(scroll, horizontal), max(0, value))
end

local function HasMinimalScrollBar()
    if ScrollUtil == nil or ScrollUtil.InitScrollFrameWithScrollBar == nil or BaseScrollBoxEvents == nil then return false end

    return AzerothCompendium:CheckTemplates("MinimalScrollBar")
end

local function GetAtlasInfo(atlas)
    if atlas == nil or C_Texture == nil or C_Texture.GetAtlasInfo == nil then return nil end

    return C_Texture.GetAtlasInfo(atlas)
end

local function SetRotatedAtlas(texture, atlas)
    local info = GetAtlasInfo(atlas)
    if info == nil then return false end
    texture:SetTexture(info.file or info.filename)
    local left, right, top, bottom = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
    texture:SetTexCoord(right, top, left, top, right, bottom, left, bottom)
    texture:SetSize(info.height, info.width)

    return true
end

local function LayoutHorizontalPieces(frame, beginAtlas, middleAtlas, endAtlas)
    SetRotatedAtlas(frame.Begin, beginAtlas)
    SetRotatedAtlas(frame.Middle, middleAtlas)
    SetRotatedAtlas(frame.End, endAtlas)
    frame.Begin:ClearAllPoints()
    frame.Begin:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.End:ClearAllPoints()
    frame.End:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    frame.Middle:ClearAllPoints()
    frame.Middle:SetPoint("TOPLEFT", frame.Begin, "TOPRIGHT", 0, 0)
    frame.Middle:SetPoint("BOTTOMRIGHT", frame.End, "BOTTOMLEFT", 0, 0)
end

local function CreateMinimalHBar(parent)
    if not HasMinimalScrollBar() or GetAtlasInfo("minimal-scrollbar-track-top") == nil then return nil end
    local ok, bar = pcall(CreateFrame, "EventFrame", nil, parent, "MinimalScrollBar")
    if not ok or bar == nil or bar.Track == nil or bar.Track.Thumb == nil or bar.Back == nil or bar.Forward == nil then return nil end
    if bar.SetHorizontal then
        bar:SetHorizontal(true)
    else
        bar.isHorizontal = true
    end

    bar.thumbAnchor = "LEFT"
    bar:SetHeight(MINIMAL_BAR_W)
    local track = bar.Track
    track:ClearAllPoints()
    track:SetPoint("LEFT", bar, "LEFT", MINIMAL_STEPPER_INSET, 0)
    track:SetPoint("RIGHT", bar, "RIGHT", -MINIMAL_STEPPER_INSET, 0)
    track:SetHeight(MINIMAL_BAR_W)
    LayoutHorizontalPieces(track, "minimal-scrollbar-track-top", "!minimal-scrollbar-track-middle", "minimal-scrollbar-track-bottom")
    local thumb = track.Thumb
    thumb.isHorizontal = true
    thumb:ClearAllPoints()
    thumb:SetHeight(MINIMAL_BAR_W)
    thumb:SetScript("OnSizeChanged", nil)
    thumb.OnButtonStateChanged = function(sel)
        local middleAtlas, beginAtlas, endAtlas = sel:GetAtlas()
        LayoutHorizontalPieces(sel, beginAtlas, middleAtlas, endAtlas)
    end
    thumb:OnButtonStateChanged()
    for index, stepper in ipairs({bar.Back, bar.Forward}) do
        local point = index == 1 and "LEFT" or "RIGHT"
        stepper:ClearAllPoints()
        stepper:SetPoint(point, bar, point, 0, 0)
        stepper:SetSize(MINIMAL_STEPPER_H, MINIMAL_STEPPER_W)
        stepper.Texture:ClearAllPoints()
        stepper.Texture:SetPoint("CENTER", stepper, "CENTER", 0, 0)
        stepper.OnButtonStateChanged = function(sel)
            if not SetRotatedAtlas(sel.Texture, sel:GetAtlas()) then SetRotatedAtlas(sel.Texture, sel.normalTexture) end
        end
        stepper:OnButtonStateChanged()
    end

    return bar
end

local function CreateHBar(tree, scroll, leftAnchor, anchor)
    local bar = CreateMinimalHBar(tree)
    local syncing = false
    if bar then
        bar:SetPoint("LEFT", leftAnchor, "RIGHT", 10, 0)
        bar:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        bar:RegisterCallback(BaseScrollBoxEvents.OnScroll, function(_, percentage)
            if syncing then return end
            local range = GetScrollRange(scroll, true)
            scroll:SetHorizontalScroll(ClampScroll(scroll, true, percentage * range))
        end, scroll)
        bar.Sync = function(sel)
            local range = GetScrollRange(scroll, true)
            local viewW = scroll:GetWidth() or 0
            if range <= 0 or viewW <= 0 then
                sel:Hide()

                return
            end

            syncing = true
            sel:SetVisibleExtentPercentage(viewW / (viewW + range))
            if sel.SetPanExtentPercentage then sel:SetPanExtentPercentage(min(1, WHEEL_STEP / range)) end
            sel:SetScrollPercentage(min(1, scroll:GetHorizontalScroll() / range), true)
            syncing = false
            sel:Show()
        end
    else
        bar = CreateFrame("Slider", nil, tree)
        bar:SetOrientation("HORIZONTAL")
        bar:SetPoint("LEFT", leftAnchor, "RIGHT", 10, 0)
        bar:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        bar:SetHeight(HBAR_H)
        bar:SetMinMaxValues(0, 0)
        bar:SetValueStep(1)
        bar:SetValue(0)
        bar.track = bar:CreateTexture(nil, "BACKGROUND")
        bar.track:SetAllPoints(bar)
        bar.track:SetColorTexture(0, 0, 0, 0.45)
        bar.thumb = bar:CreateTexture(nil, "OVERLAY")
        bar.thumb:SetColorTexture(0.75, 0.6, 0.25, 0.9)
        bar.thumb:SetSize(HBAR_MIN_THUMB, HBAR_H)
        bar:SetThumbTexture(bar.thumb)
        bar:SetScript("OnValueChanged", function(_, value)
            if not syncing then scroll:SetHorizontalScroll(ClampScroll(scroll, true, value)) end
        end)

        bar.Sync = function(sel)
            local range = GetScrollRange(scroll, true)
            local barW = sel:GetWidth() or 0
            local viewW = scroll:GetWidth() or 0
            syncing = true
            sel:SetMinMaxValues(0, range)
            sel:SetValue(min(range, scroll:GetHorizontalScroll()))
            syncing = false
            if range <= 0 or barW <= 0 then
                sel:Hide()

                return
            end

            sel.thumb:SetWidth(max(HBAR_MIN_THUMB, floor(barW * viewW / (viewW + range))))
            sel:Show()
        end
    end

    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", function(sel, delta)
        scroll:SetHorizontalScroll(ClampScroll(scroll, true, scroll:GetHorizontalScroll() - delta * WHEEL_STEP))
        sel:Sync()
    end)

    return bar
end

local function FormatZoom(value)
    return format("%d%%", floor(value + 0.5))
end

local function CreateZoomSlider(tree, onChange)
    local ok, slider = pcall(CreateFrame, "Frame", nil, tree, "MinimalSliderWithSteppersTemplate")
    if ok and slider ~= nil and type(slider.Init) == "function" and type(slider.RegisterCallback) == "function" and slider.Slider then
        slider:SetPoint("RIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W - ZOOM_LABEL_W, BOTTOM_H / 2)
        slider:SetSize(ZOOM_BAR_W, BOTTOM_H)
        local formatters = {}
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then formatters[MinimalSliderWithSteppersMixin.Label.Right] = FormatZoom end
        slider:Init(100, ZOOM_MIN * 100, ZOOM_MAX * 100, (ZOOM_MAX - ZOOM_MIN) * 100 / ZOOM_BAR_STEP, formatters)
        slider:RegisterCallback("OnValueChanged", function(_, value) onChange(value) end, tree)
        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel", function(sel, delta) sel.Slider:SetValue(sel.Slider:GetValue() + delta * ZOOM_BAR_STEP) end)

        return slider
    end

    local zoomText = tree:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    zoomText:SetPoint("RIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W, BOTTOM_H / 2)
    zoomText:SetSize(34, HBAR_H + 2)
    zoomText:SetJustifyH("RIGHT")
    zoomText:SetText(FormatZoom(100))
    slider = CreateFrame("Slider", nil, tree)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("RIGHT", zoomText, "LEFT", -4, 0)
    slider:SetSize(ZOOM_BAR_W, HBAR_H)
    slider:SetMinMaxValues(ZOOM_MIN * 100, ZOOM_MAX * 100)
    slider:SetValueStep(ZOOM_BAR_STEP)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:SetValue(100)
    slider.track = slider:CreateTexture(nil, "BACKGROUND")
    slider.track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    slider.track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    slider.track:SetHeight(4)
    slider.track:SetColorTexture(0, 0, 0, 0.6)
    slider.thumb = slider:CreateTexture(nil, "OVERLAY")
    slider.thumb:SetColorTexture(0.75, 0.6, 0.25, 1)
    slider.thumb:SetSize(8, HBAR_H)
    slider:SetThumbTexture(slider.thumb)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnValueChanged", function(_, value)
        zoomText:SetText(FormatZoom(value))
        onChange(value)
    end)

    slider:SetScript("OnMouseWheel", function(sel, delta) sel:SetValue(sel:GetValue() + delta * ZOOM_BAR_STEP) end)

    return slider
end

local function GetInstanceLabel(id)
    local inst = AzerothCompendium:GetInstanceByID(id)

    return inst and AzerothCompendium:GetInstanceName(inst) or tostring(id)
end

local function GetAttunementNpcName(attunement)
    if attunement.sourceNpc == nil then return nil end
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        for _, boss in ipairs(inst.bosses or {}) do
            for _, npcID in ipairs(boss.npcs or {}) do
                if npcID == attunement.sourceNpc then return AzerothCompendium:GetBossName(boss) end
            end
        end
    end

    return nil
end

local function GetAttunementDetail(attunement)
    local npcName = GetAttunementNpcName(attunement)
    if attunement.source ~= nil then
        if npcName then return format(AzerothCompendium:Trans("LID_ATTUNEFOUNDNEAR"), GetInstanceLabel(attunement.source), npcName) end

        return format(AzerothCompendium:Trans("LID_ATTUNEFOUNDIN"), GetInstanceLabel(attunement.source))
    end

    if attunement.opens ~= nil then
        local names = {}
        for _, id in ipairs(attunement.opens) do
            local inst = AzerothCompendium:GetInstanceByID(id)
            tinsert(names, inst and AzerothCompendium:GetInstanceWingName(inst) or GetInstanceLabel(id))
        end

        local opens = format(AzerothCompendium:Trans("LID_ATTUNEOPENS"), table.concat(names, ", "))
        if npcName then return format(AzerothCompendium:Trans("LID_ATTUNENEAR"), npcName) .. " · " .. opens end

        return opens
    end

    return AzerothCompendium:Trans("LID_ATTUNEREQUIRED")
end

local function CreateKeyLine(box, tree)
    local line = CreateFrame("Button", nil, box)
    line:SetHeight(KEY_LINE_H)
    line:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -HEADER_H)
    line:SetPoint("TOPRIGHT", box, "TOPRIGHT", -10, -HEADER_H)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(ICON_SIZE, ICON_SIZE)
    line.icon:SetPoint("LEFT", line, "LEFT", 0, 0)
    line.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    line.status = line:CreateTexture(nil, "OVERLAY")
    line.status:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    line.status:SetPoint("LEFT", line.icon, "RIGHT", 4, 0)
    line.text = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    line.text:SetPoint("LEFT", line.status, "RIGHT", 4, 0)
    line.text:SetPoint("RIGHT", line, "RIGHT", 0, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    line:SetScript("OnEnter", function(sel)
        local attunement = sel.attunement
        if attunement == nil then return end
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(attunement.key)
        if AzerothCompendium:HasAttunementKey(attunement.key) then
            GameTooltip:AddLine(AzerothCompendium:Trans("LID_ATTUNEHASKEY"), 0.25, 1, 0.25)
        else
            GameTooltip:AddLine(AzerothCompendium:Trans("LID_ATTUNENOKEY"), 1, 0.25, 0.25)
        end

        GameTooltip:AddLine(GetAttunementDetail(attunement), 1, 1, 1, true)
        if attunement.source ~= nil and tree.OpenInstance then GameTooltip:AddLine(format(AzerothCompendium:Trans("LID_ATTUNEOPENSOURCE"), GetInstanceLabel(attunement.source)), 0.6, 0.6, 0.6, true) end
        GameTooltip:Show()
    end)

    line:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    line:SetScript("OnClick", function(sel)
        if sel.attunement and sel.attunement.source ~= nil and tree.OpenInstance then tree.OpenInstance(sel.attunement.source) end
    end)

    return line
end

local function GetKeyLineInfo(attunement)
    local name, _, quality, _, icon = AzerothCompendium:GetItemDisplay(attunement.key)
    if name == nil and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(attunement.key) end
    name = name or ("Item " .. attunement.key)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color and color.hex then name = color.hex .. name .. "|r" end

    return icon or 134400, AzerothCompendium:HasAttunementKey(attunement.key) and KEY_OWNED_ICON or KEY_MISSING_ICON, name .. "  |cffa0a0a0" .. GetAttunementDetail(attunement) .. "|r"
end

local function UpdateKeyLine(line, attunement, box)
    line.attunement = attunement
    if attunement == nil or attunement.key == nil then
        line:Hide()

        return
    end

    if line:GetParent() ~= box then
        line:SetParent(box)
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -HEADER_H)
        line:SetPoint("TOPRIGHT", box, "TOPRIGHT", -10, -HEADER_H)
    end

    line:SetFrameLevel(box:GetFrameLevel() + 1)
    local icon, status, text = GetKeyLineInfo(attunement)
    line.icon:SetTexture(icon)
    line.status:SetTexture(status)
    line.text:SetText(text)
    line:Show()
end

local function GetListNodeKey(node)
    local phases = node.phases
    local phase = phases and (phases.accept and "a" or phases.turnin and "t" or "o") or ""

    return node.id .. ":" .. node.section .. phase
end

local function BuildListTree(graph)
    local placed = {}
    local Attach
    Attach = function(node)
        placed[node] = true
        local item = {
            node = node,
            key = GetListNodeKey(node),
            children = {}
        }

        local children = {}
        for _, child in ipairs(node.children or {}) do
            if child.section == node.section and not placed[child] then tinsert(children, child) end
        end

        table.sort(children, SortNodes)
        for _, child in ipairs(children) do
            if not placed[child] then tinsert(item.children, Attach(child)) end
        end

        return item
    end

    local roots = {}
    local rest = {}
    for _, node in ipairs(graph) do
        local root = true
        for _, parent in ipairs(node.parents or {}) do
            if parent ~= node and parent.section == node.section then root = false end
        end

        tinsert(root and roots or rest, node)
    end

    table.sort(roots, SortNodes)
    table.sort(rest, SortNodes)
    local sections = {}
    for section = 1, SECTION_COUNT do
        sections[section] = {}
    end

    for _, list in ipairs({roots, rest}) do
        for _, node in ipairs(list) do
            if not placed[node] then tinsert(sections[node.section], Attach(node)) end
        end
    end

    return sections
end

local function CountListItems(items)
    local count = #items
    for _, item in ipairs(items) do
        count = count + CountListItems(item.children)
    end

    return count
end

local function FlattenList(items, depth, collapsed, out)
    for _, item in ipairs(items) do
        tinsert(out, {
            kind = "quest",
            item = item,
            key = item.key,
            depth = depth,
            hasChildren = #item.children > 0
        })

        if #item.children > 0 and not collapsed[item.key] then FlattenList(item.children, depth + 1, collapsed, out) end
    end
end

local function FindListPath(items, questID, path)
    for _, item in ipairs(items) do
        if item.node.id == questID then return true end
        tinsert(path, item.key)
        if FindListPath(item.children, questID, path) then return true end
        tremove(path)
    end

    return false
end

local function GetListQuestTitle(node)
    local prefix = ""
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
    if startItem then
        local _, _, _, _, icon = AzerothCompendium:GetItemDisplay(startItem[1])
        prefix = format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t ", tostring(icon or 134400), STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    end

    local tagIcon = AzerothCompendium.QUESTTAGS and GetQuestTagIcon(AzerothCompendium.QUESTTAGS[node.id])
    if tagIcon then
        if tagIcon[2] and CreateAtlasMarkup then
            prefix = prefix .. CreateAtlasMarkup(tagIcon[1], STATUS_ICON_SIZE, STATUS_ICON_SIZE) .. " "
        elseif not tagIcon[2] then
            prefix = prefix .. format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t ", tagIcon[1], STATUS_ICON_SIZE, STATUS_ICON_SIZE)
        end
    end

    local text = prefix .. GetQuestDifficultyColorCode(node.level) .. "[" .. node.level .. "] " .. node.name .. "|r"
    local classText = AzerothCompendium:GetQuestClassText(node.id)
    if classText then text = text .. "  " .. classText end
    local phaseText = GetPhaseText(node)
    if phaseText then text = text .. "  |cffa0a0a0" .. phaseText .. "|r" end

    return text
end

local function GetListQuestRight(node)
    local text = ""
    local groupCount, groupTotal = GetGroupQuestCount(node.id)
    if groupCount then
        local color = groupCount >= groupTotal and "|cff66e666" or groupCount > 0 and "|cffffd100" or "|cff999999"
        text = format("%s%d/%d|r", color, groupCount, groupTotal)
    end

    if node.outside then text = text .. format(" |T%s:%d:%d:0:0:64:64:5:59:5:59|t", OUTSIDE_ICON, STATUS_ICON_SIZE, STATUS_ICON_SIZE) end

    return text
end

local function CreateListRow(parent, tree)
    local row = CreateFrame("Button", nil, parent)
    row.tree = tree
    row:SetHeight(LIST_ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(1, 1, 1, 0.08)
    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(LIST_TOGGLE_SIZE, LIST_TOGGLE_SIZE)
    row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    row.toggle:SetScript("OnClick", function() tree:ToggleListKey(row.key) end)
    row.bar = row:CreateTexture(nil, "BORDER")
    row.bar:SetSize(3, LIST_ROW_H - 4)
    row.bar:SetPoint("RIGHT", row.toggle, "LEFT", -2, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
    row.icon:SetPoint("LEFT", row.toggle, "RIGHT", 3, 0)
    row.right = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.right:SetJustifyH("RIGHT")
    row.right:SetWordWrap(false)
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row:SetScript("OnMouseDown", function() tree.dragMoved = false end)
    row:SetScript("OnEnter", function(sel)
        if sel.kind == "quest" then
            tree:SetQuestHighlight(sel.node.id)
            ShowNodeTooltip(sel)
        elseif sel.kind == "key" then
            tree.keyLine:GetScript("OnEnter")(sel)
        end
    end)

    row:SetScript("OnLeave", function()
        tree:SetQuestHighlight(nil)
        AzerothCompendium:HideGameTooltip()
    end)

    row:SetScript("OnClick", function(sel, mouseButton)
        if sel.kind == "quest" then
            OnNodeClick(sel, mouseButton)
        elseif sel.kind == "section" then
            tree:ToggleListKey(sel.key)
        elseif sel.kind == "key" then
            tree.keyLine:GetScript("OnClick")(sel)
        end
    end)

    return row
end

local function UpdateListRow(row, entry, index, collapsed)
    row.kind = entry.kind
    row.key = entry.key
    row.node = entry.item and entry.item.node or nil
    row.attunement = entry.attunement
    row.toggle:ClearAllPoints()
    row.toggle:SetPoint("LEFT", row, "LEFT", 6 + (entry.depth or 0) * LIST_INDENT, 0)
    if entry.hasChildren then
        row.toggle:SetNormalTexture(collapsed[entry.key] and PLUS_TEXTURE or MINUS_TEXTURE)
        row.toggle:Show()
    else
        row.toggle:Hide()
    end

    row.icon:SetDesaturated(false)
    row.icon:SetVertexColor(1, 1, 1)
    row.icon:SetTexCoord(0, 1, 0, 1)
    row.bar:Hide()
    row.right:SetText("")
    if entry.kind == "section" then
        row.background:SetColorTexture(0.75, 0.6, 0.25, 0.22)
        row.icon:Hide()
        row.text:SetFontObject("GameFontNormal")
        row.text:SetText(AzerothCompendium:Trans(SECTION_TITLES[entry.section]))
        row.right:SetText("|cffa0a0a0" .. entry.count .. "|r")
    elseif entry.kind == "key" then
        row.background:SetColorTexture(0, 0, 0, index % 2 == 0 and 0.25 or 0)
        local icon, status, text = GetKeyLineInfo(entry.attunement)
        row.icon:SetTexture(icon)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon:Show()
        row.text:SetFontObject("GameFontHighlightSmall")
        row.text:SetText(format("|T%s:%d|t ", status, STATUS_ICON_SIZE) .. text)
    elseif entry.kind == "empty" then
        row.background:SetColorTexture(0, 0, 0, 0)
        row.icon:Hide()
        row.text:SetFontObject("GameFontDisableSmall")
        row.text:SetText(AzerothCompendium:Trans(SECTION_EMPTY[entry.section]))
    else
        local node = row.node
        local status = GetQuestStatus(node.id, node)
        local info = STATUS_ICON[status]
        local border = STATUS_BORDER[status]
        row.background:SetColorTexture(0, 0, 0, index % 2 == 0 and 0.25 or 0)
        row.bar:SetColorTexture(border[1], border[2], border[3], border[4])
        row.bar:Show()
        row.icon:SetTexture(info[1])
        row.icon:SetDesaturated(info[2])
        if info[3] then row.icon:SetVertexColor(info[3][1], info[3][2], info[3][3]) end
        row.icon:Show()
        row.text:SetFontObject("GameFontNormalSmall")
        row.text:SetText(GetListQuestTitle(node))
        row.right:SetText(GetListQuestRight(node))
    end

    row:Show()
end

local function CreateViewSwitch(tree, onChange)
    local switch = CreateFrame("Frame", nil, tree)
    switch:SetSize(2 * VIEW_BUTTON_W, BOTTOM_H - 2)
    switch:SetPoint("LEFT", tree, "BOTTOMLEFT", 4, BOTTOM_H / 2)
    switch.buttons = {}
    for index, mode in ipairs({"tree", "list"}) do
        local button = CreateFrame("Button", nil, switch, "UIPanelButtonTemplate")
        button:SetSize(VIEW_BUTTON_W, BOTTOM_H - 2)
        button:SetPoint("LEFT", switch, "LEFT", (index - 1) * VIEW_BUTTON_W, 0)
        button:SetNormalFontObject("GameFontNormalSmall")
        button:SetHighlightFontObject("GameFontHighlightSmall")
        button:SetScript("OnClick", function() onChange(mode) end)
        switch.buttons[mode] = button
    end

    function switch:SetMode(mode)
        for key, button in pairs(self.buttons) do
            if key == mode then
                button:LockHighlight()
                button:SetNormalFontObject("GameFontHighlightSmall")
            else
                button:UnlockHighlight()
                button:SetNormalFontObject("GameFontNormalSmall")
            end
        end
    end

    local function UpdateTexts()
        switch.buttons.tree:SetText(AzerothCompendium:Trans("LID_QUESTVIEWTREE"))
        switch.buttons.list:SetText(AzerothCompendium:Trans("LID_QUESTVIEWLIST"))
    end

    UpdateTexts()
    AzerothCompendium:OnLanguage(UpdateTexts)

    return switch
end

local function CreateLegend(tree, anchor)
    local legend = CreateFrame("Frame", nil, tree, AzerothCompendium:CheckTemplates("BackdropTemplate") and "BackdropTemplate" or nil)
    legend:SetFrameStrata("HIGH")
    legend:SetSize(320, 10)
    legend:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -8, 8)
    legend:EnableMouse(true)
    if legend.SetBackdrop then
        legend:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        legend:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
        legend:SetBackdropBorderColor(1, 0.82, 0, 1)
    end

    legend.title = legend:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    legend.title:SetPoint("TOPLEFT", legend, "TOPLEFT", 12, -12)
    local close = CreateFrame("Button", nil, legend, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", legend, "TOPRIGHT", 0, 0)
    local okay = CreateFrame("Button", nil, legend, "UIPanelButtonTemplate")
    okay:SetSize(90, 22)
    okay:SetPoint("BOTTOMRIGHT", legend, "BOTTOMRIGHT", -10, 10)
    okay:SetText(_G.OKAY or "OK")
    local rows = {}
    local function AddRow(text, setup)
        local row = legend:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row:SetJustifyH("LEFT")
        row:SetWidth(270)
        row:SetPoint("TOPLEFT", legend, "TOPLEFT", 38, -36 - #rows * 18)
        local icon = legend:CreateTexture(nil, "ARTWORK")
        icon:SetSize(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
        icon:SetPoint("RIGHT", row, "LEFT", -6, 0)
        local label = legend:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("RIGHT", row, "LEFT", -6, 0)
        setup(icon, label)
        tinsert(rows, {row, text})
    end

    for _, status in ipairs({"lowlevel", "open", "locked", "active", "ready", "complete"}) do
        AddRow("LID_LEGEND" .. string.upper(status), function(icon)
            local info = STATUS_ICON[status]
            icon:SetTexture(info[1])
            icon:SetDesaturated(info[2])
            if info[3] then icon:SetVertexColor(info[3][1], info[3][2], info[3][3]) end
        end)
    end

    AddRow("LID_LEGENDTAG", function(icon)
        local tag = GetQuestTagIcon(81)
        if tag and tag[2] then icon:SetAtlas(tag[1]) elseif tag then icon:SetTexture(tag[1]) end
    end)

    AddRow("LID_LEGENDPHASES", function(icon)
        icon:SetColorTexture(0.35, 0.65, 1, 0.9)
        icon:SetSize(LINE_W + 1, STATUS_ICON_SIZE)
    end)

    AddRow("LID_LEGENDCHAIN", function(icon)
        icon:SetColorTexture(0.55, 0.55, 0.58, 0.8)
        icon:SetSize(LINE_W + 1, STATUS_ICON_SIZE)
    end)

    AddRow("LID_LEGENDCLASS", function(icon, label)
        icon:Hide()
        label:SetText("|cffff4040Abc|r")
    end)

    AddRow("LID_LEGENDGROUP", function(icon, label)
        icon:Hide()
        label:SetText("|cff66e666" .. "2/5" .. "|r")
    end)

    legend:SetHeight(36 + #rows * 18 + 40)
    local function UpdateTexts()
        legend.title:SetText(AzerothCompendium:Trans("LID_QUESTLEGEND"))
        for _, row in ipairs(rows) do
            row[1]:SetText(AzerothCompendium:Trans(row[2]))
        end
    end

    UpdateTexts()
    AzerothCompendium:OnLanguage(UpdateTexts)
    local function Dismiss()
        legend:Hide()
        AzerothCompendium:SetConfig("QUESTLEGENDSEEN", true)
    end

    close:SetScript("OnClick", Dismiss)
    okay:SetScript("OnClick", Dismiss)
    legend:Hide()
    local button = CreateFrame("Button", nil, tree)
    button:SetSize(BOTTOM_H - 4, BOTTOM_H - 4)
    button:SetNormalTexture("Interface\\FriendsFrame\\InformationIcon")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetScript("OnClick", function()
        if legend:IsShown() then Dismiss() else legend:Show() end
    end)

    button:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_TOP")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_QUESTLEGEND"))
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    local function ShowFirstTime()
        if not AzerothCompendium:GetConfig("QUESTLEGENDSEEN", false) then legend:Show() end
    end

    tree:HookScript("OnShow", ShowFirstTime)
    if tree:IsVisible() then ShowFirstTime() end

    tree.legend = legend
    tree.legendButton = button

    return button
end

function AzerothCompendium:CreateQuestTree(parent)
    local tree = CreateFrame("Frame", nil, parent)
    local scroll = nil
    local minimal = HasMinimalScrollBar()
    if minimal then
        scroll = CreateFrame("ScrollFrame", nil, tree)
    elseif AzerothCompendium:CheckTemplates("UIPanelScrollFrameTemplate") then
        scroll = CreateFrame("ScrollFrame", nil, tree, "UIPanelScrollFrameTemplate")
    else
        scroll = CreateFrame("ScrollFrame", nil, tree)
    end

    scroll:SetPoint("TOPLEFT", tree, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W, BOTTOM_H + 2)
    local holder = CreateFrame("Frame", nil, scroll)
    holder:SetSize(1, 1)
    scroll:SetScrollChild(holder)
    local canvas = CreateFrame("Frame", nil, holder)
    canvas:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    canvas:SetSize(1, 1)
    local listHolder = CreateFrame("Frame", nil, scroll)
    listHolder:SetSize(1, 1)
    listHolder:Hide()
    if minimal then
        local vbar = CreateFrame("EventFrame", nil, tree, "MinimalScrollBar")
        vbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, 0)
        vbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 6)
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, vbar)
        tree.vbar = vbar
    end

    tree.zoom = 1
    local SetZoom = nil
    local zoomSlider = CreateZoomSlider(tree, function(value)
        if SetZoom then SetZoom(floor(value / ZOOM_BAR_STEP + 0.5) * ZOOM_BAR_STEP / 100) end
    end)
    local zoomIcon = tree:CreateTexture(nil, "ARTWORK")
    zoomIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    zoomIcon:SetSize(HBAR_H, HBAR_H)
    zoomIcon:SetPoint("RIGHT", zoomSlider, "LEFT", -2, 0)
    tree.zoomBar = zoomSlider
    local legendButton = CreateLegend(tree, scroll)
    legendButton:SetPoint("RIGHT", zoomIcon, "LEFT", -8, 0)
    local viewSwitch = CreateViewSwitch(tree, function(mode) tree:SetViewMode(mode) end)
    tree.viewSwitch = viewSwitch
    local hbar = CreateHBar(tree, scroll, viewSwitch, legendButton)
    tree.hbar = hbar
    local function SetHScroll(value)
        scroll:SetHorizontalScroll(ClampScroll(scroll, true, value))
        hbar:Sync()
    end

    local function UpdateHBar()
        hbar:Sync()
        local vbar = tree.vbar or scroll.ScrollBar
        if vbar then vbar:SetShown(GetScrollRange(scroll, false) > 0) end
    end

    hbar:HookScript("OnSizeChanged", UpdateHBar)
    if scroll.HookScript then scroll:HookScript("OnScrollRangeChanged", UpdateHBar) end
    tree:HookScript("OnShow", UpdateHBar)
    SetZoom = function(zoom)
        zoom = min(ZOOM_MAX, max(ZOOM_MIN, zoom))
        if math.abs(zoom - tree.zoom) < 0.001 then return end
        local cx = (scroll:GetWidth() or 0) / 2
        local cy = (scroll:GetHeight() or 0) / 2
        local contentX = (scroll:GetHorizontalScroll() + cx) / tree.zoom
        local contentY = (scroll:GetVerticalScroll() + cy) / tree.zoom
        tree.zoom = zoom
        canvas:SetScale(zoom)
        tree:Layout()
        SetHScroll(contentX * zoom - cx)
        scroll:SetVerticalScroll(ClampScroll(scroll, false, contentY * zoom - cy))
        UpdateHBar()
    end

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(sel, delta)
        if IsShiftKeyDown and IsShiftKeyDown() then
            SetHScroll(sel:GetHorizontalScroll() - delta * WHEEL_STEP)
        else
            sel:SetVerticalScroll(ClampScroll(sel, false, sel:GetVerticalScroll() - delta * WHEEL_STEP))
        end
    end)


    function tree:StartDrag(mouseButton)
        self.dragMoved = false
        if mouseButton ~= "LeftButton" then return end
        local x, y = GetCursorPosition()
        local scale = scroll:GetEffectiveScale()
        self.drag = {
            x = x / scale,
            y = y / scale,
            h = scroll:GetHorizontalScroll(),
            v = scroll:GetVerticalScroll()
        }
        self:SetScript("OnUpdate", self.OnDragUpdate)
    end

    function tree:StopDrag()
        self.drag = nil
        self:SetScript("OnUpdate", nil)
    end

    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function(_, mouseButton) tree:StartDrag(mouseButton) end)
    scroll:SetScript("OnMouseUp", function() tree:StopDrag() end)
    tree:SetScript("OnHide", function() tree:StopDrag() end)
    function tree.OnDragUpdate(sel)
        local drag = sel.drag
        if drag == nil or IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            sel:StopDrag()

            return
        end

        local x, y = GetCursorPosition()
        local scale = scroll:GetEffectiveScale()
        local dx = x / scale - drag.x
        local dy = y / scale - drag.y
        if not sel.dragMoved and math.abs(dx) < DRAG_THRESHOLD and math.abs(dy) < DRAG_THRESHOLD then return end
        sel.dragMoved = true
        SetHScroll(drag.h - dx)
        scroll:SetVerticalScroll(ClampScroll(scroll, false, drag.v + dy))
    end

    local lineLayer = CreateFrame("Frame", nil, canvas)
    lineLayer:SetAllPoints(canvas)
    tree.scroll = scroll
    tree.canvas = canvas
    tree.lineLayer = lineLayer
    tree.nodes = {}
    tree.lines = {}
    tree.graph = {}
    tree.boxes = {}
    tree.boxTops = {}
    for section = 1, SECTION_COUNT do
        local box = CreateBox(canvas, AzerothCompendium:Trans(SECTION_TITLES[section]))
        box.empty:SetText(AzerothCompendium:Trans(SECTION_EMPTY[section]))
        tree.boxes[section] = box
    end

    tree.keyLine = CreateKeyLine(tree.boxes[1], tree)
    tree.topBox = tree.boxes[1]
    tree.empty = tree:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    tree.empty:SetPoint("CENTER", tree, "CENTER", 0, 0)
    tree.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    tree.empty:Hide()
    tree.hint = tree:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    tree.hint:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -4, 4)
    tree.hint:Hide()
    AzerothCompendium:OnLanguage(function()
        for section = 1, SECTION_COUNT do
            tree.boxes[section].title:SetText(AzerothCompendium:Trans(SECTION_TITLES[section]))
            tree.boxes[section].empty:SetText(AzerothCompendium:Trans(SECTION_EMPTY[section]))
        end

        tree.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
        tree.hint:SetText(AzerothCompendium:Trans("LID_QUESTTREESCROLL"))
    end)
    local lineCount = 0
    local function AddLine(x, y, width, height, r, g, b, a)
        lineCount = lineCount + 1
        local line = tree.lines[lineCount]
        if line == nil then
            line = lineLayer:CreateTexture(nil, "ARTWORK")
            tree.lines[lineCount] = line
        end

        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, -y)
        line:SetSize(max(1, width), max(1, height))
        line:SetColorTexture(r, g, b, a)
        line:Show()
    end

    local function AddEdge(parentNode, childNode, nodeW, gapY)
        local px = parentNode.x + nodeW / 2
        local py = parentNode.y + parentNode.h
        local cx = childNode.x + nodeW / 2
        local cy = childNode.y
        if cy <= py then
            local root = parentNode
            while #root.parents == 1 and root.parents[1].id == root.id do
                root = root.parents[1]
            end

            if root == parentNode or root.y > cy then return end
            if root.y + root.h < cy then return AddEdge(root, childNode, nodeW, gapY) end
            local rx = root.x + nodeW / 2
            local firstRow = cy <= tree.boxTops[childNode.section] + HEADER_H + KEY_LINE_H + PAD
            local topY = cy - (firstRow and PAD or gapY) / 2
            local half = LINE_W / 2
            local r, g, b, a = 0.55, 0.55, 0.58, 0.8
            if AzerothCompendium:IsQuestCompleted(parentNode.id) then r, g, b, a = 0.2, 0.75, 0.2, 0.85 end
            AddLine(rx - half, topY, LINE_W, root.y - topY, r, g, b, a)
            AddLine(min(rx, cx) - half, topY - half, math.abs(cx - rx) + LINE_W, LINE_W, r, g, b, a)
            AddLine(cx - half, topY, LINE_W, cy - topY, r, g, b, a)

            return
        end

        local completed = AzerothCompendium:IsQuestCompleted(parentNode.id)
        local r, g, b, a = 0.55, 0.55, 0.58, 0.8
        if parentNode.id == childNode.id then r, g, b, a = 0.35, 0.65, 1, 0.9 end
        if completed then r, g, b, a = 0.2, 0.75, 0.2, 0.85 end
        local half = LINE_W / 2
        if px == cx then
            AddLine(px - half, py, LINE_W, cy - py, r, g, b, a)

            return
        end

        local midY = cy - gapY / 2
        if parentNode.section ~= childNode.section then midY = tree.boxTops[childNode.section] - BOX_GAP / 2 end
        AddLine(px - half, py, LINE_W, midY - py, r, g, b, a)
        AddLine(min(px, cx) - half, midY - half, math.abs(cx - px) + LINE_W, LINE_W, r, g, b, a)
        AddLine(cx - half, midY, LINE_W, cy - midY, r, g, b, a)
    end

    function tree:SetGraph(graph)
        self.graph = graph or {}
        self:Layout()
        SetHScroll(0)
        scroll:SetVerticalScroll(0)
    end

    tree.listRows = {}
    tree.collapsed = {}
    tree.listSections = {}
    function tree:ToggleListKey(key)
        if key == nil then return end
        self.collapsed[key] = not self.collapsed[key] or nil
        self:Layout()
    end

    function tree:LayoutList()
        local graph = self.graph
        local attunement = graph.attunement
        local keySection = attunement ~= nil and attunement.key ~= nil and (attunement.opens ~= nil and 3 or 1) or nil
        local sections = BuildListTree(graph)
        self.listSections = sections
        local entries = {}
        if #graph == 0 and attunement == nil then
            self.empty:Show()
        else
            self.empty:Hide()
            for section = 1, SECTION_COUNT do
                if section ~= 1 or attunement ~= nil and attunement.opens == nil then
                    local key = "section" .. section
                    tinsert(entries, {
                        kind = "section",
                        section = section,
                        key = key,
                        depth = 0,
                        count = CountListItems(sections[section]),
                        hasChildren = true
                    })

                    if not self.collapsed[key] then
                        if section == keySection then
                            tinsert(entries, {
                                kind = "key",
                                attunement = attunement,
                                depth = 1
                            })
                        end

                        FlattenList(sections[section], 1, self.collapsed, entries)
                        if #sections[section] == 0 and section ~= 1 then
                            tinsert(entries, {
                                kind = "empty",
                                section = section,
                                depth = 1
                            })
                        end
                    end
                end
            end
        end

        local width = max(1, scroll:GetWidth() or 0)
        for index, entry in ipairs(entries) do
            local row = self.listRows[index]
            if row == nil then
                row = CreateListRow(listHolder, self)
                self.listRows[index] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", listHolder, "TOPLEFT", 0, -(index - 1) * LIST_ROW_H)
            row:SetWidth(width)
            UpdateListRow(row, entry, index, self.collapsed)
        end

        for index = #entries + 1, #self.listRows do
            self.listRows[index]:Hide()
        end

        listHolder:SetSize(width, max(1, #entries * LIST_ROW_H))
        self.hint:Hide()
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
        SetHScroll(0)
        scroll:SetVerticalScroll(ClampScroll(scroll, false, scroll:GetVerticalScroll()))
        UpdateHBar()
    end

    function tree:SetViewMode(mode)
        if mode ~= "list" then mode = "tree" end
        AzerothCompendium:SetConfig("QUESTVIEW", mode)
        self.viewMode = mode
        local list = mode == "list"
        holder:SetShown(not list)
        listHolder:SetShown(list)
        scroll:SetScrollChild(list and listHolder or holder)
        zoomSlider:SetShown(not list)
        zoomIcon:SetShown(not list)
        viewSwitch:SetMode(mode)
        self:Layout()
        SetHScroll(0)
        scroll:SetVerticalScroll(0)
    end

    function tree:Layout()
        if self.viewMode == "list" then return self:LayoutList() end
        local graph = self.graph
        lineCount = 0
        local baseLevel = canvas:GetFrameLevel() or 0
        for _, box in ipairs(self.boxes) do
            box:SetFrameLevel(baseLevel + 1)
        end
        lineLayer:SetFrameLevel(baseLevel + 2)
        local viewW = (scroll:GetWidth() or 0) / self.zoom
        if viewW <= 0 then viewW = NODE_MIN_W + 2 * PAD end
        ComputeLayers(graph)
        local components = BuildComponents(graph)
        local connected = {}
        local loose = {}
        for _, component in ipairs(components) do
            ArrangeComponent(component)
            if component.hasTop then
                tinsert(connected, component)
            else
                tinsert(loose, component)
            end
        end

        local totalCols = 0
        local rows = {}
        for section = 1, SECTION_COUNT do
            rows[section] = 0
        end

        for _, list in ipairs({connected, loose}) do
            for _, component in ipairs(list) do
                component.col = totalCols
                totalCols = totalCols + component.width
                for section = 1, SECTION_COUNT do
                    rows[section] = max(rows[section], component.layers[section])
                end
            end
        end

        local nodeH = 0
        for _, node in ipairs(graph) do
            node.h = GetNodeHeight(node)
            nodeH = max(nodeH, node.h)
        end

        local viewCols = max(1, floor((viewW - 2 * PAD + GAP_X) / (NODE_MIN_W + GAP_X)))
        local cols = max(viewCols, totalCols)
        local nodeW = NODE_MIN_W
        if cols == viewCols then nodeW = max(NODE_MIN_W, min(NODE_MAX_W, floor((viewW - 2 * PAD - (cols - 1) * GAP_X) / cols))) end
        local rowStep = nodeH + GAP_Y
        local colStep = nodeW + GAP_X
        local attunement = graph.attunement
        local keySection = attunement ~= nil and attunement.key ~= nil and (attunement.opens ~= nil and 3 or 1) or nil
        local function HeaderHeight(section)
            if section == keySection then return HEADER_H + KEY_LINE_H end

            return HEADER_H
        end

        local function BoxHeight(section, count)
            if count <= 0 then
                if section == 1 then return HeaderHeight(section) + 4 end

                return HeaderHeight(section) + EMPTY_H
            end

            return HeaderHeight(section) + PAD + count * nodeH + (count - 1) * GAP_Y + PAD
        end

        local function IsBoxVisible(section)
            return section ~= 1 or attunement ~= nil and attunement.opens == nil
        end

        local canvasW = max(viewW, 2 * PAD + cols * nodeW + (cols - 1) * GAP_X)
        local canvasH = 0
        for section = 1, SECTION_COUNT do
            self.boxTops[section] = canvasH
            if IsBoxVisible(section) then canvasH = canvasH + BoxHeight(section, rows[section]) + BOX_GAP end
        end

        canvasH = canvasH - BOX_GAP
        self.bottomBoxTop = self.boxTops[3]
        for _, component in ipairs(components) do
            for _, node in ipairs(component.nodes) do
                node.x = PAD + (component.col + node.column) * colStep
                local row = node.layer
                if node.section <= 2 then row = rows[node.section] - component.layers[node.section] + node.layer end
                node.y = self.boxTops[node.section] + HeaderHeight(node.section) + PAD + row * rowStep
            end
        end

        UpdateKeyLine(self.keyLine, attunement, self.boxes[keySection or 1])
        if #graph == 0 and attunement == nil then
            for _, box in ipairs(self.boxes) do
                box:Hide()
            end

            self.empty:Show()
            canvasH = 1
        else
            self.empty:Hide()
            for section, box in ipairs(self.boxes) do
                box:ClearAllPoints()
                box:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -self.boxTops[section])
                box:SetSize(canvasW, BoxHeight(section, rows[section]))
                box.empty:ClearAllPoints()
                box.empty:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -HeaderHeight(section) - 2)
                if rows[section] == 0 and section ~= 1 then box.empty:Show() else box.empty:Hide() end
                box:SetShown(IsBoxVisible(section))
            end
        end

        for index, node in ipairs(graph) do
            local button = self.nodes[index]
            if button == nil then
                button = CreateNode(canvas, self)
                self.nodes[index] = button
            end

            button:SetFrameLevel(baseLevel + 3)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", canvas, "TOPLEFT", node.x, -node.y)
            UpdateNode(button, node, nodeW)
            for _, parentNode in ipairs(node.parents) do
                AddEdge(parentNode, node, nodeW, GAP_Y)
            end
        end

        for index = #graph + 1, #self.nodes do
            self.nodes[index]:Hide()
        end

        for index = lineCount + 1, #self.lines do
            self.lines[index]:Hide()
        end

        canvas:SetSize(canvasW, canvasH)
        holder:SetSize(canvasW * self.zoom, canvasH * self.zoom)
        if canvasW > viewW + 1 then self.hint:Show() else self.hint:Hide() end
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
        SetHScroll(scroll:GetHorizontalScroll())
        scroll:SetVerticalScroll(ClampScroll(scroll, false, scroll:GetVerticalScroll()))
        UpdateHBar()
    end

    function tree:FocusQuest(questID)
        if self.viewMode == "list" then
            for section, items in ipairs(self.listSections) do
                local path = {}
                if FindListPath(items, questID, path) then
                    self.collapsed["section" .. section] = nil
                    for _, key in ipairs(path) do
                        self.collapsed[key] = nil
                    end

                    self:Layout()
                    for index, row in ipairs(self.listRows) do
                        if row:IsShown() and row.kind == "quest" and row.node.id == questID then
                            scroll:SetVerticalScroll(ClampScroll(scroll, false, (index - 0.5) * LIST_ROW_H - scroll:GetHeight() / 2))

                            return true
                        end
                    end
                end
            end

            return false
        end

        for index, node in ipairs(self.graph) do
            if node.id == questID then
                local button = self.nodes[index]
                SetHScroll((node.x + button:GetWidth() / 2) * self.zoom - scroll:GetWidth() / 2)
                scroll:SetVerticalScroll(ClampScroll(scroll, false, (node.y + node.h / 2) * self.zoom - scroll:GetHeight() / 2))

                return true
            end
        end

        return false
    end

    function tree:SetQuestHighlight(questID)
        for _, button in ipairs(self.nodes) do
            if questID ~= nil and button:IsShown() and button.node and button.node.id == questID then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end

        for _, row in ipairs(self.listRows) do
            if questID ~= nil and row:IsShown() and row.kind == "quest" and row.node.id == questID then
                row:LockHighlight()
            else
                row:UnlockHighlight()
            end
        end
    end

    function tree:Refresh()
        if self:IsShown() then self:Layout() end
    end

    tree:SetScript("OnSizeChanged", function(sel) sel:Layout() end)
    tree:SetViewMode(AzerothCompendium:GetConfig("QUESTVIEW", "tree"))

    return tree
end
