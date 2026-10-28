-- Aegis Blade Ball | Composition root

local Main = {}

function Main.Start(requireAsset)
	local Config = requireAsset("Config")
	local Theme = requireAsset("Theme")
	local Components = requireAsset("Components")
	local BallTracker = requireAsset("BallTracker")
	local AutoParry = requireAsset("AutoParry")
	local Dashboard = requireAsset("Dashboard")

	local tracker = BallTracker.new(Config)
	local engine = AutoParry.new(Config, tracker)
	local components = Components.new(Theme)
	local dashboard = Dashboard.new(Config, Theme, components, engine)
	local stopped = false

	local runtime = {}
	function runtime.Stop()
		if stopped then
			return
		end
		stopped = true
		pcall(function()
			dashboard:Destroy()
		end)
		pcall(function()
			engine:Destroy()
		end)
		if getgenv().AegisRuntime == runtime then
			getgenv().AegisRuntime = nil
		end
	end

	getgenv().AegisRuntime = runtime
	engine:Start()
	dashboard:Start()
	return runtime
end

return Main