local _, AzerothCompendium = ...
local WIDTH = 860
local HEIGHT = 580
local MIN_WIDTH = 700
local MIN_HEIGHT = 400
local ROW_H = 22
local INSTANCE_ROW_H = ROW_H * 3
local BOSS_ROW_H = 54
local MEDIA_PATH = "Interface\\AddOns\\AzerothCompendium\\media\\"
local BOSS_PORTRAIT_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
local TRASH_PORTRAIT = 133639
local ALL_PORTRAIT = 132594
local PORTRAIT_ICON_ZOOM = 0.05
local LOOT_ROW_H = 34
local INSTANCE_TYPE_ICON_SIZE = 16
local INSTANCE_TYPE_ATLAS_SIZE = 24
local INSTANCE_TYPE_ATLAS_INSET = 4
local INSTANCE_TYPE_ICON_OFFSET = 3
local INSTANCE_NAME_FONT_SIZE = 11
local INSTANCE_TYPE_TAGS = {
    ["dungeon"] = 81,
    ["raid"] = 62
}

local QUEST_COUNT_ICON = "Interface\\GossipFrame\\ActiveQuestIcon"
local BOSS_PORTRAIT_SIZE = 34
local BOSS_PORTRAIT_X = 9
local BOSS_PORTRAIT_Y = 3
local BOSS_TEXT_GAP = 27
local DRAGON_SCALE = BOSS_PORTRAIT_SIZE / 64
local LEVEL_BADGE_SIZE = 16
local LEVEL_BADGE_FONT_SIZE = 9
local LEVEL_SKULL_MIN = 63
local BOSS_UNKNOWN_LEVEL = 1000
local DEFAULT_BOSS_RANK = 1
local LEVEL_BADGE_STYLE = {
    [0] = {
        ring = {0.55, 0.5, 0.4}
    },
    [1] = {
        ring = {0.95, 0.75, 0.25},
        dragon = "BossDragon-Elite"
    },
    [2] = {
        ring = {0.85, 0.87, 0.95},
        dragon = "BossDragon-Rare-Elite"
    },
    [3] = {
        ring = {0.95, 0.75, 0.25},
        dragon = "BossDragon-Elite"
    },
    [4] = {
        ring = {0.85, 0.87, 0.95},
        dragon = "BossDragon-Rare"
    }
}
local LOADSCREEN_CLASSIC = {
    aspect = 4 / 3,
    uSpan = 0.96,
    vSpanMax = 0.56,
    vCenter = 0.49
}

local LOADSCREEN_WIDE = {
    aspect = 2992 / 1684,
    uSpan = 1,
    vSpanMax = 0.66,
    vCenter = 0.5
}
local INSTANCE_COL_W = 200
local MIDDLE_COL_W = 240
local SCROLLBAR_W = 18
local SIDE_TAB_TOP = 62
local SIDE_TAB_GAP = 3
local MODEL_START_ROTATION = 0.4
local MODEL_ZOOM_MIN = 0.4
local MODEL_ZOOM_MAX = 4
local SCALE_MIN = 0.5
local SCALE_MAX = 1.5
local SCALE_STEP = 0.05
local compendium = nil
local selectedInstance = nil
local selectedBoss = nil
local listKind = "dungeon"
local middleKind = "map"
local detailKind = "loot"
local mapLevel = 1
local mapInstance = nil
local mapLevelMenu = nil
local searchText = ""
local refreshPending = false
local FLAVOR_FOREVER = "forever"
local FLAVOR_CLASSIC_ERA = "classic_era"

local function Lower(text)
    if text == nil then return "" end

    return strlower(text)
end

local function Matches(text)
    if searchText == "" then return true end
    if text == nil then return false end

    return strfind(Lower(text), searchText, 1, true) ~= nil
end

local function IsClassicEra()
    return AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA
end

local function IsItemVisible(itemID)
    return not IsClassicEra() or not AzerothCompendium:IsForeverItem(itemID)
end

local function VisibleLootCount(boss)
    local count = 0
    for _, entry in ipairs(boss.loot or {}) do
        if IsItemVisible(entry[1]) then count = count + 1 end
    end

    return count
end

local allEntries = {}
local function GetAllEntry(inst)
    if allEntries[inst] == nil then allEntries[inst] = {all = true} end

    return allEntries[inst]
end

local function GetAllLoot(inst)
    local list = {}
    local seen = {}
    if inst == nil then return list end
    for _, boss in ipairs(inst.bosses or {}) do
        for _, entry in ipairs(boss.loot or {}) do
            local itemID = entry[1]
            if not seen[itemID] and IsItemVisible(itemID) then
                seen[itemID] = true
                tinsert(list, {itemID, entry[2], source = boss})
            end
        end
    end

    return list
end

local function IsInstanceVisible(inst)
    if not IsClassicEra() then return true end
    if inst.forever then return false end
    if not inst.vendor then return true end
    for _, boss in ipairs(inst.bosses or {}) do
        if VisibleLootCount(boss) > 0 then return true end
    end

    return false
end

local function BossMatches(boss)
    if searchText == "" then return true end
    if Matches(AzerothCompendium:GetBossName(boss)) then return true end
    if Matches(boss.name) then return true end
    for _, entry in ipairs(boss.loot or {}) do
        if IsItemVisible(entry[1]) and Matches(AzerothCompendium:GetItemDisplay(entry[1])) then return true end
    end

    return false
end

local function QuestMatches(quest)
    if searchText == "" then return true end

    return Matches(AzerothCompendium:GetQuestName(quest))
end

local function InstanceMatches(inst)
    if searchText == "" then return true end
    if Matches(AzerothCompendium:GetInstanceName(inst)) then return true end
    if Matches(inst.name) then return true end
    for _, boss in ipairs(inst.bosses or {}) do
        if BossMatches(boss) then return true end
    end
    for _, quest in ipairs(AzerothCompendium:GetInstanceQuests(inst)) do
        if QuestMatches(quest) then return true end
    end

    return false
end

local function HasModernScroll()
    if ScrollUtil == nil then return false end
    if ScrollUtil.InitScrollBoxWithScrollBar == nil then return false end
    if CreateScrollBoxLinearView == nil then return false end

    return AzerothCompendium:CheckTemplates("WowScrollBox, MinimalScrollBar")
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
        scroller.view = view
    else
        local scroll = nil
        if AzerothCompendium:CheckTemplates("UIPanelScrollFrameTemplate") then
            scroll = CreateFrame("ScrollFrame", nil, scroller, "UIPanelScrollFrameTemplate")
        else
            scroll = CreateFrame("ScrollFrame", nil, scroller)
        end

        scroll:SetPoint("TOPLEFT", scroller, "TOPLEFT", 0, 0)
        scroll:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -SCROLLBAR_W, 0)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(sel, delta)
            local range = max(0, (sel.djHeight or 0) - sel:GetHeight())
            sel:SetVerticalScroll(min(range, max(0, sel:GetVerticalScroll() - delta * scroller.rowHeight * 3)))
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

    function scroller:SetRowHeight(height)
        self.rowHeight = height
        if type(self.view) == "table" and self.view.SetPanExtent then self.view:SetPanExtent(height) end
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
                self.rows[index] = row
            end

            row:SetHeight(self.rowHeight)
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

local function UsesLoadingScreens()
    return listKind == "dungeon" or listKind == "raid"
end

local function UpdateLoadingScreenCrop(row)
    local width, height = row:GetWidth(), row:GetHeight()
    if width <= 0 or height <= 0 then return end
    local layout = row.loadingLayout or LOADSCREEN_CLASSIC
    local uSpan = layout.uSpan
    local vSpan = uSpan * layout.aspect * height / width
    if vSpan > layout.vSpanMax then
        vSpan = layout.vSpanMax
        uSpan = vSpan * width / (height * layout.aspect)
    end

    row.loadingScreen:SetTexCoord(0.5 - uSpan / 2, 0.5 + uSpan / 2, layout.vCenter - vSpan / 2, layout.vCenter + vSpan / 2)
end

local function GetLoadingScreen(inst)
    if AzerothCompendium.LOADINGSCREENS_WIDE and AzerothCompendium.LOADINGSCREENS_WIDE[inst.id] then return AzerothCompendium.LOADINGSCREENS_WIDE[inst.id], LOADSCREEN_WIDE end
    if AzerothCompendium.LOADINGSCREENS and AzerothCompendium.LOADINGSCREENS[inst.id] then return AzerothCompendium.LOADINGSCREENS[inst.id], LOADSCREEN_CLASSIC end

    return nil, nil
end

local function AddLoadingScreen(row)
    row.loadingScreen = row:CreateTexture(nil, "BACKGROUND", nil, -8)
    row.loadingScreen:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.loadingScreen:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
    row.loadingScreen:Hide()
    row.loadingShade = row:CreateTexture(nil, "BACKGROUND", nil, -7)
    row.loadingShade:SetAllPoints(row.loadingScreen)
    row.loadingShade:SetColorTexture(0, 0, 0, 0.35)
    row.loadingShade:Hide()
    row:HookScript("OnSizeChanged", UpdateLoadingScreenCrop)
