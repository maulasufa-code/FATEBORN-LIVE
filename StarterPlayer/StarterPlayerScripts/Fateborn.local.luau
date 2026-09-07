local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("FatebornRemotes")
local requestState = remotes:WaitForChild("RequestState")
local awakenFate = remotes:WaitForChild("AwakenFate")
local rerollFate = remotes:WaitForChild("RerollFate")
local inspectPlayer = remotes:WaitForChild("InspectPlayer")
local manageCharacters = remotes:WaitForChild("ManageCharacters")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")
local announcementRemote = remotes:WaitForChild("Announcement")
local defenseRemote = ReplicatedStorage:WaitForChild("CombatDefenseEvent")

local COLORS = {
	Ink = Color3.fromRGB(8, 11, 19),
	Panel = Color3.fromRGB(15, 20, 32),
	PanelTwo = Color3.fromRGB(23, 29, 44),
	Text = Color3.fromRGB(240, 242, 248),
	Muted = Color3.fromRGB(147, 156, 178),
	Gold = Color3.fromRGB(239, 182, 72),
	Red = Color3.fromRGB(225, 66, 84),
	Green = Color3.fromRGB(74, 220, 139),
}

local RACE_WHEEL_ASSETS = {
	Background = "rbxassetid://82170075804483",
	OuterFrame = "rbxassetid://136794656902184",
	Disc = "rbxassetid://95438265737848", -- GANTI dengan Disc 35 wedge ICON-ONLY, tanpa nama race / tanpa skull pointer
	Pointer = "rbxassetid://132667932806178",
}

local WHEEL_ASSETS = {
	[6] = "rbxassetid://128407033592838",
	[7] = "rbxassetid://82810457243514",
	[10] = "rbxassetid://102644525607628",
	Ring = "rbxassetid://137270030340951",
	Pointer = "rbxassetid://88358094786405",
}

local WHEEL_COLORS = {
	Color3.fromRGB(73, 48, 18),
	Color3.fromRGB(19, 64, 49),
	Color3.fromRGB(51, 32, 77),
	Color3.fromRGB(76, 30, 27),
	Color3.fromRGB(24, 52, 78),
	Color3.fromRGB(76, 55, 22),
	Color3.fromRGB(57, 30, 61),
	Color3.fromRGB(24, 64, 55),
	Color3.fromRGB(73, 32, 29),
	Color3.fromRGB(31, 39, 78),
}

local RACE_WHEEL_ORDER = Config.RaceWheelOrder

assert(
	#RACE_WHEEL_ORDER == 35,
	"FATEBORN: RaceWheelOrder WAJIB tepat 35 race"
)

local RACE_SEGMENT_ANGLE = 360 / 35 -- 10.2857142857°

-- Untuk asset yang wedge Primordial-nya CENTER tepat di jam 12.
local RACE_ART_OFFSET = 0

local BGM_ID = "rbxassetid://122094086809578"
local INTRO_BGM_VOLUME = 0.42
local GAMEPLAY_BGM_VOLUME = 0.32

local bgm = Instance.new("Sound")
bgm.Name = "IntroBGM"
bgm.SoundId = BGM_ID
bgm.Volume = INTRO_BGM_VOLUME
bgm.Looped = true
bgm.PlaybackSpeed = 1
bgm.Parent = SoundService

task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({ bgm })
	end)
end)

local function playIntroBGM()
	-- Restore the intro volume every time the wheel opens. The same Sound is
	-- also used for gameplay music, so it may already be playing quietly.
	bgm.Volume = INTRO_BGM_VOLUME
	if not bgm.IsLoaded then
		pcall(function()
			ContentProvider:PreloadAsync({ bgm })
		end)
	end
	if not bgm.IsPlaying then
		bgm.TimePosition = 0
		bgm:Play()
	end
end

local function stopIntroBGM()
	if not bgm.IsPlaying then
		bgm.Volume = GAMEPLAY_BGM_VOLUME
		if not bgm.IsLoaded then
			pcall(function()
				ContentProvider:PreloadAsync({ bgm })
			end)
		end
		bgm:Play()
		return
	end

	TweenService:Create(
		bgm,
		TweenInfo.new(
			0.8,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Volume = GAMEPLAY_BGM_VOLUME
		}
	):Play()
end

-- Start the shared BGM as soon as the client is ready. Character-select may
-- already be completed (or its close event may have fired before this script
-- finished wiring up), so relying only on playIntro() can leave the game
-- permanently silent.
task.defer(playIntroBGM)

local function normalizeAngle(angle)
	return ((angle % 360) + 360) % 360
end

local function getRaceWheelIndex(raceName)
	for index, name in ipairs(RACE_WHEEL_ORDER) do
		if name == raceName then
			return index
		end
	end

	warn("Race tidak ada di RaceWheelOrder:", raceName)
	return nil
end

local function getRaceTargetAngle(raceName)
	local index = getRaceWheelIndex(raceName)
	if not index then
		return nil
	end

	-- index 1 = Primordial di jam 12
	-- index berikutnya bergerak clockwise pada PNG.
	-- Disc harus diputar counter-clockwise agar wedge target sampai pointer.
	local wedgeAngle = (index - 1) * RACE_SEGMENT_ANGLE

	return normalizeAngle(
		RACE_ART_OFFSET - wedgeAngle
	)
end

local function getRaceIndexAtPointer(rotation)
	local artworkAngle = normalizeAngle(
		RACE_ART_OFFSET - rotation
	)

	local index =
		math.floor(
			(artworkAngle / RACE_SEGMENT_ANGLE) + 0.5
		) % 35

	return index + 1
end

local function getRaceNameAtPointer(rotation)
	return RACE_WHEEL_ORDER[
		getRaceIndexAtPointer(rotation)
	]
end

local function setRaceDiscToRace(raceDisc, raceName)
	local targetAngle = getRaceTargetAngle(raceName)
	if targetAngle == nil then
		return false
	end
	raceDisc.Rotation = targetAngle
	return true
end

