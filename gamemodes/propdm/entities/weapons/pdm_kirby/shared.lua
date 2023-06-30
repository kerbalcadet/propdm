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

SWEP.MaxWeight = 1000
local MovePenaltyMul = (0.25)/200	--multiplied by inventory weight to get movespeed penalty
local MovePenaltyMax = 0.7
SWEP.Primary = {
	DefaultClip = 0,
	Automatic = true,
	Ammo = "props",
	ClipSize = 20,

	SpoolTime = 0.75,	--time to reach max firing capacity
	MaxWeightPer = 400, -- max weight to have multiple things fire at once
	BaseSpeed = 1000,
	SpeedMul = 30000,	--divided by object weight to get speed on firing
	FireDelay = 0.1, 	--delay between each shot
	Active = false,
	Shooting = false,
	Cooldown = false,
	Time = 0,
	Queue = {},
	QueueWeight = 0

}
SWEP.Secondary = {
	DefaultClip = 0,
	ClipSize = 1,
	Automatic = true,
	Ammo = "props",

	Range = 500,
	SuckPower = 4*10^5,
	MaxVelSqr = 12000,
	
	BreakTimeMul = 1/100, --multiplied by weight to get time to break props at full power
	MinBreakTime = 0.5,
	MaxBreakTime = 10,

	Active = false,
	Time = 0,	--last time the right mouse button changed
	Spool = 0,
}

SWEP.CanHolster = true
SWEP.CanDeploy = true

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
	self.Sound1 = CreateSound(self, "physics/nearmiss/whoosh_large1.wav")
	self.Sound2 = CreateSound(self, "ambient/levels/canals/windmill_wind_loop1.wav")
	self.Sound3 = CreateSound(self, "garrysmod/balloon_pop_cute.wav")
	self.Sound4 = CreateSound(self, "ambient.steam01")
	self.Sound5 = CreateSound(self, "weapons/ar2/fire1.wav")
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 31, "KirbyQueue")
	self:NetworkVar("Int", 30, "KirbyProps")
end




--[[==CLIENT==]]--
if CLIENT then

	
function SWEP:CustomAmmoDisplay()
	local ad = {}
	ad.Draw = true
	ad.PrimaryClip = self:GetKirbyQueue() or 0
	ad.PrimaryAmmo = self:GetKirbyProps() or 0

	return ad
end


end
--[[==SERVER==]]--
if SERVER then



--[[-------------------------------------
	PLAYER FUNCTIONS
]]--------------------------------------


