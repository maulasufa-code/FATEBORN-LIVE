local Config = {}

Config.Version = "Prototype 0.1"
Config.MaxLevel = 30
Config.ZoneTwoLevel = 8
Config.BaseRerollCost = 1 -- One universal ticket per chosen category reroll
Config.PityThreshold = 20
Config.WorldBossTicketDropChance = 0.01

-- Replace zeroes after publishing the experience. Keeping IDs in one place makes
-- monetization auditable and prevents purchase logic from leaking into combat code.
Config.Monetization = {
	DoubleExpPass = 0,
	DoubleGoldPass = 0,
	QuadBoostProduct = 0,
	QuadBoostSeconds = 15 * 60,
}

Config.Rarity = {
	Common = { Weight = 60, Color = Color3.fromRGB(185, 194, 205), Rank = 1 },
	Uncommon = { Weight = 25, Color = Color3.fromRGB(83, 214, 125), Rank = 2 },
	Rare = { Weight = 10, Color = Color3.fromRGB(72, 149, 255), Rank = 3 },
	Epic = { Weight = 4, Color = Color3.fromRGB(173, 92, 255), Rank = 4 },
	Legendary = { Weight = 0.8, Color = Color3.fromRGB(255, 178, 46), Rank = 5 },
	Mythic = { Weight = 0.18, Color = Color3.fromRGB(255, 65, 128), Rank = 6 },
	Secret = { Weight = 0.02, Color = Color3.fromRGB(255, 242, 160), Rank = 7 },
}

Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

local function entry(name, rarity, power, extra)
	local result = extra or {}
	result.Name = name
	result.Rarity = rarity
	result.Power = power
	return result
end

local function race(name, rarity, power, description, passives, extra)
	local result = extra or {}
	result.Name = name
	result.Rarity = rarity
	result.Power = power
	result.Description = description
	result.Passives = passives or {}
	return result
end

