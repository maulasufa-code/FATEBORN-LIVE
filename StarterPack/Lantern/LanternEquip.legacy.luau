local tool=script.Parent
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local ORB_TEMPLATE_NAME="LanternOrbAsset"
local TRAIL_TEMPLATE_NAME="LanternTrailCurveAsset"
local ORB_NAME="LanternOrb"
local BASE_OFFSET=Vector3.new(-2.35,1.9,0.35)
local TELEPORT_DISTANCE=22
local FOLLOW_SPEED=10
local IDLE_FIRE_SIZE=2
local IDLE_FIRE_HEAT=1.25
local MOVING_FIRE_HEAT=0.1
local IDLE_MOTE_RATE=14
local MOVING_MOTE_RATE=2
local IDLE_MOTE_TRANSPARENCY=NumberSequence.new({
 NumberSequenceKeypoint.new(0,0.35),
 NumberSequenceKeypoint.new(0.7,0.5),
 NumberSequenceKeypoint.new(1,1),
})
local MOVING_MOTE_TRANSPARENCY=NumberSequence.new({
 NumberSequenceKeypoint.new(0,0.88),
 NumberSequenceKeypoint.new(0.7,0.95),
 NumberSequenceKeypoint.new(1,1),
})
local equippedModel
local followConnection
local function clear()
 if followConnection then followConnection:Disconnect() followConnection=nil end
 if equippedModel then equippedModel:Destroy() equippedModel=nil end
end
tool.Equipped:Connect(function()
 clear()
 local character=tool.Parent
 local root=character:FindFirstChild("HumanoidRootPart")
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 local template=ReplicatedStorage:FindFirstChild(ORB_TEMPLATE_NAME)
 if not root or not humanoid or humanoid.Health<=0 or not template then return end
 local previous=character:FindFirstChild(ORB_NAME)
 if previous then previous:Destroy() end
 local model=template:Clone()
 model.Name=ORB_NAME
 model.Parent=character
 local orbRoot=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
 if not orbRoot then model:Destroy() return end
 model.PrimaryPart=orbRoot
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true
  end
 end
 local trailTemplate=ReplicatedStorage:FindFirstChild(TRAIL_TEMPLATE_NAME)
 local trailModel=trailTemplate and trailTemplate:Clone()
 local trailPart
 local trails={}
 if trailModel then
  trailModel.Name="OrbTrail"
  trailModel.Parent=model
  trailPart=trailModel:FindFirstChildWhichIsA("BasePart",true)
  local attachmentPositions={
   Attachment0=Vector3.new(-0.15,0,0), Attachment1=Vector3.new(0.15,0,0),
   Attachment2=Vector3.new(0,-0.12,0), Attachment3=Vector3.new(0,0.12,0),
  }
  for name,position in pairs(attachmentPositions) do
   local attachment=trailModel:FindFirstChild(name,true)
   if attachment and attachment:IsA("Attachment") then attachment.Position=position end
  end
  for _,part in ipairs(trailModel:GetDescendants()) do
   if part:IsA("BasePart") then
    part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Transparency=1
   end
  end
  for _,trail in ipairs(trailModel:GetDescendants()) do
   if trail:IsA("Trail") then
    trail.Color=ColorSequence.new(Color3.fromRGB(255,239,152),Color3.fromRGB(255,172,28))
    trail.Transparency=NumberSequence.new({
     NumberSequenceKeypoint.new(0,0.55),
     NumberSequenceKeypoint.new(0.65,0.88),
     NumberSequenceKeypoint.new(1,1),
    })
    trail.Lifetime=0.65 trail.LightEmission=1 trail.FaceCamera=true trail.Enabled=false
    trail.WidthScale=NumberSequence.new({
     NumberSequenceKeypoint.new(0,0.42),
     NumberSequenceKeypoint.new(0.65,0.18),
     NumberSequenceKeypoint.new(1,0),
    })
    table.insert(trails,trail)
   end
  end
 end
 local started=os.clock()
 local fire=model:FindFirstChild("LegacyFire",true)
 local motes=model:FindFirstChild("GoldenMotes",true)
 local wasMoving=false
 local currentPosition=(root.CFrame*CFrame.new(BASE_OFFSET)).Position
 model:PivotTo(CFrame.new(currentPosition))
 equippedModel=model
 followConnection=RunService.Heartbeat:Connect(function(deltaTime)
  if equippedModel~=model or tool.Parent~=character or not character.Parent or humanoid.Health<=0 then
   clear()
   return
  end
  local now=os.clock()-started
  local bob=math.sin(now*2.15)*0.22
  local sideDrift=math.sin(now*1.1+0.8)*0.12
  local depthDrift=math.cos(now*0.85)*0.08
  local targetPosition=(root.CFrame*CFrame.new(BASE_OFFSET+Vector3.new(sideDrift,bob,depthDrift))).Position
  if (targetPosition-currentPosition).Magnitude>TELEPORT_DISTANCE then
   currentPosition=targetPosition
  else
   currentPosition=currentPosition:Lerp(targetPosition,1-math.exp(-FOLLOW_SPEED*deltaTime))
  end
  local velocity=root.AssemblyLinearVelocity
  local moving=humanoid.MoveDirection.Magnitude>0.05 or Vector3.new(velocity.X,0,velocity.Z).Magnitude>2
  if moving~=wasMoving then
   wasMoving=moving
   if fire then
    fire.Enabled=not moving
    fire.Size=IDLE_FIRE_SIZE
    fire.Heat=moving and MOVING_FIRE_HEAT or IDLE_FIRE_HEAT
   end
   if motes then
    motes.Rate=moving and MOVING_MOTE_RATE or IDLE_MOTE_RATE
    motes.Transparency=moving and MOVING_MOTE_TRANSPARENCY or IDLE_MOTE_TRANSPARENCY
   end
   for _,trail in ipairs(trails) do
    trail.Enabled=moving
   end
  end
  model:PivotTo(CFrame.new(currentPosition)*CFrame.Angles(0,now*0.32,math.sin(now*0.7)*0.06))
  if moving and trailPart then
   trailPart.CFrame=CFrame.new(currentPosition)
  end
 end)
end)
tool.Unequipped:Connect(clear)
tool.Destroying:Connect(clear)
