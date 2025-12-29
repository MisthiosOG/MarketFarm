--[[
    NEBULA HUB | Misthios - ULTIMATE NOTIFICATION FIX (INTEGRATED)
    - AUTO-EXECUTE COMPATIBLE
    - PATCH: AUTO LOAD & AUTO RESUME ON SERVER HOP
    - FIX: TRADE SUBMIT DELAY SYNCHRONIZATION
    - PATCH: AUTO ADD PET MAX 12 (FIXED)
    - FIX: DOUBLE EXECUTE CAUSES ALL FEATURES OFF (STATE RESET ISSUE)
]]

local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    
    if ok then
        WindUI = result
    else 
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

if not WindUI then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "NEBULA HUB ERROR",
        Text = "WindUI gagal load! Gunakan Wave/Delta terbaru.",
        Duration = 20
    })
    return
end

-- [PATCH: PREVENT DOUBLE EXECUTION RESET]
if _G.NebulaHubLoaded then
    WindUI:Notify({ 
        Title = "NEBULA HUB", 
        Content = "Script sudah berjalan! Tidak perlu execute ulang.", 
        Duration = 8 
    })
    return
end
_G.NebulaHubLoaded = true

local http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game.Players
local lp = Players.LocalPlayer
local DataService = require(RS.Modules.DataService)

-- [PATCH: AGGRESSIVE NOTIFICATION HIDER INTEGRATION]
_G.HideNotifEnabled = false 

