local Players = game:GetService("Players")

-- Do not create a gameplay character before the character-select/intro flow completes.
Players.CharacterAutoLoads = false
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RaceCharacterModels = require(
	ReplicatedStorage:WaitForChild("ZeroScript"):WaitForChild("Data"):WaitForChild("RaceCharacterModels")
)
local HitReactionSystem = require(ServerStorage:WaitForChild("ZeroScript"):WaitForChild("HitReactionSystem"))
local EnemyAISystem = require(ServerStorage:WaitForChild("ZeroScript"):WaitForChild("EnemyAISystem"))
local rng = Random.new()

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "FatebornRemotes"
remoteFolder.Parent = ReplicatedStorage

local function remote(className, name)
	local object = Instance.new(className)
	object.Name = name
	object.Parent = remoteFolder
	return object
end

local requestState = remote("RemoteFunction", "RequestState")
local awakenFate = remote("RemoteFunction", "AwakenFate")
local rerollFate = remote("RemoteFunction", "RerollFate")
local inspectPlayer = remote("RemoteFunction", "InspectPlayer")
local manageCharacters = remote("RemoteFunction", "ManageCharacters")
local actionRemote = remote("RemoteEvent", "Action")
local stateRemote = remote("RemoteEvent", "State")
local announcementRemote = remote("RemoteEvent", "Announcement")
local defenseRemote = ReplicatedStorage:FindFirstChild("CombatDefenseEvent")
if not defenseRemote then
	defenseRemote = Instance.new("RemoteEvent")
	defenseRemote.Name = "CombatDefenseEvent"
	defenseRemote.Parent = ReplicatedStorage
end
-- VFX is partly Studio-only content. Rojo may sync the Lua modules while
-- leaving the runtime remotes absent, so bootstrap only the required channels.
local vfxFolder = ReplicatedStorage:FindFirstChild("VFX")
if not vfxFolder then
	vfxFolder = Instance.new("Folder")
	vfxFolder.Name = "VFX"
	vfxFolder.Parent = ReplicatedStorage
end
local vfxRemote = vfxFolder:FindFirstChild("VFXEvent")
if not vfxRemote then
	vfxRemote = Instance.new("RemoteEvent")
	vfxRemote.Name = "VFXEvent"
	vfxRemote.Parent = vfxFolder
end
local vfxLocal = vfxFolder:FindFirstChild("VFXLocal")
if not vfxLocal then
	vfxLocal = Instance.new("BindableEvent")
	vfxLocal.Name = "VFXLocal"
	vfxLocal.Parent = vfxFolder
end

local function dispatchVFX(effectName, position, color, data)
	vfxRemote:FireAllClients(effectName, position, color, data)
end

local store
local storeReady, storeResult = pcall(function()
	return DataStoreService:GetDataStore("FATEBORN_CharacterSlots_v2")
end)
if storeReady then
	store = storeResult
else
	warn("FATEBORN DataStore unavailable; using temporary Studio session data.", storeResult)
end
local profiles = {}
local accounts = {}
local activeSlots = {}
local cooldowns = {}
local respawnQueued = {}
local boostCache = {}
local enemies = {}
local spawnDefinitions = {}
local worldFolder

