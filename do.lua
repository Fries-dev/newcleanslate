local Library, Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Atlanta/Library.lua"))()
local Flags = Library.flags
local SETTINGS = {
    Basic = {}
}

local Window = Library:window({name = "Atlanta | "})

local CombatTab   = Window:tab({name = "Combat"})
local SettingsTab = Window:tab({name = "Settings"})
local AimSec = CombatTab:section({name = "Basic"})

AimSec:slider({
    name = "Slider",
    flag = "S_Slider",
    min = 0,
    max = 100,
    default = 20,
    suffix = "%",
    interval = 0.1,
    callback = function(v)
        SETTINGS.Basic.Slider = v * 10
    end
})
AimSec:dropdown({
    name = "Dropdown",
    flag = "DD_Dropdown",
    items = {"1", "2", "3", "4"},
    multi = true,
    default = {"1"},
    callback = function(v)
        SETTINGS.Basic.TargetHead = false
        SETTINGS.Basic.TargetBody = false

        if typeof(v) == "table" then
            for _, name in ipairs(v) do
                if name == "1" then
                    SETTINGS.Basic.TargetHead = true
                else
                    SETTINGS.Basic.TargetBody = true
                end
            end
        end
    end
})
AimSec:label({name = "Color"}):colorpicker({
    name = "Color Picker",
    flag = "C_Color",
    color = Color3.fromRGB(255, 0, 0),
    callback = function(v)
        SETTINGS.Basic.ManipulationIndicatorColor = v
    end
})
local C = Color3.fromHex

Library:update_theme("accent", C("29a5e1"))
Library:update_theme("glow", C("000000"))
Library:update_theme("inline", C("000000"))
Library:update_theme("text", C("ffffff"))
Library:update_theme("outline", C("434343"))
Library:update_theme("text_outline", C("000000"))
Library:update_theme("low_contrast", C("000000"))
Library:update_theme("high_contrast", C("000000"))
Library:update_theme("contrast", ColorSequence.new{
    ColorSequenceKeypoint.new(0, C("000000")),
    ColorSequenceKeypoint.new(1, C("000000"))
})
for flag, hex in pairs({
    Accent = "ffffff",
    Glow = "ffffff",
    Inline = "a0a0a0",
    Main = "ffffff",
    low_contrast = "161616",
    high_contrast = "262626",
}) do
    local setter = Library.config_flags[flag]
    if setter then setter(C(hex)) end
end
for _, gui in next, Library.guis do
    for _, obj in next, gui:GetDescendants() do
        if obj:IsA("ImageLabel") and obj.Image:find("18245826428", 1, true) then
            obj.Visible = false
        end
    end
end
Library:config_list_update()
CombatTab.open_tab()
Library.old_config = Library:get_config()