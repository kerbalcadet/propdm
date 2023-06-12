-- Variables that are used on both client and server
SWEP.PrintName		= "Kirby"
SWEP.Category = "Prop Deathmatch"
SWEP.ViewModel		= "models/weapons/c_toolgun.mdl"
SWEP.WorldModel		= "models/weapons/w_toolgun.mdl"
SWEP.Slot = 5
SWEP.SlotPos = 1

SWEP.UseHands		= true
SWEP.Spawnable		= true

-- Be nice, precache the models
util.PrecacheModel( SWEP.ViewModel )
util.PrecacheModel( SWEP.WorldModel )

SWEP.Primary = {
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none",
	ClipSize = -1,
}
SWEP.Secondary = {
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none",
	ClipSize = -1,

	Range = 400,
	Time = 0,	--last time the right mouse button changed
	Spool = 0,
	SuckPower = 50000,
	Range = 500,
	MaxWeight = 200
}

SWEP.CanHolster = true
SWEP.CanDeploy = true
SWEP.Sucking = false	

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
	self.Sound1 = CreateSound(self, "physics/nearmiss/whoosh_large1.wav")
	self.Sound2 = CreateSound(self, "ambient/levels/canals/windmill_wind_loop1.wav")
end

if SERVER then

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
	local mdl = ent:GetModel()
	local keyval = ent:GetKeyValues()
	
	local tab = {class=class, mdl=mdl, keyval=keyval}
	table.insert(own.KirbyInv, tab)
	self:EmitSound("garrysmod/balloon_pop_cute.wav")
	ent:Remove()
end

function SWEP:Think()
	--spool up/down behavior
	if self.Owner:KeyDown(IN_ATTACK2) then
		if not self.Sucking then 
			self.Sucking = true
			self.Secondary.Time = CurTime()

			self.Sound1:Play()
			self.Sound2:Play()
		end

		local t = CurTime() - self.Secondary.Time
		self.Secondary.Spool = math.Clamp(t*2, 0, 1)
	
	else
		if self.Sucking then
			self.Sucking = false 
			self.Secondary.Time = CurTime()
		end

		local t = CurTime() - self.Secondary.Time
		self.Secondary.Spool = math.Clamp(1 - t*2, 0, 1)
	end

	--actual suck
	if self.Secondary.Spool > 0 then
		local pos = self.Owner:EyePos()
		local range = self.Secondary.Range*self.Secondary.Spool
		for _, ent in pairs(ents.FindInCone(pos, self.Owner:EyeAngles():Forward(), range, 0.8)) do
			local phys = ent:GetPhysicsObject()
			if not ent:IsSolid() or not phys:IsValid() or ent:IsPlayer() then continue end

			local diff = pos - ent:GetPos()
			local dir = diff:GetNormalized()
			local distsq = math.Clamp(diff:LengthSqr()/144, 0.5, 100)	--feet bc why not
			
			--apply suction force
			local force = (dir/distsq)*self.Secondary.SuckPower*self.Secondary.Spool
			phys:ApplyForceCenter(force)
		
			if ent == self.Owner:GetTouchTrace().Entity then self:TryAddInv(ent) end
		end
	elseif not self.Owner:Alive() or not self.Owner:KeyDown(IN_ATTACK2) then
		self.Sound1:Stop()
	end

	self.Sound1:ChangeVolume(self.Secondary.Spool)
	self.Sound2:ChangeVolume(self.Secondary.Spool)

	--yada yada yada
	self:NextThink(CurTime())
	return true
end


end



function SWEP:PrimaryAttack()
	local inv = self.Owner.KirbyInv
	if not inv or table.IsEmpty(inv) then
		self:SetNextPrimaryFire(CurTime() + 0.5)
		return
	end
	
	if SERVER then
		local tab = inv[#inv]
		
		local ent = ents.Create(tab.class)
		ent:SetModel(tab.mdl)
		ent:PhysicsInit(SOLID_VPHYSICS)
		ent:SetSolid(SOLID_VPHYSICS)
		
		ent:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward()*30)
		ent:Spawn()

		table.remove(self.Owner.KirbyInv)
	end

	self:EmitSound("garrysmod/balloon_pop_cute.wav")
	self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:SecondaryAttack()

end