task.spawn(function()
    -- Method 1: Hooking (Untuk notif sistem standard)
    local success, NotificationModule = pcall(function()
        return require(lp.PlayerScripts:FindFirstChild("NotificationHandler", true) or 
                       lp.PlayerGui:FindFirstChild("Notification", true))
    end)

    if success and type(NotificationModule) == "table" and NotificationModule.CreateNotification then
        local oldNotificationFunc = NotificationModule.CreateNotification
        NotificationModule.CreateNotification = function(...)
            if _G.HideNotifEnabled then return nil end
            return oldNotificationFunc(...)
        end
    end

    -- Method 2: Brute Force (Untuk menghapus paksa "Please Wait" di layar)
    while task.wait(0.1) do
        if _G.HideNotifEnabled then
            pcall(function()
                local topNotif = lp.PlayerGui:FindFirstChild("Top_Notification")
                if topNotif and topNotif:FindFirstChild("Frame") then
                    for _, child in pairs(topNotif.Frame:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("GuiObject") then
                            child:Destroy()
                        end
                    end
                end
            end)
        end
    end
end)

WindUI:AddTheme({
    Name = "Cyber Midnight",
    Accent = Color3.fromHex("#7775F2"),
    Background = Color3.fromHex("#050505"),
    Outline = Color3.fromHex("#1A1A1A"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#444444"),
    Button = Color3.fromHex("#121212"),
    Icon = Color3.fromHex("#7775F2"),
    Hover = Color3.fromHex("#FFFFFF"),
    WindowBackground = Color3.fromHex("#050505"),
    WindowShadow = Color3.fromHex("#000000"),
    TabTitle = Color3.fromHex("#FFFFFF"),
    ElementBackground = Color3.fromHex("#0A0A0A"),
    Toggle = Color3.fromHex("#7775F2"),
    ToggleBar = Color3.fromHex("#FFFFFF"),
})

local Config = {
    TargetPetName = "", 
    ListingPrice = 100,
    MaxPetWeight = 2.0,
    TargetPetAmount = 1,
    SubmitDelay = 6.0,
    LoopDelay = 10.0,
    AutoListingLoop = false,
    BlacklistedUUIDs = {},

    TradeTargetPetName = "",
    TradeMaxPetWeight = 2.0,
    TradePetAmount = 12,
    TradeSubmitDelay = 0.15,
    AutoAcceptTrade = false,
    AutoAcceptRequest = false,
    AutoAddPetLoop = false,
    IsTradeProcessing = false,

    WebhookURL = "",
    DiscordMentionID = "",
    AntiAFK = true,
    StartTime = os.time(),

    PetPickupDelaySec = 0.7,
    autoResetSkillEnabled = false,

    ServerHopDelayHours = 0,
    AutoServerHopEnabled = false,
    
    AutoClaimBooth = false,

    AutoFavLoopEnabled = false,
    HideGameNotif = false,
    FavKeywords = {"Tranquil", "Choc", "Luminous", "Pollinated", "Glimmering", "AncientAmber", "Alienlike", "Slashbound", "Gourmet", "Oil", "Bone Blossom"},
    
    AutoSaveEnabled = true,
    AutoSaveIntervalSeconds = 1
}

local Stats = { Sold = 0, Gems = 0, CurrentlyListed = 0, CurrentTokens = 0, Status = "Idle" }

-- [PATCH: IMPROVED ANTI-FULL SERVER HOP DENGAN PROXY]
local function RandomServerHop()
    WindUI:Notify({ Title = "SERVER HOP", Content = "Mencari server via Proxy...", Duration = 5 })
    
    local sfUrl = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=50"
    local servers = {}
    
    local success, raw = pcall(function() return game:HttpGet(sfUrl) end)
    
    if success and raw then
        local decoded = http:JSONDecode(raw)
        if decoded and decoded.data then
            for _, v in pairs(decoded.data) do
                if v.playing and v.playing < (v.maxPlayers - 3) and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
    end

    if #servers > 0 then
        local target = servers[math.random(1, #servers)]
        
        local teleportConn
        teleportConn = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
            if player == lp then
                WindUI:Notify({ Title = "HOP FAILED", Content = "Mencoba server lain...", Duration = 3 })
                teleportConn:Disconnect()
                RandomServerHop()
            end
        end)

        WindUI:Notify({ Title = "TELEPORTING", Content = "Memasuki server baru...", Duration = 3 })
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target, lp)
    else
        WindUI:Notify({ Title = "SERVER HOP", Content = "Gagal via Proxy, mencoba standard...", Duration = 5 })
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, lp)
    end
end

local function SafeInvoke(remote, ...)
    if not remote then return nil end
    local success, result = pcall(remote.InvokeServer, remote, ...)
    return success and result
end

local function SafeFire(remote, ...)
    if not remote then return end
    pcall(remote.FireServer, remote, ...)
end

local function SendWebhook(embedTable, extraContent)
    if Config.WebhookURL == "" then return end
    local req = http_request or syn and syn.request or request or HttpPost
    if not req then return end

    local content = nil
    if Config.DiscordMentionID ~= "" then
        content = "<@" .. Config.DiscordMentionID .. ">" .. (extraContent or "")
    elseif extraContent then
        content = extraContent
    end

    local payload = {
        username = "NEBULA HUB | Misthios",
        content = content,
        embeds = embedTable
    }

    task.spawn(function()
        pcall(function()
            req({
                Url = Config.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = http:JSONEncode(payload)
            })
        end)
    end)
end

local Window = WindUI:CreateWindow({
    Title = "NEBULA HUB | Misthios",
    SubTitle = "ipowfu verified",
    Author = "Misthios",
    Theme = "Cyber Midnight",
    Icon = "solar:moon-bold",
    Folder = "NebulaHub",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Nebula Hub",
        CornerRadius = UDim.new(1,0),
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#7775F2"), Color3.fromHex("#30ff6a"))
    },
    Topbar = { Height = 44, ButtonsType = "Windows" },
    KeySystem = {
        Note = "Get Key at pandadevelopment.net | Service: misthios666",
        ButtonText = "Get Key",
        API = { { Type = "pandadevelopment", ServiceId = "misthios666" } }
    }
})

if not Window then 
    WindUI:Notify({ Title = "NEBULA HUB", Content = "Key verification failed!", Duration = 15 })
    return 
end

task.wait(0.2)
WindUI:Notify({ Title = "NEBULA HUB", Content = "Loaded successfully!", Duration = 8, Icon = "solar:moon-bold" })
Window:Tag({ Title = "iPowfu", Icon = "solar:verified-check-bold", Color = Color3.fromHex("#30ff6a"), Radius = 8 })
Window:Tag({ Title = "v19.7.1 FIXED", Icon = "github", Color = Color3.fromHex("#7775F2"), Radius = 8 })

SendWebhook({{
    title = "🚀 NEBULA HUB LOADED",
    description = "**User:** " .. lp.Name .. " (" .. lp.UserId .. ")",
    color = tonumber("7775F2", 16),
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    footer = { text = "Nebula Hub | Misthios" }
}}, " Script aktif!")

