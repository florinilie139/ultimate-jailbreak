 /* Ct banner by Drekes.	
  *
  * This plugin is made for Jailbreak servers, but can be used on every server but i don't see the use in that.
  * The point is: when a player is ct on Jailbreak, and he mass freekills or something, you can ban him from ct team.
  * So he can't be ct untell you unban him from ct. 
  *
  * Commands: 	- amx_addctban 		<player> 	"bans him from ct team"
  *			  	- amx_removectban 	<player> 	"Unbans him from the ct team"
  *			  	- amx_ctbanmenu					"Shows the Ctban Menu"
  *
  * Cvars:		- ctban_kill 1				Kill a player when he gets banned
  *				- ctban_connect_msg 1			Show message when player connects
  *		
  * Credits: 
  *				Drekes
  * 			Fysiks
  * 			Wrecked_
  *			    Bugsy
  *				Crazyeffect
  *
  * Changelog:
  * 			v1.0: 	- Initial Release
  *				v1.1: 	- Minor fix (tnx wrecked)
  *				v1.2:	- Make banned ct's autojoin T (thanks VEN for auto join on connect plugin)
  *				v1.3: 	- Multilangual
  *				v1.4: 	- Added banmenu
  *				v1.5: 	- Fixed Admin only bug
  *				v1.6: 	- Added a ban/unban menu, added to amxmodmenu
  *				v1.7: 	- Added Kill cvar, Reorganized code to make more readable
  *				v2.0: 	- Completely Rewrote plugin.
  *				v2.1: 	- Improved menu functionality.
  *				v2.2: 	- Rewritten menu (Only 1 menu is used now.)
  *					  	- Renamed console commands.
  *					  	- Added connection message cvar.
  *					 	- Added reason & playername in .ini (Still works with old .ini files)
  *				v2.2a:	- Minor bug fix
  *				v2.2b:	- Terrorist players don't get killed when ct-banned.
  *				v2.3: 	- Added message when using amx_ctbanmenu with only yourself in the server.
  *						- Fixed ban list not saving.
  *						- Fixed auto-select option working on ct-banned players.
  */
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>

#pragma semicolon 1
#define VERSION 		"2.3"

#define SetCtBan(%1)      (g_iBanned |= (1<<(%1&31)))
#define ClearCtBan(%1)    (g_iBanned &= ~(1 <<(%1&31)))
#define CheckCtBan(%1)    (g_iBanned & (1<<(%1&31))) 

#define set_user_messagemode(%1)	(client_cmd(%1,"messagemode %s", g_szReasonMessage))

#define TEAMMENU_ID		5

#define TEAM_CT		1
#define TEAM_RANDOM 4

new const g_szReasonMessage[] = "Reason_for_ct-ban";

   
enum Cvars
{
	KillBanned
	, ConnectMsg
};


new Trie: g_tBannedSteamids
	, g_iBanned
	, g_iSelectedPlayer[33]
	, g_szFile[64]
	, g_pCvars[Cvars]
;


public plugin_init()
{
	register_plugin("Ct Banner", VERSION, "Drekes");
	
	register_dictionary("ctbanner.txt");
	register_dictionary("common.txt");
	
	register_concmd("amx_addctban", "Cmd_CtBan", ADMIN_SLAY, "<player> <reason> ^"Bans a player from ct team^"");
	register_concmd("amx_removectban", "Cmd_CtUnBan", ADMIN_SLAY, "<player> ^"Unbans a player from ct team^"");
	
	register_clcmd("amx_ctbanmenu", "Menu_Main", ADMIN_SLAY, "opens the ct-ban menu");
	register_clcmd("jointeam", "Cmd_JoinTeam");
	register_clcmd(g_szReasonMessage, "CmdEnterReason");
		
	register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "Menu_TeamSelect");

	register_cvar("ctban_version", VERSION, FCVAR_SPONLY | FCVAR_SERVER);
	
	new const szCvars[Cvars][][] =
	{
		{ "ctban_kill", "1" },
		{ "ctban_connect_msg", "1" }
	};
	
	for(new Cvars: i = Cvars: 0; i < Cvars; i++)
		g_pCvars[i] = register_cvar(szCvars[i][0], szCvars[i][1]);
		

	g_tBannedSteamids = TrieCreate();
	
	if(g_tBannedSteamids == Invalid_Trie)
		set_fail_state("Error creating Trie. Update your AMXX installation!");
	

	formatex(g_szFile[get_datadir(g_szFile, charsmax(g_szFile))], charsmax(g_szFile), "/ct-banlist.ini");
	
	new iFile = fopen(g_szFile, "rt")
		, szSteamid[35]
	;
	
	if(iFile)
	{
		new szData[35];
		while(!feof(iFile))
		{
			fgets(iFile, szData, charsmax(szData));
			trim(szData);
			
			if(comment(szData))
				continue;
				
			parse(szData, szSteamid, charsmax(szSteamid));	
			TrieSetCell(g_tBannedSteamids, szSteamid, 1);
		}
		
		fclose(iFile);
		
		log_amx("Ctban list loaded succesfully");
	}
	
	else
		log_amx("^"%s^" not found", g_szFile);
	
}


