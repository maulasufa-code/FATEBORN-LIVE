local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local LOCK_RANGE = 110
local BREAK_RANGE = 135
local CAMERA_TURN_SPEED = 10
local CHARACTER_TURN_SPEED = 18
local CAMERA_HEIGHT_OFFSET = 1.8
local MOUSE_SWITCH_THRESHOLD = 48
local SWITCH_COOLDOWN = 0.22
local REACQUIRE_DELAY = 0.12

local lockedTarget = nil
local highlight = nil
local billboard = nil
local lockHeld = false
local mouseSwitchAccumulator = 0
local lastSwitchAt = 0
local lastAcquireAttempt = 0

local targetValue = player:FindFirstChild("TargetLockTarget")
if not targetValue then
	targetValue = Instance.new("ObjectValue")
	targetValue.Name = "TargetLockTarget"
	targetValue.Parent = player
end

local function getLocalParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function getTargetParts(model)
	if not model or not model.Parent or model:GetAttribute("Enemy") ~= true then
		return nil, nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil
	end
	return humanoid, root
end

local function clearIndicator()
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	if billboard then
		billboard:Destroy()
		billboard = nil
	end
end

local function clearLock()
	local character = player.Character
	if character then
		character:SetAttribute("CombatFacingLock", false)
	end
	lockedTarget = nil
	targetValue.Value = nil
	clearIndicator()
end

local function visibleFromCamera(model, targetRoot)
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and {character} or {}
	params.IgnoreWater = true
	local origin = camera.CFrame.Position
	local result = Workspace:Raycast(origin, targetRoot.Position - origin, params)
	return not result or result.Instance:IsDescendantOf(model)
end

local function isValidTarget(model, maxRange, requireOnScreen)
	local _, targetRoot = getTargetParts(model)
	local _, localHumanoid, localRoot = getLocalParts()
	local camera = Workspace.CurrentCamera
	if not targetRoot or not localRoot or not localHumanoid or localHumanoid.Health <= 0 or not camera then
		return false
	end
	if (targetRoot.Position - localRoot.Position).Magnitude > maxRange then
		return false
	end
	local point, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
	if requireOnScreen and (not onScreen or point.Z <= 0) then
		return false
	end
	return visibleFromCamera(model, targetRoot)
end

local function allCandidates()
	local list = {}
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("Model") and item:GetAttribute("Enemy") == true and isValidTarget(item, LOCK_RANGE, true) then
			table.insert(list, item)
		end
	end
	return list
end

local function scoreTarget(model)
	local camera = Workspace.CurrentCamera
	local _, targetRoot = getTargetParts(model)
	local _, _, localRoot = getLocalParts()
	if not camera or not targetRoot or not localRoot then
		return math.huge
	end
	local toTarget = targetRoot.Position - camera.CFrame.Position
	local direction = toTarget.Magnitude > 0 and toTarget.Unit or camera.CFrame.LookVector
	local anglePenalty = 1 - math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)
	local distancePenalty = (targetRoot.Position - localRoot.Position).Magnitude / LOCK_RANGE
	local screenPoint = camera:WorldToViewportPoint(targetRoot.Position)
	local center = camera.ViewportSize * 0.5
	local screenPenalty = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude / math.max(1, camera.ViewportSize.X)
	return anglePenalty * 4 + screenPenalty * 2 + distancePenalty
end

local function createIndicator(model)
	clearIndicator()
	local _, root = getTargetParts(model)
	if not root then
		return
	end

	highlight = Instance.new("Highlight")
	highlight.Name = "TargetLockHighlight"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.86
	highlight.OutlineTransparency = 0.08
	highlight.FillColor = Color3.fromRGB(190, 42, 60)
	highlight.OutlineColor = Color3.fromRGB(255, 225, 190)
	highlight.Parent = model

	billboard = Instance.new("BillboardGui")
	billboard.Name = "TargetLockBillboard"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(92, 24)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = BREAK_RANGE + 15
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "◆ LOCK ◆"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(255, 225, 190)
	label.TextStrokeColor3 = Color3.fromRGB(30, 12, 18)
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard
end

local function setLock(model)
	if not isValidTarget(model, LOCK_RANGE, false) then
		clearLock()
		return
	end
	lockedTarget = model
	targetValue.Value = model
	local character = player.Character
	if character then
		character:SetAttribute("CombatFacingLock", true)
	end
	createIndicator(model)
end

