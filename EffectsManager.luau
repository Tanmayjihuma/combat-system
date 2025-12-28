local EffectsManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hitFX = ReplicatedStorage.RemoteEvents:WaitForChild("HitFXEvent")

function EffectsManager:OnHit(attackerPlayer, targetCharacter, damage, position)
	if attackerPlayer then
		-- send to attacker so they see floating damage + shake
		hitFX:FireClient(attackerPlayer, position, damage)
	end
end

return EffectsManager
