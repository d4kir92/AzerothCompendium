local _, DungeonJournal = ...
local WIDTH = 860
local HEIGHT = 580
local ROW_H = 22
local LOOT_ROW_H = 34
local COL_W = 200
local SCROLLBAR_W = 18
local SIDE_TAB_TOP = 62
local SIDE_TAB_GAP = 3
local MODEL_START_ROTATION = 0.4
local MODEL_ZOOM_MIN = 0.4
local MODEL_ZOOM_MAX = 4
local journal = nil
local selectedInstance = nil
local selectedBoss = nil
local listKind = "dungeon"
local detailKind = "loot"
local searchText = ""
local refreshPending = false

local function Lower(text)
    if text == nil then return "" end

    return strlower(text)
end

local function Matches(text)
    if searchText == "" then return true end
    if text == nil then return false end

    return strfind(Lower(text), searchText, 1, true) ~= nil
end

local function BossMatches(boss)
    if searchText == "" then return true end
    if Matches(DungeonJournal:GetBossName(boss)) then return true end
    if Matches(boss.name) then return true end
    for _, entry in ipairs(boss.loot or {}) do
        if Matches(DungeonJournal:GetItemDisplay(entry[1])) then return true end
    end

    return false
end

local function InstanceMatches(inst)
    if searchText == "" then return true end
    if Matches(DungeonJournal:GetInstanceName(inst)) then return true end
    if Matches(inst.name) then return true end
    for _, boss in ipairs(inst.bosses or {}) do
        if BossMatches(boss) then return true end
    end

    return false
end

local function HasModernScroll()
    if ScrollUtil == nil then return false end
    if ScrollUtil.InitScrollBoxWithScrollBar == nil then return false end
    if CreateScrollBoxLinearView == nil then return false end

    return DungeonJournal:CheckTemplates("WowScrollBox, MinimalScrollBar")
end

local function CreateScroller(parent, rowHeight, initRow)
    local scroller = CreateFrame("Frame", nil, parent)
    scroller.rowHeight = rowHeight
    scroller.initRow = initRow
    scroller.rows = {}
    scroller.data = {}
    local content = nil
    if HasModernScroll() then
        local box = CreateFrame("Frame", nil, scroller, "WowScrollBox")
        box:SetPoint("TOPLEFT", scroller, "TOPLEFT", 0, 0)
        box:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -SCROLLBAR_W, 0)
        local bar = CreateFrame("EventFrame", nil, scroller, "MinimalScrollBar")
        bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
        bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)
        content = CreateFrame("Frame", nil, box)
        content.scrollable = true
        content:SetSize(1, 1)
        local view = CreateScrollBoxLinearView()
        view:SetPanExtent(rowHeight)
        ScrollUtil.InitScrollBoxWithScrollBar(box, bar, view)
        scroller.box = box
        scroller.bar = bar
    else
        local scroll = nil
        if DungeonJournal:CheckTemplates("UIPanelScrollFrameTemplate") then
            scroll = CreateFrame("ScrollFrame", nil, scroller, "UIPanelScrollFrameTemplate")
        else
            scroll = CreateFrame("ScrollFrame", nil, scroller)
        end

        scroll:SetPoint("TOPLEFT", scroller, "TOPLEFT", 0, 0)
        scroll:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -SCROLLBAR_W, 0)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(sel, delta)
            local range = max(0, (sel.djHeight or 0) - sel:GetHeight())
            sel:SetVerticalScroll(min(range, max(0, sel:GetVerticalScroll() - delta * rowHeight * 3)))
        end)

        content = CreateFrame("Frame", nil, scroll)
        content:SetSize(1, 1)
        scroll:SetScrollChild(content)
        scroller.scroll = scroll
    end

    scroller.content = content
    function scroller:GetViewport()
        if type(self.box) == "table" then return self.box end
        if type(self.scroll) == "table" then return self.scroll end

        return nil
    end

    function scroller:UpdateScroll()
        local height = max(1, #self.data * self.rowHeight)
        self.content:SetHeight(height)
        if type(self.scroll) == "table" then self.scroll.djHeight = height end
        if type(self.box) == "table" and self.box.FullUpdate and ScrollBoxConstants then self.box:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
    end

    function scroller:ScrollToTop()
        if type(self.box) == "table" and self.box.ScrollToBegin then
            self.box:ScrollToBegin()
        elseif type(self.scroll) == "table" then
            self.scroll:SetVerticalScroll(0)
        end
    end

    function scroller:Scroll(offset)
        local viewport = self:GetViewport()
        if viewport == nil then return end
        local range = max(0, #self.data * self.rowHeight - viewport:GetHeight())
        local target = min(range, max(0, offset * self.rowHeight))
        if type(self.box) == "table" and self.box.SetScrollPercentage then
            local percentage = 0
            if range > 0 then percentage = target / range end
            self.box:SetScrollPercentage(percentage)
        elseif type(self.scroll) == "table" then
            self.scroll:SetVerticalScroll(target)
        end
    end

    function scroller:SetData(data)
        self.data = data or {}
        self:Refresh()
        self:ScrollToTop()
    end

    function scroller:Refresh()
        local viewport = self:GetViewport()
        local width = viewport and viewport:GetWidth() or 0
        if width > 0 then self.content:SetWidth(width) end
        for index, entry in ipairs(self.data) do
            local row = self.rows[index]
            if row == nil then
                row = self.initRow(self.content)
                row:SetHeight(self.rowHeight)
                self.rows[index] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(index - 1) * self.rowHeight)
            row:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -(index - 1) * self.rowHeight)
            row:Update(entry)
            row:Show()
        end

        for index = #self.data + 1, #self.rows do
            self.rows[index]:Hide()
        end

        self:UpdateScroll()
    end

    scroller:SetScript("OnSizeChanged", function(sel) sel:Refresh() end)

    return scroller
