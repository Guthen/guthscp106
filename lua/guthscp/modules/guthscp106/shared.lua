local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

--  scps filter
guthscp106.filter = guthscp.players_filter:new( "guthscp106" )
if SERVER then
	guthscp106.filter:listen_disconnect()
	guthscp106.filter:listen_weapon_users( "guthscp_106" )  --  being SCP-106 just mean a player having the weapon 

    guthscp106.filter.event_added:add_listener( "guthscp106:setup", function( ply )
		ply:SetCustomCollisionCheck( true )
		guthscp.sound.play( ply, config.sound_idle, config.sound_hear_distance, true, .5 )
	end )
	guthscp106.filter.event_removed:add_listener( "guthscp106:reset", function( ply )
		ply:SetCustomCollisionCheck( false )
		guthscp.sound.stop( ply, config.sound_idle )
	end )
end

--  functions
function guthscp106.get_scps_106()
	return guthscp106.filter:get_entities()
end

function guthscp106.is_scp_106( ply )
	if CLIENT and ply == nil then
		ply = LocalPlayer() 
	end

	return guthscp106.filter:is_in( ply )
end

--  pass through entities
hook.Add( "ShouldCollide", "guthscp106:nocollide", function( ent_1, ent_2 )
    if not ent_1:IsPlayer() or not guthscp106.is_scp_106( ent_1 ) then return end
	
	if not config.traversable_entity_classes[ent_2:GetClass()] then return end  --  check not a traversable class
	if guthscp106.passthrough_filter:is_in( ent_2 ) then return end  --  check filter blacklist

	return false
end )