-- Agoys Script / Curve.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Curve = { LastDirection = nil, LastTarget = nil }
local player = Players.LocalPlayer
local Config
local random = Random.new()
local inputConnection
local lastUse = 0
local ballTimes = setmetatable({}, { __mode = "k" })
local refreshTimer = 0
local cachedBalls = {}

local function rootPart(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function myRoot()
    return rootPart(player.Character)
end

local function getBalls()
    local result = {}
    local folder = workspace:FindFirstChild("Balls")
    local source = folder and folder:GetChildren() or workspace:GetChildren()
    for _, item in ipairs(source) do
        if item:IsA("BasePart") and (folder or string.find(string.lower(item.Name), "ball")) then
            table.insert(result, item)
        end
    end
    return result
end

local function ballTargetsMe(ball)
    for _, key in ipairs({ "target", "Target", "player", "Player" }) do
        local ok, value = pcall(function() return ball:GetAttribute(key) end)
        if ok and value ~= nil then
            return value == player.Name or value == player.DisplayName or value == player.UserId or value == player
        end
    end
    return true
end

local function chooseTarget(ball)
    local origin = ball and ball.Position or (myRoot() and myRoot().Position)
    if not origin then return nil end
    local wanted = Config.Get("Curve.Target")
    local selected, selectedDistance = nil, wanted == "Closest" and math.huge or -math.huge
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local root = rootPart(other.Character)
            local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - origin).Magnitude
                if (wanted == "Closest" and distance < selectedDistance) or
                   (wanted ~= "Closest" and distance > selectedDistance) then
                    selected, selectedDistance = root, distance
                end
            end
        end
    end
    return selected
end

local function enabledDirections()
    local result = {}
    local directions = Config.Get("Curve.Directions")
    for _, name in ipairs({ "Atas", "Bawah", "Kiri", "Kanan" }) do
        if directions[name] then table.insert(result, name) end
    end
    if #result == 0 then table.insert(result, "Atas") end
    return result
end

local function calculateDirection(ball, target)
    local origin = ball and ball.Position or (myRoot() and myRoot().Position)
    if not origin then return nil end
    local destination = target and target.Position
    if not destination and workspace.CurrentCamera then
        destination = origin + workspace.CurrentCamera.CFrame.LookVector * 30
    end
    if not destination then return nil end
    local direction = destination - origin
    if direction.Magnitude < 0.05 then return nil end
    direction = direction.Unit

    if Config.Get("Curve.Doting") then return direction end
    local directionName = Config.Get("Curve.ManualDirection")
    if Config.Get("Curve.Mode") == "Auto" then
        local choices = enabledDirections()
        directionName = choices[random:NextInteger(1, #choices)]
    end
    if directionName == "Atas" then
        direction = (direction + Vector3.new(0, 0.48, 0)).Unit
    elseif directionName == "Bawah" then
        direction = (direction + Vector3.new(0, -0.32, 0)).Unit
    elseif directionName == "Kiri" then
        direction = (CFrame.Angles(0, math.rad(24), 0):VectorToWorldSpace(direction)).Unit
    elseif directionName == "Kanan" then
        direction = (CFrame.Angles(0, math.rad(-24), 0):VectorToWorldSpace(direction)).Unit
    end
    return direction
end

local function resolveRemote(path)
    if type(path) ~= "string" or path == "" then return nil end
    local node = ReplicatedStorage
    for part in string.gmatch(path, "[^.]+") do
        node = node:FindFirstChild(part)
        if not node then return nil end
    end
    return node
end

local function dispatch(direction, target)
    local remote = resolveRemote(Config.Get("Curve.RemotePath"))
    if not remote then return false, "RemotePath kosong atau tidak ditemukan" end
    local strength = Config.Get("Curve.Doting") and Config.Get("Curve.DotingStrength") or Config.Get("Curve.Strength")
    local mode = Config.Get("Curve.RemoteArgumentMode")
    local ok, err = pcall(function()
        if mode == "Direction" then
            remote:FireServer(direction)
        elseif mode == "Vector" then
            remote:FireServer(direction * strength)
        else
            remote:FireServer(direction, target)
        end
    end)
    return ok, err
end

function Curve.Use(manual)
    if not Config or not Config.Get("Curve.Enabled") then return false end
    local now = os.clock()
    if now - lastUse < Config.Get("Curve.Cooldown") then return false end
    local ball = cachedBalls[1]
    if not ball or not ball.Parent then ball = getBalls()[1] end
    local target = chooseTarget(ball)
    local direction = calculateDirection(ball, target)
    if not direction then return false end
    Curve.LastDirection = direction
    Curve.LastTarget = target
    lastUse = now
    return dispatch(direction, target)
end

function Curve.Start(config)
    Config = config
    lastUse = 0
    if inputConnection then inputConnection:Disconnect() end
    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or Config.Get("Curve.Mode") ~= "Manual" then return end
        local key = Enum.KeyCode[Config.Get("Curve.ManualKey") or "C"]
        if key and input.KeyCode == key then Curve.Use(true) end
    end)
end

function Curve.Step(deltaTime)
    if not Config or not Config.Get("Curve.Enabled") or Config.Get("Curve.Mode") ~= "Auto" then return end
    local root = myRoot()
    if not root then return end
    refreshTimer = refreshTimer - deltaTime
    if refreshTimer <= 0 then
        cachedBalls = getBalls()
        refreshTimer = 0.15
    end
    local now = os.clock()
    for _, ball in ipairs(cachedBalls) do
        if ball.Parent and ballTargetsMe(ball) then
            local distance = (ball.Position - root.Position).Magnitude
            if distance <= Config.Get("Curve.Range") and now - (ballTimes[ball] or 0) > 0.6 then
                ballTimes[ball] = now
                Curve.Use(false)
                break
            end
        end
    end
end

function Curve.Stop()
    if inputConnection then inputConnection:Disconnect(); inputConnection = nil end
    table.clear(cachedBalls)
    table.clear(ballTimes)
end

return Curve