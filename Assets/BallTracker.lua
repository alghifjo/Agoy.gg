-- Aegis Blade Ball | Ball discovery, trajectory estimation, and approach segmentation

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local BallTracker = {}
BallTracker.__index = BallTracker

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function safeAttribute(instance, name)
	local ok, value = pcall(instance.GetAttribute, instance, name)
	if ok then
		return value
	end
	return nil
end

local function timeToImpact(relativePosition, relativeVelocity, radius)
	local c = relativePosition:Dot(relativePosition) - radius * radius
	if c <= 0 then
		return 0
	end

	local a = relativeVelocity:Dot(relativeVelocity)
	if a < 0.01 then
		return math.huge
	end

	local b = 2 * relativePosition:Dot(relativeVelocity)
	local discriminant = b * b - 4 * a * c
	if discriminant < 0 then
		return math.huge
	end

	local root = math.sqrt(discriminant)
	local first = (-b - root) / (2 * a)
	local second = (-b + root) / (2 * a)
	if first >= 0 then
		return first
	end
	if second >= 0 then
		return second
	end
	return math.huge
end

function BallTracker.new(config)
	local self = setmetatable({}, BallTracker)
	self.Config = config
	self.LocalPlayer = Players.LocalPlayer
	self.Ball = nil
	self.NextScanAt = 0
	self.Connections = {}
	self.History = {}
	self:ResetHistory()
	return self
end

function BallTracker:ResetHistory()
	self.History = {
		Ball = nil,
		Position = nil,
		LastSampleAt = nil,
		LastSpeed = 0,
		LastDirection = nil,
		WasTargeted = false,
		WasIncoming = false,
		WasHeld = false,
		HasOutgoing = false,
		HoldTime = 0,
		ApproachId = 0,
		LastApproachReason = "NONE",
		LastParryAt = 0,
	}
end

function BallTracker:Start()
	table.insert(self.Connections, Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and self:IsCandidate(descendant) then
			self.NextScanAt = 0
		end
	end))
	table.insert(self.Connections, Workspace.DescendantRemoving:Connect(function(descendant)
		if descendant == self.Ball then
			self.Ball = nil
			self:ResetHistory()
			self.NextScanAt = 0
		end
	end))
end

function BallTracker:IsCandidate(part)
	if not part:IsA("BasePart") then
		return false
	end
	if safeAttribute(part, self.Config.Ball.RealBallAttribute) ~= nil then
		return true
	end
	local name = string.lower(part.Name)
	return name == "ball" or string.find(name, "ball", 1, true) ~= nil
end

function BallTracker:GetTargetState(ball)
	for _, attributeName in ipairs(self.Config.Ball.TargetAttributes) do
		local value = safeAttribute(ball, attributeName)
		if typeof(value) == "Instance" then
			if value == self.LocalPlayer or value == self.LocalPlayer.Character then
				return true
			end
			return false
		end
		if type(value) == "string" and value ~= "" then
			return value == self.LocalPlayer.Name or value == self.LocalPlayer.DisplayName
		end
		if type(value) == "number" and value ~= 0 then
			return value == self.LocalPlayer.UserId
		end
	end

	for _, childName in ipairs({ "Target", "target", "TargetPlayer" }) do
		local valueObject = ball:FindFirstChild(childName)
		if valueObject and valueObject:IsA("ValueBase") then
			local value = valueObject.Value
			if typeof(value) == "Instance" then
				return value == self.LocalPlayer or value == self.LocalPlayer.Character
			end
			if type(value) == "string" then
				return value == self.LocalPlayer.Name or value == self.LocalPlayer.DisplayName
			end
		end
	end
	return nil
end

function BallTracker:ScoreBall(ball, root)
	local realBall = safeAttribute(ball, self.Config.Ball.RealBallAttribute)
	if realBall == false then
		return -math.huge
	end

	local score = 0
	if realBall == true then
		score = score + 1000
	end
	if ball.Name == "Ball" then
		score = score + 80
	end
	local target = self:GetTargetState(ball)
	if target == true then
		score = score + 500
	elseif target == false then
		score = score - 80
	end
	if root then
		score = score - (ball.Position - root.Position).Magnitude * 0.05
	end
	return score
end

function BallTracker:SelectBall(root)
	local bestBall = nil
	local bestScore = -math.huge
	local visited = {}

	local function consider(container)
		if not container then
			return
		end
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("BasePart") and not visited[descendant] and self:IsCandidate(descendant) then
				visited[descendant] = true
				local score = self:ScoreBall(descendant, root)
				if score > bestScore then
					bestScore = score
					bestBall = descendant
				end
			end
		end
	end

	for _, containerName in ipairs(self.Config.Ball.ContainerNames) do
		local container = Workspace:FindFirstChild(containerName)
		if container then
			if container:IsA("BasePart") then
				consider(container.Parent)
			else
				consider(container)
			end
		end
	end

	if not bestBall then
		consider(Workspace)
	end
	return bestBall
end

function BallTracker:MarkParry(now)
	self.History.LastParryAt = now
	self.History.HasOutgoing = false
end

