local EnemyRig={}
function EnemyRig.Build(model,root,head,humanoid,definition)
	local hound=model.Name=="FateHound"
	local king=definition.Boss
	local scale=root.Size.Y/(hound and 5 or 6.5)
	root.Transparency=1 root.RootPriority=127
	humanoid.RequiresNeck=false humanoid.BreakJointsOnDeath=false
	local gold=Color3.fromRGB(172,125,52)
	local dark=king and Color3.fromRGB(38,35,43) or definition.Color
	local function part(name,size,color,shape)
		local p=Instance.new("Part") p.Name=name p.Size=size*scale p.Color=color or dark
		p.Material=king and Enum.Material.Metal or Enum.Material.Slate
		p.CanCollide=false p.CanTouch=false p.Massless=true p.CastShadow=true
		if shape then p.Shape=shape end
		p.Parent=model return p
	end
	local function joint(name,p0,p1,offset,childOffset)
		local m=Instance.new("Motor6D") m.Name=name m.Part0=p0 m.Part1=p1
		m.C0=CFrame.new(offset*scale) m.C1=CFrame.new((childOffset or Vector3.zero)*scale)
		p1.CFrame=p0.CFrame*m.C0*m.C1:Inverse() m.Parent=p0 return m
	end
	local function detail(parent,name,size,offset,color,shape,rotation)
		local p=part(name,size,color,shape)
		p.CFrame=parent.CFrame*CFrame.new(offset*scale)*(rotation or CFrame.identity)
		local w=Instance.new("WeldConstraint") w.Part0=parent w.Part1=p w.Parent=p
		return p
	end
	local torso=part("Torso",hound and Vector3.new(2.4,1.8,3.8) or Vector3.new(2.2,2.2,1.1))
	joint("RootJoint",root,torso,Vector3.new(0,hound and .1 or .9,0))
	head.Massless=true head.Transparency=0 head.Color=king and Color3.fromRGB(83,78,73) or definition.Color
	head.Size=(hound and Vector3.new(1.6,1.25,1.7) or Vector3.new(1.3,1.3,1.2))*scale
	joint("Neck",torso,head,hound and Vector3.new(0,.45,-1.65) or Vector3.new(0,1.1,0),Vector3.new(0,-.65,0))
	for _,side in {-1,1} do
		local prefix=side<0 and "Left" or "Right"
		local upper=part(prefix.."Arm",hound and Vector3.new(.65,.9,.75) or Vector3.new(.65,1.1,.7))
		joint(prefix.."Shoulder",torso,upper,hound and Vector3.new(side*.9,-.7,-1.2) or Vector3.new(side*1.45,.85,0),Vector3.new(0,hound and .45 or .5,0))
		local fore=part(prefix.."ForeArm",Vector3.new(.6,hound and .9 or 1,.65))
		joint(prefix.."Elbow",upper,fore,Vector3.new(0,hound and -.45 or -.55,0),Vector3.new(0,hound and .45 or .5,0))
		local hand=detail(fore,prefix.."Hand",Vector3.new(.7,.4,.75),Vector3.new(0,-.55,-.03),king and gold or dark)
		local thigh=part(prefix.."Leg",hound and Vector3.new(.75,.9,.85) or Vector3.new(.85,1.3,.9))
		joint(prefix.."Hip",torso,thigh,hound and Vector3.new(side*.9,-.7,1.25) or Vector3.new(side*.6,-1.1,0),Vector3.new(0,hound and .45 or .65,0))
		local shin=part(prefix.."Shin",Vector3.new(hound and .65 or .75,hound and .9 or 1.3,.8))
		joint(prefix.."Knee",thigh,shin,Vector3.new(0,hound and -.45 or -.65,0),Vector3.new(0,hound and .45 or .65,0))
		detail(shin,prefix.."Foot",Vector3.new(hound and .8 or .9,.45,1.15),Vector3.new(0,hound and -.45 or -.65,-.18),king and Color3.fromRGB(55,48,39) or dark)
		if king or model.Name=="AshKnight" then
			detail(upper,prefix.."Pauldron",Vector3.new(1,.55,1),Vector3.new(0,.4,0),gold)
			detail(shin,prefix.."Greave",Vector3.new(.82,1.1,.18),Vector3.new(0,0,-.46),gold)
			detail(fore,prefix.."Bracer",Vector3.new(.72,.55,.8),Vector3.new(0,-.12,0),gold)
		end
		if side==1 and (king or model.Name=="AshKnight") then
			local grip=detail(hand,"SwordGrip",Vector3.new(.16,.65,.16),Vector3.new(0,-.35,-.1),Color3.fromRGB(38,24,22))
			detail(grip,"SwordGuard",Vector3.new(1,.14,.28),Vector3.new(0,-.4,0),gold)
			detail(grip,"SwordBlade",Vector3.new(.33,king and 2.6 or 1.9,.13),Vector3.new(0,king and -1.75 or -1.4,0),Color3.fromRGB(173,185,198))
		end
	end
	if hound then
		local jaw=part("Jaw",Vector3.new(1.2,.35,1.2))
		joint("Jaw",head,jaw,Vector3.new(0,-.4,0),Vector3.new(0,0,.35))
		local tail=part("Tail",Vector3.new(.4,.4,1.6))
		joint("Tail",torso,tail,Vector3.new(0,.25,1.9),Vector3.new(0,0,-.8))
		for _,s in {-1,1} do detail(head,"Ear",Vector3.new(.35,.6,.45),Vector3.new(s*.55,.75,.35),dark) end
	end
	for _,s in {-1,1} do
		local eye=detail(head,"Eye",Vector3.new(.18,.12,.08),Vector3.new(s*.29,.13,hound and -.88 or -.63),king and Color3.fromRGB(255,182,45) or Color3.fromRGB(230,65,92))
		eye.Material=Enum.Material.Neon
	end
	if king then
		detail(torso,"Breastplate",Vector3.new(1.8,1.65,.22),Vector3.new(0,.12,-.65),gold)
		detail(torso,"RoyalBelt",Vector3.new(2.3,.28,1.2),Vector3.new(0,-.85,0),gold)
		detail(torso,"RoyalGem",Vector3.new(.35,.5,.2),Vector3.new(0,.3,-.83),Color3.fromRGB(175,31,49))
		local cape=detail(torso,"RoyalCape",Vector3.new(2.4,3.3,.12),Vector3.new(0,-.5,.72),Color3.fromRGB(86,21,37),nil,CFrame.Angles(math.rad(8),0,0))
		cape.Material=Enum.Material.Fabric
		for i=0,7 do
			local angle=i*math.pi/4
			local tip=detail(head,"CrownPoint",Vector3.new(.2,i%2==0 and .8 or .55,.2),Vector3.new(math.cos(angle)*.63,.95,math.sin(angle)*.58),gold)
			tip.Material=Enum.Material.Metal
		end
		for _,s in {-1,1} do
			detail(head,"CrownBand",Vector3.new(1.45,.18,.15),Vector3.new(0,.65,s*.59),gold)
			detail(head,"CrownBand",Vector3.new(.15,.18,1.2),Vector3.new(s*.65,.65,0),gold)
		end
	elseif model.Name=="RiftCultist" then
		detail(torso,"RiftMantle",Vector3.new(2.4,.55,1.35),Vector3.new(0,.75,0),Color3.fromRGB(87,42,126))
		local orb=detail(torso,"RiftSigil",Vector3.new(.4,.4,.2),Vector3.new(0,.35,-.65),Color3.fromRGB(173,83,255),Enum.PartType.Ball)
		orb.Material=Enum.Material.Neon
	end
	model:SetAttribute("RigScale",scale)
	model:SetAttribute("AnimationRigVersion",2)
	game:GetService("CollectionService"):AddTag(model,"FatebornAnimatedEnemy")
end
return EnemyRig
