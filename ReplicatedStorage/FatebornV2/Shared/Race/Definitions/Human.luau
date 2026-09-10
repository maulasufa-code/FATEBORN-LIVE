--!strict

local definition = {
	Name = "Human",
	Rarity = "Common",
	ActiveConfig = table.freeze({
		Power = 1.00,
		Description = "Bonus EXP gain; No inherent weakness",
		PassivesAreDescriptiveOnly = true,
	}),
	LegacyRaceData = table.freeze({
		Weight = 95,
		Description = "Flexible baseline race with hidden late-game evolution.",
	}),
	LegacyM1Profile = table.freeze({
		Damage = 1.00,
		Reach = 4.6,
		Width = 4.0,
		Combo = 4,
		Tempo = 1.00,
		Knockback = 1.00,
		Cleave = 1,
		UsedByActiveBasicDamage = false,
	}),
	Character = table.freeze({
		Mode = "GenericStarterCharacter",
		StarterPath = "StarterPlayer.StarterCharacter",
		BoneCharacter = true,
		HasCustomPackage = false,
	}),
	AnimationProfile = "Human",
	KnownDivergence = table.freeze({
		"Active Config and legacy RaceData use different probability schemas and descriptions.",
		"M1Config has race geometry/damage fields, but active Basic damage does not consume them.",
		"HumanBoxingBones is enabled in Studio but the server currently emits Basic cues only for Half-Beast.",
	}),
}

return table.freeze(definition)