local function spinRaceDisc(raceDisc, raceName, duration, liveLabel)
	local targetAngle = getRaceTargetAngle(raceName)

	if targetAngle == nil then
		return nil
	end

	local currentRotation = raceDisc.Rotation
	local currentNormalized = normalizeAngle(currentRotation)

	-- Jarak tambahan yang dibutuhkan dari posisi sekarang
	-- menuju posisi target.
	local delta = normalizeAngle(
		targetAngle - currentNormalized
	)

	-- 6 putaran penuh + berhenti tepat di center wedge.
	local fullSpins = math.random(6, 8)

	local finalRotation =
		currentRotation
		+ (fullSpins * 360)
		+ delta

	local tween = TweenService:Create(
		raceDisc,
		TweenInfo.new(
			duration or 3,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		{
			Rotation = finalRotation
		}
	)

	local liveConnection
	local lastRace

	if liveLabel then
		liveConnection = RunService.RenderStepped:Connect(function()
			local shownRace =
				getRaceNameAtPointer(raceDisc.Rotation)

			if shownRace ~= lastRace then
				lastRace = shownRace
				liveLabel.Text = string.upper(shownRace)
			end
		end)
	end

	tween.Completed:Once(function()
		if liveConnection then
			liveConnection:Disconnect()
			liveConnection = nil
		end

		-- PENTING:
		-- snap ke nilai exact supaya tidak ada error decimal Tween.
		raceDisc.Rotation = targetAngle

		if liveLabel then
			liveLabel.Text = string.upper(raceName)
		end

		-- Debug untuk memastikan hasil visual == hasil server
		local actualRace =
			getRaceNameAtPointer(raceDisc.Rotation)

		print(
			"[RACE WHEEL]",
			"SERVER =", raceName,
			"POINTER =", actualRace,
			"ROTATION =", raceDisc.Rotation
		)

		if actualRace ~= raceName then
			warn(
				"RACE WHEEL MISMATCH!",
				"Expected:", raceName,
				"Pointer:", actualRace
			)
		end
	end)

	tween:Play()
	return tween
end

local currentState
-- Only the initial profile load may open the onboarding intro.
-- Combat state updates must never reopen it.
local hasReceivedInitialState = false
local selectedCategory = "Race"
local localCooldowns = {}
local introRunning = false

local screen = Instance.new("ScreenGui")
screen.Name = "FATEBORN_UI"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

task.spawn(function()
	local preloaders = {}

	local function queueAssets(assetTable)
		for _, assetId in pairs(assetTable) do
			local image = Instance.new("ImageLabel")
			image.BackgroundTransparency = 1
			image.Image = assetId
			table.insert(preloaders, image)
		end
	end

	queueAssets(WHEEL_ASSETS)
	queueAssets(RACE_WHEEL_ASSETS)

	pcall(function()
		ContentProvider:PreloadAsync(preloaders)
	end)

	for _, image in ipairs(preloaders) do
		image:Destroy()
	end
end)

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function stroke(parent, color, transparency, thickness)
	local object = Instance.new("UIStroke")
	object.Color = color or COLORS.Gold
	object.Transparency = transparency or 0
	object.Thickness = thickness or 1
	object.Parent = parent
	return object
end

local function padding(parent, left, right, top, bottom)
	local object = Instance.new("UIPadding")
	object.PaddingLeft = UDim.new(0, left or 0)
	object.PaddingRight = UDim.new(0, right or left or 0)
	object.PaddingTop = UDim.new(0, top or left or 0)
	object.PaddingBottom = UDim.new(0, bottom or top or left or 0)
	object.Parent = parent
	return object
end

local function label(parent, text, size, position, font, color, textSize, align)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Text = text or ""
	object.Size = size or UDim2.fromScale(1, 1)
	object.Position = position or UDim2.fromOffset(0, 0)
	object.Font = font or Enum.Font.Gotham
	object.TextColor3 = color or COLORS.Text
	object.TextSize = textSize or 14
	object.TextXAlignment = align or Enum.TextXAlignment.Left
	object.TextWrapped = true
	object.Parent = parent
	return object
end

local function button(parent, text, size, position, accent)
	local object = Instance.new("TextButton")
	object.AutoButtonColor = false
	object.Text = text
	object.Size = size
	object.Position = position or UDim2.fromOffset(0, 0)
	object.BackgroundColor3 = accent or COLORS.PanelTwo
	object.TextColor3 = COLORS.Text
	object.Font = Enum.Font.GothamBold
	object.TextSize = 13
	object.BorderSizePixel = 0
	object.Parent = parent
	round(object, 8)
	object.MouseEnter:Connect(function()
		TweenService:Create(object, TweenInfo.new(0.12), { BackgroundColor3 = (accent or COLORS.PanelTwo):Lerp(Color3.new(1, 1, 1), 0.12) }):Play()
	end)
	object.MouseLeave:Connect(function()
		TweenService:Create(object, TweenInfo.new(0.12), { BackgroundColor3 = accent or COLORS.PanelTwo }):Play()
	end)
	return object
end

local function formatNumber(value)
	value = math.floor(value or 0)
	if value >= 1000000 then
		return string.format("%.2fM", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.1fK", value / 1000)
	end
	return tostring(value)
end

local dim = Instance.new("Frame")
dim.Name = "Dim"
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = COLORS.Ink
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Visible = false
dim.ZIndex = 20
dim.Parent = screen

local titleBar = Instance.new("Frame")
titleBar.Name = "GameplayTitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 56)
titleBar.BackgroundColor3 = COLORS.Ink
titleBar.BackgroundTransparency = 0.08
titleBar.BorderSizePixel = 0
titleBar.Parent = screen

local brand = label(titleBar, "FATEBORN", UDim2.fromOffset(230, 54), UDim2.fromOffset(22, 0), Enum.Font.GothamBlack, COLORS.Text, 22)
local brandAccent = label(titleBar, "BORN WEAK. ROLL YOUR DESTINY.", UDim2.fromOffset(270, 20), UDim2.fromOffset(170, 19), Enum.Font.GothamMedium, COLORS.Gold, 9)

local currencies = label(titleBar, "", UDim2.new(0, 510, 1, 0), UDim2.new(1, -530, 0, 0), Enum.Font.GothamBold, COLORS.Text, 13, Enum.TextXAlignment.Right)

local hud = Instance.new("Frame")
hud.Name = "GameplayStatusHUD"
hud.Size = UDim2.fromOffset(335, 162)
hud.Position = UDim2.fromOffset(20, 75)
hud.BackgroundColor3 = COLORS.Panel
hud.BackgroundTransparency = 0.08
hud.BorderSizePixel = 0
hud.Parent = screen
round(hud, 12)
stroke(hud, Color3.fromRGB(65, 75, 99), 0.35)

local identity = label(hud, "AWAITING FATE", UDim2.new(1, -24, 0, 36), UDim2.fromOffset(14, 10), Enum.Font.GothamBlack, COLORS.Gold, 18)
local power = label(hud, "POWER 0", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 46), Enum.Font.GothamBold, COLORS.Text, 13)
local level = label(hud, "LEVEL 1", UDim2.fromOffset(92, 20), UDim2.fromOffset(14, 73), Enum.Font.GothamBold, COLORS.Muted, 11)

local expBack = Instance.new("Frame")
expBack.Size = UDim2.new(1, -124, 0, 8)
expBack.Position = UDim2.fromOffset(106, 79)
expBack.BackgroundColor3 = Color3.fromRGB(42, 48, 66)
expBack.BorderSizePixel = 0
expBack.Parent = hud
round(expBack, 8)
local expFill = Instance.new("Frame")
expFill.Size = UDim2.fromScale(0, 1)
expFill.BackgroundColor3 = COLORS.Gold
expFill.BorderSizePixel = 0
expFill.Parent = expBack
round(expFill, 8)

local quest = label(hud, "QUEST — Defeat enemies 0/5", UDim2.new(1, -28, 0, 42), UDim2.fromOffset(14, 104), Enum.Font.GothamMedium, COLORS.Text, 12)

local menu = Instance.new("Frame")
menu.Name = "GameplayMenuBar"
menu.Size = UDim2.fromOffset(505, 42)
menu.Position = UDim2.fromOffset(20, 246)
menu.BackgroundTransparency = 1
menu.Parent = screen
local wheelToggle = button(menu, "G  WHEEL", UDim2.fromOffset(158, 40), UDim2.fromOffset(0, 0), COLORS.PanelTwo)
local inspectToggle = button(menu, "TAB  INSPECT", UDim2.fromOffset(165, 40), UDim2.fromOffset(170, 0), COLORS.PanelTwo)
local boostToggle = button(menu, "B  BOOSTS", UDim2.fromOffset(158, 40), UDim2.fromOffset(347, 0), Color3.fromRGB(72, 48, 31))

local notificationStack = Instance.new("Frame")
notificationStack.Name = "GameplayNotifications"
notificationStack.Size = UDim2.fromOffset(520, 220)
notificationStack.Position = UDim2.new(0.5, -260, 0, 70)
notificationStack.BackgroundTransparency = 1
notificationStack.Parent = screen
local notifLayout = Instance.new("UIListLayout")
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notificationStack

local function notify(text, kind)
	local accent = kind == "Boss" and COLORS.Red or (kind == "Reward" and COLORS.Green or COLORS.Gold)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.fromOffset(500, 46)
	toast.BackgroundColor3 = COLORS.Panel
	toast.BackgroundTransparency = 1
	toast.BorderSizePixel = 0
	toast.Parent = notificationStack
	round(toast, 8)
	stroke(toast, accent, 0.2, 1.5)
	local textLabel = label(toast, text, UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), Enum.Font.GothamBold, accent, 14, Enum.TextXAlignment.Center)
	textLabel.TextTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.08 }):Play()
	TweenService:Create(textLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(3.2, function()
		TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		task.wait(0.35)
		toast:Destroy()
	end)
end

local actionBar = Instance.new("Frame")
actionBar.Name = "GameplayActionBar"
actionBar.Size = UDim2.fromOffset(704, 86)
actionBar.Position = UDim2.new(0.5, -352, 1, -108)
actionBar.BackgroundColor3 = COLORS.Panel
actionBar.BackgroundTransparency = 0.06
actionBar.BorderSizePixel = 0
actionBar.Parent = screen
round(actionBar, 12)
stroke(actionBar, Color3.fromRGB(76, 82, 105), 0.35)

local actionButtons = {}
local keys = { "M1", "Q", "E", "R", "F", "T" }
for index = 1, 6 do
	local x = 10 + (index - 1) * 115
	local actionButton = button(actionBar, keys[index], UDim2.fromOffset(105, 66), UDim2.fromOffset(x, 10), index == 1 and Color3.fromRGB(49, 56, 75) or Color3.fromRGB(38, 46, 66))
	actionButton.Text = ""
	local keyLabel = label(actionButton, keys[index], UDim2.fromOffset(28, 22), UDim2.fromOffset(7, 5), Enum.Font.GothamBlack, COLORS.Gold, 11, Enum.TextXAlignment.Center)
	local moveLabel = label(actionButton, index == 1 and "Basic Attack" or "Skill", UDim2.new(1, -10, 0, 32), UDim2.fromOffset(5, 29), Enum.Font.GothamBold, COLORS.Text, 10, Enum.TextXAlignment.Center)
	local cooldownLabel = label(actionButton, "", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, COLORS.Text, 21, Enum.TextXAlignment.Center)
	cooldownLabel.BackgroundColor3 = COLORS.Ink
	cooldownLabel.BackgroundTransparency = 1
	cooldownLabel.Visible = false
	cooldownLabel.ZIndex = 5
	actionButtons[index] = { Button = actionButton, Name = moveLabel, Cooldown = cooldownLabel, Key = keyLabel }
end

local controls = label(screen, "SHIFT Sprint / CTRL Roll / SPACE Jump  •  Click enemy to attack  •  Q E R F T abilities", UDim2.fromOffset(600, 24), UDim2.new(0.5, -300, 1, -23), Enum.Font.GothamMedium, COLORS.Muted, 10, Enum.TextXAlignment.Center)
controls.Name = "GameplayControls"

local function setWheelHighlight(ring, index)
	if not ring then
		return
	end
	for _, child in ipairs(ring:GetChildren()) do
		if child:IsA("ImageLabel") and child.Name:match("^WheelSegment") then
			local currentIndex = tonumber(child.Name:match("(%d+)$")) or 1
			local isActive = currentIndex == index
			local baseColor = child:GetAttribute("BaseColor") or COLORS.PanelTwo
			TweenService:Create(child, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
				ImageColor3 = isActive and baseColor:Lerp(Color3.fromRGB(255, 235, 175), 0.26) or baseColor,
			}):Play()
		end
	end
