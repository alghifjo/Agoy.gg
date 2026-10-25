--[[
    Agoys Script — Loader (Online GitHub Version)
]]

local repoOwner = "USERNAME_GITHUB_KAMU" -- Ganti dengan username GitHub kamu
local repoName = "NAMA_REPO_KAMU"     -- Ganti dengan nama repository GitHub kamu
local branch = "main"

local function getUrl(path)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", repoOwner, repoName, branch, path)
end

local Loader = {}
local cache = {}

function Loader.Import(rel)
    if cache[rel] ~= nil then
        return cache[rel]
    end
    
    local url = getUrl(rel)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not content then
        error("Gagal mengunduh modul dari GitHub: " .. rel)
    end
    
    local chunk, err = loadstring(content, "@" .. rel)
    if not chunk then
        error(err or ("Gagal compile " .. rel))
    end
    
    local result = chunk()
    cache[rel] = result
    return result
end

-- 1. Muat Config terlebih dahulu
local Config = Loader.Import("Config.lua")

-- 2. Muat Komponen dan Dashboard UI
local Dashboard = Loader.Import("UI/Dashboard.lua")

if Dashboard and Dashboard.Init then
    Dashboard.Init()
end

return Loader