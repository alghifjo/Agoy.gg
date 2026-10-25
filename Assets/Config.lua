-- Agoys Script / Config.lua
local Config = {}

Config.Values = {
    AutoParry = {
        Enabled = false,
        Adaptive = true,
        InputMode = "Key", -- Key | Mouse
        KeyCode = "F",
        Reaction = 0.115,
        Cooldown = 0.24,
        MinDistance = 3,
        MaxDistance = 72,
        PingFactor = 0.65,
        SpeedFactor = 0.12,
        MinPrediction = 0.045,
        MaxPrediction = 0.58,
        AssumeTargeted = true,
    },
    Curve = {
        Enabled = false,
        Mode = "Auto", -- Auto | Manual
        Target = "Closest", -- Closest | Furthest
        ManualKey = "C",
        ManualDirection = "Atas",
        Directions = { Atas = true, Bawah = true, Kiri = true, Kanan = true },
        Strength = 24,
        Range = 65,
        Cooldown = 0.28,
        Doting = false,
        DotingStrength = 48,
        -- Isi hanya jika Anda mengetahui remote game yang valid, mis. "Remotes.Curve".
        -- Kosongkan agar modul hanya menghitung arah tanpa mengirim remote.
        RemotePath = "",
        RemoteArgumentMode = "DirectionTarget", -- DirectionTarget | Direction | Vector
    },
    Visual = {
        SwordSwap = false,
        MeshID = "",
        TextureID = "",
        ParticleColor = false,
        ColorR = 96,
        ColorG = 165,
        ColorB = 250,
        VRTX = false,
        Brightness = 0.18,
        Contrast = 0.12,
        Saturation = -0.04,
        BloomIntensity = 0.32,
        BloomSize = 22,
        BloomThreshold = 1.08,
        SunRaysIntensity = 0.08,
        SunRaysSpread = 0.82,
    },
    UI = {
        ToggleKey = "RightShift",
    },
}

local listeners = {}

local function splitPath(path)
    local result = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(result, part)
    end
    return result
end

function Config.Get(path)
    local node = Config.Values
    for _, key in ipairs(splitPath(path)) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function Config.Set(path, value)
    local parts = splitPath(path)
    local node = Config.Values
    for index = 1, #parts - 1 do
        local key = parts[index]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[parts[#parts]] = value
    for _, callback in ipairs(listeners) do
        task.spawn(callback, path, value)
    end
    return value
end

function Config.Bind(callback)
    table.insert(listeners, callback)
    return function()
        local index = table.find(listeners, callback)
        if index then table.remove(listeners, index) end
    end
end

return Config