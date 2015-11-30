/*
Copyright 2011 - 2012, m0skVi4a ;]
Plugin created in Rousse, Bulgaria


Plugin thread 1:
https://forums.alliedmods.net/showthread.php?t=171460

Plugin thread 2:
http://amxmodxbg.org/forum/viewtopic.php?t=37116

Original posted by m0skVi4a ;]



Description:

This is Register System. You can put a password to your name and if someone connect to the server with the same name he will be kicked if he does not login.


Commands:

say /reg
say_team /reg
Open the register system menu


CVARS:

"rs_on"			 - 	Is the plugin on(1) or off(0).   Default: 1
"rs_save_type"		 -	Where to seve the information: to file(0) or to MySQL(1).   Default: 0
"rs_host"    		 -	The host for the database.   Default: 127.0.0.1
"rs_user"	 	 	 -	The username for the database login.   Default: root
"rs_pass"		 	 -	The password for the database login.   Default:
"rs_db" 		 	 - 	The database name.   Default: registersystem
"rs_password_prefix"	 -	The prefix of the setinfo for the Auto Login function.   Default: _rspass
"rs_register_time"  	 	 - 	How much time has the client to register. If is set to 0 registration is not mandatory.   Default: 0
"rs_login_time" 		 - 	How much time has the client to login if is registered.   Default: 60.0
"rs_messages"		 - 	What messages will be displayed when the client connect - only hud messages(1), only chat messages(2) or hud and chat messages(3).   Default: 3
"rs_password_len"	 	 -	What is minimum length of the password.   Default: 6
"rs_attempts"  		 - 	How much attempts has the client to login if he type wrong password.   Default: 3
"rs_chngpass_times"	 -	How much times can the client change his password per map.   Default: 3
"rs_register_log"	 	 -	Is it allowed the plugin to log in file when the client is registered.   Default: 1
"rs_chngpass_log"	 	 -	Is it allowed the plugin to log in file when the client has change his password.   Default: 1
"rs_autologin_log"	 	 - 	Is it allowed the plugin to log in file when the client has change his Auto Login function.   Default: 1
"rs_name_change"	 	 -	Which of the clients can change their names - all clients(0), all clients without Logged cients(1) or no one can(2).   Default: 1
"rs_blind"			 -	Whether clients who have not Logged or who must Register be blinded.   Default: 1
"rs_chat"		 	 -	Whether clients who have not Logged or who must Register chat's be blocked.   Default: 1
"rs_logout"		 -	What to do when client Logout - kick him from the server(0) or wait to Login during the Login time(1).   Default: 0


All CVARS are without quotes


Credits:

m0skVi4a ;]    	-	for the idea and make the plugin
ConnorMcLeod 	- 	for his help to block the name change for logged clients
Sylwester		-	for the idea for the encrypt
dark_style	-	for ideas in the plugin


Changelog:

November 6, 2011   -  V1.0 BETA:
	-  First Release

November 20, 2011   -  V1.1 FINAL
	-  Fixed some bugs
	-  Added hange Password function
	-  Added Info/Help
	-  Added cvars to show when the client is registered and change his password
	-  Password are now encrypted for more safety

November 23, 2011   -  V1.1 FINAL FIX 1
	-  Fixed bug if the client type more than CVAR setted attempts passwords

November 28, 2011   -  V1.1 FINAL FIX 2
	-  Fixed bug if that the menu does not pop up when user connect
	
December 26, 2011   -  V2.0
	-  Fixed bug if player change his name and the system does not check the new name
	-  Added block chooseteam if the client is registered but not logged
	-  Added MySQL support
	-  Added .cfg file to manually set the settings of the system
	-  Added CVAR for to set which clients can change their names
	-  Added auto login on changevel or client retry
	
December 27, 2011   -  V2.0 FIX 1
	-  Fixed bug with the kick function
	
January 3, 2012   -  V2.0 FIX 2
	-  Fixed bug with the auto login function that does not work on steam clients

January 24, 2012   -  V3.0
	-  Fixed bug with the MYSQL Connection
	-  Added new style of the Change Password function
	-  Removed some CVARs and added new
	-  Now in the Register System file or into MYSQL table is not saving the date and time for registering or for changing password for the client. They are saving in special log file with name register_system_log.txt
	
February 17, 2012   -  V4.0
	-  Fixed some little bugs
	-  Added new style of the main menu
	-  Removed the possibility of SQL Injection
	-  The whole name change function is rewritten
	-  Added option for the not registered and not logged clients to be blinded
	-  Added option for the not registered and not logged clients chat's to be blocked
	-  Added showing information in the consoles of the clients about why they are kicked

February 19, 2012   -  V4.0 FIX 1
	-  Fixed bug with the join in the Spectator team
	-  Added the Auto Assign option in the main menu
	-  Small rewrite of the Auto Login function
	
March 10, 2012   -  V5.0
	-  Fixed bug with % that replace the space in the name of the client
	-  Fixed the bug with the menu that stands when client choose team
	-  Fixed some little bugs
	-  Added new style of the main menu

	
Visit www.forums.alliedmods.net
Visit www.amxmodxbg.org


Contact me on:
E-MAIL: pvldimitrov@abv.bg
SKYPE: pa7ohin
*/


#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <sqlx>

#define TASK_MESS 2133 
#define TASK_KICK 3312 
#define SALT "8c4f4370c53e0c1e1ae9acd577dddbed" //The SALT for the password encryption. It can be edited!

