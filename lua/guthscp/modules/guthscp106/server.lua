local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106


function guthscp106.apply_movement_speed_scale( ply, scale, time )
	if not guthscp106.is_scp_106( ply ) then return end

	local timer_id = "guthscp106:revert-speed-" .. ply:SteamID64()

	--  apply new speed
	if not timer.Exists( timer_id ) then
		ply:SetWalkSpeed( config.walk_speed * scale )
		ply:SetRunSpeed( config.walk_speed * scale )
	end

	--  revert after time
	timer.Create( timer_id, time, 1, function()
		if not guthscp106.is_scp_106( ply ) then return end
		
		ply:SetWalkSpeed( config.walk_speed )
		ply:SetRunSpeed( config.walk_speed )
	end )
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
	if not guthscp106.is_scp_106( ply ) then return end

	local sounds = config.sounds_footstep
	if #sounds == 0 then return end

	ply:EmitSound( sounds[math.random( #sounds )], nil, nil, math.max( 0.4, volume ) )

	return true
end )

hook.Add( "SetupMove", "guthscp106:passthrough-speed", function( ply, mv, cmd )
	if not config.should_passthrough_change_speed then return end
	if not guthscp106.is_scp_106( ply ) then return end

	--  get passing-through entity
	local tr = util.TraceEntity( {
		start = ply:GetPos(),
		endpos = ply:GetPos(),
		filter = ply,
	}, ply )
	if not tr.Hit or not config.passthrough_entity_classes[tr.Entity:GetClass()] then return end  --  check hit and not a traversable class
	
	--  scale movement speed
	guthscp106.apply_movement_speed_scale( ply, config.passthrough_speed_factor, config.passthrough_speed_time )
end )