local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- ============================================================
-- FATEBORN DYNAMIC DAY / NIGHT
-- 1 full in-game day = 20 real minutes.
-- Morning, noon, afternoon/golden hour, dusk and night each
-- have their own lighting + post-processing profile.
-- ============================================================

local FULL_DAY_SECONDS = 20 * 60
local START_TIME = 6.0
local UPDATE_INTERVAL = 0.08 -- ~12.5 updates/sec; smooth without spamming replication

Lighting.ClockTime = START_TIME
Lighting.GeographicLatitude = 23
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.45
Lighting.ShadowSoftness = 0.25

local function ensureEffect(className, name)
	local existing = Lighting:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting
	return effect
end

-- Reuse the Bloom that already exists in this place so two BloomEffects
-- do not stack on top of each other.
local bloom = Lighting:FindFirstChild("Bloom")
if not bloom or not bloom:IsA("BloomEffect") then
	bloom = ensureEffect("BloomEffect", "Bloom")
end
bloom.Enabled = true

local color = ensureEffect("ColorCorrectionEffect", "FatebornColor")
color.Enabled = true

local sunRays = ensureEffect("SunRaysEffect", "FatebornSunRays")
sunRays.Enabled = true

local atmosphere = ensureEffect("Atmosphere", "FatebornAtmosphere")

