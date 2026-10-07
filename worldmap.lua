local _, AzerothCompendium = ...
local MEDIA_PATH = "Interface\\AddOns\\AzerothCompendium\\media\\"
local DEFAULT_BOSS_RANK = 1
local MAX_WORLD_MAP_TYPE = 2
local NATIVE_CHECK_MAX_ID = 1000
local ENTRANCE_SIZE = 32
local MEETING_STONE_SIZE = 20
local MEETING_STONE_INSET = 3
local PIN_LEVEL = 2000
local POI_START_SCALE = 1
local POI_END_SCALE = 1.2
local UPDATE_INTERVAL = 0.05
local GROUP_DISTANCE = 0.5
local WorldMap = {
    instanceMaps = {
        [2959] = {16544},
        [2998] = {16732},
        [2999] = {16611},
        [3065] = {16919},
        [189] = {189001, 189002, 189003, 189004},
    },
    entranceMaps = {
        [16544] = 2959,
        [16732] = 2998,
        [16611] = 2999,
        [16919] = 3065,
    },
    entranceLevels = {
        [429001] = 235,
        [429002] = 236,
        [429003] = 239,
    },
    dungeonIcon = {{"Dungeon", "DungeonSkull", "Dungeon-Normal"}, "Interface\\Icons\\INV_Misc_Bone_Skull_02"},
    raidIcon = {{"Raid", "Dungeon", "DungeonSkull", "Dungeon-Normal"}, "Interface\\Icons\\INV_Misc_Bone_Skull_02"},
    meetingStoneIcon = MEDIA_PATH .. "meetingstone",
    sharedKeys = {
        ["DUNGEONWORLDMAPPINS"] = "DUNGEONWORLDMAPPINS",
        ["DUNGEONMINIMAPPINS"] = "DUNGEONMINIMAPPINS",
        ["MEETINGSTONEWORLDMAPPINS"] = "MEETINGSTONEWORLDMAPPINS",
        ["MEETINGSTONEMINIMAPPINS"] = "MEETINGSTONEMINIMAPPINS",
        ["INSTANCEPINS_BOSS"] = "MAPPINS_BOSS",
        ["INSTANCEPINS_ITEM"] = "MAPPINS_ITEM",
        ["INSTANCEPINS_ENTRANCE"] = "MAPPINS_ENTRANCE",
        ["INSTANCEPINS_LEVEL"] = "MAPPINS_LEVEL",
    },
    checkboxes = {},
    instances = {},
    pinCache = {},
    pins = {},
    minimapPins = {},
    waypointPositions = {},
    locationState = {poiScale = 0},
    trackingAtlas = {"UI-QuestPoi-QuestNumber-SuperTracked"},
    minimapYards = {
        outdoor = {[0] = 466.66666, 400, 333.33333, 266.66666, 200, 133.33333},
        indoor = {[0] = 300, 240, 180, 120, 80, 50},
    },
}
AzerothCompendium.WorldMap = WorldMap
function AzerothCompendium:GetSharedOption(key)
    local own = WorldMap.sharedKeys[key]
    local default = true
    if strfind(own, "^MAPPINS_") then default = AzerothCompendium:GetConfig("MAPPINS", true) end
    return AzerothCompendium:GetConfig(own, default) ~= false
end

function AzerothCompendium:OnSharedOptionChanged(key, value)
    if WorldMap.checkboxes[key] ~= nil then WorldMap.checkboxes[key]:SetChecked(value) end
    WorldMap.locationKey = nil
    if WorldMap.map ~= nil then WorldMap.map:Invalidate() end
    if AzerothCompendium.RefreshMapPins ~= nil then AzerothCompendium:RefreshMapPins() end
end

function AzerothCompendium:SetSharedOption(key, value)
    AzerothCompendium:SetConfig(WorldMap.sharedKeys[key], value)
    AzerothCompendium:SetSharedSetting(key, value)
    AzerothCompendium:OnSharedOptionChanged(key, value)
end

