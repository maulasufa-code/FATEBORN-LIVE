-- HumanBoxingBones (LocalScript)
-- Procedural boxing M1 combo khusus race Human yang memakai bone rig
-- (char1 + Bone, tanpa Motor6D). Berjalan di RenderStepped SETELAH
-- PlayerMovement menulis locomotion di PreSimulation, jadi pose pukulan
-- menang tiap frame selama window aktif lalu dilepas kembali mulus.
-- Trigger: attribute server-authoritative BasicAttackStartedAt /
-- BasicAttackComboIndex (ServerScriptService.Fateborn.basicAttack).
-- Reset ikut server: delay lama -> Index 1 (animasi pertama),
-- rapid click -> Index lanjut. Damage tetap dihitung server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SWING_ID = "rbxassetid://9045207152"
local HIT_ID = "rbxassetid://75638578888623"
local FINISHER_ID = "rbxassetid://78971025489858"

local HIT_DELAY = 0.22
local A_T = 0.12
local S_T = 0.24
local F_T = 0.40
local DUR = 0.62

local function R(x, y, z)
  return { math.rad(x), math.rad(y), math.rad(z) }
end

-- Combo boxing keyframed: antisipasi -> strike -> follow-through -> guard.
-- 1 Jab, 2 Straight, 3 Hook, 4 Uppercut, 5 Body Rip, 6 Overhand.
-- Derajat euler bone-local (X positif = ayun ke depan). Pinggul + Spine01/Spine
-- ikut berputar berlapis agar ada gelombang badan seperti boxing beneran.
local STAGES = {
  { Name = "Jab", Pitch = 1.05, Volume = 0.9, Finisher = false, Keys = {
    { t = A_T, bones = {
      LeftArm = { rot = R(12, 4, -6) },
      LeftForeArm = { rot = R(45, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(0, 7, 0) },
      Spine01 = { rot = R(0, 4, 0) },
      Hips = { rot = R(0, 4, 0), off = Vector3.new(0, -0.02, 0) },
      neck = { rot = R(0, 5, 0) },
    } },
    { t = S_T, bones = {
      LeftArm = { rot = R(80, -6, 0), off = Vector3.new(0, 0, -0.4) },
      LeftForeArm = { rot = R(8, 0, 0) },
      RightArm = { rot = R(26, 0, 16) },
      RightForeArm = { rot = R(62, 0, 0) },
      Spine02 = { rot = R(-2, -8, 0) },
      Spine01 = { rot = R(-1, -4, 0) },
      Spine = { rot = R(0, -2, 0) },
      Hips = { rot = R(-2, -7, 0), off = Vector3.new(0, 0, -0.06) },
      neck = { rot = R(0, -6, 0) },
    } },
    { t = F_T, bones = {
      LeftArm = { rot = R(70, -16, 4), off = Vector3.new(0, 0, -0.35) },
      LeftForeArm = { rot = R(14, 0, 0) },
      RightArm = { rot = R(24, 0, 15) },
      RightForeArm = { rot = R(60, 0, 0) },
      Spine02 = { rot = R(0, -12, 0) },
      Spine01 = { rot = R(0, -6, 0) },
      Hips = { rot = R(0, -10, 0) },
      neck = { rot = R(0, -8, 0) },
    } },
  } },
  { Name = "Straight", Pitch = 1.0, Volume = 0.9, Finisher = false, Keys = {
    { t = A_T, bones = {
      RightArm = { rot = R(12, -4, 6) },
      RightForeArm = { rot = R(45, 0, 0) },
      LeftArm = { rot = R(24, 0, -14) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(0, -7, 0) },
      Spine01 = { rot = R(0, -4, 0) },
      Hips = { rot = R(0, -4, 0), off = Vector3.new(0, -0.02, 0) },
      neck = { rot = R(0, -5, 0) },
    } },
    { t = S_T, bones = {
      RightArm = { rot = R(80, 6, 0), off = Vector3.new(0, 0, -0.4) },
      RightForeArm = { rot = R(6, 0, 0) },
      LeftArm = { rot = R(26, 0, -16) },
      LeftForeArm = { rot = R(62, 0, 0) },
      Spine02 = { rot = R(-2, 8, 0) },
      Spine01 = { rot = R(-1, 4, 0) },
      Spine = { rot = R(0, 2, 0) },
      Hips = { rot = R(-2, 7, 0), off = Vector3.new(0, 0, -0.06) },
      neck = { rot = R(0, 6, 0) },
    } },
    { t = F_T, bones = {
      RightArm = { rot = R(70, 16, -4), off = Vector3.new(0, 0, -0.35) },
      RightForeArm = { rot = R(14, 0, 0) },
      LeftArm = { rot = R(24, 0, -15) },
      LeftForeArm = { rot = R(60, 0, 0) },
      Spine02 = { rot = R(0, 12, 0) },
      Spine01 = { rot = R(0, 6, 0) },
      Hips = { rot = R(0, 10, 0) },
      neck = { rot = R(0, 8, 0) },
    } },
  } },
  { Name = "Hook", Pitch = 0.95, Volume = 0.95, Finisher = false, Keys = {
    { t = A_T, bones = {
      LeftArm = { rot = R(40, 25, 20) },
      LeftForeArm = { rot = R(50, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(2, 10, 0) },
      Spine01 = { rot = R(1, 5, 0) },
      Hips = { rot = R(0, 8, 0) },
      neck = { rot = R(0, 8, 0) },
    } },
    { t = S_T, bones = {
      LeftArm = { rot = R(72, -28, 18), off = Vector3.new(0.05, 0, -0.25) },
      LeftForeArm = { rot = R(78, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(0, -14, 0) },
      Spine01 = { rot = R(0, -7, 0) },
      Hips = { rot = R(-2, -16, 0), off = Vector3.new(0, 0, -0.05) },
      neck = { rot = R(0, -10, 0) },
    } },
    { t = F_T, bones = {
      LeftArm = { rot = R(60, -48, 10), off = Vector3.new(0.15, 0, -0.15) },
      LeftForeArm = { rot = R(85, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(2, -24, 0) },
      Spine01 = { rot = R(1, -12, 0) },
      Spine = { rot = R(0, -6, 0) },
      Hips = { rot = R(0, -22, 0) },
      neck = { rot = R(0, -14, 0) },
    } },
  } },
  { Name = "Uppercut", Pitch = 0.9, Volume = 0.95, Finisher = false, Keys = {
    { t = A_T, bones = {
      RightArm = { rot = R(18, 6, -6) },
      RightForeArm = { rot = R(70, 0, 0) },
      LeftArm = { rot = R(24, 0, -14) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-12, 6, 0) },
      Spine01 = { rot = R(-6, 3, 0) },
      Hips = { rot = R(6, 5, 0), off = Vector3.new(0, -0.12, 0) },
      neck = { rot = R(-6, 4, 0) },
    } },
    { t = S_T, bones = {
      RightArm = { rot = R(48, 8, -6), off = Vector3.new(0, -0.05, -0.2) },
      RightForeArm = { rot = R(105, 0, 0) },
      LeftArm = { rot = R(24, 0, -14) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(8, -10, 0) },
      Spine01 = { rot = R(4, -5, 0) },
      Spine = { rot = R(2, -2, 0) },
      Hips = { rot = R(-4, -8, 0), off = Vector3.new(0, 0.02, 0) },
      neck = { rot = R(10, -6, 0) },
    } },
    { t = F_T, bones = {
      RightArm = { rot = R(60, 6, -4) },
      RightForeArm = { rot = R(95, 0, 0) },
      LeftArm = { rot = R(24, 0, -14) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(10, -12, 0) },
      Spine01 = { rot = R(5, -6, 0) },
      Hips = { rot = R(0, -10, 0), off = Vector3.new(0, 0.04, -0.02) },
      neck = { rot = R(12, -8, 0) },
    } },
  } },
  { Name = "Body", Pitch = 1.1, Volume = 1.0, Finisher = true, Keys = {
    { t = A_T, bones = {
      LeftArm = { rot = R(30, -6, 0) },
      LeftForeArm = { rot = R(45, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-26, 8, 0) },
      Spine01 = { rot = R(-13, 4, 0) },
      Spine = { rot = R(-6, 2, 0) },
      Hips = { rot = R(8, 5, 0), off = Vector3.new(0, -0.15, 0) },
      neck = { rot = R(-10, 5, 0) },
    } },
    { t = S_T, bones = {
      LeftArm = { rot = R(52, -8, 0), off = Vector3.new(0, 0.02, -0.3) },
      LeftForeArm = { rot = R(38, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-16, -8, 0) },
      Spine01 = { rot = R(-8, -4, 0) },
      Hips = { rot = R(4, -6, 0), off = Vector3.new(0, -0.1, 0) },
      neck = { rot = R(-4, -5, 0) },
    } },
    { t = F_T, bones = {
      LeftArm = { rot = R(45, -14, 2) },
      LeftForeArm = { rot = R(45, 0, 0) },
      RightArm = { rot = R(24, 0, 14) },
      RightForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-18, -14, 0) },
      Spine01 = { rot = R(-9, -7, 0) },
      Hips = { rot = R(4, -10, 0), off = Vector3.new(0, -0.12, 0) },
      neck = { rot = R(-6, -8, 0) },
    } },
  } },
  { Name = "Overhand", Pitch = 0.85, Volume = 1.0, Finisher = true, Keys = {
    { t = A_T, bones = {
      RightArm = { rot = R(5, 0, -8) },
      RightForeArm = { rot = R(40, 0, 0) },
      LeftArm = { rot = R(30, 0, -14) },
      LeftForeArm = { rot = R(60, 0, 0) },
      Spine02 = { rot = R(-4, -10, 0) },
      Spine01 = { rot = R(-2, -5, 0) },
      Hips = { rot = R(0, -12, 0) },
      neck = { rot = R(0, -8, 0) },
    } },
    { t = S_T, bones = {
      RightArm = { rot = R(122, 0, -18), off = Vector3.new(0, 0.12, -0.32) },
      RightForeArm = { rot = R(10, 0, 0) },
      LeftArm = { rot = R(26, 0, -15) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-12, 14, 0) },
      Spine01 = { rot = R(-6, 7, 0) },
      Spine = { rot = R(-3, 3, 0) },
      Hips = { rot = R(-6, 16, 0), off = Vector3.new(0, 0.02, -0.06) },
      neck = { rot = R(-6, 10, 0) },
    } },
    { t = F_T, bones = {
      RightArm = { rot = R(88, 4, -10), off = Vector3.new(0, 0, -0.35) },
      RightForeArm = { rot = R(18, 0, 0) },
      LeftArm = { rot = R(24, 0, -14) },
      LeftForeArm = { rot = R(58, 0, 0) },
      Spine02 = { rot = R(-20, 18, 0) },
      Spine01 = { rot = R(-10, 9, 0) },
      Spine = { rot = R(-5, 4, 0) },
      Hips = { rot = R(-8, 20, 0), off = Vector3.new(0, -0.02, -0.04) },
      neck = { rot = R(-10, 12, 0) },
    } },
  } },
}