end

local function StyleRow(row)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(1, 1, 1, 0.12)
    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints(row)
    row.selected:SetColorTexture(0.9, 0.75, 0.3, 0.2)
    row.selected:Hide()
end

local function CreateTextRow(scroller, onClick)
    local row = CreateFrame("Button", nil, scroller)
    StyleRow(row)
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.text:SetJustifyH("LEFT")
    row.info = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.info:SetJustifyH("RIGHT")
    row.text:SetPoint("RIGHT", row.info, "LEFT", -4, 0)
    row:SetScript("OnClick", function(sel)
        if sel.entry ~= nil then onClick(sel.entry) end
    end)

    return row
end

local function UpdateInstanceRow(row, inst)
    row.entry = inst
    row.text:SetText(DungeonJournal:GetInstanceName(inst))
    if inst.minLevel and inst.maxLevel then
        row.info:SetText(inst.minLevel .. "-" .. inst.maxLevel)
    else
        row.info:SetText("")
    end

    if selectedInstance == inst then
        row.text:SetTextColor(1, 0.82, 0)
        row.selected:Show()
    else
        row.text:SetTextColor(0.9, 0.9, 0.9)
        row.selected:Hide()
    end
end

local function UpdateBossRow(row, boss)
    row.entry = boss
    row.text:SetText(DungeonJournal:GetBossName(boss))
    local count = #(boss.loot or {})
    if count > 0 then
        row.info:SetText(count)
    else
        row.info:SetText("")
    end

    if selectedBoss == boss then
        row.text:SetTextColor(1, 0.82, 0)
        row.selected:Show()
    else
        row.text:SetTextColor(0.9, 0.9, 0.9)
        row.selected:Hide()
    end
end

local function GetInstanceList()
    local list = {}
    for _, inst in ipairs(DungeonJournal:GetInstances(listKind)) do
        if InstanceMatches(inst) then tinsert(list, inst) end
    end

    return list
end

local function GetBossList()
    local list = {}
    if selectedInstance == nil then return list end
    for _, boss in ipairs(selectedInstance.bosses or {}) do
        if BossMatches(boss) then tinsert(list, boss) end
    end

    return list
end

