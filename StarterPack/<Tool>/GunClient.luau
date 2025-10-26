local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")

local GunEvent = game.ReplicatedStorage:WaitForChild("GunEvent")
local UpdateEvent = game.ReplicatedStorage:WaitForChild("UpdateEvent")

local IsEquipped = false
local CanFire = true

local Gui
local AmmoLabel

Tool.Equipped:Connect(function()
	IsEquipped = true
	
	Gui = Tool.GunGui:Clone()
	Gui.Parent = Player.PlayerGui
	AmmoLabel = Gui:WaitForChild("AmmoLabel")
end)

Tool.Unequipped:Connect(function()
	IsEquipped = false
	
	if Gui then
		Gui:Destroy()
		Gui = nil
		AmmoLabel = nil
	end
end)

local function FireOnce()
	if Tool:GetAttribute("Ammo") < 1 then
		GunEvent:FireServer("Reload")
		task.wait(Tool:GetAttribute("ReloadTime"))
		return
	end
	
	if not CanFire or not Handle then return end
	
	local Origin = Handle.Position
	local HitPos = Mouse.Hit.Position
	
	if HitPos then
		GunEvent:FireServer("Fire", Origin, HitPos)
	end
end

local FireThread
local IsFiring = false

local function FireAuto()
	IsFiring = true
	if FireThread then return end
	local FireInterval = 1 / Tool:GetAttribute("FireRate")
	
	FireThread = coroutine.create(function()
		while IsFiring do
			FireOnce()
			task.wait(FireInterval)
		end
		print("Stopped firing")
		FireThread = nil
		IsFiring = false
	end)
	
	coroutine.resume(FireThread)
end

Mouse.Button1Down:Connect(function()
	if not IsEquipped or not CanFire then return end
	
	local AutomaticFire = Tool:GetAttribute("Automatic")
	
	if AutomaticFire then
		FireAuto()
	else
		FireOnce()
	end
end)

Mouse.Button1Up:Connect(function()
	IsFiring = false
end)

UpdateEvent.OnClientEvent:Connect(function(subject, ...)
	if subject == "reload" then
		if AmmoLabel then
			local ReloadTime = Tool:GetAttribute("ReloadTime")
			local MagSize = Tool:GetAttribute("MagSize")
			
			AmmoLabel.Text = "Reloading..."
			task.wait(ReloadTime)
			AmmoLabel.Text = "Ammo: " .. tostring(MagSize) .. "/" .. tostring(MagSize)
		end
		
	elseif subject == "ammo" then
		local Ammo = ...
		local MagSize = Tool:GetAttribute("MagSize")
		
		if AmmoLabel then
			AmmoLabel.Text = "Ammo: " .. tostring(Ammo) .. "/" .. tostring(MagSize)
		end
	end
end)

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	
	if input.KeyCode == Enum.KeyCode.R then
		GunEvent:FireServer("Reload")
	end
end)
