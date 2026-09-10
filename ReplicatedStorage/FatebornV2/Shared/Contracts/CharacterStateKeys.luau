--!strict

-- Semantic vocabulary only. Legacy Humanoid state, attributes, and private
-- server/client tables remain authoritative during M1.

local Locomotion = table.freeze({
	Idle = "Idle",
	Walk = "Walk",
	Run = "Run",
	Jump = "Jump",
	Fall = "Fall",
	Climb = "Climb",
	Swim = "Swim",
	SwimIdle = "SwimIdle",
})

local Action = table.freeze({
	None = "None",
	Basic = "Basic",
	M1 = "Basic",
	Roll = "Roll",
	Block = "Block",
	Parry = "Parry",
	AbilityCast = "AbilityCast",
	Skill = "AbilityCast",
	Dash = "Dash",
})

local Condition = table.freeze({
	None = "None",
	HitReaction = "HitReaction",
	Flinch = "Flinch",
	Stagger = "Stagger",
	Finisher = "Finisher",
	Death = "Death",
})

return table.freeze({
	Locomotion = Locomotion,
	Action = Action,
	Condition = Condition,
})