end

local function rebuildWheelSegments(ring, items, diameter, zIndex)
	if not ring then
		return
	end
	ring:ClearAllChildren()
	ring.Rotation = 0
	local count = #items
	local wedgeAsset = WHEEL_ASSETS[count]
	if count == 0 or not wedgeAsset then
		warn("FATEBORN wheel only supports 6, 7, or 10 rewards", count)
		return
	end
	local angleStep = 360 / count
	for index, item in ipairs(items) do
		local angle = (index - 1) * angleStep
		local color = WHEEL_COLORS[((index - 1) % #WHEEL_COLORS) + 1]
		local segment = Instance.new("ImageLabel")
		segment.Name = "WheelSegment" .. index
		segment.AnchorPoint = Vector2.new(0.5, 0.5)
		segment.Size = UDim2.fromScale(1, 1)
		segment.Position = UDim2.fromScale(0.5, 0.5)
		segment.BackgroundTransparency = 1
		segment.Image = wedgeAsset
		segment.ImageColor3 = color
		segment.ScaleType = Enum.ScaleType.Fit
		segment.Rotation = angle
		segment.ZIndex = zIndex + 2
		segment.Parent = ring
		segment:SetAttribute("BaseColor", color)

		local content = Instance.new("Frame")
		content.Name = "RewardSlot" .. index
		content.AnchorPoint = Vector2.new(0.5, 0.5)
		content.Size = UDim2.fromOffset(diameter * (count == 10 and 0.16 or 0.19), diameter * 0.16)
		local theta = math.rad(angle - 90)
		local radius = diameter * 0.31
		content.Position = UDim2.fromOffset(diameter * 0.5 + math.cos(theta) * radius, diameter * 0.5 + math.sin(theta) * radius)
		content.BackgroundTransparency = 1
		content:SetAttribute("RewardIndex", index)
		content.ZIndex = zIndex + 4
		content.Parent = ring

		local jewel = Instance.new("Frame")
		jewel.Name = "Jewel"
		jewel.AnchorPoint = Vector2.new(0.5, 0.5)
		jewel.Size = UDim2.fromOffset(math.max(14, diameter * 0.04), math.max(14, diameter * 0.04))
		jewel.Position = UDim2.fromScale(0.5, 0.19)
		jewel.BackgroundColor3 = Config.GetRarityColor(item.Rarity)
		jewel.BorderSizePixel = 0
		jewel.Rotation = 45
		jewel.ZIndex = zIndex + 4
		jewel.Parent = content
		round(jewel, 3)
		stroke(jewel, Color3.fromRGB(255, 221, 150), 0.08, 1.5)

		local itemName = label(content, string.upper(item.Name), UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0.36, 0), Enum.Font.GothamBlack, Color3.fromRGB(255, 237, 198), math.max(8, math.floor(diameter * (count == 10 and 0.021 or 0.025))), Enum.TextXAlignment.Center)
		itemName.Name = "ItemName"
		itemName.ZIndex = zIndex + 4
		local rarityName = label(content, string.upper(item.Rarity), UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0.75, 0), Enum.Font.GothamBold, Config.GetRarityColor(item.Rarity), math.max(7, math.floor(diameter * 0.018)), Enum.TextXAlignment.Center)
		rarityName.Name = "RarityName"
		rarityName.ZIndex = zIndex + 4
	end
end

local function createCircularWheel(parent, diameter, position, zIndex)
	local disc = Instance.new("Frame")
	disc.Name = "CircularWheel"
	disc.Size = UDim2.fromOffset(diameter, diameter)
	disc.Position = position
	disc.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
	disc.BorderSizePixel = 0
	disc.ZIndex = zIndex
	disc.Parent = parent
	round(disc, 999)

	local ring = Instance.new("Frame")
	ring.Name = "SpinningRing"
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	ring.ZIndex = zIndex + 1
	ring.Parent = disc

	local ringOverlay = Instance.new("ImageLabel")
	ringOverlay.Name = "RingOverlay"
	ringOverlay.Size = UDim2.fromScale(1, 1)
	ringOverlay.BackgroundTransparency = 1
	ringOverlay.Image = WHEEL_ASSETS.Ring
	ringOverlay.ScaleType = Enum.ScaleType.Fit
	ringOverlay.ZIndex = zIndex + 8
	ringOverlay.Parent = disc

	local hub = Instance.new("Frame")
	hub.Name = "Hub"
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Size = UDim2.fromOffset(diameter * 0.22, diameter * 0.22)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.BackgroundTransparency = 1
	hub.ZIndex = zIndex + 9
	hub.Parent = disc
	local hubText = label(hub, "FATE\nWHEEL", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, Color3.fromRGB(255, 197, 77), math.max(10, math.floor(diameter * 0.037)), Enum.TextXAlignment.Center)
	hubText.ZIndex = zIndex + 10

	local pointer = Instance.new("ImageLabel")
	pointer.Name = "Pointer"
	pointer.AnchorPoint = Vector2.new(0.5, 0)
	pointer.Size = UDim2.fromOffset(diameter * 0.15, diameter * 0.15)
	pointer.Position = UDim2.new(0.5, 0, 0, -diameter * 0.035)
	pointer.BackgroundTransparency = 1
	pointer.Image = WHEEL_ASSETS.Pointer
	pointer.ScaleType = Enum.ScaleType.Fit
	pointer.ZIndex = zIndex + 12
	pointer.Parent = disc

	rebuildWheelSegments(ring, Config.Pools.Ability, diameter, zIndex)
	setWheelHighlight(ring, 1)
	return disc, ring, hub
end