Config.Pools = {
	Race = {
		-- Common
		race("Human", "Common", 1.00, "Bonus EXP gain; No inherent weakness", {
			"Bonus EXP gain",
			"No inherent weakness",
		}),
		race("Half-Beast", "Common", 1.03, "Slight speed or strength bonus", {
			"Slight speed or strength bonus",
		}),
		race("Goblin", "Common", 1.04, "Evasion bonus; Extra gold gain", {
			"Evasion bonus",
			"Extra gold gain",
		}),
		race("Dwarf", "Common", 1.05, "Durability bonus; Crafting efficiency", {
			"Durability bonus",
			"Crafting efficiency",
		}),

		-- Uncommon
		race("Beastkin", "Uncommon", 1.08, "Movement speed bonus; Dash cooldown reduction; Attack tempo bonus", {
			"Movement speed bonus",
			"Dash cooldown reduction",
			"Attack tempo bonus",
		}),
		race("Orc", "Uncommon", 1.10, "Strength bonus; Out-of-combat regen", {
			"Strength bonus",
			"Out-of-combat regen",
		}),
		race("Elf", "Uncommon", 1.11, "Ability power bonus; Mana regen bonus; Precision bonus", {
			"Ability power bonus",
			"Mana regen bonus",
			"Precision bonus",
		}),
		race("Halfling", "Uncommon", 1.09, "Luck bonus; Critical chance bonus", {
			"Luck bonus",
			"Critical chance bonus",
		}),
		race("Lizardfolk", "Uncommon", 1.10, "Strong regeneration; Poison resistance; Swim speed", {
			"Strong regeneration",
			"Poison resistance",
			"Swim speed",
		}),
		race("Harpy", "Uncommon", 1.10, "Limited flight; Fast attacks; Physical vulnerability", {
			"Limited flight",
			"Fast attacks",
			"Physical vulnerability",
		}),

		-- Rare
		race("Demon", "Rare", 1.16, "Physical damage bonus; Lifesteal on kill; Dark aura", {
			"Physical damage bonus",
			"Lifesteal on kill",
			"Dark aura",
		}),
		race("Vampire", "Rare", 1.18, "Strong lifesteal; Sunlight weakness", {
			"Strong lifesteal",
			"Sunlight weakness",
		}),
		race("Werewolf", "Rare", 1.18, "Transformation speed and strength; Reduced control at full moon", {
			"Transformation speed and strength",
			"Reduced control at full moon",
		}),
		race("Naga", "Rare", 1.17, "Area attack bonus; Low mobility", {
			"Area attack bonus",
			"Low mobility",
		}),
		race("Kitsune", "Rare", 1.19, "Illusion utility; Charm bonus", {
			"Illusion utility",
			"Charm bonus",
		}),
		race("Drow", "Rare", 1.17, "Dark damage bonus; Light weakness", {
			"Dark damage bonus",
			"Light weakness",
		}),

		-- Epic
		race("Celestial", "Epic", 1.26, "Light damage bonus; Brief hover; Mana regen", {
			"Light damage bonus",
			"Brief hover",
			"Mana regen",
		}),
		race("Dragonborn", "Epic", 1.28, "Elemental resistance; HP bonus; Elemental transform", {
			"Elemental resistance",
			"HP bonus",
			"Elemental transform",
		}),
		race("Phoenix", "Epic", 1.29, "Fire damage bonus; One-time revival", {
			"Fire damage bonus",
			"One-time revival",
		}),
		race("Titan", "Epic", 1.30, "HP bonus; Knockback resistance; Larger size", {
			"HP bonus",
			"Knockback resistance",
			"Larger size",
		}),
		race("Elementalborn", "Epic", 1.28, "Elemental affinity; Elemental evolution", {
			"Elemental affinity",
			"Elemental evolution",
		}),
		race("Sylph", "Epic", 1.27, "High speed; Frequent light attacks", {
			"High speed",
			"Frequent light attacks",
		}),
		race("Undead", "Epic", 1.27, "Dark regen; Light weakness", {
			"Dark regen",
			"Light weakness",
		}),
		race("Djinn", "Epic", 1.29, "Ability power bonus; Short teleport", {
			"Ability power bonus",
			"Short teleport",
		}),

		-- Legendary
		race("Elder Dragon", "Legendary", 1.40, "Massive durability; Elemental breath attack", {
			"Massive durability",
			"Elemental breath attack",
		}),
		race("Archon", "Legendary", 1.42, "Large area attacks; Cosmic authority", {
			"Large area attacks",
			"Cosmic authority",
		}),
		race("Oni Lord", "Legendary", 1.41, "Massive strength; Rage regeneration", {
			"Massive strength",
			"Rage regeneration",
		}),
		race("Wendigo", "Legendary", 1.39, "Damage scaling at low HP; Frost theme", {
			"Damage scaling at low HP",
			"Frost theme",
		}),
		race("Leviathan", "Legendary", 1.41, "Area control; Low mobility", {
			"Area control",
			"Low mobility",
		}),

		-- Mythic
		race("Fallen Seraph", "Mythic", 1.62, "Dual mode based on alignment; Self-damage risk", {
			"Dual mode based on alignment",
			"Self-damage risk",
		}),
		race("Abyssal", "Mythic", 1.64, "High dark damage; Corruption effect", {
			"High dark damage",
			"Corruption effect",
		}),
		race("Voidborne", "Mythic", 1.66, "Damage negation; Effect resistance", {
			"Damage negation",
			"Effect resistance",
		}),
		race("Chronos", "Mythic", 1.68, "Time slow on enemies; Time-based evolution", {
			"Time slow on enemies",
			"Time-based evolution",
		}),
		race("World Eater", "Mythic", 1.70, "Extreme destruction; Cosmic devour", {
			"Extreme destruction",
			"Cosmic devour",
		}),

		-- Secret
		race("Primordial", "Secret", 2.00, "Unlimited scaling; Special evolution path", {
			"Unlimited scaling",
			"Special evolution path",
		}),
	},
	Potential = {
		entry("Crippled", "Common", 0.82), entry("Poor", "Common", 0.92),
		entry("Average", "Uncommon", 1.00), entry("Gifted", "Rare", 1.16),
		entry("Genius", "Epic", 1.34), entry("Monstrous", "Legendary", 1.58),
		entry("Limitless", "Secret", 2.10),
	},
	Ability = {
		entry("Flame", "Common", 1.00, { Accent = Color3.fromRGB(255, 98, 47) }),
		entry("Wind", "Uncommon", 1.07, { Accent = Color3.fromRGB(134, 255, 204) }),
		entry("Lightning", "Rare", 1.18, { Accent = Color3.fromRGB(255, 232, 73) }),
		entry("Blood", "Epic", 1.30, { Accent = Color3.fromRGB(194, 25, 52) }),
		entry("Gravity", "Legendary", 1.48, { Accent = Color3.fromRGB(159, 84, 255) }),
		entry("Shadow", "Mythic", 1.70, { Accent = Color3.fromRGB(91, 74, 160) }),
		entry("Time Fracture", "Secret", 2.12, { Accent = Color3.fromRGB(117, 255, 241) }),
	},
	Weakness = {
		entry("Fragile Body", "Common", 0.90), entry("Mana Deficiency", "Common", 0.93),
		entry("Heavy Steps", "Uncommon", 0.95), entry("Sun Curse", "Rare", 0.98),
		entry("Blood Hunger", "Epic", 1.02), entry("Unstable Power", "Legendary", 1.08),
		entry("Fate Scar", "Mythic", 1.13),
	},
	Strength = {}, Speed = {}, Durability = {}, Stamina = {}, IQ = {}, FightingMastery = {},
	WeaponAffinity = {
		entry("Fists", "Common", 1.00), entry("Sword", "Common", 1.02),
		entry("Spear", "Uncommon", 1.05), entry("Greatsword", "Rare", 1.10),
		entry("Katana", "Epic", 1.17), entry("Scythe", "Legendary", 1.28),
		entry("Astral Staff", "Mythic", 1.42),
	},
	Backstory = {
		entry("Village Child", "Common", 1.00), entry("Mercenary's Child", "Uncommon", 1.01),
		entry("Exiled Noble", "Rare", 1.03), entry("Last Survivor", "Legendary", 1.06),
		entry("Child of Prophecy", "Mythic", 1.09), entry("Forgotten God", "Secret", 1.15),
	},
	Alignment = {
		entry("Heroic", "Uncommon", 1.01), entry("Lawful", "Common", 1.00),
		entry("Neutral", "Common", 1.00), entry("Chaotic", "Rare", 1.02),
		entry("Villain", "Epic", 1.04), entry("Calamity", "Mythic", 1.08),
	},
}