AzerothCompendium:RegisterSharedSettings({
    ["keys"] = {"DUNGEONWORLDMAPPINS", "MEETINGSTONEWORLDMAPPINS", "DUNGEONMINIMAPPINS", "MEETINGSTONEMINIMAPPINS", "INSTANCEPINS_BOSS", "INSTANCEPINS_ITEM", "INSTANCEPINS_ENTRANCE", "INSTANCEPINS_LEVEL"},
    ["getDB"] = function() return ACOTAB end,
    ["get"] = function(key) return AzerothCompendium:GetSharedOption(key) end,
    ["set"] = function(key, value) AzerothCompendium:SetConfig(WorldMap.sharedKeys[key], value) end,
    ["onChange"] = function(key, value) AzerothCompendium:OnSharedOptionChanged(key, value) end,
})
function WorldMap.GetInstances(id)
    if WorldMap.instances[id] == nil then
        local list = {}
        for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
            if inst.id == id or inst.parentID == id then tinsert(list, inst) end
        end

        WorldMap.instances[id] = list
    end

    return WorldMap.instances[id]
end

function WorldMap.IsNative()
    if WorldMap.native ~= nil then return WorldMap.native end
    WorldMap.native = false
    if C_Map == nil or C_Map.GetMapInfo == nil then return false end
    if C_Map.GetMapInfo(947) == nil then
        WorldMap.native = true
        return true
    end

    for _, maps in pairs(AzerothCompendium.INSTANCEMAPS or {}) do
        for _, info in ipairs(maps) do
            local mapInfo = type(info.id) == "number" and info.id < NATIVE_CHECK_MAX_ID and C_Map.GetMapInfo(info.id) or nil
            if mapInfo ~= nil and mapInfo.mapType ~= nil and mapInfo.mapType > MAX_WORLD_MAP_TYPE then
                WorldMap.native = true
                return true
            end
        end
    end

    return false
end

function WorldMap.GetLevels(instanceMapID)
    local levels = {}
    for _, id in ipairs(WorldMap.instanceMaps[instanceMapID] or {instanceMapID}) do
        local inst = WorldMap.GetInstances(id)[1]
        for _, info in ipairs(AzerothCompendium.INSTANCEMAPS and AzerothCompendium.INSTANCEMAPS[id] or {}) do
            tinsert(levels, {
                ["file"] = info.file,
                ["key"] = info.id,
                ["name"] = info.name,
                ["width"] = info.width,
                ["height"] = info.height,
                ["fileWidth"] = info.fileWidth,
                ["fileHeight"] = info.fileHeight,
                ["inst"] = inst,
            })
        end
    end

    if #levels == 0 then return nil end
    return levels
end

function WorldMap.GetLabel(levels, level)
    local base = level.inst ~= nil and AzerothCompendium:GetInstanceName(level.inst) or ""
    if level.name == nil then return base end
    for _, other in ipairs(levels) do
        if other.inst ~= level.inst then return base .. " - " .. level.name end
    end

    return level.name
end

function WorldMap.GetPins(level)
    local cached = WorldMap.pinCache[level.key]
    if cached ~= nil then return cached end
    local MapPins = AzerothCompendium.MapPins
    MapPins.Init()
    local inst = level.inst
    local rows = {}
    for _, entry in ipairs(AzerothCompendium.INSTANCEMAPPINS and AzerothCompendium.INSTANCEMAPPINS[level.key] or {}) do
        if not MapPins.IsHidden(entry) then
            local kind = entry[1]
            if kind == "boss" then
                local boss = MapPins.FindBoss(entry[4], inst)
                if boss ~= nil then
                    local npcID = boss.npcs and boss.npcs[1]
                    local rank = boss.classification or npcID and AzerothCompendium.BOSSRANKS and AzerothCompendium.BOSSRANKS[npcID] or DEFAULT_BOSS_RANK
                    tinsert(rows, {"boss", entry[2], entry[3], entry[4], AzerothCompendium:GetBossName(boss), boss.level, boss.model, rank})
                end
            elseif kind == "level" then
                tinsert(rows, {"level", entry[2], entry[3], entry[4], entry[5] == true})
            elseif kind == "item" then
                if type(entry[4]) == "number" then tinsert(rows, {"item", entry[2], entry[3], entry[4]}) end
            else
                tinsert(rows, {"entrance", entry[2], entry[3], inst ~= nil and inst.type == "raid" and "raid" or nil})
            end
        end
    end

    WorldMap.pinCache[level.key] = rows
    return rows
end

function WorldMap.GetPinType(kind)
    for _, def in ipairs(AzerothCompendium.MapPins.types) do
        if def[1] == kind then return def end
    end

    return nil
end

