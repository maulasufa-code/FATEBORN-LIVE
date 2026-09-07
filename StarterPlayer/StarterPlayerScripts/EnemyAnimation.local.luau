local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Motion=require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnemyMotion"))
local states={}
local scan=1
local mapping={LeftUpLeg="LeftHip",RightUpLeg="RightHip",LeftLeg="LeftKnee",RightLeg="RightKnee",LeftFoot="LeftAnkle",RightFoot="RightAnkle",LeftArm="LeftShoulder",RightArm="RightShoulder",LeftForeArm="LeftElbow",RightForeArm="RightElbow",Spine02="Waist",neck="Neck"}
local function register(model)
	if states[model] then return end
	local root=model:FindFirstChild("HumanoidRootPart")
	local hum=model:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	local bones,motors={},{}
	for _,node in model:GetDescendants() do
		if node:IsA("Bone") and mapping[node.Name] then
			bones[mapping[node.Name]]={node=node,basis=root.CFrame:ToObjectSpace(node.WorldCFrame).Rotation}
		elseif node:IsA("Motor6D") then motors[node.Name]=node end
	end
	if model.Name=="Wanderer" and not bones.LeftHip then return end
	if model.Name~="Wanderer" and (not motors.LeftHip or not motors.RightShoulder or not motors.LeftKnee) then return end
	states[model]={root=root,hum=hum,bones=bones,motors=motors,phase=0,blend=0,run=0}
end
CollectionService:GetInstanceRemovedSignal("FatebornAnimatedEnemy"):Connect(function(m) states[m]=nil end)
local function angles(name,value)
	local v=value or Vector3.zero
	local x=v.X
	if string.find(name,"Shoulder") or string.find(name,"Elbow") or string.find(name,"Knee") then x=-x end
	return CFrame.Angles(math.rad(x),math.rad(v.Y),math.rad(v.Z))
end
RunService.PreSimulation:Connect(function(dt)
	scan+=dt
	if scan>.5 then scan=0 for _,model in CollectionService:GetTagged("FatebornAnimatedEnemy") do register(model) end end
	local now=workspace:GetServerTimeNow()
	for model,state in pairs(states) do
		local valid=state.root:IsDescendantOf(workspace)
		for _,b in pairs(state.bones) do if not b.node:IsDescendantOf(model) then valid=false end end
		for _,m in pairs(state.motors) do if not m:IsDescendantOf(model) or not m.Part1 then valid=false end end
		if not valid then states[model]=nil;continue end
		local v=state.root.AssemblyLinearVelocity
		local speed=Vector3.new(v.X,0,v.Z).Magnitude
		local alive=state.hum.Health>0
		local action=model:GetAttribute("AnimationAction")
		local elapsed=now-(model:GetAttribute("AnimationStartedAt") or 0)
		local clip=action and Motion.Clips[action]
		local active=clip and elapsed>=0 and (elapsed<clip.duration or clip.hold)
		local blendTarget=alive and not active and math.abs(v.Y)<6 and speed>.5 and math.clamp(speed/7,0,1) or 0
		local smoothing=1-math.exp(-12*dt)
		state.blend+=(blendTarget-state.blend)*smoothing
		local profile=Motion.Profiles[model.Name] or Motion.Profiles.Wanderer
		local runTarget=math.clamp((speed-profile.walk)/math.max(profile.run-profile.walk,1),0,1)
		state.run+=(runTarget-state.run)*smoothing
		state.phase+=math.min(speed,28)*dt*math.pi*2/(model.Name=="FallenKing" and 9 or 7)
		local pose=Motion.Gait(model.Name,state.phase,state.blend,state.run,now)
		if active then
			-- Actions own the full pose so locomotion cannot fight attack anticipation.
			pose=Motion.Sample(action,elapsed)
		end
		local hitElapsed=now-(model:GetAttribute("AnimationHitAt") or 0)
		local reactionName=model:GetAttribute("HitReaction")
		local reactionStarted=model:GetAttribute("HitReactionStartedAt") or now
		local reactionUntil=model:GetAttribute("HitReactionUntil") or -math.huge
		local reacting=alive and now<reactionUntil and type(reactionName)=="string"
		if reacting then
			local total=math.max(.05,reactionUntil-reactionStarted)
			local progress=math.clamp((now-reactionStarted)/total,0,1)
			local sampleTime=math.min(progress*Motion.Clips.Hit.duration,Motion.Clips.Hit.duration-.001)
			local hit=Motion.Sample("Hit",sampleTime)
			local strength=reactionName=="Stagger" and 1.15 or (reactionName=="Finisher" and 1.45 or .55)
			pose.Root=(pose.Root or Vector3.zero)+(hit.Root or Vector3.zero)*strength
			pose.Neck=(pose.Neck or Vector3.zero)+(hit.Neck or Vector3.zero)*strength
			if reactionName=="Stagger" then
				pose.LeftShoulder=(pose.LeftShoulder or Vector3.zero)+Vector3.new(-18,0,-12)
				pose.RightShoulder=(pose.RightShoulder or Vector3.zero)+Vector3.new(-18,0,12)
			elseif reactionName=="Finisher" then
				pose.LeftShoulder=(pose.LeftShoulder or Vector3.zero)+Vector3.new(-28,0,-18)
				pose.RightShoulder=(pose.RightShoulder or Vector3.zero)+Vector3.new(-28,0,18)
			end
		elseif alive and hitElapsed>=0 and hitElapsed<Motion.Clips.Hit.duration then
			local hit=Motion.Sample("Hit",hitElapsed)
			pose.Root=(pose.Root or Vector3.zero)+(hit.Root or Vector3.zero)*.5
			pose.Neck=(pose.Neck or Vector3.zero)+(hit.Neck or Vector3.zero)*.5
		end
		for name,entry in pairs(state.bones) do
			entry.node.Transform=entry.basis:Inverse()*angles(name,pose[name])*entry.basis
		end
		local scale=state.root.Size.Y/6.5
		local rootPose=CFrame.new((pose.Offset or Vector3.zero)*scale)*angles("Root",pose.Root)
		for name,motor in pairs(state.motors) do
			if name=="EnemyVisualMotor" then motor.Transform=rootPose
			elseif name=="RootJoint" then motor.Transform=rootPose*angles("Waist",pose.Waist)
			else motor.Transform=angles(name,pose[name]) end
		end
	end
end)
