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
    local function Add(id, source, fallback, questID)
        if not id then return end
        if AC:GetFlavor() ~= "forever" and AC:IsForeverItem(id) then return end
        local entry = entries[id]
        if not entry then
            entry = {id = id, sources = {}, fallback = fallback, questIDs = {}}
            entries[id] = entry
        end
        if source and source ~= "" then entry.sources[source] = true end
        if questID then entry.questIDs[questID] = true end
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
                for _, item in ipairs(items) do Add(item[1], source, nil, questID) end
            end
        end
    end
    for questID, item in pairs(AC.QUESTSTARTITEMS or {}) do
        if AC:IsQuestForFlavor(questID) then Add(item[1], AC:Trans("LID_QUESTS") .. " #" .. questID, nil, questID) end
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
    local minimums, maximums, statFilter = {}, {}, false
    for key, input in pairs(self.inputs) do
        local value = tonumber(input:GetText())
        if string.sub(key, 1, 4) == "max:" then
            if value and value >= 0 then maximums[string.sub(key, 5)] = value statFilter = true end
        elseif value and value > 0 then
            minimums[key] = value
            if key ~= "level" and key ~= "maxLevel" and key ~= "itemLevel" then statFilter = true end
        end
    end
    local list, loading, unavailable = {}, 0, 0
    if query == "" and next(minimums) == nil and next(maximums) == nil then
        self.list = list
        self.count:SetText("")
        self.empty:SetText(AC:Trans("LID_ITEMBROWSERHINT"))
        for _, header in ipairs(self.headers) do
            self:SetHeaderText(header)
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
        if matches and minimums.maxLevel and (not entry.loaded or entry.level > minimums.maxLevel) then matches = false end
        if matches and minimums.itemLevel and (not entry.loaded or entry.itemLevel < minimums.itemLevel) then matches = false end
        if matches and not entry.stats and name then entry.stats = statsAPI and statsAPI(link or ("item:" .. entry.id)) or {} end
        if matches and statFilter then
            for key, minimum in pairs(minimums) do
                if key ~= "level" and key ~= "maxLevel" and key ~= "itemLevel" and (not entry.loaded or ((entry.stats or {})[key] or 0) < minimum) then matches = false end
            end
        end
        if matches then
            for key, maximum in pairs(maximums) do
                if not entry.loaded or ((entry.stats or {})[key] or 0) > maximum then matches = false end
            end
        end
        entry.attribute = (entry.stats or {})[self.attribute] or 0
        if matches and entry.loaded then table.insert(list, entry) end
    end
    local key, descending = self.sortKey, self.descending
    table.sort(list, function(a, b)
        local av, bv = self:GetColumnValue(a, key), self:GetColumnValue(b, key)
        if type(av) == "string" then av, bv = strlower(av), strlower(bv) end
        if av == bv then return a.id < b.id end
        if descending then return av > bv end
        return av < bv
    end)
    self.list = list
    self.count:SetText(AC:Trans("LID_ITEMCOUNT", nil, #list) .. (loading > 0 and (" |cff888888(" .. AC:Trans("LID_LOADINGITEMS", nil, loading) .. ")|r") or "") .. (unavailable > 0 and (" |cff888888(" .. AC:Trans("LID_UNAVAILABLEITEMS", nil, unavailable) .. ")|r") or ""))
    for _, header in ipairs(self.headers) do
        self:SetHeaderText(header)
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
                GameTooltip:SetHyperlink(button.entry.link or ("item:" .. button.entry.id))
                GameTooltip:AddLine(button.entry.source, 0.7, 0.7, 0.7, true)
                GameTooltip:AddLine(AC:Trans("LID_CATALOGSOURCEHINT"), 0.2, 1, 0.2, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row:SetScript("OnClick", function(button)
                if not button.entry then return end
                if button.entry.link and HandleModifiedItemClick and HandleModifiedItemClick(button.entry.link) then return end
                AC:NavigateToCatalogItem(button.entry)
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
                row.cells[1]:SetText(entry.name)
                row.cells[1]:SetTextColor(color.r, color.g, color.b)
                for column = 2, #self.headers do
                    row.cells[column]:SetText(tostring(self:GetColumnValue(entry, self.headers[column].key)))
                end
            end
        end
    end
end

function Browser:GetColumnValue(entry, key)
    if string.sub(key, 1, 5) == "stat:" then return (entry.stats or {})[string.sub(key, 6)] or 0 end
    return entry[key]
end

function Browser:SetHeaderText(header)
    local suffix = ""
    if header.key == self.sortKey then
        local direction = self.descending and "Down" or "Up"
        suffix = " |TInterface\\Buttons\\UI-ScrollBar-Scroll" .. direction .. "Button-Up:28:28:0:0|t"
    end
    if header.OverrideText then header:OverrideText(header.label .. suffix) else header:SetText(header.label .. suffix) end
end

function Browser:BuildColumns()
    for _, header in ipairs(self.headers) do header:Hide() end
    for _, row in ipairs(self.rows) do row:Hide() end
    self.headers, self.rows = {}, {}
    local definitions = {{"name", NAME or "Name", 180}, {"level", LEVEL or "Level", 64}, {"itemLevel", AC:Trans("LID_ITEMLEVEL"), 76}, {"kind", TYPE or "Type", 90}}
    for _, attribute in ipairs(self.attributes) do
        if self.selectedAttributes[attribute[1]] then table.insert(definitions, {"stat:" .. attribute[1], self:Label(attribute), 100}) end
    end
    table.insert(definitions, {"source", AC:Trans("LID_SOURCE"), 140})
    local validSort = false
    for _, definition in ipairs(definitions) do
        local modern = AC:CheckTemplates("WowStyle1DropdownTemplate")
        local header = CreateFrame(modern and "DropdownButton" or "Button", nil, self.table, modern and "WowStyle1DropdownTemplate" or "UIPanelButtonTemplate")
        header.key, header.label, header.minimumWidth = unpack(definition)
        if header.key == self.sortKey then validSort = true end
        local function Sort(descending)
            self.sortKey, self.descending, self.offset = header.key, descending, 0
            self:Refresh()
        end
        if modern then
            header:SetupMenu(function(_, root)
                root:CreateRadio(AC:Trans("LID_SORTASCENDING"), function() return self.sortKey == header.key and not self.descending end, function() Sort(false) end)
                root:CreateRadio(AC:Trans("LID_SORTDESCENDING"), function() return self.sortKey == header.key and self.descending end, function() Sort(true) end)
            end)
        else
            header:SetScript("OnClick", function() Sort(self.sortKey == header.key and not self.descending) end)
        end
        table.insert(self.headers, header)
    end
    if not validSort then self.sortKey, self.descending = "name", false end
    for _, header in ipairs(self.headers) do self:SetHeaderText(header) end
    self:Layout()
end

function Browser:Layout()
    local minimumWidth = 0
    for _, header in ipairs(self.headers) do minimumWidth = minimumWidth + header.minimumWidth end
    local viewportWidth = math.max(1, self.horizontalViewport:GetWidth())
    local canvasWidth = math.max(viewportWidth, minimumWidth + 24)
    self.table:SetSize(canvasWidth, math.max(1, self.horizontalViewport:GetHeight()))
    self.horizontalBar:SetMinMaxValues(0, math.max(0, canvasWidth - viewportWidth))
    self.horizontalBar:SetShown(canvasWidth > viewportWidth)
    self.horizontalBar:SetValue(math.min(self.horizontalBar:GetValue(), math.max(0, canvasWidth - viewportWidth)))
    self.horizontalViewport:SetHorizontalScroll(self.horizontalBar:GetValue())
    local width = canvasWidth - 24
    local x = 0
    for index, header in ipairs(self.headers) do
        header.x, header.width = x, width * header.minimumWidth / math.max(1, minimumWidth)
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
    self.selectedAttributes = {[self.attribute] = true}
    local panel = CreateFrame("Frame", nil, parent)
    self.panel = panel
    AC:AnchorContent(panel)
    local filterFrame = CreateFrame("Frame", nil, panel)
    filterFrame:SetPoint("TOPLEFT")
    filterFrame:SetPoint("BOTTOMLEFT", 0, 0)
    filterFrame:SetWidth(216)
    AzerothCompendiumAPI.AddContentBorder(filterFrame)
    local modernScroll = ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and AC:CheckTemplates("MinimalScrollBar")
    local filters = CreateFrame("ScrollFrame", nil, filterFrame, not modernScroll and "UIPanelScrollFrameTemplate" or nil)
    filters:SetPoint("TOPLEFT", 8, -2)
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
    local y = -12
    self.filterPages, self.filterTabs = {}, {}
    local general = CreateFrame("Frame", nil, content)
    general:SetPoint("TOPLEFT")
    general:SetWidth(186)
    self.filterPages[1] = general
    local inputParent = general
    local function Label(text)
        local label = inputParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 4, y)
        label:SetWidth(180)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        y = y - 15
    end
    local function Input(key, text, numeric, bound)
        if bound ~= "max" then Label(text) end
        local input = CreateFrame("EditBox", nil, inputParent, "InputBoxTemplate")
        input:SetSize(bound and 72 or 168, 22)
        input:SetPoint("TOPLEFT", bound == "max" and 104 or 8, y)
        input:SetAutoFocus(false)
        input:SetNumeric(numeric)
        input:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
        input:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
        if not key or bound then
            input.placeholder = input:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            input.placeholder:SetPoint("LEFT", 2, 0)
            input.placeholder:SetPoint("RIGHT", -2, 0)
            input.placeholder:SetJustifyH("LEFT")
            input.placeholder:SetWordWrap(false)
            input.placeholder:SetText(bound and (bound == "max" and "Max" or "Min") or AC:Trans("LID_ITEMSEARCHPLACEHOLDER"))
        end
        input:SetScript("OnTextChanged", function(box)
            if box.placeholder then box.placeholder:SetShown(box:GetText() == "") end
            self.offset = 0
            self:Refresh()
        end)
        if key then self.inputs[key] = input else self.search = input end
        if bound == "min" then
            local separator = inputParent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            separator:SetPoint("TOPLEFT", 84, y - 4)
            separator:SetWidth(16)
            separator:SetText("-")
        else
            y = y - 34
        end
    end
    Input(nil, AC:Trans("LID_ITEMSEARCH"), false)
    Input("level", AC:Trans("LID_MINLEVEL"), true)
    Input("maxLevel", AC:Trans("LID_MAXLEVEL"), true)
    Input("itemLevel", AC:Trans("LID_MINITEMLEVEL"), true)
    general:SetHeight(-y)
    for _, primary in ipairs({true, false}) do
        local page = CreateFrame("Frame", nil, content)
        page:SetPoint("TOPLEFT")
        page:SetWidth(186)
        inputParent, y = page, -12
        for _, attribute in ipairs(self.attributes) do
            if (attribute[3] == true) == primary then
                Input(attribute[1], self:Label(attribute), true, "min")
                Input("max:" .. attribute[1], self:Label(attribute), true, "max")
            end
        end
        page:SetHeight(-y)
        table.insert(self.filterPages, page)
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
    function self:SelectFilterPage(index)
        self.filterPage = index
        self.search:ClearFocus()
        for _, input in pairs(self.inputs) do input:ClearFocus() end
        for pageIndex, page in ipairs(self.filterPages) do page:SetShown(pageIndex == index) end
        for tabIndex, tab in ipairs(self.filterTabs) do tab:SetTabSelected(tabIndex == index) end
        local height = self.filterPages[index]:GetHeight()
        reset:ClearAllPoints()
        reset:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -height - 6)
        content:SetHeight(height + 40)
        filters:SetVerticalScroll(0)
    end
    local definitions = {{"LID_GENERALFILTERS", 134442}, {"LID_PRIMARYATTRIBUTES", 132333}, {"LID_SECONDARYATTRIBUTES", 136112}}
    local previous
    for index, definition in ipairs(definitions) do
        local tab = AzerothCompendiumAPI.CreateContentTab(panel, definition[1], definition[2], function() self:SelectFilterPage(index) end)
        tab:ClearAllPoints()
        AzerothCompendiumAPI.PositionContentTab(tab, filterFrame, previous)
        self.filterTabs[index] = tab
        previous = tab
    end
    self:SelectFilterPage(1)
    local tableBorder = CreateFrame("Frame", nil, panel)
    tableBorder:SetPoint("TOPLEFT", 230, 0)
    tableBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    local viewport = CreateFrame("ScrollFrame", nil, tableBorder)
    viewport:SetPoint("TOPLEFT", 2, -2)
    viewport:SetPoint("BOTTOMRIGHT", -22, 12)
    self.horizontalViewport = viewport
    local tableFrame = CreateFrame("Frame", nil, viewport)
    self.table = tableFrame
    tableFrame:SetSize(1, 1)
    viewport:SetScrollChild(tableFrame)
    local horizontalBar = CreateFrame("Slider", nil, tableBorder)
    horizontalBar:SetOrientation("HORIZONTAL")
    horizontalBar:SetPoint("BOTTOMLEFT", 4, 3)
    horizontalBar:SetPoint("BOTTOMRIGHT", -4, 3)
    horizontalBar:SetHeight(6)
    horizontalBar:SetMinMaxValues(0, 0)
    horizontalBar:SetValue(0)
    horizontalBar:SetValueStep(12)
    local track = horizontalBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    local thumb = horizontalBar:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(32, 6)
    thumb:SetColorTexture(0.7, 0.6, 0.4, 1)
    horizontalBar:SetThumbTexture(thumb)
    horizontalBar:SetScript("OnValueChanged", function(_, value) viewport:SetHorizontalScroll(value) end)
    self.horizontalBar = horizontalBar
    AzerothCompendiumAPI.AddContentBorder(tableBorder)
    local body = CreateFrame("Frame", nil, tableFrame)
    self.body = body
    body:SetPoint("TOPLEFT", 2, -32)
    body:SetPoint("BOTTOMRIGHT", -2, 2)
    local scroll = CreateFrame("Slider", nil, tableBorder, "UIPanelScrollBarTemplate")
    self.scroll = scroll
    scroll:SetPoint("TOPRIGHT", tableBorder, "TOPRIGHT", -3, -48)
    scroll:SetPoint("BOTTOMRIGHT", tableBorder, "BOTTOMRIGHT", -3, 28)
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
    self.count:SetPoint("BOTTOMLEFT", tableBorder, "TOPLEFT", 4, 8)
    local modern = AC:CheckTemplates("WowStyle1DropdownTemplate")
    local choose = CreateFrame(modern and "DropdownButton" or "Button", nil, panel, modern and "WowStyle1DropdownTemplate" or "UIPanelButtonTemplate")
    choose:SetSize(180, 22)
    choose:SetPoint("BOTTOMRIGHT", tableBorder, "TOPRIGHT", 0, 6)
    local function Toggle(attribute)
        self.selectedAttributes[attribute[1]] = not self.selectedAttributes[attribute[1]]
        self:BuildColumns()
        self:Refresh()
    end
    if modern then
        choose:OverrideText(AC:Trans("LID_ATTRIBUTECOLUMN"))
        choose:SetupMenu(function(_, root)
            root:CreateTitle(AC:Trans("LID_PRIMARYATTRIBUTES"))
            for index, attribute in ipairs(self.attributes) do
                if index == 6 then root:CreateTitle(AC:Trans("LID_SECONDARYATTRIBUTES")) end
                root:CreateCheckbox(self:Label(attribute), function() return self.selectedAttributes[attribute[1]] == true end, function() Toggle(attribute) end)
            end
        end)
    else
        choose:SetText(AC:Trans("LID_ATTRIBUTECOLUMN"))
        choose:SetScript("OnClick", function(button)
            local entries = {}
            for _, attribute in ipairs(self.attributes) do
                table.insert(entries, {text = self:Label(attribute), checked = self.selectedAttributes[attribute[1]] == true, func = function() Toggle(attribute) end})
            end
            AC:ShowContextMenu(button, entries)
        end)
    end
    self:BuildColumns()
    self.horizontalViewport:SetScript("OnSizeChanged", function() self:Layout() end)
    panel:SetScript("OnShow", function() self:Refresh() self:Layout() end)
    panel:Hide()
    return panel
end
