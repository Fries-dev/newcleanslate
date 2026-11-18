-- Services & References
local CoreGuiRef       = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn         = gethui or function() return CoreGuiRef end
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local Client = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = Client:GetMouse()

-- UI Library Setup
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostDuckyy/esp-Library/refs/heads/main/Sense/source.lua'))()

Sense.teamSettings.enemy.enabled = true
Sense.teamSettings.enemy.box = true
Sense.teamSettings.enemy.boxColor[1] = Color3.new(0, 0.25, 0.75)
-- Library Initialization
local Library, Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Atlanta/Library.lua"))()
local flags = Library.flags

local Window = Library:window({name = "Atlanta | "})

local CombatTab   = Window:tab({name = "Combat"})
local FovSec      = CombatTab:section({name = "Fov"})
local CameraSec   = CombatTab:section({name = "Camera"})
local AimSec      = CombatTab:section({name = "Aim"})
local function isEnemy(player)
    if not Client.Team or not player.Team then
        return false
    end

    return player.Team ~= Client.Team
end



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
local zoomKeyActive = false
local thirdPersonActive = false
local cameraDistance = 15
local rightClickAiming = false

local SETTINGS = {
    Fov = { Enabled = false, Amount = 100, Base = Camera.FieldOfView },
    Zoom = { Enabled = false, Amount = 30, AnimationSpeed = 8 },
    player = { Enabled = false},
    Aimlock = { Enabled = false, FOV = 150, Distance = 500, Smoothing = 5 }
}
-- Create the FOV Circle using the Drawing library
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = SETTINGS.Aimlock.FOV
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 0.7

-- Helper function to find a valid target player within the FOV
local function getTargetInFOV()
    local viewportSize = Camera.ViewportSize
    local screenCenter = viewportSize / 2
    local closestTarget = nil
    local shortestDist = SETTINGS.Aimlock.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Client and isEnemy(player) then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 and targetPart then
                    local screenPoint, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                    if onScreen then
                        local targetPos2D = Vector2.new(screenPoint.X, screenPoint.Y)
                        local distFromCenter = (targetPos2D - screenCenter).Magnitude

                        if distFromCenter <= shortestDist then
                            shortestDist = distFromCenter
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Render loop for FOV circle updates and aiming logic
RunService:BindToRenderStep("FOVAimlock", Enum.RenderPriority.Camera.Value + 1, function()
    local viewportSize = Camera.ViewportSize
    fovCircle.Position = viewportSize / 2
    fovCircle.Radius = SETTINGS.Aimlock.FOV
    

    if not SETTINGS.Aimlock.Enabled or not rightClickAiming then return end

    local targetPart = getTargetInFOV()
    if targetPart then
        local currentPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.new(currentPos, targetPart.Position)
    end
end)

-- UI Components setup
FovSec:toggle({
    name = "Aimlock Enabled", 
    flag = "Aimlock_Enabled",    
    default = false, 
    callback = function(v) 
        SETTINGS.Aimlock.Enabled = v 
    end
})

FovSec:slider({
    name = "FOV Radius",   
    flag = "Aimlock_FOV",  
    min = 50, 
    default = 150, 
    max = 400, 
    suffix = " px", 
    interval = 1, 
    callback = function(v) 
        SETTINGS.Aimlock.FOV = v 
    end
})
-- ==========================================
-- FOV & ZOOM CONTROLS
-- ==========================================
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
    mode = "toggle",
    callback = function(active)
        zoomKeyActive = active
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
AimSec:slider({
    name = "Aim Distance",
    flag = "Aimlock_Distance",
    min = 50,
    default = 500,
    max = 2000,
    suffix = " studs",
    interval = 10,
    callback = function(v)
        SETTINGS.Aimlock.Distance = v
    end
})

