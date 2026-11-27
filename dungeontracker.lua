local _, AzerothCompendium = ...
local Tracker = {}
AzerothCompendium.DungeonTracker = Tracker
Tracker.config = {
    width = 340,
    minWidth = 260,
    lootExtra = 110,
    side = 12,
    top = 38,
    bottom = 24,
    gap = 8,
    stats = 66,
    label = 18,
    panelPad = 8,
    portrait = 25,
    cellW = 50,
    cellH = 50,
    iconX = 21,
    iconY = 19,
    badge = 14,
    badgeFont = 8,
    skullLevel = 63,
    lootRow = 20,
    lootMin = 64,
    collapsed = 30,
    collapsedModern = 40,
    scaleMin = 0.5,
    scaleMax = 1.5,
    scaleStep = 0.01,
    restartDelay = 1800,
    historyMax = 50,
    runRow = 38,
    runsHeight = 260,
    minQuality = 2,
    defaultQuality = 3,
    media = "Interface\\AddOns\\AzerothCompendium\\media\\",
    fallback = "Interface\\Icons\\INV_Misc_QuestionMark",
    deadMark = "Interface\\RaidFrame\\ReadyCheck-NotReady",
    mask = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
}

Tracker.ranks = {
    [0] = {
        ring = {0.55, 0.5, 0.4}
    },
    [1] = {
        dragon = "BossDragon-Elite",
        ring = {0.95, 0.75, 0.25}
    },
    [2] = {
        dragon = "BossDragon-Rare-Elite",
        ring = {0.85, 0.87, 0.95},
        rare = true
    },
    [3] = {
        dragon = "BossDragon-Elite",
        ring = {0.95, 0.75, 0.25}
    },
    [4] = {
        dragon = "BossDragon-Rare",
        ring = {0.85, 0.87, 0.95},
        rare = true
    },
}

Tracker.qualities = {
    ["9d9d9d"] = 0,
    ["ffffff"] = 1,
    ["1eff00"] = 2,
    ["0070dd"] = 3,
    ["a335ee"] = 4,
    ["ff8000"] = 5,
    ["e6cc80"] = 6,
}

Tracker.qualityOrder = {2, 3, 4, 5}
Tracker.qualityFallbacks = {
    [2] = {0.12, 1, 0},
    [3] = {0, 0.44, 0.87},
    [4] = {0.64, 0.21, 0.93},
    [5] = {1, 0.5, 0},
}

Tracker.qualityNames = {
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
}

Tracker.icons = {}
Tracker.elapsed = 0
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

function Tracker:IsEnabled()
    return AzerothCompendium:GetConfig("DUNGEONTRACKER", true) == true
end

function Tracker:GetRun()
    if type(ACOTABPC) ~= "table" then return nil end
    local run = ACOTABPC.DUNGEONRUN
    if type(run) ~= "table" then return nil end

    return run
end

function Tracker:BuildPattern(fmt, full)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    fmt = fmt:gsub("%%%d%$", "%%")
    fmt = fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    fmt = fmt:gsub("%%s", "(.-)"):gsub("%%d", "(%%d+)"):gsub("%%%%%.%d*f", "[%%d%%.%%,]+"):gsub("%%f", "[%%d%%.%%,]+")

    return "^" .. fmt .. (full and "$" or "")
end

function Tracker:GetPatterns()
    if self.patterns then return self.patterns end
    local patterns = {
        loot = {},
        rep = {},
        xp = self:BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON),
        reset = self:BuildPattern(INSTANCE_RESET_SUCCESS)
    }

    for _, fmt in ipairs({FACTION_STANDING_INCREASED_DOUBLE_BONUS, FACTION_STANDING_INCREASED_ACH_BONUS, FACTION_STANDING_INCREASED_BONUS, FACTION_STANDING_INCREASED_ACCOUNT_WIDE_ACH_BONUS, FACTION_STANDING_INCREASED_ACCOUNT_WIDE, FACTION_STANDING_INCREASED}) do
        local pattern = self:BuildPattern(fmt)
        if pattern then tinsert(patterns.rep, pattern) end
    end

    for _, info in ipairs({{LOOT_ITEM_SELF_MULTIPLE, true}, {LOOT_ITEM_SELF, true}, {LOOT_ITEM_MULTIPLE, false}, {LOOT_ITEM, false}}) do
        local pattern = self:BuildPattern(info[1], true)
        if pattern then
            tinsert(patterns.loot, {
                pattern = pattern,
                self = info[2]
            })
        end
    end

    self.patterns = patterns

    return patterns
end

function Tracker:GetCurrentInstance()
    if IsInInstance == nil or GetInstanceInfo == nil then return nil end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return nil end
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if IsSecret(name) or IsSecret(instanceID) or instanceID == nil then return nil end

    return instanceID, name
end

function Tracker:FindCandidates(instanceID, name, historic)
    local list = {}
    local instances = AzerothCompendium.INSTANCES or {}
    local mapped = AzerothCompendium.WorldMap and AzerothCompendium.WorldMap.instanceMaps and AzerothCompendium.WorldMap.instanceMaps[instanceID]
    local wanted = nil
    if mapped ~= nil then
        wanted = {}
        for _, id in ipairs(mapped) do
            wanted[id] = true
        end
    end

    for _, inst in ipairs(instances) do
        if inst.id == instanceID or inst.parentID == instanceID or (wanted ~= nil and wanted[inst.id]) then tinsert(list, inst) end
    end

    if #list > 0 or type(name) ~= "string" then return list end
    for _, inst in ipairs(instances) do
        if inst.name == name or AzerothCompendium:GetInstanceBaseName(inst) == name then tinsert(list, inst) end
    end

    if #list > 0 or historic or C_Map == nil or C_Map.GetBestMapForUnit == nil then return list end
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID == nil or IsSecret(mapID) then return list end
    for _, inst in ipairs(instances) do
        if inst.uiMapID == mapID then tinsert(list, inst) end
    end

    return list
end

function Tracker:IndexCandidates()
    self.npcWing = {}
    for _, inst in ipairs(self.candidates or {}) do
        for _, boss in ipairs(inst.bosses or {}) do
            if not boss.trash and not boss.all and type(boss.npcs) == "table" then
                for _, npcID in ipairs(boss.npcs) do
                    local known = self.npcWing[npcID]
                    if known == nil then
                        self.npcWing[npcID] = inst.id
                    elseif known ~= inst.id then
                        self.npcWing[npcID] = 0
                    end
                end
            end
        end
    end
end

function Tracker:GetBossRank(boss)
    local npcID = boss.npcs[1]

    return boss.classification or AzerothCompendium.BOSSRANKS and AzerothCompendium.BOSSRANKS[npcID] or 1
end

function Tracker:GetRunCandidates(run)
    if run == self:GetRun() then
        if self.candidates == nil then
            self.candidates = self:FindCandidates(run.instanceID, run.name)
            self:IndexCandidates()
        end

        return self.candidates
    end

    self.runCandidates = self.runCandidates or setmetatable({}, {
        __mode = "k"
    })

    local list = self.runCandidates[run]
    if list == nil then
        list = self:FindCandidates(run.instanceID, run.name, true)
        self.runCandidates[run] = list
    end

    return list
end

