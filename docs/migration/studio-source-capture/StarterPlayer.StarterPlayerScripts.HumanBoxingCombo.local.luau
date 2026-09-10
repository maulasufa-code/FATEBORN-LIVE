-- HumanBoxingCombo (LocalScript)
-- Procedural boxing M1 combo khusus race Human (rig R15 standar).
-- Mendengarkan attribute server-authoritative BasicAttackStartedAt /
-- BasicAttackComboIndex (di-set di ServerScriptService.Fateborn.basicAttack).
-- Reset otomatis ikut server: delay lama -> Index balik 1 (animasi pertama),
-- rapid click -> Index lanjut (animasi berikutnya). Visual saja, damage tetap
-- dihitung server. Bone character (Half-Beast dll) diabaikan karena sudah
-- ditangani PlayerMovement.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Dinonaktifkan: semua char Human memakai bone rig, combo ditangani HumanBoxingBones.
do return end

local SWING_ID = "rbxassetid://9045207152"
local HIT_ID = "rbxassetid://75638578888623"
local FINISHER_ID = "rbxassetid://78971025489858"

local OUT_TIME = 0.09
local HOLD_TIME = 0.05
local BACK_TIME = 0.18
local HIT_DELAY = 0.08

local function A(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

-- Referensi combo boxing: 1 Jab, 2 Straight/Cross, 3 Lead Hook,
-- 4 Rear Uppercut, 5 Body Shot, 6 Overhand (finisher).
local STAGES = {
	{ Name = "Jab", Pitch = 1.05, Volume = 0.9, Finisher = false, Pose = function(b)
		return { shL = b.shL * A(-78, -8, 0), elL = b.elL and (b.elL * A(-14, 0, 0)) or nil, waist = b.waist and (b.waist * A(0, 7, 0)) or nil }
	end },
	{ Name = "Straight", Pitch = 1.0, Volume = 0.9, Finisher = false, Pose = function(b)
		return { shR = b.shR * A(-78, 8, 0), elR = b.elR and (b.elR * A(-11, 0, 0)) or nil, waist = b.waist and (b.waist * A(0, -9, 0)) or nil }
	end },
	{ Name = "Hook", Pitch = 0.95, Volume = 0.95, Finisher = false, Pose = function(b)
		return { shL = b.shL * A(-63, -40, 17), elL = b.elL and (b.elL * A(-69, 0, 0)) or nil, waist = b.waist and (b.waist * A(0, 14, 0)) or nil }
	end },
	{ Name = "Uppercut", Pitch = 0.9, Volume = 0.95, Finisher = false, Pose = function(b)
		return { shR = b.shR * A(-29, 11, -11), elR = b.elR and (b.elR * A(-57, 0, 0)) or nil, waist = b.waist and (b.waist * A(-6, -11, 0)) or nil }
	end },
	{ Name = "Body", Pitch = 1.1, Volume = 1.0, Finisher = true, Pose = function(b)
		return { shL = b.shL * A(-40, -11, 0), elL = b.elL and (b.elL * A(-29, 0, 0)) or nil, waist = b.waist and (b.waist * A(14, 9, 0)) or nil }
	end },
	{ Name = "Overhand", Pitch = 0.85, Volume = 1.0, Finisher = true, Pose = function(b)
		return { shR = b.shR * A(-109, 0, -17), elR = b.elR and (b.elR * A(-9, 0, 0)) or nil, waist = b.waist and (b.waist * A(-9, -14, 0)) or nil }
	end },
}

local attached = {}

local function findMotor(char, names)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") then
			for _, n in ipairs(names) do
				if d.Name == n then
					return d
				end
			end
		end
	end
	return nil
end

local function cancelTweens(state)
	for _, tw in ipairs(state.tweens) do
		pcall(function() tw:Cancel() end)
	end
	table.clear(state.tweens)
end

local function tweenJoint(state, joint, goal, time, style, dir)
	if not joint then return end
	local tw = TweenService:Create(joint, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), { C0 = goal })
	table.insert(state.tweens, tw)
	tw:Play()
end

