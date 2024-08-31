--  warn for new version
local message = "[IMPORTANT] You are using an old version of Guthen's SCP 106 addon, please consider upgrading to the new version. You can find the new addons in this collection: https://steamcommunity.com/sharedfiles/filedetails/?id=3034749707"
MsgC( Color( 255, 0, 0 ), message, "\n" )
if CLIENT then
    hook.Add( "InitPostEntity", "GuthSCP:NewSCP106Version", function()
        timer.Simple( 5, function()
            if not LocalPlayer():IsAdmin() then return end
            chat.AddText( Color( 161, 154, 255 ), message )
        end )
    end )
end

local DimensionPos106 = DimensionPos106 or
	{
--		["rp_scp_site_8_v2b"] = Vector(-781, -10808, 744),
--		["gm_site19"] = Vector(2307, 4630, 576),
	}

-- collide things
local uncollideEnt =
{
	["func_door"] = true,
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_dynamic"] = true,
	["prop_static"] = true,
	["prop_door_rotating"] = true,
	["prop_vehicle_jeep"] = true,
}
local exceptionMapID = exceptionMapID or
{
	-- [2346] = true,
	-- [3510] = true,
	-- [3762] = true,
	-- [1781] = true,
	-- [1783] = true,
}

if SERVER then
	concommand.Add( "guthscp_set_106_dimension", function( ply )
		if not ply:IsValid() or not ply:IsSuperAdmin() then return end
		DimensionPos106[game.GetMap()] = ply:GetPos()

		if not file.Exists( "guth_scp", "DATA" ) then file.CreateDir( "guth_scp" ) end
		file.Write( "guth_scp/scp_106_dimension.txt", util.TableToJSON( DimensionPos106 ) )

		ply:PrintMessage( HUD_PRINTCONSOLE, "GuthSCP - Dimension Pos has been saved" )
	end )

	concommand.Add( "guthscp_set_106_collide", function( ply )
		if not ply:IsValid() or not ply:IsSuperAdmin() then return end

		local ent = ply:GetEyeTrace().Entity
		if not IsValid( ent ) then return end

		if not exceptionMapID[game.GetMap()] then exceptionMapID[game.GetMap()] = {} end
		exceptionMapID[game.GetMap()][ent:MapCreationID()] = true

		if not file.Exists( "guth_scp", "DATA" ) then file.CreateDir( "guth_scp" ) end
		file.Write( "guth_scp/scp_106_uncollide.txt", util.TableToJSON( exceptionMapID ) )

		ply:PrintMessage( HUD_PRINTCONSOLE, "GuthSCP - Collide ID has been saved" )
	end )

	concommand.Add( "guthscp_set_106_uncollide", function( ply )
		if not ply:IsValid() or not ply:IsSuperAdmin() then return end

		local ent = ply:GetEyeTrace().Entity
		if not IsValid( ent ) then return end

		if not exceptionMapID[game.GetMap()] then return end
		exceptionMapID[game.GetMap()][ent:MapCreationID()] = nil

		if not file.Exists( "guth_scp", "DATA" ) then file.CreateDir( "guth_scp" ) end
		file.Write( "guth_scp/scp_106_uncollide.txt", util.TableToJSON( exceptionMapID ) )

		ply:PrintMessage( HUD_PRINTCONSOLE, "GuthSCP - Uncollide ID has been saved" )
	end )
end

function util.PaintDown(start, effname, ignore, z)
   local btr = util.TraceLine({start=start, endpos=(start + Vector(0,0,z or -64)), filter=ignore, mask=MASK_VISIBLE})
   util.Decal(effname, btr.HitPos+btr.HitNormal, btr.HitPos-btr.HitNormal)
end

hook.Add("PlayerFootstep", "SCP106Footstep", function(ply, pos)
	if ply:Team() == TEAM_SCP106 then
		util.PaintDown(ply:GetPos(), "Scorch", ply)

		ply:EmitSound("guthen_scp/106/StepPD"..math.random(1, 3)..".ogg")
		return true
	end
end)

-- disable damage to scp
hook.Add("PlayerShouldTakeDamage", "GuthenSCPProtectSCP", function(ply)
	if TEAM_SCP106 == ply:Team() then return false end
end)

-- no collide with 106
hook.Add("ShouldCollide", "GuthenSCP106DontCollide", function(ent1, ent2)
	if ent1:IsPlayer() and ent1:Team() == TEAM_SCP106 then
		if uncollideEnt[ent2:GetClass()] then
			if SERVER and exceptionMapID[game.GetMap()] and exceptionMapID[game.GetMap()][ent2:MapCreationID()] then
				return true
			end
			--print(ent2:GetClass()..":"..ent2:MapCreationID())
			return false
		end
	end
end)

hook.Add("PlayerNoClip", "SCP106Noclip", function(ply)
	if ply:Team() == TEAM_SCP106 then return true end
end)

hook.Add( "PlayerSpawn", "SCP106Capacities", function(ply)
	if timer.Exists( "SCP106Breathing"..ply:UserID() ) then timer.Remove( "SCP106Breathing"..ply:UserID() ) end
	if ply:Team() == TEAM_SCP106 then
		ply:SetCustomCollisionCheck( true )

		timer.Create( "SCP106Breathing"..ply:UserID(), 3, 0, function()
			if not ply:IsValid() then return end

			ply:StopSound( "guthen_scp/106/Breathing.ogg" )
			ply:EmitSound( "guthen_scp/106/Breathing.ogg" )
		end)
	else
		ply:SetCustomCollisionCheck( false )
	end
end)

--	Player	--

if not SERVER then return end

local Player = FindMetaTable( "Player" )

function Player:SlowTo106(trg, pos)
	trg = trg or self
    if not trg:IsValid() or not trg:Alive() then return end
	trg:Lock()
	trg:SetPos( trg:GetPos() - Vector( 0, 0, 5 ) )

	trg:EmitSound( "guthen_scp/106/Corrosion"..math.random(1, 2)..".ogg" )

	timer.Create("GuthenSCP106DrowningPlayer"..tostring(trg:UserID()), .05, 70, function()
		trg:SetPos(trg:GetPos()+Vector(0, 0, -1))
	end)

	timer.Simple(3, function()
	    if not trg:IsValid() or not trg:Alive() then return end
		if not ( self == trg ) then self:ChatPrint("Vous avez envoyé "..trg:Name().." dans votre dimension.") end
		trg:SetPos( pos or DimensionPos106[game.GetMap()] or Vector() )
		trg:SetEyeAngles(Angle(90, 0, 0))
		trg:EmitSound("guthen_scp/106/SinkholeFall.ogg")
		trg:TakeDamage(math.random(42, 64), ply, self)
		trg:UnLock()
	end)
end

hook.Add( "PlayerInitialSpawn", "GuthenSCP106:GetPos", function()
	if file.Exists( "guth_scp", "DATA" ) then
 		if file.Exists( "guth_scp/scp_106_dimension.txt", "DATA" ) then
			local txt = file.Read( "guth_scp/scp_106_dimension.txt", "DATA" )
			DimensionPos106 = util.JSONToTable( txt )
			print( "GuthSCP - 106 Dimension Pos loaded !" )
		end
		if file.Exists( "guth_scp/scp_106_uncollide.txt", "DATA" ) then
			local txt = file.Read( "guth_scp/scp_106_uncollide.txt", "DATA" )
			exceptionMapID = util.JSONToTable( txt )
			print( "GuthSCP - 106 Uncollide ID loaded !" )
		end
	end

	hook.Remove( "PlayerInitialSpawn", "GuthenSCP106:GetPos" )
end )