new g_on, g_save, g_host, g_user, g_pass, g_db, g_setinfo_pr, g_regtime, g_logtime, g_msg, g_pass_length, g_attempts, g_chp_time, g_reg_log, g_chp_log, g_aulog_log, g_name, g_blind, g_chat, g_logout; //cvar pointers
new reg_file[256], configs_dir[64], file[192], params[2], name[32], check_name[32], check_pass[34], check_status[10], query[512], password[34][34], namepass[512], typedpass[32], new_pass[33][33], passsalt[64], hash[34], pass_prefix[32]; //arrays
new bool:is_logged[33], bool:is_registered[33], bool:is_autolog[33], attempts[33], times[33]; //Booleans and other arrays
new menu[512], keys, length; //variables and array for the menus
new Handle:g_SQLTuple, g_error[512]; //SQL array and handle
new g_saytxt, g_screenfade; //other variables
new const prefix[] = "[REGISTER SYSTEM]"; //The prefix in the chat messages. It can be edited!
new const log_file[] = "register_system_log.txt"; //The name of the log file. It can be edited!
new const JOIN_TEAM_MENU_FIRST[] = "#Team_Select"; //The text of the Team Select menu. DO NOT CHANGE!
new const JOIN_TEAM_MENU_FIRST_SPEC[] = "#Team_Select_Spect"; //The text of the Spectator Team Select menu. DO NOT CHANGE!
new const JOIN_TEAM_MENU_INGAME[] = "#IG_Team_Select"; //The text of the Ingame Team Select menu. DO NOT CHANGE!
new const JOIN_TEAM_MENU_INGAME_SPEC[] = "#IG_Team_Select_Spect"; //The text of the Ingame Spectator Team Select menu. DO NOT CHANGE!
new const JOIN_TEAM_VGUI_MENU = 2; //The number of the VGUI menu for Team Select. DO NOT CHANGE!
new const NAME_CHANGE_MSG[] = "#Cstrike_Name_Change"; ////The text of the Name Change Message. DO NOT CHANGE!

/*==============================================================================
	Start of Plugin Init
================================================================================*/
public plugin_init() 
{
	register_plugin("Register System", "5.0", "m0skVi4a ;]")

	g_on = register_cvar("rs_on", "1") //Is the plugin on(1) or off(0)
	g_save = register_cvar("rs_save_type", "0") //Where to seve the information: to file(0) or to MySQL(1).
	g_host = register_cvar("rs_host", "127.0.0.1") //The host for the database.
	g_user = register_cvar("rs_user", "root") //The username for the database login.
	g_pass = register_cvar("rs_pass", "") //The password for the database login.
	g_db = register_cvar("rs_db", "registersystem") //The database name.
	g_setinfo_pr = register_cvar("rs_password_prefix", "_rspass") //The prefix of the setinfo for the auto login.
	g_regtime = register_cvar("rs_register_time", "0") //How much time has the client to register. If is set to 0 registration is not mandatory. 
	g_logtime = register_cvar("rs_login_time", "60.0") //How much time has the client to login if is registered.
	g_msg = register_cvar("rs_messages", "3") //What messages will be displayed when the client connect - only hud messages(1), only chat messages(2) or hud and chat messages(3).
	g_pass_length = register_cvar("rs_password_length", "6") //What is minimum length of the password.
	g_attempts = register_cvar("rs_attempts", "3") //How much attempts has the client to login if he type wrong password.
	g_chp_time = register_cvar("rs_chngpass_times", "3") //How much times can the client change his password per map.
	g_reg_log = register_cvar("rs_register_log", "1") //Is it allowed the plugin to log in file when the client is registered.
	g_chp_log = register_cvar("rs_chngpass_log", "1") //Is it allowed the plugin to log in file when the client has change his password.
	g_aulog_log = register_cvar("rs_autologin_log", "1") //Is it allowed the plugin to log in file when the client has change his Auto Login function.
	g_name = register_cvar("rs_name_change", "1") //Which of the clients can change their names - all clients(0), all clients without Logged cients(2) or no one can(3). 
	g_blind = register_cvar("rs_blind", "1") //Whether clients who have not Logged or who must Register be blinded.
	g_chat = register_cvar("rs_chat", "1") //Whether clients who have not Logged or who must Register chat's be blocked.
	g_logout = register_cvar("rs_logout", "0") //What to do when client Logout - kick him from the server(0) or wait to Login during the Login time(1).

	register_message(get_user_msgid("ShowMenu"), "ShowMenu")
	register_message(get_user_msgid("VGUIMenu"), "VGUIMenu")
	register_menucmd(register_menuid("Main Menu"), 1023, "HandlerMainMenu")
	register_menucmd(register_menuid("Options Menu"), 1023, "HandlerOptionsMenu")
	register_menucmd(register_menuid("Password Menu"), 1023, "HandlerConfirmPasswordMenu")
	register_clcmd("jointeam", "HookJoinCommands")
	register_clcmd("chooseteam", "HookJoinCommands")
	register_clcmd("say", "HookSayCommands")
	register_clcmd("say_team", "HookSayCommands")
	register_clcmd("LOGIN_PASS", "Login")
	register_clcmd("REGISTER_PASS", "Register")
	register_clcmd("CHANGE_PASS_NEW", "ChangePasswordNew")
	register_clcmd("CHANGE_PASS_OLD", "ChangePasswordOld")
	register_clcmd("AUTO_LOGIN_PASS", "AutoLoginPassword")

	register_forward(FM_PlayerPreThink, "PlayerPreThink")
	register_forward(FM_ClientUserInfoChanged, "ClientInfoChanged")

	register_dictionary("register_system.txt")
	g_saytxt = get_user_msgid("SayText")
	g_screenfade = get_user_msgid("ScreenFade")
}
/*==============================================================================
	End of Plugin Init
================================================================================*/