end

local ENTRANCE_PIN_SIZE = 18
local ENTRANCE_PIN_ATLAS = "Waypoint-MapPin-Untracked"
local ENTRANCE_PIN_HIGHLIGHT_ATLAS = "Waypoint-MapPin-Highlight"
local ENTRANCE_PIN_FALLBACK = 134269

local function HasAtlas(atlas)
    return C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil and C_Texture.GetAtlasInfo(atlas) ~= nil
end

local function CreateEntrancePin(row)
    local pin = CreateFrame("Button", nil, row)
    pin:SetSize(ENTRANCE_PIN_SIZE, ENTRANCE_PIN_SIZE)
    pin:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
    pin:SetFrameLevel(row:GetFrameLevel() + 2)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints(pin)
    local highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(pin)
    if HasAtlas(ENTRANCE_PIN_ATLAS) then
        pin.icon:SetAtlas(ENTRANCE_PIN_ATLAS)
        if HasAtlas(ENTRANCE_PIN_HIGHLIGHT_ATLAS) then
            highlight:SetAtlas(ENTRANCE_PIN_HIGHLIGHT_ATLAS)
        else
            highlight:SetAtlas(ENTRANCE_PIN_ATLAS)
            highlight:SetBlendMode("ADD")
        end
    else
        pin.icon:SetTexture(ENTRANCE_PIN_FALLBACK)
        pin.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        highlight:SetTexture(ENTRANCE_PIN_FALLBACK)
        highlight:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        highlight:SetBlendMode("ADD")
    end

    pin:SetScript("OnClick", function(sel)
        local waypointSet, reason = AzerothCompendium:SetInstanceEntranceWaypoint(sel:GetParent().entry)
        if not waypointSet and reason == "combat" then AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT")) end
    end)

    pin:SetScript("OnEnter", function(sel)
        AzerothCompendium:AttachMapOpener(sel, function(owner)
            return AzerothCompendium:SetInstanceEntranceWaypoint(owner:GetParent().entry)
        end)
        local inst = sel:GetParent().entry
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_SETENTRANCEWAYPOINT")))
        local zone = AzerothCompendium:GetInstanceEntranceZoneName(inst)
        if zone then GameTooltip:AddLine(zone, 1, 1, 1) end
        GameTooltip:Show()
    end)

    pin:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    pin:Hide()

    return pin
end

local function UpdateInstanceBackground(row, inst)
    if row.loadingScreen == nil then return end
    local fileID, layout = nil, nil
    if UsesLoadingScreens() then fileID, layout = GetLoadingScreen(inst) end
    if fileID ~= nil then
        row.loadingLayout = layout
        row.loadingScreen:SetTexture(fileID)
        UpdateLoadingScreenCrop(row)
        row.loadingScreen:Show()
    else
        row.loadingScreen:Hide()
    end

    row.text:ClearAllPoints()
    row.info:ClearAllPoints()
    if row.subText == nil then
        row.subText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.subText:SetJustifyH("LEFT")
        row.subText:SetWordWrap(false)
    end

    if row.typeIcon == nil then
        row.typeIcon = row:CreateTexture(nil, "ARTWORK")
        row.questCount = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.questCount:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 6)
        row.questCount:SetJustifyH("RIGHT")
        row.entrancePin = CreateEntrancePin(row)
    end

    row.subText:Hide()
    row.typeIcon:Hide()
    row.questCount:Hide()
    row.entrancePin:Hide()
    if UsesLoadingScreens() then
        row.loadingShade:Show()
        row.text:SetFontObject("GameFontNormal")
        local fontFile, _, fontFlags = row.text:GetFont()
        if fontFile then row.text:SetFont(fontFile, INSTANCE_NAME_FONT_SIZE, fontFlags) end
        local textX = 6
        local typeIcon = AzerothCompendium:GetQuestTagIcon(INSTANCE_TYPE_TAGS[inst.type or listKind])
        if typeIcon then
            row.typeIcon:ClearAllPoints()
            if typeIcon[2] and not typeIcon[3] then
                row.typeIcon:SetTexCoord(0, 1, 0, 1)
                row.typeIcon:SetAtlas(typeIcon[1])
                row.typeIcon:SetSize(INSTANCE_TYPE_ATLAS_SIZE, INSTANCE_TYPE_ATLAS_SIZE)
                row.typeIcon:SetPoint("TOPLEFT", row, "TOPLEFT", INSTANCE_TYPE_ICON_OFFSET - INSTANCE_TYPE_ATLAS_INSET, INSTANCE_TYPE_ATLAS_INSET - INSTANCE_TYPE_ICON_OFFSET)
            elseif typeIcon[2] then
                row.typeIcon:SetTexCoord(0, 1, 0, 1)
                row.typeIcon:SetAtlas(typeIcon[1])
                row.typeIcon:SetSize(INSTANCE_TYPE_ICON_SIZE, INSTANCE_TYPE_ICON_SIZE)
                row.typeIcon:SetPoint("TOPLEFT", row, "TOPLEFT", INSTANCE_TYPE_ICON_OFFSET, -INSTANCE_TYPE_ICON_OFFSET)
            else
                row.typeIcon:SetTexture(typeIcon[1])
                row.typeIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                row.typeIcon:SetSize(INSTANCE_TYPE_ICON_SIZE, INSTANCE_TYPE_ICON_SIZE)
                row.typeIcon:SetPoint("TOPLEFT", row, "TOPLEFT", INSTANCE_TYPE_ICON_OFFSET, -INSTANCE_TYPE_ICON_OFFSET)
            end

            textX = INSTANCE_TYPE_ICON_OFFSET + INSTANCE_TYPE_ICON_SIZE + 3
            row.typeIcon:Show()
        end

        local textY = -INSTANCE_TYPE_ICON_OFFSET - floor((INSTANCE_TYPE_ICON_SIZE - INSTANCE_NAME_FONT_SIZE) / 2)
        local textRight = -6
        if AzerothCompendium:GetInstanceEntrance(inst) then
            row.entrancePin:Show()
            textRight = -ENTRANCE_PIN_SIZE - 8
        end

        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", textX, textY)
        row.text:SetPoint("TOPRIGHT", row, "TOPRIGHT", textRight, textY)
        row.subText:ClearAllPoints()
        row.subText:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
        row.subText:SetPoint("TOPRIGHT", row.text, "BOTTOMRIGHT", 0, -2)
        row.info:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 6)
        row.info:SetJustifyH("LEFT")
        row.info:SetTextColor(1, 1, 1)
    else
        row.loadingShade:Hide()
        row.text:SetFontObject("GameFontNormalSmall")
        row.info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.info:SetJustifyH("RIGHT")
        row.info:SetTextColor(0.5, 0.5, 0.5)
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row.info, "LEFT", -4, 0)
    end
end

