local _, AzerothCompendium = ...
local lootByInstance = {}
for name, loot in pairs(AzerothCompendium.TRASH) do
	lootByInstance[name] = loot
end

for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
	if inst.type == "dungeon" then
		tinsert(inst.bosses, {
			["name"] = "Trash",
			["trash"] = true,
			["loot"] = lootByInstance[inst.name] or {},
		})
	end
end
