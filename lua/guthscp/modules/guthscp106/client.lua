local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

function guthscp106.open_custom_menu( title, options, hold_key )
	local ply = LocalPlayer()

	local options_buttons = {}
	local size = ScrW() * 0.1

	--  init frame
	local frame = vgui.Create( "DFrame" )
	frame:SetTall( size )
	frame:SetTitle( title )
	frame:SetDraggable( false )
	frame:MakePopup()
	function frame:Think()
		if not ply:KeyDown( hold_key ) then
			for i, button in ipairs( options_buttons ) do
				if not button:IsEnabled() or not button:IsHovered() then continue end

				button:DoClick()
			end

			self:Remove()
		end
	end

	--  create options buttons
	for i, option in ipairs( options ) do
		local button = frame:Add( "DButton" )
		button:Dock( LEFT )
		button:SetWide( size - 32 )
		button:DockMargin( 0, 0, 4, 0 )

		--  custom initialize
		option.init( button )

		function button:DoClick()
			--  custom action
			option.action()

			frame:Remove()
		end

		options_buttons[i] = button
	end

	--  size frame to children and center
	frame:InvalidateLayout( true )
	frame:SizeToChildren( true, false )
	frame:Center()
end

hook.Add( "HUDPaint", "guthscp106:sinkholes", function()
	if not config.sinkhole_hud_enabled then return end
	if not guthscp106.is_scp_106() then return end

	local ply = LocalPlayer()
	local eye_pos = ply:EyePos()
	local aim = ply:GetAimVector()

	local font = config.sinkhole_hud_font
	surface.SetFont( font )
	local _, font_height = surface.GetTextSize( "A" )

	for slot_id, slot in pairs( guthscp106.SINKHOLE_SLOTS ) do
		local sinkhole = guthscp106.get_sinkhole( ply, slot )
		if not IsValid( sinkhole ) then continue end

		--  convert position to screen
		local pos = sinkhole:GetPos()
		local screen_pos = pos:ToScreen()
		if not screen_pos.visible then continue end

		--  get direction and distance from eye 
		local dir = pos - eye_pos
		local dir_length = dir:Length()
		local normalized_dir = dir / dir_length

		local alpha = config.sinkhole_hud_alpha

		--  dot product aim & direction and compute alpha out of it
		if config.sinkhole_hud_dynamic_alpha_enabled then
			local min_value = config.sinkhole_hud_minimum_dot
			local dot = math.abs( math.max( min_value, normalized_dir:Dot( aim ) ) )
			alpha = math.Remap( dot, min_value, 1.0, config.sinkhole_hud_minimum_alpha, config.sinkhole_hud_alpha )
		end

		--  get drawing colors
		local text_color = ColorAlpha( config.sinkhole_hud_text_color, alpha )
		local outline_color = ColorAlpha( config.sinkhole_hud_outline_text_color, alpha )
		local text_line = 0

		--  draw name
		draw.SimpleTextOutlined( "Sinkhole " .. slot_id, font, screen_pos.x, screen_pos.y, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1.0, outline_color )
		text_line = text_line + 1

		--  draw distance in meters
		local meters = dir_length / 52.5
		if config.sinkhole_hud_show_distance and meters > 5 then
			local text = ( "%dm" ):format( meters )
			draw.SimpleTextOutlined( text, font, screen_pos.x, screen_pos.y + text_line * font_height, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1.0, outline_color )
			text_line = text_line + 1
		end

		--  draw preys counter
		local preys_count = sinkhole:GetNearbyPreysCount()
		if preys_count > 0 then
			text_color = guthscp.helpers.lerp_color( math.abs( math.sin( CurTime() * 3.0 ) ), config.sinkhole_hud_prey1_text_color, config.sinkhole_hud_prey2_text_color )
			outline_color = config.sinkhole_hud_outline_text_color

			local text = ( "%d preys!" ):format( preys_count )
			draw.SimpleTextOutlined( text, font, screen_pos.x, screen_pos.y + ( text_line + 0.5 ) * font_height, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1.0, outline_color )
			text_line = text_line + 1
		end
	end
end )