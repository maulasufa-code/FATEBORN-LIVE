local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

local altHeld = false
local lastMenuState = nil

local GAMEPLAY_UI_NAMES = {
	GameplayTitleBar = true,
	GameplayStatusHUD = true,
	GameplayMenuBar = true,
	GameplayNotifications = true,
	GameplayActionBar = true,
	GameplayControls = true,
}

local MENU_PANEL_NAMES = {
	MenuIntro = true,
	MenuWheelPanel = true,
	MenuInspectPanel = true,
	MenuBoostPanel = true,
}

local function guiObjectActuallyVisible(object)
	if not object or not object:IsA("GuiObject") or not object.Visible then
		return false
	end
	local parent = object.Parent
	while parent and parent ~= playerGui do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		elseif parent:IsA("ScreenGui") and not parent.Enabled then
			return false
		end
		parent = parent.Parent
	end
	return true
end

local function isMenuState()
	if not playerGui then
		return false
	end

	local characterSelect = playerGui:FindFirstChild("FATEBORN_CHARACTER_SELECT")
	if characterSelect and characterSelect:IsA("ScreenGui") and characterSelect.Enabled then
		return true
	end

	local fatebornUi = playerGui:FindFirstChild("FATEBORN_UI")
	if fatebornUi and fatebornUi:IsA("ScreenGui") and fatebornUi.Enabled then
		for name in pairs(MENU_PANEL_NAMES) do
			local panel = fatebornUi:FindFirstChild(name)
			if guiObjectActuallyVisible(panel) then
				return true
			end
		end
	end

	return false
end

local function setGameplayUiVisible(visible)
	if not playerGui then
		return
	end

	local fatebornUi = playerGui:FindFirstChild("FATEBORN_UI")
	if fatebornUi then
		for name in pairs(GAMEPLAY_UI_NAMES) do
			local object = fatebornUi:FindFirstChild(name)
			if object and object:IsA("GuiObject") then
				object.Visible = visible
			end
		end
	end

	local staminaHud = playerGui:FindFirstChild("StaminaHUD")
	if staminaHud and staminaHud:IsA("ScreenGui") then
		staminaHud.Enabled = visible
	end

	local hotbar = playerGui:FindFirstChild("FATEBORN_HOTBAR")
	if hotbar and hotbar:IsA("ScreenGui") then
		hotbar.Enabled = visible
	end
end

local function applyState()
	local menuState = isMenuState()
	player:SetAttribute("GameplayActive", not menuState)

	if lastMenuState ~= menuState then
		lastMenuState = menuState
		setGameplayUiVisible(not menuState)
	end

	if menuState or altHeld then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		altHeld = true
		applyState()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		altHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
		applyState()
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	altHeld = false
end)

RunService:BindToRenderStep(
	"FatebornGameplayMouse",
	Enum.RenderPriority.Camera.Value + 2,
	function()
		applyState()
	end
)

applyState()
