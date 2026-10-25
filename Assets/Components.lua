-- Agoys Script / Components.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Components = {}
local Theme

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Corner), Parent = parent })
end

local function stroke(parent, color, transparency)
    create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, amount)
    create("UIPadding", {
        PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount),
        PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount),
        Parent = parent,
    })
end

local function text(parent, value, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = color or Theme.Text,
        TextSize = size or Theme.BodySize,
        Font = font or Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    })
end

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    local ok = pcall(function() return game:GetService("CoreGui").Name end)
    if ok then return game:GetService("CoreGui") end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPosition = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end

function Components.Init(theme)
    Theme = theme
end

function Components.CreateWindow(options)
    assert(Theme, "Components.Init(Theme) harus dipanggil sebelum membuat UI")
    options = options or {}
    local screen = create("ScreenGui", {
        Name = "AgoysDashboard", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getGuiParent(),
    })
    local root = create("Frame", {
        Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 510),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = screen,
    })
    corner(root, 14)
    stroke(root, Theme.Border, 0.12)
    local scale = create("UIScale", { Parent = root })
    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        scale.Scale = math.clamp(math.min((viewport.X - 28) / 820, (viewport.Y - 28) / 510), 0.62, 1)
    end
    resize()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end

    local topbar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0, Parent = root,
    })
    corner(topbar, 14)
    create("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = topbar })
    local brand = text(topbar, options.Title or "Agoys Script", 16, Theme.Text, Theme.FontBold)
    brand.Position = UDim2.fromOffset(22, 10)
    brand.Size = UDim2.new(0, 260, 0, 22)
    local subtitle = text(topbar, options.Subtitle or "Blade Ball  /  Control Center", Theme.SmallSize, Theme.TextMuted)
    subtitle.Position = UDim2.fromOffset(22, 32)
    subtitle.Size = UDim2.new(0, 300, 0, 16)
    local close = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Theme.Surface,
        Text = "×", TextSize = 22, Font = Theme.FontMedium, TextColor3 = Theme.TextMuted,
        AutoButtonColor = false, BorderSizePixel = 0, Parent = topbar,
    })
    corner(close, 8)

    local sidebar = create("Frame", {
        Position = UDim2.fromOffset(0, 58), Size = UDim2.new(0, 188, 1, -58),
        BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = root,
    })
    create("Frame", { Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
        BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = sidebar })
    local nav = create("Frame", { Position = UDim2.fromOffset(12, 16),
        Size = UDim2.new(1, -24, 1, -62), BackgroundTransparency = 1, Parent = sidebar })
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = nav })
    local footer = text(sidebar, "RightShift  ·  sembunyikan", Theme.SmallSize, Theme.TextMuted)
    footer.Position = UDim2.new(0, 16, 1, -32)
    footer.Size = UDim2.new(1, -32, 0, 18)

    local content = create("Frame", {
        Position = UDim2.fromOffset(188, 58), Size = UDim2.new(1, -188, 1, -58),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = root,
    })
    corner(content, 12)
    create("Frame", { Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0, Parent = content })

    local window = { Screen = screen, Root = root, Tabs = {}, ActiveTab = nil }
    function window.SetVisible(value)
        root.Visible = value
    end
    function window.Toggle()
        root.Visible = not root.Visible
    end
    function window.SelectTab(name)
        for tabName, tab in pairs(window.Tabs) do
            local selected = tabName == name
            tab.Page.Visible = selected
            tab.Button.BackgroundColor3 = selected and Theme.SurfaceActive or Color3.new(0, 0, 0)
            tab.Button.BackgroundTransparency = selected and 0 or 1
            tab.Button.TextColor3 = selected and Theme.Text or Theme.TextMuted
            tab.Indicator.BackgroundTransparency = selected and 0 or 1
        end
        window.ActiveTab = name
    end
    function window.AddTab(name, order)
        local button = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
            Text = "     " .. name, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.TextMuted, TextSize = Theme.BodySize, Font = Theme.FontMedium,
            AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order or 0, Parent = nav,
        })
        corner(button, 8)
        local indicator = create("Frame", { Size = UDim2.fromOffset(3, 18),
            Position = UDim2.new(0, 0, 0.5, -9), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1, BorderSizePixel = 0, Parent = button })
        corner(indicator, 3)
        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, -26, 1, -24), Position = UDim2.fromOffset(14, 12),
            BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, Parent = content,
        })
        create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
        create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), Parent = page })
        window.Tabs[name] = { Button = button, Page = page, Indicator = indicator }
        button.MouseButton1Click:Connect(function() window.SelectTab(name) end)
        if not window.ActiveTab then window.SelectTab(name) end
        return page
    end
    close.MouseButton1Click:Connect(function() root.Visible = false end)
    function window.Destroy()
        screen:Destroy()
    end
    makeDraggable(root, topbar)
    return window
