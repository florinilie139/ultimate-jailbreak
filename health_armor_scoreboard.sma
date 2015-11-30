///////////////////////////////////////////////////////
//  Credits...                                       //
//                                       	     	 //
//  tostly, joropito, L//, Starsailor, ConnorMcLeod  //
//                                                   //
///////////////////////////////////////////////////////

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <ujbm>

#define PLUGIN    "Health,Armor&Revolt 4 JB"
#define AUTHOR    "Alucard & Mister X"
#define VERSION    "1.4m"

#define MAX_FRAGS 1000
#define SET_FRAGS 1337

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

enum _:ScoreInfo_Args {
	PlayerID = 1,
	Frags,
	Deaths,
	ClassID,
	TeamID
}

new g_msgScoreInfo, g_msgSayText
new p_MsgOn, p_MsgDelay
new g_PlayerRevolt
new g_PlayerEscaped[33]
new g_PlayerFailed[33]
new g_MaxClients

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("health_armor_scoreboard", VERSION,FCVAR_SERVER|FCVAR_SPONLY)
	register_cvar("health_armor_scoreboard_author", AUTHOR,FCVAR_SERVER|FCVAR_SPONLY)
	
	p_MsgOn = register_cvar("has_msg_on", "0")
	p_MsgDelay = register_cvar("has_msg_delay", "180.0")
	
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgSayText = get_user_msgid("SayText")
	
	register_message(g_msgScoreInfo, "Message_ScoreInfo")
	
	register_event("Battery", "EventBattery", "b")
	register_event("Health", "EventHealth", "b")
	
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
	
	g_MaxClients = 24

	set_task(get_pcvar_float(p_MsgDelay), "MsgToPlayers", .flags="b")
}

public client_putinserver(id)
{
	clear_bit(g_PlayerRevolt, id)
	g_PlayerEscaped[id] = 0
	g_PlayerFailed[id] = 0
}

public Message_ScoreInfo(iMsgId, iMsgType, iMsgEnt)
{
	new id = get_msg_arg_int(PlayerID)
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		set_msg_arg_int(Frags, ARG_SHORT, get_user_health(id) )
		set_msg_arg_int(Deaths, ARG_SHORT, get_user_armor(id) )
	}
	else
	{
		set_msg_arg_int(Frags, ARG_SHORT, g_PlayerEscaped[id] )
		set_msg_arg_int(Deaths, ARG_SHORT, g_PlayerFailed[id] )
	}
}

Send_ScoreInfo(id, iFrags, iDeaths, iTeamID)
{

	if(iFrags > MAX_FRAGS)
	{
		iFrags = SET_FRAGS
		iDeaths = SET_FRAGS
	}
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(id)  
		write_short(iFrags) 
		write_short(iDeaths) 
		write_short(0) 
		write_short(iTeamID) 
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(id)  
		write_short(g_PlayerEscaped[id])
		write_short(g_PlayerFailed[id]) 
		write_short(0) 
		write_short(iTeamID) 
		message_end()
	}
}
public EventBattery(id)
{
	Send_ScoreInfo(id, get_user_health(id), read_data(1), get_user_team(id) )
}
public EventHealth(id)
{
	Send_ScoreInfo(id, read_data(1), get_user_armor(id), get_user_team(id) )
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

public round_end ()
{
	new Players[32] 	
	new playerCount, i 
	get_players(Players, playerCount, "c") 
	for (i=0; i<playerCount; i++) 
	{
		if (is_user_connected(Players[i]) && get_bit(g_PlayerRevolt, Players[i]))
			clear_bit(g_PlayerRevolt, Players[i])
	}
}

public player_killed(victim, attacker, shouldgib)
{
	static CsTeams:vteam, CsTeams:kteam
	if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
		kteam = CS_TEAM_UNASSIGNED
	else
		kteam = cs_get_user_team(attacker)
	vteam = cs_get_user_team(victim)
	new GameMode = get_gamemode()
	if(GameMode == 1 || GameMode == 0)
	{
		switch(vteam)
		{
			case(CS_TEAM_CT):
			{
				if(kteam == CS_TEAM_T && !get_bit(g_PlayerRevolt, attacker))
				{
					set_bit(g_PlayerRevolt, attacker)
					g_PlayerEscaped[attacker] += 1;
				}
			}
			case(CS_TEAM_T):
			{
				if(get_bit(g_PlayerRevolt, victim))
					g_PlayerFailed[victim] += 1;
				clear_bit(g_PlayerRevolt, victim)
			}
		}
			
	}
	return HAM_IGNORED
}