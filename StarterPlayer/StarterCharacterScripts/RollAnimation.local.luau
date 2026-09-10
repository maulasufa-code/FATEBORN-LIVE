local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ROLL_KEY = Enum.KeyCode.P
local ROLL_COOLDOWN = 1.5 -- detik

local player = Players.LocalPlayer
local character = script.Parent
-- Half-Beast roll playback is owned by PlayerMovement.local.luau and the
-- existing PlayerMovement RemoteEvent state, rather than this legacy P-key clip.
if character:GetAttribute("FatebornBoneCharacter") == true then return end
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Ambel instance Animation dari ReplicatedStorage
local animInstance = ReplicatedStorage:FindFirstChild("BaseRollCharacter")
if not animInstance or not animInstance:IsA("Animation") then
    warn("Animation 'BaseRollCharacter' tidak ditemukan di ReplicatedStorage!")
    return
end

-- Load animation track
local rollTrack = animator:LoadAnimation(animInstance)
rollTrack.Priority = Enum.AnimationPriority.Action
rollTrack.Looped = false

local isRolling = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Abaikan jika sedang mengetik di chat atau UI lainnya
    if gameProcessed then return end

    if input.KeyCode == ROLL_KEY and not isRolling and rollTrack then
        isRolling = true
        rollTrack:Play()

        -- Reset flag setelah animasi selesai
        rollTrack.Stopped:Once(function()
            task.wait(ROLL_COOLDOWN)
            isRolling = false
        end)
    end
end)
