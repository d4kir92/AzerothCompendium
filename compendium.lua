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
local WORLD_QUEST_ITEM_ROW_H = LOOT_ROW_H + 6
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
local TAB_ICONS = {
    ["map"] = {
        texture = "Interface\\Icons\\INV_Misc_Map_01"
    },
    ["bosses"] = {
        texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
        texCoords = {0.75, 1, 0.25, 0.5}
    },
    ["quests"] = {
        texture = "Interface\\GossipFrame\\ActiveQuestIcon",
        texCoords = {0, 1, 0, 1}
    },
    ["loot"] = {
        texture = "Interface\\Icons\\INV_Misc_Bag_08"
    },
    ["spells"] = {
        texture = "Interface\\Icons\\Spell_Nature_Lightning"
    },
    ["model"] = {
        texture = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
    }
}

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
local validListKinds = {
    dungeon = true,
    raid = true,
    pvp = true,
    faction = true,
    worldquestitems = true,
    wishlist = true
}

local validMiddleKinds = {
    map = true,
    bosses = true,
    quests = true
}

local validDetailKinds = {
    loot = true,
    spells = true,
    model = true
}

local listKind = "dungeon"
local middleKind = "map"
local detailKind = "loot"
local mapLevel = 1
local restoreInstanceKey = nil
local restoreBossKey = nil
local mapInstance = nil
local savedSearchText = ""
local searchText = ""
local navigationLoaded = false
local refreshPending = false
local FLAVOR_FOREVER = "forever"
local FLAVOR_CLASSIC_ERA = "classic_era"
local function Lower(text)
    if text == nil then return "" end
    return strlower(text)
end

local function LoadNavigationState()
    if navigationLoaded then return end
    navigationLoaded = true
    local navigation = type(ACOTABPC) == "table" and type(ACOTABPC["NAVIGATION"]) == "table" and ACOTABPC["NAVIGATION"] or {}
    listKind = validListKinds[navigation.listKind] and navigation.listKind or "dungeon"
    middleKind = validMiddleKinds[navigation.middleKind] and navigation.middleKind or "map"
    detailKind = validDetailKinds[navigation.detailKind] and navigation.detailKind or "loot"
    mapLevel = max(1, floor(tonumber(navigation.mapLevel) or 1))
    restoreInstanceKey = type(navigation.instance) == "string" and navigation.instance or nil
    restoreBossKey = type(navigation.boss) == "string" and navigation.boss or nil
    savedSearchText = type(navigation.search) == "string" and navigation.search or ""
    searchText = Lower(strtrim(savedSearchText))
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
    if allEntries[inst] == nil then
        allEntries[inst] = {
            all = true
        }
    end
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
                tinsert(list, {
                    itemID,
                    entry[2],
                    source = boss
                })
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

local function AddContentBorder(frame)
    frame.contentBackground = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    frame.contentBackground:SetAtlas("collections-background-tile")
    frame.contentBackground:SetHorizTile(true)
    frame.contentBackground:SetVertTile(true)
    frame.contentBackground:SetAllPoints(frame)
    frame.border = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    frame.border:SetAtlas("common-insideframe")
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
end

local function CreateScroller(parent, rowHeight, initRow, padding)
    padding = padding or 0
    local scroller = CreateFrame("Frame", nil, parent)
    AddContentBorder(scroller)
    scroller.rowHeight = rowHeight
    scroller.rowGap = padding
    scroller.initRow = initRow
    scroller.rows = {}
    scroller.data = {}
    local content = nil
    if HasModernScroll() then
        local box = CreateFrame("Frame", nil, scroller, "WowScrollBox")
        box:SetPoint("TOPLEFT", scroller, "TOPLEFT", padding, -padding)
        box:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -SCROLLBAR_W, padding)
        local bar = CreateFrame("EventFrame", nil, scroller, "MinimalScrollBar")
        bar:SetPoint("TOPRIGHT", scroller, "TOPRIGHT", -5, -6)
        bar:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -5, 6)
        content = CreateFrame("Frame", nil, box)
        content.scrollable = true
        content:SetSize(1, 1)
        local view = CreateScrollBoxLinearView()
        view:SetPanExtent(rowHeight + padding)
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

        scroll:SetPoint("TOPLEFT", scroller, "TOPLEFT", padding, -padding)
        scroll:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -SCROLLBAR_W, padding)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(sel, delta)
            local range = max(0, (sel.djHeight or 0) - sel:GetHeight())
            sel:SetVerticalScroll(min(range, max(0, sel:GetVerticalScroll() - delta * (scroller.rowHeight + scroller.rowGap) * 3)))
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
        local height = max(1, (self.contentHeight or #self.data * (self.rowHeight + self.rowGap)) - self.rowGap)
        self.content:SetHeight(height)
        if type(self.scroll) == "table" then
            self.scroll.djHeight = height
            self.scroll:SetVerticalScroll(min(self.scroll:GetVerticalScroll(), max(0, height - self.scroll:GetHeight())))
        end
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
        local step = self.rowHeight + self.rowGap
        local range = max(0, (self.contentHeight or #self.data * step) - self.rowGap - viewport:GetHeight())
        local target = min(range, max(0, offset * step))
        if type(self.box) == "table" and self.box.SetScrollPercentage then
            local percentage = 0
            if range > 0 then percentage = target / range end
            self.box:SetScrollPercentage(percentage)
        elseif type(self.scroll) == "table" then
            self.scroll:SetVerticalScroll(target)
        end
    end

    function scroller:ScrollToIndex(index)
        if type(index) ~= "number" or self.data[index] == nil then return end
        local entry = self.data[index]
        local function Apply()
            if self.data[index] ~= entry then return end
            local viewport = self:GetViewport()
            if viewport == nil or viewport:GetHeight() <= 0 then return end
            self:Scroll(((self.rowOffsets and self.rowOffsets[index] or (index - 1) * (self.rowHeight + self.rowGap)) + (type(entry) == "table" and entry.rowHeight or self.rowHeight) / 2 - viewport:GetHeight() / 2) / (self.rowHeight + self.rowGap))
        end

        Apply()
        AzerothCompendium:After(0, Apply, "AzerothCompendium:ScrollToIndex")
    end

    function scroller:SetRowHeight(height)
        self.rowHeight = height
        if type(self.view) == "table" and self.view.SetPanExtent then self.view:SetPanExtent(height + self.rowGap) end
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
        local offset = 0
        self.rowOffsets = {}
        for index, entry in ipairs(self.data) do
            local row = self.rows[index]
            if row == nil then
                row = self.initRow(self.content)
                self.rows[index] = row
            end

            if row.stripe == nil and row.loadingScreen == nil then
                row.stripe = row:CreateTexture(nil, "BACKGROUND", nil, -8)
                row.stripe:SetAllPoints(row)
            end

            if row.stripe then row.stripe:SetColorTexture(1, 1, 1, index % 2 == 1 and 0.03 or 0.06) end
            self.rowOffsets[index] = offset
            row:SetHeight(type(entry) == "table" and entry.rowHeight or self.rowHeight)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -offset)
            offset = offset + (type(entry) == "table" and entry.rowHeight or self.rowHeight) + self.rowGap
            row:Update(entry)
            row:Show()
        end

        for index = #self.data + 1, #self.rows do
            self.rows[index]:Hide()
        end

        self.contentHeight = offset
        if self.empty then
            self.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
            self.empty:SetShown(#self.data == 0)
        end

        self:UpdateScroll()
    end

    function scroller:EnableEmptyText()
        self.empty = self:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
        self.empty:SetPoint("CENTER", self, "CENTER", 0, 0)
        self.empty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
        self.empty:SetShown(#self.data == 0)
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
    row:SetScript("OnClick", function(sel) if sel.entry ~= nil then onClick(sel.entry) end end)
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

local LOCATION_PIN_SIZE = 20
local LOCATION_PIN_SPACING = 2
local LOCATION_PIN_BADGE_SIZE = 11
local LOCATION_PIN_BADGE_ATLAS = "Waypoint-MapPin-Untracked"
local LOCATION_PIN_BADGE_HIGHLIGHT_ATLAS = "Waypoint-MapPin-Highlight"
local LOCATION_PIN_BADGE_FALLBACK = 134269
local DUNGEON_ICON_CANDIDATES = {"Dungeon", "DungeonSkull", "Dungeon-Normal"}
local DUNGEON_ICON_FALLBACK = "Interface\\Icons\\INV_Misc_Bone_Skull_02"
local RAID_ICON_CANDIDATES = {"Raid"}
local MEETING_STONE_ICON = {"Interface\\AddOns\\AzerothCompendium\\media\\meetingstone", false, true, 3}
local resolvedIcons = {}
local function ResolveIcon(candidates, fallback)
    if resolvedIcons[candidates] == nil then
        local atlas = AzerothCompendium:FindAtlas(candidates)
        resolvedIcons[candidates] = atlas and {atlas, true} or {fallback, false}
    end
    return resolvedIcons[candidates]
end

local function ApplyIcon(texture, icon)
    local inset = icon[4] or 0
    local parent = texture:GetParent()
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    AzerothCompendium:SetIconTexture(texture, icon[1], icon[3])
end

local function SetBadgeHighlight(pin, highlighted)
    if not AzerothCompendium:AtlasExists(LOCATION_PIN_BADGE_ATLAS) then return end
    if highlighted and AzerothCompendium:AtlasExists(LOCATION_PIN_BADGE_HIGHLIGHT_ATLAS) then
        pin.badge:SetAtlas(LOCATION_PIN_BADGE_HIGHLIGHT_ATLAS)
    else
        pin.badge:SetAtlas(LOCATION_PIN_BADGE_ATLAS)
    end
end

local LOCATION_PINS = {
    entrance = {
        getIcon = function(inst)
            if inst.type == "raid" then return ResolveIcon(RAID_ICON_CANDIDATES, DUNGEON_ICON_FALLBACK) end
            return ResolveIcon(DUNGEON_ICON_CANDIDATES, DUNGEON_ICON_FALLBACK)
        end,
        get = function(inst) return AzerothCompendium:GetInstanceEntrance(inst) end,
        getZone = function(inst) return AzerothCompendium:GetInstanceEntranceZoneName(inst) end,
        setWaypoint = function(inst) return AzerothCompendium:SetInstanceEntranceWaypoint(inst) end,
        title = "LID_SETENTRANCEWAYPOINT",
        label = "LID_ENTRANCE",
    },
    meetingStone = {
        getIcon = function() return MEETING_STONE_ICON end,
        get = function(inst) return AzerothCompendium:GetInstanceMeetingStone(inst) end,
        getZone = function(inst) return AzerothCompendium:GetInstanceMeetingStoneZoneName(inst) end,
        setWaypoint = function(inst) return AzerothCompendium:SetInstanceMeetingStoneWaypoint(inst) end,
        title = "LID_SETMEETINGSTONEWAYPOINT",
        label = "LID_MEETINGSTONE",
    },
}

local function CreateLocationPin(row, def)
    local pin = CreateFrame("Button", nil, row)
    pin.def = def
    pin:SetSize(LOCATION_PIN_SIZE, LOCATION_PIN_SIZE)
    pin:SetFrameLevel(row:GetFrameLevel() + 2)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints(pin)
    pin.highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    pin.highlight:SetAllPoints(pin)
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetAlpha(0.5)
    pin.badge = pin:CreateTexture(nil, "OVERLAY")
    pin.badge:SetSize(LOCATION_PIN_BADGE_SIZE, LOCATION_PIN_BADGE_SIZE)
    pin.badge:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 3, -2)
    if AzerothCompendium:AtlasExists(LOCATION_PIN_BADGE_ATLAS) then
        pin.badge:SetAtlas(LOCATION_PIN_BADGE_ATLAS)
    else
        pin.badge:SetTexture(LOCATION_PIN_BADGE_FALLBACK)
        pin.badge:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    pin:SetScript("OnClick", function(sel)
        local inst = sel:GetParent().entry
        local waypointSet, reason = sel.def.setWaypoint(inst)
        if waypointSet then
            local location = sel.def.get(inst)
            if location then AzerothCompendium:OpenWorldMapTo(location[1]) end
        elseif reason == "combat" then
            AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT"))
        end
    end)

    pin:SetScript("OnEnter", function(sel)
        SetBadgeHighlight(sel, true)
        if not AzerothCompendium:CanOpenWorldMapTo() then AzerothCompendium:AttachMapOpener(sel, function(owner) return owner.def.setWaypoint(owner:GetParent().entry) end) end
        local inst = sel:GetParent().entry
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans(sel.def.title)))
        GameTooltip:AddLine(AzerothCompendium:Trans(sel.def.label), 1, 0.82, 0)
        local zone = sel.def.getZone(inst)
        if zone then GameTooltip:AddLine(zone, 1, 1, 1) end
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_WORLDMAPWAYPOINTHINT"), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    pin:SetScript("OnLeave", function(sel)
        SetBadgeHighlight(sel, false)
        AzerothCompendium:HideGameTooltip()
    end)

    pin:Hide()
    return pin
end

local function UpdateLocationPins(row, inst)
    local right = -4
    for _, pin in ipairs(row.locationPins) do
        pin:Hide()
        if pin.def.get(inst) then
            local icon = pin.def.getIcon(inst)
            ApplyIcon(pin.icon, icon)
            ApplyIcon(pin.highlight, icon)
            pin:ClearAllPoints()
            pin:SetPoint("TOPRIGHT", row, "TOPRIGHT", right, -4)
            pin:Show()
            right = right - LOCATION_PIN_SIZE - LOCATION_PIN_SPACING
        end
    end
    return right
end

local function UpdateInstanceBackground(row, inst)
    if row.loadingScreen == nil then return end
    local fileID, layout = nil, nil
    if UsesLoadingScreens() and not inst.levelGroup then fileID, layout = GetLoadingScreen(inst) end
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
        row.questCountHover = CreateFrame("Frame", nil, row)
        row.questCountHover:SetAllPoints(row.questCount)
        row.questCountHover:SetFrameLevel(row:GetFrameLevel() + 2)
        row.questCountHover:EnableMouse(true)
        if row.questCountHover.SetMouseClickEnabled then
            row.questCountHover:SetMouseClickEnabled(false)
        else
            row.questCountHover:SetScript("OnMouseUp", function(sel)
                local parent = sel:GetParent()
                if parent.Click then parent:Click() end
            end)
        end

        row.questCountHover:SetScript("OnEnter", function(sel)
            local parent = sel:GetParent()
            if parent.LockHighlight then parent:LockHighlight() end
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_QUESTS")))
            GameTooltip:AddLine(format(AzerothCompendium:Trans("LID_QUESTSCOMPLETED"), parent.questsDone or 0, parent.questsTotal or 0), 1, 1, 1)
            GameTooltip:AddLine(AzerothCompendium:Trans("LID_QUESTSCOMPLETEDHINT"), 0.6, 0.6, 0.6, true)
            GameTooltip:Show()
        end)

        row.questCountHover:SetScript("OnLeave", function(sel)
            local parent = sel:GetParent()
            if parent.UnlockHighlight then parent:UnlockHighlight() end
            AzerothCompendium:HideGameTooltip()
        end)

        row.locationPins = {CreateLocationPin(row, LOCATION_PINS.entrance), CreateLocationPin(row, LOCATION_PINS.meetingStone)}
    end

    row.subText:Hide()
    row.typeIcon:Hide()
    row.questCount:Hide()
    row.questCountHover:Hide()
    for _, pin in ipairs(row.locationPins) do
        pin:Hide()
    end

    if UsesLoadingScreens() and not inst.levelGroup then
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
        local textRight = UpdateLocationPins(row, inst) - 2
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
        row.questsDone = done
        row.questsTotal = #quests
        row.questCountHover:Show()
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

local function AddIconRing(parent, icon, size, round)
    local ring = parent:CreateTexture(nil, "OVERLAY", nil, 1)
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetTexCoord(0, 0.6, 0, 0.6)
    ring:SetSize(size * 1.55, size * 1.55)
    ring:SetPoint("CENTER", icon, "CENTER", 0, 0)
    if round and parent.CreateMaskTexture and icon.AddMaskTexture then
        local mask = parent:CreateMaskTexture()
        mask:SetAllPoints(icon)
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        icon:AddMaskTexture(mask)
    end
    return ring
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

    row.portraitRing = AddIconRing(row.portraitFrame, row.portrait, size)
    row.bossDragon = row.portraitFrame:CreateTexture(nil, "OVERLAY", nil, 2)
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
    row.info:ClearAllPoints()
    if not UsesBossPortraits() then
        row.portraitFrame:Hide()
        row.info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row.info, "LEFT", -4, 0)
        return
    end

    row.info:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 5)
    local offsetY = (boss.all or boss.trash) and 0 or BOSS_PORTRAIT_Y
    row.portraitFrame:ClearAllPoints()
    row.portraitFrame:SetPoint("LEFT", row, "LEFT", BOSS_PORTRAIT_X, offsetY)
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
    row.text:SetPoint("LEFT", row.portraitFrame, "RIGHT", BOSS_TEXT_GAP, -offsetY)
    row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
