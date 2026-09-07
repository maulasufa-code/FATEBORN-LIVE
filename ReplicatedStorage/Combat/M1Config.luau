local Config = {}

--==================================================
-- GLOBAL
--==================================================

Config.BaseDamage = 10

Config.HitboxHeight = 5.4

-- Tambahan jarak hanya untuk memilih target.
-- BUKAN tambahan range damage.
Config.TargetExtraRange = 0.75

-- Target assist.
Config.ClientTargetHalfAngle = 90
Config.ServerTargetHalfAngle = 100

Config.FaceDuration = 0.16
Config.FaceSpeed = 30

Config.MinAttackInterval = 0.18
Config.MaxAttackInterval = 0.62

Config.AllowPvP = false


--==================================================
-- RACE M1 PROFILE
--
-- Damage    = multiplier damage dasar
-- Reach     = panjang serangan (stud)
-- Width     = lebar hitbox
-- Combo     = combo maximum bawaan race
-- Tempo     = attack-speed bawaan race
-- Knockback = finisher force multiplier
-- Cleave    = maximum musuh terkena 1 swing
--==================================================

Config.Races = {

	-- COMMON
	Human = {
		Damage = 1.00,
		Reach = 4.6,
		Width = 4.0,
		Combo = 4,
		Tempo = 1.00,
		Knockback = 1.00,
		Cleave = 1,
	},

	["Half-Beast"] = {
		Damage = 1.03,
		Reach = 4.8,
		Width = 4.1,
		Combo = 5,
		Tempo = 1.08,
		Knockback = 1.00,
		Cleave = 1,
	},

	Goblin = {
		Damage = 0.90,
		Reach = 4.1,
		Width = 3.6,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 0.80,
		Cleave = 1,
	},

	Dwarf = {
		Damage = 1.12,
		Reach = 4.3,
		Width = 4.4,
		Combo = 3,
		Tempo = 0.92,
		Knockback = 1.25,
		Cleave = 1,
	},


	-- UNCOMMON
	Beastkin = {
		Damage = 1.02,
		Reach = 4.8,
		Width = 4.0,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 1.00,
		Cleave = 1,
	},

	Orc = {
		Damage = 1.15,
		Reach = 4.7,
		Width = 4.6,
		Combo = 3,
		Tempo = 0.90,
		Knockback = 1.35,
		Cleave = 2,
	},

	Elf = {
		Damage = 0.98,
		Reach = 5.2,
		Width = 3.8,
		Combo = 4,
		Tempo = 1.08,
		Knockback = 0.90,
		Cleave = 1,
	},

	Halfling = {
		Damage = 0.91,
		Reach = 3.9,
		Width = 3.4,
		Combo = 6,
		Tempo = 1.14,
		Knockback = 0.70,
		Cleave = 1,
	},

	Lizardfolk = {
		Damage = 1.08,
		Reach = 5.5,
		Width = 4.5,
		Combo = 4,
		Tempo = 0.98,
		Knockback = 1.15,
		Cleave = 1,
	},

	Harpy = {
		Damage = 0.96,
		Reach = 5.0,
		Width = 4.1,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 0.90,
		Cleave = 1,
	},


	-- RARE
	Demon = {
		Damage = 1.12,
		Reach = 4.9,
		Width = 4.4,
		Combo = 4,
		Tempo = 1.05,
		Knockback = 1.20,
		Cleave = 1,
	},

	Vampire = {
		Damage = 1.06,
		Reach = 4.8,
		Width = 4.0,
		Combo = 5,
		Tempo = 1.10,
		Knockback = 0.95,
		Cleave = 1,
	},

	Werewolf = {
		Damage = 1.14,
		Reach = 5.0,
		Width = 4.5,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 1.20,
		Cleave = 1,
	},

	Naga = {
		Damage = 1.08,
		Reach = 6.0,
		Width = 4.8,
		Combo = 4,
		Tempo = 0.95,
		Knockback = 1.05,
		Cleave = 2,
	},

	Kitsune = {
		Damage = 0.98,
		Reach = 5.1,
		Width = 3.8,
		Combo = 6,
		Tempo = 1.15,
		Knockback = 0.80,
		Cleave = 1,
	},

	Drow = {
		Damage = 1.03,
		Reach = 5.3,
		Width = 3.7,
		Combo = 5,
		Tempo = 1.10,
		Knockback = 0.90,
		Cleave = 1,
	},


	-- EPIC
	Celestial = {
		Damage = 1.04,
		Reach = 5.4,
		Width = 4.2,
		Combo = 5,
		Tempo = 1.08,
		Knockback = 1.00,
		Cleave = 1,
	},

	Dragonborn = {
		Damage = 1.16,
		Reach = 5.2,
		Width = 4.8,
		Combo = 4,
		Tempo = 0.94,
		Knockback = 1.30,
		Cleave = 2,
	},

	Phoenix = {
		Damage = 1.05,
		Reach = 5.1,
		Width = 4.2,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 0.95,
		Cleave = 1,
	},

	Titan = {
		Damage = 1.22,
		Reach = 5.6,
		Width = 5.2,
		Combo = 3,
		Tempo = 0.82,
		Knockback = 1.50,
		Cleave = 2,
	},


	-- LEGENDARY
	Archon = {
		Damage = 1.10,
		Reach = 5.5,
		Width = 4.5,
		Combo = 4,
		Tempo = 1.02,
		Knockback = 1.20,
		Cleave = 1,
	},

	Leviathan = {
		Damage = 1.14,
		Reach = 6.2,
		Width = 5.0,
		Combo = 4,
		Tempo = 0.90,
		Knockback = 1.35,
		Cleave = 2,
	},

	Seraph = {
		Damage = 1.06,
		Reach = 5.8,
		Width = 4.3,
		Combo = 5,
		Tempo = 1.12,
		Knockback = 1.00,
		Cleave = 1,
	},

	Reaper = {
		Damage = 1.14,
		Reach = 6.0,
		Width = 4.6,
		Combo = 4,
		Tempo = 1.00,
		Knockback = 1.30,
		Cleave = 2,
	},

	Lich = {
		Damage = 0.98,
		Reach = 5.6,
		Width = 4.0,
		Combo = 4,
		Tempo = 0.96,
		Knockback = 0.80,
		Cleave = 1,
	},

	Valkyrie = {
		Damage = 1.10,
		Reach = 5.4,
		Width = 4.5,
		Combo = 5,
		Tempo = 1.10,
		Knockback = 1.15,
		Cleave = 1,
	},

	Djinn = {
		Damage = 0.96,
		Reach = 5.7,
		Width = 4.0,
		Combo = 6,
		Tempo = 1.16,
		Knockback = 0.75,
		Cleave = 1,
	},

	Minotaur = {
		Damage = 1.20,
		Reach = 5.4,
		Width = 5.0,
		Combo = 3,
		Tempo = 0.88,
		Knockback = 1.50,
		Cleave = 2,
	},

	Banshee = {
		Damage = 0.94,
		Reach = 5.8,
		Width = 4.1,
		Combo = 5,
		Tempo = 1.08,
		Knockback = 0.65,
		Cleave = 1,
	},

	Centaur = {
		Damage = 1.10,
		Reach = 5.8,
		Width = 4.8,
		Combo = 4,
		Tempo = 1.06,
		Knockback = 1.20,
		Cleave = 2,
	},


	-- MYTHIC
	Ancient = {
		Damage = 1.10,
		Reach = 5.7,
		Width = 4.5,
		Combo = 5,
		Tempo = 1.02,
		Knockback = 1.15,
		Cleave = 1,
	},

	Primordial = {
		Damage = 1.15,
		Reach = 6.0,
		Width = 4.8,
		Combo = 5,
		Tempo = 1.10,
		Knockback = 1.25,
		Cleave = 2,
	},

	Archdemon = {
		Damage = 1.18,
		Reach = 5.6,
		Width = 4.8,
		Combo = 4,
		Tempo = 1.05,
		Knockback = 1.35,
		Cleave = 2,
	},

	["World Serpent"] = {
		Damage = 1.16,
		Reach = 6.5,
		Width = 5.2,
		Combo = 4,
		Tempo = 0.96,
		Knockback = 1.30,
		Cleave = 2,
	},

	Voidwalker = {
		Damage = 1.00,
		Reach = 5.8,
		Width = 4.0,
		Combo = 6,
		Tempo = 1.18,
		Knockback = 0.75,
		Cleave = 1,
	},
}


