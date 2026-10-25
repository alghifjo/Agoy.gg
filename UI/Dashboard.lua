local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Dashboard = {}

local function guiParent()
    if gethui then
        return gethui()
    end
    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and core then
        return core
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Dashboard.Mount(config, theme, components)
    local T, W, Th = theme.T, theme.W, theme
    local existing = guiParent():FindFirstChild("AgoysDashboard")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AgoysDashboard"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = guiParent()

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.BackgroundColor3 = T.Background
    window.BorderSizePixel = 0
    window.Size = UDim2.fromOffset(W.Width, W.Height)
    window.Position = UDim2.new(0.5, -W.Width / 2, 0.5, -W.Height / 2)
    window.Parent = gui
    Th.Corner(window, W.WindowRadius)
    Th.Stroke(window)

    local sidebar = Instance.new("Frame")
    sidebar.BackgroundColor3 = T.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.new(0, W.SidebarWidth, 1, 0)
    sidebar.Parent = window
    Th.Corner(sidebar, W.WindowRadius)
    local clip = Instance.new("Frame")
    clip.BackgroundColor3 = T.Sidebar
    clip.BorderSizePixel = 0
    clip.Position = UDim2.new(1, -16, 0, 0)
    clip.Size = UDim2.new(0, 16, 1, 0)
    clip.Parent = sidebar

    local brand = Instance.new("Frame")
    brand.BackgroundTransparency = 1
    brand.Size = UDim2.new(1, 0, 0, W.HeaderHeight)
    brand.Parent = sidebar
    Th.Pad(brand, 18, 20, 0, 20)
    Th.Label(brand, { Text = config.Meta.Brand, Font = T.FontBold, Size = 16, Height = 20, Color = T.Text })
    Th.Label(brand, {
        Text = config.Meta.Product,
        Size = 12,
        Color = T.TextMuted,
        Height = 16,
        Pos = UDim2.new(0, 0, 0, 22),
        Rect = UDim2.new(1, 0, 0, 16),
    })

    local nav = Instance.new("Frame")
    nav.BackgroundTransparency = 1
    nav.Position = UDim2.new(0, 12, 0, W.HeaderHeight + 8)
    nav.Size = UDim2.new(1, -24, 1, -(W.HeaderHeight + 48))
    nav.Parent = sidebar
    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 4)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Parent = nav

    Th.Label(sidebar, {
        Text = "v" .. config.Meta.Version .. "  ·  " .. config.Meta.Game,
        Size = 11,
        Color = T.TextMuted,
        Height = 16,
        Pos = UDim2.new(0, 20, 1, -28),
        Rect = UDim2.new(1, -40, 0, 16),
    })

    local main = Instance.new("Frame")
    main.BackgroundTransparency = 1
    main.Position = UDim2.new(0, W.SidebarWidth, 0, 0)
    main.Size = UDim2.new(1, -W.SidebarWidth, 1, 0)
    main.Parent = window

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, W.HeaderHeight)
    header.Parent = main
    Th.Pad(header, 16, 20, 8, 24)

    local title = Th.Label(header, { Text = "", Font = T.FontMedium, Size = 18, Height = 22, Pos = UDim2.new(0, 0, 0, 0), Rect = UDim2.new(1, -52, 0, 22) })
    local subtitle = Th.Label(header, { Text = "", Size = 12, Color = T.TextMuted, Height = 16, Pos = UDim2.new(0, 0, 0, 24), Rect = UDim2.new(1, -52, 0, 16) })

    local close = Instance.new("TextButton")
    close.AutoButtonColor = false
    close.Text = "×"
    close.Font = T.Font
    close.TextSize = 18
    close.TextColor3 = T.TextMuted
    close.BackgroundColor3 = T.Surface
    close.BorderSizePixel = 0
    close.Size = UDim2.fromOffset(W.CloseSize, W.CloseSize)
    close.Position = UDim2.new(1, -28, 0, 2)
    close.Parent = header
    Th.Corner(close, 8)
    close.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    local body = Instance.new("ScrollingFrame")
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Position = UDim2.new(0, 0, 0, W.HeaderHeight)
    body.Size = UDim2.new(1, 0, 1, -W.HeaderHeight)
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ScrollBarThickness = 4
    body.ScrollBarImageColor3 = T.Border
    body.ScrollingDirection = Enum.ScrollingDirection.Y
    body.Parent = main
    Th.Pad(body, 8, W.ContentPadding, 24, W.ContentPadding)

    local pages = {}
    local tabButtons = {}
    local activeTab = config.Settings.DefaultTab or "combat"

    local function sectionVisible(section)
        local rule = section.VisibleWhen
        if not rule then
            return true
        end
        return config.Get(rule.Path) == rule.Equals
    end

    for _, tab in ipairs(config.UI.Tabs) do
        local page = Instance.new("Frame")
        page.Name = tab.Id
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.Parent = body
        local pageList = Instance.new("UIListLayout")
        pageList.Padding = UDim.new(0, W.SectionGap)
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Parent = page

        local catalog = config.Catalog[tab.Id]
        local sectionFrames = {}
        if catalog then
            for _, section in ipairs(catalog.Sections) do
                local card = components.Card(page)
                components.SectionHead(card, section.Title, section.Description)
                for _, ctrl in ipairs(section.Controls) do
                    components.Control(card, ctrl)
                end
                sectionFrames[#sectionFrames + 1] = { Frame = card, Section = section }
            end
        end
        pages[tab.Id] = { Frame = page, Catalog = catalog, Sections = sectionFrames, Tab = tab }

        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.BackgroundColor3 = T.Sidebar
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, 0, 0, W.NavItemHeight)
        btn.Parent = nav
        Th.Corner(btn, 8)

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.BorderSizePixel = 0
        accent.BackgroundColor3 = T.Accent
        accent.Size = UDim2.new(0, 2, 0, 20)
        accent.Position = UDim2.new(0, 8, 0.5, 0)
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.Visible = false
        accent.Parent = btn
        Th.Corner(accent, 1)

        Th.Label(btn, {
            Text = tab.Title,
            Font = T.FontMedium,
            Size = 13,
            Height = 18,
            Pos = UDim2.new(0, 22, 0, 10),
            Rect = UDim2.new(1, -28, 0, 18),
        })
        Th.Label(btn, {
            Text = tab.Caption,
            Size = 11,
            Color = T.TextMuted,
            Height = 14,
            Pos = UDim2.new(0, 22, 0, 28),
            Rect = UDim2.new(1, -28, 0, 14),
        })

        btn.MouseButton1Click:Connect(function()
            Dashboard.ShowTab(tab.Id)
        end)
        tabButtons[tab.Id] = btn
    end

    local function refreshVisibility()
        local page = pages[activeTab]
        if not page then
            return
        end
        for _, item in ipairs(page.Sections) do
            item.Frame.Visible = sectionVisible(item.Section)
        end
    end

    function Dashboard.ShowTab(id)
        activeTab = id
        if config.Settings.RememberTab then
            config.Set("Settings.DefaultTab", id)
        end
        for tabId, page in pairs(pages) do
            page.Frame.Visible = tabId == id
        end
        for tabId, btn in pairs(tabButtons) do
            local on = tabId == id
            btn.BackgroundColor3 = on and T.AccentSoft or T.Sidebar
            local mark = btn:FindFirstChild("Accent")
            if mark then
                mark.Visible = on
            end
        end
        local page = pages[id]
        if page and page.Catalog then
            title.Text = page.Catalog.Title
            subtitle.Text = page.Catalog.Description
        end
        refreshVisibility()
        body.CanvasPosition = Vector2.new(0, 0)
    end

    config.Watch("Curve.Mode", function()
        if activeTab == "curve" then
            refreshVisibility()
        end
    end)

    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end
        if input.KeyCode == config.Settings.ToggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    Dashboard.Gui = gui
    Dashboard.Window = window
    Dashboard.ShowTab(activeTab)
    gui.Enabled = config.Settings.OpenOnInject
    return Dashboard
end

return Dashboard
