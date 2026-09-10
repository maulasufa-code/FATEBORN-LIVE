local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local remote = ReplicatedStorage:WaitForChild("PlayerMovement")
local player = Players.LocalPlayer
local RaceCharacterModels = require(
	ReplicatedStorage:WaitForChild("ZeroScript"):WaitForChild("Data"):WaitForChild("RaceCharacterModels")
)

local rigs = {}

-- Existing FATEBORN bone characters use these published Meshy clips. A race
-- profile replaces this set only when it explicitly supplies its own clips.
local defaultBoneAnimations = {
	Walk = { Id = "rbxassetid://92954261547077" },
	Run = { Id = "rbxassetid://85618915186426" },
	Roll = { Id = "rbxassetid://137733801815535" },
}

local sprint = false

local animationSettings = {
	Idle = { Priority = Enum.AnimationPriority.Idle, Looped = true },
	Walk = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	Run = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	Jump = { Priority = Enum.AnimationPriority.Movement, Looped = false },
	RunningJump = { Priority = Enum.AnimationPriority.Movement, Looped = false },
	Fall = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	Climb = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	Swim = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	SwimIdle = { Priority = Enum.AnimationPriority.Movement, Looped = true },
	Block = { Priority = Enum.AnimationPriority.Action, Looped = true },
	Guard = { Priority = Enum.AnimationPriority.Action, Looped = true },
	BasicAttack = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_1 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_2 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_3 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_4 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_5 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	M1_6 = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	Roll = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	Backstep = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	SpellCast = { Priority = Enum.AnimationPriority.Action2, Looped = false },
	SlidingStumble = { Priority = Enum.AnimationPriority.Action3, Looped = false },
	IdleStumble = { Priority = Enum.AnimationPriority.Action3, Looped = false },
	Drink = { Priority = Enum.AnimationPriority.Action, Looped = false },
	Death = { Priority = Enum.AnimationPriority.Action4, Looped = false },
}

local function stopTrack(track, fadeTime)
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.08)
	end
end

local function playState(rig, name, fadeTime, restart)
	local track = rig.tracks[name]
	if not track then
		return false
	end

	if restart and track.IsPlaying then
		track:Stop(0)
	end
	if restart then
		track.TimePosition = 0
	end

	for otherName, otherTrack in pairs(rig.tracks) do
		if otherName ~= name then
			stopTrack(otherTrack, fadeTime)
		end
	end

	if not track.IsPlaying or restart then
		track:Play(fadeTime or 0.1)
	end

	rig.currentState = name
	return true
end

local function playAction(rig, name, duration, fadeTime)
	if playState(rig, name, fadeTime or 0.04, true) then
		rig.actionName = name
		rig.actionUntil = duration == math.huge
			and math.huge
			or workspace:GetServerTimeNow() + duration
	end
end

local function setBoneRotation(rig, name, x, y, z)
	local boneData = rig.bones[name]
	if not boneData then
		return
	end

	boneData.bone.Transform = boneData.bind:Inverse()
		* CFrame.Angles(x or 0, y or 0, z or 0)
		* boneData.bind
end

local function isReactionLocked()
	local character = player.Character
	if not character then
		return false
	end
	return workspace:GetServerTimeNow() < (character:GetAttribute("HitReactionUntil") or -math.huge)
end

-- Semakin kecil = putaran lebih lembut/lambat
-- Semakin besar = semakin responsif
local TURN_SPEED = 12


--==================================================
-- SPRINT
--==================================================

local function setSprint(value)
	if sprint == value then
		return
	end

	sprint = value
	remote:FireServer("Sprint", value)
end

ContextActionService:BindActionAtPriority(
	"MainPlayerSprint",

	function(_, state)
		if state == Enum.UserInputState.End
			or state == Enum.UserInputState.Cancel then

			setSprint(false)

		elseif state == Enum.UserInputState.Begin
			and not UserInputService:GetFocusedTextBox() then

			if isReactionLocked() then
				setSprint(false)
			else
				setSprint(true)
			end
		end

		return Enum.ContextActionResult.Sink
	end,

	true,
	5000,

	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
	Enum.KeyCode.ButtonL3
)

