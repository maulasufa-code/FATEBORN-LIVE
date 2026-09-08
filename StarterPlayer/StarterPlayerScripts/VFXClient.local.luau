local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local vfx = ReplicatedStorage:WaitForChild("VFX")
local event = vfx:WaitForChild("VFXEvent")
local localEvent = vfx:WaitForChild("VFXLocal")
local Presets = require(vfx:WaitForChild("Presets"))
local Assets = require(vfx:WaitForChild("Assets"))
local templates = vfx:WaitForChild("Templates")

-- The imported particle pack keeps descriptive instance names (for example
-- "D - QUICKSTEP") instead of the stable names used by Assets.luau. Keep the
-- translation in the client renderer so Rojo cannot discard Studio-only
-- aliases during the next sync.
local templateAliases = {
	HitLight = "Hits.HitEffect", HitHeavy = "Hits.HitEff2", CritStrike = "Hits.HitEff",
	BlockContact = "Hits.BlockEff", ParryContact = "Misc.Perfect Block", GuardBreak = "Portal.BlockBreak",
	ImpactMedium = "Hits.HitEff2", ImpactLarge = "Hits.HitEff",
	BloodSuddenWound = "Blood.A - SUDDEN WOUND", BloodHemorrhage = "Blood.B - HEMORRHAGE",
	BloodSplatter = "Blood.C - BLOOD SPLATTER", BloodSwordContact = "Blood.SwordHitEff2",
	PortalA = "Portal.07 - PORTAL [A]", PortalB = "Portal.08 - PORTAL [B]",
	AuraBase = "Misc.Aura", PrestigeAura = "Misc.Aura", Quickstep = "Hits.D - QUICKSTEP",
	ArcaneTrace = "Misc.Magic Ting7", CastSmall = "Misc.Magic Ting", CastMedium = "Fire.Magic Ting2", CastLarge = "Fire.Magic Ting3",
	FireImpact = "Fire.Burn", FireBurst = "Fire.C - STRONG FIRE", FireAura = "Fire.B - FLAMES",
	FireTrail = "Fire.E - FLOOR FLAMES", FireCharge = "Misc.G - CHARGE", FireProjectile = "Fire.B - FLAMES",
	FireSmoke = "Fire.Burn", FireEmbers = "Fire.A - CANDLELIGHT",
	ExplosionA = "Explosion.01 - EXPLOSION [A]", ExplosionB = "Explosion.02 - EXPLOSION [B]",
	LightningImpact = "Lightning.05 - LIGHTNING STRIKE [A]", LightningArc = "Lightning.I - ELECTRIC BURST",
	LightningCharge = "Lightning.G - LIGHTNING BOLT 01", LightningAura = "Lightning.I - ELECTRIC BURST",
	LightningTrail = "Lightning.H - LIGHTNING BOLT 02",
	SlashLight = "Slash.A - CUTS 01", SlashHeavy = "Slash.B - SLASHES 01", SlashMagic = "Slash.C - SLASH STRIKE",
	SlashMulti = "Slash.D - MULTIPLE SLASHES",
	SmokeLight = "Smoke.A - SMOKE [A]", SmokeHeavy = "Smoke.C - DARK SMOKE [A]",
	SmokeBurst = "Smoke.B - SMOKE [B]", SmokeLoop = "Smoke.D - DARK SMOKE [B]",
	WaterSplash = "Water.SPLASH", WaterImpact = "Water.C - STRONG WATER SPRAY", WaterTrail = "Water.A - STEADY RIPPLE",
	WaterBurst = "Water.B - WATER SPRAY", WaterAura = "Water.E - STEAM",
	BlackHoleA = "BlackHole.03 - BLACK HOLE [A]", BlackHoleB = "BlackHole.04 - BLACK HOLE [B]",
	GroundRing = "Misc.Ground2", AuraBurst = "Misc.Aura", ChargeRing = "Misc.G - CHARGE",
	PowerVortex = "Misc.L - POWER", ShockBubble = "Misc.I - SHOCK BUBBLE",
}

