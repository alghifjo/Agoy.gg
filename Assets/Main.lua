-- Agoys Script / Main.lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Main = { Running = false }
local modules
local heartbeatConnection
local inputConnection
local window

function Main.Start(loadedModules)
    if Main.Running then Main.Stop() end
    modules = loadedModules
    for _, name in ipairs({ "Config", "Theme", "Components", "Dashboard", "AutoParry", "Curve", "Visual" }) do
        assert(type(modules[name]) == "table", "Modul tidak valid: " .. name)
    end
    Main.Running = true
    modules.AutoParry.Start(modules.Config)
    modules.Curve.Start(modules.Config)
    modules.Visual.Start(modules.Config)
    window = modules.Dashboard.Mount(modules)

    heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not Main.Running then return end
        local okParry, parryError = pcall(modules.AutoParry.Step, deltaTime)
        if not okParry then warn("[Agoys AutoParry] " .. tostring(parryError)); Main.Running = false end
        local okCurve, curveError = pcall(modules.Curve.Step, deltaTime)
        if not okCurve then warn("[Agoys Curve] " .. tostring(curveError)) end
    end)
    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local configured = modules.Config.Get("UI.ToggleKey")
        if Enum.KeyCode[configured] and input.KeyCode == Enum.KeyCode[configured] and window then
            window.Toggle()
        end
    end)

    getgenv().AgoysScript = { Stop = Main.Stop, Modules = modules, Version = "1.0.0" }
    print("[Agoys] Dashboard berhasil dimuat. RightShift untuk show/hide.")
end

function Main.Stop()
    if not modules then return end
    Main.Running = false
    if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection = nil end
    if inputConnection then inputConnection:Disconnect(); inputConnection = nil end
    pcall(function() modules.AutoParry.Stop() end)
    pcall(function() modules.Curve.Stop() end)
    pcall(function() modules.Visual.Stop() end)
    pcall(function() modules.Dashboard.Destroy() end)
    window = nil
    if getgenv().AgoysScript and getgenv().AgoysScript.Modules == modules then
        getgenv().AgoysScript = nil
    end
    modules = nil
end

return Main