ContextActionService:SetTitle(
	"MainPlayerSprint",
	"Sprint"
)


--==================================================
-- ROLL
--==================================================

ContextActionService:BindActionAtPriority(
	"MainPlayerRoll",

	function(_, state)
		if state == Enum.UserInputState.Begin
			and not UserInputService:GetFocusedTextBox()
			and not isReactionLocked() then

			remote:FireServer("Roll")
		end

		return Enum.ContextActionResult.Sink
	end,

	true,
	5000,

	Enum.KeyCode.LeftControl,
	Enum.KeyCode.RightControl,
	Enum.KeyCode.ButtonB
)

ContextActionService:SetTitle(
	"MainPlayerRoll",
	"Roll"
)


--==================================================
-- RESET INPUT
--==================================================

UserInputService.WindowFocusReleased:Connect(function()
	setSprint(false)
end)

--==================================================
-- JUMP
--==================================================
-- Jump input is owned here for Half-Beast so idle, walk, and sprint all use
-- exactly the same physical takeoff path. Sprint only selects the visual clip.
local JUMP_INPUT_DEBOUNCE = 0.10
local JUMP_VISUAL_HOLD = 0.24

local function canStartJump(humanoid)
	if humanoid.Health <= 0 or humanoid.Sit or humanoid.PlatformStand then
		return false
	end

	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing then
		return false
	end

	return humanoid.FloorMaterial ~= Enum.Material.Air
		or state == Enum.HumanoidStateType.Running
		or state == Enum.HumanoidStateType.RunningNoPhysics
		or state == Enum.HumanoidStateType.Landed
end

local function commandHalfBeastJump()
	local character = player.Character
	local rig = character and rigs[character]
	if not character or not rig then
		return
	end

	local humanoid = rig.humanoid
	local root = rig.root
	local serverNow = workspace:GetServerTimeNow()
	local rollDuration = rig.tuning.RollGameplayDuration or 0.6

	if not canStartJump(humanoid)
		or serverNow < (character:GetAttribute("HitReactionUntil") or -math.huge)
		or serverNow - (character:GetAttribute("RollStartedAt") or -100) < rollDuration then
		return
	end

	local inputNow = os.clock()
	if inputNow - (rig.lastJumpInputAt or -math.huge) < JUMP_INPUT_DEBOUNCE then
		return
	end
	rig.lastJumpInputAt = inputNow

	local sprintingAtTakeoff = sprint or character:GetAttribute("Sprinting") == true
	rig.jumpAnimationName = sprintingAtTakeoff and "RunningJump" or "Jump"
	rig.jumpStartedAt = serverNow
	rig.jumpCommandedAt = serverNow

	-- Same takeoff for idle/walk/sprint. This explicitly starts the Humanoid jump
	-- and preserves the existing horizontal velocity.
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local jumpVelocity
	if humanoid.UseJumpPower then
		jumpVelocity = humanoid.JumpPower
	else
		jumpVelocity = math.sqrt(math.max(0, 2 * workspace.Gravity * humanoid.JumpHeight))
	end

	local velocity = root.AssemblyLinearVelocity
	if velocity.Y < jumpVelocity then
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpVelocity, velocity.Z)
	end

	playState(rig, rig.jumpAnimationName, 0.03, true)
end

-- Explicit Space/ButtonA binding removes any dependency on Shift/Ctrl or on a
-- default player-script jump binding. We own this input and sink only Jump.
ContextActionService:BindActionAtPriority(
	"MainPlayerJump",
	function(_, state)
		local character = player.Character
		if not character or not rigs[character] then
			return Enum.ContextActionResult.Pass
		end

		if state == Enum.UserInputState.Begin
			and not UserInputService:GetFocusedTextBox() then
			commandHalfBeastJump()
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	5001,
	Enum.KeyCode.Space,
	Enum.KeyCode.ButtonA
)

-- Mobile/default jump-button path. Keyboard duplicates are swallowed by debounce.
UserInputService.JumpRequest:Connect(commandHalfBeastJump)

