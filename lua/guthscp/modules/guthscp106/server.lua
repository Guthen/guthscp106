local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

local function start_unsink_animation( ent, tick_time, steps, start_pos, offset_by_step, on_finish )
	ent:SetPos( start_pos )

	local step = 0
	local timer_id = "guthscp106:unsink-" .. ent:EntIndex()
	timer.Create( timer_id, tick_time, steps, function()
		if not IsValid( ent ) then
			timer.Remove( timer_id )
			return
		end

		ent:SetPos( start_pos + offset_by_step * ( 1 + step ) )

		step = step + 1
		if step == steps then
			if ent:IsPlayer() then
				ent:SetMoveType( MOVETYPE_WALK )
			end

			--  remove sinking mark
			guthscp106.set_sinking( ent, false )

			--  call callback
			if on_finish then
				on_finish()
			end
		end
	end )
end

local function start_sink_animation( ent, steps, pos, should_unsink, on_finish )
	--  mark as sinking
	guthscp106.set_sinking( ent, true )

	--  set fly movement so it disables movement and looks better with the 3rd-person animation
	if ent:IsPlayer() then
		ent:SetMoveType( MOVETYPE_FLY )
	end

	--  setup animation variables
	local start_pos = ent:GetPos()
	local view_offset = ent:EyePos() - ent:GetPos()
	local offset_by_step = view_offset / steps
	local tick_time = config.sink_time / steps

	--  start animation
	local step = 0
	local timer_id = "guthscp106:sink-" .. ent:EntIndex()
	timer.Create( timer_id, tick_time, steps, function()
		if not IsValid( ent ) then
			timer.Remove( timer_id )
			return
		end

		step = step + 1
		if step == steps then
			--  unsink animation
			if should_unsink then
				start_unsink_animation( ent, tick_time, steps, pos - view_offset + vector_up, offset_by_step, on_finish )
			else
				ent:SetPos( pos )
				if ent:IsPlayer() then
					ent:SetMoveType( MOVETYPE_WALK )
				end

				--  remove sinking mark
				guthscp106.set_sinking( ent, false )

				--  call callback
				if on_finish then
					on_finish()
				end
			end
		else
			ent:SetPos( start_pos - offset_by_step * ( 1 + step ) )
		end
	end )
end

function guthscp106.sink_to( ent, pos, should_suppress_sound, should_unsink, on_finish )
	--  check for playing animation
	local steps = config.sink_steps
	if steps > 0 then
		start_sink_animation( ent, steps, pos, should_unsink, on_finish )
	else
		--  teleport directly to position
		ent:SetPos( pos )

		--  reset movement type
		if ent:IsPlayer() then
			ent:SetMoveType( MOVETYPE_WALK )
		end

		--  call callback
		if on_finish then
			on_finish()
		end
	end

	--  play sinking sound
	if not should_suppress_sound then
		guthscp106.play_corrosion_sound( ent )
	end
end

function guthscp106.sink_to_dimension( ent )
	guthscp106.sink_to( ent, config.dimension_position, false, false, function()
		if ent:IsPlayer() then
			guthscp.sound.play_client( ent, config.sounds_sink_in_dimension )
		end
	end )
end

function guthscp106.set_sinking( ent, value )
	ent:SetNWBool( "guthscp106:is_sinking", value )
end

--  Mark SCP-106 in containment phase, used during the femur breaker to avoid multiple calls  
function guthscp106.set_containing( ply, value )
	ply:SetNWBool( "guthscp106:is_containing", value )
end

function guthscp106.set_sinkhole( ply, sinkhole, slot )
	ply:SetNWEntity( "guthscp106:" .. slot, sinkhole )
end

function guthscp106.create_sinkhole( pos, owner )
	local hole = ents.Create( "guthscp106_sinkhole" )
	hole:SetPos( pos )
	hole:SetOwner( owner )
	hole:Spawn()

	return hole
end

function guthscp106.set_walking_sinkhole( ply, sinkhole )
	ply:SetNWEntity( "guthscp106:sinkhole", sinkhole )
end

function guthscp106.apply_corrosion_damage( ent )
	local damage = math.max( 1.0, ent:GetMaxHealth() * config.dimension_corrosion_damage )
	ent:TakeDamage( damage )
end


hook.Add( "PlayerNoClip", "aaa_guthscp106:noclip", function( ply )
	if config.noclip and guthscp106.is_scp_106( ply ) then
		if config.auto_disable_abilities and guthscp106.is_in_containment_cell( ply ) then return end
		return true
	end
end )

