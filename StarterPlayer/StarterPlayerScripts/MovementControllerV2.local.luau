local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local player=Players.LocalPlayer
local animations=ReplicatedStorage:WaitForChild("R15Anims")
local actionRemote=ReplicatedStorage:WaitForChild("FatebornRemotes"):WaitForChild("Action")
local character,humanoid,walkTrack,runTrack,rollTrack
local sprinting,rolling,ctrlWasDown=false,false,false
local lastRoll=0
local ROLL_COOLDOWN=2.2
local ROLL_SPEED=1.2
local ROLL_DURATION=(21/30)/ROLL_SPEED
local preRollWalkSpeed=16
local function direction()
 if humanoid and humanoid.MoveDirection.Magnitude>.05 then return humanoid.MoveDirection.Unit end
 local camera=Workspace.CurrentCamera
 if camera then local look=camera.CFrame.LookVector local flat=Vector3.new(look.X,0,look.Z) if flat.Magnitude>.05 then return flat.Unit end end
 return Vector3.new(0,0,-1)
end
local function loadTrack(anim,priority,looped)
 local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",humanoid)
 local track=animator:LoadAnimation(anim) track.Priority=priority track.Looped=looped return track
end
local function stopMovement(fade)
 if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(fade or .12) end
 if runTrack and runTrack.IsPlaying then runTrack:Stop(fade or .12) end
end
local function playMovement()
 if not humanoid or humanoid.Health<=0 or rolling then stopMovement(.08) return end
 local state=humanoid:GetState()
 local grounded=state~=Enum.HumanoidStateType.Jumping and state~=Enum.HumanoidStateType.Freefall and state~=Enum.HumanoidStateType.FallingDown
 if humanoid.MoveDirection.Magnitude<.05 or not grounded then stopMovement(.12) return end
 local wanted=sprinting and runTrack or walkTrack local other=sprinting and walkTrack or runTrack
 if other and other.IsPlaying then other:Stop(.12) end
 if wanted and not wanted.IsPlaying then wanted:Play(.12,1,1) end
 if wanted then wanted:AdjustSpeed(sprinting and 1 or math.clamp(humanoid.WalkSpeed/16,.8,1.25)) end
end
local function doRoll()
 local now=os.clock()
 if not humanoid or humanoid.Health<=0 or rolling or now-lastRoll<ROLL_COOLDOWN then return end
 lastRoll=now rolling=true stopMovement(.05)
 preRollWalkSpeed=humanoid.WalkSpeed
 humanoid.WalkSpeed=0
 humanoid.AutoRotate=false
 if rollTrack then rollTrack:Stop(0) rollTrack:Play(.03,1,ROLL_SPEED) end
 character:SetAttribute("Dashing",true) actionRemote:FireServer("Dash",0,direction())
 task.delay(ROLL_DURATION,function()
  if rollTrack and rollTrack.IsPlaying then rollTrack:Stop(.03) end
  if character and character.Parent then character:SetAttribute("Dashing",false) end
  if humanoid then humanoid.WalkSpeed=preRollWalkSpeed humanoid.AutoRotate=true end
  rolling=false playMovement()
 end)
end
local function setSprint(enabled)
 if sprinting==enabled then return end
 sprinting=enabled
 if character then character:SetAttribute("Sprinting",enabled) end
 actionRemote:FireServer("Sprint",enabled,direction()) playMovement()
end
local function setup(newCharacter)
 character=newCharacter humanoid=character:WaitForChild("Humanoid") character:WaitForChild("HumanoidRootPart")
 walkTrack=loadTrack(animations.Walk,Enum.AnimationPriority.Movement,true)
 runTrack=loadTrack(animations.Run,Enum.AnimationPriority.Movement,true)
 rollTrack=loadTrack(animations.Roll,Enum.AnimationPriority.Action4,false)
 sprinting=false rolling=false ctrlWasDown=false
 character:SetAttribute("Sprinting",false) character:SetAttribute("Dashing",false)
 humanoid.Running:Connect(playMovement) humanoid.StateChanged:Connect(playMovement)
end
player.CharacterAdded:Connect(setup)
if player.Character then task.spawn(setup,player.Character) end
UserInputService.InputBegan:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then setSprint(true)
 elseif input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then doRoll() end
end)
UserInputService.InputEnded:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then setSprint(false) end
end)
ContextActionService:BindActionAtPriority("FatebornRollV2",function(_,state)
 if state==Enum.UserInputState.Begin then doRoll() end return Enum.ContextActionResult.Sink
end,false,4000,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl)
RunService.RenderStepped:Connect(function()
 if not humanoid then return end
 local shift=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
 if shift~=sprinting then setSprint(shift) end
 local ctrl=UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
 if ctrl and not ctrlWasDown then doRoll() end
 ctrlWasDown=ctrl
 playMovement()
end)
