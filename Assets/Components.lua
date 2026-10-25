local Components = {}

function Components.Attach(config, theme)
    Components.Config = config
    Components.Theme = theme
    return Components
end

local function rowHeight(hint)
    return hint and 58 or 44
end

function Components.Card(parent)
    local T, W, Th = Components.Theme.T, Components.Theme.W, Components.Theme
    local card = Instance.new("Frame")
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = parent
    Th.Corner(card, W.CardRadius)
    Th.Stroke(card)
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 10)
    list.Parent = card
    Th.Pad(card, 18, 18, 18, 18)
    return card
end

function Components.SectionHead(parent, title, description)
    local T, Th = Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.Parent = parent
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 4)
    list.Parent = wrap
    Th.Label(wrap, { Text = title, Font = T.FontMedium, Size = 15, Height = 20, Color = T.Text })
    if description and description ~= "" then
        Th.Label(wrap, {
            Text = description,
            Size = 12,
            Color = T.TextMuted,
            Wrap = true,
            Auto = Enum.AutomaticSize.Y,
            Height = 16,
        })
    end
    return wrap
end

function Components.Toggle(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local h = rowHeight(ctrl.Hint)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, h)
    row.Parent = parent

    Th.Label(row, { Text = ctrl.Label, Font = T.FontMedium, Size = 13, Height = 18, Pos = UDim2.new(0, 0, 0, 4) })
    if ctrl.Hint then
        Th.Label(row, {
            Text = ctrl.Hint,
            Size = 12,
            Color = T.TextMuted,
            Wrap = true,
            Height = 28,
            Pos = UDim2.new(0, 0, 0, 24),
            Rect = UDim2.new(1, -64, 0, 28),
        })
    end

    local track = Instance.new("TextButton")
    track.AutoButtonColor = false
    track.Text = ""
    track.Size = UDim2.new(0, 42, 0, 24)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Parent = row
    Th.Corner(track, 12)

    local knob = Instance.new("Frame")
    knob.BorderSizePixel = 0
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = track
    Th.Corner(knob, 9)

    local function paint(on)
        track.BackgroundColor3 = on and T.Accent or T.ToggleOff
        Th.Tween(knob, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, "Toggle")
    end

    paint(config.Get(ctrl.Path) == true)
    track.MouseButton1Click:Connect(function()
        local nextValue = not config.Get(ctrl.Path)
        config.Set(ctrl.Path, nextValue)
        paint(nextValue)
    end)
    config.Watch(ctrl.Path, function(value)
        paint(value == true)
    end)
    return row
end

function Components.Note(parent, ctrl)
    local T, Th = Components.Theme.T, Components.Theme
    local box = Instance.new("Frame")
    box.BackgroundColor3 = T.AccentSoft
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.Parent = parent
    Th.Corner(box, 8)
    Th.Pad(box, 12, 14, 12, 14)
    Th.Label(box, {
        Text = ctrl.Text,
        Size = 12,
        Color = T.TextSecondary,
        Wrap = true,
        Auto = Enum.AutomaticSize.Y,
        Height = 16,
    })
    return box
end

function Components.Segment(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.Parent = parent

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = wrap

    Th.Label(wrap, { Text = ctrl.Label, Size = 12, Color = T.TextMuted, Height = 16 })

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = T.Elevated
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, 0, 0, 36)
    bar.Parent = wrap
    Th.Corner(bar, 8)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = bar
    Th.Pad(bar, 4, 4, 4, 4)

    local buttons = {}
    local n = #ctrl.Options
    for i, opt in ipairs(ctrl.Options) do
        local caption = (ctrl.Captions and ctrl.Captions[opt]) or opt
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.Font = T.FontMedium
        btn.Text = caption
        btn.TextSize = 12
        btn.Size = UDim2.new(1 / n, -4, 1, 0)
        btn.BorderSizePixel = 0
        btn.Parent = bar
        Th.Corner(btn, 6)
        buttons[opt] = btn
        btn.MouseButton1Click:Connect(function()
            config.Set(ctrl.Path, opt)
        end)
    end

    local function paint(value)
        for opt, btn in pairs(buttons) do
            local on = opt == value
            btn.BackgroundColor3 = on and T.SurfaceHover or T.Elevated
            btn.TextColor3 = on and T.Text or T.TextMuted
        end
    end
    paint(config.Get(ctrl.Path))
    config.Watch(ctrl.Path, paint)
    return wrap
