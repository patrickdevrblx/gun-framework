local GunHandler = require(game.ServerStorage.GunHandler)
local GunEvent = game.ReplicatedStorage.GunEvent
local UpdateEvent = game.ReplicatedStorage.UpdateEvent

local GunMap: {[Tool]: GunHandler.GunInstance} = {}

local Players = game:GetService("Players")

function InitTool(Tool: Tool)
	if GunMap[Tool] then return end
	
	local GunConfig = Tool:FindFirstChild("GunConfig")
	if not GunConfig or not GunConfig:IsA("ModuleScript") then return end
	
	local GunInstance: GunHandler.GunInstance = GunHandler.new(require(GunConfig))
	GunMap[Tool] = GunInstance
	
	-- store data that will be used on the client
	Tool:SetAttribute("Ammo", GunInstance.Ammo)
	Tool:SetAttribute("MagSize", GunInstance.MagSize)
	Tool:SetAttribute("FireRate", GunInstance.Config.FIRE_RATE)
	Tool:SetAttribute("Damage", GunInstance.Damage)
	Tool:SetAttribute("Reloading", false)
	Tool:SetAttribute("ReloadTime", GunInstance.ReloadTime)
	Tool:SetAttribute("Automatic", GunInstance.Config.AUTOMATIC)
	
	Tool.Destroying:Connect(function()
		GunMap[Tool] = nil -- remove from map to free memory
	end)
end

Players.PlayerAdded:Connect(function(Player) -- player added tool listener
	if not Player.Character then
		Player.CharacterAdded:Wait()
	end
	
	local Backpack = Player:WaitForChild("Backpack")
	
	Backpack.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") then
			InitTool(Tool)
		end
	end)
	
	for _, Tool in Backpack:GetChildren() do
		InitTool(Tool)
	end
end)

for _, Player in ipairs(Players:GetPlayers()) do
	local Tools = Player.Backpack:GetChildren()
	
	if Player.Character then
		local Tool = Player.Character:FindFirstChildWhichIsA("Tool")
		if Tool then
			table.insert(Tools, Tool)
		end
	end

	for _, Tool in ipairs(Tools) do
		if Tool:IsA("Tool") then
			InitTool(Tool)
		end
	end
end

GunEvent.OnServerEvent:Connect(function(Player, Action, ...)
	local Character = Player.Character
	if not Character then return end
	
	local GunTool = Character:FindFirstChildWhichIsA("Tool")
	if not GunTool then return end
	
	local GunInstance: GunHandler.GunInstance = GunMap[GunTool]
	if not GunInstance then return end
	
	if Action == "Fire" then
		local Origin, Direction = ...
		
		local Handle: Part = GunTool and GunTool:FindFirstChild("Handle")
		if not Handle then return end
		
		local OriginDistance = (Handle.Position - Origin).Magnitude
		if OriginDistance > 10 then return end -- check if origin is near enough to the tool handle
		
		GunInstance:Fire(Origin, Direction, {Character})
		GunTool:SetAttribute("Ammo", GunInstance.Ammo)
		
		if not GunInstance.Reloading then
			UpdateEvent:FireClient(Player, "ammo", GunInstance.Ammo)
		end
		
	elseif Action == "Reload" then
		if GunInstance.Ammo < GunInstance.MagSize and not GunInstance.Reloading then
			UpdateEvent:FireClient(Player, "reload")
			GunInstance:Reload()
			GunTool:SetAttribute("Ammo", GunInstance.Ammo)
		end
	end
end)
