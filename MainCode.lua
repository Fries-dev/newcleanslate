-- Services & Variables
local CoreGuiRef = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn = gethui or function() return CoreGuiRef end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer

local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer

local zoomKeyActive = false
local thirdPersonActive = false
local cameraDistance = 15

local SETTINGS = {
    Fov = { Enabled = false, Amount = 70, Base = Camera.FieldOfView },
    Zoom = { Enabled = false, Amount = 30, AnimationSpeed = 8 },
    player = { Enabled = false}
}
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostDuckyy/ESP-Library/refs/heads/main/Sense/source.lua'))()
local success, config = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/config.lua'))()
end)

if success and config then
    -- A recursive function to apply the settings automatically
    local function applySettings(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                applySettings(target[k], v)
            else
                target[k] = v
            end
        end
    end

    -- Apply everything from the GitHub config
    applySettings(Sense, config)
else
    warn("Failed to load config from GitHub.")
end

local Library, Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Atlanta/Library.lua"))()
local Window = Library:window({name = "Atlanta | "})

local CombatTab   = Window:tab({name = "Combat"})
local SettingsTab = Window:tab({name = "Settings"})
local FovSec      = CombatTab:section({name = "Fov"})
local AimSec      = CombatTab:section({name = "Fov"})
local ModelSec    = CombatTab:section({name = "Model Transformer"})

-- Functions
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
        if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("Decal") then
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
    default = false,
    callback = function(v) SETTINGS.Fov.Enabled = v end
})

FovSec:slider({
    name = "FOV Amount",   
    flag = "FovChanger_Amount",  
    min = 70, default = 70, max = 120, 
    suffix = " fov", interval = 1, 
    callback = function(v) SETTINGS.Fov.Amount = v end
})

FovSec:toggle({
    name = "Zoom Enabled", 
    flag = "FovZoom_Enabled",    
    default = false, 
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
    min = 10, default = 30, max = 70, 
    suffix = " fov", interval = 1, 
    callback = function(v) SETTINGS.Zoom.Amount = v end
})
AimSec:toggle({
    name = "player Enabled", 
    flag = "player_Enabled",    
    default = false, 
    callback = function(v) 
        SETTINGS.player.Enabled = v
        
        if v then
            -- Safe load
            pcall(function()
                Sense.Load()
            end)
        else
            -- Safe unload (prevents the error if it wasn't loaded yet)
            pcall(function()
                Sense.Unload()
            end)
        end
    end
})


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
                    -- Check if camera is physically in first-person (scrolled all the way in)
                    local isFirstPerson = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 1.5

                    if transformedModel and character and character:FindFirstChild("HumanoidRootPart") then
                        transformedModel:PivotTo(character.HumanoidRootPart.CFrame * CFrame.new(0, verticalOffset, 0))
                        
                        -- Only hide the model if in first person; keep it visible during keybind zoom
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

        -- Directly apply the FieldOfView without breaking the camera projection matrix
        Camera.FieldOfView = displayFov
    end)
end


Library:config_list_update()
CombatTab.open_tab()
Library.old_config = Library:get_config()