local function GetLootList()
    local list = {}
    if selectedBoss == nil then return list end
    local onlyClass = DungeonJournal:GetConfig("CLASSFILTER", false)
    local class = select(2, UnitClass("player"))
    local bossMatched = Matches(DungeonJournal:GetBossName(selectedBoss)) or Matches(selectedBoss.name)
    for _, entry in ipairs(selectedBoss.loot or {}) do
        local itemID = entry[1]
        local ok = true
        if onlyClass and not DungeonJournal:IsUsableByClass(itemID, class) then ok = false end
        if ok and searchText ~= "" and not bossMatched and not Matches(DungeonJournal:GetItemDisplay(itemID)) then ok = false end
        if ok then tinsert(list, entry) end
    end

    return list
end

local function GetSpellList()
    local list = {}
    if selectedBoss == nil then return list end
    for _, spellID in ipairs(selectedBoss.spells or {}) do
        if DungeonJournal:GetSpellInfo(spellID) ~= nil then tinsert(list, spellID) end
    end

    return list
end

local function UpdateTabs(tabs, active)
    for kind, button in pairs(tabs) do
        if kind == active then
            button.text:SetTextColor(1, 0.82, 0)
            button.underline:Show()
        else
            button.text:SetTextColor(0.7, 0.7, 0.7)
            button.underline:Hide()
        end
    end
end

local function UpdateModel()
    local frame = journal.model
    if frame == nil then return false end
    local displayID = nil
    local npcID = nil
    if selectedBoss ~= nil then
        displayID = selectedBoss.model
        if selectedBoss.npcs then npcID = selectedBoss.npcs[1] end
    end

    if displayID == nil and npcID == nil then
        frame.shownID = nil
        frame.shownNPC = nil
        frame:Hide()

        return false
    end

    frame:Show()
    if frame.shownID == displayID and frame.shownNPC == npcID then return true end
    frame.shownID = displayID
    frame.shownNPC = npcID
    frame.rotation = MODEL_START_ROTATION
    frame.zoom = 1
    local applied = false
    if displayID ~= nil and frame.SetDisplayInfo then applied = pcall(frame.SetDisplayInfo, frame, displayID) end
    if not applied and npcID ~= nil and frame.SetCreature then applied = pcall(frame.SetCreature, frame, npcID) end
    if frame.SetCamDistanceScale then pcall(frame.SetCamDistanceScale, frame, frame.zoom) end
    if frame.SetRotation then pcall(frame.SetRotation, frame, frame.rotation) end
    if frame.RefreshCamera then pcall(frame.RefreshCamera, frame) end

    return applied
end

local function UpdateKindTabs()
    if journal == nil then return end
    for kind, tab in pairs(journal.kindTabs) do
        tab:SetChecked(kind == listKind)
    end
end

local function RefreshDetail()
    if journal == nil then return end
    local count = 0
    local empty = false
    local lootOnly = selectedInstance ~= nil and (selectedInstance.vendor == true or selectedBoss ~= nil and selectedBoss.trash == true)
    if lootOnly and detailKind ~= "loot" then detailKind = "loot" end
    for kind, button in pairs(journal.detailTabs) do
        if kind ~= "loot" and lootOnly then
            button:Hide()
        else
            button:Show()
        end
    end

    if detailKind == "loot" then
        journal.loot:SetData(GetLootList())
        journal.loot:Show()
        journal.spells:Hide()
        if journal.model then journal.model:Hide() end
        count = #journal.loot.data
        journal.detailCount:SetText(DungeonJournal:Trans("LID_ITEMCOUNT", nil, count))
        journal.classFilter:Show()
        journal.classFilterLabel:Show()
        empty = count == 0
    elseif detailKind == "spells" then
        journal.spells:SetData(GetSpellList())
        journal.spells:Show()
        journal.loot:Hide()
        if journal.model then journal.model:Hide() end
        count = #journal.spells.data
        journal.detailCount:SetText(DungeonJournal:Trans("LID_ABILITYCOUNT", nil, count))
        journal.classFilter:Hide()
        journal.classFilterLabel:Hide()
        empty = count == 0
    else
        journal.loot:Hide()
        journal.spells:Hide()
        journal.detailCount:SetText("")
        journal.classFilter:Hide()
        journal.classFilterLabel:Hide()
        empty = not UpdateModel()
    end

    if selectedBoss ~= nil then
        journal.detailTitle:SetText(DungeonJournal:GetBossName(selectedBoss))
    else
        journal.detailTitle:SetText("")
    end

    if empty then
        if detailKind == "model" then
            journal.empty:SetText(DungeonJournal:Trans("LID_NOMODEL"))
        elseif selectedInstance ~= nil and selectedInstance.forever then
            journal.empty:SetText(DungeonJournal:Trans("LID_NODATAYET"))
        else
            journal.empty:SetText(DungeonJournal:Trans("LID_NOENTRIES"))
        end

        journal.empty:Show()
    else
        journal.empty:Hide()
    end

    UpdateTabs(journal.detailTabs, detailKind)
