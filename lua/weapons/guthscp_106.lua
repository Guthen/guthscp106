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
	
	--  check target is a living entity
	local ply = self:GetOwner()
	local target = guthscp.world.player_trace_attack( ply, config.distance_unit, config.attack_hull_size ).Entity
	if not IsValid( target ) or not guthscp.world.is_living_entity( target ) then 
		self:SetNextPrimaryFire( CurTime() + 0.1 )
		return 
	end
	self:SetNextPrimaryFire( CurTime() + 1.0 )

	--  depending on config, avoid attacking SCPs Teams
	if not config.dimension_can_attack_scps and guthscp.is_scp( target ) then return end
	if guthscp106.is_sinking( target ) then return end

	--  TODO: in-pocket-dimension condition
	if guthscp106.is_in_pocket_dimension( target ) then
		--  deal different damage in pocket dimension
		if config.attack_damage_in_dimension > 0.0 then
			target:TakeDamage( config.attack_damage_in_dimension, ply, self )
		end
	else
		--  teleport and damage
		guthscp106.sink_to_dimension( target )
		guthscp106.play_corrosion_sound( self )

		if config.attack_damage > 0.0 then
			target:TakeDamage( config.attack_damage, ply, self )
		end
	end
end

function SWEP:SecondaryAttack()
	if not SERVER then return end

	--  play sound
	local ply = self:GetOwner()
	guthscp.sound.play( ply, config.sound_laugh, config.sound_hear_distance, false, config.sound_laugh_volume )

	self:SetNextSecondaryFire( CurTime() + 2.0 )
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
end

function SWEP:Deploy()
	self.GuthSCPLVL = config.keycard_level
end

local can_reload = true
function SWEP:Reload()
	if not CLIENT then return end

	local ply = LocalPlayer()
	if guthscp106.is_sinking( ply ) then return end

	--  handle reload cooldown
	if not can_reload then return end
	can_reload = false
	timer.Simple( .5, function() can_reload = true end )
	
	--  setup vars
	local is_containing = guthscp106.is_containing( ply )
	local is_contained = config.auto_disable_abilities and guthscp106.is_in_containment_cell( ply )
	local is_in_pocket_dimension = guthscp106.is_in_pocket_dimension( ply )

	local function create_sinkhole_option( slot )
		local name = slot == guthscp106.SINKHOLE_SLOTS.A and "A" or "B"
		return {
			init = function( button )
				local sinkhole = guthscp106.get_sinkhole( ply, slot )

				if is_in_pocket_dimension then
					button:SetText( "Go To Sinkhole " .. name )
					button:SetEnabled( IsValid( sinkhole ) )
				else
					button:SetText( "Place Sinkhole " .. name )

					if IsValid( sinkhole ) then
						button:SetColor( Color( 0, 200, 0 ) )
					else
						button:SetColor( Color( 200, 0, 0 ) )
					end
				end

				if is_containing or is_contained then
					button:SetEnabled( false )
				end
			end,
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES["SINKHOLE_" .. name] )
			end,
		}
	end

	--  setup menu options
	local options = {
		create_sinkhole_option( guthscp106.SINKHOLE_SLOTS.A ),
		{
			init = function( button )
				button:SetText( "Enter Pocket Dimension" )
				button:SetEnabled( not is_in_pocket_dimension )

				if is_containing or is_contained then
					button:SetEnabled( false )
				end
			end,
			action = function()
				guthscp106.use_ability( guthscp106.ABILITIES.ENTER_DIMENSION )
			end,
		},
		create_sinkhole_option( guthscp106.SINKHOLE_SLOTS.B ),
	}

	--  show menu
	guthscp106.open_custom_menu( "Abilities", options, IN_RELOAD )
end

--  add to spawnmenu
if CLIENT and guthscp then
	guthscp.spawnmenu.add_weapon( SWEP, "SCPs" )
end