local container = workspace:FindFirstChild("ClientVFX")
if not container then
	container = Instance.new("Folder")
	container.Name = "ClientVFX"
	container.Parent = workspace
end

local function transientAnchor(position, name, direction)
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = direction and direction.Magnitude > 0.01
		and CFrame.lookAt(position, position + direction.Unit)
		or CFrame.new(position)
	anchor.Parent = container
	return anchor
end

local function resolveTemplate(name)
	local function findPath(path)
		if not path then return nil end
		local node = templates
		for segment in string.gmatch(path, "[^%.]+") do
			node = node and node:FindFirstChild(segment)
		end
		return node
	end
	-- Assets contains the logical path. It may point to an imported name that
	-- does not exist, so only accept it when the complete path resolves.
	return findPath(Assets.Templates[name]) or findPath(templateAliases[name])
end

local function scaleSequence(sequence, scale)
	if scale == 1 then return sequence end
	local points = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(
			point.Time,
			point.Value * scale,
			point.Envelope * scale
		))
	end
	return NumberSequence.new(points)
end

local function cloneLayers(templateName, position, color, options)
	options = options or {}
	local template = resolveTemplate(templateName)
	if not template then
		warn("Missing FATEBORN VFX template", templateName)
		return nil, {}
	end

	local anchor = transientAnchor(
		position + (options.Offset or Vector3.zero),
		"VFX_" .. templateName,
		options.Direction
	)
	local attachment = Instance.new("Attachment")
	attachment.Name = "VFXAttachment"
	attachment.Parent = anchor

	local emitters = {}
	-- Imported templates are usually Parts/Models. Their ParticleEmitters may
	-- be nested under Attachments, so direct children alone silently produce an
	-- empty effect (for example, Perfect Block has five nested emitters).
	for _, layer in ipairs(template:GetDescendants()) do
		if layer:IsA("ParticleEmitter") then
			local emitter = layer:Clone()
			emitter.Enabled = false
			emitter.Rate = 0
			if typeof(color) == "Color3" and not options.PreserveSourceColor then
				emitter.Color = ColorSequence.new(color)
			end
			emitter.Size = scaleSequence(emitter.Size, options.Scale or 1)
			local lifetimeScale = options.LifetimeScale or 1
			emitter.Lifetime = NumberRange.new(
				math.max(0.04, emitter.Lifetime.Min * lifetimeScale),
				math.max(0.05, emitter.Lifetime.Max * lifetimeScale)
			)
			emitter.Speed = NumberRange.new(
				emitter.Speed.Min * (options.SpeedScale or 1),
				emitter.Speed.Max * (options.SpeedScale or 1)
			)
			emitter.LightEmission = math.clamp(
				emitter.LightEmission * (options.Brightness or 1),
				0,
				0.9
			)
			emitter.Parent = attachment
			table.insert(emitters, emitter)
		end
	end
	return anchor, emitters
end

local function emitTemplate(templateName, position, color, options)
	options = options or {}
	local anchor, emitters = cloneLayers(templateName, position, color, options)
	if not anchor then return end
	local maxLifetime = 0
	for _, emitter in ipairs(emitters) do
		local sourceCount = emitter:GetAttribute("EmitCount") or 1
		local count = math.clamp(math.floor(sourceCount * (options.Density or 1) + 0.5), 1, 8)
		emitter:Emit(count)
		maxLifetime = math.max(maxLifetime, emitter.Lifetime.Max)
	end
	Debris:AddItem(anchor, maxLifetime + 0.3)
end

