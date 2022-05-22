if not GuthSCP or not GuthSCP.Config then
    error( "[VKX SCP 106] '[SCP] Guthen's Addons Base' (https://steamcommunity.com/sharedfiles/filedetails/?id=2139692777) is not installed on the server, the addon won't work as intended, please install the base addon." )
    return
end

--  functions
function GuthSCP.isSCP106( ply )
    ply = ply or CLIENT and LocalPlayer() 
    return ply:Team() == GuthSCP.Config.vkxscp106.team or ( GuthSCP.isSCP( ply ) and ply:HasWeapon( "vkx_scp_106" ) )
end

hook.Add( "ShouldCollide", "vkxscp106:nocollide", function( ent_1, ent_2 )
    if ent_1:IsPlayer() and GuthSCP.isSCP106( ent_1 ) then
        if GuthSCP.Config.vkxscp106.traversable_entity_classes[ent_2:GetClass()] then
            return false
        end
    end
end )

--  config
hook.Add( "guthscpbase:config", "vkxscp106", function()

    GuthSCP.addConfig( "vkxscp106", {
        label = "SCP-106",
        icon = "icon16/user_gray.png",
        elements = {
            {
                type = "Form",
                name = "Configuration",
                elements = {
                    {
                        type = "Category",
                        name = "General",
                    },
                    GuthSCP.createTeamsConfigElement( {
                        type = "ComboBox",
                        name = "SCP-106 Team",
                        id = "team",
                        default = "TEAM_SCP106",
                    } ),
                    {
                        type = "CheckBox",
                        name = "No-Clip",
                        id = "noclip",
                        desc = "If checked, SCP-106 will be able to noclip at his will",
                        default = true,
                    },
                    GuthSCP.maxKeycardLevel and {
                        type = "NumWang",
                        name = "Keycard Level",
                        id = "keycard_level",
                        desc = "Compatibility with my keycard system. Set a keycard level to SCP-106's swep",
                        default = 5,
                        min = 0,
                        max = GuthSCP.maxKeycardLevel,
                    },
                    {
                        type = "TextEntry[]",
                        name = "Traversable Entity Classes",
                        id = "traversable_entity_classes",
                        desc = "List of entity classes that SCP-106 can walk through",
                        default = {
                            "func_door",
                            "func_button",
                            "prop_physics",
                            "prop_physics_multiplayer",
                            "prop_dynamic",
                            "prop_static",
                            "prop_door_rotating",
                            "prop_vehicle_jeep",
                        },
                        value = function( value, key )
                            return key
                        end,
                    },
                    {
                        type = "Category",
                        name = "Sounds",
                    },
                    {
                        type = "NumWang",
                        name = "Hear Distance",
                        id = "sound_hear_distance",
                        desc = "Maximum distance where you can hear SCP-106's sounds",
                        default = 2048,
                    },
                    {
                        type = "TextEntry",
                        name = "Idle",
                        id = "sound_idle",
                        desc = "Looped-sound played in idle state",
                        default = "guthen_scp/106/breathing.ogg",
                    },
                    {
                        type = "TextEntry[]",
                        name = "Footstep",
                        id = "sounds_footstep",
                        desc = "Sounds randomly played when SCP-106 move. Remove all elements to disable the custom footstep sounds",
                        default = {
                            "guthen_scp/106/steppd1.ogg", --  'pd' for Pocket Dimension, not for something else
                            "guthen_scp/106/steppd2.ogg",
                            "guthen_scp/106/steppd3.ogg",
                        },
                    },
                    {
                        type = "Button",
                        name = "Apply",
                        action = function( form, serialize_form )
                            GuthSCP.sendConfig( "vkxscp106", serialize_form )
                        end,
                    },
                }
            },
        },
        receive = function( form )
            GuthSCP.applyConfig( "vkxscp106", form, {
                network = true,
                save = true,
            } )
        end,
        parse = function( form )
            if #form.traversable_entity_classes > 0 then  --  avoid empty and sequential tables
                form.traversable_entity_classes = GuthSCP.valuesToKeysTable( form.traversable_entity_classes )
                form.traversable_entity_classes[""] = nil --  remove nil values
            end
            
            if isstring( form.team ) then
                form.team = _G[form.team]
            end
        end,
    } )

end )