-- Guard santai: pose netral tiap combo selesai agar lepasnya mulus.
local REST = {
  LeftArm = { rot = R(24, 0, -14) },
  RightArm = { rot = R(24, 0, 14) },
  LeftForeArm = { rot = R(55, 0, 0) },
  RightForeArm = { rot = R(55, 0, 0) },
  Spine02 = { rot = R(0, 0, 0) },
  Spine01 = { rot = R(0, 0, 0) },
  Spine = { rot = R(0, 0, 0) },
  Hips = { rot = R(0, 0, 0) },
  neck = { rot = R(0, 0, 0) },
}

local attached = {}
local active = {}

local function easeInOut(u)
  if u <= 0 then return 0 end
  if u >= 1 then return 1 end
  return u < 0.5 and 2 * u * u or 1 - ((-2 * u + 2) ^ 2) / 2
end

local function easeOutQuart(u)
  if u <= 0 then return 0 end
  if u >= 1 then return 1 end
  return 1 - (1 - u) ^ 4
end

local function goalCF(bindInv, bind, spec)
  local r = spec.rot or { 0, 0, 0 }
  return bindInv * CFrame.new(spec.off or Vector3.zero) * CFrame.Angles(r[1], r[2], r[3]) * bind
end

local function startPunch(char, rec, stage)
  local union = {}
  for n in pairs(REST) do union[n] = true end
  for _, k in ipairs(stage.Keys) do
    for n in pairs(k.bones) do union[n] = true end
  end
  local from = {}
  for n in pairs(union) do
    local b = rec.bones[n]
    if b then from[n] = b.Transform end
  end
  local points = { { t = 0, goals = from } }
  for _, k in ipairs(stage.Keys) do
    local g = {}
    for n, spec in pairs(k.bones) do
      if rec.bind[n] then g[n] = goalCF(rec.bindInv[n], rec.bind[n], spec) end
    end
    table.insert(points, { t = k.t, goals = g })
  end
  local restG = {}
  for n, spec in pairs(REST) do
    if rec.bind[n] then restG[n] = goalCF(rec.bindInv[n], rec.bind[n], spec) end
  end
  table.insert(points, { t = DUR, goals = restG })
  local last = {}
  for _, pt in ipairs(points) do
    local r = {}
    for n in pairs(union) do r[n] = pt.goals[n] or last[n] end
    pt.full = r
    last = r
  end
  active[char] = { rec = rec, points = points, union = union, t0 = os.clock() }
  char:SetAttribute("BoxingDebug", stage.Name)
  local swing = rec.sounds.swing
  if swing then pcall(function()
    swing.PlaybackSpeed = stage.Pitch
    swing:Play()
  end) end
  task.delay(HIT_DELAY, function()
    local s = rec.sounds.hit
    if stage.Finisher then s = rec.sounds.finisher or s end
    if s then pcall(function()
      s.PlaybackSpeed = stage.Pitch
      s.Volume = stage.Volume
      s:Play()
    end) end
  end)
