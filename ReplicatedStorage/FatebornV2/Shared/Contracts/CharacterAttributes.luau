--!strict

-- Constants map canonical concepts to the exact strings used by the legacy
-- runtime. M1 intentionally does not rename or write any of these attributes.

local Player = table.freeze({
	Stamina = "Stamina",
	MaxStamina = "MaxStamina",
	GameplayActive = "GameplayActive",
	LegacyRace = "Race",
	LegacyRaceTier = "RaceTier",
	LegacyRaceDescription = "RaceDescription",
})

local Character = table.freeze({
	FatebornPlayerId = "FatebornPlayerId",
	Race = "Race",
	RaceName = "RaceName",
	FateRace = "FateRace",
	Ability = "Ability",
	Power = "Power",

	FatebornBoneCharacter = "FatebornBoneCharacter",
	PlayerModelAssetId = "PlayerModelAssetId",
	RaceCharacterProfile = "RaceCharacterProfile",
	RaceCharacterAssetId = "RaceCharacterAssetId",

	StrengthPower = "StrengthPower",
	SpeedPower = "SpeedPower",
	DurabilityPower = "DurabilityPower",
	FightingMasteryPower = "FightingMasteryPower",
	Strength = "Strength",
	Speed = "Speed",
	Durability = "Durability",
	FightingMastery = "FightingMastery",
	Mastery = "Mastery",
	FateStrength = "FateStrength",
	FateSpeed = "FateSpeed",
	FateDurability = "FateDurability",

	BaseWalkSpeed = "BaseWalkSpeed",
	Sprinting = "Sprinting",
	Dashing = "Dashing",
	RollStartedAt = "RollStartedAt",
	Blocking = "Blocking",
	BasicAttackStartedAt = "BasicAttackStartedAt",
	BasicAttackComboIndex = "BasicAttackComboIndex",
	SkillCastStartedAt = "SkillCastStartedAt",
	HitReaction = "HitReaction",
	HitReactionStartedAt = "HitReactionStartedAt",
	HitReactionUntil = "HitReactionUntil",
	Staggered = "Staggered",

	M1RangeMultiplier = "M1RangeMultiplier",
	M1ComboBonus = "M1ComboBonus",
	M1TempoMultiplier = "M1TempoMultiplier",
	M1DamageMultiplier = "M1DamageMultiplier",
	DamageTakenMultiplier = "DamageTakenMultiplier",

	CombatFacingLock = "CombatFacingLock",
	LocalAnimationState = "LocalAnimationState",
	LocalAnimationSource = "LocalAnimationSource",
})

local RaceReadOrder = table.freeze({
	Character.Race,
	Character.RaceName,
	Character.FateRace,
})

local StatReadOrder = table.freeze({
	Strength = table.freeze({ Character.StrengthPower, Character.Strength, Character.FateStrength }),
	Speed = table.freeze({ Character.SpeedPower, Character.Speed, Character.FateSpeed }),
	Durability = table.freeze({ Character.DurabilityPower, Character.Durability, Character.FateDurability }),
	FightingMastery = table.freeze({ Character.FightingMastery, Character.FightingMasteryPower, Character.Mastery }),
})

return table.freeze({
	Player = Player,
	Character = Character,
	RaceReadOrder = RaceReadOrder,
	StatReadOrder = StatReadOrder,
})
