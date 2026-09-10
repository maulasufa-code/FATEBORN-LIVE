-- MovementAnimations (R15)
-- Walk & Run: pakai animasi default Roblox (tidak di-override)
-- Dash: memutar animasi Roll saat attribute "Dashing" = true, berhenti saat dash selesai

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent
-- Half-Beast uses the cached tracks in PlayerMovement.local.luau. Do not load
-- a competing generic dash track for that race visual.
if character:GetAttribute("FatebornBoneCharacter") == true then return end
local humanoid = character:WaitForChild("Humanoid", 10)
if not humanoid then return end

local animFolder = ReplicatedStorage:WaitForChild("R15Anims", 10)
if not animFolder then return end

local dashAnim = animFolder:FindFirstChild("Roll") or animFolder:FindFirstChild("Dash")

-- Dash handling
local animator = humanoid:FindFirstChildOfClass("Animator")
local dashTrack
if dashAnim and animator then
	dashTrack = animator:LoadAnimation(dashAnim)
	dashTrack.Priority = Enum.AnimationPriority.Action
	dashTrack.Looped = false
end

local wasDashing = false
character:GetAttributeChangedSignal("Dashing"):Connect(function()
	local dashing = character:GetAttribute("Dashing") == true
	if dashTrack then
		if dashing and not wasDashing then
			dashTrack:Play(0.05)
		elseif not dashing and wasDashing then
			dashTrack:Stop(0.1)
		end
	end
	wasDashing = dashing
end)
