--[[
    jade.xyz UI Library - Example & Test Script
    
    Для запуска напрямую через Roblox Executor одной строкой:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/example.lua"))()
]]

local Jade

-- 1. Сначала пробуем загрузить локальный файл (если есть в воркспейсе для локальной разработки)
pcall(function()
    if isfile and isfile("Jade/Library.lua") then
        Jade = loadstring(readfile("Jade/Library.lua"))()
    elseif isfile and isfile("Library.lua") then
        Jade = loadstring(readfile("Library.lua"))()
    end
end)

-- 2. Если воркспейс пустой или очищенный — скачиваем актуальную библиотеку напрямую с GitHub!
if not Jade then
    local LibraryUrl = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/library"
    local Success, Source = pcall(function()
        return game:HttpGet(LibraryUrl)
    end)
    if Success and Source and #Source > 1000 then
        Jade = loadstring(Source)()
    else
        error("[jade.xyz] Не удалось загрузить библиотеку по ссылке: " .. tostring(LibraryUrl))
    end
end

-- Базовый URL для ассетов на GitHub
local GitHubBase = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main"
local MainIconUrl = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/asset_23de81e2.png"

-- Проверка и фоновая загрузка 8 кадров котика на случай первого запуска или чистого воркспейса
if makefolder and isfolder then
    if not isfolder("Jade") then makefolder("Jade") end
    if not isfolder("Jade/Assets") then makefolder("Jade/Assets") end
end

if writefile and isfile and game and game.HttpGet then
    for i = 1, 8 do
        local LocalPath = "Jade/Assets/cat_run_right_" .. i .. ".png"
        if not isfile(LocalPath) then
            local FrameUrls = {
                string.format("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/cat_run_right_%d.png", i),
                string.format("https://github.com/777DmOrYber777/jade.xyz/blob/main/cat_run_right_%d.png?raw=true", i)
            }
            for _, Url in ipairs(FrameUrls) do
                local Ok, Body = pcall(function() return game:HttpGet(Url) end)
                if Ok and Body and #Body > 100 then
                    writefile(LocalPath, Body)
                    break
                end
            end
        end
    end
end

-- Интерактивный экран загрузки (с 8-кадровым бегущим котом и автоматической проверкой файлов)
Jade:ShowLoader({})

-- Создание главного окна
local Window = Jade:Window({
    Name = "jade.xyz | Criminality",
    Icon = MainIconUrl,
    IconSize = 38
})

-- ====================================================================
-- 1. ВКЛАДКА: COMBAT
-- ====================================================================
local Combat = Window:Tab({Name = "Combat", Icon = "swords"})

local AimbotSub = Combat:SubTab({Name = "Aimbot", Icon = "crosshair"})
local SilentAimSub = Combat:SubTab({Name = "Silent Aim", Icon = "zap"})

-- Секции для Aimbot
local AimMain = AimbotSub:Section({Name = "Main", Side = 1})
local AimEnabled = AimMain:Toggle({Name = "Enable Aimbot", Default = false, Flag = "aim_enabled"})
AimEnabled:Keybind({Default = Enum.KeyCode.E, Flag = "aim_key"})
AimMain:Toggle({Name = "Team Check", Default = true, Flag = "aim_team"})
AimMain:Toggle({Name = "Visible Check", Default = false, Flag = "aim_vis"})
AimMain:Dropdown({Name = "Target Part", Items = {"Head", "Torso", "Random"}, Default = "Head", Flag = "aim_part"})

local AimTuning = AimbotSub:Section({Name = "Tuning", Side = 2})
AimTuning:Slider({Name = "FOV Radius", Min = 10, Max = 360, Default = 120, Suffix = "°", Flag = "aim_fov"})
AimTuning:Slider({Name = "Smoothness", Min = 1, Max = 30, Default = 8, Flag = "aim_smooth"})
AimTuning:Button({Name = "Reset Tuning", Callback = function()
    Jade:Notification({Title = "Tuning", Description = "Values restored!", Icon = "check", Duration = 3})
end})

-- Секции для Silent Aim
local SilentMain = SilentAimSub:Section({Name = "Silent Targeting", Side = 1})
SilentMain:Toggle({Name = "Silent Aim", Default = false, Flag = "silent_enabled"})
SilentMain:Slider({Name = "Hit Chance", Min = 0, Max = 100, Default = 100, Suffix = "%", Flag = "silent_chance"})

