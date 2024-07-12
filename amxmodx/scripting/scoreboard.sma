#include < amxmodx >

new g_pScoreBoardTitle;

public plugin_init( ) {
	register_plugin( "ScoreBoard Title", "1.0", "xPaw" );
	
	register_message( get_user_msgid( "ServerName" ), "MessageServerName" );
	
	g_pScoreBoardTitle = register_cvar( "scoreboard_title", "" );
}

public MessageServerName( ) {
	new szTitle[ 32 ];
	get_pcvar_string( g_pScoreBoardTitle, szTitle, 31 );
	
	if( szTitle[ 0 ] )
		set_msg_arg_string( 1, szTitle );
}