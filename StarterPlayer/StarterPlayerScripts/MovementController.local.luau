local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local actionRemote = ReplicatedStorage:WaitForChild("FatebornRemotes", 5):WaitForChild("Action", 5)
local vfxLocal = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("VFXLocal")

local lastRollTime = 0
local ROLL_COOLDOWN = 0.85
local animationFolder = ReplicatedStorage:WaitForChild("R15Anims")
local rollAnimation = animationFolder:WaitForChild("Roll")
local rollTrack
local rollCharacter
local shiftHeld = false
local landingConnection

local function usesHalfBeastController()
	local character = player.Character
	return character and character:GetAttribute("FatebornBoneCharacter") == true
end

local function getCharacterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function movementDirection()
	local _, humanoid = getCharacterParts()
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		return humanoid.MoveDirection.Unit
	end

	local camera = Workspace.CurrentCamera
	if camera then
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.1 then
			return flat.Unit
		end
	end

	return Vector3.new(0, 0, -1)
end

local function setSprint(enabled)
	if usesHalfBeastController() then
		return
	end
	local character = player.Character
	if character then
		character:SetAttribute("Sprinting", enabled)
	end
	if actionRemote then
		actionRemote:FireServer("Sprint", enabled, movementDirection())
	end
end

local function triggerDash()
	if usesHalfBeastController() then
		return
	end
	local character, humanoid = getCharacterParts()
	if character and humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		if not rollTrack or rollCharacter ~= character then
			local ok, track = pcall(function() return animator:LoadAnimation(rollAnimation) end)
			if ok then
				rollTrack = track
				rollCharacter = character
				rollTrack.Priority = Enum.AnimationPriority.Action
				rollTrack.Looped = false
			end
		end
		if rollTrack then
			rollTrack:Stop(0)
			rollTrack:Play(0.08, 1, 1.05)
		end
		character:SetAttribute("Dashing", true)
		task.delay(0.22, function()
			if character and character.Parent then
				character:SetAttribute("Dashing", false)
			end
		end)
	end
	local direction = movementDirection()
	if actionRemote then
		actionRemote:FireServer("Dash", "Roll", direction)
	end
end

local function isCtrl(input)
	return input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl
end

local function isShift(input)
	return input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift
end

local function onShiftBegan(input)
	if not isShift(input) or shiftHeld then
		return
	end
	shiftHeld = true
	setSprint(true)
end

local function onShiftEnded(input)
	if not isShift(input) then
		return
	end
	shiftHeld = false
	setSprint(false)
end

local function onCtrlBegan(input)
	if not isCtrl(input) then
		return
	end
	local now = os.clock()
	if now - lastRollTime < ROLL_COOLDOWN then
		return
	end
	lastRollTime = now
	triggerDash()
end

local function onCharacterAdded(character)
	if landingConnection then
		landingConnection:Disconnect()
		landingConnection = nil
	end
	character:SetAttribute("Sprinting", false)
	local animate = character:WaitForChild("Animate", 5)
	if animate then
		local walk = animate:FindFirstChild("walk") and animate.walk:FindFirstChild("WalkAnim")
		local run = animate:FindFirstChild("run") and animate.run:FindFirstChild("RunAnim")
		if walk then walk.AnimationId = animationFolder.Walk.AnimationId end
		if run then run.AnimationId = animationFolder.Run.AnimationId end
	end
	character:SetAttribute("Dashing", false)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local fallStartY
	if humanoid and root then
		landingConnection = humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Freefall then
				fallStartY = root.Position.Y
			elseif newState == Enum.HumanoidStateType.Landed and fallStartY then
				local drop = fallStartY - root.Position.Y
				fallStartY = nil
				if drop >= 5 then
					local hit = Workspace:Raycast(root.Position, Vector3.new(0, -10, 0), RaycastParams.new())
					local groundPosition = hit and hit.Position or (root.Position - Vector3.new(0, 2.4, 0))
					local kind = drop >= 16 and "HeavyLanding" or "Landing"
					vfxLocal:Fire(kind, groundPosition, nil, { Direction = humanoid.MoveDirection })
				end
			end
		end)
	end
	shiftHeld = false
	rollTrack = nil
	rollCharacter = nil
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

UserInputService.InputBegan:Connect(function(input)
	onShiftBegan(input)
	onCtrlBegan(input)
end)

ContextActionService:BindActionAtPriority("FatebornRoll", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		local now = os.clock()
		if now - lastRollTime >= ROLL_COOLDOWN then
			lastRollTime = now
			triggerDash()
		end
	end
	return Enum.ContextActionResult.Sink
end, false, 3000, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)

UserInputService.InputEnded:Connect(function(input)
	onShiftEnded(input)
end)
