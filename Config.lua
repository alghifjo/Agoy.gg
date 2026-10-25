--[[
    Agoys Script — Blade Ball (Solara)
    Config.lua — sumber pengaturan pusat.

    Dashboard merender Catalog (tab, kartu, kontrol).
    Modul fitur hanya membaca nilai runtime lewat Get / Watch.
    Jangan hardcode opsi di UI; ubah tabel di sini.
]]

local Config = {}

----------------------------------------------------------------------
-- Identitas
----------------------------------------------------------------------
Config.Meta = {
    Product = "Agoys Script",
    Brand = "Agoy.gg",
    Version = "1.0.0",
    Game = "Blade Ball",
    Executor = "Solara",
}

----------------------------------------------------------------------
-- Nilai tetap (dipakai Catalog & validasi)
----------------------------------------------------------------------
Config.Enums = {
    CurveMode = { "Auto", "Manual" },
    CurveTarget = { "Closest", "Furthest" },
    CurveDirection = { "Up", "Down", "Left", "Right" },
}

Config.Labels = {
    Direction = {
        Up = "Atas",
        Down = "Bawah",
        Left = "Kiri",
        Right = "Kanan",
    },
}

----------------------------------------------------------------------
-- Dashboard
-- Palet netral, satu aksen, spasi longgar — nyaman untuk sesi panjang.
----------------------------------------------------------------------
Config.UI = {
    Window = {
        Title = "Agoys Script",
        Width = 880,
        Height = 560,
        SidebarWidth = 220,
        HeaderHeight = 58,
        ContentPadding = 28,
        SectionGap = 14,
        CardRadius = 10,
        WindowRadius = 12,
        StrokeThickness = 1,
        InnerGap = 18,
        NavItemHeight = 52,
        CloseSize = 28,
    },

    Theme = {
        Background = Color3.fromRGB(14, 15, 17),
        Sidebar = Color3.fromRGB(17, 18, 21),
        Surface = Color3.fromRGB(24, 26, 30),
        SurfaceHover = Color3.fromRGB(30, 33, 38),
        Elevated = Color3.fromRGB(34, 37, 43),
        Border = Color3.fromRGB(48, 52, 60),
        Divider = Color3.fromRGB(40, 43, 50),
        Text = Color3.fromRGB(236, 237, 240),
        TextSecondary = Color3.fromRGB(164, 170, 180),
        TextMuted = Color3.fromRGB(112, 118, 128),
        Accent = Color3.fromRGB(122, 154, 224),
        AccentSoft = Color3.fromRGB(28, 34, 48),
        Success = Color3.fromRGB(126, 176, 148),
        Warning = Color3.fromRGB(206, 168, 104),
        Danger = Color3.fromRGB(196, 112, 112),
        ToggleOff = Color3.fromRGB(56, 60, 70),
        Overlay = Color3.fromRGB(0, 0, 0),
        Font = Enum.Font.Gotham,
        FontMedium = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
    },

    Motion = {
        Hover = 0.12,
        Toggle = 0.16,
        TabSwitch = 0.18,
    },

    Tabs = {
        { Id = "combat", Title = "Combat", Caption = "Parry & timing" },
        { Id = "curve", Title = "Curve", Caption = "Arah & doting" },
        { Id = "visuals", Title = "Visuals", Caption = "Pedang & shader" },
        { Id = "settings", Title = "Settings", Caption = "Antarmuka" },
    },
}

----------------------------------------------------------------------
-- Gameplay — Auto Parry
-- Lead time prediksi adaptif: mengikuti kecepatan bola.
-- Tidak ada slider ping / FOV / delay manual.
----------------------------------------------------------------------
Config.Gameplay = {
    AutoParry = {
        Enabled = true,
        AdaptivePrediction = true,
        ReferenceSpeed = 80,
        BaseLead = 0.185,
        MinLead = 0.055,
        MaxLead = 0.320,
        SpeedExponent = 0.72,
        DistancePadding = 1.15,
        SampleRate = 1 / 60,
    },
}

----------------------------------------------------------------------
-- Curve
-- Mode: "Auto" | "Manual"
-- Auto: target Closest / Furthest, lalu gabung + acak arah aktif.
-- Doting: sakelar terpisah — dorongan lurus cepat, mengabaikan curve.
----------------------------------------------------------------------
Config.Curve = {
    Mode = "Auto",

    Auto = {
        Enabled = true,
        Target = "Closest",
        RandomizeDirections = true,
        Directions = {
            Up = true,
            Down = true,
            Left = true,
            Right = true,
        },
        RetargetInterval = 0.12,
    },

    Manual = {
        Direction = "Up",
    },

    Doting = {
        Enabled = false,
        ImpulseScale = 1.35,
        Straighten = true,
    },
}