-- Each keyframe is blended into the next one. Add more keyframes here
-- if you want a more stylized transition around a specific hour.
local phases = {
	{
		Time = 0.0, Name = "MIDNIGHT",
		Brightness = 0.95, Exposure = -0.58,
		Ambient = Color3.fromRGB(23, 29, 48), Outdoor = Color3.fromRGB(35, 43, 66),
		FogColor = Color3.fromRGB(38, 48, 72), FogEnd = 1050,
		AtmosColor = Color3.fromRGB(103, 124, 170), AtmosDecay = Color3.fromRGB(48, 58, 88),
		Density = 0.37, Haze = 2.2, Glare = 0.00,
		Tint = Color3.fromRGB(174, 194, 255), Saturation = -0.12, Contrast = 0.12,
		BloomIntensity = 0.16, BloomSize = 28, BloomThreshold = 1.65,
		SunIntensity = 0.00, SunSpread = 0.70,
	},
	{
		Time = 4.4, Name = "PRE_DAWN",
		Brightness = 1.05, Exposure = -0.43,
		Ambient = Color3.fromRGB(38, 43, 66), Outdoor = Color3.fromRGB(57, 62, 84),
		FogColor = Color3.fromRGB(79, 80, 106), FogEnd = 1200,
		AtmosColor = Color3.fromRGB(126, 131, 173), AtmosDecay = Color3.fromRGB(66, 67, 96),
		Density = 0.34, Haze = 2.0, Glare = 0.00,
		Tint = Color3.fromRGB(199, 203, 255), Saturation = -0.08, Contrast = 0.09,
		BloomIntensity = 0.14, BloomSize = 28, BloomThreshold = 1.70,
		SunIntensity = 0.00, SunSpread = 0.70,
	},
	{
		Time = 5.5, Name = "DAWN",
		Brightness = 1.55, Exposure = -0.12,
		Ambient = Color3.fromRGB(91, 74, 76), Outdoor = Color3.fromRGB(133, 105, 93),
		FogColor = Color3.fromRGB(185, 139, 123), FogEnd = 1450,
		AtmosColor = Color3.fromRGB(217, 163, 139), AtmosDecay = Color3.fromRGB(102, 91, 115),
		Density = 0.31, Haze = 1.8, Glare = 0.05,
		Tint = Color3.fromRGB(255, 219, 194), Saturation = 0.03, Contrast = 0.07,
		BloomIntensity = 0.22, BloomSize = 34, BloomThreshold = 1.35,
		SunIntensity = 0.045, SunSpread = 0.82,
	},
	{
		Time = 7.0, Name = "MORNING",
		Brightness = 2.15, Exposure = 0.03,
		Ambient = Color3.fromRGB(108, 108, 116), Outdoor = Color3.fromRGB(152, 146, 132),
		FogColor = Color3.fromRGB(190, 207, 221), FogEnd = 1850,
		AtmosColor = Color3.fromRGB(191, 215, 235), AtmosDecay = Color3.fromRGB(115, 131, 157),
		Density = 0.285, Haze = 1.45, Glare = 0.10,
		Tint = Color3.fromRGB(255, 242, 222), Saturation = 0.05, Contrast = 0.04,
		BloomIntensity = 0.18, BloomSize = 30, BloomThreshold = 1.45,
		SunIntensity = 0.075, SunSpread = 0.84,
	},
	{
		Time = 10.0, Name = "LATE_MORNING",
		Brightness = 2.65, Exposure = 0.12,
		Ambient = Color3.fromRGB(121, 123, 130), Outdoor = Color3.fromRGB(174, 170, 157),
		FogColor = Color3.fromRGB(200, 218, 232), FogEnd = 2200,
		AtmosColor = Color3.fromRGB(196, 221, 241), AtmosDecay = Color3.fromRGB(126, 144, 168),
		Density = 0.26, Haze = 1.20, Glare = 0.15,
		Tint = Color3.fromRGB(255, 250, 238), Saturation = 0.07, Contrast = 0.03,
		BloomIntensity = 0.14, BloomSize = 26, BloomThreshold = 1.60,
		SunIntensity = 0.095, SunSpread = 0.88,
	},
	{
		Time = 12.5, Name = "NOON",
		Brightness = 3.00, Exposure = 0.18,
		Ambient = Color3.fromRGB(132, 134, 142), Outdoor = Color3.fromRGB(187, 185, 174),
		FogColor = Color3.fromRGB(205, 224, 239), FogEnd = 2450,
		AtmosColor = Color3.fromRGB(199, 224, 244), AtmosDecay = Color3.fromRGB(132, 151, 178),
		Density = 0.245, Haze = 1.05, Glare = 0.20,
		Tint = Color3.fromRGB(255, 253, 246), Saturation = 0.06, Contrast = 0.02,
		BloomIntensity = 0.11, BloomSize = 24, BloomThreshold = 1.72,
		SunIntensity = 0.115, SunSpread = 0.90,
	},
	{
		Time = 15.2, Name = "AFTERNOON",
		Brightness = 2.55, Exposure = 0.09,
		Ambient = Color3.fromRGB(126, 114, 110), Outdoor = Color3.fromRGB(178, 154, 133),
		FogColor = Color3.fromRGB(221, 199, 177), FogEnd = 2100,
		AtmosColor = Color3.fromRGB(231, 205, 177), AtmosDecay = Color3.fromRGB(149, 128, 119),
		Density = 0.27, Haze = 1.35, Glare = 0.16,
		Tint = Color3.fromRGB(255, 235, 210), Saturation = 0.09, Contrast = 0.05,
		BloomIntensity = 0.16, BloomSize = 29, BloomThreshold = 1.50,
		SunIntensity = 0.095, SunSpread = 0.88,
	},
	{
		Time = 17.3, Name = "GOLDEN_HOUR",
		Brightness = 2.05, Exposure = -0.02,
		Ambient = Color3.fromRGB(117, 84, 75), Outdoor = Color3.fromRGB(168, 115, 86),
		FogColor = Color3.fromRGB(231, 157, 121), FogEnd = 1725,
		AtmosColor = Color3.fromRGB(241, 164, 119), AtmosDecay = Color3.fromRGB(128, 86, 87),
		Density = 0.305, Haze = 1.85, Glare = 0.12,
		Tint = Color3.fromRGB(255, 197, 158), Saturation = 0.14, Contrast = 0.09,
		BloomIntensity = 0.28, BloomSize = 38, BloomThreshold = 1.20,
		SunIntensity = 0.075, SunSpread = 0.84,
	},
	{
		Time = 18.5, Name = "DUSK",
		Brightness = 1.50, Exposure = -0.22,
		Ambient = Color3.fromRGB(76, 57, 72), Outdoor = Color3.fromRGB(111, 76, 87),
		FogColor = Color3.fromRGB(142, 102, 124), FogEnd = 1375,
		AtmosColor = Color3.fromRGB(181, 119, 137), AtmosDecay = Color3.fromRGB(82, 64, 92),
		Density = 0.34, Haze = 2.15, Glare = 0.04,
		Tint = Color3.fromRGB(227, 184, 212), Saturation = 0.02, Contrast = 0.12,
		BloomIntensity = 0.24, BloomSize = 35, BloomThreshold = 1.28,
		SunIntensity = 0.025, SunSpread = 0.78,
	},
	{
		Time = 20.0, Name = "NIGHT",
		Brightness = 1.05, Exposure = -0.48,
		Ambient = Color3.fromRGB(31, 35, 55), Outdoor = Color3.fromRGB(47, 53, 75),
		FogColor = Color3.fromRGB(50, 60, 85), FogEnd = 1125,
		AtmosColor = Color3.fromRGB(111, 132, 174), AtmosDecay = Color3.fromRGB(50, 60, 91),
		Density = 0.365, Haze = 2.25, Glare = 0.00,
		Tint = Color3.fromRGB(181, 199, 255), Saturation = -0.10, Contrast = 0.13,
		BloomIntensity = 0.18, BloomSize = 30, BloomThreshold = 1.55,
		SunIntensity = 0.00, SunSpread = 0.70,
	},
	{
		Time = 24.0, Name = "MIDNIGHT",
		Brightness = 0.95, Exposure = -0.58,
		Ambient = Color3.fromRGB(23, 29, 48), Outdoor = Color3.fromRGB(35, 43, 66),
		FogColor = Color3.fromRGB(38, 48, 72), FogEnd = 1050,
		AtmosColor = Color3.fromRGB(103, 124, 170), AtmosDecay = Color3.fromRGB(48, 58, 88),
		Density = 0.37, Haze = 2.2, Glare = 0.00,
		Tint = Color3.fromRGB(174, 194, 255), Saturation = -0.12, Contrast = 0.12,
		BloomIntensity = 0.16, BloomSize = 28, BloomThreshold = 1.65,
		SunIntensity = 0.00, SunSpread = 0.70,
	},
}