end

local function UpdateBossRow(row, boss)
    row.entry = boss
    UpdateBossPortrait(row, boss)
    row.text:SetText(AzerothCompendium:GetBossName(boss))
    local count = boss.all and #GetAllLoot(selectedInstance) or VisibleLootCount(boss)
    if count > 0 then
        row.info:SetText(AzerothCompendium:Trans("LID_ITEMCOUNT", nil, count))
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
        local relevant = true
        if listKind == "dungeon" and type(ACOTABPC) == "table" and ACOTABPC.ONLYRELEVANT == true then
            local level = UnitLevel("player")
            relevant = inst.minLevel ~= nil and inst.maxLevel ~= nil and level >= inst.minLevel and level <= inst.maxLevel
        end
        if relevant and IsInstanceVisible(inst) and InstanceMatches(inst) then tinsert(list, inst) end
    end
    return list
end

function AzerothCompendium:GetGroupedInstanceList(list)
    if listKind ~= "dungeon" and listKind ~= "raid" then return list end
    ACOTABPC = ACOTABPC or {}
    ACOTABPC.INSTANCEGROUPS = ACOTABPC.INSTANCEGROUPS or {}
    local groups, levels, result = {}, {}, {}
    for _, inst in ipairs(list) do
        local level = floor((inst.minLevel or 0) / 10) * 10
        if groups[level] == nil then
            groups[level] = {}
            tinsert(levels, level)
        end
        tinsert(groups[level], inst)
    end
    table.sort(levels)
    for _, level in ipairs(levels) do
        local key = listKind .. ":" .. level
        local collapsed = ACOTABPC.INSTANCEGROUPS[key] == true and searchText == ""
        tinsert(result, {levelGroup = true, key = key, level = level, count = #groups[level], collapsed = collapsed, rowHeight = 26})
        if not collapsed then
            for _, inst in ipairs(groups[level]) do tinsert(result, inst) end
        end
    end
    return result
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
    if boss.all then return "all" end
    if boss.trash then return "trash" end
    if boss.npcs and boss.npcs[1] then return "npc:" .. boss.npcs[1] end
    if boss.standing ~= nil then return "standing:" .. boss.standing end
    if boss.rank ~= nil then return "rank:" .. boss.rank end
    return "name:" .. (boss.name or "")
end

local function SaveNavigationState()
    ACOTABPC = ACOTABPC or {}
    ACOTABPC["NAVIGATION"] = {
        listKind = listKind,
        middleKind = middleKind,
        detailKind = detailKind,
        instance = GetInstanceKey(selectedInstance),
        boss = GetBossKey(selectedBoss),
        mapLevel = mapLevel,
        search = compendium ~= nil and compendium.search ~= nil and compendium.search:GetText() or savedSearchText
    }
end

local function BossHasItem(boss, itemID)
    for _, loot in ipairs(boss.loot or {}) do
        if loot[1] == itemID then return true end
    end
    return false
end

local function FindWishlistSource(itemID, source)
    if type(source) == "table" and source.kind == "worldquestitems" then return nil, nil, nil end
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
            local kind, inst, boss = FindWishlistSource(itemID, source)
            local worldItem = nil
            if kind == nil or type(source) == "table" and source.kind == "worldquestitems" then
                for _, entry in ipairs(AzerothCompendium.WORLDQUESTITEMS or {}) do
                    if entry.itemID == itemID and (not IsClassicEra() or not entry.forever) then
                        worldItem = entry
                        kind, inst, boss = "worldquestitems", nil, nil
                        break
                    end
                end
            end
            if worldItem == nil and type(source) == "table" and source.kind == "worldquestitems" and (not IsClassicEra() or not source.forever) then
                worldItem = source
                kind, inst, boss = "worldquestitems", nil, nil
            end
            if worldItem then name = name or worldItem.itemName end
            local sourceText = ""
            if inst ~= nil and boss ~= nil then sourceText = AzerothCompendium:GetInstanceName(inst) .. " - " .. AzerothCompendium:GetBossName(boss) end
            if worldItem then
                sourceText = worldItem.sourceText or worldItem.source or ""
                if worldItem.questID then sourceText = AzerothCompendium:GetQuestNameByID(worldItem.questID) .. " - " .. (worldItem.zone or sourceText) end
            end
            if (not IsClassicEra() or inst ~= nil or worldItem ~= nil) and (Matches(name) or Matches(sourceText)) then
                tinsert(list, {
                    kind = kind or "worldquestitems",
                    instanceKey = GetInstanceKey(inst) or worldItem and (worldItem.zone or worldItem.source),
                    instanceName = inst and AzerothCompendium:GetInstanceName(inst) or worldItem and (worldItem.zone or worldItem.source),
                    itemID = itemID,
                    source = source,
                    sourceText = sourceText,
                    name = name
                })
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

function AzerothCompendium:GetGroupedWishlistList(list)
    ACOTABPC = ACOTABPC or {}
    ACOTABPC.WISHLISTGROUPS = ACOTABPC.WISHLISTGROUPS or {}
    local result, instances, ordered = {}, {}, {}
    local kind = type(ACOTABPC) == "table" and ACOTABPC.WISHLISTCATEGORY or "dungeon"
    for _, entry in ipairs(list) do
        if entry.kind == kind then
            local key = entry.instanceKey or "other"
            if instances[key] == nil then
                instances[key] = {name = entry.instanceName or self:Trans("LID_OTHER"), key = key, items = {}}
                tinsert(ordered, instances[key])
            end
            tinsert(instances[key].items, entry)
        end
    end
    table.sort(ordered, function(a, b)
        if a.name == b.name then return a.key < b.key end
        return Lower(a.name) < Lower(b.name)
    end)
    for _, instance in ipairs(ordered) do
        local key = kind .. ":" .. instance.key
        local collapsed = ACOTABPC.WISHLISTGROUPS[key] == true and searchText == ""
        tinsert(result, {wishlistCategory = true, key = key, collapsed = collapsed, name = instance.name, count = #instance.items, rowHeight = 26})
        if not collapsed then
            for _, entry in ipairs(instance.items) do tinsert(result, entry) end
        end
    end
    return result
end
local function GetWorldQuestItemList()
    local list = {}
    for _, entry in ipairs(AzerothCompendium.WORLDQUESTITEMS or {}) do
        if not IsClassicEra() or not entry.forever then
            local itemName = AzerothCompendium:GetItemDisplay(entry.itemID) or entry.itemName or tostring(entry.itemID)
            local questName = AzerothCompendium:GetQuestNameByID(entry.questID)
            local source = entry.source or AzerothCompendium:Trans("LID_WORLDDROPUNKNOWN")
            local sourceText = source
            if entry.zone ~= nil then sourceText = sourceText .. " - " .. entry.zone end
            if Matches(itemName) or Matches(entry.itemName) or Matches(questName) or Matches(sourceText) or Matches(entry.description) then
                tinsert(list, {
                    itemID = entry.itemID,
                    questID = entry.questID,
                    itemName = itemName,
                    questName = questName,
                    sourceText = sourceText,
                    data = entry
                })
            end
        end
    end

    table.sort(list, function(a, b)
        local aName = Lower(a.itemName or tostring(a.itemID))
        local bName = Lower(b.itemName or tostring(b.itemID))
        if aName == bName then return a.itemID < b.itemID end
        return aName < bName
    end)
    return list
end

local function UpdateTabs(tabs, active)
    for kind, button in pairs(tabs) do
        button:SetTabSelected(kind == active)
        button.Icon:SetPoint("CENTER", button, "CENTER", button.questIcon and -2 or 0, button:GetIconYOffset(kind == active))
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
    frame:ApplyCamera()
    AzerothCompendium:After(0, function() frame:ApplyCamera() end, "AzerothCompendium:ModelCamera")
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

local MapPins = {
    pool = {},
    size = 26,
    bossSize = 34,
    downIcons = {"CaveUnderground-Down", "CaveUnderground-Up"},
    upIcons = {"CaveUnderground-Up", "CaveUnderground-Down"},
    levelFallback = "Interface\\Icons\\INV_Misc_Map_01",
}

function MapPins.FindBoss(npcID, inst)
    inst = inst or selectedInstance
    if inst == nil then return nil end
    for _, boss in ipairs(inst.bosses or {}) do
        for _, id in ipairs(boss.npcs or {}) do
            if id == npcID then return boss end
        end
    end
    return nil
end

function MapPins.GetBossLevel(boss)
    MapPins.Init()
    local data = AzerothCompendium.INSTANCEMAPPINS
    if data == nil or boss == nil or boss.npcs == nil then return nil end
    for index, info in ipairs(GetInstanceMaps() or {}) do
        for _, entry in ipairs(data[info.id] or {}) do
            if entry[1] == "boss" and not MapPins.IsHidden(entry) then
                for _, id in ipairs(boss.npcs) do
                    if id == entry[4] then return index end
                end
            end
        end
    end
    return nil
end

function MapPins.AddRowButton(row)
    local button = CreateFrame("Button", nil, row)
    button:SetSize(16, 16)
    button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
    button:SetFrameLevel(row:GetFrameLevel() + 2)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(TAB_ICONS["map"].texture)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button)
    button.highlight:SetTexture(TAB_ICONS["map"].texture)
    button.highlight:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.highlight:SetBlendMode("ADD")
    button.highlight:SetAlpha(0.5)
    button:SetScript("OnClick", function(sel) MapPins.ShowBoss(sel:GetParent().entry) end)
    button:SetScript("OnEnter", function(sel)
        local maps = GetInstanceMaps() or {}
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_SHOWONMAP"))
        if #maps > 1 then GameTooltip:AddLine(GetMapLevelLabel(maps, MapPins.GetBossLevel(sel:GetParent().entry)), 1, 1, 1) end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    button:Hide()
    row.mapButton = button
end

function MapPins.UpdateRowButton(row, boss)
    row.mapButton:SetShown(MapPins.GetBossLevel(boss) ~= nil)
end

function MapPins.FindLevel(maps, artID)
    for index, info in ipairs(maps or {}) do
        if info.id == artID then return index end
    end
    return nil
end

function MapPins.GetQuestItems()
    local items = {}
    local seen = {}
    for _, quest in ipairs(AzerothCompendium:GetInstanceQuests(selectedInstance)) do
        for _, step in ipairs(AzerothCompendium:GetQuestChain(quest[1])) do
            local item = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[step[1]]
            if item ~= nil and not seen[item[1]] then
                seen[item[1]] = true
                local name = AzerothCompendium:GetItemDisplay(item[1]) or item[2] or tostring(item[1])
                tinsert(items, {format("%s (%d) - %s", name, item[1], step[2]), item[1]})
            end
        end
    end

    table.sort(items, function(a, b) return a[1] < b[1] end)
    return items
end

function MapPins.GetItemName(itemID)
    local name = AzerothCompendium:GetItemDisplay(itemID)
    if name ~= nil then return name end
    for _, item in pairs(AzerothCompendium.QUESTSTARTITEMS or {}) do
        if item[1] == itemID then return item[2] or tostring(itemID) end
    end
    return tostring(itemID)
end

function MapPins.Create(view)
    local pin = CreateFrame("Button", nil, view.viewport)
    pin:SetSize(MapPins.size, MapPins.size)
    pin:SetFrameLevel(view:GetFrameLevel() + 2)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetAlpha(0.5)
    pin.portrait = pin:CreateTexture(nil, "ARTWORK")
    pin.portrait:SetPoint("TOPLEFT", pin, "TOPLEFT", 2, -2)
    pin.portrait:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -2, 2)
    pin.ring = AddIconRing(pin, pin.portrait, MapPins.bossSize - 4)
    local scale = (MapPins.bossSize - 4) / 64
    local badgeSize = LEVEL_BADGE_SIZE * (MapPins.bossSize - 4) / BOSS_PORTRAIT_SIZE
    pin.bossDragon = pin:CreateTexture(nil, "OVERLAY", nil, 2)
    pin.bossDragon:SetSize(256 * scale, 128 * scale)
    pin.bossDragon:SetPoint("CENTER", pin, "CENTER", -54 * scale, -20 * scale)
    pin.bossDragon:Hide()
    pin.levelBadge = CreateFrame("Frame", nil, pin)
    pin.levelBadge:SetSize(badgeSize, badgeSize)
    pin.levelBadge:SetPoint("CENTER", pin, "CENTER", 19.5 * scale, -22 * scale)
    pin.levelBadge:SetFrameLevel(pin:GetFrameLevel() + 2)
    pin.levelRing = pin.levelBadge:CreateTexture(nil, "BORDER")
    pin.levelRing:SetAllPoints(pin.levelBadge)
    pin.levelFill = pin.levelBadge:CreateTexture(nil, "ARTWORK")
    pin.levelFill:SetPoint("TOPLEFT", pin.levelBadge, "TOPLEFT", 1.5, -1.5)
    pin.levelFill:SetPoint("BOTTOMRIGHT", pin.levelBadge, "BOTTOMRIGHT", -1.5, 1.5)
    pin.levelFill:SetColorTexture(0.05, 0.04, 0.03, 0.95)
    pin.levelText = pin.levelBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pin.levelText:SetPoint("CENTER", pin.levelBadge, "CENTER", 0.5, 0)
    local fontFile, _, fontFlags = pin.levelText:GetFont()
    if fontFile then pin.levelText:SetFont(fontFile, LEVEL_BADGE_FONT_SIZE - 1, fontFlags) end
    pin.levelSkull = pin.levelBadge:CreateTexture(nil, "OVERLAY")
    pin.levelSkull:SetSize(badgeSize - 5, badgeSize - 5)
    pin.levelSkull:SetPoint("CENTER", pin.levelBadge, "CENTER", 0, 0)
    pin.levelSkull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    pin.levelBadge:Hide()
    if pin.CreateMaskTexture and pin.portrait.AddMaskTexture then
        for _, texture in ipairs({pin.portrait, pin.levelRing, pin.levelFill}) do
            local mask = pin:CreateMaskTexture()
            mask:SetAllPoints(texture)
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            texture:AddMaskTexture(mask)
        end

        pin.masked = true
    end

    pin:EnableMouseWheel(true)
    pin:SetScript("OnMouseWheel", function(_, delta) MapPins.Zoom(view, delta) end)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin:SetScript("OnClick", function(sel, mouse) MapPins.OnClick(sel, mouse) end)
    pin:SetScript("OnEnter", function(sel) MapPins.OnEnter(sel) end)
    pin:SetScript("OnLeave", function(sel) MapPins.OnLeave(sel) end)
    return pin
end

function MapPins.Style(pin)
    local isBoss = pin.kind == "boss"
    local size = isBoss and MapPins.bossSize or MapPins.size
    pin:SetSize(size, size)
    local isItem = pin.kind == "item"
    pin.portrait:SetShown(isBoss or isItem)
    pin.icon:SetShown(not isBoss and not isItem)
    pin.portrait:SetTexCoord(0, 1, 0, 1)
    pin.ring:SetSize((size - 4) * 1.55, (size - 4) * 1.55)
    pin.bossDragon:Hide()
    pin.levelBadge:Hide()
    pin.ring:Hide()
    if isBoss then
        UpdateBossLevelBadge(pin, pin.boss)
        pin.ring:Show()
        pin.ring:SetVertexColor(1, 1, 1, 1)
        pin.highlight:SetTexture(nil)
        local applied = false
        if pin.boss.model ~= nil and SetPortraitTextureFromCreatureDisplayID then applied = pcall(SetPortraitTextureFromCreatureDisplayID, pin.portrait, pin.boss.model) end
        if not applied then pin.portrait:SetTexture(BOSS_PORTRAIT_FALLBACK) end
        return
    end

    if isItem then
        local _, _, _, _, texture = AzerothCompendium:GetItemDisplay(pin.entry[4])
        pin.portrait:SetTexture(texture or 134400)
        pin.portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        pin.ring:SetVertexColor(1, 1, 1, 1)
        pin.ring:Show()
        pin.highlight:SetTexture(nil)
        return
    end

    local icon = nil
    if pin.kind == "entrance" then
        icon = ResolveIcon(DUNGEON_ICON_CANDIDATES, DUNGEON_ICON_FALLBACK)
    else
        icon = ResolveIcon(pin.up and MapPins.upIcons or MapPins.downIcons, MapPins.levelFallback)
    end

    ApplyIcon(pin.icon, icon)
    ApplyIcon(pin.highlight, icon)
end

function MapPins.Layout(view)
    local w = view.art:GetWidth()
    local h = view.art:GetHeight()
    for _, pin in ipairs(MapPins.pool) do
        if pin:IsShown() then
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", view.art, "TOPLEFT", w * pin.x, -h * pin.y)
        end
    end
end

MapPins.types = {{"boss", "MAPPINS_BOSS", "BOSSPINS", {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", false, true}, {0.75, 1, 0.25, 0.5}}, {"item", "MAPPINS_ITEM", "QUESTPINS", {"Interface\\Icons\\INV_Misc_Bag_10"}}, {"entrance", "MAPPINS_ENTRANCE", "ENTRANCEPINS"}, {"level", "MAPPINS_LEVEL", "LEVELPINS"},}
function MapPins.IsEnabled(kind)
    if MapPins.debug then return true end
    for _, def in ipairs(MapPins.types) do
        if def[1] == kind then return AzerothCompendium:GetConfig(def[2], AzerothCompendium:GetConfig("MAPPINS", true)) ~= false end
    end
    return true
end

function MapPins.UpdateToggle(view)
    view.pinToggles = view.pinToggles or {}
    local maps = GetInstanceMaps()
    local anchor, point, relativePoint, anchorX, anchorY = view, "BOTTOMRIGHT", "TOPRIGHT", 0, 5
    if compendium.mapLevel and maps ~= nil and #maps > 1 then anchor, point, relativePoint, anchorX, anchorY = compendium.mapLevel, "RIGHT", "LEFT", -8, 2 end
    for index, def in ipairs(MapPins.types) do
        local button = view.pinToggles[index]
        if button == nil then
            button = CreateFrame("Button", nil, view)
            button:SetSize(20, 20)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
            local icon = def[3] == "ENTRANCEPINS" and ResolveIcon(DUNGEON_ICON_CANDIDATES, DUNGEON_ICON_FALLBACK) or def[3] == "LEVELPINS" and ResolveIcon(MapPins.upIcons, MapPins.levelFallback) or def[4]
            ApplyIcon(button.icon, icon)
            ApplyIcon(button.highlight, icon)
            if def[5] then
                button.icon:SetTexCoord(unpack(def[5]))
                button.highlight:SetTexCoord(unpack(def[5]))
            end

            button.highlight:SetBlendMode("ADD")
            button.highlight:SetAlpha(0.4)
            button.ring = AddIconRing(button, button, 20)
            button.ring:SetDesaturated(true)
            if button.CreateMaskTexture and button.icon.AddMaskTexture then
                local mask = button:CreateMaskTexture()
                mask:SetAllPoints(button)
                mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                button.icon:AddMaskTexture(mask)
                button.highlight:AddMaskTexture(mask)
            end

            button:SetScript("OnClick", function(sel)
                AzerothCompendium:SetConfig(def[2], AzerothCompendium:GetConfig(def[2], AzerothCompendium:GetConfig("MAPPINS", true)) == false)
                MapPins.Update(view)
                if GameTooltip:IsOwned(sel) then sel:GetScript("OnEnter")(sel) end
            end)

            button:SetScript("OnEnter", function(sel)
                GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
                local hidden = AzerothCompendium:GetConfig(def[2], AzerothCompendium:GetConfig("MAPPINS", true)) == false
                GameTooltip:SetText(AzerothCompendium:Trans((hidden and "LID_SHOW" or "LID_HIDE") .. def[3]))
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
            view.pinToggles[index] = button
        end

        button:ClearAllPoints()
        button:SetPoint(point, anchor, relativePoint, anchorX - 4 - (index - 1) * 30, anchorY)
        local enabled = MapPins.IsEnabled(def[1])
        if enabled then
            button.ring:SetVertexColor(0.2, 1, 0.2)
        else
            button.ring:SetVertexColor(1, 0.2, 0.2)
        end

        button.icon:SetDesaturated(not enabled)
        button.icon:SetAlpha(enabled and 1 or 0.5)
        button:SetShown(view.info ~= nil)
        button:SetFrameLevel((view.pinTopLevel or view:GetFrameLevel()) + 1)
    end

    local last = view.pinToggles[#MapPins.types]
    if last and compendium.detailCount and view:IsShown() then
        compendium.detailCount:ClearAllPoints()
        compendium.detailCount:SetPoint("RIGHT", last, "LEFT", -8, -2)
    end
end

function MapPins.Update(view)
    MapPins.Init()
    local info = view.info
    local data = info and AzerothCompendium.INSTANCEMAPPINS and AzerothCompendium.INSTANCEMAPPINS[info.id] or nil
    local maps = GetInstanceMaps()
    local count = 0
    for _, entry in ipairs(data or {}) do
        local kind = entry[1]
        local boss = nil
        local level = nil
        if kind == "boss" then
            boss = MapPins.FindBoss(entry[4])
        elseif kind == "level" then
            level = MapPins.FindLevel(maps, entry[4])
        end

        if MapPins.IsEnabled(kind) and not MapPins.IsHidden(entry) and (kind == "entrance" or kind == "item" and type(entry[4]) == "number" or boss ~= nil or level ~= nil) then
            count = count + 1
            local pin = MapPins.pool[count]
            if pin == nil then
                pin = MapPins.Create(view)
                MapPins.pool[count] = pin
            end

            local pinFrameLevel = view.viewport:GetFrameLevel() + 2 + count * 3
            if kind == "boss" then pinFrameLevel = pinFrameLevel + #data * 3 end
            pin:SetFrameLevel(pinFrameLevel)
            pin.levelBadge:SetFrameLevel(pinFrameLevel + 2)
            pin.kind = kind
            pin.x = entry[2]
            pin.y = entry[3]
            pin.boss = boss
            pin.level = level
            pin.up = entry[5] == true
            pin.entry = entry
            pin:SetAlpha(entry.deleted and 0.25 or MapPins.debug and MapPins.selected ~= nil and MapPins.selected ~= entry and 0.5 or 1)
            MapPins.Style(pin)
            pin:Show()
        end
    end

    for i = count + 1, #MapPins.pool do
        MapPins.pool[i]:Hide()
    end

    view.pinTopLevel = view.viewport:GetFrameLevel() + 4 + #(data or {}) * 6
    MapPins.UpdateToggle(view)
    MapPins.Layout(view)
    MapPins.DebugRefresh()
end

function MapPins.OnEnter(pin)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    if pin.kind == "boss" then
        pin.ring:SetVertexColor(1, 1, 1, 1)
        GameTooltip:SetText(AzerothCompendium:GetBossName(pin.boss))
        if pin.boss.level ~= nil then GameTooltip:AddLine(AzerothCompendium:Trans("LID_LEVEL", nil, pin.boss.level), 1, 1, 1) end
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_MAPPINBOSSHINT"), 0.6, 0.6, 0.6)
    elseif pin.kind == "item" then
        GameTooltip:SetItemByID(pin.entry[4])
    elseif pin.kind == "level" then
        GameTooltip:SetText(GetMapLevelLabel(GetInstanceMaps() or {}, pin.level))
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_MAPPINLEVELHINT"), 0.6, 0.6, 0.6)
    else
        GameTooltip:SetText(AzerothCompendium:Trans("LID_ENTRANCE"))
        if AzerothCompendium:GetInstanceEntrance(selectedInstance) then GameTooltip:AddLine(AzerothCompendium:Trans("LID_WORLDMAPWAYPOINTHINT"), 0.6, 0.6, 0.6) end
    end

    GameTooltip:Show()
end

function MapPins.OnLeave(pin)
    if pin.kind == "boss" then pin.ring:SetVertexColor(1, 1, 1, 1) end
    AzerothCompendium:HideGameTooltip()
end

local function LayoutMapArt()
    local view = compendium.mapView
    local info = view.info
    if info == nil then return end
    local w = view.viewport:GetWidth()
    local h = view.viewport:GetHeight()
    if w == nil or h == nil or w <= 0 or h <= 0 then return end
    local ratio = info.height / info.width
    local width = w
    local height = w * ratio
    if height > h then
        height = h
        width = h / ratio
    end

    width = width * (view.zoom or 1)
    height = height * (view.zoom or 1)
    local maxX = math.max(0, (width - w) / 2)
    local maxY = math.max(0, (height - h) / 2)
    view.offsetX = math.max(-maxX, math.min(maxX, view.offsetX or 0))
    view.offsetY = math.max(-maxY, math.min(maxY, view.offsetY or 0))
    view.art:ClearAllPoints()
    view.art:SetPoint("CENTER", view.viewport, "CENTER", view.offsetX, view.offsetY)
    view.art:SetSize(width, height)
    MapPins.Layout(view)
end

function MapPins.Zoom(view, delta)
    if view.info == nil then return end
    local old = view.zoom or 1
    local zoom = math.max(1, math.min(4, old + delta * 0.25))
    if zoom == old then return end
    local x, y = GetCursorPosition()
    local scale = view:GetEffectiveScale()
    local cx, cy = view.viewport:GetCenter()
    x, y = x / scale - cx, y / scale - cy
    local factor = zoom / old
    view.offsetX = x - (x - (view.offsetX or 0)) * factor
    view.offsetY = y - (y - (view.offsetY or 0)) * factor
    view.zoom = zoom
    LayoutMapArt()
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
        MapPins.Update(view)
        return
    end

    if mapLevel > #maps then mapLevel = 1 end
    local info = maps[mapLevel]
    if view.info ~= info then
        view.zoom = 1
        view.offsetX, view.offsetY = 0, 0
        view.dragX, view.dragY = nil, nil
    end

    view.info = info
    view.art:SetTexture(info.file)
    view.art:SetTexCoord(0, info.width / info.fileWidth, 0, info.height / info.fileHeight)
    view.art:Show()
    view.empty:Hide()
    compendium.detailCount:SetText(info.source and format(AzerothCompendium:Trans("LID_MAPSOURCE"), info.source) or "")
    LayoutMapArt()
    MapPins.Update(view)
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
    SaveNavigationState()
end

local function ShowMapLevelMenu(owner)
    local maps = GetInstanceMaps()
    if maps == nil then return end
    local entries = {}
    for i in ipairs(maps) do
        tinsert(entries, {
            text = GetMapLevelLabel(maps, i),
            checked = function() return mapLevel == i end,
            func = function() SelectMapLevel(i) end
        })
    end

    AzerothCompendium:ShowContextMenu(owner, entries)
end

local function RefreshDetail()
    if compendium == nil then return end
    compendium.detailCount:ClearAllPoints()
    compendium.detailCount:SetPoint("BOTTOMRIGHT", compendium.loot, "TOPRIGHT", 0, 6)
    if middleKind == "map" and (listKind == "dungeon" or listKind == "raid") then
        compendium.loot:Hide()
        compendium.spells:Hide()
        if compendium.model then compendium.model:Hide() end
        for _, button in pairs(compendium.detailTabs) do
            button:Hide()
        end

        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        compendium.empty:Hide()
        compendium.detailTitle:SetText("")
        compendium.detailCount:SetText("")
        UpdateMapView()
        return
    end

    if middleKind == "quests" and (listKind == "dungeon" or listKind == "raid") then
        compendium.loot:Hide()
        compendium.spells:Hide()
        if compendium.model then compendium.model:Hide() end
        for _, button in pairs(compendium.detailTabs) do
            button:Hide()
        end

        compendium.classFilter:Hide()
        compendium.classFilterLabel:Hide()
        compendium.empty:Hide()
        compendium.detailTitle:SetText("")
        compendium.detailCount:SetText(AzerothCompendium:Trans("LID_QUESTCOUNT", nil, CountInstanceQuests(compendium.questTree.graph)))
        return
    end

    compendium.questTree:Hide()
    compendium.detailTitle:Show()
    compendium.detailCount:Show()
    local count = 0
    local showCount = false
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
        showCount = true
        compendium.detailCount:SetText("")
        compendium.classFilter:Show()
        compendium.classFilterLabel:Show()
        empty = count == 0
    elseif detailKind == "spells" then
        compendium.spells:SetData(GetSpellList())
        compendium.spells:Show()
        compendium.loot:Hide()
        if compendium.model then compendium.model:Hide() end
        count = #compendium.spells.data
        showCount = true
        compendium.detailCount:SetText("")
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

    local title = selectedBoss ~= nil and AzerothCompendium:GetBossName(selectedBoss) or ""
    if showCount then title = strtrim(title .. " (" .. AzerothCompendium:Trans(detailKind == "spells" and "LID_ABILITYCOUNT" or "LID_ITEMCOUNT", nil, count) .. ")") end
    compendium.detailTitle:SetText(title)
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
    SaveNavigationState()
end

local function RefreshBosses()
    if compendium == nil then return end
    local showMiddleTabs = listKind == "dungeon" or listKind == "raid"
    if not showMiddleTabs then middleKind = "bosses" end
    for _, tab in pairs(compendium.middleTabs) do
        if showMiddleTabs then
            tab:Show()
        else
            tab:Hide()
        end
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
    local restoredIndex = nil
    if selectedBoss == nil and restoreBossKey ~= nil then
        for index, boss in ipairs(list) do
            if GetBossKey(boss) == restoreBossKey then
                selectedBoss = boss
                restoredIndex = index
                break
            end
        end
    end

    restoreBossKey = nil
    local found = false
    for _, boss in ipairs(list) do
        if boss == selectedBoss then found = true end
    end

    if not found then selectedBoss = list[1] end
    compendium.bosses:Refresh()
    if restoredIndex ~= nil then compendium.bosses:ScrollToIndex(restoredIndex) end
    if selectedInstance ~= nil then
        compendium.bossTitle:SetText(AzerothCompendium:GetInstanceName(selectedInstance))
    else
        compendium.bossTitle:SetText("")
    end

    if showMiddleTabs then
        compendium.bossTitle:Hide()
    else
        compendium.bossTitle:Show()
    end

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

    compendium.instances.fullList = list
    compendium.instances:SetData(AzerothCompendium:GetGroupedInstanceList(list))
    local restoredIndex = nil
    if selectedInstance == nil and restoreInstanceKey ~= nil then
        for index, inst in ipairs(list) do
            if GetInstanceKey(inst) == restoreInstanceKey then
                selectedInstance = inst
                restoredIndex = index
                mapInstance = inst
                break
            end
        end
    end

    restoreInstanceKey = nil
    local found = false
    for _, inst in ipairs(list) do
        if inst == selectedInstance then found = true end
    end

    if not found then
        selectedInstance = list[1]
        selectedBoss = nil
    end

    compendium.instances:Refresh()
    if compendium.updateInstanceSelection then compendium.updateInstanceSelection() end
    if restoredIndex ~= nil then
        for index, inst in ipairs(compendium.instances.data) do
            if inst == selectedInstance then compendium.instances:ScrollToIndex(index) end
        end
    end
    RefreshBosses()
end

local function OnInstanceClick(inst)
    selectedInstance = inst
    selectedBoss = nil
    mapLevel = 1
    SaveNavigationState()
    compendium.instances:Refresh()
    if compendium.updateInstanceSelection then compendium.updateInstanceSelection() end
    if compendium.instancePopup then compendium.instancePopup:Hide() end
    RefreshBosses()
end

local function OnBossClick(boss)
    selectedBoss = boss
    SaveNavigationState()
    compendium.bosses:Refresh()
    RefreshDetail()
end

function MapPins.OnClick(pin, mouse)
    if mouse == "RightButton" then
        if MapPins.debug then
            AzerothCompendium:HideGameTooltip()
            MapPins.selected = pin.entry
            MapPins.Update(compendium.mapView)
        end
        return
    end

    if pin.kind == "item" then
        for _, node in ipairs(AzerothCompendium:GetInstanceQuestGraph(selectedInstance)) do
            local item = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[node.id]
            if item ~= nil and item[1] == pin.entry[4] then
                AzerothCompendium:HideGameTooltip()
                middleKind = "quests"
                if searchText ~= "" then compendium.search:SetText("") end
                SaveNavigationState()
                RefreshBosses()
                compendium.questTree:FocusQuest(node.id)
                return
            end
        end
        return
    end

    if pin.kind == "entrance" then
        local waypointSet, reason = AzerothCompendium:SetInstanceEntranceWaypoint(selectedInstance)
        if waypointSet then
            local location = AzerothCompendium:GetInstanceEntrance(selectedInstance)
            if location then AzerothCompendium:OpenWorldMapTo(location[1]) end
        elseif reason == "combat" then
            AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT"))
        end
        return
    end

    AzerothCompendium:HideGameTooltip()
    if pin.kind == "level" then
        SelectMapLevel(pin.level)
        return
    end

    middleKind = "bosses"
    selectedBoss = pin.boss
    SaveNavigationState()
    RefreshBosses()
    for index, boss in ipairs(GetBossList()) do
        if boss == selectedBoss then compendium.bosses:ScrollToIndex(index) end
    end
end

function MapPins.ShowBoss(boss)
    local level = MapPins.GetBossLevel(boss)
    if level == nil then return end
    AzerothCompendium:HideGameTooltip()
    middleKind = "map"
    selectedBoss = boss
    mapInstance = selectedInstance
    mapLevel = level
    SaveNavigationState()
    RefreshBosses()
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

    if row.boss ~= nil then GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_DROPPEDBY"), AzerothCompendium:GetBossName(row.boss))), 1, 0.82, 0) end
    if row.worldQuestItem ~= nil then
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_STARTSQUEST"), row.worldQuestItem.questName)), 1, 0.82, 0)
        GameTooltip:AddLine(AzerothCompendium:GetCompendiumTooltipLabel(format(AzerothCompendium:Trans("LID_SOURCE"), row.worldQuestItem.sourceText)), 1, 1, 1)
    end

    if not row.isWishlist and row.boss ~= nil and MapPins.GetBossLevel(row.boss) ~= nil then
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans("LID_SHOWBOSSONMAP"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    elseif row.isWishlist then
        GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_LEFTCLICK") .. ":"), AzerothCompendium:Trans("LID_GOTOSOURCE"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    end

    GameTooltip:AddDoubleLine(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_RIGHTCLICK") .. ":"), AzerothCompendium:Trans(AzerothCompendium:IsWishlisted(row.itemID) and "LID_REMOVEFROMWISHLIST" or "LID_ADDTOWISHLIST"), 0.9, 0.9, 0.9, 1, 0.82, 0)
    GameTooltip:Show()
end

local function ShowWishlistMenu(owner, itemID, source)
    itemID = tonumber(itemID)
    if itemID == nil then return end
    if owner.worldQuestItem then
        local entry = owner.worldQuestItem
        local data = entry.data or {}
        source = {kind = "worldquestitems", questID = data.questID or entry.questID, itemName = data.itemName or entry.itemName, zone = data.zone, sourceText = entry.sourceText, forever = data.forever}
    end
    local listed = AzerothCompendium:IsWishlisted(itemID)
    local label = AzerothCompendium:Trans(listed and "LID_REMOVEFROMWISHLIST" or "LID_ADDTOWISHLIST")
    local action = function()
        if listed then
            AzerothCompendium:SetWishlistItem(itemID, nil)
        else
            AzerothCompendium:SetWishlistItem(itemID, source or {})
        end
    end

    AzerothCompendium:ShowContextMenu(owner, {
        {
            text = label,
            func = action
        }
    }, "cursor")
end

local function CreateLootRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.iconRing = AddIconRing(row, row.icon, 26, true)
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

        if button == "LeftButton" and sel.boss ~= nil and MapPins.GetBossLevel(sel.boss) ~= nil and not (IsModifiedClick and IsModifiedClick()) then
            MapPins.ShowBoss(sel.boss)
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
    row.isWishlist = true
    row.collapseIcon = row:CreateTexture(nil, "OVERLAY")
    row.collapseIcon:SetSize(16, 16)
    row.collapseIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.collapseIcon:Hide()
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.iconRing = AddIconRing(row, row.icon, 26, true)
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
        if sel.entry == nil then return end
        if sel.entry.wishlistCategory then
            if button ~= "LeftButton" then return end
            ACOTABPC.WISHLISTGROUPS[sel.entry.key] = not ACOTABPC.WISHLISTGROUPS[sel.entry.key]
            compendium.wishlist.data = AzerothCompendium:GetGroupedWishlistList(compendium.wishlist.fullList or {})
            compendium.wishlist:Refresh()
            return
        end
        if button == "RightButton" then
            ShowWishlistMenu(sel, sel.itemID, nil)
            return
        end

        if NavigateToWishlistItem then NavigateToWishlistItem(sel.entry) end
    end)

    function row:Update(entry)
        self.entry = entry
        self.itemID = entry.itemID
        self.boss = nil
        self.link = nil
        self.icon:SetShown(not entry.wishlistCategory)
        self.iconRing:SetShown(not entry.wishlistCategory)
        self.source:SetShown(not entry.wishlistCategory)
        self.collapseIcon:SetShown(entry.wishlistCategory == true)
        self.name:ClearAllPoints()
        if entry.wishlistCategory then
            self.selected:Hide()
            self.collapseIcon:SetTexture(entry.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            self.name:SetPoint("LEFT", self.collapseIcon, "RIGHT", 4, 0)
            self.name:SetPoint("RIGHT", self, "RIGHT", -8, 0)
            self.name:SetText(entry.name .. " (" .. entry.count .. ")")
            self.name:SetTextColor(1, 0.82, 0)
            return
        end
        self.name:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 8, -1)
        self.name:SetPoint("RIGHT", self, "RIGHT", -8, 0)
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

local function CreateWorldQuestItemRow(scroller)
    local row = CreateFrame("Button", nil, scroller)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    StyleRow(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.iconRing = AddIconRing(row, row.icon, 26, true)
    row.pin = CreateFrame("Button", nil, row)
    row.pin:SetSize(28, 28)
    row.pin:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.pin.icon = row.pin:CreateTexture(nil, "ARTWORK")
    row.pin.icon:SetAllPoints(row.pin)
    row.pin.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    row.pin.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.pin.badge = row.pin:CreateTexture(nil, "OVERLAY")
    row.pin.badge:SetSize(LOCATION_PIN_BADGE_SIZE, LOCATION_PIN_BADGE_SIZE)
    row.pin.badge:SetPoint("BOTTOMRIGHT", row.pin, "BOTTOMRIGHT", 3, -2)
    if AzerothCompendium:AtlasExists(LOCATION_PIN_BADGE_ATLAS) then
        row.pin.badge:SetAtlas(LOCATION_PIN_BADGE_ATLAS)
    else
        row.pin.badge:SetTexture(LOCATION_PIN_BADGE_FALLBACK)
        row.pin.badge:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetPoint("RIGHT", row.pin, "LEFT", -8, 0)
    row.name:SetJustifyH("LEFT")
    row.detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.detail:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 1)
    row.detail:SetPoint("RIGHT", row.pin, "LEFT", -8, 0)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(false)
    row:SetScript("OnEnter", function(sel) ShowItemTooltip(sel) end)
    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel, button)
        if button == "RightButton" then
            ShowWishlistMenu(sel, sel.itemID, {kind = "worldquestitems"})
            return
        end

        if sel.link ~= nil and HandleModifiedItemClick then HandleModifiedItemClick(sel.link) end
    end)

    row.pin:SetScript("OnClick", function(sel)
        local entry = sel:GetParent().worldQuestItem
        if entry == nil then return end
        local data = entry.data
        local waypointSet, reason = AzerothCompendium:SetMapWaypoint(data.mapID, data.x, data.y)
        if waypointSet then
            AzerothCompendium:OpenWorldMapTo(data.mapID)
        elseif reason == "combat" then
            AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT"))
        end
    end)

    row.pin:SetScript("OnEnter", function(sel)
        SetBadgeHighlight(sel, true)
        if not AzerothCompendium:CanOpenWorldMapTo() then
            AzerothCompendium:AttachMapOpener(sel, function(owner)
                local entry = owner:GetParent().worldQuestItem
                if entry == nil then return false end
                return AzerothCompendium:SetMapWaypoint(entry.data.mapID, entry.data.x, entry.data.y)
            end)
        end

        local entry = sel:GetParent().worldQuestItem
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_SETITEMSOURCEWAYPOINT")))
        if entry ~= nil and entry.data.zone ~= nil then GameTooltip:AddLine(entry.data.zone, 1, 1, 1) end
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_WORLDMAPWAYPOINTHINT"), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    row.pin:SetScript("OnLeave", function(sel)
        SetBadgeHighlight(sel, false)
        AzerothCompendium:HideGameTooltip()
    end)

    function row:Update(entry)
        self.worldQuestItem = entry
        self.itemID = entry.itemID
        local name, link, quality, _, icon = AzerothCompendium:GetItemDisplay(entry.itemID)
        self.link = link
        self.icon:SetTexture(icon or 134400)
        self.name:SetText(name or entry.itemName or AzerothCompendium:Trans("LID_LOADING"))
        self.detail:SetText(format(AzerothCompendium:Trans("LID_WORLDQUESTITEMDETAIL"), entry.questName, entry.sourceText))
        local color = nil
        if quality ~= nil and ITEM_QUALITY_COLORS ~= nil then color = ITEM_QUALITY_COLORS[quality] end
        if color ~= nil then
            self.name:SetTextColor(color.r, color.g, color.b)
        else
            self.name:SetTextColor(0.6, 0.6, 0.6)
        end

        local data = entry.data
        if data.mapID ~= nil and data.x ~= nil and data.y ~= nil then
            self.pin:Show()
            self.name:SetPoint("RIGHT", self.pin, "LEFT", -8, 0)
            self.detail:SetPoint("RIGHT", self.pin, "LEFT", -8, 0)
        else
            self.pin:Hide()
            self.name:SetPoint("RIGHT", self, "RIGHT", -8, 0)
            self.detail:SetPoint("RIGHT", self, "RIGHT", -8, 0)
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

local function CreateTabButton(parent, label, iconInfo, onClick)
    local button = CreateFrame("Button", nil, parent, "TabSystemButtonArtTemplate")
    button:SetSize(button.Icon:GetWidth() + 8, 32)
    button:SetFrameLevel(parent:GetFrameLevel() + 4)
    button.isTabOnTop = true
    button:HandleRotation()
    button.squareMode = true
    for _, texture in ipairs(button.RotatedTextures) do
        texture:Hide()
    end

    button.chrome = CreateFrame("Frame", nil, parent)
    button.chrome:SetAllPoints(button)
    button.chrome:SetFrameLevel(parent:GetFrameLevel())
    button.chrome:EnableMouse(false)
    button.chrome:Hide()
    for _, def in ipairs({{"SquareBackground", "spellbook-Tab-Frame-C60", 1}, {"SquareBackgroundActive", "spellbook-Tab-Frame-Glow-C60", 1}, {"SquareBackgroundActiveGlow", "spellbook-Tab-Frame-glow-gradient-C60", 0},}) do
        local texture = button[def[1]]
        texture:SetParent(button.chrome)
        texture:SetDrawLayer("ARTWORK", 1)
        texture:ClearAllPoints()
        texture:SetPoint("BOTTOM", button, "BOTTOM", 0, def[3])
        texture:SetAtlas(def[2], true)
    end

    button.Icon:SetParent(button.chrome)
    button.Icon:SetDrawLayer("ARTWORK", 0)
    button.IconMask:SetParent(button.chrome)
    button.questIcon = iconInfo == TAB_ICONS.quests
    button.Icon:SetTexture(iconInfo.texture)
    if iconInfo.texCoords then
        button.Icon:SetTexCoord(unpack(iconInfo.texCoords))
    else
        button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    button.Icon:Show()
    button.IconMask:Show()
    button.Text:Hide()
    button:SetTabSelected(false)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans(label))
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    button:SetScript("OnShow", function(sel) sel.chrome:Show() end)
    button:SetScript("OnHide", function(sel) sel.chrome:Hide() end)
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

local function ShowFlavorMenu(owner)
    AzerothCompendium:ShowContextMenu(owner, {
        {
            text = "Classic Era",
            checked = function() return AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA end,
            func = function() AzerothCompendium:SetFlavor(FLAVOR_CLASSIC_ERA) end
        },
        {
            text = "Forever",
            checked = function() return AzerothCompendium:GetFlavor() == FLAVOR_FOREVER end,
            func = function() AzerothCompendium:SetFlavor(FLAVOR_FOREVER) end
        }
    })
end

local function CreateFlavorControl(parent)
    if AzerothCompendium:CheckTemplates("SettingsDropdownWithButtonsTemplate") then
        local control = CreateFrame("Frame", "AzerothCompendiumFlavorControl", parent, "SettingsDropdownWithButtonsTemplate")
        control:SetPoint("LEFT", parent, "TOPLEFT", 59, -14)
        control:SetWidth(190)
        control.Dropdown:SetWidth(120)
        local function SelectFlavor(value)
            AzerothCompendium:SetFlavor(value)
        end

        local steppers = AzerothCompendium:SetupDropdownSteppers(control, function() SelectFlavor(FLAVOR_CLASSIC_ERA) end, function() SelectFlavor(FLAVOR_FOREVER) end, true)
        control.Dropdown:SetupMenu(function(_, rootDescription)
            rootDescription:CreateTitle(AzerothCompendium:Trans("LID_FLAVOR"))
            rootDescription:CreateButton("Classic Era", function() SelectFlavor(FLAVOR_CLASSIC_ERA) end)
            rootDescription:CreateButton("Forever", function() SelectFlavor(FLAVOR_FOREVER) end)
        end)

        parent.flavorControl = control
        parent.flavorDropdown = control.Dropdown
        parent.updateFlavorSteppers = function()
            local classic = AzerothCompendium:GetFlavor() == FLAVOR_CLASSIC_ERA
            steppers:SetEnabled(not classic, classic)
        end

        control:HookScript("OnShow", parent.updateFlavorSteppers)
    else
        local button = CreateTemplated("Button", "AzerothCompendiumFlavorDropdown", parent, {"UIPanelButtonTemplate"})
        button:SetSize(190, 22)
        button:SetPoint("LEFT", parent, "TOPLEFT", 59, -14)
        button:SetScript("OnClick", function(sel) ShowFlavorMenu(sel) end)
        local arrow = button:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", button, "RIGHT", -3, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
        parent.flavorDropdown = button
    end

    AzerothCompendium:SetDropdownText(parent.flavorDropdown, GetFlavorText())
    if parent.updateFlavorSteppers then parent.updateFlavorSteppers() end
end

local function SetFrameTitle(frame, text)
    if type(frame.SetTitle) == "function" then pcall(frame.SetTitle, frame, text) end
    local name = frame:GetName()
    local title = type(frame.TitleContainer) == "table" and frame.TitleContainer.TitleText or frame.TitleText or name and _G[name .. "TitleText"]
    if title == nil then
        title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("TOP", frame, "TOP", 0, -6)
    end

    title:SetText(text)
    local points = {}
    for index = 1, title:GetNumPoints() do
        points[index] = {title:GetPoint(index)}
    end

    title:ClearAllPoints()
    for _, point in ipairs(points) do
        title:SetPoint(point[1], point[2], point[3], point[4], point[5] + 1)
    end
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
        if frame.SavePosition then frame:SavePosition() end
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
    AzerothCompendium:OnLanguage(function()
        tab.tooltip = AzerothCompendium:Trans(label)
        tab.tooltipText = tab.tooltip
    end)

    tab:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:GetCompendiumTooltipLabel(sel.tooltip))
        GameTooltip:Show()
    end)

    tab:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    if large then
        tab:EnableMouse(true)
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside) if button == "LeftButton" and upInside then onClick() end end)
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
    function frame:ApplyCamera()
        if self.RefreshCamera then pcall(self.RefreshCamera, self) end
        if self.SetCamDistanceScale then pcall(self.SetCamDistanceScale, self, self.zoom or 1) end
        if self.SetRotation then pcall(self.SetRotation, self, self.rotation or 0) end
    end

    pcall(frame.SetScript, frame, "OnModelLoaded", function(sel) sel:ApplyCamera() end)
    frame:SetScript("OnSizeChanged", function(sel) sel:ApplyCamera() end)
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

local function CreateScaleSlider(parent, target)
    local value = NormalizeScale(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1))
    local function ApplyScale(scale)
        scale = NormalizeScale(scale)
        target:SetScale(scale)
        if target.SavePosition then target:SavePosition() end
        AzerothCompendium:SetConfig("COMPENDIUMSCALE", scale)
    end

    local ok, slider = pcall(CreateFrame, "Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    if ok and slider ~= nil and type(slider.Init) == "function" and type(slider.RegisterCallback) == "function" then
        slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 16, 3)
        slider:SetSize(150, 25)
        local formatters = {}
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then formatters[MinimalSliderWithSteppersMixin.Label.Right] = function(scale) return format("%d%%", floor(NormalizeScale(scale) * 100 + 0.5)) end end
        slider:Init(value, SCALE_MIN, SCALE_MAX, (SCALE_MAX - SCALE_MIN) / SCALE_STEP, formatters)
        local pendingScale = value
        slider:RegisterCallback("OnValueChanged", function(_, scale)
            pendingScale = NormalizeScale(scale)
            if slider.InteractionFlags == nil or not slider.InteractionFlags:IsAnySet() then ApplyScale(pendingScale) end
        end, parent)

        slider.Slider:HookScript("OnMouseUp", function() ApplyScale(pendingScale) end)
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

    slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 20, 7)
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

