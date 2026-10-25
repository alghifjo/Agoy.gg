--[[
    Agoys Script — AgoyLoader (Robust & Secure Production Version)
]]

local ROOT_FOLDER = "Agoy.gg"
local BASE_URL = "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/"

-- 1. Validasi Fungsi Eksekutor
local function safeHttp(path)
    local url = BASE_URL .. path
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not success or not response or response == "404: Not Found" then
        warn("[AgoyLoader] Gagal mengambil file dari server: " .. path)
        return nil
    end
    return response
end

-- 2. Inisialisasi Workspace Lokal
if makefolder and isfolder then
    if not isfolder(ROOT_FOLDER) then
        pcall(function() makefolder(ROOT_FOLDER) end)
    end
end

-- 3. Sinkronisasi File Inti
local filesToSync = {
    "Config.lua",
    "Theme.lua",
    "Components.lua",
    "Dashboard.lua",
    "Visual.lua",
    "AutoParry.lua",
    "Curve.lua",
}

local loadedModules = {}

for _, file in ipairs(filesToSync) do
    local content = safeHttp(file)
    if content then
        -- Simpan ke cache lokal jika fungsi writefile tersedia
        if writefile then
            pcall(function()
                writefile(ROOT_FOLDER .. "/" .. file, content)
            end)
        end
        
        -- Compile dan load chunk
        local chunk, err = loadstring(content, "@" .. file)
        if chunk then
            local ok, res = pcall(chunk)
            if ok then
                loadedModules[file:gsub("%.lua$", "")] = res
            else
                warn("[AgoyLoader] Error saat eksekusi modul " .. file .. ": " .. tostring(res))
            end
        else
            warn("[AgoyLoader] Gagal compile " .. file .. ": " .. tostring(err))
        end
    end
end

-- 4. Inisialisasi Tampilan Dashboard UI
local Config = loadedModules["Config"]
local Theme = loadedModules["Theme"]
local Components = loadedModules["Components"]
local Dashboard = loadedModules["Dashboard"]

if Dashboard and type(Dashboard.Mount) == "function" then
    local success, err = pcall(function()
        Dashboard.Mount(Config, Theme, Components)
    end)
    if not success then
        warn("[AgoyLoader] Gagal merender Dashboard: " .. tostring(err))
    end
else
    warn("[AgoyLoader] Modul Dashboard atau fungsi Mount tidak ditemukan.")
end

return loadedModules