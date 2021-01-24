#include <amxmodx>
#include <amxmisc>
#include <geoip>

#define PLUGIN "Lunetistii Gag"
#define VERSION "3.0"
#define AUTHOR "PedoBear"

#define INTCVARS 29

#define ADMIN_MENU_CVARS ADMIN_RCON
#define ACCESS_LEVEL ADMIN_CHAT
#define NICK_LEVEL ADMIN_CHAT
#define IMMUNITY_LEVEL ADMIN_CHAT

#define CT_LANG_RO 0
#define CT_LANG_ENG 1

#define CT_MSGPOS_START 0
#define CT_MSGPOS_PREFIX 1
#define CT_MSGPOS_PRENAME 2
#define CT_MSGPOS_END 3

#define is_valid_player(%1) (1 <= %1 <= 32)

#define LOGTITLE "<META http-equiv=Content-Type content='text/html;charset=UTF-8'><h2 align=center>Lunetistii Gag Chat Logger v3.0 by PedoBear</h2><hr>"
#define LOGFONT "<font face=^"Verdana^" size=2>"

#define PUNISH_CHEAT 1
#define PUNISH_SPAM 2

#define ACTION_CHEAT 1
#define ACTION_SPAM 2

#define MAX_SWEARS 999
#define MAX_REPLACES 1
#define MAX_IGNORES 9999
#define MAX_SPAMS 9999
#define MAX_CHEAT 9999

#define CT_TRANSLIT 0
#define CT_LOG 1
#define CT_ADMIN_PREFIX 2
#define CT_NAME_COLOR 3
#define CT_CHAT_COLOR 4
#define CT_ALLCHAT 5
#define CT_LISTEN 6
#define CT_SOUNDS 7
#define CT_COUNTRY 8
#define CT_SWEAR 9
#define CT_SWEAR_WARNS 10
#define CT_SWEAR_IMMUN 11
#define CT_SWEAR_GAG 12
#define CT_SWEAR_GAG_TIME 13
#define CT_AUTO_ENG 14
#define CT_SHOW_INFO 15
#define CT_IGNORE 16
#define CT_IGNORE_MODE 17
#define CT_GAG_IMMUN 18
#define CT_FLOOD 19
#define CT_SPAM 20
#define CT_SPAM_IMMUN 21
#define CT_SPAM_WARNS 22
#define CT_SPAM_ACTION 23
#define CT_SPAM_TIME 24
#define CT_CHEAT 25
#define CT_CHEAT_IMMUN 26
#define CT_CHEAT_ACTION 27
#define CT_CHEAT_TIME 28

new iLines[INTCVARS]
new iCvars[INTCVARS]

new Edited[33]
new Position[33]

new Adds[4][10][128]
new AddsNum[4]

new Cmds[100][128]
new CmdsNum

new Replace[MAX_REPLACES][192]
new Spam[MAX_SPAMS][192]
new Cheat[MAX_CHEAT][192]
new Ignore[MAX_IGNORES][64]
new Swear[MAX_SWEARS][64]

new g_OriginalSimb[128][32]
new g_TranslitSimb[128][32]
new s_GagName[33][32]
new s_GagIp[33][32]
new SpamFound[33]
new SwearCount[33]
new i_Gag[33]

new p_LogMessage[1024]
new p_LogMsg[1024]
new p_LogInfo[512]
new p_LogTitle[512]
new p_LogFile[128]
new p_LogFileTime[32]
new p_LogIp[32]
new p_LogSteamId[32]
new p_LogTime[32]
new p_LogDir[64]
new p_LogAdminIp[32]

new Message[512]
new s_Msg[256]
new s_SwearMsg[256]
new s_Name[128]
new sUserId[32]
new AliveTeam[32]
new s_CheckGag[32]
new s_CheckIp[32]
new s_GagTime[32]
new s_GagPlayer[32]
new s_GagAdmin[32]
new s_GagTarget[32]
new s_BanAuthId[32]
new s_CountryIp[32]
new s_Country[46]
new s_KickName[64]
new s_BanName[32]
new s_BanIp[32]
new s_Reason[128]
new s_CheatAction[128]

new p_FilePath[64]
new s_ConfigsDir[64]
new s_File[64]
new s_ConfigFile[64]
new s_SwearFile[64]
new s_IgnoreFile[64]
new s_ReplaceFile[64]
new s_SpamFile[64]
new s_CheatFile[64]
new s_Country1[45]
new s_Country2[3]
new s_Country3[4]

new Input[32]
new Info[192]
new TeamColor[10]
new TeamName[10]
new s_Info[2]
new s_Arg[64]

new g_Translit
new g_Log
new g_NameColor
new g_AllChat
new g_AdminPrefix
new g_Listen
new g_ChatColor
new g_Country
new g_SwearFilter
new g_SwearWarns
new g_AutoRus
new g_ShowInfo
new g_SwearImmunity
new g_Sounds
new g_Ignore
new g_IgnoreMode
new g_SwearGag
new g_SwearTime
new g_FloodTime
new g_GagImmunity
new g_Spam
new g_SpamImmunity
new g_SpamWarns
new g_SpamAction
new g_SpamActionTime
new g_Cheat
new g_CheatImmunity
new g_CheatAction
new g_CheatActionTime
new g_CheatActionCustom

new fwd_Begin
new fwd_Cheat
new fwd_Spam
new fwd_Swear
new fwd_Format

new isAlive
new i_MaxSimbols
new SwearNum
new ReplaceNum
new IgnoreNum
new SpamNum
new CheatNum
new Line
new Len
new gagid
new i_GagTime
new SysTime
new i_ShowGag
new SwearFound
new mLen
new lgLen
new fwdResult

new bool:Flood[33]
new bool:Logged[33]
new bool:SwearList
new bool:ReplaceList
new bool:ConfigsList
new bool:TranslitList
new bool:IgnoreList
new bool:SpamList
new bool:IgnoreFound
new bool:SlashFound
new bool:CheatList

new color[10]

new sCvars[INTCVARS][] =
{
	"amx_translit",
	"amx_translit_log", 
	"amx_admin_prefix", 
	"amx_name_color", 
	"amx_chat_color",
	"amx_allchat",
	"amx_listen",
	"amx_ctsounds",
	"amx_country_chat",
	"amx_swear_filter",
	"amx_swear_warns",
	"amx_swear_immunity",
	"amx_swear_gag",
	"amx_swear_gag_time",
	"amx_auto_rus",
	"amx_show_info",
	"amx_ignore",
	"amx_ignore_mode", 
	"amx_gag_immunity",
	"amx_flood_time",
	"amx_spam_filter",
	"amx_spam_immunity",
	"amx_spam_warns",
	"amx_spam_action",
	"amx_spam_time",
	"amx_cheat_filter",
	"amx_cheat_immunity",
	"amx_cheat_action",
	"amx_cheat_time"
}

new cOnOff[2][] =
{
	"CT_OFF",
	"CT_ON"
}

new cChatColors[7][] =
{
	"",
	"CT_COLOR_YELLOW",
	"CT_COLOR_GREEN",
	"CT_COLOR_GRAY",
	"CT_COLOR_BLUE",
	"CT_COLOR_RED",
	"CT_COLOR_TEAM"
}

new cAllChat[3][] =
{
	"CT_OFF",
	"CT_ON",
	"CT_ALLCHAT_ADMIN"
}

new cCountry[4][] =
{
	"CT_OFF",
	"CT_COUNTRY_FULL",
	"CT_COUNTRY_2",
	"CT_COUNTRY_3"
}

new cAutoRus[3][] =
{
	"CT_OFF",
	"CT_AUTO_ENG_CONNECT",
	"CT_AUTO_ENG_ALWAYS"
}

new cIgnoreMode[4][] =
{
	"",
	"CT_IGNORE_NO_TRANSLIT",
	"CT_IGNORE_HIDE",
	"CT_IGNORE_STATSX_SHELL"
}

new cSpamAction[7][] =
{
	"CT_OFF",
	"CT_SPAM_KICK",
	"CT_SPAM_GAG",
	"CT_SPAM_BAN_STEAMID",
	"CT_SPAM_BAN_IP",
	"CT_SPAM_BAN_STEAMID_AMXBANS",
	"CT_SPAM_BAN_IP_AMXBANS"
}

new cCheatAction[7][] =
{
	"CT_OFF",
	"CT_CHEAT_KICK",
	"CT_CHEAT_BAN_STEAMID",
	"CT_CHEAT_BAN_IP",
	"CT_CHEAT_BAN_STEAMID_AMXBANS",
	"CT_CHEAT_BAN_IP_AMXBANS",
	"CT_CHEAT_CUSTOM"
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_dictionary("LunetistiiGag.txt")

	register_menucmd(register_menuid("Config Menu"), 1023, "action_configs_menu")

	register_concmd("lunetistii_gag_config", "cmd_admin_menu", ADMIN_MENU_CVARS)

	g_Translit = register_cvar("amx_translit", "0")
	g_Log = register_cvar("amx_translit_log", "1")
	g_AdminPrefix = register_cvar("amx_admin_prefix", "0")
	g_NameColor = register_cvar("amx_name_color", "6")
	g_ChatColor = register_cvar("amx_chat_color", "1")
	g_AllChat = register_cvar("amx_allchat", "0")
	g_Listen = register_cvar("amx_listen", "1")
	g_Sounds = register_cvar("amx_ctsounds", "1")
	g_Country = register_cvar("amx_country_chat", "0")
	g_SwearFilter = register_cvar("amx_swear_filter", "1")
	g_SwearWarns = register_cvar("amx_swear_warns", "3")
	g_SwearImmunity = register_cvar("amx_swear_immunity", "1")
	g_SwearGag = register_cvar("amx_swear_gag", "1")
	g_SwearTime = register_cvar("amx_swear_gag_time", "5")
	g_AutoRus = register_cvar("amx_auto_rus", "0")
	g_ShowInfo = register_cvar("amx_show_info", "1")
	g_Ignore = register_cvar("amx_ignore", "1")
	g_IgnoreMode = register_cvar("amx_ignore_mode", "1")
	g_GagImmunity = register_cvar("amx_gag_immunity", "0")
	g_FloodTime = register_cvar("amx_flood_time", "1")
	g_Spam = register_cvar("amx_spam_filter", "1")
	g_SpamImmunity = register_cvar("amx_spam_immunity", "1")
	g_SpamWarns = register_cvar("amx_spam_warns", "3")
	g_SpamAction = register_cvar("amx_spam_action", "2")
	g_SpamActionTime = register_cvar("amx_spam_time", "60")
	g_Cheat = register_cvar("amx_cheat_filter", "1")
	g_CheatImmunity = register_cvar("amx_cheat_immunity", "1")
	g_CheatAction = register_cvar("amx_cheat_action", "1")
	g_CheatActionTime = register_cvar("amx_cheat_time", "0")
	g_CheatActionCustom = register_cvar("amx_cheat_custom", "")

	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say_team")

	register_concmd("amx_gag", "cmd_gag", ACCESS_LEVEL, "<Nick> <Minutes>")
	register_concmd("amx_ungag", "cmd_ungag", ACCESS_LEVEL, "<Nick>")

	fwd_Begin = CreateMultiForward("ct_message_begin", ET_IGNORE, FP_CELL, FP_STRING, FP_CELL)
	fwd_Cheat = CreateMultiForward("ct_message_cheat", ET_IGNORE, FP_CELL, FP_STRING)
	fwd_Spam = CreateMultiForward("ct_message_spam", ET_IGNORE, FP_CELL, FP_STRING)
	fwd_Swear = CreateMultiForward("ct_message_swear", ET_IGNORE, FP_CELL, FP_STRING)
	fwd_Format = CreateMultiForward("ct_message_format", ET_IGNORE, FP_CELL)

	get_localinfo("amxx_logs", p_FilePath, 63)

	cache_lines()
	read_cvars()
	add_menu()

	return PLUGIN_CONTINUE
}

