AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

util.AddNetworkString( "guthscp106:sinkhole" )

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

	--  find nearby humans
	if IsValid( owner ) and config.sinkhole_signal_distance > 0 then
		local count = 0

		--  count
		for i, ent in ipairs( ents.FindInSphere( self:GetPos(), config.sinkhole_signal_distance ) ) do
			if not ent:IsPlayer() then continue end
			if guthscp106.is_sinking( ent ) then continue end
			if guthscp.is_scp( ent ) then continue end

			count = count + 1
		end

		--  update and network
		if count ~= self:GetNearbyPreysCount() then
			self:SetNearbyPreysCount( count )
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

	guthscp106.set_walking_sinkhole( ent, self )
end

function ENT:Touch( ent )
	if self:IsQueueRemoved() then return end

	--  check entity is targetable
	if not guthscp.world.is_living_entity( ent ) then return end
	if guthscp106.is_scp_106( ent ) then return end
	if guthscp106.is_sinking( ent ) then return end

	--  check sink distance
	local dist = config.sinkhole_size * config.sinkhole_distance_ratio * 0.5
	if ent:GetPos():DistToSqr( self:GetPos() ) >= dist * dist then
		--  slow players
		if ent:IsPlayer() then
			guthscp.apply_player_speed_modifier( ent, "guthscp106-sinkhole", config.sinkhole_trigger_speed_factor, config.sinkhole_speed_time )
		end
		return
	end

	--  check config allow sinking entities
	if not config.sinkhole_can_sink then return end

	--  sink player
	guthscp106.sink_to_dimension( ent )
	guthscp106.play_corrosion_sound( self )

	--  alert owner
	local owner = self:GetOwner()
	if IsValid( owner ) then
		guthscp.player_message( owner, "Someone fell into your dimension" )
	end
end

function ENT:EndTouch( ent )
	if not ent:IsPlayer() then return end
	if guthscp106.get_walking_sinkhole( ent ) ~= self then return end

	guthscp106.set_walking_sinkhole( ent, nil )
end

function ENT:UpdateTransmitState()
	--  set as always so GetNearbyPreysCount
	return TRANSMIT_ALWAYS
end

local authorized_players = {}
function ENT:Use( ent )
	if self:IsQueueRemoved() then return end
	if self.IsUseDisabled then return end

	if not guthscp106.is_scp_106( ent ) then return end
	if guthscp106.is_sinking( ent ) then return end

	net.Start( "guthscp106:sinkhole" )
		net.WriteEntity( self )
	net.Send( ent )

	authorized_players[ent] = {
		time = CurTime(),
		sinkhole = self,
	}
end

local MAX_AUTHORIZATION_TIME = 30  	--  30 seconds for using the sinkhole, should be more than enough
local MAX_DISTANCE_SQR = 128 * 128  --  128 hammer units of maximum distance
net.Receive( "guthscp106:sinkhole", function( len, ply )
	--  securiy checks
	local data = authorized_players[ply]
	if not data then
		guthscp106:warning( "%s (%s) tried to use a sinkhole while not being authorized!", ply:GetName(), ply:SteamID() )
		return
	end
	if CurTime() - data.time > MAX_AUTHORIZATION_TIME then
		guthscp106:warning( "%s (%s) tried to use a sinkhole while being out of authorization time!", ply:GetName(), ply:SteamID() )
		return
	end
	if not IsValid( data.sinkhole ) then
		guthscp106:warning( "%s (%s) tried to use an invalid sinkhole!", ply:GetName(), ply:SteamID() )
		return
	end
	if data.sinkhole:GetPos():DistToSqr( ply:GetPos() ) > MAX_DISTANCE_SQR then
		guthscp106:warning( "%s (%s) tried to use a sinkhole while being too far!", ply:GetName(), ply:SteamID() )
		return
	end

	--  sink to dimension
	local is_going_to_dimension = net.ReadBool()
	if is_going_to_dimension then
		guthscp106.sink_to_dimension( ply )
	--  sink to the other sinkhole
	else
		local sinkhole_a = guthscp106.get_sinkhole( ply, guthscp106.SINKHOLE_SLOTS.A )
		local sinkhole_b = guthscp106.get_sinkhole( ply, guthscp106.SINKHOLE_SLOTS.B )
		local target_sinkhole = data.sinkhole == sinkhole_a and sinkhole_b or sinkhole_a
		if not IsValid( target_sinkhole ) then
			guthscp106:warning( "%s (%s) tried to use a sinkhole to sink to an invalid one!", ply:GetName(), ply:SteamID() )
			return
		end

		guthscp106.sink_to( ply, target_sinkhole:GetPos(), false, true )
	end

	--  reset authorization
	authorized_players[ply] = nil
end )