local SilentMisc = SilentAimSub:Section({Name = "Prediction", Side = 2})
SilentMisc:Toggle({Name = "Velocity Prediction", Default = true, Flag = "silent_pred"})
SilentMisc:Slider({Name = "Prediction Strength", Min = 1, Max = 5, Default = 1.5, Decimals = 0.1, Flag = "silent_strength"})


-- ====================================================================
-- 2. ВКЛАДКА: VISUALS
-- ====================================================================
local Visuals = Window:Tab({Name = "Visuals", Icon = "eye"})
local Esp = Visuals:SubTab({Name = "ESP", Icon = "scan-eye"})

local EspMain = Esp:Section({Name = "Players", Side = 1})
local EspEnabled = EspMain:Toggle({Name = "Enable ESP", Default = false, Flag = "esp_enabled"})
EspEnabled:Keybind({Default = Enum.KeyCode.R, Flag = "esp_key"})
EspMain:Toggle({Name = "Boxes", Default = true, Flag = "esp_box"})
EspMain:Toggle({Name = "Names", Default = true, Flag = "esp_names"})
EspMain:Toggle({Name = "Health Bar", Default = true, Flag = "esp_health"})
EspMain:Toggle({Name = "Tracers", Default = false, Flag = "esp_tracers"})
EspMain:Slider({Name = "Distance", Min = 100, Max = 4000, Default = 1500, Suffix = "m", Flag = "esp_dist"})
EspMain:Dropdown({Name = "Box Fill", Items = {"None", "Full", "Gradient"}, Default = "None", Flag = "esp_fill"})

local ChamsSection = Esp:Section({Name = "Chams & Visuals", Side = 2})
ChamsSection:Toggle({Name = "Arms Chams", Default = false, Flag = "arms_chams"})
ChamsSection:Dropdown({Name = "Arms Mode", Items = {"Outline", "Glow", "Solid"}, Default = "Outline", Flag = "arms_mode"})
ChamsSection:Toggle({Name = "Gun Chams", Default = false, Flag = "gun_chams"})


-- ====================================================================
-- 3. ВКЛАДКА: SETTINGS
-- ====================================================================
local Settings = Window:Tab({Name = "Settings", Icon = "settings"})
local ConfigSub = Settings:SubTab({Name = "Config", Icon = "save"})

-- Автоматическое построение палитр тем, шрифтов, фона, курсора, кейбинд-меню и конфигов
ConfigSub:ThemeConfig({})

local ActionsSub = Settings:SubTab({Name = "Actions", Icon = "sparkles"})

local NotifSection = ActionsSub:Section({Name = "Notifications & Actions", Side = 1})
local NotifBtn = NotifSection:Button({
    Name = "Button with Notification",
    Callback = function()
        print("[Jade] Action executed!")
    end,
    Notification = {
        Title = "jade.xyz",
        Description = "Notification attached directly via parameter!",
        Icon = "bell",
        Duration = 3.5
    }
})

local DynamicBtn = NotifSection:Button({
    Name = "Button:SetNotification()",
    Callback = function()
        print("[Jade] Dynamic button pressed!")
    end
})

DynamicBtn:SetNotification({
    Title = "Attached by Command",
    Description = "Configured dynamically via Button:SetNotification()!",
    Icon = "sparkles",
    Duration = 3
})

NotifSection:Button({
    Name = "Replay Loader Screen (Cat Run)",
    Callback = function()
        Jade:ShowLoader({ PromptFonts = false })
    end
})

local KeybindSection = ActionsSub:Section({Name = "Keybind System", Side = 2})
KeybindSection:Keybind({
    Name = "Panic Mode",
    Default = Enum.KeyCode.P,
    Flag = "panic_key",
    Callback = function()
        Jade:Notification({
            Title = "Panic Triggered",
            Description = "Panic key was pressed!",
            Icon = "triangle-alert",
            Duration = 2.5
        })
    end
})
KeybindSection:Button({
    Name = "Toggle Keybind Menu",
    Callback = function()
        Jade:SetKeybindMenu(not Jade.KeybindMenuEnabled)
    end
})


-- ====================================================================
-- 4. WATERMARK
-- ====================================================================
Window:Watermark({
    Name = "jade.xyz",
    Icon = MainIconUrl
})

-- Стартовое уведомление об успешной инициализации
Jade:Notification({
    Title = "jade.xyz",
    Description = "Loaded successfully from GitHub! All systems operational.",
    Icon = "check",
    Duration = 5
})
