local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

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