end

local function RefreshBosses()
    if journal == nil then return end
    local list = GetBossList()
    journal.bosses:SetData(list)
    local found = false
    for _, boss in ipairs(list) do
        if boss == selectedBoss then found = true end
    end

    if not found then selectedBoss = list[1] end
    journal.bosses:Refresh()
    if selectedInstance ~= nil then
        journal.bossTitle:SetText(DungeonJournal:GetInstanceName(selectedInstance))
    else
        journal.bossTitle:SetText("")
    end

    RefreshDetail()
end

local function RefreshInstances()
    if journal == nil then return end
    local list = GetInstanceList()
    journal.instances:SetData(list)
    local found = false
    for _, inst in ipairs(list) do
        if inst == selectedInstance then found = true end
    end

    if not found then
        selectedInstance = list[1]
        selectedBoss = nil
    end

    journal.instances:Refresh()
    RefreshBosses()
end

local function OnInstanceClick(inst)
    selectedInstance = inst
    selectedBoss = nil
    journal.instances:Refresh()
    RefreshBosses()
end

local function OnBossClick(boss)
    selectedBoss = boss
    journal.bosses:Refresh()
    RefreshDetail()
end

local function ShowItemTooltip(row)
    if row.itemID == nil then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(row.itemID)
    elseif row.link then
        GameTooltip:SetHyperlink(row.link)
    else
        GameTooltip:SetHyperlink("item:" .. row.itemID)
    end

    if row.boss ~= nil then
        GameTooltip:AddLine(format(DungeonJournal:Trans("LID_DROPPEDBY"), DungeonJournal:GetBossName(row.boss)), 1, 0.82, 0)
    end

    GameTooltip:Show()
end

local function CreateLootRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.chance = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.chance:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.chance:SetJustifyH("RIGHT")
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetPoint("RIGHT", row.chance, "LEFT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.slot = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.slot:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 1)
    row.slot:SetPoint("RIGHT", row.chance, "LEFT", -6, 0)
    row.slot:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(sel) ShowItemTooltip(sel) end)
    row:SetScript("OnLeave", function() DungeonJournal:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel)
        if sel.link == nil then return end
        if HandleModifiedItemClick then HandleModifiedItemClick(sel.link) end
    end)

    function row:Update(entry)
        local itemID = entry[1]
        local chance = entry[2]
        self.itemID = itemID
        self.boss = selectedInstance and not selectedInstance.vendor and selectedBoss or nil
        local name, link, quality, _, icon = DungeonJournal:GetItemDisplay(itemID)
        self.link = link
        self.icon:SetTexture(icon or 134400)
        self.name:SetText(name or DungeonJournal:Trans("LID_LOADING"))
        local color = nil
        if quality ~= nil and ITEM_QUALITY_COLORS ~= nil then color = ITEM_QUALITY_COLORS[quality] end
        if color ~= nil then
            self.name:SetTextColor(color.r, color.g, color.b)
        else
            self.name:SetTextColor(0.6, 0.6, 0.6)
        end

        self.slot:SetText(DungeonJournal:GetItemSlotText(itemID))
        if chance ~= nil and DungeonJournal:GetConfig("SHOWCHANCE", true) then
            self.chance:SetText(format("%.1f%%", chance))
            if chance >= 50 then
                self.chance:SetTextColor(0.4, 0.9, 0.4)
            elseif chance >= 10 then
                self.chance:SetTextColor(0.95, 0.85, 0.4)
            else
                self.chance:SetTextColor(0.9, 0.55, 0.45)
            end
        elseif DungeonJournal:IsForeverItem(itemID) then
            self.chance:SetText(DungeonJournal:Trans("LID_NEWITEM"))
            self.chance:SetTextColor(0.4, 0.8, 1)
        else
            self.chance:SetText("")
        end
    end

    return row