WorldMap.map = AzerothCompendium:CreateInstanceMap({
    ["media"] = MEDIA_PATH,
    ["isDisabled"] = WorldMap.IsNative,
    ["getLevels"] = WorldMap.GetLevels,
    ["getLabel"] = WorldMap.GetLabel,
    ["getPins"] = WorldMap.GetPins,
    ["getBossHint"] = function() return AzerothCompendium:Trans("LID_MAPPINBOSSHINT") end,
    ["getLevelHint"] = function() return AzerothCompendium:Trans("LID_MAPPINLEVELHINT") end,
    ["getEntranceText"] = function() return AzerothCompendium:Trans("LID_ENTRANCE") end,
    ["getEntranceHint"] = function() return AzerothCompendium:Trans("LID_RIGHTCLICK") .. ": " .. AzerothCompendium:Trans("LID_SHOWENTRANCEMAP") end,
    ["getReturnMapID"] = function(level)
        local inst = level ~= nil and level.inst or nil
        if inst ~= nil then
            local location = AzerothCompendium.INSTANCEENTRANCES[inst.id] or (inst.parentID ~= nil and AzerothCompendium.INSTANCEENTRANCES[inst.parentID])
            if type(location) == "table" then return location[1] end
            for id, entry in pairs(AzerothCompendium.INSTANCEENTRANCES) do
                if (entry[4] or id) == inst.id or (entry[4] or id) == inst.parentID then return entry[1] end
            end
        end

        return WorldMap.returnMapID
    end,
    ["onBossClick"] = function(level, row) AzerothCompendiumAPI.ShowBossLoot(strmatch(level.file, "([^\\]+)$"), row[4]) end,
    ["isPinEnabled"] = function(kind) return AzerothCompendium.MapPins.IsEnabled(kind) end,
    ["setPinEnabled"] = function(kind, enabled) AzerothCompendium:SetSharedOption("INSTANCEPINS_" .. strupper(kind), enabled) end,
    ["getToggleText"] = function(kind, enabled)
        local def = WorldMap.GetPinType(kind)
        return def ~= nil and AzerothCompendium:Trans((enabled and "LID_HIDE" or "LID_SHOW") .. def[3]) or ""
    end,
})

function WorldMap.AddLocation(groups, kind, id, location)
    local insts = WorldMap.GetInstances(location[4] or id)
    if #insts == 0 then return end
    if insts[1].forever and AzerothCompendium:IsClassicEraClient() then return end
    local mapID = location[1]
    groups[mapID] = groups[mapID] or {}
    local group = nil
    for _, other in ipairs(groups[mapID]) do
        if other.kind == kind and abs(other.x - location[2]) < GROUP_DISTANCE and abs(other.y - location[3]) < GROUP_DISTANCE then group = other end
    end

    if group == nil then
        group = {
            ["kind"] = kind,
            ["mapID"] = mapID,
            ["x"] = location[2],
            ["y"] = location[3],
            ["raid"] = true,
            ["entries"] = {},
        }

        tinsert(groups[mapID], group)
    end

    local minLevel, maxLevel = nil, nil
    for _, inst in ipairs(insts) do
        if inst.minLevel ~= nil and (minLevel == nil or inst.minLevel < minLevel) then minLevel = inst.minLevel end
        if inst.maxLevel ~= nil and (maxLevel == nil or inst.maxLevel > maxLevel) then maxLevel = inst.maxLevel end
        if inst.type ~= "raid" then group.raid = false end
    end

    tinsert(group.entries, {
        ["id"] = id,
        ["inst"] = insts[1],
        ["minLevel"] = minLevel,
        ["maxLevel"] = maxLevel,
        ["instanceMapID"] = WorldMap.entranceMaps[id] or location[4] or id,
        ["level"] = WorldMap.entranceLevels[id],
    })
end

function WorldMap.GetLocations(mapID)
    if WorldMap.locations == nil then
        local groups = {}
        for id, location in pairs(AzerothCompendium.INSTANCEENTRANCES or {}) do
            WorldMap.AddLocation(groups, "entrance", id, location)
        end

        for id, location in pairs(AzerothCompendium.MEETINGSTONES or {}) do
            WorldMap.AddLocation(groups, "meetingstone", id, location)
        end

        for _, list in pairs(groups) do
            for _, group in ipairs(list) do
                table.sort(group.entries, function(a, b)
                    if (a.minLevel or 0) ~= (b.minLevel or 0) then return (a.minLevel or 0) < (b.minLevel or 0) end
                    return a.id < b.id
                end)
            end
        end

        WorldMap.locations = groups
    end

    return WorldMap.locations[mapID]
