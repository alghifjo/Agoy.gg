-- Aegis Blade Ball | Central configuration
-- Semua nilai jarak memakai stud dan waktu memakai detik.

local Config = {
	Product = {
		Name = "AEGIS",
		Subtitle = "Adaptive Parry Intelligence",
		Version = "1.0.0",
	},

	Runtime = {
		ToggleKey = Enum.KeyCode.RightControl,
		MenuKey = Enum.KeyCode.RightShift,
		MaxFrameDelta = 0.05,
		BallScanInterval = 0.35,
	},

	Ball = {
		ContainerNames = { "Balls", "Ball" },
		RealBallAttribute = "realBall",
		TargetAttributes = { "target", "Target", "TargetPlayer", "TargetName" },
		RootRadius = 2.0,
		TeleportDistance = 90,
		VelocityBlend = 0.65,
	},

	Parry = {
		Enabled = true,
		Predictive = true,
		CompensatePing = true,
		HitboxRadius = 9.5,
		EmergencyRadius = 7.0,
		MaxPredictionReach = 6.0,
		SpeedReachFactor = 0.006,
		BaseTriggerWindow = 0.025,
		MaxTriggerWindow = 0.105,
		PingScale = 0.30,
		MaxPingCompensation = 0.065,
		MinimumInputInterval = 0.035,
		InputMethod = "Auto", -- Auto | KeyF | Mouse | VirtualInput
	},

	Pull = {
		Enabled = true,
		DirectionChangeAngle = 38,
		ReentryWindow = 1.10,
		MinimumClosingSpeed = 8,
	},

	Fury = {
		Enabled = true,
		HoldSpeed = 3.0,
		HoldDelay = 0.065,
		SpikeAbsoluteSpeed = 115,
		SpikeMultiplier = 2.15,
		SpikeAcceleration = 900,
		ReleaseMinimumSpeed = 28,
	},

	Dashboard = {
		RefreshRate = 0.10,
		Width = 720,
		Height = 454,
		MinScale = 0.72,
		MaxScale = 1.0,
	},
}

function Config.GetPingSeconds()
	local ok, value = pcall(function()
		local stats = game:GetService("Stats")
		local item = stats.Network.ServerStatsItem["Data Ping"]
		return item:GetValue() / 1000
	end)

	if ok and type(value) == "number" and value >= 0 and value < 2 then
		return value
	end
	return 0
end

return Config