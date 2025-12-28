local CombatSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local events = ReplicatedStorage:WaitForChild("RemoteEvents")
local hitFX = events:WaitForChild("HitFXEvent")

local DamageHandler = require(script.Parent:WaitForChild("DamageHandler"))
local EffectsManager = require(script.Parent:WaitForChild("EffectsManager"))
local PowerService = require(script.Parent:WaitForChild("PowerService"))
local PowerConfig = require(ReplicatedStorage.Shared.PowerConfig)

local ATTACK_RANGE = 5
local ATTACK_COOLDOWN = 0.35
local MAX_DISTANCE = 12

local lastAttack = {} -- Anti-spam

local function getRay(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position + Vector3.new(0, 1.5, 0)
	local direction = hrp.CFrame.LookVector * ATTACK_RANGE

	return origin, direction
end

function CombatSystem:ServerHandlePunch(player)
	local now = tick()
	if lastAttack[player.UserId] and now - lastAttack[player.UserId] < ATTACK_COOLDOWN then
		return
	end
	lastAttack[player.UserId] = now

	-- Character check
	local character = player.Character
	if not character then return end

	local origin, direction = getRay(character)
	if not origin then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, params)
	if not result then return end

	local hitPart = result.Instance
	if not hitPart then return end

	local targetChar = hitPart:FindFirstAncestorOfClass("Model")
	if not targetChar then return end

	local targetHum = targetChar:FindFirstChildWhichIsA("Humanoid")
	if not targetHum or targetHum.Health <= 0 then return end

	-- Distance validation
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then return end

	if (hrp.Position - targetHRP.Position).Magnitude > MAX_DISTANCE then
		return
	end

	-- Get power punch damage
	local powerName = PowerService:GetPower(player)
	local powerData = PowerConfig.Powers[powerName]

	local baseDamage = 10
	if powerData and powerData.PunchDamage then
		baseDamage = powerData.PunchDamage
	end

	local dmg = baseDamage + math.random(-2, 2)

	DamageHandler:ApplyDamage(player, targetChar, dmg)
	EffectsManager:OnHit(player, targetChar, dmg, result.Position)
	hitFX:FireClient(player, result.Position, dmg)
end

return CombatSystem
