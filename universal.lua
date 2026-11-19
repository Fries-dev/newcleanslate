local CoreGuiRef = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn = gethui or function() return CoreGuiRef end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer
local target = nil
local dim2 = UDim2.new
local hex = Color3.fromHex 
local LocalPlayer = Players.LocalPlayer

local zoomKeyActive = false

local SETTINGS = {
    Fov = { Enabled = false, Amount = 70, Base = Camera.FieldOfView },
    Zoom = { Enabled = false, Amount = 30, AnimationSpeed = 8 },
    player = { Enabled = false }
}

-- Load Sense ESP Library
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostDuckyy/ESP-Library/refs/heads/main/Sense/source.lua'))()

-- Load Remote Config from GitHub and apply directly to Sense & SETTINGS
local success, config = pcall(function()
    local chunk, err = loadstring(game:HttpGet('https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/MainProp.lua'))
    if not chunk then error(err) end
    return chunk()
end)
local SoundService = game:GetService("SoundService")


if success and type(config) == "table" then
    local function applySettings(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                applySettings(target[k], v)
            else
                target[k] = v
            end
        end
    end

    applySettings(Sense, config)
    applySettings(SETTINGS, config)
    print("Config applied successfully to Sense and SETTINGS!")
else
    warn("Failed to load config from GitHub. Error: ", config)
end

-- Try downloading the library with detailed error tracking
local success, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/newlib.lua?v=9999999")
end)

-- Check if the HTTP request failed completely
if not success then
    warn("[Loader Error] Failed to connect to GitHub. Check your internet connection or URL.")
    return
end

-- Check if GitHub returned a 404 Not Found page
if response == "404: Not Found" or response:sub(1, 9) == "Not Found" then
    warn("[Loader Error] newlib.lua was not found (404). Check the branch name and repository path.")
    return
end

-- Compile the downloaded string into a Lua chunk
local libChunk, compileErr = loadstring(response)
if not libChunk then
    warn("[Loader Error] Syntax error detected in newlib.lua:\n" .. tostring(compileErr))
    return
end

-- Safely execute the library chunk
local runSuccess, library, themes = pcall(libChunk)
if not runSuccess then
    warn("[Loader Error] Runtime error while initializing newlib.lua:\n" .. tostring(library))
    return
end

-- Success! Proceed with your script
local hub_name = "LizardWare"
local suffix_name = " "
print("[Loader] newlib.lua loaded successfully!")

-- 1. Run the login window and capture the role
local success, userRole = library:login_window({
    prefix = hub_name,
    suffix = suffix_name,
    credentials = {
        ["admin"] = "ether2026",
        ["lizard"] = "1",
        ["dev"] = "3"
    }
})

-- 2. Define role text and color based on who logged in
local watermark_role = (userRole == "dev") and "Developer" or "Customer"
local role_color_hex = (userRole == "dev") and "00FF7F" or "6b6a85" -- Green for dev, White for customer

-- 3. Create your custom watermark
local watermark = library:custom_watermark({
    script_name = hub_name,
    suffix = suffix_name,
    role = watermark_role,
    role_color = role_color_hex,
    position = dim2(0.5, -100, 0, 100) -- Use dim2 if your library uses custom UDim2 wrappers
})

-- 4. Open your main window
local window = library:window({
    name = hub_name .. " | - Nov 18 2026",
    size = dim2(0, 600, 0, 450)
})
local frames = 0
local lastTime = tick()
local fps = 60
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastTime >= 1 then
        fps = math.round(frames / (now - lastTime))
        frames = 0
        lastTime = now
    end

    local ping = 0
    pcall(function()
        ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
    end)

    local currentTime = os.date("%H:%M:%S")
    local coloredRole = string.format('<font color="#%s">%s</font>', role_color_hex, watermark_role)

    watermark.change_info(string.format(
        "%s | %d fps | %dms | %s | %s",
        LocalPlayer.Name,
        fps,
        ping,
        coloredRole,
        currentTime
    ))
end)


local Aiming = window:tab({name = "Aiming"})
local Visuals = window:tab({name = "Visuals"})
local Misc = window:tab({name = "Misc"})

