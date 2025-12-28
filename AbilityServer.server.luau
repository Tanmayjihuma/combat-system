local modules = script.Parent.Modules

local PowerService = require(modules:WaitForChild("PowerService"))
local AbilityManager = require(modules:WaitForChild("AbilityManager"))

PowerService:Init()
AbilityManager:Init()

-- 99360705989051