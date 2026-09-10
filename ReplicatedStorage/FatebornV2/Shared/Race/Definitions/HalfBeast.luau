--!strict

local definition = {
	Name = "Half-Beast",
	Rarity = "Common",
	ActiveConfig = table.freeze({
		Power = 1.03,
		Description = "Slight speed or strength bonus",
		PassivesAreDescriptiveOnly = true,
	}),
	LegacyRaceData = table.freeze({
		Weight = 95,
		Description = "Human-animal hybrid with balanced stats.",
	}),
	LegacyM1Profile = table.freeze({
		Damage = 1.03,
		Reach = 4.8,
		Width = 4.1,
		Combo = 5,
		Tempo = 1.08,
		Knockback = 1.00,
		Cleave = 1,
		UsedByActiveBasicDamage = false,
	}),
	Character = table.freeze({
		Mode = "CustomGraftedPackage",
		StarterPath = "StarterPlayer.StarterCharacter",
		TemplateFolder = "PlayerAssetSources",
		TemplateName = "HalfBeastCharacter",
		CharacterModelName = "Char half beast",
		AssetId = 92882444915511,
		BoneCharacter = true,
		HasCustomPackage = true,
	}),
	AnimationProfile = "HalfBeast",
	KnownDivergence = table.freeze({
		"Active Config and legacy RaceData use different probability schemas and descriptions.",
		"M1Config Half-Beast Damage/Reach/Width/Combo/Tempo/Cleave do not drive the active Basic path.",
		"Race Power affects displayed aggregate Power but is not multiplied into active Basic or ability damage.",
	}),
}

return table.freeze(definition)
