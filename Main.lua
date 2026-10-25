--[[
    Agoys Script — Blade Ball (Solara)
    Entry: jalankan file ini dari folder Agoy.gg.
]]

local function loadRel(rel)
    if getgenv and getgenv().AgoysModules and getgenv().AgoysModules[rel] then
        return getgenv().AgoysModules[rel]
    end
    if not readfile then
        error("Executor tidak menyediakan readfile. Letakkan proyek di workspace Solara dan jalankan Main.lua.")
    end
    local candidates = { rel, rel:gsub("/", "\\"), "Agoy.gg/" .. rel, "Agoy.gg\\" .. rel:gsub("/", "\\") }
    local source
    for i = 1, #candidates do
        local path = candidates[i]
        if not isfile or isfile(path) then
            local ok, data = pcall(readfile, path)
            if ok and type(data) == "string" and #data > 0 then
                source = data
                break
            end
        end
    end
    if not source then
        error("Tidak bisa membaca " .. rel)
    end
    local chunk, err = loadstring(source, "@" .. rel)
    if not chunk then
        error(err)
    end
    return chunk()
end

local Config = loadRel("Config.lua")
local Theme = loadRel("src/UI/Theme.lua").Attach(Config)
local Components = loadRel("src/UI/Components.lua").Attach(Config, Theme)
local Dashboard = loadRel("src/UI/Dashboard.lua")
local AutoParry = loadRel("src/Features/AutoParry.lua").Start(Config)
local Curve = loadRel("src/Features/Curve.lua").Start(Config)
local Visuals = loadRel("src/Features/Visuals.lua").Start(Config)

Dashboard.Mount(Config, Theme, Components)

local Agoy = {
    Config = Config,
    AutoParry = AutoParry,
    Curve = Curve,
    Visuals = Visuals,
    Dashboard = Dashboard,
}

if getgenv then
    getgenv().Agoy = Agoy
end

return Agoy
