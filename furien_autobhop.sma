#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include "furien.inc"
#include "furien_shop.inc"

#define VERSION "0.2.1"

new g_bHasAutoBhop
#define SetUserAutoBhop(%1)		g_bHasAutoBhop |=	1<<(%1&31)
#define RemoveUserAutoBhop(%1)	g_bHasAutoBhop &=	~(1<<(%1&31))
#define HasUserAutoBhop(%1)		g_bHasAutoBhop &	1<<(%1&31)

new g_iCost[2]

public plugin_init()
{
	register_plugin("Furien AutoBhop", VERSION, "ConnorMcLeod")

	new szConfigFile[128]
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile))
	format(szConfigFile, charsmax(szConfigFile), "%s/furien/items/autobhop.ini", szConfigFile);

	new fp = fopen(szConfigFile, "rt")
	if( !fp )
	{
		return
	}

	new szFurienName[32], szAntiName[32]

	new szDatas[64], szKey[16], szValue[32]
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
		}
	}
	fclose( fp )

	if( g_iCost[Furien] || g_iCost[AntiFurien] )
	{
		furien_register_item(szFurienName, g_iCost[Furien], szAntiName, g_iCost[AntiFurien], "furien_buy_autobhop")

		RegisterHam(Ham_Player_Jump, "player", "CBasePlayer_Jump", false)
		RegisterHam(Ham_Killed, "player", "CBasePlayer_Killed", true)
	}
}

public furien_buy_autobhop( id )
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

	if( ~HasUserAutoBhop(id) )
	{
		if( furien_try_buy(id, iItemCost) )
		{
			SetUserAutoBhop( id )
			return ShopBought
		}
		else
		{
			return ShopNotEnoughMoney
		}
	}
	return ShopAlreadyHaveOne
}

public CBasePlayer_Jump( id )
{
	if( HasUserAutoBhop(id) && is_user_alive(id) )
	{
		set_pev(id, pev_oldbuttons, pev(id, pev_oldbuttons) & ~IN_JUMP)
		set_pev(id, pev_fuser2, 0.0)
	}
}

public client_putinserver(id)
{
	RemoveUserAutoBhop(id)
}

public CBasePlayer_Killed(id)
{
	RemoveUserAutoBhop(id)
}

public furien_team_change( /*iFurien */ )
{
	if( !g_iCost[Furien] || !g_iCost[AntiFurien] )
	{
		g_bHasAutoBhop = 0
	}
}

public furien_round_restart()
{
	g_bHasAutoBhop = 0
}