local function CreateSettingsPanel()
    local panel = CreateFrame("Frame", nil, compendium)
    AddContentBorder(panel)
    panel:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -70)
    panel:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    panel:Hide()
    compendium.settingsPanel = panel
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    local labels = {}
    for index = 1, 3 do
        labels[index] = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        labels[index]:SetPoint("LEFT", panel, "TOPLEFT", 16, -24 - index * 38)
    end

    local function GetLanguageTitle()
        local text = AzerothCompendium:Trans("LID_LANGUAGE")
        if text ~= "Language" then text = text .. " / Language" end
        return text
    end

    local dropdown = nil
    local templated = AzerothCompendium:CheckTemplates("WowStyle1DropdownTemplate")
    if templated then
        dropdown = CreateTemplated("DropdownButton", nil, panel, {"WowStyle1DropdownTemplate"})
        dropdown:SetupMenu(function(_, rootDescription)
            rootDescription:CreateTitle(GetLanguageTitle())
            for _, info in ipairs(AzerothCompendium.LANGUAGES) do
                rootDescription:CreateRadio(info[1], function() return AzerothCompendium:GetLanguage() == info[2] end, function() AzerothCompendium:SetLanguage(info[2]) end)
            end
        end)
    else
        dropdown = CreateTemplated("Button", nil, panel, {"UIPanelButtonTemplate"})
        dropdown:SetScript("OnClick", function(sel) MapPins.ShowMenu(sel, AzerothCompendium.LANGUAGES, AzerothCompendium:GetLanguage(), function(lang) AzerothCompendium:SetLanguage(lang) end) end)
        local arrow = dropdown:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", dropdown, "RIGHT", -3, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    end

    dropdown:SetSize(190, 22)
    dropdown:SetPoint("LEFT", labels[1], "LEFT", 190, 0)
    local flavor = compendium.flavorControl or compendium.flavorDropdown
    flavor:SetParent(panel)
    flavor:ClearAllPoints()
    flavor:SetPoint("LEFT", labels[2], "LEFT", 190, 0)
    CreateScaleSlider(panel, compendium)
    panel.scaleSlider:ClearAllPoints()
    panel.scaleSlider:SetPoint("LEFT", labels[3], "LEFT", 190, 0)
    AzerothCompendium:OnLanguage(function()
        title:SetText(AzerothCompendium:Trans("LID_SETTINGS"))
        labels[1]:SetText(GetLanguageTitle() .. ":")
        labels[2]:SetText(AzerothCompendium:Trans("LID_FLAVOR") .. ":")
        labels[3]:SetText(AzerothCompendium:Trans("LID_SCALE") .. ":")
        if not templated and dropdown.SetText then dropdown:SetText(AzerothCompendium:GetLanguageName()) end
    end)