/*==============================================================================
	Start of Executing plugin's config and choose the save mode
================================================================================*/
public plugin_cfg()
{
	if(!get_pcvar_num(g_on))
		return PLUGIN_HANDLED

	get_configsdir(configs_dir, charsmax(configs_dir))
	formatex(file, charsmax(file), "%s/registersystem.cfg", configs_dir)
		
	if(!file_exists(file))
	{
		server_print("%L", LANG_SERVER, "ERROR_CFG", file)
	}
	else
	{
		server_cmd("exec %s", file)
		server_print("%L", LANG_SERVER, "CFG_EXEC", file)
	}

	if(get_pcvar_num(g_save))
	{
		new Host[64], User[32], Pass[32], DB[128];

		get_pcvar_string(g_host, Host, charsmax(Host))
		get_pcvar_string(g_user, User, charsmax(User))
		get_pcvar_string(g_pass, Pass, charsmax(Pass))
		get_pcvar_string(g_db, DB, charsmax(DB))
	
		g_SQLTuple = SQL_MakeDbTuple(Host, User, Pass, DB)
	
		new errorcode, Handle:SqlConnection = SQL_Connect(g_SQLTuple, errorcode, g_error, charsmax(g_error))
	
		if(SqlConnection == Empty_Handle) 
		{
			server_print("%L", LANG_SERVER, "ERROR_MYSQL")
			set_fail_state(g_error)
		}
		else
		{
			server_print("%L", LANG_SERVER, "MYSQL_CONNECT")
		}

		new Handle:Query

		Query = SQL_PrepareQuery(SqlConnection, "CREATE TABLE IF NOT EXISTS registersystem (Name VARCHAR(32), Password VARCHAR(34), Status VARCHAR(10))")

		if(!SQL_Execute(Query)) 
		{
			SQL_QueryError(Query, g_error, charsmax(g_error))
			set_fail_state(g_error)
		}

		SQL_FreeHandle(Query)
		SQL_FreeHandle(SqlConnection)
	}
	else
	{
		get_configsdir(configs_dir, charsmax(configs_dir))
		formatex(reg_file, charsmax(reg_file), "%s/regusers.ini", configs_dir)

		if(!file_exists(reg_file))
		{
			write_file(reg_file,";Register System file^n;Modifying may cause the clients to can not Login!^n^n")
			server_print("%L", LANG_SERVER, "ERROR_FILE", reg_file)
		}
	}
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Executing plugin's config and choose the save mode
================================================================================*/

/*==============================================================================
	Start of Client's connect and disconenct functions
================================================================================*/
public client_connect(id)
{
	is_logged[id] = false
	is_registered[id] = false
	is_autolog[id] = false
	attempts[id] = 0
	times[id] = 0
	remove_task(id+TASK_MESS)
	CheckClient(id)
}

public client_putinserver(id)
{
	ShowMsg(id)
}

public client_disconnect(id)
{
	is_logged[id] = false
	is_registered[id] = false
	is_autolog[id] = false
	attempts[id] = 0
	times[id] = 0
	remove_task(id+TASK_MESS)
	remove_task(id+TASK_KICK)
}
/*==============================================================================
	End of Client's connect and disconenct functions
================================================================================*/

/*==============================================================================
	Start of Show Menu functions
================================================================================*/
public ShowMenu(msgid, dest, id)
{
	if(get_pcvar_num(g_on))
	{
		new menu_text[64]

		get_msg_arg_string(4, menu_text, charsmax(menu_text))	

		if(equal(menu_text, JOIN_TEAM_MENU_FIRST) || equal(menu_text, JOIN_TEAM_MENU_FIRST_SPEC) || equal(menu_text, JOIN_TEAM_MENU_INGAME) || equal(menu_text, JOIN_TEAM_MENU_INGAME_SPEC))
		{
			Menu(id)

			return PLUGIN_HANDLED
		}

		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public VGUIMenu(msgid, dest, id)
{
	if(get_pcvar_num(g_on))
	{
		if(get_msg_arg_int(1) == JOIN_TEAM_VGUI_MENU)
		{
			Menu(id)

			return PLUGIN_HANDLED
		}

		return PLUGIN_CONTINUE
	}

	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Show Menu functions
================================================================================*/

/*==============================================================================
	Start of Check Client functions
================================================================================*/
public CheckClient(id)
{
	if(!get_pcvar_num(g_on) || is_user_bot(id))
		return PLUGIN_HANDLED

	is_registered[id] = false
	is_autolog[id] = false
	is_logged[id] = false
	remove_task(id+TASK_KICK)

	if(get_pcvar_num(g_save))
	{
		get_user_name(id, name, charsmax(name))

		new data[1]
		data[0] = id

		formatex(query, charsmax(query), "SELECT `Password`, `Status` FROM `registersystem` WHERE Name = ^"%s^";", name)

		SQL_ThreadQuery(g_SQLTuple, "QuerySelectData", query, data, 1)
	}
	else
	{
		new file = fopen(reg_file, "r")

		while(!feof(file))
		{
			get_user_name(id, name, charsmax(name))
			fgets(file, namepass, charsmax(namepass))
			parse(namepass, check_name, charsmax(check_name), check_pass, charsmax(check_pass), check_status, charsmax(check_status))

			if(namepass[0] == ';')
				continue

			if(equal(check_name, name))
			{
				is_registered[id] = true
				password[id] = check_pass

				if(is_user_connected(id))
				{
					user_silentkill(id)
					cs_set_user_team(id, CS_TEAM_UNASSIGNED)
					ShowMsg(id)
					Menu(id)
				}

				if(equal(check_status, "LOGGED"))
				{
					is_autolog[id] = true
					CheckAutoLogin(id)
				}

				break
			}
		}
		fclose(file)
	}
	return PLUGIN_CONTINUE
}

public QuerySelectData(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{ 
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", error)
		return
	}
	else
	{
		new id = data[0];
		new col_pass = SQL_FieldNameToNum(Query, "Password")
		new col_status = SQL_FieldNameToNum(Query, "Status")

		while(SQL_MoreResults(Query)) 
		{
			SQL_ReadResult(Query, col_pass, check_pass, charsmax(check_pass))
			SQL_ReadResult(Query, col_status, check_status, charsmax(check_status))
			is_registered[id] = true
			password[id] = check_pass

			if(is_user_connected(id))
			{
				user_silentkill(id)
				cs_set_user_team(id, CS_TEAM_UNASSIGNED)
				ShowMsg(id)
				Menu(id)
			}

			if(equal(check_status, "LOGGED"))
			{
				is_autolog[id] = true
				CheckAutoLogin(id)
			}
			SQL_NextRow(Query)
		}
	}
}

public CheckAutoLogin(id)
{
	new client_password[32];
	get_pcvar_string(g_setinfo_pr, pass_prefix, charsmax(pass_prefix))
	get_user_info(id, pass_prefix, client_password, charsmax(client_password))
	formatex(passsalt, charsmax(passsalt), "%s%s", client_password, SALT)
	md5(passsalt, hash)
	
	if(equal(hash, password[id]))
	{
		is_logged[id] = true
	}
}
/*==============================================================================
	End of Check Client functions
================================================================================*/

/*==============================================================================
	Start of Show Client's informative messages
================================================================================*/
public ShowMsg(id)
{
	if(!get_pcvar_num(g_on))
		return PLUGIN_HANDLED

	set_task(5.0, "Messages", id+TASK_MESS)

	params[0] = id

	if(!is_registered[id])
	{
		if(get_pcvar_float(g_regtime) != 0)
		{
			params[1] = 1
			set_task(get_pcvar_float(g_regtime), "KickPlayer", id+TASK_KICK, params, sizeof params)
			return PLUGIN_HANDLED
		}
	}
	else
	{
		params[1] = 2
		set_task(get_pcvar_float(g_logtime), "KickPlayer", id+TASK_KICK, params, sizeof params)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public Messages(id)
{
	id -= TASK_MESS

	if(get_pcvar_num(g_msg) == 1 || get_pcvar_num(g_msg) == 3)
	{
		if(!is_registered[id])
		{
			if(get_pcvar_float(g_regtime) != 0)
			{
				set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 0.5, 5.0, 2.0, 2.0, -1)
				show_hudmessage(id, "%L", LANG_SERVER, "REGISTER_HUD", get_pcvar_num(g_regtime))
			}
			else
			{
				set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 0.5, 5.0, 2.0, 2.0, -1)
				show_hudmessage(id, "%L", LANG_SERVER, "YOUCANREG_HUD", get_pcvar_num(g_regtime))
			}
		}
		else if(!is_logged[id])
		{
			set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 0.5, 5.0, 2.0, 2.0, -1)
			show_hudmessage(id, "%L", LANG_SERVER, "LOGIN_HUD", get_pcvar_num(g_logtime))
		}
		else if(is_autolog[id])
		{
			set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 0.5, 5.0, 2.0, 2.0, -1)
			show_hudmessage(id, "%L", LANG_SERVER, "AUTO_LOGIN_HUD")
		}
	}

	if(get_pcvar_num(g_msg) == 2 || get_pcvar_num(g_msg) == 3)
	{
		if(!is_registered[id])
		{
			if(get_pcvar_float(g_regtime) != 0)
			{
				client_printcolor(id, "%L", LANG_SERVER, "REGISTER_CHAT", prefix, get_pcvar_num(g_regtime))
			}
			else
			{
				client_printcolor(id, "%L", LANG_SERVER, "YOUCANREG_CHAT", prefix, get_pcvar_num(g_regtime))
			}
		}
		else if(!is_logged[id])
		{
			client_printcolor(id, "%L", LANG_SERVER, "LOGIN_CHAT", prefix, get_pcvar_num(g_logtime))
		}
		else if(is_autolog[id])
		{
			client_printcolor(id, "%L", LANG_SERVER, "AUTO_LOGIN_CHAT", prefix)
		}
	}
}
/*==============================================================================
	End of Show Client's informative messages
================================================================================*/

/*==============================================================================
	Start of Hook Client's jointeam commands
================================================================================*/
public HookJoinCommands(id)
{
	if(get_pcvar_num(g_on))
	{
		if((!is_registered[id] && get_pcvar_float(g_regtime)) || (is_registered[id] && !is_logged[id]))
		{
			Menu(id)
			return PLUGIN_HANDLED
		}

		return PLUGIN_CONTINUE
	}

	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Hook Client's jointeam commands
================================================================================*/

/*==============================================================================
	Start of Hook Client's say commands
================================================================================*/
public HookSayCommands(id)
{
	new g_message[16];
	read_args(g_message, charsmax(g_message))
	remove_quotes(g_message)
	
	if(get_pcvar_num(g_on))
	{
		if(equal(g_message, "/reg"))
		{
			Menu(id)
		}
		else if(get_pcvar_num(g_chat))
		{
			if(!is_registered[id] && get_pcvar_float(g_regtime))
			{
				client_printcolor(id, "%L", LANG_SERVER, "CHAT_REG", prefix)
				return PLUGIN_HANDLED			
			}
			else if(is_registered[id] && !is_logged[id])
			{
				client_printcolor(id, "%L", LANG_SERVER, "CHAT_LOG", prefix)  
				return PLUGIN_HANDLED
			}
		}
	}

	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Hook Client's say commands
================================================================================*/

/*==============================================================================
	Start of the Main Menu function
================================================================================*/
public Menu(id)
{
	if(!get_pcvar_num(g_on) || !is_user_connected(id))
		return PLUGIN_HANDLED

	length = 0

	if(is_registered[id])
	{
		if(is_logged[id])
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "MAIN_MENU_LOG")
			keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_9|MENU_KEY_0
		}
		else
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "MAIN_MENU_REG")
			keys = MENU_KEY_7|MENU_KEY_9
		}
	}
	else
	{		
		if(get_pcvar_float(g_regtime) == 0)
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "MAIN_MENU_NOTREG")
			keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
		}
		else
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "MAIN_MENU_NOTREG_FORCE")
			keys = MENU_KEY_8|MENU_KEY_9
		}
	}
	show_menu(id, keys, menu, -1, "Main Menu")

	return PLUGIN_CONTINUE
}