local function spinCircularWheel(ring, duration, targetIndex)
	if not ring then
		return
	end
	local segmentCount = 0
	for _, child in ipairs(ring:GetChildren()) do
		if child:IsA("ImageLabel") and child.Name:match("^WheelSegment") then
			segmentCount += 1
		end
	end
	if segmentCount == 0 then
		return
	end
	local chosenIndex = math.clamp(tonumber(targetIndex) or math.random(1, segmentCount), 1, segmentCount)
	local segmentAngle = 360 / segmentCount
	local baseRotation = ring.Rotation % 360
	local desiredAngle = (360 - (((chosenIndex - 1) * segmentAngle) % 360)) % 360
	local delta = (desiredAngle - baseRotation + 360) % 360
	local target = ring.Rotation + (math.random(5, 7) * 360) + delta
	local tween = TweenService:Create(ring, TweenInfo.new(duration or 1.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = target })
	local orientationConnection = RunService.RenderStepped:Connect(function()
		for _, child in ipairs(ring:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^RewardSlot") then
				child.Rotation = -ring.Rotation
			end
		end
	end)
	tween:Play()
	tween.Completed:Wait()
	orientationConnection:Disconnect()
	ring.Rotation = target % 360
	for _, child in ipairs(ring:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^RewardSlot") then
			child.Rotation = -ring.Rotation
		end
	end
	setWheelHighlight(ring, chosenIndex)
end

local function createRaceWheel(parent, diameter, position, zIndex)
	local container = Instance.new("Frame")
	container.Name = "RaceWheel"
	container.Size = UDim2.fromOffset(diameter, diameter)
	container.Position = position
	container.BackgroundTransparency = 1
	container.ZIndex = zIndex
	container.Parent = parent

	local background = Instance.new("ImageLabel")
	background.Name = "BackgroundImage"
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.Size = UDim2.new(1.62, 0, 0.92, 0)
	background.Position = UDim2.fromScale(0.5, 0.52)
	background.BackgroundTransparency = 1
	background.Image = RACE_WHEEL_ASSETS.Background
	background.ScaleType = Enum.ScaleType.Crop
	background.ImageTransparency = 0.08
	background.ZIndex = zIndex
	background.Parent = container

	local disc = Instance.new("ImageLabel")
	disc.Name = "RaceDiscImage"
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Size = UDim2.fromScale(0.78, 0.78)
	disc.Position = UDim2.fromScale(0.5, 0.53)
	disc.BackgroundTransparency = 1
	disc.Image = RACE_WHEEL_ASSETS.Disc
	disc.ScaleType = Enum.ScaleType.Fit
	disc.ZIndex = zIndex + 2
	disc.Parent = container

	local discAspect = Instance.new("UIAspectRatioConstraint")
	discAspect.AspectRatio = 1
	discAspect.Parent = disc

	local outerFrame = Instance.new("ImageLabel")
	outerFrame.Name = "OuterFrameImage"
	outerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	outerFrame.Size = UDim2.fromScale(0.94, 0.94)
	outerFrame.Position = UDim2.fromScale(0.5, 0.53)
	outerFrame.BackgroundTransparency = 1
	outerFrame.Image = RACE_WHEEL_ASSETS.OuterFrame
	outerFrame.ScaleType = Enum.ScaleType.Fit
	outerFrame.ZIndex = zIndex + 4
	outerFrame.Parent = container

	local frameAspect = Instance.new("UIAspectRatioConstraint")
	frameAspect.AspectRatio = 1
	frameAspect.Parent = outerFrame

	local pointer = Instance.new("ImageLabel")
	pointer.Name = "CenterPointerImage"
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Size = UDim2.fromScale(0.40, 0.40)
	pointer.Position = UDim2.fromScale(0.5, 0.51)
	pointer.BackgroundTransparency = 1
	pointer.Image = RACE_WHEEL_ASSETS.Pointer
	pointer.ScaleType = Enum.ScaleType.Fit

	-- Asset pointer aslinya mengarah ke bawah.
	-- Dibalik 180° supaya ujung pointer menunjuk ke wedge jam 12.
	pointer.Rotation = 0

	-- Pointer STATIC: child container, bukan child RaceDiscImage.
	pointer.ZIndex = zIndex + 6
	pointer.Parent = container

	return container, disc, pointer
end

local wheelPanel = Instance.new("Frame")
wheelPanel.Name = "MenuWheelPanel"
wheelPanel.Size = UDim2.new(0.86, 0, 0.88, 0)
wheelPanel.Position = UDim2.new(0.07, 0, 0.065, 0)
wheelPanel.BackgroundColor3 = Color3.fromRGB(14, 10, 13)
wheelPanel.BorderSizePixel = 0
wheelPanel.Visible = false
wheelPanel.ZIndex = 30
wheelPanel.Parent = screen
round(wheelPanel, 14)
stroke(wheelPanel, Color3.fromRGB(202, 144, 55), 0.02, 3)
local wheelPanelGradient = Instance.new("UIGradient")
wheelPanelGradient.Color = ColorSequence.new(Color3.fromRGB(38, 23, 24), Color3.fromRGB(7, 10, 17))
wheelPanelGradient.Rotation = 110
wheelPanelGradient.Parent = wheelPanel

local wheelTitle = label(wheelPanel, "WHEELSPIN", UDim2.new(1, -90, 0, 54), UDim2.fromOffset(25, 9), Enum.Font.GothamBlack, Color3.fromRGB(255, 220, 148), 28)
local wheelSubtitle = label(wheelPanel, "PUTAR SENDIRI SETIAP BENANG TAKDIRMU", UDim2.new(1, -90, 0, 22), UDim2.fromOffset(27, 49), Enum.Font.GothamBold, Color3.fromRGB(200, 155, 77), 11)
local wheelClose = button(wheelPanel, "×", UDim2.fromOffset(44, 44), UDim2.new(1, -59, 0, 17), Color3.fromRGB(55, 31, 42))
wheelClose.TextSize = 23
wheelClose.ZIndex = 31

local categories = Instance.new("ScrollingFrame")
categories.Size = UDim2.new(0.27, -26, 1, -108)
categories.Position = UDim2.fromOffset(24, 90)
categories.BackgroundColor3 = COLORS.Ink
categories.BackgroundTransparency = 0.3
categories.BorderSizePixel = 0
categories.ScrollBarThickness = 4
categories.ScrollBarImageColor3 = COLORS.Gold
categories.CanvasSize = UDim2.fromOffset(0, #Config.Categories * 46 + 12)
categories.ZIndex = 31
categories.Parent = wheelPanel
round(categories, 10)
padding(categories, 8, 8, 8, 8)
local categoryLayout = Instance.new("UIListLayout")
categoryLayout.Padding = UDim.new(0, 6)
categoryLayout.Parent = categories

local categoryButtons = {}
local selectedTitle
local selectedValue
local selectedRarity
local oddsLabel
local costLabel
local spinButton
local pityLabel

local resultArea = Instance.new("Frame")
resultArea.Size = UDim2.new(0.73, -40, 1, -108)
resultArea.Position = UDim2.new(0.27, 16, 0, 90)
resultArea.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
resultArea.BackgroundTransparency = 0.08
resultArea.BorderSizePixel = 0
resultArea.ZIndex = 31
resultArea.Parent = wheelPanel
round(resultArea, 10)
stroke(resultArea, Color3.fromRGB(125, 88, 42), 0.18, 1.5)

selectedTitle = label(resultArea, "ABILITY", UDim2.new(1, -40, 0, 30), UDim2.fromOffset(20, 8), Enum.Font.GothamBlack, COLORS.Gold, 14, Enum.TextXAlignment.Center)
local resultWheel, wheelRing = createCircularWheel(resultArea, 320, UDim2.new(0.5, -160, 0, 34), 32)
local raceWheel, raceDisc, racePointer = createRaceWheel(resultArea, 350, UDim2.new(0.5, -175, 0, 18), 32)
raceWheel.Visible = false
local raceWheelBackground = raceWheel:FindFirstChild("BackgroundImage")
if raceWheelBackground then
	raceWheelBackground.Visible = false
end
selectedValue = label(resultArea, "—", UDim2.new(0, 150, 0, 42), UDim2.new(0.5, -75, 0, 161), Enum.Font.GothamBlack, COLORS.Text, 19, Enum.TextXAlignment.Center)
selectedValue.ZIndex = 36
selectedValue.Visible = false
selectedRarity = label(resultArea, "", UDim2.new(0, 130, 0, 22), UDim2.new(0.5, -65, 0, 202), Enum.Font.GothamBold, COLORS.Muted, 10, Enum.TextXAlignment.Center)
selectedRarity.ZIndex = 36
selectedRarity.Visible = false

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -50, 0, 1)
divider.Position = UDim2.fromOffset(25, 362)
divider.BackgroundColor3 = Color3.fromRGB(66, 75, 98)
divider.BorderSizePixel = 0
divider.ZIndex = 31
divider.Parent = resultArea

oddsLabel = label(resultArea, "ODDS", UDim2.new(1, -50, 0, 58), UDim2.fromOffset(25, 371), Enum.Font.GothamMedium, COLORS.Muted, 10)
pityLabel = label(resultArea, "PITY 0 / 20", UDim2.new(1, -50, 0, 24), UDim2.new(0, 25, 1, -105), Enum.Font.GothamBold, COLORS.Text, 11)
costLabel = label(resultArea, "10 FATE FRAGMENTS", UDim2.new(1, -50, 0, 25), UDim2.new(0, 25, 1, -78), Enum.Font.GothamBlack, COLORS.Gold, 12)
spinButton = button(resultArea, "SPIN ABILITY", UDim2.new(1, -50, 0, 48), UDim2.new(0, 25, 1, -55), Color3.fromRGB(108, 49, 131))
spinButton.TextColor3 = COLORS.Ink
spinButton.TextSize = 17
spinButton.ZIndex = 32
stroke(spinButton, COLORS.Gold, 0, 2)

local inspectPanel = Instance.new("Frame")
inspectPanel.Name = "MenuInspectPanel"
inspectPanel.Size = UDim2.fromOffset(430, 610)
inspectPanel.Position = UDim2.new(1, -455, 0.5, -290)
inspectPanel.BackgroundColor3 = COLORS.Panel
inspectPanel.BorderSizePixel = 0
inspectPanel.Visible = false
inspectPanel.ZIndex = 30
inspectPanel.Parent = screen
round(inspectPanel, 14)
stroke(inspectPanel, Color3.fromRGB(92, 103, 137), 0.15)
local inspectClose = button(inspectPanel, "×", UDim2.fromOffset(40, 40), UDim2.new(1, -52, 0, 12), Color3.fromRGB(55, 31, 42))
inspectClose.TextSize = 20
inspectClose.ZIndex = 32
local inspectName = label(inspectPanel, "CHARACTER PROFILE", UDim2.new(1, -72, 0, 34), UDim2.fromOffset(20, 15), Enum.Font.GothamBlack, COLORS.Text, 20)
inspectName.ZIndex = 31
local inspectSub = label(inspectPanel, "", UDim2.new(1, -40, 0, 26), UDim2.fromOffset(20, 49), Enum.Font.GothamBold, COLORS.Gold, 12)
inspectSub.ZIndex = 31
local inspectScroll = Instance.new("ScrollingFrame")
inspectScroll.Size = UDim2.new(1, -36, 1, -102)
inspectScroll.Position = UDim2.fromOffset(18, 88)
inspectScroll.BackgroundTransparency = 1
inspectScroll.BorderSizePixel = 0
inspectScroll.ScrollBarThickness = 4
inspectScroll.CanvasSize = UDim2.fromOffset(0, 680)
inspectScroll.ZIndex = 31
inspectScroll.Parent = inspectPanel
local inspectLayout = Instance.new("UIListLayout")
inspectLayout.Padding = UDim.new(0, 7)
inspectLayout.Parent = inspectScroll

local boostPanel = Instance.new("Frame")
boostPanel.Name = "MenuBoostPanel"
boostPanel.Size = UDim2.fromOffset(430, 380)
boostPanel.Position = UDim2.new(0.5, -215, 0.5, -190)
boostPanel.BackgroundColor3 = COLORS.Panel
boostPanel.BorderSizePixel = 0
boostPanel.Visible = false
boostPanel.ZIndex = 30
boostPanel.Parent = screen
round(boostPanel, 14)
stroke(boostPanel, COLORS.Gold, 0.15, 1.5)
local boostClose = button(boostPanel, "×", UDim2.fromOffset(40, 40), UDim2.new(1, -52, 0, 12), Color3.fromRGB(55, 31, 42))
boostClose.TextSize = 20
boostClose.ZIndex = 32
local boostTitle = label(boostPanel, "PROGRESSION BOOSTS", UDim2.new(1, -75, 0, 38), UDim2.fromOffset(20, 17), Enum.Font.GothamBlack, COLORS.Text, 20)
boostTitle.ZIndex = 31
local boostNote = label(boostPanel, "Acceleration only. Every reward remains earnable through play.", UDim2.new(1, -40, 0, 42), UDim2.fromOffset(20, 58), Enum.Font.GothamMedium, COLORS.Muted, 11)
boostNote.ZIndex = 31
local expPassButton = button(boostPanel, "PERMANENT x2 EXP", UDim2.new(1, -40, 0, 54), UDim2.fromOffset(20, 116), Color3.fromRGB(45, 65, 80))
local goldPassButton = button(boostPanel, "PERMANENT x2 GOLD", UDim2.new(1, -40, 0, 54), UDim2.fromOffset(20, 182), Color3.fromRGB(78, 59, 35))
local quadButton = button(boostPanel, "x4 EXP + GOLD  •  15 MINUTES", UDim2.new(1, -40, 0, 54), UDim2.fromOffset(20, 248), Color3.fromRGB(86, 43, 62))
local boostStatus = label(boostPanel, "CURRENT  x1 EXP  •  x1 GOLD", UDim2.new(1, -40, 0, 34), UDim2.fromOffset(20, 320), Enum.Font.GothamBlack, COLORS.Gold, 12, Enum.TextXAlignment.Center)
for _, object in ipairs({ expPassButton, goldPassButton, quadButton }) do object.ZIndex = 32 end

local function showDim()
	dim.Visible = wheelPanel.Visible or inspectPanel.Visible or boostPanel.Visible
end

local function openBoosts()
	if introRunning then return end
	boostPanel.Visible = not boostPanel.Visible
	wheelPanel.Visible = false
	inspectPanel.Visible = false
	showDim()
end

local function promptPass(id, labelText)
	if id <= 0 then
		notify(labelText .. " is ready; add its ID in Config.Monetization after publishing.", "Info")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

expPassButton.Activated:Connect(function() promptPass(Config.Monetization.DoubleExpPass, "x2 EXP") end)
goldPassButton.Activated:Connect(function() promptPass(Config.Monetization.DoubleGoldPass, "x2 Gold") end)
quadButton.Activated:Connect(function()
	if Config.Monetization.QuadBoostProduct <= 0 then
		notify("x4 timed boost is ready; add its Product ID in Config.Monetization.", "Info")
		return
	end
	MarketplaceService:PromptProductPurchase(player, Config.Monetization.QuadBoostProduct)
end)
boostClose.Activated:Connect(function() boostPanel.Visible = false; showDim() end)

local function updateCategorySelection()
	if not currentState or not currentState.Fate then
		return
	end
	for category, object in pairs(categoryButtons) do
		local unlocked = currentState.UnlockedCategories and currentState.UnlockedCategories[category]
		object.BackgroundColor3 = category == selectedCategory and Color3.fromRGB(63, 50, 34) or COLORS.PanelTwo
		object.TextColor3 = not unlocked and COLORS.Muted or (category == selectedCategory and COLORS.Gold or COLORS.Text)
		local owned = currentState.Fate[category]
		local display = Config.CategoryLabels[category] or category
		object.Text = string.upper(display) .. (not unlocked and "  •  LOCKED" or owned and ("  •  " .. owned.Name) or "  •  READY")
	end
	local fate = currentState.Fate[selectedCategory]
	selectedTitle.Text = (Config.CategoryLabels[selectedCategory] or selectedCategory):upper()
	selectedValue.Text = fate and fate.Name or "UNKNOWN"
	selectedRarity.Text = fate and fate.Rarity:upper() or ""
	selectedRarity.TextColor3 = fate and Config.GetRarityColor(fate.Rarity) or COLORS.Muted
	local isRace = selectedCategory == "Race"
	resultWheel.Visible = not isRace
	raceWheel.Visible = isRace

	if isRace then
		if fate then
			setRaceDiscToRace(raceDisc, fate.Name)
		else
			raceDisc.Rotation = RACE_ART_OFFSET
		end
	elseif wheelRing and Config.Pools[selectedCategory] then
		local pool = Config.Pools[selectedCategory]
		rebuildWheelSegments(wheelRing, pool, 320, 32)
		local selectedIndex = 1
		if fate then
			for index, item in ipairs(pool) do
				if item.Name == fate.Name then
					selectedIndex = index
					break
				end
			end
		end
		setWheelHighlight(wheelRing, selectedIndex)
	end
	local pity = currentState.Pity[selectedCategory] or 0
	local unlocked = currentState.UnlockedCategories and currentState.UnlockedCategories[selectedCategory]
	local requirement = Config.FateUnlocks[selectedCategory]
	pityLabel.Text = string.format("PITY %d / %d", pity, Config.PityThreshold)
	if not unlocked then
		costLabel.Text = string.format("LOCKED • %s • %s %d", requirement.Story, string.upper(requirement.Kind), requirement.Value)
		spinButton.Text = "LOCKED"
	elseif fate then
		costLabel.Text = string.format("COST 1 UNIVERSAL TICKET  •  YOU HAVE %d", currentState.RerollTickets or 0)
		spinButton.Text = "REROLL " .. string.upper(Config.CategoryLabels[selectedCategory] or selectedCategory)
	else
		costLabel.Text = "FIRST ASSIGNMENT • FREE"
		spinButton.Text = "CLAIM " .. string.upper(Config.CategoryLabels[selectedCategory] or selectedCategory)
	end
	local poolLines = {}
	for _, item in ipairs(Config.Pools[selectedCategory]) do
		table.insert(poolLines, string.format("%s  •  %s", item.Name, item.Rarity))
	end
	oddsLabel.Text = "POSSIBLE FATES\n" .. table.concat(poolLines, "     ") .. "\n\nPublished base rarity weights: Common 60%  •  Uncommon 25%  •  Rare 10%  •  Epic 4%  •  Legendary 0.8%  •  Mythic 0.18%  •  Secret 0.02%"
end

for _, category in ipairs(Config.Categories) do
	local display = Config.CategoryLabels[category] or category
	local categoryButton = button(categories, display, UDim2.new(1, -4, 0, 40), UDim2.fromOffset(0, 0), COLORS.PanelTwo)
	categoryButton.ZIndex = 32
	categoryButton.TextSize = 10
	categoryButton.Activated:Connect(function()
		selectedCategory = category
		updateCategorySelection()
	end)
	categoryButtons[category] = categoryButton
end

local function updateActionBar()
	if not currentState or not currentState.Fate or not currentState.Fate.Ability then
		return
	end
	local kit = Config.GetAbilityKit(currentState.Fate.Ability.Name)
	actionButtons[1].Name.Text = "Basic Attack"
	for slot = 1, 5 do
		actionButtons[slot + 1].Name.Text = kit[slot].Name
		actionButtons[slot + 1].Button.BackgroundColor3 = Config.GetRarityColor(currentState.Fate.Ability.Rarity):Lerp(COLORS.Ink, 0.72)
	end
end

local function updateHUD(state)
	if not state then
		return
	end
	currentState = state
	local race = state.Fate.Race
	local ability = state.Fate.Ability
	if race and ability then
		identity.Text = string.format("%s  •  %s", race.Name:upper(), ability.Name:upper())
		identity.TextColor3 = Config.GetRarityColor(ability.Rarity)
	else
		identity.Text = race and race.Name:upper() or "RACE NOT AWAKENED"
		identity.TextColor3 = COLORS.Gold
	end
	power.Text = string.format("POWER %s  •  MASTERY %d", formatNumber(state.Power), state.Mastery)
	level.Text = "LEVEL " .. state.Level
	expFill.Size = UDim2.fromScale(math.clamp(state.Exp / math.max(1, state.NextExp), 0, 1), 1)
	currencies.Text = string.format("◈ %s GOLD     ✦ %s ESSENCE     ◆ %s REROLL TICKET", formatNumber(state.Gold), formatNumber(state.Essence), formatNumber(state.RerollTickets or 0))
	if state.Boost then
		boostStatus.Text = string.format("CURRENT  x%d EXP  •  x%d GOLD", state.Boost.Exp, state.Boost.Gold)
		boostStatus.TextColor3 = (state.Boost.Exp > 1 or state.Boost.Gold > 1) and COLORS.Green or COLORS.Gold
	end
	local nextUnlock
	for _, category in ipairs(Config.Categories) do
		if not state.Fate[category] and not (state.UnlockedCategories and state.UnlockedCategories[category]) then
			nextUnlock = category
			break
		end
	end
	if nextUnlock then
		local req = Config.FateUnlocks[nextUnlock]
		quest.Text = string.format("STORY • %s\n%s %d to unlock %s", req.Story, string.upper(req.Kind), req.Value, string.upper(Config.CategoryLabels[nextUnlock] or nextUnlock))
	else
		quest.Text = string.format("DAILY FATE QUEST\nDefeat enemies  %d / %d", state.Quest.Progress, state.Quest.Target)
	end
	updateActionBar()
	updateCategorySelection()
end

local function openWheel()
	if introRunning then
		return
	end

	wheelPanel.Visible = not wheelPanel.Visible

	inspectPanel.Visible = false
	boostPanel.Visible = false

	showDim()
	updateCategorySelection()
end

local function clearInspectRows()
	for _, child in ipairs(inspectScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function inspectRow(field, value, rarity)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 37)
	row.BackgroundColor3 = COLORS.PanelTwo
	row.BackgroundTransparency = 0.18
	row.BorderSizePixel = 0
	row.ZIndex = 32
	row.Parent = inspectScroll
	round(row, 6)
	local fieldLabel = label(row, field, UDim2.new(0.43, -10, 1, 0), UDim2.fromOffset(10, 0), Enum.Font.GothamMedium, COLORS.Muted, 11)
	fieldLabel.ZIndex = 33
	local valueLabel = label(row, tostring(value), UDim2.new(0.57, -10, 1, 0), UDim2.new(0.43, 0, 0, 0), Enum.Font.GothamBold, rarity and Config.GetRarityColor(rarity) or COLORS.Text, 12)
	valueLabel.ZIndex = 33
end

local function openInspect(userId)
	if not userId then
		return
	end
	local success, data = pcall(function()
		return inspectPlayer:InvokeServer(userId)
	end)
	if not success or not data then
		notify("No inspectable player nearby.", "Error")
		return
	end
	clearInspectRows()
	inspectName.Text = data.DisplayName:upper()
	inspectSub.Text = string.format("@%s  •  LEVEL %d  •  POWER %s", data.Name, data.Level, formatNumber(data.Power))
	inspectRow("Power Rating", formatNumber(data.Power))
	for _, category in ipairs(Config.Categories) do
		local fate = data.Fate[category]
		if fate then
			inspectRow(Config.CategoryLabels[category] or category, fate.Name, fate.Rarity)
		end
	end
	inspectRow("Mastery", data.Mastery)
	inspectRow("Bosses Defeated", data.BossKills)
	inspectPanel.Visible = true
	wheelPanel.Visible = false
	boostPanel.Visible = false
	showDim()
end

local function nearestOtherPlayer()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local nearest, nearestDistance
	if not root then
		return nil
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (other.Character.HumanoidRootPart.Position - root.Position).Magnitude
			if distance <= 100 and (not nearestDistance or distance < nearestDistance) then
				nearest = other
				nearestDistance = distance
			end
		end
	end
	return nearest
end

local function cameraDirection()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetValue = player:FindFirstChild("TargetLockTarget")
	local target = targetValue and targetValue.Value
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")

	if root and targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
		local delta = targetRoot.Position - root.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if flat.Magnitude > 0.01 then
			return flat.Unit
		end
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new(0, 0, -1)
	end
	local look = camera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	return flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
end

local function startCooldown(slot, duration)
	local entry = actionButtons[slot + 1]
	if not entry then
		return
	end
	local finish = os.clock() + duration
	localCooldowns[slot] = finish
	entry.Cooldown.Visible = true
	entry.Cooldown.BackgroundTransparency = 0.25
	task.spawn(function()
		while localCooldowns[slot] == finish and os.clock() < finish do
			entry.Cooldown.Text = string.format("%.1f", finish - os.clock())
			RunService.RenderStepped:Wait()
		end
		if localCooldowns[slot] == finish then
			entry.Cooldown.Visible = false
		end
	end)
end

local function useAbility(slot)
	if not currentState or not currentState.Fate.Ability or wheelPanel.Visible or inspectPanel.Visible or introRunning then
		return
	end
	local kit = Config.GetAbilityKit(currentState.Fate.Ability.Name)
	local move = kit[slot]
	if not move or (localCooldowns[slot] or 0) > os.clock() then
		return
	end
	actionRemote:FireServer("Ability", slot, cameraDirection())
	startCooldown(slot, move.Cooldown)
end

local function basicAttack()
	if wheelPanel.Visible or inspectPanel.Visible or introRunning then
		return
	end
	actionRemote:FireServer("Basic", 0, cameraDirection())
end

actionButtons[1].Button.Activated:Connect(basicAttack)
for slot = 1, 5 do
	actionButtons[slot + 1].Button.Activated:Connect(function()
		useAbility(slot)
	end)
end

wheelToggle.Activated:Connect(openWheel)

inspectClose.Activated:Connect(function()
	inspectPanel.Visible = false
	showDim()
end)
inspectToggle.Activated:Connect(function()
	local nearest = nearestOtherPlayer()
	if nearest then
		openInspect(nearest.UserId)
	else
		openInspect(player.UserId)
		notify("No other player nearby — showing your own Fate.", "Info")
	end
end)
boostToggle.Activated:Connect(openBoosts)

spinButton.Activated:Connect(function()
	if spinButton:GetAttribute("Busy") or not currentState then
		return
	end
	if not (currentState.UnlockedCategories and currentState.UnlockedCategories[selectedCategory]) then
		local requirement = Config.FateUnlocks[selectedCategory]
		notify(string.format("LOCKED — %s requires %s %d.", requirement.Story, requirement.Kind, requirement.Value), "Error")
		return
	end
	spinButton:SetAttribute("Busy", true)
	spinButton.Text = "FATE IS TURNING..."
	local isFirstAssignment = not currentState.Fate[selectedCategory]
	local success, result = pcall(function()
		if isFirstAssignment then
			return awakenFate:InvokeServer(selectedCategory)
		end
		return rerollFate:InvokeServer(selectedCategory)
	end)
	local targetIndex = 1
	if success and result and result.Ok then
		if selectedCategory == "Race" then
			local tween = spinRaceDisc(raceDisc, result.Result.Name, 2.25, selectedTitle)
			if tween then
				tween.Completed:Wait()
			end
		else
			for index, item in ipairs(Config.Pools[selectedCategory]) do
				if item.Name == result.Result.Name then
					targetIndex = index
					break
				end
			end
			spinCircularWheel(wheelRing, 1.8, targetIndex)
		end
	elseif selectedCategory ~= "Race" then
		spinCircularWheel(wheelRing, 0.7, targetIndex)
	end

	if success and result and result.Ok then
		currentState = result.State
		selectedValue.Text = result.Result.Name
		selectedRarity.Text = result.Result.Rarity:upper()
		selectedRarity.TextColor3 = Config.GetRarityColor(result.Result.Rarity)
		updateHUD(currentState)
		notify(string.format("%s — %s", result.Result.Rarity, result.Result.Name), result.Result.Rarity == "Common" and "Info" or "Reward")
	else
		notify(result and result.Message or "The Wheel rejected this request.", "Error")
		updateCategorySelection()
	end
	spinButton:SetAttribute("Busy", false)
	updateCategorySelection()
end)

local intro = Instance.new("Frame")
intro.Name = "MenuIntro"
intro.Size = UDim2.fromScale(1, 1)
intro.BackgroundColor3 = COLORS.Ink
intro.BorderSizePixel = 0
intro.Visible = false
intro.ZIndex = 100
intro.Parent = screen

local introBackground = Instance.new("ImageLabel")
introBackground.Name = "RaceFullscreenBackground"
introBackground.AnchorPoint = Vector2.new(0.5, 0.5)
introBackground.Position = UDim2.fromScale(0.5, 0.5)
introBackground.Size = UDim2.fromScale(1, 1)
introBackground.BackgroundTransparency = 1
introBackground.Image = RACE_WHEEL_ASSETS.Background
introBackground.ScaleType = Enum.ScaleType.Crop
introBackground.ZIndex = 101
introBackground.Parent = intro

local introVignette = Instance.new("UIGradient")
introVignette.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 7, 13)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 14, 29)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 13)),
})
introVignette.Rotation = 25
introVignette.Parent = intro
local introContent = Instance.new("Frame")
introContent.Name = "ResponsiveIntroCanvas"
introContent.AnchorPoint = Vector2.new(0.5, 0.5)
introContent.Size = UDim2.fromOffset(1600, 900)
introContent.Position = UDim2.fromScale(0.5, 0.5)
introContent.BackgroundTransparency = 1
introContent.ZIndex = 102
introContent.Parent = intro
local introScale = Instance.new("UIScale")
introScale.Name = "ViewportScale"
introScale.Parent = introContent
local function updateIntroScale()
	local viewport = intro.AbsoluteSize
	if viewport.X > 0 and viewport.Y > 0 then
		introScale.Scale = math.min(viewport.X / 1600, viewport.Y / 900)
	end