hook.Remove("PlayerDeath", "kirbyexplode")
hook.Add("PlayerDeath", "kirbyexplode", function(ply, inf, att)
	if not ply.KirbyInv then return end
	if #ply.KirbyInv == 0 and #ply.KirbyQueue == 0 then return end

	local queue = ply.KirbyInv
	table.Add(queue, ply.KirbyQueue)

	local pos = ply:GetPos() + Vector(0,0,50)
	timer.Create(tostring(ply).."kirbyexplode", 0.1, #queue, function()
		local tab = queue[#queue]
		local dir = VectorRand()
		dir.z = math.Clamp(dir.z, -0.2, 0.2)

		KirbyFireProp(tab, pos, dir, 2000, ply)
		table.remove(queue)
		ply:EmitSound("phx/explode00.wav", 100, 100, 1)
	end)

	ply:KirbyPlayerInit()
end)

function PLAYER:KirbyPlayerInit()
	self.KirbyInv = {}
	self.KirbyQueue = {}
	self.KirbyQWeight = 0	--weight of items in fire queue
	self.KirbyWeight = 0		--total weight
	
end

--adjust player movement speed
function PLAYER:ChangeMoveSpeed()
	local mp = math.Clamp(self.KirbyWeight*MovePenaltyMul, 0, MovePenaltyMax)

	self:SetWalkSpeed(200*(1 - mp))
	self:SetRunSpeed(400*(1 - mp))
end

--initialize inventory
function SWEP:Equip(own)
	if not own.KirbyInv then
		own:KirbyPlayerInit()
	end
end

function SWEP:OnRemove()
	self.Sound1:Stop()
	self.Sound2:Stop()
	self.Sound3:Stop()
	self.Sound4:Stop()
	self.Sound5:Stop()
end





--[[----------------------------------------------
	PROP FUNCTIONS AND SUCH THINGS
]]------------------------------------------------



function SWEP:TryAddInv(ent)
	local own = self:GetOwner()
	
	local phys = ent:GetPhysicsObject()
	local mass = phys:GetMass() or nil
	if ent.NoPickup then return end 
	--TODO: change to be total weight

	--can only pick up one superheavy object
	if mass and mass + own.KirbyWeight > self.MaxWeight and #own.KirbyInv > 0 then return end

	local class = ent:GetClass()
	local mass = phys:GetMass()
	local model = ent:GetModel()
	local keyval = ent:GetKeyValues()
	local map = ent.map
	
	local tab = {class=class, mass=mass, model=model, keyval=keyval, map=map}
	table.insert(own.KirbyInv, tab)
	self:SetKirbyProps(#own.KirbyInv)
	
	own.KirbyWeight = own.KirbyWeight + mass
	own:ChangeMoveSpeed()

	self.Sound3:Stop()
	self.Sound3:Play()
	ent:Remove()
end

--add entity table to kirbyqueue 
function SWEP:AddQueue(tab, heavy)
	local heavy = heavy or false
	local pitch = heavy and 40 or 60
	local own = self:GetOwner()
	
	self.Sound3:Stop()
	self.Sound3:Play()	
	self.Sound3:ChangePitch(pitch)

	
	table.insert(own.KirbyQueue, tab)
	own.KirbyQWeight = own.KirbyQWeight + tab.mass

	--remove prop from inventory
	table.remove(own.KirbyInv)
	self:SetKirbyProps(#own.KirbyInv)
	self:SetKirbyQueue(#own.KirbyQueue)
end

--fire prop from entity table
function KirbyFireProp(tab, pos, dir, vel, att)
	local ent = PDM_FireProp(tab, pos, AngleRand(), dir*vel, VectorRand(), att)

	--weaken explosive props
	local exp = ent:GetKeyValues().ExplodeDamage
	if exp and exp > 0 then ent:SetHealth(1) end

	--for some reason, setowner nocollides the entities to you. 
	--it happens to be the easiest way to do this
	ent:SetOwner(att)
	timer.Simple(0.2, function() if IsValid(ent) then ent:SetOwner(nil) end end)

	if not tab.map then
		timer.Simple(PDM_DESPTIME:GetInt(), function()
			if IsValid(ent) then ent:Dissolve(1, ent:GetPos()) end
		end)
	end
end

--try to break an immoveable map prop
function SWEP:KirbyTryBreak(ent, dir)
	local brk = ent.KirbyBreak or 0

	if not brk or brk <= 0 then 
		ent.KirbyLastBreak = CurTime()
		ent:EmitSound("physics/metal/metal_solid_strain"..math.random(1,5)..".wav")
	elseif ent.KirbyLastBreak and CurTime() - ent.KirbyLastBreak > 3 then
		ent.KirbyBreak = 0
	end
	
	--'dislodge' map props
	if brk >= 1 then
		ent:EmitSound("physics/metal/metal_barrel_impact_hard"..math.random(1,3)..".wav")
		
		local mdl = ent:GetModel()
		local skn = ent:GetSkin()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		
		local newent = ents.Create("prop_physics_multiplayer")
		newent:SetPos(pos)
		newent:SetAngles(ang)
		newent:SetModel(mdl)
		newent:SetSkin(skn)

		ent:Remove()
		newent:Spawn()

		local phys = newent:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(dir*100)
		end

	--add time to field otherwise
	else
		local mass = PDM_PropInfo(ent:GetModel())
		local breaktime = mass and math.Clamp(mass*self.Secondary.BreakTimeMul, self.Secondary.MinBreakTime, self.Secondary.MaxBreakTime) or self.Secondary.MinBreakTime

		brk = brk + self.KirbyPwrFrac*(engine.TickInterval() + math.Rand(-0.05, 0.05))/breaktime
		ent.KirbyBreak = brk
	end
end

function SWEP:KirbySuckEnts()
	local rspool = self.Secondary.Spool
	local own = self:GetOwner()
	local pos = own:EyePos()
	local range = self.Secondary.Range*rspool

	for _, ent in pairs(ents.FindInCone(pos, own:EyeAngles():Forward(), range, 0.8)) do
		local phys = ent:GetPhysicsObject()
		if not ent:IsSolid() or not phys:IsValid() or ent:IsPlayer() then continue end
		
		local mass = phys:GetMass()
		
		--don't suck props we can't hold
		if (mass + own.KirbyWeight > self.MaxWeight) and not #own.KirbyInv == 0 then continue end

		local diff = pos - ent:GetPos()
		local dir = diff:GetNormalized()
		local distsq = math.Clamp(diff:LengthSqr(), 1, 1000)	--feet bc why not

		local moveable = string.StartsWith(ent:GetClass(), "prop_physics")
		
		--dislodge map props, func_breakable, prop_detail, etc.
		if not moveable then
			self:KirbyTryBreak(ent, dir)

		--for normal props, apply suction force
		else
			slow =  ent:GetVelocity():LengthSqr() < self.Secondary.MaxVelSqr	--prevent super speed
			
			local power = self.Secondary.SuckPower*self.KirbyPwrFrac
			local force = slow and (dir/distsq)*mass*power or Vector(0,0,0)
			local lift = Vector(0,0,1)*mass*600*engine.TickInterval()*0.9
			phys:ApplyForceCenter((force + lift)*rspool)
		end
	end

	--actually find and add nearby props to inventory
	local gpos = own:GetPos()
	local trh =	util.TraceEntityHull({start=gpos, endpos=gpos + own:GetAimVector()*20, filter=own, ignoreworld=true}, own)
	local tre = trh.Entity
	
	if IsValid(tre) then
		local phys = tre:GetPhysicsObject()
		if IsValid(phys) and phys:IsMoveable() then
			self:TryAddInv(trh.Entity)
		end
	end
end

end


--[[SHARED]]--
function SWEP:Think()
	local own = self:GetOwner()

	--[[== SECONDARY FIRE ==]]--

	local rclick = own:KeyDown(IN_ATTACK2)

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

	local rspool = self.Secondary.Spool

	--actual suck
	if SERVER then
		if rspool > 0 then
			self.KirbyPwrFrac = 1 - own.KirbyWeight/self.MaxWeight

			self:KirbySuckEnts()
			
			local pchange =  100 - (1 - self.KirbyPwrFrac)*50
			self.Sound1:ChangePitch(pchange)
			self.Sound2:ChangePitch(pchange)

		elseif not rclick then
			self.Sound1:Stop()
		end
	end


	self.Sound1:ChangeVolume(rspool)
	self.Sound2:ChangeVolume(rspool)

	--screen shake effect
	if CLIENT and rspool > 0 then
		util.ScreenShake(LocalPlayer():GetPos(), rspool/2, 100, 0.1, 10)
	end


	--[[== PRIMARY FIRE ==]]--
	
	--spool up/down behavior
	local lclick = own:KeyDown(IN_ATTACK)
	if lclick and not self.Primary.Cooldown then
		if not self.Primary.Active then 
			self.Primary.Active = true
			self.Primary.Time = CurTime()

			self.Sound4:ChangeVolume(0)
			self.Sound4:Play()
		end

		local t = CurTime() - self.Primary.Time
		self.Primary.Spool = math.Clamp(t/self.Primary.SpoolTime, 0, 1)
	
	else
		if self.Primary.Active then
			self.Primary.Active = false 
			self.Primary.Cooldown = true
			self.Primary.Time = CurTime()
		
		elseif self.Primary.Spool == 0 then
			self.Primary.Cooldown = false
		end
		
		local t = CurTime() - self.Primary.Time
		self.Primary.Spool = math.Clamp(1 - t*2, 0, 1)
	end

	local lspool = self.Primary.Spool

	self.Sound4:ChangeVolume(lspool)
	self.Sound4:ChangePitch(80 + 40*lspool)


	--firing behavior
	if SERVER then

	--add props to shoot queue
	if lclick and not self.Primary.Cooldown and own.KirbyInv and not table.IsEmpty(own.KirbyInv) then
		local next = own.KirbyInv[#own.KirbyInv]
		local maxw = lspool*self.Primary.MaxWeightPer	
		
		if (maxw + 10> own.KirbyQWeight + next.mass) then	--several light props
			self:AddQueue(next)
		elseif lspool == 1 and #own.KirbyQueue == 0 then	--one single heavy prop
			self:AddQueue(next, true)
		end

	--actual shooting!
	elseif self.Primary.Cooldown and not self.Primary.Shooting and own.KirbyQueue and not table.IsEmpty(own.KirbyQueue) then
		self.Primary.Shooting = true
		own.KirbyQWeight = 0
		local title = tostring(self).."shoot"

		--timer to repeat firing logic
		timer.Create(title, self.Primary.FireDelay, #own.KirbyQueue, function()
			if not IsValid(self) or not own:Alive() then return end
			
			local queue = own.KirbyQueue
			local dir = own:EyeAngles():Forward()
			local tab = queue[#queue]
			
			self.Sound5:Stop()
			self.Sound5:Play()
			self.Sound5:ChangePitch(70)
			KirbyFireProp(tab, own:GetShootPos() + dir*30, dir, self.Primary.BaseSpeed + self.Primary.SpeedMul/tab.mass, own)
			
			table.remove(queue)
			self:SetKirbyQueue(#queue)

			own.KirbyWeight = own.KirbyWeight - tab.mass
			own:ChangeMoveSpeed()
			
			if timer.RepsLeft(title) == 0 then
				self.Primary.Shooting = false
			end
		end)
	end

	end

	--yada yada yada
	self:NextThink(CurTime())
	return true
end





function SWEP:PrimaryAttack()
end


function SWEP:SecondaryAttack()
end