--==================================================
-- COMBO DAMAGE CURVES
--==================================================

Config.ComboDamage = {

	[3] = {
		0.90,
		1.00,
		1.35,
	},

	[4] = {
		0.82,
		0.90,
		1.00,
		1.35,
	},

	[5] = {
		0.72,
		0.80,
		0.88,
		0.98,
		1.32,
	},

	[6] = {
		0.64,
		0.72,
		0.80,
		0.88,
		0.98,
		1.30,
	},
}


--==================================================
-- STAT TIERS
--==================================================

local TierPower = {
	f = 0.78,
	e = 0.84,
	d = 0.90,
	c = 0.96,
	b = 1.00,
	a = 1.08,
	s = 1.16,
	ss = 1.24,
	sss = 1.34,
	transcendent = 1.48,
}


local MasteryComboCap = {
	novice = 3,
	beginner = 3,
	apprentice = 3,

	adept = 4,
	skilled = 4,

	expert = 5,
	master = 5,

	grandmaster = 6,
	transcendent = 6,

	f = 3,
	e = 3,
	d = 3,

	c = 4,
	b = 4,
	a = 4,

	s = 5,
	ss = 5,

	sss = 6,
}


--==================================================
-- HELPERS
--==================================================

local function normalize(value)

	return string.lower(
		tostring(value or "")
	)
		:gsub("[%s_%-]", "")
end


local normalizedRaces = {}

for name, data in pairs(Config.Races) do

	data.Name = name

	normalizedRaces[normalize(name)] = data
end


local function readAttribute(character, names)

	for _, name in ipairs(names) do

		local value = character:GetAttribute(name)

		if value ~= nil then
			return value
		end
	end

	return nil
