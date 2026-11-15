==Agoy Loader===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if (method == "Kick" or method == "kick") and self == LocalPlayer then
        warn("[Anti-Kick] Kick diblokir!")
        return nil
    end
    return oldNamecall(self, ...)
end)
print("[Anti-Kick] Layer 1 (__namecall) aktif.")

if hookfunction then
    local ok, err = pcall(function()
        hookfunction(LocalPlayer.Kick, function()
            warn("[Anti-Kick][L2] Kick via hookfunction diblokir!")
            return nil
        end)
    end)
    if ok then
        print("[Anti-Kick] Layer 2 (hookfunction Kick) aktif.")
    else
        warn("[Anti-Kick] Layer 2 gagal: " .. tostring(err))
    end
end

if hookmetamethod and getrawmetatable then
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        if self == LocalPlayer and (key == "Kick" or key == "kick") then
            return function()
                warn("[Anti-Kick][L3] Akses Kick diblokir via __index!")
            end
        end
        return oldIndex(self, key)
    end)

    setreadonly(mt, true)
    print("[Anti-Kick] Layer 3 (__index) aktif.")
end

print("[Anti-Kick] Advanced aktif - semua layer terpasang.")

local ROOT = "AegisBladeBall"
local BASE_URL = getgenv().AEGIS_BASE_URL or "https://raw.githubusercontent.com/alghifjo/Agoy.gg/refs/heads/main/Assets/AgoyLoader.lua"
local FILES = { "Config.lua", "Theme.lua", "Components.lua", "BallTracker.lua", "AutoParry.lua", "Dashboard.lua", "Main.lua" }

assert(type(game.HttpGet) == "function", "game:HttpGet tidak tersedia")
assert(type(writefile) == "function" and type(loadfile) == "function", "API filesystem Solara tidak tersedia")

if getgenv().AegisRuntime and type(getgenv().AegisRuntime.Stop) == "function" then
	pcall(getgenv().AegisRuntime.Stop)
	getgenv().AegisRuntime = nil
end

if not isfolder(ROOT) then
	makefolder(ROOT)
end
if not isfolder(ROOT .. "/assets") then
	makefolder(ROOT .. "/assets")
end

local function compile(source, chunkName)
	local chunk, compileError = loadstring(source, chunkName)
	assert(chunk, compileError)
	return chunk
end

for _, fileName in ipairs(FILES) do
	local path = ROOT .. "/assets/" .. fileName
	local ok, source = pcall(function()
		return game:HttpGet(BASE_URL .. "/" .. fileName)
	end)
	if ok and type(source) == "string" and #source > 0 then
		compile(source, "@" .. fileName) -- Jangan men-cache HTML atau modul rusak.
		writefile(path, source)
	elseif not isfile(path) then
		error("Gagal mengunduh " .. fileName .. " dan cache lokal tidak tersedia")
	else
		warn("[Aegis] Memakai cache untuk " .. fileName)
	end
end

local moduleCache = {}
local function requireAsset(name)
	if moduleCache[name] then
		return moduleCache[name]
	end
	local path = ROOT .. "/assets/" .. name .. ".lua"
	local chunk, loadError = loadfile(path)
	assert(chunk, loadError)
	local result = chunk()
	moduleCache[name] = result
	return result
end

local main = requireAsset("Main")
return main.Start(requireAsset)