do
    local column = Aiming:column() 
    local selec, lock = column:multi_section({names = {"Selection", "Lock"}})
    
    selec:toggle({
        name = "Player Enabled", 
        flag = "player_Enabled", 
        default = SETTINGS.player.Enabled, 
        value = SETTINGS.player.Enabled, 
        callback = function(v) 
        
            SETTINGS.player.Enabled = v
            if Sense.teamSettings and Sense.teamSettings.enemy then
                Sense.teamSettings.enemy.enabled = v
                Sense.teamSettings.enemy.box = v
            end
            if v then
                pcall(function() Sense.Load() end)
            else
                pcall(function() Sense.Unload() end)
            end
        end
    })
    
    selec:toggle({
        name = "Global Outlines", 
        flag = "Global_Outlines", 
        default = true, 
        value = true, 
        callback = function(state)
            if Sense.teamSettings and Sense.teamSettings.enemy then
                for key, _ in pairs(Sense.teamSettings.enemy) do
                    if key:lower():find("outline") and type(Sense.teamSettings.enemy[key]) == "boolean" then
                        Sense.teamSettings.enemy[key] = state
                    end
                end
            end
        end
    })
    local FovSec = selec
    FovSec:toggle({name = "FOV Changer", flag = "FovChanger_Enabled", value = SETTINGS.Fov.Enabled, callback = function(v) SETTINGS.Fov.Enabled = v end})
    FovSec:slider({name = "FOV Amount", min = 70, max = 120, default = SETTINGS.Fov.Amount, interval = 1, suffix = " fov", flag = "FovChanger_Amount", callback = function(v) SETTINGS.Fov.Amount = v end})
    
    FovSec:toggle({name = "Zoom Enabled", flag = "FovZoom_Enabled", value = SETTINGS.Zoom.Enabled, callback = function(v) SETTINGS.Zoom.Enabled = v end}):keybind({
        name = "Zoom Key",
        flag = "FovZoom_Key",
        key = Enum.KeyCode.Z,
        mode = "hold",
        callback = function(active) zoomKeyActive = active end
    })
    FovSec:slider({name = "Zoom Amount", min = 10, max = 70, default = SETTINGS.Zoom.Amount, interval = 1, suffix = " fov", flag = "FovZoom_Amount", callback = function(v) SETTINGS.Zoom.Amount = v end})
end




-- Example: Toggle with audio
Misc:toggle({
    name = "Speed Boost",
    flag = "speed_toggle",
    default = false,
    callback = function(state)
        
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = state and 50 or 16
        end
    end
})
-- Spin Player Variables
local spinning = false
local spinConnection = nil
local spinSpeed = 10


-- 2. Spin Speed Slider
Misc:slider({
    name = "Spin Speed",
    flag = "spin_speed",
    min = 1,
    max = 50,
    default = 10,
    callback = function(value)
        spinSpeed = value
    end
})