local function UpdateInstanceRow(row, inst)
    row.entry = inst
    UpdateInstanceBackground(row, inst)
    local wing = AzerothCompendium:GetInstanceWingName(inst)
    if wing and row.subText and UsesLoadingScreens() then
        row.text:SetText(wing)
        row.subText:SetText(AzerothCompendium:GetInstanceBaseName(inst))
        row.subText:Show()
    else
        row.text:SetText(AzerothCompendium:GetInstanceName(inst))
    end
    if inst.minLevel and inst.maxLevel and inst.minLevel == inst.maxLevel then
        row.info:SetText(inst.minLevel)
    elseif inst.minLevel and inst.maxLevel then
        row.info:SetText(inst.minLevel .. "-" .. inst.maxLevel)
    else
        row.info:SetText("")
    end

    if UsesLoadingScreens() then
        local quests = AzerothCompendium:GetInstanceQuests(inst)
        local done = 0
        for _, quest in ipairs(quests) do
            if AzerothCompendium:IsQuestCompleted(quest[1]) then done = done + 1 end
        end

        if #quests == 0 then
            row.questCount:SetTextColor(0.6, 0.6, 0.6)
        elseif done == #quests then
            row.questCount:SetTextColor(0.25, 1, 0.25)
        else
            row.questCount:SetTextColor(1, 1, 1)
        end

        row.questCount:SetText(format("|T%s:14:14|t %d/%d", QUEST_COUNT_ICON, done, #quests))
        row.questCount:Show()
    end

    if selectedInstance == inst then
        row.text:SetTextColor(1, 0.82, 0)
        row.selected:Show()
    else
        row.text:SetTextColor(0.9, 0.9, 0.9)
        row.selected:Hide()
    end
end

local function UsesBossPortraits()
    return selectedInstance ~= nil and selectedInstance.vendor ~= true
end

local function AddBossPortrait(row)
    local size = BOSS_PORTRAIT_SIZE
    row.portraitFrame = CreateFrame("Frame", nil, row)
    row.portraitFrame:SetSize(size, size)
    row.portraitFrame:SetPoint("LEFT", row, "LEFT", BOSS_PORTRAIT_X, BOSS_PORTRAIT_Y)
    row.portrait = row.portraitFrame:CreateTexture(nil, "ARTWORK")
    row.portrait:SetSize(size, size)
    row.portrait:SetPoint("CENTER", row.portraitFrame, "CENTER", 0, 0)
    if row.portraitFrame.CreateMaskTexture and row.portrait.AddMaskTexture then
        local mask = row.portraitFrame:CreateMaskTexture()
        mask:SetAllPoints(row.portraitFrame)
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        row.portrait:AddMaskTexture(mask)
        row.portraitZoomable = true
    elseif row.portrait.SetMask then
        row.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end

    row.bossDragon = row.portraitFrame:CreateTexture(nil, "OVERLAY")
    row.bossDragon:SetSize(256 * DRAGON_SCALE, 128 * DRAGON_SCALE)
    row.bossDragon:SetPoint("CENTER", row.portraitFrame, "CENTER", -54 * DRAGON_SCALE, -20 * DRAGON_SCALE)
    row.bossDragon:Hide()
    row.levelBadge = CreateFrame("Frame", nil, row.portraitFrame)
    row.levelBadge:SetSize(LEVEL_BADGE_SIZE, LEVEL_BADGE_SIZE)
    row.levelBadge:SetPoint("CENTER", row.portraitFrame, "CENTER", 19.5 * DRAGON_SCALE, -22 * DRAGON_SCALE)
    row.levelBadge:SetFrameLevel(row.portraitFrame:GetFrameLevel() + 2)
    row.levelRing = row.levelBadge:CreateTexture(nil, "BORDER")
    row.levelRing:SetAllPoints(row.levelBadge)
    row.levelFill = row.levelBadge:CreateTexture(nil, "ARTWORK")
    row.levelFill:SetPoint("TOPLEFT", row.levelBadge, "TOPLEFT", 1.5, -1.5)
    row.levelFill:SetPoint("BOTTOMRIGHT", row.levelBadge, "BOTTOMRIGHT", -1.5, 1.5)
    row.levelFill:SetColorTexture(0.05, 0.04, 0.03, 0.95)
    if row.levelBadge.CreateMaskTexture and row.levelRing.AddMaskTexture then
        local ringMask = row.levelBadge:CreateMaskTexture()
        ringMask:SetAllPoints(row.levelRing)
        ringMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        row.levelRing:AddMaskTexture(ringMask)
        local fillMask = row.levelBadge:CreateMaskTexture()
        fillMask:SetAllPoints(row.levelFill)
        fillMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        row.levelFill:AddMaskTexture(fillMask)
    end

    row.levelText = row.levelBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.levelText:SetPoint("CENTER", row.levelBadge, "CENTER", 0.5, 0)
    local fontFile, _, fontFlags = row.levelText:GetFont()
    if fontFile then row.levelText:SetFont(fontFile, LEVEL_BADGE_FONT_SIZE, fontFlags) end
    row.levelSkull = row.levelBadge:CreateTexture(nil, "OVERLAY")
    row.levelSkull:SetSize(LEVEL_BADGE_SIZE - 6, LEVEL_BADGE_SIZE - 6)
    row.levelSkull:SetPoint("CENTER", row.levelBadge, "CENTER", 0, 0)
    row.levelSkull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    row.levelBadge:Hide()
    row.portraitFrame:Hide()
end

local function GetLevelColor(level)
    if type(GetQuestDifficultyColor) ~= "function" then return 1, 0.82, 0 end
    local ok, color = pcall(GetQuestDifficultyColor, level)
    if not ok or type(color) ~= "table" then return 1, 0.82, 0 end

    return color.r or 1, color.g or 1, color.b or 1
end

local function UpdateBossLevelBadge(row, boss)
    if row.levelBadge == nil then return end
    row.bossDragon:Hide()
    row.levelBadge:Hide()
    if boss.all or boss.trash then return end
    local npcID = boss.npcs and boss.npcs[1]
    local rank = boss.classification or npcID and AzerothCompendium.BOSSRANKS and AzerothCompendium.BOSSRANKS[npcID] or DEFAULT_BOSS_RANK
    local style = LEVEL_BADGE_STYLE[rank] or LEVEL_BADGE_STYLE[0]
    if style.dragon then
        row.bossDragon:SetTexture(MEDIA_PATH .. style.dragon)
        row.bossDragon:Show()
    end

    local isSkull = rank == 3 or (boss.level ~= nil and boss.level >= LEVEL_SKULL_MIN)
    if boss.level == nil and not isSkull then return end
    row.levelRing:SetColorTexture(style.ring[1], style.ring[2], style.ring[3], 1)

    if isSkull then
        row.levelText:Hide()
        row.levelSkull:Show()
    else
        row.levelText:SetText(boss.level)
        row.levelText:SetTextColor(GetLevelColor(boss.level))
        row.levelText:Show()
        row.levelSkull:Hide()
    end

    row.levelBadge:Show()
end

local function UpdateBossPortrait(row, boss)
    if row.portrait == nil then return end
    row.text:ClearAllPoints()
    if not UsesBossPortraits() then
        row.portraitFrame:Hide()
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row.info, "LEFT", -4, 0)

        return
    end

    local size = row.portraitFrame:GetWidth()
    if boss.all or boss.trash then
        row.portrait:SetTexture(boss.all and ALL_PORTRAIT or TRASH_PORTRAIT)
        if row.portraitZoomable then size = size / (1 - 2 * PORTRAIT_ICON_ZOOM) end
    else
        local applied = false
        if boss.model ~= nil and SetPortraitTextureFromCreatureDisplayID then applied = pcall(SetPortraitTextureFromCreatureDisplayID, row.portrait, boss.model) end
        if not applied then row.portrait:SetTexture(BOSS_PORTRAIT_FALLBACK) end
    end

    row.portrait:SetSize(size, size)
    UpdateBossLevelBadge(row, boss)
    row.portraitFrame:Show()
    row.text:SetPoint("LEFT", row.portraitFrame, "RIGHT", BOSS_TEXT_GAP, -BOSS_PORTRAIT_Y)
    row.text:SetPoint("RIGHT", row.info, "LEFT", -4, 0)
end

local function UpdateBossRow(row, boss)
    row.entry = boss
    UpdateBossPortrait(row, boss)
    row.text:SetText(AzerothCompendium:GetBossName(boss))
    local count = boss.all and #GetAllLoot(selectedInstance) or VisibleLootCount(boss)
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
    for _, inst in ipairs(AzerothCompendium:GetInstances(listKind)) do
        if IsInstanceVisible(inst) and InstanceMatches(inst) then tinsert(list, inst) end
    end

    return list
end

local function GetBossList()
    local list = {}
    if selectedInstance == nil then return list end
    local order = {}
    for index, boss in ipairs(selectedInstance.bosses or {}) do
        order[boss] = index
        if (not selectedInstance.vendor or VisibleLootCount(boss) > 0) and BossMatches(boss) then tinsert(list, boss) end
    end

    if not selectedInstance.vendor and (listKind == "dungeon" or listKind == "raid") then
        table.sort(list, function(a, b)
            if (a.trash == true) ~= (b.trash == true) then return b.trash == true end
            local levelA = a.level or BOSS_UNKNOWN_LEVEL
            local levelB = b.level or BOSS_UNKNOWN_LEVEL
            if levelA ~= levelB then return levelA < levelB end

            return order[a] < order[b]
        end)
    end

    if #list > 0 and not selectedInstance.vendor and (listKind == "dungeon" or listKind == "raid") then tinsert(list, 1, GetAllEntry(selectedInstance)) end

    return list
end

local function GetQuestGraph()
    if selectedInstance == nil then return {} end
    local filter = nil
    if searchText ~= "" then filter = function(node) return Matches(node.quest and AzerothCompendium:GetQuestName(node.quest) or AzerothCompendium:GetQuestNameByID(node.id)) end end

    return AzerothCompendium:GetInstanceQuestGraph(selectedInstance, filter)
end

local function CountInstanceQuests(graph)
    local count = 0
    for _, node in ipairs(graph) do
        if node.instance then count = count + 1 end
    end

    return count
end

local function GetLootList()
    local list = {}
    if selectedBoss == nil then return list end
    local onlyClass = AzerothCompendium:GetConfig("CLASSFILTER", false)
    local class = select(2, UnitClass("player"))
    local loot = selectedBoss.loot or {}
    if selectedBoss.all then loot = GetAllLoot(selectedInstance) end
    for _, entry in ipairs(loot) do
        local itemID = entry[1]
        local boss = entry.source or selectedBoss
        local bossMatched = Matches(AzerothCompendium:GetBossName(boss)) or Matches(boss.name)
        local ok = IsItemVisible(itemID)
        if onlyClass and not AzerothCompendium:IsUsableByClass(itemID, class) then ok = false end
        if ok and searchText ~= "" and not bossMatched and not Matches(AzerothCompendium:GetItemDisplay(itemID)) then ok = false end
        if ok then tinsert(list, entry) end
    end

    return list
end

local function GetSpellList()
    local list = {}
    if selectedBoss == nil then return list end
    for _, spellID in ipairs(selectedBoss.spells or {}) do
        if AzerothCompendium:GetSpellInfo(spellID) ~= nil then tinsert(list, spellID) end
    end

    return list
end

local function GetInstanceKey(inst)
    if inst == nil then return nil end
    if inst.honor then return "honor" end
    if inst.factionID ~= nil then return "faction:" .. inst.factionID end
    if inst.id ~= nil then return "instance:" .. inst.id end

    return "name:" .. (inst.name or "")
end

local function GetBossKey(boss)
    if boss == nil then return nil end
    if boss.trash then return "trash" end
    if boss.npcs and boss.npcs[1] then return "npc:" .. boss.npcs[1] end
    if boss.standing ~= nil then return "standing:" .. boss.standing end
    if boss.rank ~= nil then return "rank:" .. boss.rank end

    return "name:" .. (boss.name or "")
end

local function BossHasItem(boss, itemID)
    for _, loot in ipairs(boss.loot or {}) do
        if loot[1] == itemID then return true end
    end

    return false
end

local function FindWishlistSource(itemID, source)
    if not IsItemVisible(itemID) then return nil, nil, nil end
    local kinds = {"dungeon", "raid", "pvp", "faction"}
    if type(source) == "table" and source.kind ~= nil then
        for _, inst in ipairs(AzerothCompendium:GetInstances(source.kind)) do
            if IsInstanceVisible(inst) and GetInstanceKey(inst) == source.instance then
                for _, boss in ipairs(inst.bosses or {}) do
                    if GetBossKey(boss) == source.boss and BossHasItem(boss, itemID) then return source.kind, inst, boss end
                end
            end
        end
    end

    for _, kind in ipairs(kinds) do
        for _, inst in ipairs(AzerothCompendium:GetInstances(kind)) do
            if IsInstanceVisible(inst) then
                for _, boss in ipairs(inst.bosses or {}) do
                    if BossHasItem(boss, itemID) then return kind, inst, boss end
                end
            end
        end
    end

    return nil, nil, nil
end

local function GetCurrentWishlistSource(boss)
    boss = boss or selectedBoss
    if selectedInstance == nil or boss == nil or boss.all then return nil end

    return {
        ["kind"] = listKind,
        ["instance"] = GetInstanceKey(selectedInstance),
        ["boss"] = GetBossKey(boss)
    }
end

local function GetWishlistList()
    local list = {}
    for itemID, source in pairs(AzerothCompendium:GetWishlist()) do
        itemID = tonumber(itemID)
        if itemID ~= nil and IsItemVisible(itemID) then
            local name = AzerothCompendium:GetItemDisplay(itemID)
            local _, inst, boss = FindWishlistSource(itemID, source)
            local sourceText = ""
            if inst ~= nil and boss ~= nil then sourceText = AzerothCompendium:GetInstanceName(inst) .. " - " .. AzerothCompendium:GetBossName(boss) end
            if (not IsClassicEra() or inst ~= nil) and (Matches(name) or Matches(sourceText)) then
                tinsert(list, {itemID = itemID, source = source, sourceText = sourceText, name = name})
            end
        end
    end

    table.sort(list, function(a, b)
        local aName = Lower(a.name or tostring(a.itemID))
        local bName = Lower(b.name or tostring(b.itemID))
        if aName == bName then return a.itemID < b.itemID end

        return aName < bName
    end)

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
    local frame = compendium.model
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
    if compendium == nil then return end
    for kind, tab in pairs(compendium.kindTabs) do
        tab:SetChecked(kind == listKind)
    end
end

local function GetInstanceMaps()
    if selectedInstance == nil or AzerothCompendium.INSTANCEMAPS == nil then return nil end

    return AzerothCompendium.INSTANCEMAPS[selectedInstance.id]
end

local function GetMapLevelLabel(maps, index)
    local info = maps[index]
    if info == nil then return "" end
    if info.name then return info.name end

    return selectedInstance and AzerothCompendium:GetInstanceName(selectedInstance) or ""
end

local function LayoutMapArt()
    local view = compendium.mapView
    local info = view.info
    if info == nil then return end
    local w = view:GetWidth()
    local h = view:GetHeight()
    if w == nil or h == nil or w <= 0 or h <= 0 then return end
    local ratio = info.height / info.width
    local width = w
    local height = w * ratio
    if height > h then
        height = h
        width = h / ratio
    end

    view.art:SetSize(width, height)
end

local function UpdateMapView()
    local view = compendium.mapView
    local control = compendium.mapLevel
    local maps = GetInstanceMaps()
    view:Show()
    if selectedInstance ~= mapInstance then
        mapInstance = selectedInstance
        mapLevel = 1
    end

    if maps == nil or #maps == 0 then
        view.info = nil
        view.art:Hide()
        view.empty:Show()
        control:Hide()

        return
    end

    if mapLevel > #maps then mapLevel = 1 end
    local info = maps[mapLevel]
    view.info = info
    view.art:SetTexture(info.file)
    view.art:SetTexCoord(0, info.width / info.fileWidth, 0, info.height / info.fileHeight)
    view.art:Show()
    view.empty:Hide()
    LayoutMapArt()
    if #maps > 1 then
        compendium.detailTitle:SetText("")
        control:Show()
        if control.GenerateMenu then
            control:GenerateMenu()
        elseif control.SetText then
            control:SetText(GetMapLevelLabel(maps, mapLevel))
        end
    else
        control:Hide()
    end
end

local function SelectMapLevel(index)
    mapLevel = index
    UpdateMapView()
end

local function ShowMapLevelMenu(owner)
    local maps = GetInstanceMaps()
    if maps == nil then return end
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
            for i in ipairs(maps) do
                rootDescription:CreateRadio(GetMapLevelLabel(maps, i), function() return mapLevel == i end, function() SelectMapLevel(i) end)
            end
        end)

        return
    end

    if EasyMenu == nil then return end
    if mapLevelMenu == nil then mapLevelMenu = CreateFrame("Frame", "AzerothCompendiumMapLevelMenu", UIParent, "UIDropDownMenuTemplate") end
    local entries = {}
    for i in ipairs(maps) do
        tinsert(entries, {text = GetMapLevelLabel(maps, i), checked = mapLevel == i, func = function() SelectMapLevel(i) end})
    end

    EasyMenu(entries, mapLevelMenu, owner, 0, 0, "MENU")
