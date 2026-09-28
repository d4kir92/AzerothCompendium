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
local HBAR_H = 12
local HBAR_MIN_THUMB = 30
local DRAG_THRESHOLD = 4
local WHEEL_STEP = 60
local QUEST_TAG_LETTER = {
    [81] = "D",
    [62] = "R"
}

local SECTION_COUNT = 3
local SECTION_TITLES = {"LID_QUESTTREESTART", "LID_QUESTTREEINSTANCE", "LID_QUESTTREEAFTER"}
local SECTION_EMPTY = {"LID_QUESTTREENOSTART", "LID_NOENTRIES", "LID_QUESTTREENOAFTER"}
local ZOOM_MIN = 0.4
local ZOOM_MAX = 1.5
local ZOOM_BAR_STEP = 5
local ZOOM_BAR_W = 90
local STATUS_ICON = {
    ["complete"] = {"Interface\\RaidFrame\\ReadyCheck-Ready", false},
    ["ready"] = {"Interface\\GossipFrame\\ActiveQuestIcon", false},
    ["active"] = {"Interface\\GossipFrame\\ActiveQuestIcon", true},
    ["open"] = {"Interface\\GossipFrame\\AvailableQuestIcon", false}
}

local STATUS_BORDER = {
    ["complete"] = {0.13, 0.75, 0.13, 1},
    ["ready"] = {1, 0.82, 0, 1},
    ["active"] = {0.7, 0.6, 0.25, 1},
    ["open"] = {0.35, 0.35, 0.38, 1}
}

local function GetQuestStatus(questID)
    if AzerothCompendium:IsQuestCompleted(questID) then return "complete" end
    if AzerothCompendium:IsQuestReadyForTurnIn(questID) then return "ready" end
    if AzerothCompendium:IsQuestActive(questID) then return "active" end

    return "open"
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

local function AddQuestStatusToTooltip(questID, quest)
    local status = GetQuestStatus(questID)
    local text = status == "complete" and AzerothCompendium:Trans("LID_QUESTCOMPLETE") or status == "ready" and AzerothCompendium:Trans("LID_QUESTREADY") or status == "active" and AzerothCompendium:Trans("LID_QUESTACTIVE") or AzerothCompendium:Trans("LID_QUESTNOTACCEPTED")
    local color = status == "open" and {0.65, 0.65, 0.65} or STATUS_BORDER[status]
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
    if rewards == nil then return end
    GameTooltip:AddLine(" ")
    AddRewardItemsToTooltip(AzerothCompendium:Trans("LID_QUESTREWARDS"), rewards.items)
    AddRewardItemsToTooltip(AzerothCompendium:Trans("LID_QUESTCHOICE"), rewards.choices)
    if rewards.xp then GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTXP")), tostring(rewards.xp), 0.9, 0.9, 0.9, 0.6, 0.4, 1) end
    if rewards.money then GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(_G.MONEY or "Money"), GetMoneyText(rewards.money), 0.9, 0.9, 0.9, 1, 1, 1) end
    for _, entry in ipairs(rewards.rep or {}) do
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(GetFactionName(entry[1])), format("+%d %s", entry[2], _G.REPUTATION or "Reputation"), 0.9, 0.9, 0.9, 0.3, 0.8, 1)
    end
end

local function ShowNodeTooltip(button)
    local node = button.node
    if node == nil then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "quest:" .. node.id)
    if not shown then
        GameTooltip:ClearLines()
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(node.name), 1, 0.82, 0)
    end

    AddQuestStatusToTooltip(node.id, node.quest)
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[node.id]
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
    if startItem then
        local name, link = AzerothCompendium:GetItemDisplay(startItem[1])
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format("%s: %s", _G.ITEM or "Item", link or name or startItem[2])), 1, 0.82, 0)
        if giver then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format("%s: %s", _G.SOURCE or "Source", giver[5])), 0.75, 0.75, 0.75) end
    elseif giver then
        local mapName = GetMapName(giver[1])
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

    GameTooltip:Show()
end

local function OnNodeClick(button)
    local node = button.node
    if node == nil or button.tree.dragMoved then return end
    if InsertQuestLink(node.id) then return end
    if AzerothCompendium:IsQuestStartInInstance(node.id) then
        AzerothCompendium:INFO(format(AzerothCompendium:Trans("LID_QUESTSTARTSININSTANCE"), node.name))

        return
    end

    local waypointSet, reason = AzerothCompendium:SetQuestWaypoint(node.id)
    if not waypointSet then
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
    node:RegisterForClicks("LeftButtonUp")
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
    node.title:SetPoint("LEFT", node.statusIcon, "RIGHT", 3, 0)
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
    local status = GetQuestStatus(node.id)
    local statusIcon = STATUS_ICON[status]
    button.statusIcon:SetTexture(statusIcon[1])
    button.statusIcon:SetDesaturated(statusIcon[2])
    local color = GetQuestDifficultyColorCode(node.level)
    local prefix = ""
    local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
    if startItem then
        local _, _, _, _, icon = AzerothCompendium:GetItemDisplay(startItem[1])
        prefix = format("|T%s:12:12:0:0|t ", tostring(icon or 134400))
    end

    local tag = AzerothCompendium.QUESTTAGS and QUEST_TAG_LETTER[AzerothCompendium.QUESTTAGS[node.id]] or ""
    button.title:SetText(prefix .. color .. "[" .. tag .. node.level .. "] " .. node.name .. "|r")
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
    local xp = rewards and rewards.xp or 0
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

