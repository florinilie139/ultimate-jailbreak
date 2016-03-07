///////////////////////////////////////////////////////
//  Credits...                                       //
//                                       	     //
//  tostly, joropito, L//, Starsailor, ConnorMcLeod  //
//                                                   //
///////////////////////////////////////////////////////

#include <amxmodx>

#define PLUGIN    "Health & Armor in Scoreboard"
#define AUTHOR    "Alucard"
#define VERSION    "1.4"

#define MAX_FRAGS 1000
#define SET_FRAGS 1337

enum _:ScoreInfo_Args {
	PlayerID = 1,
	Frags,
	Deaths,
	ClassID,
	TeamID
}

new g_msgScoreInfo, g_msgSayText
new p_MsgOn, p_MsgDelay

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("health_armor_scoreboard", VERSION,FCVAR_SERVER|FCVAR_SPONLY)
	register_cvar("health_armor_scoreboard_author", AUTHOR,FCVAR_SERVER|FCVAR_SPONLY)
	
	p_MsgOn = register_cvar("has_msg_on", "1")
	p_MsgDelay = register_cvar("has_msg_delay", "180.0")
	
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgSayText = get_user_msgid("SayText")
	
	register_message(g_msgScoreInfo, "Message_ScoreInfo")
	
	register_event("Battery", "EventBattery", "b")
	register_event("Health", "EventHealth", "b")
	
	set_task(get_pcvar_float(p_MsgDelay), "MsgToPlayers", .flags="b")
}

public Message_ScoreInfo(iMsgId, iMsgType, iMsgEnt)
{
	new id = get_msg_arg_int(PlayerID)
	
	set_msg_arg_int(Frags, ARG_SHORT, get_user_health(id) )
	set_msg_arg_int(Deaths, ARG_SHORT, get_user_armor(id) )
}

Send_ScoreInfo(id, iFrags, iDeaths, iTeamID)
{
	if(iFrags > MAX_FRAGS)
	{
		iFrags = SET_FRAGS
		iDeaths = SET_FRAGS
	}
	
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id)  
	write_short(is_user_alive(id) ? iFrags : 0) 
	write_short(is_user_alive(id) ? iDeaths : 0) 
	write_short(0) 
	write_short(iTeamID) 
	message_end()
}

public EventBattery(id)
	Send_ScoreInfo(id, get_user_health(id), read_data(1), get_user_team(id) )

public EventHealth(id)
	Send_ScoreInfo(id, read_data(1), get_user_armor(id), get_user_team(id) )

public MsgToPlayers()
{
	if(get_pcvar_num(p_MsgOn) )
		chat_color("^4[H & A] ^1In this server ^3Frags & Deaths ^1are replaced with ^3Health & Armor ^1in the Scoreboard.")
}

stock chat_color(const input[], any:...)
{
    static msg[191]
    vformat(msg, 190, input, 2)
    
    message_begin(MSG_BROADCAST, g_msgSayText)
    write_byte(1)
    write_string(msg)
    message_end()
}