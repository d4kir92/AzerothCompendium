local _, AC = ...
local Browser = {}
AC.ItemBrowser = Browser
Browser.attributes = {
    {"ITEM_MOD_STRENGTH_SHORT", "Strength", true},
    {"ITEM_MOD_AGILITY_SHORT", "Agility", true},
    {"ITEM_MOD_STAMINA_SHORT", "Stamina", true},
    {"ITEM_MOD_INTELLECT_SHORT", "Intellect", true},
    {"ITEM_MOD_SPIRIT_SHORT", "Spirit", true},
    {"ITEM_MOD_ATTACK_POWER_SHORT", "Attack Power"},
    {"ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "Ranged Attack Power"},
    {"ITEM_MOD_SPELL_POWER_SHORT", "Spell Power"},
    {"ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "Spell Damage"},
    {"ITEM_MOD_SPELL_HEALING_DONE_SHORT", "Healing"},
    {"ITEM_MOD_CRIT_RATING_SHORT", "Critical Strike"},
    {"ITEM_MOD_HIT_RATING_SHORT", "Hit"},
    {"ITEM_MOD_HASTE_RATING_SHORT", "Haste"},
    {"ITEM_MOD_MASTERY_RATING_SHORT", "Mastery"},
    {"ITEM_MOD_VERSATILITY", "Versatility"},
    {"ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "Defense"},
    {"ITEM_MOD_DODGE_RATING_SHORT", "Dodge"},
    {"ITEM_MOD_PARRY_RATING_SHORT", "Parry"},
    {"ITEM_MOD_BLOCK_RATING_SHORT", "Block"},
    {"ITEM_MOD_EXPERTISE_RATING_SHORT", "Expertise"},
    {"ITEM_MOD_RESILIENCE_RATING_SHORT", "Resilience"},
    {"ITEM_MOD_MANA_REGENERATION_SHORT", "Mana Regeneration"},
    {"ITEM_MOD_HEALTH_REGENERATION_SHORT", "Health Regeneration"},
    {"RESISTANCE0_NAME", "Armor"},
    {"RESISTANCE1_NAME", "Holy Resistance"},
    {"RESISTANCE2_NAME", "Fire Resistance"},
    {"RESISTANCE3_NAME", "Nature Resistance"},
    {"RESISTANCE4_NAME", "Frost Resistance"},
    {"RESISTANCE5_NAME", "Shadow Resistance"},
    {"RESISTANCE6_NAME", "Arcane Resistance"},
}

function Browser:Label(attribute)
    return _G[attribute[1]] or attribute[2]
end

function Browser:Collect()
    local entries = {}
    local function Add(id, source, fallback)
        if not id then return end
        if AC:GetFlavor() ~= "forever" and AC:IsForeverItem(id) then return end
        local entry = entries[id]
        if not entry then
            entry = {id = id, sources = {}, fallback = fallback}
            entries[id] = entry
        end
        if source and source ~= "" then entry.sources[source] = true end
    end
    for _, collection in ipairs({AC.INSTANCES or {}, AC.VENDORS or {}}) do
        for _, instance in ipairs(collection) do
            if AC:GetFlavor() == "forever" or not instance.forever then
                for _, boss in ipairs(instance.bosses or {}) do
                    local source = AC:GetInstanceName(instance) .. " / " .. AC:GetBossName(boss)
                    for _, loot in ipairs(boss.loot or {}) do Add(loot[1], source) end
                end
            end
        end
    end
    for questID, rewards in pairs(AC.QUESTREWARDS or {}) do
        if AC:IsQuestForFlavor(questID) then
            local source = AC:Trans("LID_QUESTS") .. " #" .. questID
            for _, items in ipairs({rewards.items or {}, rewards.choices or {}}) do
                for _, item in ipairs(items) do Add(item[1], source) end
            end
        end
    end
    for questID, item in pairs(AC.QUESTSTARTITEMS or {}) do
        if AC:IsQuestForFlavor(questID) then Add(item[1], AC:Trans("LID_QUESTS") .. " #" .. questID) end
    end
    for _, item in ipairs(AC.WORLDQUESTITEMS or {}) do
        if AC:IsQuestForFlavor(item.questID) then Add(item.itemID, item.source, item.itemName) end
    end
    self.byID = entries
    self.entries = {}
    for _, entry in pairs(entries) do
        local sources = {}
        for source in pairs(entry.sources) do table.insert(sources, source) end
        table.sort(sources)
        entry.source = table.concat(sources, "; ")
        table.insert(self.entries, entry)
    end
    self.flavor = AC:GetFlavor()
end

function Browser:ItemInfoReceived(itemID, success)
    local entry = self.byID and self.byID[itemID]
    if not entry then return end
    entry.info = nil
    entry.unavailable = success == false
    entry.requestedAt = nil
end

function Browser:ReadItem(entry)
    if entry.info then return unpack(entry.info, 1, 10) end
    if entry.unavailable then return end
    local now = GetTime()
    if entry.requestedAt and now - entry.requestedAt >= 10 then
        entry.unavailable = true
        return
    end
    if not entry.requestedAt then
        local info = {AC:GetItemInfo(entry.id)}
        if info[1] then
            entry.info = info
            return unpack(info, 1, 10)
        end
        entry.requestedAt = now
    end
    if not self.timeoutPending then
        self.timeoutPending = true
        AC:After(10.1, function()
            self.timeoutPending = false
            self:Refresh()
        end, "AzerothCompendium:ItemBrowserTimeout")
    end
end

function Browser:Refresh()
    if not self.panel or not self.panel:IsShown() then return end
    local query = strlower(strtrim(self.search:GetText() or ""))
    local minimums, statFilter = {}, false
    for key, input in pairs(self.inputs) do
        local minimum = tonumber(input:GetText()) or 0
        if minimum > 0 then
            minimums[key] = minimum
            if key ~= "level" and key ~= "itemLevel" then statFilter = true end
        end
    end
    local list, loading, unavailable = {}, 0, 0
    if query == "" and next(minimums) == nil then
        self.list = list
        self.count:SetText("")
        self.empty:SetText(AC:Trans("LID_ITEMBROWSERHINT"))
        for _, header in ipairs(self.headers) do
            local label = header.key == "attribute" and self:Label(self.attributes[self.attributeIndex]) or header.label
            header:SetText(label .. (header.key == self.sortKey and (self.descending and " v" or " ^") or ""))
        end
        self:Render()
        return
    end
    self.empty:SetText(AC:Trans("LID_NOITEMMATCHES"))
    if not self.entries or self.flavor ~= AC:GetFlavor() then self:Collect() end
    local statsAPI = C_Item and C_Item.GetItemStats or GetItemStats
    for _, entry in ipairs(self.entries) do
        local name, link, quality, itemLevel, level, itemType, subtype, _, _, icon = self:ReadItem(entry)
        entry.name = name or entry.fallback or ("#" .. entry.id)
        entry.link, entry.quality, entry.icon = link, quality or 1, icon or 134400
        entry.level, entry.itemLevel = level or 0, itemLevel or 0
        entry.kind = subtype or itemType or ""
        entry.loaded = name ~= nil
        if not name then
            if entry.unavailable then unavailable = unavailable + 1 else loading = loading + 1 end
        end
        local matches = true
        if query ~= "" then
            local text = strlower(table.concat({entry.name, tostring(entry.id), tostring(entry.level), tostring(entry.itemLevel), entry.kind, entry.source}, " "))
            matches = string.find(text, query, 1, true) ~= nil
        end
        if matches and minimums.level and (not entry.loaded or entry.level < minimums.level) then matches = false end
        if matches and minimums.itemLevel and (not entry.loaded or entry.itemLevel < minimums.itemLevel) then matches = false end
        if matches and not entry.stats and name then entry.stats = statsAPI and statsAPI(link or ("item:" .. entry.id)) or {} end
        if matches and statFilter then
            for key, minimum in pairs(minimums) do
                if key ~= "level" and key ~= "itemLevel" and (not entry.loaded or ((entry.stats or {})[key] or 0) < minimum) then matches = false end
            end
        end
        entry.attribute = (entry.stats or {})[self.attribute] or 0
        if matches then table.insert(list, entry) end
    end
    local key, descending = self.sortKey, self.descending
    table.sort(list, function(a, b)
        local av, bv = a[key], b[key]
        if type(av) == "string" then av, bv = strlower(av), strlower(bv) end
        if av == bv then return a.id < b.id end
        if descending then return av > bv end
        return av < bv
    end)
    self.list = list
    self.count:SetText(AC:Trans("LID_ITEMCOUNT", nil, #list) .. (loading > 0 and (" |cff888888(" .. AC:Trans("LID_LOADINGITEMS", nil, loading) .. ")|r") or "") .. (unavailable > 0 and (" |cff888888(" .. AC:Trans("LID_UNAVAILABLEITEMS", nil, unavailable) .. ")|r") or ""))
    for _, header in ipairs(self.headers) do
        local label = header.key == "attribute" and self:Label(self.attributes[self.attributeIndex]) or header.label
        header:SetText(label .. (header.key == key and (descending and " v" or " ^") or ""))
    end
    self:Render()
end

function Browser:Render()
    local capacity = math.max(1, math.floor(self.body:GetHeight() / 30))
    local maximum = math.max(0, #(self.list or {}) - capacity)
    self.offset = math.min(self.offset or 0, maximum)
    self.scroll:SetMinMaxValues(0, maximum)
    self.scroll:SetValue(self.offset)
    self.scroll:SetShown(maximum > 0)
    self.empty:SetShown(#(self.list or {}) == 0)
    for index = 1, math.max(capacity, #self.rows) do
        local row = self.rows[index]
        if not row and index <= capacity then
            row = CreateFrame("Button", nil, self.body)
            row:SetHeight(30)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 30)
            row:SetPoint("RIGHT", -20, 0)
            local background = row:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.045 or 0.015)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(24, 24)
            row.icon:SetPoint("LEFT", 3, 0)
            row.cells = {}
            for column, header in ipairs(self.headers) do
                local cell = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                cell:SetPoint("LEFT", row, "LEFT", header.x + (column == 1 and 30 or 4), 0)
                cell:SetWidth(header.width - (column == 1 and 34 or 8))
                cell:SetJustifyH("LEFT")
                row.cells[column] = cell
            end
            row:SetScript("OnEnter", function(button)
                if not button.entry then return end
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                if button.entry.unavailable and not button.entry.loaded then
                    GameTooltip:SetText(AC:Trans("LID_ITEMUNAVAILABLE"), 1, 0.25, 0.25)
                    GameTooltip:AddLine("#" .. button.entry.id, 0.7, 0.7, 0.7)
                else
                    GameTooltip:SetHyperlink(button.entry.link or ("item:" .. button.entry.id))
                end
                GameTooltip:AddLine(button.entry.source, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row:SetScript("OnClick", function(button)
                if button.entry and button.entry.link and HandleModifiedItemClick then HandleModifiedItemClick(button.entry.link) end
            end)
            self.rows[index] = row
        end
        local entry = index <= capacity and (self.list or {})[self.offset + index]
        if row then
            row.entry = entry
            row:SetShown(entry ~= nil)
            if entry then
                row.icon:SetTexture(entry.icon)
                local color = ITEM_QUALITY_COLORS[entry.quality] or ITEM_QUALITY_COLORS[1]
                local unavailable = entry.unavailable and not entry.loaded
                row.cells[1]:SetText(unavailable and (entry.name .. " |cffff4040(" .. AC:Trans("LID_ITEMUNAVAILABLE") .. ")|r") or entry.name)
                row.cells[1]:SetTextColor(color.r, color.g, color.b)
                for column = 2, #self.headers do
                    local key = self.headers[column].key
                    local pending = not entry.loaded and (key == "level" or key == "itemLevel" or key == "attribute" or key == "kind")
                    row.cells[column]:SetText(pending and (unavailable and "-" or "...") or tostring(entry[key]))
                end
            end
        end
    end
end

function Browser:Layout()
    local width = math.max(200, self.body:GetWidth() - 20)
    local x = 0
    for index, header in ipairs(self.headers) do
        header.x, header.width = x, width * header.fraction
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", self.table, "TOPLEFT", x + 2, -2)
        header:SetSize(header.width, 25)
        for _, row in ipairs(self.rows) do
            row.cells[index]:ClearAllPoints()
            row.cells[index]:SetPoint("LEFT", row, "LEFT", x + (index == 1 and 30 or 4), 0)
            row.cells[index]:SetWidth(math.max(1, header.width - (index == 1 and 34 or 8)))
        end
        x = x + header.width
    end
    self:Render()
end

function Browser:Create(parent)
    if self.panel then return self.panel end
    self.inputs, self.rows, self.headers = {}, {}, {}
    self.sortKey, self.attributeIndex = "name", 1
    self.attribute = self.attributes[1][1]
    local panel = CreateFrame("Frame", nil, parent)
    self.panel = panel
    AC:AnchorContent(panel)
    local filterFrame = CreateFrame("Frame", nil, panel)
    filterFrame:SetPoint("TOPLEFT")
    filterFrame:SetPoint("BOTTOMLEFT", 0, 26)
    filterFrame:SetWidth(216)
    local filterBackground = filterFrame:CreateTexture(nil, "BACKGROUND")
    filterBackground:SetAllPoints()
    filterBackground:SetAtlas("common-insideframe")
    local modernScroll = ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and AC:CheckTemplates("MinimalScrollBar")
    local filters = CreateFrame("ScrollFrame", nil, filterFrame, not modernScroll and "UIPanelScrollFrameTemplate" or nil)
    filters:SetPoint("TOPLEFT", 2, -2)
    filters:SetPoint("BOTTOMRIGHT", -22, 2)
    if modernScroll then
        local bar = CreateFrame("EventFrame", nil, filterFrame, "MinimalScrollBar")
        bar:SetPoint("TOPRIGHT", -5, -6)
        bar:SetPoint("BOTTOMRIGHT", -5, 6)
        ScrollUtil.InitScrollFrameWithScrollBar(filters, bar)
        self.filterBar = bar
    end
    filters:EnableMouseWheel(true)
    filters:SetScript("OnMouseWheel", function(scroll, delta)
        local maximum = math.max(0, scroll:GetVerticalScrollRange())
        scroll:SetVerticalScroll(math.max(0, math.min(maximum, scroll:GetVerticalScroll() - delta * 54)))
    end)
    local content = CreateFrame("Frame", nil, filters)
    content:SetSize(190, 1200)
    filters:SetScrollChild(content)
    local y = -4
    local inputParent = content
    local function Label(text)
        local label = inputParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 4, y)
        label:SetWidth(180)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        y = y - 20
    end
    local function Input(key, text, numeric)
        Label(text)
        local input = CreateFrame("EditBox", nil, inputParent, "InputBoxTemplate")
        input:SetSize(174, 22)
        input:SetPoint("TOPLEFT", 8, y)
        input:SetAutoFocus(false)
        input:SetNumeric(numeric)
        input:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
        input:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
        input:SetScript("OnTextChanged", function() self.offset = 0 self:Refresh() end)
        if key then self.inputs[key] = input else self.search = input end
        y = y - 34
    end
    Input(nil, AC:Trans("LID_ITEMSEARCH"), false)
    Input("level", AC:Trans("LID_MINLEVEL"), true)
    Input("itemLevel", AC:Trans("LID_MINITEMLEVEL"), true)
    local categoryTop = y
    self.attributeGroups = {}
    for _, definition in ipairs({{"LID_PRIMARYATTRIBUTES", true}, {"LID_SECONDARYATTRIBUTES", false}}) do
        local group = CreateFrame("Frame", nil, content)
        group:SetWidth(186)
        group.title = AC:Trans(definition[1])
        group.expanded = true
        group.header = CreateFrame("Button", nil, group)
        group.header:SetSize(186, 26)
        group.header:SetPoint("TOPLEFT")
        group.header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        group.indicator = group.header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        group.indicator:SetPoint("LEFT", 4, 0)
        group.indicator:SetText("-")
        group.label = group.header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        group.label:SetPoint("LEFT", 22, 0)
        group.label:SetText(group.title)
        group.content = CreateFrame("Frame", nil, group)
        group.content:SetPoint("TOPLEFT", 0, -28)
        group.content:SetWidth(186)
        inputParent, y = group.content, -4
        for _, attribute in ipairs(self.attributes) do
            if (attribute[3] == true) == definition[2] then Input(attribute[1], self:Label(attribute), true) end
        end
        group.contentHeight = -y
        group.content:SetHeight(group.contentHeight)
        table.insert(self.attributeGroups, group)
    end
    local reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 4, y)
    reset:SetSize(178, 24)
    reset:SetText(RESET or "Reset")
    reset:SetScript("OnClick", function()
        self.search:SetText("")
        for _, input in pairs(self.inputs) do input:SetText("") end
        self.offset = 0
        self:Refresh()
    end)
    local function LayoutCategories()
        local top = categoryTop
        for _, group in ipairs(self.attributeGroups) do
            group:ClearAllPoints()
            group:SetPoint("TOPLEFT", content, "TOPLEFT", 0, top)
            local height = 28 + (group.expanded and group.contentHeight or 0)
            group:SetHeight(height)
            group.content:SetShown(group.expanded)
            group.indicator:SetText(group.expanded and "-" or "+")
            top = top - height - 6
        end
        reset:ClearAllPoints()
        reset:SetPoint("TOPLEFT", content, "TOPLEFT", 4, top)
        content:SetHeight(-top + 34)
        filters:SetVerticalScroll(0)
    end
    for _, group in ipairs(self.attributeGroups) do
        group.header:SetScript("OnClick", function()
            group.expanded = not group.expanded
            if not group.expanded then
                for _, input in pairs(self.inputs) do
                    if input:GetParent() == group.content then input:ClearFocus() end
                end
            end
            LayoutCategories()
        end)
    end
    LayoutCategories()
    local tableFrame = CreateFrame("Frame", nil, panel)
    self.table = tableFrame
    tableFrame:SetPoint("TOPLEFT", 230, 0)
    tableFrame:SetPoint("BOTTOMRIGHT", 0, 26)
    local background = tableFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetAtlas("common-insideframe")
    local body = CreateFrame("Frame", nil, tableFrame)
    self.body = body
    body:SetPoint("TOPLEFT", 2, -32)
    body:SetPoint("BOTTOMRIGHT", -2, 2)
    local definitions = {{"name", NAME or "Name", 0.30}, {"level", LEVEL or "Level", 0.09}, {"itemLevel", AC:Trans("LID_ITEMLEVEL"), 0.11}, {"kind", TYPE or "Type", 0.15}, {"attribute", "", 0.15}, {"source", AC:Trans("LID_SOURCE"), 0.20}}
    for _, definition in ipairs(definitions) do
        local header = CreateFrame("Button", nil, tableFrame, "UIPanelButtonTemplate")
        header.key, header.label, header.fraction = unpack(definition)
        header:SetNormalFontObject("GameFontNormalSmall")
        header:SetScript("OnClick", function()
            if self.sortKey == header.key then self.descending = not self.descending else self.sortKey, self.descending = header.key, false end
            self.offset = 0
            self:Refresh()
        end)
        table.insert(self.headers, header)
    end
    local scroll = CreateFrame("Slider", nil, body, "UIPanelScrollBarTemplate")
    self.scroll = scroll
    scroll:SetPoint("TOPRIGHT", -1, -16)
    scroll:SetPoint("BOTTOMRIGHT", -1, 16)
    scroll:SetValueStep(1)
    scroll:SetScript("OnValueChanged", function(_, value)
        local offset = math.floor(value + 0.5)
        if self.offset ~= offset then self.offset = offset self:Render() end
    end)
    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local _, maximum = scroll:GetMinMaxValues()
        self.offset = math.max(0, math.min(maximum, (self.offset or 0) - delta * 3))
        self:Render()
    end)
    self.empty = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.empty:SetPoint("CENTER")
    self.empty:SetText(AC:Trans("LID_NOITEMMATCHES"))
    self.count = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    self.count:SetPoint("BOTTOMLEFT", 234, 2)
    local choose = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    choose:SetSize(150, 22)
    choose:SetPoint("BOTTOMRIGHT")
    choose:SetText(AC:Trans("LID_ATTRIBUTECOLUMN"))
    choose:SetScript("OnClick", function(button)
        local entries = {}
        for index, attribute in ipairs(self.attributes) do
            table.insert(entries, {text = self:Label(attribute), checked = self.attributeIndex == index, func = function()
                self.attributeIndex, self.attribute = index, attribute[1]
                self:Refresh()
            end})
        end
        AC:ShowContextMenu(button, entries)
    end)
    body:SetScript("OnSizeChanged", function() self:Layout() end)
    panel:SetScript("OnShow", function() self:Refresh() self:Layout() end)
    panel:Hide()
    return panel
end
