////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP System
//==========================================================================================================
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>

#define PLUGIN "VIP System"
#define VERSION "1.0"
#define AUTHOR "Aragon*"

#define VIP_LEVEL		ADMIN_LEVEL_H
static const COLOR[] = "^x04"; // Green for display VIP

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP Plugin Init
//==========================================================================================================
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "handle_say");
	RegisterHam(Ham_Spawn, "player", "PlayerSpawm");
	register_message(get_user_msgid("ScoreAttrib"),"vip_scoreboard");
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP Give Items
//==========================================================================================================
public PlayerSpawm(id) {
	if(cs_get_user_team(id) == CS_TEAM_T && get_user_flags(id) & VIP_LEVEL) {
	set_task(1.5,"T_Bonus",id);
	}
	else if(cs_get_user_team(id) == CS_TEAM_CT && get_user_flags(id) & VIP_LEVEL) {
	set_task(1.5,"CT_Bonus",id);
	}
	}
public T_Bonus(id) {
	set_user_health(id, 200);
	}
public CT_Bonus(id) {
	fm_give_item(id, "weapon_hegrenade");
	fm_give_item(id, "item_defuse");
	set_user_health(id, 200);
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP Online/List | VIP ScoreBoard
//==========================================================================================================
public print_adminlist(user) {
	new adminnames[33][32];
	new message[256];
	new id, count, x, len;
	
	for(id = 1 ; id <= get_maxplayers() ; id++)
	if(is_user_connected(id))
	if(get_user_flags(id) & VIP_LEVEL)
	get_user_name(id, adminnames[count++], 31);

	len = format(message, 255, "%s VIP ONLINE: ",COLOR);
	if(count > 0) {
	for(x = 0 ; x < count ; x++) {
	len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"");
	if(len > 96) {
	print_message(user, message);
	len = format(message, 255, "%s ",COLOR);
	}
	}
	print_message(user, message);
	}
	else {
	len += format(message[len], 255-len, "No VIP online.");
	print_message(user, message);
	}
	}
print_message(id, msg[]) {
	message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id);
	write_byte(id);
	write_string(msg);
	message_end();
	}
public handle_say(id) {
	new said[192];
	read_args(said,192);
	if(contain(said, "/vips") != -1)
	set_task(0.1,"print_adminlist",id);
	return PLUGIN_CONTINUE;
	}
public vip_scoreboard(const MsgId, const MsgType, const MsgDest) {
	static id;
	id = get_msg_arg_int(1);
	if(get_user_flags(id) & VIP_LEVEL)
	set_msg_arg_int(2, ARG_BYTE, (1 << 2 ));
	}
