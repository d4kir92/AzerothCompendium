local _, Addon = ...
local Library = {bags = {}, categories = {"all", "starter", "l35", "l45", "l60", "rewards"}, levels = {starter = 20, l35 = 35, l45 = 45, l60 = 60}}
Addon.Library = Library

function Library:Text(key)
    return Addon:Trans("LID_LIBRARY_" .. key)
end

function Library:DB()
    ACOTABPC.LIBRARYBOOKS = ACOTABPC.LIBRARYBOOKS or {done = {}, manual = {}, bank = {}}
    return ACOTABPC.LIBRARYBOOKS
end

function Library:Flag(book)
    return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(book.questId) or false
end

function Library:State(book)
    local db = self:DB()
    if db.done[book.itemId] then return "done" end
    if db.manual[book.itemId] then return "manual" end
    if self.bags[book.itemId] then return "bag" end
    if db.bank[book.itemId] then return "bank" end
    if self:Flag(book) then return "questflag" end
    return "missing"
end

function Library:Scan(bank)
    if not C_Container then return end
    local items = {}
    local first, last = 0, 4
    if bank then first, last = 5, 11 end
    local function read(bag)
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id then items[id] = true end
        end
    end
    if bank then read(-1) end
    for bag = first, last do read(bag) end
    if bank then
        self:DB().bank = items
        self:DB().bankScanned = time()
    else
        self.bags = items
    end
end

function Library:Name(book)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(book.itemId)
    return name or book.name
end

function Library:Zone(book)
    local id = Addon.LIBRARYMAPS[book.zone]
    local info = id and C_Map and C_Map.GetMapInfo(id)
    return info and info.name or book.zone
end

function Library:Tooltip(row, book)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self:Name(book), 1, 0.82, 0)
    GameTooltip:AddLine(self:Zone(book) .. (book.subzone and " - " .. book.subzone or ""), 1, 1, 1, true)
    GameTooltip:AddLine(self:Text(Addon.LIBRARYTERRITORIES[book.zone] or "Contested"), 0.8, 0.8, 0.8)
    if book.x then GameTooltip:AddLine(string.format("%.1f, %.1f", book.x, book.y), 1, 1, 1) end
    GameTooltip:AddLine(book.container or "", 0.7, 0.8, 1)
    GameTooltip:AddLine(self:Text(book.status), 1, 0.75, 0.3, true)
    if book.note then GameTooltip:AddLine(book.note, 1, 1, 1, true) end
    for _, source in ipairs(book.sources or {}) do
        GameTooltip:AddLine(string.format("%s — %s (%.1f, %.1f)", source.name, source.zone, source.x, source.y), 0.7, 0.8, 1, true)
    end
    GameTooltip:AddLine(self:Text(self:State(book)), 0.7, 0.85, 1)
    GameTooltip:AddLine(string.format("Quest: %d / Item: %d", book.questId, book.itemId), 0.6, 0.6, 0.6)
    if self:Flag(book) then GameTooltip:AddLine(self:Text("flaghint"), 1, 0.6, 0.2, true) end
    local scanned = self:DB().bankScanned
    GameTooltip:AddLine(self:Text("bankscan") .. (scanned and date("%Y-%m-%d %H:%M", scanned) or self:Text("unknown")), 0.7, 0.7, 0.7, true)
    GameTooltip:AddLine(self:Text("clickhint"), 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

function Library:Create(host)
    self.host = host
    host.category = "all"
    host.rows = {}
    local function label(parent, font)
        local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
        text:SetJustifyH("LEFT")
        return text
    end
    host.summary = label(host, "GameFontNormalLarge")
    host.summary:SetPoint("TOPLEFT", 14, -14)
    host.summary:SetPoint("TOPRIGHT", -14, -14)
    host.navigation = {}
    for index, key in ipairs(self.categories) do
        local button = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        button:SetSize(155, 26)
        button:SetPoint("TOPLEFT", 12, -52 - (index - 1) * 31)
        button:SetScript("OnClick", function() host.category = key; host.scroll:SetVerticalScroll(0); self:Refresh() end)
        host.navigation[key] = button
    end
    host.hideDone = CreateFrame("CheckButton", nil, host, "UICheckButtonTemplate")
    host.hideDone:SetPoint("TOPLEFT", 12, -245)
    host.hideLabel = label(host, "GameFontHighlightSmall")
    host.hideLabel:SetPoint("TOPLEFT", 16, -278)
    host.hideLabel:SetWidth(150)
    host.hideDone:SetScript("OnClick", function() self:Refresh() end)
    host.scroll = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
    host.scroll:SetPoint("TOPLEFT", 180, -50)
    host.scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    host.content = CreateFrame("Frame", nil, host.scroll)
    host.content:SetSize(400, 1)
    host.scroll:SetScrollChild(host.content)
    host.scroll:SetScript("OnSizeChanged", function(_, width) host.content:SetWidth(width); self:Refresh() end)
    host.OnSearchChanged = function(_, text) host.searchText = text; host.scroll:SetVerticalScroll(0); self:Refresh() end
    host:SetScript("OnShow", function() self:Scan(false); self:Refresh() end)
    host.NewRow = function(_, index)
        local row = CreateFrame("Button", nil, host.content)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 52)
        row:SetPoint("RIGHT", host.content, "RIGHT")
        row:SetHeight(50)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.title = label(row)
        row.title:SetPoint("TOPLEFT", 8, -5)
        row.title:SetPoint("TOPRIGHT", -8, -5)
        row.title:SetWordWrap(false)
        row.detail = label(row, "GameFontHighlightSmall")
        row.detail:SetPoint("TOPLEFT", 8, -26)
        row.detail:SetPoint("TOPRIGHT", -8, -26)
        row.detail:SetWordWrap(false)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return row
    end
    Addon.Theme:RegisterRoot(host)
    self:Refresh()