public add_menu()
{
	new mName[128]
	format(mName, charsmax(mName), "%L", LANG_SERVER, "CT_MENU_TITLE")
	AddMenuItem(mName, "lunetistii_gag_config", ADMIN_RCON, PLUGIN)
}

public write_cvars(id)
{
	new cFile[128], sLine[32]
	get_configsdir(cFile, charsmax(cFile))

	format(cFile, charsmax(cFile), "%s/lunetistii_gag/config.cfg", cFile)

	for(new i; i < INTCVARS-1; i++)
	{
		format(sLine, charsmax(sLine), "%s ^"%d^"", sCvars[i], iCvars[i])
		write_file(cFile, sLine, iLines[i])
	}

	server_cmd("exec %s", cFile)
	server_exec()
	client_print(id, print_chat, "[%s] %L", PLUGIN, id, "CT_SAVED")

	return PLUGIN_CONTINUE
}

public read_cvars()
{
	for(new i; i < INTCVARS; i++)
	{
		iCvars[i] = get_cvar_num(sCvars[i])
	}

	return PLUGIN_CONTINUE
}

public cache_lines()
{
	new cFile[128]

	get_configsdir(cFile, charsmax(cFile))

	format(cFile, charsmax(cFile), "%s/lunetistii_gag/config.cfg", cFile)

	if(!file_exists(cFile))
	{
		new errMsg[128]
		format(errMsg, charsmax(errMsg), "Config file <%s> not found!", cFile)
		set_fail_state(errMsg)
		return PLUGIN_HANDLED
	}

	new Buffer[512], Len, Cached
	new AllLines =  file_size(cFile, 1)

	while(Cached < INTCVARS-1)
	{
		for(new i; i <= AllLines; i++)
		{
			read_file(cFile, i, Buffer, charsmax(Buffer), Len)

			if(Buffer[0] == '#' || Buffer[0] == ';' || !strlen(Buffer))
			{
				continue
			}

			if(containi(Buffer, sCvars[Cached]) == 0)
			{
				iLines[Cached] = i
				Cached++
				i = AllLines
			}
		}
	}

	return PLUGIN_CONTINUE
}

public cmd_admin_menu(id, level, cid)
{
	if(!access(id, level))
	{
		return PLUGIN_HANDLED
	}

	show_configs_menu(id, Position[id] = 1, 1)

	return PLUGIN_CONTINUE
}

public show_configs_menu(id, position, firstopen)
{
	if(firstopen)
	{
		read_cvars()
		Edited[id] = 0
	}

	new Len, MenuBody[1024]
	new Keys = MENU_KEY_0
	Len = format(MenuBody, charsmax(MenuBody), "\y%L\R\r%d/5^n^n", id, "CT_MENU_TITLE", position)
	switch(position)
	{
		case 1:
		{
			Keys |= (1 << 0)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r1. \w%L\R\y%L^n", id, "CT_MENU_TRANSLIT", id, cOnOff[iCvars[CT_TRANSLIT]])
			Keys |= (1 << 1)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r2. \w%L\R\y%L^n", id, "CT_MENU_LOG", id, cOnOff[iCvars[CT_LOG]])
			Keys |= (1 << 2)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r3. \w%L\R\y%L^n", id, "CT_MENU_ADMIN_PREFIX", id, cOnOff[iCvars[CT_ADMIN_PREFIX]])
			Keys |= (1 << 3)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r4. \w%L\R\y%L^n", id, "CT_MENU_NAME_COLOR", id, cChatColors[iCvars[CT_NAME_COLOR]])
			Keys |= (1 << 4)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r5. \w%L\R\y%L^n", id, "CT_MENU_CHAT_COLOR", id, cChatColors[iCvars[CT_CHAT_COLOR]])
			Keys |= (1 << 5)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r6. \w%L\R\y%L^n", id, "CT_MENU_ALLCHAT", id, cAllChat[iCvars[CT_ALLCHAT]])
		}
		case 2:
		{
			Keys |= (1 << 0)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r1. \w%L\R\y%L^n", id, "CT_MENU_LISTEN", id, cOnOff[iCvars[CT_LISTEN]])
			Keys |= (1 << 1)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r2. \w%L\R\y%L^n", id, "CT_MENU_SOUNDS", id, cOnOff[iCvars[CT_SOUNDS]])
			Keys |= (1 << 2)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r3. \w%L\R\y%L^n", id, "CT_MENU_COUNTRY", id, cCountry[iCvars[CT_COUNTRY]])
			Keys |= (1 << 3)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r4. \w%L\R\y%L^n", id, "CT_MENU_SWEAR", id, cOnOff[iCvars[CT_SWEAR]])
			Keys |= (1 << 4)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r5. \w%L\R\y%d^n", id, "CT_MENU_SWEAR_WARNS", iCvars[CT_SWEAR_WARNS])
			Keys |= (1 << 5)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r6. \w%L\R\y%L^n", id, "CT_MENU_SWEAR_IMMUN", id, cOnOff[iCvars[CT_SWEAR_IMMUN]])
		}
		case 3:
		{
			Keys |= (1 << 0)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r1. \w%L\R\y%L^n", id, "CT_MENU_SWEAR_GAG", id, cOnOff[iCvars[CT_SWEAR_GAG]])
			Keys |= (1 << 1)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r2. \w%L\R\y%d %L^n", id, "CT_MENU_SWEAR_GAG_TIME", iCvars[CT_SWEAR_GAG_TIME], id, "CT_MIN")
			Keys |= (1 << 2)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r3. \w%L\R\y%L^n", id, "CT_MENU_AUTO_RUS", id, cAutoRus[iCvars[CT_AUTO_ENG]])
			Keys |= (1 << 3)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r4. \w%L\R\y%L^n", id, "CT_MENU_SHOW_INFO", id, cOnOff[iCvars[CT_SHOW_INFO]])
			Keys |= (1 << 4)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r5. \w%L\R\y%L^n", id, "CT_MENU_IGNORE", id, cOnOff[iCvars[CT_IGNORE]])
			Keys |= (1 << 5)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r6. \w%L\R\y%L^n", id, "CT_MENU_IGNORE_MODE", id, cIgnoreMode[iCvars[CT_IGNORE_MODE]])
		}
		case 4:
		{
			Keys |= (1 << 0)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r1. \w%L\R\y%L^n", id, "CT_MENU_GAG_IMMUN", id, cOnOff[iCvars[CT_GAG_IMMUN]])
			Keys |= (1 << 1)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r2. \w%L\R\y%d %L^n", id, "CT_MENU_FLOOD", iCvars[CT_FLOOD], id, "CT_SEC")
			Keys |= (1 << 2)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r3. \w%L\R\y%L^n", id, "CT_MENU_SPAM", id, cOnOff[iCvars[CT_SPAM]])
			Keys |= (1 << 3)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r4. \w%L\R\y%L^n", id, "CT_MENU_SPAM_IMMUN", id, cOnOff[iCvars[CT_SPAM_IMMUN]])
			Keys |= (1 << 4)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r5. \w%L\R\y%d^n", id, "CT_MENU_SPAM_WARNS", iCvars[CT_SPAM_WARNS])
			Keys |= (1 << 5)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r6. \w%L\R\y%L^n", id, "CT_MENU_SPAM_ACTION", id, cSpamAction[iCvars[CT_SPAM_ACTION]])
		}
		case 5:
		{
			Keys |= (1 << 0)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r1. \w%L\R\y%d %L^n", id, "CT_MENU_SPAM_TIME", iCvars[CT_SPAM_TIME], id, "CT_MIN")
			Keys |= (1 << 1)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r2. \w%L\R\y%L^n", id, "CT_MENU_CHEAT", id, cOnOff[iCvars[CT_CHEAT]])
			Keys |= (1 << 2)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r3. \w%L\R\y%L^n", id, "CT_MENU_CHEAT_IMMUN", id, cOnOff[iCvars[CT_CHEAT_IMMUN]])
			Keys |= (1 << 3)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r4. \w%L\R\y%L^n", id, "CT_MENU_CHEAT_ACTION", id, cCheatAction[iCvars[CT_CHEAT_ACTION]])
			Keys |= (1 << 4)
			Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r5. \w%L\R\y%d %L^n", id, "CT_MENU_CHEAT_TIME", iCvars[CT_CHEAT_TIME], id, "CT_MIN")
		}
	}

	Keys |= (1 << 6)
	Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "^n\r7. \w%L^n", id, "CT_MENU_CLEAR")
	if(Edited[id])
	{
		Keys |= (1 << 7)
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r8. \w%L \r*^n^n", id, "CT_MENU_SAVE")
	}
	else
	{
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r8. \d%L^n^n", id, "CT_MENU_SAVE")
	}

	if(position != 5)
	{
		Keys |= (1 << 8)
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r9. \w%L^n", id, "CT_MENU_MORE")
	}
	else
	{
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r9. \d%L^n", id, "CT_MENU_MORE")
	}

	if(position != 1)
	{
		Keys |= (1 << 9)
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r0. \w%L^n^n\y%s v%s by %s", id, "CT_MENU_BACK", PLUGIN, VERSION, AUTHOR)
	}
	else
	{
		Keys |= (1 << 9)
		Len += format(MenuBody[Len], charsmax(MenuBody) - Len, "\r0. \w%L^n^n\y%s v%s by %s", id, "CT_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
	}

	show_menu(id, Keys, MenuBody, -1, "Config Menu")
}

