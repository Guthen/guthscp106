local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

function guthscp106.sink_to( ent, pos, should_suppress_sound, should_unsink )
	--[[ ent:SetMoveType( MOVETYPE_NONE )
	ent:SetPos( ent:GetPos() - Vector( 0, 0, 32 ) )
	
	--  TODO: animate
	local SINK_TIME = 2.0
	local SINK_STEPS = 20
	local SINK_OFFSET_BY_STEP = ent:GetViewOffset() / SINK_STEPS
	local start_pos = ent:GetPos()
	--print( SINK_TIME / SINK_STEPS, SINK_OFFSET_BY_STEP )

	local step = 0
	timer.Create( "guthscp106:sink-" .. ent:EntIndex(), SINK_TIME / SINK_STEPS, SINK_STEPS, function()
		step = step + 1
		if step == SINK_STEPS then
			if should_unsink then
				step = 0
				ent:SetPos( pos - ent:GetViewOffset() )
				timer.Create( "guthscp106:unsink-" .. ent:EntIndex(), SINK_TIME / SINK_STEPS, SINK_STEPS, function()
					ent:SetPos( pos - ent:GetViewOffset() + SINK_OFFSET_BY_STEP * step )

					step = step + 1
					if step == SINK_STEPS then
						ent:SetMoveType( MOVETYPE_WALK )
					end
				end )
			else
				ent:SetPos( pos )
				ent:SetMoveType( MOVETYPE_WALK )
			end
		else
			ent:SetPos( start_pos - SINK_OFFSET_BY_STEP * step )
		end
	end ) ]]
	ent:SetPos( pos )

	if not should_suppress_sound then
		guthscp106.play_corrosion_sound( ent )
	end
end

function guthscp106.sink_to_dimension( ent )
	guthscp106.sink_to( ent, config.dimension_position, true, true )

	if ent:IsPlayer() then
		local sounds = config.sounds_sink_in_dimension
		if #sounds == 0 then return end
		
		guthscp.sound.play_client( ent, sounds[math.random( #sounds )] )
	end
end

function guthscp106.create_sinkhole( pos )
	local hole = ents.Create( "guthscp106_sinkhole" )
	hole:SetPos( pos )
	hole:Spawn()

	return hole
end

function guthscp106.set_walking_sinkhole( ply, sinkhole )
	ply:SetNWEntity( "guthscp106:sinkhole", sinkhole )
end

function guthscp106.get_walking_sinkhole( ply )
	return ply:GetNWEntity( "guthscp106:sinkhole", nil )
end

function guthscp106.is_in_pocket_dimension( ent )
	--  TODO: create a tool to set up the dimension
	local start, endpos = Vector( 4337, 5460, 1717 ), Vector( 1490, 3761, 500 )
	local pos = ent:GetPos()

	return pos:WithinAABox( start, endpos )
end


hook.Add( "PlayerNoClip", "aaa_guthscp106:noclip", function( ply )
	if config.noclip and guthscp106.is_scp_106( ply ) then
		return true
	end
end )

hook.Add( "PlayerShouldTakeDamage", "guthscp106:invinsible", function( ply, attacker )
	if config.immortal and guthscp106.is_scp_106( ply ) then
		return false
	end
end )

hook.Add( "PlayerFootstep", "guthscp106:footstep", function( ply, pos, foot, sound, volume )
	--  only accepts SCP-106 or players walking on a sinkhole
	if not guthscp106.is_scp_106( ply ) and not IsValid( guthscp106.get_walking_sinkhole( ply ) ) then return end

	--  check footstep sounds are available
	local sounds = config.sounds_footstep
	if #sounds == 0 then return end
	if config.sound_footstep_volume == 0.0 then return end

	--  emit sound
	guthscp.sound.play( ply, sounds[math.random( #sounds )], config.sound_hear_distance, false, config.sound_footstep_volume )

	return true
end )

hook.Add( "SetupMove", "guthscp106:passthrough-speed", function( ply, mv, cmd )
	if config.passthrough_speed_factor == 1.0 then return end
	if not guthscp106.is_scp_106( ply ) then return end

	--  get passing-through entity
	local tr = guthscp.world.safe_entity_trace( ply )
	if not tr.Hit then return end  --  check hit
	if not config.passthrough_entity_classes[tr.Entity:GetClass()] and  --  check not a traversable class
	   not ( config.passthrough_living_entities and guthscp.world.is_living_entity( tr.Entity ) ) then return end  --  check living entity
	
	--  scale movement speed
	guthscp.apply_player_speed_modifier( ply, "guthscp106-passthrough", config.passthrough_speed_factor, config.passthrough_speed_time )
end )

timer.Create( "guthscp106:dimension-corrosion", 1.0, 0, function()
	if config.dimension_corrosion_damage == 0.0 then return end

	--  TODO: find a cleaner and more performant way of iterating through entities in a zone
	for i, ent in ipairs( ents.GetAll() ) do
		if not guthscp.world.is_living_entity( ent ) then continue end
		if not config.dimension_can_corrode_scps and guthscp.is_scp( ent ) then continue end
		if not guthscp106.is_in_pocket_dimension( ent ) then continue end

		local damage = math.max( 1.0, ent:GetMaxHealth() * config.dimension_corrosion_damage )
		ent:TakeDamage( damage )
	end
end )