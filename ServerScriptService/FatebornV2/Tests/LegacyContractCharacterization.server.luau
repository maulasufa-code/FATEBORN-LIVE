--!strict

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function countCommunicationInstances(): number
	local count = 0
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		if descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction") then
			count += 1
		end
	end
	return count
end

local communicationsBefore = countCommunicationInstances()
local shared = ReplicatedStorage:WaitForChild("FatebornV2"):WaitForChild("Shared")
local ActionIds = require(shared.Contracts.ActionIds)
local CharacterAttributes = require(shared.Contracts.CharacterAttributes)
local StateKeys = require(shared.Contracts.CharacterStateKeys)
local CharacterContext = require(shared.Character.CharacterContext)
local CharacterState = require(shared.Character.CharacterState)
local RaceRegistry = require(shared.Race.RaceRegistry)
local RaceLoader = require(shared.Race.RaceLoader)
local AnimationCatalog = require(shared.Animation.AnimationCatalog)
local AnimationResolver = require(shared.Animation.AnimationResolver)
local StatCalculator = require(shared.Stats.StatCalculator)
local communicationsAfter = countCommunicationInstances()

local Config = require(ReplicatedStorage.Shared.Config)
local M1Config = require(ReplicatedStorage.Combat.M1Config)
local RaceCharacterModels = require(ReplicatedStorage.ZeroScript.Data.RaceCharacterModels)
local LegacyRaceData = require(ReplicatedStorage.ZeroScript.Data.RaceData)

local passed = 0
local failures = {}

local function check(name: string, callback: () -> ())
	local ok, message = pcall(callback)
	if ok then
		passed += 1
	else
		table.insert(failures, string.format("%s: %s", name, tostring(message)))
	end
end

local function expectEqual(actual: any, expected: any, label: string?)
	assert(actual == expected, string.format("%s expected %s, got %s", label or "value", tostring(expected), tostring(actual)))
end

local function expectNear(actual: number, expected: number, epsilon: number, label: string?)
	assert(math.abs(actual - expected) <= epsilon, string.format("%s expected %.8f, got %.8f", label or "value", expected, actual))
end

local function contains(values: { string }, target: string): boolean
	return table.find(values, target) ~= nil
end

check("contract constants preserve current names", function()
	expectEqual(ActionIds.Canonical.Basic, "Basic")
	expectEqual(ActionIds.Canonical.M1, "Basic")
	expectEqual(ActionIds.LegacyContracts.FatebornAction.Sprint, "Sprint")
	expectEqual(ActionIds.LegacyContracts.PlayerMovement.Sprint, "Sprint")
	expectEqual(ActionIds.LegacyContracts.PlayerMovement.Roll, "Roll")
	expectEqual(CharacterAttributes.Character.RollStartedAt, "RollStartedAt")
	expectEqual(CharacterAttributes.Player.MaxStamina, "MaxStamina")
	expectEqual(StateKeys.Condition.Stagger, "Stagger")
end)

check("requiring V2 modules creates no communication instances", function()
	expectEqual(communicationsAfter, communicationsBefore)
end)

check("Human uses current generic fallback", function()
	local resolution = RaceLoader.Resolve("Human")
	expectEqual(resolution.Resolved, true)
	expectEqual(resolution.Character.Mode, "GenericStarterCharacter")
	expectEqual(resolution.Character.BoneCharacter, true)
	expectEqual(resolution.UsesGenericStarterFallback, true)
	expectEqual(RaceLoader.HasCustomPackage("Human"), false)
end)

check("Half-Beast matches the current custom package", function()
	local resolution = RaceLoader.Resolve("Half-Beast")
	local legacy = RaceCharacterModels.getProfile("Half-Beast")
	expectEqual(resolution.Character.Mode, "CustomGraftedPackage")
	expectEqual(resolution.Character.AssetId, legacy.AssetId)
	expectEqual(resolution.Character.TemplateFolder, legacy.TemplateFolder)
	expectEqual(resolution.Character.TemplateName, legacy.TemplateName)
	expectEqual(resolution.Character.CharacterModelName, legacy.CharacterModelName)
	expectEqual(RaceLoader.HasCustomPackage("Half-Beast"), true)
end)

