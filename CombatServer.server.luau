local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = script.Parent:WaitForChild("Modules")
local CombatSystem = require(modules:WaitForChild("CombatSystem"))

local punchEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PunchEvent")

punchEvent.OnServerEvent:Connect(function(player)
	if not player then return end
	CombatSystem:ServerHandlePunch(player)
end)
