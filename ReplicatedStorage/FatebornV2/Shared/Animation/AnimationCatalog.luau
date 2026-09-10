--!strict

-- Data-only capture of animation facts used by the current PlayerMovement
-- controller and RaceCharacterModels. No Animation, AnimationTrack, or Animator
-- is created by this module.

export type AnimationDescriptor = {
	Id: string?,
	Source: string?,
	SourceName: string?,
	Kind: string?,
	Available: boolean?,
	Status: string?,
	Reason: string?,
	Unclassified: boolean?,
	ComboSlots: { string }?,
}

export type AnimationProfile = {
	Key: string,
	Animations: { [string]: AnimationDescriptor },
	FallbackProfile: string?,
	Tuning: { [string]: number }?,
}

local GenericBone: AnimationProfile = table.freeze({
	Key = "GenericBone",
	Animations = table.freeze({
		Walk = table.freeze({ Id = "rbxassetid://92954261547077", Source = "PlayerMovement.defaultBoneAnimations" }),
		Run = table.freeze({ Id = "rbxassetid://85618915186426", Source = "PlayerMovement.defaultBoneAnimations" }),
		Roll = table.freeze({ Id = "rbxassetid://137733801815535", Source = "PlayerMovement.defaultBoneAnimations" }),
	}),
})

local Human: AnimationProfile = table.freeze({
	Key = "Human",
	FallbackProfile = "GenericBone",
	Animations = table.freeze({
		BasicAttack = table.freeze({
			Kind = "ProceduralStudioSource",
			Available = false,
			Status = "PresentButUncued",
			Source = "StarterPlayer.StarterPlayerScripts.HumanBoxingBones",
			Reason = "The active server emits BasicAttackStartedAt only for Half-Beast.",
		}),
	}),
})

local HalfBeastAnimations: { [string]: AnimationDescriptor } = table.freeze({
	Idle = table.freeze({ Id = "rbxassetid://93023224155940", SourceName = "anims idle halfbeast" }),
	Walk = table.freeze({ Id = "rbxassetid://102484303929030", SourceName = "walking_man" }),
	Run = table.freeze({ Id = "rbxassetid://97338530445639", SourceName = "running" }),
	Jump = table.freeze({ Id = "rbxassetid://127530492522295", SourceName = "Regular_Jump" }),
	RunningJump = table.freeze({ Id = "rbxassetid://79379413190496", SourceName = "Jump_Run" }),
	Fall = table.freeze({ Id = "rbxassetid://107115183736873", SourceName = "Fall2" }),
	Climb = table.freeze({ Id = "rbxassetid://82555659345174", SourceName = "Fast_Stair_Climb" }),
	Swim = table.freeze({ Id = "rbxassetid://80726995435994", SourceName = "Swim_Forward" }),
	SwimIdle = table.freeze({ Id = "rbxassetid://132696654245914", SourceName = "Swim_Idle" }),
	BasicAttack = table.freeze({
		Id = "rbxassetid://102842280636366",
		SourceName = "400_withSkin_rigify_clip",
		ComboSlots = table.freeze({ "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack" }),
	}),
	Block = table.freeze({ Id = "rbxassetid://110775730964659", SourceName = "Block1" }),
	Guard = table.freeze({ Id = "rbxassetid://92635610215820", SourceName = "Look_from_Guard", Status = "UnusedToday" }),
	Roll = table.freeze({ Id = "rbxassetid://88464862837504", SourceName = "Roll_Dodge" }),
	Backstep = table.freeze({ Id = "rbxassetid://117701329736302", SourceName = "Hurry_Backward_2", Status = "UnusedToday" }),
	SpellCast = table.freeze({ Id = "rbxassetid://117062604126285", SourceName = "Spell_Cast_1" }),
	SlidingStumble = table.freeze({ Id = "rbxassetid://114357526081831", SourceName = "Sliding_Stumble" }),
	IdleStumble = table.freeze({ Id = "rbxassetid://98029398471017", SourceName = "Idle_Stumble" }),
	Drink = table.freeze({ Id = "rbxassetid://129082128797786", SourceName = "Stand_and_Drink", Status = "UnusedToday" }),
	Death = table.freeze({ Id = "rbxassetid://122434589194163", SourceName = "anims metong" }),
	UnclassifiedClip0 = table.freeze({
		Id = "rbxassetid://86915032860131",
		SourceName = "Armature|clip0|baselayer",
		Unclassified = true,
		Status = "IntentionallyNotLoaded",
	}),
})

local HalfBeast: AnimationProfile = table.freeze({
	Key = "HalfBeast",
	Animations = HalfBeastAnimations,
	Tuning = table.freeze({
		BasicAttackStartOffset = 0.15,
		BasicAttackPlaybackSpeed = 1.40,
		BasicAttackFadeIn = 0.03,
		RollFadeIn = 0.03,
		RollGameplayDuration = 0.60,
		RollPlaybackMultiplier = 1.00,
		IdleArmInward = 0.70,
		IdleForearmBend = 0.25,
	}),
})

local profiles: { [string]: AnimationProfile } = table.freeze({
	GenericBone = GenericBone,
	Human = Human,
	HalfBeast = HalfBeast,
})

local AnimationCatalog = {}

function AnimationCatalog.GetProfile(key: string)
	return profiles[key]
end

function AnimationCatalog.GetProfileKeyForRace(raceName: string): string
	if raceName == "Half-Beast" then
		return "HalfBeast"
	elseif raceName == "Human" then
		return "Human"
	end
	return "GenericBone"
end

return table.freeze(AnimationCatalog)
