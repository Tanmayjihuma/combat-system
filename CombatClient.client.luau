local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local punchEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PunchEvent")
local hitFX = ReplicatedStorage.RemoteEvents:WaitForChild("HitFXEvent")

-- Punch animation
local ANIM_PUNCH = "rbxassetid://00000000" -- TODO: replace with your real animation Id
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local punchTrack
if ANIM_PUNCH ~= "rbxassetid://00000000" then
	local anim = Instance.new("Animation")
	anim.AnimationId = ANIM_PUNCH
	punchTrack = animator:LoadAnimation(anim)
end

local function doPunch()
	if punchTrack then
		punchTrack:Play()
	end
	punchEvent:FireServer()
end

-- Left click for punch (PC)
local function punchAction(actionName, state, input)
	if state == Enum.UserInputState.Begin then
		doPunch()
	end
end

ContextActionService:BindAction(
	"ImpactX_Punch",
	punchAction,
	false,
	Enum.UserInputType.MouseButton1
)

---------------------------------------------------
-- PUNCH BUTTON (MOBILE + PC)
---------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "CombatHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "PunchButton"
btn.Size = UDim2.new(0, 80, 0, 80)
btn.Position = UDim2.new(1, -100, 1, -120)
btn.AnchorPoint = Vector2.new(0, 0)
btn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
btn.Font = Enum.Font.GothamBold
btn.TextColor3 = Color3.new(1, 1, 1)
btn.TextSize = 18
btn.Text = "Punch"
btn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = btn

btn.MouseButton1Click:Connect(function()
	doPunch()
end)

---------------------------------------------------
-- Hit FX from server (same as before)
---------------------------------------------------
hitFX.OnClientEvent:Connect(function(position, damage)
	-- Floating damage text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = workspace.CurrentCamera

	local text = Instance.new("TextLabel")
	
	
	
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 50, 50)
	text.TextStrokeTransparency = 0
	text.TextScaled = true
	text.Text = math.floor(damage)
	text.Parent = billboard

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position)
	part.Parent = workspace

	billboard.Adornee = part

	task.spawn(function()
		for i = 1, 25 do
			part.Position += Vector3.new(0, 0.05, 0)
			task.wait(0.02)
		end
		billboard:Destroy()
		part:Destroy()
	end)

	-- Camera shake
	local camera = workspace.CurrentCamera
	local orig = camera.CFrame
	task.spawn(function()
		for i = 1, 5 do
			camera.CFrame *= CFrame.new((math.random() - 0.5) * 0.2, (math.random() - 0.5) * 0.2, 0)
			task.wait(0.02)
		end
		camera.CFrame = orig
	end)
end)
