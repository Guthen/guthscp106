# [SCP] Enhanced SCP-106
## Steam Workshop
![Steam Views](https://img.shields.io/steam/views/1783768332?color=red&style=for-the-badge)
![Steam Downloads](https://img.shields.io/steam/downloads/1783768332?color=red&style=for-the-badge)
![Steam Favorites](https://img.shields.io/steam/favorites/1783768332?color=red&style=for-the-badge)

This addon is available on the Workshop [here](https://steamcommunity.com/sharedfiles/filedetails/?id=1783768332)!

## What is it ?
It's a SWEP which let SCP-106 to be great (again). He can pass through props (doors, spawned props..) (not the map because it's impossible to do it correctly), he can fly (BUT 106 DOESN'T FLY) (it should be use to get back to world from his dimension), it has a unique weapon that allow to him to send people (or himself) in his dimension or to laugh, he can breath (sound), he has footsteps sounds (and footsteps hints), he can't take damage (BECAUSE HE PASS THROUGH MATERIAL), and I think that it's.

## To get it to work
+ Create your TEAM_SCP106 job;
+ Set the Dimension position and some collisions to your map :
    + *guthscp_set_106_dimension* : set the dimension position to your current position
    + *guthscp_set_106_collide* : look at the map prop that you want to collide with 106 and enter this command, 106 shouldn't be able to pass through it.
    + *guthscp_set_106_uncollide* : look at the map prop that you want to uncollide with 106 and enter this command, 106 should be able to pass through it.
All is saved now, you don't have to worry about it.

## Known Issues
### "The SWEP is here but the whole script doesn't work"
For now, this mod is compatible only with team-based gamemodes such as **DarkRP** (not Sandbox). I planning on redo this addon to link it to [guthscpbase](https://github.com/Guthen/guthscpbase) and to improve the mod in general, so this issue will be fixed.

### "SCP-106 can't pass through doors and props"
First, this issue can be caused if SCP-106 didn't respawn when he take his job, so if you use DarkRP, be sure that **GM.Config.norespawn** is set to **false**. Also make sure that your SCP-106 job is named **TEAM_SCP106** in your DarkRP's jobs code.

Otherwise, this issue is mostly caused by an addon conflict. [CPTBase](https://steamcommunity.com/sharedfiles/filedetails/?id=470726908&searchtext=cptbase) is known to produce this problem, check this [topic](https://steamcommunity.com/workshop/filedetails/discussion/1783768332/5197701062327818946/) to  resolve this. If it still doesn't work, try this command in your server's console and write in the comment section what it returns (don't forget quotes around 'ShouldCollide') : 

```lua
lua_run for k, v in pairs( hook.GetTable()["ShouldCollide"] ) do local info = debug.getinfo( v, "S" ) print( k, ( "%s (lines %d to %d)" ):format( info.short_src, info.linedefined, info.lastlinedefined ) ) end
```

For curious, this code will only show other addons's files who use the same hook as mine with the code location.

## Legal Terms
This addon is licensed under [Creative Commons Sharealike 3.0](https://creativecommons.org/licenses/by-sa/3.0/) and is based on [SCP-106](http://scp-wiki.wikidot.com/scp-106) by "Dr Gears".
If you create something derived from this, please credit me (you can also tell me about what you've done).

Enjoy it !