end

local function SetSpecialMode(mode)
    if compendium == nil then return end
    local enabled = mode ~= nil
    if compendium.instancePopup then compendium.instancePopup:Hide() end
    local regular = {compendium.instanceControl, compendium.bossTitle, compendium.bosses, compendium.questTree, compendium.mapView, compendium.mapLevel, compendium.loot, compendium.spells, compendium.detailCount, compendium.detailTitle, compendium.classFilter, compendium.classFilterLabel, compendium.empty}
    if compendium.model then tinsert(regular, compendium.model) end
    for _, tab in pairs(compendium.detailTabs or {}) do
        tinsert(regular, tab)
    end

    for _, tab in pairs(compendium.middleTabs or {}) do
        tinsert(regular, tab)
    end

    for _, frame in ipairs(regular) do
        if enabled then
            frame:Hide()
        else
            frame:Show()
        end
    end

    if compendium.settingsPanel then compendium.settingsPanel:SetShown(mode == "settings") end
    for _, tab in pairs(compendium.wishlistTabs or {}) do tab:SetShown(mode == "wishlist") end
    if compendium.wishlist then
        if mode == "wishlist" then
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

    if compendium.worldQuestItems then
        if mode == "worldquestitems" then
            compendium.worldQuestItems:Show()
            compendium.worldQuestItemsTitle:Show()
            compendium.worldQuestItemsCount:Show()
        else
            compendium.worldQuestItems:Hide()
            compendium.worldQuestItemsTitle:Hide()
            compendium.worldQuestItemsCount:Hide()
            compendium.worldQuestItemsEmpty:Hide()
        end
    end