function AzerothCompendium:CreateQuestTree(parent)
    local tree = CreateFrame("Frame", nil, parent)
    local scroll = nil
    if AzerothCompendium:CheckTemplates("UIPanelScrollFrameTemplate") then
        scroll = CreateFrame("ScrollFrame", nil, tree, "UIPanelScrollFrameTemplate")
    else
        scroll = CreateFrame("ScrollFrame", nil, tree)
    end

    scroll:SetPoint("TOPLEFT", tree, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W, HBAR_H + 4)
    local canvas = CreateFrame("Frame", nil, scroll)
    canvas:SetSize(1, 1)
    scroll:SetScrollChild(canvas)
    local zoomText = tree:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    zoomText:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -SCROLLBAR_W, 0)
    zoomText:SetSize(34, HBAR_H + 2)
    zoomText:SetJustifyH("RIGHT")
    zoomText:SetText("100%")
    local zoomBar = CreateFrame("Slider", nil, tree)
    zoomBar:SetOrientation("HORIZONTAL")
    zoomBar:SetPoint("BOTTOMRIGHT", zoomText, "BOTTOMLEFT", -4, 1)
    zoomBar:SetSize(ZOOM_BAR_W, HBAR_H)
    zoomBar:SetMinMaxValues(ZOOM_MIN * 100, ZOOM_MAX * 100)
    zoomBar:SetValueStep(ZOOM_BAR_STEP)
    if zoomBar.SetObeyStepOnDrag then zoomBar:SetObeyStepOnDrag(true) end
    zoomBar:SetValue(100)
    zoomBar.track = zoomBar:CreateTexture(nil, "BACKGROUND")
    zoomBar.track:SetPoint("LEFT", zoomBar, "LEFT", 0, 0)
    zoomBar.track:SetPoint("RIGHT", zoomBar, "RIGHT", 0, 0)
    zoomBar.track:SetHeight(4)
    zoomBar.track:SetColorTexture(0, 0, 0, 0.6)
    zoomBar.thumb = zoomBar:CreateTexture(nil, "OVERLAY")
    zoomBar.thumb:SetColorTexture(0.75, 0.6, 0.25, 1)
    zoomBar.thumb:SetSize(8, HBAR_H)
    zoomBar:SetThumbTexture(zoomBar.thumb)
    zoomBar:EnableMouseWheel(true)
    local zoomIcon = tree:CreateTexture(nil, "ARTWORK")
    zoomIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    zoomIcon:SetSize(HBAR_H, HBAR_H)
    zoomIcon:SetPoint("RIGHT", zoomBar, "LEFT", -4, 0)
    tree.zoomBar = zoomBar
    local hbar = CreateFrame("Slider", nil, tree)
    hbar:SetOrientation("HORIZONTAL")
    hbar:SetPoint("BOTTOMLEFT", tree, "BOTTOMLEFT", 0, 1)
    hbar:SetPoint("BOTTOMRIGHT", zoomIcon, "BOTTOMLEFT", -8, 0)
    hbar:SetHeight(HBAR_H)
    hbar:SetMinMaxValues(0, 0)
    hbar:SetValueStep(1)
    hbar:SetValue(0)
    hbar.track = hbar:CreateTexture(nil, "BACKGROUND")
    hbar.track:SetAllPoints(hbar)
    hbar.track:SetColorTexture(0, 0, 0, 0.45)
    hbar.thumb = hbar:CreateTexture(nil, "OVERLAY")
    hbar.thumb:SetColorTexture(0.75, 0.6, 0.25, 0.9)
    hbar.thumb:SetSize(HBAR_MIN_THUMB, HBAR_H)
    hbar:SetThumbTexture(hbar.thumb)
    hbar:EnableMouseWheel(true)
    tree.hbar = hbar
    local syncing = false
    local function SetHScroll(value)
        value = ClampScroll(scroll, true, value)
        scroll:SetHorizontalScroll(value)
        syncing = true
        hbar:SetValue(value)
        syncing = false
    end

    local function UpdateHBar()
        local range = max(0, scroll:GetHorizontalScrollRange() or 0)
        local barW = hbar:GetWidth() or 0
        local viewW = scroll:GetWidth() or 0
        syncing = true
        hbar:SetMinMaxValues(0, range)
        hbar:SetValue(min(range, scroll:GetHorizontalScroll()))
        syncing = false
        if range <= 0 or barW <= 0 then
            hbar:Hide()

            return
        end

        hbar.thumb:SetWidth(max(HBAR_MIN_THUMB, floor(barW * viewW / (viewW + range))))
        hbar:Show()
    end

    hbar:SetScript("OnValueChanged", function(_, value)
        if not syncing then scroll:SetHorizontalScroll(ClampScroll(scroll, true, value)) end
    end)

    hbar:SetScript("OnSizeChanged", UpdateHBar)
    if scroll.HookScript then scroll:HookScript("OnScrollRangeChanged", UpdateHBar) end
    hbar:SetScript("OnMouseWheel", function(_, delta) SetHScroll(scroll:GetHorizontalScroll() - delta * WHEEL_STEP) end)
    tree.zoom = 1
    local function SetZoom(zoom)
        zoom = min(ZOOM_MAX, max(ZOOM_MIN, zoom))
        zoomText:SetText(floor(zoom * 100 + 0.5) .. "%")
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

    zoomBar:SetScript("OnValueChanged", function(_, value) SetZoom(floor(value / ZOOM_BAR_STEP + 0.5) * ZOOM_BAR_STEP / 100) end)
    zoomBar:SetScript("OnMouseWheel", function(sel, delta) sel:SetValue(sel:GetValue() + delta * ZOOM_BAR_STEP) end)

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
