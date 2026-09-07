local RaceData = require(game.ServerStorage.ZeroScript.Data.RaceData)

local SpinSystem = {}

function SpinSystem.rollWeighted(list)
	local totalWeight = 0
	for _, entry in ipairs(list) do
		totalWeight = totalWeight + (entry.weight or 0)
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(list) do
		cumulative = cumulative + (entry.weight or 0)
		if roll <= cumulative then
			return entry
		end
	end

	return list[#list]
end

function SpinSystem.spinRace()
	return SpinSystem.rollWeighted(RaceData)
end

function SpinSystem.applyRace(player, raceEntry)
	player:SetAttribute("Race", raceEntry.name)
	player:SetAttribute("RaceTier", raceEntry.tier)
	player:SetAttribute("RaceDescription", raceEntry.description or "")
end

return SpinSystem
