-- Aegis Blade Ball | Responsive dashboard and live telemetry

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Dashboard = {}
Dashboard.__index = Dashboard

local STATE_COLORS = {
	ARMED = "Success",
	INCOMING = "Cyan",
	REENTRY = "Warning",
	PULL_REENTRY = "Warning",
	PULL_COUNTER = "Warning",
	HELD = "Warning",
	FURY_RELEASE = "Danger",
	FURY_COUNTER = "Danger",
	VELOCITY_SPIKE = "Danger",
	ERROR = "Danger",
	INPUT_ERROR = "Danger",
	DISABLED = "TextFaint",
}

function Dashboard.new(config, theme, components, engine)
	local self = setmetatable({}, Dashboard)
	self.Config = config
	self.Theme = theme
	self.UI = components
	self.Engine = engine
	self.Connections = {}
	self.Tabs = {}
	self.Pages = {}
	self.Labels = {}
	self.Toggles = {}
	self.Sliders = {}
	self.CurrentTab = nil
	self.Alive = true
	self.Visible = true
	return self
end

function Dashboard:GetParent()
	if type(gethui) == "function" then
		local ok, parent = pcall(gethui)
		if ok and parent then
			return parent
		end
	end
	local ok = pcall(function()
		return CoreGui.Name
	end)
	if ok then
		return CoreGui
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Dashboard:BuildShell()
	local theme = self.Theme
	local ui = self.UI
	local screen = ui:Create("ScreenGui", {
		Name = "AegisDashboard",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, self:GetParent())
	self.Screen = screen

	local main = ui:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self.Config.Dashboard.Width, self.Config.Dashboard.Height),
		BackgroundColor3 = theme.Window,
		BorderSizePixel = 0,
		Active = true,
	}, screen)
	self.Main = main
	ui:Corner(main, theme.Radius.Large)
	ui:Stroke(main, theme.Border, 0.12, 1)

	local scale = ui:Create("UIScale", { Scale = 1 }, main)
	self.Scale = scale

	local accent = ui:Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	}, main)
	ui:Corner(accent, UDim.new(1, 0))

	local sidebar = ui:Create("Frame", {
		Size = UDim2.new(0, 172, 1, 0),
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
	}, main)
	ui:Corner(sidebar, theme.Radius.Large)
	local sidebarMask = ui:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 18, 1, 0),
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
	}, sidebar)

	ui:Text(sidebar, self.Config.Product.Name, 23, theme.Text, theme.Font.Bold, {
		Position = UDim2.fromOffset(18, 20),
		Size = UDim2.fromOffset(130, 28),
	})
	ui:Text(sidebar, "PARRY INTELLIGENCE", 9, theme.Accent, theme.Font.Bold, {
		Position = UDim2.fromOffset(19, 49),
		Size = UDim2.fromOffset(136, 16),
	})

	local statusCard = ui:Create("Frame", {
		Position = UDim2.fromOffset(14, 78),
		Size = UDim2.fromOffset(144, 30),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
	}, sidebar)
	ui:Corner(statusCard, theme.Radius.Small)
	self.Labels.SideDot = ui:Create("Frame", {
		Position = UDim2.fromOffset(10, 11),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = theme.Success,
		BorderSizePixel = 0,
	}, statusCard)
	ui:Corner(self.Labels.SideDot, UDim.new(1, 0))
	self.Labels.SideStatus = ui:Text(statusCard, "SYSTEM ARMED", 10, theme.TextMuted, theme.Font.Medium, {
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -32, 1, 0),
	})

	local tabContainer = ui:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 122),
		Size = UDim2.fromOffset(144, 196),
	}, sidebar)
	ui:Create("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabContainer)

	local tabs = {
		{ Name = "Overview", Title = "Overview", Subtitle = "Live defense telemetry", Order = 1 },
		{ Name = "Defense", Title = "Defense matrix", Subtitle = "Adaptive response modules", Order = 2 },
		{ Name = "Tuning", Title = "Precision tuning", Subtitle = "Calibrate the prediction envelope", Order = 3 },
		{ Name = "Diagnostics", Title = "Diagnostics", Subtitle = "Trajectory and runtime insight", Order = 4 },
	}
	for _, tab in ipairs(tabs) do
		local button = ui:Create("TextButton", {
			Size = UDim2.fromOffset(144, 40),
			LayoutOrder = tab.Order,
			BackgroundColor3 = theme.Sidebar,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = tab.Title,
			TextSize = 13,
			Font = theme.Font.Medium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.TextMuted,
		}, tabContainer)
		ui:Corner(button, theme.Radius.Small)
		ui:Padding(button, 12, 0, 0, 0)
		button.Activated:Connect(function()
			self:SelectTab(tab.Name)
		end)
		button.MouseEnter:Connect(function()
			if self.CurrentTab ~= tab.Name then
				TweenService:Create(button, theme.Tween.Fast, { BackgroundColor3 = theme.Surface }):Play()
			end
		end)
		button.MouseLeave:Connect(function()
			if self.CurrentTab ~= tab.Name then
				TweenService:Create(button, theme.Tween.Fast, { BackgroundColor3 = theme.Sidebar }):Play()
			end
		end)
		self.Tabs[tab.Name] = button
	end

	ui:Text(sidebar, "RIGHT SHIFT", 10, theme.TextFaint, theme.Font.Mono, {
		Position = UDim2.new(0, 18, 1, -52),
		Size = UDim2.fromOffset(130, 16),
	})
	ui:Text(sidebar, "Toggle dashboard", 11, theme.TextMuted, theme.Font.Regular, {
		Position = UDim2.new(0, 18, 1, -34),
		Size = UDim2.fromOffset(136, 18),
	})
	ui:Text(sidebar, "v" .. self.Config.Product.Version, 10, theme.TextFaint, theme.Font.Mono, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.fromOffset(50, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local content = ui:Create("Frame", {
		Position = UDim2.fromOffset(172, 0),
		Size = UDim2.new(1, -172, 1, 0),
		BackgroundTransparency = 1,
	}, main)
	self.Labels.Header = ui:Text(content, "Overview", 20, theme.Text, theme.Font.Bold, {
		Position = UDim2.fromOffset(22, 14),
		Size = UDim2.fromOffset(360, 26),
	})
	self.Labels.Subtitle = ui:Text(content, "Live defense telemetry", 11, theme.TextMuted, theme.Font.Regular, {
		Position = UDim2.fromOffset(23, 40),
		Size = UDim2.fromOffset(380, 18),
	})
	ui:Button(content, "×", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(30, 30),
		TextSize = 19,
	}, function()
		self:SetVisible(false)
	end)

	self.PageContainer = ui:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 1, -70),
	}, content)

	for _, tab in ipairs(tabs) do
		local page = ui:Create("Frame", {
			Name = tab.Name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
		}, self.PageContainer)
		self.Pages[tab.Name] = page
		self.TabMetadata = self.TabMetadata or {}
		self.TabMetadata[tab.Name] = tab
	end

	self:BuildOverview()
	self:BuildDefense()
	self:BuildTuning()
	self:BuildDiagnostics()
	self:SelectTab("Overview")
	self:SetupDrag(content)
	self:SetupResponsive()