end

function WorldMap.GetLevelIndex(entry)
    if entry.level == nil then return nil end
    for index, level in ipairs(WorldMap.GetLevels(entry.instanceMapID) or {}) do
        if level.key == entry.level then return index end
    end

    return nil
end

function WorldMap.GetEntryName(entry)
    local name = AzerothCompendium:GetInstanceBaseName(entry.inst)
    local index = WorldMap.GetLevelIndex(entry)
    local level = index ~= nil and WorldMap.GetLevels(entry.instanceMapID)[index] or nil
    if level ~= nil and level.name ~= nil then name = name .. " - " .. level.name end
    if entry.minLevel == nil then return name end
    local maxLevel = max(entry.maxLevel or entry.minLevel, entry.minLevel)
    local range = maxLevel > entry.minLevel and format("%d-%d", entry.minLevel, maxLevel) or tostring(entry.minLevel)
    return format("%s %s(%s)|r", name, WorldMap.GetLevelColorCode(entry.minLevel, maxLevel), range)
end

function WorldMap.GetLevelColorCode(minLevel, maxLevel)
    local playerLevel = UnitLevel("player")
    if playerLevel < minLevel then return AzerothCompendium:GetColorCode(AzerothCompendium:GetLevelDifficultyColor(minLevel)) end
    if playerLevel > maxLevel then return AzerothCompendium:GetColorCode(AzerothCompendium:GetLevelDifficultyColor(maxLevel - 2)) end
    local color = QuestDifficultyColors and QuestDifficultyColors["difficult"]
    if color == nil then return AzerothCompendium:GetColorCode(1, 0.82, 0) end
    return AzerothCompendium:GetColorCode(color.r, color.g, color.b)
end

function WorldMap.CanShowInstanceMap(group)
    if group.kind ~= "entrance" or WorldMap.IsNative() then return false end
    for _, entry in ipairs(group.entries) do
        if WorldMap.GetLevels(entry.instanceMapID) ~= nil then return true end
    end

    return false
end

