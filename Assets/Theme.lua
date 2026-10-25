local Theme = {}

function Theme.Attach(config)
    Theme.Config = config
    Theme.T = config.UI.Theme
    Theme.W = config.UI.Window
    Theme.M = config.UI.Motion
    return Theme
end

function Theme.Duration(kind)
    if Theme.Config.Settings.ReduceMotion then
        return 0
    end
    return Theme.M[kind] or 0.12
end

function Theme.Tween(inst, props, kind)
    local TweenService = game:GetService("TweenService")
    local info = TweenInfo.new(Theme.Duration(kind), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

function Theme.Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Theme.W.CardRadius)
    c.Parent = parent
    return c
end

function Theme.Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.T.Border
    s.Thickness = thickness or Theme.W.StrokeThickness
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Theme.Pad(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t)
    p.PaddingRight = UDim.new(0, r or t)
    p.PaddingBottom = UDim.new(0, b or t)
    p.PaddingLeft = UDim.new(0, l or r or t)
    p.Parent = parent
    return p
end

function Theme.Label(parent, props)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Font = props.Font or Theme.T.Font
    t.Text = props.Text or ""
    t.TextColor3 = props.Color or Theme.T.Text
    t.TextSize = props.Size or 14
    t.TextXAlignment = props.Align or Enum.TextXAlignment.Left
    t.TextYAlignment = props.VAlign or Enum.TextYAlignment.Center
    t.TextWrapped = props.Wrap == true
    t.Size = props.Rect or UDim2.new(1, 0, 0, props.Height or 18)
    t.Position = props.Pos or UDim2.new(0, 0, 0, 0)
    t.AutomaticSize = props.Auto or Enum.AutomaticSize.None
    t.Parent = parent
    return t
end

return Theme
