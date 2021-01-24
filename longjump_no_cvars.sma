/*	Formatright © 2009, ConnorMcLeod

	LongJump Enabler is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with LongJump Enabler; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "1.0.0"

#define MAX_PLAYERS 32

#define m_Activity 73
#define m_IdealActivity 74
#define m_afButtonPressed 246
#define m_fLongJump 356

#define PLAYER_SUPERJUMP 7
#define ACT_LEAP 8

#define FBitSet(%1,%2)		(%1 & %2)

new bool:g_bSuperJump[MAX_PLAYERS+1]

public plugin_init()
{
	register_plugin("LongJump Enabler", VERSION, "ConnorMcLeod")

	RegisterHam(Ham_Player_Jump, "player", "Player_Jump")
	RegisterHam(Ham_Player_Duck, "player", "Player_Duck")
}

public Player_Duck(id)
{
	if( g_bSuperJump[id] )
	{
		g_bSuperJump[id] = false
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public Player_Jump(id)
{
	if( !is_user_alive(id) )
	{
		return HAM_IGNORED
	}

	static iFlags ; iFlags = entity_get_int(id, EV_INT_flags)

	if( FBitSet(iFlags, FL_WATERJUMP) || entity_get_int(id, EV_INT_waterlevel) >= 2 )
	{
		return HAM_IGNORED
	}

	static afButtonPressed ; afButtonPressed = get_pdata_int(id, m_afButtonPressed)

	if( !FBitSet(afButtonPressed, IN_JUMP) || !FBitSet(iFlags, FL_ONGROUND) )
	{
		return HAM_IGNORED
	}

	if(	(entity_get_int(id, EV_INT_bInDuck) || iFlags & FL_DUCKING)
	&&	get_pdata_int(id, m_fLongJump)
	&&	entity_get_int(id, EV_INT_button) & IN_DUCK
	&&	entity_get_int(id, EV_INT_flDuckTime)	)
	{
		static Float:fVecTemp[3]
		entity_get_vector(id, EV_VEC_velocity, fVecTemp)
		if( vector_length(fVecTemp) > 50.0 )
		{
			entity_get_vector(id, EV_VEC_punchangle, fVecTemp)
			fVecTemp[0] = -5.0
			entity_set_vector(id, EV_VEC_punchangle, fVecTemp)

			get_global_vector(GL_v_forward, fVecTemp)
			fVecTemp[0] *= 560.0
			fVecTemp[1] *= 560.0
			fVecTemp[2] = 299.33259094191531084669989858532

			entity_set_vector(id, EV_VEC_velocity, fVecTemp)

			set_pdata_int(id, m_Activity, ACT_LEAP)
			set_pdata_int(id, m_IdealActivity, ACT_LEAP)
			g_bSuperJump[id] = true

			entity_set_int(id, EV_INT_oldbuttons, entity_get_int(id, EV_INT_oldbuttons) | IN_JUMP)

			entity_set_int(id, EV_INT_gaitsequence, PLAYER_SUPERJUMP)
			entity_set_float(id, EV_FL_frame, 0.0)

			set_pdata_int(id, m_afButtonPressed, afButtonPressed & ~IN_JUMP)
			return HAM_SUPERCEDE
		}
	}
	return HAM_IGNORED
}