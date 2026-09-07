local Players = game:GetService("Players")

local EnemyAI = {}

EnemyAI.Tiers = {
	Standard = {
		AggroMultiplier = 1.00,
		LeashMultiplier = 1.00,
		PatrolRadius = 14,
		PatrolPauseMin = 1.2,
		PatrolPauseMax = 2.8,
		AggroDelay = 0.22,
		ChaseRunDistance = 14,
		RetreatHealth = 0.18,
		RetreatDuration = 1.0,
		RetreatCooldown = 8.0,
		RetreatDistance = 10,
	},
	Elite = {
		AggroMultiplier = 1.12,
		LeashMultiplier = 1.10,
		PatrolRadius = 18,
		PatrolPauseMin = 0.9,
		PatrolPauseMax = 2.1,
		AggroDelay = 0.16,
		ChaseRunDistance = 12,
		RetreatHealth = 0.14,
		RetreatDuration = 0.8,
		RetreatCooldown = 10.0,
		RetreatDistance = 8,
	},
	MiniBoss = {
		AggroMultiplier = 1.30,
		LeashMultiplier = 1.20,
		PatrolRadius = 10,
		PatrolPauseMin = 0.6,
		PatrolPauseMax = 1.4,
		AggroDelay = 0.10,
		ChaseRunDistance = 10,
		RetreatHealth = 0.08,
		RetreatDuration = 0.55,
		RetreatCooldown = 14.0,
		RetreatDistance = 6,
	},
	Boss = {
		AggroMultiplier = 1.45,
		LeashMultiplier = 1.25,
		PatrolRadius = 0,
		PatrolPauseMin = 0,
		PatrolPauseMax = 0,
		AggroDelay = 0.05,
		ChaseRunDistance = 10,
		RetreatHealth = 0,
		RetreatDuration = 0,
		RetreatCooldown = math.huge,
		RetreatDistance = 0,
	},
}

local rng = Random.new()

local function setState(model, data, state)
	if data.AIState == state then
		return
	end
	data.AIState = state
	data.StateStartedAt = os.clock()
	model:SetAttribute("AIState", state)
	model:SetAttribute("AIStateStartedAt", workspace:GetServerTimeNow())
end

local function aliveRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil
end

local function nearestTarget(root, radius)
	local bestPlayer, bestRoot, bestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local targetRoot = aliveRoot(player)
		if targetRoot then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= radius and (not bestDistance or distance < bestDistance) then
				bestPlayer = player
				bestRoot = targetRoot
				bestDistance = distance
			end
		end
	end
	return bestPlayer, bestRoot, bestDistance
end

local function flatPoint(point, y)
	return Vector3.new(point.X, y, point.Z)
end

local function stop(humanoid, root)
	humanoid:MoveTo(root.Position)
	humanoid:Move(Vector3.zero)
end

local function newPatrolPoint(data, root)
	local tier = data.AIProfile
	if tier.PatrolRadius <= 0 then
		data.PatrolPoint = data.Home
		return
	end
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(tier.PatrolRadius * 0.35, tier.PatrolRadius)
	data.PatrolPoint = data.Home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	data.NextPatrolAt = os.clock() + rng:NextNumber(tier.PatrolPauseMin, tier.PatrolPauseMax)
end

function EnemyAI.ResolveTier(definition, explicitTier)
	if explicitTier and EnemyAI.Tiers[explicitTier] then
		return explicitTier
	end
	if definition and definition.Boss then
		return "Boss"
	end
	return "Standard"
end

function EnemyAI.Attach(model, data, explicitTier)
	local tierName = EnemyAI.ResolveTier(data.Definition, explicitTier or model:GetAttribute("AITier"))
	local profile = EnemyAI.Tiers[tierName]
	data.AITier = tierName
	data.AIProfile = profile
	data.BaseAggroRadius = data.AggroRadius
	data.BaseLeashRadius = data.LeashRadius
	data.AggroRadius = data.BaseAggroRadius * profile.AggroMultiplier
	data.LeashRadius = data.BaseLeashRadius * profile.LeashMultiplier
	data.AIState = nil
	data.StateStartedAt = os.clock()
	data.TargetPlayer = nil
	data.PatrolPoint = data.Home
	data.NextPatrolAt = os.clock()
	data.LastRetreatAt = -math.huge
	data.RetreatUntil = 0
	model:SetAttribute("AITier", tierName)
	setState(model, data, "Patrol")
end

function EnemyAI.MarkDeath(model, data)
	if data then
		setState(model, data, "Death")
	elseif model then
		model:SetAttribute("AIState", "Death")
	end
end

