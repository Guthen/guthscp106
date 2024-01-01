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