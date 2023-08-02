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

MODULE.menu = {
	--  config
	config = {
		form = {
			--  general
			"General",
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
			{
				type = "String[]",
				name = "Traversable Entity Classes",
				id = "traversable_entity_classes",
				desc = "List of entity classes that SCP-106 can walk through",
				default = guthscp.table.create_set( {
					"func_door",
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
				type = "String",
				name = "Laugh",
				id = "sound_laugh",
				desc = "Sound played when right-clicking with the SWEP",
				default = "guthen_scp/106/Laugh.ogg",
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
			guthscp.config.create_apply_button(),
			guthscp.config.create_reset_button(),
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