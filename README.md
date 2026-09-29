# jade.xyz UI Library — Полное руководство пользователя и разработчика

---

## Оглавление
1. [Быстрый старт (Запуск)](#1-быстрый-старт-запуск)
2. [Руководство пользователя](#2-руководство-пользователя)
   - [Управление окном и горячие клавиши](#управление-окном-и-горячие-клавиши)
   - [Кейбинд-меню (Keybind List)](#кейбинд-меню-keybind-list)
   - [Темы оформления и Шрифты](#темы-оформления-и-шрифты)
   - [Анимированный фон](#анимированный-фон)
   - [Конфиг-система (Сохранение и Загрузка)](#конфиг-система-сохранение-и-загрузка)
3. [Руководство разработчика (API & Код)](#3-руководство-разработчика-api--код)
   - [Инициализация и Экран загрузки](#инициализация-и-экран-загрузки)
   - [Создание главного окна](#создание-главного-окна)
   - [Вкладки (Tabs) и Подвкладки (SubTabs)](#вкладки-tabs-и-подвкладки-subtabs)
   - [Секции (Sections)](#секции-sections)
   - [Элементы управления](#элементы-управления)
     - [Переключатель (Toggle) + Инлайн-кейбинд](#переключатель-toggle--инлайн-кейбинд)
     - [Слайдер (Slider)](#слайдер-slider)
     - [Выпадающий список (Dropdown)](#выпадающий-список-dropdown)
     - [Кнопка (Button) и Уведомления](#кнопка-button-и-уведомления)
     - [Отдельный Кейбинд (Keybind)](#отдельный-кейбинд-keybind)
     - [Поле ввода (Input)](#поле-ввода-input)
     - [Палитра цветов (Colorpicker)](#палитра-цветов-colorpicker)
   - [Система уведомлений (Notifications)](#система-уведомлений-notifications)
   - [Ватермарка (Watermark)](#ватермарка-watermark)
   - [Модальное окно подтверждения (Confirm Dialog)](#модальное-окно-подтверждения-confirm-dialog)
4. [Готовый шаблон скрипта](#4-готовый-шаблон-скрипта)

---

## 1. Быстрый старт (Запуск)

Для запуска скрипта в любом Roblox Executor (Potassium, Synapse, Wave, Delta и др.) достаточно выполнить одну строчку:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/example.lua"))()
```

Скрипт автоматически:
- Проверит и загрузит файлы библиотеки.
- Покажет интерактивный экран загрузки с бегущим котом.
- Скачает и закэширует пиксельные шрифты (`PixelCode`, `Tamzen`).
- Загрузит сохранённую тему оформления и конфигурацию.

---

## 2. Руководство пользователя

### Управление окном и горячие клавиши
* **Открыть / Закрыть меню:** клавиша `G` или `Right Control` (Правый Ctrl).
* **Перетаскивание меню (Drag):** зажмите левую кнопку мыши (ЛКМ) на верхней шапке (TopBar) окна и перемещайте в любое удобное место экрана.
* **Поиск по функциям:** в верхней левой части окна расположено поле `search`. Введите название интересующей настройки, чтобы моментально её найти.

### Кейбинд-меню (Keybind List)
* В настройках (`Settings -> Config`) можно включить или выключить плавающее **Keybind Menu**.
* **Перемещение:** зажмите ЛКМ в любом месте шапки или тела кейбинд-меню, чтобы перетащить его по экрану.
* **Как оно работает:**
  - Меню динамически адаптируется по высоте. Если нет активных функций, оно скрыто или компактно сложено.
  - При нажатии клавиши включённая функция подсвечивается ярким цветом акцента вашей темы.

### Темы оформления и Шрифты
Во вкладке `Settings -> Config`:
* **Цветовые палитры:** доступны предустановленные темы:
  - `Pitch Black Jade` (классический глубокий чёрный с изумрудным акцентом)
  - `Neon Jade` (яркий неоновый зелёный)
  - `Electric Mint` (мятно-бирюзовый)
  - `Toxic Cyber` (кислотно-зелёный киберпанк)
  - `Abyssal Jade` (глубокий морской бирюзовый)
  - `Classic Jadeite` (мягкий нефритовый)
* **Шрифты:** на выбор доступны стили текста:
  - `PixelCode` (фирменный пиксельный шрифт по умолчанию)
  - `Tamzen` (компактный пиксельный шрифт)
  - `Gotham` (чистый современный сглаженный шрифт)
  - `Spleen` (ретро моноширинный)

### Анимированный фон
* В настройках темы доступен переключатель **Animated Background**.
* **Стили фона:**
  - `Neon Grid` — ровная неоновая сетка, плавно двигающаяся в сторону в тон выбранной темы.
  - `Floating Particles` — парящие световые частицы.

### Конфиг-система (Сохранение и Загрузка)
* **Создание конфига:** введите имя в поле ввода и нажмите кнопку **Create**. Конфиг мгновенно сохранится в папку `Jade/Configs/<Имя>.json`.
* **Загрузка конфига:** выберите сохранённый конфиг из списка и нажмите **Load**.
* **Перезапись / Удаление:** при попытке перезаписать существующий конфиг или удалить его, появится стильное всплывающее окно с вопросом: *«Вы уверены, что хотите удалить / перезаписать конфиг?»* с кнопками подтверждения `Yes / No`.

---

## 3. Руководство разработчика (API & Код)

### Инициализация и Экран загрузки

Подключение библиотеки с локальным приоритетом (для разработки) и удалённым GitHub-фоллбеком:

```lua
local Jade
pcall(function()
    if isfile and isfile("Jade/Library.lua") then
        Jade = loadstring(readfile("Jade/Library.lua"))()
    end
end)

if not Jade then
    Jade = loadstring(game:HttpGet("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/library"))()
end

-- Показ анимированного экрана загрузки с бегущим котом
Jade:ShowLoader({})
```

### Создание главного окна

```lua
local Window = Jade:Window({
    Name = "jade.xyz | My Script",
    Icon = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/asset_23de81e2.png",
    IconSize = 38 -- Размер иконки хаба в пикселях
})
```

### Вкладки (Tabs) и Подвкладки (SubTabs)

```lua
-- Создание вкладки первого уровня (боковая панель / верх)
local Combat = Window:Tab({
    Name = "Combat",
    Icon = "swords" -- Название иконки из Lucide pack
})

-- Создание подвкладки внутри Combat
local AimbotSub = Combat:SubTab({
    Name = "Aimbot",
    Icon = "crosshair"
})
```

### Секции (Sections)

Секции делят подвкладку на две аккуратные колонки: `Side = 1` (левая), `Side = 2` (правая).

```lua
local MainSection = AimbotSub:Section({
    Name = "Main Settings",
    Side = 1
})

local TuningSection = AimbotSub:Section({
    Name = "Tuning",
    Side = 2
})
```

---

### Элементы управления

#### Переключатель (Toggle) + Инлайн-кейбинд
Создаёт свитч для включения/выключения функции с возможностью привязать клавишу:

```lua
local AimbotToggle = MainSection:Toggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "aim_enabled",
    Callback = function(Value)
        print("Aimbot status:", Value)
    end
})

-- Привязка клавиши прямо в строке переключателя:
AimbotToggle:Keybind({
    Default = Enum.KeyCode.E,
    Flag = "aim_key",
    Callback = function(Key)
        print("Aimbot key triggered:", Key)
    end
})
```

#### Слайдер (Slider)
Ползунок для числовых значений:

```lua
MainSection:Slider({
    Name = "FOV Radius",
    Min = 10,
    Max = 360,
    Default = 120,
    Decimals = 1,     -- Шаг/точность (например 0.1 или 1)
    Suffix = "°",     -- Суффикс (например "%", " studs", "ms")
    Flag = "aim_fov",
    Callback = function(Value)
        -- Изменение радиуса FOV
    end
})
```

#### Выпадающий список (Dropdown)
Одиночный или множественный выбор:

```lua
MainSection:Dropdown({
    Name = "Target Hitbox",
    Items = {"Head", "Torso", "Random"},
    Default = "Head",
    Flag = "target_hitbox",
    Callback = function(Selected)
        print("Selected hitbox:", Selected)
    end
})
```

#### Кнопка (Button) и Уведомления
Кнопка с встроенным или динамически привязанным уведомлением:

```lua
-- Вариант 1: Уведомление через параметр
MainSection:Button({
    Name = "Reset Settings",
    Callback = function()
        -- логика сброса
    end,
    Notification = {
        Title = "Settings",
        Description = "All parameters restored to defaults!",
        Icon = "check",
        Duration = 3
    }
})

-- Вариант 2: Динамическое подключение уведомления через метод
local ActionBtn = MainSection:Button({
    Name = "Execute Script",
    Callback = function()
        -- действие
    end
})

ActionBtn:SetNotification({
    Title = "Executed",
    Description = "Script executed successfully!",
    Icon = "sparkles",
    Duration = 3.5
})
```

#### Отдельный Кейбинд (Keybind)
Автономная настройка горячей клавиши (отображается в Keybind Menu):

```lua
MainSection:Keybind({
    Name = "Panic Key",
    Default = Enum.KeyCode.P,
    Flag = "panic_key",
    Callback = function()
        Jade:Notification({
            Title = "Panic",
            Description = "Panic button triggered!",
            Icon = "triangle-alert",
            Duration = 2.5
        })
    end
})
```

#### Поле ввода (Input)
```lua
MainSection:Input({
    Name = "Custom Tag",
    Placeholder = "Enter text...",
    Flag = "custom_tag",
    Callback = function(Text)
        print("Input:", Text)
    end
})
```

#### Палитра цветов (Colorpicker)
```lua
MainSection:Colorpicker({
    Name = "Chams Color",
    Default = Color3.fromRGB(0, 255, 140),
    Flag = "chams_color",
    Callback = function(Color)
        -- применить цвет
    end
})
```

---

### Система уведомлений (Notifications)

Вызов всплывающего баннера из любой части кода:

```lua
Jade:Notification({
    Title = "jade.xyz",
    Description = "Config loaded successfully!",
    Icon = "bell",      -- Иконка из библиотеки
    Duration = 4        -- Время показа в секундах
})
```

### Ватермарка (Watermark)

Включает информационную панель в углу экрана (с FPS, задержкой и сервером):

```lua
Window:Watermark({
    Name = "jade.xyz",
    Icon = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/asset_23de81e2.png"
})
```

### Модальное окно подтверждения (Confirm Dialog)

Специальное окно для критических действий:

```lua
Jade:Confirm({
    Title = "Delete Config",
    Text = "Are you sure you want to delete this file?",
    YesText = "Delete",
    NoText = "Cancel",
    OnConfirm = function()
        print("Confirmed!")
    end,
    OnCancel = function()
        print("Cancelled!")
    end
})
```

---

## 4. Готовый шаблон скрипта

```lua
local Jade = loadstring(game:HttpGet("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/library"))()

-- Экран загрузки
Jade:ShowLoader({})

-- Окно
local Window = Jade:Window({
    Name = "jade.xyz | Template",
    Icon = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/asset_23de81e2.png",
    IconSize = 38
})

-- Вкладка Main
local Tab = Window:Tab({Name = "General", Icon = "home"})
local Sub = Tab:SubTab({Name = "Features", Icon = "zap"})
local Sec = Sub:Section({Name = "My Section", Side = 1})

local Tog = Sec:Toggle({Name = "Test Toggle", Default = false, Flag = "tog_test"})
Tog:Keybind({Default = Enum.KeyCode.X, Flag = "tog_key"})

Sec:Slider({Name = "Speed", Min = 1, Max = 100, Default = 16, Flag = "speed_val"})

-- Вкладка Settings с встроенной системой тем, шрифтов и конфигов
local Settings = Window:Tab({Name = "Settings", Icon = "settings"})
local ConfigSub = Settings:SubTab({Name = "Profiles", Icon = "save"})
ConfigSub:ThemeConfig({})

-- Ватермарка
Window:Watermark({
    Name = "jade.xyz",
    Icon = "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/asset_23de81e2.png"
})
```
