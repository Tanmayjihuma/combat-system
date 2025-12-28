local DamageHandler = {}

local Players = game:GetService("Players")

local HIT_COOLDOWN = 0.4
local recentHits = {} -- recentHits[targetUserId][attackerUserId] = time

local function setRecent(targetId, attackerId)
	recentHits[targetId] = recentHits[targetId] or {}
	recentHits[targetId][attackerId] = tick()
end

local function isRecent(targetId, attackerId)
	if not recentHits[targetId] then return false end
	if not recentHits[targetId][attackerId] then return false end
	return tick() - recentHits[targetId][attackerId] < HIT_COOLDOWN
end

function DamageHandler:ApplyDamage(attackerPlayer, targetCharacter, dmg)
	if not attackerPlayer or not targetCharacter then return end

	local targetHum = targetCharacter:FindFirstChildWhichIsA("Humanoid")
	if not targetHum then return end

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	local attackerId = attackerPlayer.UserId
	local targetId = targetPlayer and targetPlayer.UserId

	-- cooldown so attacker can't hit too fast
	if targetId and isRecent(targetId, attackerId) then
		return
	end

	if targetId then
		setRecent(targetId, attackerId)
	end

	-- apply actual damage
	targetHum:TakeDamage(dmg)

	-- respawn if dead
	if targetHum.Health <= 0 and targetPlayer then
		task.delay(2, function()
			pcall(function()
				targetPlayer:LoadCharacter()
			end)
		end)
	end
end

return DamageHandler
