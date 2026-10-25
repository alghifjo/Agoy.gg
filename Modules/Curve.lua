--[[
    Curve — Auto/Manual, target Closest/Furthest, arah acak, Doting terpisah.
]]

local Curve = {}

local AXES = {
    Up = Vector3.new(0, 1, 0),
    Down = Vector3.new(0, -1, 0),
    Left = Vector3.new(-1, 0, 0),
    Right = Vector3.new(1, 0, 0),
}

local function activeKeys(directions)
    local keys = {}
    for name, on in pairs(directions) do
        if on then
            keys[#keys + 1] = name
        end
    end
    return keys
end

function Curve.PickDirection(config)
    local c = config.Curve
    if c.Doting.Enabled then
        return Vector3.new(0, 0, 0), "Doting"
    end
    if c.Mode == "Manual" then
        local key = c.Manual.Direction
        return AXES[key] or AXES.Up, key
    end
    if not c.Auto.Enabled then
        return nil, nil
    end
    local keys = activeKeys(c.Auto.Directions)
    if #keys == 0 then
        return AXES.Up, "Up"
    end
    if c.Auto.RandomizeDirections then
        local key = keys[math.random(1, #keys)]
        return AXES[key], key
    end
    local sum = Vector3.new()
    for i = 1, #keys do
        sum += AXES[keys[i]]
    end
    if sum.Magnitude > 0 then
        sum = sum.Unit
    end
    return sum, "Blend"
end

function Curve.SelectTarget(config, origin, players, localPlayer)
    local c = config.Curve.Auto
    local wantFurthest = c.Target == "Furthest"
    local best, bestDist = nil, wantFurthest and -math.huge or math.huge
    for i = 1, #players do
        local plr = players[i]
        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - origin).Magnitude
            if wantFurthest then
                if d > bestDist then
                    best, bestDist = plr, d
                end
            else
                if d < bestDist then
                    best, bestDist = plr, d
                end
            end
        end
    end
    return best, bestDist
end

function Curve.Start(config)
    Curve._config = config
    return Curve
end

return Curve
