#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include "furien.inc"
#include "furien_shop.inc"

#define VERSION "0.2.0"

#define FIRST_PLAYER_ID	1

new g_iMaxPlayers
#define IsPlayer(%1)	( FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers )

#define XO_WEAPON 4
#define m_pPlayer 41

#define XO_PLAYER		5
#define m_pActiveItem	373

new g_bHasSuperKnife
#define SetUserSuperKnife(%1)		g_bHasSuperKnife |= 1<<(%1&31)
#define RemoveUserSuperKnife(%1)	g_bHasSuperKnife &= ~(1<<(%1&31))
#define HasUserSuperKnife(%1)		g_bHasSuperKnife & 1<<(%1&31)

new g_iszSuperKnifeModel
new Float:g_flSuperKnifeDamageFactor

new g_iCost[2]

public plugin_precache()
{
	register_plugin("Furien SuperKnife", VERSION, "ConnorMcLeod")

	new szConfigFile[128]
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile))
	format(szConfigFile, charsmax(szConfigFile), "%s/furien/items/superknife.ini", szConfigFile);

	new fp = fopen(szConfigFile, "rt")
	if( !fp )
	{
		return
	}

	new szFurienName[32], szAntiName[32]

	new szDatas[80], szKey[16], szValue[64]
	while( !feof(fp) )
	{
		fgets(fp, szDatas, charsmax(szDatas))
		trim(szDatas)
		if(!szDatas[0] || szDatas[0] == ';' || szDatas[0] == '#' || (szDatas[0] == '/' && szDatas[1] == '/'))
		{
			continue
		}

		parse(szDatas, szKey, charsmax(szKey), szValue, charsmax(szValue))

		switch( szKey[0] )
		{
			case 'A':
			{
				switch( szKey[7] )
				{
					case 'M':
					{
						if( equal(szKey, "ANTI_NAME" ) )
						{
							copy(szAntiName, charsmax(szAntiName), szValue)
						}
					}
					case 'S':
					{
						if( equal(szKey, "ANTI_COST" ) )
						{
							g_iCost[AntiFurien] = str_to_num(szValue)
						}
					}
				}
			}
			case 'F':
			{
				switch( szKey[9] )
				{
					case 'M':
					{
						if( equal(szKey, "FURIEN_NAME" ) )
						{
							copy(szFurienName, charsmax(szAntiName), szValue)
						}
					}
					case 'S':
					{
						if( equal(szKey, "FURIEN_COST" ) )
						{
							g_iCost[Furien] = str_to_num(szValue)
						}
					}
				}
			}
			case 'K':
			{
				switch( szKey[6] )
				{
					case 'M':
					{
						if( equal(szKey, "KNIFE_MODEL" ) )
						{
							precache_model(szValue)
							g_iszSuperKnifeModel = engfunc(EngFunc_AllocString, szValue)
						}
					}
					case 'D':
					{
						if( equal(szKey, "KNIFE_DAMAGE" ) )
						{
							g_flSuperKnifeDamageFactor = str_to_float(szValue)
						}
					}
				}
			}
		}
	}
	fclose( fp )

	if( g_iCost[Furien] || g_iCost[AntiFurien] )
	{
		furien_register_item(szFurienName, g_iCost[Furien], szAntiName, g_iCost[AntiFurien], "furien_buy_superknife")	

		RegisterHam(Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", true)
		RegisterHam(Ham_TakeDamage, "player", "CBasePlayer_TakeDamage", false)
		RegisterHam(Ham_Item_Deploy, "weapon_knife", "CKnife_Deploy", true)

		g_iMaxPlayers = get_maxplayers()
	}
}

public client_putinserver(id)
{
	RemoveUserSuperKnife(id)
}

public furien_buy_superknife( id )
{
	new iTeam = furien_get_user_team(id)
	if( iTeam == -1 )
	{
		return ShopCloseMenu
	}

	new iItemCost = g_iCost[iTeam]
	if( iItemCost <= 0 )
	{
		return ShopTeamNotAvail
	}

	if( ~HasUserSuperKnife(id) )
	{
		if( furien_try_buy(id, iItemCost) )
		{
			SetUserSuperKnife(id)
			if( get_user_weapon(id) == CSW_KNIFE )
			{
				ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(id, m_pActiveItem, XO_PLAYER))
			}
			return ShopBought
		}
		else
		{
			return ShopNotEnoughMoney
		}
	}
	return ShopAlreadyHaveOne
}

public CKnife_Deploy( iKnife )
{
	new id = get_pdata_cbase(iKnife, m_pPlayer, XO_WEAPON)

	if( HasUserSuperKnife(id) )
	{
		set_pev(id, pev_viewmodel, g_iszSuperKnifeModel)
	}
}

public CBasePlayer_TakeDamage(id, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if( IsPlayer(iInflictor) && HasUserSuperKnife(iAttacker) && get_user_weapon(iAttacker) == CSW_KNIFE )
	{
		SetHamParamFloat( 4, flDamage * g_flSuperKnifeDamageFactor )
	}
}

public Ham_CBasePlayer_Killed_Post(id)
{
	RemoveUserSuperKnife(id)
}

public furien_team_change( /*iFurien */ )
{
	if( !g_iCost[Furien] || !g_iCost[AntiFurien] )
	{
		new iPlayers[32], iNum, id
		get_players(iPlayers, iNum, "a")
		for(new i; i<iNum; i++)
		{
			id = iPlayers[i]
			if( HasUserSuperKnife(id) )
			{
				RemoveUserSuperKnife(id)
				if( get_user_weapon(id) == CSW_KNIFE )
				{
					ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(id, m_pActiveItem, XO_PLAYER))
				}
			}
		}
		g_bHasSuperKnife = 0
	}
}

public furien_round_restart()
{
	g_bHasSuperKnife = 0
}