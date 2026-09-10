--!strict

-- Canonical vocabulary for actions that exist in the current legacy contracts.
-- This module does not route, validate, or execute any action.

export type ActionId =
	"Basic"
	| "Ability"
	| "Sprint"
	| "Roll"
	| "Block"
	| "Dash"
	| "IntroSeen"
	| "DebugHit"

local Canonical = table.freeze({
	Basic = "Basic",
	M1 = "Basic",
	Ability = "Ability",
	Skill = "Ability",
	Sprint = "Sprint",
	Roll = "Roll",
	Block = "Block",
	Dash = "Dash",
	IntroSeen = "IntroSeen",
	DebugHit = "DebugHit",
})

-- Channel-specific tables deliberately preserve duplicate legacy names. Sprint
-- exists on two RemoteEvents today; Roll and Dash are different current paths.
local LegacyContracts = table.freeze({
	FatebornAction = table.freeze({
		Basic = "Basic",
		Ability = "Ability",
		Sprint = "Sprint",
		Dash = "Dash",
		IntroSeen = "IntroSeen",
	}),
	PlayerMovement = table.freeze({
		Sprint = "Sprint",
		Roll = "Roll",
	}),
	CombatDefense = table.freeze({
		Block = "Block",
		DebugHit = "DebugHit",
	}),
})

return table.freeze({
	Canonical = Canonical,
	LegacyContracts = LegacyContracts,
})
