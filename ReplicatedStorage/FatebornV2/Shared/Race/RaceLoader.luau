--!strict

local RaceRegistry = require(script.Parent:WaitForChild("RaceRegistry"))

local RaceLoader = {}

-- Resolution only. This function never clones, reparents, grafts, spawns, or
-- assigns Player.Character.
function RaceLoader.Resolve(raceName: string)
	local definition = RaceRegistry.Get(raceName)
	if definition then
		return table.freeze({
			RaceName = raceName,
			Definition = definition,
			Character = definition.Character,
			UsesGenericStarterFallback = not definition.Character.HasCustomPackage,
			Resolved = true,
		})
	end

	local human = RaceRegistry.Get("Human")
	assert(human, "Human pilot definition is required")
	return table.freeze({
		RaceName = raceName,
		Definition = nil,
		Character = human.Character,
		UsesGenericStarterFallback = true,
		Resolved = false,
		ResolutionNote = "No M1 pilot definition; current runtime retains the generic StarterCharacter fallback.",
	})
end

function RaceLoader.HasCustomPackage(raceName: string): boolean
	local definition = RaceRegistry.Get(raceName)
	return definition ~= nil and definition.Character.HasCustomPackage == true
end

return table.freeze(RaceLoader)
