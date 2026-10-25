--[[
    Agoys Script — AgoyLoader (Online Raw Version)
]]

local BASE_URL = "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/"

local function import(path)
    local url = BASE_URL .. path
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not result then
        error("Gagal mendownload modul: " .. path)
    end
    
    local chunk, err = loadstring(result, "@" .. path)
    if not chunk then
        error(err or ("Gagal compile " .. path))
    end
    
    return chunk()
end

-- 1. Muat Config terlebih dahulu
local Config = import("Config.lua")

-- 2. Muat Komponen Dashboard UI
local Dashboard = import("UI/Dashboard.lua")

if Dashboard and Dashboard.Init then
    Dashboard.Init()
end

return import