public HandlerMainMenu(id, key)
{
	switch(key)
	{
		case 0:
		{
			client_cmd(id, "jointeam 1")
		}
		case 1:
		{
			client_cmd(id, "jointeam 2")
		}
		case 4:
		{
			client_cmd(id, "jointeam 5")
		}
		case 5:
		{
			client_cmd(id, "jointeam 6")
		}
		case 6:
		{
			if(!is_logged[id])
			{
				client_cmd(id, "messagemode LOGIN_PASS")
				Menu(id)
			}
			else
			{
				is_logged[id] = false

				if(is_autolog[id])
				{
					AutoLogin(id)
				}
				get_pcvar_string(g_setinfo_pr, pass_prefix, charsmax(pass_prefix))
				client_cmd(id, "setinfo %s ^"^"", pass_prefix)
				client_printcolor(id, "%L", LANG_SERVER, "LOG_OUT", prefix)

				if(get_pcvar_num(g_logout))
				{
					ShowMsg(id)
					Menu(id)
				}
				else
				{
					params[0] = id
					params[1] = 4
					set_task(2.0, "KickPlayer", id+TASK_KICK, params, sizeof params)
				}
			}
		}
		case 7:
		{
			client_cmd(id, "messagemode REGISTER_PASS")
			Menu(id)
		}
		case 8:
		{
			OptionsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}
/*==============================================================================
	End of the Main Menu function
================================================================================*/

/*==============================================================================
	Start of the Options Menu function
================================================================================*/
public OptionsMenu(id)
{
	if(!get_pcvar_num(g_on) || !is_user_connected(id))
		return PLUGIN_HANDLED

	length = 0

	if(is_logged[id])
	{
		if(is_autolog[id])
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "OPTIONS_MENU_LOG_ON")
		}
		else
		{
			length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "OPTIONS_MENU_LOG_OFF")
		}
		keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_0
	}
	else
	{
		length += formatex(menu[length], charsmax(menu) - length, "%L", LANG_SERVER, "OPTIONS_MENU_NOT_LOG")
		keys = MENU_KEY_3|MENU_KEY_0
	}
	
	show_menu(id, keys, menu, -1, "Options Menu")

	return PLUGIN_CONTINUE
}

