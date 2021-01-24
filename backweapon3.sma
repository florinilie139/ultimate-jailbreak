/*	Formatright © 2010, ConnorMcLeod

	BackWeapon 3 is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with BackWeapon 3; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

// #define TEST_3RD

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

#if defined TEST_3RD
#include <engine>
#endif

#define VERSION "0.0.6"

const MAX_MODEL_PATH_LENGTH = 64 // "models/backweapons2.mdl" "backweapons2_css_ns.mdl"

const XO_CBASEPLAYERITEM = 4
const m_pPlayer = 41
const m_pNext = 42
const m_iId = 43

const XO_CBASEPLAYERWEAPON = 4
const m_fWeaponState = 74
// enum ( <<=1 )
// {
	// WEAPONSTATE_USP_SILENCED = 1,
	// WEAPONSTATE_GLOCK18_BURST_MODE,
	// WEAPONSTATE_M4A1_SILENCED,
	// WEAPONSTATE_ELITE_LEFT,
	// WEAPONSTATE_FAMAS_BURST_MODE,
	// WEAPONSTATE_SHIELD_DRAWN
// }
const WEAPONSTATE_M4A1_SILENCED = 1<<2

new const m_rgpPlayerItems_CBasePlayer_1 = 368;
const m_pActiveItem = 373;

const BODY_M4A1_SILENCED = 7;
const BODY_M4A1_NORMAL = 19;

new const g_iModelIndexLookupTable[CSW_P90+1] = {
	0, // 
	0, // CSW_P228
	0, // 
	10, // CSW_SCOUT
	0, // CSW_HEGRENADE
	11, // CSW_XM1014
	0, // CSW_C4
	18, // CSW_MAC10
	1, // CSW_AUG
	0, // CSW_SMOKEGRENADE
	0, // CSW_ELITE
	0, // CSW_FIVESEVEN
	16, // CSW_UMP45
	8, // CSW_SG550
	6, // CSW_GALIL
	15, // CSW_FAMAS
	0, // CSW_USP
	0, // CSW_GLOCK18
	3, // CSW_AWP
	4, // CSW_MP5NAVY
	14, // CSW_M249
	12, // CSW_M3
	BODY_M4A1_NORMAL, // CSW_M4A1
	17, // CSW_TMP
	13, // CSW_G3SG1
	0, // CSW_FLASHBANG
	0, // CSW_DEAGLE
	9, // CSW_SG552
	2, // CSW_AK47
	0, // CSW_KNIFE
	5 // CSW_P90
}

new g_iMaxPlayers
#define IsPlayer(%1)	( 1 <= %1 <= g_iMaxPlayers )
#define CHECK_PLAYER_ALIVE(%1)	( IsPlayer(%1) && is_user_alive(%1) )

new g_szModel[MAX_MODEL_PATH_LENGTH]
new bool:g_bNoSil, g_iMaxWeapons = 18

public plugin_init()
{
	register_plugin("BackWeapon 3", VERSION, "ConnorMcLeod")

	new szWeaponName[32]
	for(new iId=CSW_P228; iId<=CSW_P90; iId++)
	{
		if( g_iModelIndexLookupTable[iId] && get_weaponname(iId, szWeaponName, charsmax(szWeaponName)) )
		{	
			RegisterHam( Ham_Item_AttachToPlayer , szWeaponName , "Primary_AttachToPlayer_Post" , true )
			RegisterHam( Ham_Item_Holster , szWeaponName , "Primary_Holster_Post" , true )
			RegisterHam( Ham_Item_Deploy , szWeaponName , "Primary_Deploy_Pre" , false )
		}
	}
	RegisterHam( Ham_RemovePlayerItem , "player" , "Player_RemovePlayerItem_Post" , true)

	g_iMaxPlayers = get_maxplayers()

#if defined TEST_3RD
	RegisterHam( Ham_Spawn , "player" , "Player_Spawn_Post" , true)
}

public Player_Spawn_Post(id)
{
    if(cs_get_user_team(id) != CS_TEAM_CT)
	    return
	if( is_user_alive(id) && !is_user_bot(id) )
	{
		set_view(id, CAMERA_3RDPERSON)
	}
#endif
}

public plugin_precache()
{
	new szConfigFile[64] // "addons/amxmodx/configs/backweapons.ini" 38
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile))
	add(szConfigFile, charsmax(szConfigFile), "/backweapons.ini")

	new fp = fopen(szConfigFile, "rt")
	if( fp )
	{
		new szDatas[MAX_MODEL_PATH_LENGTH+22], szKey[16], szValue[MAX_MODEL_PATH_LENGTH]
		while( !feof(fp) )
		{
			fgets(fp, szDatas, charsmax(szDatas))
			trim(szDatas)
			if(!szDatas[0] || szDatas[0] == ';' || szDatas[0] == '#' || szDatas[0] == '/')
			{
				continue
			}
			parse(szDatas, szKey, charsmax(szKey), szValue, charsmax(szValue))
			if( equali(szKey, "bw_model") )
			{
				copy(g_szModel, charsmax(g_szModel), szValue)
			}
			else if( equali(szKey, "bw_nosil") )
			{
				if( szValue[0] == '1' )
				{
					g_bNoSil = true
				}
			}
			else if( equali(szKey, "bw_maxweapons") )
			{
				g_iMaxWeapons = str_to_num( szValue )
			}
		}
	}
	else
	{
		copy(g_szModel, charsmax(g_szModel), "models/backweapons2.mdl")
	}

	if( !file_exists(g_szModel) )
	{
		set_fail_state("Wrong model file, check backweapons.ini file !")
		return // ? shouldn't be needed
	}
	precache_model(g_szModel)

#if defined TEST_3RD
	precache_model("models/rpgrocket.mdl")
#endif
}

public Primary_AttachToPlayer_Post(iEnt, id)
{
	if( !CHECK_PLAYER_ALIVE(id) )
	{
		return
	}
    if(cs_get_user_team(id) != CS_TEAM_CT)
	    return
	engfunc(EngFunc_SetModel, iEnt, g_szModel) // SetModel doesn't seem to alloc

	set_pev(iEnt, pev_body, g_iModelIndexLookupTable[ get_pdata_int(iEnt, m_iId, XO_CBASEPLAYERITEM) ])

	if(	get_pdata_cbase(id, m_pActiveItem) != iEnt	)
	{
		CheckWeapons(id)
	}
}

public Primary_Holster_Post( iEnt )
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, XO_CBASEPLAYERITEM)
	if( CHECK_PLAYER_ALIVE(id) )
	{
		CheckWeapons(id)
	}
}

public Player_RemovePlayerItem_Post(id, iEnt)
{
    if(cs_get_user_team(id) != CS_TEAM_CT)
	    return
	if( ExecuteHam(Ham_Item_ItemSlot, iEnt) == 1 )
	{
		CheckWeapons(id, get_pdata_cbase(id, m_pActiveItem))
	}
}

public Primary_Deploy_Pre( iEnt )
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, XO_CBASEPLAYERITEM)
	if( CHECK_PLAYER_ALIVE(id) )
	{
		CheckWeapons(id, iEnt)
	}
}

CheckWeapons(id, iSkipEnt = FM_NULLENT)
{
    if(cs_get_user_team(id) != CS_TEAM_CT)
	    return
	new iMaxWeapons = g_iMaxWeapons

	new iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer_1)

	while( iWeapon > 0 )
	{
		if( iWeapon == iSkipEnt || iMaxWeapons <= 0 )
		{
			set_pev(iWeapon, pev_effects, EF_NODRAW)
		}
		else
		{
			if( g_bNoSil && get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM) == CSW_M4A1 )
			{
				if( get_pdata_int(iWeapon, m_fWeaponState, XO_CBASEPLAYERWEAPON) & WEAPONSTATE_M4A1_SILENCED )
				{
					set_pev(iWeapon, pev_body, BODY_M4A1_SILENCED)
				}
				else
				{
					set_pev(iWeapon, pev_body, BODY_M4A1_NORMAL)
				}
			}
			set_pev(iWeapon, pev_effects, 0)
			--iMaxWeapons
		}
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM)
	}
}
