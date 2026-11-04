local _, Addon = ...
local Library = {bags = {}, categories = {"all", "starter", "l35", "l45", "l60", "rewards"}, levels = {starter = 20, l35 = 35, l45 = 45, l60 = 60}, icons = {all = "Interface\\Icons\\INV_Misc_Book_09", starter = "Interface\\Icons\\INV_Misc_Book_07", l35 = "Interface\\Icons\\INV_Misc_Book_11", l45 = "Interface\\Icons\\INV_Misc_Book_06", l60 = "Interface\\Icons\\INV_Misc_Book_04", rewards = "Interface\\Icons\\INV_Jewelry_Ring_03"}}
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

function Library:CategoryText(key)
    return self.levels[key] and string.format(self:Text("level"), self.levels[key]) or self:Text(key)
end

function Library:Icon(itemId)
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemId) or GetItemIcon and GetItemIcon(itemId)
    return icon or self.icons.all
end

function Library:Create(host)
    self.host = host
    host.category = "all"
    host.rows = {}
    local api = AzerothCompendiumAPI
    api.AddContentBorder(host)
    local function label(parent, font)
        local text = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        return text
    end
    host.tabs = {}
    local previous
    for _, key in ipairs(self.categories) do
        local tab = api.CreateContentTab(host, key, self.icons[key], function()
            host.category = key
            host.scroll:SetVerticalScroll(0)
            self:Refresh()
        end)
        tab.category = key
        tab:SetScript("OnEnter", function(button)
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button.tooltip or self:CategoryText(key))
            GameTooltip:Show()
        end)
        api.PositionContentTab(tab, host, previous)
        host.tabs[#host.tabs + 1] = tab
        previous = tab
    end
    host.hideDone = CreateFrame("CheckButton", nil, host, "UICheckButtonTemplate")
    host.hideDone:SetSize(24, 24)
    host.hideDone:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", -2, 8)
    host.hideDone:SetScript("OnClick", function() self:Refresh() end)
    host.hideLabel = label(host, "GameFontHighlightSmall")
    host.hideLabel:SetPoint("RIGHT", host.hideDone, "LEFT", -2, 0)
    host.title = label(host, "GameFontNormal")
    host.title:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT", 12, 17)
    host.title:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", -240, 17)
    host.desc = label(host, "GameFontHighlightSmall")
    host.desc:SetTextColor(0.75, 0.75, 0.75)
    host.desc:SetPoint("TOPLEFT", host.title, "BOTTOMLEFT", 0, -3)
    host.desc:SetPoint("TOPRIGHT", host.title, "BOTTOMRIGHT", 0, -3)
    host.scroll = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
    host.scroll:SetPoint("TOPLEFT", 6, -6)
    host.scroll:SetPoint("BOTTOMRIGHT", -28, 6)
    host.content = CreateFrame("Frame", nil, host.scroll)
    host.content:SetSize(400, 1)
    host.scroll:SetScrollChild(host.content)
    host.scroll:SetScript("OnSizeChanged", function(_, width) host.content:SetWidth(width); self:Refresh() end)
    host.OnSearchChanged = function(_, text) host.searchText = text; host.scroll:SetVerticalScroll(0); self:Refresh() end
    host:SetScript("OnShow", function() self:Scan(false); self:Refresh() end)
    host.NewRow = function(_, index)
        local row = CreateFrame("Button", nil, host.content)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 44)
        row:SetPoint("RIGHT", host.content, "RIGHT")
        row:SetHeight(42)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(34, 34)
        row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.title = label(row)
        row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -2)
        row.title:SetPoint("RIGHT", -8, 0)
        row.detail = label(row, "GameFontHighlightSmall")
        row.detail:SetTextColor(0.8, 0.8, 0.8)
        row.detail:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 2)
        row.detail:SetPoint("RIGHT", -8, 0)
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
    local category = host.category
    host.title:SetText(self:CategoryText(category) .. (counts[category] and string.format(" (%d/%d)", counts[category][1], counts[category][2]) or ""))
    host.desc:SetText(string.format(self:Text("progress"), done, #Addon.LIBRARYBOOKS, owned))
    host.hideLabel:SetText(self:Text("hidedone"))
    host.hideDone:SetShown(category ~= "rewards")
    host.hideLabel:SetShown(category ~= "rewards")
    for _, tab in ipairs(host.tabs) do
        local key = tab.category
        tab.tooltip = self:CategoryText(key) .. (counts[key] and string.format(" (%d/%d)", counts[key][1], counts[key][2]) or "")
        tab:SetTabSelected(category == key)
    end
    for _, row in ipairs(host.rows) do row:Hide() end
    local index = 0
    local function row(icon, title, detail, click, enter)
        index = index + 1
        local r = host.rows[index] or host:NewRow(index)
        host.rows[index] = r
        r.icon:SetTexture(icon)
        r.title:SetText(title)
        r.detail:SetText(detail)
        r:SetScript("OnClick", click)
        r:SetScript("OnEnter", enter)
        r:Show()
    end
    if host.category == "rewards" then
        row(self.icons.all, self:Text("turnin"), self:Text("rewardhint"))
        row("Interface\\Icons\\INV_BannerPVP_02", "Garion Wendell — " .. self:Text("Alliance"), "Stormwind / 37.6, 80.8", function() Addon:SetMapWaypoint(1453, 37.6, 80.8) end)
        row("Interface\\Icons\\INV_BannerPVP_01", "Owen Thadd — " .. self:Text("Horde"), "Undercity / 73.4, 33.0", function() Addon:SetMapWaypoint(1458, 73.4, 33.0) end)
        row("Interface\\Icons\\INV_Staff_13", self:Text("mage"), self:Text("beta"))
        for _, tier in ipairs(Addon.LIBRARYREWARDS) do
            row("Interface\\Icons\\INV_Misc_Note_01", tier.quest .. " — " .. tier.books, string.format(self:Text("level"), tier.req) .. " / Quest: " .. tier.questID)
            for _, item in ipairs(tier.items) do
                row(self:Icon(item[1]), item[2], item[4], function()
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
            row(self:Icon(book.itemId), color .. self:Name(book) .. "|r", self:Text(state) .. " — " .. self:Zone(book) .. (book.x and string.format(" (%.1f, %.1f)", book.x, book.y) or ""), function(_, button)
                if button == "RightButton" then
                    local manual = self:DB().manual
                    manual[book.itemId] = not manual[book.itemId] or nil
                    self:Refresh()
                elseif book.x and book.y then
                    Addon:SetMapWaypoint(Addon.LIBRARYMAPS[book.zone], book.x, book.y)
                end
            end, function(r) self:Tooltip(r, book) end)
        end
        if #books == 0 then row(self.icons.all, self:Text("empty"), "") end
    end
    host.content:SetHeight(math.max(1, index * 44))
end

function Library:SyncTab()
    local flavor = Addon:GetFlavor()
    if (flavor == "forever" or flavor == "tbc" or flavor == "classic_era") and Addon:GetConfig("LIBRARYBOOKS_TAB", true) ~= false then
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
