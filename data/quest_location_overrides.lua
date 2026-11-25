local _, AzerothCompendium = ...
local OVERRIDES = {
	inside = {92456, 92457, 92458, 92489, 96984, 96986, 96988},
	endInside = {
		[92459] = 16544,
	},
}

AzerothCompendium.QUESTINSIDE = AzerothCompendium.QUESTINSIDE or {}
for _, questID in ipairs(OVERRIDES.inside) do
	AzerothCompendium.QUESTINSIDE[questID] = true
end

AzerothCompendium.QUESTENDERS = AzerothCompendium.QUESTENDERS or {}
for questID, instanceID in pairs(OVERRIDES.endInside) do
	local ender = AzerothCompendium.QUESTENDERS[questID]
	if ender then ender[7] = instanceID end
end
