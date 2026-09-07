local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local actionRemote = ReplicatedStorage:WaitForChild("FatebornRemotes", 5):WaitForChild("Action", 5)

local lastRollTime = 0
local ROLL_COOLDOWN = 0.85
local animationFolder = ReplicatedStorage:WaitForChild("R15Anims")
local rollAnimation = animationFolder:WaitForChild("Roll")
local rollTrack
local rollCharacter
local shiftHeld = false

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
	local character = player.Character
	if character then
		character:SetAttribute("Sprinting", enabled)
	end
	if actionRemote then
		actionRemote:FireServer("Sprint", enabled, movementDirection())
	end
end

local function triggerDash()
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
	if actionRemote then
		actionRemote:FireServer("Dash", 0, movementDirection())
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
	character:SetAttribute("Sprinting", false)
	local animate = character:WaitForChild("Animate", 5)
	if animate then
		local walk = animate:FindFirstChild("walk") and animate.walk:FindFirstChild("WalkAnim")
		local run = animate:FindFirstChild("run") and animate.run:FindFirstChild("RunAnim")
		if walk then walk.AnimationId = animationFolder.Walk.AnimationId end
		if run then run.AnimationId = animationFolder.Run.AnimationId end
	end
	character:SetAttribute("Dashing", false)
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
