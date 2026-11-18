local CoreGuiRef    = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn      = gethui or function() return CoreGuiRef end
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService  = game:GetService("SoundService")
local Debris        = game:GetService("Debris")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local Camera        = Workspace.CurrentCamera
local Client        = Players.LocalPlayer
local RAY_FILTER_EXCLUDE = Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist

local SETTINGS
local function CreateUndetectedGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = " "
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = gethuiFn()
    return gui
end
local Library, Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Atlanta/Library.lua"))()
local flags = Library.flags

local Window = Library:window({name = "Atlanta | "})

local CombatTab   = Window:tab({name = "Combat"})
local SettingsTab = Window:tab({name = "Settings"})
local FovSec = CombatTab:section({name = "Fov"})

local zoomKeyActive = false

local SETTINGS = {
    Fov = { Enabled = false, Amount = 100, Base = Camera.FieldOfView },
    Zoom = { Enabled = false, Amount = 30, AnimationSpeed = 8 }
}

-- FOV Changer Toggle & Slider
FovSec:toggle({
    name = "FOV Changer",  
    flag = "FovChanger_Enabled", 
    default = false,
    callback = function(v)
        SETTINGS.Fov.Enabled = v
    end
})

FovSec:slider({
    name = "FOV Amount",   
    flag = "FovChanger_Amount",  
    min = 70, 
    default = 100, 
    max = 120, 
    suffix = " fov", 
    interval = 1, 
    callback = function(v) 
        SETTINGS.Fov.Amount = v 
    end
})

-- Zoom Toggle with Keybind attached
FovSec:toggle({
    name = "Zoom Enabled", 
    flag = "FovZoom_Enabled",    
    default = false, 
    callback = function(v) 
        SETTINGS.Zoom.Enabled = v 
    end
}):keybind({
    flag = "FovZoom_Key",
    name = "Zoom Key",
    key = Enum.KeyCode.Z,
    mode = "hold", -- Change to "toggle" if you prefer pressing it once to stay zoomed
    callback = function(active)
        zoomKeyActive = active -- Updates instantly when you press/hold the key!
    end
})

FovSec:slider({
    name = "Zoom Amount",   
    flag = "FovZoom_Amount",  
    min = 10, 
    default = 30, 
    max = 70, 
    suffix = " fov", 
    interval = 1, 
    callback = function(v) 
        SETTINGS.Zoom.Amount = v 
    end
})
FovSec:slider({
    name = "Zoom Amount",   
    flag = "FovZoom_Amount",  
    min = 10, 
    default = 30, 
    max = 70, 
    suffix = " fov", 
    interval = 1, 
    callback = function(v) 
        SETTINGS.Zoom.Amount = v 
    end
})
local ModelSec = CombatTab:section({name = "Model Transformer"})

local transformedModel = nil
local modelConnection = nil
local savedAccessories = {}

local function restoreCharacter(character)
    if modelConnection then
        modelConnection:Disconnect()
        modelConnection = nil
    end

    if transformedModel then
        transformedModel:Destroy()
        transformedModel = nil
    end

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

        -- Clean up any existing state before applying
        restoreCharacter(character)

        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://138151705692565")
        end)

        if success and objects and #objects > 0 then
            local rawAsset = objects[1]
            
            -- Handle different asset formats (Model, Folder, or single Part/MeshPart)
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
                -- Fallback: try to find any model or basepart inside
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

                        if rootPart and part ~= rootPart then
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = rootPart
                            weld.Part1 = part
                            weld.Parent = part
                        end
                    end
                end

                -- Hide original character parts and temporarily store accessories
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
                    if transformedModel and character and character:FindFirstChild("HumanoidRootPart") then
                        transformedModel:PivotTo(character.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0))
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

do
    local baseFov = Camera.FieldOfView
    SETTINGS.Fov.Base = baseFov
    local displayFov = baseFov

    RunService.RenderStepped:Connect(function(dt)
        local zoomOn = SETTINGS.Zoom.Enabled and zoomKeyActive
        local fovOn = SETTINGS.Fov.Enabled

        if (not zoomOn) and (not fovOn) then
            if math.abs(displayFov - baseFov) < 0.5 then
                baseFov = Camera.FieldOfView
                displayFov = baseFov
                SETTINGS.Fov.Base = baseFov
                return
            end
        end

        local targetFov = baseFov
        if zoomOn then 
            targetFov = SETTINGS.Zoom.Amount
        elseif fovOn then 
            targetFov = SETTINGS.Fov.Amount 
        end

        local animSpeed = SETTINGS.Zoom.AnimationSpeed or 8
        displayFov = displayFov + (targetFov - displayFov) * math.min(dt * animSpeed, 1)

        if displayFov <= 80 then
            Camera.FieldOfView = displayFov
        else
            Camera.FieldOfView = baseFov
            local scale = math.tan(math.rad(baseFov * 0.5)) / math.tan(math.rad(displayFov * 0.5))
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, scale, 0, 0, 0, scale, 0, 0, 0, 1)
        end
    end)
end

Library:config_list_update()
CombatTab.open_tab()
Library.old_config = Library:get_config()