end

local function CreateSpellRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.name:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(sel)
        if sel.spellID == nil then return end
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(sel.spellID)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function() DungeonJournal:HideGameTooltip() end)
    function row:Update(entry)
        self.spellID = entry
        local name, _, icon = DungeonJournal:GetSpellInfo(entry)
        self.icon:SetTexture(icon or 134400)
        self.name:SetText(name or entry)
        self.name:SetTextColor(0.9, 0.9, 0.9)
    end

    return row
end

local function CreateTabButton(parent, label, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(100, 22)
    button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 1)
    button.text:SetText(label)
    button.underline = button:CreateTexture(nil, "ARTWORK")
    button.underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6, 2)
    button.underline:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 2)
    button.underline:SetHeight(2)
    button.underline:SetColorTexture(1, 0.82, 0, 0.9)
    button.underline:Hide()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.1)
    button:SetScript("OnClick", onClick)

    return button
end

local function CreateTemplated(kind, name, parent, templates)
    for _, template in ipairs(templates) do
        local ok, frame = pcall(CreateFrame, kind, name, parent, template)
        if ok and frame ~= nil then return frame, template end
    end

    return CreateFrame(kind, name, parent), nil
end

local function SetFrameTitle(frame, text)
    if type(frame.SetTitle) == "function" then
        local ok = pcall(frame.SetTitle, frame, text)
        if ok then return end
    end

    if type(frame.TitleContainer) == "table" and frame.TitleContainer.TitleText ~= nil then
        frame.TitleContainer.TitleText:SetText(text)

        return
    end

    if frame.TitleText ~= nil then
        frame.TitleText:SetText(text)

        return
    end

    local name = frame:GetName()
    if name ~= nil and _G[name .. "TitleText"] ~= nil then
        _G[name .. "TitleText"]:SetText(text)

        return
    end

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -6)
    title:SetText(text)
end

local function SetFramePortrait(frame, icon)
    local portrait = nil
    if type(frame.PortraitContainer) == "table" then portrait = frame.PortraitContainer.portrait end
    if type(portrait) ~= "table" and type(frame.portrait) == "table" then portrait = frame.portrait end
    if type(portrait) ~= "table" then return end
    if type(portrait.SetTexture) ~= "function" then return end
    pcall(portrait.SetTexture, portrait, icon)
end

local function AddFallbackChrome(frame)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0.05, 0.05, 0.06, 0.94)
    local close = CreateTemplated("Button", "DungeonJournalCloseButton", frame, {"UIPanelCloseButton"})
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    close:SetSize(28, 28)
    close:SetScript("OnClick", function() frame:Hide() end)
    if close.SetText and close.GetFontString and close:GetFontString() ~= nil then close:SetText("X") end
end