local function punch(state, stage)
	if not state.alive then return end
	state.seq += 1
	local mySeq = state.seq
	cancelTweens(state)
	local ok, goals = pcall(stage.Pose, state.base)
	if ok and type(goals) == "table" then
		for key, goal in pairs(goals) do
			local joint = state.joints[key]
			if joint and goal then
				tweenJoint(state, joint, goal, OUT_TIME)
			end
		end
	end
	local swing = state.sounds.swing
	if swing then pcall(function()
		swing.PlaybackSpeed = stage.Pitch
		swing:Play()
	end) end
	task.delay(HIT_DELAY, function()
		if not state.alive then return end
		local s = state.sounds.hit
		if stage.Finisher then s = state.sounds.finisher or s end
		if s then pcall(function()
			s.PlaybackSpeed = stage.Pitch
			s.Volume = stage.Volume
			s:Play()
		end) end
	end)
	task.delay(OUT_TIME + HOLD_TIME, function()
		if not state.alive or state.seq ~= mySeq then return end
		for key, joint in pairs(state.joints) do
			local base = state.base[key]
			if joint and base then
				tweenJoint(state, joint, base, BACK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end)
end

local function detach(char)
	local rec = attached[char]
	if not rec then return end
	attached[char] = nil
	rec.state.alive = false
	for _, c in ipairs(rec.conns) do
		pcall(function() c:Disconnect() end)
	end
	pcall(function() rec.state.sounds.folder:Destroy() end)
	for key, joint in pairs(rec.state.joints) do
		local base = rec.state.base[key]
		if joint and joint.Parent and base then
			pcall(function()
				TweenService:Create(joint, TweenInfo.new(0.15), { C0 = base }):Play()
			end)
		end
	end
end

local function tryAttach(char)
	if attached[char] or not char:IsA("Model") then return end
	if char:GetAttribute("FatebornBoneCharacter") == true then return end
	if char:GetAttribute("Race") ~= "Human" then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local shL = findMotor(char, { "LeftShoulder", "Left Shoulder" })
	local shR = findMotor(char, { "RightShoulder", "Right Shoulder" })
	if not shL or not shR then return end
	local elL = findMotor(char, { "LeftElbow" })
	local elR = findMotor(char, { "RightElbow" })
	local waist = findMotor(char, { "Waist" })
	local soundParent = char:FindFirstChild("Head") or hrp
	local folder = Instance.new("Folder")
	folder.Name = "BoxingSounds"
	local swing = Instance.new("Sound")
	swing.Name = "BoxingSwing"
	swing.SoundId = SWING_ID
	swing.Volume = 0.7
	swing.RollOffMaxDistance = 40
	swing.Parent = folder
	local hit = Instance.new("Sound")
	hit.Name = "BoxingHit"
	hit.SoundId = HIT_ID
	hit.Volume = 0.9
	hit.RollOffMaxDistance = 40
	hit.Parent = folder
	local fin = Instance.new("Sound")
	fin.Name = "BoxingFinisher"
	fin.SoundId = FINISHER_ID
	fin.Volume = 1.0
	fin.RollOffMaxDistance = 50
	fin.Parent = folder
	folder.Parent = soundParent
	local state = {
		alive = true,
		seq = 0,
		tweens = {},
		joints = { shL = shL, shR = shR, elL = elL, elR = elR, waist = waist },
		base = {},
		sounds = { folder = folder, swing = swing, hit = hit, finisher = fin },
	}
	for key, joint in pairs(state.joints) do
		if joint then state.base[key] = joint.C0 end
	end
	state.joints.elL = state.joints.elL or nil
	local conns = {}
	table.insert(conns, char:GetAttributeChangedSignal("BasicAttackStartedAt"):Connect(function()
		if char:GetAttribute("Race") ~= "Human" then return end
		local idx = char:GetAttribute("BasicAttackComboIndex")
		if type(idx) ~= "number" then return end
		local stage = STAGES[((idx - 1) % #STAGES) + 1]
		if stage then punch(state, stage) end
	end))
	table.insert(conns, char:GetAttributeChangedSignal("Race"):Connect(function()
		if char:GetAttribute("Race") ~= "Human" then detach(char) end
	end))
	table.insert(conns, char.Destroying:Connect(function()
		detach(char)
	end))
	attached[char] = { state = state, conns = conns }
end

local function watchCharacter(char)
	if not char:IsA("Model") then return end
	task.spawn(function()
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		local c = char:GetAttributeChangedSignal("Race"):Connect(function()
			tryAttach(char)
		end)
		char.Destroying:Connect(function()
			pcall(function() c:Disconnect() end)
			detach(char)
		end)
		tryAttach(char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then watchCharacter(p.Character) end
	p.CharacterAdded:Connect(watchCharacter)
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(watchCharacter)
end)