end

local function RefreshDetail()
    if compendium == nil then return end
    if middleKind == "map" and (listKind == "dungeon" or listKind == "raid") then
        compendium.loot:Hide()
        compendium.spells:Hide()
        if compendium.model then compendium.model:Hide() end
        for _, button in pairs(compendium.detailTabs) do button:Hide() end
        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        compendium.empty:Hide()
        compendium.detailTitle:SetText(selectedInstance and AzerothCompendium:GetInstanceName(selectedInstance) or "")
        compendium.detailCount:SetText("")
        UpdateMapView()

        return
    end

    if middleKind == "quests" and (listKind == "dungeon" or listKind == "raid") then
        compendium.loot:Hide()
        compendium.spells:Hide()
        if compendium.model then compendium.model:Hide() end
        for _, button in pairs(compendium.detailTabs) do button:Hide() end
        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        compendium.empty:Hide()
        compendium.detailTitle:SetText(selectedInstance and AzerothCompendium:GetInstanceName(selectedInstance) or "")
        compendium.detailCount:SetText(AzerothCompendium:Trans("LID_QUESTCOUNT", nil, CountInstanceQuests(compendium.questTree.graph)))

        return
    end

    compendium.questTree:Hide()
    compendium.detailTitle:Show()
    compendium.detailCount:Show()
    local count = 0
    local empty = false
    local lootOnly = selectedInstance ~= nil and (selectedInstance.vendor == true or selectedBoss ~= nil and (selectedBoss.trash == true or selectedBoss.all == true))
    if lootOnly and detailKind ~= "loot" then detailKind = "loot" end
    for kind, button in pairs(compendium.detailTabs) do
        if kind ~= "loot" and lootOnly then
            button:Hide()
        else
            button:Show()
        end
    end

    if detailKind == "loot" then
        compendium.loot:SetData(GetLootList())
        compendium.loot:Show()
        compendium.spells:Hide()
        if compendium.model then compendium.model:Hide() end
        count = #compendium.loot.data
        compendium.detailCount:SetText(AzerothCompendium:Trans("LID_ITEMCOUNT", nil, count))
        compendium.classFilter:Show()
        compendium.classFilterLabel:Show()
        empty = count == 0
    elseif detailKind == "spells" then
        compendium.spells:SetData(GetSpellList())
        compendium.spells:Show()
        compendium.loot:Hide()
        if compendium.model then compendium.model:Hide() end
        count = #compendium.spells.data
        compendium.detailCount:SetText(AzerothCompendium:Trans("LID_ABILITYCOUNT", nil, count))
        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        empty = count == 0
    else
        compendium.loot:Hide()
        compendium.spells:Hide()
        compendium.detailCount:SetText("")
        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        empty = not UpdateModel()
    end

    if selectedBoss ~= nil then
        compendium.detailTitle:SetText(AzerothCompendium:GetBossName(selectedBoss))
    else
        compendium.detailTitle:SetText("")
    end

    if empty then
        if detailKind == "model" then
            compendium.empty:SetText(AzerothCompendium:Trans("LID_NOMODEL"))
        elseif selectedInstance ~= nil and selectedInstance.forever then
            compendium.empty:SetText(AzerothCompendium:Trans("LID_NODATAYET"))
        else
            compendium.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
        end

        compendium.empty:Show()
    else
        compendium.empty:Hide()
    end

    UpdateTabs(compendium.detailTabs, detailKind)
