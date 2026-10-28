local ROOT = "AegisBladeBall"
local BASE_URL = getgenv().AEGIS_BASE_URL or ""
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