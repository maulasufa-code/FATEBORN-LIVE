--!strict

local AnimationCatalog = require(script.Parent:WaitForChild("AnimationCatalog"))

local aliases: { [string]: string } = table.freeze({
	Basic = "BasicAttack",
	M1 = "BasicAttack",
	Ability = "SpellCast",
	AbilityCast = "SpellCast",
	Skill = "SpellCast",
})

local AnimationResolver = {}

local function missing(raceName: string, requestedName: string, resolvedName: string, profileKey: string, reason: string)
	return table.freeze({
		RaceName = raceName,
		RequestedName = requestedName,
		Name = resolvedName,
		ProfileKey = profileKey,
		Available = false,
		Status = "Missing",
		Reason = reason,
	})
end

-- Returns a descriptor only. Playback remains owned by legacy PlayerMovement.
function AnimationResolver.Resolve(raceName: string, animationName: string)
	local resolvedName = aliases[animationName] or animationName
	local profileKey = AnimationCatalog.GetProfileKeyForRace(raceName)
	local profile = AnimationCatalog.GetProfile(profileKey)
	local descriptor = profile and profile.Animations[resolvedName]

	if not descriptor and profile and profile.FallbackProfile then
		local fallback = AnimationCatalog.GetProfile(profile.FallbackProfile)
		if fallback then
			descriptor = fallback.Animations[resolvedName]
			if descriptor then
				profileKey = profile.FallbackProfile
			end
		end
	end

	if not descriptor then
		return missing(
			raceName,
			animationName,
			resolvedName,
			profileKey,
			"The current legacy catalog has no animation asset or usable procedural cue for this state."
		)
	end

	if descriptor.Unclassified then
		return table.freeze({
			RaceName = raceName,
			RequestedName = animationName,
			Name = resolvedName,
			ProfileKey = profileKey,
			Available = false,
			Status = descriptor.Status,
			Reason = "The legacy loader explicitly skips this unclassified asset.",
			Descriptor = descriptor,
		})
	end

	if descriptor.Available == false then
		return table.freeze({
			RaceName = raceName,
			RequestedName = animationName,
			Name = resolvedName,
			ProfileKey = profileKey,
			Available = false,
			Status = descriptor.Status,
			Reason = descriptor.Reason,
			Descriptor = descriptor,
		})
	end

	return table.freeze({
		RaceName = raceName,
		RequestedName = animationName,
		Name = resolvedName,
		ProfileKey = profileKey,
		Available = true,
		Status = descriptor.Status or "Available",
		Descriptor = descriptor,
	})
end

function AnimationResolver.GetTuning(raceName: string)
	local profile = AnimationCatalog.GetProfile(AnimationCatalog.GetProfileKeyForRace(raceName))
	return profile and profile.Tuning or nil
end

return table.freeze(AnimationResolver)
