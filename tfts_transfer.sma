#include <amxmodx>
#include <amxmisc>
#include <cstrike>

public admin_chteam(id, level, cid) { 
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new cmd[10];
	new arg[32];
	
	read_argv(0,cmd,9)
	read_argv(1,arg,31)
	new player = cmd_target(id,arg,1)
	if (!player) return PLUGIN_HANDLED
	
	user_kill(player, 1);
	
	new name[32], admin[32]
	
	get_user_name(id, admin, 31)
	get_user_name(player, name, 31)
	
	if(cmd[4]=='t')
	{
		cs_set_user_team(player,1);
		client_print(0, print_chat, "%s la mutat pe %s la TERRORIST",admin, name);
	}
	if(cmd[4]=='c')
	{
		cs_set_user_team(player,2);
		client_print(0, print_chat, "%s la mutat pe %s la COUNTER TERRORIST",admin, name);
	}
	if(cmd[4]=='s')
	{
		cs_set_user_team(player,3);
		 :))
		 
	}
	return PLUGIN_HANDLED
} 

public plugin_init() {
	register_plugin("TFTS Transfer", "1.0", "TFTomSun")
	register_concmd("amx_t", "admin_chteam", ADMIN_LEVEL_A, "<authid, nick or #userid>")
	register_concmd("amx_ct", "admin_chteam", ADMIN_LEVEL_A, "<authid, nick or #userid>")
	register_concmd("amx_spec", "admin_chteam", ADMIN_LEVEL_A, "<authid, nick or #userid>")
	return PLUGIN_CONTINUE
}

