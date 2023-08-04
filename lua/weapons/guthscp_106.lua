if not guthscp then
	error( "guthscp106 - fatal error! https://github.com/Guthen/guthscpbase must be installed on the server!" )
	return
end

local guthscp106 = guthscp.modules.guthscp106
local config = guthscp.configs.guthscp106

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
	local trg = ply:GetEyeTrace().Entity
	if not trg:IsPlayer() or trg:GetPos():Distance( ply:GetPos() ) > 100 then 
		self:SetNextPrimaryFire( CurTime() + 0.1 )
		return 
	end

	self:SetNextPrimaryFire( CurTime() + 1.0 )
end

function SWEP:SecondaryAttack()
	if not SERVER then return end
	
	--  play sound
	local ply = self:GetOwner()
	if #config.sound_laugh > 0 then
		ply:EmitSound( config.sound_laugh )
	end

	self:SetNextSecondaryFire( CurTime() + 2.0 )
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
end

function SWEP:Deploy()
	self.GuthSCPLVL = config.keycard_level
end

local canReload = true
function SWEP:Reload()
	if not CLIENT then return end

	local buttons = {
		{
			text = "Enter Pocket Dimension",
			action = function()
				net.Start( "guthscp:106" )
					net.WriteBool( false )
				net.SendToServer()
			end
		},
		{
			text = "Exit Pocket Dimension",
			action = function()
				net.Start( "guthscp:106" )
					net.WriteBool( true )
				net.SendToServer()
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

--  nets
if SERVER then
	util.AddNetworkString( "guthscp:106" )

	net.Receive( "guthscp:106", function( len, ply )
		if not guthscp106.is_scp_106( ply ) then return end
		
		--  TODO: fix by creating functions
		local is_exit = net.ReadBool()
		if is_exit then 
			if not ply.SCP106LastPos then return end
			ply:SlowTo106( nil, ply.SCP106LastPos ) 
			ply.SCP106LastPos = nil
		else
			ply.SCP106LastPos = ply:GetPos()
			ply:SlowTo106()
		end
	end )
end

--  add to spawnmenu
if CLIENT and guthscp then
	guthscp.spawnmenu.add_weapon( SWEP, "SCPs" )
end