end

function Library:Refresh()
    local host = self.host
    if not host then return end
    local done, owned, counts = 0, 0, {}
    for _, book in ipairs(Addon.LIBRARYBOOKS) do
        local state = self:State(book)
        counts[book.set] = counts[book.set] or {0, 0}
        counts[book.set][2] = counts[book.set][2] + 1
        if state == "done" then done = done + 1; counts[book.set][1] = counts[book.set][1] + 1 end
        if state ~= "missing" and state ~= "questflag" then owned = owned + 1 end
    end
    host.summary:SetText(string.format(self:Text("progress"), done, #Addon.LIBRARYBOOKS, owned))
    host.hideLabel:SetText(self:Text("hidedone"))
    for key, button in pairs(host.navigation) do
        local text = self.levels[key] and string.format(self:Text("level"), self.levels[key]) or self:Text(key)
        if counts[key] then text = text .. string.format(" (%d/%d)", counts[key][1], counts[key][2]) end
        button:SetText(text)
        button:SetEnabled(host.category ~= key)
    end
    for _, row in ipairs(host.rows) do row:Hide() end
    local index = 0
    local function row(title, detail, click, enter)
        index = index + 1
        local r = host.rows[index] or host:NewRow(index)
        host.rows[index] = r
        r.title:SetText(title)
        r.detail:SetText(detail)
        r:SetScript("OnClick", click)
        r:SetScript("OnEnter", enter)
        r:Show()
    end
    if host.category == "rewards" then
        row(self:Text("turnin"), self:Text("rewardhint"))
        row("Garion Wendell — " .. self:Text("Alliance"), "Stormwind / 37.6, 80.8", function() Addon:SetMapWaypoint(1453, 37.6, 80.8) end)
        row("Owen Thadd — " .. self:Text("Horde"), "Undercity / 73.4, 33.0", function() Addon:SetMapWaypoint(1458, 73.4, 33.0) end)
        row(self:Text("mage"), self:Text("beta"))
        for _, tier in ipairs(Addon.LIBRARYREWARDS) do
            row(tier.quest .. " — " .. tier.books, string.format(self:Text("level"), tier.req) .. " / Quest: " .. tier.questID)
            for _, item in ipairs(tier.items) do
                row(item[2], item[4], function()
                    if IsControlKeyDown() and DressUpItemLink then DressUpItemLink("item:" .. item[1]) end
                end, function(r)
                    GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. item[1])
                    GameTooltip:Show()
                end)
            end
        end
    else
        local search = string.lower(host.searchText or "")
        local books = {}
        for _, book in ipairs(Addon.LIBRARYBOOKS) do
            local haystack = string.lower(self:Name(book) .. " " .. book.name .. " " .. self:Zone(book) .. " " .. (book.subzone or "") .. " " .. (book.note or "") .. " " .. book.itemId .. " " .. book.questId)
            if (host.category == "all" or host.category == book.set) and (not host.hideDone:GetChecked() or self:State(book) ~= "done") and string.find(haystack, search, 1, true) then books[#books + 1] = book end
        end
        table.sort(books, function(a, b)
            if a.set ~= b.set then return self.levels[a.set] < self.levels[b.set] end
            if a.zone ~= b.zone then return self:Zone(a) < self:Zone(b) end
            return self:Name(a) < self:Name(b)
        end)
        for _, book in ipairs(books) do
            local state = self:State(book)
            local color = state == "done" and "|cff66dd66" or state == "questflag" and "|cffffaa44" or "|cffffffff"
            row(color .. self:Name(book) .. "|r", self:Text(state) .. " — " .. self:Zone(book) .. (book.x and string.format(" (%.1f, %.1f)", book.x, book.y) or ""), function(_, button)
                if button == "RightButton" then
                    local manual = self:DB().manual
                    manual[book.itemId] = not manual[book.itemId] or nil
                    self:Refresh()
                elseif book.x and book.y then
                    Addon:SetMapWaypoint(Addon.LIBRARYMAPS[book.zone], book.x, book.y)
                end
            end, function(r) self:Tooltip(r, book) end)
        end
        if #books == 0 then row(self:Text("empty"), "") end
    end
    host.content:SetHeight(math.max(1, index * 52))
end

function Library:SyncTab()
    if Addon:GetFlavor() == "forever" then
        AzerothCompendiumAPI.RegisterTab("LibraryBooks", {label = "LibraryBooks", icon = "Interface\\Icons\\INV_Misc_Book_09", insertBefore = "wishlist", createPanel = function(host) self:Create(host) end})
    else
        AzerothCompendiumAPI.UnregisterTab("LibraryBooks")
    end
end

Library.events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "QUEST_TURNED_IN", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "QUEST_LOG_UPDATE", "GET_ITEM_INFO_RECEIVED"}) do
    Library.events:RegisterEvent(event)
end
Library.events:SetScript("OnEvent", function(_, event, questID)
    if not ACOTABPC then return end
    if event == "PLAYER_LOGIN" then
        Library:Scan(false)
        Library:SyncTab()
        Addon:OnLanguage(function() Library:Refresh() end)
    elseif event == "QUEST_TURNED_IN" then
        for _, book in ipairs(Addon.LIBRARYBOOKS) do
            if book.questId == questID then Library:DB().done[book.itemId] = true end
        end
    elseif event == "BANKFRAME_OPENED" then
        Library.bankOpen = true
        Library:Scan(true)
    elseif event == "BANKFRAME_CLOSED" then
        Library.bankOpen = false
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYERBANKSLOTS_CHANGED" then
        Library:Scan(false)
        if Library.bankOpen then Library:Scan(true) end
    end
    if Library.host and Library.host:IsShown() then Library:Refresh() end
end)
