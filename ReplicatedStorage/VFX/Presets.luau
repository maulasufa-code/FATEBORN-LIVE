local Presets = {
	HitLight = { Color = Color3.fromRGB(155, 190, 205), Radius = 3.4, Lifetime = 0.2, Particles = 5 },
	CombatHit = { Color = Color3.fromRGB(155, 190, 205), Radius = 3.4, Lifetime = 0.2, Particles = 5 },
	HitHeavy = { Color = Color3.fromRGB(116, 82, 145), Radius = 5.4, Lifetime = 0.32, Particles = 9 },
	HeavyHit = { Color = Color3.fromRGB(116, 82, 145), Radius = 5.4, Lifetime = 0.32, Particles = 9 },
	Crit = { Color = Color3.fromRGB(190, 231, 241), Radius = 5.8, Lifetime = 0.36, Particles = 11 },
	Block = { Color = Color3.fromRGB(99, 180, 255), Radius = 3.2, Lifetime = 0.22, Particles = 7 },
	Parry = { Color = Color3.fromRGB(255, 237, 139), Radius = 4.2, Lifetime = 0.26, Particles = 11 },
	GuardBreak = { Color = Color3.fromRGB(216, 146, 91), Radius = 5.8, Lifetime = 0.38, Particles = 13 },
	Dash = { Color = Color3.fromRGB(111, 186, 205), Radius = 3.2, Lifetime = 0.16, Particles = 5 },
	Roll = { Color = Color3.fromRGB(126, 112, 94), Radius = 2.2, Lifetime = 0.2, Particles = 4 },
	Landing = { Color = Color3.fromRGB(138, 120, 96), Radius = 2.8, Lifetime = 0.24, Particles = 5 },
	HeavyLanding = { Color = Color3.fromRGB(175, 127, 82), Radius = 5.4, Lifetime = 0.36, Particles = 10 },
	BlinkOut = { Color = Color3.fromRGB(76, 44, 112), Radius = 3.8, Lifetime = 0.24, Particles = 7 },
	BlinkIn = { Color = Color3.fromRGB(121, 77, 178), Radius = 4.2, Lifetime = 0.26, Particles = 8 },
	HitReaction = { Color = Color3.fromRGB(155, 24, 28), Radius = 3.8, Lifetime = 0.28, Particles = 7 },
	Cast = { Color = Color3.fromRGB(103, 78, 151), Radius = 4.2, Lifetime = 0.34, Particles = 6 },
	CastSmall = { Color = Color3.fromRGB(103, 78, 151), Radius = 3.2, Lifetime = 0.28, Particles = 4 },
	CastMedium = { Color = Color3.fromRGB(112, 82, 164), Radius = 5.2, Lifetime = 0.42, Particles = 7 },
	CastLarge = { Color = Color3.fromRGB(130, 91, 186), Radius = 8, Lifetime = 0.58, Particles = 10 },
	Projectile = { Color = Color3.fromRGB(114, 205, 255), Radius = 2.8, Lifetime = 0.3, Particles = 6 },
	Impact = { Color = Color3.fromRGB(255, 164, 72), Radius = 5.2, Lifetime = 0.36, Particles = 10 },
	ImpactMedium = { Color = Color3.fromRGB(84, 62, 132), Highlight = Color3.fromRGB(174, 228, 255), Core = Color3.fromRGB(17, 14, 28), Radius = 5.2, Lifetime = 0.48, Particles = 12 },
	ImpactLarge = { Color = Color3.fromRGB(177, 96, 54), Radius = 8.5, Lifetime = 0.58, Particles = 16 },
	AoE = { Color = Color3.fromRGB(102, 83, 153), Radius = 10, Lifetime = 0.55, Particles = 8 },
	Beam = { Color = Color3.fromRGB(128, 235, 255), Radius = 7, Lifetime = 0.34, Particles = 8 },
	Shield = { Color = Color3.fromRGB(105, 185, 255), Radius = 5, Lifetime = 0.4, Particles = 9 },
	Blink = { Color = Color3.fromRGB(183, 119, 255), Radius = 5, Lifetime = 0.3, Particles = 9 },
	Explosion = { Color = Color3.fromRGB(255, 112, 54), Radius = 10, Lifetime = 0.55, Particles = 18 },
	Status = { Color = Color3.fromRGB(123, 220, 116), Radius = 4, Lifetime = 0.9, Particles = 5 },
	Slash = { Color = Color3.fromRGB(147, 184, 201), Radius = 3.8, Lifetime = 0.16, Particles = 1 },
	HeavySlash = { Color = Color3.fromRGB(126, 91, 158), Radius = 5.2, Lifetime = 0.24, Particles = 1 },
	MagicSlash = { Color = Color3.fromRGB(116, 94, 177), Radius = 6, Lifetime = 0.36, Particles = 2 },
	Aura = { Color = Color3.fromRGB(78, 60, 122), Radius = 4, Lifetime = 1, Particles = 3 },
	PrestigeAura = { Color = Color3.fromRGB(226, 184, 92), Radius = 4.5, Lifetime = 1, Particles = 3 },
}

function Presets.Get(name, override)
	local base = Presets[name] or Presets.Impact
	local result = {}
	for key, value in pairs(base) do result[key] = value end
	for key, value in pairs(override or {}) do
		if value ~= nil then result[key] = value end
	end
	return result
end

return Presets
