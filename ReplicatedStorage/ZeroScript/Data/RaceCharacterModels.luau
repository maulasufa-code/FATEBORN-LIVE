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
		Animations = {
			Walk = {
				Id = "rbxassetid://92954261547077",
				SourceName = "Meshy_AI_Blocky_Wolf_Adventure_biped_Meshy_AI_Meshy_Merged_Animations_Walking",
			},
			Run = {
				Id = "rbxassetid://85618915186426",
				SourceName = "Meshy_AI_Blocky_Wolf_Adventure_biped_Meshy_AI_Meshy_Merged_Animations_Running",
			},
			Roll = {
				Id = "rbxassetid://137733801815535",
				SourceName = "Meshy_AI_Blocky_Wolf_Adventure_biped_Meshy_AI_Meshy_Merged_Animations_Roll_Dodge",
			},
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
