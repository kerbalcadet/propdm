-- Variables that are used on both client and server
if CLIENT then
	include("cl_init.lua")
	include("cl_viewscreen.lua")
end

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

-- Todo, make/find a better sound.
SWEP.ShootSound = Sound( "Airboat.FireGunRevDown" )

SWEP.Tool = {}

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.CanHolster = true
SWEP.CanDeploy = true

SWEP.Sucking = false

function SWEP:Initialize()

	self:SetHoldType( "revolver" )

	self.Primary = {
		ClipSize = -1,
		DefaultClip = -1,
		Automatic = false,
		Ammo = "none"
	}

	self.Secondary = {
		ClipSize = -1,
		DefaultClip = -1,
		Automatic = false,
		Ammo = "none"
	}

end

function SWEP:Think()
	--suck behavior
	if self.Sucking and not input.IsMouseDown("MOUSE_RIGHT") then self.Sucking = false end



	self:NextThink(CurTime())
	return true
end

function SWEP:SecondaryAttack()
	self.Sucking = true
	
end