end


function Config.GetRaceName(character)

	local value = readAttribute(character, {
		"Race",
		"RaceName",
		"FateRace",
	})

	if value == nil then
		return "Human"
	end

	return tostring(value)
end


function Config.GetRaceData(character)

	local raceName = Config.GetRaceName(character)

	local data =
		Config.Races[raceName]
		or normalizedRaces[normalize(raceName)]
		or Config.Races.Human

	return data
end


local function statMultiplier(value)

	if type(value) == "number" then

		-- Fate *.Power milikmu dapat langsung digunakan
		-- kalau bentuknya multiplier sekitar 1.0.

		return math.clamp(
			value,
			0.65,
			1.60
		)
	end

	if type(value) == "string" then

		return TierPower[
		normalize(value)
		] or 1
	end

	return 1
end


function Config.GetStrengthMult(character)

	local value = readAttribute(character, {
		"StrengthPower",
		"Strength",
		"FateStrength",
	})

	return statMultiplier(value)
end


function Config.GetSpeedMult(character)

	local value = readAttribute(character, {
		"SpeedPower",
		"Speed",
		"FateSpeed",
	})

	return math.clamp(
		statMultiplier(value),
		0.78,
		1.28
	)
end


function Config.GetDurabilityDamageTaken(character)

	local value = readAttribute(character, {
		"DurabilityPower",
		"Durability",
		"FateDurability",
	})

	local durability =
		statMultiplier(value)

	return math.clamp(
		1 / durability,
		0.76,
		1.20
	)
end


function Config.GetMasteryComboCap(character)

	local value = readAttribute(character, {
		"FightingMastery",
		"FightingMasteryPower",
		"Mastery",
	})

	if type(value) == "string" then

		return MasteryComboCap[
		normalize(value)
		] or 4
	end


	if type(value) == "number" then

		local power =
			statMultiplier(value)

		if power < 0.90 then
			return 3

		elseif power < 1.15 then
			return 4

		elseif power < 1.35 then
			return 5

		else
			return 6
		end
	end

	return 4
end


function Config.GetMasteryDamageMult(character)

	local value = readAttribute(character, {
		"FightingMastery",
		"FightingMasteryPower",
		"Mastery",
	})


	if type(value) == "number" then

		local power =
			statMultiplier(value)

		return math.clamp(
			1 + (power - 1) * 0.28,
			0.94,
			1.14
		)
	end


	local cap =
		Config.GetMasteryComboCap(character)

	if cap == 3 then
		return 0.97

	elseif cap == 4 then
		return 1.00

	elseif cap == 5 then
		return 1.05

	else
		return 1.10
	end
end


function Config.GetReach(character)

	local race =
		Config.GetRaceData(character)

	local bonus =
		character:GetAttribute(
			"M1RangeMultiplier"
		) or 1

	return race.Reach * bonus
end


function Config.GetComboLimit(character)

	local race =
		Config.GetRaceData(character)

	local mastery =
		Config.GetMasteryComboCap(character)

	local bonus =
		character:GetAttribute(
			"M1ComboBonus"
		) or 0

	return math.clamp(
		math.min(
			race.Combo + bonus,
			mastery
		),
		3,
		6
	)
end


function Config.GetAttackInterval(character)

	local race =
		Config.GetRaceData(character)

	local speed =
		Config.GetSpeedMult(character)

	local external =
		character:GetAttribute(
			"M1TempoMultiplier"
		) or 1

	local interval =
		0.42 /
		(race.Tempo * speed * external)

	return math.clamp(
		interval,
		Config.MinAttackInterval,
		Config.MaxAttackInterval
	)
end


function Config.GetComboResetTime(character)

	return math.max(
		0.82,
		Config.GetAttackInterval(character) * 2.8
	)
end


function Config.GetHitDelay(character)

	local race =
		Config.GetRaceData(character)

	local speed =
		Config.GetSpeedMult(character)

	return math.clamp(
		0.12 / (race.Tempo * speed),
		0.055,
		0.14
	)
end


function Config.GetDamage(
	attacker,
	target,
	comboIndex,
	comboLimit
)

	local race =
		Config.GetRaceData(attacker)

	local strength =
		Config.GetStrengthMult(attacker)

	local mastery =
		Config.GetMasteryDamageMult(attacker)

	local damageBonus =
		attacker:GetAttribute(
			"M1DamageMultiplier"
		) or 1


	local comboTable =
		Config.ComboDamage[comboLimit]
		or Config.ComboDamage[4]

	local comboMultiplier =
		comboTable[comboIndex]
		or 1


	local rawDamage =
		Config.BaseDamage
		* race.Damage
		* strength
		* mastery
		* comboMultiplier
		* damageBonus


	local durability =
		Config.GetDurabilityDamageTaken(
			target
		)


	local targetMultiplier =
		target:GetAttribute(
			"DamageTakenMultiplier"
		) or 1


	return math.max(
		1,
		rawDamage
			* durability
			* targetMultiplier
	)
end


return Config