end

local function RefreshBosses()
    if compendium == nil then return end
    local showMiddleTabs = listKind == "dungeon" or listKind == "raid"
    if not showMiddleTabs then middleKind = "bosses" end
    for _, tab in pairs(compendium.middleTabs) do
        if showMiddleTabs then tab:Show() else tab:Hide() end
    end
    UpdateTabs(compendium.middleTabs, middleKind)
    if middleKind == "map" then
        compendium.bosses:Hide()
        compendium.bossTitle:Hide()
        compendium.questTree:Hide()
        RefreshDetail()

        return
    end

    compendium.mapView:Hide()
    compendium.mapLevel:Hide()
    if middleKind == "quests" then
        compendium.bosses:Hide()
        compendium.bossTitle:Hide()
        compendium.questTree:Show()
        compendium.questTree:SetGraph(GetQuestGraph())
        RefreshDetail()

        return
    end

    compendium.questTree:Hide()
    compendium.bosses:Show()
    local list = GetBossList()
    if UsesBossPortraits() then
        compendium.bosses:SetRowHeight(BOSS_ROW_H)
    else
        compendium.bosses:SetRowHeight(ROW_H)
    end

    compendium.bosses:SetData(list)
    local found = false
    for _, boss in ipairs(list) do
        if boss == selectedBoss then found = true end
    end

    if not found then selectedBoss = list[1] end
    compendium.bosses:Refresh()
    if selectedInstance ~= nil then
        compendium.bossTitle:SetText(AzerothCompendium:GetInstanceName(selectedInstance))
    else
        compendium.bossTitle:SetText("")
    end
    if showMiddleTabs then compendium.bossTitle:Hide() else compendium.bossTitle:Show() end

    RefreshDetail()
end

local function RefreshInstances()
    if compendium == nil then return end
    local list = GetInstanceList()
    if UsesLoadingScreens() then
        compendium.instances:SetRowHeight(INSTANCE_ROW_H)
    else
        compendium.instances:SetRowHeight(ROW_H)
    end

    compendium.instances:SetData(list)
    local found = false
    for _, inst in ipairs(list) do
        if inst == selectedInstance then found = true end
    end

    if not found then
        selectedInstance = list[1]
        selectedBoss = nil
    end

    compendium.instances:Refresh()
    RefreshBosses()
end

local function OnInstanceClick(inst)
    selectedInstance = inst
    selectedBoss = nil
    compendium.instances:Refresh()
    RefreshBosses()
end

local function OnBossClick(boss)
    selectedBoss = boss
    compendium.bosses:Refresh()
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
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_DROPPEDBY"), AzerothCompendium:GetBossName(row.boss))), 1, 0.82, 0)
    end

    GameTooltip:Show()
end

local contextMenu = nil
local function ShowWishlistMenu(owner, itemID, source)
    local listed = AzerothCompendium:IsWishlisted(itemID)
    local label = AzerothCompendium:Trans(listed and "LID_REMOVEFROMWISHLIST" or "LID_ADDTOWISHLIST")
    local action = function()
        if listed then
            AzerothCompendium:SetWishlistItem(itemID, nil)
        else
            AzerothCompendium:SetWishlistItem(itemID, source)
        end
    end

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, rootDescription) rootDescription:CreateButton(label, action) end)

        return
    end

    if EasyMenu == nil then return end
    if contextMenu == nil then contextMenu = CreateFrame("Frame", "AzerothCompendiumContextMenu", UIParent, "UIDropDownMenuTemplate") end
    EasyMenu({{text = label, notCheckable = true, func = action}}, contextMenu, "cursor", 0, 0, "MENU")
end

local function CreateLootRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel, button)
        if button == "RightButton" then
            ShowWishlistMenu(sel, sel.itemID, sel.wishlistSource)

            return
        end

        if sel.jumpBoss ~= nil and not (IsModifiedClick and IsModifiedClick()) then
            OnBossClick(sel.jumpBoss)

            return
        end

        if sel.link == nil then return end
        if HandleModifiedItemClick then HandleModifiedItemClick(sel.link) end
    end)

    function row:Update(entry)
        local itemID = entry[1]
        local chance = entry[2]
        self.itemID = itemID
        self.jumpBoss = entry.source
        self.boss = entry.source or selectedInstance and not selectedInstance.vendor and selectedBoss or nil
        self.wishlistSource = GetCurrentWishlistSource(entry.source)
        local name, link, quality, _, icon = AzerothCompendium:GetItemDisplay(itemID)
        self.link = link
        self.icon:SetTexture(icon or 134400)
        self.name:SetText(name or AzerothCompendium:Trans("LID_LOADING"))
        local color = nil
        if quality ~= nil and ITEM_QUALITY_COLORS ~= nil then color = ITEM_QUALITY_COLORS[quality] end
        if color ~= nil then
            self.name:SetTextColor(color.r, color.g, color.b)
        else
            self.name:SetTextColor(0.6, 0.6, 0.6)
        end

        self.slot:SetText(AzerothCompendium:GetItemSlotText(itemID))
        if chance ~= nil and AzerothCompendium:GetConfig("SHOWCHANCE", true) then
            self.chance:SetText(format("%.1f%%", chance))
            if chance >= 50 then
                self.chance:SetTextColor(0.4, 0.9, 0.4)
            elseif chance >= 10 then
                self.chance:SetTextColor(0.95, 0.85, 0.4)
            else
                self.chance:SetTextColor(0.9, 0.55, 0.45)
            end
        elseif AzerothCompendium:IsForeverItem(itemID) then
            self.chance:SetText(AzerothCompendium:Trans("LID_NEWITEM"))
            self.chance:SetTextColor(0.4, 0.8, 1)
        else
            self.chance:SetText("")
        end
    end

    return row
end

local NavigateToWishlistItem = nil
local function CreateWishlistRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.name:SetJustifyH("LEFT")
    row.source = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.source:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 1)
    row.source:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.source:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(sel) ShowItemTooltip(sel) end)
    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel, button)
        if button == "RightButton" then
            ShowWishlistMenu(sel, sel.itemID, nil)

            return
        end

        if NavigateToWishlistItem then NavigateToWishlistItem(sel.entry) end
    end)

    function row:Update(entry)
        self.entry = entry
        self.itemID = entry.itemID
        local name, link, quality, _, icon = AzerothCompendium:GetItemDisplay(entry.itemID)
        self.link = link
        self.icon:SetTexture(icon or 134400)
        self.name:SetText(name or AzerothCompendium:Trans("LID_LOADING"))
        self.source:SetText(entry.sourceText or "")
        local color = nil
        if quality ~= nil and ITEM_QUALITY_COLORS ~= nil then color = ITEM_QUALITY_COLORS[quality] end
        if color ~= nil then
            self.name:SetTextColor(color.r, color.g, color.b)
        else
            self.name:SetTextColor(0.6, 0.6, 0.6)
        end

        local _, _, boss = FindWishlistSource(entry.itemID, entry.source)
        self.boss = boss
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

    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    function row:Update(entry)
        self.spellID = entry
        local name, _, icon = AzerothCompendium:GetSpellInfo(entry)
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

local function GetFlavorText()
    if AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA then return "Classic Era" end

    return "Forever"
end

local flavorMenu = nil
local function ShowFlavorMenu(owner)
    local function SelectFlavor(value)
        AzerothCompendium:SetFlavor(value)
    end

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
            rootDescription:CreateRadio("Classic Era", function() return AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA end, function() SelectFlavor(FLAVOR_CLASSIC_ERA) end)
            rootDescription:CreateRadio("Forever", function() return AzerothCompendium:GetFlavor() == FLAVOR_FOREVER end, function() SelectFlavor(FLAVOR_FOREVER) end)
        end)

        return
    end

    if EasyMenu == nil then return end
    if flavorMenu == nil then flavorMenu = CreateFrame("Frame", "AzerothCompendiumFlavorMenu", UIParent, "UIDropDownMenuTemplate") end
    EasyMenu({
        {text = "Classic Era", checked = AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA, func = function() SelectFlavor(FLAVOR_CLASSIC_ERA) end},
        {text = "Forever", checked = AzerothCompendium:GetFlavor() == FLAVOR_FOREVER, func = function() SelectFlavor(FLAVOR_FOREVER) end}
    }, flavorMenu, owner, 0, 0, "MENU")
end

