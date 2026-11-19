-- Ensure the library and themes are loaded properly
local library, themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/newlib.lua?v=99999"))()

-- 2. Define the game_selector function
function library:game_selector(options)
    local cfg = {
        prefix = options.prefix or "Game",
        suffix = options.suffix or "Hub",
        games = options.games or {},
        callback = options.callback or function(selectedGame) end,
        selected = nil
    }

    local accent_hex = themes.preset.accent:ToHex()
    local sgui = game:GetService("CoreGui"):FindFirstChild("ScreenGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChildOfClass("ScreenGui")
    local currentPlaceId = game.PlaceId
    
    local currentRealName = "Unknown Game"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(currentPlaceId)
        if info and info.Name then
            currentRealName = info.Name
        end
    end)

    local currentGameData = { name = currentRealName, id = currentPlaceId, icon = "rbxassetid://6023426915" }
    local otherGames = {}

    for _, g in ipairs(cfg.games) do
        if g.id == currentPlaceId then
            currentGameData.name = currentRealName
            currentGameData.icon = g.icon or currentGameData.icon
        else
            table.insert(otherGames, g)
        end
    end

    -- Main Window Outer Outline (Properly Centered with AnchorPoint 0.5, 0.5)
    local selector_outline = library:create("Frame", {
        Parent = sgui,
        Name = "GameSelectorAdvanced",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 460, 0, 410),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.outline
    }) 
    library:apply_theme(selector_outline, "outline", "BackgroundColor3")
    library:draggify(selector_outline)

    -- Inline Border
    local selector_inline = library:create("Frame", {
        Parent = selector_outline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    }) 
    library:apply_theme(selector_inline, "inline", "BackgroundColor3")

    -- Background Gradient
    local selector_bg = library:create("Frame", {
        Parent = selector_inline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    })
    local bg_grad = library:create("UIGradient", {
        Parent = selector_bg,
        Rotation = 90,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 41, 55)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 47))
        }
    }) 
    library:apply_theme(bg_grad, "contrast", "Color")

    -- Top Accent Bar
    local top_accent = library:create("Frame", {
        Parent = selector_outline,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(1, -4, 0, 2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent
    }) 
    library:apply_theme(top_accent, "accent", "BackgroundColor3")

    -- Header Title (Pushed down safely to Y:6)
    local title_label = library:create("TextLabel", {
        Parent = selector_bg,
        FontFace = library.font,
        TextColor3 = themes.preset.text,
        Text = string.format('  %s<font color="#%s">%s</font> | Game Hub', cfg.prefix, accent_hex, cfg.suffix),
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12,
        RichText = true
    })
    library:create("UIStroke", { Parent = title_label, LineJoinMode = Enum.LineJoinMode.Miter })

    -- Divider (Y:28)
    local divider = library:create("Frame", {
        Parent = selector_outline,
        Position = UDim2.new(0, 2, 0, 28),
        Size = UDim2.new(1, -4, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    }) 
    library:apply_theme(divider, "inline", "BackgroundColor3")

    -- ==================== CURRENT GAME BANNER (Y:36) ====================
    local banner_outline = library:create("Frame", {
        Parent = selector_bg,
        Position = UDim2.new(0, 10, 0, 36),
        Size = UDim2.new(1, -20, 0, 64),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent
    })
    local banner_inline = library:create("Frame", {
        Parent = banner_outline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    })
    local banner_bg = library:create("Frame", {
        Parent = banner_inline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    })
    local banner_icon = library:create("ImageLabel", {
        Parent = banner_bg,
        Position = UDim2.new(0, 7, 0, 7),
        Size = UDim2.new(0, 48, 0, 48),
        BackgroundTransparency = 1,
        Image = currentGameData.icon
    })

    local banner_tag = library:create("TextLabel", {
        Parent = banner_bg,
        FontFace = library.font,
        TextColor3 = themes.preset.accent,
        Text = "● ACTIVE SESSION",
        Position = UDim2.new(0, 64, 0, 7),
        Size = UDim2.new(1, -72, 0, 16),
        BackgroundTransparency = 1,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    library:create("UIStroke", { Parent = banner_tag, LineJoinMode = Enum.LineJoinMode.Miter })

    local banner_title = library:create("TextLabel", {
        Parent = banner_bg,
        FontFace = library.font,
        TextColor3 = themes.preset.text,
        Text = currentGameData.name,
        Position = UDim2.new(0, 64, 0, 23),
        Size = UDim2.new(1, -72, 0, 32),
        BackgroundTransparency = 1,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    library:create("UIStroke", { Parent = banner_title, LineJoinMode = Enum.LineJoinMode.Miter })

    -- ==================== SEARCH BAR (Y:108) ====================
    local search_outline = library:create("Frame", {
        Parent = selector_bg,
        Position = UDim2.new(0, 10, 0, 108),
        Size = UDim2.new(1, -20, 0, 26),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.outline
    })
    local search_inline = library:create("Frame", {
        Parent = search_outline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    })
    local search_box = library:create("TextBox", {
        Parent = search_inline,
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -12, 1, 0),
        BackgroundTransparency = 1,
        FontFace = library.font,
        TextColor3 = themes.preset.text,
        PlaceholderText = "Search games...",
        PlaceholderColor3 = Color3.fromRGB(130, 130, 130),
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    -- ==================== SCROLLING GRID (Y:142) ====================
    local scroll_frame = library:create("ScrollingFrame", {
        Parent = selector_bg,
        Position = UDim2.new(0, 10, 0, 142),
        Size = UDim2.new(1, -20, 1, -150),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4
    })

    local grid_layout = library:create("UIGridLayout", {
        Parent = scroll_frame,
        CellSize = UDim2.new(0, 130, 0, 115),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local cardFrames = {}

    for _, gameData in ipairs(otherGames) do
        local card_outline = library:create("Frame", {
            Parent = scroll_frame,
            Size = UDim2.new(0, 130, 0, 115),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.outline
        })

        local card_inline = library:create("Frame", {
            Parent = card_outline,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.inline
        })

        local card_btn = library:create("TextButton", {
            Parent = card_inline,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Text = "",
            AutoButtonColor = false
        })

        library:create("UIGradient", {
            Parent = card_btn,
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 41, 55)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 47))
            }
        })

        local icon_img = library:create("ImageLabel", {
            Parent = card_btn,
            Position = UDim2.new(0.5, -24, 0, 6),
            Size = UDim2.new(0, 48, 0, 48),
            BackgroundTransparency = 1,
            Image = gameData.icon or "rbxassetid://6023426915"
        })

        local title_lbl = library:create("TextLabel", {
            Parent = card_btn,
            FontFace = library.font,
            TextColor3 = themes.preset.text,
            Text = gameData.name,
            Position = UDim2.new(0, 4, 0, 58),
            Size = UDim2.new(1, -8, 0, 48),
            BackgroundTransparency = 1,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        library:create("UIStroke", { Parent = title_lbl, LineJoinMode = Enum.LineJoinMode.Miter })

        card_btn.MouseEnter:Connect(function()
            card_outline.BackgroundColor3 = themes.preset.accent
        end)
        card_btn.MouseLeave:Connect(function()
            card_outline.BackgroundColor3 = themes.preset.outline
        end)

        card_btn.MouseButton1Click:Connect(function()
            cfg.selected = gameData
            selector_outline:Destroy()
            cfg.callback(gameData)
        end)

        table.insert(cardFrames, { frame = card_outline, name = string.lower(gameData.name) })
    end

    search_box:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(search_box.Text)
        for _, card in ipairs(cardFrames) do
            if query == "" or string.find(card.name, query) then
                card.frame.Visible = true
            else
                card.frame.Visible = false
            end
        end
    end)

    return cfg
end
library:game_selector({
    prefix = "Game",
    suffix = "Hub",
    games = {
        { name = "BedWars", id = 6872265039, icon = "rbxassetid://6023426915" },
        { name = "Blox Fruits", id = 2753915549, icon = "rbxassetid://9984953245" },
        { name = "Arsenal", id = 286090429, icon = "rbxassetid://6023426915" }
    },
    callback = function(gameData)
        print("Selected game:", gameData.name)

        if gameData.id == 6872265039 then
            print("Running BedWars script features...")
            
            -- Safely fetch the code from the URL
            local success, body = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/universal.lua")
            end)
            
            if success and body then
                -- Try to compile the downloaded code into a function
                local fn, syntaxErr = loadstring(body)
                if fn then
                    fn() -- Run the script successfully
                else
                    warn("Syntax error in external script:", syntaxErr)
                end
            else
                warn("Failed to HTTP Get the script URL:", body)
            end
            
        elseif gameData.id == 2753915549 then
            print("Running Blox Fruits script features...")
            
        elseif gameData.name == "Arsenal" then
            print("Running Arsenal script features...")
        end
    end
})