--!strict

export type FateValue = { Power: number? }
export type Profile = {
	Level: number,
	Mastery: number,
	Fate: { [string]: FateValue? },
}

local DISPLAY_POWER_CATEGORIES = table.freeze({
	"Race", "Potential", "Ability", "Weakness", "Strength", "Speed", "Durability",
	"Stamina", "FightingMastery", "IQ", "WeaponAffinity", "Backstory", "Alignment",
})

local COMBO_DAMAGE: { [number]: { number } } = table.freeze({
	[3] = table.freeze({ 0.90, 1.00, 1.35 }),
	[4] = table.freeze({ 0.82, 0.90, 1.00, 1.35 }),
	[5] = table.freeze({ 0.72, 0.80, 0.88, 0.98, 1.32 }),
	[6] = table.freeze({ 0.64, 0.72, 0.80, 0.88, 0.98, 1.30 }),
})

local TIER_POWER: { [string]: number } = table.freeze({
	f = 0.78, e = 0.84, d = 0.90, c = 0.96, b = 1.00,
	a = 1.08, s = 1.16, ss = 1.24, sss = 1.34, transcendent = 1.48,
})

local StatCalculator = {}

local function fatePower(profile: Profile, category: string): number
	local value = profile.Fate[category]
	return value and value.Power or 1
end

local function normalize(value: any): string
	return string.lower(tostring(value or "")):gsub("[%s_%-]", "")
end

function StatCalculator.StatMultiplier(value: any): number
	if type(value) == "number" then
		return math.clamp(value, 0.65, 1.60)
	elseif type(value) == "string" then
		return TIER_POWER[normalize(value)] or 1
	end
	return 1
end

function StatCalculator.ComputeDisplayedPower(profile: Profile): number
	local multiplier = 1
	for _, category in ipairs(DISPLAY_POWER_CATEGORIES) do
		local fate = profile.Fate[category]
		if fate then
			multiplier *= 1 + ((fate.Power or 1) - 1) * 0.16
		end
	end
	return math.floor((110 + profile.Level * 82 + profile.Mastery * 3.5) * multiplier)
end

function StatCalculator.ComputeBaseDamage(profile: Profile): number
	local strength = fatePower(profile, "Strength")
	local ability = fatePower(profile, "Ability")
	return (14 + profile.Level * 3.2 + profile.Mastery * 0.22) * strength * ability
end

function StatCalculator.ComputeCharacterStats(profile: Profile, legacyBaseMaxStamina: number?)
	local durability = fatePower(profile, "Durability")
	local speed = fatePower(profile, "Speed")
	local stamina = fatePower(profile, "Stamina")
	return table.freeze({
		MaxHealth = math.floor((100 + profile.Level * 7) * durability),
		MaxStamina = math.floor((legacyBaseMaxStamina or 100) * stamina),
		WalkSpeed = math.clamp(14 * speed, 12, 24),
		JumpPower = math.clamp(50 * (0.94 + speed * 0.08), 45, 65),
	})
end

function StatCalculator.GetSpeedMultiplier(value: any): number
	return math.clamp(StatCalculator.StatMultiplier(value), 0.78, 1.28)
end

function StatCalculator.GetSpeedAttackInterval(value: any): number
	return math.clamp(0.42 / StatCalculator.GetSpeedMultiplier(value), 0.18, 0.62)
end

function StatCalculator.GetSpeedHitDelay(value: any): number
	return math.clamp(0.12 / StatCalculator.GetSpeedMultiplier(value), 0.055, 0.14)
end

function StatCalculator.GetDurabilityDamageTaken(value: any): number
	return math.clamp(1 / StatCalculator.StatMultiplier(value), 0.76, 1.20)
end

function StatCalculator.GetMasteryComboCap(value: any): number
	if type(value) == "number" then
		local power = StatCalculator.StatMultiplier(value)
		if power < 0.90 then
			return 3
		elseif power < 1.15 then
			return 4
		elseif power < 1.35 then
			return 5
		end
		return 6
	end

	local normalized = normalize(value)
	if normalized == "novice" or normalized == "beginner" or normalized == "apprentice"
		or normalized == "f" or normalized == "e" or normalized == "d" then
		return 3
	elseif normalized == "adept" or normalized == "skilled"
		or normalized == "c" or normalized == "b" or normalized == "a" then
		return 4
	elseif normalized == "expert" or normalized == "master"
		or normalized == "s" or normalized == "ss" then
		return 5
	elseif normalized == "grandmaster" or normalized == "transcendent" or normalized == "sss" then
		return 6
	end
	return 4
end

function StatCalculator.GetMasteryDamageMultiplier(value: any): number
	if type(value) == "number" then
		local power = StatCalculator.StatMultiplier(value)
		return math.clamp(1 + (power - 1) * 0.28, 0.94, 1.14)
	end
	local cap = StatCalculator.GetMasteryComboCap(value)
	if cap == 3 then return 0.97 end
	if cap == 4 then return 1.00 end
	if cap == 5 then return 1.05 end
	return 1.10
end

function StatCalculator.GetComboDamageMultiplier(comboLimit: number, comboIndex: number): number
	local curve = COMBO_DAMAGE[comboLimit] or COMBO_DAMAGE[4]
	return curve[comboIndex] or 1
end

-- Mirrors the active Basic formula. Race Power and M1Config race Damage are
-- intentionally absent because the current handler does not use them.
function StatCalculator.ComputeBasicDamage(profile: Profile, masteryPower: any, comboIndex: number): number
	local comboLimit = StatCalculator.GetMasteryComboCap(masteryPower)
	return StatCalculator.ComputeBaseDamage(profile)
		* StatCalculator.GetMasteryDamageMultiplier(masteryPower)
		* StatCalculator.GetComboDamageMultiplier(comboLimit, comboIndex)
end

function StatCalculator.ComputeAbilityDamage(profile: Profile, moveDamageMultiplier: number): number
	return StatCalculator.ComputeBaseDamage(profile) * moveDamageMultiplier
end

return table.freeze(StatCalculator)
