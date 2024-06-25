AddCSLuaFile()
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_viewscreen.lua")
AddCSLuaFile("cl_mdl.lua")

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
	QueueWeight = 0,
	QueueDelay = 0.1

}
SWEP.Secondary = {
	DefaultClip = 0,
	ClipSize = 1,
	Automatic = true,
	Ammo = "props",

	Range = 300,
	SuckPower = 4*10^5,
	MaxVelSqr = 12000,

	InstantGrabWeight = SWEP.MaxWeight/2,
	GrabTimeMul = 1/1000,
	MaxGrabTime = 10,
	

	Active = false,
	Time = 0,	--last time the right mouse button changed
	Spool = 0,
}
SWEP.CurMdl = nil

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "KirbyQueue")
	self:NetworkVar("Int", 1, "KirbyProps")
	self:NetworkVar("Float", 0, "LSpool")
	self:NetworkVar("Float", 1, "RSpool")
	self:NetworkVar("Float", 2, "PwrFrac")
end

function SWEP:Initialize()
	self:SetHoldType( "revolver" )
	self.Sound1 = CreateSound(self, "physics/nearmiss/whoosh_large1.wav")
	self.Sound2 = CreateSound(self, "ambient/levels/canals/windmill_wind_loop1.wav")
	self.Sound3 = CreateSound(self, "garrysmod/balloon_pop_cute.wav")
	self.Sound4 = CreateSound(self, "ambient.steam01")
	self.Sound5 = CreateSound(self, "weapons/ar2/fire1.wav")

	self:SetPwrFrac(1)
end



--[[---------------
	CLIENTSIDE ONLY
]]-----------------


if CLIENT then

	
function SWEP:CustomAmmoDisplay()
	local ad = {}
	ad.Draw = true
	ad.PrimaryClip = self:GetKirbyQueue() or 0
	ad.PrimaryAmmo = self:GetKirbyProps() or 0

	return ad
end




end




--[[---------------
	SERVERSIDE ONLY
]]-----------------




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





function SWEP:AddStrainEffect(ent)
	ent:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav")
	local size = math.Clamp(ent:GetPhysicsObject():GetVolume()^(1/3), 100, 4000)
	util.ScreenShake(ent:GetPos(), 10, 1000, 1, size)
end


--send the first model in our queue to the client
util.AddNetworkString("KirbyUpdateMdl")
function SWEP:UpdateMdl(mdl)
	net.Start("KirbyUpdateMdl")
	net.WriteString(mdl)
	net.Send(self:GetOwner())
end



function SWEP:TryAddInv(ent)
	local phys = ent:GetPhysicsObject()
	local own = self:GetOwner()

	--if not IsValid(phys) then return end

	local mass
	if IsValid(phys) then
		--kirby created props should probably not have a grabtime
		--initialize kirbyadd, property for time it takes to grab ent
		local ct = CurTime()
		if not ent.KirbyAdd then
			local mass = phys:GetMass()
			if mass > 10000 then mass = PDM_CalcMass(phys) end
			
			ent.KirbyMass = mass
			ent.KirbyAdd = math.Clamp(mass*self.Secondary.GrabTimeMul, 0, self.Secondary.MaxGrabTime)
			ent.KirbyLastAddEffect = ct
		end

		if ent.KirbyAdd >= 0.1 then
			if ct - ent.KirbyLastAddEffect > 2 then
				ent.KirbyLastAddEffect = ct
				self:AddStrainEffect(ent)
			end

			ent.KirbyAdd = ent.KirbyAdd - engine.TickInterval()
			return
		elseif ent.KirbyMass > 1000 then
			self:AddStrainEffect(ent)
		end


		--manage adding if the timer has run down
		
		mass = phys:GetMass() or PDM_CalcMass(phys)
		if ent.NoPickup then return end 
		--TODO: change to be total weight

		--can only pick up one superheavy object
		if mass and mass + own.KirbyWeight > self.MaxWeight and #own.KirbyInv > 0 then return end
	else
		mass = 100
	end	

	local class = ent:GetClass()
	local model = ent:GetModel()
	local skn = ent:GetSkin()
	local keyval = ent:GetKeyValues()
	local map = ent.map

	local weps={} 
	if ent:IsNPC() then
		for _, v in pairs(ent:GetWeapons()) do
			table.insert(weps, v:GetClass())
		end
	end

	
	local tab = {class=class, mass=mass, model=model, skn=skn, keyval=keyval, map=map, weps=weps}
	table.insert(own.KirbyInv, tab)
	
	local num = #own.KirbyInv
	self:SetKirbyProps(num)
	self:UpdateMdl(model)

	
	own.KirbyWeight = own.KirbyWeight + mass
	own:ChangeMoveSpeed()

	self.Sound3:Stop()
	self.Sound3:Play()
	ent:Remove()
