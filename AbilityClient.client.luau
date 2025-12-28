-- AbilityClient (FULL FINAL VERSION)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local PowerConfig = require(ReplicatedStorage.Shared.PowerConfig)
local events = ReplicatedStorage:WaitForChild("RemoteEvents")
local useAbilityEvent = events:WaitForChild("UseAbilityEvent")
local powerChanged = events:WaitForChild("PowerChanged")

local currentPower = PowerConfig.DefaultPower

local abilityByKey = {}
local abilityDefs = {}
local cooldowns = {}
local holding = {}

-------------------------------------------------------------------
-- GUI
-------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AbilityHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "AbilityBar"
bar.Size = UDim2.new(0, 220, 0, 70)
bar.Position = UDim2.new(0.5, -110, 1, -90)
bar.BackgroundTransparency = 1
bar.Parent = gui

local function createButton(name, xOffset, text)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.Position = UDim2.new(0, xOffset, 0, 5)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Visible = false
	btn.Parent = bar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = btn

	local fill = Instance.new("Frame")
	fill.Name = "CooldownFill"
	fill.Size = UDim2.new(1,0,0,0)
	fill.Position = UDim2.new(0,0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(0,0,0)
	fill.BackgroundTransparency = 0.4
	fill.Visible = false
	fill.Parent = btn

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1,0)
	fillCorner.Parent = fill

	return btn, fill
end

local qButton, qFill = createButton("QButton", 10, "Q")
local rButton, rFill = createButton("RButton", 80, "R")

local buttonAbility = {
	QButton = nil,
	RButton = nil
}

-------------------------------------------------------------------
-- TOOLTIP
-------------------------------------------------------------------
local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 180, 0, 80)
tooltip.BackgroundColor3 = Color3.fromRGB(25,25,35)
tooltip.Visible = false
tooltip.Parent = gui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0,8)
tCorner.Parent = tooltip

local tooltipTitle = Instance.new("TextLabel")
tooltipTitle.Size = UDim2.new(1,-10,0,30)
tooltipTitle.Position = UDim2.new(0,5,0,5)
tooltipTitle.BackgroundTransparency = 1
tooltipTitle.Font = Enum.Font.GothamBold
tooltipTitle.TextSize = 18
tooltipTitle.TextColor3 = Color3.new(1,1,1)
tooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
tooltipTitle.Parent = tooltip

local tooltipDesc = Instance.new("TextLabel")
tooltipDesc.Size = UDim2.new(1,-10,1,-40)
tooltipDesc.Position = UDim2.new(0,5,0,35)
tooltipDesc.BackgroundTransparency = 1
tooltipDesc.Font = Enum.Font.Gotham
tooltipDesc.TextSize = 14
tooltipDesc.TextColor3 = Color3.fromRGB(200,200,200)
tooltipDesc.TextWrapped = true
tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
tooltipDesc.Parent = tooltip

local function showTooltip(btn, abilityId)
	if not abilityId then return end
	local def = abilityDefs[abilityId]
	if not def then return end

	tooltipTitle.Text = def.Id or "Ability"

	local txt = ""
	if def.Holdable then txt ..= "Type: Hold\n" else txt ..= "Type: Tap\n" end
	if def.Damage then txt ..= "Damage: " .. def.Damage .. "\n" end
	if def.TickDamage then txt ..= "Tick Damage: " .. def.TickDamage .. "\n" end
	if def.Cooldown then txt ..= "Cooldown: " .. def.Cooldown .. "s\n" end
	if def.Range then txt ..= "Range: " .. def.Range .. "\n" end

	tooltipDesc.Text = txt

	local pos = btn.AbsolutePosition
	local size = btn.AbsoluteSize

	tooltip.Position = UDim2.new(0, pos.X + size.X + 10, 0, pos.Y - 20)
	tooltip.Visible = true
end

local function hideTooltip()
	tooltip.Visible = false
end

-------------------------------------------------------------------
-- COOLDOWN SYSTEM
-------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	for abilityId, cd in pairs(cooldowns) do
		cd.remaining = math.max(0, cd.remaining - dt)
		local ratio = cd.total > 0 and cd.remaining / cd.total or 0

		local fill
		if buttonAbility.QButton == abilityId then fill = qFill end
		if buttonAbility.RButton == abilityId then fill = rFill end

		if fill then
			fill.Visible = ratio > 0
			fill.Size = UDim2.new(1,0,ratio,0)
		end
	end
end)

local function startCooldown(abilityId)
	local def = abilityDefs[abilityId]
	if not def or not def.Cooldown then return end
	cooldowns[abilityId] = { remaining = def.Cooldown, total = def.Cooldown }
end

