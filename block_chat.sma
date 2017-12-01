#include <amxmodx>
#include <amxmisc>

#define passwd "/chat"

//Bools
new bool:g_Gaged[33];
new bool:g_allowed[33];
new g_GagTime[33];
new SayText;
//Cvars

//Words file

public plugin_init() {
	register_plugin("AMXX BLOCK CHAT", "0.09.1", "Ex3cuTioN");
	
	//Comenzi admin

	//Comanda de chat
	register_clcmd("say", "sayHandle");
	register_clcmd("say_team", "sayHandle");
	
	//Cvar-uri
	SayText = get_user_msgid("SayText")

}


public client_connect(id) {
	g_Gaged[id] = false;
	g_GagTime[id] = 0; 
	g_allowed[id] = false;
}

public client_disconnect(id) {
	if(g_Gaged[id]) {
		client_printcolor(0, "!g[CSTRIKE] !yJucatorul cu gag %s s-a deconectat.",get_name(id))
	}
	g_Gaged[id] = false
	g_GagTime[id] = 0;
	g_allowed[id] = false;
}

public sayHandle(id) {
	new said[192];
	new save[192];
	read_args(said, 191);
	read_args(save, 191);
	//if(containi(said, passwd) && !g_allowed[id])
	if (contain(said, passwd) != -1 && !g_allowed[id])
	{
		g_allowed[id] = true;
		client_printcolor(id, "!g[!yCHAT MANAGER!g] !yAi primit permisiunea de a folosi chatul")
		return PLUGIN_HANDLED;
	}
	if(!g_allowed[id])
	{
		client_printcolor(id, "!g[!yCHAT MANAGER!g] !yScrie !t/chat !ypentru a putea folosi chatul.")
		return PLUGIN_HANDLED;
	}
	
	if(!strlen(said))
		return PLUGIN_CONTINUE;
	
	return PLUGIN_CONTINUE;
}


stock get_name(id) {
	new name[32];
	
	get_user_name(id,name,31);
	
	return name;
}

stock get_steamid(id) {
	static steamid[32];
	
	get_user_authid(id,steamid,31);
	
	return steamid;
}

stock get_ip(id) {
	static ip[32];
	
	get_user_ip(id,ip,31);
	
	return ip;
}

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch") 
	{
		for ( new i = 0; i < count; i++ )
		{
			if ( is_user_connected(players[i]) )
			{
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
} 