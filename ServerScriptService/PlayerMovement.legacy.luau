local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local StaminaSystem = require(ServerStorage:WaitForChild("ZeroScript"):WaitForChild("StaminaSystem"))
local HitReactionSystem = require(ServerStorage:WaitForChild("ZeroScript"):WaitForChild("HitReactionSystem"))
local vfxFolder = ReplicatedStorage:FindFirstChild("VFX")
if not vfxFolder then
	vfxFolder = Instance.new("Folder")
	vfxFolder.Name = "VFX"
	vfxFolder.Parent = ReplicatedStorage
end
local vfxRemote = vfxFolder:FindFirstChild("VFXEvent")
if not vfxRemote then
	vfxRemote = Instance.new("RemoteEvent")
	vfxRemote.Name = "VFXEvent"
	vfxRemote.Parent = vfxFolder
end
local remote = Instance.new("RemoteEvent")
remote.Name = "PlayerMovement"
remote.Parent = ReplicatedStorage
local lastRoll = {}

remote.OnServerEvent:Connect(function(player, action, value)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end
	local reactionLocked = HitReactionSystem.IsLocked(character)
	if action == "Sprint" and typeof(value) == "boolean" then
		local base = character:GetAttribute("BaseWalkSpeed") or 14
		if reactionLocked then
			character:SetAttribute("Sprinting", false)
			humanoid.WalkSpeed = 0
			StaminaSystem.SetDrain(player, "Sprint", false, StaminaSystem.Config.SprintDrainPerSecond)
			return
		end
		local wantsSprint = value == true
		if wantsSprint and StaminaSystem.Get(player) <= 0 then
			wantsSprint = false
		end
		character:SetAttribute("Sprinting", wantsSprint)
		humanoid.WalkSpeed = base * (wantsSprint and 1.45 or 1)
		StaminaSystem.SetDrain(player, "Sprint", wantsSprint, StaminaSystem.Config.SprintDrainPerSecond)
	elseif action == "Roll" then
		if reactionLocked then return end
		local now = workspace:GetServerTimeNow()
		if now - (lastRoll[player] or -100) < 2.2 or humanoid.FloorMaterial == Enum.Material.Air then return end
		local direction = humanoid.MoveDirection
		if direction.Magnitude < 0.1 then direction = root.CFrame.LookVector end
		direction = Vector3.new(direction.X, 0, direction.Z)
		if direction.Magnitude < 0.1 then return end
		if not StaminaSystem.Spend(player, StaminaSystem.Config.RollCost) then return end
		lastRoll[player] = now
		character:SetAttribute("RollStartedAt", now)
		vfxRemote:FireAllClients("Dash", root.Position, nil, {
			SourceUserId = player.UserId,
			Direction = direction.Unit,
		})
		local attachment = Instance.new("Attachment")
		attachment.Parent = root
		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		velocity.PrimaryTangentAxis = Vector3.xAxis
		velocity.SecondaryTangentAxis = Vector3.zAxis
		velocity.PlaneVelocity = Vector2.new(direction.Unit.X, direction.Unit.Z) * 30
		velocity.MaxForce = 50000
		velocity.Parent = root
		Debris:AddItem(velocity, 0.6)
		Debris:AddItem(attachment, 0.6)
	end
end)
StaminaSystem.Depleted:Connect(function(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then return end
	if character:GetAttribute("Sprinting") then
		character:SetAttribute("Sprinting", false)
		local base = character:GetAttribute("BaseWalkSpeed") or 14
		humanoid.WalkSpeed = HitReactionSystem.IsLocked(character) and 0 or base
	end
end)

Players.PlayerRemoving:Connect(function(player) lastRoll[player] = nil end)
