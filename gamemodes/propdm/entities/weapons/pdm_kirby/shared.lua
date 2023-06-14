AddCSLuaFile()
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_viewscreen.lua")

-- Variables that are used on both client and server
if CLIENT then
	SWEP.PrintName		= "Kirby"
	SWEP.Category = "Prop Deathmatch"
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.UseHands		= true
	SWEP.Spawnable		= true
end

SWEP.Base = "weapon_base"
SWEP.ViewModel		= "models/weapons/c_toolgun.mdl"
SWEP.WorldModel		= "models/weapons/w_toolgun.mdl"

-- Be nice, precache the models
util.PrecacheModel( SWEP.ViewModel )
util.PrecacheModel( SWEP.WorldModel )

SWEP.Primary = {
	DefaultClip = -1,
	Automatic = true,
	Ammo = "none",
	ClipSize = -1,

	Active = false,
	SpeedMul = 100000,	--divided by object weight to get speed on firing
	RateMul = 1/60	--multiplied by object weight to get delay after firing
}
SWEP.Secondary = {
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none",
	ClipSize = -1,

	Active = false,
	Range = 100,
	Time = 0,	--last time the right mouse button changed
	Spool = 0,
	SuckPower = 50000,
	Range = 500,
	MaxWeight = 200
}

SWEP.CanHolster = true
SWEP.CanDeploy = true

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
	self.Sound1 = CreateSound(self, "physics/nearmiss/whoosh_large1.wav")
	self.Sound2 = CreateSound(self, "ambient/levels/canals/windmill_wind_loop1.wav")
	self.Sound3 = CreateSound(self, "garrysmod/balloon_pop_cute.wav")
end

--[[==SERVER==]]--
if SERVER then

--lessen self damage in hook
hook.Remove("EntityTakeDamage", "kirbypropdamage")
hook.Add("EntityTakeDamage", "kirbypropdamage", function(ent, dmg)
	if not ent:IsPlayer() or not (ent:GetActiveWeapon():GetClass() == "pdm_kirby") or not (dmg:GetDamageType() == 1) then return end

	if ent:GetVelocity():LengthSqr() < 12000 then
		return true
	else
		dmg:ScaleDamage(0.5)
	end
end)


function SWEP:OnRemove()
	self.Sound1:Stop()
	self.Sound2:Stop()
	self.Owner.KirbyInv = {}
end

function SWEP:TryAddInv(ent)
	local own = self.Owner
	if not own.KirbyInv then 
		own.KirbyInv = {} 
		own.KirbyInvWeight = 0 
	end

	local phys = ent:GetPhysicsObject()
	if not phys or not phys:IsValid() or phys:GetMass() > self.Secondary.MaxWeight then return end 
	--TODO: change to be total weight

	local class = ent:GetClass()
	local mass = ent:GetMass()
	local mdl = ent:GetModel()
	local keyval = ent:GetKeyValues()
	
	local tab = {class=class, mass=mass, mdl=mdl, keyval=keyval}
	table.insert(own.KirbyInv, tab)

	self.Sound3:Stop()
	self.Sound3:Play()
	ent:Remove()
end

end

--[[SHARED]]--
function SWEP:Think()
	local rclick = self.Owner:KeyDown(IN_ATTACK2)

	--spool up/down behavior
	if rclick then
		if not self.Secondary.Active then 
			self.Secondary.Active = true
			self.Secondary.Time = CurTime()

			self.Sound1:Play()
			self.Sound2:Play()
		end

		local t = CurTime() - self.Secondary.Time
		self.Secondary.Spool = math.Clamp(t*2, 0, 1)
	
	else
		if self.Secondary.Active then
			self.Secondary.Active = false 
			self.Secondary.Time = CurTime()
		end

		local t = CurTime() - self.Secondary.Time
		self.Secondary.Spool = math.Clamp(1 - t*2, 0, 1)
	end

	local spool = self.Secondary.Spool

	--actual suck
	if spool > 0 then
		if SERVER then
			local pos = self.Owner:EyePos()
			local range = self.Secondary.Range*spool
			for _, ent in pairs(ents.FindInCone(pos, self.Owner:EyeAngles():Forward(), range, 0.8)) do
				local phys = ent:GetPhysicsObject()
				if not ent:IsSolid() or not phys:IsValid() or ent:IsPlayer() then continue end

				local diff = pos - ent:GetPos()
				local dir = diff:GetNormalized()
				local distsq = math.Clamp(diff:LengthSqr()/144, 0.5, 100)	--feet bc why not
				
				--apply suction force
				local force = (dir/distsq)*self.Secondary.SuckPower*spool
				phys:ApplyForceCenter(force)
			
				if ent == self.Owner:GetTouchTrace().Entity and rclick then self:TryAddInv(ent) end
			end
		end
	elseif not rclick then
		self.Sound1:Stop()
	end


	self.Sound1:ChangeVolume(spool)
	self.Sound2:ChangeVolume(spool)

	--screen shake effect
	if CLIENT and spool > 0 then
		util.ScreenShake(LocalPlayer():GetPos(), spool/2, 100, 0.1, 10)
	end

	--yada yada yada
	self:NextThink(CurTime())
	return true
end





function SWEP:PrimaryAttack()
	if not SERVER then return end

	self.Sound3:Stop()
	self.Sound3:Play()
	
	local inv = self.Owner.KirbyInv
	if not inv or table.IsEmpty(inv) then
		self:SetNextPrimaryFire(CurTime() + 0.5)
		return
	end

	local tab = inv[#inv]
	
	local ent = ents.Create(tab.class)
	ent:SetModel(tab.mdl)
	ent:PhysicsInit(SOLID_VPHYSICS)
	ent:SetSolid(SOLID_VPHYSICS)
	
	dir = self.Owner:GetForward()
	ent:SetPos(self.Owner:GetShootPos() + dir*30)	--change to depend on bounding box later
	ent:Spawn()

	local phys = ent:GetPhysicsObject()
	local mass = phys:GetMass()
	phys:Wake()
	phys:SetVelocity(dir*self.Primary.SpeedMul/mass)

	table.remove(self.Owner.KirbyInv)
	self:SetNextPrimaryFire(CurTime() + mass*self.Primary.RateMul)

end


function SWEP:SecondaryAttack()
end