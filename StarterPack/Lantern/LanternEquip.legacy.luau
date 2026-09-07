local tool=script.Parent
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local equippedModel
local function clear()
 if equippedModel then equippedModel:Destroy() equippedModel=nil end
end
tool.Equipped:Connect(function()
 clear()
 local character=tool.Parent
 local waist=character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
 local template=ReplicatedStorage:FindFirstChild("LanternEquipModel")
 if not waist or not template then return end
 local model=template:Clone()
 model.Name="EquippedLantern"
 model.Parent=character
 model:ScaleTo(0.38)
 local root=model.PrimaryPart or model:FindFirstChild("handle") or model:FindFirstChildWhichIsA("BasePart")
 if not root then model:Destroy() return end
 model.PrimaryPart=root
 model:PivotTo(waist.CFrame*CFrame.new(-1.15,-0.65,0.12)*CFrame.Angles(0,math.rad(90),math.rad(-8)))
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=false part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true
   if part~=root then local weld=Instance.new("WeldConstraint") weld.Part0=root weld.Part1=part weld.Parent=root end
  end
 end
 local grip=Instance.new("WeldConstraint") grip.Name="WaistLanternGrip" grip.Part0=waist grip.Part1=root grip.Parent=root
 equippedModel=model
end)
tool.Unequipped:Connect(clear)
tool.Destroying:Connect(clear)
