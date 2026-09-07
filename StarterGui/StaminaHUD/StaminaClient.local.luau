local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local gui = script.Parent
local holder = gui:FindFirstChild("Holder")

if holder and holder:IsA("GuiObject") then
	holder.Visible = false
end

local character
local root
local hud
local fillSegments = {}

local BAR_HEIGHT = 38
local BAR_WIDTH = 4
local CURVE_AMOUNT = 3.2
local SCREEN_OFFSET_X = 100
local SCREEN_OFFSET_Y = -1
local SEGMENT_COUNT = 61

local function makeSegment(parent, name, color, zIndex)
	local segment = Instance.new("Frame")
	segment.Name = name
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.Size = UDim2.fromOffset(BAR_WIDTH, 2.6)
	segment.BackgroundColor3 = color
	segment.BorderSizePixel = 0
	segment.ZIndex = zIndex
	segment.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 0.7)
	corner.Parent = segment

	return segment
end

local function buildHud()
	if hud then
		hud:Destroy()
	end

	table.clear(fillSegments)

	hud = Instance.new("Frame")
	hud.Name = "CharacterStaminaArc"
	hud.AnchorPoint = Vector2.new(0.5, 0.5)
	hud.Size = UDim2.fromOffset(14, BAR_HEIGHT + 8)
	hud.BackgroundTransparency = 1
	hud.Visible = false
	hud.ZIndex = 30
	hud.Parent = gui

	for i = 1, SEGMENT_COUNT do
		local t = (i - 1) / (SEGMENT_COUNT - 1)
		local x = 3 + math.sin(t * math.pi) * CURVE_AMOUNT
		local y = 4 + t * BAR_HEIGHT
		local rotation = -5 + t * 10

		local back = makeSegment(hud, "Back" .. i, Color3.fromRGB(75, 61, 34), 30)
		back.Position = UDim2.fromOffset(x, y)
		back.Rotation = rotation
		back.BackgroundTransparency = 0.22

		local fill = makeSegment(hud, "Fill" .. i, Color3.fromRGB(255, 174, 10), 31)
		fill.Position = UDim2.fromOffset(x, y)
		fill.Rotation = rotation

		fillSegments[i] = fill
	end
end

local function updateFill()
	if #fillSegments == 0 then
		return
	end

	local maxStamina = math.max(1, player:GetAttribute("MaxStamina") or 100)
	local stamina = math.clamp(player:GetAttribute("Stamina") or maxStamina, 0, maxStamina)
	local ratio = stamina / maxStamina
	local exact = ratio * SEGMENT_COUNT

	for i, segment in ipairs(fillSegments) do
		local reverseIndex = SEGMENT_COUNT - i + 1
		local amount = math.clamp(exact - (reverseIndex - 1), 0, 1)
		segment.BackgroundTransparency = 1 - amount
	end
end

local function bindCharacter(newCharacter)
	character = newCharacter
	root = nil

	if character then
		root = character:WaitForChild("HumanoidRootPart", 5)
	end
end

buildHud()
bindCharacter(player.Character)
updateFill()

player.CharacterAdded:Connect(function(newCharacter)
	bindCharacter(newCharacter)
	updateFill()
end)

player:GetAttributeChangedSignal("Stamina"):Connect(updateFill)
player:GetAttributeChangedSignal("MaxStamina"):Connect(updateFill)

RunService.RenderStepped:Connect(function()
	if player:GetAttribute("GameplayActive") ~= true then
		if hud then hud.Visible = false end
		return
	end

	if not hud or not root or not root.Parent then
		if hud then hud.Visible = false end
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		hud.Visible = false
		return
	end

	local worldPoint = root.Position + Vector3.new(0, 1.1, 0)
	local screenPoint, onScreen = camera:WorldToViewportPoint(worldPoint)

	if not onScreen or screenPoint.Z <= 0 then
		hud.Visible = false
		return
	end

	hud.Visible = true
	hud.Position = UDim2.fromOffset(
		screenPoint.X + SCREEN_OFFSET_X,
		screenPoint.Y + SCREEN_OFFSET_Y
	)
end)