local function loopTemplate(templateName, position, color, options)
	options = options or {}
	local anchor, emitters = cloneLayers(templateName, position, color, options)
	if not anchor then return end
	local duration = math.clamp(options.Duration or 1, 0.15, 12)
	local maxLifetime = 0
	for _, emitter in ipairs(emitters) do
		emitter.Rate = math.clamp(
			(emitter:GetAttribute("LoopRate") or 1) * (options.Intensity or 1),
			0.25,
			options.MaxRate or 2.5
		)
		emitter.Enabled = true
		maxLifetime = math.max(maxLifetime, emitter.Lifetime.Max)
	end
	task.delay(duration, function()
		if not anchor.Parent then return end
		for _, emitter in ipairs(emitters) do emitter.Enabled = false end
	end)
	Debris:AddItem(anchor, duration + maxLifetime + 0.35)
end

local function emitMany(list, position, color, common)
	for _, item in ipairs(list) do
		local options = {}
		for key, value in pairs(common or {}) do options[key] = value end
		for key, value in pairs(item) do
			if key ~= "Template" then options[key] = value end
		end
		emitTemplate(item.Template, position, color, options)
	end
end

local mappings = {
	HitLight = { { Template = "HitLight", Scale = 0.7, Density = 0.8, LifetimeScale = 0.75 } },
	CombatHit = { { Template = "HitLight", Scale = 0.7, Density = 0.8, LifetimeScale = 0.75 } },
	HitHeavy = { { Template = "HitHeavy", Scale = 0.58, Density = 0.58, LifetimeScale = 0.8 } },
	HeavyHit = { { Template = "HitHeavy", Scale = 0.58, Density = 0.58, LifetimeScale = 0.8 } },
	Crit = {
		{ Template = "CritStrike", Scale = 0.54, Density = 0.52, LifetimeScale = 0.72 },
		{ Template = "LightningImpact", Scale = 0.55, Density = 0.5, LifetimeScale = 0.42, Brightness = 0.72 },
	},
	Block = { { Template = "BlockContact", Scale = 0.48, Density = 0.55, LifetimeScale = 0.55 } },
	Parry = { { Template = "ParryContact", Scale = 0.5, Density = 0.55, LifetimeScale = 0.5 } },
	GuardBreak = {
		{ Template = "GuardBreak", Scale = 0.62, Density = 0.62, LifetimeScale = 0.65 },
		{ Template = "ImpactLarge", Scale = 0.38, Density = 0.38, LifetimeScale = 0.55 },
	},
	ImpactMedium = { { Template = "ImpactMedium", Scale = 0.72, Density = 0.48, LifetimeScale = 0.7, SpeedScale = 0.65 } },
	Impact = { { Template = "ImpactMedium", Scale = 0.75, Density = 0.52, LifetimeScale = 0.72, SpeedScale = 0.7 } },
	ImpactLarge = { { Template = "ImpactLarge", Scale = 0.72, Density = 0.55, LifetimeScale = 0.75, SpeedScale = 0.7 } },
	Explosion = { { Template = "ImpactLarge", Scale = 0.8, Density = 0.62, LifetimeScale = 0.78, SpeedScale = 0.72 } },
	HitReaction = { { Template = "BloodSuddenWound", Scale = 0.58, Density = 0.5, LifetimeScale = 0.65, PreserveSourceColor = true } },
	Slash = { { Template = "SlashLight", Scale = 1.45, Density = 1, LifetimeScale = 0.55 } },
	HeavySlash = { { Template = "SlashHeavy", Scale = 1.9, Density = 1, LifetimeScale = 0.75 } },
	MagicSlash = {
		{ Template = "SlashMagic", Scale = 2.1, Density = 1, LifetimeScale = 0.85 },
		{ Template = "ArcaneTrace", Scale = 0.42, Density = 0.45, LifetimeScale = 0.45 },
	},
	Cast = { { Template = "CastSmall", Scale = 0.52, Density = 0.5, LifetimeScale = 0.65 } },
	CastSmall = { { Template = "CastSmall", Scale = 0.42, Density = 0.45, LifetimeScale = 0.55 } },
	CastMedium = { { Template = "CastMedium", Scale = 0.72, Density = 0.55, LifetimeScale = 0.75 } },
	CastLarge = { { Template = "CastLarge", Scale = 0.72, Density = 0.5, LifetimeScale = 0.75 } },
	AoE = { { Template = "CastMedium", Scale = 0.8, Density = 0.6, LifetimeScale = 0.8 } },
	Projectile = { { Template = "FireProjectile", Scale = 0.75, Density = 0.65, LifetimeScale = 0.65 } },
	Beam = { { Template = "LightningArc", Scale = 0.8, Density = 0.6, LifetimeScale = 0.5, Brightness = 0.7 } },
	Shield = { { Template = "BlockContact", Scale = 0.72, Density = 0.6, LifetimeScale = 0.75 } },
	Blink = { { Template = "PortalA", Scale = 0.42, Density = 0.5, LifetimeScale = 0.55 } },
}

