--!strict

local definitionsFolder = script.Parent:WaitForChild("Definitions")
local Human = require(definitionsFolder:WaitForChild("Human"))
local HalfBeast = require(definitionsFolder:WaitForChild("HalfBeast"))

export type CharacterDefinition = {
	Mode: string,
	StarterPath: string,
	BoneCharacter: boolean,
	HasCustomPackage: boolean,
	TemplateFolder: string?,
	TemplateName: string?,
	CharacterModelName: string?,
	AssetId: number?,
}

export type RaceDefinition = {
	Name: string,
	Rarity: string,
	ActiveConfig: { [string]: any },
	LegacyRaceData: { [string]: any },
	LegacyM1Profile: { [string]: any },
	Character: CharacterDefinition,
	AnimationProfile: string,
	KnownDivergence: { string },
}

local definitions: { [string]: RaceDefinition } = table.freeze({
	Human = Human,
	["Half-Beast"] = HalfBeast,
})

local function sortedNames(set: { [string]: boolean }): { string }
	local result = {}
	for name in pairs(set) do
		table.insert(result, name)
	end
	table.sort(result)
	return result
end

local function namesFromActivePool(pool: { any }): { [string]: boolean }
	local result = {}
	for _, item in ipairs(pool) do
		if type(item) == "table" and type(item.Name) == "string" then
			result[item.Name] = true
		end
	end
	return result
end

local function namesFromLegacyRaceData(data: { any }): { [string]: boolean }
	local result = {}
	for _, item in ipairs(data) do
		if type(item) == "table" and type(item.name) == "string" then
			result[item.name] = true
		end
	end
	return result
end

local function namesFromM1(races: { [string]: any }): { [string]: boolean }
	local result = {}
	for name in pairs(races) do
		result[name] = true
	end
	return result
end

local function difference(left: { [string]: boolean }, right: { [string]: boolean }): { string }
	local result = {}
	for name in pairs(left) do
		if not right[name] then
			table.insert(result, name)
		end
	end
	table.sort(result)
	return result
end

local RaceRegistry = {}

function RaceRegistry.Get(raceName: string): RaceDefinition?
	return definitions[raceName]
end

function RaceRegistry.GetPilotNames(): { string }
	return { "Human", "Half-Beast" }
end

function RaceRegistry.GetKnownDivergence(raceName: string): { string }?
	local definition = definitions[raceName]
	return definition and definition.KnownDivergence or nil
end

-- Accepts the live source tables as inputs so requiring RaceRegistry has no
-- dependency on, or side effect from, legacy modules.
function RaceRegistry.CompareLegacySources(activePool: { any }, legacyRaceData: { any }, m1Races: { [string]: any })
	local active = namesFromActivePool(activePool)
	local legacy = namesFromLegacyRaceData(legacyRaceData)
	local m1 = namesFromM1(m1Races)

	return {
		ActiveRoster = sortedNames(active),
		LegacyRoster = sortedNames(legacy),
		M1Roster = sortedNames(m1),
		ActiveMissingFromLegacy = difference(active, legacy),
		LegacyMissingFromActive = difference(legacy, active),
		ActiveMissingFromM1 = difference(active, m1),
		M1MissingFromActive = difference(m1, active),
		SchemaDivergence = true,
		SchemaNote = "Shared.Config uses rarity/power; RaceData uses per-entry weight; M1Config uses combat geometry.",
	}
end

return table.freeze(RaceRegistry)