Config.RaceWheelOrder = {
	-- SECRET — jam 12
	"Primordial",

	-- COMMON — abu
	"Human",
	"Half-Beast",
	"Goblin",
	"Dwarf",

	-- UNCOMMON — hijau
	"Beastkin",
	"Orc",
	"Elf",
	"Halfling",
	"Lizardfolk",
	"Harpy",

	-- RARE — biru
	"Demon",
	"Vampire",
	"Werewolf",
	"Naga",
	"Kitsune",
	"Drow",

	-- EPIC — ungu
	"Celestial",
	"Dragonborn",
	"Phoenix",
	"Titan",
	"Elementalborn",
	"Sylph",
	"Undead",
	"Djinn",

	-- LEGENDARY — emas
	"Elder Dragon",
	"Archon",
	"Oni Lord",
	"Wendigo",
	"Leviathan",

	-- MYTHIC — merah
	"Fallen Seraph",
	"Abyssal",
	"Voidborne",
	"Chronos",
	"World Eater",
}

local tierData = {
	{ "F", "Common", 0.76 }, { "E", "Common", 0.84 }, { "D", "Common", 0.92 },
	{ "C", "Uncommon", 1.00 }, { "B", "Rare", 1.10 }, { "A", "Epic", 1.22 },
	{ "S", "Legendary", 1.38 }, { "SS", "Mythic", 1.58 }, { "SSS", "Mythic", 1.80 },
	{ "Transcendent", "Secret", 2.15 },
}

for _, category in ipairs({ "Strength", "Speed", "Durability", "Stamina" }) do
	for _, data in ipairs(tierData) do
		table.insert(Config.Pools[category], entry(data[1], data[2], data[3]))
	end
end