public client_authorized(id)
{	
	new szSteamid[35], szName[35];
	get_user_authid(id, szSteamid, charsmax(szSteamid));
	get_user_name(id, szName, charsmax(szName));
	
	if(TrieKeyExists(g_tBannedSteamids, szSteamid))
	{
		if(get_pcvar_num(g_pCvars[ConnectMsg]))
			client_print(0, print_chat, "* %L", LANG_PLAYER, "FOUND", szName);
		
		SetCtBan(id);
	}
	
	else
	{
		
			
		ClearCtBan(id);
	}
}


public Cmd_CtBan(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
		
	new szArg[35];
	read_argv(1, szArg, charsmax(szArg));
	
	new iPlayer = cmd_target(id, szArg, CMDTARGET_OBEY_IMMUNITY);
	
	if(iPlayer)
	{
		new szPlayerSteamid[35];
		get_user_authid(iPlayer, szPlayerSteamid, charsmax(szPlayerSteamid));
		
		if(TrieKeyExists(g_tBannedSteamids, szPlayerSteamid))
		{
			console_print(id, "* %L", id, "ALREADY", szPlayerSteamid);
			
			return PLUGIN_HANDLED;
		}
		
		new szReason[64];
		read_argv(2, szReason, charsmax(szReason));
		
		AddCtBan(id, iPlayer, szReason);
	}
	
	return PLUGIN_HANDLED;
}


public Cmd_CtUnBan(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg[35];
	read_argv(1, szArg, charsmax(szArg));
	
	new iPlayer = cmd_target(id, szArg, CMDTARGET_OBEY_IMMUNITY);
	
	if(iPlayer)
	{
		new szSteamid[34];
		get_user_authid(iPlayer, szSteamid, charsmax(szSteamid));
		
		if(!TrieKeyExists(g_tBannedSteamids, szSteamid))
		{
			console_print(id, "* %L", id, "NOT", szSteamid);

			return PLUGIN_HANDLED;
		}
		
		RemoveCtBan(id, iPlayer);
	}
	
	return PLUGIN_HANDLED;
}


