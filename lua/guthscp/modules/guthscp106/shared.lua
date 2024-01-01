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
		--  delete sinkholes
		if IsValid( ply.guthscp106_exit_sinkhole ) then
			ply.guthscp106_exit_sinkhole:QueueRemove()
		end 
		if IsValid( ply.guthscp106_waypoint ) then
			ply.guthscp106_waypoint:QueueRemove()
		end 

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

function guthscp106.is_valid_sinkhole_position( pos )
	--  TODO: export translations in the config
	--  check it's grounded
	if not guthscp.world.is_ground( pos ) then
		return false, "You must be on ground to place a sinkhole!"
	end

	--  check distance from others sinkholes
	local dist_sqr = config.sinkhole_placement_distance * config.sinkhole_placement_distance
	if dist_sqr > 0.0 then
		for i, sinkhole in ipairs( ents.FindByClass( "guthscp106_sinkhole" ) ) do
			if pos:DistToSqr( sinkhole:GetPos() ) <= dist_sqr then
				return false, "Another sinkhole is too close from your position!"
			end
		end
	end

	return true
end

function guthscp106.is_sinking( ply )
	return ply:GetNWBool( "guthscp106:is_sinking", false )
end

function guthscp106.get_sinkhole( ply, slot )
	return ply:GetNWEntity( "guthscp106:" .. slot, NULL )
end

function guthscp106.get_walking_sinkhole( ply )
	return ply:GetNWEntity( "guthscp106:sinkhole", nil )
end

function guthscp106.is_in_pocket_dimension( ent )
	return guthscp106.pocket_dimension_zone:is_in( ent )
end

function guthscp106.is_in_containment_cell( ent )
	return guthscp106.containment_cell_zone:is_in( ent )
end

function guthscp106.play_corrosion_sound( ent )
	guthscp.sound.play( ent, config.sounds_corrosion, config.sound_hear_distance, false, config.sound_corrosion_volume )
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

	function guthscp106.use_sinkhole_ability( ply, slot )
		local last_sinkhole = guthscp106.get_sinkhole( ply, slot )

		if guthscp106.is_in_pocket_dimension( ply ) then
			if not IsValid( last_sinkhole ) then return end
			
			guthscp106.sink_to( ply, last_sinkhole:GetPos(), false, true )
			return
		end

		local sinkhole_pos = ply:GetPos() 
		local can_place, reason = guthscp106.is_valid_sinkhole_position( sinkhole_pos )
		if not can_place then
			guthscp.player_message( ply, reason )
			return
		end

		--  delete previous sinkhole
		if IsValid( last_sinkhole ) then 
			last_sinkhole:QueueRemove()
		end

		--  create new sinkhole
		guthscp106.set_sinkhole( ply, guthscp106.create_sinkhole( sinkhole_pos, ply ), slot )
	end

	local abilities = {
		[guthscp106.ABILITIES.SINKHOLE_A] = function( ply )
			guthscp106.use_sinkhole_ability( ply, guthscp106.SINKHOLE_SLOTS.A )
		end,
		[guthscp106.ABILITIES.SINKHOLE_B] = function( ply )
			guthscp106.use_sinkhole_ability( ply, guthscp106.SINKHOLE_SLOTS.B )
		end,
		[guthscp106.ABILITIES.ENTER_DIMENSION] = function( ply )
			if guthscp106.is_in_pocket_dimension( ply ) then return end

			--  direct sink to dimension if noclipping
			if ply:GetMoveType() == MOVETYPE_NOCLIP then
				guthscp106.sink_to_dimension( ply )
				return
			end

			--  check sinkhole placement
			local sinkhole_pos = ply:GetPos() 
			local can_place, reason = guthscp106.is_valid_sinkhole_position( sinkhole_pos )
			if not can_place then
				guthscp.player_message( ply, reason )
				return
			end

			--  lock SCP-106 while the sinkhole is spawning 
			ply:SetMoveType( MOVETYPE_NONE )

			--  spawn sinkhole
			local sinkhole = guthscp106.create_sinkhole( sinkhole_pos )
			sinkhole.IsUseDisabled = true
			
			--  sink SCP-106 after some time
			timer.Simple( config.sinkhole_anim_spawn_time * 0.5, function()
				if not IsValid( sinkhole ) or not IsValid( ply ) then return end

				guthscp106.sink_to_dimension( ply )

				--  auto-destroy after some time
				timer.Simple( config.sinkhole_anim_spawn_time, function()
					if not IsValid( sinkhole ) then return end

					sinkhole:QueueRemove()
				end )
			end )
		end,
	}

	function guthscp106.use_ability( ply, ability )
		if not guthscp106.is_scp_106( ply ) then return end
		if config.auto_disable_abilities and guthscp106.is_in_containment_cell( ply ) then return end

		if not abilities[ability] then return end
		abilities[ability]( ply )
	end
else
	function guthscp106.use_ability( ability )
		net.Start( "guthscp106:ability" )
			net.WriteUInt( ability, guthscp106._ability_ubits )
		net.SendToServer()
	end
end