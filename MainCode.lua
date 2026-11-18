-- Services & Variables
local CoreGuiRef = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn = gethui or function() return CoreGuiRef end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer

local zoomKeyActive = false
local thirdPersonActive = false
local cameraDistance = 15

local SETTINGS = {
    Fov = { Enabled = false, Amount = 70, Base = Camera.FieldOfView },
    Zoom = { Enabled = false, Amount = 30, AnimationSpeed = 8 },
    player = { Enabled = false },
    teamSettings = {
        enemy = {
            enabled = true,
            box = true,
            boxColor = { Color3.new(1, 0, 0), 1 },
            boxOutline = true,
            boxOutlineColor = { Color3.new(0, 0, 0), 1 },
            boxFill = true,
            boxFillColor = { Color3.new(1, 0, 0), 0.5 },
            healthBar = true,
            healthBarOutline = true,
            name = true,
            nameOutline = true,
            tracer = false,
            tracerOutline = false,
            weapon = false,
            weaponOutline = false,
            chams = false,
            chamsOutline = false,
            distance = false,
            distanceOutline = false,
        }
    }
}

-- Load Sense ESP Library
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostDuckyy/ESP-Library/refs/heads/main/Sense/source.lua'))()

-- Load Remote Config from GitHub
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

    applySettings(SETTINGS, config)
    applySettings(Sense, config)
    print("Config applied successfully to SETTINGS and Sense!")
else
    warn("Failed to load config from GitHub. Error: ", config)
end

-- Load UI Library
local Library, Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Atlanta/Library.lua"))()
local Window = Library:window({name = "Atlanta | "})

local CombatTab   = Window:tab({name = "Combat"})
local SettingsTab = Window:tab({name = "Settings"})
local FovSec      = CombatTab:section({name = "Fov"})
local AimSec      = CombatTab:section({name = "Combat Settings"})
local EspSec      = CombatTab:section({name = "ESP Settings"})
local ModelSec    = CombatTab:section({name = "Model Transformer"})

-- Model Transformer Functions
local transformedModel = nil
local modelConnection = nil
local savedAccessories = {}
local originalTransparencies = {}

local function restoreCharacter(character)
    if modelConnection then
        modelConnection:Disconnect()
        modelConnection = nil
    end

    if transformedModel then
        transformedModel:Destroy()
        transformedModel = nil
    end

    table.clear(originalTransparencies)

    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end

    for _, acc in ipairs(savedAccessories) do
        if acc then
            acc.Parent = character
        end
    end
    table.clear(savedAccessories)
end

-- UI Elements: FOV & Zoom
FovSec:toggle({
    name = "FOV Changer",  
    flag = "FovChanger_Enabled", 
    default = SETTINGS.Fov.Enabled, 
    callback = function(v) SETTINGS.Fov.Enabled = v end
})

FovSec:slider({
    name = "FOV Amount",   
    flag = "FovChanger_Amount",  
    min = 70, 
    default = SETTINGS.Fov.Amount, 
    max = 120, 
    suffix = " fov", 
    interval = 1, 
    callback = function(v) SETTINGS.Fov.Amount = v end
})

FovSec:toggle({
    name = "Zoom Enabled", 
    flag = "FovZoom_Enabled",    
    default = SETTINGS.Zoom.Enabled, 
    callback = function(v) SETTINGS.Zoom.Enabled = v end
}):keybind({
    flag = "FovZoom_Key",
    name = "Zoom Key",
    key = Enum.KeyCode.Z,
    mode = "hold",
    callback = function(active) zoomKeyActive = active end
})

FovSec:slider({
    name = "Zoom Amount",   
    flag = "FovZoom_Amount",  
    min = 10, 
    default = SETTINGS.Zoom.Amount, 
    max = 70, 
    suffix = " fov", 
    interval = 1, 
    callback = function(v) SETTINGS.Zoom.Amount = v end
})

-- Player Enabled Toggle
AimSec:toggle({
    name = "player Enabled", 
    flag = "player_Enabled",    
    default = SETTINGS.player.Enabled, 
    callback = function(v) 
        SETTINGS.player.Enabled = v
        if v then
            pcall(function() Sense.Load() end)
        else
            pcall(function() Sense.Unload() end)
        end
    end
})

