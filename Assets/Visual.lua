-- Agoys Script / Visual.lua
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Visual = {}
local player = Players.LocalPlayer
local Config
local connections = {}
local originals = setmetatable({}, { __mode = "k" })
local unbind

local function assign(instance, key, value)
    local ok = pcall(function() instance[key] = value end)
    if not ok and typeof(sethiddenproperty) == "function" then
        pcall(sethiddenproperty, instance, key, value)
    end
end

local function remember(instance)
    if originals[instance] then return end
    local data = {}
    if instance:IsA("SpecialMesh") then
        data.MeshId, data.TextureId = instance.MeshId, instance.TextureId
    elseif instance:IsA("MeshPart") then
        data.MeshID, data.TextureID = instance.MeshID, instance.TextureID
    elseif instance:IsA("ParticleEmitter") then
        data.Color = instance.Color
    end
    originals[instance] = data
end

local function applyToDescendant(instance)
    local meshId = Config.Get("Visual.MeshID")
    local textureId = Config.Get("Visual.TextureID")
    if Config.Get("Visual.SwordSwap") then
        if instance:IsA("SpecialMesh") then
            remember(instance)
            if meshId ~= "" then assign(instance, "MeshId", meshId) end
            if textureId ~= "" then assign(instance, "TextureId", textureId) end
        elseif instance:IsA("MeshPart") then
            remember(instance)
            if meshId ~= "" then assign(instance, "MeshID", meshId) end
            if textureId ~= "" then assign(instance, "TextureID", textureId) end
        end
    end
    if Config.Get("Visual.ParticleColor") and instance:IsA("ParticleEmitter") then
        remember(instance)
        local color = Color3.fromRGB(Config.Get("Visual.ColorR"), Config.Get("Visual.ColorG"), Config.Get("Visual.ColorB"))
        instance.Color = ColorSequence.new(color)
    end
end

local function applyCharacter(character)
    if not character then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, descendant in ipairs(tool:GetDescendants()) do applyToDescendant(descendant) end
        end
    end
end

local function restore()
    for instance, data in pairs(originals) do
        if instance.Parent then
            for key, value in pairs(data) do assign(instance, key, value) end
        end
    end
    table.clear(originals)
end

local function removeVRTX()
    for _, name in ipairs({ "Agoys_Color", "Agoys_Bloom", "Agoys_Sun" }) do
        local effect = Lighting:FindFirstChild(name)
        if effect then effect:Destroy() end
    end
end

local function applyVRTX()
    removeVRTX()
    if not Config.Get("Visual.VRTX") then return end
    local correction = Instance.new("ColorCorrectionEffect")
    correction.Name = "Agoys_Color"
    correction.Brightness = Config.Get("Visual.Brightness")
    correction.Contrast = Config.Get("Visual.Contrast")
    correction.Saturation = Config.Get("Visual.Saturation")
    correction.TintColor = Color3.fromRGB(246, 249, 255)
    correction.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "Agoys_Bloom"
    bloom.Intensity = Config.Get("Visual.BloomIntensity")
    bloom.Size = Config.Get("Visual.BloomSize")
    bloom.Threshold = Config.Get("Visual.BloomThreshold")
    bloom.Parent = Lighting

    local rays = Instance.new("SunRaysEffect")
    rays.Name = "Agoys_Sun"
    rays.Intensity = Config.Get("Visual.SunRaysIntensity")
    rays.Spread = Config.Get("Visual.SunRaysSpread")
    rays.Parent = Lighting
end

function Visual.Refresh()
    restore()
    applyVRTX()
    applyCharacter(player.Character)
end

function Visual.Start(config)
    Config = config
    local function onCharacter(character)
        applyCharacter(character)
        table.insert(connections, character.DescendantAdded:Connect(function(instance)
            local ancestor = instance
            while ancestor and ancestor ~= character do
                if ancestor:IsA("Tool") then
                    task.defer(applyToDescendant, instance)
                    break
                end
                ancestor = ancestor.Parent
            end
        end))
    end
    if player.Character then onCharacter(player.Character) end
    table.insert(connections, player.CharacterAdded:Connect(function(character)
        task.wait(0.4)
        onCharacter(character)
    end))
    unbind = Config.Bind(function(path)
        if string.sub(path, 1, 7) == "Visual." then Visual.Refresh() end
    end)
    Visual.Refresh()
end

function Visual.Stop()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
    if unbind then unbind(); unbind = nil end
    restore()
    removeVRTX()
end

return Visual