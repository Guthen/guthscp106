if not GuthSCP or not GuthSCP.Config then
    return
end

hook.Add( "PlayerNoClip", "aaa_vkxscp106:noclip", function( ply )
    if GuthSCP.Config.vkxscp106.noclip and GuthSCP.isSCP106( ply ) then
        return true
    end
end )

hook.Add( "OnPlayerChangedTeam", "vkxscp106:setup", function( ply, old_team, new_team )
    if new_team == GuthSCP.Config.vkxscp106.team then
        ply:SetCustomCollisionCheck( true )
        GuthSCP.playSound( ply, GuthSCP.Config.vkxscp106.sound_idle, GuthSCP.Config.vkxscp106.sound_hear_distance, true, .5 )
    elseif old_team == GuthSCP.Config.vkxscp106.team then
        ply:SetCustomCollisionCheck( false )
        GuthSCP.stopSound( ply, GuthSCP.Config.vkxscp106.sound_idle )
    end
end )

hook.Add( "PlayerShouldTakeDamage", "vkxscp106:invinsible", function( ply, attacker )
    if GuthSCP.isSCP106( ply ) then
        print( attacker )
        return false
    end
end )

hook.Add( "PlayerFootstep", "vkxscp106:footstep", function( ply, pos, foot, sound, volume )
    if GuthSCP.isSCP106( ply ) then
        local sounds = GuthSCP.Config.vkxscp106.sounds_footstep
        if #sounds == 0 then return end

        ply:EmitSound( sounds[math.random( #sounds )], nil, nil, math.max( 0.4, volume ) )

        return true
    end
end )