local function CreateFlavorControl(parent)
    if AzerothCompendium:CheckTemplates("SettingsDropdownWithButtonsTemplate") then
        local control = CreateFrame("Frame", "AzerothCompendiumFlavorControl", parent, "SettingsDropdownWithButtonsTemplate")
        control:SetPoint("LEFT", parent, "TOPLEFT", 14, -73)
        control:SetWidth(190)
        control.Dropdown:SetWidth(120)
        local steppers = {}
        for _, child in ipairs({control:GetChildren()}) do
            if child ~= control.Dropdown and child.SetEnabled and child.GetObjectType and child:GetObjectType() == "Button" then tinsert(steppers, child) end
        end

        table.sort(steppers, function(a, b) return (a:GetLeft() or 0) < (b:GetLeft() or 0) end)
        local previous = control.DecrementButton or steppers[1]
        local following = control.IncrementButton or steppers[2]
        local setEnabled = {}
        local function LockStepper(button)
            if button == nil then return end
            setEnabled[button] = button.SetEnabled
            local nop = function() end
            button.SetEnabled = nop
            button.Enable = nop
            button.Disable = nop
        end

        LockStepper(previous)
        LockStepper(following)
        local function SelectFlavor(value)
            AzerothCompendium:SetFlavor(value)
        end

        if previous then previous:SetScript("OnClick", function() SelectFlavor(FLAVOR_CLASSIC_ERA) end) end
        if following then following:SetScript("OnClick", function() SelectFlavor(FLAVOR_FOREVER) end) end
        control.Dropdown:SetupMenu(function(_, rootDescription)
            rootDescription:CreateTitle(AzerothCompendium:Trans("LID_FLAVOR"))
            rootDescription:CreateButton("Classic Era", function() SelectFlavor(FLAVOR_CLASSIC_ERA) end)
            rootDescription:CreateButton("Forever", function() SelectFlavor(FLAVOR_FOREVER) end)
        end)
        parent.flavorControl = control
        parent.flavorDropdown = control.Dropdown
        parent.updateFlavorSteppers = function()
            local classic = AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA
            if previous then setEnabled[previous](previous, not classic) end
            if following then setEnabled[following](following, classic) end
        end
        control:HookScript("OnShow", parent.updateFlavorSteppers)
    else
        local button = CreateTemplated("Button", "AzerothCompendiumFlavorDropdown", parent, {"UIPanelButtonTemplate"})
        button:SetSize(190, 22)
        button:SetPoint("LEFT", parent, "TOPLEFT", 14, -73)
        button:SetScript("OnClick", function(sel) ShowFlavorMenu(sel) end)
        local arrow = button:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", button, "RIGHT", -3, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
        parent.flavorDropdown = button
    end

    local text = GetFlavorText()
    if parent.flavorDropdown.SetDefaultText then parent.flavorDropdown:SetDefaultText(text) end
    if parent.flavorDropdown.Update then parent.flavorDropdown:Update() end
    if parent.flavorDropdown.SetText then parent.flavorDropdown:SetText(text) end
    if parent.updateFlavorSteppers then parent.updateFlavorSteppers() end
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
    local close = CreateTemplated("Button", "AzerothCompendiumCloseButton", frame, {"UIPanelCloseButton"})
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    close:SetSize(28, 28)
    close:SetScript("OnClick", function() frame:Hide() end)
    if close.SetText and close.GetFontString and close:GetFontString() ~= nil then close:SetText("X") end
end

local function MakeResizable(frame)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, 0, 0)
    elseif frame.SetMinResize then
        frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
    end

    local function GetMaxSize()
        local left, top = frame:GetLeft(), frame:GetTop()
        local scale = frame:GetEffectiveScale()
        local right = UIParent:GetRight()
        if left == nil or top == nil or right == nil or scale == nil or scale <= 0 then return nil, nil end
        local screenRight = right * UIParent:GetEffectiveScale() / scale

        return max(MIN_WIDTH, screenRight - left), max(MIN_HEIGHT, top)
    end

    local function ApplySize(width, height)
        local maxWidth, maxHeight = GetMaxSize()
        if maxWidth then
            width = min(width, maxWidth)
            height = min(height, maxHeight)
        end

        width = floor(max(MIN_WIDTH, width) + 0.5)
        height = floor(max(MIN_HEIGHT, height) + 0.5)
        if width ~= floor(frame:GetWidth() + 0.5) or height ~= floor(frame:GetHeight() + 0.5) then frame:SetSize(width, height) end
    end

    local grip = CreateFrame("Button", "AzerothCompendiumResize", frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(sel, button)
        if button ~= "LeftButton" then return end
        local left, top = frame:GetLeft(), frame:GetTop()
        if left == nil or top == nil then return end
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        local x, y = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        sel.sizing = {
            x = x / scale,
            y = y / scale,
            w = frame:GetWidth(),
            h = frame:GetHeight()
        }
    end)

    local function StopSizing(sel)
        if sel.sizing == nil then return end
        sel.sizing = nil
        AzerothCompendium:SetConfig("COMPENDIUMWIDTH", floor(frame:GetWidth() + 0.5))
        AzerothCompendium:SetConfig("COMPENDIUMHEIGHT", floor(frame:GetHeight() + 0.5))
    end

    grip:SetScript("OnMouseUp", StopSizing)
    grip:SetScript("OnHide", StopSizing)
    grip:SetScript("OnUpdate", function(sel)
        local sizing = sel.sizing
        if sizing == nil then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            StopSizing(sel)

            return
        end

        local x, y = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        ApplySize(sizing.w + x / scale - sizing.x, sizing.h + sizing.y - y / scale)
    end)

    frame:HookScript("OnShow", function() ApplySize(frame:GetWidth(), frame:GetHeight()) end)
    frame.resizeGrip = grip
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
        GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(sel.tooltip))
        GameTooltip:Show()
    end)

    tab:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
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
        local ok, created = pcall(CreateFrame, kind, "AzerothCompendiumModel", parent)
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

local function NormalizeScale(value)
    value = tonumber(value) or 1

    return min(SCALE_MAX, max(SCALE_MIN, floor(value / SCALE_STEP + 0.5) * SCALE_STEP))
end

local function CreateScaleSlider(parent)
    local value = NormalizeScale(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1))
    local function ApplyScale(scale)
        scale = NormalizeScale(scale)
        parent:SetScale(scale)
        AzerothCompendium:SetConfig("COMPENDIUMSCALE", scale)
    end
    local ok, slider = pcall(CreateFrame, "Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    if ok and slider ~= nil and type(slider.Init) == "function" and type(slider.RegisterCallback) == "function" then
        slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 16, 1)
        slider:SetSize(150, 25)
        local formatters = {}
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            formatters[MinimalSliderWithSteppersMixin.Label.Right] = function(scale)
                return format("%d%%", floor(NormalizeScale(scale) * 100 + 0.5))
            end
        end
        slider:Init(value, SCALE_MIN, SCALE_MAX, (SCALE_MAX - SCALE_MIN) / SCALE_STEP, formatters)
        local pendingScale = value
        slider:RegisterCallback("OnValueChanged", function(_, scale)
            pendingScale = NormalizeScale(scale)
            if slider.InteractionFlags == nil or not slider.InteractionFlags:IsAnySet() then ApplyScale(pendingScale) end
        end, parent)
        slider.Slider:HookScript("OnMouseUp", function()
            ApplyScale(pendingScale)
        end)
        parent.scaleSlider = slider

        return
    end
    local minimal
    minimal, slider = pcall(CreateFrame, "Slider", nil, parent, "MinimalSliderTemplate")
    if not minimal or slider == nil then
        slider = CreateFrame("Slider", nil, parent)
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", slider, "LEFT", 0, 0)
        track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        track:SetHeight(4)
        track:SetColorTexture(0.25, 0.25, 0.25, 1)
        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        thumb:SetSize(24, 24)
        slider:SetThumbTexture(thumb)
    end
    slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 20, 5)
    slider:SetSize(120, 19)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(SCALE_MIN, SCALE_MAX)
    slider:SetValueStep(SCALE_STEP)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 6, 0)
    valueText:SetWidth(42)
    valueText:SetJustifyH("LEFT")
    local pendingScale = value
    local interacting = false
    slider:SetScript("OnMouseDown", function() interacting = true end)
    slider:SetScript("OnMouseUp", function()
        interacting = false
        ApplyScale(pendingScale)
    end)
    slider:SetScript("OnValueChanged", function(_, scale)
        pendingScale = NormalizeScale(scale)
        valueText:SetFormattedText("%d%%", floor(pendingScale * 100 + 0.5))
        if not interacting then ApplyScale(pendingScale) end
    end)
    slider:SetValue(value)
    parent.scaleSlider = slider
    parent.scaleValue = valueText
end