end

function Dashboard:StatCard(parent, x, title, accentColor)
	local theme = self.Theme
	local card = self.UI:Card(parent, {
		Position = UDim2.fromOffset(x, 122),
		Size = UDim2.fromOffset(160, 88),
	})
	self.UI:Text(card, string.upper(title), 10, theme.TextMuted, theme.Font.Medium, {
		Position = UDim2.fromOffset(13, 10),
		Size = UDim2.new(1, -26, 0, 16),
	})
	local value = self.UI:Text(card, "—", 23, accentColor or theme.Text, theme.Font.Bold, {
		Position = UDim2.fromOffset(13, 31),
		Size = UDim2.new(1, -26, 0, 30),
	})
	local unit = self.UI:Text(card, "", 10, theme.TextFaint, theme.Font.Mono, {
		Position = UDim2.fromOffset(13, 64),
		Size = UDim2.new(1, -26, 0, 14),
	})
	return value, unit
end

function Dashboard:BuildOverview()
	local page = self.Pages.Overview
	local theme = self.Theme
	local ui = self.UI
	local hero = ui:Card(page, {
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.fromOffset(504, 108),
	})
	local glow = ui:Create("Frame", {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	}, hero)
	ui:Corner(glow, UDim.new(1, 0))
	self.Labels.HeroGlow = glow
	ui:Text(hero, "ADAPTIVE DEFENSE", 10, theme.TextMuted, theme.Font.Bold, {
		Position = UDim2.fromOffset(18, 14),
		Size = UDim2.fromOffset(240, 16),
	})
	self.Labels.HeroState = ui:Text(hero, "ARMED", 27, theme.Success, theme.Font.Bold, {
		Position = UDim2.fromOffset(18, 34),
		Size = UDim2.fromOffset(300, 36),
	})
	self.Labels.HeroDetail = ui:Text(hero, "Monitoring trajectory", 11, theme.TextMuted, theme.Font.Regular, {
		Position = UDim2.fromOffset(19, 76),
		Size = UDim2.fromOffset(330, 18),
	})
	local badge = ui:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(120, 28),
		BackgroundColor3 = theme.AccentSoft,
		BorderSizePixel = 0,
	}, hero)
	ui:Corner(badge, UDim.new(1, 0))
	self.Labels.Badge = ui:Text(badge, "PREDICTIVE", 10, theme.Accent, theme.Font.Bold, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local metrics = ui:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.fromOffset(504, 220),
	}, page)
	self.Labels.Speed, self.Labels.SpeedUnit = self:StatCard(metrics, 0, "Ball velocity", theme.Cyan)
	self.Labels.Distance, self.Labels.DistanceUnit = self:StatCard(metrics, 172, "Surface range", theme.Text)
	self.Labels.TTI, self.Labels.TTIUnit = self:StatCard(metrics, 344, "Time to impact", theme.Accent)
	self.Labels.SpeedUnit.Text = "STUD / SECOND"
	self.Labels.DistanceUnit.Text = "STUD"
	self.Labels.TTIUnit.Text = "MILLISECOND"

	local event = ui:Card(page, {
		Position = UDim2.fromOffset(22, 224),
		Size = UDim2.fromOffset(504, 116),
	})
	ui:Text(event, "LAST EVENT", 10, theme.TextMuted, theme.Font.Medium, {
		Position = UDim2.fromOffset(15, 12),
		Size = UDim2.fromOffset(240, 16),
	})
	self.Labels.Event = ui:Text(event, "Engine ready", 14, theme.Text, theme.Font.Medium, {
		Position = UDim2.fromOffset(15, 34),
		Size = UDim2.new(1, -30, 0, 24),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	self.Labels.Counters = ui:Text(event, "0 parries  ·  0 Pull counters  ·  0 Fury counters", 11, theme.TextMuted, theme.Font.Mono, {
		Position = UDim2.fromOffset(15, 72),
		Size = UDim2.new(1, -30, 0, 22),
	})
end

function Dashboard:BuildDefense()
	local page = self.Pages.Defense
	local holder = self.UI:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 4),
		Size = UDim2.fromOffset(504, 336),
	}, page)
	self.UI:Create("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)

	self.Toggles.Auto = self.UI:Toggle(holder, "Immortality engine", "High-frequency adaptive auto parry", self.Config.Parry.Enabled, function(value)
		self.Engine:SetEnabled(value)
	end)
	self.Toggles.Predictive = self.UI:Toggle(holder, "Continuous prediction", "Quadratic time-to-impact and speed envelope", self.Config.Parry.Predictive, function(value)
		self.Config.Parry.Predictive = value
	end)
	self.Toggles.Pull = self.UI:Toggle(holder, "Pull re-entry counter", "Rearm after target or trajectory reacquisition", self.Config.Pull.Enabled, function(value)
		self.Config.Pull.Enabled = value
	end)
	self.Toggles.Fury = self.UI:Toggle(holder, "Slashes of Fury release", "Hold-state rejection and velocity-spike detection", self.Config.Fury.Enabled, function(value)
		self.Config.Fury.Enabled = value
	end)
	self.Toggles.Ping = self.UI:Toggle(holder, "Latency compensation", "Bounded ping and frame-time trigger window", self.Config.Parry.CompensatePing, function(value)
		self.Config.Parry.CompensatePing = value
	end)
end

function Dashboard:BuildTuning()
	local page = self.Pages.Tuning
	local holder = self.UI:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 2),
		Size = UDim2.fromOffset(504, 340),
	}, page)
	self.UI:Create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)

	table.insert(self.Sliders, self.UI:Slider(holder, "Tight hitbox radius", 6, 18, 0.5, self.Config.Parry.HitboxRadius, function(value)
		self.Config.Parry.HitboxRadius = value
	end))
	table.insert(self.Sliders, self.UI:Slider(holder, "Maximum prediction reach", 0, 12, 0.5, self.Config.Parry.MaxPredictionReach, function(value)
		self.Config.Parry.MaxPredictionReach = value
	end))
	table.insert(self.Sliders, self.UI:Slider(holder, "Base trigger window (ms)", 10, 105, 5, self.Config.Parry.BaseTriggerWindow * 1000, function(value)
		self.Config.Parry.BaseTriggerWindow = value / 1000
	end))
	table.insert(self.Sliders, self.UI:Slider(holder, "Pull re-entry window", 0.2, 2, 0.05, self.Config.Pull.ReentryWindow, function(value)
		self.Config.Pull.ReentryWindow = value
	end))
