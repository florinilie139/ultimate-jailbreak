#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

const m_toggle_state = 41;

new bool:g_bFreeRound;
new g_iMsgSayText;

new freestyle[][] =
{ 
	"free",
	"fr33",
	"FREE",
	"FR33"
}


public plugin_init( ) {
	new const VERSION[ ] = "1.0";
	
	register_plugin( "Deathrun: Free Round", VERSION, "xPaw & Mister X" );
	
	new p = register_cvar( "deathrun_freeround", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_pcvar_string( p, VERSION );
	
	
	register_clcmd( "say ",     "EventSay" );
	register_clcmd( "say_team", "EventSay" );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
	
	RegisterHam( Ham_Use, "func_rot_button", "FwdHamUse_Button" );
	RegisterHam( Ham_Use, "func_button",     "FwdHamUse_Button" );
	RegisterHam( Ham_Use, "button_target",   "FwdHamUse_Button" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "1=1", "2!29" );
	register_event( "HLTV",      "EventNewRound",  "a",  "1=0", "2=0" );
	register_event( "TextMsg",   "EventRestart",   "a",  "2&#Game_C", "2&#Game_w" );
}

public EventNewRound( ) {
	if( g_bFreeRound ) {
		g_bFreeRound = false;

		return;
	}
}

public EventRestart( ) {
	g_bFreeRound = false;
}

public EventCurWeapon( id )
	if( g_bFreeRound )
		engclient_cmd( id, "weapon_knife" );

public EventSay(id)
{
	new talk[64];
	read_args(talk, 63) ;
		
	for(new a = 0; a < sizeof(freestyle); a++)
	{
		if(containi(talk, freestyle[a]) != -1)
		{
			CmdFreeRound(id)
			break;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public CmdFreeRound( id ) {
	if( cs_get_user_team( id ) != CS_TEAM_T ) {
		GreenPrint( id, "This command is only for terrorists!" );
		
		return PLUGIN_CONTINUE;
	}
	if( g_bFreeRound ) {
		GreenPrint( id, "It is free round already!" );
		
		return PLUGIN_CONTINUE;
	}
	if( IsDead() == true){
		GreenPrint( id, "Someone has died, can't make free round" );
		
		return PLUGIN_CONTINUE;
	}
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	
	set_hudmessage( 222, 70, 0, -1.0, 0.3, 1, 3.0, 3.0, 2.0, 1.0, -1 );
	show_hudmessage( 0, "Free round has been started by %s^n", szName );
	
	g_bFreeRound = true;
	
	return PLUGIN_CONTINUE;
}

public FwdHamUse_Button( iEntity, id, iActivator, iUseType, Float:flValue ) {
	if( g_bFreeRound && iUseType == 2 && flValue == 1.0 && is_user_alive( id )
	&&  get_user_team( id ) == 1 && get_pdata_int( iEntity, m_toggle_state, 4 ) == 1 ) {
		/* Oh hi this code actually happen! :D */
		
		set_hudmessage( 0, 100, 255, -1.0, 0.25, 0, 2.0, 2.0, 0.2, 0.2, 3 );
		show_hudmessage( id, "It is free round!^nYou can't use buttons!" );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}
bool:IsDead ()
{
	new iPlayers[32], iNum, i;
	get_players(iPlayers, iNum);
	for(i = 0; i <= iNum; i++)
	{
		if(is_user_connected(iPlayers[i]) && !is_user_alive(iPlayers[i]) && cs_get_user_team(iPlayers[i]) == CS_TEAM_CT) 
			return true
	}
	return false
}
GreenPrint( id, const message[ ], any:... ) {
	static szMessage[ 192 ], iLen;
	if( !iLen )
		iLen = formatex( szMessage, 191, "^4[Deathrun FreeRound]^1 " );
	
	vformat( szMessage[ iLen ], 191 - iLen, message, 3 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
	
	return 1;
}