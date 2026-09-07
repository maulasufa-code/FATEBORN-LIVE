local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local StaminaSystem = require(ServerStorage:WaitForChild("ZeroScript"):WaitForChild("StaminaSystem"))

local HitReactionSystem = {}

HitReactionSystem.Config = {
	FlinchDuration = 0.16,
	StaggerDuration = 0.58,
	FinisherLockDuration = 0.34,
	HeavyPressure = 1.15,
	PressureResetTime = 1.35,
	MinKnockbackScale = 0.55,
	MaxKnockbackScale = 1.15,
}

local reactionTokens = setmetatable({}, { __mode = "k" })
local staggerPressure = setmetatable({}, { __mode = "k" })

local function durabilityPower(model)
	local value = model:GetAttribute("DurabilityPower")
		or model:GetAttribute("Durability")
		or model:GetAttribute("FateDurability")

	if type(value) == "number" then
		return math.clamp(value, 0.65, 1.60)
	end

	return 1
end

local function durationFor(kind, durability)
	local resistance = math.clamp(1 / durability, 0.55, 1.20)

	if kind == "Light" then
		return HitReactionSystem.Config.FlinchDuration * math.clamp(resistance, 0.72, 1.15)
	elseif kind == "Heavy" then
		return HitReactionSystem.Config.StaggerDuration * resistance
	elseif kind == "Finisher" then
		return HitReactionSystem.Config.FinisherLockDuration * math.clamp(resistance, 0.70, 1.10)
	end

	return 0
end

local function heavyBreaksPoise(model, durability)
	local now = os.clock()
	local state = staggerPressure[model]

	if not state or now - state.last > HitReactionSystem.Config.PressureResetTime then
		state = { value = 0, last = now }
		staggerPressure[model] = state
	end

	state.last = now
	state.value += HitReactionSystem.Config.HeavyPressure

	if state.value + 0.001 >= durability then
		state.value = 0
		return true
	end

	return false
end

local function setReaction(model, reactionName, duration, enemyData)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end

	local now = workspace:GetServerTimeNow()
	local token = (reactionTokens[model] or 0) + 1
	reactionTokens[model] = token

	model:SetAttribute("HitReaction", reactionName)
	model:SetAttribute("HitReactionStartedAt", now)
	model:SetAttribute("HitReactionUntil", now + duration)
	model:SetAttribute("Staggered", reactionName == "Stagger")
	model:SetAttribute("AnimationHitAt", now)

	if enemyData then
		enemyData.ActionToken = (enemyData.ActionToken or 0) + 1
		enemyData.ActionEnd = math.max(enemyData.ActionEnd or 0, os.clock() + duration)
		humanoid:Move(Vector3.zero)
		humanoid:MoveTo(root.Position)
		model:SetAttribute("AnimationRunning", false)
	end

	local player = Players:GetPlayerFromCharacter(model)
	if player then
		model:SetAttribute("Sprinting", false)
		StaminaSystem.SetDrain(player, "Sprint", false, StaminaSystem.Config.SprintDrainPerSecond)
		humanoid.WalkSpeed = 0
	end

	task.delay(duration, function()
		if not model.Parent or reactionTokens[model] ~= token then
			return
		end

		model:SetAttribute("HitReaction", nil)
		model:SetAttribute("HitReactionUntil", nil)
		model:SetAttribute("Staggered", false)

		local currentHumanoid = model:FindFirstChildOfClass("Humanoid")
		if player and currentHumanoid and currentHumanoid.Health > 0 then
			currentHumanoid.WalkSpeed = model:GetAttribute("BaseWalkSpeed") or 14
		end
	end)

	return true
end

function HitReactionSystem.IsLocked(model)
	if not model then
		return false
	end

	return workspace:GetServerTimeNow() < (model:GetAttribute("HitReactionUntil") or -math.huge)
end

function HitReactionSystem.Apply(model, kind, sourcePosition, knockbackForce, enemyData)
	if not model or not model.Parent then
		return false, "InvalidTarget"
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return false, "Dead"
	end

	local durability = durabilityPower(model)

	if kind == "Heavy" and not heavyBreaksPoise(model, durability) then
		setReaction(model, "Flinch", HitReactionSystem.Config.FlinchDuration * 0.55, enemyData)
		return false, "ResistedStagger"
	end

	local reactionName = kind == "Heavy" and "Stagger"
		or kind == "Finisher" and "Finisher"
		or "Flinch"

	local duration = durationFor(kind, durability)
	setReaction(model, reactionName, duration, enemyData)

	if kind == "Heavy" then
		root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	elseif kind == "Finisher" and typeof(sourcePosition) == "Vector3" then
		local direction = root.Position - sourcePosition
		local flat = Vector3.new(direction.X, 0, direction.Z)
		if flat.Magnitude > 0.05 then
			local scale = math.clamp(1 / durability, HitReactionSystem.Config.MinKnockbackScale, HitReactionSystem.Config.MaxKnockbackScale)
			local force = (knockbackForce or 48) * scale
			root.AssemblyLinearVelocity = flat.Unit * force + Vector3.new(0, math.max(8, force * 0.24), 0)
		end
	end

	return true, reactionName
end

return HitReactionSystem