end

RunService.RenderStepped:Connect(function()
  local now = os.clock()
  for char, p in pairs(active) do
    local rec = p.rec
    if not rec.alive or char.Parent == nil then
      active[char] = nil
    else
      local t = now - p.t0
      local holdTest = char:GetAttribute("BoxingTestHold") == true
      if holdTest then t = math.min(t, S_T) end
      local pts = p.points
      if t >= DUR and not holdTest then
        active[char] = nil
      else
        local i = #pts - 1
        for k = 1, #pts - 1 do
          if t < pts[k + 1].t then i = k break end
        end
        local span = pts[i + 1].t - pts[i].t
        local u = span > 0 and math.clamp((t - pts[i].t) / span, 0, 1) or 1
        local e = (i == 2) and easeOutQuart(u) or easeInOut(u)
        for n in pairs(p.union) do
          local b = rec.bones[n]
          local a = pts[i].full[n]
          local c = pts[i + 1].full[n]
          if b and a and c then
            pcall(function() b.Transform = a:Lerp(c, e) end)
          end
        end
      end
    end
  end
end)

local function detach(char)
	local rec = attached[char]
	if not rec then return end
	attached[char] = nil
	rec.alive = false
	active[char] = nil
	for _, c in ipairs(rec.conns) do
		pcall(function() c:Disconnect() end)
	end
	pcall(function() rec.sounds.folder:Destroy() end)
