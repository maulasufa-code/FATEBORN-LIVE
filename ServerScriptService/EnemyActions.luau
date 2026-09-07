local Motion=require(game.ReplicatedStorage.Shared.EnemyMotion)
local Actions={}
local function cue(model,name)
	model:SetAttribute("AnimationAction",name)
	model:SetAttribute("AnimationStartedAt",workspace:GetServerTimeNow())
	model:SetAttribute("AnimationSequence",(model:GetAttribute("AnimationSequence") or 0)+1)
end
function Actions.Attach(model,data)
	local h=model:FindFirstChildOfClass("Humanoid")
	h.BreakJointsOnDeath=false h.RequiresNeck=false
	local previous=h.Health
	local lastHit=0
	h.HealthChanged:Connect(function(health)
		if health>0 and health<previous and os.clock()-lastHit>.25 then
			lastHit=os.clock() model:SetAttribute("AnimationHitAt",workspace:GetServerTimeNow())
		end
		previous=health
	end)
	h.Died:Connect(function()
		data.ActionToken=(data.ActionToken or 0)+1
		cue(model,"Death")
		local root=model:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity=Vector3.zero root.Anchored=true root.CanCollide=false end
	end)
end
function Actions.Start(model,data,name,onHit)
	local h=model:FindFirstChildOfClass("Humanoid")
	local clip=Motion.Clips[name]
	if not clip or not h or h.Health<=0 or os.clock()<(data.ActionEnd or 0) then return false end
	data.ActionToken=(data.ActionToken or 0)+1
	local token=data.ActionToken
	data.ActionEnd=os.clock()+clip.duration
	h:Move(Vector3.zero)
	h:MoveTo(model.HumanoidRootPart.Position)
	model:SetAttribute("AnimationRunning",false)
	cue(model,name)
	for index,delayTime in ipairs(clip.hits) do
		task.delay(delayTime,function()
			if model.Parent and h.Health>0 and data.ActionToken==token and onHit then onHit(index) end
		end)
	end
	return true
end
return Actions
