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

for _, id in pairs(clipIds) do
	nativeIds[id] = true
end

local sprint = false

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

	for _, bone in ipairs(mesh:GetDescendants()) do

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

	local rig = {
		humanoid = humanoid,
		root = root,
		bones = bones,
		phase = 0,
		animator = animator,
		tracks = {}
	}

	rigs[character] = rig


	--==============================================
	-- LOCAL PLAYER
	--==============================================

	if character == player.Character then

		-- Kita atur rotasi sendiri supaya
		-- perubahan WASD bisa di-blend.
		humanoid.AutoRotate = false

		if animator then

			for name, id in pairs(clipIds) do

				local animation = Instance.new("Animation")

				animation.Name = "Meshy" .. name
				animation.AnimationId = id

				local ok, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)

				animation:Destroy()

				if ok then

					track.Looped = name ~= "Roll"

					track.Priority =
						name == "Roll"
						and Enum.AnimationPriority.Action4
						or Enum.AnimationPriority.Movement

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


	local velocity = rig.root.AssemblyLinearVelocity

	local speed = Vector3.new(
		velocity.X,
		0,
		velocity.Z
	).Magnitude


	local rollStart =
		character:GetAttribute("RollStartedAt")
		or -100

	local serverNow = workspace:GetServerTimeNow()
	local rollTime = serverNow - rollStart
	local reactionActive = serverNow < (character:GetAttribute("HitReactionUntil") or -math.huge)


	local desired


	if rig.humanoid.Health > 0 then

		if reactionActive then
			desired = nil

		elseif rollTime >= 0
			and rollTime < 0.6 then

			desired = "Roll"


		elseif rig.humanoid.FloorMaterial
			~= Enum.Material.Air
			and speed > 0.7 then

			desired =
				character:GetAttribute("Sprinting")
				and "Run"
				or "Walk"

		end
	end


	--==============================================
	-- CROSSFADE ANIMATION
	--==============================================

	for name, track in pairs(rig.tracks) do

		if name == desired
			and track.Length > 0 then


			--======================================
			-- ROLL
			--======================================

			if name == "Roll" then

				if rig.lastRoll ~= rollStart then

					rig.lastRoll = rollStart

					track:Play(
						0.04,
						1,
						track.Length / 0.6
					)

					track.TimePosition = math.min(
						rollTime / 0.6 * track.Length,
						track.Length - 0.001
					)

				end


				--======================================
				-- WALK / RUN
				--======================================

			else

				if not track.IsPlaying then
					track:Play(0.12)
				end

				-- Walk divisor 14:
				-- sedikit lebih cepat dibanding sebelumnya 16.
				--
				-- Run tetap 23.2.

				local animationReferenceSpeed =
					name == "Run"
					and 23.2
					or 14

				track:AdjustSpeed(
					math.clamp(
						speed / animationReferenceSpeed,
						0.3,
						1.5
					)
				)

			end


		elseif track.IsPlaying then

			-- Fade-out supaya tidak pop/flick.
			track:Stop(0.08)

		end
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


		--==========================================
		-- LOCAL PLAYER MOVEMENT
		--==========================================

		if character == player.Character
			and humanoid.Health > 0
			and not humanoid.Sit
			and not humanoid.PlatformStand
			and humanoid.FloorMaterial
			~= Enum.Material.Air
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


		local rolling =
			rollTime >= 0
			and rollTime < 0.6

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
					and nativeIds[animationId] == true

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

		if reacting then
			native = false
		end


		--==========================================
		-- ANIMATION STATE ATTRIBUTE
		--==========================================

		character:SetAttribute(
			"LocalAnimationState",

			reacting and reactionName

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