#include <amxmodx>
#include <amxmisc>

public plugin_init() {
    register_plugin("Showip", "No *mErCy*", "1.0")
    register_concmd("amx_showip", "cmd_showip", ADMIN_KICK, "><LisTa IP jucatori><")
}

public cmd_showip(id, level ,cid)
{
    if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED;
	}
    console_print(id,"|-+-+-+-+- LisTa IP Jucatori -+-+-+-+-|")
    console_print(id,"|=============================|")
    new players[32], num
    get_players(players, num)
    new i

    for(i=0;i<num;i++)
    {
    new name[32] ;
    new ipeki[32];
    get_user_name(players[i],name, 31)
    get_user_ip(players[i],ipeki, 31, 0)
    console_print(id,"   -   %s - %s", name,ipeki)
    }
    console_print(id, "|=============================|")
    return PLUGIN_HANDLED
}