local function lockBestTarget()
	local candidates = allCandidates()
	local best, bestScore
	for _, model in ipairs(candidates) do
		local score = scoreTarget(model)
		if not bestScore or score < bestScore then
			best = model
			bestScore = score
		end
	end
	if best then
		setLock(best)
	end
end

local function switchTarget(direction)
	if not lockedTarget then
		lockBestTarget()
		return
	end
	local camera = Workspace.CurrentCamera
	local _, currentRoot = getTargetParts(lockedTarget)
	if not camera or not currentRoot then
		lockBestTarget()
		return
	end
	local currentPoint = camera:WorldToViewportPoint(currentRoot.Position)
	local best, bestScore
	for _, model in ipairs(allCandidates()) do
		if model ~= lockedTarget then
			local _, root = getTargetParts(model)
			if root then
				local point = camera:WorldToViewportPoint(root.Position)
				local dx = point.X - currentPoint.X
				if (direction < 0 and dx < -8) or (direction > 0 and dx > 8) then
					local score = math.abs(dx) + math.abs(point.Y - currentPoint.Y) * 0.35
					if not bestScore or score < bestScore then
						best = model
						bestScore = score
					end
				end
			end
		end
	end
	if best then
		setLock(best)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end

	lockHeld = true
	mouseSwitchAccumulator = 0
	lastAcquireAttempt = os.clock()
	lockBestTarget()
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end

	lockHeld = false
	mouseSwitchAccumulator = 0
	clearLock()
end)

UserInputService.InputChanged:Connect(function(input)
	if not lockHeld or not lockedTarget then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local deltaX = input.Delta.X
	if math.abs(deltaX) < 0.5 then
		return
	end

	if mouseSwitchAccumulator ~= 0 and math.sign(deltaX) ~= math.sign(mouseSwitchAccumulator) then
		mouseSwitchAccumulator = 0
	end
	mouseSwitchAccumulator += deltaX

	local now = os.clock()
	if now - lastSwitchAt < SWITCH_COOLDOWN then
		return
	end

	if mouseSwitchAccumulator <= -MOUSE_SWITCH_THRESHOLD then
		lastSwitchAt = now
		mouseSwitchAccumulator = 0
		switchTarget(-1)
	elseif mouseSwitchAccumulator >= MOUSE_SWITCH_THRESHOLD then
		lastSwitchAt = now
		mouseSwitchAccumulator = 0
		switchTarget(1)
	end
end)

RunService:BindToRenderStep("FatebornTargetLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not lockHeld then
		return
	end

	if not lockedTarget then
		local now = os.clock()
		if now - lastAcquireAttempt >= REACQUIRE_DELAY then
			lastAcquireAttempt = now
			lockBestTarget()
		end
		return
	end

	local targetHumanoid, targetRoot = getTargetParts(lockedTarget)
	local character, localHumanoid, localRoot = getLocalParts()
	local camera = Workspace.CurrentCamera
	if not targetHumanoid or not targetRoot or not character or not localHumanoid or not localRoot or not camera then
		clearLock()
		lastAcquireAttempt = 0
		return
	end
	if localHumanoid.Health <= 0 or (targetRoot.Position - localRoot.Position).Magnitude > BREAK_RANGE then
		clearLock()
		lastAcquireAttempt = 0
		return
	end

	character:SetAttribute("CombatFacingLock", true)

	local flat = Vector3.new(targetRoot.Position.X - localRoot.Position.X, 0, targetRoot.Position.Z - localRoot.Position.Z)
	if flat.Magnitude > 0.05 then
		local targetFacing = CFrame.lookAt(localRoot.Position, localRoot.Position + flat.Unit)
		local alpha = 1 - math.exp(-CHARACTER_TURN_SPEED * dt)
		localRoot.CFrame = localRoot.CFrame:Lerp(targetFacing, alpha)
		localRoot.AssemblyAngularVelocity = Vector3.zero
	end

	local focus = targetRoot.Position + Vector3.new(0, CAMERA_HEIGHT_OFFSET, 0)
	local desiredCamera = CFrame.lookAt(camera.CFrame.Position, focus)
	local cameraAlpha = 1 - math.exp(-CAMERA_TURN_SPEED * dt)
	camera.CFrame = camera.CFrame:Lerp(desiredCamera, cameraAlpha)
end)

player.CharacterAdded:Connect(function(character)
	lockHeld = false
	mouseSwitchAccumulator = 0
	clearLock()
	character:SetAttribute("CombatFacingLock", false)
end)

player.CharacterRemoving:Connect(function()
	lockHeld = false
	mouseSwitchAccumulator = 0
	clearLock()
end)