end
intro:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateIntroScale)
task.defer(updateIntroScale)
local introKicker = label(intro, "THE WHEEL AWAITS YOUR HAND", UDim2.new(1, -80, 0, 28), UDim2.fromOffset(40, 28), Enum.Font.GothamBold, COLORS.Gold, 12, Enum.TextXAlignment.Center)
introKicker.ZIndex = 120
local introTitle = label(intro, "SPIN YOUR FATE", UDim2.new(1, -80, 0, 62), UDim2.fromOffset(40, 66), Enum.Font.GothamBlack, Color3.fromRGB(255, 224, 158), 38, Enum.TextXAlignment.Center)
introTitle.ZIndex = 120
local introText = label(intro, "Setiap kategori hanya berputar saat kamu menekan tombolnya.", UDim2.new(1, -160, 0, 42), UDim2.fromOffset(80, 132), Enum.Font.GothamMedium, COLORS.Muted, 14, Enum.TextXAlignment.Center)
introText.ZIndex = 120
local introWheel, introRing = createCircularWheel(introContent, 560, UDim2.new(0.5, -280, 0, 196), 101)
local introRaceWheel, introRaceDisc, introRacePointer = createRaceWheel(introContent, 620, UDim2.new(0.5, -310, 0, 166), 101)

local introRaceLocalBackground = introRaceWheel:FindFirstChild("BackgroundImage")

