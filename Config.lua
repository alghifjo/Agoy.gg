--[[
    Agoy.gg / Agoys Script
    Blade Ball · Solara

    Config.lua — pusat seluruh pengaturan.
    Modul lain (nanti) cukup membaca tabel ini.
]]

local Config = {}

Config.Meta = {
    Product = "Agoys Script",
    Brand = "Agoy.gg",
    Version = "1.0.0",
    Game = "Blade Ball",
    Executor = "Solara",
}

----------------------------------------------------------------------
-- Dashboard (nilai siap pakai saat UI dibuat)
-- Palet netral, satu aksen, spasi nyaman untuk sesi panjang.
----------------------------------------------------------------------
Config.UI = {
    Window = {
        Title = "Agoys Script",
        Width = 860,
        Height = 540,
        SidebarWidth = 216,
        HeaderHeight = 56,
        ContentPadding = 24,
        SectionGap = 16,
        CardRadius = 10,
        WindowRadius = 12,
        StrokeThickness = 1,
    },

    Theme = {
        Background = Color3.fromRGB(13, 15, 18),
        Sidebar = Color3.fromRGB(16, 18, 22),
        Surface = Color3.fromRGB(22, 25, 31),
        SurfaceHover = Color3.fromRGB(28, 32, 40),
        Elevated = Color3.fromRGB(32, 36, 45),
        Border = Color3.fromRGB(44, 49, 58),
        Divider = Color3.fromRGB(38, 42, 50),
        Text = Color3.fromRGB(236, 238, 242),
        TextSecondary = Color3.fromRGB(168, 174, 186),
        TextMuted = Color3.fromRGB(118, 126, 138),
        Accent = Color3.fromRGB(114, 148, 232),
        Success = Color3.fromRGB(118, 176, 142),
        Warning = Color3.fromRGB(210, 168, 96),
        Danger = Color3.fromRGB(208, 108, 108),
        ToggleOff = Color3.fromRGB(58, 64, 74),
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
-- Auto Parry
-- Prediksi adaptif: lead time menyesuaikan kecepatan bola sendiri.
-- Tidak ada slider ping / delay manual.
----------------------------------------------------------------------
Config.Gameplay = {
    AutoParry = {
        Enabled = true,
        AdaptivePrediction = true,

        -- Lead (detik) pada ReferenceSpeed.
        -- Semakin cepat bola, lead semakin ketat (SpeedExponent < 1).
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
-- Auto: target Closest/Furthest + acak arah aktif (Up/Down/Left/Right).
-- Doting: sakelar terpisah; lurus cepat, mengabaikan curve.
----------------------------------------------------------------------
Config.Curve = {
    Mode = "Auto", -- "Auto" | "Manual"

    Auto = {
        Enabled = true,
        Target = "Closest", -- "Closest" | "Furthest"
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
        Direction = "Up", -- "Up" | "Down" | "Left" | "Right"
    },

    Doting = {
        Enabled = false,
        ImpulseScale = 1.35,
        Straighten = true,
    },
}

----------------------------------------------------------------------
-- Visual
----------------------------------------------------------------------
Config.Visuals = {
    SwordSwap = {
        Enabled = false,
        MeshId = "rbxassetid://0",
        TextureId = "rbxassetid://0",
        ParticleColor = Color3.fromRGB(114, 148, 232),
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

if getgenv then
    getgenv().AgoysConfig = Config
end

return Config