check("race source divergence remains visible", function()
	local report = RaceRegistry.CompareLegacySources(Config.Pools.Race, LegacyRaceData, M1Config.Races)
	expectEqual(#report.ActiveRoster, 35)
	expectEqual(#report.LegacyRoster, 35)
	expectEqual(#report.ActiveMissingFromLegacy, 0)
	expectEqual(#report.LegacyMissingFromActive, 0)
	assert(contains(report.ActiveMissingFromM1, "Elementalborn"))
	assert(contains(report.M1MissingFromActive, "Seraph"))
	expectEqual(report.SchemaDivergence, true)
end)

check("Half-Beast animation IDs and tuning match legacy", function()
	local legacy = RaceCharacterModels.getProfile("Half-Beast")
	local profile = AnimationCatalog.GetProfile("HalfBeast")
	expectEqual(profile.Animations.Idle.Id, legacy.Animations.Idle.Id)
	expectEqual(profile.Animations.BasicAttack.Id, legacy.Animations.BasicAttack.Id)
	expectEqual(profile.Animations.Roll.Id, legacy.Animations.Roll.Id)
	expectNear(profile.Tuning.BasicAttackPlaybackSpeed, legacy.AnimationTuning.BasicAttackPlaybackSpeed, 0.000001)
	expectNear(profile.Tuning.RollGameplayDuration, legacy.AnimationTuning.RollGameplayDuration, 0.000001)
end)

check("generic bone fallback IDs are preserved", function()
	local walk = AnimationResolver.Resolve("Human", "Walk")
	local run = AnimationResolver.Resolve("Goblin", "Run")
	local roll = AnimationResolver.Resolve("Human", "Roll")
	expectEqual(walk.Available, true)
	expectEqual(walk.Descriptor.Id, "rbxassetid://92954261547077")
	expectEqual(run.Descriptor.Id, "rbxassetid://85618915186426")
	expectEqual(roll.Descriptor.Id, "rbxassetid://137733801815535")
end)

check("missing and uncued animations are explicit", function()
	local genericJump = AnimationResolver.Resolve("Human", "Jump")
	local humanBasic = AnimationResolver.Resolve("Human", "Basic")
	local unclassified = AnimationResolver.Resolve("Half-Beast", "UnclassifiedClip0")
	expectEqual(genericJump.Available, false)
	expectEqual(genericJump.Status, "Missing")
	expectEqual(humanBasic.Available, false)
	expectEqual(humanBasic.Status, "PresentButUncued")
	expectEqual(unclassified.Available, false)
	expectEqual(unclassified.Status, "IntentionallyNotLoaded")
end)

check("CharacterContext construction is read-only", function()
	local character = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = character
	character:SetAttribute("Race", "Human")
	character:SetAttribute("Sprinting", true)
	local before = character:GetAttributes()

	local context, reason = CharacterContext.Create(nil, character)
	assert(context, reason)
	expectEqual(context.Character, character)
	expectEqual(context.Humanoid, humanoid)
	expectEqual(context.RootPart, root)
	expectEqual(context.RaceName, "Human")

	local after = character:GetAttributes()
	for key, value in pairs(before) do
		expectEqual(after[key], value, key)
	end
	for key in pairs(after) do
		assert(before[key] ~= nil, "CharacterContext added attribute " .. key)
	end
	character:Destroy()
end)

check("CharacterState mirrors representative signals", function()
	local signals = {
		HumanoidState = "Running",
		Health = 100,
		HorizontalSpeed = 18,
		VerticalSpeed = 0,
		IsAirborne = false,
		Sprinting = true,
		RollStartedAt = 99.8,
		Blocking = true,
		BasicAttackStartedAt = 98,
		BasicAttackComboIndex = 3,
		SkillCastStartedAt = nil,
		HitReaction = nil,
		HitReactionStartedAt = nil,
		HitReactionUntil = nil,
		Staggered = false,
	}
	local snapshot = CharacterState.ResolveSignals(signals, 100)
	expectEqual(snapshot.Locomotion, "Run")
	expectEqual(snapshot.Action, "Roll")
	expectEqual(snapshot.Condition, "None")
	expectEqual(snapshot.LastActionCue.Name, "Basic")
	expectEqual(snapshot.LastActionCue.Active, false)

	signals.HitReaction = "Stagger"
	signals.HitReactionUntil = 101
	signals.Staggered = true
	local staggered = CharacterState.ResolveSignals(signals, 100)
	expectEqual(staggered.Condition, "Stagger")
	expectEqual(staggered.Action, "None")
end)

check("StatCalculator reproduces legacy formulas", function()
	local profile = {
		Level = 10,
		Mastery = 20,
		Fate = {
			Race = { Power = 1.03 },
			Strength = { Power = 1.20 },
			Speed = { Power = 1.10 },
			Durability = { Power = 1.25 },
			Stamina = { Power = 1.30 },
			Ability = { Power = 1.18 },
			FightingMastery = { Power = 1.30 },
		},
	}
	local expectedDisplayMultiplier = (1 + 0.03 * 0.16)
		* (1 + 0.20 * 0.16)
		* (1 + 0.10 * 0.16)
		* (1 + 0.25 * 0.16)
		* (1 + 0.30 * 0.16)
		* (1 + 0.18 * 0.16)
		* (1 + 0.30 * 0.16)
	expectEqual(StatCalculator.ComputeDisplayedPower(profile), math.floor(1000 * expectedDisplayMultiplier))
	expectNear(StatCalculator.ComputeBaseDamage(profile), 50.4 * 1.20 * 1.18, 0.000001)
	local stats = StatCalculator.ComputeCharacterStats(profile, 100)
	expectEqual(stats.MaxHealth, math.floor(170 * 1.25))
	expectEqual(stats.MaxStamina, 130)
	expectNear(stats.WalkSpeed, 15.4, 0.000001)
	expectNear(stats.JumpPower, 51.4, 0.000001)
	expectNear(StatCalculator.GetSpeedAttackInterval(1.10), M1Config.GetSpeedAttackInterval({
		GetAttribute = function(_, name)
			return name == "SpeedPower" and 1.10 or nil
		end,
	}), 0.000001)
end)

check("Race Power/display Power distinction is preserved", function()
	local human = { Level = 10, Mastery = 20, Fate = { Race = { Power = 1.00 }, Strength = { Power = 1 }, Ability = { Power = 1 } } }
	local halfBeast = { Level = 10, Mastery = 20, Fate = { Race = { Power = 1.03 }, Strength = { Power = 1 }, Ability = { Power = 1 } } }
	assert(StatCalculator.ComputeDisplayedPower(halfBeast) > StatCalculator.ComputeDisplayedPower(human))
	expectNear(StatCalculator.ComputeBaseDamage(halfBeast), StatCalculator.ComputeBaseDamage(human), 0.000001)
	expectNear(
		StatCalculator.ComputeBasicDamage(halfBeast, 1.30, 1),
		StatCalculator.ComputeBasicDamage(human, 1.30, 1),
		0.000001
	)
end)

if #failures > 0 then
	error("FATEBORN V2 M1 characterization failed:\n- " .. table.concat(failures, "\n- "))
end

print(string.format("FATEBORN V2 M1 characterization PASS (%d checks)", passed))
