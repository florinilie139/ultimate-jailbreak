#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <fun>

#define PLUGIN "Semiclip"
#define VERSION "1.0"
#define AUTHOR "coderiz & Xalus"

new bool:playerSemiclip[33]
new Float:playerDelay[33]

new intTerrorist

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Register: Forward
	register_forward(FM_PlayerPreThink, "preThink")
	register_forward(FM_PlayerPostThink, "postThink")
	
	// Register: Ham
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn", 1)
	
	RegisterHam(Ham_Touch, "func_door", "Ham_Semiclip_Touched", 1)
	RegisterHam(Ham_Touch, "func_door_rotating", "Ham_Semiclip_Touched", 1)
	RegisterHam(Ham_Touch, "func_train", "Ham_Semiclip_Touched", 1)
	RegisterHam(Ham_Touch, "func_rotating", "Ham_Semiclip_Touched", 1)
	RegisterHam(Ham_Touch, "func_tank", "Ham_Semiclip_Touched", 1)
}
/* Semiclip:
	- Fakemeta
*/
public preThink(id)
{
	if(playerSemiclip[id])
		return
		
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_solid, SOLID_SLIDEBOX)
}
public postThink(id)
{
	if(playerSemiclip[id]) 
		return

	if(!is_user_alive(id))
		return
		
	if(!is_wall_between_points(id, intTerrorist))
	{
		set_pev(id, pev_solid, SOLID_NOT)
	}
}
/* Semiclip:
	- Hamsandwich
*/
public Ham_PlayerSpawn(id)
{
	if(is_user_alive(id) && !is_user_bot(id))
	{
		set_user_rendering(id)
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		
		playerSemiclip[id] = bool:(cs_get_user_team(id) == CS_TEAM_T)

		if(playerSemiclip[id])
			intTerrorist = id
		else
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 85)
	}
}

public Ham_Semiclip_Touched(entity, id)
{
	if(pev_valid(entity) && is_user_alive(id))
	{
		new Float:flGametime = get_gametime()
		if(playerDelay[id] > flGametime)
			return
			
		playerDelay[id] = flGametime + 1.0
		
		new Float:flOrigin[3]
		pev(id, pev_origin, flOrigin)
		
		if(!is_hull_vacant(flOrigin, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id))
		{
			ExecuteHamB(Ham_TakeDamage, id, entity, entity, 100.0, DMG_CRUSH)
		}
	}
}

/* Semiclip:
	- Stocks
*/
stock bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
		return true
	
	return false
}

stock is_wall_between_points(id, entity)
{
	if(!is_user_alive(entity))
		return 0
	
	new ptr = create_tr2()
 
	new Float:start[3], Float:end[3], Float:endpos[3]
	pev(id, pev_origin, start)
	pev(entity, pev_origin, end)
	
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, id, ptr)
 
	get_tr2(ptr, TR_vecEndPos, endpos)
	
	free_tr2(ptr)
	
	return xs_vec_equal(end, endpos)
}