if introRaceLocalBackground then
	introRaceLocalBackground.Visible = false
end

introRaceWheel.Visible = false
local birthButton = Instance.new("TextButton")
birthButton.Name = "FirstFateSpin"
birthButton.AnchorPoint = Vector2.new(0.5, 0.5)
birthButton.Size = UDim2.fromOffset(370, 62)
birthButton.Position = UDim2.new(0.5, 0, 0, 826)
birthButton.BackgroundColor3 = Color3.fromRGB(91, 41, 112)
birthButton.BorderSizePixel = 0
birthButton.AutoButtonColor = false
birthButton.Text = "SPIN RACE"
birthButton.TextWrapped = true
birthButton.TextColor3 = COLORS.Ink
birthButton.Font = Enum.Font.GothamBlack
birthButton.TextSize = 20
birthButton.ZIndex = 106
birthButton.Parent = introContent
round(birthButton, 12)
stroke(birthButton, COLORS.Gold, 0, 2)
birthButton.MouseEnter:Connect(function()
	TweenService:Create(birthButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(126, 57, 151) }):Play()
end)
birthButton.MouseLeave:Connect(function()
	TweenService:Create(birthButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(91, 41, 112) }):Play()
end)

local cancelBirthButton = button(introContent, "←  CANCEL", UDim2.fromOffset(220, 50), UDim2.fromOffset(300, 832), Color3.fromRGB(47, 31, 48))
cancelBirthButton.Name = "CancelCharacterCreation"
cancelBirthButton.TextColor3 = COLORS.Text
cancelBirthButton.TextSize = 13
cancelBirthButton.ZIndex = 106
cancelBirthButton.Visible = false
stroke(cancelBirthButton, Color3.fromRGB(190, 116, 147), 1.5)