AimSec:slider({
    name = "Aim Smoothing",
    flag = "Aimlock_Smoothing",
    min = 1,
    default = 5,
    max = 20,
    suffix = "",
    interval = 1,
    callback = function(v)
        SETTINGS.Aimlock.Smoothing = v
    end
})
-- ==========================================
-- MODEL TRANSFORMER + 3RD PERSON INTEGRATION
-- ==========================================
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
    table.clear(savedAccessories)

    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
            part.LocalTransparencyModifier = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end
end

local function applyCustomModel(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
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

            -- Hide original Roblox avatar parts & accessories without unparenting them
            for _, item in ipairs(character:GetDescendants()) do
                if item:IsA("BasePart") then
                    item.Transparency = 1
                    item.LocalTransparencyModifier = 1
                elseif item:IsA("Decal") then
                    item.Transparency = 1
                end
            end

            local verticalOffset = -0.5

            modelConnection = RunService.RenderStepped:Connect(function()
                local isFirstPerson = (not thirdPersonActive) and ((Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 1.5)

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
        end
    end
end
local function SmoothAim(targetPart, dt)
    if not targetPart or not targetPart.Parent then
        return
    end

    local smoothing = math.clamp(SETTINGS.Aimlock.Smoothing, 1, 20)
    local cameraPosition = Camera.CFrame.Position

    local targetCFrame = CFrame.lookAt(
        cameraPosition,
        targetPart.Position
    )

    local alpha = 1 - math.exp(-smoothing * dt)

    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
end
local function SmoothCameraTo(targetPart, smoothing, dt)
    if not targetPart or not targetPart.Parent then
        return
    end

    smoothing = math.max(smoothing, 1)

    local cameraPosition = Camera.CFrame.Position
    local targetPosition = targetPart.Position

    local targetCFrame = CFrame.lookAt(cameraPosition, targetPosition)

    local alpha = 1 - math.exp(-smoothing * dt)

    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
end
-- Toggle & Keybind for 3rd Person + Automatic Model Transformation
local function setThirdPersonState(active)
    thirdPersonActive = active
    local character = Client.Character
    if active then
        applyCustomModel(character)
    else
        restoreCharacter(character)
    end
end

CameraSec:toggle({
    name = "Custom 3rd Person", 
    flag = "Custom3rdPerson_Enabled",    
    default = false, 
    callback = function(v) 
        setThirdPersonState(v)
    end
}):keybind({
    flag = "Custom3rdPerson_Key",
    name = "3rd Person Key",
    key = Enum.KeyCode.X,
    mode = "toggle",
    callback = function(active)
        setThirdPersonState(active)
    end
})

CameraSec:slider({
    name = "3rd Person Distance",   
    flag = "Custom3rdPerson_Dist",  
    min = 5, 
    default = 15, 
    max = 30, 
    suffix = " studs", 
    interval = 1, 
    callback = function(v) 
        cameraDistance = v 
    end
})

-- Right-Click Aim Listeners
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickAiming = false
    end
end)

-- Re-apply model automatically upon respawning while 3rd person is active
Client.CharacterAdded:Connect(function(newCharacter)
    if thirdPersonActive then
        newCharacter:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.1)
        applyCustomModel(newCharacter)
    end
end)

local function getTargetPlayerPart(mouseTarget)
    if not mouseTarget then return nil end

    local model = mouseTarget:FindFirstAncestorOfClass("Model")
    if model and model ~= Client.Character then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local targetPlayer = Players:GetPlayerFromCharacter(model)

        if targetPlayer and isEnemy(targetPlayer) and humanoid and humanoid.Health > 0 then
            return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
        end
    end

    return nil
end

RunService:BindToRenderStep("PlayerAimLock", Enum.RenderPriority.Camera.Value + 1, function()
    local character = Client.Character
    if not character then return end

    -- Check if Right-Click is held and mouse is hovering over another player
    local targetPart = rightClickAiming and getTargetPlayerPart(Mouse.Target) or nil

    if targetPart then
        -- Smoothly look at the targeted player's part from your current camera position
        local currentPos = Camera.CFrame.Position
        SmoothAim(targetPart, 12)
    end
end)

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