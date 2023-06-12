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

}
SWEP.Secondary = {
	Range = 400,
	Time = 0,	--last time the right mouse button changed
	Spool = 0,
	SuckPower = 50000,
	Range = 500
}

SWEP.CanHolster = true
SWEP.CanDeploy = true

SWEP.Sucking = false	

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
end

if SERVER then

function SWEP:Think()
	--spool up/down behavior
	if self.Owner:KeyDown(IN_ATTACK2) then
		if not self.Sucking then 
			self.Sucking = true
			self.Secondary.Time = CurTime()
		end

		local t = CurTime() - self.Secondary.Time
		self.Secondary.Spool = math.Clamp(t, 0, 1)
	
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
		for _, ent in pairs(ents.FindInCone(pos, self.Owner:EyeAngles():Forward(), range, 0.2)) do
			local phys = ent:GetPhysicsObject()
			if not ent:IsSolid() or not phys:IsValid() or ent:IsPlayer() then continue end

			local diff = pos - ent:GetPos()
			local dir = diff:GetNormalized()
			local distsq = math.Clamp(diff:LengthSqr()/144, 0.5, 100)	--feet bc why not
			
			local force = (dir/distsq)*self.Secondary.SuckPower*self.Secondary.Spool
			print(force:Dot(dir))

			phys:ApplyForceCenter(force)
		end
	end

	--yada yada yada
	self:NextThink(CurTime())
	return true
end

function SWEP:SecondaryAttack()
end

end