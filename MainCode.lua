-- Services & Variables
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
    player = { Enabled = false },
    silent = { Enabled = false },
    wallbang = { Enabled = false }
}

-- Load Sense ESP Library
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostDuckyy/ESP-Library/refs/heads/main/Sense/source.lua'))()

-- Load Remote Config from GitHub and apply directly to Sense & SETTINGS
local success, config = pcall(function()
    local chunk, err = loadstring(game:HttpGet('https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/MainProp.lua'))
    if not chunk then error(err) end
    return chunk()
end)

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

-- Load UI Library
local library, themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Fries-dev/newcleanslate/refs/heads/main/newlib.lua"))()

local window = library:window({name = os.date('Atlanta |  - %b %d %Y'), size = dim2(0, 750, 0, 782)})

local Aiming = window:tab({name = "Aiming"})
local Visuals = window:tab({name = "Visuals"})
local Misc = window:tab({name = "Misc"})
local watermark = library:custom_watermark({
    title = 'name<font color="#55aaff">client</font>',
    info = "loading...",
    position = UDim2.new(0, 20, 0, 20)
})

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
    selec:toggle({
        name = "Silent aim", 
        flag = "Silent_aim", 
        default = false, 
        value = false, 
        callback = function(v) 
            SETTINGS.silent.Enabled = v 
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

    watermark.change_info(string.format(
        "%s | %d fps | %dms | %d/%d",
        LocalPlayer.Name,
        fps,
        ping,
        #Players:GetPlayers(),
        Players.MaxPlayers
    ))
end)
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
    local savedAccessories = {}
    local originalTransparencies = {}

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
                return game:GetObjects("rbxassetid://138151705692565")
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
                            part.Anchored = false
                            part.CanCollide = false
                            originalTransparencies[part] = part.Transparency
                            if rootPart and part ~= rootPart then
                                local weld = Instance.new("WeldConstraint")
                                weld.Part0 = rootPart
                                weld.Part1 = part
                                weld.Parent = part
                            end
                        end
                    end

                    for _, item in ipairs(character:GetDescendants()) do
                        if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
                            item.Transparency = 1
                        elseif item:IsA("Decal") then
                            item.Transparency = 1
                        elseif item:IsA("Accessory") then
                            table.insert(savedAccessories, item)
                            item.Parent = nil
                        end
                    end

                    modelConnection = RunService.RenderStepped:Connect(function()
                        local isFirstPerson = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 1.5
                        if transformedModel and character and character:FindFirstChild("HumanoidRootPart") then
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
