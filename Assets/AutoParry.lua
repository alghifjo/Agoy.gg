-- Agoys Script / AutoParry.lua
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoParry = {}
local player = Players.LocalPlayer
local Config
local lastParry = 0
local ballTimes = setmetatable({}, { __mode = "k" })
local refreshTimer = 0
local cachedBalls = {}

local function rootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getBalls()
    local result = {}
    local folder = workspace:FindFirstChild("Balls")
    local source = folder and folder:GetChildren() or workspace:GetChildren()
    for _, item in ipairs(source) do
        if item:IsA("BasePart") then
            local name = string.lower(item.Name)
            if folder or string.find(name, "ball") then table.insert(result, item) end
        end
    end
    return result
end

local function isTargeted(ball)
    local attributes = { "target", "Target", "player", "Player", "victim", "Victim" }
    for _, key in ipairs(attributes) do
        local ok, value = pcall(function() return ball:GetAttribute(key) end)
        if ok and value ~= nil then
            if value == player or value == player.Name or value == player.DisplayName or value == player.UserId then return true end
            if typeof(value) == "Instance" and value == player then return true end
            return false
        end
    end
    for _, child in ipairs(ball:GetChildren()) do
        if child:IsA("ObjectValue") and (child.Name == "Target" or child.Name == "target") then
            return child.Value == player or child.Value == player.Character
        end
        if child:IsA("StringValue") and (child.Name == "Target" or child.Name == "target") then
            return child.Value == player.Name
        end
    end
    return Config.Get("AutoParry.AssumeTargeted")
end

local function pingSeconds()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    return ok and math.clamp(value, 0, 0.35) or 0.05
end

local function pressParry()
    local mode = Config.Get("AutoParry.InputMode")
    if mode == "Mouse" then
        if typeof(mouse1press) == "function" and typeof(mouse1release) == "function" then
            pcall(mouse1press)
            task.delay(0.035, function() pcall(mouse1release) end)
        else
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.035)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
        return
    end
    local keyName = Config.Get("AutoParry.KeyCode") or "F"
    local key = Enum.KeyCode[keyName] or Enum.KeyCode.F
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.delay(0.035, function()
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end)
end

function AutoParry.Start(config)
    Config = config
    lastParry = 0
    refreshTimer = 0
end

function AutoParry.Step(deltaTime)
    if not Config or not Config.Get("AutoParry.Enabled") then return end
    local root = rootPart()
    if not root then return end
    refreshTimer = refreshTimer - deltaTime
    if refreshTimer <= 0 then
        cachedBalls = getBalls()
        refreshTimer = 0.12
    end
    local now = os.clock()
    if now - lastParry < Config.Get("AutoParry.Cooldown") then return end

    for _, ball in ipairs(cachedBalls) do
        if ball.Parent and isTargeted(ball) then
            local offset = root.Position - ball.Position
            local distance = offset.Magnitude
            if distance <= Config.Get("AutoParry.MaxDistance") and distance > 0.05 then
                local velocity = ball.AssemblyLinearVelocity
                local relativeVelocity = velocity - root.AssemblyLinearVelocity
                local closingSpeed = relativeVelocity:Dot(offset) / distance
                local speed = velocity.Magnitude
                if closingSpeed > 0.5 and speed > 0.5 then
                    local effectiveSpeed = math.max(closingSpeed, speed * 0.35, 1)
                    local timeToImpact = distance / effectiveSpeed
                    local prediction = Config.Get("AutoParry.Reaction")
                    if Config.Get("AutoParry.Adaptive") then
                        prediction = prediction + pingSeconds() * Config.Get("AutoParry.PingFactor")
                        prediction = prediction + math.min(speed / 1000, 1) * Config.Get("AutoParry.SpeedFactor")
                    end
                    prediction = math.clamp(prediction, Config.Get("AutoParry.MinPrediction"), Config.Get("AutoParry.MaxPrediction"))
                    local lastForBall = ballTimes[ball] or 0
                    if timeToImpact <= prediction and now - lastForBall > 0.35 then
                        ballTimes[ball] = now
                        lastParry = now
                        pressParry()
                        break
                    end
                end
            end
        end
    end
end

function AutoParry.Stop()
    table.clear(ballTimes)
    table.clear(cachedBalls)
end

return AutoParry