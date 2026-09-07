local Motion = {}
local function frame(t, pose) return {t=t, pose=pose} end
-- Angles are degrees; Offset is measured in studs on a six-stud character.
Motion.Clips = {
	Swipe={duration=0.8,hits={0.34},frames={frame(0,{}),frame(.3,{RightShoulder={55,-30,25},Waist={0,-20,0}}),frame(.46,{RightShoulder={-80,30,-20},Waist={10,25,0}}),frame(1,{})}},
	Bite={duration=.7,hits={.32},frames={frame(0,{}),frame(.3,{Root={12,0,0},Neck={-20,0,0},Jaw={30,0,0}}),frame(.48,{Root={-14,0,0},Neck={25,0,0},Jaw={0,0,0},Offset={0,0,-.45}}),frame(1,{})}},
	Slash={duration=.95,hits={.44},frames={frame(0,{}),frame(.34,{RightShoulder={-110,-30,35},RightElbow={-55,0,0},Waist={0,-25,0}}),frame(.51,{RightShoulder={-35,50,-25},Waist={15,35,0}}),frame(1,{})}},
	Cast={duration=1,hits={.5},frames={frame(0,{}),frame(.35,{LeftShoulder={-65,0,-15},RightShoulder={-65,0,15},LeftElbow={-45,0,0},RightElbow={-45,0,0}}),frame(.52,{LeftShoulder={-95,0,0},RightShoulder={-95,0,0},Root={-8,0,0}}),frame(1,{})}},
	Cleave={duration=1.05,hits={.5},frames={frame(0,{}),frame(.34,{RightShoulder={-135,-30,25},RightElbow={-25,0,0},LeftShoulder={-55,0,-25},Waist={0,-32,0}}),frame(.5,{RightShoulder={-25,45,-25},Waist={15,35,0},Root={-8,0,0}}),frame(.7,{RightShoulder={10,25,-10},Waist={5,20,0}}),frame(1,{})}},
	Lunge={duration=1.2,hits={.6},frames={frame(0,{}),frame(.3,{Root={16,0,0},LeftKnee={35,0,0},RightKnee={35,0,0},RightShoulder={45,0,15},Offset={0,-.2,.2}}),frame(.52,{Root={-20,0,0},RightShoulder={-100,0,0},LeftHip={-45,0,0},RightHip={40,0,0},Offset={0,.1,-.7}}),frame(.7,{Root={-8,0,0},RightShoulder={-45,0,0}}),frame(1,{})}},
	Pounce={duration=1.25,hits={.68},frames={frame(0,{}),frame(.3,{Root={18,0,0},LeftHip={-40,0,0},RightHip={-40,0,0},Offset={0,-.3,.2}}),frame(.5,{Root={-12,0,0},LeftShoulder={-60,0,0},RightShoulder={-60,0,0},LeftHip={45,0,0},RightHip={45,0,0},Jaw={25,0,0},Offset={0,.65,-.6}}),frame(.64,{Root={20,0,0},Neck={20,0,0},Offset={0,-.12,-.7}}),frame(1,{})}},
	HeavySlash={duration=1.45,hits={.82},frames={frame(0,{}),frame(.42,{RightShoulder={-165,0,15},RightElbow={-25,0,0},LeftShoulder={-115,0,-10},Root={8,0,0}}),frame(.59,{RightShoulder={-20,0,0},LeftShoulder={-25,0,0},Waist={25,0,0},Offset={0,-.15,-.3}}),frame(.76,{RightShoulder={10,0,0},Waist={15,0,0}}),frame(1,{})}},
	RiftBolt={duration=1.4,hits={.8},frames={frame(0,{}),frame(.4,{LeftShoulder={-110,0,-35},RightShoulder={-110,0,35},Neck={-15,0,0},Offset={0,.12,0}}),frame(.59,{LeftShoulder={-90,0,-5},RightShoulder={-90,0,5},Waist={18,0,0},Offset={0,0,-.2}}),frame(1,{})}},
	RoyalSlam={duration=1.65,hits={.9},frames={frame(0,{}),frame(.4,{RightShoulder={-170,0,10},LeftShoulder={-145,0,-10},RightElbow={-20,0,0},Root={12,0,0}}),frame(.55,{RightShoulder={-20,0,0},LeftShoulder={-30,0,0},Waist={32,0,0},LeftKnee={30,0,0},RightKnee={30,0,0},Offset={0,-.35,0}}),frame(.76,{Waist={18,0,0},RightShoulder={-10,0,0}}),frame(1,{})}},
	RiftEruption={duration=1.6,hits={.85},frames={frame(0,{}),frame(.4,{LeftShoulder={-160,0,-30},RightShoulder={-135,0,30},Neck={-20,0,0},Offset={0,.15,0}}),frame(.55,{LeftShoulder={-65,0,-10},RightShoulder={-50,0,10},Waist={20,0,0},Offset={0,-.15,0}}),frame(1,{})}},
	TripleShockwave={duration=2.35,hits={.65,1.2,1.75},frames={frame(0,{}),frame(.18,{LeftShoulder={-110,0,-65},RightShoulder={-110,0,65},Root={10,0,0}}),frame(.28,{LeftShoulder={-50,0,-85},RightShoulder={-50,0,85},Root={-10,0,0}}),frame(.42,{LeftShoulder={-120,0,-55},RightShoulder={-120,0,55},Root={12,0,0}}),frame(.52,{LeftShoulder={-45,0,-90},RightShoulder={-45,0,90},Root={-12,0,0}}),frame(.66,{LeftShoulder={-130,0,-45},RightShoulder={-130,0,45},Root={15,0,0}}),frame(.75,{LeftShoulder={-40,0,-90},RightShoulder={-40,0,90},Root={-15,0,0}}),frame(1,{})}},
	Roar={duration=1.5,hits={},frames={frame(0,{}),frame(.3,{LeftShoulder={30,0,-60},RightShoulder={30,0,60},Neck={-30,0,0},Root={12,0,0},Jaw={25,0,0}}),frame(.7,{LeftShoulder={-20,0,-70},RightShoulder={-20,0,70},Root={-5,0,0}}),frame(1,{})}},
	Hit={duration=.32,hits={},frames={frame(0,{}),frame(.3,{Root={14,0,-8},Neck={-15,0,0},LeftShoulder={15,0,-15},RightShoulder={15,0,15}}),frame(1,{})}},
	Death={duration=1.5,hits={},hold=true,frames={frame(0,{}),frame(.2,{Root={12,0,5},LeftKnee={35,0,0},RightKnee={35,0,0},Offset={0,-.4,0}}),frame(.7,{Root={78,0,12},LeftShoulder={-25,0,-30},RightShoulder={-20,0,35},Offset={0,-1.5,.3}}),frame(1,{Root={88,0,12},LeftShoulder={-20,0,-35},RightShoulder={-15,0,40},Offset={0,-1.7,.3}})}},
}
Motion.Profiles = {
	Wanderer={basic="Swipe",skill="Lunge",cooldown=8,skillRange=9,radius=7,multiplier=1.35,walk=7,run=11},
	FateHound={basic="Bite",skill="Pounce",cooldown=7,skillRange=11,radius=8,multiplier=1.4,walk=8,run=15},
	AshKnight={basic="Slash",skill="HeavySlash",cooldown=9,skillRange=8,radius=9,multiplier=1.6,walk=7,run=12},
	RiftCultist={basic="Cast",skill="RiftBolt",cooldown=9,skillRange=28,radius=6,multiplier=1.45,walk=7,run=12},
	FallenKing={basic="Cleave",skill="RoyalSlam",cooldown=7.5,skillRange=75,radius=17,multiplier=1.1,walk=8,run=13},
}
local zero=Vector3.zero
local function vector(value) return value and Vector3.new(value[1] or 0,value[2] or 0,value[3] or 0) or zero end
function Motion.Sample(name, elapsed)
	local clip=Motion.Clips[name]
	if not clip then return {} end
	local t=math.clamp(elapsed/clip.duration,0,1)
	local a,b=clip.frames[1],clip.frames[#clip.frames]
	for i=2,#clip.frames do if t<=clip.frames[i].t then a,b=clip.frames[i-1],clip.frames[i];break end end
	local alpha=math.clamp((t-a.t)/math.max(b.t-a.t,.001),0,1)
	alpha=alpha*alpha*(3-2*alpha)
	local result={}
	for key,value in pairs(a.pose) do result[key]=vector(value):Lerp(vector(b.pose[key]),alpha) end
	for key,value in pairs(b.pose) do if not result[key] then result[key]=vector(a.pose[key]):Lerp(vector(value),alpha) end end
	return result
end
function Motion.Gait(kind, phase, blend, run, now)
	local hound=kind=="FateHound"
	local wave=math.sin(phase)*blend
	local swing=(hound and 32 or 24)+run*16
	local arms=hound and swing or (16+run*22)
	local pose={
		LeftHip=Vector3.new(wave*swing,0,0),RightHip=Vector3.new(-wave*swing,0,0),
		LeftKnee=Vector3.new(math.max(0,-math.cos(phase))*(30+run*22)*blend,0,0),
		RightKnee=Vector3.new(math.max(0,math.cos(phase))*(30+run*22)*blend,0,0),
		LeftShoulder=Vector3.new(-wave*arms,0,0),RightShoulder=Vector3.new(wave*arms,0,0),
		LeftElbow=Vector3.new(-run*40*blend,0,0),RightElbow=Vector3.new(-run*40*blend,0,0),
		Waist=Vector3.new(-3*blend+math.sin(now*2)*.8,wave*3,0),
		Root=Vector3.new(-run*8*blend,0,wave*2),Neck=Vector3.new(run*3*blend,-wave*2,0),
		Offset=Vector3.new(math.sin(phase)*.025*blend,math.cos(phase*2)*(.045+run*.045)*blend+math.sin(now*2)*.015,0),
		Tail=Vector3.new(0,math.sin(phase)*12*blend+math.sin(now*1.7)*5,0),
	}
	if hound then
		pose.LeftElbow=Vector3.new(math.max(0,math.cos(phase))*35*blend,0,0)
		pose.RightElbow=Vector3.new(math.max(0,-math.cos(phase))*35*blend,0,0)
		if run>.4 then
			pose.LeftShoulder=Vector3.new(math.sin(phase+.35)*swing*blend,0,0)
			pose.RightShoulder=Vector3.new(math.sin(phase)*swing*blend,0,0)
			pose.LeftHip=Vector3.new(-math.sin(phase+.35)*swing*blend,0,0)
			pose.RightHip=Vector3.new(-math.sin(phase)*swing*blend,0,0)
		end
	end
	return pose
end
return Motion