public action_configs_menu(id, key)
{
	switch(key)
	{
		case 6:
		{
			show_configs_menu(id, Position[id], 1)
			return PLUGIN_HANDLED
		}
		case 7:
		{
			if(Edited[id])
			{
				write_cvars(id)
			}

			Edited[id] = 0
			show_configs_menu(id, Position[id], 0)
			return PLUGIN_HANDLED
		}
		case 8:
		{
			if(Position[id] != 5)
			{
				Position[id]++
				show_configs_menu(id, Position[id], 0)
			}

			return PLUGIN_HANDLED
		}
		case 9:
		{
			if(Position[id] == 1)
			{
				return PLUGIN_HANDLED
			}

			Position[id]--
			show_configs_menu(id, Position[id], 0)
			return PLUGIN_HANDLED
		}
		default:
		{
			new Choosed
			if(Position[id] == 1)
			{
				Choosed = Position[id] * key
			}
			else
			{
				Choosed = (Position[id] - 1) * 6 + key
			}

			iCvars[Choosed]++
			if(Choosed == CT_NAME_COLOR || Choosed == CT_CHAT_COLOR)
			{
				if(iCvars[Choosed] >= 7) 
				{
					iCvars[Choosed] = 1
				}
			}
			else if(Choosed == CT_ALLCHAT || Choosed == CT_AUTO_ENG)
			{
				if(iCvars[Choosed] >= 3)
				{
					iCvars[Choosed] = 0
				}
			}
			else if(Choosed == CT_COUNTRY)
			{
				if(iCvars[Choosed] >= 4)
				{
					iCvars[Choosed] = 0
				}
			}
			else if(Choosed == CT_SWEAR_WARNS || Choosed == CT_SPAM_WARNS || Choosed == CT_SWEAR_GAG_TIME || Choosed == CT_FLOOD)
			{
				if(iCvars[Choosed] >= 31)
				{
					iCvars[Choosed] = 0
				}
			}
			else if(Choosed == CT_CHEAT_TIME || Choosed == CT_SPAM_TIME)
			{
				if(iCvars[Choosed] < 30)
				{
					iCvars[Choosed] += 4
				}
				else if(30 <= iCvars[Choosed] < 240)
				{
					iCvars[Choosed] += 29
				}
				else if(240 <= iCvars[Choosed] < 1440)
				{
					iCvars[Choosed] += 59
				}
				else if(1440 <= iCvars[Choosed] < 10080)
				{
					iCvars[Choosed] += 1439
				}
				else if(10080 <= iCvars[Choosed] < 50000)
				{
					iCvars[Choosed] += 10079
				}
				else 
				{
					iCvars[Choosed] = 0
				}
			}
			else if(Choosed == CT_IGNORE_MODE)
			{
				if(iCvars[Choosed] >= 4)
				{
					iCvars[Choosed] = 1
				}
			}
			else if(Choosed == CT_SPAM_ACTION || Choosed == CT_CHEAT_ACTION)
			{
				if(iCvars[Choosed] >= 7)
				{
					iCvars[Choosed] = 0
				}
			}
			else if(iCvars[Choosed] >= 2)
			{
				iCvars[Choosed] = 0
			}
			Edited[id] = 1
			show_configs_menu(id, Position[id], 0)
		}
	}

	return PLUGIN_HANDLED
}

public cmd_gag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED
	}

	read_args(s_Arg, charsmax(s_Arg))
	parse(s_Arg, s_GagPlayer, charsmax(s_GagPlayer), s_GagTime, charsmax(s_GagTime))

	if(!is_str_num(s_GagTime))
	{
		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_CMD_ERROR")
		WriteMessage(id, Info)

		return PLUGIN_CONTINUE
	}

	gagid = cmd_target(id, s_GagPlayer, 8)

	if(!gagid)
	{
		return PLUGIN_HANDLED
	}

	get_user_name(id, s_GagAdmin, charsmax(s_GagAdmin))
	get_user_name(gagid, s_GagTarget, charsmax(s_GagTarget))

	if(get_user_flags(gagid) & IMMUNITY_LEVEL && get_pcvar_num(g_GagImmunity))
	{
		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_IMMUNITY", s_GagTarget)
		WriteMessage(id, Info)
	}
	else
	{
		i_GagTime = str_to_num(s_GagTime)
		get_user_name(gagid, s_GagName[gagid], 31)
		get_user_ip(gagid, s_GagIp[gagid], 31, 1)
		SysTime = get_systime(0)
		i_Gag[gagid] = SysTime + i_GagTime*60
		Flood[gagid] = false

		if(get_pcvar_num(g_Sounds))
		{
			client_cmd(gagid, "spk buttons/button5")
			client_cmd(id, "spk buttons/button5")
		}
	
		switch(get_cvar_num("amx_show_activity"))
		{
			case 0:
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_A0_GAG", s_GagTarget, i_GagTime)
				WriteMessage(id, Info)
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_GAGED", i_GagTime)
				WriteMessage(gagid, Info)
			}
			case 1:
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_A1_GAG", s_GagTarget, i_GagTime)
				for(new player = 0; player <= get_maxplayers(); player++)
				{
					if(!is_user_connected(player) || player == gagid)
					{
						continue
					}

					WriteMessage(player, Info)
				}

				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_GAGED", i_GagTime)
				WriteMessage(gagid, Info)
			}
			case 2:
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_A2_GAG", s_GagAdmin, s_GagTarget, i_GagTime)
				for(new player = 0; player <= get_maxplayers(); player++)
				{
					if(!is_user_connected(player) || player == gagid)
					{
						continue
					}

					WriteMessage(player, Info)
				}

				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_GAGED2", s_GagAdmin, i_GagTime)
				WriteMessage(gagid, Info)

				if(get_pcvar_num(g_Log))
				{
					get_time("20%y.%m.%d", p_LogFileTime, charsmax(p_LogFileTime))
					get_time("%H:%M:%S", p_LogTime, charsmax(p_LogTime))
					format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
					format(p_LogFile, charsmax(p_LogFile), "%s/gag_%s.log", p_LogDir, p_LogFileTime)

					if(!dir_exists(p_LogDir))
					{
						mkdir(p_LogDir)
					}

					get_user_ip(gagid, p_LogIp, charsmax(p_LogIp), 1)
					get_user_ip(id, p_LogAdminIp, charsmax(p_LogAdminIp), 1)
					format(p_LogMessage, charsmax(p_LogMessage), "%s - ADMIN %s <%s> has gaged %s <%s> for %d minutes", p_LogTime, s_GagAdmin, p_LogAdminIp, s_GagTarget, p_LogIp, i_GagTime)
					write_file(p_LogFile, p_LogMessage)
				}
			}
		}
	}

	return PLUGIN_CONTINUE
}

public cmd_ungag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	{
		return PLUGIN_HANDLED
	}

	SysTime = get_systime(0)
	read_args(s_GagPlayer, charsmax(s_GagPlayer))
	gagid = cmd_target(id, s_GagPlayer, 8)

	if(!gagid)
	{
		return PLUGIN_HANDLED
	}

	get_user_name(id, s_GagAdmin, charsmax(s_GagAdmin))
	get_user_name(gagid, s_GagTarget, charsmax(s_GagTarget))

	if(i_Gag[gagid] <= SysTime)
	{
			format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_ALREADY", s_GagTarget)
			WriteMessage(id, Info)
	}
	else
	{
		SysTime = get_systime(0)
		i_Gag[gagid] = SysTime

		if(get_pcvar_num(g_Sounds))
		{
			client_cmd(gagid, "spk buttons/button6")
			client_cmd(id, "spk buttons/button6")
		}

		switch(get_cvar_num("amx_show_activity"))
		{
			case 0:
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_A0_UNGAG", s_GagTarget)
				WriteMessage(id, Info)
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_UNGAGED")
				WriteMessage(gagid, Info)
			}
			case 1:
			{
				format(Info, charsmax(Info), "[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_A1_UNGAG", s_GagTarget)
				for(new player = 0; player <= get_maxplayers(); player++)
				{
					if(!is_user_connected(player) || player == gagid)
					{
						continue
					}

					WriteMessage(player, Info)
				}

				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_UNGAGED")
				WriteMessage(gagid, Info)
			}
			case 2:
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_A2_UNGAG", s_GagAdmin, s_GagTarget)
				for(new player = 0; player <= get_maxplayers(); player++)
				{
					if(!is_user_connected(player) || player == gagid)
					{
						continue
					}

					WriteMessage(player, Info)
				}

				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, gagid, "CT_YOU_UNGAGED2", s_GagAdmin)
				WriteMessage(gagid, Info)

				if(get_pcvar_num(g_Log))
				{
					get_time("20%y.%m.%d", p_LogFileTime, charsmax(p_LogFileTime))
					get_time("%H:%M:%S", p_LogTime, charsmax(p_LogTime))
					format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
					format(p_LogFile, charsmax(p_LogFile), "%s/gag_%s.log", p_LogDir, p_LogFileTime)

					if(!dir_exists(p_LogDir))
					{
						mkdir(p_LogDir)
					}

					get_user_ip(gagid, p_LogIp, charsmax(p_LogIp), 1)
					get_user_ip(id, p_LogAdminIp, charsmax(p_LogAdminIp), 1)
					format(p_LogMessage, charsmax(p_LogMessage), "%s - ADMIN %s <%s> has ungaged %s <%s>", p_LogTime, s_GagAdmin, p_LogAdminIp, s_GagTarget, p_LogIp)
					write_file(p_LogFile, p_LogMessage)
				}
			}
		}
	}

	return PLUGIN_CONTINUE
}