local function playMovement(name, position, color, data)
	local direction = typeof(data.Direction) == "Vector3" and data.Direction or Vector3.new(0, 0, -1)
	if direction.Magnitude < 0.01 then direction = Vector3.new(0, 0, -1) end
	if name == "Dash" then
		emitMany({
			{ Template = "Quickstep", Scale = 0.75, Density = 0.7, LifetimeScale = 0.65, Direction = -direction },
			{ Template = "SmokeLight", Scale = 0.2, Density = 0.35, LifetimeScale = 0.35, SpeedScale = 0.55, PreserveSourceColor = true },
		}, position, color)
	elseif name == "Roll" then
		emitTemplate("SmokeLight", position, color, { Scale = 0.24, Density = 0.42, LifetimeScale = 0.38, SpeedScale = 0.55, PreserveSourceColor = true })
	elseif name == "Landing" then
		emitTemplate("SmokeLight", position, color, { Scale = 0.32, Density = 0.48, LifetimeScale = 0.42, SpeedScale = 0.8, PreserveSourceColor = true })
	elseif name == "HeavyLanding" then
		emitMany({
			{ Template = "ImpactMedium", Scale = 0.62, Density = 0.42, LifetimeScale = 0.6, SpeedScale = 0.5 },
			{ Template = "SmokeHeavy", Scale = 0.38, Density = 0.45, LifetimeScale = 0.42, SpeedScale = 0.8, PreserveSourceColor = true },
		}, position, color)
	elseif name == "BlinkOut" then
		emitTemplate("PortalA", position + Vector3.new(0, 0.7, 0), color, { Scale = 0.42, Density = 0.48, LifetimeScale = 0.5 })
	elseif name == "BlinkIn" then
		emitTemplate("PortalB", position + Vector3.new(0, 0.7, 0), color, { Scale = 0.34, Density = 0.4, LifetimeScale = 0.42 })
	end
end

-- Skill layers intentionally reuse only imported templates.  Slot one is an
-- impact-only accent; its normal hit confirmation is emitted by CombatHit.
local function playSkill(position, color, data)
	local slot = data.Slot
	if slot == 1 then
		if data.Hit then
			emitTemplate("ImpactLarge", position, color, {
				Scale = 0.72, Density = 0.42, LifetimeScale = 0.52, SpeedScale = 0.62,
			})
		end
		return true
	elseif slot == 3 then
		emitMany({
			{ Template = "GroundRing", Scale = 1.05, Density = 0.72, LifetimeScale = 0.42 },
			{ Template = "AuraBurst", Scale = 0.52, Density = 0.28, LifetimeScale = 0.42, SpeedScale = 0.48 },
		}, position, color)
		return true
	elseif slot == 4 then
		emitMany({
			{ Template = "GroundRing", Scale = 1.35, Density = 0.8, LifetimeScale = 0.5 },
			{ Template = "AuraBurst", Scale = 0.68, Density = 0.38, LifetimeScale = 0.46, SpeedScale = 0.5 },
			{ Template = "ChargeRing", Scale = 0.72, Density = 0.38, LifetimeScale = 0.55, SpeedScale = 0.5 },
		}, position, color)
		return true
	elseif slot == 5 then
		emitMany({
			{ Template = "GroundRing", Scale = 1.8, Density = 0.9, LifetimeScale = 0.55 },
			{ Template = "PortalA", Scale = 0.9, Density = 0.38, LifetimeScale = 0.38 },
			{ Template = "ShockBubble", Scale = 1.05, Density = 0.5, LifetimeScale = 0.5 },
			{ Template = "PowerVortex", Scale = 0.56, Density = 0.34, LifetimeScale = 0.18 },
			{ Template = "LightningArc", Scale = 0.9, Density = 0.45, LifetimeScale = 0.5, Brightness = 0.72 },
		}, position, color)
		return true
	end
	return false
