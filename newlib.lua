--[[
    Atlanta -> new library compatibility layer

    Keeps the Atlanta-style API (library:window / :tab / :column / :section / :toggle ...)
    but renders everything with the second UI library, so existing scripts keep working.

    SETUP: put the second library somewhere this file can reach it:
      * upload it to GitHub (or similar) and set LIBRARY_URL below, OR
      * save it in your executor workspace as "ui_library.lua" (LIBRARY_FILE), OR
      * load it yourself before this script (getgenv().Library is reused if set).

    USAGE (same as before):
        local library, themes = loadstring(game:HttpGet("<this file>"))()
        local window = library:window({name = "My Hub"})
        local tab = window:tab({name = "Main"})
        local column = tab:column()
        local section = column:section({name = "Stuff"})
        section:toggle({name = "Enabled", flag = "enabled", callback = function(v) end})
            :keybind({flag = "enabled_bind", mode = "toggle"})
]]

local LIBRARY_URL = "https://raw.githubusercontent.com/YOU/REPO/main/ui_library.lua"
local LIBRARY_FILE = "ui_library.lua"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- load the base library ------------------------------------------------------
local Lib = getgenv().Library
if not Lib then
    local source
    if isfile and isfile(LIBRARY_FILE) then
        source = readfile(LIBRARY_FILE)
    else
        source = game:HttpGet(LIBRARY_URL)
    end
    Lib = loadstring(source)()
end

-- helpers --------------------------------------------------------------------
local atlanta = {}
atlanta.__index = atlanta
atlanta.directory = "Atlanta"
atlanta.visible_flags = {}
atlanta.config_flags = Lib.SetFlags

local function cap(s)
    s = tostring(s or "toggle")
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local function parse_key(s)
    if typeof(s) == "EnumItem" then
        return s
    end
    if type(s) ~= "string" then
        return "none"
    end
    local kind, name = string.match(s, "^Enum%.(%w+)%.(%w+)$")
    if kind and name then
        local ok, item = pcall(function()
            return Enum[kind][name]
        end)
        if ok and item then
            return item
        end
    end
    return "none"
end

-- translate the new library's flag values into the shape Atlanta scripts expect
local function convert(v)
    if type(v) ~= "table" then
        return v
    end

    if v.HexValue ~= nil and v.Color ~= nil then
        return {
            Color = v.Color,
            Transparency = v.Alpha,
            Alpha = v.Alpha,
            HexValue = v.HexValue,
        }
    end

    if v.Toggled ~= nil or (v.Mode ~= nil and v.Key ~= nil) then
        return {
            active = v.Toggled,
            mode = string.lower(v.Mode or "toggle"),
            key = parse_key(v.Key),
            Toggled = v.Toggled,
            Mode = v.Mode,
            Key = v.Key,
        }
    end

    return v
end

atlanta.flags = setmetatable({}, {
    __index = function(_, k)
        return convert(Lib.Flags[k])
    end,
    __newindex = function(_, k, v)
        Lib.Flags[k] = v
    end,
})

local flags = atlanta.flags

local function null_object()
    local o = {}
    return setmetatable(o, {
        __index = function()
            return function()
                return o
            end
        end,
        __call = function()
            return o
        end,
    })
end

local function wrap(fields)
    return setmetatable(fields, atlanta)
end

local function register_visibility(opts, fn)
    if opts.flag then
        atlanta.visible_flags[opts.flag] = fn
    end
end

-- global functions -------------------------------------------------------------
function atlanta:notification(opts)
    opts = opts or {}
    Lib:Notification(opts.text or opts.name or "Notification", opts.time or 5, Lib.Theme.Accent)
end

function atlanta:watermark(opts)
    opts = opts or {}
    local wm = Lib:Watermark(opts.text or opts.default or "Atlanta")

    local label
    pcall(function()
        local kids = Lib.Holder.Instance:GetChildren()
        local frame = kids[#kids]
        label = frame and frame:FindFirstChildOfClass("TextLabel")
    end)

    return {
        change_text = function(text)
            if label then
                label.Text = text
            end
        end,
        set_visible = function(bool)
            wm:SetVisibility(bool)
        end,
    }
end

function atlanta:fold_elements(origin, elements)
    for _, x in elements do
        local fn = atlanta.visible_flags[x]
        if fn then
            fn(flags[origin])
        end
    end
end

function atlanta:update_theme(theme, color)
    local map = {
        accent = "Accent",
        outline = "Outline",
        inline = "Border",
        text = "Text",
        high_contrast = "Section Background",
        low_contrast = "Window Background",
        glow = "Accent",
    }
    local name = map[theme] or theme
    if Lib.Theme[name] ~= nil then
        Lib:ChangeTheme(name, color)
    end
end

function atlanta:get_config()
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(Lib:GetConfig())
    end)
    if not ok then
        return "{}"
    end
    for k in decoded do
        if string.sub(k, 1, 2) == "__" then
            decoded[k] = nil
        end
    end
    return HttpService:JSONEncode(decoded)
