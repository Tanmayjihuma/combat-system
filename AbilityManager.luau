local AbilityManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local events = ReplicatedStorage:WaitForChild("RemoteEvents")
local useAbilityEvent = events:WaitForChild("UseAbilityEvent")
local hitFX = events:WaitForChild("HitFXEvent")

local PowerConfig = require(ReplicatedStorage.Shared.PowerConfig)
local PowerService = require(script.Parent.PowerService)
local DamageHandler = require(script.Parent.DamageHandler)
local EffectsManager = require(script.Parent.EffectsManager)

local cooldowns = {}
local activeBeams = {}

local function setCooldown(player, abilityId)
	local uid = player.UserId
	cooldowns[uid] = cooldowns[uid] or {}
	cooldowns[uid][abilityId] = tick()
end

local function onCooldown(player, abilityId, cd)
	local uid = player.UserId
	cooldowns[uid] = cooldowns[uid] or {}
	local last = cooldowns[uid][abilityId]
	if not last then return false end
	return (tick() - last) < cd
end

local function lightningDash(player, def)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * def.DashDistance
end

local function bruteHeavyPunch(player, def)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position + Vector3.new(0, 1.5, 0)
	local dir = hrp.CFrame.LookVector * def.Range

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, dir, params)
	if not result then return end

	local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
	local hum = hitChar and hitChar:FindFirstChildWhichIsA("Humanoid")

	if hum and hum.Health > 0 then
		DamageHandler:ApplyDamage(player, hitChar, def.Damage)
		EffectsManager:OnHit(player, hitChar, def.Damage, result.Position)
		hitFX:FireClient(player, result.Position, def.Damage)
	end
end

local function windDash(player, def)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * def.DashDistance
end

local function windGust(player, def)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position
	local radius = def.Range or 20

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {char}

	local parts = workspace:GetPartBoundsInRadius(origin, radius, params)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitModels[model] then
			local hum = model:FindFirstChildWhichIsA("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")

			if hum and root and hum.Health > 0 then
				hitModels[model] = true

				local dir = (root.Position - origin).Unit
				root.Velocity = dir * (def.KnockbackStrength or 70) + Vector3.new(0, 20, 0)

				if def.Damage then
					DamageHandler:ApplyDamage(player, model, def.Damage)
				end

				EffectsManager:OnHit(player, model, def.Damage, root.Position)
				hitFX:FireClient(player, root.Position, def.Damage)
			end
		end
	end
end

local function bruteGroundSlam(player, def, eventType)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position
	local radius = def.Radius or 18

	if eventType == "e1" then
		local folder = ReplicatedStorage:WaitForChild("Sounds")
		local sfx = folder:FindFirstChild("Slam") or folder:GetChildren()[1]
		if sfx then
			local s = sfx:Clone()
			s.Parent = hrp
			s:Play()
			Debris:AddItem(s, 3)
		end
		return
	end

	if eventType == "e2" then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {char}

		local parts = workspace:GetPartBoundsInRadius(origin, radius, params)
		local hitModels = {}

		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and not hitModels[model] then
				local hum = model:FindFirstChildWhichIsA("Humanoid")
				local root = model:FindFirstChild("HumanoidRootPart")

				if hum and root and hum.Health > 0 then
					hitModels[model] = true

					local dir = (root.Position - origin).Unit
					root.Velocity = dir * (def.KnockbackStrength or 80) + Vector3.new(0, 35, 0)

					DamageHandler:ApplyDamage(player, model, def.Damage)
					EffectsManager:OnHit(player, model, def.Damage, root.Position)
					hitFX:FireClient(player, root.Position, def.Damage)
				end
			end
		end
	end
end

local function stopLightningBeam(player, def)
	local data = activeBeams[player]
	if not data then return end

	local char = player.Character
	if char then
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum and data.originalSpeed then
			hum.WalkSpeed = data.originalSpeed
		end
	end

	activeBeams[player] = nil

	if def.Cooldown and def.Cooldown > 0 then
		setCooldown(player, def.Id)
	end
end

local function startLightningBeam(player, def)
	if onCooldown(player, def.Id, def.Cooldown) then return end
	if activeBeams[player] then return end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	activeBeams[player] = {
		def = def,
		endTime = tick() + (def.MaxHoldTime or 3),
		originalSpeed = hum.WalkSpeed,
	}

	hum.WalkSpeed = 2

	local tickDamage = def.TickDamage or 3
	local tickInterval = def.TickInterval or 0.15
	local range = def.Range or 70

	task.spawn(function()
		while activeBeams[player] do
			local data = activeBeams[player]
			if tick() > data.endTime then break end

			char = player.Character
			if not char then break end

			hum = char:FindFirstChildWhichIsA("Humanoid")
			hrp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp then break end

			local origin = hrp.Position + Vector3.new(0,1.5,0)
			local dir = hrp.CFrame.LookVector * range

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = {char}

			local result = workspace:Raycast(origin, dir, params)
			local hitPos = origin + dir

			if result then
				hitPos = result.Position
			end

			local distance = (hitPos - origin).Magnitude
			local beam = Instance.new("Part")
			beam.Anchored = true
			beam.CanCollide = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(255,255,100)
			beam.Size = Vector3.new(0.3,0.3,distance)
			beam.CFrame = CFrame.lookAt(origin + hrp.CFrame.LookVector * (distance/2), hitPos)
			beam.Parent = workspace
			Debris:AddItem(beam, 0.15)

			if result then
				local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
				local hum2 = hitChar and hitChar:FindFirstChildWhichIsA("Humanoid")
				if hum2 and hum2.Health > 0 then
					DamageHandler:ApplyDamage(player, hitChar, tickDamage)
					EffectsManager:OnHit(player, hitChar, tickDamage, hitPos)
					hitFX:FireClient(player, hitPos, tickDamage)
				end
			end

			task.wait(tickInterval)
		end

		if activeBeams[player] then
			stopLightningBeam(player, def)
		end
	end)
end

local function executeNonHold(player, power, abilityId, def)
	if power == "Lightning" then
		if abilityId == "LightningDash" then lightningDash(player, def) end

	elseif power == "Brute" then
		if abilityId == "HeavyPunch" then bruteHeavyPunch(player, def) end
		if abilityId == "GroundSlam" then end

	elseif power == "Wind" then
		if abilityId == "WindDash" then windDash(player, def)
		elseif abilityId == "WindGust" then windGust(player, def) end
	end
end

function AbilityManager:Init()
	useAbilityEvent.OnServerEvent:Connect(function(player, abilityId, state)
		local power = PowerService:GetPower(player)
		local def = PowerConfig.Powers[power].Abilities[abilityId]
		if not def then return end

		if abilityId == "GroundSlam" then
			if state == "e1" or state == "e2" then
				bruteGroundSlam(player, def, state)
				return
			else
				if def.Cooldown and not onCooldown(player, abilityId, def.Cooldown) then
					setCooldown(player, abilityId)
				end
				return
			end
		end

		if abilityId == "LightningBeam" and def.Holdable then
			if state == "start" then startLightningBeam(player, def) end
			if state == "stop" then stopLightningBeam(player, def) end
			return
		end

		if state == nil then
			if def.Cooldown and not onCooldown(player, abilityId, def.Cooldown) then
				setCooldown(player, abilityId)
			end
			executeNonHold(player, power, abilityId, def)
		end
	end)
end

return AbilityManager