end

local function play(kind, position, color, data)
	if typeof(position) ~= "Vector3" then return end
	data = data or {}
	local presetName = kind
	if kind == "Skill" then
		if playSkill(position, color, data) then return end
		local mode = data.Mode
		presetName = mode == "Projectile" and "Projectile"
			or mode == "Line" and "Beam"
			or mode == "Area" and "AoE"
			or mode == "Dash" and "Dash"
			or mode == "Awakening" and "Explosion"
			or "Cast"
	elseif kind == "Status" then
		presetName = "Status"
	end

	local preset = Presets.Get(presetName, {
		Color = typeof(color) == "Color3" and color or nil,
		Radius = data.Radius,
		Lifetime = data.Lifetime,
		Particles = data.Particles,
	})
	local effectColor = preset.Color

	if presetName == "Dash" or presetName == "Roll" or presetName == "Landing"
		or presetName == "HeavyLanding" or presetName == "BlinkOut" or presetName == "BlinkIn" then
		playMovement(presetName, position, effectColor, data)
		return
	end

	if presetName == "Aura" or presetName == "Status" or presetName == "PrestigeAura" then
		local auraTemplate = presetName == "PrestigeAura" and "PrestigeAura" or "AuraBase"
		loopTemplate(auraTemplate, position + Vector3.new(0, 0.45, 0), effectColor, {
			Scale = math.clamp((data.Scale or 1) * (presetName == "PrestigeAura" and 0.38 or 0.5), 0.22, 1),
			Intensity = math.clamp(data.Intensity or 0.6, 0.2, 1.5),
			Duration = data.Duration or preset.Lifetime,
			MaxRate = presetName == "PrestigeAura" and 1.35 or 2,
		})
		return
	end

	if Assets.Templates[presetName] then
		emitTemplate(presetName, position, effectColor, {
			Scale = data.Scale or 0.65,
			Density = data.Intensity or 0.6,
			LifetimeScale = data.LifetimeScale or 0.75,
			SpeedScale = data.SpeedScale or 0.75,
			Direction = typeof(data.Direction) == "Vector3" and data.Direction or nil,
			PreserveSourceColor = typeof(color) ~= "Color3",
		})
		return
	end

	local mapped = mappings[presetName] or mappings.Impact
	local direction = typeof(data.Direction) == "Vector3" and data.Direction or nil
	local common = {
		Scale = data.Scale or 1,
		Density = data.Intensity or 1,
		Direction = direction,
	}
	for _, item in ipairs(mapped) do
		local options = {}
		for key, value in pairs(item) do
			if key ~= "Template" then options[key] = value end
		end
		if common.Direction then options.Direction = common.Direction end
		if data.Scale then options.Scale = (options.Scale or 1) * data.Scale end
		if data.Intensity then options.Density = (options.Density or 1) * data.Intensity end
		emitTemplate(item.Template, position, effectColor, options)
	end
end

event.OnClientEvent:Connect(play)
localEvent.Event:Connect(play)
