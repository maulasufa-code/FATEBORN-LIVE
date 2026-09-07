local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")
local manage = ReplicatedStorage:WaitForChild("FatebornRemotes"):WaitForChild("ManageCharacters")

local function getBindable(name)
	local existing = playerScripts:FindFirstChild(name)
	if existing and existing:IsA("BindableEvent") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = playerScripts
	return event
end

local reopenEvent = getBindable("ReopenCharacterSelect")
local closedEvent = getBindable("CharacterSelectClosed")

local previous = playerGui:FindFirstChild("FATEBORN_CHARACTER_SELECT")
if previous then
	previous:Destroy()
end

local COLORS = {
	Ink = Color3.fromRGB(6, 9, 16),
	Panel = Color3.fromRGB(14, 19, 31),
	PanelRaised = Color3.fromRGB(22, 29, 45),
	Gold = Color3.fromRGB(239, 182, 72),
	GoldSoft = Color3.fromRGB(174, 124, 44),
	Text = Color3.fromRGB(241, 243, 249),
	Muted = Color3.fromRGB(146, 157, 181),
	Green = Color3.fromRGB(78, 218, 142),
	Red = Color3.fromRGB(177, 55, 70),
}

local gui = Instance.new("ScreenGui")
gui.Name = "FATEBORN_CHARACTER_SELECT"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local background = Instance.new("ImageLabel")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = COLORS.Ink
background.BorderSizePixel = 0
background.Image = "rbxassetid://82170075804483"
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 1
background.Parent = gui

local shade = Instance.new("Frame")
shade.Name = "Shade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(3, 6, 12)
shade.BackgroundTransparency = 0.18
shade.BorderSizePixel = 0
shade.ZIndex = 2
shade.Parent = gui

local shadeGradient = Instance.new("UIGradient")
shadeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 8, 15)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 28, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 8, 15)),
})
shadeGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.02),
	NumberSequenceKeypoint.new(0.5, 0.28),
	NumberSequenceKeypoint.new(1, 0.02),
})
shadeGradient.Rotation = 90
shadeGradient.Parent = shade

local canvas = Instance.new("Frame")
canvas.Name = "ResponsiveCanvas"
canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.Position = UDim2.fromScale(0.5, 0.5)
canvas.Size = UDim2.fromOffset(1500, 850)
canvas.BackgroundTransparency = 1
canvas.ZIndex = 3
canvas.Parent = gui

local canvasScale = Instance.new("UIScale")
canvasScale.Name = "ViewportScale"
canvasScale.Parent = canvas

local function updateScale()
	local viewport = gui.AbsoluteSize
	if viewport.X > 0 and viewport.Y > 0 then
		canvasScale.Scale = math.min(viewport.X / 1500, viewport.Y / 850)
	end
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
task.defer(updateScale)

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
	return item
end

local function outline(parent, color, thickness, transparency)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Thickness = thickness
	item.Transparency = transparency or 0
	item.Parent = parent
	return item
end

local function label(parent, text, size, position, font, textSize, color, alignment)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Size = size
	item.Position = position
	item.Font = font or Enum.Font.Gotham
	item.Text = text
	item.TextSize = textSize or 14
	item.TextColor3 = color or COLORS.Text
	item.TextXAlignment = alignment or Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.ZIndex = parent.ZIndex + 1
	item.Parent = parent
	return item
end

