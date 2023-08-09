if not guthscp then
	error( "guthscp106 - fatal error! https://github.com/Guthen/guthscpbase must be installed on the server!" )
	return
end

local guthscp106 = guthscp.modules.guthscp106

AddCSLuaFile()

SWEP.PrintName				= "SCP-106"
SWEP.Author					= "Vyrkx A.K.A. Guthen"
SWEP.Instructions			= "Left click to send your victims in your dimension. Right click to laugh. Reload to send yourself to your dimension."
SWEP.Category 				= "GuthSCP"

SWEP.Spawnable 				= true
SWEP.AdminOnly 				= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight					= 1
SWEP.AutoSwitchTo			= true
SWEP.AutoSwitchFrom			= false

SWEP.Slot			   	 	= 1
SWEP.SlotPos				= 1
SWEP.DrawAmmo				= false
SWEP.DrawCrosshair			= false

SWEP.HoldType 				= "passive"

SWEP.ViewModel				= "models/weapons/v_hands.mdl"
SWEP.WorldModel				= ""

SWEP.GuthSCPLVL 		   	= 	0

function SWEP:PrimaryAttack()
	if not SERVER then return end
	
	local ply = self:GetOwner()
	local target = guthscp.world.player_trace_attack( ply, guthscp.configs.guthscp106.distance_unit, guthscp.configs.guthscp106.attack_hull_size ).Entity
	if not IsValid( target ) or not guthscp.world.is_living_entity( target ) then 
		self:SetNextPrimaryFire( CurTime() + 0.1 )
		return 
	end

	guthscp106.sink_to( target, guthscp.configs.guthscp106.dimension_position )
	self:SetNextPrimaryFire( CurTime() + 1.0 )
end

function SWEP:SecondaryAttack()
	if not SERVER then return end
	
	--  play sound
	local ply = self:GetOwner()
	if #guthscp.configs.guthscp106.sound_laugh > 0 then
		ply:EmitSound( guthscp.configs.guthscp106.sound_laugh )
	end

	self:SetNextSecondaryFire( CurTime() + 2.0 )
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
end

function SWEP:Deploy()
	self.GuthSCPLVL = guthscp.configs.guthscp106.keycard_level
end

local canReload = true
function SWEP:Reload()
	if not CLIENT then return end

	local buttons = {
		{
			text = "Enter Pocket Dimension",
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES.ENTER_DIMENSION )
			end
		},
		{
			text = "Exit Pocket Dimension",
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES.EXIT_DIMENSION )
			end
		},
		{
			text = "Place Waypoint",
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES.PLACE_SINKHOLE )
			end
		},
		{
			text = "Go to Waypoint",
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES.ENTER_SINKHOLE )
			end
		},
	}

	if not canReload then return end
	canReload = false
	timer.Simple( .5, function() canReload = true end )

	local w = ScrW() * .2

	--  init frame
	local frame = vgui.Create( "DFrame" )
	frame:SetWide( w )
	frame:SetTitle( "Pocket Dimension" )
	frame:SetDraggable( false )
	frame:MakePopup()

	--  actions group
	local label = frame:Add( "DLabel" )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 2 )
	label:SetText( "Actions" )
	label:SizeToContents()

	for i, v in ipairs( buttons ) do
		local button = frame:Add( "DButton" )
		button:Dock( TOP )
		button:DockMargin( 0, 0, 0, 2 )
		button:SetText( v.text )
		button.DoClick = v.action
	end

	--  size frame to children and center
	frame:InvalidateLayout( true )
	frame:SizeToChildren( false, true )
	frame:Center()
end

--  add to spawnmenu
if CLIENT and guthscp then
	guthscp.spawnmenu.add_weapon( SWEP, "SCPs" )
end