end





function SWEP:KirbySuckEnts()
	--actually find and add nearby props to inventory
	local own = self:GetOwner()
	local gpos = own:GetPos()
	local trh =	util.TraceEntityHull({start=gpos, endpos=gpos + own:GetAimVector()*10, filter=own, ignoreworld=true}, own)
	local tre = trh.Entity
	
	if IsValid(tre) then
		local phys = tre:GetPhysicsObject()
		if IsValid(phys) and phys:IsMoveable() and tre:GetMoveType() == MOVETYPE_VPHYSICS then
			self:TryAddInv(tre)
		end
	end


	--pull other props closer by
	local rspool = self:GetRSpool()
	local pos = own:EyePos()
	local range = self.Secondary.Range*rspool

	for _, ent in pairs(ents.FindInCone(pos, own:EyeAngles():Forward(), range, 0.8)) do
		local phys = ent:GetPhysicsObject()
		if ent:IsPlayer() or ent:IsWeapon() or not ent:IsSolid() or not IsValid(phys) or ent.NoPickup then continue end

		local class = ent:GetClass()
		local diff = pos - ent:GetPos()
		local dir = diff:GetNormalized()

		--dislodge map props, func_breakable, prop_detail, etc.
		local moveable = ent:GetMoveType() == MOVETYPE_VPHYSICS and phys:IsMoveable() or ent:IsNPC()
		if not moveable then
			local amt = (engine.TickInterval() + math.Rand(-0.05, 0.05))
			PDM_TryBreakProp(ent, dir, amt)
		end

		local mass = phys:GetMass()
		if mass > 10000 then mass = PDM_CalcMass(phys) end
		
		--don't suck props we can't hold
		if (mass + own.KirbyWeight > self.MaxWeight) and not (#own.KirbyInv == 0) then continue end


		local distsq = math.Clamp(diff:LengthSqr(), 1, 100000)

		--don't push yourself
		if distsq < 5000 then return end


		if ent:IsNPC() then
			ent:SetVelocity(dir*10)	

		--for normal props, apply suction force
		else
			slow =  ent:GetVelocity():LengthSqr() < self.Secondary.MaxVelSqr	--prevent super speed
			
			local power = self.Secondary.SuckPower*self:GetPwrFrac()
			local force = slow and (dir/distsq)*mass*power or Vector(0,0,0)
			local lift = Vector(0,0,1)*mass*600*engine.TickInterval()*0.9
			phys:ApplyForceCenter((force + lift)*rspool)
		end
	end
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

	return ent
end



--logic to handle firing of props
function SWEP:StartFireLogic(tab)
	local own = self:GetOwner()
	if not IsValid(self) or not own:Alive() then return end
	
	local queue = own.KirbyQueue
	local dir = own:EyeAngles():Forward()
	local tab = queue[#queue]

	self.Sound5:Stop()
	self.Sound5:Play()
	self.Sound5:ChangePitch(70)
	local ent = KirbyFireProp(tab, own:GetShootPos() + dir*30, dir, self.Primary.BaseSpeed + self.Primary.SpeedMul/tab.mass, own)

	table.remove(queue)
	self:SetKirbyQueue(#queue)

	--update model displayed on client HUD
	local inv = own.KirbyInv
	local mdl = #queue > 0 and queue[#queue].model or (#inv > 0 and inv[#inv].model or "nil")
	self:UpdateMdl(mdl)

	--adjust player vars
	own.KirbyWeight = own.KirbyWeight - tab.mass
	own:ChangeMoveSpeed()
	
	if timer.RepsLeft(tostring(self).."shoot") == 0 then
		self.Primary.Shooting = false
	end
end

end


















--[[-----------------
	SHARED FUNCTIONS
]]-------------------




function SWEP:Think()
	local own = self:GetOwner()

	--[[== SECONDARY FIRE ==]]--

	if SERVER then
		self:SetPwrFrac(1 - own.KirbyWeight/self.MaxWeight)
		local rclick = own:KeyDown(IN_ATTACK2)
		--spool up/down behavior
		if rclick and self:GetPwrFrac() > 0.05 then
			if not self.Secondary.Active then 
				self.Secondary.Active = true
				self.Secondary.Time = CurTime()

				self.Sound1:Play()
				self.Sound2:Play()
			end

			local t = CurTime() - self.Secondary.Time
			self:SetRSpool(math.Clamp(t*2, 0, 1))
		
		else
			if self.Secondary.Active then
				self.Secondary.Active = false 
				self.Secondary.Time = CurTime()
			end

			local t = CurTime() - self.Secondary.Time
			self:SetRSpool(math.Clamp(1 - t*2, 0, 1))
		end

		local rspool = self:GetRSpool()

		--actual suck
		if rspool > 0 then
			self:KirbySuckEnts()
			
			local pchange =  100 - (1 - self:GetPwrFrac())*50
			self.Sound1:ChangePitch(pchange)
			self.Sound2:ChangePitch(pchange)

		elseif not rclick then
			self.Sound1:Stop()
		end


		self.Sound1:ChangeVolume(rspool)
		self.Sound2:ChangeVolume(rspool)
	end

	--screen shake effect
	if CLIENT and self:GetRSpool() > 0 then
		util.ScreenShake(LocalPlayer():GetPos(), self:GetRSpool()/2, 100, 0.1, 10)
	end


	--[[== PRIMARY FIRE ==]]--
	
	if SERVER then

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
			self:SetLSpool(math.Clamp(t/self.Primary.SpoolTime, 0, 1))
		
		else
			if self.Primary.Active then
				self.Primary.Active = false 
				self.Primary.Cooldown = true
				self.Primary.Time = CurTime()
			
			elseif self:GetLSpool() == 0 then
				self.Primary.Cooldown = false
			end
			
			local t = CurTime() - self.Primary.Time
			self:SetLSpool(math.Clamp(1 - t*2, 0, 1))
		end

		local lspool = self:GetLSpool()

		self.Sound4:ChangeVolume(lspool)
		self.Sound4:ChangePitch(80 + 40*lspool)


		--firing behavior

		--add props to shoot queue
		if lclick and not self.Primary.Cooldown and own.KirbyInv and not table.IsEmpty(own.KirbyInv) and CurTime() > (self.NextAddToQueue or 0) then
			local next = own.KirbyInv[#own.KirbyInv]
			--local maxw = lspool*self.Primary.MaxWeightPer	
			
			--if (maxw + 10> own.KirbyQWeight + next.mass) then	--several light props
				self:AddQueue(next)
			--elseif lspool == 1 and #own.KirbyQueue == 0 then	--one single heavy prop
				--self:AddQueue(next, true)
			--end

			self.NextAddToQueue = CurTime() + self.Primary.QueueDelay

		--actual shooting!
		elseif self.Primary.Cooldown and not self.Primary.Shooting and own.KirbyQueue and not table.IsEmpty(own.KirbyQueue) then
			self.Primary.Shooting = true
			own.KirbyQWeight = 0
			local title = tostring(self).."shoot"

			--timer to repeat firing logic
			timer.Create(title, self.Primary.FireDelay, #own.KirbyQueue, function()
				self:StartFireLogic(tab)
			end)
		end

	end

	--yada yada yada
	self:NextThink(CurTime())
	return true
end

--[[### scroll control for inventory ###]]--

hook.Remove("StartCommand", "KirbyScrollInv")
hook.Add("StartCommand", "KirbyScrollInv", function(ply, cmd)
	if not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not (wep:GetClass() == "pdm_kirby") then return end

	if SERVER then
		local mwheel = cmd:GetMouseWheel()
		if mwheel == 0 then return end

		local e = cmd:KeyDown(IN_USE)
		if not e then return end

		cmd:SetMouseWheel(1)

		local inv = ply.KirbyInv
		if not inv or not (#inv > 0) then return end

		local first = inv[1]
		table.remove(inv, 1)
		table.insert(inv, first)
		wep:UpdateMdl(first.model)
	end
end)

--SERVER: initialize inventory
--CLIENT: Display queued model in hud panel
function SWEP:Deploy()
	local own = self:GetOwner()

	if SERVER and not own.KirbyInv then
		own:KirbyPlayerInit()
	end

	if CLIENT then
		KirbyPanelVisible(true)
	end
end

function SWEP:Holster()
	if CLIENT then
		KirbyPanelVisible(false)
	end

	return true
end


function SWEP:PrimaryAttack()
end


function SWEP:SecondaryAttack()
end