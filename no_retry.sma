#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN_NAME	"NoRetry"
#define PLUGIN_AUTHOR	Florin Ilie aka (|Eclipse|)
#define PLUGIN_VERSION	"1.0"

new bool:NoEntry = false
new bool:RoundEnd = false

public plugin_init ()
{
	register_plugin(PLUGIN_NAME,PLUGIN_VERSION,PLUGIN_AUTHOR)
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
	register_event( "DeathMsg","player_killed","a" )
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	register_logevent("round_end", 2, "1=Round_End")
}

public round_start ()
{
	NoEntry = false
	RoundEnd = false
}

public round_end (){
	RoundEnd = true
	NoEntry = false
}

public player_killed ()
{
	if(RoundEnd==false){
		NoEntry = true
	}
	return PLUGIN_HANDLED
}

public player_spawn (id)
{
	if(NoEntry == true && is_user_connected(id) && cs_get_user_team(id) != CS_TEAM_SPECTATOR)
	{
		user_silentkill(id)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}