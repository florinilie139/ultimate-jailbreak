/*	Formatright © 2009, OT

	Peeking is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Migraine; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

/* [Plugin link]
	http://forums.alliedmods.net/showthread.php?t=132804
 */

/* [Changelog]
- 1.5  - added support for my block wallhack plugin!
- 1.4  - added wall detection via TRACE_HULL, the plugin is better closer to reality.
- 1.3  - +peekleft;+peekright commands for players that do want to use 2 keys! [You can move arround when using these two]
- 1.2  - changed the method of blocking so that the plugin can be easily adapted with other mods
- 1.1  - fixed client animation, added +canpeek command 
- 1.0  - initial release 
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN			"Peeking"
#define AUTHOR			"OT"
#define VERSION			"1.5"

#define MAX_PLAYERS 	32

#define MAX_ANGLE		60.0

#define angle_sin(%0,%1) xs_sin(%0 * float(%1) / 100.0, degrees)
#define angle_cos(%0,%1) xs_cos(%0 * float(%1) / 100.0, degrees)

new gBS_alive
new gBS_canpeek
new gI_peekPercent[MAX_PLAYERS + 1]
new gE_peekEnt[MAX_PLAYERS + 1]
new gB_BlockWallhack
new gI_MaxPlayers
new gI_peekDir[MAX_PLAYERS + 1] = {0, ...}

#define IN_PEEKLEFT							(1<<0)
#define IN_PEEKRIGHT						(1<<1)

#define add_alive(%1)						gBS_alive |= (1<<(%1 - 1))
#define add_dead(%1)						gBS_alive &= ~(1<<(%1 - 1))
#define is_alive(%1)						(gBS_alive & (1<<(%1 - 1)))

#define add_peek(%1)						gBS_canpeek |= (1<<(%1 - 1))
#define del_peek(%1)						gBS_canpeek &= ~(1<<(%1 - 1))
#define can_peek(%1)						(gBS_canpeek & (1<<(%1 - 1)))

const gBS_CanAttackWeapons = 				((1<<2) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_C4))

public plugin_precache()
{
    precache_model("models/rpgrocket.mdl")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_AddToFullPack, "pfw_AddToFullPack", 1)
	register_forward(FM_AddToFullPack, "fw_AddToFullPack")
	register_forward(FM_UpdateClientData, "pfw_UpdateClientData", 1)
	
	register_think("func_peek", "think_func_peek")

	RegisterHam(Ham_Spawn, "player", "pfw_PlayerHandleAD", 1)
	RegisterHam(Ham_Killed, "player", "pfw_PlayerHandleAD", 1)
	
	register_clcmd("+canpeek", "cmd_willpeek")
	register_clcmd("-canpeek", "cmd_stoppeek")
	
	register_clcmd("+peekleft", "cmd_peekleft")
	register_clcmd("-peekleft", "cmd_stopleft")
	register_clcmd("+peekright", "cmd_peekright")
	register_clcmd("-peekright", "cmd_stopright")
	
	gI_MaxPlayers = get_maxplayers()
	
	// A delayed init
	set_task(2.0, "plugin_dinit")
}

public plugin_dinit()
{
	// Here we check if we run my wallblocker, if yes then the plugin will send data to my plugin about attaching entities
	gB_BlockWallhack = cvar_exists("wallblocker_version")
	if (cvar_exists("trwb_version"))
		gB_BlockWallhack = 10000
}

public cmd_peekleft(id)
{
	gI_peekDir[id] |= IN_PEEKLEFT
	
	return PLUGIN_HANDLED
}

public cmd_stopleft(id)
{
	gI_peekDir[id] &= ~IN_PEEKLEFT
	
	return PLUGIN_HANDLED
}

public cmd_peekright(id)
{
	gI_peekDir[id] |= IN_PEEKRIGHT
	
	return PLUGIN_HANDLED
}

public cmd_stopright(id)
{
	gI_peekDir[id] &= ~IN_PEEKRIGHT
	
	return PLUGIN_HANDLED
}

public cmd_willpeek(id)
{
	add_peek(id)
	
	return PLUGIN_HANDLED
}

public cmd_stoppeek(id)
{
	del_peek(id)
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	if (gE_peekEnt[id])
		remove_entity(gE_peekEnt[id])
	
	gI_peekDir[id] = 0
	del_peek(id)
}

// Block client animation if we are peeking, also stop player from moving (if he uses the peek with one key)
public pfw_UpdateClientData(id, weapons, cd)
{
	if (gE_peekEnt[id])
	{
		set_cd(cd, CD_flNextAttack, 1.0)
		
		if (can_peek(id) && !(entity_get_int(id, EV_INT_button) & (IN_FORWARD | IN_BACK)))
			set_cd(cd, CD_MaxSpeed, 1.0)
	}
	
	return FMRES_IGNORED
}

// Alive/Dead handle
public pfw_PlayerHandleAD(id)
{
	if (is_user_alive(id))
	{
		add_alive(id)
	}
	else
	{
		add_dead(id)
		
		if (gE_peekEnt[id] != 0)
		{
			remove_entity(gE_peekEnt[id])
			AttachView(id, id)
			gE_peekEnt[id] = 0
			gI_peekPercent[id] = 0
		}
	}
	
	return HAM_IGNORED
}

// Count all the comands
public fw_CmdStart(id, uc, seed)
{
	if (!is_alive(id))
		return FMRES_IGNORED
	
	new iButtons = get_uc(uc, UC_Buttons)
	
	if (can_peek(id))
	{
		switch (iButtons & (IN_MOVERIGHT | IN_MOVELEFT | IN_FORWARD | IN_BACK))
		{
			case (IN_MOVERIGHT):
			{
				if (!gE_peekEnt[id])
					create_peek(id)
				
				if (gI_peekPercent[id] < 100)
					gI_peekPercent[id] += 4
			}
			
			case (IN_MOVELEFT):
			{
				if (!gE_peekEnt[id])
					create_peek(id)
				
				if (gI_peekPercent[id] > -100)
					gI_peekPercent[id] -= 4
			}
			
			default:
			{
				if (gI_peekPercent[id] == 0)
				{
					if (gE_peekEnt[id])
					{
						remove_entity(gE_peekEnt[id])
						AttachView(id, id)
						gE_peekEnt[id] = 0
					}
					
					return FMRES_IGNORED
				}
				
				if (0 < gI_peekPercent[id])
					gI_peekPercent[id] -= 4
				if (gI_peekPercent[id] < 0)
					gI_peekPercent[id] += 4
			}
		}
	}
	else
	{
		switch (gI_peekDir[id])
		{
			case IN_PEEKRIGHT:
			{
				if (!gE_peekEnt[id])
					create_peek(id)
				
				if (gI_peekPercent[id] < 100)
					gI_peekPercent[id] += 4
			}
			
			case IN_PEEKLEFT:
			{
				if (!gE_peekEnt[id])
					create_peek(id)
				
				if (gI_peekPercent[id] > -100)
					gI_peekPercent[id] -= 4
			}
			
			default:
			{
				if (gI_peekPercent[id] == 0)
				{
					if (gE_peekEnt[id])
					{
						remove_entity(gE_peekEnt[id])
						AttachView(id, id)
						gE_peekEnt[id] = 0
					}
					
					return FMRES_IGNORED
				}
				
				if (0 < gI_peekPercent[id])
					gI_peekPercent[id] -= 4
				if (gI_peekPercent[id] < 0)
					gI_peekPercent[id] += 4
			}
		}
	}
	
	if (gE_peekEnt[id])
	{
		new weapon = get_user_weapon(id)
		
		if (weapon == CSW_KNIFE)
			iButtons &= ~IN_ATTACK2
		
		if ((1<<weapon) & ~gBS_CanAttackWeapons)
			set_uc(uc, UC_Buttons, iButtons & ~(IN_ATTACK))
	}
	
	return FMRES_HANDLED
}

// Make the player invisible so that we will not get blocked by the model
public pfw_AddToFullPack(es, e, ent, host, flags, player, set)
{
	if (!player)
		return FMRES_IGNORED
	
	if (host != ent)
		return FMRES_IGNORED
	
	if (gE_peekEnt[host])
	{
		set_es(es, ES_RenderMode, kRenderTransAlpha)
		set_es(es, ES_RenderAmt, 0.0)
	}
	
	return FMRES_IGNORED
}

// Do not transmit other player peek cameras (less bandwidth usage)
// We also block the transmition of the players if the peek is in the wall
public fw_AddToFullPack(es, e, ent, host, flags, player, set)
{
	if (!player)
		return FMRES_IGNORED
	
	for (new i=1; i <= gI_MaxPlayers; i++)
	{
		if (i == host)
			continue
		
		if (!gE_peekEnt[i])
			continue
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

// Func peek Think, here we do all the calculations
public think_func_peek(eEnt)
{
	new eOwner = entity_get_edict(eEnt, EV_ENT_owner)
	
	new Float:vAngles[3], Float:vOffs[3], Float:fZoff, Float:vStart[3], Float:vAngles2[3], Float:vOffs2[3]
	
	entity_get_vector(eOwner, EV_VEC_v_angle, vAngles)
	entity_get_vector(eOwner, EV_VEC_view_ofs, vOffs)
	
	xs_vec_copy(vOffs, vStart)
	xs_vec_copy(vOffs, vOffs2)
	
	fZoff = vOffs[2]
	
	angle_vector(vAngles, ANGLEVECTOR_RIGHT, vAngles)
	
	xs_vec_copy(vAngles, vAngles2)
	
	xs_vec_mul_scalar(vAngles, angle_sin(MAX_ANGLE, gI_peekPercent[eOwner]) * fZoff * 2, vOffs)
	
	fZoff *=  angle_cos(MAX_ANGLE, gI_peekPercent[eOwner])
	
	vOffs[2] = fZoff
	
	entity_get_vector(eOwner, EV_VEC_origin, vAngles)
	
	xs_vec_add(vStart, vAngles, vStart)
	
	xs_vec_add(vAngles, vOffs, vOffs)
	
	new Float:fraction = traceCamHull(eEnt, vStart, vOffs);
	
	if (fraction > 0.99)
		entity_set_origin(eEnt, vOffs)
	else
	{
		new peekPercent = floatround((gI_peekPercent[eOwner] * fraction))
		
		fZoff = vOffs2[2]
		
		xs_vec_mul_scalar(vAngles2, angle_sin(MAX_ANGLE, peekPercent) * fZoff * 2, vOffs2)
		
		fZoff *=  angle_cos(MAX_ANGLE, peekPercent)
		
		vOffs2[2] = fZoff
		
		entity_get_vector(eOwner, EV_VEC_origin, vAngles2)
		
		xs_vec_add(vAngles2, vOffs2, vOffs2)
		
		entity_set_origin(eEnt, vOffs2)
	}
	
	entity_get_vector(eOwner, EV_VEC_velocity, vOffs)
	entity_set_vector(eEnt, EV_VEC_velocity, vOffs)
	
	entity_get_vector(eOwner, EV_VEC_v_angle, vOffs)
	entity_set_vector(eEnt, EV_VEC_angles, vOffs)
	
	entity_set_float(eEnt, EV_FL_nextthink, get_gametime() + 0.008)
	
	return PLUGIN_CONTINUE
}

stock create_peek(id)
{
	if (gE_peekEnt[id] != 0)
		return gE_peekEnt[id]
	
	new ent, Float:vOrigin[3], Float:vOffs[3]
	
	ent = create_entity("info_target")
	
	if(!ent)
		return 0
	
	entity_set_string(ent, EV_SZ_classname, "func_peek")
	
	gE_peekEnt[id] = ent
	
	entity_set_model(ent, "models/rpgrocket.mdl")
	
	entity_set_size(ent, Float:{-6.0,-6.0,-6.0}, Float:{6.0,6.0,6.0})
	
	entity_set_byte(ent, EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)
	
	entity_set_edict(ent, EV_ENT_owner, id)
	
	entity_set_int(ent,EV_INT_rendermode, kRenderTransTexture)
	entity_set_float(ent, EV_FL_renderamt, 0.0)
	
	entity_get_vector(id, EV_VEC_origin, vOrigin)
	entity_get_vector(id, EV_VEC_view_ofs, vOffs)
	
	xs_vec_add(vOrigin, vOffs, vOrigin)
	
	entity_set_origin(ent, vOrigin)
	
	entity_get_vector(id, EV_VEC_v_angle, vOffs)
	entity_set_vector(ent, EV_VEC_angles, vOffs)
	
	AttachView(id,ent)
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.02)
	
	return ent
}

stock AttachView(id, eAttachEnt) 
{ 
	attach_view(id, eAttachEnt)
	
	if (gB_BlockWallhack)
	{
		callfunc_begin("fw_setview", (gB_BlockWallhack == 10000) ? "trblock.amxx" : "block_wallhack.amxx") 
		callfunc_push_int(id) 
		callfunc_push_int(eAttachEnt) 
		callfunc_end() 
	}
	
	return 1 
}

stock Float:traceCamHull(ent, Float:start[3], Float:end[3])
{
	new ptr = create_tr2()
	
	engfunc(EngFunc_TraceHull, start, end,  IGNORE_MONSTERS | IGNORE_MISSILE, HULL_HEAD, ent, ptr)
	
	new Float:fraction
	get_tr2(ptr, TR_flFraction, fraction)
	
	free_tr2(ptr)
	
	return fraction
}