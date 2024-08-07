AddCSLuaFile()
if CLIENT then

net.Receive("PDM_DustEffect", function()
	local ent = net.ReadEntity()
	local dir = net.ReadVector()
	local scale = net.ReadFloat()

	if not IsValid(ent) then return end
	if not ent.Emitter then ent.Emitter = ParticleEmitter(ent:GetPos(), false) end
	
	local em = ent.Emitter
	local p = em:Add("particles/pdm/smoke", ent:WorldSpaceCenter())
	p:SetColor(140, 115, 90)
	p:SetDieTime(1)
	p:SetStartAlpha(20)
	p:SetEndAlpha(0)
	p:SetStartSize(scale)
	p:SetEndSize(scale*1.5)
	p:SetVelocity(VectorRand()*10 + dir*50)
	p:SetGravity(Vector())
	p:SetAngleVelocity(AngleRand()/100)
end)

end


if SERVER then

function PDM_EntFromTable(tab, pos, ang)
    local ent = ents.Create(tab.class)

    if not IsValid(ent) then return end
    
    ent:SetPos(pos)
    if ent:IsNPC() then ang = ang/3 end  --easy way to keep npc angles above ground
    ent:SetAngles(ang or Angle())
    ent:SetModel(tab.model)
    ent:SetSkin(tab.skn or 0)
    --set individual features of the entity
    if tab.keyval and ent:IsSolid() then 
        for k, v in pairs(tab.keyval) do
            ent:SetKeyValue(tostring(k), tostring(v))
        end
    end
    ent:Spawn()


    local phys = ent:GetPhysicsObject()
    if not phys or not phys:IsValid() then 
        ent:PhysicsInit(SOLID_VPHYSICS)
        ent:SetNoDraw(false)
        return ent 
    end

    local mass = tab.mass or nil
    if mass then phys:SetMass(mass) end

    --npc weapons
    if tab.weps and not table.IsEmpty(tab.weps) then
        for _, v in pairs(tab.weps) do
            ent:Give(v)
        end
    end



    return ent
end

function PDM_PropInfo(mdl)
    local info = util.GetModelInfo(mdl)
    if not info or not info.KeyValues then return false end

    local tab = util.KeyValuesToTable(info.KeyValues)
    local mass = tab.editparams.totalmass or nil
    local vol = tab.solid.volume or nil

    return mass, vol, tab
end

function PDM_CalcMass(phys, dens)
    --https://wiki.facepunch.com/gmod/Structures/SurfacePropertyData
    --calculation of default gmod mass data for metal
    local dens = dens or 2700
    local sa = phys:GetSurfaceArea()
    return sa*0.1*0.0254^3*dens
end

function PDM_SetupDespawn(ent, time)
    time = time or PDM_DESPTIME:GetInt() 
    timer.Simple(time, function()
        if IsValid(ent) then ent:Dissolve(1, ent:GetPos()) end
    end)
end

function PDM_FireProp(tab, pos, ang, vel, avel, att)
    local ent = PDM_EntFromTable(tab, pos, ang)
    local phys = ent:GetPhysicsObject()
    local minv = ent:WorldSpaceAABB()
    local ground = util.QuickTrace(pos, Vector(0,0,-5000), ent).HitPos
    local zdiff = minv.z - ground.z

    if zdiff < 0 then
        ent:SetPos(pos + Vector(0,0, -zdiff + 5))
    end

    if not IsValid(phys) then 
        
    elseif ent:IsNPC() then
        ent:SetNavType(NAV_NONE)
        ent:SetVelocity(vel)
        ent:SetNavType(NAV_GROUND)
        ent:AddRelationship("player D_HT 99")
        ent:AddEntityRelationship(att, D_LI, 99)
    else
        phys:SetVelocity(vel or Vector(0, 0, 0))
        phys:SetAngleVelocity(avel or Angle(0, 0, 0))
        phys:EnableDrag(false)
    end

    if IsValid(att) then ent:SetPhysicsAttacker(att) end

    return ent
end

function PDM_SelectRandomProp(maxw, maxv, proplist)
    local tab = {}

    for i=1,10 do
        tab = table.Random(proplist)
        local mass, vol = PDM_PropInfo(tab.model)
        if not mass or not vol then continue end
        
        if mass < maxw and vol < maxv then tab.class = "prop_physics_multiplayer" break end
    end

    return tab
end

function PDM_SelectRandomProps(num, maxw, maxv, proplist)
    local props = {}
    for i=1,num do
        table.insert(props, PDM_SelectRandomProp(maxw, maxv, proplist))
    end
    return props
end

--maxw = max weight, maxv = max volume
function PDM_FireRandomProp(pos, ang, vel, avel, att, maxw, maxv, proplist)
    maxw = maxw or 9999999
    maxv = maxv or 9999999
    proplist = proplist or PDM_PROPS

    local tab = PDM_SelectRandomProp(maxw, maxv, proplist)

    local ent = PDM_FireProp(tab, pos, AngleRand(), vel, VectorRand()*100)
    ent:SetPhysicsAttacker(att)

    return ent
end


--dust effect for props trying to break
util.AddNetworkString("PDM_DustEffect")
function PDM_DustEffect(ent, dir)
	ent:EmitSound("physics/metal/metal_solid_strain"..math.random(1,5)..".wav")
	
	local scale = IsValid(ent:GetPhysicsObject()) and math.Clamp(ent:GetPhysicsObject():GetSurfaceArea()/400, 10, 100) or 20

	net.Start("PDM_DustEffect")
		net.WriteEntity(ent)
		net.WriteVector(dir)
		net.WriteFloat(scale)
	net.Broadcast()
