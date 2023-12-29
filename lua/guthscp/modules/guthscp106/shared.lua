local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

--  scps filter
guthscp106.filter = guthscp.players_filter:new( "guthscp106" )
if SERVER then
	guthscp106.filter:listen_disconnect()
	guthscp106.filter:listen_weapon_users( "guthscp_106" )  --  being SCP-106 just mean a player having the weapon 

    guthscp106.filter.event_added:add_listener( "guthscp106:setup", function( ply )
		--  speeds
		ply:SetSlowWalkSpeed( config.walk_speed )
		ply:SetWalkSpeed( config.walk_speed )
		ply:SetRunSpeed( config.run_speed )

		--  collision
		ply:SetCustomCollisionCheck( true )
		
		--  sound
		guthscp.sound.play( ply, config.sound_idle, config.sound_hear_distance, true, config.sound_idle_volume )
	end )
	guthscp106.filter.event_removed:add_listener( "guthscp106:reset", function( ply )
		--  collision
		ply:SetCustomCollisionCheck( false )

		--  sound
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

--  pass-through entities
hook.Add( "ShouldCollide", "guthscp106:nocollide", function( scp106, target )
    if not scp106:IsPlayer() or not guthscp106.is_scp_106( scp106 ) then return end

	--  pass-through living entity
	if config.passthrough_living_entities and guthscp.world.is_living_entity( target ) then 
		return false 
	end

	if not config.passthrough_entity_classes[target:GetClass()] then return end  --  check not a traversable class
	if guthscp106.passthrough_filter:is_in( target ) then return end  --  check filter blacklist

	return false
end )

if SERVER then
	util.AddNetworkString( "guthscp106:ability" )

	net.Receive( "guthscp106:ability", function( len, ply )
		local ability = net.ReadUInt( guthscp106._ability_ubits )
		guthscp106.use_ability( ply, ability )
	end )

	function guthscp106.use_ability( ply, ability )
		if not guthscp106.is_scp_106( ply ) then return end

		--  TODO: find a nicer way of coding abilities
		if ability == guthscp106.ABILITIES.EXIT_DIMENSION then 
			if not IsValid( ply.guthscp106_exit_sinkhole ) then return end

			--  sink to exit sinkhole
			guthscp106.sink_to( ply, ply.guthscp106_exit_sinkhole:GetPos(), true )

			--  delete exit sinkhole
			local sinkhole = ply.guthscp106_exit_sinkhole
			timer.Simple( 3.0, function()
				if not IsValid( sinkhole ) then return end
				sinkhole:QueueRemove()
			end )
			ply.guthscp106_exit_sinkhole = nil
		elseif ability == guthscp106.ABILITIES.ENTER_DIMENSION then
			--  delete previous sinkhole
			if IsValid( ply.guthscp106_exit_sinkhole ) then 
				ply.guthscp106_exit_sinkhole:QueueRemove()
			end

			--  create new sinkhole
			ply.guthscp106_exit_sinkhole = guthscp106.create_sinkhole( ply:GetPos() )

			--  sink to dimension
			guthscp106.sink_to( ply, guthscp.configs.guthscp106.dimension_position )
		elseif ability == guthscp106.ABILITIES.PLACE_SINKHOLE then
			--  delete previous sinkhole
			if IsValid( ply.guthscp106_waypoint ) then
				ply.guthscp106_waypoint:QueueRemove()
			end

			--  create new sinkhole
			ply.guthscp106_waypoint = guthscp106.create_sinkhole( ply:GetPos() )
		elseif ability == guthscp106.ABILITIES.ENTER_SINKHOLE then
			if not IsValid( ply.guthscp106_waypoint ) then return end

			--  sink to waypoint
			guthscp106.sink_to( ply, ply.guthscp106_waypoint:GetPos(), true )
		end
	end
else
	function guthscp106.use_ability( ability )
		net.Start( "guthscp106:ability" )
			net.WriteUInt( ability, guthscp106._ability_ubits )
		net.SendToServer()
	end
end