function Tracker:GetRunTitle(run)
    local candidates = self:GetRunCandidates(run)
    local inst = candidates[1]
    if run.wing then
        for _, candidate in ipairs(candidates) do
            if candidate.id == run.wing then inst = candidate end
        end
    end

    if inst and (run.wing or #candidates == 1) then return AzerothCompendium:GetInstanceName(inst) end

    return run.name or ""
end

function Tracker:GetHistory()
    ACOTABPC = ACOTABPC or {}
    if type(ACOTABPC.DUNGEONRUNS) ~= "table" then ACOTABPC.DUNGEONRUNS = {} end

    return ACOTABPC.DUNGEONRUNS
end

function Tracker:ArchiveRun(run)
    if type(run) ~= "table" or not run.start or type(run.killed) ~= "table" or type(run.loot) ~= "table" then return end
    if not run.mode and next(run.killed) == nil and #run.loot == 0 and (run.xp or 0) <= 0 and (run.rep or 0) <= 0 and (run.gold or 0) <= 0 then return end
    local history = self:GetHistory()
    for _, entry in ipairs(history) do
        if entry == run then return end
    end

    run.active = nil
    run.closed = nil
    run.reset = nil
    run.left = run.left or time()
    tinsert(history, 1, run)
    for index = #history, self.config.historyMax + 1, -1 do
        tremove(history, index)
    end
end

function Tracker:GetAllRuns()
    local list = {}
    local current = self:GetRun()
    if current and current.start then tinsert(list, current) end
    for _, run in ipairs(self:GetHistory()) do
        if run ~= current then tinsert(list, run) end
    end

    return list
end

function Tracker:GetShownRun()
    return self.viewRun or self:GetRun()
end

function Tracker:GetBosses(run)
    local bosses, rares, seen = {}, {}, {}
    for _, inst in ipairs(self:GetRunCandidates(run)) do
        if run.wing == nil or run.wing == inst.id then
            for index, boss in ipairs(inst.bosses or {}) do
                local npcID = not boss.trash and not boss.all and type(boss.npcs) == "table" and boss.npcs[1]
                if npcID and not seen[npcID] then
                    seen[npcID] = true
                    local rank = self:GetBossRank(boss)
                    local style = self.ranks[rank]
                    local target = style and style.rare and rares or bosses
                    tinsert(target, {
                        boss = boss,
                        rank = rank,
                        order = index,
                        level = AzerothCompendium:GetBossLevel(boss) or 1000
                    })
                end
            end
        end
    end

    local function Compare(a, b)
        if a.level ~= b.level then return a.level < b.level end

        return a.order < b.order
    end

    sort(bosses, Compare)
    sort(rares, Compare)

    return bosses, rares
end

function Tracker:IsKilled(run, boss)
    for _, npcID in ipairs(boss.npcs) do
        if run.killed[npcID] then return true end
    end

    return false
end

function Tracker:IsBossKilled(target)
    if target == nil or not self:IsEnabled() then return false end
    local run = self:GetRun()
    if run == nil or type(run.killed) ~= "table" then return false end
    if not self:IsCurrentInstance(run) and not (self.away and run.active) then return false end
    if type(target) == "table" and type(target.npcs) == "table" then return self:IsKilled(run, target) end
    if run.killed[target] then return true end
    for _, inst in ipairs(self:GetRunCandidates(run)) do
        for _, boss in ipairs(inst.bosses or {}) do
            if not boss.trash and not boss.all and type(boss.npcs) == "table" then
                for _, npcID in ipairs(boss.npcs) do
                    if npcID == target and self:IsKilled(run, boss) then return true end
                end
            end
        end
    end

    return false
end

function Tracker:NotifyMapChange()
    if AzerothCompendium.RefreshMapPins ~= nil then AzerothCompendium:RefreshMapPins() end
    if AzerothCompendium.WorldMap ~= nil and AzerothCompendium.WorldMap.map ~= nil and AzerothCompendium.WorldMap.map.Invalidate ~= nil then AzerothCompendium.WorldMap.map:Invalidate() end
    if AzerothCompendium.DungeonMapWidget ~= nil and AzerothCompendium.DungeonMapWidget.RefreshPins ~= nil then AzerothCompendium.DungeonMapWidget:RefreshPins() end
end

function Tracker:CountKilled(run, list)
    local count = 0
    for _, entry in ipairs(list) do
        if self:IsKilled(run, entry.boss) then count = count + 1 end
    end

    return count
end

function Tracker:PrepareRun(instanceID, name)
    local run = {
        instanceID = instanceID,
        name = name,
        xp = 0,
        rep = 0,
        factions = {},
        gold = 0,
        killed = {},
        loot = {},
        active = true
    }

    ACOTABPC = ACOTABPC or {}
    self:ArchiveRun(ACOTABPC.DUNGEONRUN)
    ACOTABPC.DUNGEONRUN = run

    return run
end

function Tracker:CheckZone()
    local instanceID, name = self:GetCurrentInstance()
    local run = self:GetRun()
    local now = time()
    if instanceID == nil then
        local wasInside = self.instanceID ~= nil
        local dead = UnitIsDeadOrGhost("player")
        local isGhost = not IsSecret(dead) and dead == true
        self.instanceID = nil
        if run and run.active and run.start and not run.ended and (not run.finished or run.mode == "unranked") and (wasInside or self.away or isGhost) and self:ShouldStayAway() then
            self.away = true
        else
            self:EndRun(run)
            self.forced = false
        end

        self:UpdateVisibility()
        self:NotifyMapChange()

        return
    end

    self.away = false

    local entering = self.instanceID ~= instanceID
    if run == nil or run.instanceID ~= instanceID or run.reset or (not run.active and run.left and now - run.left > self.config.restartDelay) then
        run = self:PrepareRun(instanceID, name)
        entering = true
    end

    if entering and self:IsEnabled() then
        run.closed = nil
        self.listMode = nil
        self.viewRun = nil
        self.forced = false
    end

    run.active = true
    run.left = nil
    self.instanceID = instanceID
    self.candidates = self:FindCandidates(instanceID, name)
    self:IndexCandidates()
    if GetMoney then self.money = GetMoney() end
    self.repSnapshot = self:SnapshotReputation()
    local inCombat = UnitAffectingCombat("player")
    if not IsSecret(inCombat) and inCombat then self:StartRankedRun() end
    self:UpdateVisibility()
    self:NotifyMapChange()
end

function Tracker:StartRankedRun()
    local run = self:GetRun()
    if not run or run.start or run.mode or not self:IsCurrentInstance(run) then return end
    run.start = time()
    run.mode = "ranked"
    if GetMoney then self.money = GetMoney() end
    self.repSnapshot = self:SnapshotReputation()
end

function Tracker:IsCurrentInstance(run)
    return run.active == true and self.instanceID ~= nil and run.instanceID == self.instanceID
end

function Tracker:ControlRun(action)
    local run = self:GetRun()
    if not run or not self:IsCurrentInstance(run) or run.ended or (run.finished and run.mode ~= "unranked") then return end

    local now = time()
    if action == "start" then
        if run.mode == "unranked" and not run.paused then return end
        run.mode = "unranked"
        run.start = run.start or now
        if run.paused then
            run.pauseTime = (run.pauseTime or 0) + now - run.paused
            run.paused = nil
        end
        if GetMoney then self.money = GetMoney() end
        self.repSnapshot = self:SnapshotReputation()
    elseif run.mode == "unranked" then
        if action == "pause" then
            run.paused = run.paused or now
        elseif action == "end" then
            run.ended = now
        end
    end

    self:Refresh()
end

function Tracker:GetModeLabel(run)
    local key = "LID_DT_LEGACY"
    if run.mode == "unranked" then
        key = "LID_DT_UNRANKED"
    elseif run.mode == "ranked" or not run.start then
        key = "LID_DT_RANKED"
    end

    return AzerothCompendium:Trans(key)
end

function Tracker:ShouldStayAway()
    if IsInGroup and IsInGroup() then return true end
    if GetNumGroupMembers and GetNumGroupMembers() > 0 then return true end
    local dead = UnitIsDeadOrGhost("player")

    return not IsSecret(dead) and dead == true
end

function Tracker:EndRun(run)
    self.away = false
    if run == nil or not run.active then return end
    if run.mode == "unranked" and not run.ended then run.paused = run.paused or time() end
    run.active = false
    run.left = time()
end

function Tracker:CheckAway()
    if not self.away or self.instanceID ~= nil then return end
    if self:ShouldStayAway() then return end
    self:EndRun(self:GetRun())
    self.forced = false
    self:UpdateVisibility()
end

function Tracker:IsTracking()
    local run = self:GetRun()

    return run ~= nil and run.start ~= nil and not run.paused and not run.ended and self:IsCurrentInstance(run)
end

function Tracker:NarrowWing(npcID)
    local run = self:GetRun()
    if run == nil or run.wing ~= nil or self.candidates == nil or #self.candidates < 2 then return end
    local wing = self.npcWing and self.npcWing[npcID]
    if wing == nil or wing == 0 then return end
    run.wing = wing
end

function Tracker:CheckFinished(run)
    if run.finished then return end
    local bosses = self:GetBosses(run)
    if #bosses > 0 and self:CountKilled(run, bosses) == #bosses then
        run.finished = time()
        self:UpdateBest(run)
    end
end

function Tracker:GetBest(run)
    ACOTABPC = ACOTABPC or {}
    if type(ACOTABPC.DUNGEONBESTS) ~= "table" then ACOTABPC.DUNGEONBESTS = {} end
    local key = tostring(run.wing or run.instanceID)
    if run.mode or not run.start then key = "ranked:" .. key end
    local best = ACOTABPC.DUNGEONBESTS[key]
    if type(best) ~= "table" then
        best = {}
        ACOTABPC.DUNGEONBESTS[key] = best
    end

    return best
end

function Tracker:UpdateBest(run)
    if run.mode ~= "ranked" or not run.finished then return end
    local best = self:GetBest(run)
    if (run.xp or 0) > (best.xp or 0) then best.xp = run.xp end
    if (run.rep or 0) > (best.rep or 0) then best.rep = run.rep end
    if (run.gold or 0) > (best.gold or 0) then best.gold = run.gold end
    local duration = self:GetElapsed(run)
    if best.time == nil or duration < best.time then best.time = duration end
end

function Tracker:MarkKilled(npcID)
    if npcID == nil or not self:IsTracking() then return end
    if self.npcWing == nil or self.npcWing[npcID] == nil then return end
    AzerothCompendium:MarkNpcSeen(npcID)
    local run = self:GetRun()
    if run.killed[npcID] then return end
    run.killed[npcID] = true
    AzerothCompendium:RecordOwnKill(npcID)
    self:NarrowWing(npcID)
    self:CheckFinished(run)
    self:Refresh()
    self:NotifyMapChange()
end

function Tracker:GetNpcID(guid)
    if type(guid) ~= "string" or IsSecret(guid) then return nil end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end

    return tonumber(npcID)
end

function Tracker:OnUnit(unit)
    if not self:IsTracking() or unit == nil or not UnitExists(unit) then return end
    local npcID = self:GetNpcID(UnitGUID(unit))
    if npcID == nil or self.npcWing == nil or self.npcWing[npcID] == nil then return end
    AzerothCompendium:MarkNpcSeen(npcID)
    local dead = UnitIsDead(unit)
    if IsSecret(dead) then return end
    if dead then
        self:MarkKilled(npcID)
    elseif self:GetRun().wing == nil then
        self:NarrowWing(npcID)
        if self:GetRun().wing ~= nil then self:Refresh() end
    end
end

function Tracker:OnUnitHealth(unit)
    if type(unit) ~= "string" or not self:IsTracking() then return end
    if strfind(unit, "^nameplate") or strfind(unit, "^boss") or unit == "target" or unit == "mouseover" or unit == "focus" then self:OnUnit(unit) end
end

function Tracker:OnEncounterEnd(encounterName, success)
    if not self:IsTracking() or IsSecret(encounterName) or IsSecret(success) then return end
    if type(encounterName) ~= "string" or (success ~= 1 and success ~= true) then return end
    local target = strlower(encounterName)
    for _, inst in ipairs(self.candidates or {}) do
        for _, boss in ipairs(inst.bosses or {}) do
            if not boss.trash and not boss.all and type(boss.npcs) == "table" and #boss.npcs > 0 then
                local names = {boss.name, AzerothCompendium:GetBossName(boss)}
                for _, name in ipairs(names) do
                    if type(name) == "string" and strlower(name) == target then
                        self:MarkKilled(boss.npcs[1])

                        return
                    end
                end
            end
        end
    end
end

function Tracker:OnLootOpened()
    if not self:IsTracking() or GetLootSourceInfo == nil or GetNumLootItems == nil then return end
    local run = self:GetRun()
    run.lootCounted = run.lootCounted or {}
    for slot = 1, GetNumLootItems() do
        local sources = {pcall(GetLootSourceInfo, slot)}
        local link = GetLootSlotLink and GetLootSlotLink(slot)
        local itemID = type(link) == "string" and not IsSecret(link) and tonumber(strmatch(link, "item:(%d+)"))
        if sources[1] then
            for index = 2, #sources, 2 do
                local guid = sources[index]
                local npcID = self:GetNpcID(guid)
                self:MarkKilled(npcID)
                if itemID and npcID and self.npcWing and self.npcWing[npcID] then
                    local key = guid .. ":" .. itemID
                    if not run.lootCounted[key] then
                        run.lootCounted[key] = true
                        AzerothCompendium:RecordOwnDrop(npcID, itemID)
                    end
                end
            end
        end
    end
end

function Tracker:OnXP(msg)
    if not self:IsTracking() or type(msg) ~= "string" or IsSecret(msg) then return end
    local pattern = self:GetPatterns().xp
    if pattern == nil then return end
    local captures = {strmatch(msg, pattern)}
    for index = #captures, 1, -1 do
        local amount = tonumber(captures[index])
        if amount then
            local run = self:GetRun()
            run.xp = (run.xp or 0) + amount
            self:UpdateBest(run)
            self:UpdateStats()

            return
        end
    end
end

function Tracker:SnapshotReputation()
    local snapshot = {}
    local count = 0
    if C_Reputation and C_Reputation.GetNumFactions then
        count = C_Reputation.GetNumFactions() or 0
    elseif GetNumFactions then
        count = GetNumFactions() or 0
    end

    if IsSecret(count) or type(count) ~= "number" then return snapshot end
    for index = 1, count do
        local id, name, _, _, _, value, hasRep = AzerothCompendium:ReadReputationEntry(index)
        if id and id ~= 0 and hasRep and not IsSecret(id) and not IsSecret(name) and not IsSecret(value) and type(name) == "string" and type(value) == "number" then
            snapshot[id] = {
                name = name,
                value = value
            }
        end
    end

    return snapshot
end

function Tracker:AddReputation(faction, amount)
    if type(amount) ~= "number" or amount <= 0 or not self:IsTracking() then return end
    local run = self:GetRun()
    run.rep = (run.rep or 0) + amount
    if type(faction) == "string" and faction ~= "" then
        run.factions = type(run.factions) == "table" and run.factions or {}
        run.factions[faction] = (run.factions[faction] or 0) + amount
    end

    self:UpdateBest(run)
    self:UpdateStats()
end

function Tracker:OnReputation(msg)
    if not self:IsTracking() then return end
    if IsSecret(msg) then
        self.repSecret = true

        return
    end

    if type(msg) ~= "string" then return end
    for _, pattern in ipairs(self:GetPatterns().rep) do
        local first, second = strmatch(msg, pattern)
        if first then
            local faction, amount = nil, nil
            if tonumber(first) then
                amount = tonumber(first)
                faction = second
            elseif tonumber(second) then
                faction = first
                amount = tonumber(second)
            end

            if amount and amount > 0 then
                self:AddReputation(faction, amount)

                return
            end
        end
    end
end

function Tracker:OnUpdateFaction()
    local current = self:SnapshotReputation()
    local previous = self.repSnapshot
    self.repSnapshot = current
    if not self.repSecret or previous == nil or not self:IsTracking() then return end
    for id, data in pairs(current) do
        local old = previous[id]
        if old and data.value > old.value then self:AddReputation(data.name, data.value - old.value) end
    end
end

function Tracker:OnMoney()
    if GetMoney == nil then return end
    local money = GetMoney()
    if IsSecret(money) then return end
    local delta = self.money and money - self.money or 0
    self.money = money
    if delta <= 0 or not self:IsTracking() then return end
    local run = self:GetRun()
    run.gold = (run.gold or 0) + delta
    self:UpdateBest(run)
    self:UpdateStats()
end

function Tracker:OnSystem(msg)
    if type(msg) ~= "string" or IsSecret(msg) then return end
    local pattern = self:GetPatterns().reset
    if pattern == nil or not strmatch(msg, pattern) then return end
    local run = self:GetRun()
    if run and not run.active then run.reset = true end
end

function Tracker:GetLinkQuality(link)
    local hex = strmatch(link, "|c%x%x(%x%x%x%x%x%x)")
    if hex then return self.qualities[strlower(hex)] end
    local quality = strmatch(link, "|cnIQ(%d)")

    return tonumber(quality)
end

function Tracker:ShortName(name)
    if type(name) ~= "string" or IsSecret(name) then return nil end
    name = strmatch(name, "|h%[?([^%]|]+)%]?|h") or name
    name = gsub(gsub(gsub(name, "|c%x%x%x%x%x%x%x%x", ""), "|r", ""), "[%[%]]", "")
    name = strmatch(name, "^%s*([^%-]-)%s*$") or strmatch(name, "^%s*([^%-]-)%s*%-")
    if name == "" then return nil end

    return name
end

function Tracker:GetUnitClass(name, guid)
    if guid and not IsSecret(guid) and GetPlayerInfoByGUID then
        local ok, _, class = pcall(GetPlayerInfoByGUID, guid)
        if ok and class and not IsSecret(class) then return class end
    end

    name = self:ShortName(name)
    if name == nil then return nil end
    self.classCache = self.classCache or {}
    if self.classCache[name] then return self.classCache[name] end
    local units = {"player"}
    if IsInRaid and IsInRaid() then
        for index = 1, 40 do
            tinsert(units, "raid" .. index)
        end
    else
        for index = 1, 4 do
            tinsert(units, "party" .. index)
        end
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local unitName = UnitName(unit)
            local _, class = UnitClass(unit)
            if unitName ~= nil and class ~= nil and not IsSecret(unitName) and not IsSecret(class) then self.classCache[unitName] = class end
            if unitName == name and class ~= nil then return class end
        end
    end

    local ok, _, class = pcall(UnitClass, name)
    if ok and class and not IsSecret(class) then
        self.classCache[name] = class

        return class
    end

    return nil
end

function Tracker:OnLoot(msg, ...)
    local guid = select(11, ...)
    if not self:IsTracking() or type(msg) ~= "string" or IsSecret(msg) then return end
    for _, info in ipairs(self:GetPatterns().loot) do
        local captures = {strmatch(msg, info.pattern)}
        if #captures > 0 then
            local link, winner = nil, nil
            for _, capture in ipairs(captures) do
                local itemLink = strmatch(capture, "|c.-|Hitem:.-|h|r")
                if itemLink then
                    link = itemLink
                elseif tonumber(capture) == nil then
                    winner = capture
                end
            end

            if link then
                if info.self then winner = UnitName("player") end
                local quality = self:GetLinkQuality(link)
                if quality == nil or quality >= self.config.minQuality then
                    tinsert(self:GetRun().loot, 1, {
                        link = link,
                        winner = winner,
                        class = self:GetUnitClass(winner, guid),
                        quality = quality
                    })

                    self:Refresh()
                end

                return
            end
        end
    end
end

function Tracker:FormatTime(seconds)
    seconds = max(0, floor(seconds))
    local hours = floor(seconds / 3600)
    local minutes = floor(seconds % 3600 / 60)
    if hours > 0 then return format("%d:%02d:%02d", hours, minutes, seconds % 60) end

    return format("%d:%02d", minutes, seconds % 60)
end

function Tracker:GetElapsed(run)
    if not run.start then return 0 end
    local finished = run.mode ~= "unranked" and run.finished
    local stop = run.paused or run.ended or finished or (run.active and time()) or run.left or time()

    return max(0, stop - run.start - (run.pauseTime or 0))
end

function Tracker:FormatMoney(amount)
    amount = max(0, floor(amount or 0))
    local formatters = {}
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then formatters[#formatters + 1] = C_CurrencyInfo.GetCoinTextureString end
    if GetMoneyString then formatters[#formatters + 1] = GetMoneyString end
    if GetCoinTextureString then formatters[#formatters + 1] = GetCoinTextureString end
    for _, formatter in ipairs(formatters) do
        local ok, text = pcall(formatter, amount, true)
        if ok and type(text) == "string" and text ~= "" then return text end
    end

    if amount == 0 and GetCoinTextureString then
        local ok, text = pcall(GetCoinTextureString, 1)
        if ok and type(text) == "string" and text ~= "" then return (gsub(text, "1", "0", 1)) end
    end

    return format("%dg %ds %dc", floor(amount / 10000), floor(amount % 10000 / 100), amount % 100)
end

function Tracker:FormatPlainMoney(amount)
    amount = max(0, floor(amount or 0))
    local parts = {}
    local units = {{floor(amount / 10000), GOLD_AMOUNT_SYMBOL or "g"}, {floor(amount % 10000 / 100), SILVER_AMOUNT_SYMBOL or "s"}, {amount % 100, COPPER_AMOUNT_SYMBOL or "c"}}
    for _, unit in ipairs(units) do
        if unit[1] > 0 or #parts > 0 then tinsert(parts, unit[1] .. unit[2]) end
    end

    if #parts == 0 then return "0" .. (COPPER_AMOUNT_SYMBOL or "c") end

    return table.concat(parts, " ")
end

function Tracker:PostToChat()
    local run = self:GetShownRun()
    if run == nil then return end
    local secondText = self:ShowsXP() and format(" %s: %s", XP or "XP", self:FormatNumber(run.xp or 0)) or format(" %s: %s", AzerothCompendium:Trans("LID_REPUTATION"), self:FormatNumber(run.rep or 0))
    local msg = format("[%s] %s: %s%s %s: %s", AzerothCompendium:Trans("LID_TITLE"), AzerothCompendium:Trans("LID_DT_TIME"), self:FormatTime(self:GetElapsed(run)), secondText, AzerothCompendium:Trans("LID_DT_GOLD"), self:FormatPlainMoney(run.gold))
    local channel = nil
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid and IsInRaid() then
        channel = "RAID"
    elseif (IsInGroup and IsInGroup()) or (GetNumPartyMembers and GetNumPartyMembers() > 0) then
        channel = "PARTY"
    end

    if channel == nil then
        DEFAULT_CHAT_FRAME:AddMessage(format("[%s] %s: %s%s %s: %s", AzerothCompendium:Trans("LID_TITLE"), AzerothCompendium:Trans("LID_DT_TIME"), self:FormatTime(self:GetElapsed(run)), secondText, AzerothCompendium:Trans("LID_DT_GOLD"), self:FormatMoney(run.gold or 0)))

        return
    end

    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    send(msg, channel)
end

function Tracker:FormatNumber(value)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(value) end

    return tostring(value)
end

function Tracker:SavePosition()
    local frame = self.frame
    local left, top = frame:GetLeft(), frame:GetTop()
    if left == nil or top == nil then return end
    AzerothCompendium:SetConfig("DUNGEONTRACKERPOS", {left, top})
end

function Tracker:RestorePosition()
    local frame = self.frame
    local pos = AzerothCompendium:GetConfig("DUNGEONTRACKERPOS", nil)
    frame:ClearAllPoints()
    if type(pos) == "table" and pos[1] and pos[2] then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
    else
        frame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -self.config.width - 80, -240)
    end
end

function Tracker:ApplyScale(value)
    local frame = self.frame
    local c = self.config
    value = min(c.scaleMax, max(c.scaleMin, value))
    local left, top = frame:GetLeft(), frame:GetTop()
    local oldScale = frame:GetEffectiveScale()
    frame:SetScale(value)
    if left ~= nil and top ~= nil then
        local scale = frame:GetEffectiveScale()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / scale, top * oldScale / scale)
    end
end

function Tracker:IsCollapsed()
    return AzerothCompendium:GetConfig("DUNGEONTRACKERCOLLAPSED", false) == true
end

function Tracker:SetCollapsed(collapsed)
    AzerothCompendium:SetConfig("DUNGEONTRACKERCOLLAPSED", collapsed == true)
    self:Layout()
end

function Tracker:IsBossesCollapsed()
    return AzerothCompendium:GetConfig("DUNGEONTRACKERBOSSESCOLLAPSED", false) == true
end

function Tracker:SetBossesCollapsed(collapsed)
    AzerothCompendium:SetConfig("DUNGEONTRACKERBOSSESCOLLAPSED", collapsed == true)
    self:Layout()
end

function Tracker:IsRaresCollapsed()
    return AzerothCompendium:GetConfig("DUNGEONTRACKERRARESCOLLAPSED", false) == true
end

function Tracker:SetRaresCollapsed(collapsed)
    AzerothCompendium:SetConfig("DUNGEONTRACKERRARESCOLLAPSED", collapsed == true)
    self:Layout()
end

function Tracker:IsLootCollapsed()
    return AzerothCompendium:GetConfig("DUNGEONTRACKERLOOTCOLLAPSED", false) == true
end

function Tracker:SetLootCollapsed(collapsed)
    AzerothCompendium:SetConfig("DUNGEONTRACKERLOOTCOLLAPSED", collapsed == true)
    self:Layout()
end

function Tracker:IsQualityEnabled(quality)
    if quality < self.config.minQuality then return false end
    local filter = AzerothCompendium:GetConfig("DUNGEONTRACKERQUALITIES", nil)
    if type(filter) == "table" and filter[quality] ~= nil then return filter[quality] == true end

    return quality >= self.config.defaultQuality
end

function Tracker:SetQualityEnabled(quality, enabled)
    local filter = AzerothCompendium:GetConfig("DUNGEONTRACKERQUALITIES", nil)
    if type(filter) ~= "table" then
        filter = {}
        for _, q in ipairs(self.qualityOrder) do
            filter[q] = q >= self.config.defaultQuality
        end
    end

    filter[quality] = enabled == true
    AzerothCompendium:SetConfig("DUNGEONTRACKERQUALITIES", filter)
    self:Refresh()
end

function Tracker:GetQualityColor(quality)
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b end
    local fallback = self.qualityFallbacks[quality]
    if fallback then return fallback[1], fallback[2], fallback[3] end

    return 1, 1, 1
end

function Tracker:GetQualityName(quality)
    return _G["ITEM_QUALITY" .. quality .. "_DESC"] or self.qualityNames[quality] or tostring(quality)
end

function Tracker:GetEntryQuality(entry)
    if type(entry) ~= "table" then return nil end
    if type(entry.quality) == "number" then return entry.quality end
    if type(entry.link) == "string" then
        local quality = self:GetLinkQuality(entry.link)
        if quality ~= nil then entry.quality = quality end

        return quality
    end

    return nil
end

function Tracker:GetFilteredLoot(run)
    local list = {}
    local total = 0
    if type(run) ~= "table" or type(run.loot) ~= "table" then return list, total end
    for _, entry in ipairs(run.loot) do
        local quality = self:GetEntryQuality(entry)
        if quality == nil or quality >= self.config.minQuality then
            total = total + 1
            if quality == nil or self:IsQualityEnabled(min(5, quality)) then tinsert(list, entry) end
        end
    end

    return list, total
end

function Tracker:GetSavedSize()
    local size = AzerothCompendium:GetConfig("DUNGEONTRACKERSIZE", nil)
    if type(size) ~= "table" then return self.config.width, nil end

    return size[1] or self.config.width, size[2]
end

function Tracker:SaveSize()
    local frame = self.frame
    AzerothCompendium:SetConfig("DUNGEONTRACKERSIZE", {floor(frame:GetWidth() + 0.5), floor(frame:GetHeight() + 0.5)})
    AzerothCompendium:SetConfig("DUNGEONTRACKERSCALE", frame:GetScale())
    self:SavePosition()
end

function Tracker:GetTitleRegion(frame)
    if type(frame.GetTitleText) == "function" then
        local ok, title = pcall(frame.GetTitleText, frame)
        if ok and title then return title end
    end

    if type(frame.TitleContainer) == "table" and frame.TitleContainer.TitleText then return frame.TitleContainer.TitleText end
    if frame.TitleText then return frame.TitleText end

    return _G[frame:GetName() .. "TitleText"]
end

function Tracker:CreateStat(parent)
    local stat = {}
    stat.label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stat.label:SetJustifyH("CENTER")
    stat.value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    stat.value:SetPoint("TOP", stat.label, "BOTTOM", 0, -4)
    stat.value:SetJustifyH("CENTER")
    stat.value:SetWordWrap(false)
    stat.best = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    stat.best:SetPoint("TOP", stat.value, "BOTTOM", 0, -4)
    stat.best:SetJustifyH("CENTER")
    stat.best:SetWordWrap(false)

    return stat
end

function Tracker:ShowReputationTooltip(owner)
    if self:ShowsXP() then return end
    local run = self:GetShownRun()
    if run == nil or type(run.factions) ~= "table" or next(run.factions) == nil then return end
    local list = {}
    for faction, amount in pairs(run.factions) do
        if type(amount) == "number" and amount > 0 then
            tinsert(list, {
                name = faction,
                amount = amount
            })
        end
    end

    if #list == 0 then return end
    sort(list, function(a, b)
        if a.amount ~= b.amount then return a.amount > b.amount end

        return a.name < b.name
    end)

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(AzerothCompendium:Trans("LID_REPUTATION"))
    for _, entry in ipairs(list) do
        GameTooltip:AddDoubleLine(entry.name, "+" .. self:FormatNumber(entry.amount), 0.9, 0.9, 0.9, 0.3, 0.8, 1)
    end

    GameTooltip:Show()
end

function Tracker:ShowsXP()
    if type(IsPlayerAtEffectiveMaxLevel) == "function" then
        local ok, atMax = pcall(IsPlayerAtEffectiveMaxLevel)
        if ok and not IsSecret(atMax) and type(atMax) == "boolean" then return not atMax end
    end

    local maxLevel = type(GetMaxPlayerLevel) == "function" and GetMaxPlayerLevel() or AzerothCompendium:GetMaxLevel()
    local level = UnitLevel("player")
    if IsSecret(level) or IsSecret(maxLevel) or type(level) ~= "number" or type(maxLevel) ~= "number" then return true end

    return level < maxLevel
end

Tracker.collapsedNineSliceKeys = {"LeftEdge", "RightEdge", "BottomEdge", "BottomLeftCorner", "BottomRightCorner", "Center"}
Tracker.collapsedFrameKeys = {"Bg", "LeftBorder", "RightBorder", "BottomBorder", "BotLeftCorner", "BotRightCorner", "BottomLeftCorner", "BottomRightCorner", "BtnCornerLeft", "BtnCornerRight", "ButtonBottomBorder"}

function Tracker:SyncCollapsedChrome(frame, collapsed)
    if frame == nil then return end
    local hideBody = collapsed == true and not AzerothCompendium.Theme:IsModern()
    if not hideBody and not frame.collapsedChromeHidden then return end
    local ns = frame.NineSlice
    if ns then
        for _, key in ipairs(self.collapsedNineSliceKeys) do
            local region = ns[key]
            if region and region.SetShown then region:SetShown(not hideBody) end
        end
    end

    for _, key in ipairs(self.collapsedFrameKeys) do
        local region = frame[key]
        if region and region.SetShown then
            if hideBody then
                region:Hide()
            elseif not AzerothCompendium.Theme:IsModern() then
                region:Show()
            end
        end
    end

    frame.collapsedChromeHidden = hideBody
end

function Tracker:LayoutHeaderTitle(frame, collapsed)
    if frame == nil or frame.titleText == nil or frame.headerOverlay == nil then return end
    local title = frame.titleText
    local rightAnchor = (collapsed and not self.listMode and frame.headerTime) or frame.runsButton
    local leftPad = AzerothCompendium.Theme:IsModern() and 44 or 12
    title:ClearAllPoints()
    title:SetPoint("LEFT", frame.headerOverlay, "LEFT", leftPad, 0)
    if rightAnchor then title:SetPoint("RIGHT", rightAnchor, "LEFT", -6, 0) end
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
end

function Tracker:GetChromeLevel(frame)
    local level = frame:GetFrameLevel() + 30
    if frame.NineSlice then level = max(level, frame.NineSlice:GetFrameLevel() + 10) end
    if frame.CloseButton then level = max(level, frame.CloseButton:GetFrameLevel() + 2) end

    return level
end

function Tracker:SyncChromeLevels(frame)
    if frame == nil then return end
    local level = self:GetChromeLevel(frame)
    for _, child in ipairs({frame.toggle, frame.post, frame.runsButton, frame.headerOverlay, frame.grip}) do
        if child then child:SetFrameLevel(level) end
    end
end

function Tracker:CreateResizeGrip(frame)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    grip:SetFrameLevel(self:GetChromeLevel(frame))
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_RESIZEWINDOW"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine((SHIFT_KEY_TEXT or "Shift") .. " + " .. AzerothCompendium:Trans("LID_LEFTCLICK"), AzerothCompendium:Trans("LID_SCALE"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine(AzerothCompendium:Trans("LID_RIGHTCLICK"), AzerothCompendium:Trans("LID_RESETSIZEANDSCALE"), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:Show()
    end)

    grip:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    grip:SetScript("OnMouseDown", function(sel, button)
        if button == "RightButton" then
            sel.sizing = nil
            Tracker:ApplyScale(1)
            frame:SetWidth(Tracker.config.width)
            frame.userHeight = nil
            AzerothCompendium:SetConfig("DUNGEONTRACKERSIZE", nil)
            AzerothCompendium:SetConfig("DUNGEONTRACKERSCALE", 1)
            Tracker:Layout()
            Tracker:SavePosition()

            return
        end

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
            h = frame:GetHeight(),
            scaling = IsShiftKeyDown(),
            startScale = frame:GetScale(),
            effectiveScale = scale
        }

        sel:SetScript("OnUpdate", sel.OnSizingUpdate)
    end)

    local function StopSizing(sel)
        sel:SetScript("OnUpdate", nil)
        if sel.sizing == nil then return end
        sel.sizing = nil
        Tracker:SaveSize()
    end

    grip:SetScript("OnMouseUp", StopSizing)
    grip:SetScript("OnHide", StopSizing)
    function grip.OnSizingUpdate(sel)
        local sizing = sel.sizing
        if sizing == nil then
            sel:SetScript("OnUpdate", nil)

            return
        end

        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            StopSizing(sel)

            return
        end

        local x, y = GetCursorPosition()
        local c = Tracker.config
        if sizing.scaling then
            local w, h = sizing.w * sizing.effectiveScale, sizing.h * sizing.effectiveScale
            local dx, dy = x - sizing.x * sizing.effectiveScale, y - sizing.y * sizing.effectiveScale
            local value = sizing.startScale * (1 + (dx * w - dy * h) / (w * w + h * h))
            value = floor(value / c.scaleStep + 0.5) * c.scaleStep
            if value ~= frame:GetScale() then Tracker:ApplyScale(value) end

            return
        end

        local scale = frame:GetEffectiveScale()
        frame:SetWidth(floor(max(c.minWidth, sizing.w + x / scale - sizing.x) + 0.5))
        frame.userHeight = floor(sizing.h + sizing.y - y / scale + 0.5)
        Tracker:Layout()
    end

    return grip