local function button(parent, text, size, position, color)
	local item = Instance.new("TextButton")
	item.Size = size
	item.Position = position
	item.BackgroundColor3 = color
	item.BorderSizePixel = 0
	item.AutoButtonColor = false
	item.Font = Enum.Font.GothamBlack
	item.Text = text
	item.TextSize = 14
	item.TextColor3 = COLORS.Ink
	item.ZIndex = parent.ZIndex + 2
	item.Parent = parent
	corner(item, 9)

	local baseColor = color
	local hoverColor = color:Lerp(Color3.new(1, 1, 1), 0.12)
	item.MouseEnter:Connect(function()
		TweenService:Create(item, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	item.MouseLeave:Connect(function()
		TweenService:Create(item, TweenInfo.new(0.12), { BackgroundColor3 = baseColor }):Play()
	end)
	return item
end

local brand = label(canvas, "FATEBORN", UDim2.fromOffset(420, 54), UDim2.fromOffset(540, 38), Enum.Font.GothamBlack, 42, COLORS.Gold, Enum.TextXAlignment.Center)
brand.TextStrokeColor3 = Color3.fromRGB(44, 24, 5)
brand.TextStrokeTransparency = 0.35

local title = label(canvas, "CHOOSE YOUR CHARACTER", UDim2.fromOffset(720, 48), UDim2.fromOffset(390, 96), Enum.Font.GothamBlack, 27, COLORS.Text, Enum.TextXAlignment.Center)
local subtitle = label(canvas, "THREE LIVES. THREE DESTINIES. EACH PROGRESS SAVES SEPARATELY.", UDim2.fromOffset(900, 28), UDim2.fromOffset(300, 142), Enum.Font.GothamMedium, 13, COLORS.Muted, Enum.TextXAlignment.Center)

local leftLine = Instance.new("Frame")
leftLine.Size = UDim2.fromOffset(300, 2)
leftLine.Position = UDim2.fromOffset(180, 121)
leftLine.BackgroundColor3 = COLORS.GoldSoft
leftLine.BorderSizePixel = 0
leftLine.ZIndex = 4
leftLine.Parent = canvas

local rightLine = leftLine:Clone()
rightLine.Position = UDim2.fromOffset(1020, 121)
rightLine.Parent = canvas

local cards = Instance.new("Frame")
cards.Name = "CharacterCards"
cards.Size = UDim2.fromOffset(1260, 465)
cards.Position = UDim2.fromOffset(120, 205)
cards.BackgroundTransparency = 1
cards.ZIndex = 4
cards.Parent = canvas

local status = label(canvas, "LOADING CHARACTER SLOTS...", UDim2.fromOffset(920, 34), UDim2.fromOffset(290, 695), Enum.Font.GothamBold, 13, COLORS.Muted, Enum.TextXAlignment.Center)
local hint = label(canvas, "ALT releases the cursor during gameplay", UDim2.fromOffset(620, 26), UDim2.fromOffset(440, 790), Enum.Font.GothamMedium, 11, COLORS.Muted, Enum.TextXAlignment.Center)

local backButton = button(canvas, "←  RETURN TO GAME", UDim2.fromOffset(210, 42), UDim2.fromOffset(36, 42), COLORS.PanelRaised)
backButton.TextColor3 = COLORS.Text
outline(backButton, COLORS.GoldSoft, 1.5, 0.25)
backButton.Visible = false

local activeSlot
local busy = false
local refresh

local function setStatus(message, color)
	status.Text = message
	status.TextColor3 = color or COLORS.Muted
end

local function invoke(action, slot)
	local ok, response = pcall(function()
		return manage:InvokeServer(action, slot)
	end)
	if not ok then
		return nil, "Connection failed. Try again."
	end
	if not response or not response.Ok then
		return nil, response and response.Message or "The character service did not answer."
	end
	return response
end

local function closeToGameplay(state)
	gui.Enabled = false
	busy = false
	closedEvent:Fire(state)
end

local function selectSlot(slotIndex, exists)
	if busy then
		return
	end
	busy = true
	setStatus(exists and "ENTERING CHARACTER " .. slotIndex .. "..." or "CREATING CHARACTER " .. slotIndex .. "...", COLORS.Gold)

	if not exists then
		local created, createError = invoke("Create", slotIndex)
		if not created then
			busy = false
			setStatus(createError, COLORS.Red)
			return
		end
	end

	local selected, selectError = invoke("Select", slotIndex)
	if not selected then
		busy = false
		setStatus(selectError, COLORS.Red)
		refresh()
		return
	end

	setStatus("FATE ACCEPTED. ENTERING THE WORLD...", COLORS.Green)
	closeToGameplay(selected.State)
end

local function buildCard(slotIndex, info)
	local x = (slotIndex - 1) * 430
	local isActive = activeSlot == slotIndex
	local exists = info and info.Exists == true

	local card = Instance.new("Frame")
	card.Name = "CharacterSlot" .. slotIndex
	card.Size = UDim2.fromOffset(400, 450)
	card.Position = UDim2.fromOffset(x, 5)
	card.BackgroundColor3 = isActive and Color3.fromRGB(27, 35, 48) or COLORS.Panel
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.ZIndex = 5
	card.Parent = cards
	corner(card, 14)
	outline(card, isActive and COLORS.Green or COLORS.GoldSoft, isActive and 2.5 or 1.5, isActive and 0.05 or 0.3)

	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new(
		Color3.fromRGB(31, 40, 57),
		Color3.fromRGB(10, 14, 24)
	)
	cardGradient.Rotation = 105
	cardGradient.Parent = card

	label(card, string.format("CHARACTER  %02d", slotIndex), UDim2.fromOffset(230, 30), UDim2.fromOffset(24, 24), Enum.Font.GothamBlack, 16, COLORS.Gold)

	local badge = label(card, isActive and "ACTIVE" or (exists and "READY" or "EMPTY"), UDim2.fromOffset(100, 28), UDim2.fromOffset(276, 22), Enum.Font.GothamBlack, 11, isActive and COLORS.Green or COLORS.Muted, Enum.TextXAlignment.Center)
	badge.BackgroundTransparency = 0.25
	badge.BackgroundColor3 = isActive and Color3.fromRGB(25, 70, 55) or Color3.fromRGB(31, 39, 54)
	corner(badge, 14)

	local portrait = Instance.new("Frame")
	portrait.Size = UDim2.fromOffset(352, 128)
	portrait.Position = UDim2.fromOffset(24, 72)
	portrait.BackgroundColor3 = Color3.fromRGB(8, 13, 23)
	portrait.BackgroundTransparency = 0.12
	portrait.BorderSizePixel = 0
	portrait.ZIndex = 6
	portrait.Parent = card
	corner(portrait, 10)

	local glyph = label(portrait, exists and "◆" or "+", UDim2.fromOffset(82, 82), UDim2.fromOffset(18, 22), Enum.Font.GothamBlack, exists and 48 or 54, exists and COLORS.Gold or COLORS.Muted, Enum.TextXAlignment.Center)
	local raceName = exists and (info.Race or "UNAWAKENED") or "UNWRITTEN FATE"
	label(portrait, string.upper(raceName), UDim2.fromOffset(230, 42), UDim2.fromOffset(108, 23), Enum.Font.GothamBlack, 19, COLORS.Text)
	label(portrait, exists and "A soul bound to this slot" or "Begin a new journey", UDim2.fromOffset(230, 30), UDim2.fromOffset(108, 68), Enum.Font.GothamMedium, 12, COLORS.Muted)

	local divider = Instance.new("Frame")
	divider.Size = UDim2.fromOffset(352, 1)
	divider.Position = UDim2.fromOffset(24, 224)
	divider.BackgroundColor3 = Color3.fromRGB(65, 76, 98)
	divider.BorderSizePixel = 0
	divider.ZIndex = 6
	divider.Parent = card

	label(card, "LEVEL", UDim2.fromOffset(100, 22), UDim2.fromOffset(28, 246), Enum.Font.GothamBold, 11, COLORS.Muted)
	label(card, exists and tostring(info.Level or 1) or "—", UDim2.fromOffset(100, 38), UDim2.fromOffset(28, 270), Enum.Font.GothamBlack, 24, COLORS.Text)
	label(card, "POWER", UDim2.fromOffset(150, 22), UDim2.fromOffset(210, 246), Enum.Font.GothamBold, 11, COLORS.Muted, Enum.TextXAlignment.Right)
	label(card, exists and tostring(info.Power or 0) or "—", UDim2.fromOffset(150, 38), UDim2.fromOffset(210, 270), Enum.Font.GothamBlack, 24, COLORS.Text, Enum.TextXAlignment.Right)

	local primaryText = exists and (isActive and "CONTINUE" or "PLAY CHARACTER") or "CREATE CHARACTER"
	local primary = button(card, primaryText, UDim2.fromOffset(352, 48), UDim2.fromOffset(24, 332), isActive and COLORS.Green or COLORS.Gold)
	primary.Activated:Connect(function()
		selectSlot(slotIndex, exists)
	end)

	if exists then
		local deleteButton = button(card, "DELETE CHARACTER", UDim2.fromOffset(352, 34), UDim2.fromOffset(24, 393), Color3.fromRGB(67, 28, 38))
		deleteButton.TextColor3 = Color3.fromRGB(255, 220, 225)
		deleteButton.TextSize = 11
		outline(deleteButton, COLORS.Red, 1.2, 0.15)

		local armed = false
		deleteButton.Activated:Connect(function()
			if busy then
				return
			end
			if not armed then
				armed = true
				deleteButton.Text = "CLICK AGAIN TO CONFIRM"
				setStatus("Deleting a character cannot be undone.", COLORS.Red)
				task.delay(3, function()
					if deleteButton.Parent then
						armed = false
						deleteButton.Text = "DELETE CHARACTER"
					end
				end)
				return
			end

			busy = true
			setStatus("DELETING CHARACTER " .. slotIndex .. "...", COLORS.Red)
			local deleted, deleteError = invoke("Delete", slotIndex)
			busy = false
			if not deleted then
				setStatus(deleteError, COLORS.Red)
				return
			end
			setStatus("CHARACTER " .. slotIndex .. " DELETED.", COLORS.Muted)
			refresh()
		end)
	end
end

refresh = function()
	local response, listError = invoke("List")
	if not response then
		setStatus(listError, COLORS.Red)
		return false
	end

	activeSlot = response.ActiveSlot
	local activeInfo = activeSlot and response.Slots[activeSlot]
	local canReturnToGameplay = activeInfo and activeInfo.Exists and activeInfo.Race and activeInfo.Race ~= "Unawakened"
	backButton.Visible = canReturnToGameplay == true

	for _, child in ipairs(cards:GetChildren()) do
		child:Destroy()
	end

	for slotIndex = 1, 3 do
		buildCard(slotIndex, response.Slots[slotIndex] or { Exists = false })
	end

	if activeSlot and canReturnToGameplay then
		setStatus("CHARACTER " .. activeSlot .. " IS CURRENTLY ACTIVE", COLORS.Green)
	elseif activeSlot then
		setStatus("CHARACTER " .. activeSlot .. " IS READY — AWAKEN YOUR RACE TO CONTINUE", COLORS.Gold)
	else
		setStatus("SELECT OR CREATE A CHARACTER TO ENTER THE WORLD", COLORS.Muted)
	end
	return true
end

backButton.Activated:Connect(function()
	if busy or not activeSlot then
		return
	end
	closeToGameplay(nil)
end)

reopenEvent.Event:Connect(function()
	if busy then
		return
	end
	gui.Enabled = true
	setStatus("REFRESHING CHARACTER SLOTS...", COLORS.Muted)
	task.spawn(refresh)
end)

task.spawn(function()
	for _ = 1, 30 do
		if refresh() then
			return
		end
		task.wait(0.25)
	end
	setStatus("CHARACTER DATABASE IS UNAVAILABLE. TRY AGAIN.", COLORS.Red)
end)
