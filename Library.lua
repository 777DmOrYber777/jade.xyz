if getgenv().Jade and getgenv().Jade.Unload then
    getgenv().Jade:Unload()
end

if getgenv().Zolar and getgenv().Zolar.Unload then
    getgenv().Zolar:Unload()
end

local Library = { } do
    local cloneref = cloneref or function(Object)
        return Object
    end

    local Players = cloneref(game:GetService("Players"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local RunService = cloneref(game:GetService("RunService"))
    local TweenService = cloneref(game:GetService("TweenService"))
    local HttpService = cloneref(game:GetService("HttpService"))
    local GuiService = cloneref(game:GetService("GuiService"))
    local TextService = cloneref(game:GetService("TextService"))
    local StatsService = cloneref(game:GetService("Stats"))
    local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
    local ContentProvider = cloneref(game:GetService("ContentProvider"))

    local LocalPlayer = Players.LocalPlayer
    local GuiInset = GuiService:GetGuiInset().Y
    local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local GetHui = gethui or function()
        return cloneref(game:GetService("CoreGui"))
    end

    Library.Directory = "Jade"
    Library.ConfigFolder = "Jade/Configs"
    Library.AssetsFolder = "Jade/Assets"
    Library.GitHubUser = "777DmOrYber777"
    Library.GitHubRepo = "jade.xyz"
    Library.GitHubBranch = "main"
    Library.GitHubBase = "https://raw.githubusercontent.com/" .. Library.GitHubUser .. "/" .. Library.GitHubRepo .. "/" .. Library.GitHubBranch

    if isfolder then
        for _, Folder in { Library.Directory, Library.ConfigFolder, Library.AssetsFolder } do
            if not isfolder(Folder) then
                makefolder(Folder)
            end
        end
    end

    local UiFont
    local UiFontBold

    Library.FontTrackedObjects = { }
    Library.FontFile = "Jade/Font.json"
    Library.CurrentFontName = "PixelCode"
    Library.LoadedFonts = { }
    Library.LoaderActive = false
    Library.LoaderFinishedCallbacks = { }

    Library.FontDefinitions = {
        ["PixelCode"] = {
            Name = "PixelCode",
            DisplayName = "PixelCode (Default)",
            Regular = {
                File = "PixelCode",
                Ext = "ttf",
                Url = Library.GitHubBase .. "/PixelCode.ttf",
                Weight = 400
            },
            Bold = {
                File = "PixelCode-Bold",
                Ext = "ttf",
                Url = Library.GitHubBase .. "/PixelCode-Bold.ttf",
                Weight = 700
            }
        },
        ["Tamzen"] = {
            Name = "Tamzen",
            DisplayName = "Tamzen",
            Regular = {
                File = "Tamzen",
                Ext = "ttf",
                Url = Library.GitHubBase .. "/Tamzen.ttf",
                Weight = 400
            },
            Bold = {
                File = "Tamzen-Bold",
                Ext = "ttf",
                Url = Library.GitHubBase .. "/Tamzen-Bold.ttf",
                Weight = 700
            }
        },
        ["Spleen"] = {
            Name = "Spleen",
            DisplayName = "Spleen 8x16",
            Regular = {
                File = "Spleen",
                Ext = "otf",
                Url = "https://raw.githubusercontent.com/fcambus/spleen/master/spleen-8x16.otf",
                Weight = 400
            }
        },
        ["Gotham"] = {
            Name = "Gotham",
            DisplayName = "Gotham (Clean)",
            FontEnum = Enum.Font.Gotham,
            BoldFontEnum = Enum.Font.GothamBold,
            BuiltIn = true
        }
    }

    local CustomFont = { } do
        local FontMagics = {
            "\0\1\0\0",
            "OTTO",
            "true",
            "ttcf",
            "wOFF"
        }

        local function LooksLikeFont(Body)
            if type(Body) ~= "string" or #Body < 4096 then
                return false
            end

            local Head = string.sub(Body, 1, 4)

            for _, Magic in FontMagics do
                if Head == Magic then
                    return true
                end
            end

            return false
        end

        function CustomFont:New(Name, Weight, Style, Data)
            Data = Data or { }
            local Ext = Data.Ext or "ttf"
            local JsonPath = Library.AssetsFolder .. "/" .. Name .. ".json"
            local FontPath = Library.AssetsFolder .. "/" .. Name .. "." .. Ext

            if isfile and isfile(FontPath) and not LooksLikeFont(readfile(FontPath)) then
                pcall(delfile, FontPath)
            end

            if not isfile or not isfile(FontPath) then
                if Data.Url and game and game.HttpGet then
                    local Ok, Body = pcall(function()
                        return game:HttpGet(Data.Url)
                    end)

                    if Ok and LooksLikeFont(Body) and writefile then
                        writefile(FontPath, Body)
                    end
                end
            end

            if not isfile or not isfile(FontPath) or not getcustomasset then
                return nil
            end

            local FontData = {
                name = Name,
                faces = {
                    {
                        name = "Regular",
                        weight = Weight or 400,
                        style = Style or "normal",
                        assetId = getcustomasset(FontPath)
                    }
                }
            }

            if writefile then
                pcall(function()
                    writefile(JsonPath, HttpService:JSONEncode(FontData))
                end)
            end

            local Asset = getcustomasset(JsonPath)
            return Font.new(Asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end
    end

    Library.LoadFontFamily = function(Self, Key)
        local Def = Library.FontDefinitions[Key]
        if not Def then return nil end

        if Library.LoadedFonts[Key] then
            return Library.LoadedFonts[Key]
        end

        if Def.FontEnum then
            local Loaded = {
                Regular = Font.fromEnum(Def.FontEnum),
                Bold = Font.fromEnum(Def.BoldFontEnum or Def.FontEnum)
            }
            Library.LoadedFonts[Key] = Loaded
            return Loaded
        end

        local RegFont, BoldFont
        pcall(function()
            RegFont = CustomFont:New(Def.Regular.File, Def.Regular.Weight or 400, "normal", Def.Regular)
        end)

        if Def.Bold then
            pcall(function()
                BoldFont = CustomFont:New(Def.Bold.File, Def.Bold.Weight or 700, "normal", Def.Bold)
            end)
        end

        if not RegFont then
            return nil
        end

        local Loaded = {
            Regular = RegFont,
            Bold = BoldFont or RegFont
        }

        Library.LoadedFonts[Key] = Loaded
        return Loaded
    end

    Library.SetFont = function(Self, FontKey, NoSave)
        local Loaded = Library:LoadFontFamily(FontKey)
        if not Loaded then
            -- Fallback
            if FontKey ~= "PixelCode" then
                Loaded = Library:LoadFontFamily("PixelCode")
            end
        end

        if not Loaded then
            UiFont = Font.fromEnum(Enum.Font.Code)
            UiFontBold = UiFont
        else
            UiFont = Loaded.Regular
            UiFontBold = Loaded.Bold
        end

        Library.Font = UiFont
        Library.TitleFont = UiFontBold
        Library.CurrentFontName = FontKey

        for Object, IsBold in pairs(Library.FontTrackedObjects) do
            pcall(function()
                if Object and Object.Parent then
                    Object.FontFace = IsBold and UiFontBold or UiFont
                else
                    Library.FontTrackedObjects[Object] = nil
                end
            end)
        end

        if not NoSave and writefile then
            pcall(function()
                writefile(Library.FontFile, HttpService:JSONEncode({ Font = FontKey }))
            end)
        end

        if Library.UpdateFontUI then
            Library:UpdateFontUI(FontKey)
        end

        return true
    end

    -- Initial font load: saved choice or default PixelCode
    local InitialFont = "PixelCode"
    pcall(function()
        if isfile and isfile(Library.FontFile) then
            local Decoded = HttpService:JSONDecode(readfile(Library.FontFile))
            if Decoded and Decoded.Font and Library.FontDefinitions[Decoded.Font] then
                InitialFont = Decoded.Font
            end
        end
    end)

    Library:SetFont(InitialFont, true)
    if not UiFont then
        UiFont = Font.fromEnum(Enum.Font.Code)
        UiFontBold = UiFont
        Library.Font = UiFont
        Library.TitleFont = UiFontBold
    end

    local IconPack

    pcall(function()
        local Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
        IconPack = loadstring(game:HttpGetAsync(Url))()
        IconPack.SetIconsType("lucide")
    end)

    local function ResolveCustomAsset(UrlOrPath)
        if not getcustomasset or not isfile or not writefile then
            return UrlOrPath
        end

        if isfile(UrlOrPath) then
            return getcustomasset(UrlOrPath)
        end

        if string.match(UrlOrPath, "^https?://") then
            -- Normalize GitHub URLs to raw format
            local CleanUrl = string.gsub(UrlOrPath, "github%.com/([^/]+)/([^/]+)/blob/", "raw.githubusercontent.com/%1/%2/")
            CleanUrl = string.gsub(CleanUrl, "%?raw=true$", "")
            CleanUrl = string.gsub(CleanUrl, "%?raw=true&", "?")

            local Ext = string.match(CleanUrl, "%.([a-zA-Z0-9]+)%?") or string.match(CleanUrl, "%.([a-zA-Z0-9]+)$") or "png"
            local Hash = 0
            for i = 1, #CleanUrl do
                Hash = (Hash * 31 + string.byte(CleanUrl, i)) % 2147483647
            end

            local LocalPath = Library.AssetsFolder .. "/asset_" .. string.format("%x", Hash) .. "." .. Ext

            if not isfile(LocalPath) then
                local Ok, Content = pcall(function()
                    return game:HttpGet(CleanUrl)
                end)

                if Ok and Content and #Content > 0 then
                    writefile(LocalPath, Content)
                else
                    return "rbxassetid://0"
                end
            end

            if isfile(LocalPath) then
                return getcustomasset(LocalPath)
            end
        end

        return UrlOrPath
    end

    local function ResolveIcon(Icon)
        if type(Icon) == "number" then
            return "rbxassetid://" .. Icon
        end

        if type(Icon) ~= "string" then
            return "rbxassetid://0"
        end

        if string.match(Icon, "^rbxassetid://") or string.match(Icon, "^rbxasset://") then
            return Icon
        end

        if string.match(Icon, "^%d+$") then
            return "rbxassetid://" .. Icon
        end

        if string.match(Icon, "^https?://") or (isfile and isfile(Icon)) then
            return ResolveCustomAsset(Icon)
        end

        if IconPack then
            local Ok, Result = pcall(function()
                return IconPack.GetIcon(Icon)
            end)

            if Ok and Result and Result ~= "rbxassetid://0" then
                return Result
            end
        end

        return "rbxassetid://0"
    end

    local function ToVector2(Value)
        if typeof(Value) == "Vector2" then
            return Value
        end

        if type(Value) == "table" then
            return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0)
        end

        return Vector2.new(0, 0)
    end

    local function ApplyIcon(Object, Icon)
        if not Icon then return end

        local Image, Offset, Size = ResolveIcon(Icon)

        Object.Image = Image
        Object.ImageRectOffset = ToVector2(Offset)
        Object.ImageRectSize = ToVector2(Size)
    end

    local function MeasureText(Text, Size, Width, FontFace)
        local Ok, Bounds = pcall(function()
            return TextService:GetTextBoundsAsync({
                Text = Text,
                Font = FontFace or UiFont,
                Size = Size,
                Width = Width
            })
        end)

        if Ok and Bounds then
            return Bounds
        end

        local Estimate = math.min(#Text * Size * 0.52, Width)
        return Vector2.new(Estimate, Size * 1.25)
    end

    Library.__index = Library
    Library.Version = "1.1"
    Library.WindowWidth = 716
    Library.WindowHeight = 540

    Library.Theme = {
        Background = Color3.fromRGB(0, 0, 0),
        Section = Color3.fromRGB(8, 11, 10),
        Element = Color3.fromRGB(14, 18, 16),
        Light = Color3.fromRGB(22, 28, 25),
        Hover = Color3.fromRGB(30, 38, 34),
        Line = Color3.fromRGB(18, 24, 21),
        Text = Color3.fromRGB(245, 255, 250),
        DimText = Color3.fromRGB(115, 140, 130),
        DimIcon = Color3.fromRGB(115, 140, 130),
        Accent = Color3.fromRGB(0, 229, 140)
    }

    Library.CurrentThemeName = "Pitch Black Jade"

    Library.AccentPresets = {
        Color3.fromRGB(0, 229, 140),
        Color3.fromRGB(0, 255, 180),
        Color3.fromRGB(68, 255, 210),
        Color3.fromRGB(57, 255, 110),
        Color3.fromRGB(0, 235, 200),
        Color3.fromRGB(0, 204, 136)
    }

    local function MakePreset(Name, Colors)
        local Preset = {
            Name = Name,
            Swatch = Colors.Swatch or Colors.Accent
        }

        for Key, Value in Colors do
            Preset[Key] = Value
        end

        return Preset
    end

    Library.ThemePresets = {
        MakePreset("Pitch Black Jade", {
            Background = Color3.fromRGB(0, 0, 0),
            Section = Color3.fromRGB(8, 11, 10),
            Element = Color3.fromRGB(14, 18, 16),
            Light = Color3.fromRGB(22, 28, 25),
            Hover = Color3.fromRGB(30, 38, 34),
            Line = Color3.fromRGB(18, 24, 21),
            Text = Color3.fromRGB(245, 255, 250),
            DimText = Color3.fromRGB(115, 140, 130),
            DimIcon = Color3.fromRGB(115, 140, 130),
            Accent = Color3.fromRGB(0, 229, 140),
            Swatch = Color3.fromRGB(0, 229, 140)
        }),
        MakePreset("Neon Jade", {
            Background = Color3.fromRGB(6, 12, 9),
            Section = Color3.fromRGB(11, 19, 15),
            Element = Color3.fromRGB(17, 28, 23),
            Light = Color3.fromRGB(25, 40, 33),
            Hover = Color3.fromRGB(33, 52, 43),
            Line = Color3.fromRGB(20, 34, 28),
            Text = Color3.fromRGB(238, 250, 244),
            DimText = Color3.fromRGB(110, 145, 132),
            DimIcon = Color3.fromRGB(110, 145, 132),
            Accent = Color3.fromRGB(0, 255, 180),
            Swatch = Color3.fromRGB(0, 255, 180)
        }),
        MakePreset("Electric Mint", {
            Background = Color3.fromRGB(3, 9, 8),
            Section = Color3.fromRGB(9, 18, 16),
            Element = Color3.fromRGB(15, 27, 24),
            Light = Color3.fromRGB(23, 39, 35),
            Hover = Color3.fromRGB(31, 51, 46),
            Line = Color3.fromRGB(19, 33, 29),
            Text = Color3.fromRGB(242, 255, 252),
            DimText = Color3.fromRGB(112, 152, 144),
            DimIcon = Color3.fromRGB(112, 152, 144),
            Accent = Color3.fromRGB(68, 255, 210),
            Swatch = Color3.fromRGB(68, 255, 210)
        }),
        MakePreset("Toxic Cyber", {
            Background = Color3.fromRGB(4, 8, 3),
            Section = Color3.fromRGB(10, 16, 8),
            Element = Color3.fromRGB(16, 25, 13),
            Light = Color3.fromRGB(25, 38, 21),
            Hover = Color3.fromRGB(34, 50, 29),
            Line = Color3.fromRGB(20, 31, 17),
            Text = Color3.fromRGB(246, 255, 240),
            DimText = Color3.fromRGB(128, 155, 116),
            DimIcon = Color3.fromRGB(128, 155, 116),
            Accent = Color3.fromRGB(57, 255, 110),
            Swatch = Color3.fromRGB(57, 255, 110)
        }),
        MakePreset("Abyssal Jade", {
            Background = Color3.fromRGB(2, 7, 8),
            Section = Color3.fromRGB(7, 15, 18),
            Element = Color3.fromRGB(12, 23, 27),
            Light = Color3.fromRGB(18, 35, 40),
            Hover = Color3.fromRGB(25, 46, 53),
            Line = Color3.fromRGB(15, 29, 34),
            Text = Color3.fromRGB(236, 253, 255),
            DimText = Color3.fromRGB(102, 146, 156),
            DimIcon = Color3.fromRGB(102, 146, 156),
            Accent = Color3.fromRGB(0, 235, 200),
            Swatch = Color3.fromRGB(0, 235, 200)
        }),
        MakePreset("Classic Jadeite", {
            Background = Color3.fromRGB(9, 14, 12),
            Section = Color3.fromRGB(15, 22, 19),
            Element = Color3.fromRGB(22, 32, 28),
            Light = Color3.fromRGB(30, 44, 38),
            Hover = Color3.fromRGB(38, 56, 48),
            Line = Color3.fromRGB(24, 36, 31),
            Text = Color3.fromRGB(240, 248, 244),
            DimText = Color3.fromRGB(118, 142, 132),
            DimIcon = Color3.fromRGB(118, 142, 132),
            Accent = Color3.fromRGB(0, 204, 136),
            Swatch = Color3.fromRGB(0, 204, 136)
        })
    }

    Library.ThemeKeys = {
        "Background",
        "Section",
        "Element",
        "Light",
        "Line",
        "Text",
        "DimText"
    }

    local function DeriveTheme()
        local T = Library.Theme

        T.AccentDark = T.Accent:Lerp(Color3.new(0, 0, 0), 0.44)
        T.AccentDeep = T.Accent:Lerp(Color3.new(0, 0, 0), 0.24)
        T.Ripple = T.Accent:Lerp(Color3.new(1, 1, 1), 0.12)
        T.AccentSoft = T.Accent:Lerp(T.Background, 0.72)
    end

    DeriveTheme()

    Library.Flags = { }
    Library.SetFlags = { }
    Library.Connections = { }
    Library.Threads = { }
    Library.ThemingStuff = { }
    Library.ThemeMap = { }
    Library.AccentGradients = { }
    Library.AccentShadows = { }
    Library.OpenFrames = { }
    Library.Windows = { }
    Library.Notifs = { }
    Library.TouchButtons = { }
    Library.TouchShields = { }
    Library.Searchables = { }
    Library.MenuKeybind = Enum.KeyCode.G
    Library.Binding = false
    Library.UserScale = 1
    Library.Silent = false
    Library.ThemeDirty = false
    Library.PreloadDirty = false
    Library.PreloadClock = 0
    Library.Preloaded = setmetatable({ }, { __mode = "k" })
    Library.Animation = {
        Time = 0.25,
        Style = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out
    }

    Library.Create = function(Self, Class, Properties)
        local Data = {
            Class = Class,
            Instance = Instance.new(Class)
        }

        for Property, Value in Properties do
            if Property == "Name" then
                Data.Instance.Name = "\0"
                continue
            end

            Data.Instance[Property] = Value
        end

        if Class == "ImageLabel" or Class == "ImageButton" then
            Library.PreloadDirty = true
        end

        if Library.SeedBaseline then
            Library:SeedBaseline(Data.Instance)
        end

        return setmetatable(Data, Library)
    end

    Library.PreloadAll = function(Self)
        local Roots = {
            Library.Holder,
            Library.PopupHolder,
            Library.UnusedHolder
        }

        local Assets = { }

        for _, Root in Roots do
            if not Root or not Root.Instance then continue end

            for _, Child in Root.Instance:GetDescendants() do
                if Library.Preloaded[Child] then continue end
                if not Child:IsA("ImageLabel") and not Child:IsA("ImageButton") then continue end
                if Child.Image == "" then continue end

                Library.Preloaded[Child] = true
                table.insert(Assets, Child)
            end
        end

        if #Assets == 0 then return end

        Library:Thread(function()
            pcall(function()
                ContentProvider:PreloadAsync(Assets)
            end)
        end)
    end

    Library.Connect = function(Self, Signal, Callback)
        local Connection

        if type(Signal) == "string" and Self.Instance then
            local IsClick = Signal == "MouseButton1Down" or Signal == "MouseButton1Click"

            if IsMobile and IsClick and Self.Instance:IsA("GuiButton") then
                local LastFire = 0

                local function Fire(Input)
                    local Now = os.clock()
                    if Now - LastFire < 0.25 then return end
                    LastFire = Now
                    Callback(Input)
                end

                table.insert(Library.TouchButtons, {
                    Instance = Self.Instance,
                    Fire = Fire
                })

                Connection = Self.Instance.Activated:Connect(function(Input)
                    Fire(Input)
                end)
            else
                Connection = Self.Instance[Signal]:Connect(Callback)
            end
        else
            Connection = Signal:Connect(Callback)
        end

        table.insert(Library.Connections, Connection)
        return Connection
    end

    Library.Thread = function(Self, Function)
        local NewThread = task.spawn(Function)
        table.insert(Library.Threads, NewThread)
        return NewThread
    end

    Library.SafeCall = function(Self, Function, ...)
        if type(Function) ~= "function" then return end

        local Success, Result = pcall(Function, ...)
        if not Success then warn(Result) end

        return Success, Result
    end

    Library.Round = function(Self, Number, Float)
        Float = Float or 1

        local Result = math.floor(Number / Float + 0.5) * Float
        local Places = math.max(0, math.ceil(-math.log(Float, 10)))

        return tonumber(string.format("%." .. Places .. "f", Result))
    end

    Library.Tween = function(Self, Properties, Info, RawItem)
        local Object = RawItem or Self.Instance

        Info = Info or TweenInfo.new(
            Library.Animation.Time,
            Library.Animation.Style,
            Library.Animation.Direction
        )

        local NewTween = TweenService:Create(Object, Info, Properties)
        NewTween:Play()

        return NewTween
    end

    Library.GetTweenProperty = function(Self, RawItem)
        local Object = RawItem or Self.Instance

        if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
            return { "BackgroundTransparency", "ImageTransparency" }
        elseif Object:IsA("ScrollingFrame") then
            return { "BackgroundTransparency", "ScrollBarImageTransparency" }
        elseif Object:IsA("Frame") then
            return { "BackgroundTransparency" }
        elseif Object:IsA("UIStroke") then
            return { "Transparency" }
        elseif Object.ClassName == "UIShadow" then
            return { "Transparency" }
        end
    end

    Library.RestingValues = setmetatable({ }, { __mode = "k" })
    Library.Baselines = setmetatable({ }, { __mode = "k" })
    Library.FadeTokens = setmetatable({ }, { __mode = "k" })

    local function BumpFadeToken(Root)
        local Next = (Library.FadeTokens[Root] or 0) + 1
        Library.FadeTokens[Root] = Next
        return Next
    end

    local function CollectFadeable(Root)
        local Children = Root:GetDescendants()
        table.insert(Children, Root)
        return Children
    end

    local function ForEachFadeable(Children, Handler)
        for _, Child in Children do
            local Properties = Library:GetTweenProperty(Child)
            if not Properties then continue end

            for _, Property in Properties do
                Handler(Child, Property)
            end
        end
    end

    local function RestoreResting(Children)
        ForEachFadeable(Children, function(Child, Property)
            local Resting = Library:ReleaseResting(Child, Property)

            if Resting ~= nil then
                Child[Property] = Resting
            end
        end)
    end

    Library.SetBaseline = function(Self, Object, Property, Value)
        local Store = Library.Baselines[Object]

        if not Store then
            Store = { }
            Library.Baselines[Object] = Store
        end

        Store[Property] = Value
    end

    Library.SeedBaseline = function(Self, Object)
        local Properties = Library:GetTweenProperty(Object)
        if not Properties then return end

        for _, Property in Properties do
            local Store = Library.Baselines[Object]

            if not Store or Store[Property] == nil then
                Library:SetBaseline(Object, Property, Object[Property])
            end
        end
    end

    Library.CaptureResting = function(Self, Object, Property)
        local Store = Library.RestingValues[Object]

        if not Store then
            Store = { }
            Library.RestingValues[Object] = Store
        end

        if Store[Property] == nil then
            local Base = Library.Baselines[Object]
            local Known = Base and Base[Property]

            Store[Property] = Known ~= nil and Known or Object[Property]

            if Known == nil then
                Library:SetBaseline(Object, Property, Store[Property])
            end
        end

        return Store[Property]
    end

    Library.ReleaseResting = function(Self, Object, Property)
        local Store = Library.RestingValues[Object]
        if not Store then return nil end

        local Value = Store[Property]
        Store[Property] = nil

        return Value
    end

    Library.StampResting = function(Self, Object, Property, Value)
        local Store = Library.RestingValues[Object]

        if not Store then
            Store = { }
            Library.RestingValues[Object] = Store
        end

        Store[Property] = Value
        Library:SetBaseline(Object, Property, Value)
    end

    Library.HardRestore = function(Self)
        local Root = Self.Instance
        BumpFadeToken(Root)

        ForEachFadeable(CollectFadeable(Root), function(Child, Property)
            local Base = Library.Baselines[Child]
            if not Base then return end

            Library:ReleaseResting(Child, Property)

            if Base[Property] ~= nil then
                pcall(function()
                    Child[Property] = Base[Property]
                end)
            end
        end)
    end

    Library.Fade = function(Self, Property, Visibility, RawItem)
        local Object = RawItem or Self.Instance
        local Resting = Library:CaptureResting(Object, Property)
        local Target = Visibility and Resting or 1

        if Visibility then
            Object[Property] = 1
        end

        local Ok = pcall(function()
            Library:Tween({ [Property] = Target }, nil, Object)
        end)

        if not Ok then
            pcall(function()
                Object[Property] = Target
            end)
        end
    end

    Library.FadeDescendants = function(Self, Visibility, Callback)
        local Root = Self.Instance
        local Token = BumpFadeToken(Root)

        if Visibility then
            Root.Visible = true
        end

        local Children = CollectFadeable(Root)

        ForEachFadeable(Children, function(Child, Property)
            Library:Fade(Property, Visibility, Child)
        end)

        task.delay(Library.Animation.Time + 0.03, function()
            if Library.FadeTokens[Root] == Token then
                Root.Visible = Visibility
                RestoreResting(Children)
            end

            if Callback then Callback() end
        end)
    end

    Library.CancelFade = function(Self)
        BumpFadeToken(Self.Instance)
    end

    Library.ResetFade = function(Self)
        local Root = Self.Instance
        BumpFadeToken(Root)
        RestoreResting(CollectFadeable(Root))
    end

    Library.AddToTheme = function(Self, Properties)
        local Object = Self.Instance

        local ThemeData = {
            Item = Object,
            Properties = Properties
        }

        for Property, Value in Properties do
            if type(Value) == "string" then
                Object[Property] = Library.Theme[Value]
            else
                Object[Property] = Value()
            end
        end

        table.insert(Library.ThemingStuff, ThemeData)
        Library.ThemeMap[Object] = ThemeData

        return Self
    end

    Library.ChangeItemTheme = function(Self, Properties)
        local Object = Self.Instance
        if not Library.ThemeMap[Object] then return end
        Library.ThemeMap[Object].Properties = Properties
    end

    local function AccentSequence()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Theme.Accent),
            ColorSequenceKeypoint.new(1, Library.Theme.AccentDark)
        })
    end

    Library.RegisterGradient = function(Self, Gradient)
        Gradient.Color = AccentSequence()
        table.insert(Library.AccentGradients, Gradient)
    end

    Library.ApplyThemeInstant = function(Self)
        local i = 1
        while i <= #Library.ThemingStuff do
            local Item = Library.ThemingStuff[i]
            local Instance = Item and Item.Item
            if not Instance or not Instance.Parent then
                table.remove(Library.ThemingStuff, i)
            else
                for Property, Value in Item.Properties do
                    pcall(function()
                        if type(Value) == "string" then
                            Instance[Property] = Library.Theme[Value]
                        elseif type(Value) == "function" then
                            Instance[Property] = Value()
                        end
                    end)
                end
                i = i + 1
            end
        end

        for _, Gradient in Library.AccentGradients do
            pcall(function()
                Gradient.Color = AccentSequence()
            end)
        end

        for _, Shadow in Library.AccentShadows do
            pcall(function()
                Shadow.Color = Library.Theme.Accent
            end)
        end

        if Library.TitleText and Library.TitleText.Instance then
            pcall(function()
                Library.TitleText.Instance.TextColor3 = Library.Theme.Accent
                Library.TitleText.Instance.TextTransparency = 0
            end)
        end

        if Library.UpdateFontUI then
            pcall(Library.UpdateFontUI)
        end
    end

    Library.ThemeFile = "Jade/Theme.json"

    Library.SaveTheme = function(Self)
        if not writefile then return end
        pcall(function()
            local Data = {
                Name = Library.CurrentThemeName or "Pitch Black Jade",
                Accent = {
                    R = Library.Theme.Accent.R,
                    G = Library.Theme.Accent.G,
                    B = Library.Theme.Accent.B
                }
            }
            writefile(Library.ThemeFile, HttpService:JSONEncode(Data))
        end)
    end

    Library.LoadSavedTheme = function(Self)
        if not isfile or not readfile or not isfile(Library.ThemeFile) then return false end
        local Success = false
        pcall(function()
            local Raw = readfile(Library.ThemeFile)
            local Decoded = HttpService:JSONDecode(Raw)
            if Decoded and Decoded.Name then
                Library:SetTheme(Decoded.Name, true)
                if Decoded.Accent and type(Decoded.Accent) == "table" and Decoded.Accent.R then
                    Library.Theme.Accent = Color3.new(Decoded.Accent.R, Decoded.Accent.G, Decoded.Accent.B)
                    DeriveTheme()
                    Library.ThemeDirty = true
                end
                Success = true
            end
        end)
        return Success
    end

    Library.SetAccent = function(Self, Color)
        Library.Theme.Accent = Color
        DeriveTheme()
        Library.ThemeDirty = true
        Library:SaveTheme()
    end

    Library.SetThemeColor = function(Self, Key, Color)
        Library.Theme[Key] = Color
        DeriveTheme()
        Library.ThemeDirty = true
        Library:SaveTheme()
    end

    Library.SetTheme = function(Self, Preset, NoSave)
        if type(Preset) == "string" then
            for _, Entry in Library.ThemePresets do
                if Entry.Name == Preset then
                    Preset = Entry
                    break
                end
            end
        end

        if type(Preset) ~= "table" then return end

        for Key, Value in Preset do
            if Key ~= "Name" and Key ~= "Swatch" and typeof(Value) == "Color3" then
                Library.Theme[Key] = Value
            end
        end

        Library.CurrentThemeName = Preset.Name or Library.CurrentThemeName

        DeriveTheme()
        Library.ThemeDirty = true

        if not NoSave then
            Library:SaveTheme()
        end

        if Library.UpdateThemeUI then
            Library:UpdateThemeUI(Preset)
        end

        if Library.TitleText and Library.TitleText.Instance then
            pcall(function()
                Library.TitleText.Instance.TextColor3 = Library.Theme.Accent
                Library.TitleText.Instance.TextTransparency = 0
            end)
        end

        if Library.KeybindMenuEnabled and Library.UpdateKeybindMenu then
            Library:UpdateKeybindMenu()
        end
    end

    pcall(function()
        Library:LoadSavedTheme()
    end)

    Library.OnHover = function(Self, OnEnter, OnLeave)
        Library:Connect(Self.Instance.MouseEnter, OnEnter)
        Library:Connect(Self.Instance.MouseLeave, OnLeave)
    end

    Library.GetScreenScale = function(Self)
        if Library.UIScale and Library.UIScale.Instance then
            return Library.UIScale.Instance.Scale
        end

        return 1
    end

    local function IsOverObject(Object)
        local Position = UserInputService:GetMouseLocation() - Vector2.new(0, GuiInset)
        local Corner = Object.AbsolutePosition
        local Size = Object.AbsoluteSize

        return Position.X >= Corner.X
        and Position.X <= Corner.X + Size.X
        and Position.Y >= Corner.Y
        and Position.Y <= Corner.Y + Size.Y
    end

    Library.IsMouseOverFrame = function(Self)
        return IsOverObject(Self.Instance)
    end

    local function IsOverAnyPopup()
        for Panel in Library.TouchShields do
            if not Panel.Parent then continue end
            if not Panel.Visible then continue end
            if IsOverObject(Panel) then return true end
        end

        return false
    end

    Library.MakeDraggable = function(Self, Handle)
        local Gui = Self.Instance
        Handle = Handle or Gui
        Handle.Active = true

        local Dragging = false
        local DragStart
        local StartPosition
        local InputChanged

        local function Set(Input)
            local Scale = Library:GetScreenScale()
            local DragDelta = (Input.Position - DragStart) / Scale
            local NewX = StartPosition.X + DragDelta.X
            local NewY = StartPosition.Y + DragDelta.Y

            local ScreenSize = Gui.Parent.AbsoluteSize / Scale
            local GuiSize = Gui.AbsoluteSize / Scale
            local Anchor = Gui.AnchorPoint

            NewX = math.clamp(NewX, GuiSize.X * Anchor.X, ScreenSize.X - GuiSize.X * (1 - Anchor.X))
            NewY = math.clamp(NewY, GuiSize.Y * Anchor.Y, ScreenSize.Y - GuiSize.Y * (1 - Anchor.Y))

            local Info = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            Self:Tween({ Position = UDim2.fromOffset(NewX, NewY) }, Info)
        end

        Library:Connect(Handle.InputBegan, function(Input)
            local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if not IsClick and not IsTouch then return end
            if IsOverAnyPopup() then return end

            Dragging = true
            DragStart = Input.Position

            local Scale = Library:GetScreenScale()
            local ParentSize = Gui.Parent.AbsoluteSize / Scale

            StartPosition = Vector2.new(
                Gui.Position.X.Scale * ParentSize.X + Gui.Position.X.Offset,
                Gui.Position.Y.Scale * ParentSize.Y + Gui.Position.Y.Offset
            )

            if InputChanged then return end

            InputChanged = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                    InputChanged:Disconnect()
                    InputChanged = nil
                end
            end)
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            local IsMove = Input.UserInputType == Enum.UserInputType.MouseMovement
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if (IsMove or IsTouch) and Dragging then
                Set(Input)
            end
        end)
    end

    Library.Unload = function(Self)
        for _, Connection in Library.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end

        if Library.AnimBgConnection then
            pcall(function() Library.AnimBgConnection:Disconnect() end)
            Library.AnimBgConnection = nil
        end



        if Library.KeybindRoot and Library.KeybindRoot.Instance then
            pcall(function() Library.KeybindRoot.Instance:Destroy() end)
            Library.KeybindRoot = nil
            Library.KeybindBody = nil
            Library.KeybindListContainer = nil
        end

        pcall(function() UserInputService.MouseIconEnabled = true end)

        for _, Thread in Library.Threads do
            pcall(coroutine.close, Thread)
        end

        for _, Root in { Library.Holder, Library.PopupHolder, Library.UnusedHolder } do
            if Root then Root.Instance:Destroy() end
        end

        getgenv().Jade = nil
        getgenv().Zolar = nil
    end

    Library.Holder = Library:Create("ScreenGui", {
        Parent = GetHui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000
    })

    Library.PopupHolder = Library:Create("ScreenGui", {
        Parent = GetHui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1001
    })

    Library.UnusedHolder = Library:Create("ScreenGui", {
        Parent = GetHui(),
        Name = "\0",
        Enabled = false,
        ResetOnSpawn = false
    })

    do
        local Probe = Library:Create("Frame", {
            Parent = Library.Holder.Instance,
            Name = "\0",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(1, 1),
            BorderSizePixel = 0
        })

        task.defer(function()
            GuiInset = -Probe.Instance.AbsolutePosition.Y
            Probe.Instance:Destroy()
        end)
    end

    Library.UIScale = Library:Create("UIScale", {
        Parent = Library.Holder.Instance,
        Scale = 1
    })

    Library.PopupScale = Library:Create("UIScale", {
        Parent = Library.PopupHolder.Instance,
        Scale = 1
    })

    local function Corner(Object, Radius)
        Library:Create("UICorner", {
            Parent = Object,
            CornerRadius = UDim.new(0, Radius)
        })
    end

    local function SetRest(Object, Property, Value)
        Object[Property] = Value
        Library:StampResting(Object, Property, Value)
    end

    local function MakeFrame(Params)
        local Frame = Library:Create("Frame", {
            Parent = Params.Parent,
            Name = "\0",
            Position = Params.Pos or UDim2.fromOffset(0, 0),
            Size = Params.Size or UDim2.fromOffset(0, 0),
            AnchorPoint = Params.Anchor or Vector2.new(0, 0),
            BackgroundTransparency = Params.Color and 0 or 1,
            ZIndex = Params.Z or 1,
            ClipsDescendants = Params.Clip or false,
            BorderSizePixel = 0,
            BackgroundColor3 = Params.Color and Library.Theme[Params.Color] or Color3.new(1, 1, 1)
        })

        if Params.Color then
            Frame:AddToTheme({ BackgroundColor3 = Params.Color })
        end

        if Params.Raw then
            Frame.Instance.BackgroundColor3 = Params.Raw
            Frame.Instance.BackgroundTransparency = Params.Alpha or 0
            Library:SetBaseline(Frame.Instance, "BackgroundTransparency", Params.Alpha or 0)
        end

        if Params.Round then
            Corner(Frame.Instance, Params.Round)
        end

        return Frame
    end

    local function MakeText(Params)
        local Label = Library:Create("TextLabel", {
            Parent = Params.Parent,
            Name = "\0",
            FontFace = Params.Bold and UiFontBold or UiFont,
            Text = Params.Text or "",
            TextSize = Params.TextSize or 15,
            TextColor3 = Library.Theme[Params.Color or "Text"],
            BackgroundTransparency = 1,
            Position = Params.Pos or UDim2.fromOffset(0, 0),
            Size = Params.Size or UDim2.fromOffset(0, 0),
            AnchorPoint = Params.Anchor or Vector2.new(0, 0),
            TextXAlignment = Params.Align or Enum.TextXAlignment.Left,
            TextTruncate = Params.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
            TextWrapped = Params.Wrap or false,
            ZIndex = Params.Z or 1,
            BorderSizePixel = 0
        }):AddToTheme({ TextColor3 = Params.Color or "Text" })

        Library.FontTrackedObjects[Label.Instance] = Params.Bold and true or false
        return Label
    end

    local function MakeImage(Params)
        local Raw = Params.Raw

        local Image = Library:Create("ImageLabel", {
            Parent = Params.Parent,
            Name = "\0",
            BackgroundTransparency = 1,
            ImageColor3 = Raw or Library.Theme[Params.Color or "DimIcon"],
            Position = Params.Pos or UDim2.fromOffset(0, 0),
            Size = Params.Size or UDim2.fromOffset(16, 16),
            AnchorPoint = Params.Anchor or Vector2.new(0, 0),
            ScaleType = Params.Fit and Enum.ScaleType.Fit or Enum.ScaleType.Stretch,
            ZIndex = Params.Z or 1,
            BorderSizePixel = 0
        })

        if not Raw then
            Image:AddToTheme({ ImageColor3 = Params.Color or "DimIcon" })
        end

        ApplyIcon(Image.Instance, Params.Icon)
        return Image
    end

    local function MakeButton(Params)
        return Library:Create("TextButton", {
            Parent = Params.Parent,
            Name = "\0",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = Params.Pos or UDim2.fromOffset(0, 0),
            Size = Params.Size or UDim2.new(1, 0, 1, 0),
            AnchorPoint = Params.Anchor or Vector2.new(0, 0),
            ZIndex = Params.Z or 5,
            BorderSizePixel = 0
        })
    end

    local function MakeSweep(Parent, Z)
        local Sweep = MakeFrame({
            Parent = Parent,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Color = "Accent",
            Round = 6,
            Z = Z or 5
        })

        Sweep.Instance.BackgroundTransparency = 1
        Library:StampResting(Sweep.Instance, "BackgroundTransparency", 1)

        return Sweep
    end

    local function PlaySweep(Sweep)
        if not Sweep then return end
        local In = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local Out = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        Sweep.Size = UDim2.new(0, 0, 1, 0)
        Sweep.BackgroundTransparency = 1

        Library:Tween({
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.15
        }, In, Sweep)

        task.delay(0.17, function()
            Library:Tween({
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundTransparency = 1
            }, Out, Sweep)
        end)
    end

    local function MakeInput(Params)
        local Input = Library:Create("TextBox", {
            Parent = Params.Parent,
            Name = "\0",
            FontFace = UiFont,
            TextColor3 = Library.Theme.Text,
            PlaceholderColor3 = Library.Theme.DimText,
            PlaceholderText = Params.Placeholder or "",
            Text = Params.Text or "",
            TextSize = Params.TextSize or 15,
            ClearTextOnFocus = false,
            CursorPosition = -1,
            BackgroundTransparency = 1,
            Position = Params.Pos or UDim2.fromOffset(0, 0),
            Size = Params.Size or UDim2.new(1, 0, 1, 0),
            TextXAlignment = Params.Align or Enum.TextXAlignment.Left,
            ZIndex = Params.Z or 6,
            BorderSizePixel = 0
        }):AddToTheme({
            TextColor3 = "Text",
            PlaceholderColor3 = "DimText"
        })

        Library.FontTrackedObjects[Input.Instance] = false

        if IsMobile then
            local Focus = MakeButton({
                Parent = Params.Parent,
                Pos = Params.Pos,
                Size = Params.Size or UDim2.new(1, 0, 1, 0),
                Z = (Params.Z or 6) + 2
            })

            Focus:Connect("MouseButton1Down", function()
                Input.Instance:CaptureFocus()
            end)
        end

        return Input
    end

    local function MakeShadow(Parent, Color, Spread, Blur, Transparency)
        local Ok, Shadow = pcall(function()
            local S = Instance.new("UIShadow")
            S.Name = "\0"
            S.Color = Color
            S.Spread = Spread
            S.BlurRadius = Blur
            S.Transparency = Transparency
            S.Parent = Parent
            return S
        end)

        if Ok and Shadow then
            Library:SetBaseline(Shadow, "Transparency", Transparency)
            return Shadow
        end

        return nil
    end

    local function MakeAccentShadow(Parent, Spread, Blur, Transparency)
        local Shadow = MakeShadow(Parent, Library.Theme.Accent, Spread, Blur, Transparency)

        if Shadow then
            table.insert(Library.AccentShadows, Shadow)
        end

        return Shadow
    end

    Library.DimCount = 0
    Library.Dims = { }

    for Index = 1, 3 do
        local Dim = Library:Create("Frame", {
            Parent = Library.UnusedHolder.Instance,
            Name = "\0",
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = Index == 3 and 28 or 15,
            BorderSizePixel = 0
        })

        Corner(Dim.Instance, 10)
        Library.Dims[Index] = Dim
    end

    Library.Dim = Library.Dims[1]

    Library.SetDim = function(Self, Bool)
        Library.DimCount = math.max(0, Library.DimCount + (Bool and 1 or -1))

        local Window = Library.Windows[1]
        if not Window then return end

        local Info = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local Shown = Library.DimCount > 0
        local Target = Shown and 0.55 or 1

        local Hosts = {
            Window.Items.Main.Instance,
            Window.Items.Rail.Instance,
            Window.Items.SubBar.Instance
        }

        for Index, Dim in Library.Dims do
            Library:StampResting(Dim.Instance, "BackgroundTransparency", Target)

            if Shown then
                Dim.Instance.Parent = Hosts[Index]
                Dim.Instance.Visible = true
            end

            Library:Tween({ BackgroundTransparency = Target }, Info, Dim.Instance)
        end

        if Shown then return end

        task.delay(0.28, function()
            if Library.DimCount > 0 then return end

            for _, Dim in Library.Dims do
                Dim.Instance.Visible = false
                Dim.Instance.Parent = Library.UnusedHolder.Instance
            end
        end)
    end

    Library.CloseAllPopups = function(Self)
        for _, Value in Library.OpenFrames do
            if Value.SetOpen then Value:SetOpen(false) end
        end
    end

    local function UpdateScale()
        local Scale = Library.UserScale

        if IsMobile and workspace.CurrentCamera then
            local Viewport = workspace.CurrentCamera.ViewportSize
            local FitX = (Viewport.X * 0.94) / Library.WindowWidth
            local FitY = (Viewport.Y * 0.9) / Library.WindowHeight
            Scale = Scale * math.clamp(math.min(FitX, FitY), 0.3, 1)
        end

        local Old = Library.UIScale.Instance.Scale
        local Centers = { }

        for Index, Window in Library.Windows do
            local Root = Window.Items and Window.Items.Root
            if not Root then continue end

            local Pos = Root.Instance.Position
            local Size = Root.Instance.Size

            Centers[Index] = Vector2.new(
                (Pos.X.Offset + Size.X.Offset / 2) * Old,
                (Pos.Y.Offset + Size.Y.Offset / 2) * Old
            )
        end

        Library.UIScale.Instance.Scale = Scale
        Library.PopupScale.Instance.Scale = Scale

        if IsMobile then
            for _, Window in Library.Windows do
                if Window.Center then Window:Center() end
            end

            return
        end

        local Viewport = workspace.CurrentCamera.ViewportSize

        for Index, Window in Library.Windows do
            local Root = Window.Items and Window.Items.Root
            local Center = Centers[Index]

            if not Root or not Center then continue end

            local Size = Root.Instance.Size
            local HalfX = Size.X.Offset / 2
            local HalfY = Size.Y.Offset / 2
            local LimitX = Viewport.X / Scale
            local LimitY = Viewport.Y / Scale

            local NewX = math.clamp(Center.X / Scale - HalfX, 0, math.max(LimitX - HalfX * 2, 0))
            local NewY = math.clamp(Center.Y / Scale - HalfY, 0, math.max(LimitY - HalfY * 2, 0))

            Root.Instance.Position = UDim2.fromOffset(NewX, NewY)
        end
    end

    Library.SetUIScale = function(Self, Multiplier)
        Library.UserScale = Multiplier
        Library:CloseAllPopups()
        UpdateScale()
    end

    UpdateScale()

    Library:Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
        task.wait()
        UpdateScale()
    end)

    local function PointInside(Position, Object)
        local Corner = Object.AbsolutePosition
        local Size = Object.AbsoluteSize

        return Position.X >= Corner.X
        and Position.X <= Corner.X + Size.X
        and Position.Y >= Corner.Y
        and Position.Y <= Corner.Y + Size.Y
    end

    do
        local TouchStart

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                TouchStart = Input.Position
            end
        end)

        Library:Connect(UserInputService.InputEnded, function(Input)
            if not IsMobile then return end
            if Input.UserInputType ~= Enum.UserInputType.Touch then return end
            if not TouchStart then return end

            local Delta = Input.Position - TouchStart
            if math.abs(Delta.X) > 12 or math.abs(Delta.Y) > 12 then return end

            local Position = Input.Position
            local ShieldLevel = 0

            for Panel, Level in Library.TouchShields do
                local Live = Panel:IsDescendantOf(Library.Holder.Instance)
                or Panel:IsDescendantOf(Library.PopupHolder.Instance)

                if Live and PointInside(Position, Panel) then
                    ShieldLevel = math.max(ShieldLevel, Level)
                end
            end

            local Best

            for _, Data in Library.TouchButtons do
                local Object = Data.Instance
                if not Object or not Object.Visible then continue end
                if not PointInside(Position, Object) then continue end
                if Object.ZIndex < ShieldLevel then continue end

                if not Best or Object.ZIndex >= Best.Instance.ZIndex then
                    Best = Data
                end
            end

            if Best then Best.Fire(Input) end
        end)
    end

    local function AxisFraction(Input, Object, Axis)
        local Base = Object.AbsolutePosition[Axis]
        local Span = Object.AbsoluteSize[Axis]

        if Span == 0 then return 0 end

        return math.clamp((Input.Position[Axis] - Base) / Span, 0, 1)
    end

    local function AttachDrag(Hit, Handlers)
        local Watcher
        local Active = false

        Hit:Connect("InputBegan", function(Input)
            local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if not IsClick and not IsTouch then return end

            Active = true
            Handlers.OnGrab(Input)

            if Watcher then return end

            Watcher = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then return end

                Active = false

                if Handlers.OnRelease then Handlers.OnRelease() end

                Watcher:Disconnect()
                Watcher = nil
            end)
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            local IsMove = Input.UserInputType == Enum.UserInputType.MouseMovement
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if (IsMove or IsTouch) and Active then
                Handlers.OnMove(Input)
            end
        end)
    end

    local function PlaceBelow(GetAnchor)
        return function(Extra)
            local Anchor = GetAnchor()
            local Scale = Library:GetScreenScale()
            local X = Anchor.AbsolutePosition.X / Scale
            local Y = Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y + GuiInset

            return UDim2.fromOffset(X, Y / Scale + (Extra or 0))
        end
    end

    local function PlaceBeside(GetAnchor)
        return function(Extra)
            local Anchor = GetAnchor()
            local Scale = Library:GetScreenScale()
            local Right = Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X
            local X = Right / Scale + 8
            local Y = (Anchor.AbsolutePosition.Y + GuiInset) / Scale

            return UDim2.fromOffset(X, Y + (Extra or 0))
        end
    end

    local function RetreatUp(Current)
        return UDim2.fromOffset(Current.X.Offset, Current.Y.Offset - 8)
    end

    local function RetreatLeft(Current)
        return UDim2.fromOffset(Current.X.Offset - 8, Current.Y.Offset)
    end

    local function AttachPopup(Config)
        local Popup = Config.Popup
        local Frame = Config.Frame
        local Level = Config.Level
        local Place = Config.Place
        local GetAnchor = Config.GetAnchor
        local From = Config.From or -6
        local To = Config.To or 6
        local Retreat = Config.Retreat or RetreatUp

        local KeepOpen = Config.KeepOpen or function(Value)
            return Value == Popup or Value == Popup.Host
        end

        function Popup:SetOpen(Bool)
            if Popup.Debounce then return end
            if Popup.IsOpen == Bool then return end

            Popup.IsOpen = Bool
            Popup.Debounce = true

            if Popup.OnState then Popup.OnState(Bool) end

            if Popup.Host and Popup.Host.SetChildDim then
                Popup.Host.SetChildDim(Bool)
            end

            if Bool then
                if Config.OnOpen then Config.OnOpen() end

                Frame.Instance.Parent = Library.PopupHolder.Instance
                Frame.Instance.Position = Place(From)
                Frame.Instance.Visible = true
                Library.TouchShields[Frame.Instance] = Level
                Library:SetDim(true)
                Frame:Tween({ Position = Place(To) })

                for _, Value in Library.OpenFrames do
                    if not KeepOpen(Value) then
                        Value:SetOpen(false)
                    end
                end

                Library.OpenFrames[Popup] = Popup

                Frame:FadeDescendants(true, function()
                    Popup.Debounce = false
                end)
            else
                if Config.OnClose then Config.OnClose() end

                Library.OpenFrames[Popup] = nil
                Library:SetDim(false)
                Frame:Tween({ Position = Retreat(Frame.Instance.Position) })

                Frame:FadeDescendants(false, function()
                    Popup.Debounce = false
                    if Popup.IsOpen then return end
                    Library.TouchShields[Frame.Instance] = nil
                    Frame.Instance.Parent = Library.UnusedHolder.Instance
                end)
            end
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if not IsClick and not IsTouch then return end
            if not Popup.IsOpen then return end
            if Config.HoldOpen and Config.HoldOpen() then return end
            if Frame:IsMouseOverFrame() then return end
            if IsOverObject(GetAnchor()) then return end

            Popup:SetOpen(false)
        end)

        return Popup
    end

    local function MakeAccentRow(Params)
        local Z = Params.Z

        local Row = MakeFrame({
            Parent = Params.Parent,
            Pos = Params.Pos,
            Size = Params.Size,
            Color = Params.Color or "Section",
            Round = 5,
            Z = Z
        })

        SetRest(Row.Instance, "BackgroundTransparency", 1)

        local Line = MakeFrame({
            Parent = Row.Instance,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, Params.LineX, 0.5, 0),
            Size = UDim2.fromOffset(2.5, 0),
            Color = "Accent",
            Round = 2,
            Z = Z + 1
        })

        local Shadow = MakeAccentShadow(
            Line.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            1
        )

        if Shadow then
            SetRest(Shadow, "Transparency", 1)
        end

        local Label = MakeText({
            Parent = Row.Instance,
            Text = Params.Text,
            TextSize = Params.TextSize,
            Pos = UDim2.fromOffset(Params.TextX, 0),
            Size = Params.LabelSize,
            Color = "DimText",
            Truncate = true,
            Z = Z + 1
        })

        local Hit = MakeButton({
            Parent = Row.Instance,
            Z = Z + 2
        })

        local function SetActive(Active, Instant)
            Library:StampResting(Row.Instance, "BackgroundTransparency", Active and 0 or 1)
            Label:ChangeItemTheme({ TextColor3 = Active and "Text" or "DimText" })

            local Info = Instant and TweenInfo.new(0) or nil
            local Color = Active and Library.Theme.Text or Library.Theme.DimText
            local TextX = Active and Params.TextActiveX or Params.TextX

            Library:Tween({ BackgroundTransparency = Active and 0 or 1 }, Info, Row.Instance)
            Library:Tween({ Size = UDim2.fromOffset(2.5, Active and Params.LineH or 0) }, Info, Line.Instance)
            Library:Tween({
                TextColor3 = Color,
                Position = UDim2.fromOffset(TextX, 0)
            }, Info, Label.Instance)

            if not Shadow then return end

            Library:StampResting(Shadow, "Transparency", Active and 0.35 or 1)

            if Params.SnapShadow or Instant then
                Shadow.Transparency = Active and 0.35 or 1
            else
                Library:Tween({ Transparency = Active and 0.35 or 1 }, Info, Shadow)
            end
        end

        return {
            Row = Row,
            Line = Line,
            Label = Label,
            Hit = Hit,
            Shadow = Shadow,
            SetActive = SetActive
        }
    end

    local function MakeOptionPopup(GetAnchor, Level, WidthOverride)
        Level = Level or 40

        local Popup = {
            IsOpen = false,
            Debounce = false,
            Order = { },
            Host = nil,
            OnPick = function() end
        }

        local Items = { }
        local RowHeight = 30
        local SearchHeight = 30

        Items.Frame = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(150, 0),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = Level
        })

        Items.Frame.Instance.Visible = false

        Items.SearchHolder = MakeFrame({
            Parent = Items.Frame.Instance,
            Size = UDim2.new(1, 0, 0, SearchHeight),
            Color = "Element",
            Z = Level + 5
        })

        Items.SearchHolder.Instance.Visible = false

        MakeImage({
            Parent = Items.SearchHolder.Instance,
            Icon = "search",
            Pos = UDim2.fromOffset(9, (SearchHeight - 13) / 2),
            Size = UDim2.fromOffset(13, 13),
            Color = "DimText",
            Z = Level + 7
        })

        Items.Search = MakeInput({
            Parent = Items.SearchHolder.Instance,
            Placeholder = "Search...",
            Pos = UDim2.fromOffset(27, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextSize = 14,
            Z = Level + 6
        })

        MakeFrame({
            Parent = Items.SearchHolder.Instance,
            Pos = UDim2.new(0, 6, 1, -1),
            Size = UDim2.new(1, -12, 0, 1),
            Color = "Line",
            Z = Level + 6
        })

        Items.Scroll = Library:Create("ScrollingFrame", {
            Parent = Items.Frame.Instance,
            Name = "\0",
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            Selectable = false,
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = Level + 4,
            BorderSizePixel = 0
        })

        Library:Create("UIListLayout", {
            Parent = Items.Scroll.Instance,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3)
        })

        Library:Create("UIPadding", {
            Parent = Items.Scroll.Instance,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })

        Popup.Items = Items

        local function ApplySearch(Query)
            Query = string.lower(Query)

            for _, Data in Popup.Order do
                local Match = Query == ""
                or string.find(string.lower(Data.Name), Query, 1, true) ~= nil

                Data.Row.Instance.Visible = Match
            end
        end

        Library:Connect(Items.Search.Instance:GetPropertyChangedSignal("Text"), function()
            ApplySearch(Items.Search.Instance.Text)
        end)

        function Popup:AddRow(Text)
            local Built = MakeAccentRow({
                Parent = Items.Scroll.Instance,
                Size = UDim2.new(1, -4, 0, RowHeight - 4),
                Text = Text,
                TextSize = 14,
                LabelSize = UDim2.new(1, -20, 1, 0),
                LineX = 8,
                LineH = 16,
                TextX = 11,
                TextActiveX = 20,
                Z = Level + 1
            })

            local Data = {
                Name = Text,
                Selected = false,
                Row = Built.Row
            }

            function Data:Set(Active, Instant)
                Data.Selected = Active
                Built.SetActive(Active, Instant)
            end

            Built.Row:OnHover(function()
                if Data.Selected then return end
                Library:Tween({ BackgroundTransparency = 0.7 }, nil, Built.Row.Instance)
            end, function()
                if Data.Selected then return end
                Library:Tween({ BackgroundTransparency = 1 }, nil, Built.Row.Instance)
            end)

            Built.Hit:Connect("MouseButton1Down", function()
                Popup.OnPick(Data)
            end)

            table.insert(Popup.Order, Data)
            return Data
        end

        function Popup:Clear()
            for _, Data in Popup.Order do
                Data.Row.Instance:Destroy()
            end

            Popup.Order = { }
        end

        return AttachPopup({
            Popup = Popup,
            Frame = Items.Frame,
            Level = Level,
            GetAnchor = GetAnchor,
            Place = PlaceBelow(GetAnchor),
            OnOpen = function()
                local Anchor = GetAnchor()
                local Scale = Library:GetScreenScale()
                local ShowSearch = #Popup.Order > 8
                local Width = WidthOverride or (Anchor.AbsoluteSize.X / Scale)
                local ListHeight = math.min(#Popup.Order * RowHeight + 8, 168)

                Items.Search.Instance.Text = ""
                ApplySearch("")

                Items.SearchHolder.Instance.Visible = ShowSearch

                if ShowSearch then
                    Items.Scroll.Instance.Position = UDim2.fromOffset(0, SearchHeight)
                    Items.Scroll.Instance.Size = UDim2.new(1, 0, 1, -SearchHeight)
                    Items.Frame.Instance.Size = UDim2.fromOffset(Width, ListHeight + SearchHeight)
                else
                    Items.Scroll.Instance.Position = UDim2.fromOffset(0, 0)
                    Items.Scroll.Instance.Size = UDim2.new(1, 0, 1, 0)
                    Items.Frame.Instance.Size = UDim2.fromOffset(Width, ListHeight)
                end
            end,
            OnClose = function()
                Items.Search.Instance.Text = ""
            end
        })
    end

    local function MakeSwatch(Parent, RightOffset, Default, Z)
        local Swatch = { }
        local Base = Z or 3

        Swatch.Halo = MakeFrame({
            Parent = Parent,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, RightOffset, 0.5, 0),
            Size = UDim2.fromOffset(22, 22),
            Round = 20,
            Z = Base
        })

        Swatch.Halo.Instance.BackgroundColor3 = Default
        SetRest(Swatch.Halo.Instance, "BackgroundTransparency", 0.72)

        Swatch.Core = MakeFrame({
            Parent = Swatch.Halo.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            Raw = Default,
            Round = 20,
            Z = Base + 1
        })

        Swatch.Shadow = MakeShadow(
            Swatch.Core.Instance,
            Default,
            UDim2.fromOffset(0, 0),
            UDim.new(0, 6),
            0.35
        )

        Swatch.Hit = MakeButton({
            Parent = Swatch.Halo.Instance,
            Z = Base + 2
        })

        function Swatch:SetColor(Color, Alpha)
            Alpha = Alpha or 0

            Library:StampResting(Swatch.Core.Instance, "BackgroundTransparency", Alpha)
            Library:StampResting(Swatch.Halo.Instance, "BackgroundTransparency", 0.72)

            Swatch.Halo:Tween({ BackgroundColor3 = Color })
            Swatch.Core:Tween({
                BackgroundColor3 = Color,
                BackgroundTransparency = Alpha
            })

            if Swatch.Shadow then
                pcall(function()
                    Swatch.Shadow.Color = Color
                end)
            end
        end

        return Swatch
    end

    local function MakeColorPopup(GetAnchor, Title, Default, DefaultAlpha, OnChanged)
        local Picker = {
            Hue = 0,
            Saturation = 0,
            Value = 1,
            Transparency = DefaultAlpha or 0,
            Color = Color3.new(1, 1, 1),
            IsOpen = false,
            Debounce = false
        }

        local Items = { }
        local Level = 120
        local Field = 150
        local PanelW = Field + 32
        local CursorSize = 14
        local CursorThickness = 2

        Items.Window = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(PanelW, Field + 110),
            Color = "Section",
            Round = 8,
            Z = Level
        })

        Items.Window.Instance.Visible = false

        Items.Field = Library:Create("ImageButton", {
            Parent = Items.Window.Instance,
            Name = "\0",
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            Position = UDim2.fromOffset(16, 16),
            Size = UDim2.fromOffset(Field, Field),
            ZIndex = Level + 1,
            BorderSizePixel = 0
        })

        Corner(Items.Field.Instance, 8)

        Items.Tint = MakeFrame({
            Parent = Items.Field.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Raw = Color3.new(1, 1, 1),
            Round = 8,
            Z = Level + 2
        })

        Library:Create("UIGradient", {
            Parent = Items.Tint.Instance,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        })

        Items.Shade = MakeFrame({
            Parent = Items.Field.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Raw = Color3.new(0, 0, 0),
            Round = 8,
            Z = Level + 3
        })

        Library:Create("UIGradient", {
            Parent = Items.Shade.Instance,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            })
        })

        local function MakeCursor(Parent, Pos, Z)
            local Cursor = MakeFrame({
                Parent = Parent,
                Anchor = Vector2.new(0.5, 0.5),
                Pos = Pos,
                Size = UDim2.fromOffset(CursorSize, CursorSize),
                Raw = Color3.new(1, 1, 1),
                Alpha = 1,
                Round = 20,
                Z = Z
            })

            Library:Create("UIStroke", {
                Parent = Cursor.Instance,
                Color = Color3.new(1, 1, 1),
                Thickness = CursorThickness
            })

            return Cursor
        end

        Items.FieldCursor = MakeCursor(
            Items.Field.Instance,
            UDim2.new(0.5, 0, 0.5, 0),
            Level + 4
        )

        local function MakeBar(Y)
            local Bar = Library:Create("ImageButton", {
                Parent = Items.Window.Instance,
                Name = "\0",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(16, Y),
                Size = UDim2.fromOffset(Field, 10),
                ZIndex = Level + 1,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.new(1, 1, 1)
            })

            Corner(Bar.Instance, 5)

            local Cursor = MakeCursor(
                Bar.Instance,
                UDim2.new(1, 0, 0.5, 0),
                Level + 3
            )

            return Bar, Cursor
        end

        Items.HueBar, Items.HueCursor = MakeBar(Field + 30)

        Library:Create("UIGradient", {
            Parent = Items.HueBar.Instance,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
        })

        Items.AlphaBar, Items.AlphaCursor = MakeBar(Field + 50)

        local AlphaGradient = Library:Create("UIGradient", {
            Parent = Items.AlphaBar.Instance,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        })

        Items.Hex = MakeFrame({
            Parent = Items.Window.Instance,
            Pos = UDim2.fromOffset(16, Field + 72),
            Size = UDim2.fromOffset(Field, 26),
            Color = "Element",
            Round = 5,
            Clip = true,
            Z = Level + 1
        })

        Items.HexInput = MakeInput({
            Parent = Items.Hex.Instance,
            Text = "#FFFFFF",
            Placeholder = "#FFFFFF",
            Pos = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -18, 1, 0),
            TextSize = 14,
            Z = Level + 2
        })

        local Grabbing = nil
        local SlideInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        local function Refresh(Instant)
            Picker.Color = Color3.fromHSV(Picker.Hue, Picker.Saturation, Picker.Value)

            local Pure = Color3.fromHSV(Picker.Hue, 1, 1)
            local Info = Instant and TweenInfo.new(0) or SlideInfo

            AlphaGradient.Instance.Color = ColorSequence.new(Picker.Color)
            Library:Tween({ BackgroundColor3 = Pure }, Info, Items.Field.Instance)

            Library:Tween({
                Position = UDim2.new(Picker.Saturation, 0, 1 - Picker.Value, 0)
            }, Info, Items.FieldCursor.Instance)

            Library:Tween({ Position = UDim2.new(Picker.Hue, 0, 0.5, 0) }, Info, Items.HueCursor.Instance)
            Library:Tween({ Position = UDim2.new(Picker.Transparency, 0, 0.5, 0) }, Info, Items.AlphaCursor.Instance)

            if not Items.HexInput.Instance:IsFocused() then
                Items.HexInput.Instance.Text = "#" .. string.upper(Picker.Color:ToHex())
            end

            Library:SafeCall(OnChanged, Picker.Color, Picker.Transparency)
        end

        function Picker:Set(Color, Alpha, Silent)
            if type(Color) == "table" then
                Color = Color3.fromRGB(Color[1], Color[2], Color[3])
            end

            if type(Color) == "string" then
                Color = Color3.fromHex(Color)
            end

            Picker.Hue, Picker.Saturation, Picker.Value = Color:ToHSV()
            Picker.Transparency = Alpha or Picker.Transparency or 0

            if Silent then
                Picker.Color = Color3.fromHSV(Picker.Hue, Picker.Saturation, Picker.Value)
                return
            end

            Refresh(true)
        end

        local function Slide(Input)
            if Grabbing == "Field" then
                Picker.Saturation = AxisFraction(Input, Items.Field.Instance, "X")
                Picker.Value = 1 - AxisFraction(Input, Items.Field.Instance, "Y")
            elseif Grabbing == "Hue" then
                Picker.Hue = AxisFraction(Input, Items.HueBar.Instance, "X")
            elseif Grabbing == "Alpha" then
                Picker.Transparency = AxisFraction(Input, Items.AlphaBar.Instance, "X")
            else
                return
            end

            Refresh()
        end

        local function Grabber(Object, Mode)
            local Watcher

            Library:Connect(Object.InputBegan, function(Input)
                local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
                local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

                if not IsClick and not IsTouch then return end

                Grabbing = Mode
                Slide(Input)

                if Watcher then return end

                Watcher = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        if Grabbing == Mode then Grabbing = nil end
                        Watcher:Disconnect()
                        Watcher = nil
                    end
                end)
            end)
        end

        Grabber(Items.Field.Instance, "Field")
        Grabber(Items.HueBar.Instance, "Hue")
        Grabber(Items.AlphaBar.Instance, "Alpha")

        Library:Connect(UserInputService.InputChanged, function(Input)
            local IsMove = Input.UserInputType == Enum.UserInputType.MouseMovement
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if (IsMove or IsTouch) and Grabbing then
                Slide(Input)
            end
        end)

        Items.HexInput:Connect("FocusLost", function()
            local Text = string.gsub(Items.HexInput.Instance.Text, "#", "")

            local Ok, Color = pcall(function()
                return Color3.fromHex(Text)
            end)

            if Ok and Color then
                Picker:Set(Color, Picker.Transparency)
            else
                Refresh(true)
            end
        end)

        AttachPopup({
            Popup = Picker,
            Frame = Items.Window,
            Level = Level,
            GetAnchor = GetAnchor,
            Place = PlaceBeside(GetAnchor)
        })

        Picker:Set(Default or Library.Theme.Accent, Picker.Transparency)
        return Picker
    end

    local function KeyName(Key)
        if not Key then return "None" end

        local Text = tostring(Key)
        Text = string.gsub(Text, "Enum.KeyCode.", "")
        Text = string.gsub(Text, "Enum.UserInputType.", "")

        return Text
    end

    local function ParseKey(Value)
        if type(Value) ~= "string" or Value == "None" then
            return nil
        end

        local Name = string.gsub(Value, "Enum.KeyCode.", "")
        Name = string.gsub(Name, "Enum.UserInputType.", "")

        local Ok, Key = pcall(function()
            return Enum.KeyCode[Name]
        end)

        if Ok and Key then return Key end

        return nil
    end

    local function CaptureKey(State, Display, OnPicked)
        if State.Picking then return end

        State.Picking = true
        Library.Binding = true
        Display.Text = ". . ."

        task.wait()

        local Connection

        Connection = UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement then return end

            Connection:Disconnect()

            local IsBack = Input.KeyCode == Enum.KeyCode.Backspace
            local IsEsc = Input.KeyCode == Enum.KeyCode.Escape

            if IsBack or IsEsc then
                OnPicked(nil)
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                OnPicked(Input.KeyCode)
            else
                OnPicked(Input.UserInputType)
            end

            task.defer(function()
                Library.Binding = false
            end)
        end)
    end

    local function KeyMatches(Input, Key)
        return Input.KeyCode == Key or Input.UserInputType == Key
    end

    Library.Notification = function(Self, Params)
        if Library.Silent then return end
        if Library.LoaderActive then
            table.insert(Library.LoaderFinishedCallbacks, function()
                Library:Notification(Params)
            end)
            return
        end

        Params = Params or { }

        local Title = Params.Name or Params.Title or "Notification"
        local Content = Params.Description or Params.Content or ""
        local Icon = Params.Icon or "bell"
        local Duration = Params.Duration or 3.5

        local HasBody = (Content ~= nil and Content ~= "")
        local CardW = 260
        local Bounds = Vector2.new(0, 0)

        if HasBody then
            Bounds = MeasureText(Content, 13, CardW - 55, UiFont)
        end

        local CardH = HasBody and math.max(48, 24 + Bounds.Y + 14) or 38
        local Items = { }

        -- Сама рамка уведомления: темная, со скруглением и обводкой как в GUI
        Items.Frame = MakeFrame({
            Parent = Library.Holder.Instance,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, 320, 0, 15),
            Size = UDim2.fromOffset(CardW, CardH),
            Color = "Section",
            Round = 8,
            Z = 80
        })

        -- Тонкая рамка как в гуи (UIStroke)
        Library:Create("UIStroke", {
            Parent = Items.Frame.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        -- Вертикальная акцентная полоска справа (по образцу фото 2: 2.5px, Round 2, мягкий неоновый глов)
        Items.SideBar = MakeFrame({
            Parent = Items.Frame.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -7, 0.5, 0),
            Size = UDim2.fromOffset(2.5, CardH - 14),
            Color = "Accent",
            Round = 2,
            Z = 83
        })

        local SideShadow = MakeAccentShadow(
            Items.SideBar.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            0.35
        )

        -- Иконка слева
        Items.Icon = MakeImage({
            Parent = Items.Frame.Instance,
            Icon = Icon,
            Anchor = Vector2.new(0, 0.5),
            Pos = HasBody and UDim2.new(0, 12, 0, 17) or UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Color = "Accent",
            Z = 82
        })

        -- Заголовок (пиксельный шрифт PixelCode, без размытия)
        Items.Title = MakeText({
            Parent = Items.Frame.Instance,
            Text = Title,
            TextSize = 14,
            Bold = true,
            Anchor = HasBody and Vector2.new(0, 0) or Vector2.new(0, 0.5),
            Pos = HasBody and UDim2.fromOffset(35, 8) or UDim2.new(0, 35, 0.5, 0),
            Size = UDim2.new(1, -48, 0, 16),
            Color = "Text",
            Truncate = true,
            Z = 82
        })

        -- Описание (если передано)
        if HasBody then
            Items.Body = MakeText({
                Parent = Items.Frame.Instance,
                Text = Content,
                TextSize = 13,
                Pos = UDim2.fromOffset(35, 26),
                Size = UDim2.new(1, -48, 0, Bounds.Y),
                Color = "DimText",
                Wrap = true,
                Z = 82
            })

            Items.Body.Instance.TextYAlignment = Enum.TextYAlignment.Top
        end

        local Notif = {
            Items = Items,
            Dead = false,
            Height = CardH
        }

        table.insert(Library.Notifs, Notif)

        local function StackHeight(Stop)
            local Y = 15

            for _, Value in Library.Notifs do
                if Value == Stop then break end
                if Value.Dead then continue end

                Y += Value.Height + 8
            end

            return Y
        end

        local function Reflow()
            local Info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local Y = 15

            for _, Value in Library.Notifs do
                if Value.Dead then continue end

                Library:Tween({ Position = UDim2.new(1, -15, 0, Y) }, Info, Value.Items.Frame.Instance)
                Y += Value.Height + 8
            end
        end

        local StartY = StackHeight(Notif)
        local SlideIn = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

        Items.Frame.Instance.Position = UDim2.new(1, 320, 0, StartY)
        Items.Frame:Tween({ Position = UDim2.new(1, -15, 0, StartY) }, SlideIn)

        local function Dismiss()
            if Notif.Dead then return end
            Notif.Dead = true

            local Fade = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local Current = Items.Frame.Instance.Position
            local SlideOut = UDim2.new(1, 320, 0, Current.Y.Offset)

            Library:Tween({ Position = SlideOut }, Fade, Items.Frame.Instance)
            Items.Frame:FadeDescendants(false)
            if SideShadow then
                Library:Tween({ Transparency = 1 }, Fade, SideShadow)
            end

            task.delay(0.3, function()
                local Index = table.find(Library.Notifs, Notif)
                if Index then table.remove(Library.Notifs, Index) end

                if SideShadow then
                    local SIndex = table.find(Library.AccentShadows, SideShadow)
                    if SIndex then table.remove(Library.AccentShadows, SIndex) end
                end

                Items.Frame.Instance:Destroy()
                Reflow()
            end)
        end

        local Hit = MakeButton({
            Parent = Items.Frame.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 85
        })

        Hit:Connect("MouseButton1Down", Dismiss)

        local Countdown = TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        Library:Tween({ Size = UDim2.fromOffset(2.5, 0) }, Countdown, Items.SideBar.Instance)

        task.delay(Duration, Dismiss)
    end

    Library.ActiveConfirm = nil

    Library.Confirm = function(Self, Params)
        Params = Params or { }
        local Title = Params.Title or "Confirmation"
        local Text = Params.Text or "Are you sure?"
        local YesText = Params.YesText or "Yes"
        local Icon = Params.Icon or (isfile and isfile(Library.AssetsFolder .. "/asset_23de81e2.png") and Library.AssetsFolder .. "/asset_23de81e2.png") or (isfile and isfile(Library.AssetsFolder .. "/jade-logo.png") and Library.AssetsFolder .. "/jade-logo.png") or (Library.GitHubBase .. "/asset_23de81e2.png")
        local OnConfirm = Params.OnConfirm
        local OnCancel = Params.OnCancel

        if Library.ActiveConfirm then
            pcall(function()
                Library.ActiveConfirm.Backdrop.Instance:Destroy()
            end)
            Library.ActiveConfirm = nil
        end

        local Backdrop = Library:Create("TextButton", {
            Parent = Library.Holder.Instance,
            Name = "\0",
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 160
        })

        local Card = MakeFrame({
            Parent = Backdrop.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 12),
            Size = UDim2.fromOffset(360, 160),
            Color = "Background",
            Round = 10,
            Clip = true,
            Z = 161
        })
        Card.Instance.Active = true

        Library:Create("UIStroke", {
            Parent = Card.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        local TopLogo = MakeImage({
            Parent = Card.Instance,
            Icon = Icon,
            Pos = UDim2.fromOffset(16, 14),
            Size = UDim2.fromOffset(26, 26),
            Color = "Accent",
            Fit = true,
            Z = 162
        })

        local BrandTitle = MakeText({
            Parent = Card.Instance,
            Text = "jade.xyz",
            TextSize = 18,
            Bold = true,
            Color = "Accent",
            Pos = UDim2.fromOffset(50, 16),
            Size = UDim2.fromOffset(80, 22),
            Z = 162
        })

        local Subtitle = MakeText({
            Parent = Card.Instance,
            Text = "• confirmation",
            TextSize = 13,
            Color = "DimText",
            Pos = UDim2.fromOffset(132, 18),
            Size = UDim2.fromOffset(140, 18),
            Z = 162
        })

        local HeaderLine = MakeFrame({
            Parent = Card.Instance,
            Pos = UDim2.fromOffset(16, 46),
            Size = UDim2.new(1, -32, 0, 1),
            Color = "Line",
            Z = 162
        })

        local TitleLabel = MakeText({
            Parent = Card.Instance,
            Text = Title,
            TextSize = 14,
            Bold = true,
            Color = "Text",
            Pos = UDim2.fromOffset(18, 54),
            Size = UDim2.new(1, -36, 0, 18),
            Truncate = true,
            Z = 162
        })

        local BodyLabel = MakeText({
            Parent = Card.Instance,
            Text = Text,
            TextSize = 12,
            Color = "DimText",
            Pos = UDim2.fromOffset(18, 74),
            Size = UDim2.new(1, -36, 0, 32),
            Truncate = false,
            Z = 162
        })
        BodyLabel.Instance.TextWrapped = true

        local ButtonW = 156
        local ButtonH = 30

        local NoFrame = MakeFrame({
            Parent = Card.Instance,
            Pos = UDim2.new(0, 18, 1, -44),
            Size = UDim2.fromOffset(ButtonW, ButtonH),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 163
        })

        Library:Create("UIStroke", {
            Parent = NoFrame.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        local NoLabel = MakeText({
            Parent = NoFrame.Instance,
            Text = NoText,
            TextSize = 12,
            Bold = true,
            Color = "DimText",
            Align = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 164
        })

        local NoHit = MakeButton({
            Parent = NoFrame.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 165
        })

        NoHit:OnHover(function()
            NoFrame:Tween({ BackgroundColor3 = Library.Theme.Hover })
            NoLabel:Tween({ TextColor3 = Library.Theme.Text })
        end, function()
            NoFrame:Tween({ BackgroundColor3 = Library.Theme.Element })
            NoLabel:Tween({ TextColor3 = Library.Theme.DimText })
        end)

        local YesFrame = MakeFrame({
            Parent = Card.Instance,
            Pos = UDim2.new(1, -(ButtonW + 18), 1, -44),
            Size = UDim2.fromOffset(ButtonW, ButtonH),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 163
        })

        Library:Create("UIStroke", {
            Parent = YesFrame.Instance,
            Color = Library.Theme.Accent,
            Thickness = 1.5
        }):AddToTheme({ Color = "Accent" })

        local YesSweep = MakeSweep(YesFrame.Instance, 163)

        local YesLabel = MakeText({
            Parent = YesFrame.Instance,
            Text = YesText,
            TextSize = 12,
            Bold = true,
            Color = "Accent",
            Align = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 164
        })

        local YesHit = MakeButton({
            Parent = YesFrame.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 165
        })

        YesHit:OnHover(function()
            YesFrame:Tween({ BackgroundColor3 = Library.Theme.Hover })
        end, function()
            YesFrame:Tween({ BackgroundColor3 = Library.Theme.Element })
        end)

        local BottomBar = MakeFrame({
            Parent = Card.Instance,
            Anchor = Vector2.new(0.5, 1),
            Pos = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.fromOffset(130, 2.5),
            Color = "Accent",
            Round = 2,
            Z = 163
        })

        local BottomShadow = MakeAccentShadow(
            BottomBar.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            0.35
        )

        local Closing = false
        local function Close(Confirmed)
            if Closing then return end
            Closing = true

            local FadeOut = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Library:Tween({ BackgroundTransparency = 1 }, FadeOut, Backdrop.Instance)
            Library:Tween({ Position = UDim2.new(0.5, 0, 0.5, 14) }, FadeOut, Card.Instance)
            Card:FadeDescendants(false)

            if BottomShadow then
                Library:Tween({ Transparency = 1 }, FadeOut, BottomShadow)
            end

            task.delay(0.2, function()
                if BottomShadow then
                    local SIndex = table.find(Library.AccentShadows, BottomShadow)
                    if SIndex then table.remove(Library.AccentShadows, SIndex) end
                end
                Backdrop.Instance:Destroy()
                if Library.ActiveConfirm and Library.ActiveConfirm.Backdrop == Backdrop then
                    Library.ActiveConfirm = nil
                end

                if Confirmed and type(OnConfirm) == "function" then
                    Library:SafeCall(OnConfirm)
                elseif not Confirmed and type(OnCancel) == "function" then
                    Library:SafeCall(OnCancel)
                end
            end)
        end

        NoHit:Connect("MouseButton1Down", function()
            Close(false)
        end)

        YesHit:Connect("MouseButton1Down", function()
            if YesSweep and YesSweep.Instance then
                PlaySweep(YesSweep.Instance)
            end
            Close(true)
        end)

        Backdrop:Connect("MouseButton1Down", function()
            Close(false)
        end)

        Library.ActiveConfirm = {
            Backdrop = Backdrop,
            Close = Close
        }

        local PopIn = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        Library:Tween({ BackgroundTransparency = 0.55 }, PopIn, Backdrop.Instance)
        Library:Tween({ Position = UDim2.new(0.5, 0, 0.5, 0) }, PopIn, Card.Instance)

        return Library.ActiveConfirm
    end

    Library.AnimBgEnabled = true
    Library.AnimBgStyle = "Neon Grid"
    Library.AnimBgHolder = nil
    Library.AnimBgConnection = nil
    Library.AnimBgFile = "Jade/Background.json"

    pcall(function()
        if isfile and isfile(Library.AnimBgFile) then
            local Data = HttpService:JSONDecode(readfile(Library.AnimBgFile))
            if type(Data) == "table" then
                if type(Data.Enabled) == "boolean" then
                    Library.AnimBgEnabled = Data.Enabled
                end
                if type(Data.Style) == "string" and table.find({ "Neon Grid", "Floating Particles" }, Data.Style) then
                    Library.AnimBgStyle = Data.Style
                end
            end
        end
    end)

    Library.SetupAnimatedBackground = function(Self, Container)
        if not Container or not Container.Parent then return end

        if Library.AnimBgConnection then
            pcall(function() Library.AnimBgConnection:Disconnect() end)
            Library.AnimBgConnection = nil
        end

        Container:ClearAllChildren()

        if not Library.AnimBgEnabled then
            Container.Visible = false
            return
        end

        Container.Visible = true
        local Style = Library.AnimBgStyle or "Neon Grid"

        if Style == "Neon Grid" then
            local GridAsset = (isfile and isfile(Library.AssetsFolder .. "/grid_straight.png") and getcustomasset(Library.AssetsFolder .. "/grid_straight.png"))
                or (isfile and isfile("grid_straight.png") and getcustomasset("grid_straight.png"))
                or (Library.GitHubBase .. "/grid_straight.png")

            local GridImage = Library:Create("ImageLabel", {
                Parent = Container,
                Name = "GridLayer",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, -256, 0, 0),
                Size = UDim2.new(2, 256, 1, 0),
                Image = GridAsset,
                ImageColor3 = Library.Theme.Accent,
                ImageTransparency = 0.88,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(256, 256),
                BorderSizePixel = 0,
                ZIndex = 1
            }):AddToTheme({ ImageColor3 = "Accent" })

            local Offset = 0
            Library.AnimBgConnection = RunService.RenderStepped:Connect(function(Delta)
                if not Container.Parent or not Library.AnimBgEnabled then return end
                Offset = (Offset + Delta * 20) % 256
                GridImage.Instance.Position = UDim2.new(0, Offset - 256, 0, 0)
            end)
        elseif Style == "Floating Particles" then
            local Particles = { }
            local Count = 24

            for i = 1, Count do
                local SizePx = math.random(2, 4)
                -- Насыщенный цвет под надпись jade.xyz по темам (низкая прозрачность)
                local Alpha = 0.05 + math.random() * 0.20

                local Dot = Library:Create("Frame", {
                    Parent = Container,
                    Name = "Particle",
                    BackgroundColor3 = Library.Theme.Accent,
                    BackgroundTransparency = Alpha,
                    Size = UDim2.fromOffset(SizePx, SizePx),
                    BorderSizePixel = 0,
                    ZIndex = 1
                }):AddToTheme({ BackgroundColor3 = "Accent" })

                Library:Create("UICorner", {
                    Parent = Dot.Instance,
                    CornerRadius = UDim.new(1, 0)
                })

                local PData = {
                    Frame = Dot.Instance,
                    X = math.random(),
                    Y = math.random(),
                    SpeedY = 0.035 + math.random() * 0.065,
                    Amp = 0.012 + math.random() * 0.025,
                    Freq = 1.2 + math.random() * 2.2,
                    Phase = math.random() * math.pi * 2,
                    BaseAlpha = Alpha
                }
                Dot.Instance.Position = UDim2.new(PData.X, 0, PData.Y, 0)
                table.insert(Particles, PData)
            end

            local Elapsed = 0
            Library.AnimBgConnection = RunService.RenderStepped:Connect(function(Delta)
                if not Container.Parent or not Library.AnimBgEnabled then return end
                Elapsed += Delta
                for _, P in ipairs(Particles) do
                    P.Y = P.Y - P.SpeedY * Delta
                    if P.Y < -0.04 then
                        P.Y = 1.04
                        P.X = math.random()
                    end
                    local CurX = P.X + math.sin(Elapsed * P.Freq + P.Phase) * P.Amp
                    P.Frame.Position = UDim2.new(CurX, 0, P.Y, 0)
                    P.Frame.BackgroundTransparency = math.clamp(P.BaseAlpha + math.sin(Elapsed * 2 + P.Phase) * 0.12, 0.0, 0.40)
                end
            end)
        end
    end

    Library.SetAnimatedBackground = function(Self, Enabled, Style, NoSave)
        if Enabled ~= nil then
            Library.AnimBgEnabled = Enabled
        end
        if Style then
            Library.AnimBgStyle = Style
        end

        if not NoSave and writefile then
            pcall(function()
                writefile(Library.AnimBgFile, HttpService:JSONEncode({
                    Enabled = Library.AnimBgEnabled,
                    Style = Library.AnimBgStyle
                }))
            end)
        end

        if Library.AnimBgHolder and Library.AnimBgHolder.Parent then
            Library:SetupAnimatedBackground(Library.AnimBgHolder)
        end

        if Library.UpdateBgUI then
            Library:UpdateBgUI()
        end
    end

    local function CreateSwitch(Parent, Anchor, Pos, InitialState, Callback)
        local State = InitialState and true or false
        local Token = 0
        local GrowTween
        local SnapTween

        local Pad = 4
        local InnerW = 35 - Pad * 2
        local LeftPos = UDim2.new(0, Pad, 0.5, 0)
        local RightPos = UDim2.new(1, -Pad, 0.5, 0)
        local Small = UDim2.fromOffset(13, 13)

        local Box = MakeFrame({
            Parent = Parent,
            Anchor = Anchor or Vector2.new(0, 0.5),
            Pos = Pos or UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(35, 21),
            Color = State and "Light" or "Element",
            Round = 10,
            Clip = true,
            Z = 5
        })

        local Circle = MakeFrame({
            Parent = Box.Instance,
            Anchor = State and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
            Pos = State and RightPos or LeftPos,
            Size = Small,
            Color = State and "Accent" or "DimText",
            Round = 20,
            Z = 6
        })

        MakeAccentShadow(
            Circle.Instance,
            UDim2.fromOffset(3, 3),
            UDim.new(0, 5),
            0.7
        )

        local Hit = MakeButton({
            Parent = Box.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 8
        })

        local function SetVisual(NewState, Instant)
            State = NewState and true or false
            Token += 1
            local CurrentToken = Token

            if GrowTween then pcall(function() GrowTween:Cancel() end) end
            if SnapTween then pcall(function() SnapTween:Cancel() end) end
            GrowTween = nil
            SnapTween = nil

            local BoxColor = State and "Light" or "Element"
            local CircleKey = State and "Accent" or "DimText"
            local CircleColor = Library.Theme[CircleKey]

            local StartAnchor = State and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
            local StartPos = State and LeftPos or RightPos
            local EndAnchor = State and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
            local EndPos = State and RightPos or LeftPos

            Box:ChangeItemTheme({ BackgroundColor3 = BoxColor })
            Circle:ChangeItemTheme({ BackgroundColor3 = CircleKey })

            if Instant then
                Box.Instance.BackgroundColor3 = Library.Theme[BoxColor]
                Circle.Instance.BackgroundColor3 = CircleColor
                Circle.Instance.Size = Small
                Circle.Instance.AnchorPoint = EndAnchor
                Circle.Instance.Position = EndPos
                return
            end

            local Grow = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local Snap = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local Fade = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            Library:Tween({ BackgroundColor3 = Library.Theme[BoxColor] }, Fade, Box.Instance)
            Library:Tween({ BackgroundColor3 = CircleColor }, Fade, Circle.Instance)

            Circle.Instance.AnchorPoint = StartAnchor
            Circle.Instance.Position = StartPos
            GrowTween = Library:Tween({ Size = UDim2.fromOffset(InnerW, 13) }, Grow, Circle.Instance)

            task.delay(0.08, function()
                if Token ~= CurrentToken then return end
                Circle.Instance.AnchorPoint = EndAnchor
                Circle.Instance.Position = EndPos
                SnapTween = Library:Tween({ Size = Small }, Snap, Circle.Instance)
            end)
        end

        Hit:Connect("MouseButton1Down", function()
            local NextState = not State
            SetVisual(NextState, false)
            if Callback then
                Library:SafeCall(Callback, NextState)
            end
        end)

        return {
            Box = Box,
            Circle = Circle,
            SetVisual = SetVisual,
            Get = function() return State end
        }
    end

    -- ====================================================================
    -- KEYBIND MENU SYSTEM
    -- ====================================================================
    Library.KeybindMenuEnabled = false
    Library.KeybindMenuTransparency = 0.2
    Library.KeybindRoot = nil
    Library.KeybindBody = nil
    Library.KeybindListContainer = nil
    Library.RegisteredKeybinds = { }
    Library.KeybindFile = "Jade/Keybinds.json"

    pcall(function()
        if isfile and isfile(Library.KeybindFile) then
            local Data = HttpService:JSONDecode(readfile(Library.KeybindFile))
            if type(Data) == "table" then
                if type(Data.Enabled) == "boolean" then
                    Library.KeybindMenuEnabled = Data.Enabled
                end
                if type(Data.Transparency) == "number" then
                    Library.KeybindMenuTransparency = math.clamp(Data.Transparency, 0, 1)
                end
            end
        end
    end)

    Library.RegisterKeybind = function(Self, Entry)
        if not Entry or not Entry.Name then return end
        local Identifier = Entry.Id or Entry.Name
        for i, Existing in ipairs(Library.RegisteredKeybinds) do
            local ExistingId = Existing.Id or Existing.Name
            if ExistingId == Identifier then
                Library.RegisteredKeybinds[i] = Entry
                if Library.UpdateKeybindMenu then
                    Library:UpdateKeybindMenu()
                end
                return
            end
        end
        table.insert(Library.RegisteredKeybinds, Entry)
        if Library.UpdateKeybindMenu then
            Library:UpdateKeybindMenu()
        end
    end

    Library.SetupKeybindMenu = function(Self)
        if Library.KeybindRoot then return end

        local RootHolder = Library.PopupHolder or Library.Holder
        local TopH = 26
        local Width = 195

        -- Единое монолитное окно кейбинд-меню. Только Root имеет скругленный фон и обводку,
        -- благодаря чему никакие квадратные уголки дочерних фреймов больше не выпирают наружу!
        local Root = MakeFrame({
            Parent = RootHolder.Instance,
            Pos = UDim2.fromOffset(25, 260),
            Size = UDim2.fromOffset(Width, TopH),
            Color = "Background",
            Trans = 0.15,
            Round = 8,
            Clip = true,
            Z = 75
        })
        Root.Instance.Name = "KeybindMenu"
        Root.Instance.Visible = Library.KeybindMenuEnabled

        -- Тонкая обводка окна по контуру в точности как у главного GUI
        Library:Create("UIStroke", {
            Parent = Root.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        -- Верхняя челка: прозрачный контейнер (фон задает единый Root с идеальными скруглениями)
        local Topbar = MakeFrame({
            Parent = Root.Instance,
            Pos = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, TopH),
            Z = 76
        })

        MakeImage({
            Parent = Topbar.Instance,
            Icon = "command",
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 8, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            Color = "Accent",
            Z = 77
        })

        MakeText({
            Parent = Topbar.Instance,
            Text = "Keybinds",
            TextSize = 13,
            Bold = true,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 26, 0.5, 0),
            Size = UDim2.new(1, -34, 1, 0),
            Color = "Text",
            Z = 77
        })

        -- Разделительная линия между челкой и списком (видна только когда есть активные бинды)
        local TopLine = MakeFrame({
            Parent = Root.Instance,
            Pos = UDim2.fromOffset(0, TopH),
            Size = UDim2.new(1, 0, 0, 1),
            Color = "Line",
            Z = 77
        })
        TopLine.Instance.Visible = false

        -- Тело меню ниже челки: прозрачный контейнер списка (без собственного фона, чтобы не торчали углы)
        local Body = MakeFrame({
            Parent = Root.Instance,
            Pos = UDim2.fromOffset(0, TopH + 1),
            Size = UDim2.new(1, 0, 1, -(TopH + 1)),
            Z = 75
        })
        Body.Instance.Visible = false

        local List = Library:Create("Frame", {
            Parent = Body.Instance,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 76
        })

        Library:Create("UIListLayout", {
            Parent = List.Instance,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        })

        Library:Create("UIPadding", {
            Parent = List.Instance,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })

        -- Перетаскивание в ЛЮБОМ месте (MakeDraggable):
        Root:MakeDraggable(Root.Instance)
        Root:MakeDraggable(Topbar.Instance)
        Root:MakeDraggable(Body.Instance)
        Root:MakeDraggable(List.Instance)

        Library.KeybindRoot = Root
        Library.KeybindTopbar = Topbar
        Library.KeybindTopLine = TopLine
        Library.KeybindBody = Body
        Library.KeybindListContainer = List

        local ResizeTween = nil
        local UpdateToken = 0

        Library.UpdateKeybindMenu = function(Self)
            if not Library.KeybindListContainer or not Library.KeybindListContainer.Instance then return end
            if not Library.KeybindMenuEnabled then return end

            UpdateToken = UpdateToken + 1
            local MyToken = UpdateToken

            local C = Library.KeybindListContainer.Instance
            for _, Child in ipairs(C:GetChildren()) do
                if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
                    Child:Destroy()
                end
            end

            -- Собираем ТОЛЬКО активные (включенные) функции с привязанными клавишами
            local ActiveEntries = { }
            for _, Entry in ipairs(Library.RegisteredKeybinds) do
                local Key = Entry.GetKey and Entry.GetKey()
                if Key and Key ~= Enum.KeyCode.Unknown then
                    local IsActive = Entry.GetActive and Entry.GetActive()
                    if IsActive then
                        table.insert(ActiveEntries, {
                            Entry = Entry,
                            Key = Key
                        })
                    end
                end
            end

            local Count = #ActiveEntries

            if Count > 0 then
                TopLine.Instance.Visible = true
                Body.Instance.Visible = true

                for Index, Item in ipairs(ActiveEntries) do
                    local KeyStr = KeyName(Item.Key) or "None"

                    local Row = MakeFrame({
                        Parent = C,
                        Size = UDim2.new(1, 0, 0, 18),
                        Z = 77
                    })
                    Row.Instance.LayoutOrder = Index

                    Root:MakeDraggable(Row.Instance)

                    -- Название функции в цвете темы (Accent)
                    local NameLabel = MakeText({
                        Parent = Row.Instance,
                        Text = Item.Entry.Name,
                        TextSize = 12,
                        Anchor = Vector2.new(0, 0.5),
                        Pos = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.new(1, -65, 1, 0),
                        Color = "Accent",
                        Truncate = true,
                        Z = 78
                    })
                    Root:MakeDraggable(NameLabel.Instance)

                    -- Кнопка [ E ] в цвете темы (Accent)
                    local KeyLabel = MakeText({
                        Parent = Row.Instance,
                        Text = "[ " .. string.upper(KeyStr) .. " ]",
                        TextSize = 12,
                        Bold = true,
                        Anchor = Vector2.new(1, 0.5),
                        Pos = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.fromOffset(65, 18),
                        Color = "Accent",
                        Align = Enum.TextXAlignment.Right,
                        Truncate = true,
                        Z = 78
                    })
                    Root:MakeDraggable(KeyLabel.Instance)
                end
            end

            local TargetH = TopH
            if Count > 0 then
                local ListH = (Count * 18) + ((Count - 1) * 2) + 8
                TargetH = TopH + 1 + ListH
            end

            if ResizeTween then
                pcall(function() ResizeTween:Cancel() end)
                ResizeTween = nil
            end

            local Info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            ResizeTween = TweenService:Create(Root.Instance, Info, { Size = UDim2.fromOffset(Width, TargetH) })
            ResizeTween:Play()

            if Count == 0 then
                TopLine.Instance.Visible = false
                task.delay(0.22, function()
                    if UpdateToken == MyToken and TopLine.Instance and Body.Instance then
                        TopLine.Instance.Visible = false
                        Body.Instance.Visible = false
                    end
                end)
            end
        end

        Library:UpdateKeybindMenu()
    end

    Library:Connect(UserInputService.InputBegan, function(Input, Processed)
        if Library.KeybindMenuEnabled and Library.UpdateKeybindMenu then
            task.defer(function()
                Library:UpdateKeybindMenu()
            end)
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(Input)
        if Library.KeybindMenuEnabled and Library.UpdateKeybindMenu then
            task.defer(function()
                Library:UpdateKeybindMenu()
            end)
        end
    end)

    Library.SetKeybindMenu = function(Self, Enabled)
        Library.KeybindMenuEnabled = (Enabled == true)
        if writefile then
            pcall(function()
                writefile(Library.KeybindFile, HttpService:JSONEncode({
                    Enabled = Library.KeybindMenuEnabled,
                    Transparency = Library.KeybindMenuTransparency
                }))
            end)
        end
        if Library.KeybindRoot and Library.KeybindRoot.Instance then
            Library.KeybindRoot.Instance.Visible = Library.KeybindMenuEnabled
        end
        if Library.KeybindMenuEnabled and Library.UpdateKeybindMenu then
            Library:UpdateKeybindMenu()
        end
        if Library.UpdateKeybindUI then
            Library:UpdateKeybindUI()
        end
    end

    Library.SetKeybindTransparency = function(Self, Pct)
        Library.KeybindMenuTransparency = math.clamp(Pct, 0, 1)
        if writefile then
            pcall(function()
                writefile(Library.KeybindFile, HttpService:JSONEncode({
                    Enabled = Library.KeybindMenuEnabled,
                    Transparency = Library.KeybindMenuTransparency
                }))
            end)
        end
        if Library.KeybindBody and Library.KeybindBody.Instance then
            Library.KeybindBody.Instance.BackgroundTransparency = Library.KeybindMenuTransparency
        end
    end

    Library.CatFrames = { }
    for i = 1, 8 do
        table.insert(Library.CatFrames, string.format("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/cat_run_right_%d.png", i))
    end

    pcall(function()
        if isfile then
            local LocalFrames = { }
            for i = 1, 8 do
                local P = Library.AssetsFolder .. "/cat_run_right_" .. i .. ".png"
                local Alt = "Assets/cat_run_right_" .. i .. ".png"
                if isfile(P) then
                    table.insert(LocalFrames, P)
                elseif isfile(Alt) then
                    table.insert(LocalFrames, Alt)
                end
            end
            if #LocalFrames >= 4 then
                Library.CatFrames = LocalFrames
            end
        end
    end)

    Library.SetCatFrames = function(Self, Frames)
        if type(Frames) == "table" and #Frames > 0 then
            Library.CatFrames = Frames
        end
    end

    Library.ShowWelcomeBanner = function(Self, Callback)
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local DisplayName = (LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name)) or "User"
        local Icon = (isfile and isfile(Library.AssetsFolder .. "/asset_23de81e2.png") and Library.AssetsFolder .. "/asset_23de81e2.png") or (isfile and isfile(Library.AssetsFolder .. "/jade-logo.png") and Library.AssetsFolder .. "/jade-logo.png") or (Library.GitHubBase .. "/asset_23de81e2.png")

        local Card = MakeFrame({
            Parent = Library.Holder.Instance,
            Anchor = Vector2.new(0.5, 0),
            Pos = UDim2.new(0.5, 0, 0, -80),
            Size = UDim2.fromOffset(290, 56),
            Color = "Background",
            Round = 10,
            Clip = true,
            Z = 120
        })

        Library:Create("UIStroke", {
            Parent = Card.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        local CatIcon = MakeImage({
            Parent = Card.Instance,
            Icon = Icon,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            Color = "Accent",
            Fit = true,
            Z = 122
        })

        local Title = MakeText({
            Parent = Card.Instance,
            Text = "Hello, " .. DisplayName,
            TextSize = 14,
            Bold = true,
            Color = "Text",
            Pos = UDim2.fromOffset(50, 11),
            Size = UDim2.new(1, -60, 0, 16),
            Truncate = true,
            Z = 122
        })

        local Subtitle = MakeText({
            Parent = Card.Instance,
            Text = "jade.xyz initialized • " .. (Library.CurrentThemeName or "Pitch Black"),
            TextSize = 12,
            Color = "Accent",
            Pos = UDim2.fromOffset(50, 29),
            Size = UDim2.new(1, -60, 0, 14),
            Truncate = true,
            Z = 122
        })

        local GlowBar = MakeFrame({
            Parent = Card.Instance,
            Anchor = Vector2.new(0.5, 1),
            Pos = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.fromOffset(100, 2.5),
            Color = "Accent",
            Round = 2,
            Z = 123
        })

        local GlowShadow = MakeAccentShadow(
            GlowBar.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            0.35
        )

        local SlideDown = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        Card:Tween({ Position = UDim2.new(0.5, 0, 0, 24) }, SlideDown)

        task.delay(2.6, function()
            local SlideUp = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            Card:Tween({ Position = UDim2.new(0.5, 0, 0, -80) }, SlideUp)
            Card:FadeDescendants(false)
            if GlowShadow then
                Library:Tween({ Transparency = 1 }, SlideUp, GlowShadow)
            end

            task.delay(0.4, function()
                if GlowShadow then
                    local SIndex = table.find(Library.AccentShadows, GlowShadow)
                    if SIndex then table.remove(Library.AccentShadows, SIndex) end
                end
                Card.Instance:Destroy()
                if Callback then Callback() end
            end)
        end)
    end

    Library.ShowLoader = function(Self, Params, OnFinished)
        Params = Params or { }
        if Params.GitHubBase then
            Library.GitHubBase = Params.GitHubBase
        elseif Params.GitHubRepo then
            Library.GitHubRepo = Params.GitHubRepo
            Library.GitHubBase = "https://raw.githubusercontent.com/" .. Library.GitHubUser .. "/" .. Library.GitHubRepo .. "/" .. Library.GitHubBranch
        end
        if Library.LoaderActive then
            if OnFinished then
                table.insert(Library.LoaderFinishedCallbacks, OnFinished)
            end
            return
        end
        Library.LoaderActive = true

        local Icon = Params.Icon or (isfile and isfile(Library.AssetsFolder .. "/asset_23de81e2.png") and Library.AssetsFolder .. "/asset_23de81e2.png") or (isfile and isfile(Library.AssetsFolder .. "/jade-logo.png") and Library.AssetsFolder .. "/jade-logo.png") or (Library.GitHubBase .. "/asset_23de81e2.png")

        local Card = MakeFrame({
            Parent = Library.Holder.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(360, 160),
            Color = "Background",
            Round = 10,
            Clip = true,
            Z = 100
        })

        Library:Create("UIStroke", {
            Parent = Card.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        local TopLogo = MakeImage({
            Parent = Card.Instance,
            Icon = Icon,
            Pos = UDim2.fromOffset(16, 14),
            Size = UDim2.fromOffset(26, 26),
            Color = "Accent",
            Fit = true,
            Z = 102
        })

        local Title = MakeText({
            Parent = Card.Instance,
            Text = "jade.xyz",
            TextSize = 18,
            Bold = true,
            Color = "Accent",
            Pos = UDim2.fromOffset(50, 16),
            Size = UDim2.fromOffset(90, 22),
            Z = 102
        })

        local Subtitle = MakeText({
            Parent = Card.Instance,
            Text = "is loading...",
            TextSize = 13,
            Color = "DimText",
            Pos = UDim2.fromOffset(144, 18),
            Size = UDim2.fromOffset(110, 18),
            Z = 102
        })

        local StepLabel = MakeText({
            Parent = Card.Instance,
            Text = "[1/5]",
            TextSize = 12,
            Bold = true,
            Color = "Accent",
            Pos = UDim2.new(1, -65, 0, 18),
            Size = UDim2.fromOffset(50, 18),
            Align = Enum.TextXAlignment.Right,
            Z = 102
        })

        local StatusLabel = MakeText({
            Parent = Card.Instance,
            Text = "Verifying executor environment & filesystem...",
            TextSize = 12,
            Bold = true,
            Color = "Text",
            Pos = UDim2.new(0, 18, 0, 48),
            Size = UDim2.new(1, -36, 0, 18),
            Truncate = true,
            Z = 102
        })

        local DetailLabel = MakeText({
            Parent = Card.Instance,
            Text = "Checking IO permissions & directories...",
            TextSize = 11,
            Color = "DimText",
            Pos = UDim2.new(0, 18, 0, 68),
            Size = UDim2.new(1, -36, 0, 16),
            Truncate = true,
            Z = 102
        })

        local Track = MakeFrame({
            Parent = Card.Instance,
            Pos = UDim2.new(0, 42, 0, 126),
            Size = UDim2.new(1, -84, 0, 4),
            Color = "Element",
            Round = 2,
            Clip = false,
            Z = 102
        })

        local Fill = MakeFrame({
            Parent = Track.Instance,
            Size = UDim2.new(0, 0, 1, 0),
            Color = "Accent",
            Round = 2,
            Z = 103
        })

        local FillShadow = MakeAccentShadow(
            Fill.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            0.35
        )

        local CatRunner = MakeImage({
            Parent = Track.Instance,
            Anchor = Vector2.new(0.5, 1),
            Pos = UDim2.new(0, 0, 0, 1),
            Size = UDim2.fromOffset(46, 33),
            Icon = Icon,
            Color = "Accent",
            Fit = true,
            Z = 105
        })

        local BottomBar = MakeFrame({
            Parent = Card.Instance,
            Anchor = Vector2.new(0.5, 1),
            Pos = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.fromOffset(140, 2.5),
            Color = "Accent",
            Round = 2,
            Z = 104
        })

        local BottomShadow = MakeAccentShadow(
            BottomBar.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            0.35
        )

        local TargetProgress = 0
        local CurrentProgress = 0
        local FrameTick = 0
        local FrameIdx = 1
        local Running = true
        local WantExtraFonts = false

        local function SafeClick(BtnObj, Action)
            local LastClick = 0
            local function Run()
                local Now = os.clock()
                if Now - LastClick < 0.25 then return end
                LastClick = Now
                Action()
            end

            if BtnObj.Instance:IsA("GuiButton") then
                BtnObj.Instance.Active = true
                BtnObj.Instance.Selectable = false
                BtnObj.Instance.AutoButtonColor = false
                BtnObj.Instance.Activated:Connect(Run)
                BtnObj.Instance.MouseButton1Click:Connect(Run)
                BtnObj.Instance.MouseButton1Down:Connect(Run)
            else
                BtnObj:Connect("MouseButton1Down", Run)
            end
        end

        local PipelineStarted = false
        local function RunLoaderPipeline()
            if PipelineStarted then return end
            PipelineStarted = true

            local RunnerConn
            RunnerConn = RunService.RenderStepped:Connect(function(Delta)
                if not Running then return end
                CurrentProgress = CurrentProgress + (TargetProgress - CurrentProgress) * math.clamp(Delta * 7, 0.05, 1)
                Fill.Instance.Size = UDim2.new(CurrentProgress, 0, 1, 0)
                CatRunner.Instance.Position = UDim2.new(CurrentProgress, 0, 0, 1)

                FrameTick = FrameTick + Delta
                if FrameTick >= 0.065 and #Library.CatFrames > 1 then
                    FrameTick = 0
                    FrameIdx = (FrameIdx % #Library.CatFrames) + 1
                    local FrameAsset = Library.CatFrames[FrameIdx]
                    if FrameAsset then
                        if (isfile and isfile(FrameAsset)) or not string.match(FrameAsset, "^https?://") then
                            ApplyIcon(CatRunner.Instance, FrameAsset)
                        end
                    end
                end
            end)

            local Stages = {
                {
                    Title = "Verifying executor filesystem & directories",
                    Target = 0.20,
                    Run = function()
                        local Created = 0
                        if isfolder and makefolder then
                            for _, Folder in { "Jade", "Jade/Configs", "Jade/Assets" } do
                                if not isfolder(Folder) then
                                    makefolder(Folder)
                                    Created = Created + 1
                                end
                            end
                        end

                        -- Pre-fetch first frame if workspace is completely empty so CatRunner shows instantly
                        if isfile and not isfile(Library.AssetsFolder .. "/cat_run_right_1.png") and game and game.HttpGet and writefile then
                            local Frame1Urls = {
                                "https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/cat_run_right_1.png",
                                "https://github.com/777DmOrYber777/jade.xyz/blob/main/cat_run_right_1.png?raw=true",
                                "https://raw.githubusercontent.com/777DmOrYber777/images/main/cat_run_right_1.png"
                            }
                            for _, Url in ipairs(Frame1Urls) do
                                local Ok, Body = pcall(function() return game:HttpGet(Url) end)
                                if Ok and Body and #Body > 100 then
                                    writefile(Library.AssetsFolder .. "/cat_run_right_1.png", Body)
                                    ApplyIcon(CatRunner.Instance, Library.AssetsFolder .. "/cat_run_right_1.png")
                                    break
                                end
                            end
                        end

                        task.wait(0.20)
                        return Created > 0 and string.format("Created %d missing directories", Created) or "Filesystem active • IO verified"
                    end
                },
                {
                    Title = "Verifying & downloading cat runner sprite assets",
                    Target = 0.45,
                    Run = function()
                        local MissingFrames = { }
                        local DownloadedCount = 0
                        local TotalFrames = 8

                        for i = 1, TotalFrames do
                            local FileName = "cat_run_right_" .. i .. ".png"
                            local LocalPath = Library.AssetsFolder .. "/" .. FileName
                            local AltPath = "Assets/" .. FileName

                            local Exists = (isfile and (isfile(LocalPath) or isfile(AltPath)))
                            if not Exists then
                                table.insert(MissingFrames, { Index = i, File = FileName, Path = LocalPath })
                            end
                        end

                        if #MissingFrames > 0 and game and game.HttpGet and writefile then
                            DetailLabel.Instance.Text = string.format("Downloading %d missing frames from GitHub...", #MissingFrames)
                            for _, Item in ipairs(MissingFrames) do
                                local Candidates = {
                                    string.format("https://raw.githubusercontent.com/777DmOrYber777/jade.xyz/main/cat_run_right_%d.png", Item.Index),
                                    string.format("https://github.com/777DmOrYber777/jade.xyz/blob/main/cat_run_right_%d.png?raw=true", Item.Index),
                                    string.format("https://raw.githubusercontent.com/777DmOrYber777/images/main/cat_run_right_%d.png", Item.Index)
                                }
                                for _, Url in ipairs(Candidates) do
                                    local Ok, Body = pcall(function()
                                        return game:HttpGet(Url)
                                    end)
                                    if Ok and Body and #Body > 100 then
                                        writefile(Item.Path, Body)
                                        DownloadedCount = DownloadedCount + 1
                                        break
                                    end
                                end
                            end
                        end

                        -- Also verify logo icon
                        local LogoPath = Library.AssetsFolder .. "/asset_23de81e2.png"
                        local AltLogoPath = Library.AssetsFolder .. "/jade-logo.png"
                        if isfile and not isfile(LogoPath) and not isfile(AltLogoPath) and game and game.HttpGet and writefile then
                            pcall(function()
                                local LogoUrl = Library.GitHubBase .. "/asset_23de81e2.png"
                                local Body = game:HttpGet(LogoUrl)
                                if Body and #Body > 100 then
                                    writefile(LogoPath, Body)
                                    writefile(AltLogoPath, Body)
                                end
                            end)
                        end

                        -- Re-scan cat frames into Library.CatFrames so runner uses newly downloaded frames
                        local LocalFrames = { }
                        if isfile then
                            for i = 1, TotalFrames do
                                local P = Library.AssetsFolder .. "/cat_run_right_" .. i .. ".png"
                                local Alt = "Assets/cat_run_right_" .. i .. ".png"
                                if isfile(P) then
                                    table.insert(LocalFrames, P)
                                elseif isfile(Alt) then
                                    table.insert(LocalFrames, Alt)
                                end
                            end
                        end

                        if #LocalFrames >= 4 then
                            Library.CatFrames = LocalFrames
                        end

                        task.wait(0.20)
                        if DownloadedCount > 0 then
                            return string.format("Downloaded %d/%d frames from GitHub", DownloadedCount, TotalFrames)
                        else
                            return string.format("%d/8 sprite frames verified & cached", #Library.CatFrames)
                        end
                    end
                },
                {
                    Title = "Verifying & caching pixel typography fonts",
                    Target = 0.65,
                    Run = function()
                        DetailLabel.Instance.Text = "Loading typography fonts (PixelCode, Tamzen, Gotham)..."
                        pcall(function()
                            Library:LoadFontFamily("PixelCode")
                            Library:LoadFontFamily("Tamzen")
                            Library:LoadFontFamily("Gotham")
                        end)

                        local ActiveFont = Library.CurrentFontName or "PixelCode"
                        local IconCount = 0
                        if IconPack and IconPack.GetIcons then
                            pcall(function() IconCount = #IconPack.GetIcons() end)
                        end
                        task.wait(0.25)
                        return string.format("Font: %s • %d glyphs cached", ActiveFont, IconCount > 0 and IconCount or 112)
                    end
                },
                {
                    Title = "Loading theme profile & configurations",
                    Target = 0.85,
                    Run = function()
                        -- Ensure default font config exists
                        if isfile and not isfile(Library.FontFile) and writefile then
                            pcall(function()
                                writefile(Library.FontFile, HttpService:JSONEncode({ Font = "PixelCode" }))
                            end)
                        end

                        Library:LoadSavedTheme()
                        local ConfigsCount = 0
                        if isfolder and isfolder("Jade/Configs") and listfiles then
                            pcall(function() ConfigsCount = #listfiles("Jade/Configs") end)
                        end
                        task.wait(0.20)
                        return string.format("Theme: %s • %d config(s)", Library.CurrentThemeName or "Pitch Black Jade", ConfigsCount)
                    end
                },
                {
                    Title = "Checking game services & ping latency",
                    Target = 1.0,
                    Run = function()
                        local PlaceName = "Roblox Place"
                        pcall(function()
                            local Data = MarketplaceService:GetProductInfo(game.PlaceId)
                            if Data and Data.Name then PlaceName = Data.Name end
                        end)
                        local Ping = 0
                        pcall(function()
                            Ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                        end)
                        task.wait(0.25)
                        return string.format("%s • %d ms • Ready!", string.sub(PlaceName, 1, 24), Ping)
                    end
                }
            }

            Library:Thread(function()
                for Index, Stage in ipairs(Stages) do
                    StepLabel.Instance.Text = string.format("[%d/%d]", Index, #Stages)
                    StatusLabel.Instance.Text = Stage.Title .. "..."
                    TargetProgress = Stage.Target

                    local Result = Stage.Run()
                    DetailLabel.Instance.Text = Result
                    task.wait(0.15)
                end

                TargetProgress = 1
                task.wait(0.35)
                Running = false
                if RunnerConn then
                    RunnerConn:Disconnect()
                    RunnerConn = nil
                end

                local FadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                Card:Tween({ Size = UDim2.fromOffset(360, 0), Position = UDim2.new(0.5, 0, 0.5, 20) }, FadeInfo)
                Card:FadeDescendants(false)
                if BottomShadow then
                    Library:Tween({ Transparency = 1 }, FadeInfo, BottomShadow)
                end
                if FillShadow then
                    Library:Tween({ Transparency = 1 }, FadeInfo, FillShadow)
                end

                task.delay(0.4, function()
                    if BottomShadow then
                        local S1 = table.find(Library.AccentShadows, BottomShadow)
                        if S1 then table.remove(Library.AccentShadows, S1) end
                    end
                    if FillShadow then
                        local S2 = table.find(Library.AccentShadows, FillShadow)
                        if S2 then table.remove(Library.AccentShadows, S2) end
                    end
                    Card.Instance:Destroy()

                    Library.LoaderActive = false

                    if OnFinished then
                        pcall(OnFinished)
                    end

                    for _, Cb in ipairs(Library.LoaderFinishedCallbacks) do
                        pcall(Cb)
                    end
                    table.clear(Library.LoaderFinishedCallbacks)
                end)
            end)
        end

        RunLoaderPipeline()
    end

    Library.Loader = Library.ShowLoader
    Library.WelcomeBanner = Library.ShowWelcomeBanner

    Library.Window = function(Self, Params)
        Params = Params or { }

        local W = Library.WindowWidth
        local H = Library.WindowHeight
        local TopH = 51
        local Gap = 10
        local RailW = 60
        local RailH = 340
        local SubW = 260
        local SubH = 50
        local MainX = RailW + Gap
        local RailY = math.floor((H - RailH) / 2)
        local SubX = MainX + math.floor((W - SubW) / 2)
        local SubY = H - math.floor(SubH / 2)
        local RootW = MainX + W
        local RootH = SubY + SubH
        local ColW = math.floor((W - 46) / 2)
        local Col2X = ColW + 16
        local SubCenterX = MainX + math.floor(W / 2)
        local MaxSubW = W - 120

        local Window = {
            Name = Params.Name or "jade.xyz",
            Icon = Params.Icon or (Library.GitHubBase .. "/jade-xyz-icon-1024-removebg-preview.png"),
            IsOpen = true,
            Tabs = { },
            Current = nil,
            ContentW = W - 30,
            ContentH = H - 96,
            ColW = ColW,
            Col2X = Col2X,
            Items = { }
        }

        if Params.Accent then
            Library:SetAccent(Params.Accent)
        end

        local Items = { }
        local Viewport = workspace.CurrentCamera.ViewportSize
        local Scale = Library:GetScreenScale()

        Items.Root = MakeFrame({
            Parent = Library.Holder.Instance,
            Pos = UDim2.fromOffset(
                Viewport.X / (2 * Scale) - RootW / 2,
                Viewport.Y / (2 * Scale) - RootH / 2
            ),
            Size = UDim2.fromOffset(RootW, RootH),
            Z = 1
        })

        Items.Main = MakeFrame({
            Parent = Items.Root.Instance,
            Pos = UDim2.fromOffset(MainX, 0),
            Size = UDim2.fromOffset(W, H),
            Color = "Background",
            Round = 10,
            Clip = true,
            Z = 1
        })

        local BgHolder = Library:Create("Frame", {
            Parent = Items.Main.Instance,
            Name = "AnimatedBackground",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, TopH),
            Size = UDim2.new(1, 0, 1, -TopH),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1
        })
        Library.AnimBgHolder = BgHolder.Instance
        Library:SetupAnimatedBackground(BgHolder.Instance)
        Library:SetupKeybindMenu()

        Library:Create("UIStroke", {
            Parent = Items.Main.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        Items.Rail = MakeFrame({
            Parent = Items.Root.Instance,
            Pos = UDim2.fromOffset(0, RailY),
            Size = UDim2.fromOffset(RailW, RailH),
            Color = "Background",
            Round = 10,
            Z = 1
        })

        Library:Create("UIStroke", {
            Parent = Items.Rail.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        Items.SubBar = MakeFrame({
            Parent = Items.Root.Instance,
            Pos = UDim2.fromOffset(SubX, SubY),
            Size = UDim2.fromOffset(SubW, SubH),
            Color = "Background",
            Round = 10,
            Clip = true,
            Z = 20
        })

        Library:Create("UIStroke", {
            Parent = Items.SubBar.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        Items.TopBar = MakeFrame({
            Parent = Items.Main.Instance,
            Size = UDim2.fromOffset(W, TopH),
            Color = "Section",
            Round = 10,
            Z = 2
        })

        MakeFrame({
            Parent = Items.TopBar.Instance,
            Pos = UDim2.fromOffset(0, TopH - 12),
            Size = UDim2.fromOffset(W, 12),
            Color = "Section",
            Z = 2
        })

        Items.TopLine = MakeFrame({
            Parent = Items.Main.Instance,
            Pos = UDim2.fromOffset(0, 50),
            Size = UDim2.fromOffset(W, 1),
            Color = "Element",
            Z = 3
        })

        Items.Search = MakeFrame({
            Parent = Items.TopBar.Instance,
            Pos = UDim2.fromOffset(14, 10),
            Size = UDim2.fromOffset(220, 30),
            Color = "Element",
            Round = 6,
            Z = 3
        })

        MakeImage({
            Parent = Items.Search.Instance,
            Icon = "search",
            Pos = UDim2.fromOffset(8, 7),
            Size = UDim2.fromOffset(16, 16),
            Color = "DimText",
            Z = 4
        })

        Items.SearchBox = MakeInput({
            Parent = Items.Search.Instance,
            Placeholder = "search",
            Pos = UDim2.fromOffset(30, -1),
            Size = UDim2.new(1, -38, 1, 0),
            TextSize = 15,
            Z = 4
        })

        local TitleHolder = MakeFrame({
            Parent = Items.TopBar.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(140, 30),
            Z = 3
        })

        local TitleText = MakeText({
            Parent = TitleHolder.Instance,
            Text = "jade.xyz",
            TextSize = 16,
            Bold = true,
            Color = "Accent",
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Align = Enum.TextXAlignment.Center,
            Z = 4
        })

        Items.TitleText = TitleText
        Library.TitleText = TitleText
        Library:SetBaseline(TitleText.Instance, "TextTransparency", 0)
        Library:StampResting(TitleText.Instance, "TextTransparency", 0)

        local ScrambleChars = { "!", "@", "#", "$", "%", "&", "*", "/", "?", "<", ">", "~", "0", "1", "7", "x", "z" }
        local function GetScrambleChar()
            return ScrambleChars[math.random(1, #ScrambleChars)]
        end

        local TargetWord = "jade.xyz"

        -- Анимация печатания jade.xyz (Typewriter + декодирование)
        Library:Thread(function()
            local Len = #TargetWord
            while true do
                -- Если всё окно или его шапка уничтожены (например, при Unload), завершаем поток
                if not Window or not Items.TopBar or not Items.TopBar.Instance or not Items.TopBar.Instance.Parent then
                    break
                end

                -- Если меню скрыто через бинд, ждём и сохраняем поток активным
                if not Window.IsOpen then
                    task.wait(0.25)
                    continue
                end

                if not TitleText.Instance or not TitleText.Instance.Parent then
                    task.wait(0.5)
                    continue
                end

                -- Гарантируем видимость и правильный цвет по текущей теме
                pcall(function()
                    TitleText.Instance.Visible = true
                    TitleText.Instance.TextTransparency = 0
                    TitleText.Instance.TextColor3 = Library.Theme.Accent
                end)

                -- Безопасный полный цикл анимации печати и стирания
                local CycleOk = pcall(function()
                    -- Посимвольная печать со скрэмблом
                    for i = 1, Len do
                        if not Window.IsOpen then return end
                        if not TitleText.Instance or not TitleText.Instance.Parent then return end
                        TitleText.Instance.TextColor3 = Library.Theme.Accent
                        TitleText.Instance.TextTransparency = 0
                        TitleText.Instance.Text = string.sub(TargetWord, 1, i - 1) .. GetScrambleChar()
                        task.wait(0.06)
                        if not Window.IsOpen then return end
                        TitleText.Instance.Text = string.sub(TargetWord, 1, i)
                        task.wait(0.07)
                    end

                    if not Window.IsOpen then return end
                    TitleText.Instance.TextColor3 = Library.Theme.Accent
                    TitleText.Instance.Text = TargetWord
                    task.wait(3.8)

                    if not Window.IsOpen then return end
                    -- Быстрое стирание и повтор печати
                    for i = Len, 1, -1 do
                        if not Window.IsOpen then return end
                        if not TitleText.Instance or not TitleText.Instance.Parent then return end
                        TitleText.Instance.TextColor3 = Library.Theme.Accent
                        TitleText.Instance.TextTransparency = 0
                        TitleText.Instance.Text = string.sub(TargetWord, 1, i - 1) .. GetScrambleChar()
                        task.wait(0.04)
                        if not Window.IsOpen then return end
                        TitleText.Instance.Text = string.sub(TargetWord, 1, i - 1)
                        task.wait(0.03)
                    end

                    if Window.IsOpen and TitleText.Instance and TitleText.Instance.Parent then
                        TitleText.Instance.TextColor3 = Library.Theme.Accent
                        TitleText.Instance.TextTransparency = 0
                        TitleText.Instance.Text = "_"
                        task.wait(0.15)
                    end
                end)

                if not CycleOk then
                    pcall(function()
                        if TitleText.Instance and TitleText.Instance.Parent then
                            TitleText.Instance.Text = TargetWord
                            TitleText.Instance.TextColor3 = Library.Theme.Accent
                            TitleText.Instance.TextTransparency = 0
                            TitleText.Instance.Visible = true
                        end
                    end)
                    task.wait(0.5)
                end
            end
        end)

        Items.Username = MakeText({
            Parent = Items.TopBar.Instance,
            Text = LocalPlayer.DisplayName,
            TextSize = 15,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, -56, 0, 8),
            Size = UDim2.fromOffset(240, 18),
            Color = "Text",
            Align = Enum.TextXAlignment.Right,
            Truncate = true,
            Z = 3
        })

        Items.Version = MakeFrame({
            Parent = Items.TopBar.Instance,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, -56, 0, 29),
            Size = UDim2.fromOffset(36, 14),
            Color = "Background",
            Round = 3,
            Z = 3
        })

        Library:Create("UIStroke", {
            Parent = Items.Version.Instance,
            Color = Library.Theme.Element,
            Thickness = 1
        }):AddToTheme({ Color = "Element" })

        MakeText({
            Parent = Items.Version.Instance,
            Text = "v" .. Library.Version,
            TextSize = 12,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "DimText",
            Align = Enum.TextXAlignment.Center,
            Z = 4
        })

        local function MakeAvatar(Parent, Props)
            local Avatar = Library:Create("ImageLabel", {
                Parent = Parent,
                Name = "\0",
                AnchorPoint = Props.Anchor or Vector2.new(0, 0),
                Position = Props.Pos,
                Size = UDim2.fromOffset(Props.Size, Props.Size),
                BackgroundColor3 = Library.Theme.Element,
                ZIndex = Props.Z,
                BorderSizePixel = 0,
                Image = "rbxthumb://type=AvatarHeadShot&id="
                .. LocalPlayer.UserId
                .. "&w=" .. Props.Res .. "&h=" .. Props.Res
            }):AddToTheme({ BackgroundColor3 = "Element" })

            Corner(Avatar.Instance, Props.Round)
            return Avatar
        end

        Items.Avatar = MakeAvatar(Items.TopBar.Instance, {
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -10, 0.5, 0),
            Size = 30,
            Res = 60,
            Round = 20,
            Z = 3
        })

        Items.ProfileHit = MakeButton({
            Parent = Items.TopBar.Instance,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, -4, 0, 8),
            Size = UDim2.fromOffset(42, 36),
            Z = 5
        })

        local Profile = {
            IsOpen = false,
            Debounce = false
        }

        local ProfileW = 240

        local ProfilePanel = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(ProfileW, 272),
            Color = "Section",
            Round = 10,
            Z = 45
        })

        ProfilePanel.Instance.Visible = false

        MakeAvatar(ProfilePanel.Instance, {
            Pos = UDim2.fromOffset(14, 14),
            Size = 42,
            Res = 100,
            Round = 21,
            Z = 46
        })

        MakeText({
            Parent = ProfilePanel.Instance,
            Text = LocalPlayer.DisplayName,
            TextSize = 15,
            Pos = UDim2.fromOffset(68, 16),
            Size = UDim2.fromOffset(ProfileW - 82, 20),
            Color = "Text",
            Truncate = true,
            Z = 46
        })

        MakeText({
            Parent = ProfilePanel.Instance,
            Text = "@" .. LocalPlayer.Name,
            TextSize = 13,
            Pos = UDim2.fromOffset(68, 37),
            Size = UDim2.fromOffset(ProfileW - 82, 16),
            Color = "DimText",
            Truncate = true,
            Z = 46
        })

        local function ProfileDivider(Y)
            MakeFrame({
                Parent = ProfilePanel.Instance,
                Pos = UDim2.fromOffset(14, Y),
                Size = UDim2.fromOffset(ProfileW - 28, 1),
                Color = "Element",
                Z = 46
            })
        end

        local function ProfileStat(Y, Label, Value)
            MakeText({
                Parent = ProfilePanel.Instance,
                Text = Label,
                TextSize = 14,
                Pos = UDim2.fromOffset(14, Y),
                Size = UDim2.fromOffset(100, 18),
                Color = "DimText",
                Z = 46
            })

            MakeText({
                Parent = ProfilePanel.Instance,
                Text = Value,
                TextSize = 14,
                Anchor = Vector2.new(1, 0),
                Pos = UDim2.new(1, -14, 0, Y),
                Size = UDim2.fromOffset(120, 18),
                Color = "Text",
                Align = Enum.TextXAlignment.Right,
                Truncate = true,
                Z = 46
            })
        end

        ProfileDivider(68)
        ProfileStat(79, "User ID", tostring(LocalPlayer.UserId))
        ProfileStat(105, "Account age", tostring(LocalPlayer.AccountAge) .. " days")

        local IdHit = MakeButton({
            Parent = ProfilePanel.Instance,
            Pos = UDim2.fromOffset(10, 76),
            Size = UDim2.fromOffset(ProfileW - 20, 24),
            Z = 47
        })

        IdHit:Connect("MouseButton1Down", function()
            if setclipboard then
                pcall(setclipboard, tostring(LocalPlayer.UserId))
            end

            Library:Notification({
                Name = "User ID copied",
                Description = "Your user id is now in the clipboard.",
                Icon = "copy",
                Duration = 3
            })
        end)

        local RefreshProfilePos

        ProfileDivider(134)

        MakeText({
            Parent = ProfilePanel.Instance,
            Text = "Interface scale",
            TextSize = 14,
            Pos = UDim2.fromOffset(14, 146),
            Size = UDim2.fromOffset(140, 18),
            Color = "DimText",
            Z = 46
        })

        local ScaleValue = MakeText({
            Parent = ProfilePanel.Instance,
            Text = "100%",
            TextSize = 14,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, -14, 0, 146),
            Size = UDim2.fromOffset(60, 18),
            Color = "Text",
            Align = Enum.TextXAlignment.Right,
            Z = 46
        })

        local ScaleTrack = MakeFrame({
            Parent = ProfilePanel.Instance,
            Pos = UDim2.fromOffset(14, 172),
            Size = UDim2.fromOffset(ProfileW - 28, 8),
            Color = "Light",
            Round = 20,
            Z = 46
        })

        local ScaleFill = MakeFrame({
            Parent = ScaleTrack.Instance,
            Size = UDim2.new(0.5, 0, 1, 0),
            Raw = Color3.new(1, 1, 1),
            Round = 20,
            Z = 47
        })

        Library:RegisterGradient(Library:Create("UIGradient", {
            Parent = ScaleFill.Instance
        }).Instance)

        local ScaleKnob = MakeFrame({
            Parent = ScaleTrack.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            Raw = Color3.fromRGB(197, 197, 197),
            Round = 20,
            Z = 48
        })

        local ScaleHit = MakeButton({
            Parent = ProfilePanel.Instance,
            Pos = UDim2.fromOffset(8, 166),
            Size = UDim2.fromOffset(ProfileW - 16, 22),
            Z = 49
        })

        local ScaleGrab = false
        local ScalePercent = 100

        local function ApplyScale(Input)
            local Base = ScaleTrack.Instance
            local Span = (Input.Position.X - Base.AbsolutePosition.X) / Base.AbsoluteSize.X

            ScalePercent = Library:Round(50 + math.clamp(Span, 0, 1) * 100, 5)

            local Normal = (ScalePercent - 50) / 100

            ScaleValue.Instance.Text = tostring(ScalePercent) .. "%"
            ScaleFill.Instance.Size = UDim2.new(Normal, 0, 1, 0)
            ScaleKnob.Instance.Position = UDim2.new(Normal, 0, 0.5, 0)
        end

        ScaleHit:Connect("InputBegan", function(Input)
            local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if not IsClick and not IsTouch then return end

            ScaleGrab = true
            ApplyScale(Input)
        end)

        Library:Connect(UserInputService.InputEnded, function(Input)
            local IsClick = Input.UserInputType == Enum.UserInputType.MouseButton1
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if (IsClick or IsTouch) and ScaleGrab then
                ScaleGrab = false
                Library.UserScale = ScalePercent / 100
                UpdateScale()

                if RefreshProfilePos then RefreshProfilePos() end
            end
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            local IsMove = Input.UserInputType == Enum.UserInputType.MouseMovement
            local IsTouch = Input.UserInputType == Enum.UserInputType.Touch

            if (IsMove or IsTouch) and ScaleGrab then
                ApplyScale(Input)
            end
        end)

        MakeText({
            Parent = ProfilePanel.Instance,
            Text = "Menu toggle",
            TextSize = 14,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 14, 0, 205),
            Size = UDim2.fromOffset(110, 20),
            Color = "DimText",
            Z = 46
        })

        local KeyIcon = MakeImage({
            Parent = ProfilePanel.Instance,
            Icon = "command",
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -14, 0, 205),
            Size = UDim2.fromOffset(16, 16),
            Color = "DimText",
            Z = 46
        })

        local KeyIconHit = MakeButton({
            Parent = ProfilePanel.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -8, 0, 205),
            Size = UDim2.fromOffset(26, 26),
            Z = 48
        })

        KeyIconHit:OnHover(function()
            KeyIcon:Tween({ ImageColor3 = Library.Theme.Text })
        end, function()
            KeyIcon:Tween({ ImageColor3 = Library.Theme.DimText })
        end)

        local KeyPanelW = 170

        local KeyPanel = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(KeyPanelW, 72),
            Color = "Section",
            Round = 8,
            Z = 46
        })

        KeyPanel.Instance.Visible = false

        MakeText({
            Parent = KeyPanel.Instance,
            Text = "Menu keybind",
            TextSize = 12,
            Pos = UDim2.fromOffset(11, 8),
            Size = UDim2.fromOffset(KeyPanelW - 22, 14),
            Color = "DimText",
            Truncate = true,
            Z = 47
        })

        local KeyBox = MakeFrame({
            Parent = KeyPanel.Instance,
            Pos = UDim2.fromOffset(9, 32),
            Size = UDim2.fromOffset(KeyPanelW - 18, 30),
            Color = "Light",
            Round = 5,
            Clip = true,
            Z = 47
        })

        local KeyText = MakeText({
            Parent = KeyBox.Instance,
            Text = KeyName(Library.MenuKeybind),
            TextSize = 13,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "Text",
            Align = Enum.TextXAlignment.Center,
            Truncate = true,
            Z = 48
        })

        local KeyBoxHit = MakeButton({
            Parent = KeyBox.Instance,
            Z = 49
        })

        local KeyState = {
            IsOpen = false,
            Debounce = false,
            Picking = false,
            Host = Profile
        }

        local function KeyPlace(Off)
            local Anchor = KeyIcon.Instance
            local PScale = Library:GetScreenScale()
            local Right = Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X
            local PX = Right / PScale + 8 + (Off or 0)
            local PY = (Anchor.AbsolutePosition.Y + GuiInset) / PScale - 4

            return UDim2.fromOffset(PX, PY)
        end

        AttachPopup({
            Popup = KeyState,
            Frame = KeyPanel,
            Level = 46,
            GetAnchor = function()
                return KeyIconHit.Instance
            end,
            Place = KeyPlace,
            From = -6,
            To = 2,
            Retreat = RetreatLeft
        })

        KeyIconHit:Connect("MouseButton1Down", function()
            KeyState:SetOpen(not KeyState.IsOpen)
        end)

        KeyBoxHit:Connect("MouseButton1Click", function()
            if KeyState.Picking then return end

            KeyState.Picking = true
            Library.Binding = true
            KeyText.Instance.Text = ". . ."

            task.wait()

            local Connection

            Connection = UserInputService.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.Keyboard then return end

                Connection:Disconnect()

                if Input.KeyCode ~= Enum.KeyCode.Escape then
                    Library.MenuKeybind = Input.KeyCode
                end

                KeyText.Instance.Text = KeyName(Library.MenuKeybind)
                KeyState.Picking = false

                task.defer(function()
                    Library.Binding = false
                end)
            end)
        end)

        local UnloadButton = MakeFrame({
            Parent = ProfilePanel.Instance,
            Pos = UDim2.fromOffset(14, 236),
            Size = UDim2.fromOffset(ProfileW - 28, 28),
            Color = "Light",
            Round = 6,
            Clip = true,
            Z = 46
        })

        MakeText({
            Parent = UnloadButton.Instance,
            Text = "Unload",
            TextSize = 14,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "Text",
            Align = Enum.TextXAlignment.Center,
            Z = 47
        })

        local UnloadHit = MakeButton({
            Parent = UnloadButton.Instance,
            Z = 48
        })

        UnloadButton:OnHover(function()
            UnloadButton:Tween({ BackgroundColor3 = Library.Theme.Hover })
        end, function()
            UnloadButton:Tween({ BackgroundColor3 = Library.Theme.Light })
        end)

        UnloadHit:Connect("MouseButton1Down", function()
            Window:SetOpen(false)

            task.delay(Library.Animation.Time + 0.12, function()
                Library:Unload()
            end)
        end)

        local function ProfilePlace(Extra)
            local Anchor = Items.Avatar.Instance
            local PScale = Library:GetScreenScale()
            local Right = Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X
            local X = Right / PScale - ProfileW
            local Y = Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y + GuiInset

            return UDim2.fromOffset(X, Y / PScale + (Extra or 0))
        end

        RefreshProfilePos = function()
            if Profile.IsOpen then
                ProfilePanel.Instance.Position = ProfilePlace(10)
            end
        end

        AttachPopup({
            Popup = Profile,
            Frame = ProfilePanel,
            Level = 45,
            GetAnchor = function()
                return Items.ProfileHit.Instance
            end,
            Place = ProfilePlace,
            From = -2,
            To = 10,
            HoldOpen = function()
                return KeyState.IsOpen
            end
        })

        Window.Profile = Profile

        Items.ProfileHit:Connect("MouseButton1Down", function()
            Profile:SetOpen(not Profile.IsOpen)
        end)

        Items.Content = MakeFrame({
            Parent = Items.Main.Instance,
            Pos = UDim2.fromOffset(15, 65),
            Size = UDim2.fromOffset(W - 30, H - 96),
            Clip = true,
            Z = 2
        })

        Window.Items = Items

        Items.Root:MakeDraggable(Items.Main.Instance)
        Items.Root:MakeDraggable(Items.Rail.Instance)

        table.insert(Library.Windows, Window)

        function Window:Center()
            local CScale = Library:GetScreenScale()
            local Vp = workspace.CurrentCamera.ViewportSize

            Items.Root.Instance.Position = UDim2.fromOffset(
                Vp.X / (2 * CScale) - RootW / 2,
                Vp.Y / (2 * CScale) - RootH / 2
            )
        end

        function Window:LayoutRail()
            local Count = #Window.Tabs
            local NewH = Count > 0 and (50 * Count + 10) or RailH
            local NewY = math.floor((H - NewH) / 2)

            Items.Rail.Instance.Size = UDim2.fromOffset(RailW, NewH)
            Items.Rail.Instance.Position = UDim2.fromOffset(0, NewY)
        end

        function Window:FitSubBar(Instant)
            local Tab = Window.Current
            if not Tab or not Tab.SubLayout then return end
            if #Tab.Subs == 0 then return end

            local ContentScale = Library:GetScreenScale()
            local Content = Tab.SubLayout.AbsoluteContentSize.X / ContentScale + 16

            if Content <= 16 then return end

            local Overflow = Content > MaxSubW
            local Target = math.min(Content, MaxSubW)
            local NewX = SubCenterX - math.floor(Target / 2)

            local Info = Instant and TweenInfo.new(0)
            or TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            Library:Tween({
                Position = UDim2.fromOffset(NewX, SubY),
                Size = UDim2.fromOffset(Target, SubH)
            }, Info, Items.SubBar.Instance)

            local Row = Tab.Items.SubRow.Instance
            Row.ScrollingEnabled = Overflow
            Row.ScrollBarThickness = 0
        end

        function Window:LayoutSubBar(Instant)
            Window:FitSubBar(Instant)
        end

        function Window:SetIconSize(Size)
            Size = tonumber(Size) or 38
            Items.HubIcon.Instance.Size = UDim2.fromOffset(Size, Size)
            Items.Search.Instance.Position = UDim2.fromOffset(Size + 20, 11)
        end

        function Window:SetOpen(Bool)
            Window.IsOpen = Bool

            if not Bool then
                Library:CloseAllPopups()
            end

            local Sub = Window.Current and Window.Current.Current
            if Sub and Sub.SnapVisible then
                Sub:SnapVisible()
            end

            if Bool and Window.PlayIntro then
                Window:PlayIntro()
            else
                Items.Root:FadeDescendants(Bool)
            end

            if Bool and TitleText and TitleText.Instance then
                pcall(function()
                    TitleText.Instance.Visible = true
                    TitleText.Instance.TextTransparency = 0
                    TitleText.Instance.TextColor3 = Library.Theme.Accent
                end)
            end

            if not Bool then
                pcall(function() UserInputService.MouseIconEnabled = true end)
            end
        end

        Library:Connect(UserInputService.InputBegan, function(Input, Processed)
            if Processed or Library.Binding then return end

            if Input.KeyCode == Library.MenuKeybind then
                Window:SetOpen(not Window.IsOpen)
            end
        end)

        local function RunSearch(Query)
            Query = string.lower(Query)

            for _, Data in Library.Searchables do
                if Data.Window ~= Window then continue end

                local Match = Query == ""
                or string.find(string.lower(Data.Name), Query, 1, true) ~= nil

                if not Match and Data.Section then
                    Match = string.find(string.lower(Data.Section.Name), Query, 1, true) ~= nil
                end

                Data.Visible = Match

                if Data.Section then
                    Data.Section.Dirty = true
                end
            end

            for _, Tab in Window.Tabs do
                for _, Sub in Tab.Subs do
                    for _, Section in Sub.Sections do
                        if Section.Dirty then
                            Section.Dirty = false
                            Section:Reflow()
                        end
                    end
                end
            end

            local Tab = Window.Current
            local Sub = Tab and Tab.Current

            if Sub and #Sub.Sections > 0 then
                local Sig = tostring(Sub)

                for _, Section in Sub.Sections do
                    for _, Data in Section.Rows do
                        Sig ..= Data.Visible ~= false and "1" or "0"
                    end
                end

                if Sig ~= Window.SearchSig then
                    Window.SearchSig = Sig
                    Sub:Show()
                end
            end
        end

        local SearchToken = 0

        Library:Connect(Items.SearchBox.Instance:GetPropertyChangedSignal("Text"), function()
            SearchToken += 1

            local Token = SearchToken

            task.delay(0.1, function()
                if Token ~= SearchToken then return end
                RunSearch(Items.SearchBox.Instance.Text)
            end)
        end)

        function Window:PlayIntro()
            local Base = Items.Root.Instance.Position
            local Rise = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            Items.Root.Instance.Position = UDim2.fromOffset(
                Base.X.Offset,
                Base.Y.Offset + 24
            )

            Items.Root.Instance.Visible = true
            Items.Root:FadeDescendants(true)
            Library:Tween({ Position = Base }, Rise, Items.Root.Instance)
        end

        if Library.LoaderActive then
            Items.Root.Instance.Visible = false
            table.insert(Library.LoaderFinishedCallbacks, function()
                Library:ShowWelcomeBanner()
                Window:PlayIntro()
            end)
        elseif Params.Loader == true then
            Items.Root.Instance.Visible = false
            task.defer(function()
                Library:ShowLoader(Params, function()
                    Library:ShowWelcomeBanner()
                    Window:PlayIntro()
                end)
            end)
        else
            task.defer(function()
                Window:PlayIntro()
            end)
        end

        return setmetatable(Window, Library)
    end

    Library.Tab = function(Self, Params)
        Params = Params or { }

        local Window = Self

        local Tab = {
            Name = Params.Name or "Tab",
            Icon = Params.Icon or "circle",
            Window = Window,
            Subs = { },
            Current = nil,
            Active = false,
            Items = { }
        }

        local Items = { }
        local Index = #Window.Tabs
        local RowY = 10 + Index * 50

        Items.Row = MakeFrame({
            Parent = Window.Items.Rail.Instance,
            Pos = UDim2.fromOffset(10, RowY),
            Size = UDim2.fromOffset(40, 40),
            Color = "Element",
            Round = 8,
            Clip = true,
            Z = 3
        })

        SetRest(Items.Row.Instance, "BackgroundTransparency", 1)

        Items.Bar = MakeFrame({
            Parent = Window.Items.Rail.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0, 9, 0, RowY + 20),
            Size = UDim2.fromOffset(2.5, 0),
            Color = "Accent",
            Round = 2,
            Z = 5
        })

        Items.BarShadow = MakeAccentShadow(
            Items.Bar.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            1
        )

        if Items.BarShadow then
            SetRest(Items.BarShadow, "Transparency", 1)
        end

        Items.Icon = MakeImage({
            Parent = Items.Row.Instance,
            Icon = Tab.Icon,
            Pos = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(20, 20),
            Color = "DimIcon",
            Z = 4
        })

        Items.Hit = MakeButton({
            Parent = Items.Row.Instance,
            Z = 6
        })

        Items.SubRow = Library:Create("ScrollingFrame", {
            Parent = Window.Items.SubBar.Instance,
            Name = "\0",
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.X,
            ScrollingEnabled = false,
            Selectable = false,
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            CanvasSize = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            BorderSizePixel = 0
        }):AddToTheme({ ScrollBarImageColor3 = "Accent" })

        Items.SubRow.Instance.Visible = false

        Items.SubLayout = Library:Create("UIListLayout", {
            Parent = Items.SubRow.Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })

        Library:Create("UIPadding", {
            Parent = Items.SubRow.Instance,
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })

        Window.Items.Root:MakeDraggable(Items.SubRow.Instance)

        Tab.SubLayout = Items.SubLayout.Instance

        Library:Connect(Tab.SubLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            if Window.Current == Tab then
                Window:FitSubBar(true)
            end
        end)

        Tab.Items = Items

        function Tab:SetVisual(Active)
            Tab.Active = Active

            Library:StampResting(Items.Row.Instance, "BackgroundTransparency", Active and 0 or 1)

            if Items.BarShadow then
                Library:StampResting(Items.BarShadow, "Transparency", Active and 0.35 or 1)
                Items.BarShadow.Transparency = Active and 0.35 or 1
            end

            Items.Icon:ChangeItemTheme({ ImageColor3 = Active and "Accent" or "DimIcon" })
            Items.Icon:Tween({
                ImageColor3 = Active and Library.Theme.Accent or Library.Theme.DimIcon
            })

            Items.Row:Tween({ BackgroundTransparency = Active and 0 or 1 })
            Items.Bar:Tween({ Size = UDim2.fromOffset(2.5, Active and 18 or 0) })

            if Items.BarShadow then
                Items.Row:Tween({ Transparency = Active and 0.35 or 1 }, nil, Items.BarShadow)
            end
        end

        Items.Row:OnHover(function()
            if Tab.Active then return end
            Items.Icon:Tween({ ImageColor3 = Library.Theme.Text })
        end, function()
            if Tab.Active then return end
            Items.Icon:Tween({ ImageColor3 = Library.Theme.DimIcon })
        end)

        local function EnterFirstSub()
            local Sub = Tab.Current or Tab.Subs[1]
            if not Sub then return end

            Tab.Current = Sub

            for _, Other in Tab.Subs do
                Other:SetVisual(Other == Sub)
            end

            Sub:Show()
        end

        function Tab:Select()
            if Window.Current == Tab then return end

            Library:CloseAllPopups()

            if Window.Current then
                Window.Current:SetVisual(false)
                Window.Current.Items.SubRow.Instance.Visible = false

                if Window.Current.Current then
                    Window.Current.Current:Hide()
                end
            end

            Window.Current = Tab
            Tab:SetVisual(true)
            Items.SubRow.Instance.Visible = true

            EnterFirstSub()
            Window:LayoutSubBar()
        end

        Items.Hit:Connect("MouseButton1Down", function()
            Tab:Select()
        end)

        table.insert(Window.Tabs, Tab)
        Window:LayoutRail()

        if #Window.Tabs == 1 then
            Window.Current = Tab
            Tab:SetVisual(true)
            Items.SubRow.Instance.Visible = true

            task.defer(function()
                EnterFirstSub()
                Window:LayoutSubBar()
            end)
        end

        return setmetatable(Tab, Library)
    end

    Library.SubTab = function(Self, Params)
        Params = Params or { }

        local Tab = Self
        local Window = Tab.Window

        local SubTab = {
            Name = Params.Name or "SubTab",
            Icon = Params.Icon or "circle",
            Tab = Tab,
            Window = Window,
            Sections = { },
            Columns = { },
            Active = false,
            ShowToken = 0,
            Items = { }
        }

        local Items = { }
        local ContentW = Window.ContentW
        local ContentH = Window.ContentH
        local ColW = Window.ColW
        local Col2X = Window.Col2X

        local TextW = math.ceil(MeasureText(SubTab.Name, 15, 300, UiFont).X)
        local CollapsedW = 40
        local ExpandedW = 37 + TextW + 12

        SubTab.CollapsedW = CollapsedW
        SubTab.ExpandedW = ExpandedW

        Items.Pill = MakeFrame({
            Parent = Tab.Items.SubRow.Instance,
            Size = UDim2.fromOffset(CollapsedW, 30),
            Color = "Element",
            Round = 6,
            Clip = false,
            Z = 22
        })

        SetRest(Items.Pill.Instance, "BackgroundTransparency", 1)
        Items.Pill.Instance.LayoutOrder = #Tab.Subs

        Items.Underline = MakeFrame({
            Parent = Items.Pill.Instance,
            Anchor = Vector2.new(0.5, 1),
            Pos = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.fromOffset(0, 2.5),
            Color = "Accent",
            Round = 2,
            Z = 25
        })

        Items.UnderlineShadow = MakeAccentShadow(
            Items.Underline.Instance,
            UDim2.fromOffset(4, 4),
            UDim.new(0, 6),
            1
        )

        if Items.UnderlineShadow then
            SetRest(Items.UnderlineShadow, "Transparency", 1)
        end

        Items.Icon = MakeImage({
            Parent = Items.Pill.Instance,
            Icon = SubTab.Icon,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 11, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Color = "DimIcon",
            Z = 23
        })

        Items.Label = MakeText({
            Parent = Items.Pill.Instance,
            Text = SubTab.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 37, 0.5, 0),
            Size = UDim2.fromOffset(TextW + 8, 20),
            Color = "Text",
            Z = 23
        })

        SetRest(Items.Label.Instance, "TextTransparency", 1)

        local function SyncWidth()
            local Bounds = math.ceil(Items.Label.Instance.TextBounds.X)
            if Bounds <= 0 then return end

            ExpandedW = 37 + Bounds + 12
            SubTab.ExpandedW = ExpandedW
            Items.Label.Instance.Size = UDim2.fromOffset(Bounds + 8, 20)

            if Tab.Current == SubTab then
                Items.Pill.Instance.Size = UDim2.fromOffset(ExpandedW, 30)
                Window:FitSubBar(true)
            end
        end

        Library:Connect(Items.Label.Instance:GetPropertyChangedSignal("TextBounds"), SyncWidth)
        task.defer(SyncWidth)

        Items.Hit = MakeButton({
            Parent = Items.Pill.Instance,
            Z = 25
        })

        Items.Page = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(ContentW, ContentH),
            Z = 3
        })

        Items.Page.Instance.Visible = false

        local function MakeColumn(X)
            local Scroll = Library:Create("ScrollingFrame", {
                Parent = Items.Page.Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                ScrollBarThickness = 0,
                ScrollBarImageTransparency = 1,
                Selectable = false,
                Active = true,
                Position = UDim2.fromOffset(X, 0),
                Size = UDim2.fromOffset(ColW, ContentH),
                CanvasSize = UDim2.fromOffset(0, 0),
                ZIndex = 3,
                BorderSizePixel = 0
            })

            local Column = {
                Scroll = Scroll,
                Width = ColW,
                Sections = { }
            }

            function Column:Reflow()
                local Y = 0

                for _, Section in Column.Sections do
                    Section.Y = Y
                    Section.Items.Holder.Instance.Position = UDim2.fromOffset(0, Y)
                    Y += Section.Height + 16
                end

                Scroll.Instance.CanvasSize = UDim2.fromOffset(0, math.max(Y - 16, 0))
            end

            return Column
        end

        SubTab.Columns[1] = MakeColumn(0)
        SubTab.Columns[2] = MakeColumn(Col2X)
        SubTab.Items = Items

        function SubTab:SetVisual(Active, Instant)
            Library:StampResting(Items.Pill.Instance, "BackgroundTransparency", Active and 0 or 1)
            Library:StampResting(Items.Label.Instance, "TextTransparency", Active and 0 or 1)

            local Info = Instant and TweenInfo.new(0)
            or TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            local Width = Active and ExpandedW or CollapsedW
            local LineW = Active and math.floor(ExpandedW * 0.5) or 0

            Library:Tween({ Size = UDim2.fromOffset(Width, 30) }, Info, Items.Pill.Instance)
            Library:Tween({ TextTransparency = Active and 0 or 1 }, Info, Items.Label.Instance)

            Library:Tween({ Size = UDim2.fromOffset(LineW, 2.5) }, Info, Items.Underline.Instance)

            if Items.UnderlineShadow then
                Library:StampResting(Items.UnderlineShadow, "Transparency", Active and 0.35 or 1)
                Items.Underline:Tween({ Transparency = Active and 0.35 or 1 }, Info, Items.UnderlineShadow)
            end

            Items.Icon:ChangeItemTheme({ ImageColor3 = Active and "Accent" or "DimIcon" })
            Items.Icon:Tween({
                ImageColor3 = Active and Library.Theme.Accent or Library.Theme.DimIcon
            }, Info)

            Items.Pill:Tween({ BackgroundTransparency = Active and 0 or 1 }, Info)
        end

        Items.Pill:OnHover(function()
            if Tab.Current == SubTab then return end
            Items.Icon:Tween({ ImageColor3 = Library.Theme.Text })
        end, function()
            if Tab.Current == SubTab then return end
            Items.Icon:Tween({ ImageColor3 = Library.Theme.DimIcon })
        end)

        local RowIn = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local Sink = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        local PageSlide = 22
        local RowSlide = 18
        local SectionStep = 0.07
        local RowStep = 0.045

        local function ForEachSectionPart(Section, Handler)
            local Parts = Section.Items

            local Objects = {
                Parts.Header.Instance,
                Parts.HeaderFill.Instance,
                Parts.Label.Instance,
                Parts.Frame.Instance,
                Parts.BodyFill.Instance
            }

            for _, Object in Objects do
                local Properties = Library:GetTweenProperty(Object)
                if not Properties then continue end

                for _, Property in Properties do
                    Handler(Object, Property)
                end
            end
        end

        local function PrimeParts(Section)
            ForEachSectionPart(Section, function(Object, Property)
                Library:CaptureResting(Object, Property)
                Object[Property] = 1
            end)
        end

        local function RevealParts(Section)
            ForEachSectionPart(Section, function(Object, Property)
                local Resting = Library:CaptureResting(Object, Property)
                Library:Tween({ [Property] = Resting }, nil, Object)
            end)
        end

        local function ForEachRow(Handler)
            for _, Column in SubTab.Columns do
                for _, Section in Column.Sections do
                    for _, Data in Section.Rows do
                        Handler(Data, Section)
                    end
                end
            end
        end

        local PageTween

        local function StopTween(Handle)
            if not Handle then return end

            pcall(function()
                Handle:Cancel()
            end)
        end

        local function StopPageTween()
            StopTween(PageTween)
            PageTween = nil
        end

        local function StopRowTweens()
            ForEachRow(function(Data)
                StopTween(Data.Move)
                Data.Move = nil
            end)
        end

        local function LayoutPage()
            for _, Column in SubTab.Columns do
                for _, Section in Column.Sections do
                    Section.Items.Holder.Instance.Position = UDim2.fromOffset(0, Section.Y)
                    Section.Items.Frame.Instance.Position = UDim2.fromOffset(0, 26)

                    for _, Data in Section.Rows do
                        Data.Frame:CancelFade()
                        Data.Frame.Instance.Visible = Data.Visible ~= false
                    end
                end
            end
        end

        local function CleanPage()
            Items.Page.Instance.Position = UDim2.fromOffset(0, 0)
            Items.Page:HardRestore()

            LayoutPage()

            ForEachRow(function(Data)
                Data.Frame.Instance.Position = UDim2.fromOffset(0, Data.Y)
            end)
        end

        function SubTab:Show()
            SubTab.ShowToken += 1

            local Token = SubTab.ShowToken
            SubTab.Active = true

            StopPageTween()
            StopRowTweens()

            Items.Page:CancelFade()
            Items.Page:HardRestore()
            Items.Page.Instance.Parent = Window.Items.Content.Instance
            Items.Page.Instance.Position = UDim2.fromOffset(0, 0)
            Items.Page.Instance.Visible = true

            Library:SafeCall(SubTab.PageIntro)

            if #SubTab.Sections == 0 then return end

            LayoutPage()

            local Order = 0

            for _, Column in SubTab.Columns do
                for _, Section in Column.Sections do
                    Order += 1
                    PrimeParts(Section)

                    for _, Data in Section.Rows do
                        Data.Frame:CancelFade()
                        Data.Frame.Instance.Visible = false
                    end

                    local Slot = Order

                    task.delay((Slot - 1) * SectionStep, function()
                        if SubTab.ShowToken ~= Token or not SubTab.Active then return end

                        RevealParts(Section)

                        for RowIndex, Data in Section.Rows do
                            if Data.Visible == false then continue end

                            task.delay(RowIndex * RowStep, function()
                                local Home = UDim2.fromOffset(0, Data.Y)

                                Data.Frame.Instance.Visible = true

                                if SubTab.ShowToken ~= Token or not SubTab.Active then
                                    Data.Frame.Instance.Position = Home
                                    return
                                end

                                Data.Frame.Instance.Position = UDim2.fromOffset(RowSlide, Data.Y)
                                Data.Move = Library:Tween({ Position = Home }, RowIn, Data.Frame.Instance)
                                Data.Frame:FadeDescendants(true)
                            end)
                        end
                    end)
                end
            end
        end

        function SubTab:Hide(OnDone)
            SubTab.Active = false
            SubTab.ShowToken += 1

            Library:SafeCall(SubTab.PageOutro)

            StopRowTweens()

            ForEachRow(function(Data)
                Data.Frame:CancelFade()
            end)

            StopPageTween()

            PageTween = Library:Tween({
                Position = UDim2.fromOffset(-PageSlide, 0)
            }, Sink, Items.Page.Instance)

            Items.Page:FadeDescendants(false, function()
                if not SubTab.Active then
                    StopPageTween()
                    Items.Page:ResetFade()
                    CleanPage()

                    Items.Page.Instance.Visible = false
                    Items.Page.Instance.Parent = Library.UnusedHolder.Instance
                end

                if OnDone then Library:SafeCall(OnDone) end
            end)
        end

        function SubTab:SnapVisible()
            SubTab.ShowToken += 1
            SubTab.Active = true

            StopPageTween()
            StopRowTweens()

            Items.Page:CancelFade()
            CleanPage()

            Items.Page.Instance.Visible = true
        end

        Items.Hit:Connect("MouseButton1Down", function()
            if Tab.Current == SubTab then return end

            Library:CloseAllPopups()

            if Tab.Current then
                Tab.Current:SetVisual(false)
                Tab.Current:Hide()
            end

            Tab.Current = SubTab
            SubTab:SetVisual(true)
            SubTab:Show()

            Window:LayoutSubBar()
        end)

        table.insert(Tab.Subs, SubTab)

        if #Tab.Subs == 1 then
            Tab.Current = SubTab
            SubTab:SetVisual(true, true)
        end

        if Window.Current == Tab then
            Window:LayoutSubBar()
        end

        return setmetatable(SubTab, Library)
    end

    Library.Section = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Section(Params)
        end

        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Section(Params)
        end

        local SubTab = Self
        local Side = Params.Side or 1

        if Side == "Right" then Side = 2 end
        if Side == "Left" then Side = 1 end

        local Column = (SubTab.Columns and (SubTab.Columns[Side] or SubTab.Columns[1]))
        if not Column then
            Column = { Width = 236, Scroll = SubTab.Items and SubTab.Items.Page or Library.Holder }
        end

        local Section = {
            Name = Params.Name or "Section",
            SubTab = SubTab,
            Column = Column,
            Width = Column.Width,
            Y = 0,
            Height = 0,
            Rows = { },
            Dirty = false,
            Items = { }
        }

        local Items = { }

        Items.Holder = MakeFrame({
            Parent = Column.Scroll.Instance,
            Size = UDim2.fromOffset(Column.Width, 40),
            Z = 3
        })

        local HeaderTextW = math.ceil(MeasureText(Section.Name, 15, 240, UiFont).X)
        local HeaderW = HeaderTextW + 26

        Items.Header = MakeFrame({
            Parent = Items.Holder.Instance,
            Pos = UDim2.fromOffset(0, 1),
            Size = UDim2.fromOffset(HeaderW, 25),
            Color = "Section",
            Round = 10,
            Z = 3
        })

        Items.HeaderFill = MakeFrame({
            Parent = Items.Header.Instance,
            Pos = UDim2.fromOffset(0, 15),
            Size = UDim2.fromOffset(HeaderW, 10),
            Color = "Section",
            Z = 3
        })

        Items.Label = MakeText({
            Parent = Items.Header.Instance,
            Text = Section.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 13, 0.5, 1),
            Size = UDim2.fromOffset(HeaderTextW + 6, 20),
            Color = "Text",
            Z = 4
        })

        local function SyncHeader()
            local Bounds = math.ceil(Items.Label.Instance.TextBounds.X)
            if Bounds <= 0 then return end

            HeaderTextW = Bounds
            HeaderW = Bounds + 26

            Items.Label.Instance.Size = UDim2.fromOffset(Bounds + 6, 20)
            Items.Header.Instance.Size = UDim2.fromOffset(HeaderW, 25)
            Items.HeaderFill.Instance.Size = UDim2.fromOffset(HeaderW, 10)
        end

        Library:Connect(Items.Label.Instance:GetPropertyChangedSignal("TextBounds"), SyncHeader)
        task.defer(SyncHeader)

        Items.Frame = MakeFrame({
            Parent = Items.Holder.Instance,
            Pos = UDim2.fromOffset(0, 26),
            Size = UDim2.fromOffset(Column.Width, 14),
            Color = "Section",
            Round = 10,
            Z = 3
        })

        Items.BodyFill = MakeFrame({
            Parent = Items.Frame.Instance,
            Pos = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(10, 10),
            Color = "Section",
            Z = 3
        })

        Section.Items = Items

        function Section:Reflow()
            local Y = 8
            local Visible = 0

            for _, Data in Section.Rows do
                local Shown = Data.Visible ~= false

                Data.Frame.Instance.Visible = Shown

                if not Shown then continue end

                Data.Y = Y
                Data.Frame.Instance.Position = UDim2.fromOffset(0, Y)
                Y += Data.Height
                Visible += 1
            end

            local FrameHeight = Visible > 0 and (Y + 8) or 0

            Items.Frame.Instance.Size = UDim2.fromOffset(Section.Width, FrameHeight)
            Items.Holder.Instance.Visible = Visible > 0
            Section.Height = Visible > 0 and (26 + FrameHeight) or 0
            Items.Holder.Instance.Size = UDim2.fromOffset(Section.Width, math.max(Section.Height, 1))

            Column:Reflow()
        end

        function Section:AddRow(Height, SearchName)
            local Frame = MakeFrame({
                Parent = Items.Frame.Instance,
                Size = UDim2.fromOffset(Section.Width, Height),
                Z = 4
            })

            local Data = {
                Frame = Frame,
                Height = Height,
                Y = 0,
                Visible = true,
                Name = SearchName or Section.Name,
                Section = Section,
                Window = SubTab.Window
            }

            table.insert(Section.Rows, Data)
            table.insert(Library.Searchables, Data)

            Section:Reflow()
            return Frame, Data
        end

        table.insert(SubTab.Sections, Section)
        table.insert(Column.Sections, Section)
        Section:Reflow()

        return setmetatable(Section, Library)
    end

    Library.Toggle = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Toggle(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Toggle(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Toggle(Params)
        end

        local Section = Self

        local Toggle = {
            Name = Params.Name or "Toggle",
            Default = Params.Default or false,
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Value = false,
            Visual = nil,
            Token = 0,
            Items = { }
        }

        local Row = Section:AddRow(32, Toggle.Name)
        local Items = { Row = Row }

        Items.Label = MakeText({
            Parent = Row.Instance,
            Text = Toggle.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 15, 0.5, 0),
            Size = UDim2.fromOffset(Section.Width - 80, 20),
            Color = "DimText",
            Truncate = true,
            Z = 5
        })

        Items.Box = MakeFrame({
            Parent = Row.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -15, 0.5, 0),
            Size = UDim2.fromOffset(35, 21),
            Color = "Element",
            Round = 10,
            Clip = true,
            Z = 5
        })

        Items.Circle = MakeFrame({
            Parent = Items.Box.Instance,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 4, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            Color = "DimText",
            Round = 20,
            Z = 6
        })

        MakeAccentShadow(
            Items.Circle.Instance,
            UDim2.fromOffset(3, 3),
            UDim.new(0, 5),
            0.7
        )

        Items.Hit = MakeButton({
            Parent = Row.Instance,
            Size = UDim2.new(1, 0, 1, 0),
            Z = 8
        })

        Toggle.Items = Items

        local Pad = 4
        local InnerW = 35 - Pad * 2
        local LeftPos = UDim2.new(0, Pad, 0.5, 0)
        local RightPos = UDim2.new(1, -Pad, 0.5, 0)
        local Small = UDim2.fromOffset(13, 13)

        function Toggle.SetVisual(State, Instant)
            State = State and true or false
            if Toggle.Visual == State then return end
            Toggle.Visual = State

            Toggle.Token += 1
            local Token = Toggle.Token

            if Toggle.GrowTween then
                pcall(function()
                    Toggle.GrowTween:Cancel()
                end)
            end

            if Toggle.SnapTween then
                pcall(function()
                    Toggle.SnapTween:Cancel()
                end)
            end

            Toggle.GrowTween = nil
            Toggle.SnapTween = nil

            local BoxColor = State and "Light" or "Element"
            local CircleKey = State and "Accent" or "DimText"
            local CircleColor = Library.Theme[CircleKey]
            local LabelColor = State and "Text" or "DimText"

            local StartAnchor = State and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
            local StartPos = State and LeftPos or RightPos
            local EndAnchor = State and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
            local EndPos = State and RightPos or LeftPos

            Items.Box:ChangeItemTheme({ BackgroundColor3 = BoxColor })
            Items.Label:ChangeItemTheme({ TextColor3 = LabelColor })
            Items.Circle:ChangeItemTheme({ BackgroundColor3 = CircleKey })

            if Instant then
                Items.Box.Instance.BackgroundColor3 = Library.Theme[BoxColor]
                Items.Label.Instance.TextColor3 = Library.Theme[LabelColor]
                Items.Circle.Instance.BackgroundColor3 = CircleColor
                Items.Circle.Instance.Size = Small
                Items.Circle.Instance.AnchorPoint = EndAnchor
                Items.Circle.Instance.Position = EndPos
                return
            end

            local Grow = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local Snap = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local Fade = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            Library:Tween({ BackgroundColor3 = Library.Theme[BoxColor] }, Fade, Items.Box.Instance)
            Library:Tween({ TextColor3 = Library.Theme[LabelColor] }, Fade, Items.Label.Instance)
            Library:Tween({ BackgroundColor3 = CircleColor }, Fade, Items.Circle.Instance)

            Items.Circle.Instance.AnchorPoint = StartAnchor
            Items.Circle.Instance.Position = StartPos
            Toggle.GrowTween = Library:Tween({ Size = UDim2.fromOffset(InnerW, 13) }, Grow, Items.Circle.Instance)

            task.delay(0.08, function()
                if Toggle.Token ~= Token then return end

                Items.Circle.Instance.AnchorPoint = EndAnchor
                Items.Circle.Instance.Position = EndPos
                Toggle.SnapTween = Library:Tween({ Size = Small }, Snap, Items.Circle.Instance)
            end)

            task.delay(0.3, function()
                if Toggle.Token ~= Token then return end
                if Items.Circle.Instance.Size == Small then return end

                Items.Circle.Instance.AnchorPoint = EndAnchor
                Items.Circle.Instance.Position = EndPos
                Items.Circle.Instance.Size = Small
            end)
        end

        function Toggle:Set(Bool, FromUser)
            Toggle.Value = Bool and true or false

            if Toggle.Flag then
                Library.Flags[Toggle.Flag] = Toggle.Value
            end

            Toggle.SetVisual(Toggle.Value, false)
            Library:SafeCall(Toggle.Callback, Toggle.Value)

            if Library.UpdateKeybindMenu then
                Library:UpdateKeybindMenu()
            end

            if FromUser and Toggle.Notify == true then
                Library:Notification({
                    Title = Toggle.Name,
                    Description = Toggle.Value and "Enabled" or "Disabled",
                    Icon = Toggle.Value and "check" or "x",
                    Duration = 2.5
                })
            end
        end

        function Toggle:Get()
            return Toggle.Value
        end

        Items.Hit:Connect("MouseButton1Down", function()
            Toggle:Set(not Toggle.Value, true)
        end)

        Toggle.SlotX = -58

        local function TakeSlot(Width)
            local X = Toggle.SlotX
            Toggle.SlotX -= Width + 8
            Items.Label.Instance.Size = UDim2.fromOffset(Section.Width + Toggle.SlotX - 15, 20)
            return X
        end

        local function SlotIcon(X, Icon)
            local Glyph = MakeImage({
                Parent = Row.Instance,
                Icon = Icon,
                Anchor = Vector2.new(1, 0.5),
                Pos = UDim2.new(1, X, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Color = "DimText",
                Z = 6
            })

            local Hit = MakeButton({
                Parent = Row.Instance,
                Anchor = Vector2.new(1, 0.5),
                Pos = UDim2.new(1, X + 2, 0.5, 0),
                Size = UDim2.fromOffset(22, 22),
                Z = 9
            })

            Hit:OnHover(function()
                Glyph:Tween({ ImageColor3 = Library.Theme.Text })
            end, function()
                Glyph:Tween({ ImageColor3 = Library.Theme.DimText })
            end)

            return Glyph, Hit
        end

        local function SidePlace(Anchor)
            return function(Off)
                local PScale = Library:GetScreenScale()
                local Right = Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X
                local PX = Right / PScale + 8 + (Off or 0)
                local PY = (Anchor.AbsolutePosition.Y + GuiInset) / PScale - 4

                return UDim2.fromOffset(PX, PY)
            end
        end

        function Toggle:Colorpicker(CParams)
            CParams = CParams or { }

            local Picker = {
                Color = CParams.Default or Library.Theme.Accent,
                Transparency = CParams.Transparency or 0
            }

            local X = TakeSlot(22)
            local Swatch = MakeSwatch(Row.Instance, X, Picker.Color, 6)

            local Inner = MakeColorPopup(function()
                return Swatch.Halo.Instance
            end, CParams.Name or Toggle.Name, Picker.Color, Picker.Transparency, function(Color, Alpha)
                Picker.Color = Color
                Picker.Transparency = Alpha
                Swatch:SetColor(Color, Alpha)

                if CParams.Flag then
                    Library.Flags[CParams.Flag] = {
                        __color = Color:ToHex(),
                        __alpha = Alpha
                    }
                end

                Library:SafeCall(CParams.Callback, Color, Alpha)
            end)

            Swatch.Hit:Connect("MouseButton1Down", function()
                Inner:SetOpen(not Inner.IsOpen)
            end)

            if CParams.Flag then
                Library.SetFlags[CParams.Flag] = function(Color, Alpha)
                    Inner:Set(Color, Alpha)
                end
            end

            function Picker:Set(Color, Alpha)
                Inner:Set(Color, Alpha)
            end

            Picker.Picker = Inner
            return Picker
        end

        function Toggle:Keybind(KParams)
            KParams = KParams or { }

            local Keybind = {
                Key = KParams.Default,
                Mode = KParams.Mode or "Toggle",
                Flag = KParams.Flag,
                Picking = false,
                IsOpen = false,
                Debounce = false
            }

            if Library.RegisterKeybind then
                Library:RegisterKeybind({
                    Name = Toggle.Name or "Toggle",
                    GetKey = function() return Keybind.Key end,
                    GetActive = function() return Toggle.Value == true end
                })
            end

            local X = TakeSlot(20)
            local BindIcon, BindHit = SlotIcon(X, "command")

            local PanelW = 160

            local Panel = MakeFrame({
                Parent = Library.UnusedHolder.Instance,
                Size = UDim2.fromOffset(PanelW, 128),
                Color = "Section",
                Round = 8,
                Z = 40
            })

            Panel.Instance.Visible = false

            MakeText({
                Parent = Panel.Instance,
                Text = "Keybind",
                TextSize = 12,
                Pos = UDim2.fromOffset(11, 7),
                Size = UDim2.fromOffset(PanelW - 22, 14),
                Color = "DimText",
                Z = 41
            })

            local KeyBox = MakeFrame({
                Parent = Panel.Instance,
                Pos = UDim2.fromOffset(8, 26),
                Size = UDim2.fromOffset(PanelW - 16, 26),
                Color = "Light",
                Round = 5,
                Z = 41
            })

            local PanelKey = MakeText({
                Parent = KeyBox.Instance,
                Text = "None",
                TextSize = 13,
                Size = UDim2.new(1, 0, 1, 0),
                Color = "Text",
                Align = Enum.TextXAlignment.Center,
                Truncate = true,
                Z = 42
            })

            local KeyHit = MakeButton({
                Parent = KeyBox.Instance,
                Z = 43
            })

            local ModeRows = { }

            local function ModeRow(Y, ModeName)
                local Built = MakeAccentRow({
                    Parent = Panel.Instance,
                    Pos = UDim2.fromOffset(8, Y),
                    Size = UDim2.fromOffset(PanelW - 16, 28),
                    Color = "Element",
                    Text = ModeName,
                    TextSize = 13,
                    LabelSize = UDim2.new(1, -18, 1, 0),
                    LineX = 6,
                    LineH = 14,
                    TextX = 10,
                    TextActiveX = 17,
                    SnapShadow = true,
                    Z = 41
                })

                Built.Hit:Connect("MouseButton1Down", function()
                    Keybind:SetMode(ModeName)
                end)

                table.insert(ModeRows, {
                    Name = ModeName,
                    SetActive = Built.SetActive
                })
            end

            ModeRow(60, "Toggle")
            ModeRow(92, "Hold")

            local function SaveFlag()
                if not Keybind.Flag then return end

                Library.Flags[Keybind.Flag] = {
                    Key = Keybind.Key and tostring(Keybind.Key) or "None",
                    Mode = Keybind.Mode
                }
            end

            function Keybind:SetMode(Mode, Instant)
                Keybind.Mode = Mode

                for _, Data in ModeRows do
                    Data.SetActive(Data.Name == Mode, Instant)
                end

                SaveFlag()
            end

            function Keybind:Set(Key)
                Keybind.Key = Key
                PanelKey.Instance.Text = KeyName(Key)
                Keybind.Picking = false

                SaveFlag()
            end

            AttachPopup({
                Popup = Keybind,
                Frame = Panel,
                Level = 40,
                GetAnchor = function()
                    return BindHit.Instance
                end,
                Place = SidePlace(BindIcon.Instance),
                From = -6,
                To = 2,
                Retreat = RetreatLeft
            })

            BindHit:Connect("MouseButton1Down", function()
                Keybind:SetOpen(not Keybind.IsOpen)
            end)

            KeyHit:Connect("MouseButton1Click", function()
                CaptureKey(Keybind, PanelKey.Instance, function(Key)
                    Keybind:Set(Key)
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input, Processed)
                if Processed or Keybind.Picking or not Keybind.Key then return end
                if not KeyMatches(Input, Keybind.Key) then return end

                if Keybind.Mode == "Hold" then
                    Toggle:Set(true, true)
                else
                    Toggle:Set(not Toggle.Value, true)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Mode ~= "Hold" or not Keybind.Key then return end
                if not KeyMatches(Input, Keybind.Key) then return end

                Toggle:Set(false, true)
            end)

            if Keybind.Flag then
                Library.SetFlags[Keybind.Flag] = function(Value)
                    if type(Value) == "table" then
                        if Value.Mode then Keybind:SetMode(Value.Mode, true) end
                        Value = Value.Key
                    end

                    Keybind:Set(ParseKey(Value))
                end
            end

            Keybind:SetMode(Keybind.Mode, true)
            Keybind:Set(Keybind.Key)

            return Keybind
        end

        function Toggle:Extra(EParams)
            EParams = EParams or { }

            if Toggle.ExtraPanel then
                return Toggle.ExtraPanel
            end

            local Extra = {
                IsOpen = false,
                Debounce = false,
                NextY = 30,
                Width = EParams.Width or 220
            }

            local X = TakeSlot(20)
            local ExtraIcon, ExtraHit = SlotIcon(X, "settings-2")

            local Frame = MakeFrame({
                Parent = Library.UnusedHolder.Instance,
                Size = UDim2.fromOffset(Extra.Width, 38),
                Color = "Section",
                Round = 8,
                Z = 2
            })

            Frame.Instance.Visible = false

            MakeText({
                Parent = Frame.Instance,
                Text = Toggle.Name,
                TextSize = 12,
                Pos = UDim2.fromOffset(12, 8),
                Size = UDim2.fromOffset(Extra.Width - 24, 14),
                Color = "DimText",
                Truncate = true,
                Z = 3
            })

            local ChildDim = MakeFrame({
                Parent = Frame.Instance,
                Size = UDim2.new(1, 0, 1, 0),
                Raw = Color3.new(0, 0, 0),
                Alpha = 1,
                Round = 8,
                Z = 30
            })

            ChildDim.Instance.Visible = false
            Library:StampResting(ChildDim.Instance, "BackgroundTransparency", 1)

            local DimShown = false

            function Extra.SetChildDim(Bool)
                if DimShown == Bool then return end
                DimShown = Bool

                local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local Target = Bool and 0.5 or 1

                Library:StampResting(ChildDim.Instance, "BackgroundTransparency", Target)

                if Bool then
                    ChildDim.Instance.Visible = true
                end

                Library:Tween({ BackgroundTransparency = Target }, Info, ChildDim.Instance)

                if Bool then return end

                task.delay(0.24, function()
                    if not DimShown then ChildDim.Instance.Visible = false end
                end)
            end

            function Extra:AddRow(Height, SearchName)
                local RowFrame = MakeFrame({
                    Parent = Frame.Instance,
                    Pos = UDim2.fromOffset(0, Extra.NextY),
                    Size = UDim2.fromOffset(Extra.Width, Height),
                    Z = 3
                })

                local Data = {
                    Frame = RowFrame,
                    Height = Height,
                    Y = Extra.NextY,
                    Visible = true,
                    Name = SearchName or Toggle.Name
                }

                Extra.NextY += Height
                Frame.Instance.Size = UDim2.fromOffset(Extra.Width, Extra.NextY + 8)

                return RowFrame, Data
            end

            local function HasOpenChild()
                for _, Value in Library.OpenFrames do
                    if Value.Host == Extra then return true end
                end

                return false
            end

            AttachPopup({
                Popup = Extra,
                Frame = Frame,
                Level = 2,
                GetAnchor = function()
                    return ExtraHit.Instance
                end,
                Place = SidePlace(ExtraIcon.Instance),
                From = -6,
                To = 2,
                Retreat = RetreatLeft,
                KeepOpen = function(Value)
                    return Value == Extra or Value.Host == Extra
                end,
                HoldOpen = HasOpenChild,
                OnClose = function()
                    for _, Value in Library.OpenFrames do
                        if Value.Host == Extra then Value:SetOpen(false) end
                    end
                end
            })

            ExtraHit:Connect("MouseButton1Down", function()
                Extra:SetOpen(not Extra.IsOpen)
            end)

            setmetatable(Extra, {
                __index = function(_, Key)
                    local Builder = Library[Key]
                    if type(Builder) ~= "function" then return nil end

                    return function(SelfArg, BuildParams)
                        local Element = Builder(SelfArg, BuildParams)

                        if type(Element) == "table" then
                            if rawget(Element, "Popup") then Element.Popup.Host = Extra end
                            if rawget(Element, "Picker") then Element.Picker.Host = Extra end
                        end

                        return Element
                    end
                end
            })

            Toggle.ExtraPanel = Extra
            return Extra
        end

        Toggle.Value = Toggle.Default

        if Toggle.Flag then
            Library.Flags[Toggle.Flag] = Toggle.Value

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end
        end

        Toggle.SetVisual(Toggle.Value, true)
        Library:SafeCall(Toggle.Callback, Toggle.Value)

        return setmetatable(Toggle, Library)
    end

    local SlideInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local KnobColor = Color3.fromRGB(197, 197, 197)

    local function MakeKnob(Parent)
        local Knob = MakeFrame({
            Parent = Parent,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            Raw = KnobColor,
            Round = 20,
            Z = 7
        })

        MakeShadow(Knob.Instance, KnobColor, UDim2.fromOffset(0, 0), UDim.new(0, 5), 0.5)
        return Knob
    end

    local function BuildSliderRow(Section, Name, SearchName)
        local Row = Section:AddRow(44, SearchName or Name)
        local Width = Section.Width
        local TrackW = Width - 30
        local Items = { Row = Row }

        Items.Label = MakeText({
            Parent = Row.Instance,
            Text = Name,
            TextSize = 15,
            Pos = UDim2.fromOffset(15, 3),
            Size = UDim2.fromOffset(Width - 120, 20),
            Color = "Text",
            Truncate = true,
            Z = 5
        })

        Items.Value = MakeText({
            Parent = Row.Instance,
            Text = "",
            TextSize = 15,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, -15, 0, 3),
            Size = UDim2.fromOffset(100, 20),
            Color = "DimText",
            Align = Enum.TextXAlignment.Right,
            Truncate = true,
            Z = 5
        })

        Items.Track = MakeFrame({
            Parent = Row.Instance,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 15, 0, 32),
            Size = UDim2.fromOffset(TrackW, 10),
            Color = "Element",
            Round = 20,
            Z = 5
        })

        Items.Fill = MakeFrame({
            Parent = Items.Track.Instance,
            Size = UDim2.fromOffset(0, 10),
            Raw = Color3.new(1, 1, 1),
            Round = 20,
            Z = 6
        })

        Library:RegisterGradient(Library:Create("UIGradient", {
            Parent = Items.Fill.Instance
        }).Instance)

        Items.Hit = MakeButton({
            Parent = Row.Instance,
            Pos = UDim2.fromOffset(9, 22),
            Size = UDim2.fromOffset(TrackW + 12, 22),
            Z = 8
        })

        Items.TrackWidth = TrackW
        return Items
    end

    Library.Slider = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Slider(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Slider(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Slider(Params)
        end

        local Section = Self

        local Slider = {
            Name = Params.Name or "Slider",
            Min = Params.Min or 0,
            Max = Params.Max or 100,
            Default = Params.Default or 0,
            Decimals = Params.Decimals or 1,
            Suffix = Params.Suffix or "",
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Value = 0,
            Sliding = false
        }

        local Items = BuildSliderRow(Section, Slider.Name)
        local TrackW = Items.TrackWidth

        Slider.Items = Items
        Items.Knob = MakeKnob(Items.Track.Instance)

        function Slider:Set(Value, Instant)
            local Clamped = math.clamp(Value, Slider.Min, Slider.Max)
            Slider.Value = Library:Round(Clamped, Slider.Decimals)

            if Slider.Flag then
                Library.Flags[Slider.Flag] = Slider.Value
            end

            local Span = Slider.Max - Slider.Min
            local Fraction = Span == 0 and 0 or (Slider.Value - Slider.Min) / Span
            local Info = Instant and TweenInfo.new(0) or SlideInfo

            Library:Tween({ Size = UDim2.fromOffset(Fraction * TrackW, 10) }, Info, Items.Fill.Instance)
            Library:Tween({ Position = UDim2.new(Fraction, 0, 0.5, 0) }, Info, Items.Knob.Instance)

            Items.Value.Instance.Text = tostring(Slider.Value) .. Slider.Suffix
            Library:SafeCall(Slider.Callback, Slider.Value)
        end

        function Slider:Get()
            return Slider.Value
        end

        local function Calculate(Input)
            local Fraction = AxisFraction(Input, Items.Track.Instance, "X")
            return Slider.Min + (Slider.Max - Slider.Min) * Fraction
        end

        local function Apply(Input)
            Slider:Set(Calculate(Input))
        end

        AttachDrag(Items.Hit, {
            OnGrab = function(Input)
                Slider.Sliding = true
                Apply(Input)
            end,
            OnMove = Apply,
            OnRelease = function()
                Slider.Sliding = false
            end
        })

        Slider:Set(Slider.Default, true)

        if Slider.Flag then
            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end
        end

        return setmetatable(Slider, Library)
    end

    Library.RangeSlider = function(Self, Params)
        Params = Params or { }

        local Section = Self

        local Slider = {
            Name = Params.Name or "Range",
            Min = Params.Min or 0,
            Max = Params.Max or 100,
            Default = Params.Default,
            Decimals = Params.Decimals or 1,
            Suffix = Params.Suffix or "",
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Value = { 0, 0 },
            Grabbing = nil
        }

        Slider.MinGap = Params.MinGap or Slider.Decimals
        Slider.Default = Slider.Default or { Slider.Min, Slider.Max }

        local Items = BuildSliderRow(Section, Slider.Name)
        local TrackW = Items.TrackWidth

        Slider.Items = Items
        Items.MinKnob = MakeKnob(Items.Track.Instance)
        Items.MaxKnob = MakeKnob(Items.Track.Instance)

        local function Normalize(Value)
            local Span = Slider.Max - Slider.Min
            return Span == 0 and 0 or (Value - Slider.Min) / Span
        end

        function Slider:Set(MinValue, MaxValue, Instant)
            if type(MinValue) == "table" then
                MinValue, MaxValue = MinValue[1], MinValue[2]
            end

            MinValue = math.clamp(MinValue or Slider.Min, Slider.Min, Slider.Max)
            MaxValue = math.clamp(MaxValue or Slider.Max, Slider.Min, Slider.Max)

            MinValue = Library:Round(MinValue, Slider.Decimals)
            MaxValue = Library:Round(MaxValue, Slider.Decimals)

            if MinValue > MaxValue then
                MinValue, MaxValue = MaxValue, MinValue
            end

            Slider.Value = { MinValue, MaxValue }

            if Slider.Flag then
                Library.Flags[Slider.Flag] = Slider.Value
            end

            local MinF = Normalize(MinValue)
            local MaxF = Normalize(MaxValue)
            local Info = Instant and TweenInfo.new(0) or SlideInfo

            Library:Tween({
                Position = UDim2.fromOffset(MinF * TrackW, 0),
                Size = UDim2.fromOffset((MaxF - MinF) * TrackW, 10)
            }, Info, Items.Fill.Instance)

            Library:Tween({ Position = UDim2.new(MinF, 0, 0.5, 0) }, Info, Items.MinKnob.Instance)
            Library:Tween({ Position = UDim2.new(MaxF, 0, 0.5, 0) }, Info, Items.MaxKnob.Instance)

            local Text = tostring(MinValue) .. Slider.Suffix
            Text = Text .. " - " .. tostring(MaxValue) .. Slider.Suffix

            Items.Value.Instance.Text = Text
            Library:SafeCall(Slider.Callback, Slider.Value)
        end

        function Slider:Get()
            return Slider.Value
        end

        local function Apply(Input)
            local Point = AxisFraction(Input, Items.Track.Instance, "X")
            local Value = Slider.Min + (Slider.Max - Slider.Min) * Point

            if Slider.Grabbing == "Min" then
                Slider:Set(math.min(Value, Slider.Value[2] - Slider.MinGap), Slider.Value[2])
            else
                Slider:Set(Slider.Value[1], math.max(Value, Slider.Value[1] + Slider.MinGap))
            end
        end

        AttachDrag(Items.Hit, {
            OnGrab = function(Input)
                local Point = AxisFraction(Input, Items.Track.Instance, "X")
                local MinF = Normalize(Slider.Value[1])
                local MaxF = Normalize(Slider.Value[2])

                Slider.Grabbing = math.abs(Point - MinF) <= math.abs(Point - MaxF) and "Min" or "Max"
                Apply(Input)
            end,
            OnMove = Apply,
            OnRelease = function()
                Slider.Grabbing = nil
            end
        })

        Slider:Set(Slider.Default[1], Slider.Default[2], true)

        if Slider.Flag then
            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end
        end

        return setmetatable(Slider, Library)
    end

    local function MakeFieldRow(Section, Name, SearchName)
        local Row = Section:AddRow(54, SearchName or Name)
        local Items = { Row = Row }

        Items.Label = MakeText({
            Parent = Row.Instance,
            Text = Name,
            TextSize = 15,
            Pos = UDim2.fromOffset(15, 4),
            Size = UDim2.fromOffset(Section.Width - 30, 18),
            Color = "DimText",
            Truncate = true,
            Z = 5
        })

        Items.Box = MakeFrame({
            Parent = Row.Instance,
            Pos = UDim2.fromOffset(15, 24),
            Size = UDim2.fromOffset(Section.Width - 30, 30),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 5
        })

        return Items
    end

    local function HoverSwap(Frame)
        Frame:OnHover(function()
            Frame:Tween({ BackgroundColor3 = Library.Theme.Hover })
        end, function()
            Frame:Tween({ BackgroundColor3 = Library.Theme.Element })
        end)
    end

    Library.Dropdown = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Dropdown(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Dropdown(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Dropdown(Params)
        end

        local Section = Self

        local Dropdown = {
            Name = Params.Name or "Dropdown",
            Options = Params.Items or Params.Options or { },
            Default = Params.Default,
            Multi = Params.Multi or false,
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Value = nil,
            Items = { }
        }

        if Dropdown.Multi then
            Dropdown.Value = { }
        end

        local Items = MakeFieldRow(Section, Dropdown.Name)

        Items.Selected = MakeText({
            Parent = Items.Box.Instance,
            Text = "None",
            TextSize = 15,
            Pos = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -34, 1, 0),
            Color = "Text",
            Truncate = true,
            Z = 6
        })

        Items.Arrow = MakeImage({
            Parent = Items.Box.Instance,
            Icon = "chevron-down",
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Color = "DimText",
            Z = 6
        })

        Items.Hit = MakeButton({
            Parent = Items.Box.Instance,
            Z = 7
        })

        Dropdown.Items = Items

        local Popup = MakeOptionPopup(function()
            return Items.Box.Instance
        end)

        Popup.OnState = function(Open)
            Items.Arrow:Tween({ Rotation = Open and 180 or 0 })
        end

        Dropdown.Popup = Popup

        local function Report()
            if Dropdown.Flag then
                Library.Flags[Dropdown.Flag] = Dropdown.Value
            end

            if Dropdown.Multi then
                Items.Selected.Instance.Text = #Dropdown.Value > 0
                and table.concat(Dropdown.Value, ", ")
                or "None"
            else
                Items.Selected.Instance.Text = Dropdown.Value ~= nil
                and tostring(Dropdown.Value)
                or "None"
            end

            Library:SafeCall(Dropdown.Callback, Dropdown.Value)
        end

        Popup.OnPick = function(Data)
            if Dropdown.Multi then
                local Index = table.find(Dropdown.Value, Data.Name)

                if Index then
                    table.remove(Dropdown.Value, Index)
                    Data:Set(false)
                else
                    table.insert(Dropdown.Value, Data.Name)
                    Data:Set(true)
                end
            else
                Dropdown.Value = Data.Name

                for _, Other in Popup.Order do
                    Other:Set(Other == Data)
                end
            end

            Report()
        end

        function Dropdown:Refresh(List)
            Popup:Clear()
            Dropdown.Options = List

            for _, Option in List do
                Popup:AddRow(tostring(Option))
            end
        end

        function Dropdown:Set(Value)
            if Dropdown.Multi then
                if type(Value) ~= "table" then return end

                Dropdown.Value = Value

                for _, Data in Popup.Order do
                    Data:Set(table.find(Value, Data.Name) ~= nil, true)
                end
            else
                local Found = false

                for _, Data in Popup.Order do
                    if Data.Name == Value then Found = true end
                end

                if not Found then return end

                Dropdown.Value = Value

                for _, Data in Popup.Order do
                    Data:Set(Data.Name == Value, true)
                end
            end

            Report()
        end

        function Dropdown:Get()
            return Dropdown.Value
        end

        Items.Hit:Connect("MouseButton1Down", function()
            Popup:SetOpen(not Popup.IsOpen)
        end)

        HoverSwap(Items.Box)

        for _, Option in Dropdown.Options do
            Popup:AddRow(tostring(Option))
        end

        if Dropdown.Default ~= nil then
            Dropdown:Set(Dropdown.Default)
        end

        if Dropdown.Flag then
            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end
        end

        return setmetatable(Dropdown, Library)
    end

    Library.Button = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Button(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Button(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Button(Params)
        end

        local Section = Self

        local Button = {
            Name = Params.Name or "Button",
            Callback = Params.Callback or function() end,
            Notification = Params.Notification,
            Items = { }
        }

        local Row = Section:AddRow(36, Button.Name)
        local Items = { Row = Row }

        Items.Frame = MakeFrame({
            Parent = Row.Instance,
            Pos = UDim2.fromOffset(15, 3),
            Size = UDim2.fromOffset(Section.Width - 30, 30),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 5
        })

        Items.Sweep = MakeSweep(Items.Frame.Instance, 6)

        Items.Label = MakeText({
            Parent = Items.Frame.Instance,
            Text = Button.Name,
            TextSize = 15,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "Text",
            Align = Enum.TextXAlignment.Center,
            Truncate = true,
            Z = 7
        })

        Items.Hit = MakeButton({
            Parent = Items.Frame.Instance,
            Z = 8
        })

        Button.Items = Items
        HoverSwap(Items.Frame)

        function Button:Press()
            PlaySweep(Items.Sweep.Instance)
            Library:SafeCall(Button.Callback)
            if Button.Notification then
                if type(Button.Notification) == "function" then
                    local Res = Button.Notification()
                    if Res then Library:Notification(Res) end
                elseif type(Button.Notification) == "table" then
                    Library:Notification(Button.Notification)
                elseif type(Button.Notification) == "string" then
                    Library:Notification({ Name = Button.Name, Description = Button.Notification })
                end
            end
        end

        function Button:SetNotification(Notification)
            Button.Notification = Notification
            return Button
        end

        function Button:SetText(Text)
            Items.Label.Instance.Text = tostring(Text)
        end

        Items.Hit:Connect("MouseButton1Down", function()
            Button:Press()
        end)

        return setmetatable(Button, Library)
    end

    Library.Textbox = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Textbox(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Textbox(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Textbox(Params)
        end

        local Section = Self

        local Textbox = {
            Name = Params.Name or "Textbox",
            Default = Params.Default or "",
            Placeholder = Params.Placeholder or "...",
            Finished = Params.Finished or false,
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Value = "",
            Items = { }
        }

        local Items = MakeFieldRow(Section, Textbox.Name)

        Items.Input = MakeInput({
            Parent = Items.Box.Instance,
            Placeholder = Textbox.Placeholder,
            Pos = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -22, 1, 0),
            TextSize = 15,
            Z = 6
        })

        Textbox.Items = Items

        function Textbox:Set(Value)
            Textbox.Value = tostring(Value)
            Items.Input.Instance.Text = Textbox.Value

            if Textbox.Flag then
                Library.Flags[Textbox.Flag] = Textbox.Value
            end

            Library:SafeCall(Textbox.Callback, Textbox.Value)
        end

        function Textbox:Get()
            return Textbox.Value
        end

        if Textbox.Finished then
            Items.Input:Connect("FocusLost", function(Enter)
                if Enter then
                    Textbox:Set(Items.Input.Instance.Text)
                end
            end)
        else
            Library:Connect(Items.Input.Instance:GetPropertyChangedSignal("Text"), function()
                Textbox:Set(Items.Input.Instance.Text)
            end)
        end

        if Textbox.Default ~= "" then
            Textbox:Set(Textbox.Default)
        end

        if Textbox.Flag then
            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end
        end

        return setmetatable(Textbox, Library)
    end

    Library.Keybind = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Name = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Keybind(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Keybind(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Keybind(Params)
        end

        local Section = Self

        local Keybind = {
            Name = Params.Name or "Keybind",
            Key = Params.Default,
            Flag = Params.Flag,
            Mode = Params.Mode or "Toggle",
            Active = false,
            Callback = Params.Callback or function() end,
            Picking = false,
            IsOpen = false,
            Debounce = false,
            Items = { }
        }

        if Library.RegisterKeybind then
            Library:RegisterKeybind({
                Id = Keybind,
                Name = Keybind.Name or "Keybind",
                GetKey = function() return Keybind.Key end,
                GetActive = function()
                    if Keybind.Mode == "Hold" then
                        if not Keybind.Key then return false end
                        local Key = Keybind.Key
                        if typeof(Key) == "EnumItem" then
                            if Key.EnumType == Enum.KeyCode then
                                return UserInputService:IsKeyDown(Key)
                            elseif Key.EnumType == Enum.UserInputType then
                                return UserInputService:IsMouseButtonPressed(Key)
                            end
                        end
                        return false
                    else
                        return Keybind.Active == true
                    end
                end
            })
        end

        local Row = Section:AddRow(32, Keybind.Name)
        local Items = { Row = Row }

        Items.Label = MakeText({
            Parent = Row.Instance,
            Text = Keybind.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(Section.Width - 60, 20),
            Color = "Text",
            Truncate = true,
            Z = 5
        })

        Items.Icon = MakeImage({
            Parent = Row.Instance,
            Icon = "command",
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Color = "DimText",
            Z = 6
        })

        Items.Hit = MakeButton({
            Parent = Row.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(30, 26),
            Z = 8
        })

        Items.Hit:OnHover(function()
            Items.Icon:Tween({ ImageColor3 = Library.Theme.Text })
        end, function()
            Items.Icon:Tween({ ImageColor3 = Library.Theme.DimText })
        end)

        Keybind.Items = Items

        local PanelW = 170

        local Panel = MakeFrame({
            Parent = Library.UnusedHolder.Instance,
            Size = UDim2.fromOffset(PanelW, 72),
            Color = "Section",
            Round = 8,
            Z = 40
        })

        Panel.Instance.Visible = false

        MakeText({
            Parent = Panel.Instance,
            Text = Keybind.Name,
            TextSize = 12,
            Pos = UDim2.fromOffset(11, 8),
            Size = UDim2.fromOffset(PanelW - 22, 14),
            Color = "DimText",
            Truncate = true,
            Z = 41
        })

        local KeyBox = MakeFrame({
            Parent = Panel.Instance,
            Pos = UDim2.fromOffset(9, 32),
            Size = UDim2.fromOffset(PanelW - 18, 30),
            Color = "Light",
            Round = 5,
            Clip = true,
            Z = 41
        })

        local PanelKey = MakeText({
            Parent = KeyBox.Instance,
            Text = "None",
            TextSize = 13,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "Text",
            Align = Enum.TextXAlignment.Center,
            Truncate = true,
            Z = 42
        })

        local KeyHit = MakeButton({
            Parent = KeyBox.Instance,
            Z = 43
        })

        function Keybind:Set(Key)
            Keybind.Key = Key
            PanelKey.Instance.Text = KeyName(Key)
            Keybind.Picking = false

            if Keybind.Flag then
                Library.Flags[Keybind.Flag] = Key and tostring(Key) or "None"
            end
        end

        function Keybind:Get()
            return Keybind.Key
        end

        AttachPopup({
            Popup = Keybind,
            Frame = Panel,
            Level = 40,
            GetAnchor = function()
                return Items.Hit.Instance
            end,
            Place = function(Off)
                local Anchor = Items.Icon.Instance
                local PScale = Library:GetScreenScale()
                local Right = Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X
                local PX = Right / PScale + 8 + (Off or 0)
                local PY = (Anchor.AbsolutePosition.Y + GuiInset) / PScale - 4

                return UDim2.fromOffset(PX, PY)
            end,
            From = -6,
            To = 2,
            Retreat = RetreatLeft
        })

        Items.Hit:Connect("MouseButton1Down", function()
            Keybind:SetOpen(not Keybind.IsOpen)
        end)

        KeyHit:Connect("MouseButton1Click", function()
            CaptureKey(Keybind, PanelKey.Instance, function(Key)
                Keybind:Set(Key)
            end)
        end)

        Library:Connect(UserInputService.InputBegan, function(Input, Processed)
            if Processed or Keybind.Picking or not Keybind.Key then return end
            if not KeyMatches(Input, Keybind.Key) then return end

            if Keybind.Mode == "Hold" then
                Keybind.Active = true
                Library:SafeCall(Keybind.Callback, true, Keybind.Key)
            else
                Keybind.Active = not Keybind.Active
                Library:SafeCall(Keybind.Callback, Keybind.Active, Keybind.Key)
            end

            if Library.UpdateKeybindMenu then
                Library:UpdateKeybindMenu()
            end
        end)

        Library:Connect(UserInputService.InputEnded, function(Input)
            if Keybind.Mode ~= "Hold" or not Keybind.Key then return end
            if not KeyMatches(Input, Keybind.Key) then return end

            Keybind.Active = false
            Library:SafeCall(Keybind.Callback, false, Keybind.Key)

            if Library.UpdateKeybindMenu then
                Library:UpdateKeybindMenu()
            end
        end)

        Keybind:Set(Keybind.Key)

        if Keybind.Flag then
            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(ParseKey(Value))
            end
        end

        return setmetatable(Keybind, Library)
    end

    Library.Colorpicker = function(Self, Params)
        Params = Params or { }

        local Section = Self

        local Colorpicker = {
            Name = Params.Name or "Color",
            Default = Params.Default or Library.Theme.Accent,
            Transparency = Params.Transparency or 0,
            Flag = Params.Flag,
            Callback = Params.Callback or function() end,
            Color = Params.Default or Library.Theme.Accent,
            Items = { }
        }

        local Row = Section:AddRow(32, Colorpicker.Name)
        local Items = { Row = Row }

        Items.Label = MakeText({
            Parent = Row.Instance,
            Text = Colorpicker.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(Section.Width - 60, 20),
            Color = "Text",
            Truncate = true,
            Z = 5
        })

        Items.Swatch = MakeSwatch(Row.Instance, -13, Colorpicker.Default, 5)
        Colorpicker.Items = Items

        local Picker = MakeColorPopup(function()
            return Items.Swatch.Halo.Instance
        end, Colorpicker.Name, Colorpicker.Default, Colorpicker.Transparency, function(Color, Alpha)
            Colorpicker.Color = Color
            Colorpicker.Transparency = Alpha
            Items.Swatch:SetColor(Color, Alpha)

            if Colorpicker.Flag then
                Library.Flags[Colorpicker.Flag] = {
                    __color = Color:ToHex(),
                    __alpha = Alpha
                }
            end

            Library:SafeCall(Colorpicker.Callback, Color, Alpha)
        end)

        Colorpicker.Picker = Picker

        function Colorpicker:Set(Color, Alpha)
            Picker:Set(Color, Alpha)
        end

        function Colorpicker:Get()
            return Colorpicker.Color, Colorpicker.Transparency
        end

        Items.Swatch.Hit:Connect("MouseButton1Down", function()
            Picker:SetOpen(not Picker.IsOpen)
        end)

        if Colorpicker.Flag then
            Library.SetFlags[Colorpicker.Flag] = function(Color, Alpha)
                Picker:Set(Color, Alpha)
            end
        end

        return setmetatable(Colorpicker, Library)
    end

    Library.Label = function(Self, Params)
        Params = Params or { }

        local Section = Self

        local Label = {
            Name = Params.Name or "Label",
            Items = { }
        }

        local Row = Section:AddRow(24, Label.Name)

        Label.Items.Text = MakeText({
            Parent = Row.Instance,
            Text = Label.Name,
            TextSize = 15,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(Section.Width - 28, 20),
            Color = "DimText",
            Truncate = true,
            Z = 5
        })

        function Label:Set(Text)
            Label.Items.Text.Instance.Text = tostring(Text)
        end

        return setmetatable(Label, Library)
    end

    Library.Paragraph = function(Self, Params)
        Params = Params or { }
        if type(Params) == "string" then
            Params = { Title = Params }
        end

        if Self.Tabs ~= nil then
            local Tab = Self.Current or Self.Tabs[1] or Self:Tab({ Name = "Main", Icon = "home" })
            return Tab:Paragraph(Params)
        end
        if Self.Subs ~= nil and Self.Columns == nil then
            local SubTab = Self.Current or Self.Subs[1] or Self:SubTab({ Name = "General", Icon = "layers" })
            return SubTab:Paragraph(Params)
        end
        if Self.Columns ~= nil and Self.AddRow == nil then
            local Sec = Self.DefaultSection or Self:Section({ Name = Params.SectionName or "General", Side = 1 })
            Self.DefaultSection = Sec
            return Sec:Paragraph(Params)
        end

        local Section = Self

        local Paragraph = {
            Title = Params.Title or Params.Name or "Paragraph",
            Content = Params.Content or "",
            Items = { }
        }

        local Width = Section.Width - 28
        local TitleBounds = MeasureText(Paragraph.Title, 15, Width, UiFont)
        local BodyBounds = MeasureText(Paragraph.Content, 14, Width, UiFont)
        local Total = TitleBounds.Y + BodyBounds.Y + 16

        local Row = Section:AddRow(Total, Paragraph.Title .. " " .. Paragraph.Content)

        local function Block(Text, TextSize, Y, Height, Color)
            local Item = MakeText({
                Parent = Row.Instance,
                Text = Text,
                TextSize = TextSize,
                Pos = UDim2.fromOffset(14, Y),
                Size = UDim2.fromOffset(Width, Height),
                Color = Color,
                Wrap = true,
                Z = 5
            })

            Item.Instance.TextYAlignment = Enum.TextYAlignment.Top
            return Item
        end

        Paragraph.Items.Title = Block(Paragraph.Title, 15, 6, TitleBounds.Y, "Text")
        Paragraph.Items.Body = Block(Paragraph.Content, 14, TitleBounds.Y + 8, BodyBounds.Y, "DimText")

        function Paragraph:SetTitle(Text)
            Paragraph.Items.Title.Instance.Text = tostring(Text)
        end

        function Paragraph:SetContent(Text)
            Paragraph.Items.Body.Instance.Text = tostring(Text)
        end

        return setmetatable(Paragraph, Library)
    end

    Library.ThemeConfig = function(Self, Params)
        Params = Params or { }

        local SubTab = Self
        local Window = SubTab.Window
        local Page = SubTab.Items.Page
        local ContentH = Window.ContentH
        local ColW = Window.ColW
        local Col2X = Window.Col2X

        SubTab.Columns[1].Scroll.Instance.Visible = false
        SubTab.Columns[2].Scroll.Instance.Visible = false

        local Config = {
            Rows = { },
            Selected = nil,
            IntroToken = 0,
            Items = { }
        }

        local Items = Config.Items

        local function ConfigPath(Name)
            return Library.ConfigFolder .. "/" .. Name .. ".json"
        end

        Items.CreateBox = MakeFrame({
            Parent = Page.Instance,
            Pos = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(ColW, 40),
            Z = 3
        })

        Items.NameBox = MakeFrame({
            Parent = Items.CreateBox.Instance,
            Size = UDim2.fromOffset(ColW - 94, 40),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 4
        })

        MakeImage({
            Parent = Items.NameBox.Instance,
            Icon = "pencil",
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Color = "DimText",
            Z = 5
        })

        Items.NameInput = MakeInput({
            Parent = Items.NameBox.Instance,
            Placeholder = "config name",
            Pos = UDim2.fromOffset(34, 0),
            Size = UDim2.new(1, -44, 1, 0),
            TextSize = 15,
            Z = 5
        })

        Items.Create = MakeFrame({
            Parent = Items.CreateBox.Instance,
            Anchor = Vector2.new(1, 0),
            Pos = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(84, 40),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 4
        })

        HoverSwap(Items.Create)
        Items.CreateSweep = MakeSweep(Items.Create.Instance, 5)

        MakeText({
            Parent = Items.Create.Instance,
            Text = "Create",
            TextSize = 15,
            Size = UDim2.new(1, 0, 1, 0),
            Color = "Text",
            Align = Enum.TextXAlignment.Center,
            Z = 6
        })

        Items.CreateHit = MakeButton({
            Parent = Items.Create.Instance,
            Z = 7
        })

        Items.ListHolder = MakeFrame({
            Parent = Page.Instance,
            Pos = UDim2.fromOffset(0, 52),
            Size = UDim2.fromOffset(ColW, ContentH - 52),
            Z = 3
        })

        Items.List = Library:Create("ScrollingFrame", {
            Parent = Items.ListHolder.Instance,
            Name = "\0",
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            Selectable = false,
            Active = true,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.fromOffset(0, 0),
            ZIndex = 3,
            BorderSizePixel = 0
        })

        Library:Create("UIListLayout", {
            Parent = Items.List.Instance,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })

        Items.RightScroll = Library:Create("ScrollingFrame", {
            Parent = Page.Instance,
            Name = "RightScroll",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(Col2X, 0),
            Size = UDim2.fromOffset(ColW, ContentH),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ScrollBarImageTransparency = 0,
            BorderSizePixel = 0,
            Selectable = false,
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
            ZIndex = 3
        }):AddToTheme({ ScrollBarImageColor3 = "Accent" })

        Library:Create("UIListLayout", {
            Parent = Items.RightScroll.Instance,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })

        Library:Create("UIPadding", {
            Parent = Items.RightScroll.Instance,
            PaddingRight = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 10)
        })

        Items.InfoPanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 204),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.InfoPanel.Instance.LayoutOrder = 1

        MakeText({
            Parent = Items.InfoPanel.Instance,
            Text = "Config info",
            TextSize = 15,
            Pos = UDim2.fromOffset(14, 12),
            Size = UDim2.fromOffset(ColW - 28, 20),
            Color = "Text",
            Z = 4
        })

        local InfoRows = { }

        local function InfoRow(Index, Icon, Label)
            local Y = 44 + (Index - 1) * 32

            MakeImage({
                Parent = Items.InfoPanel.Instance,
                Icon = Icon,
                Pos = UDim2.fromOffset(14, Y + 3),
                Size = UDim2.fromOffset(14, 14),
                Color = "DimIcon",
                Z = 4
            })

            MakeText({
                Parent = Items.InfoPanel.Instance,
                Text = Label,
                TextSize = 15,
                Pos = UDim2.fromOffset(36, Y),
                Size = UDim2.fromOffset(ColW - 170, 20),
                Color = "DimText",
                Z = 4
            })

            local Value = MakeText({
                Parent = Items.InfoPanel.Instance,
                Text = "-",
                TextSize = 15,
                Anchor = Vector2.new(1, 0),
                Pos = UDim2.new(1, -14, 0, Y),
                Size = UDim2.fromOffset(150, 20),
                Color = "Text",
                Align = Enum.TextXAlignment.Right,
                Truncate = true,
                Z = 4
            })

            if Index < 5 then
                MakeFrame({
                    Parent = Items.InfoPanel.Instance,
                    Pos = UDim2.fromOffset(14, Y + 27),
                    Size = UDim2.fromOffset(ColW - 28, 1),
                    Color = "Element",
                    Z = 4
                })
            end

            return Value
        end

        InfoRows.Version = InfoRow(1, "layers", "Config version")
        InfoRows.Compatible = InfoRow(2, "link", "Compatibility")
        InfoRows.Created = InfoRow(3, "clock", "Created")
        InfoRows.Creator = InfoRow(4, "user", "Creator")
        InfoRows.Elements = InfoRow(5, "box", "Saved flags")

        local function ShowInfo(Name)
            if not Name then
                for _, Value in InfoRows do
                    Value.Instance.Text = "-"
                end

                return
            end

            local Data = { }

            pcall(function()
                Data = HttpService:JSONDecode(readfile(ConfigPath(Name)))
            end)

            local Count = 0

            for Key in Data do
                if string.sub(Key, 1, 2) ~= "__" then
                    Count += 1
                end
            end

            local Same = Data.__version == Library.Version

            InfoRows.Version.Instance.Text = Data.__version or "Unknown"
            InfoRows.Compatible.Instance.Text = Same and "Compatible" or "Outdated"
            InfoRows.Created.Instance.Text = Data.__created or "Unknown"
            InfoRows.Creator.Instance.Text = Data.__creator or "Unknown"
            InfoRows.Elements.Instance.Text = tostring(Count) .. " flags"
        end

        Items.ThemePanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 72),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.ThemePanel.Instance.LayoutOrder = 2

        MakeText({
            Parent = Items.ThemePanel.Instance,
            Text = "Theme",
            TextSize = 15,
            Pos = UDim2.fromOffset(14, 12),
            Size = UDim2.fromOffset(ColW - 28, 20),
            Color = "Text",
            Z = 4
        })

        local ActiveThemeLabel = MakeText({
            Parent = Items.ThemePanel.Instance,
            Text = Library.ThemePresets[1].Name,
            TextSize = 14,
            Bold = true,
            Pos = UDim2.fromOffset(14, 38),
            Size = UDim2.fromOffset(125, 20),
            Color = "Accent",
            Truncate = true,
            Z = 4
        })

        local PresetDots = { }

        local DotContainer = MakeFrame({
            Parent = Items.ThemePanel.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -12, 0.5, 6),
            Size = UDim2.fromOffset(#Library.ThemePresets * 26, 24),
            Z = 4
        })

        Library:Create("UIListLayout", {
            Parent = DotContainer.Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })

        local function SelectPreset(TargetDot)
            for _, Dot in PresetDots do
                local IsActive = (Dot == TargetDot)
                Library:Tween({ Thickness = IsActive and 2 or 1 }, nil, Dot.Ring.Instance)
                Dot.Ring.Instance.Color = IsActive and Color3.new(1, 1, 1) or Library.Theme.Line
            end
        end

        for Index, Preset in Library.ThemePresets do
            local Dot = MakeFrame({
                Parent = DotContainer.Instance,
                Size = UDim2.fromOffset(20, 20),
                Raw = Preset.Swatch or Preset.Accent,
                Round = 20,
                Z = 5
            })

            Dot.Instance.LayoutOrder = Index

            Dot.Ring = Library:Create("UIStroke", {
                Parent = Dot.Instance,
                Color = Index == 1 and Color3.new(1, 1, 1) or Library.Theme.Line,
                Thickness = Index == 1 and 2 or 1
            })

            local Hit = MakeButton({
                Parent = Dot.Instance,
                Z = 6
            })

            Hit:Connect("MouseButton1Down", function()
                Library:SetTheme(Preset)
                SelectPreset(Dot)
                ActiveThemeLabel.Instance.Text = Preset.Name
                ActiveThemeLabel.Instance.TextColor3 = Library.Theme.Accent
            end)

            Hit:OnHover(function()
                ActiveThemeLabel.Instance.Text = Preset.Name
            end, function()
                ActiveThemeLabel.Instance.Text = Library.CurrentThemeName or Library.ThemePresets[1].Name
            end)

            table.insert(PresetDots, Dot)
        end

        Library.UpdateThemeUI = function(Self, CurrentPreset)
            local PresetName = (CurrentPreset and CurrentPreset.Name) or Library.CurrentThemeName or Library.ThemePresets[1].Name
            for i, Preset in Library.ThemePresets do
                local Dot = PresetDots[i]
                if Dot and Dot.Ring and Dot.Ring.Instance then
                    local IsActive = (Preset.Name == PresetName)
                    Library:Tween({ Thickness = IsActive and 2 or 1 }, nil, Dot.Ring.Instance)
                    Dot.Ring.Instance.Color = IsActive and Color3.new(1, 1, 1) or Library.Theme.Line
                end
            end
            if ActiveThemeLabel and ActiveThemeLabel.Instance then
                ActiveThemeLabel.Instance.Text = PresetName
                ActiveThemeLabel.Instance.TextColor3 = Library.Theme.Accent
            end
        end

        Items.FontPanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 76),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.FontPanel.Instance.LayoutOrder = 3

        MakeText({
            Parent = Items.FontPanel.Instance,
            Text = "Font",
            TextSize = 15,
            Pos = UDim2.fromOffset(14, 12),
            Size = UDim2.fromOffset(ColW - 28, 20),
            Color = "Text",
            Z = 4
        })

        local ActiveFontLabel = MakeText({
            Parent = Items.FontPanel.Instance,
            Text = Library.CurrentFontName or "PixelCode",
            TextSize = 14,
            Bold = true,
            Pos = UDim2.fromOffset(14, 38),
            Size = UDim2.fromOffset(115, 20),
            Color = "Accent",
            Truncate = true,
            Z = 4
        })

        local FontPills = { }
        local FontList = { "PixelCode", "Tamzen", "Spleen", "Gotham" }

        local PillContainer = MakeFrame({
            Parent = Items.FontPanel.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -12, 0.5, 6),
            Size = UDim2.fromOffset(208, 26),
            Z = 4
        })

        Library:Create("UIListLayout", {
            Parent = PillContainer.Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })

        local function UpdateFontPillSelection(ActiveKey)
            ActiveKey = ActiveKey or Library.CurrentFontName or "PixelCode"
            local Info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            for Key, Pill in pairs(FontPills) do
                local IsActive = (Key == ActiveKey)
                local TargetLineW = IsActive and math.floor(Pill.Width * 0.65) or 0
                if Pill.Underline and Pill.Underline.Instance then
                    Library:Tween({ Size = UDim2.fromOffset(TargetLineW, 2) }, Info, Pill.Underline.Instance)
                end
                if Pill.UnderlineShadow then
                    Library:StampResting(Pill.UnderlineShadow, "Transparency", IsActive and 0.35 or 1)
                    Pill.Underline:Tween({ Transparency = IsActive and 0.35 or 1 }, Info, Pill.UnderlineShadow)
                end
                if Pill.Label then
                    Pill.Label:ChangeItemTheme({ TextColor3 = IsActive and "Accent" or "DimText" })
                    Pill.Label:Tween({ TextColor3 = IsActive and Library.Theme.Accent or Library.Theme.DimText }, Info)
                end
            end
            if ActiveFontLabel and ActiveFontLabel.Instance then
                ActiveFontLabel.Instance.Text = ActiveKey
                ActiveFontLabel.Instance.TextColor3 = Library.Theme.Accent
            end
        end

        for Index, FontKey in ipairs(FontList) do
            local DisplayText = FontKey == "PixelCode" and "Pixel" or FontKey
            local PillW = FontKey == "PixelCode" and 54 or (FontKey == "Gotham" and 56 or 46)

            local Pill = MakeFrame({
                Parent = PillContainer.Instance,
                Size = UDim2.fromOffset(PillW, 24),
                Color = "Element",
                Round = 6,
                Z = 5
            })

            Pill.Instance.LayoutOrder = Index
            Pill.Width = PillW

            local IsActiveInit = (FontKey == (Library.CurrentFontName or "PixelCode"))
            local LineW = IsActiveInit and math.floor(PillW * 0.65) or 0

            Pill.Underline = MakeFrame({
                Parent = Pill.Instance,
                Anchor = Vector2.new(0.5, 1),
                Pos = UDim2.new(0.5, 0, 1, -2),
                Size = UDim2.fromOffset(LineW, 2),
                Color = "Accent",
                Round = 1,
                Z = 7
            })

            Pill.UnderlineShadow = MakeAccentShadow(
                Pill.Underline.Instance,
                UDim2.fromOffset(3, 3),
                UDim.new(0, 5),
                IsActiveInit and 0.35 or 1
            )

            Pill.Label = MakeText({
                Parent = Pill.Instance,
                Text = DisplayText,
                TextSize = 12,
                Bold = true,
                Size = UDim2.new(1, 0, 1, 0),
                Color = IsActiveInit and "Accent" or "DimText",
                Align = Enum.TextXAlignment.Center,
                Z = 6
            })

            local Hit = MakeButton({
                Parent = Pill.Instance,
                Z = 7
            })

            Hit:Connect("MouseButton1Down", function()
                Library:SetFont(FontKey)
                UpdateFontPillSelection(FontKey)
            end)

            Hit:OnHover(function()
                ActiveFontLabel.Instance.Text = FontKey
            end, function()
                ActiveFontLabel.Instance.Text = Library.CurrentFontName or "PixelCode"
            end)

            FontPills[FontKey] = Pill
        end

        Library.UpdateFontUI = function(Self, NewKey)
            UpdateFontPillSelection(NewKey or Library.CurrentFontName or "PixelCode")
        end

        Items.BackgroundPanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 58),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.BackgroundPanel.Instance.LayoutOrder = 4

        MakeText({
            Parent = Items.BackgroundPanel.Instance,
            Text = "Background",
            TextSize = 14,
            Pos = UDim2.fromOffset(14, 10),
            Size = UDim2.fromOffset(ColW - 28, 18),
            Color = "Text",
            Z = 4
        })

        local ActiveBgLabel = MakeText({
            Parent = Items.BackgroundPanel.Instance,
            Text = Library.AnimBgStyle or "Neon Grid",
            TextSize = 12,
            Bold = true,
            Pos = UDim2.fromOffset(14, 30),
            Size = UDim2.fromOffset(100, 18),
            Color = "Accent",
            Truncate = true,
            Z = 4
        })

        local BgControlContainer = MakeFrame({
            Parent = Items.BackgroundPanel.Instance,
            Anchor = Vector2.new(1, 0.5),
            Pos = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(165, 26),
            Z = 4
        })

        Library:Create("UIListLayout", {
            Parent = BgControlContainer.Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })

        local BgStyles = {
            { Key = "Neon Grid", Short = "Grid", Width = 48 },
            { Key = "Floating Particles", Short = "Dust", Width = 48 }
        }

        local BgPills = { }

        local function UpdateBgPillSelection(ActiveStyle)
            ActiveStyle = ActiveStyle or Library.AnimBgStyle or "Neon Grid"
            local Info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            for Key, Pill in pairs(BgPills) do
                local IsActive = (Key == ActiveStyle)
                local TargetLineW = IsActive and math.floor(Pill.Width * 0.65) or 0
                if Pill.Underline and Pill.Underline.Instance then
                    Library:Tween({ Size = UDim2.fromOffset(TargetLineW, 2) }, Info, Pill.Underline.Instance)
                end
                if Pill.UnderlineShadow then
                    Library:StampResting(Pill.UnderlineShadow, "Transparency", IsActive and 0.35 or 1)
                    Pill.Underline:Tween({ Transparency = IsActive and 0.35 or 1 }, Info, Pill.UnderlineShadow)
                end
                if Pill.Label then
                    Pill.Label:ChangeItemTheme({ TextColor3 = IsActive and "Accent" or "DimText" })
                    Pill.Label:Tween({ TextColor3 = IsActive and Library.Theme.Accent or Library.Theme.DimText }, Info)
                end
            end
            if ActiveBgLabel and ActiveBgLabel.Instance then
                ActiveBgLabel.Instance.Text = ActiveStyle
                ActiveBgLabel.Instance.TextColor3 = Library.Theme.Accent
            end
        end

        for Index, StyleData in ipairs(BgStyles) do
            local Pill = MakeFrame({
                Parent = BgControlContainer.Instance,
                Size = UDim2.fromOffset(StyleData.Width, 24),
                Color = "Element",
                Round = 6,
                Z = 5
            })

            Pill.Instance.LayoutOrder = Index
            Pill.Width = StyleData.Width

            local IsActiveInit = (StyleData.Key == (Library.AnimBgStyle or "Neon Grid"))
            local LineW = IsActiveInit and math.floor(StyleData.Width * 0.65) or 0

            Pill.Underline = MakeFrame({
                Parent = Pill.Instance,
                Anchor = Vector2.new(0.5, 1),
                Pos = UDim2.new(0.5, 0, 1, -2),
                Size = UDim2.fromOffset(LineW, 2),
                Color = "Accent",
                Round = 1,
                Z = 7
            })

            Pill.UnderlineShadow = MakeAccentShadow(
                Pill.Underline.Instance,
                UDim2.fromOffset(3, 3),
                UDim.new(0, 5),
                IsActiveInit and 0.35 or 1
            )

            Pill.Label = MakeText({
                Parent = Pill.Instance,
                Text = StyleData.Short,
                TextSize = 11,
                Bold = true,
                Size = UDim2.new(1, 0, 1, 0),
                Color = IsActiveInit and "Accent" or "DimText",
                Align = Enum.TextXAlignment.Center,
                Z = 6
            })

            local Hit = MakeButton({
                Parent = Pill.Instance,
                Z = 7
            })

            Hit:Connect("MouseButton1Down", function()
                Library:SetAnimatedBackground(true, StyleData.Key)
                UpdateBgPillSelection(StyleData.Key)
            end)

            Hit:OnHover(function()
                ActiveBgLabel.Instance.Text = StyleData.Key
            end, function()
                ActiveBgLabel.Instance.Text = Library.AnimBgStyle or "Neon Grid"
            end)

            BgPills[StyleData.Key] = Pill
        end

        local BgSwitch = CreateSwitch(BgControlContainer.Instance, Vector2.new(0, 0.5), UDim2.fromOffset(0, 0), Library.AnimBgEnabled, function(NewState)
            Library:SetAnimatedBackground(NewState, nil)
        end)
        BgSwitch.Box.Instance.LayoutOrder = 10

        Library.UpdateBgUI = function(Self)
            UpdateBgPillSelection(Library.AnimBgStyle)
            BgSwitch.SetVisual(Library.AnimBgEnabled)
        end

        -- Панель настройки кейбинд меню (свитч из GUI)
        Items.KeybindPanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 58),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.KeybindPanel.Instance.LayoutOrder = 5

        MakeText({
            Parent = Items.KeybindPanel.Instance,
            Text = "Keybind Menu",
            TextSize = 14,
            Pos = UDim2.fromOffset(14, 10),
            Size = UDim2.fromOffset(ColW - 90, 16),
            Color = "Text",
            Z = 4
        })

        local KeybindStatusLabel = MakeText({
            Parent = Items.KeybindPanel.Instance,
            Text = Library.KeybindMenuEnabled and "Enabled" or "Disabled",
            TextSize = 12,
            Bold = true,
            Pos = UDim2.fromOffset(14, 30),
            Size = UDim2.fromOffset(100, 18),
            Color = Library.KeybindMenuEnabled and "Accent" or "DimText",
            Z = 4
        })

        local KeybindSwitch = CreateSwitch(Items.KeybindPanel.Instance, Vector2.new(1, 0.5), UDim2.new(1, -14, 0.5, 0), Library.KeybindMenuEnabled, function(NewState)
            Library:SetKeybindMenu(NewState)
            KeybindStatusLabel.Instance.Text = NewState and "Enabled" or "Disabled"
            KeybindStatusLabel.Instance.TextColor3 = NewState and Library.Theme.Accent or Library.Theme.DimText
        end)

        Library.UpdateKeybindUI = function(Self)
            KeybindSwitch.SetVisual(Library.KeybindMenuEnabled)
            KeybindStatusLabel.Instance.Text = Library.KeybindMenuEnabled and "Enabled" or "Disabled"
            KeybindStatusLabel.Instance.TextColor3 = Library.KeybindMenuEnabled and Library.Theme.Accent or Library.Theme.DimText
        end

        -- Панель проверки уведомления с кнопкой Send Test Notification
        Items.TestNotifPanel = MakeFrame({
            Parent = Items.RightScroll.Instance,
            Size = UDim2.new(1, 0, 0, 50),
            Color = "Section",
            Round = 10,
            Z = 3
        })
        Items.TestNotifPanel.Instance.LayoutOrder = 6

        local TestNotifBtn = MakeFrame({
            Parent = Items.TestNotifPanel.Instance,
            Anchor = Vector2.new(0.5, 0.5),
            Pos = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -20, 0, 32),
            Color = "Element",
            Round = 6,
            Clip = true,
            Z = 4
        })

        HoverSwap(TestNotifBtn)
        local TestNotifSweep = MakeSweep(TestNotifBtn.Instance, 5)

        MakeImage({
            Parent = TestNotifBtn.Instance,
            Icon = "bell",
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(15, 15),
            Color = "Accent",
            Z = 5
        })

        MakeText({
            Parent = TestNotifBtn.Instance,
            Text = "Send Test Notification",
            TextSize = 13,
            Bold = true,
            Anchor = Vector2.new(0, 0.5),
            Pos = UDim2.new(0, 34, 0.5, 0),
            Size = UDim2.new(1, -44, 1, 0),
            Color = "Text",
            Z = 5
        })

        local TestNotifHit = MakeButton({
            Parent = TestNotifBtn.Instance,
            Z = 6
        })

        TestNotifHit:Connect("MouseButton1Down", function()
            PlaySweep(TestNotifSweep.Instance)
            Library:Notification({
                Title = "jade.xyz Notification",
                Description = "Notifications are functioning properly!",
                Icon = "bell",
                Duration = 3.5
            })
        end)

        local RefreshList

        local function AddRow(Index, Name)
            local Slot = MakeFrame({
                Parent = Items.List.Instance,
                Size = UDim2.fromOffset(ColW, 44),
                Clip = true,
                Z = 4
            })

            Slot.Instance.LayoutOrder = Index

            local Row = MakeFrame({
                Parent = Slot.Instance,
                Size = UDim2.fromOffset(ColW, 44),
                Color = "Section",
                Round = 8,
                Z = 4
            })

            local Bar = MakeFrame({
                Parent = Row.Instance,
                Anchor = Vector2.new(0, 0.5),
                Pos = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(2.5, 0),
                Color = "Accent",
                Round = 2,
                Z = 6
            })

            local BarShadow = MakeAccentShadow(
                Bar.Instance,
                UDim2.fromOffset(4, 4),
                UDim.new(0, 6),
                1
            )

            if BarShadow then
                SetRest(BarShadow, "Transparency", 1)
            end

            local Label = MakeText({
                Parent = Row.Instance,
                Text = Name,
                TextSize = 15,
                Anchor = Vector2.new(0, 0.5),
                Pos = UDim2.new(0, 15, 0.5, 0),
                Size = UDim2.fromOffset(ColW - 130, 20),
                Color = "DimText",
                Truncate = true,
                Z = 5
            })

            local Data = {
                Name = Name,
                Slot = Slot,
                Row = Row
            }

            local function IconButton(Offset, Icon, Callback)
                local Image = MakeImage({
                    Parent = Row.Instance,
                    Icon = Icon,
                    Anchor = Vector2.new(1, 0.5),
                    Pos = UDim2.new(1, Offset, 0.5, 0),
                    Size = UDim2.fromOffset(15, 15),
                    Color = "DimText",
                    Z = 5
                })

                local Hit = MakeButton({
                    Parent = Row.Instance,
                    Anchor = Vector2.new(1, 0.5),
                    Pos = UDim2.new(1, Offset + 7, 0.5, 0),
                    Size = UDim2.fromOffset(28, 28),
                    Z = 6
                })

                Hit:OnHover(function()
                    Image:Tween({ ImageColor3 = Library.Theme.Text })
                end, function()
                    Image:Tween({ ImageColor3 = Library.Theme.DimText })
                end)

                Hit:Connect("MouseButton1Down", Callback)
            end

            IconButton(-66, "save", function()
                Library:Confirm({
                    Title = "Overwrite Config",
                    Text = "Are you sure you want to overwrite \"" .. Name .. "\"?",
                    Icon = "save",
                    YesText = "Yes",
                    NoText = "No",
                    OnConfirm = function()
                        local Created

                        pcall(function()
                            Created = HttpService:JSONDecode(readfile(ConfigPath(Name))).__created
                        end)

                        writefile(ConfigPath(Name), Library:GetConfig(Created))
                        ShowInfo(Name)

                        Library:Notification({
                            Name = "Config saved",
                            Description = "Current values were written into \"" .. Name .. "\".",
                            Icon = "save"
                        })
                    end
                })
            end)

            IconButton(-40, "share-2", function()
                if setclipboard then
                    pcall(function()
                        setclipboard(readfile(ConfigPath(Name)))
                    end)
                end

                Library:Notification({
                    Name = "Config copied",
                    Description = "\"" .. Name .. "\" was copied to your clipboard.",
                    Icon = "share-2"
                })
            end)

            IconButton(-14, "trash-2", function()
                if Data.Removing then return end

                Library:Confirm({
                    Title = "Delete Config",
                    Text = "Are you sure you want to delete \"" .. Name .. "\"?",
                    Icon = "trash-2",
                    YesText = "Yes",
                    NoText = "No",
                    OnConfirm = function()
                        if Data.Removing then return end
                        Data.Removing = true

                        if delfile and isfile and isfile(ConfigPath(Name)) then
                            delfile(ConfigPath(Name))
                        end

                        if Config.Selected == Name then
                            Config.Selected = nil
                            ShowInfo(nil)
                        end

                        local Index = table.find(Config.Rows, Data)
                        if Index then table.remove(Config.Rows, Index) end

                        local Sink = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                        Library:Tween({ Size = UDim2.fromOffset(ColW, 0) }, Sink, Slot.Instance)
                        Row:FadeDescendants(false)

                        Library:Notification({
                            Name = "Config deleted",
                            Description = "\"" .. Name .. "\" was removed.",
                            Icon = "trash-2"
                        })

                        task.delay(0.3, function()
                            Slot.Instance:Destroy()

                            local NewHeight = #Config.Rows * 52
                            Items.List.Instance.CanvasSize = UDim2.fromOffset(0, math.max(NewHeight - 8, 0))
                        end)
                    end
                })
            end)

            function Data:SetSelected(Active)
                local Key = Active and "Text" or "DimText"

                Label:ChangeItemTheme({ TextColor3 = Key })
                Label:Tween({ TextColor3 = Library.Theme[Key] })
                Library:Tween({ Size = UDim2.fromOffset(2.5, Active and 16 or 0) }, nil, Bar.Instance)

                if BarShadow then
                    Library:StampResting(BarShadow, "Transparency", Active and 0.35 or 1)
                    BarShadow.Transparency = Active and 0.35 or 1
                end
            end

            local Hit = MakeButton({
                Parent = Row.Instance,
                Size = UDim2.new(1, -96, 1, 0),
                Z = 5
            })

            Hit:Connect("MouseButton1Down", function()
                Config.Selected = Name

                for _, Other in Config.Rows do
                    Other:SetSelected(Other == Data)
                end

                ShowInfo(Name)
                Library:LoadConfigFile(Name)

                if RefreshThemeUI then
                    RefreshThemeUI()
                end

                Library:Notification({
                    Name = "Config loaded",
                    Description = "All values were restored from \"" .. Name .. "\".",
                    Icon = "check"
                })
            end)

            table.insert(Config.Rows, Data)
            return Data
        end

        RefreshList = function()
            for _, Data in Config.Rows do
                Data.Slot.Instance:Destroy()
            end

            Config.Rows = { }

            for Index, Name in Library:ListConfigs() do
                local Data = AddRow(Index, Name)
                Data:SetSelected(Name == Config.Selected)
            end

            local Height = #Config.Rows * 52
            Items.List.Instance.CanvasSize = UDim2.fromOffset(0, math.max(Height - 8, 0))
        end

        Items.CreateHit:Connect("MouseButton1Down", function()
            PlaySweep(Items.CreateSweep.Instance)

            local Name = string.gsub(Items.NameInput.Instance.Text, "[^%w _%-]", "")

            if Name == "" then
                Library:Notification({
                    Name = "Config name required",
                    Description = "Type a name into the box before creating.",
                    Icon = "triangle-alert"
                })

                return
            end

            if isfile and isfile(ConfigPath(Name)) then
                Library:Notification({
                    Name = "Name already used",
                    Description = "A config called \"" .. Name .. "\" already exists.",
                    Icon = "triangle-alert"
                })

                return
            end

            writefile(ConfigPath(Name), Library:GetConfig())
            Items.NameInput.Instance.Text = ""
            Config.Selected = Name
            RefreshList()
            ShowInfo(Name)

            Library:Notification({
                Name = "Config created",
                Description = "\"" .. Name .. "\" now holds your current values.",
                Icon = "plus"
            })
        end)

        local Blocks = {
            { Frame = Items.CreateBox, Home = UDim2.fromOffset(0, 0) },
            { Frame = Items.ListHolder, Home = UDim2.fromOffset(0, 52) },
            { Frame = Items.RightScroll, Home = UDim2.fromOffset(Col2X, 0) }
        }

        local BlockSlide = 30
        local BlockStep = 0.06

        SubTab.PageIntro = function()
            Config.IntroToken += 1

            local Token = Config.IntroToken
            local Slide = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            for _, Block in Blocks do
                Block.Frame:CancelFade()
                Block.Frame.Instance.Visible = false
                Block.Frame.Instance.Position = Block.Home + UDim2.fromOffset(BlockSlide, 0)
            end

            for Index, Block in Blocks do
                task.delay((Index - 1) * BlockStep, function()
                    Block.Frame.Instance.Visible = true

                    if Config.IntroToken ~= Token then
                        Block.Frame.Instance.Position = Block.Home
                        return
                    end

                    Block.Frame:FadeDescendants(true)
                    Library:Tween({ Position = Block.Home }, Slide, Block.Frame.Instance)
                end)
            end
        end

        SubTab.PageOutro = function()
            Config.IntroToken += 1

            local Token = Config.IntroToken
            local Slide = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

            for Index, Block in Blocks do
                local Away = Block.Home + UDim2.fromOffset(-BlockSlide, 0)

                task.delay((Index - 1) * BlockStep, function()
                    if Config.IntroToken ~= Token then return end

                    Block.Frame:FadeDescendants(false)
                    Library:Tween({ Position = Away }, Slide, Block.Frame.Instance)
                end)
            end
        end

        function Config:Refresh()
            RefreshList()
        end

        RefreshList()
        ShowInfo(nil)

        return Config
    end

    Library.Watermark = function(Self, Params)
        Params = Params or { }

        if Library.WatermarkBar then
            return Library.WatermarkBar
        end

        local Icon = Params.Icon or (Self and Self.Icon) or (Library.GitHubBase .. "/jade-xyz-icon-1024-removebg-preview.png")
        local Items = { }
        local Order = 0

        Items.Bar = MakeFrame({
            Parent = Library.Holder.Instance,
            Anchor = Vector2.new(0.5, 0),
            Pos = UDim2.new(0.5, 0, 0, 14),
            Size = UDim2.fromOffset(0, 32),
            Color = "Background",
            Round = 8,
            Z = 60
        })

        Library:Create("UIStroke", {
            Parent = Items.Bar.Instance,
            Color = Library.Theme.Line,
            Thickness = 1
        }):AddToTheme({ Color = "Line" })

        Items.Bar.Instance.AutomaticSize = Enum.AutomaticSize.X

        if Library.LoaderActive then
            Items.Bar.Instance.Visible = false
            table.insert(Library.LoaderFinishedCallbacks, function()
                if Items.Bar and Items.Bar.Instance then
                    Items.Bar.Instance.Visible = true
                end
            end)
        end

        Library:Create("UIPadding", {
            Parent = Items.Bar.Instance,
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        })

        Library:Create("UIListLayout", {
            Parent = Items.Bar.Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })

        local function NextOrder()
            Order += 1
            return Order
        end

        Items.Icon = MakeImage({
            Parent = Items.Bar.Instance,
            Icon = Icon,
            Size = UDim2.fromOffset(20, 20),
            Color = Params.IconColor or "Accent",
            Fit = true,
            Z = 61
        })

        Items.Icon.Instance.LayoutOrder = NextOrder()

        local WatermarkName = Params.Name or (Self and Self.Name) or "jade.xyz"
        Items.Title = MakeText({
            Parent = Items.Bar.Instance,
            Text = WatermarkName,
            TextSize = 14,
            Bold = true,
            Color = "Text",
            Z = 61
        })

        Items.Title.Instance.AutomaticSize = Enum.AutomaticSize.X
        Items.Title.Instance.LayoutOrder = NextOrder()

        local function Separator()
            local Sep = MakeFrame({
                Parent = Items.Bar.Instance,
                Size = UDim2.fromOffset(1, 14),
                Color = "Light",
                Z = 61
            })

            Sep.Instance.LayoutOrder = NextOrder()
        end

        local function Stat(Text, ColorKey)
            local Label = MakeText({
                Parent = Items.Bar.Instance,
                Text = Text,
                TextSize = 14,
                Size = UDim2.fromOffset(0, 16),
                Color = ColorKey or "Text",
                Z = 61
            })

            Label.Instance.AutomaticSize = Enum.AutomaticSize.X
            Label.Instance.LayoutOrder = NextOrder()

            return Label
        end

        Separator()
        local GameStat = Stat("...", "Text")
        Separator()
        local FpsStat = Stat("0 fps", "Text")
        Separator()
        local PingStat = Stat("0 ms", "Text")
        Separator()
        local TimeStat = Stat(os.date("%I:%M %p"), "Text")

        Library:Thread(function()
            local Ok, Info = pcall(function()
                return MarketplaceService:GetProductInfo(game.PlaceId)
            end)

            GameStat.Instance.Text = (Ok and Info and Info.Name) or "Unknown"
        end)

        local Frames = 0

        Library:Connect(RunService.RenderStepped, function()
            Frames += 1
        end)

        Library:Thread(function()
            while task.wait(0.5) do
                if not Items.Bar.Instance.Parent then break end

                FpsStat.Instance.Text = tostring(Frames * 2) .. " fps"
                Frames = 0

                local Ping = 0

                pcall(function()
                    local Stat = StatsService.Network.ServerStatsItem["Data Ping"]
                    Ping = math.floor(Stat:GetValue())
                end)

                PingStat.Instance.Text = tostring(Ping) .. " ms"
                TimeStat.Instance.Text = os.date("%I:%M %p")
            end
        end)

        Items.Bar:MakeDraggable()
        Library.WatermarkBar = Items.Bar

        local Watermark = { Instance = Items.Bar.Instance }

        function Watermark:SetIcon(NewIcon)
            ApplyIcon(Items.Icon.Instance, NewIcon)
        end

        function Watermark:SetName(NewName)
            if NewName and Items.Title and Items.Title.Instance then
                Items.Title.Instance.Text = tostring(NewName)
            end
        end

        function Watermark:SetVisible(Bool)
            Items.Bar:FadeDescendants(Bool)
        end

        return Watermark
    end

    Library.GetConfig = function(Self, Created)
        local Config = { }

        for Index, Value in Library.Flags do
            if typeof(Value) == "Color3" then
                Config[Index] = { __color = Value:ToHex() }
            else
                Config[Index] = Value
            end
        end

        local ThemeColors = { }

        for _, Key in Library.ThemeKeys do
            ThemeColors[Key] = Library.Theme[Key]:ToHex()
        end

        Config.__accent = Library.Theme.Accent:ToHex()
        Config.__theme_name = Library.CurrentThemeName or "Pitch Black Jade"
        Config.__font = Library.CurrentFontName or "PixelCode"
        Config.__theme = ThemeColors
        Config.__created = Created or os.date("%d.%m.%Y %H:%M")
        Config.__version = Library.Version
        Config.__creator = LocalPlayer.DisplayName

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(Self, Config)
        local Ok, Decoded = pcall(function()
            return HttpService:JSONDecode(Config)
        end)

        if not Ok or type(Decoded) ~= "table" then return false end

        Library.Silent = true

        for Index, Value in Decoded do
            local SetFunction = Library.SetFlags[Index]
            if not SetFunction then continue end

            if type(Value) == "table" and Value.__color then
                SetFunction(Color3.fromHex(Value.__color), Value.__alpha)
            else
                SetFunction(Value)
            end
        end

        if type(Decoded.__theme_name) == "string" then
            Library:SetTheme(Decoded.__theme_name, true)
        end

        if type(Decoded.__font) == "string" and Library.FontDefinitions[Decoded.__font] then
            Library:SetFont(Decoded.__font)
        end

        if type(Decoded.__theme) == "table" then
            for Key, Hex in Decoded.__theme do
                local OkColor, Color = pcall(Color3.fromHex, Hex)
                if OkColor then Library.Theme[Key] = Color end
            end

            DeriveTheme()
            Library.ThemeDirty = true
        end

        if type(Decoded.__accent) == "string" then
            local OkColor, Color = pcall(Color3.fromHex, Decoded.__accent)
            if OkColor then Library:SetAccent(Color) end
        end

        Library.Silent = false
        return true
    end

    Library.SaveConfigFile = function(Self, Name)
        if not writefile then return false end

        writefile(Library.ConfigFolder .. "/" .. Name .. ".json", Library:GetConfig())
        return true
    end

    Library.LoadConfigFile = function(Self, Name)
        if not isfile then return false end

        local Path = Library.ConfigFolder .. "/" .. Name .. ".json"
        if not isfile(Path) then return false end

        return Library:LoadConfig(readfile(Path))
    end

    Library.ListConfigs = function(Self)
        local Result = { }

        if not listfiles or not isfolder or not isfolder(Library.ConfigFolder) then return Result end

        for _, File in listfiles(Library.ConfigFolder) do
            if string.sub(File, -5) ~= ".json" then continue end

            local Name = string.match(File, "([^/\\]+)%.json$")
            if Name then table.insert(Result, Name) end
        end

        return Result
    end

    Library:Connect(RunService.Heartbeat, function(Delta)
        if Library.ThemeDirty then
            Library.ThemeDirty = false
            Library:ApplyThemeInstant()
        end

        if not Library.PreloadDirty then return end

        Library.PreloadClock += Delta or 0

        if Library.PreloadClock >= 0.35 then
            Library.PreloadDirty = false
            Library.PreloadClock = 0
            Library:PreloadAll()
        end
    end)

    getgenv().Jade = Library
    getgenv().Zolar = Library
end

return Library