player.CharacterAdded:Connect(function()
	sprint = false
end)

--==================================================
-- REGISTER CHARACTER
--==================================================

local function register(character)

	if not character:GetAttribute("FatebornBoneCharacter") then
		return
	end
	if rigs[character] then
		return
	end

	local raceName = character:GetAttribute("RaceCharacterProfile")
	local characterProfile = RaceCharacterModels.getProfile(raceName)
	local animationProfile = characterProfile and characterProfile.Animations or defaultBoneAnimations

	local humanoid = character:WaitForChild(
		"Humanoid",
		10
	)

	local root = character:WaitForChild(
		"HumanoidRootPart",
		10
	)

	local mesh = character:WaitForChild(
		"char1",
		10
	)

	if not humanoid
		or not root
		or not mesh then

		return
	end


	--==============================================
	-- BONES
	--==============================================

	local bones = {}

	for _, bone in ipairs(character:GetDescendants()) do

		if bone:IsA("Bone") then

			-- Convert model-space rotation axes
			-- ke bind orientation bone bawaan model.

			local bind = mesh.CFrame
				:ToObjectSpace(bone.WorldCFrame)
				.Rotation

			bones[bone.Name] = {
				bone = bone,
				bind = bind,
				pose = CFrame.identity
			}
		end
	end


	-- Disable Animate Roblox bawaan
	local animate = character:FindFirstChild("Animate")

	if animate
		and animate:IsA("LocalScript") then

		animate.Enabled = false
	end


	--==============================================
	-- ANIMATOR
	--==============================================

	local animator = humanoid:WaitForChild(
		"Animator",
		10
	)
	local visualRoot = character:FindFirstChild("RaceVisualRoot")
	local visualMotor = visualRoot and visualRoot:FindFirstChild("RaceVisualRootWeld")
	local visualRollPivot = visualRoot and visualRoot.CFrame:PointToObjectSpace(mesh.Position) or Vector3.zero

	local rig = {
		humanoid = humanoid,
		root = root,
		bones = bones,
		phase = 0,
		animator = animator,
		tracks = {},
		nativeIds = {},
		connections = {},
		actionUntil = -math.huge,
		tuning = characterProfile and characterProfile.AnimationTuning or {},
		visualMotor = visualMotor and visualMotor:IsA("Motor6D") and visualMotor or nil,
		visualRollPivot = visualRollPivot,
	}

	rigs[character] = rig


	--==============================================
	-- LOCAL PLAYER
	--==============================================

	if character == player.Character then
		-- Race characters are assigned manually by the server. Reassert the
		-- normal Roblox camera subject after the old character is removed.
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraSubject = humanoid
		end

		-- Kita atur rotasi sendiri supaya
		-- perubahan WASD bisa di-blend.
		humanoid.AutoRotate = false

		if animator then

			for name, animationData in pairs(animationProfile) do
				if animationData.Unclassified then
					continue
				end

				local id = animationData.Id
				rig.nativeIds[id] = true

				local animation = Instance.new("Animation")

				animation.Name = "Meshy" .. name
				animation.AnimationId = id

				local ok, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)

				animation:Destroy()

				if ok then
					local settings = animationSettings[name]
					track.Looped = settings and settings.Looped or false
					track.Priority = settings and settings.Priority or Enum.AnimationPriority.Movement

					rig.tracks[name] = track

				else

					warn(
						"Meshy animation failed: "
							.. name
							.. ": "
							.. tostring(track)
					)

				end
			end
		end

		local function actionLength(name, fallback)
			local track = rig.tracks[name]
			return math.max(fallback, track and track.Length or 0)
		end

		local function actionDuration(name, fallback, startOffset, playbackSpeed)
			local track = rig.tracks[name]
			local length = track and track.Length or 0
			if length <= 0 then
				return fallback
			end
			return math.max(fallback, math.max(0, length - (startOffset or 0)) / (playbackSpeed or 1))
		end

		local function onBasicAttack()
			local startedAt = character:GetAttribute("BasicAttackStartedAt")
			if type(startedAt) == "number" and startedAt > (rig.lastBasicAttackAt or -math.huge) then
				rig.lastBasicAttackAt = startedAt
				local comboIndex = character:GetAttribute("BasicAttackComboIndex")
				local comboSlots = animationProfile.BasicAttack and animationProfile.BasicAttack.ComboSlots
				local animationName = type(comboIndex) == "number" and comboSlots and comboSlots[comboIndex]
				local selectedName = animationName or "BasicAttack"
				local startOffset = rig.tuning.BasicAttackStartOffset or 0
				local playbackSpeed = rig.tuning.BasicAttackPlaybackSpeed or 1
				playAction(
					rig,
					selectedName,
					actionDuration(selectedName, 0.38, startOffset, playbackSpeed),
					rig.tuning.BasicAttackFadeIn or 0.04
				)
				local track = rig.tracks[selectedName]
				local function tuneTrack()
					if track and track.IsPlaying and rig.lastBasicAttackAt == startedAt and track.Length > 0 then
						track.TimePosition = math.min(startOffset, math.max(0, track.Length - 0.001))
						track:AdjustSpeed(playbackSpeed)
					end
				end
				tuneTrack()
				if track and track.Length <= 0 then
					table.insert(rig.connections, track:GetPropertyChangedSignal("Length"):Once(tuneTrack))
				end
			end
		end

		local function onSkillCast()
			local startedAt = character:GetAttribute("SkillCastStartedAt")
			if type(startedAt) == "number" and startedAt > (rig.lastSkillCastAt or -math.huge) then
				rig.lastSkillCastAt = startedAt
				playAction(rig, "SpellCast", actionLength("SpellCast", 0.45), 0.05)
			end
		end

		table.insert(rig.connections, character:GetAttributeChangedSignal("BasicAttackStartedAt"):Connect(onBasicAttack))
		table.insert(rig.connections, character:GetAttributeChangedSignal("SkillCastStartedAt"):Connect(onSkillCast))
		table.insert(rig.connections, humanoid.StateChanged:Connect(function(_, newState)
			if rig.dead then
				return
			end

			if newState == Enum.HumanoidStateType.Jumping then
			local stateNow = workspace:GetServerTimeNow()
			-- commandHalfBeastJump already chose the variant and started the clip.
			-- Only select here when another system caused the jump.
			if stateNow - (rig.jumpCommandedAt or -math.huge) > 0.12 then
				local sprintingAtJumpStart = sprint
					or character:GetAttribute("Sprinting") == true
				rig.jumpAnimationName = sprintingAtJumpStart and "RunningJump" or "Jump"
				rig.jumpStartedAt = stateNow
				playState(rig, rig.jumpAnimationName, 0.04, true)
			end
		elseif newState == Enum.HumanoidStateType.Landed then
				-- The next grounded PreAnimation pass will select Idle/Walk/Run.
				-- Clear only the takeoff timestamp so an old jump cannot hold the
				-- short Freefall startup window on a later state transition.
				rig.jumpStartedAt = nil
			end
		end))
		table.insert(rig.connections, humanoid.Died:Connect(function()
			rig.dead = true
			playAction(rig, "Death", math.huge, 0.02)
		end))
		table.insert(rig.connections, character.AncestryChanged:Connect(function(_, parent)
			if parent then
				return
			end
			for _, connection in ipairs(rig.connections) do
				connection:Disconnect()
			end
			rig.connections = {}
			rigs[character] = nil
		end))

		onBasicAttack()
		onSkillCast()
	end