function WorldMap.OnPinEnter(pin)
    local group = pin.group
    if group == nil then return end
    local meetingStone = group.kind == "meetingstone"
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    for _, entry in ipairs(group.entries) do
        GameTooltip:AddLine(WorldMap.GetEntryName(entry), 1, 1, 1)
    end

    GameTooltip:AddLine(AzerothCompendium:Trans(meetingStone and "LID_MEETINGSTONE" or "LID_ENTRANCE"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans(meetingStone and "LID_SETMEETINGSTONEWAYPOINT" or "LID_SETENTRANCEWAYPOINT"), 1, 0.82, 0, 1, 1, 1)
    if WorldMap.CanShowInstanceMap(group) then GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_RIGHTCLICK"), AzerothCompendium:Trans("LID_SHOWINSTANCEMAP"), 1, 0.82, 0, 1, 1, 1) end
    GameTooltip:Show()
end

function WorldMap.OnPinLeave(pin)
    if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
end

function WorldMap.OnPinClick(pin, button)
    local group = pin.group
    if group == nil then return end
    if button == "RightButton" then
        if not WorldMap.CanShowInstanceMap(group) then return end
        local ids = {}
        for _, entry in ipairs(group.entries) do
            tinsert(ids, entry.instanceMapID)
        end

        if WorldMapFrame == nil then return end
        if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
        if WorldMapFrame.SetMapID ~= nil then WorldMapFrame:SetMapID(group.mapID) end
        WorldMap.returnMapID = group.mapID
        WorldMap.OnPinLeave(pin)
        WorldMap.map:Show(ids, #group.entries == 1 and WorldMap.GetLevelIndex(group.entries[1]) or nil)
        return
    end

    if button ~= "LeftButton" then return end
    local _, reason = AzerothCompendium:SetMapWaypoint(group.mapID, group.x, group.y)
    if reason == "combat" then AzerothCompendium:INFO(AzerothCompendium:Trans("LID_WAYPOINTCOMBAT")) end
end

function WorldMap.CreatePin(parent)
    local pin = CreateFrame("Button", nil, parent)
    pin.circle = pin:CreateTexture(nil, "ARTWORK")
    pin.circle:SetAllPoints(pin)
    pin.circle:Hide()
    pin.icon = pin:CreateTexture(nil, "OVERLAY")
    pin.highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetAlpha(0.5)
    pin.textures = {pin.icon, pin.highlight}
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin:SetScript("OnClick", WorldMap.OnPinClick)
    pin:SetScript("OnEnter", WorldMap.OnPinEnter)
    pin:SetScript("OnLeave", WorldMap.OnPinLeave)
    return pin
end

function WorldMap.ApplyIcon(pin, group, size)
    local meetingStone = group.kind == "meetingstone"
    local icon = WorldMap.meetingStoneIcon
    local inset = 0
    if meetingStone then
        inset = MEETING_STONE_INSET * size / MEETING_STONE_SIZE
    else
        local def = group.raid and WorldMap.raidIcon or WorldMap.dungeonIcon
        if def.resolved == nil then def.resolved = AzerothCompendium:FindAtlas(def[1]) or def[2] end
        icon = def.resolved
    end

    for _, texture in ipairs(pin.textures) do
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", pin, "TOPLEFT", inset, -inset)
        texture:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -inset, inset)
        AzerothCompendium:SetIconTexture(texture, icon, meetingStone)
    end
end

function WorldMap.UpdatePinStyle(pin)
    if pin.group == nil then return end
    local tracked = false
    if C_Map ~= nil and C_Map.GetUserWaypointPositionForMap ~= nil and AzerothCompendium:IsWaypointTracked() then
        local pos = WorldMap.waypointPositions[pin.group.mapID]
        if pos == nil then
            pos = C_Map.GetUserWaypointPositionForMap(pin.group.mapID) or false
            WorldMap.waypointPositions[pin.group.mapID] = pos
        end
        if pos ~= false then
            local x, y = pos:GetXY()
            if not WorldMap.IsSecret(x) and not WorldMap.IsSecret(y) and x ~= nil and y ~= nil then
                tracked = abs(x - pin.group.x / 100) < 0.001 and abs(y - pin.group.y / 100) < 0.001
            end
        end
    end

    local size = pin:GetWidth()
    if pin.styleGroup == pin.group and pin.styleSize == size and pin.styleTracked == tracked then return end
    pin.styleGroup = pin.group
    pin.styleSize = size
    pin.styleTracked = tracked
    if tracked and WorldMap.trackingAtlas.resolved == nil then WorldMap.trackingAtlas.resolved = AzerothCompendium:FindAtlas(WorldMap.trackingAtlas) or false end
    local atlas = tracked and WorldMap.trackingAtlas.resolved or nil
    if atlas then
        pin.circle:SetAtlas(atlas)
        pin.circle:Show()
    else
        pin.circle:Hide()
    end

    WorldMap.ApplyIcon(pin, pin.group, size)
    if atlas then
        local inset = size * 0.14
        if pin.group.kind == "meetingstone" then inset = size * 0.21 end
        for _, texture in ipairs(pin.textures) do
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", pin, "TOPLEFT", inset, -inset)
            texture:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -inset, inset)
        end
    end
end

function WorldMap.RefreshWaypoint()
    wipe(WorldMap.waypointPositions)
    for _, pin in ipairs(WorldMap.pins) do
        if pin:IsShown() then WorldMap.UpdatePinStyle(pin) end
    end

    for _, pin in ipairs(WorldMap.minimapPins) do
        if pin:IsShown() then WorldMap.UpdatePinStyle(pin) end
    end
end

if C_Map ~= nil and C_Map.GetUserWaypointPositionForMap ~= nil then
    WorldMap.waypointUpdater = CreateFrame("FRAME")
    WorldMap.waypointUpdater:RegisterEvent("USER_WAYPOINT_UPDATED")
    if C_SuperTrack ~= nil then WorldMap.waypointUpdater:RegisterEvent("SUPER_TRACKING_CHANGED") end
    WorldMap.waypointUpdater:SetScript("OnEvent", WorldMap.RefreshWaypoint)
end

function WorldMap.IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