cancelBirthButton.Activated:Connect(function()
	if birthButton:GetAttribute("Busy") then
		return
	end
	cancelBirthButton.Visible = false
	birthButton.Visible = false
	introRunning = false
	intro.Visible = false
	intro.BackgroundTransparency = 0
	stopIntroBGM()

	local reopenEvent = player.PlayerScripts:FindFirstChild("ReopenCharacterSelect")
	if reopenEvent and reopenEvent:IsA("BindableEvent") then
		reopenEvent:Fire()
	else
		notify("Character Select is still loading. Try again.", "Error")
	end
end)

local reveal = label(intro, "", UDim2.fromOffset(360, 34), UDim2.new(0.5, -180, 0, 775), Enum.Font.GothamBlack, COLORS.Text, 17, Enum.TextXAlignment.Center)
reveal.ZIndex = 102

local birthCategoryIndex = 1

local function findNextBirthCategory()
	if not currentState or not currentState.Fate then
		return nil
	end

	-- Character creation only assigns Race. Every later Fate category, including
	-- Potential, is unlocked through its existing quest/story requirement.
	if not currentState.Fate.Race then
		return 1
	end

	return nil
end

local function prepareBirthCategory(index)
	birthCategoryIndex = index
	local category = Config.Categories[index]
	local display = Config.CategoryLabels[category] or category
	local isRace = category == "Race"

	introWheel.Visible = not isRace
	introRaceWheel.Visible = isRace

	if isRace then
		introRaceDisc.Rotation = RACE_ART_OFFSET
	else
		rebuildWheelSegments(introRing, Config.Pools[category], 560, 101)
		setWheelHighlight(introRing, 0)
	end

	introTitle.Text = string.upper(display)
	introTitle.TextColor3 = Color3.fromRGB(255, 224, 158)
	introText.Text = "Tekan SPIN untuk menentukan " .. display .. "."
	birthButton.Text = "SPIN " .. string.upper(display)
	birthButton.Visible = true
	birthButton:SetAttribute("Busy", false)
end

local function playIntro()
	reveal.Text = ""

	local nextIndex = findNextBirthCategory()

	if not nextIndex then
		introRunning = false
		cancelBirthButton.Visible = false
		intro.Visible = false

		stopIntroBGM()

		actionRemote:FireServer(
			"IntroSeen",
			0,
			Vector3.new(0, 0, -1)
		)

		return
	end

	introRunning = true
	intro.Visible = true
	cancelBirthButton.Visible = true

	-- BGM HANYA UNTUK INTRO
	playIntroBGM()

	prepareBirthCategory(nextIndex)
