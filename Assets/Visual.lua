--[[
    Sword swap + Shader V-RTX (ColorCorrection, Bloom, SunRays).
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Visuals = {}

local TAG = "AgoysVRTX"
local fx = {}

local function ensure(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing:IsA(className) then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local inst = Instance.new(className)
    inst.Name = name
    inst.Parent = Lighting
    return inst
end

local function applyShader(config)
    local sh = config.Visuals.ShaderVRTX
    if not sh.Enabled then
        for _, inst in pairs(fx) do
            if inst then
                inst.Enabled = false
            end
        end
        return
    end

    fx.cc = fx.cc or ensure("ColorCorrectionEffect", TAG .. "_CC")
    fx.bloom = fx.bloom or ensure("BloomEffect", TAG .. "_Bloom")
    fx.sun = fx.sun or ensure("SunRaysEffect", TAG .. "_Sun")

    local cc = sh.ColorCorrection
    fx.cc.Enabled = true
    fx.cc.Brightness = cc.Brightness
    fx.cc.Contrast = cc.Contrast
    fx.cc.Saturation = cc.Saturation
    fx.cc.TintColor = cc.TintColor

    fx.bloom.Enabled = true
    fx.bloom.Intensity = sh.Bloom.Intensity
    fx.bloom.Size = sh.Bloom.Size
    fx.bloom.Threshold = sh.Bloom.Threshold

    fx.sun.Enabled = true
    fx.sun.Intensity = sh.SunRays.Intensity
    fx.sun.Spread = sh.SunRays.Spread
end

local function applySword(config)
    local swap = config.Visuals.SwordSwap
    local player = Players.LocalPlayer
    if not player or not player.Character then
        return
    end
    for _, inst in ipairs(player.Character:GetDescendants()) do
        if inst:IsA("SpecialMesh") and swap.Enabled then
            if swap.MeshId ~= "" and swap.MeshId ~= "rbxassetid://0" then
                inst.MeshId = swap.MeshId
            end
            if swap.TextureId ~= "" and swap.TextureId ~= "rbxassetid://0" then
                inst.TextureId = swap.TextureId
            end
        elseif inst:IsA("ParticleEmitter") and swap.Enabled then
            inst.Color = ColorSequence.new(swap.ParticleColor)
            inst.Rate = swap.ParticleRate
        end
    end
end

function Visuals.Refresh(config)
    applyShader(config)
    applySword(config)
end

function Visuals.Start(config)
    Visuals._config = config
    Visuals.Refresh(config)
    config.Watch("*", function(_, path)
        if string.sub(path, 1, 8) == "Visuals." then
            Visuals.Refresh(config)
        end
    end)
    return Visuals
end

return Visuals