end


--==================================================
-- WATCH PLAYERS
--==================================================

local function watch(other)

	other.CharacterAdded:Connect(register)

	if other.Character then
		task.spawn(
			register,
			other.Character
		)
	end
end

Players.PlayerAdded:Connect(watch)

for _, other in ipairs(Players:GetPlayers()) do
	watch(other)
end


--==================================================
-- NATIVE ANIMATION
--==================================================

RunService.PreAnimation:Connect(function()
	local character = player.Character
	local rig = character and rigs[character]
	if not rig then
		return
	end

	local serverNow = workspace:GetServerTimeNow()
	local humanoid = rig.humanoid
	local velocity = rig.root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local rollStart = character:GetAttribute("RollStartedAt") or -100
	local rollTime = serverNow - rollStart
	local rollDuration = rig.tuning.RollGameplayDuration or 0.6
	local reactionActive = serverNow < (character:GetAttribute("HitReactionUntil") or -math.huge)
	local desired

	if rig.dead or humanoid.Health <= 0 then
		if not rig.dead then
			rig.dead = true
			playAction(rig, "Death", math.huge, 0.02)
		end
		return
	end

	if reactionActive then
		local reactionStartedAt = character:GetAttribute("HitReactionStartedAt") or -math.huge
		desired = speed > 1.5 and "SlidingStumble" or "IdleStumble"
		if rig.reactionStartedAt ~= reactionStartedAt or rig.currentState ~= desired then
			rig.reactionStartedAt = reactionStartedAt
			playAction(rig, desired, math.max(0, (character:GetAttribute("HitReactionUntil") or serverNow) - serverNow), 0.03)
		end
		return
	elseif rollTime >= 0 and rollTime < rollDuration then
		desired = "Roll"
		if rig.lastRoll ~= rollStart then
			rig.lastRoll = rollStart
			local remainingDuration = math.max(0.01, rollDuration - rollTime)
			playAction(rig, desired, remainingDuration, rig.tuning.RollFadeIn or 0.04)
			local track = rig.tracks.Roll
			local function tuneTrack()
				if track and track.IsPlaying and rig.lastRoll == rollStart then
					local playbackSpeed = rig.tuning.RollPlaybackMultiplier or 1
					if track.Length > 0 then
						playbackSpeed *= track.Length / remainingDuration
					end
					track:AdjustSpeed(playbackSpeed)
				end
			end
			tuneTrack()
			if track and track.Length <= 0 then
				table.insert(rig.connections, track:GetPropertyChangedSignal("Length"):Once(tuneTrack))
			end
		end
	elseif rig.actionName and serverNow < rig.actionUntil then
		desired = rig.actionName
	elseif character:GetAttribute("Blocking") == true then
		desired = "Block"
	else
		rig.actionName = nil
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Swimming then
			desired = speed > 0.7 and "Swim" or "SwimIdle"
		elseif state == Enum.HumanoidStateType.Climbing then
			desired = "Climb"
		elseif state == Enum.HumanoidStateType.Jumping
			or (serverNow - (rig.jumpStartedAt or -math.huge) < JUMP_VISUAL_HOLD
				and rig.root.AssemblyLinearVelocity.Y > -1) then
			desired = rig.jumpAnimationName or "Jump"
		elseif state == Enum.HumanoidStateType.Freefall or humanoid.FloorMaterial == Enum.Material.Air then
			desired = "Fall"
		elseif speed > 0.7 then
			desired = character:GetAttribute("Sprinting") and "Run" or "Walk"
		else
			desired = "Idle"
		end
	end

	if desired and desired ~= rig.currentState then
		playState(rig, desired, desired == "Roll" and 0.04 or 0.12)
	elseif desired and rig.tracks[desired] and not rig.tracks[desired].IsPlaying then
		playState(rig, desired, 0.1)
	end

	local track = desired and rig.tracks[desired]
	if track and (desired == "Walk" or desired == "Run" or desired == "Climb" or desired == "Swim") then
		local referenceSpeed = desired == "Run" and 23.2 or 14
		track:AdjustSpeed(math.clamp(speed / referenceSpeed, 0.3, 1.5))
	end
end)