end

function PDM_ReplaceProp(ent, att)
    if ent.Replaced then return end

    local mdl = ent:GetModel()
    local skn = ent:GetSkin()
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    
    local newent = ents.Create("prop_physics_multiplayer")
    newent:SetPos(pos)
    newent:SetAngles(ang)
    newent:SetModel(mdl)
    newent:SetSkin(skn)

    if ent:IsPlayer() or ent:IsNPC() then
        ent:SetPos(pos - vector_up*10000)   --can't seem to make ragdolls despawn without a lot of jank. so just replace jank with lesser jank.

        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_DISSOLVE)
        dmg:SetDamage(ent:Health() or 99999)
        dmg:SetAttacker(att or game.GetWorld())
        dmg:SetInflictor(att or game.GetWorld())
        ent:TakeDamageInfo(dmg)
    
    elseif not ent:IsSolid() then       --don't actually remove level triggers and such
        ent.Replaced = true
        ent:SetNoDraw(true)
    else
        ent:Remove()
    end

    newent:Spawn()
    return newent
end

--try to break an immoveable map prop
function PDM_TryBreakProp(ent, dir, amt)
	local brk = ent.Break or 0

	local ct = CurTime()
	if not brk or brk <= 0 then 
		ent.LastBreak = ct
		ent.LastBreakEffect = ct

		PDM_DustEffect(ent, dir)
	elseif ent.LastBreak and ct - ent.LastBreak > 3 then
		ent.Break = 0
	end

	if ct - ent.LastBreakEffect > 3 then
		PDM_DustEffect(ent, dir)
		ent.LastBreakEffect = ct
	end

    if not ent:GetModel() then return end
    local phys = ent:GetPhysicsObject()
    local mass = PDM_PropInfo(ent:GetModel()) or (IsValid(phys) and phys:GetMass()) or 100

    --map props that have no normal model but are set to 50,000
    if mass > 10000 and phys then
        phys:SetMass(PDM_CalcMass(phys))
    end

    local breaktime = mass and math.Clamp(mass/200, 1, 10) or 1
    brk = brk + amt/breaktime
	

	--'dislodge' map props
	if brk >= 1 then
		ent:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav")

		local newent = PDM_ReplaceProp(ent)
		local phys = newent:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(dir*100)
		
            if phys:GetMass() > 10000 then
                phys:SetMass(PDM_CalcMass(phys, 500))
            end
        end
    else
        ent.Break = brk
    end
end

function PDM_PropExplode(tabs, pos, vel, normal, maxang, att)

    local props = {}
    for _, tab in pairs(tabs) do
        local ar = AngleRand()

        --create vector within max vertical angle
        local a = AngleRand()
        a.p = math.random(-maxang, maxang)
        local vr = a:Forward()

        --make sure it's firing in the same hemisphere as the normal
        --pass (0,0,0) to normal if you want to have a spherical-ish explosion
        local dot = vr:Dot(normal)
        if dot < 0 then vr = vr + 2*dot*normal end

        local new = PDM_FireProp(tab, pos + normal*100, ar, vel*vr, vr*100, att)
        new:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
        table.insert(props, new)
    end

    timer.Simple(0.1, function()
        for _, p in pairs(props) do
            if IsValid(p) then p:SetCollisionGroup(COLLISION_GROUP_NONE) end
        end
    end)

    return props
end

--helper function since multiple weapons use gravity explosions
function PDM_GravExplode(pos, rad, pwr, minrad, plyw, att)
    for _,ent in pairs(ents.FindInSphere(pos, rad)) do
        
        local phys = ent:GetPhysicsObject()
        if not ent:IsSolid() or not phys:IsValid() then continue end

        local diff = ent:GetPos() + phys:GetMassCenter() - pos
        local dir = diff:GetNormalized()
        local dist = math.Clamp(diff:Length()/12, minrad, rad/12)	--feet bc why not
        local mag = pwr/dist^(3/2)
        local force = dir*mag
        local plyweight = plyw or 2400

        if not ent:IsPlayer() and not ((ent:GetMoveType() == MOVETYPE_VPHYSICS) or phys:IsMoveable()) and ent:IsSolid() then
            PDM_TryBreakProp(ent, dir, 2*mag/(10^6))
        end

        ent:SetPos(ent:GetPos()+Vector(0,0,1))  --remove ground friction

        if ent:IsPlayer() then     --applyforce doesn't work for players
            ent:SetVelocity(ent:GetVelocity() + force/plyw)
        elseif ent:IsNPC() then
            local nav = ent:GetNavType()
            
            ent:SetNavType(NAV_NONE)
            ent:SetVelocity(ent:GetVelocity() + force/plyw)
            ent:SetNavType(nav)
        else
            phys:ApplyForceCenter(force)
        end

        ent:SetPhysicsAttacker(att)
    end
end


hook.Remove("EntityTakeDamage", "PDM_PropDamage")
hook.Add("EntityTakeDamage", "PDM_PropDamage", function(ent, dmg)
    local inf = dmg:GetInflictor()
    if not IsValid(ent) or not IsValid(inf) then return end

    --kirby self damage
    if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == "pdm_kirby" and  inf:GetVelocity():LengthSqr() < 10000 then return true end

    --damage attribution override for cases like heli where it still shows "prop physics" as attacker
    local inf = dmg:GetInflictor()
    if IsValid(inf) and inf.Attacker then
--        dmg:SetInflictor(inf)
        dmg:SetAttacker(inf.Attacker)
    end
end)

end