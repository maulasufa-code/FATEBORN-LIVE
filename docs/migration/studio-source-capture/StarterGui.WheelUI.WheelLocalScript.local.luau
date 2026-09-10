local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
local wheelUI = playerGui:WaitForChild("WheelUI", 10)
local mainFrame = wheelUI:WaitForChild("MainFrame", 10)

local spinRemote = ReplicatedStorage:WaitForChild("SpinRaceEvent", 10)
local RaceData = require(ReplicatedStorage:WaitForChild("ZeroScript", 10):WaitForChild("Data", 10):WaitForChild("RaceData", 10))

local tierColors = {
	Common = Color3.fromRGB(160, 160, 160),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(80, 140, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
	Secret = Color3.fromRGB(255, 230, 90)
}

-- Clear existing children
for _, child in ipairs(mainFrame:GetChildren()) do
	child:Destroy()
end

mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BackgroundTransparency = 1

-- Full-screen wheel background image (static)
local wheelImage = Instance.new("ImageLabel")
wheelImage.Name = "WheelImage"
wheelImage.Size = UDim2.new(1, 0, 1, 0)
wheelImage.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelImage.AnchorPoint = Vector2.new(0.5, 0.5)
wheelImage.BackgroundTransparency = 1
wheelImage.Image = "rbxassetid://108444846902696"
wheelImage.ScaleType = Enum.ScaleType.Fit
wheelImage.ZIndex = 0
wheelImage.Parent = mainFrame

-- Build list of rollable races
local rollableRaces = {}
for _, race in ipairs(RaceData) do
	if (race.weight or 0) > 0 then
		table.insert(rollableRaces, race)
	end
end

-- Horizontal reel for race names
local reel = Instance.new("Frame")
reel.Name = "RaceReel"
reel.Size = UDim2.new(0.6, 0, 0.22, 0)
reel.Position = UDim2.new(0.5, 0, 0.5, 0)
reel.AnchorPoint = Vector2.new(0.5, 0.5)
reel.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
reel.BackgroundTransparency = 0.25
reel.BorderSizePixel = 0
reel.ClipsDescendants = true
reel.ZIndex = 3
reel.Parent = mainFrame

local reelCorner = Instance.new("UICorner")
reelCorner.CornerRadius = UDim.new(0, 12)
reelCorner.Parent = reel

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ReelScroll"
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
scrollFrame.HorizontalScrollBarInset = Enum.ScrollBarInset.None
scrollFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
scrollFrame.ScrollBarThickness = 0
scrollFrame.Parent = reel

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

local raceLabels = {}
local labelWidth = 120
for idx, race in ipairs(rollableRaces) do
	local label = Instance.new("TextButton")
	label.Name = race.name
	label.Size = UDim2.new(0, labelWidth, 0, 70)
	label.LayoutOrder = idx
	label.BackgroundColor3 = tierColors[race.tier] or Color3.fromRGB(120, 120, 120)
	label.Text = string.format("%s\n(%s)", race.name, race.tier)
	label.TextColor3 = Color3.fromRGB(20, 20, 20)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.AutoButtonColor = false
	label.ZIndex = 4
	label.Parent = scrollFrame

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 6)
	labelCorner.Parent = label

	raceLabels[race.name] = label
end

local totalWidth = (#rollableRaces * labelWidth) + ((#rollableRaces - 1) * 10)
scrollFrame.CanvasSize = UDim2.new(0, totalWidth + 40, 1, 0)

-- Spin button overlay
local spinButton = Instance.new("TextButton")
spinButton.Name = "SpinButton"
spinButton.Size = UDim2.new(0.3, 0, 0.08, 0)
spinButton.Position = UDim2.new(0.5, 0, 0.85, 0)
spinButton.AnchorPoint = Vector2.new(0.5, 0.5)
spinButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
spinButton.Text = "SPIN YOUR FATE"
spinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spinButton.Font = Enum.Font.GothamBold
spinButton.TextScaled = true
spinButton.ZIndex = 5
spinButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = spinButton

-- Result label overlay
local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(0.6, 0, 0.15, 0)
resultLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
resultLabel.AnchorPoint = Vector2.new(0.5, 0.5)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextWrapped = true
resultLabel.TextScaled = true
resultLabel.ZIndex = 5
resultLabel.Parent = mainFrame

local isSpinning = false
local pendingResult = nil

local function displayResult(result)
	resultLabel.Text = string.format("%s\n%s", result.name, result.tier)
end

local function startSpinAnimation()
	local targetX = scrollFrame.CanvasSize.X.Offset - scrollFrame.AbsoluteSize.X
	local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(scrollFrame, tweenInfo, { CanvasPosition = Vector2.new(targetX, 0) })
	tween:Play()
	return tween
end

spinButton.Activated:Connect(function()
	if isSpinning then return end
	isSpinning = true
	pendingResult = nil
	spinButton.Text = "SPINNING..."
	resultLabel.Text = ""

	local tween = startSpinAnimation()
	tween.Completed:Connect(function()
		isSpinning = false
		spinButton.Text = "SPIN YOUR FATE"
		if pendingResult then
			displayResult(pendingResult)
		end
	end)

	spinRemote:FireServer()
end)

spinRemote.OnClientEvent:Connect(function(result)
	if isSpinning then
		pendingResult = result
	else
		displayResult(result)
	end
end)