-- Tabs
local DashboardTab = Window:Tab({ Title = "Dashboard", Icon = "solar:chart-bold", IconColor = Color3.fromHex("#AF52DE"), IconShape = "Square", Border = true })
local ScannerTab   = Window:Tab({ Title = "Scanner",   Icon = "solar:scanner-bold", IconColor = Color3.fromHex("#007AFF"), IconShape = "Square", Border = true })
local TradeTab     = Window:Tab({ Title = "Trade",     Icon = "solar:hand-shake-bold", IconColor = Color3.fromHex("#30ff6a"), IconShape = "Square", Border = true })
local PerksTab     = Window:Tab({ Title = "AFK Perks", Icon = "solar:ghost-bold", IconColor = Color3.fromHex("#FF3B30"), IconShape = "Square", Border = true })
local MiscTab      = Window:Tab({ Title = "Misc",      Icon = "solar:gallery-wide-bold", IconColor = Color3.fromHex("#FFD700"), IconShape = "Square", Border = true })
local SettingsTab  = Window:Tab({ Title = "Settings",  Icon = "solar:settings-bold", IconColor = Color3.fromHex("#8E8E93"), IconShape = "Square", Border = true })
local ConfigTab    = Window:Tab({ Title = "Config Usage", Icon = "solar:folder-with-files-bold", IconColor = Color3.fromHex("#7775F2"), IconShape = "Square", Border = true })

-- Dashboard
local DashSec = DashboardTab:Section({ Title = "System Monitor" })
local StatusBtn = DashSec:Button({ Title = "Status: Idle", Color = Color3.fromHex("#305dff") })
local TokenBtn  = DashSec:Button({ Title = "Wallet: Loading...", Color = Color3.fromHex("#305dff") })
local BoothBtn  = DashSec:Button({ Title = "Booth: 0/50 Items", Color = Color3.fromHex("#305dff") })
local ProfitBtn = DashSec:Button({ Title = "Session Profit: 0 Tokens", Color = Color3.fromHex("#305dff") })
local UptimeBtn = DashSec:Button({ Title = "Uptime: 0h 0m", Color = Color3.fromHex("#305dff") })

-- Dashboard Update Loop
task.spawn(function()
    local function updateTokens()
        pcall(function()
            local data = DataService:GetData()
            if data and data.TradeData then
                Stats.CurrentTokens = data.TradeData.Tokens
                TokenBtn:SetTitle("Wallet: " .. string.format("%.0f", Stats.CurrentTokens) .. " Tokens")
            end
        end)
    end
    DataService:GetPathSignal("TradeData/Tokens"):Connect(updateTokens)
    updateTokens()

    while task.wait(1) do
        local diff = os.difftime(os.time(), Config.StartTime)
        local h, m = math.floor(diff / 3600), math.floor((diff % 3600) / 60)
        UptimeBtn:SetTitle("Uptime: " .. string.format("%dh %dm", h, m))
        StatusBtn:SetTitle("Status: " .. Stats.Status)

        local count = 0
        local bGui = lp.PlayerGui:FindFirstChild("TradeBooth") or lp.PlayerGui:FindFirstChild("Booth")
        if bGui then
            local scrolling = bGui:FindFirstChild("ScrollingFrame") or bGui:FindFirstChild("List")
            if scrolling then
                for _, child in pairs(scrolling:GetChildren()) do
                    if child:IsA("Frame") and child.Name ~= "Add" and child.Visible then
                        if child:FindFirstChild("Price") or child:FindFirstChild("ItemFrame") or child:FindFirstChild("Item") then
                            count += 1
                        end
                    end
                end
            end
        end

        Stats.CurrentlyListed = count
        BoothBtn:SetTitle("Booth: " .. count .. "/50 Items")
    end
end)