Config.Pools.IQ = {
	entry("Dull", "Common", 0.88), entry("Average", "Common", 1.00),
	entry("Sharp", "Uncommon", 1.08), entry("Gifted", "Rare", 1.17),
	entry("Genius", "Epic", 1.30), entry("Supergenius", "Mythic", 1.56),
}

Config.Pools.FightingMastery = {
	entry("Novice", "Common", 0.86), entry("Trained", "Common", 0.96),
	entry("Adept", "Uncommon", 1.05), entry("Expert", "Rare", 1.16),
	entry("Master", "Epic", 1.30), entry("Grandmaster", "Legendary", 1.48),
	entry("Battle Saint", "Mythic", 1.70),
}

Config.Categories = {
	"Race", "Potential", "Ability", "Weakness", "Strength", "Speed", "Durability",
	"Stamina", "FightingMastery", "IQ", "WeaponAffinity", "Backstory", "Alignment",
}

Config.CategoryLabels = {
	FightingMastery = "Fighting Mastery",
	WeaponAffinity = "Weapon Affinity",
}

-- First assignment spins unlock with story progress. Race alone is available at birth.
Config.FateUnlocks = {
	Race = { Kind = "Start", Value = 0, Story = "Awakening" },
	Potential = { Kind = "Kills", Value = 5, Story = "Croco Hunt" },
	Ability = { Kind = "Level", Value = 2, Story = "The First Spark" },
	Strength = { Kind = "Kills", Value = 12, Story = "Trial of Strength" },
	Speed = { Kind = "Level", Value = 3, Story = "The Swift Path" },
	Durability = { Kind = "Kills", Value = 25, Story = "Iron Body" },
	Stamina = { Kind = "Level", Value = 4, Story = "Endless March" },
	FightingMastery = { Kind = "Mastery", Value = 20, Story = "Warrior Discipline" },
	IQ = { Kind = "Level", Value = 5, Story = "Ancient Riddle" },
	WeaponAffinity = { Kind = "BossKills", Value = 1, Story = "Fallen King Trophy" },
	Weakness = { Kind = "BossKills", Value = 1, Story = "Scar of Defeat" },
	Backstory = { Kind = "Level", Value = 6, Story = "Echoes of the Past" },
	Alignment = { Kind = "BossKills", Value = 2, Story = "Judgment of Fate" },
}