function BallTracker:Sample(root, now, frameDelta)
	if not self.Ball or not self.Ball.Parent then
		self.Ball = self:SelectBall(root)
		self:ResetHistory()
		self.Ball = self.Ball
	elseif now >= self.NextScanAt then
		self.NextScanAt = now + self.Config.Runtime.BallScanInterval
		local selected = self:SelectBall(root)
		if selected and selected ~= self.Ball then
			self.Ball = selected
			self:ResetHistory()
		end
	end

	local ball = self.Ball
	if not ball or not root then
		return nil
	end

	local history = self.History
	if history.Ball ~= ball then
		self:ResetHistory()
		history = self.History
		history.Ball = ball
	end

	local position = ball.Position
	local physicsVelocity = ball.AssemblyLinearVelocity
	local velocity = physicsVelocity
	local sampleDelta = frameDelta
	local teleported = false

	if history.Position and history.LastSampleAt then
		sampleDelta = clamp(now - history.LastSampleAt, 1 / 240, self.Config.Runtime.MaxFrameDelta)
		local displacement = position - history.Position
		teleported = displacement.Magnitude > self.Config.Ball.TeleportDistance
		if teleported then
			history.LastDirection = nil
			history.LastSpeed = 0
			history.HoldTime = 0
		else
			local measuredVelocity = displacement / sampleDelta
			local blend = self.Config.Ball.VelocityBlend
			velocity = measuredVelocity * blend + physicsVelocity * (1 - blend)
			if physicsVelocity.Magnitude > measuredVelocity.Magnitude * 2 and physicsVelocity.Magnitude > 40 then
				velocity = physicsVelocity
			end
		end
	end

	local speed = velocity.Magnitude
	local relativePosition = position - root.Position
	local distance = relativePosition.Magnitude
	local rootVelocity = root.AssemblyLinearVelocity
	local relativeVelocity = velocity - rootVelocity
	local closingSpeed = distance > 0.01 and -relativePosition:Dot(relativeVelocity) / distance or 0
	local direction = speed > 4 and velocity.Unit or nil
	local directionChange = 0
	if direction and history.LastDirection then
		directionChange = math.deg(math.acos(clamp(direction:Dot(history.LastDirection), -1, 1)))
	end

	local wasHeld = history.WasHeld
	if speed <= self.Config.Fury.HoldSpeed then
		history.HoldTime = history.HoldTime + sampleDelta
	else
		history.HoldTime = 0
	end
	local held = history.HoldTime >= self.Config.Fury.HoldDelay
	local justReleased = wasHeld and not held and speed >= self.Config.Fury.ReleaseMinimumSpeed
	local acceleration = sampleDelta > 0 and (speed - history.LastSpeed) / sampleDelta or 0
	local velocitySpike = justReleased or (
		history.LastSampleAt ~= nil
		and speed >= self.Config.Fury.SpikeAbsoluteSpeed
		and speed >= math.max(history.LastSpeed * self.Config.Fury.SpikeMultiplier, history.LastSpeed + 35)
		and acceleration >= self.Config.Fury.SpikeAcceleration
	)

	local predictionReach = self.Config.Parry.Predictive
		and math.min(self.Config.Parry.MaxPredictionReach, speed * self.Config.Parry.SpeedReachFactor)
		or 0
	local collisionRadius = self.Config.Parry.HitboxRadius + predictionReach
	local tti = timeToImpact(relativePosition, relativeVelocity, collisionRadius)
	local target = self:GetTargetState(ball)
	local incoming = not held and closingSpeed >= self.Config.Pull.MinimumClosingSpeed and tti < 2.5
	local eligibleTarget = target ~= false
	local newApproach = false
	local reason = nil

	if incoming and eligibleTarget then
		if history.ApproachId == 0 then
			newApproach = true
			reason = "INITIAL"
		end
		if target == true and not history.WasTargeted then
			newApproach = true
			reason = "TARGET_ACQUIRED"
		end
		if velocitySpike and not history.WasIncoming and self.Config.Fury.Enabled then
			newApproach = true
			reason = "VELOCITY_SPIKE"
		end
		if history.HasOutgoing and not history.WasIncoming then
			if directionChange >= self.Config.Pull.DirectionChangeAngle or target == true then
				newApproach = true
				reason = "PULL_REENTRY"
			end
		end
		-- Fury diletakkan terakhir agar labelnya tidak tertimpa spike umum atau re-entry.
		if justReleased and self.Config.Fury.Enabled then
			newApproach = true
			reason = "FURY_RELEASE"
		end
	end

	if newApproach then
		history.ApproachId = history.ApproachId + 1
		history.LastApproachReason = reason
		history.HasOutgoing = false
	end
	if history.LastParryAt > 0 and (not incoming or target == false) then
		history.HasOutgoing = true
	end

	local state = "IDLE"
	if held then
		state = "HELD"
	elseif justReleased or velocitySpike then
		state = "FURY_RELEASE"
	elseif newApproach and (reason == "PULL_REENTRY" or reason == "TARGET_ACQUIRED") then
		state = "REENTRY"
	elseif incoming and eligibleTarget then
		state = "INCOMING"
	elseif target == false then
		state = "OTHER_TARGET"
	elseif distance > 0 then
		state = "OUTGOING"
	end

	local snapshot = {
		Ball = ball,
		Position = position,
		Velocity = velocity,
		Speed = speed,
		Distance = distance,
		SurfaceDistance = math.max(0, distance - self.Config.Ball.RootRadius - ball.Size.Magnitude * 0.25),
		ClosingSpeed = closingSpeed,
		TimeToImpact = tti,
		CollisionRadius = collisionRadius,
		Target = target,
		Incoming = incoming,
		Held = held,
		JustReleased = justReleased,
		VelocitySpike = velocitySpike,
		DirectionChange = directionChange,
		Acceleration = acceleration,
		ApproachId = history.ApproachId,
		ApproachReason = history.LastApproachReason,
		NewApproach = newApproach,
		State = state,
		SinceLastParry = history.LastParryAt > 0 and now - history.LastParryAt or math.huge,
	}

	history.Position = position
	history.LastSampleAt = now
	history.LastSpeed = speed
	history.LastDirection = direction or history.LastDirection
	history.WasTargeted = target == true
	history.WasIncoming = incoming
	history.WasHeld = held
	return snapshot
end

function BallTracker:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	self.Ball = nil
	self:ResetHistory()
end

return BallTracker