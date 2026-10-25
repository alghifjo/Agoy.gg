--[[
    Resolves sibling Lua files for Solara (readfile / isfile).
]]

local Loader = {}

local cache = {}

local function bases()
    local list = { "", "Agoy.gg/", "Agoy.gg\\", "src/", "src\\" }
    if typeof(script) == "Instance" and script.Parent then
        -- Studio fallback; unused on Solara.
    end
    return list
end

function Loader.Path(rel)
    rel = rel:gsub("/", "\\")
    local alt = rel:gsub("\\", "/")
    if isfile then
        for _, root in ipairs(bases()) do
            local a = root .. rel
            local b = root .. alt
            if isfile(a) then
                return a
            end
            if isfile(b) then
                return b
            end
        end
    end
    return alt
end

function Loader.Import(rel)
    if cache[rel] ~= nil then
        return cache[rel]
    end
    local path = Loader.Path(rel)
    if not readfile then
        error("Solara readfile tidak tersedia. Jalankan dari executor dengan akses file: " .. rel)
    end
    if isfile and not isfile(path) then
        error("File tidak ditemukan: " .. path)
    end
    local source = readfile(path)
    local chunk, err = loadstring(source, "@" .. rel)
    if not chunk then
        error(err or ("Gagal compile " .. rel))
    end
    local result = chunk()
    cache[rel] = result
    return result
end

return Loader