Config.Abilities = {
	Flame = {
		{ Name = "Ember Shot", Cooldown = 2.0, Damage = 1.0, Range = 70, Mode = "Projectile" },
		{ Name = "Blazing Step", Cooldown = 6.0, Damage = 0.8, Range = 24, Mode = "Dash" },
		{ Name = "Fire Ring", Cooldown = 9.0, Damage = 1.35, Range = 18, Mode = "Area" },
		{ Name = "Inferno", Cooldown = 16.0, Damage = 2.5, Range = 25, Mode = "Area" },
		{ Name = "Blue Flame", Cooldown = 35.0, Damage = 3.4, Range = 34, Mode = "Awakening" },
	},
	Wind = {
		{ Name = "Air Blade", Cooldown = 1.7, Damage = 0.9, Range = 75, Mode = "Projectile" },
		{ Name = "Gale Rush", Cooldown = 5.0, Damage = 0.8, Range = 30, Mode = "Dash" },
		{ Name = "Cyclone", Cooldown = 8.0, Damage = 1.3, Range = 20, Mode = "Area" },
		{ Name = "Sky Rend", Cooldown = 15.0, Damage = 2.2, Range = 65, Mode = "Line" },
		{ Name = "Tempest Crown", Cooldown = 34.0, Damage = 3.0, Range = 32, Mode = "Awakening" },
	},
	Lightning = {
		{ Name = "Volt Spear", Cooldown = 2.3, Damage = 1.15, Range = 85, Mode = "Projectile" },
		{ Name = "Flash Step", Cooldown = 5.5, Damage = 1.0, Range = 34, Mode = "Dash" },
		{ Name = "Chain Arc", Cooldown = 8.5, Damage = 1.45, Range = 28, Mode = "Area" },
		{ Name = "Thunder Verdict", Cooldown = 17.0, Damage = 2.7, Range = 70, Mode = "Line" },
		{ Name = "Heavenly Thunder", Cooldown = 36.0, Damage = 3.6, Range = 38, Mode = "Awakening" },
	},
	Blood = {
		{ Name = "Blood Needle", Cooldown = 2.0, Damage = 1.05, Range = 72, Mode = "Projectile" },
		{ Name = "Crimson Lunge", Cooldown = 5.8, Damage = 1.1, Range = 27, Mode = "Dash" },
		{ Name = "Sanguine Cage", Cooldown = 9.0, Damage = 1.55, Range = 19, Mode = "Area" },
		{ Name = "Red Moon", Cooldown = 17.5, Damage = 2.8, Range = 29, Mode = "Area" },
		{ Name = "Blood Monarch", Cooldown = 37.0, Damage = 3.8, Range = 36, Mode = "Awakening" },
	},
	Gravity = {
		{ Name = "Gravity Crush", Cooldown = 2.8, Damage = 1.25, Range = 78, Mode = "Projectile" },
		{ Name = "Repulsion", Cooldown = 6.5, Damage = 1.1, Range = 22, Mode = "Area" },
		{ Name = "Gravity Field", Cooldown = 10.0, Damage = 1.75, Range = 24, Mode = "Area" },
		{ Name = "Meteor Fall", Cooldown = 19.0, Damage = 3.2, Range = 32, Mode = "Area" },
		{ Name = "Gravity Sovereign", Cooldown = 40.0, Damage = 4.2, Range = 42, Mode = "Awakening" },
	},
	Shadow = {
		{ Name = "Shade Cut", Cooldown = 2.1, Damage = 1.25, Range = 74, Mode = "Projectile" },
		{ Name = "Umbral Step", Cooldown = 5.2, Damage = 1.25, Range = 38, Mode = "Dash" },
		{ Name = "Night Prison", Cooldown = 9.5, Damage = 1.8, Range = 24, Mode = "Area" },
		{ Name = "Abyssal Maw", Cooldown = 18.0, Damage = 3.35, Range = 34, Mode = "Area" },
		{ Name = "Shadow Emperor", Cooldown = 39.0, Damage = 4.4, Range = 42, Mode = "Awakening" },
	},
	["Time Fracture"] = {
		{ Name = "Second Hand", Cooldown = 1.6, Damage = 1.45, Range = 90, Mode = "Projectile" },
		{ Name = "Lost Moment", Cooldown = 4.5, Damage = 1.4, Range = 42, Mode = "Dash" },
		{ Name = "Still World", Cooldown = 8.0, Damage = 2.0, Range = 28, Mode = "Area" },
		{ Name = "Age Collapse", Cooldown = 16.0, Damage = 3.7, Range = 38, Mode = "Area" },
		{ Name = "Chrono Dominion", Cooldown = 38.0, Damage = 4.8, Range = 46, Mode = "Awakening" },
	},
}

Config.Enemies = {
	Wanderer = { Level = 1, MaxHealth = 85, Damage = 8, Gold = 9, Exp = 18, Essence = 1, Color = Color3.fromRGB(113, 126, 139) },
	FateHound = { Level = 4, MaxHealth = 165, Damage = 13, Gold = 18, Exp = 34, Essence = 2, Color = Color3.fromRGB(94, 39, 65) },
	AshKnight = { Level = 8, MaxHealth = 310, Damage = 20, Gold = 35, Exp = 62, Essence = 4, Color = Color3.fromRGB(72, 66, 83) },
	RiftCultist = { Level = 11, MaxHealth = 430, Damage = 25, Gold = 48, Exp = 86, Essence = 6, Color = Color3.fromRGB(62, 37, 103) },
	FallenKing = { Level = 35, MaxHealth = 12000, Damage = 75, Gold = 650, Exp = 1800, Essence = 150, Fragments = 35, Boss = true, Color = Color3.fromRGB(168, 116, 45) },
}

function Config.GetRarityColor(rarity)
	return (Config.Rarity[rarity] or Config.Rarity.Common).Color
end

function Config.GetRarityRank(rarity)
	return (Config.Rarity[rarity] or Config.Rarity.Common).Rank
end

function Config.GetAbilityKit(name)
	return Config.Abilities[name] or Config.Abilities.Flame
end

return Config
