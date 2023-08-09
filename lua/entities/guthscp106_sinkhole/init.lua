AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self:PlaySound()

	local size = guthscp.configs.guthscp106.sinkhole_size * guthscp.configs.guthscp106.sinkhole_trigger_size_ratio * 0.5
	local bounds = Vector( size, size, 1.0 )
	self:PhysicsInitBox( -bounds, bounds )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )

	self:SetTrigger( true )
	self:UseTriggerBounds( true, 0.0 )  --  this allows trigger to behave properly without collision
	self:SetUseType( SIMPLE_USE )
end

function ENT:QueueRemove()
	self:PlaySound()
	self:SetQueueRemoveTime( CurTime() + guthscp.configs.guthscp106.sinkhole_anim_remove_time )

	timer.Simple( guthscp.configs.guthscp106.sinkhole_anim_remove_time, function()
		if not IsValid( self ) then return end
		self:Remove()
	end )
end

function ENT:PlaySound()
	local sounds = guthscp.configs.guthscp106.sounds_corrosion
	if #sounds == 0 then return end

	self:EmitSound( sounds[math.random( #sounds )] )
end

function ENT:StartTouch( ent )
	if self:IsQueueRemoved() then return end
	if not ent:IsPlayer() or guthscp.modules.guthscp106.is_scp_106( ent ) then return end

	--PrintMessage( HUD_PRINTTALK, "StartTouch: " .. tostring( ent ) )
	guthscp.modules.guthscp106.set_walking_sinkhole( ent, self )
end

function ENT:Touch( ent )
	if not guthscp.configs.guthscp106.sinkhole_can_sink then return end

	if self:IsQueueRemoved() then return end
	if guthscp.modules.guthscp106.is_scp_106( ent ) then return end

	--  check sink distance
	local dist = guthscp.configs.guthscp106.sinkhole_size * guthscp.configs.guthscp106.sinkhole_distance_ratio * 0.5
	if ent:GetPos():DistToSqr( self:GetPos() ) >= dist * dist then
		--  slow players
		--  TODO: use non-106 players movement speed
		if ent:IsPlayer() then
			guthscp.modules.guthscp106.apply_movement_speed_scale( ent, 0.8, 0.1 )
		end
		return 
	end 

	--  sink player
	guthscp.modules.guthscp106.sink_to( ent, guthscp.configs.guthscp106.dimension_position )
end

function ENT:EndTouch( ent )
	if not ent:IsPlayer() then return end
	if guthscp.modules.guthscp106.get_walking_sinkhole( ent ) ~= self then return end

	guthscp.modules.guthscp106.set_walking_sinkhole( ent, nil )
end

function ENT:Use( ent )
	if not guthscp.modules.guthscp106.is_scp_106( ent ) then return end

	PrintMessage( HUD_PRINTTALK, "Use: " .. tostring( ent ) )
	guthscp.modules.guthscp106.sink_to( ent, guthscp.configs.guthscp106.dimension_position )
end