----------------------------------------------------------------------
-- Visual
-- Sword swap: MeshId, TextureId, ParticleColor (Color3).
-- Shader V-RTX: ColorCorrection, Bloom, SunRays.
----------------------------------------------------------------------
Config.Visuals = {
    SwordSwap = {
        Enabled = false,
        MeshId = "rbxassetid://0",
        TextureId = "rbxassetid://0",
        ParticleColor = Color3.fromRGB(122, 154, 224),
        ParticleRate = 12,
    },

    ShaderVRTX = {
        Enabled = false,
        ColorCorrection = {
            Brightness = 0.04,
            Contrast = 0.12,
            Saturation = 0.08,
            TintColor = Color3.fromRGB(232, 236, 245),
        },
        Bloom = {
            Intensity = 0.35,
            Size = 18,
            Threshold = 0.92,
        },
        SunRays = {
            Intensity = 0.08,
            Spread = 0.42,
        },
    },
}

----------------------------------------------------------------------
-- Sesi UI
----------------------------------------------------------------------
Config.Settings = {
    OpenOnInject = true,
    ToggleKey = Enum.KeyCode.RightShift,
    RememberTab = true,
    DefaultTab = "combat",
    ReduceMotion = false,
}

----------------------------------------------------------------------
-- Catalog — kontrak dashboard (bukan hardcode per-fitur)
----------------------------------------------------------------------
Config.Catalog = {
    combat = {
        Title = "Combat",
        Description = "Parry mengikuti kecepatan bola. Lead time dihitung sendiri; tidak perlu di-adjust.",
        Sections = {
            {
                Title = "Auto Parry",
                Description = "Prediksi adaptif mengetatkan timing saat bola mempercepat, dan memberi ruang saat bola melambat.",
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Gameplay.AutoParry.Enabled",
                        Label = "Aktifkan Auto Parry",
                        Hint = "Menempel ke bola dan memicu parry saat jendela prediksi terbuka.",
                    },
                    {
                        Kind = "Note",
                        Text = "Adaptive prediction selalu menyala. Tidak ada slider ping, FOV, atau delay manual — kecepatan bola menjadi satu-satunya acuan.",
                    },
                },
            },
        },
    },

    curve = {
        Title = "Curve",
        Description = "Satu sistem untuk mode, target, arah pantulan, dan doting.",
        Sections = {
            {
                Title = "Mode",
                Description = "Auto mengurus target dan arah. Manual mengunci satu arah.",
                Controls = {
                    {
                        Kind = "Segment",
                        Path = "Curve.Mode",
                        Label = "Mode curve",
                        Options = Config.Enums.CurveMode,
                    },
                },
            },
            {
                Title = "Auto Curve",
                Description = "Target musuh lalu menggabungkan dan mengacak arah pantulan yang aktif (Atas, Bawah, Kiri, Kanan).",
                VisibleWhen = { Path = "Curve.Mode", Equals = "Auto" },
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Curve.Auto.Enabled",
                        Label = "Aktifkan Auto Curve",
                        Hint = "Berjalan hanya saat mode Auto dipilih.",
                    },
                    {
                        Kind = "Segment",
                        Path = "Curve.Auto.Target",
                        Label = "Target",
                        Options = Config.Enums.CurveTarget,
                    },
                    {
                        Kind = "Chips",
                        Path = "Curve.Auto.Directions",
                        Label = "Arah pantulan",
                        Hint = "Arah yang aktif digabung lalu diacak menjadi satu vektor curve.",
                        Keys = Config.Enums.CurveDirection,
                        Captions = Config.Labels.Direction,
                    },
                },
            },
            {
                Title = "Manual Curve",
                Description = "Satu arah tetap, tanpa randomisasi.",
                VisibleWhen = { Path = "Curve.Mode", Equals = "Manual" },
                Controls = {
                    {
                        Kind = "Segment",
                        Path = "Curve.Manual.Direction",
                        Label = "Arah",
                        Options = Config.Enums.CurveDirection,
                        Captions = Config.Labels.Direction,
                    },
                },
            },
            {
                Title = "Doting",
                Description = "Dorongan lurus cepat. Sakelar terpisah; saat aktif, curve diabaikan.",
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Curve.Doting.Enabled",
                        Label = "Mode Doting",
                        Hint = "Impulse lurus ke depan, tanpa lengkungan.",
                    },
                },
            },
        },
    },

    visuals = {
        Title = "Visuals",
        Description = "Tampilan pedang dan lighting. Tidak memengaruhi timing parry.",
        Sections = {
            {
                Title = "Sword Swap",
                Description = "Ganti mesh dan tekstur pedang, plus warna partikel kustom.",
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Visuals.SwordSwap.Enabled",
                        Label = "Aktifkan swap pedang",
                    },
                    {
                        Kind = "Text",
                        Path = "Visuals.SwordSwap.MeshId",
                        Label = "MeshID",
                        Placeholder = "rbxassetid://…",
                    },
                    {
                        Kind = "Text",
                        Path = "Visuals.SwordSwap.TextureId",
                        Label = "TextureID",
                        Placeholder = "rbxassetid://…",
                    },
                    {
                        Kind = "Color",
                        Path = "Visuals.SwordSwap.ParticleColor",
                        Label = "Warna partikel",
                    },
                },
            },
            {
                Title = "Shader V-RTX",
                Description = "ColorCorrection, Bloom, dan SunRays dengan parameter yang tenang.",
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Visuals.ShaderVRTX.Enabled",
                        Label = "Aktifkan V-RTX",
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.ColorCorrection.Brightness",
                        Label = "Brightness",
                        Min = -0.25,
                        Max = 0.35,
                        Step = 0.01,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.ColorCorrection.Contrast",
                        Label = "Contrast",
                        Min = 0,
                        Max = 0.4,
                        Step = 0.01,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.ColorCorrection.Saturation",
                        Label = "Saturation",
                        Min = -0.2,
                        Max = 0.4,
                        Step = 0.01,
                    },
                    {
                        Kind = "Color",
                        Path = "Visuals.ShaderVRTX.ColorCorrection.TintColor",
                        Label = "Tint",
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.Bloom.Intensity",
                        Label = "Bloom intensity",
                        Min = 0,
                        Max = 1,
                        Step = 0.01,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.Bloom.Size",
                        Label = "Bloom size",
                        Min = 4,
                        Max = 40,
                        Step = 1,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.Bloom.Threshold",
                        Label = "Bloom threshold",
                        Min = 0.4,
                        Max = 1.2,
                        Step = 0.01,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.SunRays.Intensity",
                        Label = "SunRays intensity",
                        Min = 0,
                        Max = 0.35,
                        Step = 0.01,
                    },
                    {
                        Kind = "Slider",
                        Path = "Visuals.ShaderVRTX.SunRays.Spread",
                        Label = "SunRays spread",
                        Min = 0.1,
                        Max = 1,
                        Step = 0.01,
                    },
                },
            },
        },
    },

    settings = {
        Title = "Settings",
        Description = "Perilaku jendela. Tidak ada opsi yang mengubah rumus parry.",
        Sections = {
            {
                Title = "Antarmuka",
                Controls = {
                    {
                        Kind = "Toggle",
                        Path = "Settings.OpenOnInject",
                        Label = "Buka saat inject",
                    },
                    {
                        Kind = "Toggle",
                        Path = "Settings.RememberTab",
                        Label = "Ingat tab terakhir",
                    },
                    {
                        Kind = "Toggle",
                        Path = "Settings.ReduceMotion",
                        Label = "Kurangi animasi",
                    },
                    {
                        Kind = "Note",
                        Text = "Right Shift menampilkan atau menyembunyikan dashboard.",
                    },
                },
            },
        },
    },
}

