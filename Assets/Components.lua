-- Aegis Blade Ball | Reusable UI primitives

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Components = {}
Components.__index = Components

function Components.new(theme)
	return setmetatable({ Theme = theme }, Components)
end

function Components:Create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

function Components:Corner(parent, radius)
	return self:Create("UICorner", {
		CornerRadius = radius or self.Theme.Radius.Medium,
	}, parent)
end

function Components:Stroke(parent, color, transparency, thickness)
	return self:Create("UIStroke", {
		Color = color or self.Theme.Border,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function Components:Padding(parent, left, right, top, bottom)
	return self:Create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	}, parent)
end

function Components:Text(parent, text, size, color, font, properties)
	local settings = {
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = color or self.Theme.Text,
		TextSize = size or 14,
		Font = font or self.Theme.Font.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end
	return self:Create("TextLabel", settings, parent)
end

function Components:Button(parent, text, properties, callback)
	local theme = self.Theme
	local settings = {
		BackgroundColor3 = theme.Surface,
		AutoButtonColor = false,
		Text = text or "",
		TextColor3 = theme.Text,
		TextSize = 13,
		Font = theme.Font.Medium,
		BorderSizePixel = 0,
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end

	local button = self:Create("TextButton", settings, parent)
	self:Corner(button, theme.Radius.Small)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, theme.Tween.Fast, { BackgroundColor3 = theme.SurfaceHover }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, theme.Tween.Fast, { BackgroundColor3 = theme.Surface }):Play()
	end)
	if callback then
		button.Activated:Connect(callback)
	end
	return button
end

function Components:Card(parent, properties)
	local card = self:Create("Frame", {
		BackgroundColor3 = self.Theme.Surface,
		BorderSizePixel = 0,
	}, parent)
	for key, value in pairs(properties or {}) do
		card[key] = value
	end
	self:Corner(card, self.Theme.Radius.Medium)
	self:Stroke(card, self.Theme.Border, 0.35)
	return card
end

function Components:Toggle(parent, label, description, initialValue, callback)
	local theme = self.Theme
	local value = initialValue == true
	local container = self:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 54),
	}, parent)

	self:Text(container, label, 14, theme.Text, theme.Font.Medium, {
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, -62, 0, 20),
	})
	self:Text(container, description, 11, theme.TextMuted, theme.Font.Regular, {
		Position = UDim2.fromOffset(0, 25),
		Size = UDim2.new(1, -62, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local track = self:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		BackgroundColor3 = value and theme.Accent or theme.Track,
		BorderSizePixel = 0,
	}, container)
	self:Corner(track, UDim.new(1, 0))

	local knob = self:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
	}, track)
	self:Corner(knob, UDim.new(1, 0))

	local button = self:Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
	}, track)

	local api = {}
	function api.Set(_, newValue, silent)
		value = newValue == true
		TweenService:Create(track, theme.Tween.Fast, {
			BackgroundColor3 = value and theme.Accent or theme.Track,
		}):Play()
		TweenService:Create(knob, theme.Tween.Fast, {
			Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}):Play()
		if not silent and callback then
			callback(value)
		end
	end

	button.Activated:Connect(function()
		api:Set(not value, false)
	end)
	return api
end

function Components:Slider(parent, label, minimum, maximum, step, initialValue, callback)
	local theme = self.Theme
	local value = initialValue
	local dragging = false
	local connections = {}
	local container = self:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 62),
	}, parent)

	self:Text(container, label, 13, theme.Text, theme.Font.Medium, {
		Size = UDim2.new(1, -72, 0, 20),
	})
	local valueLabel = self:Text(container, tostring(initialValue), 12, theme.Cyan, theme.Font.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(72, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local track = self:Create("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = theme.Track,
		BorderSizePixel = 0,
	}, container)
	self:Corner(track, UDim.new(1, 0))
	local fill = self:Create("Frame", {
		Size = UDim2.fromScale((initialValue - minimum) / (maximum - minimum), 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	}, track)
	self:Corner(fill, UDim.new(1, 0))
	local knob = self:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
	}, track)
	self:Corner(knob, UDim.new(1, 0))

	local hitbox = self:Create("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, -8),
		Size = UDim2.new(1, 0, 1, 16),
		Text = "",
	}, track)

	local function update(newValue, fireCallback)
		local snapped = math.floor((newValue - minimum) / step + 0.5) * step + minimum
		value = math.clamp(snapped, minimum, maximum)
		local alpha = (value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = step < 1 and string.format("%.2f", value) or tostring(math.floor(value + 0.5))
		if fireCallback and callback then
			callback(value)
		end
	end

	local function updateFromX(x)
		update(minimum + (maximum - minimum) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), true)
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	update(initialValue, false)
	return {
		Set = function(_, newValue)
			update(newValue, false)
		end,
		Destroy = function()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
		end,
	}
end

return Components