public hook_say(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
	{
		return PLUGIN_CONTINUE
	}

	if(is_user_gaged(id))
	{
		return PLUGIN_HANDLED
	}

	read_args(s_Msg, charsmax(s_Msg))
	remove_quotes(s_Msg)
	replace_all(s_Msg, charsmax(s_Msg), "%s", "")

	for(new posid; posid < 4; posid++)
	{
		AddsNum[posid] = 0
	}

	ExecuteForward(fwd_Begin, fwdResult, id, s_Msg, 0)

	if(check_plugin_cmd(id, s_Msg))
	{
		return PLUGIN_CONTINUE
	}

	if(is_empty_message(s_Msg))
	{
		return PLUGIN_HANDLED
	}

	if(is_system_message(s_Msg))
	{
		if(get_pcvar_num(g_IgnoreMode) == 1)
		{
			SlashFound = true
		}
		else if(get_pcvar_num(g_IgnoreMode) == 2)
		{
			return PLUGIN_HANDLED
		}
		else if(get_pcvar_num(g_IgnoreMode) == 3)
		{
			return PLUGIN_CONTINUE
		}
	}
	else
	{
		SlashFound = false
	}

	get_time("20%y.%m.%d", p_LogFileTime, charsmax(p_LogFileTime))
	get_time("%H:%M:%S", p_LogTime, charsmax(p_LogTime))

	if(get_pcvar_num(g_Cheat) && is_cheat_message(id, s_Msg))
	{
		ExecuteForward(fwd_Cheat, fwdResult, id, s_Msg)
		client_punish(id, PUNISH_CHEAT)
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(g_Spam) && is_spam_message(id, s_Msg))
	{
		ExecuteForward(fwd_Spam, fwdResult, id, s_Msg)
		SpamFound[id]++
		if(SpamFound[id]-1 >= get_pcvar_num(g_SpamWarns))
		{
			SpamFound[id] = 0
			client_punish(id, PUNISH_SPAM)
		}
		else
		{
			format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SPAMWARN", get_pcvar_num(g_SpamWarns) - SpamFound[id])
			WriteMessage(id, Info)
			if(get_pcvar_num(g_Sounds))
			{
				client_cmd(id, "spk buttons/blip2")
			}
		}

		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(g_Ignore) && is_ignored_message(s_Msg))
	{
		if(get_pcvar_num(g_IgnoreMode) == 1)
		{
			IgnoreFound = true
		}
		else if(get_pcvar_num(g_IgnoreMode) == 2)
		{
			return PLUGIN_HANDLED
		}
		else if(get_pcvar_num(g_IgnoreMode) == 3)
		{
			return PLUGIN_CONTINUE
		}
	}
	else
	{
		IgnoreFound = false
	}

	get_user_team(id, AliveTeam, charsmax(AliveTeam))
	ReplaceSwear(charsmax(s_Msg), s_Msg)

	if(get_pcvar_num(g_Translit) && !IgnoreFound)
	{
		get_user_info(id, "translit", s_Info, charsmax(s_Info))
		if(equal(s_Info, "1") || get_pcvar_num(g_AutoRus) == 2)
		{
			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_SwearMsg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_SwearMsg, charsmax(s_SwearMsg), g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}

			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_Msg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_Msg, charsmax(s_Msg), g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}
		}
	}

	get_user_name(id, s_Name, charsmax(s_Name))

	if(get_pcvar_num(g_SwearFilter))
	{
		new iSwear = is_swear_message(id, s_SwearMsg)
		if(iSwear)
		{
			ExecuteForward(fwd_Swear, fwdResult, id, s_Msg)
		}

		if(iSwear)
		{
			SwearFound = 1
			SwearCount[id]++

			if(get_pcvar_num(g_SwearGag) && (SwearCount[id]-1 >= get_pcvar_num(g_SwearWarns)))
			{
				SwearCount[id] = 0
				Flood[id] = false
				SysTime = get_systime(0)
				i_Gag[id] = SysTime + get_pcvar_num(g_SwearTime)*60
				get_user_name(id, s_GagName[id], 31)
				get_user_ip(id, s_GagIp[id], 31, 1)
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SWEAR_GAG", get_pcvar_num(g_SwearTime))
				WriteMessage(id, Info)

				if(get_pcvar_num(g_Log) == 1)
				{
					format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
					format(p_LogFile, charsmax(p_LogFile), "%s/gag_%s.log", p_LogDir, p_LogFileTime)

					if(!dir_exists(p_LogDir))
					{
						mkdir(p_LogDir)
					}

					get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
					format(p_LogMessage, charsmax(p_LogMessage), "%s - Swear Filter has gaged %s <%s> for %d minutes. Message: %s. Found: %s", p_LogTime, s_GagName[id], p_LogIp, get_pcvar_num(g_SwearTime), s_SwearMsg, Swear[iSwear - 1])
					write_file(p_LogFile, p_LogMessage)
				}

				if(get_pcvar_num(g_Sounds))
				{
					client_cmd(id, "spk buttons/button5")
				}
			}
			else if(get_pcvar_num(g_SwearGag))
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SWEARWARN", get_pcvar_num(g_SwearWarns) - SwearCount[id])
				WriteMessage(id, Info)

				if(get_pcvar_num(g_Sounds))
				{
					client_cmd(id, "spk buttons/blip2")
				}
			}
		}
		else
		{
			SwearFound = 0
		}
	}

	if(get_pcvar_num(g_Country))
	{
		get_user_ip(id, s_CountryIp, charsmax(s_CountryIp))
		switch(get_pcvar_num(g_Country))
		{
			case 1:
			{
				geoip_country(s_CountryIp, s_Country1)
				format(s_Country, charsmax(s_Country), "%s", s_Country1)
			}
			case 2:
			{
				geoip_code2(s_CountryIp, s_Country2)
				format(s_Country, charsmax(s_Country), "%s", s_Country2)
			}
			case 3:
			{
				geoip_code3(s_CountryIp, s_Country3)
				format(s_Country, charsmax(s_Country), "%s", s_Country3)
			}
		}
	}

	ExecuteForward(fwd_Format, fwdResult, id)
	mLen = 0
	lgLen = 0
	new posnum
	mLen = format(Message, charsmax(Message), "^x01")

	if(AddsNum[CT_MSGPOS_START])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_START]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_START][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_START][posnum])
		}
	}

	if(!is_user_alive(id) && !equal(AliveTeam, "SPECTATOR"))
	{
		isAlive = 0
		mLen += format(Message[mLen], charsmax(Message) - mLen, "^x01*%L* ", LANG_PLAYER, "CT_DEAD")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_DEAD")
	}
	else if(!is_user_alive(id) && equal(AliveTeam, "SPECTATOR"))
	{
		isAlive = 0
		mLen += format(Message[mLen], charsmax(Message) - mLen, "^x01*%L* ", LANG_PLAYER, "CT_SPECTATOR")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_SPECTATOR")
	}
	else
	{
		isAlive = 1
		mLen += format(Message[mLen], charsmax(Message) - mLen, "^x01")
	}

	if(AddsNum[CT_MSGPOS_PREFIX])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_PREFIX]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_PREFIX][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_PREFIX][posnum])
		}
	}

	if(get_pcvar_num(g_Country))
	{
		get_user_ip(id, s_CountryIp, charsmax(s_CountryIp))
		if(containi(s_CountryIp, "10.") == 0)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_LAN")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_LAN")
		}
		else if(containi(s_CountryIp, "172.") == 0)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_PROVIDER")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_PROVIDER")
		}
		else if(containi(s_Country, "err") != -1)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_ERROR")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_ERROR")
		}
		else
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%s^x01] ", s_Country)
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%s] </font>", s_Country)
		}
	}

	if(get_user_flags(id) & NICK_LEVEL && get_pcvar_num(g_AdminPrefix))
	{
		mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_ADMIN")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_ADMIN")
	}

	if(AddsNum[CT_MSGPOS_PRENAME])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_PRENAME]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_PRENAME][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_PRENAME][posnum])
		}
	}

	if(get_user_flags(id) & NICK_LEVEL)
	{
		switch(get_pcvar_num(g_NameColor))
		{
			case 1:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, "%s", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", s_Name)
			}
			case 2:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x04%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">%s </font>", s_Name)
			}
			case 3:
			{
				color = "SPECTATOR"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font>", s_Name)
			}
			case 4:
			{
				color = "CT"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font>", s_Name)
			}
			case 5:
			{
				color = "TERRORIST"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font>", s_Name)
			}
			case 6:
			{
				get_user_team(id, color, charsmax(color))
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				if(equal(color, "CT"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font>", s_Name)
				}
				else if(equal(color, "TERRORIST"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font>", s_Name)
				}
				else if(equal(color, "SPECTATOR"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font>", s_Name)
				}
			}
		}

		switch(get_pcvar_num(g_ChatColor))
		{
			case 1:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": %s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">: %s </font>", s_Msg)
			}
			case 2:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x04%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">: %s </font>", s_Msg)
			}
			case 3:
			{
				copy(color, 9, "SPECTATOR")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">: %s </font>", s_Msg)
			}
			case 4:
			{
				copy(color, 9, "CT")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">: %s </font>", s_Msg)
			}
			case 5:
			{
				copy(color, 9, "TERRORIST")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">: %s </font>", s_Msg)
			}
			case 6:
			{
				get_user_team(id, TeamColor, 9)
				copy(color, 9, TeamColor)
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)

				if(equal(TeamColor, "CT"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">: %s </font>", s_Msg)
				}
				else if(equal(TeamColor, "TERRORIST"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">: %s </font>", s_Msg)
				}
				else if(equal(TeamColor, "SPECTATOR"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">: %s </font>", s_Msg)
				}
			}
		}
	}
	else
	{
		get_user_team(id, color, 9)
		mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s ^x01: %s", s_Name, SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
		if(equal(color, "CT"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
		else if(equal(color, "TERRORIST"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
		else if(equal(color, "SPECTATOR"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
	}

	if(AddsNum[CT_MSGPOS_END])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_END]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, " %s", Adds[CT_MSGPOS_END][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^"> %s</font>", Adds[CT_MSGPOS_END][posnum])
		}
	}

	if(strlen(Message) >= 192)
	{
		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_LONGMSG")
		WriteMessage(id, Info)
		return PLUGIN_HANDLED
	}

	switch(get_pcvar_num(g_AllChat))
	{
		case 0:
		{
			SendMessage(color, isAlive)
		}
		case 1:
		{
			SendMessageAll(color)
		}
		case 2:
		{
			if(get_user_flags(id) & ACCESS_LEVEL)
			{
				SendMessageAll(color)
			}
			else
			{
				SendMessage(color, isAlive)
			}
		}
	}

	if(get_pcvar_num(g_Log))
	{
		format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
		format(p_LogFile, charsmax(p_LogFile), "%s/chat_%s.htm", p_LogDir, p_LogFileTime)

		if(!dir_exists(p_LogDir))
		{
			mkdir(p_LogDir)
		}

		if(!file_exists(p_LogFile))
		{
			format(p_LogTitle, charsmax(p_LogTitle), "<title>Lunetistii CtGag Chat Log v3.0 by PedoBear - %s</title>%s", p_LogFileTime, LOGTITLE)
			write_file(p_LogFile, p_LogTitle)
			write_file(p_LogFile, LOGFONT)
		}

		get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
		get_user_authid(id, p_LogSteamId, charsmax(p_LogSteamId))
		format(p_LogInfo, charsmax(p_LogInfo), "<font color=^"black^">%s &lt;%s&gt;&lt;%s&gt;</font>", p_LogTime, p_LogSteamId, p_LogIp)
		format(p_LogMessage, charsmax(p_LogMessage), "%s - %s<br>", p_LogInfo, p_LogMsg)
		write_file(p_LogFile, p_LogMessage)
	}

	if((!SwearFound || get_pcvar_num(g_SwearGag) != 1) && get_pcvar_num(g_FloodTime))
	{
		SysTime = get_systime(0)
		i_Gag[id] = SysTime + get_pcvar_num(g_FloodTime)
		Flood[id] = true
	}

	return PLUGIN_HANDLED
}

public hook_say_team(id)
{
	if(is_user_hltv(id) || is_user_bot(id))
	{
		return PLUGIN_CONTINUE
	}

	if(is_user_gaged(id))
	{
		return PLUGIN_HANDLED
	}

	read_args(s_Msg, charsmax(s_Msg))
	remove_quotes(s_Msg)
	replace_all(s_Msg, charsmax(s_Msg), "%s", "")

	for(new posid; posid < 4; posid++)
	{
		AddsNum[posid] = 0
	}

	ExecuteForward(fwd_Begin, fwdResult, id, s_Msg, 1)

	if(check_plugin_cmd(id, s_Msg))
	{
		return PLUGIN_CONTINUE
	}

	if(is_empty_message(s_Msg))
	{
		return PLUGIN_HANDLED
	}

	if(is_system_message(s_Msg))
	{
		if(get_pcvar_num(g_IgnoreMode) == 1)
		{
			SlashFound = true
		}
		else if(get_pcvar_num(g_IgnoreMode) == 2)
		{
			return PLUGIN_HANDLED
		}
		else if(get_pcvar_num(g_IgnoreMode) == 3)
		{
			return PLUGIN_CONTINUE
		}
	}
	else
	{
		SlashFound = false
	}

	get_time("20%y.%m.%d", p_LogFileTime, charsmax(p_LogFileTime))
	get_time("%H:%M:%S", p_LogTime, charsmax(p_LogTime))

	if(get_pcvar_num(g_Cheat) && is_cheat_message(id, s_Msg))
	{
		ExecuteForward(fwd_Cheat, fwdResult, id, s_Msg)
		client_punish(id, PUNISH_CHEAT)
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(g_Spam) && is_spam_message(id, s_Msg))
	{
		ExecuteForward(fwd_Spam, fwdResult, id, s_Msg)
		SpamFound[id]++
		if(SpamFound[id]-1 >= get_pcvar_num(g_SpamWarns))
		{
			SpamFound[id] = 0
			client_punish(id, PUNISH_SPAM)
		}
		else
		{
			format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SPAMWARN", get_pcvar_num(g_SpamWarns) - SpamFound[id])
			WriteMessage(id, Info)

			if(get_pcvar_num(g_Sounds))
			{
				client_cmd(id, "spk buttons/blip2")
			}
		}

		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(g_Ignore) && is_ignored_message(s_Msg))
	{
		if(get_pcvar_num(g_IgnoreMode) == 1)
		{
			IgnoreFound = true
		}
		else if(get_pcvar_num(g_IgnoreMode) == 2)
		{
			return PLUGIN_HANDLED
		}
		else if(get_pcvar_num(g_IgnoreMode) == 3)
		{
			return PLUGIN_CONTINUE
		}
	}
	else
	{
		IgnoreFound = false
	}

	get_user_team(id, AliveTeam, charsmax(AliveTeam))
	ReplaceSwear(charsmax(s_Msg), s_Msg)

	if(get_pcvar_num(g_Translit) && !IgnoreFound)
	{
		get_user_info(id, "translit", s_Info, charsmax(s_Info))
		if(equal(s_Info, "1") || get_pcvar_num(g_AutoRus) == 2)
		{
			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_SwearMsg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_SwearMsg, charsmax(s_SwearMsg), g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}

			for(new i; i < i_MaxSimbols; i++)
			{
				if(contain(s_Msg, g_OriginalSimb[i]) != -1)
				{
					replace_all(s_Msg, charsmax(s_Msg), g_OriginalSimb[i], g_TranslitSimb[i])
				}
			}
		}
	}

	get_user_name(id, s_Name, charsmax(s_Name))

	if(get_pcvar_num(g_SwearFilter))
	{
		new iSwear = is_swear_message(id, s_SwearMsg)
		if(iSwear)
		{
			ExecuteForward(fwd_Swear, fwdResult, id, s_Msg)
		}

		if(iSwear)
		{
			SwearFound = 1
			SwearCount[id]++

			if(get_pcvar_num(g_SwearGag) && (SwearCount[id]-1 >= get_pcvar_num(g_SwearWarns)))
			{
				SwearCount[id] = 0
				Flood[id] = false
				SysTime = get_systime(0)
				i_Gag[id] = SysTime + get_pcvar_num(g_SwearTime)*60
				get_user_name(id, s_GagName[id], 31)
				get_user_ip(id, s_GagIp[id], 31, 1)
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SWEAR_GAG", get_pcvar_num(g_SwearTime))
				WriteMessage(id, Info)

				if(get_pcvar_num(g_Log) == 1)
				{
					format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
					format(p_LogFile, charsmax(p_LogFile), "%s/gag_%s.log", p_LogDir, p_LogFileTime)

					if(!dir_exists(p_LogDir))
					{
						mkdir(p_LogDir)
					}

					get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
					format(p_LogMessage, charsmax(p_LogMessage), "%s - Swear Filter has gaged %s <%s> for %d minutes. Message: %s. Found: %s", p_LogTime, s_GagName[id], p_LogIp, get_pcvar_num(g_SwearTime), s_SwearMsg, Swear[iSwear - 1])
					write_file(p_LogFile, p_LogMessage)
				}

				if(get_pcvar_num(g_Sounds))
				{
					client_cmd(id, "spk buttons/button5")
				}
			}
			else if(get_pcvar_num(g_SwearGag))
			{
				format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SWEARWARN", get_pcvar_num(g_SwearWarns) - SwearCount[id])
				WriteMessage(id, Info)

				if(get_pcvar_num(g_Sounds))
				{
					client_cmd(id, "spk buttons/blip2")
				}
			}
		}
		else
		{
			SwearFound = 0
		}
	}

	if(get_pcvar_num(g_Country))
	{
		get_user_ip(id, s_CountryIp, charsmax(s_CountryIp))
		switch(get_pcvar_num(g_Country))
		{
			case 1:
			{
				geoip_country(s_CountryIp, s_Country1)
				format(s_Country, charsmax(s_Country), "%s", s_Country1)
			}
			case 2:
			{
				geoip_code2(s_CountryIp, s_Country2)
				format(s_Country, charsmax(s_Country), "%s", s_Country2)
			}
			case 3:
			{
				geoip_code3(s_CountryIp, s_Country3)
				format(s_Country, charsmax(s_Country), "%s", s_Country3)
			}
		}
	}

	ExecuteForward(fwd_Format, fwdResult, id)
	mLen = 0
	lgLen = 0
	new posnum
	mLen = format(Message, charsmax(Message), "^x01")

	if(AddsNum[CT_MSGPOS_START])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_START]; posnum++)
		{
			log_amx("ADD %s", Adds[CT_MSGPOS_START][posnum])
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_START][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_START][posnum])
		}
	}

	if(!is_user_alive(id) && !equal(AliveTeam, "SPECTATOR"))
	{
		isAlive = 0
		mLen = format(Message, charsmax(Message), "^x01*%L* ", LANG_PLAYER, "CT_DEAD")
		lgLen = format(p_LogMsg, charsmax(p_LogMsg), "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_DEAD")
	}
	else if(!is_user_alive(id) && equal(AliveTeam, "SPECTATOR"))
	{
		isAlive = 0
		mLen = format(Message, charsmax(Message), "^x01*%L* ", LANG_PLAYER, "CT_SPECTATOR")
		lgLen = format(p_LogMsg, charsmax(p_LogMsg), "<font color=^"#FFB41E^">*%L* </font>", LANG_PLAYER, "CT_SPECTATOR")
	}
	else
	{
		isAlive = 1
		mLen = format(Message, charsmax(Message), "^x01")
	}

	if(equal(AliveTeam, "TERRORIST"))
	{
		mLen += format(Message[mLen], charsmax(Message) - mLen, "(%L) ", LANG_PLAYER, "CT_TERRORIST")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - mLen, "<font color=^"#FFB41E^">(%L) </font>", LANG_PLAYER, "CT_TERRORIST")
	}
	else if(equal(AliveTeam, "CT"))
	{
		mLen += format(Message[mLen], charsmax(Message) - mLen, "(%L) ", LANG_PLAYER, "CT_CT")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - mLen,  "<font color=^"#FFB41E^">(%L) </font>", LANG_PLAYER, "CT_CT")
	}
	else if(equal(AliveTeam, "SPECTATOR"))
	{
		mLen += format(Message[mLen], charsmax(Message) - mLen, "(%L) ", LANG_PLAYER, "CT_SPECTATOR2")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - mLen, "<font color=^"#FFB41E^">(%L) </font>", LANG_PLAYER, "CT_SPECTATOR2")
	}

	if(AddsNum[CT_MSGPOS_PREFIX])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_PREFIX]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_PREFIX][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_PREFIX][posnum])
		}
	}

	if(get_pcvar_num(g_Country))
	{
		get_user_ip(id, s_CountryIp, charsmax(s_CountryIp))
		if(containi(s_CountryIp, "10.") == 0)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_LAN")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_LAN")
		}
		else if(containi(s_CountryIp, "172.") == 0)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_PROVIDER")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_PROVIDER")
		}
		else if(containi(s_Country, "err") != -1)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_ERROR")
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_ERROR")
		}
		else
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%s^x01] ", s_Country)
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%s] </font>", s_Country)
		}
	}

	if(get_user_flags(id) & NICK_LEVEL && get_pcvar_num(g_AdminPrefix))
	{
		mLen += format(Message[mLen], charsmax(Message) - mLen, "[^x04%L^x01] ", LANG_PLAYER, "CT_ADMIN")
		lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">[%L] </font>", LANG_PLAYER, "CT_ADMIN")
	}

	if(AddsNum[CT_MSGPOS_PRENAME])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_PRENAME]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, "%s ", Adds[CT_MSGPOS_PRENAME][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", Adds[CT_MSGPOS_PRENAME][posnum])
		}
	}

	if(get_user_flags(id) & NICK_LEVEL)
	{
		switch(get_pcvar_num(g_NameColor))
		{
			case 1:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, "%s", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">%s </font>", s_Name)
			}
			case 2:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x04%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">%s </font>", s_Name)
			}
			case 3:
			{
				color = "SPECTATOR"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font>", s_Name)
			}
			case 4:
			{
				color = "CT"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font>", s_Name)
			}
			case 5:
			{
				color = "TERRORIST"
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font>", s_Name)
			}
			case 6:
			{
				get_user_team(id, color, charsmax(color))
				mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s^x01 ", s_Name)
				if(equal(color, "CT"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font>", s_Name)
				}
				else if(equal(color, "TERRORIST"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font>", s_Name)
				}
				else if(equal(color, "SPECTATOR"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font>", s_Name)
				}

			}
		}

		switch(get_pcvar_num(g_ChatColor))
		{
			case 1:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": %s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^">: %s </font>", s_Msg)
			}
			case 2:
			{
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x04%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"green^">: %s </font>", s_Msg)
			}
			case 3:
			{
				copy(color, 9, "SPECTATOR")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">: %s </font>", s_Msg)
			}
			case 4:
			{
				copy(color, 9, "CT")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">: %s </font>", s_Msg)
			}
			case 5:
			{
				copy(color, 9, "TERRORIST")
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)
				lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">: %s </font>", s_Msg)
			}
			case 6:
			{
				get_user_team(id, TeamColor, 9)
				copy(color, 9, TeamColor)
				mLen += format(Message[mLen], charsmax(Message) - mLen, ": ^x03%s", SwearFound ? Replace[random(ReplaceNum)] : s_Msg)

				if(equal(TeamColor, "CT"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">: %s </font>", s_Msg)
				}
				else if(equal(TeamColor, "TERRORIST"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">: %s </font>", s_Msg)
				}
				else if(equal(TeamColor, "SPECTATOR"))
				{
					lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">: %s </font>", s_Msg)
				}
			}
		}
	}
	else
	{
		get_user_team(id, color, 9)
		mLen += format(Message[mLen], charsmax(Message) - mLen, "^x03%s ^x01: %s", s_Name, SwearFound ? Replace[random(ReplaceNum)] : s_Msg)

		if(equal(color, "CT"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"blue^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
		else if(equal(color, "TERRORIST"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"red^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
		else if(equal(color, "SPECTATOR"))
		{
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"gray^">%s </font><font color=^"#FFB41E^">: %s </font>", s_Name, s_Msg)
		}
	}

	if(AddsNum[CT_MSGPOS_END])
	{
		for(posnum = 0; posnum < AddsNum[CT_MSGPOS_END]; posnum++)
		{
			mLen += format(Message[mLen], charsmax(Message) - mLen, " %s", Adds[CT_MSGPOS_END][posnum])
			lgLen += format(p_LogMsg[lgLen], charsmax(p_LogMsg) - lgLen, "<font color=^"#FFB41E^"> %s</font>", Adds[CT_MSGPOS_END][posnum])
		}
	}

	if(strlen(Message) >= 192)
	{
		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_LONGMSG")
		WriteMessage(id, Info)
		return PLUGIN_HANDLED
	}

	SendTeamMessage(color, isAlive, get_user_team(id))

	if(get_pcvar_num(g_Log))
	{
		format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
		format(p_LogFile, charsmax(p_LogFile), "%s/chat_%s.htm", p_LogDir, p_LogFileTime)

		if(!dir_exists(p_LogDir))
		{
			mkdir(p_LogDir)
		}

		if(!file_exists(p_LogFile))
		{
			format(p_LogTitle, charsmax(p_LogTitle), "<title>Lunetistii CtGag Chat Log v3.0 by PedoBear - %s</title>%s", p_LogFileTime, LOGTITLE)
			write_file(p_LogFile, p_LogTitle)
			write_file(p_LogFile, LOGFONT)
		}

		get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
		get_user_authid(id, p_LogSteamId, charsmax(p_LogSteamId))
		format(p_LogInfo, charsmax(p_LogInfo), "<font color=^"black^">%s &lt;%s&gt;&lt;%s&gt;</font>", p_LogTime, p_LogSteamId, p_LogIp)
		format(p_LogMessage, charsmax(p_LogMessage), "%s - %s<br>", p_LogInfo, p_LogMsg)
		write_file(p_LogFile, p_LogMessage)
	}

	if((!SwearFound || get_pcvar_num(g_SwearGag) != 1) && get_pcvar_num(g_FloodTime))
	{
		SysTime = get_systime(0)
		i_Gag[id] = SysTime + get_pcvar_num(g_FloodTime)
		Flood[id] = true
	}

	return PLUGIN_HANDLED
}

public plugin_cfg()
{
	get_configsdir(s_ConfigsDir, 63)
	format(s_File, charsmax(s_File), "%s/lunetistii_gag/traducere.ini", s_ConfigsDir)
	format(s_SwearFile, charsmax(s_File), "%s/lunetistii_gag/cuvinte.ini", s_ConfigsDir)
	format(s_ReplaceFile, charsmax(s_ReplaceFile), "%s/lunetistii_gag/rescriere.ini", s_ConfigsDir)
	format(s_IgnoreFile, charsmax(s_IgnoreFile), "%s/lunetistii_gag/ignorari.ini", s_ConfigsDir)
	format(s_SpamFile,  charsmax(s_SpamFile), "%s/lunetistii_gag/reclame.ini", s_ConfigsDir)
	format(s_CheatFile,  charsmax(s_CheatFile), "%s/lunetistii_gag/coduri.ini", s_ConfigsDir)
	format(s_ConfigFile, charsmax(s_ConfigFile), "%s/lunetistii_gag/config.cfg", s_ConfigsDir)

	if(file_exists(s_File))
	{
		while((Line = read_file(s_File, Line, Input, 31, Len)) != 0)
		{
			strtok(Input, g_OriginalSimb[i_MaxSimbols], 16, g_TranslitSimb[i_MaxSimbols], 16, ' ')
			i_MaxSimbols++
		}
		TranslitList = true
	}
	else
	{
		set_pcvar_num(g_Translit, 0)
		TranslitList = false
	}

	if(file_exists(s_SwearFile))
	{
		new i=0
		while(i < MAX_SWEARS && read_file(s_SwearFile, i , Swear[SwearNum], 63, Len))
		{
			i++
			if(Swear[SwearNum][0] == ';' || !Len)
			{
				continue
			}
			SwearNum++
		}
		SwearList = true
	}
	else
	{
		set_pcvar_num(g_SwearFilter, 0)
		SwearList = false
	}

	if(file_exists(s_ReplaceFile))
	{
		new i=0
		while(i < MAX_REPLACES && read_file(s_ReplaceFile, i , Replace[ReplaceNum], 191, Len))
		{
			i++
			if(Replace[ReplaceNum][0] == ';' || !Len)
			{
				continue
			}
			ReplaceNum++
		}
		ReplaceList = true
	}
	else
	{
		set_pcvar_num(g_SwearFilter, 0)
		ReplaceList = false
	}

	if(file_exists(s_IgnoreFile))
	{
		new i=0
		while(i < MAX_IGNORES && read_file(s_IgnoreFile, i , Ignore[IgnoreNum], 63, Len))
		{
			i++
			if(Ignore[IgnoreNum][0] == ';' || !Len)
			{
				continue
			}
			IgnoreNum++
		}
		IgnoreList = true
	}
	else
	{
		set_pcvar_num(g_Ignore, 0)
		IgnoreList = false
	}

	if(file_exists(s_SpamFile))
	{
		new i=0
		while(i < MAX_SPAMS && read_file(s_SpamFile, i , Spam[SpamNum], 191, Len))
		{
			i++
			if(Spam[SpamNum][0] == ';' || !Len)
			{
				continue
			}
			SpamNum++
		}
		SpamList = true
	}
	else
	{
		set_pcvar_num(g_Spam, 0)
		SpamList = false
	}

	if(file_exists(s_CheatFile))
	{
		new i=0
		while(i < MAX_CHEAT && read_file(s_CheatFile, i , Cheat[CheatNum], 191, Len))
		{
			i++
			if(Cheat[CheatNum][0] == ';' || !Len)
			{
				continue
			}
			CheatNum++
		}
		CheatList = true
	}
	else
	{
		set_pcvar_num(g_Cheat, 0)
		CheatList = false
	}

	if(file_exists(s_ConfigFile))
	{
		server_cmd("exec %s", s_ConfigFile)
		ConfigsList = true
	}
	else
	{
		ConfigsList = false
	}

	server_print("========== [%s] START SET FCVAR ==========", PLUGIN)
	register_cvar("Lunetistii Gag Version", "2.0b Final", FCVAR_SERVER)

	if(TranslitList)
	{
		register_cvar("Lunetistii Gag Status", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Status", "Failed", FCVAR_SERVER)
	}
	if(SwearList)
	{
		register_cvar("Lunetistii Gag Swear", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Swear", "Failed", FCVAR_SERVER)
	}

	if(ReplaceList)
	{
		register_cvar("Lunetistii Gag Replace", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Replace", "Failed", FCVAR_SERVER)
	}

	if(IgnoreList)
	{
		register_cvar("Lunetistii Gag Ignores", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Ignores", "Failed", FCVAR_SERVER)
	}

	if(SpamList)
	{
		register_cvar("Lunetistii Gag Spam", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Spam", "Failed", FCVAR_SERVER)
	}

	if(CheatList)
	{
		register_cvar("Lunetistii Gag Cheat", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Cheat", "Failed", FCVAR_SERVER)
	}

	if(ConfigsList)
	{
		register_cvar("Lunetistii Gag Config", "Loaded", FCVAR_SERVER)
	}
	else
	{
		register_cvar("Lunetistii Gag Config", "Failed", FCVAR_SERVER)
	}

	server_print("=========== [%s] END SET FCVAR ===========", PLUGIN)
	server_print("=========== [%s] START DEBUG =============", PLUGIN)

	if(TranslitList)
	{
		server_print("[%s] Translit File Loaded. Symbols: %d", PLUGIN, i_MaxSimbols)
	}
	else
	{
		server_print("[%s] Translit File Not Found: %s", PLUGIN, s_File)
	}

	if(SwearList)
	{
		server_print("[%s] Swear File Loaded. Swears: %d", PLUGIN, SwearNum)	
	}
	else
	{
		server_print("[%s] Swear File Not Found: %s", PLUGIN, s_SwearFile)
	}

	if(ReplaceList)
	{
		server_print("[%s] Replace File Loaded. Replacements: %d", PLUGIN, ReplaceNum)	
	}
	else
	{
		server_print("[%s] Replace File Not Found: %s", PLUGIN, s_ReplaceFile)
	}

	if(IgnoreList)
	{
		server_print("[%s] Ignore File Loaded. Ignore Words: %d", PLUGIN, IgnoreNum)
	}
	else
	{
		server_print("[%s] Ignore File Not Found: %s", PLUGIN, s_IgnoreFile)
	}

	if(SpamList)
	{
		server_print("[%s] Spam File Loaded. Spam Words: %d", PLUGIN, SpamNum)
	}
	else
	{
		server_print("[%s] Spam File Not Found: %s", PLUGIN, s_SpamFile)
	}

	if(CheatList)
	{
		server_print("[%s] Cheat File Loaded. Cheat Words: %d", PLUGIN, CheatNum)
	}
	else
	{
		server_print("[%s] Cheat File Not Found: %s", PLUGIN, s_CheatFile)
	}

	if(ConfigsList)
	{
		server_print("[%s] Config File Executed. Version: %s", PLUGIN, VERSION)
	}
	else
	{
		server_print("[%s] Config File Not Found: %s", PLUGIN, s_ConfigFile)
	}

	server_print("=========== [%s] END DEBUG ===============", PLUGIN)
	return PLUGIN_CONTINUE
}

public cmd_eng(id)
{
	if(!is_user_connected(id) || get_pcvar_num(g_AutoRus) == 2)
	{
		return PLUGIN_CONTINUE
	}

	client_cmd(id, "setinfo ^"translit^" ^"1^"")
	format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_RUS")
	WriteMessage(id, Info)

	if(get_pcvar_num(g_Sounds))
	{
		client_cmd(id, "spk buttons/blip2")
	}

	return PLUGIN_CONTINUE
}

public cmd_ro(id)
{
	if(!is_user_connected(id) || get_pcvar_num(g_AutoRus) == 2)
	{
		return PLUGIN_CONTINUE
	}

	client_cmd(id, "setinfo ^"translit^" ^"0^"")
	format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_ENG")
	WriteMessage(id, Info)

	if(get_pcvar_num(g_Sounds))
	{
		client_cmd(id, "spk buttons/blip2")
	}

	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	Logged[id] = false
	set_task(10.0, "ShowInfo", id)
	get_user_name(id, s_CheckGag, charsmax(s_CheckGag))
	get_user_ip(id, s_CheckIp, charsmax(s_CheckIp), 1)

	if(get_systime(0) < i_Gag[id])
	{
		if(!equal(s_GagName[id], s_CheckGag) && !equal(s_GagIp[id], s_CheckIp))
		{
			i_Gag[id] = get_systime(0)
			SpamFound[id] = 0
			SwearCount[id] = 0
		}
	}

	return PLUGIN_CONTINUE
}

stock is_user_gaged(id)
{
	SysTime = get_systime(0)

	if(SysTime < i_Gag[id])
	{
		if(Flood[id])
		{
			format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_FLOOD")
			i_Gag[id] = SysTime + get_pcvar_num(g_FloodTime)
		}
		else
		{
			i_ShowGag = i_Gag[id] - SysTime
			format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_GAGED", i_ShowGag/60+1)
		}

		WriteMessage(id, Info)

		if(get_pcvar_num(g_Sounds))
		{
			client_cmd(id, "spk buttons/button2")
		}
		return 1
	}
	else if(Flood[id])
	{
		Flood[id] = false
	}

	return 0
}

stock is_empty_message(const Message[])
{
	if(Message[0] == ' ' || equal(Message, "") || !strlen(Message))
	{
		return 1
	}

	return 0
}

stock is_system_message(const Message[])
{
	if(Message[0] == '@' || Message[0] == '/' || Message[0] == '!')
	{
		return 1
	}

	return 0
}

stock is_cheat_message(id, const Message[])
{
	new i = 0
	if(get_pcvar_num(g_CheatImmunity) && get_user_flags(id) & IMMUNITY_LEVEL)
	{
		return 0
	}

	while(i < CheatNum)
	{
		if(containi(Message, Cheat[i++]) != -1)
		{
			return 1
		}
	}

	return 0
}

stock is_spam_message(id, const Message[])
{
	new i = 0
	if(get_pcvar_num(g_SpamImmunity) && get_user_flags(id) & IMMUNITY_LEVEL)
	{
		return 0
	}

	while(i < SpamNum)
	{
		if(containi(Message, Spam[i++]) != -1)
		{
			return 1
		}
	}

	return 0
}

stock is_ignored_message(const Message[])
{
	new i = 0
	while(i < IgnoreNum)
	{
		if(containi(Message, Ignore[i++]) != -1 || SlashFound)
		{
			return 1
		}
	}

	return 0
}

stock is_swear_message(id, const Message[])
{
	new i = 0
	if(get_user_flags(id) & IMMUNITY_LEVEL && get_pcvar_num(g_SwearImmunity))
	{
		return 0
	}

	while(i < SwearNum )
	{
		if(containi(Message, Swear[i++]) != -1)
		{
			new j, playercount, players[32]
			get_players( players, playercount, "c" )
			for(j = 0 ; j < playercount ; j++)
			{
				if(get_user_flags(players[j]) & ACCESS_LEVEL && is_user_connected(players[j]))
				{
					format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_CONTAIN", Swear[i-1])
					WriteMessage(players[j], Info)
					console_print(players[j], "[%s] %L", PLUGIN, LANG_PLAYER, "CT_CONTAIN", Swear[i-1])
					format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, LANG_PLAYER, "CT_SWEAR", s_Name, s_Msg)
					WriteMessage(players[j], Info)
					console_print(players[j], "[%s] %L", PLUGIN, LANG_PLAYER, "CT_SWEAR", s_Name, s_Msg)
				}
			}

			return i
		}
	}

	return 0
}

stock check_plugin_cmd(id, const Message[])
{
	if(equal(Message, "/eng"))
	{
		cmd_eng(id)
		return 0
	}

	if(equal(Message, "/ro"))
	{
		cmd_ro(id)
		return 0
	}

	for(new cmdid; cmdid < CmdsNum; cmdid++)
	{
		if(equal(Message, Cmds[cmdid]))
		{
			return 1
		}
	}

	return 0
}

stock client_punish(id, type)
{
	switch(type)
	{
		case PUNISH_CHEAT:
		{
			switch(get_pcvar_num(g_CheatAction))
			{
				case 1:
				{
					server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "CT_KICKCHEAT")
				}
				case 2:
				{
					get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
					get_user_name(id, s_BanName, charsmax(s_BanName))
					server_cmd("banid ^"%d^" ^"%s^";wait;wait;wait;writeid", get_pcvar_num(g_CheatActionTime), s_BanAuthId)
				}
				case 3:
				{
					get_user_ip(id, s_BanIp, charsmax(s_BanIp), 1)
					get_user_name(id, s_BanName, charsmax(s_BanName))
					server_cmd("addip ^"%d^" ^"%s^";wait;wait;wait;writeip", get_pcvar_num(g_CheatActionTime), s_BanIp)
				}
				case 4:
				{
					get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
					get_user_name(id, s_BanName, charsmax(s_BanName))
					format(s_Reason, 127, "[%s] Cheat", PLUGIN)
					server_cmd("amx_ban %d %s %s", get_pcvar_num(g_CheatActionTime), s_BanAuthId, s_Reason)
				}
				case 5:
				{
					get_user_ip(id, s_BanIp, charsmax(s_BanIp), 1)
					get_user_name(id, s_BanName, charsmax(s_BanName))
					format(s_Reason, 127, "[%s] Cheat", PLUGIN)
					server_cmd("amx_ban %d %s %s", get_pcvar_num(g_CheatActionTime), s_BanIp, s_Reason)
				}
				case 6:
				{
					get_user_name(id, s_KickName, charsmax(s_KickName))
					get_user_ip(id, s_BanIp, charsmax(s_BanIp), 1)
					get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
					get_user_name(id, s_BanName, charsmax(s_BanName))
					num_to_str(get_user_userid(id), sUserId, charsmax(sUserId))
					get_pcvar_string(g_CheatActionCustom, s_CheatAction, charsmax(s_CheatAction))
					replace_all(s_CheatAction, charsmax(s_CheatAction), "%userid%", sUserId)
					replace_all(s_CheatAction, charsmax(s_CheatAction), "%ip%", s_BanIp)
					replace_all(s_CheatAction, charsmax(s_CheatAction), "%steamid%", s_BanAuthId)
					replace_all(s_CheatAction, charsmax(s_CheatAction), "%name%", s_KickName)
					server_cmd(s_CheatAction)
				}
			}

			if(get_pcvar_num(g_Log) && get_pcvar_num(g_CheatAction) != 1 && get_pcvar_num(g_CheatAction) != 6 && !Logged[id])
			{
				log_action(id, ACTION_CHEAT)
				Logged[id] = true
			}
		}
		case PUNISH_SPAM:
		{
			switch(get_pcvar_num(g_SpamAction))
			{
				case 1:
				{
					server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "CT_KICK")
				}
				case 2:
				{
					SysTime = get_systime(0)
					i_Gag[id] = SysTime + get_pcvar_num(g_SpamActionTime) * 60
					format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_SPAMGAG", get_pcvar_num(g_SpamActionTime))
					WriteMessage(id, Info)
					Flood[id] = false
					get_user_name(id, s_GagName[id], 31)
					get_user_ip(id, s_GagIp[id], 31, 1)

					if(get_pcvar_num(g_Log))
					{
						format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)
						format(p_LogFile, charsmax(p_LogFile), "%s/gag_%s.log", p_LogDir, p_LogFileTime)

						if(!dir_exists(p_LogDir))
						{
							mkdir(p_LogDir)
						}

						get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
						format(p_LogMessage, charsmax(p_LogMessage), "%s - Spam Filter has gaged %s <%s> for %d minutes. Message: %s", p_LogTime, s_GagName[id], s_GagIp[id], get_pcvar_num(g_SpamActionTime), s_Msg)
						write_file(p_LogFile, p_LogMessage)

						if(get_pcvar_num(g_Sounds))
						{
							client_cmd(id, "spk buttons/button5")
						}
					}
				}
				case 3:
				{
					get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
					get_user_name(id, s_BanName, charsmax(s_BanName))
					server_cmd("banid ^"%d^" ^"%s^";wait;wait;wait;writeid", get_pcvar_num(g_SpamActionTime), s_BanAuthId)
				}
				case 4:
				{
					get_user_ip(id, s_BanIp, charsmax(s_BanIp), 1)
					get_user_name(id, s_BanName, charsmax(s_BanName))
					server_cmd("addip ^"%d^" ^"%s^";wait;wait;wait;writeip", get_pcvar_num(g_SpamActionTime), s_BanIp)
				}
				case 5:
				{
					get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
					get_user_name(id, s_BanName, charsmax(s_BanName))
					format(s_Reason, 127, "[%s] Spam", PLUGIN)
					server_cmd("amx_ban %d %s %s", get_pcvar_num(g_SpamActionTime), s_BanAuthId, s_Reason)
				}
				case 6:
				{
					get_user_ip(id, s_BanIp, charsmax(s_BanIp), 1)
					get_user_name(id, s_BanName, charsmax(s_BanName))
					format(s_Reason, 127, "[%s] Spam", PLUGIN)
					server_cmd("amx_ban %d %s %s", get_pcvar_num(g_SpamActionTime), s_BanIp, s_Reason)
				}
			}

			if(get_pcvar_num(g_Log) && get_pcvar_num(g_SpamAction) > 2)
			{
				log_action(id, ACTION_SPAM)
			}
		}
	}
}

stock log_action(id, action)
{
	get_time("20%y.%m.%d", p_LogFileTime, charsmax(p_LogFileTime))
	get_time("%H:%M:%S", p_LogTime, charsmax(p_LogTime))
	format(p_LogDir, charsmax(p_LogDir), "%s/lunetistii_gag", p_FilePath)

	if(!dir_exists(p_LogDir))
	{
		mkdir(p_LogDir)
	}

	format(p_LogFile, charsmax(p_LogFile), "%s/ban_%s.log", p_LogDir, p_LogFileTime)
	get_user_ip(id, p_LogIp, charsmax(p_LogIp), 1)
	get_user_authid(id, s_BanAuthId, charsmax(s_BanAuthId))
	get_user_name(id, s_BanName, charsmax(s_BanName))

	switch(action)
	{
		case ACTION_CHEAT:
		{
			if(get_pcvar_num(g_CheatActionTime))
			{
				format(p_LogMessage, charsmax(p_LogMessage), "%s - Cheat Filter has banned %s <%s> <%s> for %d minutes. Message: %s", p_LogTime, s_BanName, s_BanIp, s_BanAuthId, get_pcvar_num(g_CheatActionTime), s_Msg)
			}
			else
			{
				format(p_LogMessage, charsmax(p_LogMessage), "%s - Cheat Filter has banned %s <%s> <%s> permanently. Message: %s", p_LogTime, s_BanName, s_BanIp, s_BanAuthId, s_Msg)
			}

			write_file(p_LogFile, p_LogMessage)
		}
		case ACTION_SPAM:
		{
			if(get_pcvar_num(g_SpamActionTime))
			{
				format(p_LogMessage, charsmax(p_LogMessage), "%s - Spam Filter has banned %s <%s> <%s> for %d minutes. Message: %s", p_LogTime, s_BanName, s_BanIp, s_BanAuthId, get_pcvar_num(g_SpamActionTime), s_Msg)
			}
			else
			{
				format(p_LogMessage, charsmax(p_LogMessage), "%s - Spam Filter has banned %s <%s> <%s> permanently. Message: %s", p_LogTime, s_BanName, s_BanIp, s_BanAuthId, s_Msg)
			}

			write_file(p_LogFile, p_LogMessage)
		}
	}
}

stock ReplaceSwear(Size, Message[])
{
	copy(s_SwearMsg, Size, Message)
	replace_all(s_SwearMsg, Size, " ", "")
	replace_all(s_SwearMsg, Size, "A", "a")
	replace_all(s_SwearMsg, Size, "B", "b")
	replace_all(s_SwearMsg, Size, "C", "c")
	replace_all(s_SwearMsg, Size, "D", "d")
	replace_all(s_SwearMsg, Size, "E", "e")
	replace_all(s_SwearMsg, Size, "F", "f")
	replace_all(s_SwearMsg, Size, "G", "g")
	replace_all(s_SwearMsg, Size, "H", "h")
	replace_all(s_SwearMsg, Size, "I", "i")
	replace_all(s_SwearMsg, Size, "J", "j")
	replace_all(s_SwearMsg, Size, "K", "k")
	replace_all(s_SwearMsg, Size, "L", "l")
	replace_all(s_SwearMsg, Size, "M", "m")
	replace_all(s_SwearMsg, Size, "N", "n")
	replace_all(s_SwearMsg, Size, "O", "o")
	replace_all(s_SwearMsg, Size, "P", "p")
	replace_all(s_SwearMsg, Size, "Q", "q")
	replace_all(s_SwearMsg, Size, "R", "r")
	replace_all(s_SwearMsg, Size, "S", "s")
	replace_all(s_SwearMsg, Size, "T", "t")
	replace_all(s_SwearMsg, Size, "U", "u")
	replace_all(s_SwearMsg, Size, "V", "v")
	replace_all(s_SwearMsg, Size, "W", "w")
	replace_all(s_SwearMsg, Size, "X", "x")
	replace_all(s_SwearMsg, Size, "Y", "y")
	replace_all(s_SwearMsg, Size, "Z", "z")
	replace_all(s_SwearMsg, Size, "{", "[")
	replace_all(s_SwearMsg, Size, "}", "]")
	replace_all(s_SwearMsg, Size, "<", ",")
	replace_all(s_SwearMsg, Size, ">", ".")
	replace_all(s_SwearMsg, Size, "~", "`")
	replace_all(s_SwearMsg, Size, "*", "")
	replace_all(s_SwearMsg, Size, "_", "")
}

stock SendMessage(color[], alive)
{
	for(new player = 0; player <= get_maxplayers(); player++)
	{
		if(!is_user_connected(player))
		{
			continue
		}

		if (alive && is_user_alive(player) || !alive && !is_user_alive(player) || get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL)
		{
			console_print(player, "%s : %s", s_Name, s_Msg)
			get_user_team(player, TeamName, 9)
			ChangeTeamInfo(player, color)
			WriteMessage(player, Message)
			ChangeTeamInfo(player, TeamName)
		}
	}
}

stock SendMessageAll(color[])
{
	for(new player = 0; player <= get_maxplayers(); player++)
	{
		if(!is_user_connected(player))
		{
			continue
		}

		console_print(player, "%s : %s", s_Name, s_Msg)
		get_user_team(player, TeamName, 9)
		ChangeTeamInfo(player, color)
		WriteMessage(player, Message)
		ChangeTeamInfo(player, TeamName)
	}
}

stock SendTeamMessage(color[], alive, playerTeam)
{
	for (new player = 0; player <= get_maxplayers(); player++)
	{
		if (!is_user_connected(player))
		{
			continue
		}

		if(get_user_team(player) == playerTeam || (get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL))
		{
			if (alive && is_user_alive(player) || !alive && !is_user_alive(player) || get_pcvar_num(g_Listen) && get_user_flags(player) & ACCESS_LEVEL)
			{
				console_print(player, "%s : %s", s_Name, s_Msg)
				get_user_team(player, TeamName, 9)
				ChangeTeamInfo(player, color)
				WriteMessage(player, Message)
				ChangeTeamInfo(player, TeamName)
			}
		}
	}
}

stock ChangeTeamInfo(player, team[])
{
	message_begin (MSG_ONE, get_user_msgid("TeamInfo"), _, player)
	write_byte(player)
	write_string(team)
	message_end()
}

stock WriteMessage(player, message[])
{
	message_begin (MSG_ONE, get_user_msgid("SayText"), _, player)
	write_byte(player)
	write_string(message)
	message_end()
}

public plugin_natives()
{
	register_library("lunetistii_gag")
	register_native("ct_cmd_lang", "native_cmd_lang", 1)
	register_native("ct_register_clcmd", "native_register_clcmd", 1)
	register_native("ct_send_infomsg", "native_infomsg", 1)
	register_native("ct_get_lang", "native_get_lang", 1)
	register_native("ct_add_to_msg", "native_add_to_msg", 1)
	register_native("ct_is_user_gaged", "native_is_gaged", 1)
	return PLUGIN_CONTINUE
}

public native_cmd_lang(id, lang)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d", id)
		return 0
	}

	if(lang != CT_LANG_RO && lang != CT_LANG_ENG)
	{
		log_error(AMX_ERR_NATIVE, "Invalid lang %d", lang)
		return 0
	}

	switch(lang)
	{
		case CT_LANG_RO:
		{
			cmd_ro(id)
			return 1
		}
		case CT_LANG_ENG:
		{
			cmd_eng(id)
			return 1
		}
	}

	return 0
}

public native_register_clcmd(const cmd[])
{
	param_convert(1)

	if(!strlen(cmd))
	{
		log_error(AMX_ERR_NATIVE, "Empty command")
		return 0
	}

	copy(Cmds[CmdsNum], 127, cmd)
	CmdsNum++
	return 1
}

public native_infomsg(id, const input[], any:...)
{
	param_convert(2)
	param_convert(3)

	if(!is_valid_player(id) && id != 0)
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d", id)
		return 0
	}

	new msg[192]
	vformat(msg, charsmax(msg), input, 3)
	format(Info, charsmax(Info), "^x01[^x04%s^x01] %s", PLUGIN, msg)

	if(id && is_user_connected(id))
	{
		WriteMessage(id, Info)
		return 1
	}
	else
	{
		for(new i = 1; i <= get_maxplayers(); i++)
		{
			if(!is_user_connected(i))
			{
				continue
			}
			WriteMessage(i, Info)
		}

		return 1
	}

	return 0
}

public native_get_lang(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d", id)
		return 0
	}

	new s_Inf[2]
	get_user_info(id, "translit", s_Inf, charsmax(s_Inf))
	return str_to_num(s_Inf)
}

public native_add_to_msg(position, const input[], any:...)
{
	param_convert(2)
	param_convert(3)
	if(0 > position || position > 3)
	{
		log_error(AMX_ERR_NATIVE, "Invalid message position %d", position)
		return 0
	}

	if(!strlen(input))
	{
		log_error(AMX_ERR_NATIVE, "Empty input string")
		return 0
	}

	new rdmsg[128]
	vformat(rdmsg, charsmax(rdmsg), input, 3)
	copy(Adds[position][AddsNum[position]], 127, rdmsg)
	AddsNum[position]++
	return 1
}

public native_is_gaged(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d", id)
		return 0
	}

	if(i_Gag[id] > get_systime(0))
	{
		return i_Gag[id]
	}

	return 0
}

public ShowInfo(id)
{
	if(get_pcvar_num(g_AutoRus) == 1)
	{
		client_cmd(id, "setinfo ^"translit^" ^"1^"")
	}

	if(get_pcvar_num(g_ShowInfo) == 1 && get_pcvar_num(g_AutoRus) != 2)
	{
		if(!is_user_connected(id))
		{
			return PLUGIN_CONTINUE
		}

		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_INFO_ENG")
		WriteMessage(id, Info)
		format(Info, charsmax(Info), "^x01[^x04%s^x01] %L", PLUGIN, id, "CT_INFO_RO")
		WriteMessage(id, Info)
	}

	return PLUGIN_CONTINUE
}