end

function Components.Chips(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.Parent = parent

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = wrap

    Th.Label(wrap, { Text = ctrl.Label, Size = 12, Color = T.TextMuted, Height = 16 })
    if ctrl.Hint then
        Th.Label(wrap, { Text = ctrl.Hint, Size = 12, Color = T.TextMuted, Wrap = true, Auto = Enum.AutomaticSize.Y, Height = 16 })
    end

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 32)
    row.Parent = wrap
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = row

    for _, key in ipairs(ctrl.Keys) do
        local path = ctrl.Path .. "." .. key
        local caption = (ctrl.Captions and ctrl.Captions[key]) or key
        local chip = Instance.new("TextButton")
        chip.AutoButtonColor = false
        chip.Font = T.FontMedium
        chip.Text = caption
        chip.TextSize = 12
        chip.Size = UDim2.new(0, 78, 0, 30)
        chip.BorderSizePixel = 0
        chip.Parent = row
        Th.Corner(chip, 8)
        Th.Stroke(chip)

        local function paint(on)
            chip.BackgroundColor3 = on and T.AccentSoft or T.Elevated
            chip.TextColor3 = on and T.Accent or T.TextSecondary
            local stroke = chip:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = on and T.Accent or T.Border
            end
        end
        paint(config.Get(path) == true)
        chip.MouseButton1Click:Connect(function()
            config.Set(path, not config.Get(path))
        end)
        config.Watch(path, function(v)
            paint(v == true)
        end)
    end
    return wrap
end

function Components.Text(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 54)
    wrap.Parent = parent
    Th.Label(wrap, { Text = ctrl.Label, Size = 12, Color = T.TextMuted, Height = 16 })

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = T.Elevated
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Font = T.Font
    box.PlaceholderText = ctrl.Placeholder or ""
    box.PlaceholderColor3 = T.TextMuted
    box.Text = tostring(config.Get(ctrl.Path) or "")
    box.TextColor3 = T.Text
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Size = UDim2.new(1, 0, 0, 32)
    box.Position = UDim2.new(0, 0, 0, 20)
    box.Parent = wrap
    Th.Corner(box, 8)
    Th.Stroke(box)
    Th.Pad(box, 0, 10, 0, 10)
    box.FocusLost:Connect(function()
        config.Set(ctrl.Path, box.Text)
    end)
    config.Watch(ctrl.Path, function(v)
        if not box:IsFocused() then
            box.Text = tostring(v or "")
        end
    end)
    return wrap
end

local function round(n, step)
    if step >= 1 then
        return math.floor(n + 0.5)
    end
    local inv = 1 / step
    return math.floor(n * inv + 0.5) / inv
end

