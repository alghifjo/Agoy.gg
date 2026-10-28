-- Aegis Blade Ball | High-frequency parry decision engine

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoParry = {}
AutoParry.__index = AutoParry

function AutoParry.new(config, tracker)
	local self = setmetatable({}, AutoParry)
	self.Config = config
	self.Tracker = tracker
	self.Player = Players.LocalPlayer
	self.Connections = {}
	self.Character = nil
	self.Root = nil
	self.LastInputAt = 0
	self.LastParryBall = nil
	self.LastParryApproach = -1
	self.LastErrorAt = 0
	self.InputMode = "KeyF"
	self.Metrics = {
		Parries = 0,
		PullCounters = 0,
		FuryCounters = 0,
	}
	self.View = {
		State = "STARTING",
		Speed = 0,
		Distance = 0,
		TimeToImpact = math.huge,
		ClosingSpeed = 0,
		ApproachReason = "NONE",
		DirectionChange = 0,
		Ping = 0,
		LastEvent = "Awaiting character",
	}
	return self
end

function AutoParry:ResolveInputMode()
	local configured = self.Config.Parry.InputMethod
	if configured ~= "Auto" then
		return configured
	end
	if type(keypress) == "function" and type(keyrelease) == "function" then
		return "KeyF"
	end
	if type(mouse1click) == "function" then
		return "Mouse"
	end
	return "VirtualInput"
end

function AutoParry:BindCharacter(character)
	self.Character = character
	self.Root = nil
	self.LastParryBall = nil
	self.LastParryApproach = -1
	if character then
		self.Root = character:WaitForChild("HumanoidRootPart", 5)
	end
end

function AutoParry:Start()
	self.InputMode = self:ResolveInputMode()
	self:BindCharacter(self.Player.Character)
	table.insert(self.Connections, self.Player.CharacterAdded:Connect(function(character)
		self:BindCharacter(character)
	end))
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == self.Config.Runtime.ToggleKey then
			self:SetEnabled(not self.Config.Parry.Enabled)
		end
	end))
	table.insert(self.Connections, RunService.RenderStepped:Connect(function(deltaTime)
		local ok, err = pcall(function()
			self:Step(deltaTime)
		end)
		if not ok then
			self.View.State = "ERROR"
			self.View.LastEvent = tostring(err)
			if os.clock() - self.LastErrorAt > 2 then
				self.LastErrorAt = os.clock()
				warn("[Aegis] " .. tostring(err))
			end
		end
	end))
	self.Tracker:Start()
	self.View.State = self.Config.Parry.Enabled and "ARMED" or "DISABLED"
	self.View.LastEvent = "Engine ready · " .. self.InputMode
end

function AutoParry:SetEnabled(enabled)
	self.Config.Parry.Enabled = enabled == true
	self.LastParryBall = nil
	self.LastParryApproach = -1
	self.View.State = self.Config.Parry.Enabled and "ARMED" or "DISABLED"
	self.View.LastEvent = self.Config.Parry.Enabled and "Defense enabled" or "Defense disabled"
end

function AutoParry:FireInput()
	local mode = self.InputMode
	if mode == "KeyF" and type(keypress) == "function" then
		keypress(0x46)
		if type(keyrelease) == "function" then
			keyrelease(0x46)
		end
		return true
	end
	if mode == "Mouse" and type(mouse1click) == "function" then
		mouse1click()
		return true
	end

	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
	return true
end

function AutoParry:GetTriggerWindow(frameDelta)
	local window = self.Config.Parry.BaseTriggerWindow + math.min(frameDelta, 1 / 30)
	local ping = self.Config.GetPingSeconds()
	if self.Config.Parry.CompensatePing then
		window = window + math.min(ping * self.Config.Parry.PingScale, self.Config.Parry.MaxPingCompensation)
	end
	self.View.Ping = ping
	return math.min(window, self.Config.Parry.MaxTriggerWindow)
end

