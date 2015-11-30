#include <amxmodx>
#include <engine>

#define CVAR_MAXWARNINGS		"amx_nameflood_maxwarnings"
#define CVAR_NAMESPAMBANMINUTES	"amx_nameflood_banminutes"
#define CVAR_USEAMXBANS			"amx_nameflood_useamxbans"
#define REASON					"Name change flooding"

new Float:g_Flooding[33] = {0.0, ...}
new g_Flood[33] = {0, ...}
new g_warnings[32] = {0, ...}
new Float:g_nextNameChange[32]

public plugin_init() {
	register_plugin("Anti Flood + NameSpam protection", "0.1", "AMXX Dev Team (JGHG)")
	register_dictionary("antiflood.txt")
	register_dictionary("admincmd.txt")
	register_dictionary("common.txt")
	register_clcmd("say","chkFlood")
	register_clcmd("say_team","chkFlood")
	register_cvar("amx_flood_time","0.75")
	register_cvar("amx_nameflood_time", "10.0")
	register_cvar(CVAR_MAXWARNINGS, "0")
	register_cvar(CVAR_NAMESPAMBANMINUTES, "0")
	register_cvar(CVAR_USEAMXBANS, "0")
	//register_cvar(CVAR_WARNMESSAGE, "Warning: You are name spamming!")
	register_message(get_user_msgid("SayText"), "message_SayText")
}


public plugin_modules() {
	require_module("engine")
}

/*
L 11/12/2004 - 12:10:27: [msglogging.amxx] MessageBegin SayText(76) Arguments=4 Destination=Broadcast(0) Origin={0.000000 0.000000 0.000000} Entity=NULL Classname=NULL Netname=NULL
L 11/12/2004 - 12:10:27: [msglogging.amxx] Arg 1 (Byte): 5
L 11/12/2004 - 12:10:27: [msglogging.amxx] Arg 2 (String): #Cstrike_Name_Change
L 11/12/2004 - 12:10:27: [msglogging.amxx] Arg 3 (String): Johnny got his gun
L 11/12/2004 - 12:10:27: [msglogging.amxx] Arg 4 (String): YYY
L 11/12/2004 - 12:10:27: [msglogging.amxx] MessageEnd SayText(76)
*/

public message_SayText() {
	if (get_msg_args() != 4)
		return PLUGIN_CONTINUE

	new buffer[21]
	get_msg_arg_string(2, buffer, 20)
	if (!equal(buffer, "#Cstrike_Name_Change"))
		return PLUGIN_CONTINUE

	new id = get_msg_arg_int(1), oldName[32], newName[32]
	get_msg_arg_string(3, oldName, 31)
	get_msg_arg_string(4, newName, 31)
	if (!equal(oldName, newName) && get_gametime() < g_nextNameChange[id - 1]) {
		g_nextNameChange[id - 1] = get_gametime() + get_cvar_float("amx_nameflood_time")
		console_print(id, "** %L **", id, "STOP_FLOOD" )
		//console_print(id, "Hey no name flooding! Wait %f seconds before you try to change your naNext name change for you is in %f seconds%f, now is %f...", g_nextNameChange[id - 1], get_gametime())
		//console_print(id, "You are changing name before you can do that again, blocking!")
		set_user_info(id, "name", oldName)
		
		new maxWarnings = get_cvar_num(CVAR_MAXWARNINGS)
		if (maxWarnings > 0 && ++g_warnings[id - 1] >= maxWarnings) {
			if (get_cvar_num(CVAR_USEAMXBANS) == 1) {
				// AMXBans, managing bans for Half-Life modifications
				// Implemented by request
				// http://www.xs4all.nl/~yomama/amxbans/
				new authid[32]
				get_user_authid(id, authid, 31)

				server_cmd("amx_ban ^"%d^" ^"%s^" ^"%s^"", get_cvar_num(CVAR_NAMESPAMBANMINUTES), authid, REASON)
			}
			else {
				new userid = get_user_userid(id)
				new minutesString[10]
				get_cvar_string(CVAR_NAMESPAMBANMINUTES, minutesString, 9)
				new temp[64], banned[16], minutes = get_cvar_num(CVAR_NAMESPAMBANMINUTES)
	
				if (minutes)
					format(temp, 63, "%L", id, "FOR_MIN", minutesString)
				else
					format(temp, 63, "%L", id, "PERM")
				
				format(banned, 15, "%L", id, "BANNED")
	
				new authid[32]
				get_user_authid(id, authid, 31)
	
				new name[32]
				get_user_name(id, name, 31)
				log_amx("%s (%s), %s %s because of name spamming.", name, authid, banned, temp)
	
				server_cmd("kick #%d ^"%s (%s %s)^";wait;banid ^"%d^" ^"%s^";wait;writeid", userid, REASON, banned, temp, minutes, authid)
			}
		}
		else {
		}

		return PLUGIN_HANDLED
	}

	g_nextNameChange[id - 1] = get_gametime() + get_cvar_float("amx_nameflood_time")
	//console_print(id, "Next name change for you is %f, now is %f...", g_nextNameChange[id - 1], get_gametime())

	return PLUGIN_CONTINUE
}

public client_disconnect(id) {
	// Reset warnings
	g_warnings[id - 1] = 0

	return PLUGIN_CONTINUE
}

public chkFlood(id) {
  new Float:maxChat = get_cvar_float("amx_flood_time")

  if ( maxChat ) {
    new Float:nexTime = get_gametime()

    if ( g_Flooding[id] > nexTime ) {
	  if (g_Flood[id] >= 3) {
        client_print( id , print_notify , "** %L **", id, "STOP_FLOOD" )
        g_Flooding[ id ] = nexTime + maxChat + 3.0
        return PLUGIN_HANDLED
      }
	  g_Flood[id]++
    }
    else {
	  if (g_Flood[id])
	    g_Flood[id]--
    }

    g_Flooding[id] = nexTime + maxChat
  }

  return PLUGIN_CONTINUE
}

