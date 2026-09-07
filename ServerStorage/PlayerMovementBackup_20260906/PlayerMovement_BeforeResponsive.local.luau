local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local remote = ReplicatedStorage:WaitForChild("PlayerMovement")
local player = Players.LocalPlayer
local rigs = {}
local clipIds = {
	Walk = "rbxassetid://92954261547077",
	Run = "rbxassetid://85618915186426",
	Roll = "rbxassetid://137733801815535",
}
local nativeIds = {}
for _, id in pairs(clipIds) do nativeIds[id] = true end
local sprint = false
local function setSprint(value)
	if sprint == value then return end
	sprint = value
	remote:FireServer("Sprint", value)
end
ContextActionService:BindActionAtPriority("MainPlayerSprint", function(_, state)
	if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then setSprint(false)
	elseif state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then setSprint(true) end
	return Enum.ContextActionResult.Sink
end, true, 5000, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("MainPlayerSprint", "Sprint")
ContextActionService:BindActionAtPriority("MainPlayerRoll", function(_, state)
	if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then remote:FireServer("Roll") end
	return Enum.ContextActionResult.Sink
end, true, 5000, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("MainPlayerRoll", "Roll")
UserInputService.WindowFocusReleased:Connect(function() setSprint(false) end)
player.CharacterAdded:Connect(function() sprint = false end)

local function register(character)
	if not character:GetAttribute("FatebornBoneCharacter") then return end
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local mesh = character:WaitForChild("char1", 10)
	if not humanoid or not root or not mesh then return end
	local bones = {}
	for _, bone in ipairs(mesh:GetDescendants()) do
		if bone:IsA("Bone") then
			-- Convert model-space rotation axes to the imported bone's bind orientation.
			local bind = mesh.CFrame:ToObjectSpace(bone.WorldCFrame).Rotation
			bones[bone.Name] = {bone = bone, bind = bind, pose = CFrame.identity}
		end
	end
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then animate.Enabled = false end
	local animator = humanoid:WaitForChild("Animator", 10)
	local rig = {humanoid = humanoid, root = root, bones = bones, phase = 0, animator = animator, tracks = {}}
	rigs[character] = rig
	-- Only the owning client starts tracks; the server-created Animator replicates them.
	if character == player.Character and animator then
		for name, id in pairs(clipIds) do
			local animation = Instance.new("Animation")
			animation.Name = "Meshy" .. name
			animation.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
			animation:Destroy()
			if ok then
				track.Looped = name ~= "Roll"
				track.Priority = name == "Roll" and Enum.AnimationPriority.Action4 or Enum.AnimationPriority.Movement
				rig.tracks[name] = track
			else warn("Meshy animation failed: " .. name .. ": " .. tostring(track)) end
		end
	end
end
local function watch(other)
	other.CharacterAdded:Connect(register)
	if other.Character then task.spawn(register, other.Character) end
end
Players.PlayerAdded:Connect(watch)
for _, other in ipairs(Players:GetPlayers()) do watch(other) end

RunService.PreAnimation:Connect(function()
	local character = player.Character
	local rig = character and rigs[character]
	if not rig then return end
	local v = rig.root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local rollStart = character:GetAttribute("RollStartedAt") or -100
	local rollTime = workspace:GetServerTimeNow() - rollStart
	local desired
	if rig.humanoid.Health > 0 then
		if rollTime >= 0 and rollTime < 0.6 then desired = "Roll"
		elseif rig.humanoid.FloorMaterial ~= Enum.Material.Air and speed > 0.7 then
			desired = character:GetAttribute("Sprinting") and "Run" or "Walk"
		end
	end
	for name, track in pairs(rig.tracks) do
		if name == desired and track.Length > 0 then
			if name == "Roll" then
				if rig.lastRoll ~= rollStart then
					rig.lastRoll = rollStart
					track:Play(0.04, 1, track.Length / 0.6)
					track.TimePosition = math.min(rollTime / 0.6 * track.Length, track.Length - 0.001)
				end
			else
				if not track.IsPlaying then track:Play(0.12) end
				track:AdjustSpeed(math.clamp(speed / (name == "Run" and 23.2 or 16), 0.3, 1.5))
			end
		elseif track.IsPlaying then track:Stop(0.08) end
	end
end)

RunService.PreSimulation:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	for character, rig in pairs(rigs) do
		if not character.Parent then rigs[character] = nil continue end
		local h, root = rig.humanoid, rig.root
		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local moving = speed > 0.7
		local running = character:GetAttribute("Sprinting") == true
		local airborne = h.FloorMaterial == Enum.Material.Air
		local rollTime = now - (character:GetAttribute("RollStartedAt") or -100)
		local rolling = rollTime >= 0 and rollTime < 0.6
		local native = false
		if rig.animator then
			for _, track in ipairs(rig.animator:GetPlayingAnimationTracks()) do
				if track.Animation and nativeIds[track.Animation.AnimationId] and track.WeightCurrent > 0.001 then
					native = true break
				end
			end
		end
		character:SetAttribute("LocalAnimationState", rolling and "Roll" or airborne and (velocity.Y > 0 and "Jump" or "Fall") or moving and (running and "Run" or "Walk") or "Idle")
		character:SetAttribute("LocalAnimationSource", native and "Meshy" or "Procedural")
		if native then
			for _, b in pairs(rig.bones) do b.pose = b.bone.Transform end
			continue
		end
		rig.phase += dt * (running and 13 or 9) * math.clamp(speed / (running and 23.2 or 16), 0.3, 1.5)
		local targets = {}
		local function pose(name, x, y, z, offset)
			local b = rig.bones[name]
			if not b then return end
			local rotation = CFrame.Angles(x or 0, y or 0, z or 0)
			targets[name] = b.bind:Inverse() * CFrame.new(offset or Vector3.zero) * rotation * b.bind
		end
		if h.Health <= 0 then
			pose("Spine02", 0.3)
		elseif rolling then
			local t = rollTime / 0.6
			pose("Hips", -2 * math.pi * t, 0, 0, Vector3.new(0, -0.6 * math.sin(math.pi*t), 0))
			pose("Spine02", -0.55)
			pose("LeftUpLeg", -1.25) pose("RightUpLeg", -1.25)
			pose("LeftLeg", 1.6) pose("RightLeg", 1.6)
			pose("LeftArm", -1.2) pose("RightArm", -1.2)
			pose("LeftForeArm", -1.1) pose("RightForeArm", -1.1)
		elseif airborne then
			local rising = velocity.Y > 0
			pose("LeftUpLeg", rising and -0.55 or -0.15)
			pose("RightUpLeg", rising and 0.15 or 0.2)
			pose("LeftLeg", 0.6) pose("RightLeg", 0.45)
			pose("LeftArm", -0.5, 0, -0.25) pose("RightArm", -0.5, 0, 0.25)
			pose("Spine02", -0.12)
		elseif moving then
			local wave = math.sin(rig.phase)
			local stride = running and 0.85 or 0.5
			pose("LeftUpLeg", wave*stride) pose("RightUpLeg", -wave*stride)
			pose("LeftLeg", math.max(0,-wave)*(running and 1.15 or 0.65))
			pose("RightLeg", math.max(0,wave)*(running and 1.15 or 0.65))
			pose("LeftArm", -wave*stride*0.8) pose("RightArm", wave*stride*0.8)
			pose("LeftForeArm", running and -0.9 or -0.25) pose("RightForeArm", running and -0.9 or -0.25)
			pose("Spine02", running and -0.18 or -0.04, wave*0.06)
			pose("Hips", 0, 0, wave*0.035, Vector3.new(0,math.cos(rig.phase*2)*0.055,0))
		else
			pose("Spine02", math.sin(now*2)*0.018)
			pose("LeftArm", 0, 0, -0.04) pose("RightArm", 0, 0, 0.04)
		end
		character:SetAttribute("LocalAnimationState", rolling and "Roll" or airborne and (velocity.Y > 0 and "Jump" or "Fall") or moving and (running and "Run" or "Walk") or "Idle")
		for name,b in pairs(rig.bones) do
			local target = targets[name] or CFrame.identity
			b.pose = rolling and target or b.pose:Lerp(target, 1-math.exp(-dt*16))
			b.bone.Transform = b.pose
		end
	end
end)

