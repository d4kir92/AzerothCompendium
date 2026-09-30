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
local SECTION_COUNT = 3
local SECTION_TITLES = {"LID_QUESTTREESTART", "LID_QUESTTREEINSTANCE", "LID_QUESTTREEAFTER"}
local SECTION_EMPTY = {"LID_QUESTTREENOSTART", "LID_NOENTRIES", "LID_QUESTTREENOAFTER"}
local ZOOM_MIN = 0.4
local ZOOM_MAX = 1.5
local ZOOM_BAR_STEP = 5
local ZOOM_BAR_W = 130
local STATUS_ICON = {
    ["complete"] = {"Interface\\RaidFrame\\ReadyCheck-Ready", false},
    ["ready"] = {"Interface\\GossipFrame\\ActiveQuestIcon", false},
    ["active"] = {"Interface\\GossipFrame\\ActiveQuestIcon", true},
    ["open"] = {"Interface\\GossipFrame\\AvailableQuestIcon", false},
    ["locked"] = {"Interface\\GossipFrame\\AvailableQuestIcon", true}
}

local STATUS_BORDER = {
    ["complete"] = {0.13, 0.75, 0.13, 1},
    ["ready"] = {1, 0.82, 0, 1},
    ["active"] = {0.7, 0.6, 0.25, 1},
    ["open"] = {0.35, 0.35, 0.38, 1},
    ["locked"] = {0.35, 0.35, 0.38, 1}
}

local function IsQuestLocked(node)
    for _, parent in ipairs(node and node.parents or {}) do
        if not AzerothCompendium:IsQuestCompleted(parent.id) then return true end
    end

    return false
end

local function GetQuestStatus(questID, node)
    if AzerothCompendium:IsQuestCompleted(questID) then return "complete" end
    if AzerothCompendium:IsQuestReadyForTurnIn(questID) then return "ready" end
    if AzerothCompendium:IsQuestActive(questID) then return "active" end
    if IsQuestLocked(node) then return "locked" end

    return "open"
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
    if type(GetQuestDifficultyColor) ~= "function" then return "|cffffffff" end
    local ok, color = pcall(GetQuestDifficultyColor, level)
    if not ok or type(color) ~= "table" then return "|cffffffff" end
    local red = min(255, max(0, floor((color.r or 1) * 255 + 0.5)))
    local green = min(255, max(0, floor((color.g or 1) * 255 + 0.5)))
    local blue = min(255, max(0, floor((color.b or 1) * 255 + 0.5)))

    return format("|cff%02x%02x%02x", red, green, blue)
end

local function AddQuestStatusToTooltip(questID, quest, node)
    local status = GetQuestStatus(questID, node)
    local text = status == "complete" and AzerothCompendium:Trans("LID_QUESTCOMPLETE") or status == "ready" and AzerothCompendium:Trans("LID_QUESTREADY") or status == "active" and AzerothCompendium:Trans("LID_QUESTACTIVE") or status == "locked" and AzerothCompendium:Trans("LID_QUESTLOCKED") or AzerothCompendium:Trans("LID_QUESTNOTACCEPTED")
    local color = (status == "open" or status == "locked") and {0.65, 0.65, 0.65} or STATUS_BORDER[status]
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(_G.STATUS or "Status"), text, 0.9, 0.9, 0.9, color[1], color[2], color[3])
    quest = quest or AzerothCompendium:GetQuestDataByID(questID) or questID
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTREQUIREDLEVEL")), tostring(AzerothCompendium:GetQuestRequiredLevel(quest)), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTRECOMMENDEDLEVEL")), tostring(AzerothCompendium:GetQuestRecommendedLevel(quest)), 0.9, 0.9, 0.9, 1, 0.82, 0)
end

local function InsertQuestLink(questID)
    if IsShiftKeyDown == nil or not IsShiftKeyDown() or ChatEdit_InsertLink == nil then return false end
    if ChatEdit_GetActiveWindow ~= nil and ChatEdit_GetActiveWindow() == nil then return false end
    local link = C_QuestLog and C_QuestLog.GetQuestLink and C_QuestLog.GetQuestLink(questID)
    if link == nil and GetQuestLink ~= nil then link = GetQuestLink(questID) end
    if link == nil then return false end
    ChatEdit_InsertLink(link)

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

    if InsertQuestLink(node.id) then return end
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
    edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[4]:SetWidth(1)
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

        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans(sel.choice and "LID_QUESTCHOICE" or "LID_QUESTREWARDS")), 1, 0.82, 0)
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
    node:SetScript("OnEnter", ShowNodeTooltip)
    node:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
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

local function GetNodeRequiredLevel(node)
    local level = AzerothCompendium:GetQuestRequiredLevel(node.quest or node.id)

    return type(level) == "number" and level > 0 and level or nil
end

