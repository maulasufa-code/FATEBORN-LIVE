-- RaceCharacterModels
-- Per-race character templates and animation overrides. Races without an
-- entry continue through Roblox's normal character and animation flow.

local profiles = {
	["Half-Beast"] = {
		AssetId = 92882444915511,
		TemplateFolder = "PlayerAssetSources",
		TemplateName = "HalfBeastCharacter",
		CharacterModelName = "Char half beast",
		BoneCharacter = true,
		AnimationTuning = {
			BasicAttackStartOffset = 0.15,
			BasicAttackPlaybackSpeed = 1.40,
			BasicAttackFadeIn = 0.03,
			RollFadeIn = 0.03,
			RollGameplayDuration = 0.60,
			RollPlaybackMultiplier = 1.00,
			-- The source idle is close to a T-pose. These bring both upper arms
			-- down alongside the torso and keep the hands near the hips.
			IdleArmInward = 0.70,
			IdleForearmBend = 0.25,
		},
		Animations = {
			-- Locomotion
			Idle = {
				Id = "rbxassetid://93023224155940",
				SourceName = "anims idle halfbeast",
			},
			Walk = {
				Id = "rbxassetid://102484303929030",
				SourceName = "walking_man",
			},
			Run = {
				Id = "rbxassetid://97338530445639",
				SourceName = "running",
			},
			Jump = { Id = "rbxassetid://127530492522295", SourceName = "Regular_Jump" },
			RunningJump = { Id = "rbxassetid://79379413190496", SourceName = "Jump_Run" },
			Fall = { Id = "rbxassetid://107115183736873", SourceName = "Fall2" },
			Climb = { Id = "rbxassetid://82555659345174", SourceName = "Fast_Stair_Climb" },
			Swim = { Id = "rbxassetid://80726995435994", SourceName = "Swim_Forward" },
			SwimIdle = { Id = "rbxassetid://132696654245914", SourceName = "Swim_Idle" },

			-- Combat and reactions. BasicAttack is intentionally one shared clip
			-- until individual Half-Beast combo clips are supplied.
			BasicAttack = {
				Id = "rbxassetid://102842280636366",
				SourceName = "400_withSkin_rigify_clip",
				ComboSlots = { "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack", "BasicAttack" },
			},
			Block = { Id = "rbxassetid://110775730964659", SourceName = "Block1" },
			Guard = { Id = "rbxassetid://92635610215820", SourceName = "Look_from_Guard" },
			Roll = {
				Id = "rbxassetid://88464862837504",
				SourceName = "Roll_Dodge",
			},
			Backstep = { Id = "rbxassetid://117701329736302", SourceName = "Hurry_Backward_2" },
			SpellCast = { Id = "rbxassetid://117062604126285", SourceName = "Spell_Cast_1" },
			SlidingStumble = { Id = "rbxassetid://114357526081831", SourceName = "Sliding_Stumble" },
			IdleStumble = { Id = "rbxassetid://98029398471017", SourceName = "Idle_Stumble" },
			Drink = { Id = "rbxassetid://129082128797786", SourceName = "Stand_and_Drink" },
			Death = { Id = "rbxassetid://122434589194163", SourceName = "anims metong" },

			-- The role of this asset is not confirmed. It is deliberately not
			-- loaded or selected by the animation controller.
			UnclassifiedClip0 = { Id = "rbxassetid://86915032860131", SourceName = "Armature|clip0|baselayer", Unclassified = true },
		},
	},
}

local RaceCharacterModels = {}

function RaceCharacterModels.getProfile(raceName)
	return profiles[raceName]
end

function RaceCharacterModels.hasCustomModel(raceName)
	return profiles[raceName] ~= nil
end

return RaceCharacterModels
