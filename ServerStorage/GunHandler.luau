-- module script

type GunConfig = {
	MAG_SIZE: number,
	FIRE_RATE: number,
	DAMAGE: number,
	RANGE: number,
	SPREAD: number,
	RELOAD_TIME: number,
	AUTOMATIC: boolean,
	DAMAGE_MULTIPLIERS: {[string]: number}?
}

export type GunInstance = {
	-- methods
	Fire: (self: GunInstance, Origin: Vector3, Direction: Vector3, ExcludeInstances: {Instance}) -> (),
	Reload: (self: GunInstance) -> (),
	_canFire: (self: GunInstance) -> (),
	_createBeam: (self: GunInstance, cFrame: CFrame, Size: Vector3) -> (),
	_getSpreadAngle: (self: GunInstance) -> CFrame,
	
	-- class attributes
	Ammo: number,
	MagSize: number,
	Damage: number,
	Config: GunConfig,
	Reloading: boolean,
	ReloadTime: number,
	CanFire: boolean,
	LastFire: number
}

local DEFAULT_GUN_CONFIG: GunConfig = {
	MAG_SIZE = 300,
	FIRE_RATE = 8,
	DAMAGE = 10,
	RANGE = 200,
	SPREAD = 5,
	RELOAD_TIME = 1.2,
	AUTOMATIC = true,
}

local GunHandler = {}
GunHandler.__index = GunHandler

function GunHandler.new(Config) : GunInstance
	local self = setmetatable({}, GunHandler)
	
	Config = setmetatable(Config, {__index = DEFAULT_GUN_CONFIG})
	Config.DAMAGE_MULTIPLIERS = Config.DAMAGE_MULTIPLIERS or {}
	
	self.Config = Config
	self.MagSize = Config.MAG_SIZE
	self.Damage = Config.DAMAGE
	self.Ammo = Config.MAG_SIZE
	self.Reloading = false
	self.ReloadTime = Config.RELOAD_TIME
	self.CanFire = true
	self.LastFire = 0
	
	return self :: GunInstance
end

function GunHandler:_canFire(): boolean
	if not self.CanFire then return false end
	if self.Ammo < 1 then return false end
	if os.clock() - self.LastFire < (1 / self.Config.FIRE_RATE) then return false end
	if self.Reloading then return false end
	
	return true
end

function GunHandler:_createBeam(cFrame: CFrame, Size: Vector3) : ()
	local beam = Instance.new("Part", workspace)
	beam.Anchored = true
	beam.CanCollide = false
	beam.CFrame = cFrame
	beam.Size = Size
	beam.BrickColor = BrickColor.new("New Yeller")
	beam.Material = Enum.Material.Neon
	
	game:GetService("Debris"):AddItem(beam, .1)
end

function GunHandler:_getSpreadAngle(): CFrame
	local Spread = self.Config.SPREAD
	
	local AngleX = math.rad(math.random() * (Spread * 2) - Spread)
	local AngleY = math.rad(math.random() * (Spread * 2) - Spread)
	
	return CFrame.Angles(AngleX, AngleY, 0)
end

function GunHandler:Fire(Origin: Vector3, Direction: Vector3, ExcludeInstances: {Instance}) : ()
	if not self:_canFire() then return end
	self.CanFire = false
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ExcludeInstances
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local directionUnit = (Direction - Origin).Unit
	local actualDirection = directionUnit * self.Config.RANGE
	
	local RaycastResult = workspace:Raycast(Origin, actualDirection, raycastParams)
	
	if not RaycastResult then self.CanFire = true return end
	
	local BeamLength = RaycastResult.Distance
	local HitPos = RaycastResult.Position
	
	if BeamLength and HitPos then
		self.LastFire = os.clock()
		self.Ammo -= 1
		
		local SpreadAngle = self:_getSpreadAngle()
		local cFrame = CFrame.new(Origin, Direction) * SpreadAngle * CFrame.new(0, 0, -BeamLength / 2)
		
		self:_createBeam(cFrame, Vector3.new(.1, .1, BeamLength))
		
		local Target = RaycastResult.Instance
		if Target then
			local Humanoid = Target.Parent:FindFirstChild("Humanoid")
			
			if Humanoid and Humanoid.Health > 0 then
				local DamageMultiplier = self.Config.DAMAGE_MULTIPLIERS[Target.Name] or 1
				Humanoid.Health -= (self.Damage * DamageMultiplier)
			end
		end
	end
	
	self.CanFire = true
end

function GunHandler:Reload() : ()
	if self.Reloading then return end
	if self.Ammo >= self.MagSize then return end
	
	self.Reloading = true
	task.wait(self.ReloadTime)
	self.Ammo = self.MagSize
	self.Reloading = false
end

return GunHandler