-- Master Global Outline Toggle
EspSec:toggle({
    name = "Global Outlines",
    flag = "Global_Outlines",
    default = true,
    callback = function(state)
        for key, _ in pairs(SETTINGS.teamSettings.enemy) do
            -- Find any setting that contains "Outline" but isn't a color table
            if key:lower():find("outline") and type(SETTINGS.teamSettings.enemy[key]) == "boolean" then
                SETTINGS.teamSettings.enemy[key] = state
                if Sense.teamSettings and Sense.teamSettings.enemy then
                    Sense.teamSettings.enemy[key] = state
                end
            end
        end
    end
})

-- Helper function to build UI controls (toggles, sliders, and colorpickers)
local function BuildTeamUI(section, teamName, teamTable, senseTable)
    for key, value in pairs(teamTable) do
        local flagName = teamName .. "_" .. key
        local displayName = key:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)

        if type(value) == "boolean" then
            section:toggle({
                name = displayName,
                flag = flagName,
                default = value,
                callback = function(v)
                    teamTable[key] = v
                    if senseTable then senseTable[key] = v end
                end
            })
        elseif type(value) == "number" then
            section:slider({
                name = displayName,
                flag = flagName,
                min = 0,
                default = value,
                max = 1000, 
                interval = 1,
                callback = function(v)
                    teamTable[key] = v
                    if senseTable then senseTable[key] = v end
                end
            })
        elseif type(value) == "table" and typeof(value[1]) == "Color3" then
            pcall(function()
                local labelObj = section:label({ name = displayName })
                labelObj:colorpicker({
                    name = displayName,
                    flag = flagName,
                    color = value[1],
                    alpha = value[2],
                    callback = function(newColor, newAlpha)
                        teamTable[key][1] = newColor
                        if newAlpha ~= nil then teamTable[key][2] = newAlpha end
                        if senseTable and senseTable[key] then
                            senseTable[key][1] = newColor
                            if newAlpha ~= nil then senseTable[key][2] = newAlpha end
                        end
                    end
                })
            end)
        end
    end
end

-- Build UI for Enemy ESP and pass Sense's table to sync updates
BuildTeamUI(EspSec, "Enemy", SETTINGS.teamSettings.enemy, Sense.teamSettings.enemy)

-- Model Transformer Toggle
ModelSec:toggle({
    name = "Transform into Model",
    flag = "ModelTransformer_Enabled",
    default = false,
    callback = function(enabled)
        local character = Client.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        if not enabled then
            restoreCharacter(character)
            return
        end

        restoreCharacter(character)

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
                for _, child in ipairs(rawAsset:GetChildren()) do
                    child.Parent = transformedModel
                end
            elseif rawAsset:IsA("BasePart") then
                transformedModel = Instance.new("Model")
                transformedModel.Name = "CustomPlayerModel"
                rawAsset.Parent = transformedModel
                transformedModel.PrimaryPart = rawAsset
            else
                transformedModel = rawAsset:FindFirstChildWhichIsA("Model")
                if not transformedModel then
                    local part = rawAsset:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        transformedModel = Instance.new("Model")
                        transformedModel.Name = "CustomPlayerModel"
                        part.Parent = transformedModel
                        transformedModel.PrimaryPart = part
                    end
                end
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

                local verticalOffset = -0.5

                modelConnection = RunService.RenderStepped:Connect(function()
                    local isFirstPerson = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 1.5

                    if transformedModel and character and character:FindFirstChild("HumanoidRootPart") then
                        transformedModel:PivotTo(character.HumanoidRootPart.CFrame * CFrame.new(0, verticalOffset, 0))
                        
                        for part, origTrans in pairs(originalTransparencies) do
                            if part and part.Parent then
                                if isFirstPerson then
                                    part.Transparency = 1
                                    part.LocalTransparencyModifier = 1
                                else
                                    part.Transparency = origTrans
                                    part.LocalTransparencyModifier = 0
                                end
                            end
                        end
                    else
                        restoreCharacter(character)
                    end
                end)
            else
                warn("Could not convert loaded asset into a valid transformable model.")
            end
        else
            warn("Failed to fetch asset 138151705692565 via GetObjects.")
        end
    end
})

-- Render Loop for FOV/Zoom
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

Library:config_list_update()
CombatTab.open_tab()
Library.old_config = Library:get_config()