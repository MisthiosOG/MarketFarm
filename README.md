local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

-- Load Data dari Module (PetEggs)
local PetEggData
local success, err = pcall(function()
    -- Mencoba beberapa kemungkinan nama file di ReplicatedStorage
    return require(rs.Data.PetRegistry).PetEggs or require(rs.Data.PetEggs)
end)
if success then PetEggData = err end

local function createESP(model)
    -- Cek OWNER (Pastikan namamu sama dengan attribute OWNER di telur)
    if model:GetAttribute("OWNER") ~= lp.Name then return end
    
    if model:FindFirstChild("EggESP") then model.EggESP:Destroy() end

    local eggName = model:GetAttribute("EggName") or "Telur"
    local uuid = model:GetAttribute("OBJECT_UUID")
    
    local bgui = Instance.new("BillboardGui")
    bgui.Name = "EggESP"
    bgui.Adornee = model
    bgui.Size = UDim2.new(0, 200, 0, 100)
    bgui.StudsOffset = Vector3.new(0, 3, 0)
    bgui.AlwaysOnTop = true
    
    local tl = Instance.new("TextLabel")
    tl.Parent = bgui
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Text = string.format("[%s]\nBelum Ready", eggName)
    tl.TextColor3 = Color3.new(1, 1, 1) -- Putih saat belum ready
    tl.TextStrokeTransparency = 0
    tl.TextSize = 15
    tl.Font = Enum.Font.SourceSansBold
    
    bgui.Parent = model

    -- Fungsi untuk merubah teks saat data pet datang
    local function updateData(targetUuid, petName)
        if uuid == targetUuid then
            local weightStr = "Weight: 0.8-2.0" -- Default dari file kamu
            
            -- Ambil data spesifik jika ada di module
            if PetEggData and PetEggData[eggName] then
                local items = PetEggData[eggName].RarityData.Items
                if items[petName] then
                    local w = items[petName].GeneratedPetData.WeightRange
                    weightStr = string.format("Weight: %.1f - %.1f", w[1], w[2])
                end
            end
            
            tl.Text = string.format("%s\n%s\n[%s]", eggName, petName, weightStr)
            tl.TextColor3 = Color3.new(0, 1, 0) -- Berubah HIJAU saat isi ketahuan
            print("Berhasil mendeteksi isi telur: " .. petName)
        end
    end

    -- Konek ke Remote Event (Gunakan pcall biar gak error kalau remote ganti nama)
    local event
    pcall(function()
        event = rs.GameEvents.EggReadyToHatch_RE.OnClientEvent:Connect(updateData)
    end)
    
    model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(workspace) and event then
            event:Disconnect()
        end
    end)
end

-- Scan Telur yang sudah ada
for _, inst in pairs(cs:GetTagged("PetEggServer")) do
    task.spawn(createESP, inst)
end

-- Pantau Telur baru yang muncul
cs:GetInstanceAddedSignal("PetEggServer"):Connect(createESP)

print("ESP Aktif! Tunggu sampai telur kamu 'READY' untuk melihat isi pet.")