local function CreateSideTab(parent, label, icon, onClick)
    local ok, tab = pcall(CreateFrame, "Frame", nil, parent, "LargeSideTabButtonTemplate")
    local large = ok and tab ~= nil
    if not large then
        tab = CreateTemplated("CheckButton", nil, parent, {"RightSideTabTemplate", "SpellBookSkillLineTabTemplate"})
        tab:SetSize(32, 32)
    end

    if type(tab.Icon) ~= "table" then
        local background = tab:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(tab)
        background:SetColorTexture(0.05, 0.05, 0.06, 0.9)
        local texture = tab:CreateTexture(nil, "ARTWORK")
        texture:SetSize(30, 30)
        texture:SetPoint("CENTER", tab, "CENTER", 0, 0)
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tab.Icon = texture
        tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        tab:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
    end

    tab.Icon:SetTexture(icon)
    if large and type(tab.SetFillToInterior) == "function" then tab:SetFillToInterior(true) end
    tab.tooltip = label
    tab.tooltipText = label
    tab:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(sel.tooltip)
        GameTooltip:Show()
    end)

    tab:SetScript("OnLeave", function() DungeonJournal:HideGameTooltip() end)
    if large then
        tab:EnableMouse(true)
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
            if button == "LeftButton" and upInside then onClick() end
        end)
    else
        tab:HookScript("OnClick", onClick)
    end

    return tab
end

local function CreateModelFrame(parent)
    local frame = nil
    for _, kind in ipairs({"PlayerModel", "DressUpModel", "CinematicModel", "Model"}) do
        local ok, created = pcall(CreateFrame, kind, "DungeonJournalModel", parent)
        if ok and created ~= nil then
            frame = created
            break
        end
    end

    if frame == nil then return nil end
    frame.rotation = MODEL_START_ROTATION
    frame.zoom = 1
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseDown", function(sel, button)
        if button ~= "LeftButton" then return end
        sel.dragging = true
        sel.cursorX = GetCursorPosition()
    end)

    frame:SetScript("OnMouseUp", function(sel) sel.dragging = false end)
    frame:SetScript("OnHide", function(sel) sel.dragging = false end)
    frame:SetScript("OnUpdate", function(sel)
        if not sel.dragging then return end
        local x = GetCursorPosition()
        local last = sel.cursorX or x
        sel.cursorX = x
        sel.rotation = (sel.rotation or 0) + (x - last) / 60
        if sel.SetRotation then pcall(sel.SetRotation, sel, sel.rotation) end
    end)

    frame:SetScript("OnMouseWheel", function(sel, delta)
        sel.zoom = min(MODEL_ZOOM_MAX, max(MODEL_ZOOM_MIN, (sel.zoom or 1) - delta * 0.15))
        if sel.SetCamDistanceScale then pcall(sel.SetCamDistanceScale, sel, sel.zoom) end
    end)

    return frame
end

