local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StaminaSystem = {}

StaminaSystem.Config = {
	MaxStamina = 100,
	RegenDelay = 1.5,
	RegenPerSecond = 20,
	SprintDrainPerSecond = 18,
	RollCost = 25,
	HeavyAttackCost = 30,
	BlockDrainPerSecond = 12,
}

local states = {}
local depletedEvent = Instance.new("BindableEvent")
StaminaSystem.Depleted = depletedEvent.Event

local function getState(player)
	local state = states[player]
	if state then
		return state
	end

	state = {
		lastUse = -math.huge,
		drains = {},
	}
	states[player] = state
	return state
end

local function getMax(player)
	return player:GetAttribute("MaxStamina") or StaminaSystem.Config.MaxStamina
end

function StaminaSystem.InitPlayer(player)
	local state = getState(player)
	local maxStamina = getMax(player)
	player:SetAttribute("MaxStamina", maxStamina)
	player:SetAttribute("Stamina", maxStamina)

	if not state.characterConnection then
		state.characterConnection = player.CharacterAdded:Connect(function()
			local respawnMax = getMax(player)
			state.drains = {}
			state.lastUse = -math.huge
			player:SetAttribute("MaxStamina", respawnMax)
			player:SetAttribute("Stamina", respawnMax)
		end)
	end
end

function StaminaSystem.Get(player)
	return player:GetAttribute("Stamina") or 0
end

function StaminaSystem.GetMax(player)
	return getMax(player)
end

function StaminaSystem.CanSpend(player, amount)
	return StaminaSystem.Get(player) >= math.max(0, amount or 0)
end

function StaminaSystem.Spend(player, amount)
	amount = math.max(0, amount or 0)
	local current = StaminaSystem.Get(player)
	if current < amount then
		return false
	end

	local state = getState(player)
	state.lastUse = workspace:GetServerTimeNow()
	player:SetAttribute("Stamina", math.max(0, current - amount))
	return true
end

function StaminaSystem.SetDrain(player, source, enabled, rate)
	local state = getState(player)
	if enabled then
		state.drains[source] = math.max(0, rate or 0)
		state.lastUse = workspace:GetServerTimeNow()
	else
		state.drains[source] = nil
	end
end

function StaminaSystem.StopAllDrains(player)
	local state = getState(player)
	state.drains = {}
end

local function hasDrain(state)
	return next(state.drains) ~= nil
end

Players.PlayerAdded:Connect(StaminaSystem.InitPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	StaminaSystem.InitPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

RunService.Heartbeat:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	for player, state in pairs(states) do
		if not player.Parent then
			states[player] = nil
			continue
		end

		local current = StaminaSystem.Get(player)
		local maxStamina = StaminaSystem.GetMax(player)
		local totalDrain = 0
		for source, rate in pairs(state.drains) do
			if source == "Sprint" then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0.05 then
					totalDrain += rate
				end
			else
				totalDrain += rate
			end
		end

		if totalDrain > 0 then
			state.lastUse = now
			local nextValue = math.max(0, current - totalDrain * dt)
			player:SetAttribute("Stamina", nextValue)
			if current > 0 and nextValue <= 0 then
				state.drains = {}
				depletedEvent:Fire(player)
			end
		elseif current < maxStamina and now - state.lastUse >= StaminaSystem.Config.RegenDelay then
			player:SetAttribute("Stamina", math.min(maxStamina, current + StaminaSystem.Config.RegenPerSecond * dt))
		end
	end
end)

return StaminaSystem
