#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <nvault>



#define PLUGIN "AMXX Poker"
#define VERSION "0.1"
#define AUTHOR "Florin Ilie aka (|Eclipse|)"

enum _group {_name[30], _pass[30], _players, _game}
enum _:Games{ None, Poker}
enum _playerdata{_hand[56],_bet}
enum _gamedata{_deck[56],_totalbet,_players[32],_turn}

new g_Groups[32][_group]
new g_PlayerData[32][_playerdata]
new g_Gamedata[32][_gamedata]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
    register_logevent("round_end", 2, "1=Round_End")
	
    register_clcmd("say /game", "cmd_game")
    
	return PLUGIN_CONTINUE
}

public round_end()
{
    
}

public cmd_game()
{
    //join
    //create
    //exit
}

public cmd_create ()
{

}