end

function Tracker:CreateSectionHeader(parent, onClick)
    local header = CreateFrame("Button", nil, parent)
    header:SetHeight(self.config.label)
    header.icon = header:CreateTexture(nil, "ARTWORK")
    header.icon:SetSize(14, 14)
    header.icon:SetPoint("LEFT", header, "LEFT", 0, 0)
    header.label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.label:SetPoint("LEFT", header.icon, "RIGHT", 4, 0)
    header:SetScript("OnClick", onClick)

    return header
end

function Tracker:ShowQualityTooltip(button)
    local quality = button.quality
    local r, g, b = self:GetQualityColor(quality)
    local enabled = self:IsQualityEnabled(quality)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(self:GetQualityName(quality), r, g, b)
    if enabled then
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_DT_QUALITYSHOWN"), 0.25, 1, 0.25)
    else
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_DT_QUALITYHIDDEN"), 0.65, 0.65, 0.65)
    end

    GameTooltip:Show()
end

function Tracker:CreateQualityFilters(parent)
    local size = 14
    local gap = 3
    local circle = AzerothCompendium.Theme.MEDIA .. "circle"
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(#self.qualityOrder * size + (#self.qualityOrder - 1) * gap, self.config.label)
    local buttons = {}
    for index, quality in ipairs(self.qualityOrder) do
        local button = CreateFrame("Button", nil, container)
        button:SetSize(size, size)
        button:SetPoint("LEFT", container, "LEFT", (index - 1) * (size + gap), 0)
        button.quality = quality
        button.outline = button:CreateTexture(nil, "BACKGROUND")
        button.outline:SetAllPoints()
        button.outline:SetTexture(circle)
        button.outline:SetVertexColor(0, 0, 0, 0.65)
        button.fill = button:CreateTexture(nil, "BORDER")
        button.fill:SetSize(size - 2, size - 2)
        button.fill:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.fill:SetTexture(circle)
        button.hole = button:CreateTexture(nil, "ARTWORK")
        button.hole:SetSize(size - 6, size - 6)
        button.hole:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.hole:SetTexture(circle)
        button.hole:SetVertexColor(0.08, 0.09, 0.11, 0.95)
        button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
        button.highlight:SetAllPoints()
        button.highlight:SetTexture(circle)
        button.highlight:SetBlendMode("ADD")
        button.highlight:SetVertexColor(1, 1, 1, 0.25)
        button:SetScript("OnClick", function(sel)
            Tracker:SetQualityEnabled(sel.quality, not Tracker:IsQualityEnabled(sel.quality))
            if GameTooltip:IsOwned(sel) then Tracker:ShowQualityTooltip(sel) end
        end)

        button:SetScript("OnEnter", function(sel) Tracker:ShowQualityTooltip(sel) end)
        button:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
        buttons[index] = button
    end

    return container, buttons
end

function Tracker:UpdateQualityFilters()
    local frame = self.frame
    if frame == nil or frame.qualityButtons == nil then return end
    for _, button in ipairs(frame.qualityButtons) do
        local r, g, b = self:GetQualityColor(button.quality)
        local enabled = self:IsQualityEnabled(button.quality)
        button.fill:SetVertexColor(r, g, b, enabled and 1 or 0.55)
        button.hole:SetShown(not enabled)
    end
end

function Tracker:CreateFrame()
    if self.frame then return self.frame end
    local c = self.config
    local ui = AzerothCompendium.SharedUI
    local frame = AzerothCompendium:CreateCompendiumDialog("AzerothCompendiumDungeonTracker", "")
    self.frame = frame
    if ButtonFrameTemplate_HidePortrait then pcall(ButtonFrameTemplate_HidePortrait, frame) end
    if type(frame.Inset) == "table" then frame.Inset:Hide() end
    AzerothCompendium:ApplyWidgetLayer(frame, "tracker")
    frame:SetToplevel(false)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        Tracker:SavePosition()
        Tracker:RestorePosition()
    end)

    local width, height = self:GetSavedSize()
    frame:SetWidth(max(c.minWidth, width))
    frame.userHeight = height
    frame:SetScale(AzerothCompendium:GetConfig("DUNGEONTRACKERSCALE", 1) or 1)
    self:RestorePosition()
    frame.titleText = self:GetTitleRegion(frame)
    if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() Tracker:Close() end) end
    frame.toggle = CreateFrame("Button", nil, frame)
    frame.toggle:SetSize(16, 16)
    if frame.CloseButton then
        frame.toggle:SetPoint("RIGHT", frame.CloseButton, "LEFT", -2, 0)
    else
        frame.toggle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -4)
    end

    frame.toggle:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.toggle.icon = frame.toggle:CreateTexture(nil, "ARTWORK")
    frame.toggle.icon:SetAllPoints()
    frame.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    frame.toggle:SetScript("OnClick", function() Tracker:SetCollapsed(not Tracker:IsCollapsed()) end)
    frame.post = CreateFrame("Button", nil, frame)
    frame.post:SetSize(18, 18)
    frame.post:SetPoint("RIGHT", frame.toggle, "LEFT", -4, 0)
    frame.post:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.post:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
    frame.post:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
    frame.post:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    frame.post:SetScript("OnClick", function() Tracker:PostToChat() end)
    frame.post:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_DT_POSTCHAT"))
        GameTooltip:Show()
    end)

    frame.post:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    frame.runsButton = CreateFrame("Button", nil, frame)
    frame.runsButton:SetSize(16, 16)
    frame.runsButton:SetPoint("RIGHT", frame.post, "LEFT", -4, 0)
    frame.runsButton:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.runsButton:SetNormalTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    frame.runsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    frame.runsButton:SetScript("OnClick", function()
        if Tracker.listMode then
            Tracker:ShowRun(Tracker.lastViewed)
        else
            Tracker:ShowRuns()
        end
    end)

    frame.runsButton:SetScript("OnEnter", function(sel)
        GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
        GameTooltip:SetText(AzerothCompendium:Trans("LID_DT_RUNS"))
        GameTooltip:Show()
    end)

    frame.runsButton:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    frame.headerOverlay = CreateFrame("Frame", nil, frame)
    frame.headerOverlay:SetPoint("TOP", frame.runsButton, "TOP", 0, 2)
    frame.headerOverlay:SetPoint("BOTTOM", frame.runsButton, "BOTTOM", 0, -2)
    frame.headerOverlay:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.headerOverlay:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    frame.headerOverlay:EnableMouse(false)
    frame.headerTime = frame.headerOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.headerTime:SetPoint("RIGHT", frame.runsButton, "LEFT", -6, 0)
    frame.runList = ui.CreateScroller(frame, c.runRow, function(parent) return Tracker:CreateRunRow(parent) end, 0, 4)
    frame.runList:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    frame.runList:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    frame.runList:Hide()
    frame.runsEmpty = frame.runList:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.runsEmpty:SetPoint("CENTER", frame.runList, "CENTER", 0, 0)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", c.side, -c.top)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c.side, c.bottom)
    frame.stats = CreateFrame("Frame", nil, frame.content)
    ui.AddContentBorder(frame.stats)
    frame.stats:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.stats:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, 0)
    frame.stats:SetHeight(c.stats)
    frame.statColumns = {}
    for index = 1, 3 do
        frame.statColumns[index] = self:CreateStat(frame.stats)
    end

    local repHit = CreateFrame("Frame", nil, frame.stats)
    repHit:EnableMouse(true)
    repHit:RegisterForDrag("LeftButton")
    repHit:SetScript("OnDragStart", function() frame:StartMoving() end)
    repHit:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        Tracker:SavePosition()
        Tracker:RestorePosition()
    end)
    repHit:SetScript("OnEnter", function(sel) Tracker:ShowReputationTooltip(sel) end)
    repHit:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    frame.statColumns[2].hit = repHit

    frame.controls = CreateFrame("Frame", nil, frame.content)
    frame.controls:SetPoint("TOPLEFT", frame.stats, "BOTTOMLEFT", 0, -c.gap)
    frame.controls:SetPoint("TOPRIGHT", frame.stats, "BOTTOMRIGHT", 0, -c.gap)
    frame.controls:SetHeight(22)
    for index, action in ipairs({"start", "pause", "end"}) do
        local button = CreateFrame("Button", nil, frame.controls, "UIPanelButtonTemplate")
        button:SetHeight(22)
        button:SetScript("OnClick", function() Tracker:ControlRun(action) end)
        frame.controls[index] = button
    end

    frame.bosses = CreateFrame("Frame", nil, frame.content)
    ui.AddContentBorder(frame.bosses)
    frame.bossHeader = self:CreateSectionHeader(frame.bosses, function() Tracker:SetBossesCollapsed(not Tracker:IsBossesCollapsed()) end)
    frame.bossLabel = frame.bossHeader.label
    frame.rareHeader = self:CreateSectionHeader(frame.bosses, function() Tracker:SetRaresCollapsed(not Tracker:IsRaresCollapsed()) end)
    frame.rareLabel = frame.rareHeader.label
    frame.lootHeader = self:CreateSectionHeader(frame.content, function() Tracker:SetLootCollapsed(not Tracker:IsLootCollapsed()) end)
    frame.lootLabel = frame.lootHeader.label
    frame.lootLabel:SetPoint("RIGHT", frame.lootHeader, "RIGHT", 0, 0)
    frame.lootLabel:SetJustifyH("LEFT")
    frame.lootLabel:SetWordWrap(false)
    frame.lootFilters, frame.qualityButtons = self:CreateQualityFilters(frame.content)
    frame.loot = ui.CreateScroller(frame.content, c.lootRow, function(parent) return Tracker:CreateLootRow(parent) end, 0, 4)
    frame.loot:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", 0, 0)
    frame.lootEmpty = frame.loot:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.lootEmpty:SetPoint("CENTER", frame.loot, "CENTER", 0, 0)
    frame.grip = self:CreateResizeGrip(frame)
    self:SyncChromeLevels(frame)
    frame:HookScript("OnShow", function(sel) Tracker:SyncChromeLevels(sel) end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        Tracker.elapsed = Tracker.elapsed + elapsed
        if Tracker.elapsed < 0.5 then return end
        Tracker.elapsed = 0
        Tracker:UpdateStats()
    end)

    frame:Hide()
    AzerothCompendium:OnLanguage(function() Tracker:Refresh() end)

    return frame