-- Scanner Tab + Auto Listing Function
function StartRhythmScan()
    Stats.Status = "Initializing..."
    WindUI:Notify({ Title = "Scanner", Content = "Mencari remote CreateListing...", Duration = 6 })

    task.spawn(function()
        local CreateListingRemote = nil
        pcall(function()
            for _, obj in pairs(RS:GetDescendants()) do
                if obj.Name == "CreateListing" and obj:IsA("RemoteFunction") then
                    CreateListingRemote = obj
                    break
                end
            end
        end)

        if not CreateListingRemote then
            WindUI:Notify({ Title = "ERROR", Content = "Remote tidak ditemukan!", Duration = 15 })
            Stats.Status = "Remote Error"
            return
        end

        while Config.AutoListingLoop do
            if Stats.CurrentlyListed >= 50 then
                Stats.Status = "Booth Full"
                repeat task.wait(5) until Stats.CurrentlyListed < 50 or not Config.AutoListingLoop
                if not Config.AutoListingLoop then break end
            end

            Stats.Status = "Listing Pets"
            local bp = lp:FindFirstChild("Backpack")
            local listedThisCycle = 0

            if bp then
                for _, item in pairs(bp:GetChildren()) do
                    if not Config.AutoListingLoop or listedThisCycle >= Config.TargetPetAmount then break end
                    local itemNameLower = item.Name:lower()
                    local uuid = item:GetAttribute("PET_UUID")
                    if uuid and (Config.TargetPetName == "" or itemNameLower:find(Config.TargetPetName:lower())) then
                        local weight = tonumber(string.match(item.Name, "%d+%.?%d*")) or 0
                        if weight <= Config.MaxPetWeight and not Config.BlacklistedUUIDs[uuid] then
                            local result = SafeInvoke(CreateListingRemote, "Pet", uuid, Config.ListingPrice)
                            if result then
                                Config.BlacklistedUUIDs[uuid] = true
                                listedThisCycle += 1
                                Stats.CurrentlyListed += 1
                                WindUI:Notify({ Title = "SUCCESS", Content = "Listed " .. item.Name, Duration = 6 })
                            end
                            task.wait(Config.SubmitDelay)
                        end
                    end
                end
            end
            task.wait(Config.LoopDelay)
        end
        Stats.Status = "Idle"
    end)
end