end

local function RefreshWishlistView()
    if compendium == nil or compendium.wishlist == nil then return end
    SetSpecialMode("wishlist")
    local list = GetWishlistList()
    compendium.wishlist.fullList = list
    compendium.wishlist:SetData(AzerothCompendium:GetGroupedWishlistList(list))
    local kind = type(ACOTABPC) == "table" and ACOTABPC.WISHLISTCATEGORY or "dungeon"
    local count = 0
    for _, entry in ipairs(list) do
        if entry.kind == kind then count = count + 1 end
    end
    UpdateTabs(compendium.wishlistTabs, kind)
    compendium.wishlistCount:SetText(AzerothCompendium:Trans("LID_ITEMCOUNT", nil, count))
    if count == 0 then
        compendium.wishlistEmpty:Show()
    else
        compendium.wishlistEmpty:Hide()
    end
end

function AzerothCompendium:CreateWishlistTabs()
    ACOTABPC = ACOTABPC or {}
    local pvpIcon = "Interface\\Icons\\INV_BannerPVP_02"
    if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then pvpIcon = "Interface\\Icons\\INV_BannerPVP_01" end
    local categories = {{"dungeon", "LID_DUNGEONS", 236180}, {"raid", "LID_RAIDS", "Interface\\Icons\\INV_Misc_Head_Dragon_01"}, {"pvp", "LID_PVP", pvpIcon}, {"faction", "LID_REPUTATION", "Interface\\Icons\\INV_Shirt_GuildTabard_01"}, {"worldquestitems", "LID_WORLDQUESTITEMS", "Interface\\Icons\\INV_Misc_Book_09"}}
    compendium.wishlistTabs = {}
    local previous = nil
    for _, info in ipairs(categories) do
        local kind = info[1]
        local tab = CreateTabButton(compendium, info[2], {texture = info[3]}, function()
            ACOTABPC.WISHLISTCATEGORY = kind
            RefreshWishlistView()
        end)
        if previous then
            tab:SetPoint("LEFT", previous, "RIGHT", 1, 0)
        else
            tab:SetPoint("BOTTOMLEFT", compendium.wishlist, "TOPLEFT", 0, -2)
        end
        tab:Hide()
        compendium.wishlistTabs[kind] = tab
        previous = tab
    end
    if not compendium.wishlistTabs[ACOTABPC.WISHLISTCATEGORY] then ACOTABPC.WISHLISTCATEGORY = "dungeon" end
end