end

function Tracker:AcquireIcon(index)
    local icon = self.icons[index]
    if icon then return icon end
    local c = self.config
    local size = c.portrait
    local scale = size / 64
    icon = CreateFrame("Frame", nil, self.frame.bosses)
    icon:SetSize(size, size)
    icon:EnableMouse(true)
    icon.portrait = icon:CreateTexture(nil, "ARTWORK")
    icon.portrait:SetAllPoints(icon)
    if icon.CreateMaskTexture and icon.portrait.AddMaskTexture then
        local mask = icon:CreateMaskTexture()
        mask:SetAllPoints(icon)
        mask:SetTexture(c.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        icon.portrait:AddMaskTexture(mask)
    elseif icon.portrait.SetMask then
        icon.portrait:SetMask(c.mask)
    end

    icon.ring = icon:CreateTexture(nil, "OVERLAY", nil, 1)
    icon.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    icon.ring:SetTexCoord(0, 0.6, 0, 0.6)
    icon.ring:SetSize(size * 1.55, size * 1.55)
    icon.ring:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.dragon = icon:CreateTexture(nil, "OVERLAY", nil, 2)
    icon.dragon:SetSize(256 * scale, 128 * scale)
    icon.dragon:SetPoint("CENTER", icon, "CENTER", -54 * scale, -20 * scale)
    icon.dead = icon:CreateTexture(nil, "OVERLAY", nil, 4)
    icon.dead:SetTexture(c.deadMark)
    icon.dead:SetSize(size * 0.95, size * 0.95)
    icon.dead:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.badge = CreateFrame("Frame", nil, icon)
    icon.badge:SetSize(c.badge, c.badge)
    icon.badge:SetPoint("CENTER", icon, "CENTER", 19.5 * scale, -22 * scale)
    icon.badge:SetFrameLevel(icon:GetFrameLevel() + 2)
    icon.badgeRing = icon.badge:CreateTexture(nil, "BORDER")
    icon.badgeRing:SetAllPoints()
    icon.badgeFill = icon.badge:CreateTexture(nil, "ARTWORK")
    icon.badgeFill:SetPoint("TOPLEFT", icon.badge, "TOPLEFT", 1.5, -1.5)
    icon.badgeFill:SetPoint("BOTTOMRIGHT", icon.badge, "BOTTOMRIGHT", -1.5, 1.5)
    icon.badgeFill:SetColorTexture(0.05, 0.04, 0.03, 0.95)
    if icon.badge.CreateMaskTexture and icon.badgeRing.AddMaskTexture then
        for _, texture in ipairs({icon.badgeRing, icon.badgeFill}) do
            local mask = icon.badge:CreateMaskTexture()
            mask:SetAllPoints(texture)
            mask:SetTexture(c.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            texture:AddMaskTexture(mask)
        end
    end

    icon.badgeText = icon.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon.badgeText:SetPoint("CENTER", icon.badge, "CENTER", 0.5, 0)
    local fontFile, _, fontFlags = icon.badgeText:GetFont()
    if fontFile then icon.badgeText:SetFont(fontFile, c.badgeFont, fontFlags) end
    icon.badgeSkull = icon.badge:CreateTexture(nil, "OVERLAY")
    icon.badgeSkull:SetSize(c.badge - 5, c.badge - 5)
    icon.badgeSkull:SetPoint("CENTER", icon.badge, "CENTER", 0, 0)
    icon.badgeSkull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    icon:SetScript("OnEnter", function(sel) Tracker:ShowBossTooltip(sel) end)
    icon:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    self.icons[index] = icon

    return icon
end

function Tracker:ShowBossTooltip(icon)
    local entry = icon.entry
    if entry == nil then return end
    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    if icon.concealed then
        GameTooltip:AddLine("???", 1, 0.82, 0)
        GameTooltip:AddLine(AzerothCompendium:Trans("LID_SPOILERFREE"), 0.7, 0.7, 0.7)
        GameTooltip:Show()

        return
    end

    GameTooltip:AddLine(AzerothCompendium:GetBossName(entry.boss), 1, 0.82, 0)
    local level = AzerothCompendium:GetBossLevel(entry.boss)
    if level then GameTooltip:AddLine(format("%s %d", LEVEL or "Level", level), 1, 1, 1) end
    if icon.killed then GameTooltip:AddLine(DEAD or "Dead", 1, 0.25, 0.25) end
    GameTooltip:Show()
end

function Tracker:UpdateBadge(icon, entry)
    local style = self.ranks[entry.rank] or self.ranks[0]
    local level = AzerothCompendium:GetBossLevel(entry.boss)
    local skull = entry.rank == 3 or (level ~= nil and level >= self.config.skullLevel)
    if level == nil and not skull then
        icon.badge:Hide()

        return
    end

    icon.badgeRing:SetColorTexture(style.ring[1], style.ring[2], style.ring[3], 1)
    icon.badgeSkull:SetShown(skull)
    icon.badgeText:SetShown(not skull)
    if not skull then
        icon.badgeText:SetText(level)
        icon.badgeText:SetTextColor(AzerothCompendium:GetLevelDifficultyColor(level))
    end

    icon.badge:Show()
end

function Tracker:IsBossConcealed(entry, killed)
    return not killed and type(ACOTABPC) == "table" and ACOTABPC.SPOILERFREE == true and not AzerothCompendium:IsBossFound(entry.boss)
end

function Tracker:UpdateIcon(icon, entry, killed)
    icon.entry = entry
    icon.killed = killed
    icon.concealed = self:IsBossConcealed(entry, killed)
    if icon.concealed then
        icon.portrait:SetTexture(self.config.fallback)
        icon.portrait:SetDesaturated(true)
        icon.portrait:SetVertexColor(0.5, 0.5, 0.5)
        icon.dragon:Hide()
        icon.badge:Hide()
        icon.dead:Hide()
        icon:Show()

        return
    end

    local applied = false
    if entry.boss.model ~= nil and SetPortraitTextureFromCreatureDisplayID then applied = pcall(SetPortraitTextureFromCreatureDisplayID, icon.portrait, entry.boss.model) end
    if not applied then icon.portrait:SetTexture(self.config.fallback) end
    icon.portrait:SetDesaturated(killed)
    local shade = killed and 0.6 or 1
    icon.portrait:SetVertexColor(shade, shade, shade)
    local style = self.ranks[entry.rank]
    if style and style.dragon then
        icon.dragon:SetTexture(self.config.media .. style.dragon)
        icon.dragon:Show()
    else
        icon.dragon:Hide()
    end

    self:UpdateBadge(icon, entry)
    icon.dead:SetShown(killed)
    icon:Show()
end

function Tracker:PlaceIcons(run, list, index, top, width)
    local c = self.config
    local perRow = max(1, floor(width / c.cellW))
    for position, entry in ipairs(list) do
        index = index + 1
        local icon = self:AcquireIcon(index)
        local col = (position - 1) % perRow
        local row = floor((position - 1) / perRow)
        local inRow = min(perRow, #list - row * perRow)
        local left = c.panelPad + (width - inRow * c.cellW) / 2
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", self.frame.bosses, "TOPLEFT", left + col * c.cellW + c.iconX, top - row * c.cellH - c.iconY)
        self:UpdateIcon(icon, entry, self:IsKilled(run, entry.boss))
    end

    return top - ceil(#list / perRow) * c.cellH, index
end

function Tracker:GetItemTexture(link)
    if type(link) ~= "string" then return nil end
    local itemID = tonumber(strmatch(link, "item:(%d+)"))
    local item = C_Item or {}
    local lookups = {{item.GetItemIconByID, itemID}, {GetItemIcon, itemID}, {item.GetItemInfoInstant, link, 5}, {GetItemInfoInstant, link, 5}}
    for _, lookup in ipairs(lookups) do
        if lookup[1] and lookup[2] then
            local result = {pcall(lookup[1], lookup[2])}
            local texture = result[1] and result[(lookup[3] or 1) + 1]
            if texture then return texture end
        end
    end

    return nil
end

function Tracker:CreateLootRow(parent)
    local c = self.config
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(c.lootRow)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(c.lootRow - 4, c.lootRow - 4)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.winner = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.winner:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.winner:SetJustifyH("RIGHT")
    row.winner:SetWordWrap(false)
    row.winner:SetWidth(90)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.text:SetPoint("RIGHT", row.winner, "LEFT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row:SetScript("OnEnter", function(sel)
        if sel.link == nil then return end
        GameTooltip:SetOwner(sel, "ANCHOR_LEFT")
        GameTooltip:SetHyperlink(sel.link)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function() AzerothCompendium:HideGameTooltip() end)
    row:SetScript("OnClick", function(sel)
        if sel.link and HandleModifiedItemClick then HandleModifiedItemClick(sel.link) end
    end)

    function row:Update(entry)
        self.link = entry.link
        self.icon:SetTexture(Tracker:GetItemTexture(entry.link) or Tracker.config.fallback)
        self.text:SetText(entry.link)
        if entry.class == nil then entry.class = Tracker:GetUnitClass(entry.winner) end
        self.winner:SetText(Tracker:ShortName(entry.winner) or "")
        local color = entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
        if color then
            self.winner:SetTextColor(color.r, color.g, color.b)
        else
            self.winner:SetTextColor(0.9, 0.9, 0.9)
        end
    end

    return row
end

function Tracker:CreateRunRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(self.config.runRow)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -3)
    row.date = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.date:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -5)
    row.date:SetJustifyH("RIGHT")
    row.date:SetWordWrap(false)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.title:SetPoint("RIGHT", row.date, "LEFT", -6, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.info:SetPoint("TOPLEFT", row.icon, "BOTTOMLEFT", 2, -4)
    row.info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.info:SetJustifyH("LEFT")
    row.info:SetWordWrap(false)
    row:SetScript("OnClick", function(sel) Tracker:ShowRun(sel.run) end)
    function row:Update(run)
        self.run = run
        local current = run == Tracker:GetRun()
        local bosses = Tracker:GetBosses(run)
        self.icon:SetTexture((run.finished or run.ended) and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-Waiting")
        self.title:SetText(Tracker:GetRunTitle(run))
        self.date:SetText(current and AzerothCompendium:Trans("LID_DT_CURRENT") or date("%d.%m.%y %H:%M", run.start or 0))
        local secondText = Tracker:ShowsXP() and format("%s %s   ", Tracker:FormatNumber(run.xp or 0), XP or "XP") or format("%s %s   ", Tracker:FormatNumber(run.rep or 0), AzerothCompendium:Trans("LID_REPUTATION"))
        self.info:SetText(format("%s   %s   %s %d/%d   %s%s", Tracker:GetModeLabel(run), Tracker:FormatTime(Tracker:GetElapsed(run)), AzerothCompendium:Trans("LID_BOSSES"), Tracker:CountKilled(run, bosses), #bosses, secondText, Tracker:FormatMoney(run.gold or 0)))
    end

    return row
end

function Tracker:ShowRuns()
    self.listMode = true
    self.forced = true
    self:CreateFrame():Show()
    self:Refresh()
end

function Tracker:ShowRun(run)
    self.listMode = nil
    self.viewRun = run ~= self:GetRun() and run or nil
    self.lastViewed = run
    self.forced = true
    self:UpdateVisibility()
end

function Tracker:RefreshRuns()
    local frame = self.frame
    local c = self.config
    local runs = self:GetAllRuns()
    if frame.titleText then frame.titleText:SetText(format("%s (%d)", AzerothCompendium:Trans("LID_DT_RUNS"), #runs)) end
    self:SyncCollapsedChrome(frame, false)
    self:LayoutHeaderTitle(frame, false)
    frame.content:Hide()
    frame.headerTime:Hide()
    frame.post:Hide()
    frame.toggle:Hide()
    frame.grip:Show()
    frame.runList:Show()
    frame.runsEmpty:SetText(AzerothCompendium:Trans("LID_DT_NORUNS"))
    frame.runsEmpty:SetShown(#runs == 0)
    local minHeight = c.top + c.bottom + c.runRow * 2
    if frame.SetResizeBounds then
        frame:SetResizeBounds(c.minWidth, minHeight, 0, 0)
    elseif frame.SetMinResize then
        frame:SetMinResize(c.minWidth, minHeight)
    end

    frame:SetHeight(max(minHeight, frame.userHeight or c.runsHeight))
    frame.runList.data = runs
    frame.runList:Refresh()
end

function Tracker:UpdateStats()
    local frame = self.frame
    local run = self:GetShownRun()
    if frame == nil or run == nil or not frame:IsShown() or self.listMode then return end
    local columns = frame.statColumns
    local best = run.mode == "unranked" and {} or self:GetBest(run)
    local elapsed = self:FormatTime(self:GetElapsed(run))
    local showXP = self:ShowsXP()
    local secondValue = showXP and (run.xp or 0) or (run.rep or 0)
    local secondBest = showXP and best.xp or best.rep
    columns[1].value:SetText(elapsed)
    columns[2].value:SetText(self:FormatNumber(secondValue))
    columns[3].value:SetText(self:FormatMoney(run.gold or 0))
    columns[1].best:SetText(AzerothCompendium:Trans("LID_DT_BEST", nil, best.time and self:FormatTime(best.time) or "-"))
    columns[2].best:SetText(AzerothCompendium:Trans("LID_DT_BEST", nil, secondBest and self:FormatNumber(secondBest) or "-"))
    columns[3].best:SetText(AzerothCompendium:Trans("LID_DT_BEST", nil, best.gold and self:FormatMoney(best.gold) or "-"))
    frame.headerTime:SetText(format("%s · %s", self:GetModeLabel(run), elapsed))
    if run.ended or (run.finished and run.mode ~= "unranked") then
        columns[1].value:SetTextColor(0.25, 1, 0.25)
    else
        columns[1].value:SetTextColor(1, 1, 1)
    end
end

function Tracker:Layout()
    local frame = self.frame
    if frame == nil or frame.layingOut then return end
    if self.listMode then
        self:RefreshRuns()

        return
    end

    frame.layingOut = true
    local c = self.config
    local collapsed = self:IsCollapsed()
    frame.runList:Hide()
    frame.post:Show()
    frame.toggle:Show()
    AzerothCompendium.Theme:SetCollapseIcon(frame.toggle.icon, collapsed)
    frame.content:SetShown(not collapsed)
    frame.grip:SetShown(not collapsed)
    frame.headerTime:SetShown(collapsed)
    self:SyncCollapsedChrome(frame, collapsed)
    self:LayoutHeaderTitle(frame, collapsed)
    if collapsed then
        frame:SetHeight(AzerothCompendium.Theme:IsModern() and c.collapsedModern or c.collapsed)
        frame.layingOut = false

        return
    end

    local innerWidth = frame:GetWidth() - c.side * 2
    local columnWidth = innerWidth / 3
    for index, column in ipairs(frame.statColumns) do
        column.label:Show()
        column.value:Show()
        column.best:Show()
        column.label:ClearAllPoints()
        column.label:SetPoint("TOP", frame.stats, "TOPLEFT", columnWidth * (index - 0.5), -8)
        column.label:SetWidth(columnWidth - 8)
        column.value:SetWidth(columnWidth - 8)
        column.best:SetWidth(columnWidth - 8)
        if column.hit then
            column.hit:ClearAllPoints()
            column.hit:SetPoint("TOPLEFT", frame.stats, "TOPLEFT", columnWidth * (index - 1), 0)
            column.hit:SetPoint("BOTTOMLEFT", frame.stats, "BOTTOMLEFT", columnWidth * (index - 1), 0)
            column.hit:SetWidth(columnWidth)
        end
    end

    local run = self:GetShownRun()
    local unranked = run.mode == "unranked"
    local controls = not self.viewRun and self:IsCurrentInstance(run) and not run.ended and (unranked or not run.finished)
    frame.controls:SetShown(controls)
    local anchor = controls and frame.controls or frame.stats
    if controls then
        for index, button in ipairs(frame.controls) do
            button:SetWidth(columnWidth - 2)
            button:SetPoint("TOPLEFT", frame.controls, "TOPLEFT", (index - 1) * columnWidth + 1, 0)
        end
        frame.controls[1]:SetWidth(unranked and columnWidth - 2 or innerWidth - 2)
        frame.controls[1]:SetText(AzerothCompendium:Trans(unranked and "LID_DT_RESUME" or "LID_DT_STARTUNRANKED"))
        frame.controls[2]:SetShown(unranked)
        frame.controls[3]:SetShown(unranked)
        frame.controls[1]:SetEnabled(not unranked or run.paused ~= nil)
        frame.controls[2]:SetText(AzerothCompendium:Trans("LID_DT_PAUSE"))
        frame.controls[2]:SetEnabled(unranked and not run.paused)
        frame.controls[3]:SetText(AzerothCompendium:Trans("LID_DT_END"))
        frame.controls[3]:SetEnabled(unranked)
    end
    frame.bosses:ClearAllPoints()
    frame.bosses:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -c.gap)
    frame.bosses:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -c.gap)
    local bosses, rares = self.bossList or {}, self.rareList or {}
    local bossesCollapsed = self:IsBossesCollapsed()
    local raresCollapsed = self:IsRaresCollapsed()
    local iconWidth = innerWidth - c.panelPad * 2
    local top = -c.panelPad
    local index = 0
    local lastCollapsed = false
    frame.bossHeader:SetShown(#bosses > 0)
    if #bosses > 0 then
        AzerothCompendium.Theme:SetCollapseIcon(frame.bossHeader.icon, bossesCollapsed)
        frame.bossHeader:ClearAllPoints()
        frame.bossHeader:SetPoint("TOPLEFT", frame.bosses, "TOPLEFT", c.panelPad + 2, top)
        frame.bossHeader:SetPoint("TOPRIGHT", frame.bosses, "TOPRIGHT", -c.panelPad, top)
        top = top - c.label
        if bossesCollapsed then
            lastCollapsed = true
        else
            top, index = self:PlaceIcons(run, bosses, index, top, iconWidth)
            lastCollapsed = false
        end
    end

    frame.rareHeader:SetShown(#rares > 0)
    if #rares > 0 then
        if #bosses > 0 then top = top - 4 end
        AzerothCompendium.Theme:SetCollapseIcon(frame.rareHeader.icon, raresCollapsed)
        frame.rareHeader:ClearAllPoints()
        frame.rareHeader:SetPoint("TOPLEFT", frame.bosses, "TOPLEFT", c.panelPad + 2, top)
        frame.rareHeader:SetPoint("TOPRIGHT", frame.bosses, "TOPRIGHT", -c.panelPad, top)
        top = top - c.label
        if raresCollapsed then
            lastCollapsed = true
        else
            top, index = self:PlaceIcons(run, rares, index, top, iconWidth)
            lastCollapsed = false
        end
    end

    for i = index + 1, #self.icons do
        self.icons[i]:Hide()
    end

    local hasBosses = #bosses > 0 or #rares > 0
    local bossHeight = 0
    local lootAnchor = anchor
    if hasBosses then
        bossHeight = -top + (lastCollapsed and c.panelPad or 2)
        frame.bosses:SetHeight(bossHeight)
        frame.bosses:Show()
        lootAnchor = frame.bosses
    else
        frame.bosses:Hide()
    end

    local lootCollapsed = self:IsLootCollapsed()
    AzerothCompendium.Theme:SetCollapseIcon(frame.lootHeader.icon, lootCollapsed)
    frame.lootFilters:ClearAllPoints()
    frame.lootFilters:SetPoint("TOPRIGHT", lootAnchor, "BOTTOMRIGHT", 0, -c.gap - 2)
    frame.lootHeader:ClearAllPoints()
    frame.lootHeader:SetPoint("TOPLEFT", lootAnchor, "BOTTOMLEFT", 2, -c.gap - 2)
    frame.lootHeader:SetPoint("RIGHT", frame.lootFilters, "LEFT", -6, 0)
    self:UpdateQualityFilters()
    frame.loot:ClearAllPoints()
    frame.loot:SetPoint("TOPLEFT", lootAnchor, "BOTTOMLEFT", 0, -c.gap - c.label - 4)
    frame.loot:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", 0, 0)
    frame.loot:SetShown(not lootCollapsed)
    local fixed = c.top + c.stats + (controls and frame.controls:GetHeight() + c.gap or 0) + c.gap + (hasBosses and bossHeight + c.gap or 0) + c.label + 4 + c.bottom
    local minHeight = lootCollapsed and fixed or fixed + c.lootMin
    if frame.SetResizeBounds then
        frame:SetResizeBounds(c.minWidth, minHeight, 0, 0)
    elseif frame.SetMinResize then
        frame:SetMinResize(c.minWidth, minHeight)
    end

    if lootCollapsed then
        frame:SetHeight(fixed)
    else
        frame:SetHeight(max(minHeight, frame.userHeight or fixed + c.lootExtra))
    end
    frame.layingOut = false
    frame.loot:Refresh()
    AzerothCompendium.Theme.PageText:Refresh(frame.stats)
    AzerothCompendium.Theme.PageText:Refresh(frame.bosses)
end

function Tracker:Refresh()
    local frame = self.frame
    if frame == nil or not frame:IsShown() then return end
    if self.listMode then
        self:RefreshRuns()

        return
    end

    local run = self:GetShownRun()
    if run == nil then return end
    local title = self:GetRunTitle(run)
    if self.viewRun then title = format("%s - %s", title, date("%d.%m.%y", run.start or 0)) end
    if frame.titleText then frame.titleText:SetText(title) end
    self:SyncChromeLevels(frame)
    local showXP = self:ShowsXP()
    frame.statColumns[1].label:SetText(self:GetModeLabel(run))
    frame.statColumns[2].label:SetText(AzerothCompendium:Trans(showXP and "LID_DT_MOBXP" or "LID_REPUTATION"))
    frame.statColumns[3].label:SetText(AzerothCompendium:Trans("LID_DT_GOLD"))
    self.bossList, self.rareList = self:GetBosses(run)
    frame.bossLabel:SetText(format("%s (%d/%d)", AzerothCompendium:Trans("LID_BOSSES"), self:CountKilled(run, self.bossList), #self.bossList))
    frame.rareLabel:SetText(format("%s (%d/%d)", AzerothCompendium:Trans("LID_DT_RARES"), self:CountKilled(run, self.rareList), #self.rareList))
    local loot, total = self:GetFilteredLoot(run)
    frame.lootLabel:SetText(format("%s (%d)", AzerothCompendium:Trans("LID_LOOT"), #loot))
    frame.lootEmpty:SetText(AzerothCompendium:Trans(total == 0 and "LID_DT_NOLOOT" or "LID_DT_NOLOOTFILTERED"))
    frame.lootEmpty:SetShown(#loot == 0)
    frame.loot.data = loot
    self:Layout()
    self:UpdateStats()
end

function Tracker:UpdateVisibility()
    local run = self:GetRun()
    local show = self.listMode or self.viewRun ~= nil or (run ~= nil and (self.forced or (self:IsEnabled() and (self:IsCurrentInstance(run) or (self.away and run.active)) and not run.closed)))
    if not show then
        if self.frame then self.frame:Hide() end

        return
    end

    self:CreateFrame():Show()
    self:Refresh()
end

function Tracker:Close()
    if self.listMode or self.viewRun then
        self.listMode = nil
        self.viewRun = nil
        self.forced = false
        self:UpdateVisibility()
        self:NotifyMapChange()

        return
    end

    local run = self:GetRun()
    if run and (self:IsCurrentInstance(run) or self.away) then run.closed = true end
    self.forced = false
    if self.frame then self.frame:Hide() end
end

function Tracker:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Close()

        return
    end

    local run = self:GetRun()
    if run == nil then
        self:ShowRuns()

        return
    end

    run.closed = nil
    self.forced = true
    self:UpdateVisibility()
end

function Tracker:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:CheckZone()
        if C_Timer and C_Timer.After then C_Timer.After(2, function() Tracker:CheckZone() end) end
    elseif event == "PLAYER_REGEN_DISABLED" then
        local currentID = self:GetCurrentInstance()
        if currentID ~= nil and currentID == self.instanceID then
            self:StartRankedRun()
            self:Refresh()
        end
    elseif event == "UNIT_HEALTH" then
        self:OnUnitHealth(...)
    elseif event == "ENCOUNTER_END" then
        local _, encounterName, _, _, success = ...
        self:OnEncounterEnd(encounterName, success)
    elseif event == "BOSS_KILL" then
        local _, encounterName = ...
        self:OnEncounterEnd(encounterName, true)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        self:OnXP(...)
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        self:OnReputation(...)
    elseif event == "UPDATE_FACTION" then
        self:OnUpdateFaction()
    elseif event == "PLAYER_MONEY" then
        self:OnMoney()
    elseif event == "CHAT_MSG_LOOT" then
        self:OnLoot(...)
    elseif event == "CHAT_MSG_SYSTEM" then
        self:OnSystem(...)
    elseif event == "LOOT_OPENED" then
        self:OnLootOpened()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:OnUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        self:OnUnit("mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        self:OnUnit(...)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        self:CheckAway()
    elseif event == "PLAYER_LEVEL_UP" then
        if C_Timer and C_Timer.After then C_Timer.After(0, function() Tracker:Refresh() end) else self:Refresh() end
    end
end

Tracker.eventFrame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_DISABLED", "UNIT_HEALTH", "ENCOUNTER_END", "BOSS_KILL", "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_COMBAT_FACTION_CHANGE", "UPDATE_FACTION", "PLAYER_MONEY", "CHAT_MSG_LOOT", "CHAT_MSG_SYSTEM", "LOOT_OPENED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "GROUP_ROSTER_UPDATE", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_LEVEL_UP"}) do
    pcall(Tracker.eventFrame.RegisterEvent, Tracker.eventFrame, event)
end

Tracker.eventFrame:SetScript("OnEvent", function(_, event, ...) Tracker:OnEvent(event, ...) end)