hook.Add( "PlayerShouldTakeDamage", "guthscp106:invinsible", function( ply, attacker )
	if config.immortal and guthscp106.is_scp_106( ply ) then
		return false
	end
end )

hook.Add( "PlayerFootstep", "guthscp106:footstep", function( ply, pos, foot, sound, volume )
	--  only accepts SCP-106 or players walking on a sinkhole or players in pocket dimension
	if not guthscp106.is_scp_106( ply ) and
	   not IsValid( guthscp106.get_walking_sinkhole( ply ) ) and
	   not guthscp106.is_in_pocket_dimension( ply ) then return end

	--  emit sound
	guthscp.sound.play( ply, config.sounds_footstep, config.sound_hear_distance, false, config.sound_footstep_volume )

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

	local modifier_id = "guthscp106-passthrough"

	--  play sound if start passing-through
	if not guthscp.has_player_speed_modifier( ply, modifier_id ) then
		guthscp.sound.play( tr.Entity, config.sounds_passthrough, config.sound_hear_distance, false, config.sound_corrosion_volume )
	end

	--  scale movement speed
	guthscp.apply_player_speed_modifier( ply, modifier_id, config.passthrough_speed_factor, config.passthrough_speed_time )
end )

timer.Create( "guthscp106:dimension-corrosion", 1.0, 0, function()
	if config.dimension_corrosion_damage == 0.0 then return end

	--  TODO: add possibility to link a filter to a zone

	--  corrode players
	for i, ply in ipairs( player.GetAll() ) do
		if not guthscp106.is_in_pocket_dimension( ply ) then continue end
		if not config.dimension_can_corrode_scps and guthscp.is_scp( ply ) then continue end

		guthscp106.apply_corrosion_damage( ply )
	end

	--  corrode NPCs
	if config.dimension_can_corrode_npcs then
		for i, npc in ipairs( guthscp.get_npcs() ) do
			if not guthscp106.is_in_pocket_dimension( npc ) then continue end

			guthscp106.apply_corrosion_damage( npc )
		end
	end
end )

hook.Add( "PlayerUse", "guthscp106:femur-breaker", function( ply, ent )
	if config.femur_button_id <= -1 then return end  --  check if the config is set
	if ent:MapCreationID() ~= config.femur_button_id then return end 	--  check is the femur breaker button
	if ent:GetInternalVariable( "m_bLocked" ) then return end  --  check is not locked

	local scps_106 = guthscp106.get_scps_106()

	--  check if a SCP-106 can be recontained
	local should_recontain = false
	for i, scp in ipairs( scps_106 ) do
		if guthscp106.is_containing( scp ) then continue end  --  avoid SCPs already containing (i.e. in femur breaker event)
		should_recontain = true
	end
	if not should_recontain then return end

	--  find players in containment cell
	local has_found_human = false
	for i, human in ipairs( player.GetAll() ) do
		if guthscp.is_scp( human ) then continue end
		if not guthscp106.is_in_containment_cell( human ) then continue end

		has_found_human = true
		break
	end

	--  trigger femur breaker
	if has_found_human then
		guthscp106:info( "Femur Breaker has been activated!" )

		local time = config.femur_sink_delay
		for i, scp in ipairs( scps_106 ) do
			if guthscp106.is_containing( scp ) then continue end  --  avoid SCPs already containing (in femur breaker event)
			if guthscp106.is_in_containment_cell( scp ) then continue end  --  check is already contained

			--  alert SCP-106
			guthscp.player_message(
				scp,
				guthscp.helpers.format_message(
					config.translation_femur_breaker_warning,
					{
						time = time,
					}
				)
			)

			--  schedule sinking
			timer.Simple( time, function()
				if not IsValid( scp ) then return end
				if not guthscp106.is_scp_106( scp ) then return end

				guthscp106.sink_to( scp, config.femur_sink_position, false, true, function()
					guthscp.player_message( scp, config.translation_femur_breaker_hint )
				end )
				guthscp106.set_containing( scp, false )
			end )

			--  mark as containing
			guthscp106.set_containing( scp, true )

			guthscp106:info( "%s (%s) is going to containment cell in %d seconds", scp:GetName(), scp:SteamID(), time )
		end
	else
		guthscp106:info( "Femur Breaker has been activated without humans inside the containment cell, resulting in no effect!" )
	end
end )