function Components.Slider(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 44)
    wrap.Parent = parent

    local title = Th.Label(wrap, { Text = ctrl.Label, Size = 12, Color = T.TextMuted, Height = 16, Rect = UDim2.new(1, -56, 0, 16) })
    local valueLbl = Th.Label(wrap, {
        Text = "",
        Size = 12,
        Color = T.TextSecondary,
        Align = Enum.TextXAlignment.Right,
        Height = 16,
        Rect = UDim2.new(0, 56, 0, 16),
        Pos = UDim2.new(1, -56, 0, 0),
    })

    local track = Instance.new("Frame")
    track.BackgroundColor3 = T.Elevated
    track.BorderSizePixel = 0
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 28)
    track.Parent = wrap
    Th.Corner(track, 3)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = track
    Th.Corner(fill, 3)

    local function paint(v)
        local t = (v - ctrl.Min) / (ctrl.Max - ctrl.Min)
        t = math.clamp(t, 0, 1)
        fill.Size = UDim2.new(t, 0, 1, 0)
        local digits = ctrl.Step < 1 and 2 or 0
        valueLbl.Text = string.format("%." .. digits .. "f", v)
    end

    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local function fromX(x)
        local abs = track.AbsolutePosition.X
        local w = track.AbsoluteSize.X
        local a = math.clamp((x - abs) / math.max(w, 1), 0, 1)
        local raw = ctrl.Min + a * (ctrl.Max - ctrl.Min)
        config.Set(ctrl.Path, round(raw, ctrl.Step))
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    paint(config.Get(ctrl.Path) or ctrl.Min)
    config.Watch(ctrl.Path, paint)
    return wrap
end

function Components.Color(parent, ctrl)
    local config, T, Th = Components.Config, Components.Theme.T, Components.Theme
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, 54)
    wrap.Parent = parent
    Th.Label(wrap, { Text = ctrl.Label, Size = 12, Color = T.TextMuted, Height = 16 })

    local swatch = Instance.new("Frame")
    swatch.BorderSizePixel = 0
    swatch.Size = UDim2.new(0, 32, 0, 32)
    swatch.Position = UDim2.new(0, 0, 0, 20)
    swatch.Parent = wrap
    Th.Corner(swatch, 8)
    Th.Stroke(swatch)

    local fields = {}
    local labels = { "R", "G", "B" }
    for i = 1, 3 do
        local box = Instance.new("TextBox")
        box.BackgroundColor3 = T.Elevated
        box.BorderSizePixel = 0
        box.ClearTextOnFocus = false
        box.Font = T.Font
        box.PlaceholderText = labels[i]
        box.PlaceholderColor3 = T.TextMuted
        box.TextColor3 = T.Text
        box.TextSize = 13
        box.Size = UDim2.new(0, 64, 0, 32)
        box.Position = UDim2.new(0, 40 + (i - 1) * 72, 0, 20)
        box.Parent = wrap
        Th.Corner(box, 8)
        Th.Stroke(box)
        fields[i] = box
    end

    local function paint(c)
        if typeof(c) ~= "Color3" then
            return
        end
        swatch.BackgroundColor3 = c
        fields[1].Text = tostring(math.floor(c.R * 255 + 0.5))
        fields[2].Text = tostring(math.floor(c.G * 255 + 0.5))
        fields[3].Text = tostring(math.floor(c.B * 255 + 0.5))
    end

    local function commit()
        local r = math.clamp(tonumber(fields[1].Text) or 0, 0, 255)
        local g = math.clamp(tonumber(fields[2].Text) or 0, 0, 255)
        local b = math.clamp(tonumber(fields[3].Text) or 0, 0, 255)
        config.Set(ctrl.Path, Color3.fromRGB(r, g, b))
    end
    for i = 1, 3 do
        fields[i].FocusLost:Connect(commit)
    end
    paint(config.Get(ctrl.Path))
    config.Watch(ctrl.Path, paint)
    return wrap
end

function Components.Control(parent, ctrl)
    local kind = ctrl.Kind
    if kind == "Toggle" then
        return Components.Toggle(parent, ctrl)
    elseif kind == "Note" then
        return Components.Note(parent, ctrl)
    elseif kind == "Segment" then
        return Components.Segment(parent, ctrl)
    elseif kind == "Chips" then
        return Components.Chips(parent, ctrl)
    elseif kind == "Text" then
        return Components.Text(parent, ctrl)
    elseif kind == "Slider" then
        return Components.Slider(parent, ctrl)
    elseif kind == "Color" then
        return Components.Color(parent, ctrl)
    end
end

return Components