end

local function tryAttach(char)
	if attached[char] or not char:IsA("Model") then return end
	if char:GetAttribute("Race") ~= "Human" then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local mesh = char:FindFirstChild("char1")
	if not hum or not mesh or not mesh:IsA("BasePart") then return end
	local bones = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Bone") then bones[d.Name] = d end
	end
	if not bones.LeftArm or not bones.RightArm then return end
	local bind, bindInv = {}, {}
	for name, b in pairs(bones) do
		local ok, cf = pcall(function()
			return mesh.CFrame:ToObjectSpace(b.WorldCFrame).Rotation
		end)
		if ok then
			bind[name] = cf
			bindInv[name] = cf:Inverse()
		end
	end
	if not bind.LeftArm then return end
	local soundParent = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not soundParent then return end
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
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ swing, hit, fin })
		end)
	end)
	local rec = { alive = true, bones = bones, bind = bind, bindInv = bindInv, sounds = { folder = folder, swing = swing, hit = hit, finisher = fin }, conns = {} }
	table.insert(rec.conns, char:GetAttributeChangedSignal("BasicAttackStartedAt"):Connect(function()
		if char:GetAttribute("Race") ~= "Human" then return end
		if hum.Health <= 0 then return end
		local idx = char:GetAttribute("BasicAttackComboIndex")
		if type(idx) ~= "number" then return end
		local stage = STAGES[((idx - 1) % #STAGES) + 1]
		if stage then startPunch(char, rec, stage) end
	end))
	table.insert(rec.conns, char:GetAttributeChangedSignal("Race"):Connect(function()
		if char:GetAttribute("Race") ~= "Human" then detach(char) end
	end))
	table.insert(rec.conns, char.Destroying:Connect(function()
		detach(char)
	end))
	attached[char] = rec
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
		for _ = 1, 20 do
			if attached[char] or not char.Parent then break end
			task.wait(0.5)
			tryAttach(char)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then watchCharacter(p.Character) end
	p.CharacterAdded:Connect(watchCharacter)
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(watchCharacter)
end)
