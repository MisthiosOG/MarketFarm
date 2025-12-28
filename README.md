local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local plrs = game:GetService("Players")
local rsRun = game:GetService("RunService")

local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- Mengambil data dari file PetEggs yang kamu temukan di Dex
local PetEggModule = require(rs.Data.PetRegistry).PetEggs or require(rs:WaitForChild("Data"):WaitForChild("PetEggs"))

local labelCache = {}
local trackedEggs = {}

-- Fungsi untuk mengambil data WeightRange dan ItemOdd dari module
local function getPetStats(eggName, petName)
    local egg = PetEggModule[eggName]
    if egg and egg.RarityData and egg.RarityData.Items[petName] then
        local item = egg.RarityData.Items[petName]
        local weight = item.GeneratedPetData.WeightRange
        -- Mengembalikan format: W: Min-Max
        return string.format("Weight: %.1f - %.1f", weight[1], weight[2])
    end
    return "Weight: Unknown"
end

local function createLabel(model)
    if model:GetAttribute("OWNER") ~= lp.Name then return end

    local uuid = model:GetAttribute("OBJECT_UUID")
    local eggName = model:GetAttribute("EggName")
    if not uuid then return end

    local txt = Drawing.new("Text")
    txt.Size = 19
    txt.Color = Color3.new(1, 1, 0) -- Warna Kuning agar kontras
    txt.Outline = true
    txt.Center = true
    txt.Visible = false

    labelCache[uuid] = txt
    trackedEggs[uuid] = {model = model, egg = eggName}
end

-- Update teks saat server kasih tau isi petnya
local function refreshLabel(uuid, petName)
    local info = trackedEggs[uuid]
    if info and labelCache[uuid] then
        local weightInfo = getPetStats(info.egg, petName)
        labelCache[uuid].Text = string.format("%s\n%s\n[%s]", info.egg, petName, weightInfo)
        labelCache[uuid].Color = Color3.new(0, 1, 0) -- Berubah hijau saat isi diketahui
    end
end

local function removeLabel(model)
    local uuid = model:GetAttribute("OBJECT_UUID")
    if labelCache[uuid] then
        labelCache[uuid]:Remove()
        labelCache[uuid] = nil
    end
    trackedEggs[uuid] = nil
end

-- Hook Remote Event agar kita tahu isi pet sebelum menetas
local connections = getconnections(rs.GameEvents.EggReadyToHatch_RE.OnClientEvent)
if connections[1] then
    local original; original = hookfunction(connections[1].Function, newcclosure(function(uuid, petName)
        refreshLabel(uuid, petName)
        return original(uuid, petName)
    end))
end

-- Render loop untuk posisi teks
rsRun.RenderStepped:Connect(function()
    for uuid, data in trackedEggs do
        local model = data.model
        local lbl = labelCache[uuid]
        
        if lbl and model and model.Parent then
            local pos, visible = cam:WorldToViewportPoint(model:GetPivot().Position)
            if visible then
                lbl.Position = Vector2.new(pos.X, pos.Y - 60)
                lbl.Visible = true
            else
                lbl.Visible = false
            end
        elseif lbl then
            lbl.Visible = false
        end
    end
end)

-- Inisialisasi telur yang sudah ada
for _, inst in cs:GetTagged("PetEggServer") do
    task.spawn(createLabel, inst)
end

cs:GetInstanceAddedSignal("PetEggServer"):Connect(createLabel)
cs:GetInstanceRemovedSignal("PetEggServer"):Connect(removeLabel)