local function SetWishlistMode(enabled)
    if compendium == nil then return end
    local regular = {
        compendium.instances,
        compendium.bossTitle,
        compendium.bosses,
        compendium.questTree,
        compendium.mapView,
        compendium.mapLevel,
        compendium.loot,
        compendium.spells,
        compendium.detailCount,
        compendium.detailTitle,
        compendium.classFilter,
        compendium.classFilterLabel,
        compendium.empty
    }

    if compendium.model then tinsert(regular, compendium.model) end
    for _, tab in pairs(compendium.detailTabs or {}) do tinsert(regular, tab) end
    for _, tab in pairs(compendium.middleTabs or {}) do tinsert(regular, tab) end
    for _, frame in ipairs(regular) do
        if enabled then
            frame:Hide()
        else
            frame:Show()
        end
    end

    for _, frame in ipairs({compendium.flavorControl or compendium.flavorDropdown}) do
        if enabled then
            frame:Hide()
        else
            frame:Show()
        end
    end

    if compendium.wishlist then
        if enabled then
            compendium.wishlist:Show()
            compendium.wishlistTitle:Show()
            compendium.wishlistCount:Show()
        else
            compendium.wishlist:Hide()
            compendium.wishlistTitle:Hide()
            compendium.wishlistCount:Hide()
            compendium.wishlistEmpty:Hide()
        end
    end
end

local function RefreshWishlistView()
    if compendium == nil or compendium.wishlist == nil then return end
    SetWishlistMode(true)
    local list = GetWishlistList()
    compendium.wishlist:SetData(list)
    compendium.wishlistCount:SetText(AzerothCompendium:Trans("LID_ITEMCOUNT", nil, #list))
    if #list == 0 then
        compendium.wishlistEmpty:Show()
    else
        compendium.wishlistEmpty:Hide()
    end
end

local function RefreshCurrentView()
    if listKind == "wishlist" then
        RefreshWishlistView()
    else
        SetWishlistMode(false)
        RefreshInstances()
    end
end

NavigateToWishlistItem = function(entry)
    if entry == nil then return end
    local kind, inst, boss = FindWishlistSource(entry.itemID, entry.source)
    if kind == nil or inst == nil or boss == nil then return end
    listKind = kind
    selectedInstance = inst
    selectedBoss = boss
    detailKind = "loot"
    searchText = ""
    UpdateKindTabs()
    SetWishlistMode(false)
    if compendium.search:GetText() ~= "" then
        compendium.search:SetText("")
    else
        RefreshInstances()
    end
end

function AzerothCompendium:RefreshWishlist()
    if compendium == nil or not compendium:IsShown() or listKind ~= "wishlist" then return end
    RefreshWishlistView()
end

local function CreateJournal()
    if compendium ~= nil then return compendium end
    local template = nil
    compendium, template = CreateTemplated(
        "Frame",
        "AzerothCompendiumFrame",
        UIParent,
        {"ButtonFrameTemplate", "PortraitFrameTemplate", "BasicFrameTemplateWithInset"}
    )

    if template == nil then AddFallbackChrome(compendium) end
    if type(compendium.Inset) == "table" and type(compendium.Inset.Bg) == "table" then compendium.Inset.Bg:SetAlpha(0.6) end
    SetFramePortrait(compendium, AzerothCompendium:GetIcon())
    local width = tonumber(AzerothCompendium:GetConfig("COMPENDIUMWIDTH", WIDTH)) or WIDTH
    local height = tonumber(AzerothCompendium:GetConfig("COMPENDIUMHEIGHT", HEIGHT)) or HEIGHT
    compendium:SetScale(NormalizeScale(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1)))
    compendium:SetSize(max(MIN_WIDTH, width), max(MIN_HEIGHT, height))
    compendium:SetPoint("TOPLEFT", UIParent, "CENTER", -compendium:GetWidth() / 2, compendium:GetHeight() / 2)
    compendium:SetFrameStrata("HIGH")
    compendium:SetMovable(true)
    compendium:EnableMouse(true)
    compendium:RegisterForDrag("LeftButton")
    compendium:SetScript("OnDragStart", function(sel) sel:StartMoving() end)
    compendium:SetScript("OnDragStop", function(sel) sel:StopMovingOrSizing() end)
    MakeResizable(compendium)
    AzerothCompendium:SetClampedToScreen(compendium, true, "AzerothCompendium")
    compendium:Hide()
    SetFrameTitle(compendium, format("|T%d:16:16:0:0|t %s v%s", AzerothCompendium:GetIcon(), AzerothCompendium:Trans("LID_TITLE"), AzerothCompendium:GetAddonVersion()))
    if type(UISpecialFrames) == "table" then tinsert(UISpecialFrames, "AzerothCompendiumFrame") end
    local search = CreateTemplated("EditBox", "AzerothCompendiumSearchBox", compendium, {"InputBoxTemplate", "SearchBoxTemplate"})
    search:SetSize(180, 20)
    search:SetPoint("TOPRIGHT", compendium, "TOPRIGHT", -30, -32)
    search:SetFontObject("ChatFontNormal")
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(sel)
        searchText = Lower(strtrim(sel:GetText() or ""))
        RefreshCurrentView()
    end)

    search:SetScript("OnEscapePressed", function(sel)
        sel:SetText("")
        sel:ClearFocus()
    end)

    compendium.search = search
    local searchLabel = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    searchLabel:SetPoint("RIGHT", search, "LEFT", -6, 0)
    searchLabel:SetText(AzerothCompendium:Trans("LID_SEARCH"))
    CreateFlavorControl(compendium)
    compendium.kindTabs = {}
    local pvpIcon = "Interface\\Icons\\INV_BannerPVP_01"
    if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then pvpIcon = "Interface\\Icons\\INV_BannerPVP_02" end
    local previousTab = nil
    for _, info in ipairs({
        {"dungeon", "LID_DUNGEONS", "Interface\\Icons\\INV_Misc_Map_01"},
        {"raid", "LID_RAIDS", "Interface\\Icons\\INV_Misc_Head_Dragon_01"},
        {"pvp", "LID_PVP", pvpIcon},
        {"faction", "LID_REPUTATION", "Interface\\Icons\\INV_Shirt_GuildTabard_01"},
        {"wishlist", "LID_WISHLIST", "Interface\\Icons\\INV_Misc_Note_01"},
    }) do
        local kind = info[1]
        local tab = CreateSideTab(compendium, AzerothCompendium:Trans(info[2]), info[3], function()
            if listKind == kind then
                UpdateKindTabs()

                return
            end

            listKind = kind
            middleKind = "map"
            selectedInstance = nil
            selectedBoss = nil
            UpdateKindTabs()
            RefreshCurrentView()
        end)

        if previousTab == nil then
            tab:SetPoint("TOPLEFT", compendium, "TOPRIGHT", -2, -SIDE_TAB_TOP)
        else
            tab:SetPoint("TOPLEFT", previousTab, "BOTTOMLEFT", 0, -SIDE_TAB_GAP)
        end

        compendium.kindTabs[kind] = tab
        previousTab = tab
    end

    local instances = CreateScroller(compendium, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, OnInstanceClick)
        AddLoadingScreen(row)
        function row:Update(entry)
            UpdateInstanceRow(self, entry)
        end

        return row
    end)

    instances:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -90)
    instances:SetPoint("BOTTOMLEFT", compendium, "BOTTOMLEFT", 12, 28)
    instances:SetWidth(INSTANCE_COL_W)
    compendium.instances = instances
    local bossTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    bossTitle:SetPoint("BOTTOMLEFT", instances, "TOPLEFT", INSTANCE_COL_W + 12, 6)
    bossTitle:SetWidth(MIDDLE_COL_W)
    bossTitle:SetWordWrap(false)
    bossTitle:SetJustifyH("LEFT")
    compendium.bossTitle = bossTitle
    local bosses = CreateScroller(compendium, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, OnBossClick)
        AddBossPortrait(row)
        function row:Update(entry)
            UpdateBossRow(self, entry)
        end

        return row
    end)

    bosses:SetPoint("TOPLEFT", instances, "TOPRIGHT", 12, 0)
    bosses:SetPoint("BOTTOMLEFT", instances, "BOTTOMRIGHT", 12, 0)
    bosses:SetWidth(MIDDLE_COL_W)
    compendium.bosses = bosses
    local questTree = AzerothCompendium:CreateQuestTree(compendium)
    questTree:SetPoint("TOPLEFT", bosses, "TOPLEFT", 0, 0)
    questTree:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    questTree:Hide()
    compendium.questTree = questTree
    local mapView = CreateFrame("Frame", nil, compendium)
    mapView:SetPoint("TOPLEFT", bosses, "TOPLEFT", 0, 0)
    mapView:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    mapView.art = mapView:CreateTexture(nil, "ARTWORK")
    mapView.art:SetPoint("CENTER", mapView, "CENTER", 0, 0)
    mapView.empty = mapView:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    mapView.empty:SetPoint("CENTER", mapView, "CENTER", 0, 0)
    mapView.empty:SetText(AzerothCompendium:Trans("LID_NOMAP"))
    mapView:SetScript("OnSizeChanged", LayoutMapArt)
    mapView:Hide()
    compendium.mapView = mapView
    local mapLevelControl = nil
    if AzerothCompendium:CheckTemplates("WowStyle1DropdownTemplate") then
        mapLevelControl = CreateTemplated("DropdownButton", nil, compendium, {"WowStyle1DropdownTemplate"})
        mapLevelControl:SetupMenu(function(_, rootDescription)
            local maps = GetInstanceMaps() or {}
            for i in ipairs(maps) do
                rootDescription:CreateRadio(GetMapLevelLabel(maps, i), function() return mapLevel == i end, function() SelectMapLevel(i) end)
            end
        end)
    else
        mapLevelControl = CreateTemplated("Button", nil, compendium, {"UIPanelButtonTemplate"})
        mapLevelControl:SetScript("OnClick", function(sel) ShowMapLevelMenu(sel) end)
        local arrow = mapLevelControl:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", mapLevelControl, "RIGHT", -3, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    end

    mapLevelControl:SetSize(220, 22)
    mapLevelControl:SetPoint("BOTTOMRIGHT", mapView, "TOPRIGHT", 0, 2)
    mapLevelControl:Hide()
    compendium.mapLevel = mapLevelControl
    compendium.middleTabs = {}
    local tabWidth = (MIDDLE_COL_W - 4) / 3
    local mapTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_MAP"), function()
        middleKind = "map"
        RefreshBosses()
    end)
    mapTab:SetWidth(tabWidth)
    mapTab:SetPoint("BOTTOMLEFT", bosses, "TOPLEFT", 0, 1)
    local bossTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_BOSSES"), function()
        middleKind = "bosses"
        RefreshBosses()
    end)
    bossTab:SetWidth(tabWidth)
    bossTab:SetPoint("LEFT", mapTab, "RIGHT", 2, 0)
    local questTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_QUESTS"), function()
        middleKind = "quests"
        RefreshBosses()
    end)
    questTab:SetWidth(tabWidth)
    questTab:SetPoint("LEFT", bossTab, "RIGHT", 2, 0)
    compendium.middleTabs["map"] = mapTab
    compendium.middleTabs["bosses"] = bossTab
    compendium.middleTabs["quests"] = questTab
    local loot = CreateScroller(compendium, LOOT_ROW_H, CreateLootRow)
    loot:SetPoint("TOPLEFT", bosses, "TOPRIGHT", 14, -ROW_H)
    loot:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    compendium.loot = loot
    local wishlist = CreateScroller(compendium, LOOT_ROW_H, CreateWishlistRow)
    wishlist:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -90)
    wishlist:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    wishlist:Hide()
    compendium.wishlist = wishlist
    local wishlistTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    wishlistTitle:SetPoint("BOTTOMLEFT", wishlist, "TOPLEFT", 0, 6)
    wishlistTitle:SetText(AzerothCompendium:Trans("LID_WISHLIST"))
    wishlistTitle:Hide()
    compendium.wishlistTitle = wishlistTitle
    local wishlistCount = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    wishlistCount:SetPoint("BOTTOMRIGHT", wishlist, "TOPRIGHT", 0, 6)
    wishlistCount:SetJustifyH("RIGHT")
    wishlistCount:Hide()
    compendium.wishlistCount = wishlistCount
    local wishlistEmpty = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    wishlistEmpty:SetPoint("CENTER", wishlist, "CENTER", 0, 0)
    wishlistEmpty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    wishlistEmpty:Hide()
    compendium.wishlistEmpty = wishlistEmpty
    local spells = CreateScroller(compendium, LOOT_ROW_H, CreateSpellRow)
    spells:SetAllPoints(loot)
    spells:Hide()
    compendium.spells = spells
    compendium.detailTabs = {}
    local spellTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_ABILITIES"), function()
        detailKind = "spells"
        RefreshDetail()
    end)

    spellTab:SetWidth(78)
    local lootTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_LOOT"), function()
        detailKind = "loot"
        RefreshDetail()
    end)

    lootTab:SetWidth(78)
    compendium.detailTabs["loot"] = lootTab
    compendium.detailTabs["spells"] = spellTab
    local model = CreateModelFrame(compendium)
    if model ~= nil then
        model:SetPoint("TOPLEFT", loot, "TOPLEFT", 0, 0)
        model:SetPoint("BOTTOMRIGHT", loot, "BOTTOMRIGHT", 0, 0)
        model:Hide()
        compendium.model = model
        local modelTab = CreateTabButton(compendium, AzerothCompendium:Trans("LID_MODEL"), function()
            detailKind = "model"
            RefreshDetail()
        end)

        modelTab:SetWidth(78)
        modelTab:SetPoint("TOPRIGHT", compendium, "TOPRIGHT", -14, -62 - ROW_H)
        compendium.detailTabs["model"] = modelTab
        spellTab:SetPoint("TOPRIGHT", modelTab, "TOPLEFT", -2, 0)
    else
        spellTab:SetPoint("TOPRIGHT", compendium, "TOPRIGHT", -14, -62 - ROW_H)
    end

    lootTab:SetPoint("TOPRIGHT", spellTab, "TOPLEFT", -2, 0)
    local detailCount = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detailCount:SetPoint("BOTTOMRIGHT", loot, "TOPRIGHT", 0, ROW_H + 6)
    detailCount:SetJustifyH("RIGHT")
    compendium.detailCount = detailCount
    local detailTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    detailTitle:SetPoint("BOTTOMLEFT", bosses, "TOPRIGHT", 14, 6)
    detailTitle:SetPoint("RIGHT", detailCount, "LEFT", -8, 0)
    detailTitle:SetWordWrap(false)
    detailTitle:SetJustifyH("LEFT")
    compendium.detailTitle = detailTitle
    local classFilter = CreateTemplated("CheckButton", "AzerothCompendiumClassFilter", compendium, {"UICheckButtonTemplate", "ChatConfigCheckButtonTemplate"})
    classFilter:SetSize(24, 24)
    classFilter:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -32, 2)
    classFilter:SetChecked(AzerothCompendium:GetConfig("CLASSFILTER", false) == true)
    local classFilterLabel = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    classFilterLabel:SetPoint("RIGHT", classFilter, "LEFT", 0, 0)
    classFilterLabel:SetText(AzerothCompendium:Trans("LID_CLASSFILTER"))
    classFilter:SetScript("OnClick", function(sel)
        AzerothCompendium:SetClassFilter(sel:GetChecked() == true)
    end)

    compendium.classFilter = classFilter
    compendium.classFilterLabel = classFilterLabel
    CreateScaleSlider(compendium)
    local empty = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    empty:SetPoint("CENTER", loot, "CENTER", 0, 0)
    empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    empty:Hide()
    compendium.empty = empty

    return compendium
