/* AMX Mod X
*   Juicy Corpse
*
* (c) Copyright 2006 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION/USAGE
*       Just use the dead player's body to regain your health.
*       But be careful, other players may hear your greedy suction.
*       Corpses are juicy! :-P
*
*     MODULES
*       fakemeta 1.71+
*
*     MODS SUPPORT
*       Plugin probably will work for some of the Game Mods but tested only on CS1.6.
*       Plugin will not work for Mods with instant respawn style.
*       Juice indicator bar will not shown for all Mods.
*       For Half-Life plugin will not work when player force respawn after his death.
*
*     CVARs
*       jc_total_juice (default: 30) - total amount of a corpse's juice
*       jc_suction_amount (default: 3) - amount of restored health per suction
*
*     VERSIONS
*       0.3   added jc_total_juice and jc_suction_amount CVARs
*             added check of possibility of displaying indicator
*             suction sounds auto channeled now
*       0.2   added juice indicator bar
*             added hungry say text (disabled by default)
*       0.1   first release
*
*     IDEA/REQUEST
*       Manikstor
*/

/* *************************************************** Init **************************************************** */

#include <amxmodx>	// AMX Mod X 1.71+ required, check your addons/metamod/plugins.ini
#include <fakemeta>	// fakemeta module required, check your configs/modules.ini
#include <xs>		// this is not a module!

// plugin's main information
#define PLUGIN_NAME "Juicy Corpse"
#define PLUGIN_VERSION "0.3"
#define PLUGIN_AUTHOR "VEN"

// OPTIONS BELOW

// uncomment to enable hungry person's say text at the start of a suction
//#define HUNGRY_PHRASE_ENABLED

#if defined HUNGRY_PHRASE_ENABLED
	// hungry person will say that at the start of a suction
	new HUNGRY_PHRASE[] = "Mmmmm... Im Hungry, Time To Eat!"
#endif

// max. allowed distance from a hungry person to a juicy corpse
#define MAX_DISTANCE 70

// max. allowed angle difference between hungry person's view vector and corpse's position
#define MAX_VIEWANGLE_DIFF 35

// suction time interval (float seconds)
#define SUCTION_INTERVAL 1.0

// health restore limit (float units)
#define HEALTH_LIMIT 100.0

// suction sound files, can be changed to the custom (will be precached)
#define SUCTION_SOUND_NUM 8
new SUCTION_FILE[SUCTION_SOUND_NUM][] = {
	"zombie/zo_alert10.wav",
	"zombie/zo_alert20.wav",
	"zombie/zo_alert30.wav",
	"zombie/zo_attack2.wav",
	"zombie/zo_idle1.wav",
	"zombie/zo_idle2.wav",
	"zombie/zo_idle3.wav",
	"zombie/zo_idle4.wav"
}

// name of the CVAR which controls total amount of a corpse's juice
#define CVAR_TOTAL_JUICE_NAME "jc_total_juice"

// default value of the "jc_total_juice" CVAR
#define CVAR_TOTAL_JUICE_DEF "30"

// name of the CVAR which controls amount of restored health per suction
#define CVAR_SUCTION_AMOUNT_NAME "jc_suction_amount"

// default value of the "jc_suction_amount" CVAR
#define CVAR_SUCTION_AMOUNT_DEF "3"

// OPTIONS ABOVE

// calculates how much time required to suck out the full juice amount
// parameter1: suction amount; parameter2: total juice
#define FORMULA_TOTAL_SUCTION_TIME(%1,%2) floatround((SUCTION_INTERVAL / (%1)) * (%2))

// calculates the sucked out juice percent depending on the current juice amount
// parameter1: juice amount; parameter2: total juice
#define FORMULA_SUCKED_OUT_PERCENT(%1,%2) floatround((100.0 * ((%2) - (%1))) / (%2))

// few HLSDK constants
#define IN_USE (1<<5)
#define DEAD_DEAD 2

// use sound
new USE_SOUND[] = "common/wpn_denyselect.wav"

// used to retrieve corpse's position more accurately
#define DEAD_FLAG_CHECK_INTERVAL 0.5
#define DEAD_FLAG_CHECK_MAX_TIME 3.0

#define MAX_PLAYERS 32
new g_origin[MAX_PLAYERS + 1][3]
new g_juice[MAX_PLAYERS + 1]

new g_pcvar_total_juice
new g_pcvar_suction_amount

new g_msgid_bartime2

// precaching suction sounds
public plugin_precache() {
	for (new i = 0; i < SUCTION_SOUND_NUM; ++i)
		precache_sound(SUCTION_FILE[i])
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_event("ResetHUD", "event_hud_reset", "be")
	register_event("DeathMsg", "event_death", "a")

	register_forward(FM_EmitSound, "forward_emit_sound")

	g_pcvar_total_juice = register_cvar(CVAR_TOTAL_JUICE_NAME, CVAR_TOTAL_JUICE_DEF)
	g_pcvar_suction_amount = register_cvar(CVAR_SUCTION_AMOUNT_NAME, CVAR_SUCTION_AMOUNT_DEF)

	g_msgid_bartime2 = get_user_msgid("BarTime2")
}

/* *************************************************** Base **************************************************** */

public event_hud_reset(id) {
	g_juice[id] = 0
}

public event_death() {
	new id = read_data(2)

	if (task_exists(id))
		remove_task(id)

	set_task(DEAD_FLAG_CHECK_INTERVAL, "task_dead_flag_check", id, _, _, "b")
}

public client_disconnect(id) {
	g_juice[id] = 0

	if (task_exists(id))
		remove_task(id)
}

