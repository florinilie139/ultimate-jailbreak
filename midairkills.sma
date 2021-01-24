#define PLUGINNAME	"Mid-air kills"
#define VERSION		"0.1"
#define AUTHOR		"JGHG"

// plugin topic: http://www.amxmodx.org/forums/viewtopic.php?p=93809

#include <amxmodx>
#include <engine>
#include <ujbm>

public MidAirKill

public eDeathMsg() {
	new killerId = read_data(1)
	if (killerId == 0)
		return PLUGIN_CONTINUE
		
    if (get_user_weapon(killerId) == CSW_KNIFE)
        return PLUGIN_CONTINUE
	
    new g_GameMode = get_gamemode()
    if(g_GameMode != 0 && g_GameMode != 1)
        return PLUGIN_CONTINUE

	new victimId = read_data(2)
	new bool:enemykill = (get_user_team(killerId) != get_user_team(victimId))

	// Only if stats enabled
	// Only if killed by enemy
	// Only if victim wasn't swimming
	// Only if victim wasn't on ground
	if (!MidAirKill || !enemykill || entity_get_int(victimId, EV_INT_flags) & FL_ONGROUND)
		return PLUGIN_CONTINUE /* && !(entity_get_int(victimId, EV_INT_movetype) & FL_SWIM)*/

	new Float:victimOrigin[3]
	entity_get_vector(victimId, EV_VEC_origin, victimOrigin)
	victimOrigin[2] = victimOrigin[2] - 46.0 // Should be enough to get somewhere at feet... maybe :-P didn't bother checking exact distance feet->user origin
	new contents = point_contents(victimOrigin)

	// Only if contents are CONTENTS_EMPTY or CONTENTS_SKY
	if (contents != CONTENTS_EMPTY && contents != CONTENTS_SKY && contents != CONTENTS_LADDER)
		return PLUGIN_CONTINUE

	new victimName[32], killerName[32]
	get_user_name(victimId, victimName, 31)
	get_user_name(killerId, killerName, 31)

	new Float:lowOrigin[3], /*hitIndex,*/ Float:hitOrigin[3]
	//entity_get_vector(victimId, EV_VEC_origin, victimOrigin)
	lowOrigin[0] = victimOrigin[0]
	lowOrigin[1] = victimOrigin[1]
	lowOrigin[2] = -2000.0 // how low can you go, really, MISTER???
	/*hitIndex = */
	trace_line(victimId, victimOrigin, lowOrigin, hitOrigin)
	new Float:distanceToGround = vector_distance(victimOrigin, hitOrigin)

	new headshot = read_data(3)
	if (headshot) {
		//server_print("%s picked %s's head out of the sky! (%.0f units from ground)", killerName, victimName, distanceToGround)
		client_print(0, print_chat, "%s era in aer cand %s i-a spart capul! (%.0f unitati inaltime)", victimName, killerName, distanceToGround)
		server_cmd("give_points %d 3", killerId)
	}
	else {
		//server_print("%s killed the flying bird %s! (%.0f units from ground)", killerName, victimName, distanceToGround)
		client_print(0, print_chat, "%s l-a omorat pe %s care era in aer! (%.0f unitati inaltime)", killerName, victimName, distanceToGround)
		server_cmd("give_points %d 1", killerId)
	}

	return PLUGIN_CONTINUE
}

public plugin_cfg() {
	server_cmd("amx_statscfg add MidAirKill MidAirKill")
}

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	register_event("DeathMsg", "eDeathMsg", "a")
}