function WorldMap.GetMinimapOffset(group, wx, wy, scale, radius, cosF, sinF)
    if group.worldPos == nil then
        local _, pos = C_Map.GetWorldPosFromMapPos(group.mapID, CreateVector2D(group.x / 100, group.y / 100))
        if pos ~= nil then group.worldPos = pos end
    end

    if group.worldPos == nil then return nil end
    local x, y = group.worldPos:GetXY()
    if x == nil or y == nil or WorldMap.IsSecret(x) or WorldMap.IsSecret(y) then return nil end
    local dx, dy = x - wx, y - wy
    local sx = -(dy * cosF - dx * sinF) * scale
    local sy = (dx * cosF + dy * sinF) * scale
    if sx * sx + sy * sy > radius * radius then return nil end
    return sx, sy
end

WorldMap.minimapLast = {time = 0}
function WorldMap.UpdateMinimap()
    local last = WorldMap.minimapLast
    local mapID = C_Map ~= nil and C_Map.GetBestMapForUnit ~= nil and C_Map.GetBestMapForUnit("player") or nil
    local wx, wy
    if UnitPosition ~= nil then wx, wy = UnitPosition("player") end
    local facing = GetPlayerFacing ~= nil and GetPlayerFacing() or 0
    local zoom = Minimap:GetZoom()
    local now = GetTime()
    if not (WorldMap.IsSecret(mapID) or WorldMap.IsSecret(wx) or WorldMap.IsSecret(wy) or WorldMap.IsSecret(facing) or WorldMap.IsSecret(zoom)) then
        if last.mapID == mapID and last.x == wx and last.y == wy and last.facing == facing and last.zoom == zoom and now - last.time < 1 then return end
        last.mapID, last.x, last.y, last.facing, last.zoom, last.time = mapID, wx, wy, facing, zoom, now
    end

    WorldMap.RedrawMinimap()
end

function WorldMap.RedrawMinimap()
    for _, pin in ipairs(WorldMap.minimapPins) do
        pin:Hide()
    end

    if not WorldMap.IsLocationOwner() or C_Map == nil or C_Map.GetBestMapForUnit == nil or C_Map.GetWorldPosFromMapPos == nil or UnitPosition == nil then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    local groups = mapID ~= nil and WorldMap.GetLocations(mapID) or nil
    if groups == nil then return end
    local wx, wy = UnitPosition("player")
    if wx == nil or wy == nil or WorldMap.IsSecret(wx) or WorldMap.IsSecret(wy) then return end
    local zoom = Minimap:GetZoom()
    if zoom == nil then return end
    local inside = tonumber(AzerothCompendium:GetCVar("minimapInsideZoom") or "")
    local outside = tonumber(AzerothCompendium:GetCVar("minimapZoom") or "")
    local yards = (inside == zoom and outside ~= zoom and WorldMap.minimapYards.indoor or WorldMap.minimapYards.outdoor)[zoom]
    if yards == nil or yards <= 0 then return end
    local width = Minimap:GetWidth()
    local scale = width / yards
    local radius = width / 2
    local facing = 0
    if AzerothCompendium:GetCVar("rotateMinimap") == "1" then facing = GetPlayerFacing() or 0 end
    if WorldMap.IsSecret(facing) then return end
    local cosF, sinF = math.cos(facing), math.sin(facing)
    local count = 0
    for _, group in ipairs(groups) do
        local enabled = AzerothCompendium:GetSharedOption(group.kind == "meetingstone" and "MEETINGSTONEMINIMAPPINS" or "DUNGEONMINIMAPPINS")
        if enabled then
            local sx, sy = WorldMap.GetMinimapOffset(group, wx, wy, scale, radius, cosF, sinF)
            if sx ~= nil then
                count = count + 1
                local pin = WorldMap.minimapPins[count]
                if pin == nil then
                    pin = WorldMap.CreatePin(Minimap)
                    WorldMap.minimapPins[count] = pin
                end

                pin.group = group
                pin:SetSize(MEETING_STONE_SIZE, MEETING_STONE_SIZE)
                pin:SetFrameLevel(Minimap:GetFrameLevel() + 10)
                WorldMap.UpdatePinStyle(pin)
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
                pin:Show()
            end
        end
    end
end

if Minimap ~= nil then
    WorldMap.minimapUpdater = CreateFrame("FRAME", nil, Minimap)
    WorldMap.minimapUpdater.elapsed = 0
    WorldMap.minimapUpdater:SetScript("OnUpdate", function(sel, elapsed)
        sel.elapsed = sel.elapsed + elapsed
        if sel.elapsed < UPDATE_INTERVAL then return end
        sel.elapsed = 0
        WorldMap.UpdateMinimap()
    end)
end