public Cmd_JoinTeam(id)
{	
	if(CheckCtBan(id))
	{
		new szArg[4];
		read_argv(1, szArg, charsmax(szArg));
		
		new iTeam = str_to_num(szArg) - 1;
		if(iTeam == TEAM_CT || iTeam == TEAM_RANDOM)
		{
			engclient_cmd(id, "chooseteam");
			
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}


public CmdEnterReason(id)
{
	new iPlayer = g_iSelectedPlayer[id];
	
	if(!iPlayer)
		return PLUGIN_HANDLED;
		
	new szReason[64];
	read_argv(1, szReason, charsmax(szReason));
	
	if(!szReason[0])
	{
		client_print(id, print_chat, "* %L", id, "ENTER_REASON");
		
		set_user_messagemode(id);
	}
		
	else
	{
		AddCtBan(id, iPlayer, szReason);
		g_iSelectedPlayer[id] = 0;
	}
	
	return PLUGIN_HANDLED;
}

public Menu_TeamSelect(id, key)
{
	if(CheckCtBan(id) && key == TEAM_CT || key == TEAM_RANDOM)
	{
		engclient_cmd(id, "chooseteam");
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}


public Menu_Main(id, iLevel)
{	
	if(!(get_user_flags(id) & iLevel))
		return PLUGIN_HANDLED;
		
	new iPlayers[32], iNum, iPlayer;
	get_players(iPlayers, iNum, "ch");
	
	if(!iNum)
		console_print(id, "%L", id, "NO_PLAYERS");
		
	else
	{
		new szData[64], iMenu;
		formatex(szData, charsmax(szData), "\y%L", id, "MAINMENU_TITLE");
		iMenu = menu_create(szData, "HandleMainMenu");
		
		for(new szSteamid[32], i = 0; i < iNum; i++)
		{
			iPlayer = iPlayers[i];
			
			if(iPlayer == id)
				continue;
				
			get_user_authid(iPlayer, szSteamid, charsmax(szSteamid));
			get_user_name(iPlayer, szData, charsmax(szData));
					
			format(szData, charsmax(szData), "%s (%L)", szData, id, TrieKeyExists(g_tBannedSteamids, szSteamid) ? "BANNED" : "NOT_BANNED");
			
			menu_additem(iMenu, szData, szSteamid);
		}
		
		menu_display(id, iMenu);
	}	
	
	return PLUGIN_HANDLED;
}


public HandleMainMenu(id, iMenu, iItem)
{
	if(iItem != MENU_EXIT)
	{
		new iAccess, szSteamid[32], iCallback;
		menu_item_getinfo(iMenu, iItem, iAccess, szSteamid, charsmax(szSteamid), _, _, iCallback);
		
		new iPlayer = find_player("ch", szSteamid);
		
		if(iPlayer)
		{
			if(!TrieKeyExists(g_tBannedSteamids, szSteamid))
			{
				g_iSelectedPlayer[id] = iPlayer;
				
				set_user_messagemode(id);
			}
			
			else
				RemoveCtBan(id, iPlayer);
		}
		
		else
			client_print(id, print_chat, "* %L", id, "CL_NOT_FOUND");
	}
	
	menu_destroy(iMenu);
	
	return PLUGIN_HANDLED;
}
	
	
AddCtBan(id, iPlayer, const szReason[])
{
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(get_pcvar_num(g_pCvars[KillBanned]))
			user_kill(iPlayer);
		
		cs_set_user_team(iPlayer, CS_TEAM_T);
	}
	
	new szBuffer[128], szSteamid[34], szPlayerName[32];
	get_user_authid(iPlayer, szSteamid, charsmax(szSteamid));
	get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName));
	
	formatex(szBuffer, charsmax(szBuffer), "%s %s ^"%s^"", szSteamid, szPlayerName, szReason);
	write_file(g_szFile, szBuffer);
	
	TrieSetCell(g_tBannedSteamids, szSteamid, 1);
	SetCtBan(iPlayer);
	
	new szAdminName[32], szAdminSteamid[34];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminSteamid, charsmax(szAdminSteamid));
	
	client_print(id, print_chat, "* %L", id, "ADDED", szSteamid);
	show_activity_key("ACTIVITY_ADDED_CASE1", "ACTIVITY_ADDED_CASE2", szAdminName, szPlayerName);
	log_amx("%L", LANG_SERVER, "LOG_ADDED", szAdminName, szAdminSteamid, szPlayerName, szSteamid);
}


RemoveCtBan(id, iPlayer)
{	
	new szData[128], Line;
	new iFile = fopen(g_szFile, "rt");

	if(!iFile)
		return;
	
	new szSteamid[34], szTempSteamid[34];
	get_user_authid(iPlayer, szSteamid, charsmax(szSteamid));
	
	while(!feof(iFile))
	{
		fgets(iFile, szData, charsmax(szData));
		trim(szData);
		
		Line++;
		
		if(comment(szData))
			continue;
			
		parse(szData, szTempSteamid, charsmax(szTempSteamid));
		
		if(equali(szSteamid, szTempSteamid))
		{	
			format(szData, charsmax(szData), "; %s", szData);
			write_file(g_szFile, szData, Line - 1);
			
			break;
		}
	}
	
	
	TrieDeleteKey(g_tBannedSteamids, szSteamid);
	ClearCtBan(id);
	
	new szAdminName[32], szPlayerName[32], szAdminSteamid[32];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName));
	get_user_authid(id, szAdminSteamid, charsmax(szAdminSteamid));
	
	console_print(id, "* %L", id, "REMOVED", szSteamid);
	show_activity_key("ACTIVITY_REMOVED_CASE1", "ACTIVITY_REMOVED_CASE2", szAdminName, szPlayerName);
	log_amx("%L", LANG_SERVER, "LOG_REMOVED", szAdminName, szAdminSteamid, szPlayerName, szSteamid);
}

	
bool: comment(const szData[])
	return (!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/')) ? true : false;

	
		