end

function Dashboard:DiagnosticRow(parent, order, title)
	local theme = self.Theme
	local row = self.UI:Create("Frame", {
		BackgroundColor3 = order % 2 == 1 and theme.Surface or theme.Window,
		BackgroundTransparency = order % 2 == 1 and 0.35 or 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = order,
	}, parent)
	self.UI:Corner(row, self.Theme.Radius.Small)
	self.UI:Text(row, title, 12, theme.TextMuted, theme.Font.Regular, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.58, -12, 1, 0),
	})
	return self.UI:Text(row, "—", 12, theme.Text, theme.Font.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.42, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

function Dashboard:BuildDiagnostics()
	local page = self.Pages.Diagnostics
	local holder = self.UI:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 4),
		Size = UDim2.fromOffset(504, 330),
	}, page)
	self.UI:Create("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	self.Labels.Approach = self:DiagnosticRow(holder, 1, "Approach segment")
	self.Labels.Closing = self:DiagnosticRow(holder, 2, "Closing speed")
	self.Labels.Direction = self:DiagnosticRow(holder, 3, "Direction change")
	self.Labels.Ping = self:DiagnosticRow(holder, 4, "Data ping")
	self.Labels.Input = self:DiagnosticRow(holder, 5, "Input adapter")
	self.Labels.Radius = self:DiagnosticRow(holder, 6, "Prediction envelope")
	self.Labels.Input.Text = self.Engine.InputMode
end

function Dashboard:SelectTab(name)
	local theme = self.Theme
	self.CurrentTab = name
	for tabName, button in pairs(self.Tabs) do
		local selected = tabName == name
		TweenService:Create(button, theme.Tween.Fast, {
			BackgroundColor3 = selected and theme.AccentSoft or theme.Sidebar,
			TextColor3 = selected and theme.Text or theme.TextMuted,
		}):Play()
	end
	for pageName, page in pairs(self.Pages) do
		page.Visible = pageName == name
		if page.Visible then
			page.Position = UDim2.fromOffset(0, 5)
			TweenService:Create(page, theme.Tween.Normal, { Position = UDim2.fromOffset(0, 0) }):Play()
		end
	end
	local metadata = self.TabMetadata[name]
	self.Labels.Header.Text = metadata.Title
	self.Labels.Subtitle.Text = metadata.Subtitle
end

function Dashboard:SetupResponsive()
	local camera = workspace.CurrentCamera
	local function update()
		camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		local scale = math.min(viewport.X / 900, viewport.Y / 650)
		self.Scale.Scale = math.clamp(scale, self.Config.Dashboard.MinScale, self.Config.Dashboard.MaxScale)
	end
	update()
	if camera then
		table.insert(self.Connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
	end
	table.insert(self.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(update))
end

function Dashboard:SetupDrag(handle)
	local dragging = false
	local dragStart = nil
	local startPosition = nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPosition = self.Main.Position
		end
	end)
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPosition then
			local delta = (input.Position - dragStart) / self.Scale.Scale
			self.Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end))
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))
end

