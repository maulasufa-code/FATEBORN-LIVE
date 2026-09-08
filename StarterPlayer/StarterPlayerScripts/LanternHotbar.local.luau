local Players=game:GetService("Players")
local StarterGui=game:GetService("StarterGui")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
local gui=Instance.new("ScreenGui") gui.Name="FATEBORN_HOTBAR" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=20 gui.Parent=player:WaitForChild("PlayerGui")
local slot=Instance.new("ImageButton")
slot.Name="LanternSlot" slot.AnchorPoint=Vector2.new(0,1) slot.Size=UDim2.fromOffset(86,86) slot.Position=UDim2.new(0,22,1,-28)
slot.BackgroundColor3=Color3.fromRGB(12,15,22) slot.BorderSizePixel=0 slot.AutoButtonColor=false slot.Image="rbxassetid://114673441710459" slot.ScaleType=Enum.ScaleType.Crop slot.Parent=gui
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=slot
local border=Instance.new("UIStroke") border.Name="Selection" border.Color=Color3.fromRGB(77,69,55) border.Thickness=2 border.Parent=slot
local gradient=Instance.new("UIGradient") gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(205,151,69)) gradient.Rotation=90 gradient.Parent=slot
local number=Instance.new("TextLabel") number.Size=UDim2.fromOffset(22,22) number.Position=UDim2.fromOffset(5,4) number.BackgroundColor3=Color3.fromRGB(5,7,12) number.BackgroundTransparency=.15 number.Text="1" number.TextColor3=Color3.fromRGB(239,182,72) number.Font=Enum.Font.GothamBlack number.TextSize=14 number.ZIndex=3 number.Parent=slot
local nc=Instance.new("UICorner") nc.CornerRadius=UDim.new(0,5) nc.Parent=number
local name=Instance.new("TextLabel") name.AnchorPoint=Vector2.new(.5,1) name.Size=UDim2.new(1,-8,0,22) name.Position=UDim2.new(.5,0,1,-4) name.BackgroundColor3=Color3.fromRGB(5,7,12) name.BackgroundTransparency=.15 name.Text="LANTERN" name.TextColor3=Color3.fromRGB(239,182,72) name.Font=Enum.Font.GothamBold name.TextSize=11 name.ZIndex=3 name.Parent=slot
local equipped=false
local function findTool()
 local character=player.Character
 return (character and character:FindFirstChild("Lantern")) or player.Backpack:FindFirstChild("Lantern")
end
local function sync()
 local character=player.Character
 equipped=character and character:FindFirstChild("Lantern")~=nil
 border.Color=equipped and Color3.fromRGB(239,182,72) or Color3.fromRGB(77,69,55)
 border.Thickness=equipped and 3 or 2
 slot.BackgroundColor3=equipped and Color3.fromRGB(54,39,18) or Color3.fromRGB(12,15,22)
end
local function toggle()
 local character=player.Character local humanoid=character and character:FindFirstChildOfClass("Humanoid") local tool=findTool()
 if not humanoid or not tool then return end
 if tool.Parent==character then humanoid:UnequipTools() else humanoid:EquipTool(tool) end
 task.defer(sync)
end
slot.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input)
 if input.KeyCode~=Enum.KeyCode.One then return end
 if UserInputService:GetFocusedTextBox() then return end
 if player:GetAttribute("GameplayActive")==false then return end
 toggle()
end)
player.CharacterAdded:Connect(function(character)
 character.ChildAdded:Connect(function(x) if x.Name=="Lantern" then task.defer(sync) end end)
 character.ChildRemoved:Connect(function(x) if x.Name=="Lantern" then task.defer(sync) end end)
 task.wait(.5) sync()
end)
task.defer(sync)