--==================================================
-- MOVEMENT + PROCEDURAL ANIMATION
--==================================================

RunService.PreSimulation:Connect(function(dt)

	local now = workspace:GetServerTimeNow()


	for character, rig in pairs(rigs) do

		if not character.Parent then
			rigs[character] = nil
			continue
		end


		local humanoid = rig.humanoid
		local root = rig.root
		local humanoidState = humanoid:GetState()

		--==========================================
		-- LOCAL PLAYER MOVEMENT
		--==========================================

		if character == player.Character
			and humanoid.Health > 0
			and not humanoid.Sit
			and not humanoid.PlatformStand
			and humanoid.FloorMaterial
			~= Enum.Material.Air
			and humanoidState ~= Enum.HumanoidStateType.Jumping
			and humanoid.Jump ~= true
			and now
			- (
				character:GetAttribute(
					"RollStartedAt"
				)
					or -100
			)
				>= 0.6
				and now >= (character:GetAttribute("HitReactionUntil") or -math.huge)
				and not root:FindFirstChildOfClass(
					"LinearVelocity"
				) then


			local direction =
				humanoid.MoveDirection

			local velocity =
				root.AssemblyLinearVelocity


			--======================================
			-- MOVEMENT VELOCITY
			--======================================

			root.AssemblyLinearVelocity =
				Vector3.new(
					direction.X
					* humanoid.WalkSpeed,

					velocity.Y,

					direction.Z
					* humanoid.WalkSpeed
				)


			--======================================
			-- SMOOTH CHARACTER ROTATION
			--======================================

			if direction.Magnitude > 0.1
				and not character:GetAttribute("CombatFacingLock") then

				local flatDirection =
					Vector3.new(
						direction.X,
						0,
						direction.Z
					).Unit


				local targetCFrame =
					CFrame.lookAt(
						root.Position,
						root.Position
						+ flatDirection
					)


				-- Frame-rate independent smoothing.
				local turnAlpha =
					1 - math.exp(
						-TURN_SPEED * dt
					)


				root.CFrame =
					root.CFrame:Lerp(
						targetCFrame,
						turnAlpha
					)


				root.AssemblyAngularVelocity =
					Vector3.zero
			end
		end


		--==========================================
		-- MOVEMENT STATE
		--==========================================

		local velocity =
			root.AssemblyLinearVelocity

		local speed =
			Vector3.new(
				velocity.X,
				0,
				velocity.Z
			).Magnitude


		local moving =
			speed > 0.7


		local running =
			character:GetAttribute(
				"Sprinting"
			) == true


		local airborne =
			humanoid.FloorMaterial
			== Enum.Material.Air


		local rollTime =
			now
		- (
			character:GetAttribute(
				"RollStartedAt"
			)
				or -100
		)

		local rollDuration = rig.tuning.RollGameplayDuration or 0.6

		local rolling =
			rollTime >= 0
			and rollTime < rollDuration

		-- Rotate only the welded Half-Beast visual during the existing roll
		-- window. This leaves the HumanoidRootPart, physics, and server roll
		-- authority untouched while making the whole visible model somersault.
		if rig.visualMotor then
			if rolling then
				local rollAlpha = math.clamp(rollTime / rollDuration, 0, 1)
				local rotation = CFrame.Angles(-math.pi * 2 * rollAlpha, 0, 0)
				-- RaceVisualRoot is aligned to the visual's base, not its center.
				-- Offset the Motor6D transform so the complete mesh rotates around
				-- its own center instead of sweeping down through the floor.
				rig.visualMotor.Transform = CFrame.new(rig.visualRollPivot) * rotation * CFrame.new(-rig.visualRollPivot)
			else
				rig.visualMotor.Transform = CFrame.identity
			end
		end

		local reactionName = character:GetAttribute("HitReaction")
		local reactionStartedAt = character:GetAttribute("HitReactionStartedAt") or now
		local reactionUntil = character:GetAttribute("HitReactionUntil") or -math.huge
		local reacting = now < reactionUntil and type(reactionName) == "string"
		local reactionElapsed = math.max(0, now - reactionStartedAt)


		--==========================================
		-- CHECK NATIVE ANIMATION
		--==========================================

		local native = false

		if rig.animator then
			for _, track in ipairs(
				rig.animator:GetPlayingAnimationTracks()
				) do

				local animation = track.Animation
				local animationId =
					animation and animation.AnimationId

				local nativeMovement =
					animationId
					and rig.nativeIds[animationId] == true

				local priority =
					track.Priority

				local actionAnimation =
					priority == Enum.AnimationPriority.Action
					or priority == Enum.AnimationPriority.Action2
					or priority == Enum.AnimationPriority.Action3
					or priority == Enum.AnimationPriority.Action4

				if track.WeightCurrent > 0.001
					and (nativeMovement or actionAnimation) then

					native = true
					break
				end
			end
		end

		local reactionTrack = reacting
			and rig.tracks[speed > 1.5 and "SlidingStumble" or "IdleStumble"]
		if reacting and not (reactionTrack and reactionTrack.IsPlaying) then
			native = false
		end


		--==========================================
		-- ANIMATION STATE ATTRIBUTE
		--==========================================

		character:SetAttribute(
			"LocalAnimationState",

			rig.dead and "Death"

				or rig.currentState

				or reacting and reactionName

				or rolling and "Roll"

				or airborne
				and (
					velocity.Y > 0
					and "Jump"
					or "Fall"
				)

				or moving
				and (
					running
					and "Run"
					or "Walk"
				)

				or "Idle"
		)


		character:SetAttribute(
			"LocalAnimationSource",

			native
				and "Meshy"
				or "Procedural"
		)


		-- Kalau native animation sedang aktif,
		-- ambil pose native dan jangan procedural.
		if native then
			if rig.currentState == "Idle" then
				-- Keep the Idle clip's body motion, but override its wide arm pose
				-- with a relaxed, waist-adjacent hand position.
				local inward = rig.tuning.IdleArmInward or 0
				local forearmBend = rig.tuning.IdleForearmBend or 0
				-- This rig's mirrored arm axes rotate downward with these signs.
				setBoneRotation(rig, "LeftArm", 0, 0, inward)
				setBoneRotation(rig, "RightArm", 0, 0, -inward)
				setBoneRotation(rig, "LeftForeArm", forearmBend)
				setBoneRotation(rig, "RightForeArm", forearmBend)
			end

			for _, boneData in pairs(
				rig.bones
				) do

				boneData.pose =
					boneData.bone.Transform

			end

			continue
		end


		--==========================================
		-- PROCEDURAL PHASE
		--==========================================

		local movementReferenceSpeed =
			running
			and 23.2
			or 14


		rig.phase +=
			dt
			* (
				running
				and 13
				or 9
			)
			* math.clamp(
				speed
				/ movementReferenceSpeed,

				0.3,
				1.5
			)


		local targets = {}


		--==========================================
		-- POSE HELPER
		--==========================================

		local function pose(
			name,
			x,
			y,
			z,
			offset
		)

			local boneData =
				rig.bones[name]

			if not boneData then
				return
			end


			local rotation =
				CFrame.Angles(
					x or 0,
					y or 0,
					z or 0
				)


			targets[name] =
				boneData.bind:Inverse()

				* CFrame.new(
					offset
					or Vector3.zero
				)

				* rotation

				* boneData.bind
		end


		--==========================================
		-- DEAD
		--==========================================

		if humanoid.Health <= 0 then

			pose(
				"Spine02",
				0.3
			)


			--==========================================
			-- HIT REACTION
			--==========================================

		elseif reacting then
			local pulse = math.sin(math.clamp(reactionElapsed * 18, 0, math.pi))

			if reactionName == "Stagger" then
				pose("Hips", 0.10, 0, 0, Vector3.new(0, -0.18, 0.18))
				pose("Spine02", 0.42 + pulse * 0.12, 0, 0)
				pose("LeftArm", -0.55, 0, -0.38)
				pose("RightArm", -0.55, 0, 0.38)
				pose("LeftUpLeg", -0.28)
				pose("RightUpLeg", -0.18)
				pose("LeftLeg", 0.42)
				pose("RightLeg", 0.35)
			elseif reactionName == "Finisher" then
				pose("Hips", 0.18, 0, 0, Vector3.new(0, -0.12, 0.35))
				pose("Spine02", 0.62 + pulse * 0.14)
				pose("LeftArm", -0.85, 0, -0.55)
				pose("RightArm", -0.85, 0, 0.55)
				pose("LeftForeArm", -0.35)
				pose("RightForeArm", -0.35)
			else
				pose("Spine02", 0.22 + pulse * 0.09, 0, pulse * 0.05)
				pose("LeftArm", -0.22, 0, -0.18)
				pose("RightArm", -0.22, 0, 0.18)
			end


			--==========================================
			-- ROLL
			--==========================================

		elseif rolling then

			local t =
				rollTime / 0.6


			pose(
				"Hips",
				-2 * math.pi * t,
				0,
				0,
				Vector3.new(
					0,
					-0.6
						* math.sin(
							math.pi * t
						),
					0
				)
			)


			pose(
				"Spine02",
				-0.55
			)


			pose(
				"LeftUpLeg",
				-1.25
			)

			pose(
				"RightUpLeg",
				-1.25
			)


			pose(
				"LeftLeg",
				1.6
			)

			pose(
				"RightLeg",
				1.6
			)


			pose(
				"LeftArm",
				-1.2
			)

			pose(
				"RightArm",
				-1.2
			)


			pose(
				"LeftForeArm",
				-1.1
			)

			pose(
				"RightForeArm",
				-1.1
			)


			--==========================================
			-- AIR
			--==========================================

		elseif airborne then

			local rising =
				velocity.Y > 0


			pose(
				"LeftUpLeg",
				rising
					and -0.55
					or -0.15
			)


			pose(
				"RightUpLeg",
				rising
					and 0.15
					or 0.2
			)


			pose(
				"LeftLeg",
				0.6
			)

			pose(
				"RightLeg",
				0.45
			)


			pose(
				"LeftArm",
				-0.5,
				0,
				-0.25
			)

			pose(
				"RightArm",
				-0.5,
				0,
				0.25
			)


			pose(
				"Spine02",
				-0.12
			)


			--==========================================
			-- WALK / RUN PROCEDURAL
			--==========================================

		elseif moving then

			local wave =
				math.sin(
					rig.phase
				)


			local stride =
				running
				and 0.85
				or 0.5


			pose(
				"LeftUpLeg",
				wave * stride
			)

			pose(
				"RightUpLeg",
				-wave * stride
			)


			pose(
				"LeftLeg",

				math.max(
					0,
					-wave
				)
					* (
						running
						and 1.15
						or 0.65
					)
			)


			pose(
				"RightLeg",

				math.max(
					0,
					wave
				)
					* (
						running
						and 1.15
						or 0.65
					)
			)


			pose(
				"LeftArm",
				-wave
					* stride
					* 0.8
			)


			pose(
				"RightArm",
				wave
					* stride
					* 0.8
			)


			pose(
				"LeftForeArm",

				running
					and -0.9
					or -0.25
			)


			pose(
				"RightForeArm",

				running
					and -0.9
					or -0.25
			)


			pose(
				"Spine02",

				running
					and -0.18
					or -0.04,

				wave * 0.06
			)


			pose(
				"Hips",
				0,
				0,
				wave * 0.035,

				Vector3.new(
					0,

					math.cos(
						rig.phase * 2
					) * 0.055,

					0
				)
			)


			--==========================================
			-- IDLE
			--==========================================

		else

			pose(
				"Spine02",
				math.sin(
					now * 2
				) * 0.018
			)


			pose(
				"LeftArm",
				0,
				0,
				-0.04
			)


			pose(
				"RightArm",
				0,
				0,
				0.04
			)

		end


		--==========================================
		-- PROCEDURAL BONE BLENDING
		--==========================================

		for name, boneData in pairs(
			rig.bones
			) do

			local target =
				targets[name]
				or CFrame.identity


			-- Roll tetap lebih direct.
			-- Movement biasa smooth blend.
			boneData.pose =
				rolling
				and target

				or boneData.pose:Lerp(
					target,
					1 - math.exp(
						-dt * 16
					)
				)


			boneData.bone.Transform =
				boneData.pose
		end
	end
end)
