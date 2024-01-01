include( "shared.lua" )

local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

function ENT:Initialize()
	self:FindPosAndNormal()

	--  setup cracks animation
	self.cracks_angle = math.random( 0, 360 )
	self.cracks_size = 0.0

	--  setup corrosion animation
	self.target_corrosion_angle = math.random( 0, 360 )
	self.start_corrosion_angle = self.target_corrosion_angle - 180
	self.corrosion_angle = self.start_corrosion_angle
	self.corrosion_size = 0.0

	--  adapt render bounds
	--  it avoids no-draw optimisation because its center is not looked at
	local size = config.sinkhole_size * 0.5
	local bounds = Vector( size, size, size )
	self:SetRenderBounds( -bounds, bounds )
end

function ENT:FindPosAndNormal()
	local pos = self:GetPos()
	local tr = util.TraceLine( {
		start = pos + Vector( 0, 0, config.sinkhole_offset_z ),
		endpos = pos - Vector( 0, 0, config.sinkhole_offset_z ),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	self.projected_pos, self.projected_normal = tr.HitPos, tr.HitNormal
end

function ENT:UpdateAnimation()
	local anim_ratio = 0.0
	local queue_remove_time = self:GetQueueRemoveTime()

	--  spawn anim
	if queue_remove_time <= -1.0 then
		local anim_time = config.sinkhole_anim_spawn_time
		anim_ratio = math.min( CurTime() - self:GetCreationTime(), anim_time ) / anim_time
	--  remove anim
	else
		local anim_time = config.sinkhole_anim_remove_time
		anim_ratio = math.min( queue_remove_time - CurTime(), anim_time ) / anim_time
	end

	--  update animation
	if anim_ratio < 1.0 or not ( self.cracks_size == 1.0 ) then
		self.cracks_size = Lerp( math.ease.OutExpo( anim_ratio ), 0.0, 1.0 )
		self.corrosion_size = Lerp( math.ease.InOutCubic( anim_ratio ), 0.0, 1.0 )
		self.corrosion_angle = Lerp( math.ease.OutQuad( anim_ratio ), self.start_corrosion_angle, self.target_corrosion_angle )
	end
end

local material_corrosion = Material( "guthscp/106/decal_corrosion" )
local material_cracks = Material( "guthscp/106/decal_cracks" )
function ENT:Draw()
	--debugoverlay.Axis( self:GetPos(), self:GetAngles(), 15.0, FrameTime() )
	--debugoverlay.Line( self:GetPos() - Vector( 0, 0, config.sinkhole_offset_z ), self:GetPos() + Vector( 0, 0, config.sinkhole_offset_z ), FrameTime(), Color( 255, 0, 0 ) )

	self:UpdateAnimation()
	
	local size = config.sinkhole_size
	local pos, normal = self.projected_pos, self.projected_normal

	--  cracks
	render.SetMaterial( material_cracks )
	render.DrawQuadEasy( pos, normal, self.cracks_size * size, self.cracks_size * size, color_white, self.cracks_angle )

	--  corrosion
	render.SetMaterial( material_corrosion )
	render.DrawQuadEasy( pos, normal, self.corrosion_size * size, self.corrosion_size * size, color_white, self.corrosion_angle )
end

net.Receive( "guthscp106:sinkhole", function()
	local ply = LocalPlayer()
	local sinkhole = net.ReadEntity()

	--  setup menu options
	local options = {
		{
			init = function( button )
				local sinkhole_a = guthscp106.get_sinkhole( ply, guthscp106.SINKHOLE_SLOTS.A )
				local sinkhole_b = guthscp106.get_sinkhole( ply, guthscp106.SINKHOLE_SLOTS.B )
				local target_sinkhole = sinkhole == sinkhole_a and sinkhole_b or sinkhole_a

				button:SetText( "Go To Sinkhole " .. ( sinkhole == sinkhole_a and "B" or "A" ) )
				button:SetEnabled( IsValid( target_sinkhole ) )
			end,
			action = function()
				net.Start( "guthscp106:sinkhole" )
					net.WriteBool( false )
				net.SendToServer()
			end,
		},
		{
			init = function( button )
				button:SetText( "Enter Pocket Dimension" )
			end,
			action = function()
				net.Start( "guthscp106:sinkhole" )
					net.WriteBool( true )
				net.SendToServer()
			end,
		},
	}

	--  show menu
	guthscp106.open_custom_menu( "Sinkhole", options, IN_USE )
end )