end

function AzerothCompendium:SyncCompendiumClassFilter()
    if compendium == nil or compendium.classFilter == nil then return end
    compendium.classFilter:SetChecked(AzerothCompendium:GetConfig("CLASSFILTER", false) == true)
end

function AzerothCompendium:SyncCompendiumFlavor()
    if compendium == nil or compendium.flavorDropdown == nil then return end
    local dropdown = compendium.flavorDropdown
    local text = GetFlavorText()
    if dropdown.SetDefaultText then dropdown:SetDefaultText(text) end
    if dropdown.Update then dropdown:Update() end
    if dropdown.SetText then dropdown:SetText(text) end
    if compendium.updateFlavorSteppers then compendium.updateFlavorSteppers() end
end

function AzerothCompendium:RefreshCompendium()
    AzerothCompendium:SyncCompendiumClassFilter()
    AzerothCompendium:SyncCompendiumFlavor()
    if compendium == nil or not compendium:IsShown() then return end
    RefreshCurrentView()
end

function AzerothCompendium:ToggleCompendium()
    CreateJournal()
    if compendium:IsShown() then
        compendium:Hide()

        return
    end

    compendium:Show()
    UpdateKindTabs()
    RefreshCurrentView()
end

function AzerothCompendium:OpenCompendium()
    CreateJournal()
    if compendium:IsShown() then return end
    compendium:Show()
    UpdateKindTabs()
    RefreshCurrentView()
end

local loader = CreateFrame("Frame")
AzerothCompendium:RegisterEvent(loader, "PLAYER_LOGIN")
AzerothCompendium:RegisterEvent(loader, "GET_ITEM_INFO_RECEIVED")
AzerothCompendium:RegisterEvent(loader, "QUEST_LOG_UPDATE")
AzerothCompendium:RegisterEvent(loader, "QUEST_TURNED_IN")
loader:SetScript("OnEvent", function(sel, event)
    if event == "PLAYER_LOGIN" then
        AzerothCompendium:PreloadItems()

        return
    end

    if event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" then
        if compendium ~= nil and compendium:IsShown() and middleKind == "quests" then
            compendium.questTree:Refresh()
        end

        return
    end

    if compendium == nil or not compendium:IsShown() then return end
    if refreshPending then return end
    refreshPending = true
    AzerothCompendium:After(
        0.25,
        function()
            refreshPending = false
            if compendium ~= nil and compendium:IsShown() then
                if listKind == "wishlist" then
                    RefreshWishlistView()
                else
                    compendium.instances:Refresh()
                    compendium.bosses:Refresh()
                    compendium.loot:Refresh()
                    compendium.questTree:Refresh()
                end
            end
        end,
        "AzerothCompendium:ItemInfo"
    )
end)