local function lerpNumber(a, b, alpha)
	return a + (b - a) * alpha
end

local function findPhase(time)
	for index = 1, #phases - 1 do
		local a = phases[index]
		local b = phases[index + 1]
		if time >= a.Time and time <= b.Time then
			return a, b
		end
	end
	return phases[#phases - 1], phases[#phases]
end

local currentPhaseName = nil

local function applyLighting(time)
	local a, b = findPhase(time)
	local alpha = math.clamp((time - a.Time) / math.max(0.001, b.Time - a.Time), 0, 1)
	-- Smoothstep keeps transitions soft when entering/leaving a keyframe.
	alpha = alpha * alpha * (3 - 2 * alpha)

	Lighting.Brightness = lerpNumber(a.Brightness, b.Brightness, alpha)
	Lighting.ExposureCompensation = lerpNumber(a.Exposure, b.Exposure, alpha)
	Lighting.Ambient = a.Ambient:Lerp(b.Ambient, alpha)
	Lighting.OutdoorAmbient = a.Outdoor:Lerp(b.Outdoor, alpha)
	Lighting.FogColor = a.FogColor:Lerp(b.FogColor, alpha)
	Lighting.FogStart = 0
	Lighting.FogEnd = lerpNumber(a.FogEnd, b.FogEnd, alpha)

	atmosphere.Color = a.AtmosColor:Lerp(b.AtmosColor, alpha)
	atmosphere.Decay = a.AtmosDecay:Lerp(b.AtmosDecay, alpha)
	atmosphere.Density = lerpNumber(a.Density, b.Density, alpha)
	atmosphere.Haze = lerpNumber(a.Haze, b.Haze, alpha)
	atmosphere.Glare = lerpNumber(a.Glare, b.Glare, alpha)
	atmosphere.Offset = 0.05

	color.TintColor = a.Tint:Lerp(b.Tint, alpha)
	color.Saturation = lerpNumber(a.Saturation, b.Saturation, alpha)
	color.Contrast = lerpNumber(a.Contrast, b.Contrast, alpha)
	color.Brightness = 0

	bloom.Intensity = lerpNumber(a.BloomIntensity, b.BloomIntensity, alpha)
	bloom.Size = lerpNumber(a.BloomSize, b.BloomSize, alpha)
	bloom.Threshold = lerpNumber(a.BloomThreshold, b.BloomThreshold, alpha)

	sunRays.Intensity = lerpNumber(a.SunIntensity, b.SunIntensity, alpha)
	sunRays.Spread = lerpNumber(a.SunSpread, b.SunSpread, alpha)

	if currentPhaseName ~= a.Name then
		currentPhaseName = a.Name
		Lighting:SetAttribute("TimePhase", currentPhaseName)
	end
end

applyLighting(Lighting.ClockTime)

local accumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
	accumulator += deltaTime
	if accumulator < UPDATE_INTERVAL then
		return
	end

	local step = accumulator
	accumulator = 0
	Lighting.ClockTime = (Lighting.ClockTime + step * 24 / FULL_DAY_SECONDS) % 24
	applyLighting(Lighting.ClockTime)
end)