-- [PATCH: LOGIKA AUTO FAV-UNFAV LOOPING]
local function RunAggressiveFavLoop()
    local bp = lp:FindFirstChild("Backpack")
    if not bp then return end
    local favRemote = RS:WaitForChild("GameEvents"):WaitForChild("Favorite_Item")
    
    for _, item in pairs(bp:GetChildren()) do
        if not Config.AutoFavLoopEnabled then break end
        
        local isSpecial = false
        for _, keyword in pairs(Config.FavKeywords) do
            if item.Name:find(keyword) then
                isSpecial = true
                break
            end
        end
        
        if isSpecial then
            task.spawn(function()
                while item and item.Parent == bp and Config.AutoFavLoopEnabled do
                    pcall(function() favRemote:FireServer(item, true) end)
                    task.wait(0.2)
                    pcall(function() favRemote:FireServer(item, false) end)
                    task.wait(0.2)
                end
            end)
            
            task.spawn(function()
                while item and item.Parent == bp and Config.AutoFavLoopEnabled do
                    if #item.Name > 12 then
                        item.Name = "⭐ Special"
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
end

local ScannerSec = ScannerTab:Section({ Title = "Auto Listing Configuration" })
ScannerSec:Input({ Flag = "TargetPetName", Title = "Target Pet Name", Placeholder = "e.g. huge", Callback = function(v) Config.TargetPetName = v end })
ScannerSec:Input({ Flag = "ListingPrice", Title = "Listing Price", Value = "100", Callback = function(v) Config.ListingPrice = tonumber(v) or 100 end })
ScannerSec:Input({ Flag = "MaxPetWeight", Title = "Max Pet Weight (KG)", Value = "2.0", Callback = function(v) Config.MaxPetWeight = tonumber(v) or 2.0 end })
ScannerSec:Input({ Flag = "TargetPetAmount", Title = "Pets Per Cycle", Value = "1", Callback = function(v) Config.TargetPetAmount = tonumber(v) or 1 end })
ScannerSec:Input({ Flag = "SubmitDelay", Title = "Submit Delay (s)", Value = "6.0", Callback = function(v) Config.SubmitDelay = tonumber(v) or 6.0 end })
ScannerSec:Input({ Flag = "LoopDelay", Title = "Cycle Delay (s)", Value = "10.0", Callback = function(v) Config.LoopDelay = tonumber(v) or 10.0 end })
ScannerSec:Toggle({ Flag = "AutoListingLoop", Title = "Auto Listing Loop", Value = false, Callback = function(v) Config.AutoListingLoop = v if v then StartRhythmScan() end end })

-- [PATCH: SMART AUTO CLAIM BOOTH]
ScannerSec:Toggle({ Flag = "AutoClaimBooth", Title = "Auto Claim Empty Booth", Value = false, Callback = function(v) Config.AutoClaimBooth = v end })

task.spawn(function()
    local ClaimRemote = RS:WaitForChild("GameEvents"):WaitForChild("TradeEvents"):WaitForChild("Booths"):WaitForChild("ClaimBooth")
    
    while task.wait(1) do 
        if Config.AutoClaimBooth then
            local myId = lp.UserId
            local myIdStr = "Player_" .. myId
            local hasBooth = false
            
            local boothFolder = workspace:FindFirstChild("TradeWorld") and workspace.TradeWorld:FindFirstChild("Booths")
            if boothFolder then
                for _, b in pairs(boothFolder:GetChildren()) do
                    local owner = b:GetAttribute("Owner")
                    if owner == myId or owner == myIdStr then
                        hasBooth = true
                        break
                    end
                end

                if not hasBooth then
                    for _, b in pairs(boothFolder:GetChildren()) do
                        local owner = b:GetAttribute("Owner")
                        if owner == nil or owner == 0 or owner == "" then
                            WindUI:Notify({ Title = "BOOTH", Content = "Mengklaim booth kosong...", Duration = 2 })
                            ClaimRemote:FireServer(b)
                            Config.AutoClaimBooth = false
                            ScannerTab:SetFlag("AutoClaimBooth", false) 
                            break 
                        end
                    end
                else
                    Config.AutoClaimBooth = false
                    ScannerTab:SetFlag("AutoClaimBooth", false)
                end
            end
        end
    end
end)

-- Trade Tab
local WorldSec = TradeTab:Section({ Title = "World Travel" })
WorldSec:Button({ Title = "Teleport to Trade World", Color = Color3.fromHex("#305dff"), Callback = function() RS.GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end })

local TradeReqSec = TradeTab:Section({ Title = "Incoming Trade" })
TradeReqSec:Toggle({ Flag = "AutoAcceptRequest", Title = "Auto Accept Request", Value = false, Callback = function(v) Config.AutoAcceptRequest = v end })

local TradeSubSec = TradeTab:Section({ Title = "Auto Trade Submitter" })
TradeSubSec:Input({ Flag = "TradeTargetPetName", Title = "Target Pet Name", Callback = function(v) Config.TradeTargetPetName = v end })
TradeSubSec:Input({ Flag = "TradeMaxPetWeight", Title = "Max Pet Weight", Value = "2.0", Callback = function(v) Config.TradeMaxPetWeight = tonumber(v) or 2.0 end })
TradeSubSec:Input({ Flag = "TradePetAmount", Title = "Pets Per Cycle (max 12)", Value = "12", Callback = function(v) Config.TradePetAmount = math.clamp(tonumber(v) or 12, 1, 12) end })
TradeSubSec:Input({ Flag = "TradeSubmitDelay", Title = "Delay Per Pet (s)", Value = "0.15", Callback = function(v) Config.TradeSubmitDelay = tonumber(v) or 0.15 end })
TradeSubSec:Toggle({ Flag = "AutoAcceptTrade", Title = "Auto Accept Trade", Value = false, Callback = function(v) Config.AutoAcceptTrade = v end })
TradeSubSec:Toggle({ Flag = "AutoAddPetLoop", Title = "Auto Add Pet Loop", Value = false, Callback = function(v) Config.AutoAddPetLoop = v end })

-- [PATCH: TRADE ADD PET FIX - REPEAT UNTIL MAX OR NO MORE PETS]
task.spawn(function()
    local TradeEvents = RS.GameEvents.TradeEvents
    local TradingController = require(RS.Modules.TradeControllers.TradingController)

    TradeEvents.SendRequest.OnClientEvent:Connect(function(id)
        if Config.AutoAcceptRequest then
            task.wait(0.3)
            SafeFire(TradeEvents.RespondRequest, id, true)
            WindUI:Notify({ Title = "Trade", Content = "Accepted request!", Duration = 5 })
        end
    end)

    while task.wait(0.1) do
        local bp = lp:FindFirstChild("Backpack")

        if Config.AutoAddPetLoop and bp and Config.TradeTargetPetName ~= "" and not Config.IsTradeProcessing and TradingController.CurrentTradeReplicator then
            Config.IsTradeProcessing = true
            local added = 0
            local eligiblePets = {}

            for _, item in pairs(bp:GetChildren()) do
                if item.Name:lower():find(Config.TradeTargetPetName:lower()) then
                    local uuid = item:GetAttribute("PET_UUID")
                    local weight = tonumber(string.match(item.Name, "%d+%.?%d*")) or 0
                    if uuid and weight <= Config.TradeMaxPetWeight then
                        table.insert(eligiblePets, {item = item, uuid = uuid})
                    end
                end
            end

            for _, petData in ipairs(eligiblePets) do
                if not Config.AutoAddPetLoop or added >= Config.TradePetAmount then break end
                SafeFire(TradeEvents.AddItem, "Pet", tostring(petData.uuid))
                added += 1
                task.wait(Config.TradeSubmitDelay)
            end

            Config.IsTradeProcessing = false
        end

        if Config.AutoAcceptTrade then
            pcall(function()
                if TradingController.CurrentTradeReplicator then
                    local data = TradingController.CurrentTradeReplicator:GetData()
                    if data then
                        local myIndex = table.find(data.players, lp)
                        if myIndex then
                            local myState = data.states[myIndex]
                            if myState == "None" or myState == "Declined" then
                                TradingController:Accept()
                            elseif myState == "Accepted" then
                                TradingController:Confirm()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- AFK Perks
local PerksSec = PerksTab:Section({ Title = "Elite Protection" })
PerksSec:Toggle({ Flag = "AntiAFK", Title = "Anti-AFK", Value = true, Callback = function(v) Config.AntiAFK = v end })
PerksSec:Button({ Title = "Server Hop", Color = Color3.fromHex("#305dff"), CornerRadius = UDim.new(1,0), Callback = RandomServerHop })

-- [PATCH: MISC TOGGLES]
local MiscSec = MiscTab:Section({ Title = "Item Management" })
MiscSec:Toggle({ Flag = "AutoFavToggle", Title = "Auto Fav-Unfav Looping", Value = false, Callback = function(v) Config.AutoFavLoopEnabled = v end })
MiscSec:Toggle({ Flag = "HideNotifToggle", Title = "Hide In-Game Notifications", Value = false, Callback = function(v) _G.HideNotifEnabled = v end })
MiscSec:Toggle({ Flag = "autoResetSkillEnabled", Title = "Auto Reset Skill", Value = false, Callback = function(v) Config.autoResetSkillEnabled = v end })
MiscSec:Input({ Flag = "PetPickupDelaySec", Title = "Pickup Delay (s)", Value = "0.7", Callback = function(v) Config.PetPickupDelaySec = tonumber(v) or 0.7 end })

-- Settings
local SettingsSec = SettingsTab:Section({ Title = "Webhook Settings" })
SettingsSec:Input({ Flag = "WebhookURL", Title = "Webhook URL", Callback = function(v) Config.WebhookURL = v end })
SettingsSec:Input({ Flag = "DiscordMentionID", Title = "Discord Mention ID", Callback = function(v) Config.DiscordMentionID = v:gsub("%D", "") end })

SettingsSec:Button({ 
    Title = "Test Webhook", 
    Color = Color3.fromHex("#0A0A0A"), 
    Callback = function()
        if Config.WebhookURL ~= "" then
            SendWebhook({{ title = "🧪 WEBHOOK TEST", description = "Test dari **" .. lp.Name .. "**", color = tonumber("7775F2", 16) }}, "Test!")
            WindUI:Notify({ Title = "Webhook", Content = "Test dikirim!", Duration = 5 })
        else
            WindUI:Notify({ Title = "Webhook", Content = "URL belum diisi!", Duration = 5 })
        end
    end 
})

-- Server Hop Settings
local HopSec = SettingsTab:Section({ Title = "Auto Server Hop" })
HopSec:Input({ Flag = "ServerHopDelayHours", Title = "Hop Every (Hours)", Placeholder = "e.g. 1", Value = "0", Callback = function(v) Config.ServerHopDelayHours = tonumber(v) or 0 end })
HopSec:Toggle({ Flag = "AutoServerHopEnabled", Title = "Enable Auto Hop", Value = false, Callback = function(v) Config.AutoServerHopEnabled = v end })

HopSec:Button({ 
    Title = "Force Server Hop Now", 
    Color = Color3.fromHex("#0A0A0A"), 
    Callback = function() 
        RandomServerHop()
    end 
})

task.spawn(function()
    while task.wait(60) do 
        if Config.AutoServerHopEnabled and Config.ServerHopDelayHours > 0 then
            local elapsed = os.difftime(os.time(), Config.StartTime)
            if elapsed >= (Config.ServerHopDelayHours * 3600) then
                RandomServerHop()
            end
        end
    end
end)

-- Config Usage Tab
local ConfigManager = Window.ConfigManager
local ConfigName = "default"
local ConfigNameInput = ConfigTab:Input({ Title = "Config Name", Icon = "file-cog", Callback = function(v) ConfigName = v end })
ConfigTab:Space()
local AllConfigs = ConfigManager:AllConfigs()
local AllConfigsDropdown = ConfigTab:Dropdown({ Title = "All Configs", Values = AllConfigs, Callback = function(v) ConfigName = v ConfigNameInput:Set(v) end })
ConfigTab:Space()
ConfigTab:Button({ Title = "Save Config", Color = Color3.fromHex("#305dff"), Callback = function() Window.CurrentConfig = ConfigManager:Config(ConfigName) Window.CurrentConfig:Save() WindUI:Notify({ Title = "Saved", Content = "Config saved!" }) AllConfigsDropdown:Refresh(ConfigManager:AllConfigs()) end })
ConfigTab:Space()
ConfigTab:Button({ Title = "Load Config", Color = Color3.fromHex("#305dff"), Callback = function() Window.CurrentConfig = ConfigManager:Config(ConfigName) Window.CurrentConfig:Load() WindUI:Notify({ Title = "Loaded", Content = "Config loaded!" }) end })

-- [PATCH: AUTO SAVE SYSTEM - UPGRADED TO PER SECOND]
local AutoSaveSec = SettingsTab:Section({ Title = "Auto Save Config" })
AutoSaveSec:Toggle({ 
    Flag = "AutoSaveEnabled", 
    Title = "Enable Auto Save", 
    Value = true, 
    Callback = function(v) 
        Config.AutoSaveEnabled = v 
    end 
})
AutoSaveSec:Input({ 
    Flag = "AutoSaveInterval", 
    Title = "Auto Save Every (Seconds)", 
    Value = "1", 
    Placeholder = "Min: 1",
    Callback = function(v) 
        local num = tonumber(v) or 1
        Config.AutoSaveIntervalSeconds = math.max(1, num)
    end 
})

task.spawn(function()
    local currentConfigObj = ConfigManager:Config(ConfigName)
    
    while task.wait(Config.AutoSaveIntervalSeconds) do
        if Config.AutoSaveEnabled and currentConfigObj then
            pcall(function()
                currentConfigObj:Save()
                if Config.AutoSaveIntervalSeconds >= 10 then
                    WindUI:Notify({ 
                        Title = "AUTO SAVE", 
                        Content = "Config '" .. ConfigName .. "' otomatis disimpan!", 
                        Duration = 3 
                    })
                end
            end)
        end
    end
end)

-- Sale Detection
local function HandleSaleEvent(data)
    if not data or not data.seller or data.seller.userId ~= lp.UserId then return end
    Stats.Sold += 1
    Stats.Gems += data.price or 0
    ProfitBtn:SetTitle("Session Profit: " .. Stats.Gems .. " Tokens")
    SendWebhook({{ title = "💎 SALE!", description = "Sold for " .. (data.price or 0) .. " Tokens!" }}, "SALE!")
end
pcall(function() RS.GameEvents.TradeEvents.Booths.AddToHistory.OnClientEvent:Connect(HandleSaleEvent) end)

-- Anti-AFK
task.spawn(function()
    while task.wait(10) do
        if Config.AntiAFK then
            pcall(function() game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
        end
    end
end)

-- [PATCH: FAV LOOP SYSTEM]
task.spawn(function()
    while true do
        if Config.AutoFavLoopEnabled then
            RunAggressiveFavLoop()
        end
        task.wait(1)
    end
end)

-- [PATCH: AUTO LOAD & AUTO RUN ON STARTUP - DIPINDAH KE BAWAH AGAR TIDAK DOUBLE]
task.spawn(function()
    task.wait(3) 
    pcall(function()
        local target = "default"
        local configObj = ConfigManager:Config(target)
        if configObj then
            configObj:Load()
            WindUI:Notify({ 
                Title = "AUTO RESUME", 
                Content = "Config '" .. target .. "' berhasil di-load otomatis!", 
                Duration = 6 
            })
            
            -- Resume fitur yang sebelumnya aktif
            if Config.AutoListingLoop then
                StartRhythmScan()
            end
        end
    end)
end)