local function RefreshWorldQuestItemsView()
    if compendium == nil or compendium.worldQuestItems == nil then return end
    SetSpecialMode("worldquestitems")
    local list = GetWorldQuestItemList()
    local scroller = compendium.worldQuestItems
    local sameEntries = #list == #scroller.data
    if sameEntries then
        for index, entry in ipairs(list) do
            local previous = scroller.data[index]
            if entry.itemID ~= previous.itemID or entry.questID ~= previous.questID then
                sameEntries = false
                break
            end
        end
    end

    if sameEntries then
        scroller.data = list
        scroller:Refresh()
    else
        scroller:SetData(list)
    end
    compendium.worldQuestItemsCount:SetText(AzerothCompendium:Trans("LID_ITEMCOUNT", nil, #list))
    if #list == 0 then
        compendium.worldQuestItemsEmpty:Show()
    else
        compendium.worldQuestItemsEmpty:Hide()
    end
end

local function RefreshCurrentView()
    if listKind == "wishlist" then
        RefreshWishlistView()
    elseif listKind == "worldquestitems" then
        RefreshWorldQuestItemsView()
    elseif listKind == "settings" then
        SetSpecialMode("settings")
    else
        SetSpecialMode(nil)
        RefreshInstances()
    end
end

NavigateToWishlistItem = function(entry)
    if entry == nil then return end
    if entry.kind == "worldquestitems" then
        listKind = "worldquestitems"
        searchText = entry.name or ""
        compendium.search:SetText(searchText)
        SaveNavigationState()
        UpdateKindTabs()
        RefreshCurrentView()
        return
    end
    local kind, inst, boss = FindWishlistSource(entry.itemID, entry.source)
    if kind == nil or inst == nil or boss == nil then return end
    listKind = kind
    selectedInstance = inst
    selectedBoss = boss
    detailKind = "loot"
    searchText = ""
    SaveNavigationState()
    UpdateKindTabs()
    SetSpecialMode(nil)
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

function AzerothCompendium:CreateInstanceControls()
    local instances = CreateScroller(compendium, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, function(entry)
            if entry.levelGroup then
                ACOTABPC.INSTANCEGROUPS[entry.key] = not ACOTABPC.INSTANCEGROUPS[entry.key]
                local listScroller = compendium.instances
                listScroller.data = AzerothCompendium:GetGroupedInstanceList(listScroller.fullList)
                listScroller:Refresh()
                compendium.instancePopup:SetHeight(min(360, listScroller.contentHeight + 10))
            else
                OnInstanceClick(entry)
            end
        end)
        AddLoadingScreen(row)
        row.collapseIcon = row:CreateTexture(nil, "OVERLAY")
        row.collapseIcon:SetSize(16, 16)
        row.collapseIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.collapseIcon:Hide()
        function row:Update(entry)
            if entry.levelGroup then
                UpdateInstanceBackground(self, entry)
                self.entry = entry
                self.loadingScreen:Hide()
                self.loadingShade:Hide()
                self.typeIcon:Hide()
                self.subText:Hide()
                self.selected:Hide()
                self.text:ClearAllPoints()
                self.info:ClearAllPoints()
                self.collapseIcon:SetTexture(entry.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                self.collapseIcon:Show()
                self.text:SetPoint("LEFT", self.collapseIcon, "RIGHT", 4, 0)
                self.text:SetPoint("RIGHT", self, "RIGHT", -30, 0)
                self.info:SetPoint("RIGHT", self, "RIGHT", -6, 0)
                self.text:SetText(AzerothCompendium:Trans("LID_LEVELGROUP", nil, entry.level, entry.level + 9))
                self.text:SetTextColor(1, 0.82, 0)
                self.info:SetJustifyH("RIGHT")
                self.info:SetTextColor(0.7, 0.7, 0.7)
                self.info:SetText(entry.count)
            else
                self.collapseIcon:Hide()
                UpdateInstanceRow(self, entry)
            end
        end
        return row
    end)

    instances:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -90)
    instances:SetPoint("BOTTOMLEFT", compendium, "BOTTOMLEFT", 12, 28)
    instances:SetWidth(INSTANCE_COL_W)
    instances:EnableEmptyText()
    compendium.instances = instances
    local instanceControl = CreateTemplated("Frame", nil, compendium, {"SettingsDropdownWithButtonsTemplate"})
    instanceControl:SetPoint("LEFT", compendium, "TOPLEFT", 59, -42)
    instanceControl:SetSize(INSTANCE_COL_W + 60, 22)
    local instanceDropdown = instanceControl.Dropdown
    if instanceDropdown == nil then
        instanceDropdown = CreateTemplated("Button", nil, instanceControl, {"UIPanelButtonTemplate"})
        instanceDropdown:SetSize(INSTANCE_COL_W, 22)
        instanceDropdown:SetPoint("LEFT", instanceControl, "LEFT", 30, 0)
    else
        instanceDropdown:SetWidth(INSTANCE_COL_W)
    end

    local instancePopup = CreateFrame("Frame", nil, compendium)
    instancePopup:SetFrameStrata("DIALOG")
    instancePopup:SetPoint("TOPLEFT", instanceDropdown, "BOTTOMLEFT", 0, -4)
    instancePopup:SetSize(INSTANCE_COL_W + 10, 360)
    instancePopup:SetClampedToScreen(true)
    instancePopup:EnableMouse(true)
    instancePopup.background = instancePopup:CreateTexture(nil, "BACKGROUND")
    instancePopup.background:SetAllPoints(instancePopup)
    instancePopup.background:SetColorTexture(0.04, 0.04, 0.05, 1)
    instances:SetParent(instancePopup)
    instances:ClearAllPoints()
    instances:SetPoint("TOPLEFT", instancePopup, "TOPLEFT", 5, -5)
    instances:SetPoint("BOTTOMRIGHT", instancePopup, "BOTTOMRIGHT", -5, 5)
    instancePopup:Hide()
    instancePopup:SetScript("OnUpdate", function(sel) if IsMouseButtonDown("LeftButton") and not sel:IsMouseOver() and not instanceControl:IsMouseOver() then sel:Hide() end end)
    instanceDropdown:SetScript("OnClick", function()
        if instancePopup:IsShown() then
            instancePopup:Hide()
        else
            instancePopup:SetHeight(min(360, max(ROW_H, instances.contentHeight or 0) + 10))
            instancePopup:Show()
            instances:Refresh()
            for index, inst in ipairs(instances.data) do
                if inst == selectedInstance then instances:ScrollToIndex(index) end
            end
        end
    end)

    local function StepInstance(delta)
        for index, inst in ipairs(instances.fullList or {}) do
            if inst == selectedInstance and instances.fullList[index + delta] then
                OnInstanceClick(instances.fullList[index + delta])
                return
            end
        end
    end

    local instanceSteppers = AzerothCompendium:SetupDropdownSteppers(instanceControl, function() StepInstance(-1) end, function() StepInstance(1) end, false, instanceDropdown)
    local relevantFilter = CreateTemplated("CheckButton", "AzerothCompendiumRelevantFilter", instanceControl, {"UICheckButtonTemplate", "ChatConfigCheckButtonTemplate"})
    relevantFilter:SetSize(24, 24)
    relevantFilter:SetPoint("LEFT", instanceControl, "RIGHT", 8, 0)
    relevantFilter:SetChecked(type(ACOTABPC) == "table" and ACOTABPC.ONLYRELEVANT == true)
    local relevantLabel = relevantFilter:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    relevantLabel:SetPoint("LEFT", relevantFilter, "RIGHT", 2, 0)
    relevantLabel:SetText(AzerothCompendium:Trans("LID_ONLYRELEVANT"))
    relevantFilter:SetScript("OnClick", function(sel)
        ACOTABPC = ACOTABPC or {}
        ACOTABPC.ONLYRELEVANT = sel:GetChecked() == true
        RefreshInstances()
        if instancePopup:IsShown() then instancePopup:SetHeight(min(360, max(ROW_H, instances.contentHeight or 0) + 10)) end
    end)
    compendium.relevantFilter = relevantFilter
    compendium.relevantLabel = relevantLabel
    compendium.instanceControl = instanceControl
    compendium.instancePopup = instancePopup
    compendium.updateInstanceSelection = function()
        relevantFilter:SetShown(listKind == "dungeon")
        local text = selectedInstance and AzerothCompendium:GetInstanceName(selectedInstance) or "-"
        if instanceDropdown.SetDefaultText then instanceDropdown:SetDefaultText(text) end
        if instanceDropdown.SetText then instanceDropdown:SetText(text) end
        local selectedIndex = 0
        for index, inst in ipairs(instances.fullList or {}) do
            if inst == selectedInstance then selectedIndex = index end
        end

        instanceSteppers:SetEnabled(selectedIndex > 1, selectedIndex > 0 and selectedIndex < #(instances.fullList or {}))
    end

    instanceControl:HookScript("OnShow", function() compendium.updateInstanceSelection() end)
    compendium:HookScript("OnHide", function() instancePopup:Hide() end)
end

local function CreateJournal()
    LoadNavigationState()
    if compendium ~= nil then return compendium end
    local template = nil
    compendium, template = CreateTemplated("Frame", "AzerothCompendiumFrame", UIParent, {"ButtonFrameTemplate", "PortraitFrameTemplate", "BasicFrameTemplateWithInset"})
    if template == nil then AddFallbackChrome(compendium) end
    if type(compendium.Inset) == "table" and type(compendium.Inset.Bg) == "table" then compendium.Inset.Bg:SetAlpha(0.6) end
    SetFramePortrait(compendium, AzerothCompendium:GetIcon())
    local width = tonumber(AzerothCompendium:GetConfig("COMPENDIUMWIDTH", WIDTH)) or WIDTH
    local height = tonumber(AzerothCompendium:GetConfig("COMPENDIUMHEIGHT", HEIGHT)) or HEIGHT
    compendium:SetScale(NormalizeScale(AzerothCompendium:GetConfig("COMPENDIUMSCALE", 1)))
    compendium:SetSize(max(MIN_WIDTH, width), max(MIN_HEIGHT, height))
    local savedX = tonumber(AzerothCompendium:GetConfig("COMPENDIUMX"))
    local savedY = tonumber(AzerothCompendium:GetConfig("COMPENDIUMY"))
    if savedX and savedY then
        compendium:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedX / compendium:GetScale(), savedY / compendium:GetScale())
    else
        compendium:SetPoint("TOPLEFT", UIParent, "CENTER", -compendium:GetWidth() / 2, compendium:GetHeight() / 2)
    end

    function compendium:SavePosition()
        local left, top = self:GetLeft(), self:GetTop()
        if left == nil or top == nil then return end
        AzerothCompendium:SetConfig("COMPENDIUMX", left * self:GetScale())
        AzerothCompendium:SetConfig("COMPENDIUMY", top * self:GetScale())
    end

    compendium:SetFrameStrata("HIGH")
    compendium:SetMovable(true)
    compendium:EnableMouse(true)
    compendium:RegisterForDrag("LeftButton")
    compendium:SetScript("OnDragStart", function(sel) sel:StartMoving() end)
    compendium:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        sel:SavePosition()
    end)
    MakeResizable(compendium)
    AzerothCompendium:SetClampedToScreen(compendium, true, "AzerothCompendium")
    compendium:Hide()
    SetFrameTitle(compendium, AzerothCompendium:Trans("LID_TITLE"))
    compendium.version = compendium:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    compendium.version:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -24, 10)
    compendium.version:SetTextColor(0.5, 0.5, 0.5)
    compendium.version:SetText("v" .. AzerothCompendium:GetAddonVersion())
    if type(UISpecialFrames) == "table" then tinsert(UISpecialFrames, "AzerothCompendiumFrame") end
    local search = CreateTemplated("EditBox", "AzerothCompendiumSearchBox", compendium, {"InputBoxTemplate", "SearchBoxTemplate"})
    search:SetSize(180, 20)
    search:SetPoint("TOPRIGHT", compendium, "TOPRIGHT", -30, -32)
    search:SetFontObject("ChatFontNormal")
    search:SetAutoFocus(false)
    search:SetText(savedSearchText)
    search:SetScript("OnTextChanged", function(sel)
        searchText = Lower(strtrim(sel:GetText() or ""))
        RefreshCurrentView()
        SaveNavigationState()
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
    local pvpIcon = "Interface\\Icons\\INV_BannerPVP_02"
    if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then pvpIcon = "Interface\\Icons\\INV_BannerPVP_01" end
    local previousTab = nil
    for _, info in ipairs({{"dungeon", "LID_DUNGEONS", 236180}, {"raid", "LID_RAIDS", "Interface\\Icons\\INV_Misc_Head_Dragon_01"}, {"pvp", "LID_PVP", pvpIcon}, {"faction", "LID_REPUTATION", "Interface\\Icons\\INV_Shirt_GuildTabard_01"}, {"worldquestitems", "LID_WORLDQUESTITEMS", "Interface\\Icons\\INV_Misc_Book_09"}, {"wishlist", "LID_WISHLIST", "Interface\\Icons\\INV_Misc_Note_01"}, {"settings", "LID_SETTINGS", "Interface\\Icons\\INV_Misc_Gear_01"},}) do
        local kind = info[1]
        local tab = CreateSideTab(compendium, info[2], info[3], function()
            if listKind == kind then
                UpdateKindTabs()
                return
            end

            listKind = kind
            middleKind = "map"
            selectedInstance = nil
            selectedBoss = nil
            mapLevel = 1
            SaveNavigationState()
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

    AzerothCompendium:CreateInstanceControls()
    local bossTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    bossTitle:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -84)
    bossTitle:SetWidth(MIDDLE_COL_W)
    bossTitle:SetWordWrap(false)
    bossTitle:SetJustifyH("LEFT")
    compendium.bossTitle = bossTitle
    local bosses = CreateScroller(compendium, ROW_H, function(scroller)
        local row = CreateTextRow(scroller, OnBossClick)
        AddBossPortrait(row)
        MapPins.AddRowButton(row)
        function row:Update(entry)
            UpdateBossRow(self, entry)
            MapPins.UpdateRowButton(self, entry)
        end
        return row
    end)

    bosses:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -104)
    bosses:SetPoint("BOTTOMLEFT", compendium, "BOTTOMLEFT", 14, 28)
    bosses:SetWidth(MIDDLE_COL_W)
    bosses:EnableEmptyText()
    compendium.bosses = bosses
    local questTree = AzerothCompendium:CreateQuestTree(compendium)
    AddContentBorder(questTree)
    questTree:SetPoint("TOPLEFT", bosses, "TOPLEFT", 0, 0)
    questTree:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    questTree:Hide()
    compendium.questTree = questTree
    local mapView = CreateFrame("Frame", nil, compendium)
    AddContentBorder(mapView)
    mapView:SetPoint("TOPLEFT", bosses, "TOPLEFT", 0, 0)
    mapView:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    mapView.viewport = CreateFrame("Frame", nil, mapView)
    mapView.viewport:SetPoint("TOPLEFT", mapView, "TOPLEFT", 4, -4)
    mapView.viewport:SetPoint("BOTTOMRIGHT", mapView, "BOTTOMRIGHT", -4, 4)
    mapView.borderOverlay = CreateFrame("Frame", nil, mapView)
    mapView.borderOverlay:SetAllPoints(mapView)
    mapView.borderOverlay:SetFrameLevel(mapView.viewport:GetFrameLevel() + 20)
    mapView.borderOverlay:EnableMouse(false)
    mapView.border:SetParent(mapView.borderOverlay)
    mapView.border:SetDrawLayer("OVERLAY")
    mapView.viewport:SetClipsChildren(true)
    mapView.viewport:EnableMouse(true)
    mapView.viewport:EnableMouseWheel(true)
    mapView.viewport:SetScript("OnMouseWheel", function(_, delta) MapPins.Zoom(mapView, delta) end)
    mapView.viewport:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or mapView.info == nil or (mapView.zoom or 1) <= 1 then return end
        mapView.dragX, mapView.dragY = GetCursorPosition()
    end)

    mapView.viewport:SetScript("OnMouseUp", function() mapView.dragX, mapView.dragY = nil, nil end)
    mapView.viewport:SetScript("OnHide", function() mapView.dragX, mapView.dragY = nil, nil end)
    mapView.viewport:SetScript("OnUpdate", function()
        if mapView.dragX == nil then return end
        if not IsMouseButtonDown("LeftButton") then
            mapView.dragX, mapView.dragY = nil, nil
            return
        end

        local x, y = GetCursorPosition()
        local scale = mapView:GetEffectiveScale()
        mapView.offsetX = (mapView.offsetX or 0) + (x - mapView.dragX) / scale
        mapView.offsetY = (mapView.offsetY or 0) + (y - mapView.dragY) / scale
        mapView.dragX, mapView.dragY = x, y
        LayoutMapArt()
    end)

    mapView.art = mapView.viewport:CreateTexture(nil, "ARTWORK")
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
    local mapTab = CreateTabButton(compendium, "LID_MAP",TAB_ICONS["map"], function()
        middleKind = "map"
        SaveNavigationState()
        RefreshBosses()
    end)

    mapTab:SetPoint("BOTTOMLEFT", bosses, "TOPLEFT", 0, -2)
    local bossTab = CreateTabButton(compendium, "LID_BOSSES",TAB_ICONS["bosses"], function()
        middleKind = "bosses"
        SaveNavigationState()
        RefreshBosses()
    end)

    bossTab:SetPoint("LEFT", mapTab, "RIGHT", 1, 0)
    local questTab = CreateTabButton(compendium, "LID_QUESTS",TAB_ICONS["quests"], function()
        middleKind = "quests"
        SaveNavigationState()
        RefreshBosses()
    end)

    questTab:SetPoint("LEFT", bossTab, "RIGHT", 1, 0)
    compendium.middleTabs["map"] = mapTab
    compendium.middleTabs["bosses"] = bossTab
    compendium.middleTabs["quests"] = questTab
    local loot = CreateScroller(compendium, LOOT_ROW_H + 6, CreateLootRow, 2)
    loot.rowGap = 0
    loot:SetRowHeight(LOOT_ROW_H + 6)
    loot:SetPoint("TOPLEFT", bosses, "TOPRIGHT", 14, 0)
    loot:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    compendium.loot = loot
    local wishlist = CreateScroller(compendium, LOOT_ROW_H + 6, CreateWishlistRow, 2)
    wishlist.rowGap = 0
    wishlist:SetRowHeight(LOOT_ROW_H + 6)
    wishlist:SetPoint("TOPLEFT", bosses, "TOPLEFT", 0, 0)
    wishlist:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    wishlist:Hide()
    compendium.wishlist = wishlist
    AzerothCompendium:CreateWishlistTabs()
    local wishlistTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    wishlistTitle:SetPoint("LEFT", compendium.wishlistTabs.worldquestitems, "RIGHT", 8, 0)
    wishlistTitle:SetText(AzerothCompendium:Trans("LID_WISHLIST"))
    wishlistTitle:Hide()
    compendium.wishlistTitle = wishlistTitle
    local wishlistCount = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    wishlistCount:SetPoint("RIGHT", compendium, "TOPRIGHT", -14, -90)
    wishlistCount:SetJustifyH("RIGHT")
    wishlistCount:Hide()
    compendium.wishlistCount = wishlistCount
    local wishlistEmpty = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    wishlistEmpty:SetPoint("CENTER", wishlist, "CENTER", 0, 0)
    wishlistEmpty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    wishlistEmpty:Hide()
    compendium.wishlistEmpty = wishlistEmpty
    local worldQuestItems = CreateScroller(compendium, WORLD_QUEST_ITEM_ROW_H, CreateWorldQuestItemRow, 2)
    worldQuestItems.rowGap = 0
    worldQuestItems:SetRowHeight(WORLD_QUEST_ITEM_ROW_H)
    worldQuestItems:SetPoint("TOPLEFT", compendium, "TOPLEFT", 14, -90)
    worldQuestItems:SetPoint("BOTTOMRIGHT", compendium, "BOTTOMRIGHT", -14, 28)
    worldQuestItems:Hide()
    compendium.worldQuestItems = worldQuestItems
    local worldQuestItemsTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    worldQuestItemsTitle:SetPoint("BOTTOMLEFT", worldQuestItems, "TOPLEFT", 0, 6)
    worldQuestItemsTitle:SetText(AzerothCompendium:Trans("LID_WORLDQUESTITEMS"))
    worldQuestItemsTitle:Hide()
    compendium.worldQuestItemsTitle = worldQuestItemsTitle
    local worldQuestItemsCount = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    worldQuestItemsCount:SetPoint("BOTTOMRIGHT", worldQuestItems, "TOPRIGHT", 0, 6)
    worldQuestItemsCount:SetJustifyH("RIGHT")
    worldQuestItemsCount:Hide()
    compendium.worldQuestItemsCount = worldQuestItemsCount
    local worldQuestItemsEmpty = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
    worldQuestItemsEmpty:SetPoint("CENTER", worldQuestItems, "CENTER", 0, 0)
    worldQuestItemsEmpty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
    worldQuestItemsEmpty:Hide()
    compendium.worldQuestItemsEmpty = worldQuestItemsEmpty
    local spells = CreateScroller(compendium, LOOT_ROW_H, CreateSpellRow, 2)
    spells.rowGap = 0
    spells:SetRowHeight(LOOT_ROW_H)
    spells:SetAllPoints(loot)
    spells:Hide()
    compendium.spells = spells
    compendium.detailTabs = {}
    local spellTab = CreateTabButton(compendium, "LID_ABILITIES",TAB_ICONS["spells"], function()
        detailKind = "spells"
        SaveNavigationState()
        RefreshDetail()
    end)

    local lootTab = CreateTabButton(compendium, "LID_LOOT",TAB_ICONS["loot"], function()
        detailKind = "loot"
        SaveNavigationState()
        RefreshDetail()
    end)

    compendium.detailTabs["loot"] = lootTab
    compendium.detailTabs["spells"] = spellTab
    lootTab:SetPoint("BOTTOMLEFT", loot, "TOPLEFT", 0, -2)
    spellTab:SetPoint("LEFT", lootTab, "RIGHT", 1, 0)
    local lastDetailTab = spellTab
    local model = CreateModelFrame(compendium)
    if model ~= nil then
        AddContentBorder(model)
        model:SetPoint("TOPLEFT", loot, "TOPLEFT", 0, 0)
        model:SetPoint("BOTTOMRIGHT", loot, "BOTTOMRIGHT", 0, 0)
        model:Hide()
        compendium.model = model
        local modelTab = CreateTabButton(compendium, "LID_MODEL",TAB_ICONS["model"], function()
            detailKind = "model"
            SaveNavigationState()
            RefreshDetail()
        end)

        modelTab:SetPoint("LEFT", spellTab, "RIGHT", 1, 0)
        compendium.detailTabs["model"] = modelTab
        lastDetailTab = modelTab
    end

    local detailCount = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detailCount:SetPoint("BOTTOMRIGHT", loot, "TOPRIGHT", 0, 6)
    detailCount:SetJustifyH("RIGHT")
    compendium.detailCount = detailCount
    local detailTitle = compendium:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    detailTitle:SetPoint("BOTTOMLEFT", lastDetailTab, "BOTTOMRIGHT", 8, 8)
    detailTitle:SetPoint("RIGHT", detailCount, "LEFT", 0, 0)
    detailTitle:SetWordWrap(false)
    detailTitle:SetJustifyH("RIGHT")
    compendium.detailTitle = detailTitle
    local classFilter = CreateTemplated("CheckButton", "AzerothCompendiumClassFilter", compendium, {"UICheckButtonTemplate", "ChatConfigCheckButtonTemplate"})
    classFilter:SetSize(24, 24)
    classFilter:SetPoint("BOTTOMRIGHT", loot, "TOPRIGHT", 2, 19)
    classFilter:SetChecked(AzerothCompendium:GetConfig("CLASSFILTER", false) == true)
    local classFilterLabel = compendium:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    classFilterLabel:SetPoint("RIGHT", classFilter, "LEFT", 0, 0)
    classFilterLabel:SetText(AzerothCompendium:Trans("LID_CLASSFILTER"))
    classFilter:SetScript("OnClick", function(sel) AzerothCompendium:SetClassFilter(sel:GetChecked() == true) end)
    compendium.classFilter = classFilter
    compendium.classFilterLabel = classFilterLabel
    CreateSettingsPanel()
    AzerothCompendium:OnLanguage(function()
        searchLabel:SetText(AzerothCompendium:Trans("LID_SEARCH"))
        compendium.relevantLabel:SetText(AzerothCompendium:Trans("LID_ONLYRELEVANT"))
        mapView.empty:SetText(AzerothCompendium:Trans("LID_NOMAP"))
        wishlistTitle:SetText(AzerothCompendium:Trans("LID_WISHLIST"))
        wishlistEmpty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
        worldQuestItemsTitle:SetText(AzerothCompendium:Trans("LID_WORLDQUESTITEMS"))
        worldQuestItemsEmpty:SetText(AzerothCompendium:Trans("LID_NOENTRIES"))
        classFilterLabel:SetText(AzerothCompendium:Trans("LID_CLASSFILTER"))
    end)
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
    AzerothCompendium:SetDropdownText(compendium.flavorDropdown, GetFlavorText())
    if compendium.updateFlavorSteppers then compendium.updateFlavorSteppers() end
end

function AzerothCompendium:RefreshCompendium()
    AzerothCompendium:SyncCompendiumClassFilter()
    AzerothCompendium:SyncCompendiumFlavor()
    if compendium == nil or not compendium:IsShown() then return end
    RefreshCurrentView()
end

function MapPins.Remove(list, value)
    for index, other in ipairs(list or {}) do
        if other == value then
            tremove(list, index)
            return
        end
    end
end

function MapPins.Place(entry, art, x, y)
    local data = AzerothCompendium.INSTANCEMAPPINS
    if art ~= entry.art then
        MapPins.Remove(data[entry.art], entry)
        data[art] = data[art] or {}
        tinsert(data[art], entry)
        entry.art = art
    end

    entry[2] = x
    entry[3] = y
end

