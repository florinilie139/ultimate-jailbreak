#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Black List"
#define VERSION "1.0"
#define AUTHOR "Dias"

new const user_file[] = "black_list.ini"
new Array:BlackList

new cvar_blacklist_handle
new cvar_blacklist_bantype, cvar_blacklist_bantime

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	cvar_blacklist_handle = register_cvar("bl_handle", "1") // 1 = Kick | 2 = Ban
	
	cvar_blacklist_bantype = register_cvar("bl_ban_type", "2") // 1 = Ban SteamID | 2 = Ban IP
	cvar_blacklist_bantime = register_cvar("bl_ban_time", "30") // Minutes
}

public plugin_precache()
{
	BlackList = ArrayCreate(32, 1)
	read_user_from_file()
}

public read_user_from_file()
{
	static user_file_url[64], config_dir[32]
	
	get_configsdir(config_dir, sizeof(config_dir))
	format(user_file_url, sizeof(user_file_url), "%s/%s", config_dir, user_file)
	
	if(!file_exists(user_file_url))
		return
	
	static file_handle, line_data[64], line_count
	file_handle = fopen(user_file_url, "rt")
	
	while(!feof(file_handle))
	{
		fgets(file_handle, line_data, sizeof(line_data))
		
		replace(line_data, charsmax(line_data), "^n", "")
		
		if(!line_data[0] || line_data[0] == ';') 
			continue
			
		ArrayPushString(BlackList, line_data)
		line_count++
	}
	log_amx("S-au incarcat %i in lista",ArraySize(BlackList))
	fclose(file_handle)
}
public client_putinserver(id)
{
    check_and_handle(id)
}

public client_connect(id)
{
	check_and_handle(id)
}

public client_infochanged(id)
{
	check_and_handle(id)
}

public check_and_handle(id)
{
	static name[64], steamid[64], playerip[64],Data[32]
	
	get_user_name(id, name, sizeof(name))
	get_user_authid(id, steamid, sizeof(steamid))
	get_user_ip(id, playerip, sizeof(playerip))
	
	for(new i = 0; i < ArraySize(BlackList); i++)
	{
		ArrayGetString(BlackList, i, Data, sizeof(Data))
		
		if(equal(name, Data) || equal(steamid, Data) || equali(Data,playerip,strlen(Data)-1))
		{
			if(get_pcvar_num(cvar_blacklist_handle) == 1) // Kick
			{
				server_cmd("amx_kick %s BlackList", name)
				
				client_printcolor(0, "!g[AMX]!y !t%s!y is in Black List. Kick !t%s!y !!!", name, name)
			} else if(get_pcvar_num(cvar_blacklist_handle) == 2) { // Ban
				if(get_pcvar_num(cvar_blacklist_bantype) == 1) // Ban SteamID
				{
					server_cmd("amx_ban %s BlackList %i", steamid, get_pcvar_num(cvar_blacklist_bantime))
				} else if(get_pcvar_num(cvar_blacklist_bantype) == 2) { // BanIP
					server_cmd("amx_banip %s BlackList %i", name, get_pcvar_num(cvar_blacklist_bantime))
				}
				
				client_printcolor(0, "!g[AMX]!y !t%s!y is in Black List. Ban !t%s!y | %i minutes !!!", name, name, get_pcvar_num(cvar_blacklist_bantime))				
			}
		}
	}		
}

stock client_printcolor(const id, const input[], any:...)
{
	new iCount = 1, iPlayers[32]
	static szMsg[191]
	
	vformat(szMsg, charsmax(szMsg), input, 3)
	replace_all(szMsg, 190, "!g", "^4")
	replace_all(szMsg, 190, "!y", "^1")
	replace_all(szMsg, 190, "!t", "^3")
	
	if(id) iPlayers[0] = id
	else get_players(iPlayers, iCount, "ch")
	
	for (new i = 0; i < iCount; i++)
	{
		if(is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