-- 3. Main Spin Toggle
Misc:toggle({
    name = "Spin Player",
    flag = "spin_toggle",
    callback = function(state)
        spinning = state
        
        if spinning then
            spinConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local character = game:GetService("Players").LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    
                    if isLocalMode then
                        -- For a true client-side visual effect without network replication,
                        -- you can manipulate local joints or visual orientation. 
                        -- (Note: Direct CFrame changes on RootPart will always replicate due to network ownership).
                        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                    else
                        -- Server-replicated spin logic
                        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                    end
                end
            end)
        else
            if spinConnection then
                spinConnection:Disconnect()
                spinConnection = nil
            end
        end
    end
})
-- Visuals Tab Setup (Dynamic ESP Settings & Model Transformer)
do
    local column = Visuals:column()
    local section = column:section({name = "ESP Settings", toggle = false})
    
    if Sense.teamSettings and Sense.teamSettings.enemy then
        for key, value in pairs(Sense.teamSettings.enemy) do
            if not key:lower():find("outline") and key ~= "enabled" and key ~= "box" then
                local displayName = key:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)
                if type(value) == "boolean" then
                    section:toggle({
                        name = displayName,
                        flag = "Enemy_" .. key,
                        value = value,
                        callback = function(v)
                            Sense.teamSettings.enemy[key] = v
                        end
                    })
                elseif type(value) == "number" then
                    section:slider({
                        name = displayName,
                        min = 0,
                        max = 1000,
                        default = value,
                        interval = 1,
                        flag = "Enemy_" .. key,
                        callback = function(v)
                            Sense.teamSettings.enemy[key] = v
                        end
                    })
                elseif type(value) == "table" and typeof(value[1]) == "Color3" then
                    pcall(function()
                        local lbl = section:label({name = displayName})
                        lbl:colorpicker({
                            flag = "Enemy_" .. key,
                            color = value[1],
                            alpha = value[2],
                            callback = function(newColor, newAlpha)
                                Sense.teamSettings.enemy[key][1] = newColor
                                if newAlpha ~= nil then Sense.teamSettings.enemy[key][2] = newAlpha end
                            end
                        })
                    end)
                end
            end
        end
    end
    -- Model Transformer Section
        local modelSec = column:section({name = "Model Transformer", toggle = false})
        local transformedModel = nil
        local modelConnection = nil
        local originalTransparencies = {}

        -- Table of different models to choose from (Add or change models here anytime!)
        local modelList = {
            ["Model Option 1"] = "rbxassetid://138151705692565",
            ["Model Option 2"] = "rbxassetid://112586636995159", -- Replace with your second asset ID
            ["Model Option 3"] = "rbxassetid://5692499843", -- Replace with your third asset ID
        }
        -- Helper function to automatically extract names for the dropdown
            local function getModelNames()
                local names = {}
                for name, _ in pairs(modelList) do -- FIXED: Added "in" here!
                    table.insert(names, name)
                end
                return names
            end

            local selectedAssetId = modelList[getModelNames()[1]] or "rbxassetid://138151705692565"

            -- Dropdown to select the model (Automatically populates from your table)
            local modelDropdown = modelSec:dropdown({
                name = "Select Model",
                flag = "ModelTransformer_Selection",
                items = getModelNames(),
                default = getModelNames()[1],
                callback = function(selectedName)
                    if modelList[selectedName] then
                        selectedAssetId = modelList[selectedName]
                    end
                end
            })

            -- Function you can call anywhere in your script to instantly auto-update the dropdown list if you add new models later
            local function refreshModelList()
                local newNames = getModelNames()
                if modelDropdown and modelDropdown.refresh_options then
                    modelDropdown:refresh_options(newNames)
                end
            end

            modelSec:toggle({
                name = "Transform into Model",
                flag = "ModelTransformer_Enabled",
                value = false,
                callback = function(enabled)
                    if modelConnection then modelConnection:Disconnect(); modelConnection = nil end
                    if transformedModel then transformedModel:Destroy(); transformedModel = nil end
                    table.clear(originalTransparencies)

                    if not enabled then return end

                    local character = Client.Character
                    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

                    local success, objects = pcall(function()
                        return game:GetObjects(selectedAssetId)
                    end)

                    if success and objects and #objects > 0 then
                        local rawAsset = objects[1]
                        if rawAsset:IsA("Model") then
                            transformedModel = rawAsset
                        elseif rawAsset:IsA("Folder") then
                            transformedModel = Instance.new("Model")
                            transformedModel.Name = "CustomPlayerModel"
                            for _, child in ipairs(rawAsset:GetChildren()) do child.Parent = transformedModel end
                        elseif rawAsset:IsA("BasePart") then
                            transformedModel = Instance.new("Model")
                            transformedModel.Name = "CustomPlayerModel"
                            rawAsset.Parent = transformedModel
                            transformedModel.PrimaryPart = rawAsset
                        end

                        if transformedModel then
                            transformedModel.Name = "CustomPlayerModel"
                            transformedModel:PivotTo(character.HumanoidRootPart.CFrame)
                            transformedModel.Parent = Workspace

                            local rootPart = transformedModel.PrimaryPart or transformedModel:FindFirstChildWhichIsA("BasePart")
                            for _, part in ipairs(transformedModel:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    -- ANCHORED = true so the model stays completely rigid and doesn't fall/flop
                                    part.Anchored = true
                                    part.CanCollide = false
                                    originalTransparencies[part] = part.Transparency
                                end
                            end

                            for _, item in ipairs(character:GetDescendants()) do
                                if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
                                    item.Transparency = 1
                                elseif item:IsA("Decal") then
                                    item.Transparency = 1
                                end
                            end

                            -- Persistent tracking loop to keep it locked to your character smoothly
                            modelConnection = RunService.RenderStepped:Connect(function()
                                if not transformedModel or not transformedModel.Parent then return end
                                local isFirstPerson = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 1.5
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    transformedModel:PivotTo(character.HumanoidRootPart.CFrame * CFrame.new(0, -0.5, 0))
                                    for part, origTrans in pairs(originalTransparencies) do
                                        if part and part.Parent then
                                            part.Transparency = isFirstPerson and 1 or origTrans
                                            part.LocalTransparencyModifier = isFirstPerson and 1 or 0
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            })
    end
-- FOV & Zoom Render Loop
do
    local baseFov = Camera.FieldOfView
    SETTINGS.Fov.Base = baseFov
    local displayFov = baseFov

    RunService.RenderStepped:Connect(function(dt)
        local zoomOn = SETTINGS.Zoom.Enabled and zoomKeyActive
        local fovOn = SETTINGS.Fov.Enabled

        if not zoomOn and not fovOn then
            if math.abs(displayFov - baseFov) < 0.5 then
                baseFov = Camera.FieldOfView
                displayFov = baseFov
                SETTINGS.Fov.Base = baseFov
                return
            end
        end

        local targetFov = zoomOn and SETTINGS.Zoom.Amount or (fovOn and SETTINGS.Fov.Amount or baseFov)
        local animSpeed = SETTINGS.Zoom.AnimationSpeed or 8
        displayFov = displayFov + (targetFov - displayFov) * math.min(dt * animSpeed, 1)

        Camera.FieldOfView = displayFov
    end)
end


-- Initialisation stuff
library:config_list_update()

for index, value in themes.preset do 
    pcall(function()
        library:update_theme(index, value)
    end)
end

task.wait()

Aiming.open_tab() 
library.old_config = library:get_config()