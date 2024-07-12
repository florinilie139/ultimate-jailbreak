/* AMX Mod X
*   Zoom Info
*
* (c) Copyright 2007 by VEN
*
* This file is provided as is (no warranties)
*/

// plugin's main information
#define PLUGIN_NAME "Zoom Info"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

#include <amxmodx>
#include <fakemeta>

#define HUDMSG_X 0.02
#define HUDMSG_Y 0.7

#define SET_HUDMSG(%1,%2) set_hudmessage(%1, %2, 0, HUDMSG_X, HUDMSG_Y, 0, 0.0, 0.1, 0.0, 0.0, 4)

#define FOV_DEFAULT 90
#define FOV_ZOOM_X3 15

// ported statsx.sma distance() function
#define UNITS_TO_METERS(%1) ((%1) * 0.0254)

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_forward(FM_PlayerPostThink, "fwPlayerPostThink")
}

public fwPlayerPostThink(id) {
	static fov
	if ((fov = pev(id, pev_fov)) >= FOV_DEFAULT || !fov)
		return FMRES_IGNORED

	static Float:units, player
	units = get_user_aiming(id, player, _:units)
	if (!is_user_alive(player))
		SET_HUDMSG(255, 255)
	else if (get_user_team(id) == get_user_team(player))
		SET_HUDMSG(0, 255)
	else
		SET_HUDMSG(255, 0)

	show_hudmessage(id, "Zoom: x%d (%ddeg)^nDistance: %.1fm (%.1fu)", fov <= FOV_ZOOM_X3 ? 3 : 2, fov, UNITS_TO_METERS(units), units)

	return FMRES_IGNORED
}
