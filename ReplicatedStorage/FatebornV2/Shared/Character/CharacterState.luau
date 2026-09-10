--!strict

local CharacterAttributes = require(script.Parent.Parent:WaitForChild("Contracts"):WaitForChild("CharacterAttributes"))
local StateKeys = require(script.Parent.Parent:WaitForChild("Contracts"):WaitForChild("CharacterStateKeys"))
local CharacterContext = require(script.Parent:WaitForChild("CharacterContext"))

export type Signals = {
	HumanoidState: string,
	Health: number,
	HorizontalSpeed: number,
	VerticalSpeed: number,
	IsAirborne: boolean,
	Sprinting: boolean,
	RollStartedAt: number?,
	Blocking: boolean,
	BasicAttackStartedAt: number?,
	BasicAttackComboIndex: number?,
	SkillCastStartedAt: number?,
	HitReaction: string?,
	HitReactionStartedAt: number?,
	HitReactionUntil: number?,
	Staggered: boolean,
}

local CharacterState = {}

local function numberAttribute(character: Model, name: string): number?
	local value = character:GetAttribute(name)
	return type(value) == "number" and value or nil
end

function CharacterState.GatherSignals(context: CharacterContext.Context): Signals
	local character = context.Character
	local velocity = context.RootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local reaction = character:GetAttribute(CharacterAttributes.Character.HitReaction)

	return {
		HumanoidState = context.Humanoid:GetState().Name,
		Health = context.Humanoid.Health,
		HorizontalSpeed = horizontalSpeed,
		VerticalSpeed = velocity.Y,
		IsAirborne = context.Humanoid.FloorMaterial == Enum.Material.Air,
		Sprinting = character:GetAttribute(CharacterAttributes.Character.Sprinting) == true,
		RollStartedAt = numberAttribute(character, CharacterAttributes.Character.RollStartedAt),
		Blocking = character:GetAttribute(CharacterAttributes.Character.Blocking) == true,
		BasicAttackStartedAt = numberAttribute(character, CharacterAttributes.Character.BasicAttackStartedAt),
		BasicAttackComboIndex = numberAttribute(character, CharacterAttributes.Character.BasicAttackComboIndex),
		SkillCastStartedAt = numberAttribute(character, CharacterAttributes.Character.SkillCastStartedAt),
		HitReaction = type(reaction) == "string" and reaction or nil,
		HitReactionStartedAt = numberAttribute(character, CharacterAttributes.Character.HitReactionStartedAt),
		HitReactionUntil = numberAttribute(character, CharacterAttributes.Character.HitReactionUntil),
		Staggered = character:GetAttribute(CharacterAttributes.Character.Staggered) == true,
	}
end

local function resolveLocomotion(signals: Signals): string
	if signals.HumanoidState == "Swimming" then
		return signals.HorizontalSpeed > 0.7 and StateKeys.Locomotion.Swim or StateKeys.Locomotion.SwimIdle
	elseif signals.HumanoidState == "Climbing" then
		return StateKeys.Locomotion.Climb
	elseif signals.HumanoidState == "Jumping" then
		return StateKeys.Locomotion.Jump
	elseif signals.HumanoidState == "Freefall" or signals.IsAirborne then
		return signals.VerticalSpeed > 0 and StateKeys.Locomotion.Jump or StateKeys.Locomotion.Fall
	elseif signals.HorizontalSpeed > 0.7 then
		return signals.Sprinting and StateKeys.Locomotion.Run or StateKeys.Locomotion.Walk
	end
	return StateKeys.Locomotion.Idle
end

local function resolveCondition(signals: Signals, now: number): string
	if signals.Health <= 0 then
		return StateKeys.Condition.Death
	end
	if signals.HitReactionUntil and now < signals.HitReactionUntil then
		if signals.Staggered or signals.HitReaction == StateKeys.Condition.Stagger then
			return StateKeys.Condition.Stagger
		elseif signals.HitReaction == StateKeys.Condition.Finisher then
			return StateKeys.Condition.Finisher
		elseif signals.HitReaction == StateKeys.Condition.Flinch then
			return StateKeys.Condition.Flinch
		end
		return StateKeys.Condition.HitReaction
	end
	return StateKeys.Condition.None
end

local function lastActionCue(signals: Signals)
	local basicAt = signals.BasicAttackStartedAt
	local skillAt = signals.SkillCastStartedAt
	if skillAt and (not basicAt or skillAt > basicAt) then
		return table.freeze({ Name = StateKeys.Action.AbilityCast, StartedAt = skillAt, Active = false })
	elseif basicAt then
		return table.freeze({
			Name = StateKeys.Action.Basic,
			StartedAt = basicAt,
			ComboIndex = signals.BasicAttackComboIndex,
			Active = false,
		})
	end
	return nil
end

-- Resolves a shadow snapshot from supplied facts. Basic/skill timestamps are
-- reported as cues, not asserted as current actions, because legacy replicates
-- no authoritative end time. Parry has no Player attribute at all.
function CharacterState.ResolveSignals(signals: Signals, now: number)
	local condition = resolveCondition(signals, now)
	local action = StateKeys.Action.None
	local rollStartedAt = signals.RollStartedAt
	local rollActive = rollStartedAt ~= nil and now >= rollStartedAt and now - rollStartedAt < 0.60

	if condition == StateKeys.Condition.None then
		if rollActive then
			action = StateKeys.Action.Roll
		elseif signals.Blocking then
			action = StateKeys.Action.Block
		end
	end

	return table.freeze({
		Locomotion = resolveLocomotion(signals),
		Action = action,
		Condition = condition,
		RollActive = rollActive,
		LastActionCue = lastActionCue(signals),
		Signals = table.freeze(table.clone(signals)),
		Ambiguities = table.freeze({
			"BasicAttackStartedAt and SkillCastStartedAt have no replicated authoritative end time.",
			"Parry is a derived server event and has no Player/Character state attribute.",
			"Legacy client actionName/actionUntil is private local state and cannot be read here.",
		}),
	})
end

function CharacterState.Read(context: CharacterContext.Context, now: number?)
	return CharacterState.ResolveSignals(CharacterState.GatherSignals(context), now or workspace:GetServerTimeNow())
end

return table.freeze(CharacterState)
