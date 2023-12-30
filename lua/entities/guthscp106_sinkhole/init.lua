AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

function ENT:Initialize()
	timer.Simple( 0.1, function()
		self:PlaySound()
	end )

	local size = config.sinkhole_size * config.sinkhole_trigger_size_ratio * 0.5
	local bounds = Vector( size, size, 1.0 )
	self:PhysicsInitBox( -bounds, bounds )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )

	self:SetTrigger( true )
	self:UseTriggerBounds( true, 0.0 )  --  this allows trigger to behave properly without collision
	self:SetUseType( SIMPLE_USE )
end

function ENT:Think()
	local owner = self:GetOwner()
	
	--  signal owner from nearby beings
	if IsValid( owner ) and config.sinkhole_signal_distance > 0 then
		local count = 0

		for i, ent in ipairs( ents.FindInSphere( self:GetPos(), config.sinkhole_signal_distance ) ) do
			if not ent:IsPlayer() then continue end
			if guthscp.is_scp( ent ) then continue end

			count = count + 1
		end

		if count > 0 then
			--  TODO: find a more immersive and less spamy way of alerting 
			owner:PrintMessage( HUD_PRINTTALK, ( "There is %d humans around your sinkhole" ):format( count ) )
		end
	end

	self:NextThink( CurTime() + config.sinkhole_signal_update_time )
	return true
end

function ENT:QueueRemove()
	self:PlaySound()
	self:SetQueueRemoveTime( CurTime() + config.sinkhole_anim_remove_time )

	timer.Simple( config.sinkhole_anim_remove_time, function()
		if not IsValid( self ) then return end
		self:Remove()
	end )
end

function ENT:PlaySound()
	guthscp106.play_corrosion_sound( self )
end

function ENT:StartTouch( ent )
	if self:IsQueueRemoved() then return end
	if not ent:IsPlayer() or guthscp106.is_scp_106( ent ) then return end

	--PrintMessage( HUD_PRINTTALK, "StartTouch: " .. tostring( ent ) )
	guthscp106.set_walking_sinkhole( ent, self )
end

function ENT:Touch( ent )
	if not config.sinkhole_can_sink then return end

	if self:IsQueueRemoved() then return end
	if not guthscp.world.is_living_entity( ent ) then return end
	if guthscp106.is_scp_106( ent ) then return end

	--  check sink distance
	local dist = config.sinkhole_size * config.sinkhole_distance_ratio * 0.5
	if ent:GetPos():DistToSqr( self:GetPos() ) >= dist * dist then
		--  slow players
		if ent:IsPlayer() then
			guthscp.apply_player_speed_modifier( ent, "guthscp106-sinkhole", config.sinkhole_trigger_speed_factor, config.sinkhole_speed_time )
		end
		return 
	end 

	--  sink player
	guthscp106.sink_to_dimension( ent )

	local owner = self:GetOwner()
	if IsValid( owner ) then
		owner:PrintMessage( HUD_PRINTTALK, "Someone fell into your dimension" )
	end
end

function ENT:EndTouch( ent )
	if not ent:IsPlayer() then return end
	if guthscp106.get_walking_sinkhole( ent ) ~= self then return end

	guthscp106.set_walking_sinkhole( ent, nil )
end

--  TODO: remove
function ENT:Use( ent )
	if not guthscp106.is_scp_106( ent ) then return end

	PrintMessage( HUD_PRINTTALK, "Use: " .. tostring( ent ) )
	guthscp106.sink_to_dimension( ent )
end