function AutoParry:IsPullReentry(snapshot)
	return snapshot.ApproachReason == "PULL_REENTRY" or (
		snapshot.ApproachReason == "TARGET_ACQUIRED"
		and snapshot.SinceLastParry <= self.Config.Pull.ReentryWindow
	)
end

function AutoParry:Step(frameDelta)
	local now = os.clock()
	if not self.Config.Parry.Enabled then
		self.View.State = "DISABLED"
		return
	end

	if not self.Character or not self.Character.Parent then
		self.View.State = "NO_CHARACTER"
		return
	end
	if not self.Root or not self.Root.Parent then
		self.Root = self.Character:FindFirstChild("HumanoidRootPart")
	end
	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	if not self.Root or not humanoid or humanoid.Health <= 0 then
		self.View.State = "WAITING"
		return
	end

	local snapshot = self.Tracker:Sample(self.Root, now, frameDelta)
	if not snapshot then
		self.View.State = "SEARCHING"
		self.View.LastEvent = "No active ball"
		return
	end

	self.View.State = snapshot.State
	self.View.Speed = snapshot.Speed
	self.View.Distance = snapshot.SurfaceDistance
	self.View.TimeToImpact = snapshot.TimeToImpact
	self.View.ClosingSpeed = snapshot.ClosingSpeed
	self.View.ApproachReason = snapshot.ApproachReason
	self.View.DirectionChange = snapshot.DirectionChange

	if snapshot.Target == false or snapshot.Held or not snapshot.Incoming then
		return
	end
	if snapshot.Target == nil and snapshot.TimeToImpact > 0.20 and snapshot.SurfaceDistance > snapshot.CollisionRadius * 1.5 then
		return
	end
	if self.LastParryBall == snapshot.Ball and self.LastParryApproach == snapshot.ApproachId then
		return
	end
	if snapshot.NewApproach and self:IsPullReentry(snapshot) and not self.Config.Pull.Enabled then
		return
	end
	if now - self.LastInputAt < self.Config.Parry.MinimumInputInterval then
		return
	end

	local triggerWindow = self:GetTriggerWindow(frameDelta)
	local predictedImpact = self.Config.Parry.Predictive and snapshot.TimeToImpact <= triggerWindow
	local emergencyImpact = snapshot.SurfaceDistance <= self.Config.Parry.EmergencyRadius and snapshot.ClosingSpeed > 0
	local insideHitbox = snapshot.TimeToImpact == 0 and snapshot.ClosingSpeed > 0
	if not (predictedImpact or emergencyImpact or insideHitbox) then
		return
	end

	local ok, err = pcall(function()
		self:FireInput()
	end)
	if not ok then
		self.View.State = "INPUT_ERROR"
		self.View.LastEvent = tostring(err)
		self.LastInputAt = now - self.Config.Parry.MinimumInputInterval + 0.25
		return
	end

	self.LastInputAt = now
	self.LastParryBall = snapshot.Ball
	self.LastParryApproach = snapshot.ApproachId
	self.Tracker:MarkParry(now)
	self.Metrics.Parries = self.Metrics.Parries + 1

	local eventName = "Parry"
	if self:IsPullReentry(snapshot) then
		self.Metrics.PullCounters = self.Metrics.PullCounters + 1
		eventName = "Pull counter"
		self.View.State = "PULL_COUNTER"
	elseif self.Config.Fury.Enabled and (snapshot.ApproachReason == "FURY_RELEASE" or snapshot.JustReleased or snapshot.VelocitySpike) then
		self.Metrics.FuryCounters = self.Metrics.FuryCounters + 1
		eventName = "Fury counter"
		self.View.State = "FURY_COUNTER"
	end
	self.View.LastEvent = string.format("%s · %.0f stud/s", eventName, snapshot.Speed)
end

function AutoParry:GetView()
	return self.View, self.Metrics
end

function AutoParry:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	self.Tracker:Destroy()
end

return AutoParry