function MapPins.AddUnplaced()
    local data = AzerothCompendium.INSTANCEMAPPINS
    local placed = {}
    for _, entry in ipairs(MapPins.entries) do
        if entry[1] == "boss" then placed[entry[4]] = true end
    end

    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        local maps = AzerothCompendium.INSTANCEMAPS and AzerothCompendium.INSTANCEMAPS[inst.id]
        if maps ~= nil and maps[1] ~= nil then
            local count = 2
            local function Add(art, kind, arg, slot)
                local entry = {kind, 0.05 + (slot % 8) * 0.075, 0.08 + floor(slot / 8) * 0.11, arg}
                entry.art = art
                entry.orig = {art, entry[2], entry[3], arg, false}
                entry.unplaced = true
                data[art] = data[art] or {}
                tinsert(data[art], entry)
                tinsert(MapPins.entries, entry)
            end

            local hasEntrance = false
            for index, info in ipairs(maps) do
                local hasLevel = false
                for _, entry in ipairs(data[info.id] or {}) do
                    if entry[1] == "entrance" then hasEntrance = true end
                    if entry[1] == "level" then hasLevel = true end
                end

                local target = maps[index + 1] or maps[index - 1]
                if not hasLevel and target ~= nil then Add(info.id, "level", target.id, 1) end
            end

            if not hasEntrance then Add(maps[1].id, "entrance", nil, 0) end
            for _, boss in ipairs(inst.bosses or {}) do
                local found = boss.npcs == nil or boss.npcs[1] == nil
                for _, id in ipairs(boss.npcs or {}) do
                    if placed[id] then found = true end
                end

                if not found then
                    placed[boss.npcs[1]] = true
                    Add(maps[1].id, "boss", boss.npcs[1], count)
                    count = count + 1
                end
            end
        end
    end
end

function MapPins.IsHidden(entry)
    if MapPins.debug then return false end
    return entry.deleted == true or (entry.unplaced == true or entry.parked == true) and not MapPins.IsChanged(entry)
end

function MapPins.GetOpen()
    local counts = {}
    for _, entry in ipairs(MapPins.entries) do
        if (entry.unplaced or entry.parked) and not MapPins.IsChanged(entry) then counts[entry.art] = (counts[entry.art] or 0) + 1 end
    end

    local lines = {}
    local seen = {}
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        for _, info in ipairs(AzerothCompendium.INSTANCEMAPS and AzerothCompendium.INSTANCEMAPS[inst.id] or {}) do
            if counts[info.id] and not seen[info.id] then
                local name = AzerothCompendium:GetInstanceName(inst)
                if info.name then name = name .. " - " .. info.name end
                seen[info.id] = true
                tinsert(lines, format("%s (%d): %d", name, info.id, counts[info.id]))
            end
        end
    end
    return counts, lines
end

function MapPins.IsParked(x, y)
    local column = (x - 0.05) / 0.075
    local row = (y - 0.08) / 0.11
    return column > -0.01 and column < 7.01 and row > -0.01 and abs(column - floor(column + 0.5)) < 0.01 and abs(row - floor(row + 0.5)) < 0.01
end

function MapPins.Insert(save)
    local data = AzerothCompendium.INSTANCEMAPPINS
    local entry = {save.kind, save.x, save.y, save.arg, save.up == true or nil}
    entry.art = save.art
    entry.orig = {save.art, save.x, save.y, save.arg, save.up == true}
    entry.added = true
    entry.save = save
    data[save.art] = data[save.art] or {}
    tinsert(data[save.art], entry)
    tinsert(MapPins.entries, entry)
    return entry
end

function MapPins.Init()
    if MapPins.ready then return end
    MapPins.ready = true
    MapPins.entries = {}
    local data = AzerothCompendium.INSTANCEMAPPINS
    if data == nil then return end
    ACOTAB = ACOTAB or {}
    if type(ACOTAB["MAPPINEDITS"]) ~= "table" then ACOTAB["MAPPINEDITS"] = {} end
    if type(ACOTAB["MAPPINADDS"]) ~= "table" then ACOTAB["MAPPINADDS"] = {} end
    for art, entries in pairs(data) do
        for _, entry in ipairs(entries) do
            entry.art = art
            entry.orig = {art, entry[2], entry[3], entry[4], entry[5] == true}
            entry.parked = MapPins.IsParked(entry[2], entry[3])
            tinsert(MapPins.entries, entry)
        end
    end

    MapPins.AddUnplaced()
    local used = {}
    for _, entry in ipairs(MapPins.entries) do
        local key = entry[1] .. ":" .. tostring(entry[4] or "") .. ":" .. entry.orig[1]
        used[key] = (used[key] or 0) + 1
        entry.key = used[key] > 1 and key .. "#" .. used[key] or key
        local edit = ACOTAB["MAPPINEDITS"][entry.key]
        if type(edit) == "table" and tonumber(edit[1]) and tonumber(edit[2]) and tonumber(edit[3]) then
            if edit.arg ~= nil then entry[4] = edit.arg end
            if edit.up ~= nil then entry[5] = edit.up == true or nil end
            entry.deleted = edit.del == true or nil
        end
    end

    for _, entry in ipairs(MapPins.entries) do
        local edit = ACOTAB["MAPPINEDITS"][entry.key]
        if type(edit) == "table" and tonumber(edit[1]) and tonumber(edit[2]) and tonumber(edit[3]) then MapPins.Place(entry, edit[1], edit[2], edit[3]) end
    end

    for _, save in ipairs(ACOTAB["MAPPINADDS"]) do
        if type(save) == "table" and type(save.kind) == "string" and tonumber(save.art) and tonumber(save.x) and tonumber(save.y) then MapPins.Insert(save) end
    end
end

function MapPins.IsChanged(entry)
    if entry.added or entry.deleted then return true end
    if entry[4] ~= entry.orig[4] or (entry[5] == true) ~= entry.orig[5] then return true end
    return entry.art ~= entry.orig[1] or abs(entry[2] - entry.orig[2]) > 0.0005 or abs(entry[3] - entry.orig[3]) > 0.0005
end

function MapPins.Edit(entry, art, x, y)
    x = max(0, min(1, floor(x * 1000 + 0.5) / 1000))
    y = max(0, min(1, floor(y * 1000 + 0.5) / 1000))
    MapPins.Place(entry, art, x, y)
    if entry.added then
        entry.save.art = art
        entry.save.x = x
        entry.save.y = y
        entry.save.arg = entry[4]
        entry.save.up = entry[5] == true
    elseif MapPins.IsChanged(entry) then
        ACOTAB["MAPPINEDITS"][entry.key] = {
            art,
            x,
            y,
            arg = entry[4],
            up = entry[5] == true,
            del = entry.deleted == true,
        }
    else
        ACOTAB["MAPPINEDITS"][entry.key] = nil
    end

    MapPins.Update(compendium.mapView)
end

function MapPins.Reset(entry)
    entry[4] = entry.orig[4]
    entry[5] = entry.orig[5] or nil
    entry.deleted = nil
    MapPins.Edit(entry, entry.orig[1], entry.orig[2], entry.orig[3])
end

function MapPins.SetArg(entry, value)
    local valid = entry[1] == "boss" and MapPins.FindBoss(value) ~= nil or entry[1] == "level" and MapPins.FindLevel(GetInstanceMaps(), value) ~= nil
    if entry[1] == "item" then
        for _, item in ipairs(MapPins.GetQuestItems()) do
            if item[2] == value then valid = true end
        end
    end

    if not valid then
        if entry[1] ~= "entrance" then AzerothCompendium:INFO(format("%s is not a valid %s for this instance", tostring(value), entry[1] == "boss" and "NPC ID" or entry[1] == "item" and "item ID" or "map ID")) end
        MapPins.DebugRefresh()
        return
    end

    entry[4] = value
    MapPins.Edit(entry, entry.art, entry[2], entry[3])
end

function MapPins.ShowArgMenu(owner, entry)
    local options = {}
    if entry[1] == "boss" and selectedInstance ~= nil then
        local selected = MapPins.FindBoss(entry[4])
        for _, boss in ipairs(selectedInstance.bosses or {}) do
            if boss.npcs ~= nil and boss.npcs[1] ~= nil then
                local id = boss == selected and entry[4] or boss.npcs[1]
                tinsert(options, {format("%s (%d)", boss.name or "?", id), id})
            end
        end
    elseif entry[1] == "item" then
        options = MapPins.GetQuestItems()
    elseif entry[1] == "level" then
        local maps = GetInstanceMaps() or {}
        for index, info in ipairs(maps) do
            if info.id ~= entry.art then tinsert(options, {format("%s (%d)", GetMapLevelLabel(maps, index), info.id), info.id}) end
        end
    end

    MapPins.ShowMenu(owner, options, entry[4], function(value) MapPins.SetArg(entry, value) end)
end

function MapPins.ShowMapMenu(owner, entry)
    local maps = GetInstanceMaps() or {}
    local options = {}
    for index, info in ipairs(maps) do
        tinsert(options, {format("%s (%d)", GetMapLevelLabel(maps, index), info.id), info.id})
    end

    MapPins.ShowMenu(owner, options, entry.art, function(value)
        MapPins.Edit(entry, value, entry[2], entry[3])
        SelectMapLevel(MapPins.FindLevel(maps, value))
    end)
end

function MapPins.ShowMenu(owner, options, current, onSelect)
    local entries = {}
    for _, option in ipairs(options) do
        tinsert(entries, {
            text = option[1],
            checked = current == option[2],
            func = function() onSelect(option[2]) end
        })
    end

    AzerothCompendium:ShowContextMenu(owner, entries)
end

function MapPins.Delete(entry)
    if not entry.added then
        entry.deleted = true
        MapPins.Edit(entry, entry.art, entry[2], entry[3])
        return
    end

    MapPins.Remove(ACOTAB["MAPPINADDS"], entry.save)
    MapPins.Remove(AzerothCompendium.INSTANCEMAPPINS[entry.art], entry)
    MapPins.Remove(MapPins.entries, entry)
    MapPins.selected = nil
    MapPins.Update(compendium.mapView)
end

function MapPins.Add(kind, up)
    local view = compendium.mapView
    local maps = GetInstanceMaps()
    if view.info == nil or maps == nil or selectedInstance == nil then return end
    local arg = nil
    if kind == "boss" then
        for _, boss in ipairs(selectedInstance.bosses or {}) do
            if boss.npcs ~= nil and boss.npcs[1] ~= nil and (arg == nil or MapPins.GetBossLevel(boss) == nil) then
                arg = boss.npcs[1]
                if MapPins.GetBossLevel(boss) == nil then break end
            end
        end

        if arg == nil then return end
    elseif kind == "item" then
        local items = MapPins.GetQuestItems()
        if #items == 0 then
            AzerothCompendium:INFO("This instance has no quest start items")
            return
        end

        arg = items[1][2]
    elseif kind == "level" then
        local index = MapPins.FindLevel(maps, view.info.id)
        local target = index and (maps[index + 1] or maps[index - 1])
        if target == nil then
            AzerothCompendium:INFO("This instance has only one map")
            return
        end

        arg = target.id
    end

    local save = {
        art = view.info.id,
        kind = kind,
        x = 0.5,
        y = 0.5,
        arg = arg,
        up = up == true,
    }

    tinsert(ACOTAB["MAPPINADDS"], save)
    MapPins.selected = MapPins.Insert(save)
    MapPins.Update(view)
    if kind == "item" then MapPins.ShowArgMenu(MapPins.editor.arg, MapPins.selected) end
end

function MapPins.GetNpcName(npcID)
    if MapPins.names == nil then
        MapPins.names = {}
        for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
            for _, boss in ipairs(inst.bosses or {}) do
                for _, id in ipairs(boss.npcs or {}) do
                    if MapPins.names[id] == nil then MapPins.names[id] = boss.name end
                end
            end
        end
    end
    return MapPins.names[npcID]
end

function MapPins.FormatEntry(entry)
    local orig = entry.orig
    local src = entry.deleted and orig or {entry.art, entry[2], entry[3], entry[4], entry[5] == true}
    local text = format("[%d] {\"%s\", %.3f, %.3f", src[1], entry[1], src[2], src[3])
    if src[4] ~= nil then text = text .. ", " .. src[4] end
    if src[5] == true then text = text .. ", true" end
    text = text .. "},"
    local name = entry[1] == "boss" and MapPins.GetNpcName(src[4]) or entry[1] == "item" and MapPins.GetItemName(src[4]) or nil
    if name then text = text .. " -- " .. name end
    if entry.deleted then return text .. " (delete)" end
    if entry.added then return text .. " (add)" end
    if entry.unplaced then return text .. " (new)" end
    local was = format("[%d] %.3f, %.3f", orig[1], orig[2], orig[3])
    if src[4] ~= orig[4] or src[5] ~= orig[5] then was = was .. ", " .. tostring(orig[4]) .. (orig[5] and ", true" or "") end
    return text .. " (was " .. was .. ")"
end

function MapPins.GetEntryTitle(entry)
    local suffix = entry.deleted and " (deleted)" or entry.added and " (added)" or ""
    if entry[1] == "boss" then return format("boss: %s (%d)%s", MapPins.GetNpcName(entry[4]) or "?", entry[4], suffix) end
    if entry[1] == "level" then return format("level change -> %d%s", entry[4], suffix) end
    if entry[1] == "item" then return format("item: %s (%d)%s", MapPins.GetItemName(entry[4]), entry[4], suffix) end
    return "entrance" .. suffix
end

function MapPins.CreateInput(parent, label, x, y, onApply)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 4)
    text:SetText(label)
    local box = CreateTemplated("EditBox", nil, parent, {"InputBoxTemplate"})
    box:SetSize(56, 18)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 34, y)
    box:SetAutoFocus(false)
    if box:GetFontObject() == nil then box:SetFontObject(ChatFontNormal) end
    box:SetScript("OnEnterPressed", function(sel)
        local input = sel:GetText():gsub(",", ".")
        local value = tonumber(input)
        sel:ClearFocus()
        if value ~= nil and MapPins.selected ~= nil then
            onApply(MapPins.selected, value)
        else
            MapPins.DebugRefresh()
        end
    end)

    box:SetScript("OnEscapePressed", function(sel)
        sel:ClearFocus()
        MapPins.DebugRefresh()
    end)
    return box
end

function MapPins.CreateButton(parent, label, width, onClick)
    local button = CreateTemplated("Button", nil, parent, {"UIPanelButtonTemplate"})
    button:SetSize(width, 20)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