local function CreateJournal()
    if journal ~= nil then return journal end
    local template = nil
    journal, template = CreateTemplated(
        "Frame",
        "DungeonJournalFrame",
        UIParent,
        {"ButtonFrameTemplate", "PortraitFrameTemplate", "BasicFrameTemplateWithInset"}
    )

    if template == nil then AddFallbackChrome(journal) end
    if type(journal.Inset) == "table" and type(journal.Inset.Bg) == "table" then journal.Inset.Bg:SetAlpha(0.6) end
    SetFramePortrait(journal, DungeonJournal:GetIcon())
    journal:SetSize(WIDTH, HEIGHT)
    journal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    journal:SetFrameStrata("HIGH")
    journal:SetMovable(true)
    journal:EnableMouse(true)
    journal:RegisterForDrag("LeftButton")
    journal:SetScript("OnDragStart", function(sel) sel:StartMoving() end)
    journal:SetScript("OnDragStop", function(sel) sel:StopMovingOrSizing() end)
    DungeonJournal:SetClampedToScreen(journal, true, "DungeonJournal")
    journal:Hide()
    SetFrameTitle(journal, DungeonJournal:Trans("LID_TITLE"))
    if type(UISpecialFrames) == "table" then tinsert(UISpecialFrames, "DungeonJournalFrame") end
    local search = CreateTemplated("EditBox", "DungeonJournalSearchBox", journal, {"InputBoxTemplate", "SearchBoxTemplate"})
    search:SetSize(180, 20)
    search:SetPoint("TOPRIGHT", journal, "TOPRIGHT", -30, -32)
    search:SetFontObject("ChatFontNormal")
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(sel)
        searchText = Lower(strtrim(sel:GetText() or ""))
        RefreshInstances()
    end)

    search:SetScript("OnEscapePressed", function(sel)
        sel:SetText("")
        sel:ClearFocus()
    end)

    journal.search = search
    local searchLabel = journal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    searchLabel:SetPoint("RIGHT", search, "LEFT", -6, 0)
    searchLabel:SetText(DungeonJournal:Trans("LID_SEARCH"))
    journal.kindTabs = {}
    local pvpIcon = "Interface\\Icons\\INV_BannerPVP_01"
    if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then pvpIcon = "Interface\\Icons\\INV_BannerPVP_02" end
    local previousTab = nil
    for _, info in ipairs({
        {"dungeon", "LID_DUNGEONS", "Interface\\Icons\\INV_Misc_Map_01"},
        {"raid", "LID_RAIDS", "Interface\\Icons\\INV_Misc_Head_Dragon_01"},
        {"pvp", "LID_PVP", pvpIcon},
        {"faction", "LID_REPUTATION", "Interface\\Icons\\INV_Shirt_GuildTabard_01"},
    }) do
        local kind = info[1]
        local tab = CreateSideTab(journal, DungeonJournal:Trans(info[2]), info[3], function()
            if listKind == kind then
                UpdateKindTabs()

                return
            end

            listKind = kind
            selectedInstance = nil
            selectedBoss = nil
            UpdateKindTabs()
            RefreshInstances()
        end)

        if previousTab == nil then
            tab:SetPoint("TOPLEFT", journal, "TOPRIGHT", -2, -SIDE_TAB_TOP)
        else
            tab:SetPoint("TOPLEFT", previousTab, "BOTTOMLEFT", 0, -SIDE_TAB_GAP)
        end

        journal.kindTabs[kind] = tab
        previousTab = tab
    end

    local instances = CreateScroller(journal, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, OnInstanceClick)
        function row:Update(entry)
            UpdateInstanceRow(self, entry)
        end

        return row
    end)

    instances:SetPoint("TOPLEFT", journal, "TOPLEFT", 14, -90)
    instances:SetPoint("BOTTOMLEFT", journal, "BOTTOMLEFT", 12, 28)
    instances:SetWidth(COL_W)
    journal.instances = instances
    local bossTitle = journal:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    bossTitle:SetPoint("BOTTOMLEFT", instances, "TOPLEFT", COL_W + 12, 6)
    bossTitle:SetWidth(COL_W)
    bossTitle:SetWordWrap(false)
    bossTitle:SetJustifyH("LEFT")
    journal.bossTitle = bossTitle
    local bosses = CreateScroller(journal, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, OnBossClick)
        function row:Update(entry)
            UpdateBossRow(self, entry)
        end

        return row
    end)

    bosses:SetPoint("TOPLEFT", instances, "TOPRIGHT", 12, 0)
    bosses:SetPoint("BOTTOMLEFT", instances, "BOTTOMRIGHT", 12, 0)
    bosses:SetWidth(COL_W)
    journal.bosses = bosses
    local loot = CreateScroller(journal, LOOT_ROW_H, CreateLootRow)
    loot:SetPoint("TOPLEFT", bosses, "TOPRIGHT", 14, 0)
    loot:SetPoint("BOTTOMRIGHT", journal, "BOTTOMRIGHT", -14, 28)
    journal.loot = loot
    local spells = CreateScroller(journal, LOOT_ROW_H, CreateSpellRow)
    spells:SetAllPoints(loot)
    spells:Hide()
    journal.spells = spells
    journal.detailTabs = {}
    local spellTab = CreateTabButton(journal, DungeonJournal:Trans("LID_ABILITIES"), function()
        detailKind = "spells"
        RefreshDetail()
    end)

    spellTab:SetWidth(78)
    local lootTab = CreateTabButton(journal, DungeonJournal:Trans("LID_LOOT"), function()
        detailKind = "loot"
        RefreshDetail()
    end)

    lootTab:SetWidth(78)
    journal.detailTabs["loot"] = lootTab
    journal.detailTabs["spells"] = spellTab
    local model = CreateModelFrame(journal)
    if model ~= nil then
        model:SetPoint("TOPLEFT", loot, "TOPLEFT", 0, 0)
        model:SetPoint("BOTTOMRIGHT", loot, "BOTTOMRIGHT", 0, 0)
        model:Hide()
        journal.model = model
        local modelTab = CreateTabButton(journal, DungeonJournal:Trans("LID_MODEL"), function()
            detailKind = "model"
            RefreshDetail()
        end)

        modelTab:SetWidth(78)
        modelTab:SetPoint("TOPRIGHT", journal, "TOPRIGHT", -14, -62)
        journal.detailTabs["model"] = modelTab
        spellTab:SetPoint("TOPRIGHT", modelTab, "TOPLEFT", -2, 0)
    else
        spellTab:SetPoint("TOPRIGHT", journal, "TOPRIGHT", -14, -62)
    end

    lootTab:SetPoint("TOPRIGHT", spellTab, "TOPLEFT", -2, 0)
    local detailCount = journal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detailCount:SetPoint("BOTTOMRIGHT", lootTab, "BOTTOMLEFT", -8, 6)
    detailCount:SetJustifyH("RIGHT")
    journal.detailCount = detailCount
    local detailTitle = journal:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    detailTitle:SetPoint("BOTTOMLEFT", loot, "TOPLEFT", 0, 6)
    detailTitle:SetWidth(200)
    detailTitle:SetWordWrap(false)
    detailTitle:SetJustifyH("LEFT")
    journal.detailTitle = detailTitle
    local classFilter = CreateTemplated("CheckButton", "DungeonJournalClassFilter", journal, {"UICheckButtonTemplate", "ChatConfigCheckButtonTemplate"})
    classFilter:SetSize(24, 24)
    classFilter:SetPoint("BOTTOMRIGHT", journal, "BOTTOMRIGHT", -14, 2)
    classFilter:SetChecked(DungeonJournal:GetConfig("CLASSFILTER", false) == true)
    local classFilterLabel = journal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    classFilterLabel:SetPoint("RIGHT", classFilter, "LEFT", 0, 0)
    classFilterLabel:SetText(DungeonJournal:Trans("LID_CLASSFILTER"))
    classFilter:SetScript("OnClick", function(sel)
        DungeonJournal:SetConfig("CLASSFILTER", sel:GetChecked() == true)
        RefreshDetail()
    end)

    journal.classFilter = classFilter
    journal.classFilterLabel = classFilterLabel
    local empty = journal:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    empty:SetPoint("CENTER", loot, "CENTER", 0, 0)
    empty:SetText(DungeonJournal:Trans("LID_NOENTRIES"))
    empty:Hide()
    journal.empty = empty

    return journal