local function isOnCooldown(abilityId)
	local cd = cooldowns[abilityId]
	return cd and cd.remaining > 0
end

-------------------------------------------------------------------
-- START / STOP ABILITY
-------------------------------------------------------------------
local function startAbility(abilityId)
	local def = abilityDefs[abilityId]
	if not def then return end
	if isOnCooldown(abilityId) then return end

	---------------------------------------------------
	-- GROUND SLAM (ONLY THIS HAS ANIMATION)
	---------------------------------------------------
	if abilityId == "GroundSlam" then
		local animId = def.Animation
		if animId then
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local track = animator:LoadAnimation(anim)

			local event1 = def.Event1 or "e1"
			local event2 = def.Event2 or "e2"

			track:GetMarkerReachedSignal(event1):Connect(function()
				useAbilityEvent:FireServer(abilityId, event1)
			end)

			track:GetMarkerReachedSignal(event2):Connect(function()
				useAbilityEvent:FireServer(abilityId, event2)
				startCooldown(abilityId)
			end)

			track:Play()
		end
		return
	end

	---------------------------------------------------
	-- LIGHTNING BEAM (HOLD)
	---------------------------------------------------
	if def.Holdable then
		if holding[abilityId] then return end
		holding[abilityId] = true
		useAbilityEvent:FireServer(abilityId, "start")

		task.delay(def.MaxHoldTime + 0.1, function()
			if holding[abilityId] then
				holding[abilityId] = false
				useAbilityEvent:FireServer(abilityId, "stop")
				startCooldown(abilityId)
			end
		end)

		return
	end

	---------------------------------------------------
	-- NORMAL ABILITIES
	---------------------------------------------------
	useAbilityEvent:FireServer(abilityId)
	startCooldown(abilityId)
end

local function stopAbility(abilityId)
	if holding[abilityId] then
		holding[abilityId] = false
		useAbilityEvent:FireServer(abilityId, "stop")
		startCooldown(abilityId)
	end
end

-------------------------------------------------------------------
-- KEYBINDS
-------------------------------------------------------------------
local function abilityInput(action, state, input)
	local abilityId = abilityByKey[input.KeyCode]
	if not abilityId then return end

	if state == Enum.UserInputState.Begin then
		startAbility(abilityId)
	elseif state == Enum.UserInputState.End then
		stopAbility(abilityId)
	end
end

local function bindKeys()
	ContextActionService:UnbindAction("AbilityKeys")

	local keys = {}
	for key in pairs(abilityByKey) do table.insert(keys, key) end

	if #keys > 0 then
		ContextActionService:BindAction("AbilityKeys", abilityInput, false, table.unpack(keys))
	end
end

-------------------------------------------------------------------
-- BUTTON SETUP
-------------------------------------------------------------------
local function rebuildAbilities()
	abilityByKey = {}
	abilityDefs = {}
	buttonAbility.QButton = nil
	buttonAbility.RButton = nil

	qButton.Visible = false
	rButton.Visible = false

	local powerData = PowerConfig.Powers[currentPower]
	if not powerData or not powerData.Abilities then
		bindKeys()
		return
	end

	for id, def in pairs(powerData.Abilities) do
		abilityDefs[id] = def

		if def.KeyCode == "Q" then
			qButton.Visible = true
			buttonAbility.QButton = id
			abilityByKey[Enum.KeyCode.Q] = id
		end

		if def.KeyCode == "R" then
			rButton.Visible = true
			buttonAbility.RButton = id
			abilityByKey[Enum.KeyCode.R] = id
		end
	end

	bindKeys()
end

-------------------------------------------------------------------
-- BUTTON EVENTS
-------------------------------------------------------------------
qButton.MouseButton1Down:Connect(function()
	if buttonAbility.QButton then startAbility(buttonAbility.QButton) end
end)
qButton.MouseButton1Up:Connect(function()
	if buttonAbility.QButton then stopAbility(buttonAbility.QButton) end
end)

rButton.MouseButton1Down:Connect(function()
	if buttonAbility.RButton then startAbility(buttonAbility.RButton) end
end)
rButton.MouseButton1Up:Connect(function()
	if buttonAbility.RButton then stopAbility(buttonAbility.RButton) end
end)

qButton.MouseEnter:Connect(function()
	showTooltip(qButton, buttonAbility.QButton)
end)
qButton.MouseLeave:Connect(hideTooltip)

rButton.MouseEnter:Connect(function()
	showTooltip(rButton, buttonAbility.RButton)
end)
rButton.MouseLeave:Connect(hideTooltip)

-------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------
rebuildAbilities()

powerChanged.OnClientEvent:Connect(function(newPower)
	currentPower = newPower
	rebuildAbilities()
end)