function Dashboard:Refresh()
	if not self.Alive then
		return
	end
	local view, metrics = self.Engine:GetView()
	local theme = self.Theme
	local state = view.State or "IDLE"
	local colorName = STATE_COLORS[state] or "Text"
	local color = theme[colorName] or theme.Text
	self.Labels.HeroState.Text = string.gsub(state, "_", " ")
	self.Labels.HeroState.TextColor3 = color
	self.Labels.HeroGlow.BackgroundColor3 = color
	self.Labels.SideDot.BackgroundColor3 = color
	self.Labels.SideStatus.Text = self.Config.Parry.Enabled and "SYSTEM ARMED" or "SYSTEM IDLE"
	self.Labels.SideStatus.TextColor3 = color
	self.Labels.HeroDetail.Text = view.ApproachReason ~= "NONE" and ("Segment · " .. view.ApproachReason) or "Monitoring trajectory"
	self.Labels.Badge.Text = self.Config.Parry.Predictive and "PREDICTIVE" or "PROXIMITY"
	self.Labels.Speed.Text = string.format("%.0f", view.Speed or 0)
	self.Labels.Distance.Text = string.format("%.1f", view.Distance or 0)
	local tti = view.TimeToImpact or math.huge
	self.Labels.TTI.Text = tti == math.huge and "∞" or string.format("%.0f", math.max(0, tti * 1000))
	self.Labels.Event.Text = view.LastEvent or "—"
	self.Labels.Counters.Text = string.format("%d parries  ·  %d Pull counters  ·  %d Fury counters", metrics.Parries, metrics.PullCounters, metrics.FuryCounters)
	self.Labels.Approach.Text = view.ApproachReason or "NONE"
	self.Labels.Closing.Text = string.format("%.1f stud/s", view.ClosingSpeed or 0)
	self.Labels.Direction.Text = string.format("%.1f°", view.DirectionChange or 0)
	self.Labels.Ping.Text = string.format("%.0f ms", (view.Ping or 0) * 1000)
	self.Labels.Input.Text = self.Engine.InputMode
	self.Labels.Radius.Text = string.format("%.1f + dynamic stud", self.Config.Parry.HitboxRadius)

	if self.LastEnabled ~= self.Config.Parry.Enabled then
		self.LastEnabled = self.Config.Parry.Enabled
		self.Toggles.Auto:Set(self.LastEnabled, true)
	end
end

function Dashboard:SetVisible(visible)
	self.Visible = visible == true
	self.Main.Visible = self.Visible
	if self.Visible then
		self.Main.Position = UDim2.fromScale(0.5, 0.5)
	end
end

function Dashboard:Start()
	self:BuildShell()
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == self.Config.Runtime.MenuKey then
			self:SetVisible(not self.Visible)
		end
	end))
	task.spawn(function()
		while self.Alive do
			local ok, err = pcall(function()
				self:Refresh()
			end)
			if not ok then
				warn("[Aegis UI] " .. tostring(err))
				task.wait(0.5)
			end
			task.wait(self.Config.Dashboard.RefreshRate)
		end
	end)
end

function Dashboard:Destroy()
	self.Alive = false
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	for _, slider in ipairs(self.Sliders) do
		slider:Destroy()
	end
	if self.Screen then
		self.Screen:Destroy()
	end
end

return Dashboard