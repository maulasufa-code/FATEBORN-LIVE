--!strict

local CharacterAttributes = require(script.Parent.Parent:WaitForChild("Contracts"):WaitForChild("CharacterAttributes"))

export type Context = {
	Player: Player?,
	Character: Model,
	Humanoid: Humanoid,
	Animator: Animator?,
	RootPart: BasePart,
	RaceName: string?,
	RaceCharacterProfile: string?,
	CharacterAttributes: { [string]: any },
	PlayerAttributes: { [string]: any },
}

local CharacterContext = {}

local function freezeSnapshot(attributes: { [string]: any }): { [string]: any }
	return table.freeze(table.clone(attributes))
end

local function readFirstString(instance: Instance, names: { string }): string?
	for _, name in ipairs(names) do
		local value = instance:GetAttribute(name)
		if type(value) == "string" and value ~= "" then
			return value
		end
	end
	return nil
end

-- Construction is observational: it performs no SetAttribute, parenting,
-- LoadCharacter, Animator creation, or other gameplay mutation.
function CharacterContext.Create(player: Player?, character: Model): (Context?, string?)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, "MissingHumanoid"
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, "MissingRootPart"
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	local raceName = readFirstString(character, CharacterAttributes.RaceReadOrder)
	local profileValue = character:GetAttribute(CharacterAttributes.Character.RaceCharacterProfile)
	local raceCharacterProfile = type(profileValue) == "string" and profileValue or nil

	local context: Context = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		Animator = animator,
		RootPart = root,
		RaceName = raceName,
		RaceCharacterProfile = raceCharacterProfile,
		CharacterAttributes = freezeSnapshot(character:GetAttributes()),
		PlayerAttributes = freezeSnapshot(player and player:GetAttributes() or {}),
	}

	return table.freeze(context), nil
end

function CharacterContext.ReadCharacterAttribute(context: Context, name: string): any
	return context.Character:GetAttribute(name)
end

function CharacterContext.ReadPlayerAttribute(context: Context, name: string): any
	return context.Player and context.Player:GetAttribute(name) or nil
end

return table.freeze(CharacterContext)
