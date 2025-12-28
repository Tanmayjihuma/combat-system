local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PowerConfig = require(ReplicatedStorage.Shared.PowerConfig)

local events = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestPowerChange = events:WaitForChild("RequestPowerChange")
local powerChanged = events:WaitForChild("PowerChanged")

-- NPC Prompt Path (R15 HEAD)
local npcPrompt = workspace:WaitForChild("NPCs")
	:WaitForChild("PowerNPC")
	:WaitForChild("Head")
	:WaitForChild("PowerPrompt")

local gui
local frame

-- Create GUI
local function createGUI()
	gui = Instance.new("ScreenGui")
	gui.Name = "PowerMenu"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 260)
	frame.Position = UDim2.new(0.5, -150, 0.5, -130)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Power"
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 22
	title.Parent = frame

	local y = 50

	-- Buttons for each power
	for powerName, data in pairs(PowerConfig.Powers) do
		if powerName ~= "None" then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -20, 0, 40)
			btn.Position = UDim2.new(0, 10, 0, y)
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
			btn.Text = data.DisplayName .. " (" .. powerName .. ")"
			btn.Font = Enum.Font.Gotham
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.TextSize = 18
			btn.Parent = frame

			btn.MouseButton1Click:Connect(function()
				requestPowerChange:FireServer(powerName)
				gui.Enabled = false
			end)

			y += 45
		end
	end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 80, 0, 30)
	closeBtn.Position = UDim2.new(1, -90, 1, -40)
	closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	closeBtn.Text = "Close"
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Parent = frame

	closeBtn.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)
end

createGUI()

-- Open GUI when NPC prompt triggered
npcPrompt.Triggered:Connect(function()
	gui.Enabled = true
end)

-- Optional: small color flash when power changes
powerChanged.OnClientEvent:Connect(function()
	frame.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
	task.delay(0.2, function()
		frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	end)
end)