end

local function card(page, label, description, height)
    local frame = create("Frame", { Size = UDim2.new(1, 0, 0, height or 64),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = page })
    corner(frame, Theme.Corner)
    stroke(frame, Theme.Border, 0.35)
    local title = text(frame, label, Theme.BodySize, Theme.Text, Theme.FontMedium)
    title.Position = UDim2.fromOffset(15, description and 10 or 0)
    title.Size = UDim2.new(1, -150, 0, description and 20 or height or 64)
    if description then
        local detail = text(frame, description, Theme.SmallSize, Theme.TextMuted)
        detail.Position = UDim2.fromOffset(15, 32)
        detail.Size = UDim2.new(1, -150, 0, 18)
    end
    return frame
end

function Components.Section(page, title)
    local label = text(page, string.upper(title), Theme.SmallSize, Theme.TextMuted, Theme.FontBold)
    label.Size = UDim2.new(1, 0, 0, 24)
    return label
end

function Components.Toggle(page, label, description, default, callback)
    local frame = card(page, label, description, description and 64 or 52)
    local button = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.fromOffset(42, 24),
        BackgroundColor3 = default and Theme.AccentDark or Theme.Border, Text = "",
        AutoButtonColor = false, BorderSizePixel = 0, Parent = frame })
    corner(button, 12)
    local knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5),
        Position = default and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0, Parent = button })
    corner(knob, 9)
    local value = default == true
    button.MouseButton1Click:Connect(function()
        value = not value
        button.BackgroundColor3 = value and Theme.AccentDark or Theme.Border
        knob.Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if callback then callback(value) end
    end)
    return frame
end

function Components.Dropdown(page, label, description, values, default, callback)
    local frame = card(page, label, description, description and 64 or 52)
    local index = table.find(values, default) or 1
    local button = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.fromOffset(142, 32),
        BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.Text,
        TextSize = Theme.SmallSize, Font = Theme.FontMedium, AutoButtonColor = false,
        BorderSizePixel = 0, Text = values[index] .. "   ⌄", Parent = frame })
    corner(button, Theme.CornerSmall)
    button.MouseButton1Click:Connect(function()
        index = index % #values + 1
        button.Text = values[index] .. "   ⌄"
        if callback then callback(values[index]) end
    end)
    return frame
end

function Components.TextBox(page, label, description, default, placeholder, callback)
    local frame = card(page, label, description, description and 64 or 52)
    local box = create("TextBox", { AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.fromOffset(220, 32),
        BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted, PlaceholderText = placeholder or "",
        Text = tostring(default or ""), TextSize = Theme.SmallSize, Font = Theme.Font,
        ClearTextOnFocus = false, BorderSizePixel = 0, Parent = frame })
    corner(box, Theme.CornerSmall)
    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
    return frame
end

function Components.Slider(page, label, description, minimum, maximum, default, decimals, callback)
    local frame = card(page, label, description, description and 74 or 62)
    local valueLabel = text(frame, tostring(default), Theme.SmallSize, Theme.Accent, Theme.FontMedium)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -15, 0, 9)
    valueLabel.Size = UDim2.fromOffset(80, 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local track = create("Frame", { AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 15, 1, -13), Size = UDim2.new(1, -30, 0, 5),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = frame })
    corner(track, 3)
    local fill = create("Frame", { Size = UDim2.fromScale((default - minimum) / (maximum - minimum), 1),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track })
    corner(fill, 3)
    local dragging = false
    local function update(x)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minimum + (maximum - minimum) * alpha
        local factor = 10 ^ (decimals or 0)
        local value = math.floor(raw * factor + 0.5) / factor
        fill.Size = UDim2.fromScale(alpha, 1)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return frame
end

function Components.Button(page, label, description, buttonText, callback, danger)
    local frame = card(page, label, description, description and 64 or 52)
    local button = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.fromOffset(132, 32),
        BackgroundColor3 = danger and Theme.Danger or Theme.AccentDark,
        TextColor3 = Theme.Text, Text = buttonText, TextSize = Theme.SmallSize,
        Font = Theme.FontMedium, AutoButtonColor = false, BorderSizePixel = 0, Parent = frame })
    corner(button, Theme.CornerSmall)
    button.MouseButton1Click:Connect(function() if callback then callback() end end)
    return frame
end

return Components