function MapPins.CreateDebugUI()
    if MapPins.editor ~= nil then return end
    local view = compendium.mapView
    local overlay = CreateFrame("Frame", nil, view)
    overlay:SetAllPoints(view)
    overlay:SetFrameLevel(view:GetFrameLevel() + 5)
    view.debugText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    view.debugText:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -8, 8)
    local cursor = CreateFrame("Frame", nil, view)
    cursor:SetFrameStrata("TOOLTIP")
    cursor:SetSize(1, 1)
    cursor:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    cursor.text = cursor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cursor.text:SetJustifyH("LEFT")
    local font, size = cursor.text:GetFont()
    if font ~= nil then cursor.text:SetFont(font, size, "OUTLINE") end
    cursor:SetScript("OnUpdate", function()
        local left, top = view.art:GetLeft(), view.art:GetTop()
        local w, h = view.art:GetWidth(), view.art:GetHeight()
        if view.info == nil or left == nil or top == nil or w <= 0 or h <= 0 then
            cursor.text:Hide()
            return
        end

        local scale = view:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        local x, y = (cx - left) / w, (top - cy) / h
        if x < 0 or x > 1 or y < 0 or y > 1 then
            cursor.text:Hide()
            return
        end

        cursor.text:SetText(format("Map ID: %d\n%.3f, %.3f", view.info.id, x, y))
        cursor.text:ClearAllPoints()
        cursor.text:SetPoint("TOPLEFT", view.art, "TOPLEFT", cx - left + 18, cy - top - 8)
        cursor.text:Show()
    end)

    MapPins.cursor = cursor
    local editor = CreateFrame("Frame", nil, view)
    editor:SetSize(282, 216)
    editor:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 4, 4)
    editor:SetFrameLevel(view:GetFrameLevel() + 10)
    editor:EnableMouse(true)
    editor:SetMovable(true)
    editor:SetClampedToScreen(true)
    editor:RegisterForDrag("LeftButton")
    editor:SetScript("OnDragStart", editor.StartMoving)
    editor:SetScript("OnDragStop", editor.StopMovingOrSizing)
    editor.bg = editor:CreateTexture(nil, "BACKGROUND")
    editor.bg:SetAllPoints(editor)
    editor.bg:SetColorTexture(0, 0, 0, 0.85)
    editor.title = editor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    editor.title:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -8)
    editor.title:SetWidth(266)
    editor.title:SetJustifyH("LEFT")
    editor.title:SetWordWrap(false)
    editor.x = MapPins.CreateInput(editor, "X", 8, -26, function(entry, value) MapPins.Edit(entry, entry.art, value, entry[3]) end)
    editor.y = MapPins.CreateInput(editor, "Y", 136, -26, function(entry, value) MapPins.Edit(entry, entry.art, entry[2], value) end)
    editor.map = MapPins.CreateButton(editor, "", 266, function(sel) if MapPins.selected ~= nil then MapPins.ShowMapMenu(sel, MapPins.selected) end end)
    editor.map:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -50)
    for index, step in ipairs({0.1, 0.01, 0.001}) do
        local left = 8 + (index - 1) * 92
        local label = editor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", editor, "TOPLEFT", left, -78)
        label:SetText(tostring(step))
        for _, def in ipairs({{"^", 28, -94, 0, -1}, {"<", 0, -116, -1, 0}, {">", 56, -116, 1, 0}, {"v", 28, -138, 0, 1}}) do
            local button = MapPins.CreateButton(editor, def[1], 26, function()
                local entry = MapPins.selected
                if entry ~= nil then MapPins.Edit(entry, entry.art, entry[2] + def[4] * step, entry[3] + def[5] * step) end
            end)

            button:SetPoint("TOPLEFT", editor, "TOPLEFT", left + def[2], def[3])
        end
    end

    editor.reset = MapPins.CreateButton(editor, "Reset", 52, function()
        local entry = MapPins.selected
        if entry == nil then return end
        local level = MapPins.FindLevel(GetInstanceMaps(), entry.orig[1])
        MapPins.Reset(entry)
        if level ~= nil then SelectMapLevel(level) end
    end)

    editor.reset:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -164)
    editor.delete = MapPins.CreateButton(editor, "Delete", 52, function() if MapPins.selected ~= nil then MapPins.Delete(MapPins.selected) end end)
    editor.delete:SetPoint("TOPLEFT", editor, "TOPLEFT", 62, -164)
    editor.arg = MapPins.CreateButton(editor, "", 266, function(sel) if MapPins.selected ~= nil then MapPins.ShowArgMenu(sel, MapPins.selected) end end)
    editor.arg:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -188)
    editor.up = MapPins.CreateButton(editor, "Up", 54, function()
        local entry = MapPins.selected
        if entry == nil or entry[1] ~= "level" then return end
        if entry[5] == true then
            entry[5] = nil
        else
            entry[5] = true
        end

        MapPins.Edit(entry, entry.art, entry[2], entry[3])
    end)

    editor.up:SetPoint("TOPLEFT", editor, "TOPLEFT", 116, -164)
    MapPins.editor = editor
    local output = CreateFrame("Frame", "AzerothCompendiumMapPinDebug", compendium)
    output:SetSize(960, 190)
    output:SetPoint("TOP", compendium, "BOTTOM", 0, -4)
    output:SetFrameStrata("DIALOG")
    output:SetClampedToScreen(true)
    output:EnableMouse(true)
    output:SetMovable(true)
    output:RegisterForDrag("LeftButton")
    output:SetScript("OnDragStart", output.StartMoving)
    output:SetScript("OnDragStop", output.StopMovingOrSizing)
    output.bg = output:CreateTexture(nil, "BACKGROUND")
    output.bg:SetAllPoints(output)
    output.bg:SetColorTexture(0, 0, 0, 0.9)
    output.title = output:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    output.title:SetPoint("TOPLEFT", output, "TOPLEFT", 8, -8)
    output.scroll = CreateTemplated("ScrollFrame", nil, output, {"UIPanelScrollFrameTemplate"})
    output.scroll:SetPoint("TOPLEFT", output, "TOPLEFT", 8, -28)
    output.scroll:SetPoint("BOTTOMRIGHT", output, "BOTTOMRIGHT", -328, 32)
    output.openTitle = output:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    output.openTitle:SetPoint("TOPLEFT", output, "TOPLEFT", 660, -8)
    output.openScroll = CreateTemplated("ScrollFrame", nil, output, {"UIPanelScrollFrameTemplate"})
    output.openScroll:SetPoint("TOPLEFT", output, "TOPLEFT", 660, -28)
    output.openScroll:SetPoint("BOTTOMRIGHT", output, "BOTTOMRIGHT", -28, 32)
    output.openChild = CreateFrame("Frame", nil, output.openScroll)
    output.openChild:SetSize(270, 10)
    output.open = output.openChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    output.open:SetPoint("TOPLEFT", output.openChild, "TOPLEFT", 0, 0)
    output.open:SetWidth(270)
    output.open:SetJustifyH("LEFT")
    output.openScroll:SetScrollChild(output.openChild)
    output.edit = CreateFrame("EditBox", nil, output.scroll)
    output.edit:SetMultiLine(true)
    output.edit:SetAutoFocus(false)
    output.edit:SetFontObject(ChatFontNormal)
    output.edit:SetWidth(620)
    output.edit:SetScript("OnEscapePressed", function(sel) sel:ClearFocus() end)
    output.scroll:SetScrollChild(output.edit)
    output.scroll:EnableMouse(true)
    output.scroll:SetScript("OnMouseDown", function() output.edit:SetFocus() end)
    output.select = MapPins.CreateButton(output, "Select all", 90, function()
        output.edit:SetFocus()
        output.edit:HighlightText()
    end)

    output.select:SetPoint("BOTTOMLEFT", output, "BOTTOMLEFT", 8, 6)
    output.reset = MapPins.CreateButton(output, "Reset all", 90, function()
        for index = #MapPins.entries, 1, -1 do
            local entry = MapPins.entries[index]
            if entry.added then
                MapPins.Remove(AzerothCompendium.INSTANCEMAPPINS[entry.art], entry)
                tremove(MapPins.entries, index)
            elseif MapPins.IsChanged(entry) then
                entry[4] = entry.orig[4]
                entry[5] = entry.orig[5] or nil
                entry.deleted = nil
                MapPins.Place(entry, entry.orig[1], entry.orig[2], entry.orig[3])
            end
        end

        ACOTAB["MAPPINEDITS"] = {}
        ACOTAB["MAPPINADDS"] = {}
        MapPins.selected = nil
        MapPins.Update(compendium.mapView)
    end)

    output.reset:SetPoint("LEFT", output.select, "RIGHT", 6, 0)
    local last = output.reset
    for _, def in ipairs({{"+ Entrance", 84, "entrance"}, {"+ Boss", 64, "boss"}, {"+ Quest item", 96, "item"}, {"+ Level up", 84, "level", true}, {"+ Level down", 96, "level"}}) do
        local button = MapPins.CreateButton(output, def[1], def[2], function() MapPins.Add(def[3], def[4]) end)
        button:SetPoint("LEFT", last, "RIGHT", 6, 0)
        last = button
    end

    output.close = MapPins.CreateButton(output, "Close", 70, function() AzerothCompendium:ToggleMapPinDebug() end)
    output.close:SetPoint("BOTTOMRIGHT", output, "BOTTOMRIGHT", -8, 6)
    MapPins.output = output
end

function MapPins.DebugRefresh()
    if compendium == nil then return end
    if not MapPins.debug then
        if MapPins.editor ~= nil then
            MapPins.editor:Hide()
            MapPins.output:Hide()
            MapPins.cursor:Hide()
            compendium.mapView.debugText:Hide()
        end
        return
    end

    MapPins.CreateDebugUI()
    local view = compendium.mapView
    MapPins.editor:SetFrameLevel((view.pinTopLevel or view:GetFrameLevel()) + 3)
    view.debugText:GetParent():SetFrameLevel((view.pinTopLevel or view:GetFrameLevel()) + 2)
    local counts, open = MapPins.GetOpen()
    view.debugText:SetText(view.info and format("Map ID: %d (%d unplaced)", view.info.id, counts[view.info.id] or 0) or "")
    view.debugText:Show()
    MapPins.cursor:Show()
    MapPins.output.openTitle:SetText(format("Unfinished maps (%d)", #open))
    MapPins.output.open:SetText(table.concat(open, "\n"))
    MapPins.output.openChild:SetHeight(max(10, MapPins.output.open:GetStringHeight()))
    local lines = {}
    for _, entry in ipairs(MapPins.entries) do
        if MapPins.IsChanged(entry) then tinsert(lines, MapPins.FormatEntry(entry)) end
    end

    table.sort(lines)
    MapPins.output.title:SetText(format("Map pin corrections (%d)", #lines))
    MapPins.output.edit:SetText(table.concat(lines, "\n"))
    MapPins.output:Show()
    local entry = MapPins.selected
    if entry == nil then
        MapPins.editor:Hide()
        return
    end

    local maps = GetInstanceMaps() or {}
    MapPins.editor.title:SetText(MapPins.GetEntryTitle(entry))
    MapPins.editor.x:SetText(format("%.3f", entry[2]))
    MapPins.editor.y:SetText(format("%.3f", entry[3]))
    MapPins.editor.map:SetText(format("Map: %s (%d)", GetMapLevelLabel(maps, MapPins.FindLevel(maps, entry.art)), entry.art))
    MapPins.editor.arg:SetShown(entry[1] ~= "entrance")
    if entry[1] == "boss" then
        MapPins.editor.arg:SetText(format("Boss: %s (%d)", MapPins.GetNpcName(entry[4]) or "?", entry[4]))
    elseif entry[1] == "item" then
        MapPins.editor.arg:SetText(format("Item: %s (%d)", MapPins.GetItemName(entry[4]), entry[4]))
    elseif entry[1] == "level" then
        MapPins.editor.arg:SetText(format("To: %s (%d)", GetMapLevelLabel(maps, MapPins.FindLevel(maps, entry[4])), entry[4]))
    end

    MapPins.editor.up:SetShown(entry[1] == "level")
    MapPins.editor.up:SetText(entry[5] == true and "Up" or "Down")
    MapPins.editor.delete:SetEnabled(not entry.deleted)
    MapPins.editor:Show()
end

function AzerothCompendium:ToggleMapPinDebug()
    MapPins.debug = not MapPins.debug
    MapPins.selected = nil
    AzerothCompendium:INFO(MapPins.debug and "Map pin debug enabled (/ac debug help)" or "Map pin debug disabled")
    if compendium ~= nil then MapPins.Update(compendium.mapView) end
end

function AzerothCompendium:PrintMapPinDebugHelp()
    for _, line in ipairs({"Map pin debug help:", "/ac debug - toggle the map pin editor (Map tab), /ac debug help - show this help", "While enabled every pin is shown, including unplaced and deleted ones (deleted are faded)", "Cursor on the map: map ID and coordinates, bottom right: map ID and unplaced pins of this map", "Right-click a pin: select it and open the editor (bottom left, movable)", "Editor X / Y: type a coordinate (0-1) and press Enter, Escape discards", "Editor Map button: move the pin to another map level", "Editor arrows: move the pin by 0.1, 0.01 or 0.001", "Editor Reset: restore the shipped pin, Delete: remove the pin", "Editor Up / Down: direction of a level change, Boss / Item / To button: boss, quest start item or target map of the pin", "Window below: changed pins as data rows, Select all then Ctrl+C to copy", "Window below: Unfinished maps lists the maps that still have unplaced pins", "Window below: + Entrance / + Boss / + Quest item / + Level up / + Level down add a pin at the map center", "Window below: Reset all discards every saved correction, Close leaves the debug mode",}) do
        AzerothCompendium:INFO(line)
    end
end

function AzerothCompendium:ToggleCompendium()
    CreateJournal()
    if compendium:IsShown() then
        compendium:Hide()
        return
    end

    compendium:SetFrameStrata("HIGH")
    compendium:Show()
    UpdateKindTabs()
    RefreshCurrentView()
end

function AzerothCompendium:OpenCompendium()
    CreateJournal()
    if compendium:IsShown() then return end
    compendium:SetFrameStrata("HIGH")
    compendium:Show()
    UpdateKindTabs()
    RefreshCurrentView()
end

function MapPins.GetArt(key)
    if MapPins.artKeys == nil then
        MapPins.artKeys = {}
        for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
            for _, info in ipairs(AzerothCompendium.INSTANCEMAPS and AzerothCompendium.INSTANCEMAPS[inst.id] or {}) do
                local name = strmatch(info.file, "([^\\]+)$")
                if name ~= nil and MapPins.artKeys[name] == nil then MapPins.artKeys[name] = {inst, info} end
            end
        end
    end

    local found = MapPins.artKeys[tostring(key)]
    if found == nil then return nil, nil end
    return found[1], found[2]
end

AzerothCompendiumAPI = AzerothCompendiumAPI or {}
function AzerothCompendiumAPI.ShowBossLoot(key, npcID)
    local inst = MapPins.GetArt(key)
    local boss = inst ~= nil and IsInstanceVisible(inst) and MapPins.FindBoss(npcID, inst) or nil
    if boss == nil then return false end
    AzerothCompendium:OpenCompendium()
    if inst.type == "dungeon" and type(ACOTABPC) == "table" and ACOTABPC.ONLYRELEVANT == true then
        local level = UnitLevel("player")
        if inst.minLevel == nil or inst.maxLevel == nil or level < inst.minLevel or level > inst.maxLevel then
            ACOTABPC.ONLYRELEVANT = false
            compendium.relevantFilter:SetChecked(false)
        end
    end

    listKind = inst.type
    middleKind = "bosses"
    detailKind = "loot"
    selectedInstance = inst
    selectedBoss = boss
    mapInstance = inst
    mapLevel = MapPins.GetBossLevel(boss) or 1
    searchText = ""
    SaveNavigationState()
    UpdateKindTabs()
    SetSpecialMode(nil)
    if compendium.search:GetText() ~= "" then
        compendium.search:SetText("")
    else
        RefreshInstances()
    end

    for index, entry in ipairs(GetBossList()) do
        if entry == selectedBoss then compendium.bosses:ScrollToIndex(index) end
    end

    compendium:SetFrameStrata("HIGH")
    compendium:Raise()
    return true
end

local loader = CreateFrame("Frame")
AzerothCompendium:RegisterEvent(loader, "PLAYER_LOGIN")
AzerothCompendium:RegisterEvent(loader, "PLAYER_LEVEL_UP")
AzerothCompendium:RegisterEvent(loader, "GET_ITEM_INFO_RECEIVED")
AzerothCompendium:RegisterEvent(loader, "QUEST_DATA_LOAD_RESULT")
AzerothCompendium:RegisterEvent(loader, "QUEST_LOG_UPDATE")
AzerothCompendium:RegisterEvent(loader, "QUEST_TURNED_IN")
AzerothCompendium:RegisterEvent(loader, "GROUP_ROSTER_UPDATE")
AzerothCompendium:RegisterEvent(loader, "UNIT_QUEST_LOG_CHANGED")
AzerothCompendium:RegisterEvent(loader, "GLOBAL_MOUSE_DOWN")
loader:SetScript("OnEvent", function(sel, event)
    if event == "GLOBAL_MOUSE_DOWN" then
        if compendium == nil or not compendium:IsShown() then return end
        local overMap = WorldMapFrame ~= nil and WorldMapFrame:IsShown() and WorldMapFrame:IsMouseOver()
        local overCompendium = compendium:IsMouseOver()
        if compendium:GetFrameStrata() == "LOW" then
            if overCompendium and not overMap then compendium:SetFrameStrata("HIGH") end
        elseif overMap and not overCompendium then
            compendium:SetFrameStrata("LOW")
        end
        return
    end

    if event == "PLAYER_LEVEL_UP" then
        AzerothCompendium:After(0, function() if compendium ~= nil and listKind == "dungeon" then RefreshInstances() end end, "AzerothCompendium:RelevantLevel")
        return
    end

    if event == "PLAYER_LOGIN" then
        AzerothCompendium:PreloadItems()
        return
    end

    if event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" or event == "GROUP_ROSTER_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        if compendium ~= nil and compendium:IsShown() and middleKind == "quests" then compendium.questTree:Refresh() end
        if compendium ~= nil and compendium:IsShown() and listKind == "worldquestitems" then RefreshWorldQuestItemsView() end
        return
    end

    if compendium == nil or not compendium:IsShown() then return end
    if refreshPending then return end
    refreshPending = true
    AzerothCompendium:After(0.25, function()
        refreshPending = false
        if compendium ~= nil and compendium:IsShown() then
            if listKind == "wishlist" then
                RefreshWishlistView()
            elseif listKind == "worldquestitems" then
                RefreshWorldQuestItemsView()
            else
                compendium.instances:Refresh()
                compendium.bosses:Refresh()
                compendium.loot:Refresh()
                compendium.questTree:Refresh()
                if compendium.mapView:IsShown() then MapPins.Update(compendium.mapView) end
            end
        end
    end, "AzerothCompendium:ItemInfo")
end)