end

function DungeonJournal:RefreshJournal()
    if journal == nil or not journal:IsShown() then return end
    RefreshInstances()
end

function DungeonJournal:ToggleJournal()
    CreateJournal()
    if journal:IsShown() then
        journal:Hide()

        return
    end

    journal:Show()
    UpdateKindTabs()
    RefreshInstances()
end

function DungeonJournal:OpenJournal()
    CreateJournal()
    if journal:IsShown() then return end
    journal:Show()
    UpdateKindTabs()
    RefreshInstances()
end

local loader = CreateFrame("Frame")
DungeonJournal:RegisterEvent(loader, "PLAYER_LOGIN")
DungeonJournal:RegisterEvent(loader, "GET_ITEM_INFO_RECEIVED")
loader:SetScript("OnEvent", function(sel, event)
    if event == "PLAYER_LOGIN" then
        DungeonJournal:PreloadItems()

        return
    end

    if journal == nil or not journal:IsShown() then return end
    if refreshPending then return end
    refreshPending = true
    DungeonJournal:After(
        0.25,
        function()
            refreshPending = false
            if journal ~= nil and journal:IsShown() then
                journal.instances:Refresh()
                journal.bosses:Refresh()
                journal.loot:Refresh()
            end
        end,
        "DungeonJournal:ItemInfo"
    )
end)
