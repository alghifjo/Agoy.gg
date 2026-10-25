-[[
    Agoys Script — AgoyLoader (Updated Flat Path Sync)
]]

local ROOT_FOLDER = "Agoy.gg"
local BASE_URL = "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/"

local function ensureFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

local function downloadFile(filePath)
    local url = BASE_URL .. filePath
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and content then
        writefile(ROOT_FOLDER .. "/" .. filePath, content)
    end
end

-- 1. Inisialisasi folder workspace
ensureFolder(ROOT_FOLDER)
ensureFolder(ROOT_FOLDER .. "/Modules")

-- 2. Daftar file sesuai struktur repository GitHub saat ini
local filesToSync = {
    "Config.lua",
    "Theme.lua",
    "Components.lua",
    "Dashboard.lua",
    "Visual.lua",
    "AutoParry.lua",
    "Curve.lua",
}

for _, file in ipairs(filesToSync) do
    pcall(function()
        downloadFile(file)
    end)
end

-- 3. Fungsi loader lokal dengan fallback online
local function loadLocal(path)
    local fullPath = ROOT_FOLDER .. "/" .. path
    if isfile and isfile(fullPath) then
        local source = readfile(fullPath)
        local chunk, err = loadstring(source, "@" .. path)
        if chunk then
            return chunk()
        end
    end
    return loadstring(game:HttpGet(BASE_URL .. path))()
end

-- 4. Muat semua modul inti
local Config = loadLocal("Config.lua")
local Theme = loadLocal("Theme.lua")
local Components = loadLocal("Components.lua")
local Dashboard = loadLocal("Dashboard.lua")

-- 5. Eksekusi Mount Dashboard
if Dashboard and Dashboard.Mount then
    pcall(function()
        Dashboard.Mount(Config, Theme, Components)
    end)
end

return {
    Config = Config,
    Dashboard = Dashboard
}