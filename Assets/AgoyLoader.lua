-- Agoys Script / AgoyLoader.lua
-- Ganti BASE_URL, atau set getgenv().AgoysBaseURL sebelum menjalankan loader.
local BASE_URL = getgenv().AgoysBaseURL or "https://raw.githubusercontent.com/alghifjo/Agoy.gg/main/assets"
local FOLDER = "assets"
local FILES = {
    "Config.lua", "Theme.lua", "Components.lua", "Dashboard.lua", "Main.lua",
    "AutoParry.lua", "Curve.lua", "Visual.lua", "AgoyLoader.lua",
}
local MODULE_ORDER = { "Config", "Theme", "Components", "AutoParry", "Curve", "Visual", "Dashboard", "Main" }

assert(type(game.HttpGet) == "function", "Executor tidak menyediakan game:HttpGet")
assert(type(writefile) == "function" and type(readfile) == "function", "Executor tidak menyediakan writefile/readfile")
assert(type(makefolder) == "function" and type(isfolder) == "function", "Executor tidak menyediakan fungsi folder")

BASE_URL = string.gsub(BASE_URL, "/+$", "")
if getgenv().AgoysScript and type(getgenv().AgoysScript.Stop) == "function" then
    pcall(getgenv().AgoysScript.Stop)
    task.wait(0.1)
end
if not isfolder(FOLDER) then makefolder(FOLDER) end

local function download(fileName)
    local url = BASE_URL .. "/" .. fileName
    local lastError = "unknown error"
    for attempt = 1, 3 do
        local ok, body = pcall(function()
            return game:HttpGet(url .. "?agoy=" .. tostring(math.floor(tick() * 1000)))
        end)
        if ok and type(body) == "string" and #body > 20 then
            local chunk, compileError = loadstring(body, "@" .. fileName)
            if chunk then
                local path = FOLDER .. "/" .. fileName
                local wrote, writeError = pcall(writefile, path, body)
                assert(wrote, "Gagal menyimpan " .. path .. ": " .. tostring(writeError))
                return path
            end
            lastError = "sintaks tidak valid / respons bukan Lua: " .. tostring(compileError)
        else
            lastError = tostring(body)
        end
        task.wait(0.35 * attempt)
    end
    error("Gagal mengunduh " .. fileName .. " setelah 3 percobaan: " .. lastError, 0)
end

local loaded = {}
local ok, loadError = pcall(function()
    for _, fileName in ipairs(FILES) do download(fileName) end
    for _, moduleName in ipairs(MODULE_ORDER) do
        local path = FOLDER .. "/" .. moduleName .. ".lua"
        local source = readfile(path)
        assert(type(source) == "string" and #source > 0, "File kosong: " .. path)
        local chunk, compileError = loadstring(source, "@" .. path)
        assert(chunk, "Compile error " .. path .. ": " .. tostring(compileError))
        local result = chunk()
        assert(type(result) == "table", path .. " harus mengembalikan table, bukan nil")
        loaded[moduleName] = result
    end
    assert(type(loaded.Main.Start) == "function", "Main.Start tidak ditemukan")
    loaded.Main.Start(loaded)
end)

if not ok then
    if loaded.Main and type(loaded.Main.Stop) == "function" then pcall(loaded.Main.Stop) end
    warn("[Agoys Loader] " .. tostring(loadError))
    error(loadError, 0)
end