function EnemyAI.Step(model, data)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return { State = "Invalid" }
	end

	if humanoid.Health <= 0 then
		setState(model, data, "Death")
		return { State = "Death", Humanoid = humanoid, Root = root }
	end

	local reactionUntil = model:GetAttribute("HitReactionUntil") or -math.huge
	if workspace:GetServerTimeNow() < reactionUntil then
		setState(model, data, "Stagger")
		stop(humanoid, root)
		model:SetAttribute("AnimationRunning", false)
		return { State = "Stagger", Humanoid = humanoid, Root = root }
	end

	local now = os.clock()

	if now < (data.ActionEnd or 0) then
		setState(model, data, "Attack")
		stop(humanoid, root)
		model:SetAttribute("AnimationRunning", false)
		return {
			State = "Attack",
			Busy = true,
			Humanoid = humanoid,
			Root = root,
		}
	end

	local homeDistance = (root.Position - data.Home).Magnitude
	local hardLeashed = homeDistance > data.LeashRadius

	if hardLeashed then
		data.Leashing = true
	end

	if data.Leashing then
		setState(model, data, "Retreat")
		data.TargetPlayer = nil
		if homeDistance <= 4 then
			data.Leashing = false
			data.PatrolPoint = data.Home
			data.NextPatrolAt = now
			stop(humanoid, root)
			model:SetAttribute("AnimationRunning", false)
			setState(model, data, "Patrol")
			return {
				State = "Patrol",
				Reason = "LeashReset",
				Humanoid = humanoid,
				Root = root,
				HomeDistance = homeDistance,
			}
		end
		humanoid.WalkSpeed = data.RunSpeed or humanoid.WalkSpeed
		model:SetAttribute("AnimationRunning", true)
		humanoid:MoveTo(data.Home)
		return {
			State = "Retreat",
			Reason = "Leash",
			Humanoid = humanoid,
			Root = root,
			HomeDistance = homeDistance,
		}
	end

	local targetPlayer, targetRoot, targetDistance = nearestTarget(root, data.AggroRadius)
	local tier = data.AIProfile

	if targetPlayer then
		data.TargetPlayer = targetPlayer
	else
		data.TargetPlayer = nil
	end

	if targetRoot and tier.RetreatHealth > 0 then
		local healthRatio = humanoid.Health / math.max(1, humanoid.MaxHealth)
		local canRetreat = healthRatio <= tier.RetreatHealth
			and targetDistance <= data.AttackRange * 2.2
			and now - data.LastRetreatAt >= tier.RetreatCooldown
		if canRetreat then
			data.LastRetreatAt = now
			data.RetreatUntil = now + tier.RetreatDuration
		end
	end

	if targetRoot and now < (data.RetreatUntil or 0) then
		setState(model, data, "Retreat")
		local away = root.Position - targetRoot.Position
		local flatAway = Vector3.new(away.X, 0, away.Z)
		if flatAway.Magnitude < 0.1 then
			flatAway = -root.CFrame.LookVector
		end
		local desired = root.Position + flatAway.Unit * tier.RetreatDistance
		local fromHome = desired - data.Home
		if fromHome.Magnitude > data.LeashRadius * 0.82 then
			desired = data.Home + fromHome.Unit * data.LeashRadius * 0.82
		end
		humanoid.WalkSpeed = data.RunSpeed or humanoid.WalkSpeed
		model:SetAttribute("AnimationRunning", true)
		humanoid:MoveTo(flatPoint(desired, root.Position.Y))
		return {
			State = "Retreat",
			Reason = "LowHealth",
			TargetPlayer = targetPlayer,
			TargetRoot = targetRoot,
			TargetDistance = targetDistance,
			Humanoid = humanoid,
			Root = root,
		}
	end

	if not targetRoot then
		if homeDistance > 4 then
			setState(model, data, "Retreat")
			humanoid.WalkSpeed = data.WalkSpeed or humanoid.WalkSpeed
			model:SetAttribute("AnimationRunning", false)
			humanoid:MoveTo(data.Home)
			return { State = "Retreat", Reason = "ReturnHome", Humanoid = humanoid, Root = root }
		end

		setState(model, data, "Patrol")
		humanoid.WalkSpeed = data.WalkSpeed or humanoid.WalkSpeed
		model:SetAttribute("AnimationRunning", false)

		if not data.PatrolPoint or (root.Position - data.PatrolPoint).Magnitude <= 2.5 then
			if now >= (data.NextPatrolAt or 0) then
				newPatrolPoint(data, root)
			else
				stop(humanoid, root)
			end
		else
			humanoid:MoveTo(flatPoint(data.PatrolPoint, root.Position.Y))
		end

		return { State = "Patrol", Humanoid = humanoid, Root = root }
	end

	if data.AIState == "Patrol" or data.AIState == "Retreat" then
		setState(model, data, "Aggro")
		data.AggroReadyAt = now + tier.AggroDelay
	end

	if data.AIState == "Aggro" and now < (data.AggroReadyAt or 0) then
		stop(humanoid, root)
		model:SetAttribute("AnimationRunning", false)
		return {
			State = "Aggro",
			TargetPlayer = targetPlayer,
			TargetRoot = targetRoot,
			TargetDistance = targetDistance,
			Humanoid = humanoid,
			Root = root,
		}
	end

	local engageRange = data.EngageRange or data.AttackRange
	if targetDistance <= engageRange then
		setState(model, data, "Attack")
		stop(humanoid, root)
		model:SetAttribute("AnimationRunning", false)
		return {
			State = "Attack",
			TargetPlayer = targetPlayer,
			TargetRoot = targetRoot,
			TargetDistance = targetDistance,
			Humanoid = humanoid,
			Root = root,
		}
	end

	setState(model, data, "Chase")
	local running = targetDistance > data.AttackRange + tier.ChaseRunDistance
	humanoid.WalkSpeed = running and (data.RunSpeed or humanoid.WalkSpeed) or (data.WalkSpeed or humanoid.WalkSpeed)
	model:SetAttribute("AnimationRunning", running)
	humanoid:MoveTo(flatPoint(targetRoot.Position, root.Position.Y))
	return {
		State = "Chase",
		TargetPlayer = targetPlayer,
		TargetRoot = targetRoot,
		TargetDistance = targetDistance,
		Running = running,
		Humanoid = humanoid,
		Root = root,
	}
end

return EnemyAI
