--[[
    Agoys Script — AgoyLoader
    Seluruh file lokal disimpan langsung di dalam folder "assets"
]]

local ROOT_FOLDER = "assets"
local BASE_URL = "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/"

-- 1. Mengambil file langsung dari root repositori GitHub
local function safeHttp(path)
    local url = BASE_URL .. path

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or type(response) ~= "string" or response == "" then
        warn("[AgoyLoader] Gagal mengambil file dari server: " .. path)
        return nil
    end

    if response == "404: Not Found" then
        warn("[AgoyLoader] File tidak ditemukan di server: " .. path)
        return nil
    end

    return response
end

-- 2. Membuat satu folder utama lokal
if makefolder and isfolder then
    if not isfolder(ROOT_FOLDER) then
        local success, err = pcall(makefolder, ROOT_FOLDER)

        if not success then
            warn("[AgoyLoader] Gagal membuat folder assets: " .. tostring(err))
        end
    end
else
    warn("[AgoyLoader] Executor tidak menyediakan makefolder/isfolder.")
end

-- 3. Menyimpan file langsung ke assets/namafile.lua
local function saveToAssets(fileName, content)
    if not writefile then
        return
    end

    local filePath = ROOT_FOLDER .. "/" .. fileName

    local success, err = pcall(function()
        writefile(filePath, content)
    end)

    if not success then
        warn("[AgoyLoader] Gagal menyimpan " .. filePath .. ": " .. tostring(err))
    end
end

-- 4. Daftar file inti
-- Semua file berada di root GitHub dan disimpan langsung di folder assets
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

-- 5. Sinkronisasi dan eksekusi modul
for _, fileName in ipairs(filesToSync) do
    -- Contoh URL:
    -- https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/Config.lua
    local content = safeHttp(fileName)

    if content then
        -- Contoh jalur lokal: assets/Config.lua
        saveToAssets(fileName, content)

        local chunk, compileError = loadstring(content, "@" .. fileName)

        if chunk then
            local success, result = pcall(chunk)

            if success then
                local moduleName = fileName:gsub("%.lua$", "")
                loadedModules[moduleName] = result
            else
                warn(
                    "[AgoyLoader] Error saat eksekusi modul "
                    .. fileName .. ": " .. tostring(result)
                )
            end
        else
            warn(
                "[AgoyLoader] Gagal compile "
                .. fileName .. ": " .. tostring(compileError)
            )
        end
    end
end

-- 6. Inisialisasi Dashboard
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