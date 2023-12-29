local MODULE = {
	name = "SCP-106",
	author = "Guthen",
	version = "2.0.0",
	description = [[Be SCP-106 and creep the fuck out of people!]],
	icon = "guthscp/icons/guthscp106.png",
	--version_url = "https://raw.githubusercontent.com/Guthen/guthscp173/update-to-guthscpbase-remaster/lua/guthscp/modules/guthscp173/main.lua",
	dependencies = {
		base = "2.0.0",
	},
	requires = {
		["shared.lua"] = guthscp.REALMS.SHARED,
		["server.lua"] = guthscp.REALMS.SERVER,
		--["client.lua"] = guthscp.REALMS.CLIENT,
	},
}

MODULE.ABILITIES = {
	ENTER_DIMENSION = 0,
	EXIT_DIMENSION = 1,
	PLACE_SINKHOLE = 2,
	ENTER_SINKHOLE = 3,
}
MODULE._ability_ubits = guthscp.helpers.number_of_ubits( MODULE.ABILITIES.ENTER_SINKHOLE )

MODULE.menu = {
	--  config
	config = {
		form = {
			--  general
			"General",
			{
				type = "Number",
				name = "Walk Speed",
				id = "walk_speed",
				desc = "Speed of walking for SCP-106, in hammer units",
				default = 130,
			},
			{
				type = "Number",
				name = "Run Speed",
				id = "run_speed",
				desc = "Speed of running for SCP-106, in hammer units",
				default = 130,
			},
			{
				type = "Bool",
				name = "No-Clip",
				id = "noclip",
				desc = "If checked, SCP-106 will be able to noclip",
				default = false,
			},
			{
				type = "Bool",
				name = "Immortal",
				id = "immortal",
				desc = "If checked, SCP-106 can't take damage",
				default = true,
			},
			{
				type = "Number",
				name = "Keycard Level",
				id = "keycard_level",
				desc = "Compatibility with my keycard system. Set a keycard level to SCP-106's swep",
				default = 5,
				min = 0,
				max = function( self, numwang )
					if self:is_disabled() then return 0 end
					
					return guthscp.modules.guthscpkeycard.max_keycard_level
				end,
				is_disabled = function( self, numwang )
					return guthscp.modules.guthscpkeycard == nil
				end,
			},
			"Pocket Dimension",
			{
				type = "Vector",
				name = "Teleport Position",
				id = "dimension_position",
				desc = "Position of the pocket dimension to teleport SCP-106 and his victims",
				default = vector_origin,
				show_usepos = true,
			},
			{
				type = "Number",
				name = "Corrosion Damage",
				id = "dimension_corrosion_damage",
				desc = "Scale of target's maximum health to apply as damage in the pocket dimension per second. By default, it is set to 1% of the maximum health. Set to 0.0 to disable the damage",
				default = 0.01,
				interval = 0.01,
				min = 0.0,
				max = 1.0,
			},
			{
				type = "Bool",
				name = "Can Corrode SCPs",
				id = "dimension_can_corrode_scps",
				desc = "If checked, the dimension can corrodes SCPs Teams",
				default = false,
			},
			"Weapon",
			{
				type = "Number",
				name = "Distance Unit",
				id = "distance_unit",
				desc = "Maximum distance where SCP-106 can attacks his targets. 1 meter ~= 40 unit",
				default = 50,
			},
			{
				type = "Number",
				name = "Attack Hull Size",
				id = "attack_hull_size",
				desc = "Size of tolerance for targeting in units. The higher the number, the easier it is to aim, but the less precise it is",
				default = 5,
			},
			{
				type = "Number",
				name = "Attack Damage",
				id = "attack_damage",
				desc = "Damage to apply when SCP-106 sends a target in the pocket dimension. Set to 0.0 to disable the damage",
				default = 20,
				min = 0.0,
			},
			{
				type = "Number",
				name = "Attack Damage in Dimension",
				id = "attack_damage_in_dimension",
				desc = "Damage to apply when SCP-106 attacks a target in the pocket dimension. Set to 0.0 to disable the damage",
				default = 80,
				min = 0.0,
			},
			{
				type = "Bool",
				name = "Can Attack SCPs",
				id = "dimension_can_attack_scps",
				desc = "If checked, SCP-106 can attacks SCPs Teams and teleports them in his dimension",
				default = false,
			},
			"Pass-through",
			{
				type = "String[]",
				name = "Entity Classes",
				id = "passthrough_entity_classes",
				desc = "List of entity classes that SCP-106 can pass-through",
				default = guthscp.table.create_set( {
					"func_door",
					"func_door_rotating",
					"func_button",
					"func_breakable",
					"prop_physics",
					"prop_physics_multiplayer",
					"prop_dynamic",
					"prop_static",
					"prop_door_rotating",
					"prop_vehicle_jeep",
				} ),
				is_set = true,
			},
			{
				type = "Bool",
				name = "Pass-through Living Entities",
				id = "passthrough_living_entities",
				desc = "Can SCP-106 pass-through players, NPCs and NextBots?",
				default = true,
			},
			{
				type = "Number",
				name = "Speed Factor",
				id = "passthrough_speed_factor",
				desc = "How much passing-through should scale SCP-106's movement speed? Set to 1.0 to prevent the modifier from applying",
				default = 0.7,
				interval = 0.1,
				min = 0.1,
			},
			{
				type = "Number",
				name = "Speed Exit Time",
				id = "passthrough_speed_time",
				desc = "If 'Speed Factor' different from 1.0, how much time should SCP-106's movement speed scale after ending its pass-through state? Must be above 0.",
				default = 0.1,
				interval = 0.1,
				min = 0.1,
			},
			"Sinkhole",
			{
				type = "Number",
				name = "Spawn Time",
				id = "sinkhole_anim_spawn_time",
				desc = "In seconds, how much time it takes for a sinkhole to do its spawn animation?",
				default = 2.0,
				min = 0.1,
			},
			{
				type = "Number",
				name = "Remove Time",
				id = "sinkhole_anim_remove_time",
				desc = "In seconds, how much time it takes for a sinkhole to do its remove animation?",
				default = 3.0,
				min = 0.1,
			},
			{
				type = "Number",
				name = "Size",
				id = "sinkhole_size",
				desc = "Size of sinkholes, in Hammer units",
				default = 100.0,
				min = 20.0,
			},
			{
				type = "Number",
				name = "Trigger Size Ratio",
				id = "sinkhole_trigger_size_ratio",
				desc = "Size of sinkholes hitbox in relation to their 'Size', in percent (changes need to re-create entities to take effect)",
				default = 0.8,
				min = 0.1,
				max = 1.0,
			},
			{
				type = "Number",
				name = "Speed Factor",
				id = "sinkhole_trigger_speed_factor",
				desc = "How much should walking on a sinkhole scale players movement speed? Set to 1.0 to prevent the modifier from applying",
				default = 0.6,
				interval = 0.1,
				min = 0.1,
			},
			{
				type = "Number",
				name = "Speed Exit Time",
				id = "sinkhole_speed_time",
				desc = "If 'Speed Factor' different from 1.0, how much time should players movement speed scale after ending walking on a sinkhole? Must be above 0.0",
				default = 0.1,
				interval = 0.1,
				min = 0.1,
			},
			{
				type = "Number",
				name = "Placement Distance",
				id = "sinkhole_placement_distance",
				desc = "In Hammer units, how much distance from another sinkhole is required to place one? Set to 0 to disable",
				default = 256,
				min = 0,
			},
			{
				type = "Bool",
				name = "Can Sink",
				id = "sinkhole_can_sink",
				desc = "Can sinkholes sink non-SCP-106 players in the Pocket Dimension?",
				default = true,
			},
			{
				type = "Number",
				name = "Sink Distance",
				id = "sinkhole_distance_ratio",
				desc = "If 'Can Sink' is enabled, distance for non-SCP-106 players to sink in sinkholes in relation to their 'Size', in percent. Must be lower than 'Trigger Size Ratio'",
				default = 0.2,
				min = 0.1,
				max = 1.0,
			},
			{
				type = "Number",
				name = "Offset Z-axis",
				id = "sinkhole_offset_z",
				desc = "In hammer units, the offset in the Z-axis to project the sinkhole on the surface",
				default = 32.0,
				min = 0.0,
			},
			"Sounds",
			{
				type = "Number",
				name = "Hear Distance",
				id = "sound_hear_distance",
				desc = "Maximum distance where you can hear SCP-106's sounds",
				default = 2048,
			},
			{
				type = "String",
				name = "Idle",
				id = "sound_idle",
				desc = "Looped-sound played in idle state",
				default = "guthen_scp/106/breathing.ogg",
			},
			{
				type = "Number",
				name = "Idle Volume",
				id = "sound_idle_volume",
				desc = "Volume of idle sound, from 0.0 to 1.0. Require a respawn as SCP-106 to take effect. Set to 0.0 to disable the idle sound.",
				default = 0.5,
				interval = 0.1,
				min = 0.0,
				max = 1.0,
			},
			{
				type = "String",
				name = "Laugh",
				id = "sound_laugh",
				desc = "Sound played when right-clicking with the SWEP",
				default = "guthen_scp/106/Laugh.ogg",
			},
			{
				type = "Number",
				name = "Laugh Volume",
				id = "sound_laugh_volume",
				desc = "Volume of laugh sound, from 0.0 to 1.0. Set to 0.0 to disable the laugh sound.",
				default = 1.0,
				interval = 0.1,
				min = 0.0,
				max = 1.0,
			},
			{
				type = "String[]",
				name = "Footstep",
				id = "sounds_footstep",
				desc = "Sounds randomly played when SCP-106 move. Remove all elements to disable the custom footstep sounds",
				default = {
					"guthen_scp/106/steppd1.ogg",
					"guthen_scp/106/steppd2.ogg",
					"guthen_scp/106/steppd3.ogg",
				},
			},
			{
				type = "Number",
				name = "Footstep Volume",
				id = "sound_footstep_volume",
				desc = "Volume of footstep sounds, from 0.0 to 1.0. Set to 0.0 to disable custom footstep sounds.",
				default = 0.8,
				interval = 0.1,
				min = 0.0,
				max = 1.0,
			},
			{
				type = "String[]",
				name = "Corrosion",
				id = "sounds_corrosion",
				desc = "Sounds randomly played when SCP-106 places a sinkhole",
				default = {
					"guthen_scp/106/corrosion1.ogg",
					"guthen_scp/106/corrosion2.ogg",
				},
			},
			{
				type = "Number",
				name = "Corrosion Volume",
				id = "sound_corrosion_volume",
				desc = "Volume of corrosion sounds, from 0.0 to 1.0. Set to 0.0 to disable corrosion sounds.",
				default = 0.8,
				interval = 0.1,
				min = 0.0,
				max = 1.0,
			},
		},
	},
	--  details
	details = {
		{
			text = "CC-BY-SA",
			icon = "icon16/page_white_key.png",
		},
		"Wiki",
		{
			text = "Read Me",
			icon = "icon16/information.png",
			url = "https://github.com/Guthen/guthscp106/blob/master/README.md",
		},
		"Social",
		{
			text = "Github",
			icon = "guthscp/icons/github.png",
			url = "https://github.com/Guthen/guthscp106",
		},
		{
			text = "Steam",
			icon = "guthscp/icons/steam.png",
			url = "https://steamcommunity.com/sharedfiles/filedetails/?id=1783768332"
		},
		{
			text = "Discord",
			icon = "guthscp/icons/discord.png",
			url = "https://discord.gg/Yh5TWvPwhx",
		},
		{
			text = "Ko-fi",
			icon = "guthscp/icons/kofi.png",
			url = "https://ko-fi.com/vyrkx",
		},
	},
}

function MODULE:init()
	--  TODO: porting old config file 
	--self:port_old_config_file( "guthscpbase/guthscp106.json" )

	--  create filter
	self.passthrough_filter = guthscp.map_entities_filter:new( "guthscp106_passthrough", "GuthSCP-106 Pass-through" )
end

guthscp.module.hot_reload( "guthscp106" )
return MODULE