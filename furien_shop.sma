/*	Formatright © 2010, ConnorMcLeod

	Furien Shop is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Furien Shop; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <cstrike>

#include "furien.inc"
#include "furien_shop.inc"

new const szPickAmmoSound[] = "items/9mmclip1.wav"

enum _:ItemDatas
{
	m_szItemName[32],
	m_iItemCost,
	m_iItemForwardIndex,
	m_iItemExtraArg
}

enum ( <<= 1 )
{
	ShouldBeInBuyZone = 1,
	ShouldBeInBuyTime
}

#define HUD_PRINTCENTER		4

new g_iBlinkAcct, g_iTextMsg

new g_iBuyType, g_pCvarBuyTime

new Array:g_aItems[2]
new g_iMenuId[2] = {-1, -1}

new bool:g_bFreezeTime = true, bool:g_bBuyTime = true
new bool:g_bSwitchTime
new Float:g_flRoundStartGameTime

public plugin_init()
{
	register_plugin("Furien Shop", FURIEN_VERSION, "ConnorMcLeod")

	register_dictionary("common.txt")

	new pCvar = register_cvar("furien_shop_version", FURIEN_VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	set_pcvar_string(pCvar, FURIEN_VERSION)

	ReadCfgFile()

	if( g_iBuyType & ShouldBeInBuyZone )
	{
		register_event("StatusIcon", "Event_StatusIcon_OutOfBuyZone", "b", "1=0", "2=buyzone")
	}

	register_event("HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0")
	register_logevent("LogEvent_Round_Start", 2, "1=Round_Start")

	register_clcmd("shop", "ClientCommand_Shop")
	register_clcmd("say shop", "ClientCommand_Shop")
	register_clcmd("say_team shop", "ClientCommand_Shop")
	register_clcmd("buy", "ClientCommand_Shop")

	g_iBlinkAcct = get_user_msgid("BlinkAcct")
	g_iTextMsg = get_user_msgid("TextMsg")
	g_pCvarBuyTime = get_cvar_pointer("mp_buytime")
}

ReadCfgFile()
{
	new szConfigFile[128]
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile))
	format(szConfigFile, charsmax(szConfigFile), "%s/furien/shop.ini", szConfigFile);

	new fp = fopen(szConfigFile, "rt")
	if( !fp )
	{
		return
	}

	new szDatas[32], szKey[16], szValue[16]
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
			case 'B':
			{
				if( equal(szKey, "BUY_TYPE" ) )
				{
					g_iBuyType = str_to_num(szValue)
				}
			}
		}
	}
	fclose( fp )
}

public plugin_precache()
{
	precache_sound(szPickAmmoSound)
}

public Event_HLTV_New_Round()
{
	g_bFreezeTime = true
	g_bBuyTime = true
	g_bSwitchTime = false
}

public LogEvent_Round_Start()
{
	g_bFreezeTime = false
	g_bBuyTime = true
	g_bSwitchTime = false
	g_flRoundStartGameTime = get_gametime()
}

bool:bIsBuyTime( id = 0 )
{
	new Float:flBuyTime
	if(	!g_bFreezeTime
	&&	( !g_bBuyTime || !(g_bBuyTime = get_gametime() < g_flRoundStartGameTime + (flBuyTime = get_buytime_value() * 60.0)) )	)
	{
		if( id )
		{
			new szBuyTime[3]
			float_to_str(flBuyTime, szBuyTime, charsmax(szBuyTime))
			Util_ClientPrint(id, HUD_PRINTCENTER, "#Cant_buy", szBuyTime)
		}
		return false
	}
	return true
}

Float:get_buytime_value()
{
	new Float:flBuyTime = get_pcvar_float(g_pCvarBuyTime)
	if( flBuyTime < 0.25 )
	{
		set_pcvar_float(g_pCvarBuyTime, 0.25)
		flBuyTime = 0.25
	}
	if( flBuyTime > 1.5 )
	{
		set_pcvar_float(g_pCvarBuyTime, 1.5)
		flBuyTime = 1.5
	}
	return flBuyTime
}

public furien_team_change()
{
	g_bSwitchTime = true

	new iPlayers[32], iNum
	get_players(iPlayers, iNum, "a")
	for(new i; i<iNum; i++)
	{
		CheckMenuClose(iPlayers[i])
	}
}

public Event_StatusIcon_OutOfBuyZone( id )
{
	CheckMenuClose(id)
}

CheckMenuClose(id)
{
	new iCrap, iMenuId
	player_menu_info(id, iCrap, iMenuId)
	if( iMenuId > -1 && (iMenuId == g_iMenuId[Furien] || iMenuId == g_iMenuId[AntiFurien]) )
	{
		menu_cancel(id)
	}
}

public plugin_natives()
{
	register_library("furien_shop")
	register_native("furien_register_item", "fr_register_item")
}

public fr_register_item(iPlugin)
{
	new mDatas[ItemDatas], szCallBack[32]

	get_string(5, szCallBack, charsmax(szCallBack))
	mDatas[m_iItemForwardIndex] = CreateOneForward(iPlugin, szCallBack, FP_CELL, FP_CELL)

	mDatas[m_iItemExtraArg] = get_param(6)

	if( (mDatas[m_iItemCost] = get_param(2)) > 0 )
	{
		get_string(1, mDatas[m_szItemName], charsmax(mDatas[m_szItemName]))
		AddItemToMenu( Furien , mDatas )
	}

	if( (mDatas[m_iItemCost] = get_param(4)) > 0 )
	{
		get_string(3, mDatas[m_szItemName], charsmax(mDatas[m_szItemName]))
		AddItemToMenu( AntiFurien , mDatas )
	}

	return mDatas[m_iItemForwardIndex]
}

AddItemToMenu( iTeam , mDatas[ItemDatas] )
{
	new Array:iArray = g_aItems[iTeam]
	if( iArray == Invalid_Array )
	{
		iArray = g_aItems[iTeam] = ArrayCreate(ItemDatas)
	}

	new iMenu = g_iMenuId[iTeam]
	if( iMenu == -1 )
	{
		new szMenuNames[][] = {"Furien Shop", "AntiFurien Shop"}
		new szHandlers[][] = {"FurienMenuHandler", "AntiMenuHandler"}
		iMenu = g_iMenuId[iTeam] = menu_create(szMenuNames[iTeam], szHandlers[iTeam])
		menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\y")
	}

	ArrayPushArray(iArray, mDatas)
	new szItemInformation[64]
	formatex(szItemInformation, charsmax(szItemInformation), "%s\R\y$%d", mDatas[m_szItemName], mDatas[m_iItemCost])
	menu_additem(iMenu, szItemInformation)
}

public ClientCommand_Shop( id )
{
	if( !g_bSwitchTime && is_user_alive(id) )
	{
		if( !bCanBuy( id ) )
		{
			return PLUGIN_HANDLED_MAIN
		}

		ShowShopMenu(id)
		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED_MAIN
}

bCanBuy( id )
{
	if(	( g_iBuyType & ShouldBeInBuyZone && !cs_get_user_buyzone(id) )
	||	( g_iBuyType & ShouldBeInBuyTime && !bIsBuyTime(id) )	)
	{
		return false
	}

	return true
}

ShowShopMenu(id)
{
	new iTeam = furien_get_user_team(id)
	menu_display(id, g_iMenuId[iTeam])
}

public FurienMenuHandler(id, iMenu, iItem)
{
	if( iItem > MENU_MORE && is_user_alive(id) && furien_get_user_team(id) == Furien && bCanBuy( id ) )
	{
		new mDatas[ItemDatas]
		ArrayGetArray(Array:g_aItems[Furien], iItem, mDatas)
		Function(mDatas, id)
	}
}

public AntiMenuHandler(id, iMenu, iItem)
{
	if( iItem > MENU_MORE && is_user_alive(id) && furien_get_user_team(id) == AntiFurien && bCanBuy( id ) )
	{
		new mDatas[ItemDatas]
		ArrayGetArray(Array:g_aItems[AntiFurien], iItem, mDatas)
		Function(mDatas, id)
	}
}

Function(mDatas[ItemDatas], id)
{
	new iRet
	ExecuteForward(mDatas[m_iItemForwardIndex], iRet, id, mDatas[m_iItemExtraArg])
	switch( iRet )
	{
		case ShopBought:
		{
			emit_sound(id, CHAN_ITEM, szPickAmmoSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			return 1
		}
		case ShopTeamNotAvail:
		{
			Util_ClientPrint
			(
				id,
				HUD_PRINTCENTER,
				"#Alias_Not_Avail",
				mDatas[ m_szItemName ]
			)
		}
		case ShopNotEnoughMoney:
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money")

			message_begin(MSG_ONE_UNRELIABLE, g_iBlinkAcct, .player=id)
			{
				write_byte(2)
			}
			message_end()
		}
		case ShopAlreadyHaveOne:
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Already_Have_One")
		}
		case ShopCantCarryAnymore:
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore")
		}
		case ShopCannotBuyThis:
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This")
		}
		case ShopCloseMenu:
		{
			return 1
		}
	}
	return 0
}

// Only submessage1 is used but fully implemented for example.
// Based on HLSDK ClientPrint and UTIL_ClientPrintAll from util.cpp
Util_ClientPrint(id, iMsgDest, szMessage[], szSubMessage1[] = "", szSubMessage2[] = "", szSubMessage3[] = "", szSubMessage4[] = "")
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iTextMsg, .player=id)
	{
		write_byte(iMsgDest)
		write_string(szMessage)
		if( szSubMessage1[0] )
		{
			write_string(szSubMessage1)
		}
		if( szSubMessage2[0] )
		{
			write_string(szSubMessage2)
		}
		if( szSubMessage3[0] )
		{
			write_string(szSubMessage3)
		}
		if( szSubMessage4[0] )
		{
			write_string(szSubMessage4)
		}
	}
	message_end()
}

////// client_print //////
// #Cstrike_TitlesTXT_Cannot_Buy_This		"You cannot buy this item!"
// #Cstrike_TitlesTXT_Cannot_Carry_Anymore	"You cannot carry anymore!"
// #Cstrike_Already_Own_Weapon			"You already own that weapon."
// #Cstrike_TitlesTXT_Weapon_Not_Available	"This weapon is not available to you!"
// #Cstrike_TitlesTXT_Not_Enough_Money		"You have insufficient funds!"
// #Cstrike_TitlesTXT_CT_cant_buy			"CTs aren't allowed to buy"
// #Cstrike_TitlesTXT_Terrorist_cant_buy	"Terrorists aren't allowed to buy anything on this map!"
// #Cstrike_TitlesTXT_VIP_cant_buy			"You are the VIP. You can't buy anything!"

////// Util_ClientPrint ///////
// #Cstrike_TitlesTXT_Alias_Not_Avail + szWeapon		"The \"%s1\"is not available for your team to buy."
// #Cstrike_TitlesTXT_Cant_buy + szSeconds			"%s1 seconds have passed. You can't buy anything now!"