public HandlerOptionsMenu(id, key)
{
	switch(key)
	{
		case 0:
		{
			if(times[id] >= get_pcvar_num(g_chp_time))
			{
				client_printcolor(id, "%L", LANG_SERVER, "CHANGE_TIMES", prefix, get_pcvar_num(g_chp_time))
				return PLUGIN_HANDLED
			}
			else
			{
				client_cmd(id, "messagemode CHANGE_PASS_NEW")
			}
			OptionsMenu(id)
		}
		case 1:
		{
			if(is_autolog[id])
			{
				AutoLogin(id)
			}
			else
			{
				client_cmd(id, "messagemode AUTO_LOGIN_PASS")
			}
			OptionsMenu(id)
		}
		case 2:
		{
			Info(id)
			OptionsMenu(id)
		}
		case 9:
		{
			Menu(id)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}
/*==============================================================================
	End of the Options Menu function
================================================================================*/

/*==============================================================================
	Start of Client's Auto Login Changer function
================================================================================*/
public AutoLogin(id)
{
	get_user_name(id, name, charsmax(name))

	if(!is_registered[id] || !is_logged[id])
		return PLUGIN_HANDLED

	if(get_pcvar_num(g_save))
	{
		formatex(query, charsmax(query), "UPDATE registersystem SET Status = ^"%s^" WHERE Name = ^"%s^";", is_autolog[id] == true ? "" : "LOGGED", name)
		SQL_ThreadQuery(g_SQLTuple, "QuerySetData", query)
	}
	else
	{
		new line, file = fopen(reg_file, "r");

		while(!feof(file))
		{
			fgets(file, namepass, 255)
			parse(namepass, namepass, charsmax(namepass))
			line++

			if(equal(namepass, name))
			{						
				formatex(namepass, charsmax(namepass), "^"%s^" ^"%s^" ^"%s^"", name, password[id], is_autolog[id] == true ? "" : "LOGGED")
				write_file(reg_file, namepass, line - 1)							

				break
			}
		}
		fclose(file)
	}

	if(is_autolog[id])
	{
		is_autolog[id] = false
		client_printcolor(id, "%L", LANG_SERVER, "AUTO_LOGIN_OFF", prefix)
		get_pcvar_string(g_setinfo_pr, pass_prefix, charsmax(pass_prefix))
		client_cmd(id, "setinfo %s ^"^"", pass_prefix)
		
		if(get_pcvar_num(g_aulog_log))
		{
			log_to_file(log_file, "%L", LANG_SERVER, "LOGFILE_AUTO_OFF", name)
		}
	}
	else
	{
		is_autolog[id] = true
		client_printcolor(id, "%L", LANG_SERVER, "AUTO_LOGIN_ON", prefix)
		if(get_pcvar_num(g_aulog_log))
		{
			log_to_file(log_file, "%L", LANG_SERVER, "LOGFILE_AUTO_ON", name)
		}
	}

	return PLUGIN_CONTINUE
}

public AutoLoginPassword(id)
{
	if(!get_pcvar_num(g_on))
		return PLUGIN_HANDLED

	read_args(typedpass, charsmax(typedpass))
	remove_quotes(typedpass)
	formatex(passsalt, charsmax(passsalt), "%s%s", typedpass, SALT)
	md5(passsalt, hash)
	
	if(!equal(hash, password[id]))
	{
		client_printcolor(id, "%L", LANG_SERVER, "AUTO_LOGIN_PASS_NOTVALID", prefix)
		client_cmd(id, "messagemode AUTO_LOGIN_PASS")
		return PLUGIN_HANDLED
	}
	else
	{
		get_pcvar_string(g_setinfo_pr, pass_prefix, charsmax(pass_prefix))
		client_cmd(id, "setinfo %s %s", pass_prefix, typedpass)
		AutoLogin(id)
		OptionsMenu(id)
	}
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Client's Auto Login Changer function
================================================================================*/

/*==============================================================================
	Start of Info/Help MOTD function
================================================================================*/
public Info(id)
{
	show_motd(id, "rshelpmotd.txt", "Register System Help")
}
/*==============================================================================
	End of Info/Help MOTD function
================================================================================*/

/*==============================================================================
	Start of Login function
================================================================================*/
public Login(id)
{
	if(!get_pcvar_num(g_on))
		return PLUGIN_HANDLED

	if(!is_registered[id])
	{	
		client_printcolor(id, "%L", LANG_SERVER, "LOG_NOTREG", prefix)
		return PLUGIN_HANDLED
	}

	if(is_logged[id])
	{
		client_printcolor(id, "%L", LANG_SERVER, "LOG_LOGGED", prefix);
		return PLUGIN_HANDLED
	}
	
	read_args(typedpass, charsmax(typedpass))
	remove_quotes(typedpass)

	if(equal(typedpass, ""))
		return PLUGIN_HANDLED

	formatex(passsalt, charsmax(passsalt), "%s%s", typedpass, SALT)
	md5(passsalt, hash)

	if(!equal(hash, password[id]))
	{	
		attempts[id]++
		client_printcolor(id, "%L", LANG_SERVER, "LOG_PASS_INVALID", prefix, attempts[id], get_pcvar_num(g_attempts))

		if(attempts[id] >= get_pcvar_num(g_attempts))
		{
			params[0] = id
			params[1] = 3
			set_task(2.0, "KickPlayer", id+TASK_KICK, params, sizeof params)
			return PLUGIN_HANDLED
		}
		else
		{
			client_cmd(id, "messagemode LOGIN_PASS")
		}
		return PLUGIN_HANDLED
	}
	else
	{
		is_logged[id] = true
		attempts[id] = 0
		remove_task(id+TASK_KICK)
		client_printcolor(id, "%L", LANG_SERVER, "LOG_LOGING", prefix)
		Menu(id)
	}
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Login function
================================================================================*/

/*==============================================================================
	Start of Register function
================================================================================*/
public Register(id)
{
	if(!get_pcvar_num(g_on))
		return PLUGIN_HANDLED

	read_args(typedpass, charsmax(typedpass))
	remove_quotes(typedpass)

	new passlength = strlen(typedpass)

	if(equal(typedpass, ""))
		return PLUGIN_HANDLED
	
	if(is_registered[id])
	{
		client_printcolor(id, "%L", LANG_SERVER, "REG_EXISTS", prefix)
		return PLUGIN_HANDLED
	}

	if(passlength < get_pcvar_num(g_pass_length))
	{
		client_printcolor(id, "%L", LANG_SERVER, "REG_LEN", prefix, get_pcvar_num(g_pass_length))
		client_cmd(id, "messagemode REGISTER_PASS")
		return PLUGIN_HANDLED
	}

	new_pass[id] = typedpass
	ConfirmPassword(id)
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Register function
================================================================================*/

/*==============================================================================
	Start of Change Password function
================================================================================*/
public ChangePasswordNew(id)
{
	if(!get_pcvar_num(g_on) || !is_registered[id] || !is_logged[id])
		return PLUGIN_HANDLED

	read_args(typedpass, charsmax(typedpass))
	remove_quotes(typedpass)

	new passlenght = strlen(typedpass)

	if(equal(typedpass, ""))
		return PLUGIN_HANDLED

	if(passlenght < get_pcvar_num(g_pass_length))
	{
		client_printcolor(id, "%L", LANG_SERVER, "REG_LEN", prefix, get_pcvar_num(g_pass_length))
		client_cmd(id, "messagemode CHANGE_PASS_NEW")
		return PLUGIN_HANDLED
	}

	new_pass[id] = typedpass
	client_cmd(id, "messagemode CHANGE_PASS_OLD")
	return PLUGIN_CONTINUE
}

public ChangePasswordOld(id)
{
	if(!get_pcvar_num(g_on) || !is_registered[id] || !is_logged[id])
		return PLUGIN_HANDLED

	read_args(typedpass, charsmax(typedpass))
	remove_quotes(typedpass)
	formatex(passsalt, charsmax(passsalt), "%s%s", typedpass, SALT)
	md5(passsalt, hash)

	if(equal(typedpass, "") || equal(new_pass[id], ""))
		return PLUGIN_HANDLED

	if(!equali(hash, password[id]))
	{
		client_printcolor(id, "%L", LANG_SERVER, "CHANGE_NO", prefix)
		return PLUGIN_HANDLED
	}

	ConfirmPassword(id)
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Change Password function
================================================================================*/

/*==============================================================================
	Start of Confirming Register's or Change Password's password function
================================================================================*/
public ConfirmPassword(id)
{
	if(!get_pcvar_num(g_on) || !is_user_connected(id))
		return PLUGIN_HANDLED

	length = 0
		
	formatex(menu, charsmax(menu) - length, "%L", LANG_SERVER, "MENU_PASS", new_pass[id])
	keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_0

	show_menu(id, keys, menu, -1, "Password Menu")
	return PLUGIN_CONTINUE
}

public HandlerConfirmPasswordMenu(id, key)
{
	switch(key)
	{
		case 0:
		{
			get_user_name(id, name, charsmax(name))
			formatex(passsalt, charsmax(passsalt), "%s%s", new_pass[id],  SALT)
			md5(passsalt, hash)

			if(is_registered[id])
			{
				if(get_pcvar_num(g_save))
				{
					formatex(namepass, charsmax(namepass), "UPDATE `registersystem` SET Password = ^"%s^", Status = ^"%s^" WHERE Name = ^"%s^";", hash, is_autolog[id] == true ? "LOGGED" : "",  name)
					SQL_ThreadQuery(g_SQLTuple, "QuerySetData", namepass)
				}
				else
				{
					new line, file = fopen(reg_file, "r")

					while(!feof(file))
					{
						fgets(file, namepass, 255)
						line++
						parse(namepass, namepass, charsmax(namepass))

						if(equal(namepass, name))
						{						
							formatex(namepass, charsmax(namepass), "^"%s^" ^"%s^" ^"%s^"", name, hash, is_autolog[id] == true ? "LOGGED" : "")
							write_file(reg_file, namepass, line - 1)							

							break
						}
					}
					fclose(file)
				}
				get_pcvar_string(g_setinfo_pr, pass_prefix, charsmax(pass_prefix))
				client_cmd(id, "setinfo %s %s",pass_prefix, new_pass[id])
				client_printcolor(id, "%L", LANG_SERVER, "CHANGE_NEW", prefix, new_pass[id])
				password[id] = hash
				times[id]++

				if(get_pcvar_num(g_chp_log))
				{
					log_to_file(log_file, "%L", LANG_SERVER, "LOGFILE_CHNG_PASS", name)
				}
			}
			else
			{
				if(get_pcvar_num(g_save))
				{
					formatex(namepass, charsmax(namepass), "INSERT INTO `registersystem` (`Name`, `Password`, `Status`) VALUES (^"%s^", ^"%s^", ^"^");", name, hash)
					SQL_ThreadQuery(g_SQLTuple, "QuerySetData", namepass)
				}
				else
				{
					new file = fopen(reg_file, "a")
					format(namepass, charsmax(namepass), "^n^"%s^" ^"%s^" ^"^"", name, hash)
					fprintf(file, namepass)
					fclose(file)
				}
				remove_task(id+TASK_KICK)
				params[1] = 2
				set_task(get_pcvar_float(g_logtime), "KickPlayer", id+TASK_KICK, params, sizeof params)
				client_printcolor(id, "%L", LANG_SERVER, "REG_REGIS", prefix, new_pass[id], get_pcvar_num(g_logtime))
				is_registered[id] = true
				password[id] = hash
				new_pass[id] = ""
				
				if(get_pcvar_num(g_reg_log))
				{
					log_to_file(log_file, "%L", LANG_SERVER, "LOGFILE_REG", name)
				}
			}			
			Menu(id)
		}
		case 1:
		{
			if(is_registered[id])
			{
				client_cmd(id, "messagemode CHANGE_PASS_NEW")
			}
			else
			{
				client_cmd(id, "messagemode REGISTER_PASS")
			}
		}
		case 9:
		{
			Menu(id)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}

public QuerySetData(FailState, Handle:Query, error[],errcode, data[], datasize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", error)
		return
	}
}
/*==============================================================================
	End of Confirming Register's or Change Password's password function
================================================================================*/

/*==============================================================================
	Start of Player PreThink function for the blind function
================================================================================*/
public PlayerPreThink(id)
{
	if(!get_pcvar_num(g_on) || !get_pcvar_num(g_blind) || !is_user_connected(id))
		return PLUGIN_HANDLED

	if((!is_registered[id] && get_pcvar_float(g_regtime)) || (is_registered[id] && !is_logged[id]))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_screenfade, {0,0,0}, id)
		write_short(1<<12)
		write_short(1<<12)
		write_short(0x0000)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		message_end()
	}

	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Player PreThink function for the blind function
================================================================================*/

/*==============================================================================
	Start of Client Info Change function for hooking name change of clients
================================================================================*/
public ClientInfoChanged(id) 
{
	if(!get_pcvar_num(g_on) || !is_user_connected(id))
		return FMRES_IGNORED

	new g_oldname[32], g_newname[32];

	pev(id, pev_netname, g_oldname, charsmax(g_oldname))

	if(g_oldname[0])
	{
		get_user_info(id, "name", g_newname, charsmax(g_newname))
		replace_all(g_newname, charsmax(g_newname), "%", " ")

		if(!equal(g_oldname, g_newname))
		{
			
			switch(get_pcvar_num(g_name))
			{
				case 0:
				{
					set_pev(id, pev_netname, g_newname)
					create_name_change_msg(id, g_oldname, g_newname)
					set_task(1.0, "CheckClient", id)
					return FMRES_HANDLED
				}
				case 1:
				{
					if(is_logged[id])
					{
						set_user_info(id, "name", g_oldname)
						client_printcolor(id, "%L", LANG_SERVER, "NAME_CHANGE_LOG", prefix)
						return FMRES_HANDLED
					}
					else
					{
						set_pev(id, pev_netname, g_newname)
						create_name_change_msg(id, g_oldname, g_newname)
						set_task(1.0, "CheckClient", id)
						return FMRES_HANDLED
					}
				}
				case 2:
				{
					set_user_info(id, "name", g_oldname)
					client_printcolor(id, "%L", LANG_SERVER, "NAME_CHANGE_ALL", prefix)
					return FMRES_HANDLED
				}
			}
		}
	}
	return FMRES_IGNORED
}
/*==============================================================================
	End of Client Info Change function for hooking name change of clients
================================================================================*/

/*==============================================================================
	Start of Kick Player function
================================================================================*/
public KickPlayer(parameter[])
{
	new id = parameter[0]
	new reason = parameter[1]

	if(is_user_connected(id))
	{
		new userid = get_user_userid(id)
		
		switch(reason)
		{
			case 1:
			{
				if(is_registered[id])
					return PLUGIN_HANDLED

				server_cmd("kick #%i ^"%L^"", userid, LANG_PLAYER, "KICK_REG")
				console_print(id, "%L", LANG_SERVER, "KICK_INFO")
				return PLUGIN_CONTINUE
			}
			case 2:
			{
				if(is_logged[id])
					return PLUGIN_HANDLED

				server_cmd("kick #%i ^"%L^"", userid, LANG_PLAYER, "KICK_LOGIN")
				console_print(id, "%L", LANG_SERVER, "KICK_INFO")
				return PLUGIN_CONTINUE
			}
			case 3:
			{
				server_cmd("kick #%i ^"%L^"", userid, LANG_PLAYER, "KICK_ATMP", get_pcvar_num(g_attempts))
				console_print(id, "%L", LANG_SERVER, "KICK_INFO")
				return PLUGIN_CONTINUE
			}
			case 4:
			{
				server_cmd("kick #%i ^"%L^"", userid, LANG_SERVER, "KICK_LOGOUT")
				console_print(id, "%L", LANG_SERVER, "KICK_INFO")
				return PLUGIN_CONTINUE
			}
		}
	}
	return PLUGIN_CONTINUE
}
/*==============================================================================
	End of Kick Player function
================================================================================*/

/*==============================================================================
	Start of Plugin's stocks
================================================================================*/
stock create_name_change_msg(const id, const g_oldname[], const g_newname[])
{
	message_begin(MSG_BROADCAST, g_saytxt)
	write_byte(id)
	write_string(NAME_CHANGE_MSG)
	write_string(g_oldname)
	write_string(g_newname)
	message_end()
}

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3)
	replace_all(msg,190,"!g","^4")
	replace_all(msg,190,"!n","^1")
	replace_all(msg,190,"!t","^3")
	replace_all(msg,190,"!w","^0")
	if(id) players[0] = id
	else get_players(players , count , "ch")
	{
		for(new i = 0; i < count; i++)
		{
			if(is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_saytxt,_, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end()
			}
		}
	}
}
/*==============================================================================
	End of Plugin's stocks
================================================================================*/