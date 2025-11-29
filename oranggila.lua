local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Farrel PVB",
    SubTitle = "farrelgilaroblox",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Automation = Window:AddTab({ Title = "Automation", Icon = "shopping-cart" }),
    Movement   = Window:AddTab({ Title = "Movement",   Icon = "activity" }),
    Settings   = Window:AddTab({ Title = "Settings",  Icon = "settings" })
}

local Options = Fluent.Options

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")

local Player   = Players.LocalPlayer
local Humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") or Player.CharacterAdded:Wait():WaitForChild("Humanoid")

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local SeedsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")
local GearStocks  = require(ReplicatedStorage.Modules.Library.GearStocks)

-- === BRAINROT INVASION AUTO ===
local ImminentAttackTimer
local TimeLabel
local RequestStartInvasion
local brainrotRunning = false
local hasFiredThisWave = false

local function setupBrainrot()
    local success, err = pcall(function()
        ImminentAttackTimer = Player.PlayerGui:WaitForChild("Main"):WaitForChild("Right"):WaitForChild("ImminentAttackTimer")
        TimeLabel           = ImminentAttackTimer:WaitForChild("Main"):WaitForChild("Time")
        RequestStartInvasion = Remotes:WaitForChild("MissionServicesRemotes"):WaitForChild("RequestStartInvasion")
    end)
    
    if success then
        print("[Farrel PVB] Brainrot Invasion siap! Menunggu READY!")
    else
        warn("[Farrel PVB] Gagal setup Brainrot (mungkin belum masuk game):", err)
    end
    return success
end

local function startBrainrotLoop()
    if brainrotRunning then return end
    brainrotRunning = true
    
    spawn(function()
        while brainrotRunning and Options.AutoBrainrot.Value do
            task.wait(0.15)
            
            if not (ImminentAttackTimer and TimeLabel and RequestStartInvasion) then
                setupBrainrot()
            end
            
            if ImminentAttackTimer and ImminentAttackTimer.UIScale.Scale == 1 then
                if TimeLabel.Text == "READY!" then
                    if not hasFiredThisWave then
                        print("BRAINROT INVASION AUTO → READY! terdeteksi! Mulai wave...")
                        RequestStartInvasion:FireServer()
                        hasFiredThisWave = true
                    end
                else
                    if hasFiredThisWave then
                        hasFiredThisWave = false
                        print("Wave selesai → siap deteksi READY! lagi")
                    end
                end
            end
        end
    end)
end
-- ======================================

-- Get Seeds & Gears
local function GetAllSeeds()
    local temp = {}
    for _, seed in ipairs(SeedsFolder:GetChildren()) do
        if not seed:GetAttribute("Hidden") then
            table.insert(temp, {Name = seed.Name, Price = seed:GetAttribute("Price") or 999999})
        end
    end
    table.sort(temp, function(a,b) return a.Price < b.Price end)
    local names = {}
    for _, v in ipairs(temp) do table.insert(names, v.Name) end
    return names
end

local function GetAllGears()
    local list = {}
    for gear,_ in pairs(GearStocks) do table.insert(list, gear) end
    table.sort(list)
    return list
end

-- Buy Function
local function BuyAll(typeItem, selectedTable)
    local items = {}
    for name, enabled in pairs(selectedTable) do
        if enabled then table.insert(items, name) end
    end
    if #items == 0 then return end
    for _, name in ipairs(items) do
        if typeItem == "Seed" then
            Remotes.BuyItem:FireServer(name, true)
        elseif typeItem == "Gear" then
            Remotes.BuyGear:FireServer(name, true)
        end
        task.wait(0.01)
    end
end

-- Automation Tab
Tabs.Automation:AddSection("Shopping")

Tabs.Automation:AddDropdown("SelectSeed", {Title = "Select Seed (Multi)", Values = GetAllSeeds(), Multi = true, Default = {}})
Tabs.Automation:AddDropdown("SelectGear", {Title = "Select Gear (Multi)", Values = GetAllGears(), Multi = true, Default = {}})

Tabs.Automation:AddToggle("AutoBuySeed", {Title = "Auto Buy Selected Seed", Default = false,
    Callback = function(v)
        if v then spawn(function() while Options.AutoBuySeed.Value do BuyAll("Seed", Options.SelectSeed.Value) task.wait(0.01) end end) end
    end})

Tabs.Automation:AddToggle("AutoBuyGear", {Title = "Auto Buy Selected Gear", Default = false,
    Callback = function(v)
        if v then spawn(function() while Options.AutoBuyGear.Value do BuyAll("Gear", Options.SelectGear.Value) task.wait(0.01) end end) end
    end})

-- FITUR AUTO BRAINROT INVASION
Tabs.Automation:AddSection("Brainrot Invasion")

Tabs.Automation:AddToggle("AutoBrainrot", {
    Title = "Auto Brainrot Invasion (Setiap Wave)",
    Description = "Otomatis mulai invasion saat READY! muncul",
    Default = false,  -- DEFAULT MATI (sesuai permintaan)
    Callback = function(state)
        if state then
            setupBrainrot()
            startBrainrotLoop()
        else
            brainrotRunning = false
        end
    end
})

-- Movement Tab
Tabs.Movement:AddSection("Movement & Server")

Tabs.Movement:AddToggle("AntiAFK", {Title = "Anti AFK (Bisa AFK Selamanya)", Default = true,
    Callback = function(v)
        if v then
            Player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

Tabs.Movement:AddSlider("WalkSpeed", {Title = "Custom WalkSpeed", Min = 16, Max = 500, Default = 16, Rounding = 1,
    Callback = function(v) if Humanoid then Humanoid.WalkSpeed = v end end})

Tabs.Movement:AddButton({
    Title = "Rejoin Server Saat Ini",
    Description = "Masuk kembali ke server yang sama (Public & Private OK)",
    Callback = function()
        Fluent:Notify({Title = "Rejoin", Content = "Sedang masuk kembali ke server..."})
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, Player)
    end
})

-- Reset speed & brainrot setelah respawn
Player.CharacterAdded:Connect(function(char)
    task.wait(3)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and Options.WalkSpeed then hum.WalkSpeed = Options.WalkSpeed.Value end
    
    hasFiredThisWave = false
    if Options.AutoBrainrot and Options.AutoBrainrot.Value then
        setupBrainrot()
        startBrainrotLoop()
    end
end)

-- Save & Interface Manager
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FarrelPVB")
InterfaceManager:SetFolder("FarrelPVB")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

-- LOAD CONFIG DULU, BARU AKTIFKAN FITUR SESUAI CONFIG
SaveManager:LoadAutoloadConfig()

-- Anti-AFK langsung nyala (bisa dimatiin lewat toggle)
if Options.AntiAFK then
    Options.AntiAFK:SetValue(true)
end

-- Auto Brainrot: Hanya nyala kalau di config memang true (default = false)
task.spawn(function()
    task.wait(0.5) -- pastikan semua Options ke-load sempurna
    if Options.AutoBrainrot and Options.AutoBrainrot.Value then
        print("[Farrel PVB] Auto Brainrot Invasion dinyalakan dari config")
        setupBrainrot()
        startBrainrotLoop()
    else
        print("[Farrel PVB] Auto Brainrot Invasion dimatikan (sesuai config)")
        brainrotRunning = false
    end
end)
