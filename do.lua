-- [[ Dumped Decompiled Script Execution ]]
-- [[ Dumped Decompiled Script Execution ]]
-- Chunk: loadstring_chunk
-- Timestamp: 2026-11-05 19:35:42
-- Size: 153780 bytes

local _dbg = {}
do
    local d = debug
    _dbg.tb   = function(...) return d.traceback(...) end
    _dbg.info = function(...) return d.info(...) end
    _dbg.gup  = function(...) return d.getupvalues(...) end
    _dbg.gc   = function(...) return d.getconstants(...) end
    _dbg.sc   = function(...) return d.setconstant(...) end
    _dbg.gs   = function(...) return d.getstack(...) end
    _dbg.ss   = function(...) return d.setstack(...) end
end

local _env = getgenv and getgenv() or {}
local _hook = (hookfunction and function(a,b) return hookfunction(a,b) end) or nil
local _conn = (getconnections and function(a) return getconnections(a) end) or nil
local _senv = (getsenv and function(a) return getsenv(a) end) or nil
local _shp  = (sethiddenproperty and function(a,b,c) return sethiddenproperty(a,b,c) end) or nil
local _sff  = (setfflag and function(a,b) return setfflag(a,b) end) or nil
local _sr   = (setreadonly and function(a,b) return setreadonly(a,b) end) or nil
local _ilv  = (isvalidlevel and function(a) return isvalidlevel(a) end) or nil
local _gs2  = (getstack and function(a) return getstack(a) end) or nil
local _ss2  = (setstack and function(a,b,c) return setstack(a,b,c) end) or nil

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

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Utopia/Library.lua"))()
local function MakeDraggable(frame, dragArea, guiParent)
    dragArea = dragArea or frame
    local dragging, dragStart, startPos = false, nil, nil
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end


do
    local GreenTheme = {
        Main = Color3.fromRGB(12,24,16), Background = Color3.fromRGB(10,20,13),
        Accent = Color3.fromRGB(50,220,110), Outline = Color3.fromRGB(35,90,55),
        Text = Color3.fromRGB(235,255,240), SubText = Color3.fromRGB(150,215,170),
        Button = Color3.fromRGB(22,48,32), Toggle = Color3.fromRGB(50,220,110),
        Slider = Color3.fromRGB(50,220,110), Dropdown = Color3.fromRGB(22,48,32),
        Tab = Color3.fromRGB(18,40,26), Section = Color3.fromRGB(16,34,22),
        Window = Color3.fromRGB(12,24,16), ScrollBar = Color3.fromRGB(50,220,110),
    }
    for k, v in pairs(GreenTheme) do
        pcall(function()
            if Library.Theme[k] ~= nil then
                Library.Theme[k] = v; Library:ChangeTheme(k, v)
                if Library.ThemeColorpickers and Library.ThemeColorpickers[k] then
                    Library.ThemeColorpickers[k]:Set(v)
                end
            end
        end)
    end
end

local Window = Library:Window({
    Name = "S C O R P I O N . W T F",
    GradientTitle = {Enabled=true, Start=Color3.fromRGB(255,255,255), Middle=Color3.fromRGB(80,255,140), End=Color3.fromRGB(30,160,80), Speed=1}
})
local Watermark  = Library:Watermark("scorpion.wtf", {"77974153657891", Color3.fromRGB(100,255,150)})
local KeybindList = Library:KeybindList()
pcall(function() KeybindList:SetVisibility(false) end)
local CombatTab   = Window:Page({Name="Combat",   Columns=2})
local MovementTab = Window:Page({Name="Movement", Columns=2})
local ESPTab      = Window:Page({Name="ESP",      Columns=2})
local MiscTab     = Window:Page({Name="Misc",     Columns=2})
local SettingsTab = Window:Page({Name="Settings", Columns=2})

SETTINGS = {
    SilentAim = {
        Enabled=false, HitChance=100,
        Manipulation=false, ManipulationKey=false, ManipulationDistance=10,
        ManipulationIndicator=true, ManipulationIndicatorColor=Color3.fromRGB(255,0,0),
        VisibleCheck=false, DownCheck=true, TargetTeammates=false,
        TargetHead=true, TargetBody=false, FovSize=200,
        Autoshoot=false,
        FovCircle=false, FovCircleSize=200, FovColor=Color3.fromRGB(50,220,110),
        FovColor2=Color3.fromRGB(255,255,255), FovThickness=2, FovFill=false,
        FovFillTransparency=0.8, FovRainbow=false, FovRainbowSpeed=1,
        FovGradientRotation=0, FovRotate=false, FovRotateSpeed=1.2,
    }
}


local AimSec = CombatTab:Section({Name="Silent Aim", Side=1})
AimSec:Toggle({Name="Button", Flag="B_True", Default=false, Callback=function(v) SETTINGS.Button.Enabled=v end})
AimSec:Slider({Name="Slider", Flag="S_Slider", Min=0, Default=20, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.Slider.Slider=v*10 end})
AimSec:Dropdown({Name="", Flag="SA_TargetParts", Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, Multi=true, Default={"Head"},
    Callback=function(v)
        SETTINGS.SilentAim.TargetHead=false; SETTINGS.SilentAim.TargetBody=false
        if typeof(v)=="table" then
            for _, name in ipairs(v) do
                if name=="Head" then SETTINGS.SilentAim.TargetHead=true end
                if name~="Head" then SETTINGS.SilentAim.TargetBody=true end
            end
        end
    end})
AimSec:Label("Color","Left"):Colorpicker({Name="Color Picker", Flag="C_Color", Default=Color3.fromRGB(255,0,0), Callback=function(v) SETTINGS.SilentAim.ManipulationIndicatorColor=v end})


local ConfigsSection = SettingsTab:Section({Name="Configs", Side=1})
do
    local CN, SC
    local CL = ConfigsSection:Listbox({Name="Configs list",Flag="Configs List",Items={},Multi=false,Default=nil,Callback=function(v) SC=v end})
    ConfigsSection:Textbox({Name="Name",Flag="Config Name",Default="",Placeholder=". . .",Callback=function(v) CN=v end})
    ConfigsSection:Button({Name="Load Config",Callback=function() if SC then Library:LoadConfig(readfile(Library.Folders.Configs.."/"..SC)) end end}):SubButton({
        Name="Save Config",Callback=function() if SC then Library:SaveConfig(SC) end end})
    ConfigsSection:Button({Name="Create Config",Callback=function()
        if CN=="" then return end
        if not isfile(Library.Folders.Configs.."/"..CN..".json") then
            writefile(Library.Folders.Configs.."/"..CN..".json",Library:GetConfig())
            Library:RefreshConfigsList(CL) end
    end}):SubButton({Name="Delete Config",Callback=function() if SC then Library:DeleteConfig(SC); Library:RefreshConfigsList(CL) end end})
    ConfigsSection:Button({Name="Refresh Configs",Callback=function() Library:RefreshConfigsList(CL) end})
    Library:RefreshConfigsList(CL)
    ConfigsSection:Label("Menu Keybind","Left"):Keybind({Name="Menu Keybind",Flag="Menu Keybind",Default=Enum.KeyCode.RightShift,Mode="Toggle",
        Callback=function(_) Library.MenuKeybind=Library.Flags["Menu Keybind"].Key end})
    ConfigsSection:Toggle({Name="Watermark",   Flag="Watermark",   Default=false,Callback=function(v) Watermark:SetVisibility(v) end})
    ConfigsSection:Toggle({Name="Keybind List",Flag="Keybind List",Default=false,Callback=function(v) KeybindList:SetVisibility(v) end})
end

local Flags = Library.Flags

