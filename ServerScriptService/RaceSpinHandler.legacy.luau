local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpinSystem = require(ServerStorage:WaitForChild("ZeroScript", 10):WaitForChild("SpinSystem", 10))
local spinRemote = ReplicatedStorage:WaitForChild("SpinRaceEvent", 10)

spinRemote.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Race") then
		return
	end

	local race = SpinSystem.spinRace()
	SpinSystem.applyRace(player, race)
	print(("%s rolled race: %s (%s)"):format(player.Name, race.name, race.tier))

	spinRemote:FireClient(player, {
		name = race.name,
		tier = race.tier,
		description = race.description,
		passives = race.passives
	})
end)
