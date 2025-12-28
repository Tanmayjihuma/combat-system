local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PowerConfig = require(ReplicatedStorage.Shared.PowerConfig)

local PowerService = {}
local playerPowers = {}

local events = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestPowerChange = events:WaitForChild("RequestPowerChange")
local powerChanged = events:WaitForChild("PowerChanged")

-- Get a player's current power
function PowerService:GetPower(player)
	return playerPowers[player] or PowerConfig.DefaultPower
end

-- Set a player's power
function PowerService:SetPower(player, newPower)
	if not PowerConfig.Powers[newPower] then return end

	playerPowers[player] = newPower

	-- Notify client
	powerChanged:FireClient(player, newPower)
end

-- Initialize connections
function PowerService:Init()
	Players.PlayerAdded:Connect(function(player)
		playerPowers[player] = PowerConfig.DefaultPower
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerPowers[player] = nil
	end)

	-- When client requests power change
	requestPowerChange.OnServerEvent:Connect(function(player, desiredPower)
		if PowerConfig.Powers[desiredPower] then
			PowerService:SetPower(player, desiredPower)
		end
	end)
end

return PowerService
