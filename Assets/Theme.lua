-- Aegis Blade Ball | Visual tokens

local Theme = {
	Color = {
		Window = Color3.fromRGB(12, 15, 27),
		Sidebar = Color3.fromRGB(16, 20, 35),
		Surface = Color3.fromRGB(22, 27, 45),
		SurfaceHover = Color3.fromRGB(29, 36, 58),
		SurfaceActive = Color3.fromRGB(35, 43, 68),
		Border = Color3.fromRGB(50, 59, 86),
		Text = Color3.fromRGB(239, 242, 255),
		TextMuted = Color3.fromRGB(147, 157, 184),
		TextFaint = Color3.fromRGB(98, 108, 137),
		Accent = Color3.fromRGB(139, 125, 255),
		AccentSoft = Color3.fromRGB(48, 43, 86),
		Cyan = Color3.fromRGB(88, 210, 255),
		Success = Color3.fromRGB(87, 224, 174),
		Warning = Color3.fromRGB(255, 193, 99),
		Danger = Color3.fromRGB(255, 111, 137),
		Track = Color3.fromRGB(42, 49, 72),
	},

	Font = {
		Regular = Enum.Font.Gotham,
		Medium = Enum.Font.GothamMedium,
		Bold = Enum.Font.GothamBold,
		Mono = Enum.Font.Code,
	},

	Radius = {
		Small = UDim.new(0, 7),
		Medium = UDim.new(0, 10),
		Large = UDim.new(0, 15),
	},

	Tween = {
		Fast = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Normal = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	},
}

-- Alias top-level menjaga komponen tetap ringkas: theme.Text, theme.Surface, dst.
for name, color in pairs(Theme.Color) do
	Theme[name] = color
end

return Theme