local DEFAULT = {
	Version = 1,
	Level = 1,
	Exp = 0,
	Gold = 0,
	Essence = 0,
	Fragments = 0, -- Legacy currency; no longer grants rerolls
	RerollTickets = 0,
	BossMaterials = 0,
	Mastery = 0,
	Kills = 0,
	BossKills = 0,
	Spins = 0,
	Pity = {},
	Fate = {},
	Quest = { Kind = "Defeat", Target = 5, Progress = 0, Reward = 18 },
	SeenIntro = false,
	QuadBoostUntil = 0,
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = deepCopy(item)
	end
	return result
end

local function mergeDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = deepCopy(value)
		elseif type(value) == "table" and type(target[key]) == "table" then
			mergeDefaults(target[key], value)
		end
	end
	return target
end

local function weightedChoice(pool, pity)
	local buckets = {}

	for _, rarityName in ipairs(Config.RarityOrder) do
		buckets[rarityName] = {}
	end

	for _, item in ipairs(pool) do
		local rarityName = item.Rarity or "Common"
		if buckets[rarityName] then
			table.insert(buckets[rarityName], item)
		end
	end

	local total = 0
	local rarityWeights = {}

	for _, rarityName in ipairs(Config.RarityOrder) do
		local bucket = buckets[rarityName]
		if bucket and #bucket > 0 then
			local rarity = Config.Rarity[rarityName] or Config.Rarity.Common
			local weight = rarity.Weight

			if pity and pity >= Config.PityThreshold and rarity.Rank >= 3 then
				weight *= 4
			elseif pity and pity >= math.floor(Config.PityThreshold * 0.6) and rarity.Rank >= 2 then
				weight *= 1.8
			end

			rarityWeights[rarityName] = weight
			total += weight
		end
	end

	local roll = rng:NextNumber(0, total)

	for _, rarityName in ipairs(Config.RarityOrder) do
		local weight = rarityWeights[rarityName] or 0
		roll -= weight
		if roll <= 0 then
			local bucket = buckets[rarityName]
			return bucket[rng:NextInteger(1, #bucket)]
		end
	end

	for _, rarityName in ipairs(Config.RarityOrder) do
		local bucket = buckets[rarityName]
		if bucket and #bucket > 0 then
			return bucket[1]
		end
	end

	return pool[1]
end

local function rollCategory(profile, category, countSpin)
	local pool = Config.Pools[category]
	if not pool then
		return nil
	end
	local pity = profile.Pity[category] or 0
	local item = weightedChoice(pool, pity)
	profile.Fate[category] = deepCopy(item)
	if countSpin ~= false then
		profile.Spins += 1
	end
	if Config.GetRarityRank(item.Rarity) >= 3 then
		profile.Pity[category] = 0
	else
		profile.Pity[category] = pity + 1
	end
	return profile.Fate[category]
end

local function ensureFate(profile, countSpin)
	for _, category in ipairs(Config.Categories) do
		if not profile.Fate[category] then
			rollCategory(profile, category, countSpin)
		end
	end
end

local function expForLevel(level)
	return math.floor(80 + level ^ 1.55 * 32)
end

local function computePower(profile)
	local multiplier = 1
	for _, category in ipairs(Config.Categories) do
		local fate = profile.Fate[category]
		if fate then
			multiplier *= 1 + ((fate.Power or 1) - 1) * 0.16
		end
	end
	return math.floor((110 + profile.Level * 82 + profile.Mastery * 3.5) * multiplier)
end

local function rarityScore(profile)
	local bestName = "Common"
	local best = 1
	for _, fate in pairs(profile.Fate) do
		local rank = Config.GetRarityRank(fate.Rarity)
		if rank > best then
			best = rank
			bestName = fate.Rarity
		end
	end
	return bestName, best
end

local function categoryUnlocked(profile, category)
	local requirement = Config.FateUnlocks[category]
	if not requirement or requirement.Kind == "Start" then
		return category == "Race"
	end
	local progress = requirement.Kind == "Level" and profile.Level
		or requirement.Kind == "Kills" and profile.Kills
		or requirement.Kind == "BossKills" and profile.BossKills
		or requirement.Kind == "Mastery" and profile.Mastery
		or 0
	return progress >= requirement.Value
end

local function unlockedCategories(profile)
	local result = {}
	for _, category in ipairs(Config.Categories) do
		result[category] = categoryUnlocked(profile, category)
	end
	return result
end

local function publicState(profile, owner)
	local quadActive = (profile.QuadBoostUntil or 0) > os.time()
	local cached = owner and boostCache[owner] or {}
	return {
		Version = Config.Version,
		Level = profile.Level,
		Exp = profile.Exp,
		NextExp = expForLevel(profile.Level),
		Gold = profile.Gold,
		Essence = profile.Essence,
		Fragments = profile.Fragments,
		RerollTickets = profile.RerollTickets or 0,
		UnlockedCategories = unlockedCategories(profile),
		BossMaterials = profile.BossMaterials,
		Mastery = profile.Mastery,
		Kills = profile.Kills,
		BossKills = profile.BossKills,
		Spins = profile.Spins,
		Power = computePower(profile),
		Fate = deepCopy(profile.Fate),
		Pity = deepCopy(profile.Pity),
		Quest = deepCopy(profile.Quest),
		SeenIntro = profile.SeenIntro,
		Boost = {
			Exp = quadActive and 4 or (cached.Exp or 1),
			Gold = quadActive and 4 or (cached.Gold or 1),
			Until = profile.QuadBoostUntil or 0,
		},
	}
end

local function multipliers(player)
	local profile = profiles[player]
	local cached = boostCache[player] or {}
	if profile and (profile.QuadBoostUntil or 0) > os.time() then
		return 4, 4
	end
	return cached.Exp or 1, cached.Gold or 1
end

local function sendState(player, notice)
	local profile = profiles[player]
	if not profile then
		return
	end
	stateRemote:FireClient(player, publicState(profile, player), notice)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Level.Value = profile.Level
		leaderstats.Power.Value = computePower(profile)
		leaderstats.Gold.Value = profile.Gold
	end
end

local function createLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	for _, name in ipairs({ "Level", "Power", "Gold" }) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = folder
	end
end

local function savePlayer(player)
	local account = accounts[player]
	if not account or not store then
		return
	end
	local activeSlot = activeSlots[player]
	if activeSlot and profiles[player] then
		account.Slots[activeSlot] = deepCopy(profiles[player])
	end
	local payload = deepCopy(account)
	local success, err = pcall(function()
		store:UpdateAsync("u_" .. player.UserId, function()
			return payload
		end)
	end)
	if not success then
		warn("FATEBORN save failed for", player.Name, err)
	end
end

local function addBillboard(character, player)
	local profile = profiles[player]
	local head = character:FindFirstChild("Head")
	if not profile or not head or not profile.Fate.Race or not profile.Fate.Ability then
		return
	end
	local old = head:FindFirstChild("Fateplate")
	if old then
		old:Destroy()
	end
	local bestRarity = rarityScore(profile)
	local board = Instance.new("BillboardGui")
	board.Name = "Fateplate"
	board.Size = UDim2.fromOffset(230, 64)
	board.StudsOffset = Vector3.new(0, 3.05, 0)
	board.AlwaysOnTop = true
	board.MaxDistance = 120
	board.Parent = head

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.GetRarityColor(bestRarity)
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -12, 0, 25)
	title.Position = UDim2.fromOffset(6, 4)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = string.format("%s  •  %s", player.DisplayName, profile.Fate.Race.Name)
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, -12, 0, 25)
	subtitle.Position = UDim2.fromOffset(6, 31)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 12
	subtitle.TextColor3 = Config.GetRarityColor(profile.Fate.Ability.Rarity)
	subtitle.Text = string.format("%s  |  POWER %s", profile.Fate.Ability.Name, tostring(computePower(profile)))
	subtitle.Parent = frame

	character:SetAttribute("FatebornPlayerId", player.UserId)
	character:SetAttribute("Race", profile.Fate.Race.Name)
	character:SetAttribute("Ability", profile.Fate.Ability.Name)
	character:SetAttribute("Power", computePower(profile))
end

local function replaceRaceCharacter(player, character)
	local profile = profiles[player]
	local raceName = profile
		and profile.Fate.Race
		and profile.Fate.Race.Name
	local characterProfile = RaceCharacterModels.getProfile(raceName)

	if not characterProfile or character:GetAttribute("RaceCharacterProfile") == raceName then
		return false
	end

	local templateFolder = ServerStorage:FindFirstChild(characterProfile.TemplateFolder)
	local templateContainer = templateFolder and templateFolder:FindFirstChild(characterProfile.TemplateName)
	local template = templateContainer and templateContainer:FindFirstChild(characterProfile.CharacterModelName)
	if not template or not template:IsA("Model") then
		warn("FATEBORN race character template is missing for", raceName)
		return false
	end

	local templateRoot = template:FindFirstChild("HumanoidRootPart")
	local templateMesh = template:FindFirstChild("char1")
	if not templateRoot or not templateRoot:IsA("BasePart")
		or not templateMesh or not templateMesh:IsA("MeshPart") then
		warn("FATEBORN race character visual rig is incomplete for", raceName)
		return false
	end

	character.Archivable = true
	local replacement = character:Clone()
	local humanoid = replacement:FindFirstChildOfClass("Humanoid")
	local root = replacement:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		replacement:Destroy()
		warn("FATEBORN default character could not host the race visual for", raceName)
		return false
	end
	local oldVisual = replacement:FindFirstChild("char1")
	local hostVisualBottom = -humanoid.HipHeight - root.Size.Y * 0.5
	if oldVisual and oldVisual:IsA("BasePart") then
		local localPosition = root.CFrame:ToObjectSpace(oldVisual.CFrame).Position
		hostVisualBottom = localPosition.Y - oldVisual.Size.Y * 0.5
		oldVisual:Destroy()
	end

	for _, descendant in ipairs(replacement:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CastShadow = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant:Destroy()
		end
	end

	for _, child in ipairs(replacement:GetChildren()) do
		if child:IsA("ForceField")
			or child:IsA("Accessory")
			or child:IsA("Clothing")
			or child:IsA("ShirtGraphic")
			or child:IsA("BodyColors") then
			child:Destroy()
		end
	end

	local templateVisualOffset = templateRoot.CFrame:ToObjectSpace(templateMesh.CFrame)
	local templateVisualBottom = templateVisualOffset.Position.Y - templateMesh.Size.Y * 0.5
	local visualRoot = Instance.new("Part")
	visualRoot.Name = "RaceVisualRoot"
	visualRoot.Size = Vector3.new(0.2, 0.2, 0.2)
	visualRoot.CFrame = root.CFrame * CFrame.new(0, hostVisualBottom - templateVisualBottom, 0)
	visualRoot.Transparency = 1
	visualRoot.CanCollide = false
	visualRoot.CanTouch = false
	visualRoot.CanQuery = false
	visualRoot.Anchored = false
	visualRoot.Massless = true
	visualRoot.Parent = replacement
	local visualRootWeld = Instance.new("WeldConstraint")
	visualRootWeld.Name = "RaceVisualRootWeld"
	visualRootWeld.Part0 = root
	visualRootWeld.Part1 = visualRoot
	visualRootWeld.Parent = visualRoot

	local visual = templateMesh:Clone()
	visual.CFrame = visualRoot.CFrame * templateVisualOffset
	visual.Transparency = 0
	visual.CastShadow = true
	visual.CanCollide = false
	visual.CanTouch = false
	visual.Massless = true
	visual.Parent = replacement
	local visualWeld = Instance.new("WeldConstraint")
	visualWeld.Name = "RaceVisualWeld"
	visualWeld.Part0 = visualRoot
	visualWeld.Part1 = visual
	visualWeld.Parent = visual
	for _, child in ipairs(templateRoot:GetChildren()) do
		if child:IsA("Bone") then
			child:Clone().Parent = visualRoot
		end
	end

	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", humanoid)
	end
	replacement.Name = player.Name
	replacement.PrimaryPart = root
	replacement:SetAttribute("Race", raceName)
	replacement:SetAttribute("PlayerModelAssetId", characterProfile.AssetId)
	replacement:SetAttribute("RaceCharacterProfile", raceName)
	replacement:SetAttribute("RaceCharacterAssetId", characterProfile.AssetId)
	replacement:SetAttribute("FatebornBoneCharacter", characterProfile.BoneCharacter == true)

	local spawnCFrame = character:GetPivot()
	replacement.Parent = workspace
	replacement:PivotTo(spawnCFrame)
	player.Character = replacement
	character:Destroy()
	return true
end

local function applyCharacter(player, character)
	local profile = profiles[player]
	if not profile or not profile.Fate.Durability or not profile.Fate.Speed or not profile.Fate.Ability then
		return
	end
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end
	local durability = profile.Fate.Durability.Power or 1
	local speed = profile.Fate.Speed.Power or 1
	character:SetAttribute("DurabilityPower", durability)
	humanoid.MaxHealth = math.floor((100 + profile.Level * 7) * durability)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = math.clamp(14 * speed, 12, 24)
	character:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
	character:SetAttribute("Sprinting", false)
	character:SetAttribute("Dashing", false)
	humanoid.JumpPower = math.clamp(50 * (0.94 + speed * 0.08), 45, 65)

	local accent = Color3.fromRGB(255, 178, 46)
	for _, item in ipairs(Config.Pools.Ability) do
		if item.Name == profile.Fate.Ability.Name then
			accent = item.Accent
			break
		end
	end
	for _, oldName in ipairs({ "FateAura", "PrestigeAura" }) do
		local old = root:FindFirstChild(oldName)
		if old then
			old:Destroy()
		end
	end
	local light = Instance.new("PointLight")
	light.Name = "FateAura"
	light.Color = accent
	light.Range = 8 + Config.GetRarityRank(profile.Fate.Ability.Rarity) * 2
	light.Brightness = math.max(0.4, Config.GetRarityRank(profile.Fate.Ability.Rarity) * 0.35)
	light.Parent = root

	if Config.GetRarityRank(profile.Fate.Ability.Rarity) >= 4 then
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "PrestigeAura"
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(accent)
		particles.LightEmission = 0.8
		particles.Rate = 6 + Config.GetRarityRank(profile.Fate.Ability.Rarity) * 2
		particles.Lifetime = NumberRange.new(0.5, 1.2)
		particles.Speed = NumberRange.new(0.5, 2)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = root
	end

	addBillboard(character, player)
end

local function giveExp(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Exp += amount
	local leveled = false
	while profile.Level < Config.MaxLevel and profile.Exp >= expForLevel(profile.Level) do
		profile.Exp -= expForLevel(profile.Level)
		profile.Level += 1
		profile.Fragments += 3
		leveled = true
	end
	if leveled then
		announcementRemote:FireClient(player, string.format("LEVEL %d — Fate Fragment +3", profile.Level), "Level")
		if player.Character then
			applyCharacter(player, player.Character)
		end
	end
end

local function completeQuest(player)
	local profile = profiles[player]
	if not profile or profile.Quest.Progress < profile.Quest.Target then
		return
	end
	local reward = profile.Quest.Reward
	profile.Fragments += reward
	profile.Gold += reward * 5
	profile.Quest = {
		Kind = profile.BossKills > 0 and "Defeat" or "Defeat",
		Target = math.min(20, 5 + math.floor(profile.Level / 3) * 2),
		Progress = 0,
		Reward = math.min(45, 15 + profile.Level),
	}
	announcementRemote:FireClient(player, string.format("QUEST COMPLETE — +%d Fate Fragments", reward), "Reward")
end

local function rewardKill(player, definition)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Kills += 1
	local expMultiplier, goldMultiplier = multipliers(player)
	local goldReward = math.floor(definition.Gold * goldMultiplier)
	local expReward = math.floor(definition.Exp * expMultiplier)
	profile.Gold += goldReward
	profile.Essence += definition.Essence
	profile.Mastery += definition.Boss and 8 or 1
	if definition.Boss then
		profile.BossKills += 1
		profile.BossMaterials += 1
		announcementRemote:FireAllClients(player.DisplayName .. " defeated THE FALLEN KING", "Boss")
		if rng:NextNumber() <= Config.WorldBossTicketDropChance then
			profile.RerollTickets = (profile.RerollTickets or 0) + 1
			announcementRemote:FireClient(player, "ULTRA RARE DROP — UNIVERSAL REROLL TICKET!", "Reward")
		end
	end
	giveExp(player, expReward)
	profile.Quest.Progress = math.min(profile.Quest.Target, profile.Quest.Progress + 1)
	completeQuest(player)
	sendState(player, string.format("+%d Gold  +%d EXP", goldReward, expReward))
end

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Slate
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function floatingLabel(part, titleText, subtitleText, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(330, 80)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = color
	title.Text = titleText
	title.Parent = gui
	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.new(0, 0, 0.58, 0)
	subtitle.Size = UDim2.new(1, 0, 0.3, 0)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextScaled = true
	subtitle.TextColor3 = Color3.fromRGB(214, 218, 228)
	subtitle.Text = subtitleText
	subtitle.Parent = gui
end

local function createWorld()
	local old = workspace:FindFirstChild("FATEBORN_WORLD")
	if old then
		old:Destroy()
	end
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "FATEBORN_WORLD"
	worldFolder.Parent = workspace

	Lighting.Ambient = Color3.fromRGB(30, 34, 49)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 72, 88)
	Lighting.FogColor = Color3.fromRGB(31, 30, 45)
	Lighting.FogEnd = 580
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Color = Color3.fromRGB(153, 148, 181)
	atmosphere.Decay = Color3.fromRGB(61, 43, 70)
	atmosphere.Density = 0.34
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	makePart(worldFolder, "Hub", Vector3.new(130, 4, 130), CFrame.new(0, -2, 0), Color3.fromRGB(35, 39, 51), Enum.Material.Slate)
	makePart(worldFolder, "VillageRoad", Vector3.new(90, 2, 260), CFrame.new(0, -1, -165), Color3.fromRGB(50, 49, 57), Enum.Material.Cobblestone)
	makePart(worldFolder, "DemonForest", Vector3.new(210, 3, 230), CFrame.new(230, -1.5, -190), Color3.fromRGB(40, 34, 45), Enum.Material.Ground)
	makePart(worldFolder, "BossArena", Vector3.new(125, 3, 125), CFrame.new(230, -0.5, -385), Color3.fromRGB(44, 38, 50), Enum.Material.Basalt)
	makePart(worldFolder, "ForestBridge", Vector3.new(105, 2, 24), CFrame.new(92, -1, -145), Color3.fromRGB(48, 43, 55), Enum.Material.Cobblestone)
	makePart(worldFolder, "BossBridge", Vector3.new(24, 2, 34), CFrame.new(230, -1, -320), Color3.fromRGB(55, 44, 52), Enum.Material.Cobblestone)
	local zoneGate = makePart(worldFolder, "DemonForestGate", Vector3.new(3, 28, 30), CFrame.new(116, 13, -145), Color3.fromRGB(164, 66, 112), Enum.Material.ForceField)
	zoneGate.Transparency = 0.35
	zoneGate.CanCollide = false
	zoneGate.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local touchingPlayer = character and Players:GetPlayerFromCharacter(character)
		local profile = touchingPlayer and profiles[touchingPlayer]
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if profile and root and profile.Level < Config.ZoneTwoLevel and not character:GetAttribute("ZoneGateDebounce") then
			character:SetAttribute("ZoneGateDebounce", true)
			root.CFrame = CFrame.new(91, 5, -145)
			announcementRemote:FireClient(touchingPlayer, string.format("DEMON FOREST REQUIRES LEVEL %d", Config.ZoneTwoLevel), "Info")
			task.delay(1, function()
				if character then character:SetAttribute("ZoneGateDebounce", nil) end
			end)
		end
	end)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "FatebornSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 1, 24)
	spawn.Color = Color3.fromRGB(240, 187, 78)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.4
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = worldFolder

	local altar = makePart(worldFolder, "WheelOfExistence", Vector3.new(20, 2, 20), CFrame.new(0, 1, -10), Color3.fromRGB(223, 164, 54), Enum.Material.Neon)
	altar.Shape = Enum.PartType.Cylinder
	altar.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	floatingLabel(altar, "WHEEL OF EXISTENCE", "Press G • Roll what you were born to become", Color3.fromRGB(255, 210, 105))
	for index = 1, 12 do
		local angle = (index / 12) * math.pi * 2
		local obelisk = makePart(worldFolder, "FateObelisk", Vector3.new(2.5, 12 + (index % 3) * 3, 2.5), CFrame.new(math.cos(angle) * 39, 6, -10 + math.sin(angle) * 39), Color3.fromRGB(58, 50, 82), Enum.Material.Slate)
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(163, 100, 255)
		glow.Range = 11
		glow.Brightness = 0.7
		glow.Parent = obelisk
	end

	local villageSign = makePart(worldFolder, "VillageSign", Vector3.new(1, 1, 1), CFrame.new(0, 2, -75), Color3.new(), Enum.Material.SmoothPlastic)
	villageSign.Transparency = 1
	villageSign.CanCollide = false
	floatingLabel(villageSign, "FORGOTTEN VILLAGE", "Lv. 1+ • Wanderers and Fate Hounds", Color3.fromRGB(219, 222, 231))
	local forestSign = makePart(worldFolder, "ForestSign", Vector3.new(1, 1, 1), CFrame.new(135, 2, -140), Color3.new(), Enum.Material.SmoothPlastic)
	forestSign.Transparency = 1
	forestSign.CanCollide = false
	floatingLabel(forestSign, "DEMON FOREST", "Lv. 8+ • Ash Knights and Rift Cultists", Color3.fromRGB(199, 92, 140))
	local bossSign = makePart(worldFolder, "BossSign", Vector3.new(1, 1, 1), CFrame.new(230, 2, -385), Color3.new(), Enum.Material.SmoothPlastic)
	bossSign.Transparency = 1
	bossSign.CanCollide = false
	floatingLabel(bossSign, "THE FALLEN KING", "World Boss • Three phases", Color3.fromRGB(255, 181, 72))

	for index = 1, 34 do
		local zoneTwo = index > 18
		local x = zoneTwo and rng:NextInteger(150, 310) or rng:NextInteger(-38, 38)
		local z = zoneTwo and rng:NextInteger(-310, -105) or rng:NextInteger(-290, -70)
		local height = rng:NextInteger(9, 23)
		local trunk = makePart(worldFolder, "DeadTree", Vector3.new(3, height, 3), CFrame.new(x, height / 2, z), zoneTwo and Color3.fromRGB(37, 25, 39) or Color3.fromRGB(57, 48, 46), Enum.Material.Wood)
		trunk.CFrame *= CFrame.Angles(0, 0, math.rad(rng:NextInteger(-7, 7)))
	end

	spawnDefinitions = {
		{ Type = "Wanderer", Position = Vector3.new(-22, 3, -105), Respawn = 7 },
		{ Type = "Wanderer", Position = Vector3.new(24, 3, -122), Respawn = 7 },
		{ Type = "Wanderer", Position = Vector3.new(-18, 3, -160), Respawn = 7 },
		{ Type = "FateHound", Position = Vector3.new(25, 3, -188), Respawn = 9 },
		{ Type = "FateHound", Position = Vector3.new(-26, 3, -230), Respawn = 9 },
		{ Type = "AshKnight", Position = Vector3.new(175, 3, -155), Respawn = 11 },
		{ Type = "AshKnight", Position = Vector3.new(246, 3, -170), Respawn = 11 },
		{ Type = "RiftCultist", Position = Vector3.new(290, 3, -245), Respawn = 13 },
		{ Type = "RiftCultist", Position = Vector3.new(188, 3, -280), Respawn = 13 },
		{ Type = "FallenKing", Position = Vector3.new(230, 5, -385), Respawn = 45 },
	}
end

local function enemyLabel(root, name, humanoid, definition)
	local gui = Instance.new("BillboardGui")
	gui.Name = "EnemyPlate"
	gui.Size = UDim2.fromOffset(definition.Boss and 330 or 210, 50)
	gui.StudsOffset = Vector3.new(0, definition.Boss and 8 or 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 130
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 0.52)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = definition.Boss and Color3.fromRGB(255, 185, 72) or Color3.new(1, 1, 1)
	label.Text = string.format("%s  •  Lv. %d", name, definition.Level)
	label.Parent = gui
	local back = Instance.new("Frame")
	back.Name = "HealthBack"
	back.Position = UDim2.new(0.05, 0, 0.68, 0)
	back.Size = UDim2.new(0.9, 0, 0.18, 0)
	back.BackgroundColor3 = Color3.fromRGB(35, 28, 33)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = definition.Boss and Color3.fromRGB(230, 135, 40) or Color3.fromRGB(205, 56, 77)
	fill.BorderSizePixel = 0
	fill.Parent = back
	humanoid.HealthChanged:Connect(function(health)
		fill.Size = UDim2.fromScale(math.max(0, health / humanoid.MaxHealth), 1)
	end)
end

local function createEnemy(spawnIndex)
	local spawnDef = spawnDefinitions[spawnIndex]
	local definition = Config.Enemies[spawnDef.Type]
	if not definition then return end
	local targetHeight = spawnDef.Type == "FallenKing" and 7.5 or (spawnDef.Type == "Wanderer" and 6.5 or 6)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { worldFolder }
	local ray = workspace:Raycast(spawnDef.Position + Vector3.new(0, 80, 0), Vector3.new(0, -160, 0), rayParams)
	local groundY = ray and ray.Position.Y or spawnDef.Position.Y
	local spawnPosition = Vector3.new(spawnDef.Position.X, groundY + targetHeight * 0.5, spawnDef.Position.Z)
	local model = Instance.new("Model")
	model.Name = spawnDef.Type
	model:SetAttribute("Enemy", true)
	model:SetAttribute("SpawnIndex", spawnIndex)
	model:SetAttribute("LastHitUserId", 0)
	model:SetAttribute("Phase", 1)
	model.Parent = worldFolder
	local root = makePart(model, "HumanoidRootPart", Vector3.new(targetHeight * 0.38, targetHeight, targetHeight * 0.32), CFrame.new(spawnPosition), definition.Color, Enum.Material.SmoothPlastic)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = true
	root:SetNetworkOwner(nil)
	local head = makePart(model, "Head", Vector3.new(1, 1, 1), root.CFrame * CFrame.new(0, targetHeight * 0.35, 0), definition.Color, Enum.Material.SmoothPlastic)
	head.Transparency = 1 head.Anchored = false head.CanCollide = false
	local headWeld = Instance.new("WeldConstraint") headWeld.Part0 = root headWeld.Part1 = head headWeld.Parent = root
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = definition.MaxHealth humanoid.Health = definition.MaxHealth
	humanoid.WalkSpeed = definition.Boss and 13 or (spawnDef.Type == "Wanderer" and 11 or 12)
	humanoid.HipHeight = 0
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	Instance.new("Animator", humanoid)
	model.PrimaryPart = root
	local visualMotor
	local templateName = spawnDef.Type == "Wanderer" and "WandererAsset" or nil
	local template = templateName and game:GetService("ServerStorage"):FindFirstChild(templateName)
	if template then
		local visual = template:Clone()
		visual.Name = "Visual"
		visual.Parent = model
		local _, originalSize = visual:GetBoundingBox()
		if originalSize.Y > 0 then visual:ScaleTo(targetHeight / originalSize.Y) end
		local visualRoot = visual.PrimaryPart or visual:FindFirstChildWhichIsA("BasePart", true)
		if visualRoot then
			visual.PrimaryPart = visualRoot
			visual:PivotTo(root.CFrame)
			for _, part in ipairs(visual:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false part.CanCollide = false part.CanTouch = false part.CanQuery = false part.Massless = true
					if part ~= visualRoot then local weld = Instance.new("WeldConstraint") weld.Part0 = visualRoot weld.Part1 = part weld.Parent = visualRoot end
				elseif part:IsA("Script") or part:IsA("LocalScript") then part.Enabled = false end
			end
			visualMotor = Instance.new("Motor6D")
			visualMotor.Name = "EnemyVisualMotor"
			visualMotor.Part0 = root visualMotor.Part1 = visualRoot
			visualMotor.C0 = root.CFrame:ToObjectSpace(visualRoot.CFrame)
			visualMotor.Parent = root
		end
	end
	if not visualMotor then
		headWeld:Destroy()
		head.Transparency = 0
		require(game.ServerScriptService.EnemyRig).Build(model, root, head, humanoid, definition)
	end
	game:GetService("CollectionService"):AddTag(model, "FatebornAnimatedEnemy")
	enemyLabel(root, spawnDef.Type:gsub("(%l)(%u)", "%1 %2"), humanoid, definition)
	local motionProfile = require(ReplicatedStorage.Shared.EnemyMotion).Profiles[spawnDef.Type]
		or require(ReplicatedStorage.Shared.EnemyMotion).Profiles.Wanderer
	local aiTier = spawnDef.AITier or (definition.Boss and "Boss" or "Standard")
	model:SetAttribute("AITier", aiTier)

	enemies[model] = {
		Definition = definition, Type = spawnDef.Type, Home = spawnPosition,
		LastAttack = 0, LastSpecial = os.clock(), SpawnIndex = spawnIndex,
		AggroRadius = definition.Boss and 120 or (spawnDef.Type == "Wanderer" and 65 or 75),
		LeashRadius = definition.Boss and 145 or 95,
		AttackRange = definition.Boss and 10 or 5.5,
		WalkSpeed = motionProfile.walk,
		RunSpeed = motionProfile.run,
		VisualMotor = visualMotor, AnimClock = 0, AttackUntil = 0,
	}
	EnemyAISystem.Attach(model, enemies[model], aiTier)
	require(game.ServerScriptService.EnemyActions).Attach(model, enemies[model])
	humanoid.Died:Connect(function()
		EnemyAISystem.MarkDeath(model, enemies[model])
		local userId = model:GetAttribute("LastHitUserId")
		local player = userId and Players:GetPlayerByUserId(userId)
		if player then rewardKill(player, definition) end
		enemies[model] = nil
		task.delay(spawnDef.Respawn, function()
			if worldFolder and worldFolder.Parent and not worldFolder:FindFirstChild(spawnDef.Type .. "_" .. spawnIndex) then createEnemy(spawnIndex) end
		end)
		Debris:AddItem(model, 3)
	end)
end

local function getAliveRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil
end

local function damageEnemy(player, model, amount, reactionKind, knockback)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	local playerRoot = getAliveRoot(player)
	if not humanoid or not root or not playerRoot or humanoid.Health <= 0 then
		return false
	end

	local enemyData = enemies[model]
	local punishUserId = model:GetAttribute("PunishableByUserId")
	local punishUntil = model:GetAttribute("PunishUntil") or 0
	local advancedCounter = model:GetAttribute("AdvancedCounter") == true
	local punish = punishUserId == player.UserId and os.clock() <= punishUntil
	if punish then
		amount *= advancedCounter and 2 or 1.5
		reactionKind = advancedCounter and "Finisher" or "Heavy"
		model:SetAttribute("PunishableByUserId", nil)
		model:SetAttribute("PunishUntil", nil)
		model:SetAttribute("AdvancedCounter", nil)
		local defenseRemote = ReplicatedStorage:FindFirstChild("CombatDefenseEvent")
		if defenseRemote then
			defenseRemote:FireClient(player, "Punish", root.Position, advancedCounter and "Advanced" or "Normal")
		end
		dispatchVFX(advancedCounter and "Crit" or "HeavyHit", root.Position, advancedCounter and Color3.fromRGB(255, 229, 102) or Color3.fromRGB(255, 104, 72), { SourceUserId = player.UserId })
	end

	model:SetAttribute("LastHitUserId", player.UserId)
	humanoid:TakeDamage(amount)

	if humanoid.Health > 0 then
		dispatchVFX("HitReaction", root.Position, Color3.fromRGB(255, 128, 92), { Reaction = reactionKind or "Light" })
		local kind = reactionKind or "Light"
		if kind == "Finisher" and enemyData and enemyData.Definition.Boss then
			kind = "Heavy"
		end
		HitReactionSystem.Apply(model, kind, playerRoot.Position, knockback, enemyData)
	end

	return true
end

local function targetsNear(position, radius)
	local result = {}
	for model in pairs(enemies) do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and (root.Position - position).Magnitude <= radius then
			table.insert(result, model)
		end
	end
	return result
end

local function baseDamage(profile)
	local strength = profile.Fate.Strength and profile.Fate.Strength.Power or 1
	local ability = profile.Fate.Ability and profile.Fate.Ability.Power or 1
	return (14 + profile.Level * 3.2 + profile.Mastery * 0.22) * strength * ability
end

local function abilityColor(profile)
	if not profile.Fate.Ability then
		return Color3.fromRGB(255, 178, 46)
	end
	for _, item in ipairs(Config.Pools.Ability) do
		if item.Name == profile.Fate.Ability.Name then
			return item.Accent
		end
	end
	return Color3.fromRGB(255, 178, 46)
end

local function checkCooldown(player, key, duration)
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	if (cooldowns[player][key] or 0) > now then
		return false
	end
	cooldowns[player][key] = now + duration
	return true
end

local function basicAttack(player, direction)
	local profile = profiles[player]
	local root = getAliveRoot(player)
	if not profile or not root or not checkCooldown(player, "Basic", 0.55) then
		return
	end
	local best, bestDistance
	for _, model in ipairs(targetsNear(root.Position, 12)) do
		local enemyRoot = model:FindFirstChild("HumanoidRootPart")
		local offset = enemyRoot.Position - root.Position
		local dot = direction.Unit:Dot(offset.Unit)
		if dot > 0.2 and (not bestDistance or offset.Magnitude < bestDistance) then
			best = model
			bestDistance = offset.Magnitude
		end
	end
	local color = abilityColor(profile)
	dispatchVFX("Slash", root.Position + direction.Unit * 3 + Vector3.new(0, 1.5, 0), color, {
		SourceUserId = player.UserId,
		Direction = direction,
	})
	if best then
		damageEnemy(player, best, baseDamage(profile), "Light")
		dispatchVFX("CombatHit", best.HumanoidRootPart.Position, color, { SourceUserId = player.UserId })
	end
end

local function useAbility(player, slot, direction)
	local profile = profiles[player]
	local root = getAliveRoot(player)
	if not profile or not profile.Fate.Strength or not profile.Fate.Ability or not root then
		return
	end
	local kit = Config.GetAbilityKit(profile.Fate.Ability.Name)
	local move = kit[slot]
	if not move or not checkCooldown(player, "Skill" .. slot, move.Cooldown) then
		return
	end
	local color = abilityColor(profile)
	local damage = baseDamage(profile) * move.Damage
	local center = root.Position
	if move.Mode == "Dash" then
		local travel = direction.Unit * move.Range
		root.CFrame = CFrame.new(root.Position + travel, root.Position + travel + direction.Unit)
		center = root.Position
	elseif move.Mode == "Projectile" or move.Mode == "Line" then
		local best, bestScore
		for model in pairs(enemies) do
			local enemyRoot = model:FindFirstChild("HumanoidRootPart")
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if enemyRoot and humanoid and humanoid.Health > 0 then
				local offset = enemyRoot.Position - root.Position
				if offset.Magnitude <= move.Range then
					local dot = direction.Unit:Dot(offset.Unit)
					if dot > 0.72 and (not bestScore or dot > bestScore) then
						best = model
						bestScore = dot
					end
				end
			end
		end
		if best then
			center = best.HumanoidRootPart.Position
			damageEnemy(player, best, damage, "Heavy")
		end
	else
		center = root.Position + direction.Unit * math.min(14, move.Range * 0.4)
	end
	if move.Mode == "Area" or move.Mode == "Awakening" or move.Mode == "Dash" then
		for _, model in ipairs(targetsNear(center, move.Range)) do
			local reactionKind = move.Mode == "Awakening" and "Finisher" or "Heavy"
			local knockback = reactionKind == "Finisher" and 65 or nil
			damageEnemy(player, model, damage, reactionKind, knockback)
		end
	end
	dispatchVFX("Skill", center, color, {
		SourceUserId = player.UserId,
		Mode = move.Mode,
		Direction = direction,
		Radius = move.Mode == "Awakening" and move.Range * 2 or math.clamp(move.Range, 8, 32),
		Lifetime = move.Mode == "Awakening" and 0.8 or 0.4,
	})
end

actionRemote.OnServerEvent:Connect(function(player, action, value, direction)
	if typeof(direction) ~= "Vector3" or direction.Magnitude ~= direction.Magnitude or direction.Magnitude < 0.1 then
		direction = Vector3.new(0, 0, -1)
	end
	direction = direction.Unit

	local character = player.Character
	local reactionLocked = HitReactionSystem.IsLocked(character)
	if reactionLocked and (action == "Basic" or action == "Ability") then
		return
	end

	if action == "Basic" then
		basicAttack(player, direction)
	elseif action == "Ability" and type(value) == "number" and value >= 1 and value <= 5 then
		useAbility(player, math.floor(value), direction)
	elseif action == "Sprint" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health > 0 then
			local sprinting = value == true
			local baseSpeed = character:GetAttribute("BaseWalkSpeed")
			if type(baseSpeed) ~= "number" or baseSpeed <= 0 then
				baseSpeed = humanoid.WalkSpeed
				character:SetAttribute("BaseWalkSpeed", baseSpeed)
			end
			character:SetAttribute("Sprinting", sprinting)
			humanoid.WalkSpeed = sprinting and (baseSpeed * 1.45) or baseSpeed
		end
	elseif action == "Dash" then
		local root = getAliveRoot(player)
		if root and checkCooldown(player, "Dash", 2.2) then
			local dashVelocity = Instance.new("BodyVelocity")
			dashVelocity.Name = "FatebornDashVelocity"
			dashVelocity.MaxForce = Vector3.new(1000000, 0, 1000000)
			dashVelocity.P = 50000
			dashVelocity.Velocity = direction.Unit * 82
			dashVelocity.Parent = root
			root.AssemblyLinearVelocity = direction.Unit * 82 + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			Debris:AddItem(dashVelocity, 0.18)
			local movementVfx = value == "Roll" and "Roll" or "Dash"
			dispatchVFX(movementVfx, root.Position, nil, { SourceUserId = player.UserId, Direction = direction })
		end
	elseif action == "IntroSeen" then
		local profile = profiles[player]
		if profile then
			profile.SeenIntro = true
			sendState(player)
		end
	end
end)

local function characterSlotSummary(account)
	local result = {}
	for slot = 1, 3 do
		local profile = account and account.Slots[slot]
		result[slot] = profile and {
			Exists = true,
			Level = profile.Level or 1,
			Power = computePower(mergeDefaults(deepCopy(profile), DEFAULT)),
			Race = profile.Fate and profile.Fate.Race and profile.Fate.Race.Name or "Unawakened",
		} or { Exists = false }
	end
	return result
end

manageCharacters.OnServerInvoke = function(player, action, slot)
	local account = accounts[player]
	if not account then return { Ok = false, Message = "Character database is loading." } end
	if action == "List" then
		return { Ok = true, Slots = characterSlotSummary(account), ActiveSlot = activeSlots[player] }
	end
	slot = math.floor(tonumber(slot) or 0)
	if slot < 1 or slot > 3 then return { Ok = false, Message = "Choose slot 1, 2, or 3." } end
	if action == "Create" then
		if account.Slots[slot] then return { Ok = false, Message = "That slot is already occupied." } end
		account.Slots[slot] = deepCopy(DEFAULT)
	elseif action == "Delete" then
		if not account.Slots[slot] then return { Ok = false, Message = "That slot is already empty." } end
		account.Slots[slot] = nil
		if activeSlots[player] == slot then profiles[player] = nil activeSlots[player] = nil end
		savePlayer(player)
		return { Ok = true, Slots = characterSlotSummary(account) }
	elseif action ~= "Select" then
		return { Ok = false, Message = "Invalid character action." }
	end
	if not account.Slots[slot] then return { Ok = false, Message = "Create this character first." } end
	if activeSlots[player] and profiles[player] then
		account.Slots[activeSlots[player]] = deepCopy(profiles[player])
	end
	activeSlots[player] = slot
	profiles[player] = mergeDefaults(deepCopy(account.Slots[slot]), DEFAULT)
	if player.Character then task.defer(applyCharacter, player, player.Character) end
	sendState(player)
	savePlayer(player)
	-- Spawn only after the player has selected a character. The client then
	-- receives the state and can show the initial wheelspin intro first.
	task.defer(function()
		if player.Parent and activeSlots[player] == slot then
			player:LoadCharacter()
		end
	end)
	return { Ok = true, State = publicState(profiles[player], player), Slots = characterSlotSummary(account), ActiveSlot = slot }
end

requestState.OnServerInvoke = function(player)
	local profile = profiles[player]
	return profile and publicState(profile, player) or nil
end

awakenFate.OnServerInvoke = function(player, category)
	local profile = profiles[player]
	if not profile then
		return { Ok = false, Message = "Fate is not ready yet." }
	end
	if type(category) ~= "string" or not Config.Pools[category] then
		return { Ok = false, Message = "Choose a valid Fate category." }
	end
	if not categoryUnlocked(profile, category) then
		local requirement = Config.FateUnlocks[category]
		return { Ok = false, Message = string.format("LOCKED — complete %s (%s %d).", requirement.Story, requirement.Kind, requirement.Value) }
	end
	if profile.Fate[category] then
		return { Ok = false, Message = "This Fate is already assigned. Use one Reroll Ticket to change it." }
	end
	local result = rollCategory(profile, category, true)
	if player.Character then
		applyCharacter(player, player.Character)
	end
	sendState(player)
	savePlayer(player)
	return { Ok = true, Result = deepCopy(result), State = publicState(profile, player) }
end

rerollFate.OnServerInvoke = function(player, category)
	local profile = profiles[player]
	if not profile or type(category) ~= "string" or not Config.Pools[category] then
		return { Ok = false, Message = "Invalid Fate category." }
	end
	if not categoryUnlocked(profile, category) then
		return { Ok = false, Message = "That Fate category is still locked by the story." }
	end
	if not profile.Fate[category] then
		return { Ok = false, Message = "Claim this Fate first; a ticket is only for rerolls." }
	end
	local cost = 1
	if (profile.RerollTickets or 0) < cost then
		return { Ok = false, Message = "You need 1 Universal Reroll Ticket. It is an ultra-rare World Boss drop." }
	end
	profile.RerollTickets -= cost
	local result = rollCategory(profile, category)
	if result.Rarity == "Legendary" or result.Rarity == "Mythic" or result.Rarity == "Secret" then
		announcementRemote:FireAllClients(string.format("%s rolled %s %s!", player.DisplayName, result.Rarity, result.Name), "Rare")
	end
	if player.Character then
		applyCharacter(player, player.Character)
	end
	sendState(player)
	savePlayer(player)
	return { Ok = true, Result = deepCopy(result), Cost = cost, State = publicState(profile, player) }
end

inspectPlayer.OnServerInvoke = function(_, userId)
	if type(userId) ~= "number" then
		return nil
	end
	local target = Players:GetPlayerByUserId(userId)
	local profile = target and profiles[target]
	if not target or not profile then
		return nil
	end
	local state = publicState(profile, target)
	state.Name = target.Name
	state.DisplayName = target.DisplayName
	return state
end

local EnemyMotion=require(ReplicatedStorage.Shared.EnemyMotion)
local EnemyActions=require(game.ServerScriptService.EnemyActions)
local StaminaSystem=require(game.ServerStorage.ZeroScript.StaminaSystem)
-- CombatDefenseEvent is bootstrapped near the other shared remotes above.
local defenseStates={}

local function fightingMasteryPower(player)
	local profile=profiles[player]
	local mastery=profile and profile.Fate and profile.Fate.FightingMastery
	return mastery and tonumber(mastery.Power) or .86
end

local function parryWindowFor(player)
	local power=fightingMasteryPower(player)
	return .16+math.clamp((power-.86)/.84,0,1)*.14
end

local function hasAdvancedCounter(player)
	return fightingMasteryPower(player)>=1.30
end

local function stopBlocking(player)
	local state=defenseStates[player]
	if state then state.Blocking=false end
	StaminaSystem.SetDrain(player,"Block",false,StaminaSystem.Config.BlockDrainPerSecond)
	if player.Character then player.Character:SetAttribute("Blocking",false) end
end

defenseRemote.OnServerEvent:Connect(function(player,action,value)
	if action~="Block" then return end
	defenseStates[player]=defenseStates[player] or {Blocking=false,BlockStarted=-math.huge}
	local state=defenseStates[player]
	if value==true then
		local root,humanoid=getAliveRoot(player)
		if not root or not humanoid or StaminaSystem.Get(player)<=0 then return end
		state.Blocking=true
		state.BlockStarted=os.clock()
		StaminaSystem.SetDrain(player,"Block",true,StaminaSystem.Config.BlockDrainPerSecond)
		if player.Character then player.Character:SetAttribute("Blocking",true) end
	else
		stopBlocking(player)
	end
end)

StaminaSystem.Depleted:Connect(function(player)
	local state=defenseStates[player]
	if state and state.Blocking then
		local root=getAliveRoot(player)
		stopBlocking(player)
		if root then defenseRemote:FireClient(player,"GuardBreak",root.Position) end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	defenseStates[player]=nil
end)

local function resolveIncomingDamage(player,attackerModel,damage,reactionKind,hitPosition)
	local playerRoot,playerHumanoid=getAliveRoot(player)
	if not playerRoot or not playerHumanoid then return false end
	local state=defenseStates[player]
	local attackerRoot=attackerModel and attackerModel:FindFirstChild("HumanoidRootPart")

	if not state or not state.Blocking or StaminaSystem.Get(player)<=0 then
		playerHumanoid:TakeDamage(damage)
		dispatchVFX("HitLight", playerRoot.Position + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 128, 92), {
			SourceUserId = attackerModel and attackerModel:GetAttribute("OwnerUserId"),
		})
		if playerHumanoid.Health>0 and player.Character then
			HitReactionSystem.Apply(player.Character,reactionKind or "Heavy",hitPosition or (attackerRoot and attackerRoot.Position) or playerRoot.Position,nil,nil)
		end
		return true
	end

	if attackerRoot then
		local offset=attackerRoot.Position-playerRoot.Position
		if offset.Magnitude>0 and playerRoot.CFrame.LookVector:Dot(offset.Unit)<-.2 then
			playerHumanoid:TakeDamage(damage)
			dispatchVFX("HitLight", playerRoot.Position + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 128, 92), {
				SourceUserId = attackerModel and attackerModel:GetAttribute("OwnerUserId"),
			})
			if playerHumanoid.Health>0 and player.Character then
				HitReactionSystem.Apply(player.Character,reactionKind or "Heavy",attackerRoot.Position,nil,nil)
			end
			return true
		end
	end

	local sinceBlock=os.clock()-(state.BlockStarted or -math.huge)
	if sinceBlock<=parryWindowFor(player) then
		local advanced=hasAdvancedCounter(player)
		stopBlocking(player)
		if attackerModel then
			attackerModel:SetAttribute("PunishableByUserId",player.UserId)
			attackerModel:SetAttribute("PunishUntil",os.clock()+(advanced and 1.8 or 1.35))
			attackerModel:SetAttribute("AdvancedCounter",advanced)
			local enemyData=enemies[attackerModel]
			if enemyData then
				enemyData.ActionToken=(enemyData.ActionToken or 0)+1
				if advanced then enemyData.ActionEnd=math.max(enemyData.ActionEnd or 0,os.clock()+.65) end
			end
		end
		local parryPosition = attackerRoot and attackerRoot.Position or playerRoot.Position
		defenseRemote:FireClient(player,"Parry",parryPosition,advanced and "Advanced" or "Normal")
		dispatchVFX("Parry", parryPosition, Color3.fromRGB(255, 237, 139), { SourceUserId = player.UserId, Advanced = advanced })
		return false
	end

	playerHumanoid:TakeDamage(damage*.28)
	local blockPosition = attackerRoot and attackerRoot.Position or playerRoot.Position
	defenseRemote:FireClient(player,"Block",blockPosition)
	dispatchVFX("Block", blockPosition, Color3.fromRGB(99, 180, 255), { SourceUserId = player.UserId })
	return true
end

if RunService:IsStudio() then
	defenseRemote.OnServerEvent:Connect(function(player,action,value)
		if action~="DebugHit" then return end
		local playerRoot=getAliveRoot(player)
		if not playerRoot then return end
		local attacker,attackerRoot,bestDistance
		for model in pairs(enemies) do
			local humanoid=model:FindFirstChildOfClass("Humanoid")
			local root=model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health>0 then
				local distance=(root.Position-playerRoot.Position).Magnitude
				if not bestDistance or distance<bestDistance then
					attacker,attackerRoot,bestDistance=model,root,distance
				end
			end
		end
		if attacker then
			resolveIncomingDamage(player,attacker,tonumber(value) or 20,"Light",attackerRoot.Position)
		end
	end)
end

local aiAccumulator=0
local function damagePlayersInRadius(position,radius,damage,reactionKind,attackerModel)
	for _,player in ipairs(Players:GetPlayers()) do
		local playerRoot=getAliveRoot(player)
		if playerRoot and (playerRoot.Position-position).Magnitude<=radius then
			resolveIncomingDamage(player,attackerModel,damage,reactionKind,position)
		end
	end
end
local function face(root,position)
	local flat=Vector3.new(position.X,root.Position.Y,position.Z)
	if (flat-root.Position).Magnitude>.1 then root.CFrame=CFrame.lookAt(root.Position,flat) end
end
RunService.Heartbeat:Connect(function(delta)
	aiAccumulator+=delta
	if aiAccumulator<.1 then return end
	aiAccumulator=0
	local now=os.clock()

	for model,data in pairs(enemies) do
		local humanoid=model:FindFirstChildOfClass("Humanoid")
		local root=model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then continue end

		local profile=EnemyMotion.Profiles[data.Type] or EnemyMotion.Profiles.Wanderer
		local phase=model:GetAttribute("Phase") or 1

		if data.Definition.Boss and humanoid.Health>0 then
			local ratio=humanoid.Health/math.max(1,humanoid.MaxHealth)
			local nextPhase=ratio<=.33 and 3 or (ratio<=.66 and 2 or 1)
			if nextPhase~=phase then
				phase=nextPhase
				model:SetAttribute("Phase",phase)
				data.PendingRoar=true
				data.AggroRadius=(120+phase*10)*(data.AIProfile and data.AIProfile.AggroMultiplier or 1)
				announcementRemote:FireAllClients("THE FALLEN KING - PHASE "..phase,"Boss")
			end
		end

		data.WalkSpeed=profile.walk
		data.RunSpeed=data.Definition.Boss and (phase==3 and 20 or (phase==2 and 16 or 13)) or profile.run

		local skillCooldown=data.Definition.Boss and (phase==3 and 4 or (phase==2 and 5.5 or 7.5)) or profile.cooldown
		local skillReady=now-data.LastSpecial>=skillCooldown
		data.EngageRange=skillReady and math.max(data.AttackRange,profile.skillRange) or data.AttackRange

		local ai=EnemyAISystem.Step(model,data)
		if ai.State=="Invalid" or ai.State=="Death" or ai.State=="Stagger" then
			continue
		end

		if data.PendingRoar and not ai.Busy then
			if EnemyActions.Start(model,data,"Roar") then
				data.PendingRoar=false
				data.LastSpecial=now
			end
			continue
		end

		if ai.State~="Attack" or ai.Busy then
			continue
		end

		local targetPlayer=ai.TargetPlayer
		local targetRoot=ai.TargetRoot
		local targetDistance=ai.TargetDistance
		if not targetPlayer or not targetRoot or not targetDistance then
			continue
		end

		face(root,targetRoot.Position)

		if skillReady and targetDistance<=profile.skillRange then
			local skill=data.Definition.Boss and (phase==3 and "TripleShockwave" or (phase==2 and "RiftEruption" or "RoyalSlam")) or profile.skill
			local castPosition=targetRoot.Position
			local warningPosition=(skill=="RiftEruption" or skill=="RiftBolt") and castPosition or root.Position
			local radius=data.Definition.Boss and (phase==2 and 21 or 17) or profile.radius

			if EnemyActions.Start(model,data,skill,function(index)
				local center=root.Position
				local hitRadius=radius
				local multiplier=profile.multiplier
				if skill=="RiftEruption" or skill=="RiftBolt" then center=castPosition end
				if skill=="Lunge" or skill=="Pounce" then center+=root.CFrame.LookVector*2.5 end
				if skill=="RiftEruption" then multiplier=1.35 end
				if skill=="TripleShockwave" then hitRadius=12+index*8 multiplier=.75+index*.2 end
				damagePlayersInRadius(center,hitRadius,data.Definition.Damage*multiplier,"Heavy",model)
			end) then
				data.LastSpecial=now
			end

		elseif targetDistance<=data.AttackRange then
			local cooldown=data.Definition.Boss and math.max(1.1,1.5-phase*.12) or 1.25
			if now-data.LastAttack>=cooldown then
				if EnemyActions.Start(model,data,profile.basic,function()
					local target,targetHumanoid=getAliveRoot(targetPlayer)
					if not target then return end
					local offset=target.Position-root.Position
					local facing=offset.Magnitude<.1 or root.CFrame.LookVector:Dot(offset.Unit)>-.1
					if facing and offset.Magnitude<=data.AttackRange+1.5 then
						resolveIncomingDamage(targetPlayer,model,data.Definition.Damage*(data.Definition.Boss and (.8+phase*.22) or 1),"Light",root.Position)
					end
				end) then
					data.LastAttack=now
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	createLeaderstats(player)
	local loaded
	local success, result = false, nil
	if store then
		success, result = pcall(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
	end
	if success and type(result) == "table" and type(result.Slots) == "table" then
		loaded = result
	else
		loaded = { Version = 2, Slots = {} }
	end
	accounts[player] = loaded
	-- Character selection is the entry point in Studio and in the published game.
	-- Do not inject a debug profile here, otherwise the intro can run behind the
	-- selector and the player can appear to spawn into the sky after spinning.
	profiles[player] = nil
	activeSlots[player] = nil
	boostCache[player] = { Exp = 1, Gold = 1 }
	task.spawn(function()
		local monetization = Config.Monetization
		if monetization.DoubleExpPass > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, monetization.DoubleExpPass)
			if ok and owns and boostCache[player] then boostCache[player].Exp = 2 end
		end
		if monetization.DoubleGoldPass > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, monetization.DoubleGoldPass)
			if ok and owns and boostCache[player] then boostCache[player].Gold = 2 end
		end
		if profiles[player] then sendState(player) end
	end)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if player.Character ~= character then
				return
			end
			if replaceRaceCharacter(player, character) then
				return
			end
			local humanoid = character:WaitForChild("Humanoid", 10)
			local root = character:WaitForChild("HumanoidRootPart", 10)
			local spawn = worldFolder and worldFolder:FindFirstChild("FatebornSpawn")
			if humanoid then
				humanoid.Died:Connect(function()
					if respawnQueued[player] then return end
					respawnQueued[player] = true
					task.delay(3, function()
						respawnQueued[player] = nil
						if player.Parent and activeSlots[player] and player.Character == character then
							player:LoadCharacter()
						end
					end)
				end)
			end
			if root and spawn then
				-- Custom StarterCharacter models can ignore SpawnLocation placement;
				-- explicitly place the root at the normal default spawn pad.
				character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			applyCharacter(player, character)
		end)
	end)
	if player.Character then
		task.defer(applyCharacter, player, player.Character)
	end
	sendState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	profiles[player] = nil
	accounts[player] = nil
	activeSlots[player] = nil
	cooldowns[player] = nil
	respawnQueued[player] = nil
	boostCache[player] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(finishedPlayer, passId, purchased)
	if not purchased or not boostCache[finishedPlayer] then return end
	if passId == Config.Monetization.DoubleExpPass then boostCache[finishedPlayer].Exp = 2 end
	if passId == Config.Monetization.DoubleGoldPass then boostCache[finishedPlayer].Gold = 2 end
	sendState(finishedPlayer, "Permanent boost activated.")
end)

MarketplaceService.ProcessReceipt = function(receipt)
	if receipt.ProductId ~= Config.Monetization.QuadBoostProduct or receipt.ProductId == 0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchasingPlayer = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = purchasingPlayer and profiles[purchasingPlayer]
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	profile.QuadBoostUntil = math.max(os.time(), profile.QuadBoostUntil or 0) + Config.Monetization.QuadBoostSeconds
	sendState(purchasingPlayer, "x4 EXP & Gold active for 15 minutes.")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(savePlayer, player)
	end
	task.wait(2)
end)

createWorld()
for index = 1, #spawnDefinitions do
	createEnemy(index)
end

print("FATEBORN server ready —", Config.Version)