end

function atlanta:load_config(json)
    Lib:LoadConfig(json)
end

function atlanta:esp_preview()
    return null_object()
end

function atlanta:panel(opts)
    opts = opts or {}
    if atlanta._last_window then
        return atlanta._last_window:tab({name = opts.text or opts.name or "Panel"})
    end
end

-- layout ---------------------------------------------------------------------
function atlanta:tab(opts)
    opts = opts or {}

    local lib_window = self._window
    local page = lib_window:Page({Name = opts.name or "tab", Columns = 2})
    local component = lib_window.Pages[#lib_window.Pages]

    local tab = wrap({
        _window = lib_window,
        _page = page,
        _columns = 0,
        _root = self,
    })

    function tab.open_tab()
        for _, p in lib_window.Pages do
            p:Turn(p == component)
        end
    end

    if not self._has_user_tab then
        self._has_user_tab = true
        tab.open_tab()
    end

    return tab
end

function atlanta:column()
    self._columns += 1

    return wrap({
        _page = self._page,
        _side = math.min(self._columns, self._page.Columns),
        _tab = self,
    })
end

function atlanta:section(opts)
    opts = opts or {}

    local section = self._page:Section({
        Name = opts.name or "Section",
        Side = self._side or 1,
    })

    return wrap({
        _section = section,
        _page = self._page,
        _side = self._side,
        _btn_holder = false,
    })
end

function atlanta:multi_section(opts)
    opts = opts or {}
    local column = self._side and self or self:column()
    local out = {}

    for _, name in opts.names or {"First", "Second", "Third"} do
        out[#out + 1] = column:section({name = name})
    end

    return unpack(out)
end

-- elements -------------------------------------------------------------------
function atlanta:toggle(opts)
    opts = opts or {}

    local t = self._section:Toggle({
        Name = opts.name or "Toggle",
        Flag = opts.flag,
        Default = opts.default or opts.enabled or false,
        Callback = opts.callback,
        Tooltip = opts.tooltip,
        Risky = opts.risky,
    })

    local obj = wrap({_section = self._section, _native = t})
    obj.set = function(v)
        t:Set(v)
    end
    obj.set_element_visible = function(b)
        t:SetVisibility(b)
    end

    register_visibility(opts, obj.set_element_visible)
    return obj
end

function atlanta:colorpicker(opts)
    opts = opts or {}

    self._native:Colorpicker({
        Name = opts.name or "Color",
        Flag = opts.flag,
        Default = opts.color or opts.default,
        Callback = opts.callback,
        Alpha = opts.alpha,
    })

    return self -- allows :colorpicker():colorpicker():keybind() chaining
end

function atlanta:keybind(opts)
    opts = opts or {}
    local mode = cap(opts.mode or "toggle")

    local k = self._native:Keybind({
        Name = opts.name,
        Flag = opts.flag,
        Default = opts.key or opts.default or Enum.KeyCode.RightControl,
        Mode = mode,
        Callback = opts.callback,
        Tooltip = opts.tooltip,
    })

    -- no key given = unbound (the base library would otherwise default to RightControl)
    if not opts.key and not opts.default then
        k:Set({Key = "None", Mode = mode})
    end

    return self
end

function atlanta:slider(opts)
    opts = opts or {}

    local s = self._section:Slider({
        Name = opts.name or "",
        Flag = opts.flag,
        Min = opts.min or opts.minimum or 0,
        Max = opts.max or opts.maximum or 100,
        Default = opts.default or opts.min or 0,
        Suffix = opts.suffix or "",
        Decimals = opts.interval or opts.decimal or 1,
        Callback = opts.callback,
        Tooltip = opts.tooltip,
    })

    local obj = wrap({_section = self._section, _native = s})
    obj.set = function(v)
        s:Set(v)
    end
    obj.set_element_visible = function(b)
        s:SetVisibility(b)
    end

    register_visibility(opts, obj.set_element_visible)
    return obj
end

function atlanta:dropdown(opts)
    opts = opts or {}

    local items = opts.items or {"1", "2", "3"}
    local default = opts.default
    if default == nil then
        default = opts.multi and {items[1]} or items[1]
    end

    local d = self._section:Dropdown({
        Name = opts.name or "",
        Flag = opts.flag,
        Items = items,
        Default = default,
        Multi = opts.multi,
        Callback = opts.callback,
        Tooltip = opts.tooltip,
        MaxSize = math.clamp(#items * 17 + 8, 40, 160),
    })

    local obj = wrap({_section = self._section, _native = d})
    obj.set = function(v)
        d:Set(v)
    end
    obj.refresh_options = function(list)
        d:Refresh(list)
    end
    obj.set_element_visible = function(b)
        d:SetVisibility(b)
    end

    register_visibility(opts, obj.set_element_visible)
    return obj
end

function atlanta:button_holder()
    self._btn_holder = true
    self._first_btn = nil
    return self
end

function atlanta:button(opts)
    opts = opts or {}

    local data = {
        Name = opts.text or opts.name or "Button",
        Callback = opts.callback,
        Tooltip = opts.tooltip,
        Risky = opts.risky,
    }

    -- two buttons after a button_holder() share one row
    if self._btn_holder and self._first_btn then
        self._first_btn:SubButton(data)
        self._btn_holder = false
        self._first_btn = nil
    else
        local b = self._section:Button(data)
        if self._btn_holder then
            self._first_btn = b
        end
    end

    return self
end

function atlanta:label(opts)
    opts = opts or {}

    local l = self._section:Label(opts.text or opts.name or "Label", "Left")

    local text_label
    pcall(function()
        local kids = self._section.Items["Content"].Instance:GetChildren()
        text_label = kids[#kids]:FindFirstChildOfClass("TextLabel")
    end)

    local obj = wrap({_section = self._section, _native = l})
    obj.set = function(text)
        if text_label then
            text_label.Text = text
        end
    end

    return obj
end

function atlanta:textbox(opts)
    opts = opts or {}

    local t = self._section:Textbox({
        Name = opts.name or "",
        Flag = opts.flag,
        Default = opts.default or "",
        Placeholder = opts.placeholder or opts.placeholdertext or "type here...",
        Callback = opts.callback,
        Tooltip = opts.tooltip,
    })

    local obj = wrap({_section = self._section, _native = t})
    obj.set = function(v)
        t:Set(v)
    end
    obj.set_element_visible = function(b)
        t:SetVisibility(b)
    end

    register_visibility(opts, obj.set_element_visible)
    return obj
end

function atlanta:list(opts)
    opts = opts or {}

    local l = self._section:Listbox({
        Name = opts.name or "",
        Flag = opts.flag,
        Items = opts.items or {},
        Size = opts.size or 175,
        Callback = opts.callback,
    })

    local obj = wrap({_section = self._section, _native = l})
    obj.set = function(v)
        l:Set(v)
    end
    obj.refresh_options = function(list)
        l:Refresh(list)
    end
    obj.set_element_visible = function(b)
        l:SetVisibility(b)
    end

    register_visibility(opts, obj.set_element_visible)
    return obj
end

-- window ---------------------------------------------------------------------
local function list_configs()
    local out = {}
    local ok, files = pcall(listfiles, Lib.Folders.Configs)
    if ok then
        for _, f in files do
            local name = tostring(f):match("([^/\\]+)%.cfg$")
            if name then
                out[#out + 1] = name
            end
        end
    end
    return out
end

local function config_path(name)
    return Lib.Folders.Configs .. "/" .. name .. ".cfg"
end

local function build_settings(self, win, keylist, watermark)
    local page = win:Page({Name = "Settings", Columns = 2})
    page.Items["Inactive"].Instance.LayoutOrder = 1000

    ------------------------------------------------------------------ column 1
    local menu = page:Section({Name = "Menu", Side = 1})

    Lib.MenuKeybind = tostring(Enum.KeyCode.Insert)
    menu:Label("Menu Bind"):Keybind({
        Name = "Menu",
        Flag = "__menu_bind",
        Default = Enum.KeyCode.Insert,
        Mode = "Toggle",
        Callback = function()
            local f = Lib.Flags["__menu_bind"]
            if f and f.Key and f.Key ~= "None" then
                Lib.MenuKeybind = f.Key
            end
        end,
    })

    menu:Toggle({
        Name = "Keybind List",
        Flag = "keybind_list",
        Callback = function(b)
            keylist:SetVisibility(b)
        end,
    })
    keylist:SetVisibility(false)

    menu:Toggle({
        Name = "Watermark",
        Flag = "watermark",
        Callback = function(b)
            watermark.set_visible(b)
        end,
    })
    watermark.set_visible(false)

    menu:Button({
        Name = "Unload Menu",
        Risky = true,
        Callback = function()
            Lib:Unload()
        end,
    })

    local server = page:Section({Name = "Server", Side = 1})
    local b = server:Button({
        Name = "Copy JobId",
        Callback = function()
            setclipboard(game.JobId)
        end,
    })
    b:SubButton({
        Name = "Copy GameID",
        Callback = function()
            setclipboard(tostring(game.GameId))
        end,
    })

    local b2 = server:Button({
        Name = "Copy Join Script",
        Callback = function()
            setclipboard(
                'game:GetService("TeleportService"):TeleportToPlaceInstance('
                    .. game.PlaceId
                    .. ', "'
                    .. game.JobId
                    .. '", game.Players.LocalPlayer)'
            )
        end,
    })
    b2:SubButton({
        Name = "Rejoin",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end,
    })

    server:Button({
        Name = "Join New Server",
        Callback = function()
            local ok, res = pcall(function()
                return HttpService:JSONDecode(game:HttpGetAsync(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
            end)
            if not ok or not res or not res.data then
                return
            end
            local max_players = Lib.Flags["max_players"] or 15
            for _, srv in res.data do
                if srv.id ~= game.JobId and srv.playing <= max_players then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id)
                    return
                end
            end
            Lib:Notification("No server found under the player limit", 4, Lib.Theme.Risky)
        end,
    })
    server:Slider({Name = "Max Players", Flag = "max_players", Min = 0, Max = 40, Default = 15, Decimals = 1})

    ------------------------------------------------------------------ column 2
    local theme = page:Section({Name = "Theme", Side = 2})
    for _, name in {
        "Accent",
        "Window Background",
        "Inline",
        "Section Background",
        "Element",
        "Border",
        "Outline",
        "Text",
    } do
        theme:Label(name):Colorpicker({
            Name = name,
            Flag = "Theme " .. name,
            Default = Lib.Theme[name],
            Callback = function(color)
                Lib:ChangeTheme(name, color)
            end,
        })
    end

    local cfg = page:Section({Name = "Configs", Side = 2})
    local cfg_list = cfg:Listbox({Name = "Configs", Flag = "__cfg_list", Items = list_configs(), Size = 110})
    cfg:Textbox({Name = "Config name", Flag = "__cfg_name", Placeholder = "name..."})

    local function refresh()
        cfg_list:Refresh(list_configs())
    end

    local function save(name)
        if not name or name == "" then
            Lib:Notification("Pick or type a config name first", 4, Lib.Theme.Risky)
            return
        end
        writefile(config_path(name), atlanta:get_config())
        refresh()
        Lib:Notification("Saved config " .. name, 4, Lib.Theme.Accent)
    end

    local create = cfg:Button({
        Name = "Create",
        Callback = function()
            save(Lib.Flags["__cfg_name"])
        end,
    })
    create:SubButton({
        Name = "Save",
        Callback = function()
            save(Lib.Flags["__cfg_list"])
        end,
    })

    local load_btn = cfg:Button({
        Name = "Load",
        Callback = function()
            local name = Lib.Flags["__cfg_list"]
            if name and isfile(config_path(name)) then
                atlanta:load_config(readfile(config_path(name)))
            end
        end,
    })
    load_btn:SubButton({
        Name = "Delete",
        Risky = true,
        Callback = function()
            local name = Lib.Flags["__cfg_list"]
            if name and isfile(config_path(name)) then
                delfile(config_path(name))
                refresh()
            end
        end,
    })

    cfg:Button({Name = "Refresh Configs", Callback = refresh})

    getgenv().load_config = function(name)
        atlanta:load_config(readfile(config_path(name)))
    end
end

local function build_playerlist(win)
    local page = win:Page({Name = "Players", Columns = 1})
    page.Items["Inactive"].Instance.LayoutOrder = 1001
    return page:PlayerList({})
end

function atlanta:window(props)
    props = props or {}

    local lib_window = Lib:Window({Name = props.name or "Atlanta"})

    -- keybind list must exist before any keybind element is created
    local keylist = Lib:KeybindList()
    local watermark = atlanta:watermark({default = props.watermark or ("Atlanta | " .. os.date("%b %d %Y"))})

    local obj = wrap({_window = lib_window, opened = true})
    obj.esp_section = null_object()

    function obj.set_menu_visibility(bool)
        obj.opened = bool
        lib_window:SetOpen(bool)
    end

    build_settings(obj, lib_window, keylist, watermark)

    local playerlist = build_playerlist(lib_window)
    function atlanta.get_priority(player)
        local entry = playerlist and playerlist.Players[tostring(player)]
        if entry then
            local text = entry.PlayerStatus.Instance.Text
            if text ~= "LocalPlayer" then
                return text
            end
        end
    end

    atlanta._last_window = obj
    return obj
end

return atlanta, Lib.Theme