local function GetNodeHeight(node)
    local height = NODE_PAD_TOP + TITLE_H + REWARD_LINE_H + TEXT_LINE_H + NODE_PAD_BOTTOM
    if GetNodeRequiredLevel(node) then height = height + TEXT_LINE_H end

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
    if requiredLevel then
        PlaceLine(button.levelText, button, y, TEXT_LINE_H)
        button.levelText:SetText(format(_G.ITEM_MIN_LEVEL or "Requires Level %d", requiredLevel))
        local playerLevel = UnitLevel and UnitLevel("player") or requiredLevel
        if playerLevel < requiredLevel then
            button.levelText:SetTextColor(1, 0.25, 0.25)
        else
            button.levelText:SetTextColor(0.75, 0.75, 0.75)
        end

        button.levelText:Show()
        y = y + TEXT_LINE_H
    else
        button.levelText:Hide()
    end

    local entries, rewards = GetRewardEntries(node.id)
    local shown = 0
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

    local function Layer(node, stack)
        if node.layer ~= nil then return node.layer end
        if stack[node] then return 0 end
        stack[node] = true
        local layer = 0
        for _, parent in ipairs(node.parents) do
            if parent.section == node.section then layer = max(layer, Layer(parent, stack) + 1) end
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
                if node.section == 1 then component.hasTop = true end
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

local function ClampScroll(scroll, horizontal, value)
    local range = horizontal and scroll:GetHorizontalScrollRange() or scroll:GetVerticalScrollRange()

    return min(max(0, range or 0), max(0, value))
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

local function CreateHBar(tree, scroll, anchor)
    local bar = CreateMinimalHBar(tree)
    local syncing = false
    if bar then
        bar:SetPoint("LEFT", tree, "BOTTOMLEFT", 0, BOTTOM_H / 2)
        bar:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
        bar:RegisterCallback(BaseScrollBoxEvents.OnScroll, function(_, percentage)
            if syncing then return end
            local range = max(0, scroll:GetHorizontalScrollRange() or 0)
            scroll:SetHorizontalScroll(ClampScroll(scroll, true, percentage * range))
        end, scroll)
        bar.Sync = function(sel)
            local range = max(0, scroll:GetHorizontalScrollRange() or 0)
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
        bar:SetPoint("LEFT", tree, "BOTTOMLEFT", 0, BOTTOM_H / 2)
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
            local range = max(0, scroll:GetHorizontalScrollRange() or 0)
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

    scroll:SetPoint("TOPLEFT", tree, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W, BOTTOM_H + 2)
    local holder = CreateFrame("Frame", nil, scroll)
    holder:SetSize(1, 1)
    scroll:SetScrollChild(holder)
    local canvas = CreateFrame("Frame", nil, holder)
    canvas:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    canvas:SetSize(1, 1)
    if minimal then
        local vbar = CreateFrame("EventFrame", nil, tree, "MinimalScrollBar")
        vbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
        vbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
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
    local hbar = CreateHBar(tree, scroll, zoomIcon)
    tree.hbar = hbar
    local function SetHScroll(value)
        scroll:SetHorizontalScroll(ClampScroll(scroll, true, value))
        hbar:Sync()
    end

    local function UpdateHBar()
        hbar:Sync()
    end

    hbar:HookScript("OnSizeChanged", UpdateHBar)
    if scroll.HookScript then scroll:HookScript("OnScrollRangeChanged", UpdateHBar) end
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
    end

    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function(_, mouseButton) tree:StartDrag(mouseButton) end)
    scroll:SetScript("OnMouseUp", function() tree.drag = nil end)
    tree:SetScript("OnHide", function() tree.drag = nil end)
    tree:SetScript("OnUpdate", function(sel)
        local drag = sel.drag
        if drag == nil then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            sel.drag = nil

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
    end)

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

    tree.topBox = tree.boxes[1]
    tree.empty = tree:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    tree.empty:SetPoint("CENTER", tree, "CENTER", 0, 0)
    tree.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    tree.empty:Hide()
    tree.hint = tree:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    tree.hint:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -4, 4)
    tree.hint:SetText(AzerothCompendium:Trans("LID_QUESTTREESCROLL"))
    tree.hint:Hide()
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
        if cy <= py then return end
        local completed = AzerothCompendium:IsQuestCompleted(parentNode.id)
        local r, g, b, a = 0.55, 0.55, 0.58, 0.8
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

    function tree:Layout()
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
        local function BoxHeight(count)
            if count <= 0 then return HEADER_H + EMPTY_H end

            return HEADER_H + PAD + count * nodeH + (count - 1) * GAP_Y + PAD
        end

        local canvasW = max(viewW, 2 * PAD + cols * nodeW + (cols - 1) * GAP_X)
        local canvasH = 0
        for section = 1, SECTION_COUNT do
            self.boxTops[section] = canvasH
            canvasH = canvasH + BoxHeight(rows[section]) + BOX_GAP
        end

        canvasH = canvasH - BOX_GAP
        self.bottomBoxTop = self.boxTops[2]
        for _, component in ipairs(components) do
            for _, node in ipairs(component.nodes) do
                node.x = PAD + (component.col + node.column) * colStep
                local row = node.layer
                if node.section == 1 then row = rows[1] - component.layers[1] + node.layer end
                node.y = self.boxTops[node.section] + HEADER_H + PAD + row * rowStep
            end
        end

        if #graph == 0 then
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
                box:SetSize(canvasW, BoxHeight(rows[section]))
                if rows[section] == 0 then box.empty:Show() else box.empty:Hide() end
                box:Show()
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

    function tree:Refresh()
        if self:IsShown() then self:Layout() end
    end

    tree:SetScript("OnSizeChanged", function(sel) sel:Layout() end)

    return tree
end