function WorldMap.GetCanvas()
    if WorldMapFrame == nil then return nil end
    if WorldMapFrame.GetCanvas ~= nil then return WorldMapFrame:GetCanvas() end
    if WorldMapFrame.ScrollContainer == nil then return nil end
    return WorldMapFrame.ScrollContainer.Child
end

function WorldMap.GetPoiScale()
    local zoom = 0
    if WorldMapFrame.GetCanvasZoomPercent ~= nil then zoom = WorldMapFrame:GetCanvasZoomPercent() or 0 end
    zoom = min(max(zoom, 0), 1)
    local scale = POI_START_SCALE + (POI_END_SCALE - POI_START_SCALE) * zoom
    if WorldMapFrame.GetGlobalPinScale ~= nil then scale = scale * (WorldMapFrame:GetGlobalPinScale() or 1) end
    return scale
end

function WorldMap.IsLocationOwner()
    if WorldMap.locationOwner == nil then WorldMap.locationOwner = not AzerothCompendium:IsAddOnLoaded("MapUtils") end
    return WorldMap.locationOwner
end

function WorldMap.UpdateLocations()
    local child = WorldMap.GetCanvas()
    if child == nil or WorldMapFrame.GetMapID == nil then return end
    local mapID = WorldMapFrame:GetMapID()
    local scale = child:GetScale()
    local poiScale = WorldMap.GetPoiScale()
    local entrancesOn = AzerothCompendium:GetSharedOption("DUNGEONWORLDMAPPINS")
    local meetingStonesOn = AzerothCompendium:GetSharedOption("MEETINGSTONEWORLDMAPPINS")
    for _, pin in ipairs(WorldMap.pins) do
        if pin:IsShown() then WorldMap.UpdatePinStyle(pin) end
    end

    local last = WorldMap.locationState
    if WorldMap.locationKey == true and last.mapID == mapID and abs((last.scale or 0) - (scale or 0)) < 0.00005 and abs(last.poiScale - poiScale) < 0.00005 and last.entrancesOn == entrancesOn and last.meetingStonesOn == meetingStonesOn then return end
    WorldMap.locationKey = true
    last.mapID, last.scale, last.poiScale, last.entrancesOn, last.meetingStonesOn = mapID, scale, poiScale, entrancesOn, meetingStonesOn
    for _, pin in ipairs(WorldMap.pins) do
        pin:Hide()
    end

    local groups = WorldMap.IsLocationOwner() and WorldMap.GetLocations(mapID) or nil
    if groups == nil or scale == nil or scale <= 0 then return end
    local w = child:GetWidth()
    local h = child:GetHeight()
    local count = 0
    for _, group in ipairs(groups) do
        local meetingStone = group.kind == "meetingstone"
        if meetingStone and meetingStonesOn or not meetingStone and entrancesOn then
            count = count + 1
            local pin = WorldMap.pins[count]
            if pin == nil then
                pin = WorldMap.CreatePin(child)
                WorldMap.pins[count] = pin
            end

            local size = (meetingStone and MEETING_STONE_SIZE or ENTRANCE_SIZE) * poiScale / scale
            pin.group = group
            pin:SetSize(size, size)
            pin:SetFrameLevel(child:GetFrameLevel() + PIN_LEVEL)
            WorldMap.UpdatePinStyle(pin)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", child, "TOPLEFT", w * group.x / 100, -h * group.y / 100)
            pin:Show()
        end
    end
end

if WorldMapFrame ~= nil then
    WorldMapFrame:HookScript("OnShow", function()
        wipe(WorldMap.pinCache)
        WorldMap.map:Invalidate()
    end)

    local updater = CreateFrame("FRAME", nil, WorldMapFrame)
    updater.elapsed = 0
    updater:SetScript("OnUpdate", function(sel, elapsed)
        sel.elapsed = sel.elapsed + elapsed
        if sel.elapsed < UPDATE_INTERVAL then return end
        sel.elapsed = 0
        WorldMap.UpdateLocations()
    end)
end

AzerothCompendiumAPI = AzerothCompendiumAPI or {}
function AzerothCompendiumAPI.ShowInstanceMap(instances, level)
    return WorldMap.map:Show(instances, level)
end

function AzerothCompendiumAPI.IsInstanceMapShown()
    return WorldMap.map:IsShown()
end

function AzerothCompendiumAPI.ToggleInstanceMap()
    return WorldMap.map:Toggle()
end