public task_dead_flag_check(id) {
	if (pev(id, pev_deadflag) == DEAD_DEAD || ++g_juice[id] * DEAD_FLAG_CHECK_INTERVAL > DEAD_FLAG_CHECK_MAX_TIME) {
		get_user_origin(id, g_origin[id])

		new Float:mins[3]
		pev(id, pev_mins, mins)
		g_origin[id][2] = g_origin[id][2] + 2 - floatround(fm_distance_to_foothold(id) - mins[2])

		g_juice[id] = get_pcvar_num(g_pcvar_total_juice)

		remove_task(id)
	}
}

public forward_emit_sound(id, channel, sound[]) {
	if (!id || !equali(sound, USE_SOUND) || !is_user_alive(id) || !(pev(id, pev_button) & IN_USE) || task_exists(id))
		return FMRES_IGNORED

	new Float:health
	pev(id, pev_health, health)
	if (health >= HEALTH_LIMIT)
		return FMRES_IGNORED

	new corpse = can_drink(id)
	if (!corpse)
		return FMRES_IGNORED

	if (g_msgid_bartime2) {
		new total = get_pcvar_num(g_pcvar_total_juice)
		msg_bartime2(id, FORMULA_TOTAL_SUCTION_TIME(get_pcvar_num(g_pcvar_suction_amount), total), FORMULA_SUCKED_OUT_PERCENT(g_juice[corpse], total))
	}

#if defined HUNGRY_PHRASE_ENABLED
	engclient_cmd(id, "say", HUNGRY_PHRASE)
#endif

	suction_sound(id)

	new param[2]
	param[0] = id
	param[1] = corpse
	set_task(SUCTION_INTERVAL, "task_drink_juice", id, param, 2, "b")

	return FMRES_SUPERCEDE
}

public task_drink_juice(param[2]) {
	new id = param[0]
	new corpse = param[1]

	if (is_user_alive(id) && (pev(id, pev_button) & IN_USE) && can_drink(id, corpse)) {
		new Float:health
		pev(id, pev_health, health)
		if (health < HEALTH_LIMIT) {
			suction_sound(id)
			new amount = get_pcvar_num(g_pcvar_suction_amount)
			set_pev(id, pev_health, health + amount)
			g_juice[corpse] -= amount

			return
		}
	}

	if (g_msgid_bartime2)
		msg_bartime2(id, 0, 0)

	remove_task(id)
}

can_drink(id, corpse = 0) {
	new origin[3], Float:fcorpsepos[3]
	get_user_origin(id, origin)
	for (new i = 1; i <= MAX_PLAYERS; ++i) {
		if (g_juice[i] <= 0 || get_distance(origin, g_origin[i]) > MAX_DISTANCE)
			continue

		fm_IVecFVec(g_origin[i], fcorpsepos)
		if (!fm_is_visible(id, fcorpsepos) || get_view_angle_diff(id, fcorpsepos) > MAX_VIEWANGLE_DIFF)
			continue

		if (!corpse || corpse == i)
			return i
	}

	return 0
}

suction_sound(id) {
	emit_sound(id, CHAN_AUTO, SUCTION_FILE[random(SUCTION_SOUND_NUM)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

/* ************************************************** Stocks *************************************************** */

// copies integer vector to a float vector
stock fm_IVecFVec(const IVec[3], Float:FVec[3]) {
	FVec[0] = float(IVec[0])
	FVec[1] = float(IVec[1])
	FVec[2] = float(IVec[2])

	return 1
}

// check whether no obstacles between eyes and given point
stock bool:fm_is_visible(index, const Float:point[3]) {
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, eyespos)

	engfunc(EngFunc_TraceLine, eyespos, point, 0, index)

	new Float:fraction
	global_get(glb_trace_fraction, fraction)
	if (fraction == 1.0)
		return true

	return false
}

// returns a float degree angle between view vector and given point
stock Float:get_view_angle_diff(index, Float:vec_c[3]) {
	new Float:vec_a[3], Float:vec_b[3], viewend[3]
	new Float:origin[3], Float:view_ofs[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, vec_a)

	get_user_origin(index, viewend, 3)
	fm_IVecFVec(viewend, vec_b)

	new Float:a = get_distance_f(vec_b, vec_c)
	new Float:b = get_distance_f(vec_a, vec_c)
	new Float:c = get_distance_f(vec_a, vec_b)

	return floatacos((b*b + c*c - a*a) / (2 * b * c), _:degrees)
}

// returns a float distance to the further/current foothold
// will not work if all points of the further/current contact base's horizontal plane is fully projects to the player's feet base
stock Float:fm_distance_to_foothold(index) {
	new Float:mins[3], Float:maxs[3]
	pev(index, pev_absmin, mins)
	pev(index, pev_absmax, maxs)

	new Float:start[3]
	start[1] = mins[1]
	start[2] = mins[2] + 10

	new Float:dest[3], Float:end[3]
	dest[1] = mins[1]
	dest[2] = -8191.0

	new index[4] = {0, 0, 1, 0}, Float:value[4]
	value[0] = mins[0]
	value[1] = maxs[0]
	value[2] = maxs[1]
	value[3] = mins[0]
	new Float:ret = -8191.0

	for (new i = 0; i < 4; ++i) {
		start[index[i]] = value[i]
		dest[index[i]] = value[i]
		engfunc(EngFunc_TraceLine, start, dest, 0, index)
		global_get(glb_trace_endpos, end)
		if (end[2] > ret)
			ret = end[2]
	}

	ret = mins[2] - ret

	return ret > 0 ? ret : 0.0
}

// used to indicate the amount of the corpse's sucked out juice
stock msg_bartime2(index, scale, start_percent) {
	message_begin(MSG_ONE, g_msgid_bartime2, _, index)
	write_short(scale)
	write_short(start_percent)
	message_end()
}

/* **************************************************** EOF **************************************************** */
