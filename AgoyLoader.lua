--[[
    Agoys Script — AgoyLoader (Auto Workspace Downloader)
]]

local ROOT_FOLDER = "Agoy.gg"
local BASE_URL = "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/"

-- Fungsi untuk memastikan folder lokal ada
local function ensureFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

-- Fungsi untuk mendownload dan menyimpan file ke workspace lokal jika belum ada/perlu update
local function downloadFile(filePath)
    local url = BASE_URL .. filePath
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and content then
        -- Buat direktori subfolder jika ada (misal: UI/)
        local lastSlash = filePath:match(".*()/")
        if lastSlash then
            local dir = ROOT_FOLDER .. "/" .. filePath:sub(1, lastSlash - 1)
            ensureFolder(dir)
        end
        
        writefile(ROOT_FOLDER .. "/" .. filePath, content)
    end
end

-- 1. Inisialisasi folder workspace utama
ensureFolder(ROOT_FOLDER)
ensureFolder(ROOT_FOLDER .. "/UI")
ensureFolder(ROOT_FOLDER .. "/Modules")

-- 2. Sinkronkan file inti secara otomatis dari GitHub ke workspace
local filesToSync = {
    "Config.lua",
    "UI/Dashboard.lua",
    -- Tambahkan file modul lain di sini jika ada
}

for _, file in ipairs(filesToSync) do
    pcall(function()
        downloadFile(file)
    end)
end

-- 3. Load Config dan Dashboard dari file lokal workspace yang sudah di-sync
local function loadLocal(path)
    local fullPath = ROOT_FOLDER .. "/" .. path
    if isfile and isfile(fullPath) then
        local source = readfile(fullPath)
        local chunk, err = loadstring(source, "@" .. path)
        if chunk then
            return chunk()
        end
    end
    -- Fallback langsung dari web jika file lokal gagal
    return loadstring(game:HttpGet(BASE_URL .. path))()
end

local Config = loadLocal("Config.lua")
local Dashboard = loadLocal("UI/Dashboard.lua")

if Dashboard and Dashboard.Init then
    Dashboard.Init()
end

return {
    Config = Config,
    Dashboard = Dashboard
}