end

local homeButton = button(screen, "☰  CHARACTERS", UDim2.fromOffset(150, 42), UDim2.fromOffset(12, 300), Color3.fromRGB(43, 54, 78))
homeButton.Name = "OpenCharacterSelect"
homeButton.ZIndex = 90
homeButton.TextSize = 13
homeButton.Visible = false

local characterSelectClosed = player.PlayerScripts:FindFirstChild("CharacterSelectClosed")
if not characterSelectClosed then
	characterSelectClosed = Instance.new("BindableEvent")
	characterSelectClosed.Name = "CharacterSelectClosed"
	characterSelectClosed.Parent = player.PlayerScripts
end

characterSelectClosed.Event:Connect(function(selectedState)
	if selectedState then
		currentState = selectedState
		hasReceivedInitialState = true
		updateHUD(selectedState)
		if not selectedState.SeenIntro or not selectedState.Fate.Race then
			homeButton.Visible = false
			playIntro()
			return
		end
	end
	homeButton.Visible = currentState ~= nil and currentState.SeenIntro == true and not introRunning
end)

homeButton.Activated:Connect(function()
	homeButton.Visible = false
	wheelPanel.Visible = false
	inspectPanel.Visible = false
	boostPanel.Visible = false
	intro.Visible = false
	showDim()

	local selectEvent = player.PlayerScripts:FindFirstChild("ReopenCharacterSelect")
	if selectEvent and selectEvent:IsA("BindableEvent") then
		selectEvent:Fire()
	else
		homeButton.Visible = true
		notify("Character menu is still loading. Try again.", "Error")
	end
end)

birthButton.Activated:Connect(function()
	if not currentState or birthButton:GetAttribute("Busy") then
		return
	end
	local category = Config.Categories[birthCategoryIndex]
	local display = Config.CategoryLabels[category] or category
	birthButton:SetAttribute("Busy", true)
	birthButton.Text = "SPINNING " .. string.upper(display) .. "..."

	if category == "Race" then
		introTitle.Text = "???"
		introTitle.TextColor3 = COLORS.Text
		introText.Text = "Takdir sedang memilih Race..."
	else
		introText.Text = "Hanya " .. display .. " yang sedang ditentukan."
	end

	task.spawn(function()
		local success, result = pcall(function()
			return awakenFate:InvokeServer(category)
		end)
		if not success or not result or not result.Ok then
			birthButton.Text = "TRY SPIN " .. string.upper(display) .. " AGAIN"
			birthButton:SetAttribute("Busy", false)
			introText.Text = result and result.Message or "Fate could not answer. Try once more."
			return
		end
		currentState = result.State

		if category == "Race" then
			local tween = spinRaceDisc(introRaceDisc, result.Result.Name, 2.25, introTitle)
			if tween then
				tween.Completed:Wait()
			end
		else
			local targetIndex = 1
			for index, item in ipairs(Config.Pools[category]) do
				if item.Name == result.Result.Name then
					targetIndex = index
					break
				end
			end
			spinCircularWheel(introRing, 2.25, targetIndex)
		end

		updateHUD(currentState)
		reveal.TextTransparency = 1
		reveal.TextColor3 = Config.GetRarityColor(result.Result.Rarity)
		reveal.Text = string.format("%s\n%s", result.Result.Name, string.upper(result.Result.Rarity))
		TweenService:Create(reveal, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
		task.wait(1.05)
		birthButton.Visible = false
		cancelBirthButton.Visible = false

		if category == "Race" then
			introTitle.Text = string.upper(result.Result.Name)
			introTitle.TextColor3 = Config.GetRarityColor(result.Result.Rarity)
			introText.Text = string.upper(result.Result.Rarity) .. "  •  YOUR RACE IS AWAKENED"
		else
			introTitle.Text = "FATE AWAKENED"
			introText.Text = "Kategori Fate lain akan terbuka melalui quest dan story."
		end

		reveal.Text = string.format("%s\nPOWER %s", currentState.Fate.Race.Name, formatNumber(currentState.Power))
		actionRemote:FireServer("IntroSeen", 0, Vector3.new(0, 0, -1))
		task.wait(1.6)

		-- Fade musik bersamaan dengan fade intro
		stopIntroBGM()

		TweenService:Create(
			intro,
			TweenInfo.new(0.65),
			{
				BackgroundTransparency = 1
			}
		):Play()

		task.wait(0.85)

		intro.Visible = false
		intro.BackgroundTransparency = 0
		introRunning = false
		homeButton.Visible = true

		notify(
			"Story started: defeat 5 enemies to unlock Potential.",
			"Reward"
		)
	end)
end)

local SHIFT_DOUBLE_TAP_WINDOW = 0.32
local lastShiftTap = 0

local function setSprinting(enabled)
	actionRemote:FireServer("Sprint", enabled, cameraDirection())
end

local defenseBlocking = false
local function setDefenseBlocking(enabled)
	if defenseBlocking == enabled then return end
	defenseBlocking = enabled
	defenseRemote:FireServer("Block", enabled)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed
		and input.KeyCode ~= Enum.KeyCode.LeftShift
		and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if input.KeyCode == Enum.KeyCode.V then
		setDefenseBlocking(true)
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouse = player:GetMouse()
		local target = mouse.Target
		local model = target and target:FindFirstAncestorOfClass("Model")
		local userId = model and model:GetAttribute("FatebornPlayerId")
		if userId and userId ~= player.UserId then
			openInspect(userId)
		else
			basicAttack()
		end
	elseif input.KeyCode == Enum.KeyCode.Q then useAbility(1)
	elseif input.KeyCode == Enum.KeyCode.E then useAbility(2)
	elseif input.KeyCode == Enum.KeyCode.R then useAbility(3)
	elseif input.KeyCode == Enum.KeyCode.F then useAbility(4)
	elseif input.KeyCode == Enum.KeyCode.T then useAbility(5)
	elseif input.KeyCode == Enum.KeyCode.G then openWheel()
	elseif input.KeyCode == Enum.KeyCode.B then openBoosts()
	elseif input.KeyCode == Enum.KeyCode.Tab then
		local nearest = nearestOtherPlayer()
		openInspect(nearest and nearest.UserId or player.UserId)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.V then
		setDefenseBlocking(false)
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	setDefenseBlocking(false)
end)

stateRemote.OnClientEvent:Connect(function(state, notice)
	updateHUD(state)
	homeButton.Visible = state and state.SeenIntro and not introRunning
	if state and not hasReceivedInitialState then
		hasReceivedInitialState = true
		if not state.SeenIntro or not state.Fate.Race then
			playIntro()
		end
	end
	if notice then
		notify(notice, "Reward")
	end
end)

announcementRemote.OnClientEvent:Connect(function(text, kind)
	notify(text, kind)
end)

local function showDefenseIndicator(position, text, color, scale)
	if typeof(position) ~= "Vector3" then return end
	local anchor = Instance.new("Part")
	anchor.Name = "CombatDefenseIndicator"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(.2,.2,.2)
	anchor.Position = position + Vector3.new(0,3.2,0)
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(math.floor(220*(scale or 1)),math.floor(54*(scale or 1)))
	gui.StudsOffsetWorldSpace = Vector3.new(0,.5,0)
	gui.Adornee = anchor
	gui.Parent = anchor

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.fromScale(1,1)
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextStrokeColor3 = Color3.new(0,0,0)
	textLabel.TextStrokeTransparency = .15
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true
	textLabel.Parent = gui

	TweenService:Create(anchor,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=anchor.Position+Vector3.new(0,2.1,0)}):Play()
	TweenService:Create(textLabel,TweenInfo.new(.65),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	task.delay(.75,function() if anchor.Parent then anchor:Destroy() end end)
end

defenseRemote.OnClientEvent:Connect(function(kind, position, extra)
	if kind == "Parry" then
		showDefenseIndicator(position,"PERFECT PARRY",Color3.fromRGB(255,221,92),1.15)
	elseif kind == "Block" then
		showDefenseIndicator(position,"BLOCK",Color3.fromRGB(116,194,255),.9)
	elseif kind == "Punish" then
		showDefenseIndicator(position,extra == "Advanced" and "ADVANCED COUNTER" or "PUNISH",Color3.fromRGB(255,108,91),1.05)
	elseif kind == "GuardBreak" then
		showDefenseIndicator(position,"GUARD BREAK",Color3.fromRGB(255,76,76),1)
	end
end)

-- CharacterSelect owns initial character selection.

print("FATEBORN client ready")
