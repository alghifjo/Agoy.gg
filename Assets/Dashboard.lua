-- Agoys Script / Dashboard.lua
local Dashboard = {}
local currentWindow

local function toggle(C, page, title, description, path)
    return C.Toggle(page, title, description, Dashboard.Config.Get(path), function(value)
        Dashboard.Config.Set(path, value)
    end)
end

local function slider(C, page, title, description, path, minimum, maximum, decimals)
    return C.Slider(page, title, description, minimum, maximum, Dashboard.Config.Get(path), decimals, function(value)
        Dashboard.Config.Set(path, value)
    end)
end

local function dropdown(C, page, title, description, path, values)
    return C.Dropdown(page, title, description, values, Dashboard.Config.Get(path), function(value)
        Dashboard.Config.Set(path, value)
    end)
end

local function textbox(C, page, title, description, path, placeholder)
    return C.TextBox(page, title, description, Dashboard.Config.Get(path), placeholder, function(value)
        Dashboard.Config.Set(path, value)
    end)
end

function Dashboard.Mount(modules)
    if currentWindow then currentWindow.Destroy(); currentWindow = nil end
    local C, Config = modules.Components, modules.Config
    assert(C and Config, "Dashboard membutuhkan Components dan Config")
    Dashboard.Config = Config
    C.Init(modules.Theme)
    local window = C.CreateWindow({ Title = "Agoys Script", Subtitle = "Blade Ball  /  Control Center" })
    currentWindow = window

    local gameplay = window.AddTab("Gameplay", 1)
    C.Section(gameplay, "Auto Parry")
    toggle(C, gameplay, "Aktifkan Auto Parry", "Parry berdasarkan estimasi waktu tiba bola", "AutoParry.Enabled")
    toggle(C, gameplay, "Prediksi adaptif", "Kompensasi ping dan kecepatan bola secara dinamis", "AutoParry.Adaptive")
    dropdown(C, gameplay, "Metode input", "Gunakan Key bila Mouse tidak kompatibel", "AutoParry.InputMode", { "Key", "Mouse" })
    slider(C, gameplay, "Reaksi dasar", "Ambang prediksi awal dalam detik", "AutoParry.Reaction", 0.04, 0.25, 3)
    slider(C, gameplay, "Cooldown", "Jeda minimum antar parry", "AutoParry.Cooldown", 0.12, 0.60, 2)
    slider(C, gameplay, "Jarak maksimum", "Batas jarak deteksi bola", "AutoParry.MaxDistance", 25, 120, 0)
    slider(C, gameplay, "Faktor ping", "Besar kompensasi latensi jaringan", "AutoParry.PingFactor", 0, 1.5, 2)

    local curve = window.AddTab("Curve", 2)
    C.Section(curve, "Kontrol arah")
    toggle(C, curve, "Aktifkan Curve", "Hitung dan kirim arah melalui adapter remote", "Curve.Enabled")
    dropdown(C, curve, "Mode", "Auto saat bola mendekat; Manual dengan tombol C", "Curve.Mode", { "Auto", "Manual" })
    dropdown(C, curve, "Target", "Pilih pemain berdasarkan jarak dari bola", "Curve.Target", { "Closest", "Furthest" })
    dropdown(C, curve, "Arah manual", "Dipakai saat mode Manual", "Curve.ManualDirection", { "Atas", "Bawah", "Kiri", "Kanan" })
    C.Section(curve, "Variasi pantulan acak")
    toggle(C, curve, "Atas", "Sertakan bias arah ke atas", "Curve.Directions.Atas")
    toggle(C, curve, "Bawah", "Sertakan bias arah ke bawah", "Curve.Directions.Bawah")
    toggle(C, curve, "Kiri", "Sertakan rotasi arah ke kiri", "Curve.Directions.Kiri")
    toggle(C, curve, "Kanan", "Sertakan rotasi arah ke kanan", "Curve.Directions.Kanan")
    C.Section(curve, "Doting")
    toggle(C, curve, "Mode Doting", "Dorongan lurus cepat tanpa variasi pantulan", "Curve.Doting")
    slider(C, curve, "Kekuatan Curve", "Magnitudo untuk mode argumen Vector", "Curve.Strength", 5, 80, 0)
    slider(C, curve, "Kekuatan Doting", "Magnitudo dorongan lurus", "Curve.DotingStrength", 10, 120, 0)
    C.Section(curve, "Adapter game")
    textbox(C, curve, "RemotePath", "Kosongkan bila remote game belum diketahui", "Curve.RemotePath", "Remotes.Curve")
    dropdown(C, curve, "Format argumen", "Sesuaikan dengan kontrak remote game", "Curve.RemoteArgumentMode", { "DirectionTarget", "Direction", "Vector" })

    local visual = window.AddTab("Visual", 3)
    C.Section(visual, "Sword swap")
    toggle(C, visual, "Aktifkan sword swap", "Terapkan aset pada Tool yang sedang digunakan", "Visual.SwordSwap")
    textbox(C, visual, "MeshID", "Dapat berupa rbxassetid:// atau URL aset", "Visual.MeshID", "rbxassetid://...")
    textbox(C, visual, "TextureID", "Tekan Enter atau klik di luar untuk menerapkan", "Visual.TextureID", "rbxassetid://...")
    C.Section(visual, "Partikel")
    toggle(C, visual, "Warna partikel kustom", "Mengganti ColorSequence ParticleEmitter", "Visual.ParticleColor")
    C.TextBox(visual, "Warna RGB", "Format: merah, hijau, biru (0–255)", "96, 165, 250", "96, 165, 250", function(value)
        local r, g, b = string.match(value, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r then
            Config.Set("Visual.ColorR", math.clamp(tonumber(r), 0, 255))
            Config.Set("Visual.ColorG", math.clamp(tonumber(g), 0, 255))
            Config.Set("Visual.ColorB", math.clamp(tonumber(b), 0, 255))
        end
    end)
    C.Section(visual, "Shader V-RTX")
    toggle(C, visual, "Aktifkan V-RTX", "ColorCorrection, Bloom, dan SunRays", "Visual.VRTX")
    slider(C, visual, "Contrast", "Kekuatan kontras pencahayaan", "Visual.Contrast", -0.2, 0.5, 2)
    slider(C, visual, "Saturation", "Intensitas warna tampilan", "Visual.Saturation", -0.5, 0.5, 2)
    slider(C, visual, "Bloom", "Intensitas cahaya lembut", "Visual.BloomIntensity", 0, 1.5, 2)
    slider(C, visual, "Sun rays", "Intensitas pancaran cahaya", "Visual.SunRaysIntensity", 0, 0.4, 2)

    local settings = window.AddTab("Settings", 4)
    C.Section(settings, "Antarmuka")
    C.TextBox(settings, "Tombol sembunyikan UI", "Default: RightShift; gunakan nama Enum.KeyCode", Config.Get("UI.ToggleKey"), "RightShift", function(value)
        if Enum.KeyCode[value] then Config.Set("UI.ToggleKey", value) end
    end)
    C.Section(settings, "Lifecycle")
    C.Button(settings, "Unload Agoys Script", "Hentikan loop, putuskan koneksi, dan pulihkan visual", "Unload", function()
        if modules.Main then modules.Main.Stop() end
    end, true)

    return window
end

function Dashboard.Destroy()
    if currentWindow then currentWindow.Destroy(); currentWindow = nil end
end

return Dashboard