----------------------------------------------------------------------
-- Binding runtime
----------------------------------------------------------------------
local watchers = {}

local function splitPath(path)
    local parts = {}
    for part in string.gmatch(path, "[^%.]+") do
        parts[#parts + 1] = part
    end
    return parts
end

local function fire(path, value)
    local list = watchers[path]
    if list then
        for i = 1, #list do
            list[i](value, path)
        end
    end
    local all = watchers["*"]
    if all then
        for i = 1, #all do
            all[i](value, path)
        end
    end
end

function Config.Get(path)
    local node = Config
    for _, part in ipairs(splitPath(path)) do
        if type(node) ~= "table" then
            return nil
        end
        node = node[part]
    end
    return node
end

function Config.Set(path, value)
    local parts = splitPath(path)
    local node = Config
    for i = 1, #parts - 1 do
        node = node[parts[i]]
        if type(node) ~= "table" then
            return false
        end
    end
    local key = parts[#parts]
    if node[key] == value then
        return true
    end
    node[key] = value
    fire(path, value)
    return true
end

function Config.Watch(path, fn)
    watchers[path] = watchers[path] or {}
    watchers[path][#watchers[path] + 1] = fn
    return function()
        local list = watchers[path]
        if not list then
            return
        end
        for i = #list, 1, -1 do
            if list[i] == fn then
                table.remove(list, i)
            end
        end
    end
end

function Config.ActiveDirections()
    local keys = {}
    local dirs = Config.Curve.Auto.Directions
    for _, name in ipairs(Config.Enums.CurveDirection) do
        if dirs[name] then
            keys[#keys + 1] = name
        end
    end
    return keys
end

function Config.IsAutoCurve()
    return Config.Curve.Mode == "Auto" and Config.Curve.Auto.Enabled and not Config.Curve.Doting.Enabled
end

if getgenv then
    getgenv().AgoysConfig = Config
end

return Config
