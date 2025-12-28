-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/brNTY8nX8t)
-- Decompiled on 2025-12-28 14:55:45
-- Luau version 6, Types version 3
-- Time taken: 0.007601 seconds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService_upvr = game:GetService("TweenService")
local PetEggUI_upvr = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("PetUI"):WaitForChild("PetEggUI")
local CanvasGroup_upvr = PetEggUI_upvr:WaitForChild("CanvasGroup")
local tbl_upvr = {}
require(ReplicatedStorage.Modules.CreateTagHandler)({
	Tag = "PetEggLocalHitBox";
	OnInstanceAdded = function(arg1) -- Line 35, Named "OnInstanceAdded"
		--[[ Upvalues[1]:
			[1]: tbl_upvr (readonly)
		]]
		table.insert(tbl_upvr, arg1)
	end;
	OnInstanceRemoved = function(arg1) -- Line 38, Named "OnInstanceRemoved"
		--[[ Upvalues[1]:
			[1]: tbl_upvr (readonly)
		]]
		local table_find_result1 = table.find(tbl_upvr, arg1)
		if not table_find_result1 then
			return warn(`{arg1.Name} hitbox not tracked!`)
		end
		table.remove(tbl_upvr, table_find_result1)
	end;
})
local CurrentCamera_upvw = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- Line 49
	--[[ Upvalues[1]:
		[1]: CurrentCamera_upvw (read and write)
	]]
	CurrentCamera_upvw = workspace.CurrentCamera
end)
local var10_upvw
game:GetService("RunService").RenderStepped:Connect(function() -- Line 55
	--[[ Upvalues[3]:
		[1]: var10_upvw (read and write)
		[2]: CurrentCamera_upvw (read and write)
		[3]: PetEggUI_upvr (readonly)
	]]
	if not var10_upvw then
	else
		local any_WorldToScreenPoint_result1 = CurrentCamera_upvw:WorldToScreenPoint(var10_upvw:GetPivot().Position + Vector3.new(0, 0, 0))
		PetEggUI_upvr.Position = UDim2.new(0, any_WorldToScreenPoint_result1.X, 0, any_WorldToScreenPoint_result1.Y)
	end
end)
local PetEggs_upvr = require(ReplicatedStorage.Data.PetRegistry).PetEggs
local EggName_2_upvr = CanvasGroup_upvr:WaitForChild("EggName")
local TimeHelper_upvr = require(ReplicatedStorage.Modules.TimeHelper)
local EggHatchTime_upvr = CanvasGroup_upvr:WaitForChild("EggHatchTime")
local function UpdateRender_upvr() -- Line 61, Named "UpdateRender"
	--[[ Upvalues[6]:
		[1]: var10_upvw (read and write)
		[2]: PetEggs_upvr (readonly)
		[3]: TweenService_upvr (readonly)
		[4]: EggName_2_upvr (readonly)
		[5]: TimeHelper_upvr (readonly)
		[6]: EggHatchTime_upvr (readonly)
	]]
	local var17
	if not var10_upvw then
	else
		local PetEgg = var10_upvw:FindFirstAncestor("PetEgg")
		if not PetEgg then return end
		local EggName = PetEgg:GetAttribute("EggName")
		local TimeToHatch = PetEgg:GetAttribute("TimeToHatch")
		local GrowthMultiplier = PetEgg:GetAttribute("GrowthMultiplier")
		local var22 = GrowthMultiplier
		if var22 then
			if 0 >= GrowthMultiplier then
				var22 = false
			else
				var22 = true
			end
		end
		var17 = PetEggs_upvr
		var17 = TweenService_upvr
		local tbl = {
			TextColor3 = var17[EggName].Color;
		}
		var17 = var17:Create(EggName_2_upvr, TweenInfo.new(0.2), tbl):Play
		var17()
		if TimeToHatch == 0 then
			var17 = "Ready"
		else
			var17 = TimeHelper_upvr:GenerateColonFormatFromTime(TimeToHatch)
		end
		EggHatchTime_upvr.Text = var17
		EggName_2_upvr.Text = EggName
		if var22 and TimeToHatch ~= 0 then
			EggHatchTime_upvr.TextColor3 = Color3.new(0, 0.666667, 0)
			return
		end
		EggHatchTime_upvr.TextColor3 = Color3.new(1, 1, 1)
	end
end
local GetFarmAncestor_upvr = require(ReplicatedStorage.Modules.GetFarmAncestor)
task.spawn(function() -- Line 89
	--[[ Upvalues[6]:
		[1]: tbl_upvr (readonly)
		[2]: GetFarmAncestor_upvr (readonly)
		[3]: var10_upvw (read and write)
		[4]: UpdateRender_upvr (readonly)
		[5]: TweenService_upvr (readonly)
		[6]: CanvasGroup_upvr (readonly)
	]]
	-- KONSTANTERROR: [133] 98. Error Block 32 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [133] 98. Error Block 32 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [0] 1. Error Block 38 start (CF ANALYSIS FAILED)
	-- KONSTANTWARNING: Failed to evaluate expression, replaced with nil [133.3]
	-- KONSTANTERROR: [0] 1. Error Block 38 end (CF ANALYSIS FAILED)
end)
task.spawn(function() -- Line 141
	--[[ Upvalues[1]:
		[1]: UpdateRender_upvr (readonly)
	]]
	while true do
		task.wait(1)
		UpdateRender_upvr()
	end
end)
return {}
