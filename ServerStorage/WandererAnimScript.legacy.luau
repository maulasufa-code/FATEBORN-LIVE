local runService = game:GetService("RunService")
local root = script.Parent.Parent:FindFirstChild("HumanoidRootPart")
local visual = script.Parent
local time = 0
runService.Heartbeat:Connect(function(dt)
    time = time + dt
    local speed = root and root.AssemblyLinearVelocity.Magnitude or 0
    if speed > 0.5 then
        local bounce = math.sin(time * 14) * 0.2
        local rot = math.sin(time * 12) * 0.06
        visual.CFrame = root.CFrame * CFrame.new(0, bounce, 0) * CFrame.Angles(0, rot, 0)
    else
        local sway = math.sin(time * 2) * 0.02
        visual.CFrame = root.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(0, sway, 0)
    end
end)