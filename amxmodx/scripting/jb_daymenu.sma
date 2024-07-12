/**
* 
* 		Jailbreak Day Menu
* 		  nikhilgupta345
* 
* 
* 		Features
* 
* 			- Day Menu
* 				+ Guards choose
* 				+ One day at a time
* 
* 			- Many Day Options
* 				+ Free Day (Restricted/Unrestricted)
* 				+ Riot Day
* 				+ Cage Day
* 				+ Zombie Day
* 				+ Dodgeball Day
*					- Grenades Given at 8:00
*					- Auto Reload Nades After Throwing
* 				+ USP Ninja Day
* 				+ Lava Day
* 				+ Nightcrawler Day
* 				+ Space Day
* 				+ Shark Day
* 				+ Knife Day
* 				+ Hide and Seek Day
* 
* 			- Reverse Days For:
* 				+ Zombie Day
* 				+ Nightcrawler Day
* 				+ Shark Day
* 			
* 			- Objectives Displayed
* 
* 			- Prevent Weapon Pickup On Certain Days
*
*
*		Credits
*			Python1320 	- Used his code from WallClimb from nightcrawler's climb
*			Joropito	- Open Cells Code
*			Mercylezz	- Used some code for zombie nightvision
*
*		CVARS
*			- jb_opencells 		<0/1>			// Whether cells should be opened when day is chosen or not. (0=OFF, 1=ON)
*
*		Changelog
*			September 24, 2011 	-v1.0- 		Initial release
*			September 24, 2011 	-v1.1-		Added CVAR jb_opencells
*			September 25, 2011 	-v1.2-		Added ability for only simons to use daymenu. Also added nightvision for the zombies.
*			September 26, 2011	-v1.2.1- 	Fixed bug where daymenu didn't work even if player was simon.
*
*		Plugin Thread: http://forums.alliedmods.net/showthread.php?p=1562229
*
* 
**/ 

// Includes
////////////

#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < colorchat >
#include < fun >
#include < hamsandwich >
#include < fakemeta >
#include < engine >
#include < fakemeta_util >

#if !defined _colorchat_included
    #assert colorchat.inc library required !
#endif

// Defines
///////////

#define CELL_RADIUS	Float:200.0

// Uncomment this line if you want simon
//#define USE_SIMON 1

// Enumerations
////////////////

enum
{
	DAY_NONE = -1,
	DAY_FREE,
	DAY_CAGE,
	DAY_RIOT,
	DAY_ZOMBIE,
	DAY_DODGEBALL,
	DAY_USP_NINJA,
	DAY_LAVA,
	DAY_NIGHTCRAWLER,
	DAY_SPACE,
	DAY_SHARK,
	DAY_KNIFE,
	DAY_HNS,
	
	MAX_DAYS
}

enum
{
	UNRESTRICTED,
	RESTRICTED
}

enum
{
	CT,
	T
}
enum
{
	MAVERICK,
	AK,
	AUG,
	SCOUT,
	AWP,
	MP5
}

enum ( += 100 )
{
	TASK_HEGRENADE = 100,
	TASK_DODGEBALL,
	TASK_HIDENSEEK
}


// Integers
////////////

new g_iTimeLeft;

new g_iCurrentDay;

new g_iFreedayType;
new g_iNightcrawlerType;
new g_iZombieType;
new g_iSharkType;

// PCVars
new g_pOpenCells;

// Handles
///////////

new g_hDaysMenu;
new g_hSharkMenu;
new g_hNightcrawlerMenu;
new g_hFreedayMenu;
new g_hZombieMenu;

// Arrays
//////////

new Float:g_fWallOrigin[33][3];

new g_iButtons[10];

#if defined USE_SIMON 
	new g_iSimon;
#endif

// Messages
////////////

new g_msgNVGToggle;

// Constants
/////////////

new const g_szDaymenuOptions[MAX_DAYS][] = 
{
	"Free Day",
	"Cage Day",
	"Riot Day",
	"Zombie Day",
	"Dodgeball Day",
	"USP Ninja Day",
	"Lava Day",
	"NightCrawler Day",
	"Space Day",
	"Shark Day",
	"Knife Day",
	"Hide and Seek Day"
}

new const g_szDaymenuObjectives[MAX_DAYS][] = 
{
	"Prisoners do what they want. If restricted, Guards restrict one room.",
	"Prisoners get into the cage and follow the instructions by the Guards.",
	"One of the Prisoners has a weapon. The Guards job is to find out who it is.",
	"Kill the opposite team. Zombies start with 2000 HP.",
	"Kill the opposite team with HE-Grenades. You will start receiving nades at 8:00.",
	"Both teams have USP. Gravity reduced. Kill the other team.",
	"Prisoners must stay on a spray at all times. If they are caught off of a spray, Guards can kill them.",
	"Kill the opposite team. Nightcrawlers are completely invisible, and have no footsteps.",
	"Lower gravity. Prisoners start with scouts, and Guards have awps.",
	"The sharks have no-clip, everybody else has Awps. Kill the opposite team.",
	"Guards have 150 HP, Prisoners have 35. Kill each other!",
	"Prisoners have 60 seconds to hide anywhere in the map until they become visible. Once found they can be killed."
}

new const g_szPrefix[] = "^04[Jailbreak]^01";

new const g_szZombieModel[ ] = "models/player/zombie/zombie.mdl";
new const g_szZombieHands[ ] = "models/jailbreak/zombie_hands.mdl";

new const g_szVersion[ ] = "1.2.1";

public plugin_precache()
{
	precache_model( g_szZombieModel );
	precache_model( g_szZombieHands );
}

////////////////////////////////////
//--------- Plugin Init ----------//
////////////////////////////////////
public plugin_init()
{	
	register_plugin( "Jailbreak Daymenu", g_szVersion, "H3avY Ra1n" );
	
	register_clcmd( "say /daysmenu", "Cmd_DaysMenu" );
	
	register_logevent( "LogEvent_RoundStart", 	2, "1=Round_Start" 	);	
	register_logevent( "LogEvent_RoundEnd", 	2, "1=Round_End" 	);
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	RegisterHam( Ham_Spawn, 					"player", 			"Ham_PlayerSpawn_Post", 		1 );
	RegisterHam( Ham_TakeDamage, 				"player", 			"Ham_TakeDamage_Pre", 			0 );
	
	RegisterHam( Ham_Weapon_SecondaryAttack, 	"weapon_usp", 		"Ham_USP_SecondaryAttack_Pre", 	1 );
	
	RegisterHam( Ham_Touch, 					"armoury_entity", 	"Ham_WeaponTouch_Pre", 			0 );
	RegisterHam( Ham_Touch, 					"weaponbox", 		"Ham_WeaponTouch_Pre", 			0 );
	
	RegisterHam( Ham_Touch, 					"worldspawn", 		"Ham_WallTouch_Pre", 			0 );
	RegisterHam( Ham_Touch, 					"func_wall", 		"Ham_WallTouch_Pre", 			0 );
	RegisterHam( Ham_Touch, 					"func_breakable", 	"Ham_WallTouch_Pre", 			0 );
	
	register_forward( FM_AddToFullPack, 	"Forward_AddToFullPack_Post", 	1 );
	register_forward( FM_PlayerPreThink, 	"Forward_PreThink",				0 );
	
	server_cmd( "mp_roundtime 9" );
	server_cmd( "mp_freezetime 0" );
	
#if defined USE_SIMON
	g_iSimon = get_xvar_id( "g_iSimon" );
	
	if( g_iSimon == -1 )
	{
		set_fail_state( "[Days Menu] Simon plugin not running!" );
	}	
#endif

	g_msgNVGToggle = get_user_msgid( "NVGToggle" );
	
	g_pOpenCells	= register_cvar( "jb_opencells", "1" );
	
	register_cvar( "daymenu_version_novote", g_szVersion, FCVAR_SPONLY|FCVAR_SERVER );
	
	CreateMenus();
	
	setup_buttons();
}

public client_putinserver( id )
{
	if( g_iCurrentDay == DAY_ZOMBIE )
	{
		engfunc( EngFunc_LightStyle, 0, "b" );
	}
	
	else engfunc( EngFunc_LightStyle, 0, "m" );
}


public Cmd_DaysMenu( id )
{
#if defined USE_SIMON 
	if( id != get_xvar_num( g_iSimon ) )
	{
		ColorChat( id, NORMAL, "%s You must be ^03simon ^01to use this command.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
#else
	if( cs_get_user_team( id ) != CS_TEAM_CT )
	{
		ColorChat( id, NORMAL, "%s You must be a ^03guard ^01to use this command.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
#endif

	else if( !is_user_alive( id ) )
	{
		ColorChat( id, NORMAL, "%s You must be alive to use this command.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	menu_display( id, g_hDaysMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public CreateMenus()
{
	g_hDaysMenu = menu_create( "Choose a Day:", "DaysMenu_Handler" );
	
	new szInfo[ 6 ];
	
	for( new i = 0; i < MAX_DAYS; i++ )
	{
		num_to_str( i, szInfo, charsmax( szInfo ) );
		menu_additem( g_hDaysMenu, g_szDaymenuOptions[ i ], szInfo );
	}
	
	g_hNightcrawlerMenu = menu_create( "Choose the Nightcrawlers:", "NightcrawlerMenu_Handler" );
	menu_additem( g_hNightcrawlerMenu, "Guards", "0" );
	menu_additem( g_hNightcrawlerMenu, "Prisoners", "1" );
	
	g_hSharkMenu = menu_create( "Choose the Sharks:", "SharkMenu_Handler" );
	menu_additem( g_hSharkMenu, "Guards", "0" );
	menu_additem( g_hSharkMenu, "Prisoners", "1" );
	
	g_hZombieMenu = menu_create( "Choose the Zombies:", "ZombieMenu_Handler" );
	menu_additem( g_hZombieMenu, "Guards", "0" );
	menu_additem( g_hZombieMenu, "Prisoners", "1" );
	
	g_hFreedayMenu = menu_create( "Choose the Freeday:", "FreedayMenu_Handler" );
	menu_additem( g_hFreedayMenu, "Unrestricted", "0" );
	menu_additem( g_hFreedayMenu, "Resticted", "1" );
}

public DaysMenu_Handler( id, hMenu, iItem )
{
	if( g_iCurrentDay != DAY_NONE )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT || !is_user_alive( id ) || iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{		
		case DAY_FREE:
		{
			showFreedayMenu( id );
			return PLUGIN_HANDLED;
		}
		
		case DAY_NIGHTCRAWLER:
		{			
			showNightcrawlerMenu( id );
			return PLUGIN_HANDLED;
		}
		
		case DAY_SHARK:
		{
			showSharkMenu( id );
			return PLUGIN_HANDLED;
		}
		
		case DAY_ZOMBIE:
		{
			showZombieMenu( id );
			return PLUGIN_HANDLED;
		}
		
		default:
		{
			g_iCurrentDay = str_to_num( szData );
			startDay();
		}
	}
	
	return PLUGIN_HANDLED;
}

public showFreedayMenu( id )
{	
	menu_display( id, g_hFreedayMenu, 0 );
}

public FreedayMenu_Handler( id, hMenu, iItem )
{
	if( g_iCurrentDay != DAY_NONE )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT || !is_user_alive( id ) || iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	g_iFreedayType = str_to_num( szData );
	
	g_iCurrentDay = DAY_FREE;
	
	startAlternativeDay();
	return PLUGIN_HANDLED;
}

public showNightcrawlerMenu( id )
{	
	menu_display( id, g_hNightcrawlerMenu, 0 );
}

public NightcrawlerMenu_Handler( id, hMenu, iItem )
{
	if( g_iCurrentDay != DAY_NONE )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT || !is_user_alive( id ) || iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	
	new szData[ 6 ], iAccess, hCallback;
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	g_iNightcrawlerType = str_to_num( szData );
	
	g_iCurrentDay = DAY_NIGHTCRAWLER;
	
	startAlternativeDay();
	return PLUGIN_HANDLED;
}

public showZombieMenu( id )
{
	menu_display( id, g_hZombieMenu, 0 );
}

public ZombieMenu_Handler( id, hMenu, iItem )
{
	if( g_iCurrentDay != DAY_NONE )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT || !is_user_alive( id ) || iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	g_iZombieType = str_to_num( szData );
	
	g_iCurrentDay = DAY_ZOMBIE;
	
	startAlternativeDay();
	return PLUGIN_HANDLED;
}

public showSharkMenu( id )
{
	menu_display( id, g_hSharkMenu, 0 );
}

public SharkMenu_Handler( id, hMenu, iItem )
{
	if( g_iCurrentDay != DAY_NONE )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT || !is_user_alive( id ) || iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	g_iSharkType = str_to_num( szData );
	
	g_iCurrentDay = DAY_SHARK;
	
	startAlternativeDay();
	return PLUGIN_HANDLED;
}

public startDay()
{
	switch( g_iCurrentDay )
	{
		case DAY_CAGE:
		{
			ShowWeaponMenu();
		}
		
		case DAY_RIOT:
		{
			new players[32], num;
			get_players( players, num, "ae", "TERRORIST" );
			
			if( num <= 1 )
			{
				ColorChat( 0, NORMAL, "%s There are not enough ^03Prisoners ^01alive to do this day.", g_szPrefix );
				g_iCurrentDay = -1;
				return PLUGIN_HANDLED;
			}
			
			
			new random = random_num( 1, num );
			
			while( !is_user_alive( players[random] ) )
				random = random_num( 1, num );
			
			cs_set_weapon_ammo( give_item( players[random], "weapon_m4a1" ), 90 );
			cs_set_weapon_ammo( give_item( players[random], "weapon_deagle" ), 35 );
			
			ShowWeaponMenu();
		}
		
		case DAY_DODGEBALL:
		{	
			set_task( 30.0, "startDodgeballDay", TASK_DODGEBALL );
			
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "a" );
			
			for( new i = 0; i < iNum; i++ )
			{
				strip_user_weapons( iPlayers[ i ] );
				give_item( iPlayers[ i ], "weapon_knife" );
			}
		}
		
		case DAY_USP_NINJA:
		{
			new players[32], num, player;
			get_players( players, num, "a" );
			
			for( new i = 0; i < num; i++ )
			{
				player = players[i];
				set_user_health( player, 100 );
				StripPlayerWeapons( player );
				give_item( player, "weapon_knife" );
				
				give_item( player, "weapon_usp" );
				
				if( cs_get_user_team( player ) == CS_TEAM_CT )
				{
					cs_set_user_bpammo( player, CSW_USP, 112 );
				}
				
				else
				{
					cs_set_user_bpammo( player, CSW_USP, 32 );
				}
				
				new ent = find_ent_by_owner( 0, "weapon_usp", player );
				cs_set_weapon_silen( ent, 1 );
			}
			
			server_cmd( "sv_gravity 300" );
		}
		
		case DAY_SPACE:
		{
			new players[32], num, player;
			get_players( players, num, "a" );
			
			for( new i = 0; i < num; i++ )
			{
				player = players[i];
				StripPlayerWeapons( player );
				
				set_user_health( player, 100 );
				give_item( player, "weapon_knife" );
				
				switch( cs_get_user_team( player ) )
				{
					case CS_TEAM_CT:
					{
						give_item( player, "weapon_awp" );
						cs_set_user_bpammo( player, CSW_AWP, 30 );
						
					}
					
					case CS_TEAM_T:
					{
						give_item( player, "weapon_scout" );
						cs_set_user_bpammo( player, CSW_SCOUT, 90 );
					}
				}
			}
			
			server_cmd( "sv_gravity 300" );
		}
		
		case DAY_KNIFE:
		{
			new players[32], num, player;
			get_players( players,  num, "a" );
			
			for( new i = 0; i < num; i++ )
			{
				player = players[i];
				
				if( !is_user_alive( player ) )
					continue;
				
				switch( cs_get_user_team( player ) )
				{
					case CS_TEAM_CT:
					{
						set_user_health( player, 150 );
					}
					
					case CS_TEAM_T:
					{
						set_user_health( player, 35 );
					}
				}
				
				StripPlayerWeapons( player );
				
				give_item( player, "weapon_knife" );
			}
		}
		
		case DAY_HNS:
		{
			new players[32], num, player;
			get_players( players, num, "ae", "TERRORIST" );
			
			for( new i = 0; i < num; i++ )
			{
				player = players[i];
				
				if( !is_user_alive( player ) )
					continue;
				
				set_user_rendering( player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 16 );
				
				set_user_footsteps( player, 1 );
			}
			
			g_iTimeLeft = 60;
			set_task( 1.0, "Hidenseek_Countdown", TASK_HIDENSEEK, _, _, "a", g_iTimeLeft + 1 );
		}
		
		case DAY_LAVA: server_cmd( "decalfrequency 10" );
	}

	ColorChat( 0, NORMAL, "%s ^03Objective: ^01%s", g_szPrefix, g_szDaymenuObjectives[g_iCurrentDay] );
	
	if( get_pcvar_num( g_pOpenCells ) )
		Push_Button();
		
	return PLUGIN_HANDLED;
}

public Hidenseek_Countdown()
{
	g_iTimeLeft--;
	
	if( g_iTimeLeft >= 0 )
	{
		set_hudmessage( 0, 255, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.1, 0.1, 4 );
		show_hudmessage( 0, "%i More Seconds To Hide!", g_iTimeLeft );
	}
	
	else
	{
		set_hudmessage( 0, 255, 0, -1.0, 0.2, 0, 0.0, 5.0, 0.1, 0.1, 4 );
		show_hudmessage( 0, "READY OR NOT, HERE WE COME!" );
		
		new players[32], num, player;
		get_players( players, num, "ae", "TERRORIST" );
		
		for( new i = 0; i < num; i++ )
		{
			player = players[i];
			
			if( !is_user_alive( player ) )
				continue;
			
			set_user_rendering( player );
			set_user_footsteps( player, 0 );
		}
		
		if( task_exists( TASK_HIDENSEEK ) )
			remove_task( TASK_HIDENSEEK );	
		
		ColorChat( 0, NORMAL, "%s The ^03Prisoners^01 are now visible. FIND THEM!", g_szPrefix );
	}
}


public startAlternativeDay()
{
	switch( g_iCurrentDay )
	{
		case DAY_FREE:
		{
			switch( g_iFreedayType )
			{
				case UNRESTRICTED:
				{
					ColorChat( 0, NORMAL, "%s The guards have voted for an ^03Unrestricted Freeday^01.", g_szPrefix );
				}
				
				case RESTRICTED:
				{
					ColorChat( 0, NORMAL, "%s The guards have voted for a ^03Restricted Freeday^01.", g_szPrefix );
				}
			}
			
			ShowWeaponMenu();
		}
		
		case DAY_NIGHTCRAWLER:
		{
			ColorChat( 0, NORMAL, "%s The guards have voted for a ^03Nightcrawler Day^01.", g_szPrefix );
			
			switch( g_iNightcrawlerType )
			{
				case CT:
				{
					ColorChat( 0, NORMAL, "%s The ^03Guards ^01are the ^03Night-Crawlers^01!", g_szPrefix )
					
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						
						set_user_health( player, 100 );
						
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) ) 
						{
							case CS_TEAM_T:	
							{
								give_item( player, "weapon_m4a1" );
								give_item( player, "weapon_deagle" );
								
								cs_set_user_bpammo( player, CSW_M4A1, 90 );
								cs_set_user_bpammo( player, CSW_DEAGLE, 35 );
							}
							
							case CS_TEAM_CT:
							{								
								set_user_rendering( player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
								
								set_user_footsteps( player, 1 );
								
								
							}
						}
					}
				}
				
				case T:
				{
					ColorChat( 0, NORMAL, "%s The ^03Prisoners ^01are the ^03Night-Crawlers^01!", g_szPrefix );
					
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						
						set_user_health( player, 100 );
						
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) ) 
						{
							case CS_TEAM_CT:	
							{
								give_item( player, "weapon_m4a1" );
								give_item( player, "weapon_deagle" );
								
								cs_set_user_bpammo( player, CSW_M4A1, 90 );
								cs_set_user_bpammo( player, CSW_DEAGLE, 35 );
							}
							
							case CS_TEAM_T:
							{								
								set_user_rendering( player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
								
								set_user_footsteps( player, 1 );
								
								
							}
						}
					}					
				}
			}
		}
		
		case DAY_SHARK:
		{
			ColorChat( 0, NORMAL, "%s The guards have voted for a ^03Shark Day^01.", g_szPrefix );
			
			switch( g_iSharkType )
			{
				case CT:
				{
					ColorChat( 0, NORMAL, "%s The ^03Guards ^01are the ^03sharks^01!", g_szPrefix );
					
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						set_user_health( player, 100 );
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) )
						{
							case CS_TEAM_T:
							{
								give_item( player, "weapon_awp" );
								cs_set_user_bpammo( player, CSW_AWP, 30 );
							}
							
							case CS_TEAM_CT:
							{
								set_user_noclip( player, 1 );
							}
						}
					}
				}
				
				case T:
				{
					ColorChat( 0, NORMAL, "%s The ^03Prisoners ^01are the ^03sharks^01!", g_szPrefix );
					
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						set_user_health( player, 100 );
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) )
						{
							case CS_TEAM_CT:
							{
								give_item( player, "weapon_awp" );
								cs_set_user_bpammo( player, CSW_AWP, 30 );
							}
							
							case CS_TEAM_T:
							{
								set_user_noclip( player, 1 );
							}
						}
					}
				}
			}
		}
		
		case DAY_ZOMBIE:
		{
			ColorChat( 0, NORMAL, "%s The guards have voted for a ^03Zombie Day^01.", g_szPrefix );
			
			engfunc( EngFunc_LightStyle, 0, "b" );
			
			switch( g_iZombieType )
			{
				case CT:
				{
					ColorChat( 0, NORMAL, "%s The ^03Guards ^01are the ^03Zombies^01!", g_szPrefix );
					
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						set_user_health( player, 100 );
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) )
						{
							case CS_TEAM_CT:
							{
								set_user_health( player, 4000 );
								cs_set_user_model( player, "zombie" );
								set_user_gnvision( player, 1 );
								
								set_pev( player, pev_viewmodel2, g_szZombieHands );
							}
							
							case CS_TEAM_T:
							{
								if( random_num( 0, 1 ) == 1 )
								{
									give_item( player, "weapon_ak47" );
									cs_set_user_bpammo( player, CSW_AK47, 90 );
								}
								
								else
								{
									give_item( player, "weapon_m4a1" );
									cs_set_user_bpammo( player, CSW_M4A1, 90 );
								}
								
								give_item( player, "weapon_deagle" );
								cs_set_user_bpammo( player, CSW_DEAGLE, 35 );
							}
						}
					}
				}
				
				case T:
				{
					ColorChat( 0, NORMAL, "%s The ^03Prisoners ^01are the ^03Zombies^01!", g_szPrefix );
					new players[32], num, player;
					get_players( players, num, "a" );
					
					for( new i = 0; i < num; i++ )
					{
						player = players[i];
						set_user_health( player, 100 );
						StripPlayerWeapons( player );
						give_item( player, "weapon_knife" );
						
						switch( cs_get_user_team( player ) )
						{
							case CS_TEAM_T:
							{
								set_user_health( player, 2000 );
								cs_set_user_model( player, "zombie" );
								set_user_gnvision( player, 1 );
								
								set_pev( player, pev_viewmodel2, g_szZombieHands );
							}
							
							case CS_TEAM_CT:
							{
								if( random_num( 0, 1 ) == 1 )
								{
									give_item( player, "weapon_ak47" );
									cs_set_user_bpammo( player, CSW_AK47, 90 );
								}
								
								else
								{
									give_item( player, "weapon_m4a1" );
									cs_set_user_bpammo( player, CSW_M4A1, 90 );
								}
								
								give_item( player, "weapon_deagle" );
								cs_set_user_bpammo( player, CSW_DEAGLE, 35 );
							}
						}
					}
				}
			}
		}
	}
	
	ColorChat( 0, NORMAL, "%s ^03Objective: ^01%s", g_szPrefix, g_szDaymenuObjectives[g_iCurrentDay] );
	
	if( get_pcvar_num( g_pOpenCells ) )
		Push_Button();
}

public startDodgeballDay()
{
	set_task( 0.1, "giveNades", TASK_HEGRENADE, _, _, "b" );
}

public giveNades()
{
	static players[32], num, player;
	get_players( players, num, "a" );
	
	for( new i = 0; i < num; i++ )
	{
		player = players[i];
		
		if( !is_user_alive( player ) ) continue;
		
		if( !user_has_weapon( player, CSW_HEGRENADE ) )
		{
			give_item( player, "weapon_hegrenade" );
		}
	}
}

public LogEvent_RoundStart()
{
	engfunc( EngFunc_LightStyle, 0, "m" );
	
	Reset();
	
	RemoveAllTasks();
}

public LogEvent_RoundEnd()
{	
	Reset();
	RemoveAllTasks();
	
	new players[32], num;
	get_players( players, num, "a" );
	
	for( new i = 0; i < num; i++ )
	{
		StripPlayerWeapons( players[i] );
	}
	
	show_menu( 0, 0, "^n", 1 );
	
}

public Event_DeathMsg()
{
	new players[32], num;
	get_players( players, num, "ae", "TERRORIST" );
	
	if( num == 1 )
	{
		if( g_iCurrentDay == DAY_ZOMBIE )
		{
			engfunc( EngFunc_LightStyle, 0, "m" );
			
			cs_reset_user_model( players[ 0 ] );
			set_pev( players[ 0 ], pev_viewmodel2, "models/v_knife.mdl" );
		}
		
		g_iCurrentDay = -1;
		set_user_footsteps( players[0], 0 );
		set_user_rendering( players[0] );
	}
}

public Ham_PlayerSpawn_Post( id )
{
	if( !is_user_alive( id ) )
	{
		return HAM_IGNORED;
	}
	
	if( get_user_noclip( id ) )
		set_user_noclip( id, 0 );
	
	set_user_footsteps( id, 0 );
	
	set_user_rendering( id );
	
	set_user_gravity( id );	
	
	cs_reset_user_model( id );
	
	if( get_user_weapon( id ) == CSW_KNIFE )
		set_pev( id, pev_viewmodel2, "models/v_knife.mdl" );
		
	set_user_gnvision( id, 0 );
	
	StripPlayerWeapons( id );
	give_item( id, "weapon_knife" );
	
	
	return HAM_IGNORED;
}

public Ham_TakeDamage_Pre( victim, inflictor, attacker, Float:damage, dmgbits )
{
	switch( g_iCurrentDay )
	{
		case DAY_HNS:
		{
			if( task_exists( TASK_HIDENSEEK ) )
				return HAM_SUPERCEDE;
		}
		
		case DAY_DODGEBALL:
		{
			if( task_exists( TASK_DODGEBALL ) )
				return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public Ham_USP_SecondaryAttack_Pre( ent )
{
	if( g_iCurrentDay != DAY_USP_NINJA )
		return HAM_IGNORED;
	
	if( !pev_valid( ent ) )
		return HAM_IGNORED;
	
	if( cs_get_weapon_silen( ent ) )
		return HAM_IGNORED;
	
	else cs_set_weapon_silen( ent, 1 );
	
	return HAM_IGNORED;
}

public Ham_WeaponTouch_Pre( iEntity, id )
{
	if( !is_user_alive( id ) )
		return HAM_IGNORED;
	
	new CsTeams:team = cs_get_user_team( id );
		
	switch( g_iCurrentDay )
	{
		case DAY_ZOMBIE:
		{
			if( ( team == CS_TEAM_CT && g_iZombieType == CT ) 
				|| ( team == CS_TEAM_T && g_iZombieType == T ) )
					return HAM_SUPERCEDE;
		}
		
		case DAY_NIGHTCRAWLER:
		{
			if( ( team == CS_TEAM_CT && g_iNightcrawlerType == CT ) 
				|| ( team == CS_TEAM_T && g_iNightcrawlerType == T ) ) 
					return HAM_SUPERCEDE;
		}
		
		case DAY_SHARK:
		{
			if( ( team == CS_TEAM_CT && g_iSharkType == CT ) 
				|| ( team == CS_TEAM_T && g_iSharkType == T ) ) 
					return FMRES_SUPERCEDE;
		}
		
		case DAY_SPACE, DAY_KNIFE, DAY_USP_NINJA, DAY_DODGEBALL:
		{
			return HAM_SUPERCEDE;
		}
		
		case DAY_HNS:
		{
			if( team == CS_TEAM_T )
				return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public Ham_WallTouch_Pre( iEntity, id )
{
	if( !is_user_alive( id ) || g_iCurrentDay != DAY_NIGHTCRAWLER )
		return FMRES_IGNORED;

	pev( id, pev_origin, g_fWallOrigin[id] );
	
	return FMRES_IGNORED;
}

public Forward_AddToFullPack_Post( es_handle, e, ent, host, hostflags, id, pSet ) 
{
	if( id && g_iCurrentDay == DAY_NIGHTCRAWLER ) 
	{
		if( get_user_team( host ) == get_user_team( ent ) ) 
		{
			set_es( es_handle, ES_RenderMode, kRenderTransTexture );
			set_es( es_handle, ES_RenderAmt, 255 );
			
		}
	}
}

public Forward_PreThink( id )
{
	if( g_iCurrentDay != DAY_NIGHTCRAWLER )
		return FMRES_IGNORED;
	
	new CsTeams:team = cs_get_user_team( id );
	
	if( team == CS_TEAM_CT && g_iNightcrawlerType == T )
		return FMRES_IGNORED;
	
	else if( team == CS_TEAM_T && g_iNightcrawlerType == CT )
		return FMRES_IGNORED;
	
	new button = fm_get_user_button( id );
	
	if( button & IN_USE )
	{
		static Float:origin[3];
		pev( id, pev_origin, origin );
		
		if( get_distance_f( origin, g_fWallOrigin[id] ) > 10.0 )
			return FMRES_IGNORED;
		
		if( fm_get_entity_flags( id ) & FL_ONGROUND )
			return FMRES_IGNORED;
		
		if( button & IN_FORWARD )
		{
			static Float:velocity[3];
			velocity_by_aim( id, 240, velocity );
			
			fm_set_user_velocity( id, velocity );
		}
		
		else if( button & IN_BACK )
		{
			static Float:velocity[3];
			velocity_by_aim( id, -240, velocity );
			
			fm_set_user_velocity( id, velocity );
		}
	}
	
	return FMRES_IGNORED;
}

public ShowWeaponMenu()
{
	new menu = menu_create( "Choose Your Weapon:",  "Weapon_MenuHandler" );
	menu_additem( menu, "M4a1", "0" );
	menu_additem( menu, "AK-47", "1" );
	menu_additem( menu, "AUG", "2" );
	menu_additem( menu, "Scout", "3" )
	menu_additem( menu, "AWP", "4" );
	menu_additem( menu, "MP5", "5" );
	
	new players[32], num;
	get_players( players, num, "ae", "CT" );
	
	for( new i = 0; i < num ;i++ )
	{
		menu_display( players[i], menu, 0 );
	}
}

public Weapon_MenuHandler( id, menu, item )
{
	if( !is_user_alive( id ) )
		return PLUGIN_HANDLED;
		
	if( item == MENU_EXIT )
	{
		give_item( id, "weapon_m4a1" );
		give_item( id, "weapon_deagle" )
		
		cs_set_user_bpammo( id, CSW_M4A1, 300 );
		cs_set_user_bpammo( id, CSW_DEAGLE, 100 );
		
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_alive( id ) )
		return PLUGIN_HANDLED;
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo( menu, item, access, data, 5, szName, 63, callback );
	
	new key = str_to_num( data );
	
	StripPlayerWeapons( id );
	
	give_item( id, "weapon_knife" );
	
	switch( key )
	{
		case MAVERICK:
		{
			give_item( id, "weapon_m4a1" );
			cs_set_user_bpammo( id, CSW_M4A1, 300 );
		}
		
		case AK:
		{
			give_item( id, "weapon_ak47" );
			cs_set_user_bpammo( id, CSW_AK47, 300 );
		}
		
		case AUG:
		{
			give_item( id, "weapon_aug" );
			cs_set_user_bpammo( id, CSW_AUG, 300 );
		}
		
		case AWP:
		{
			give_item( id, "weapon_awp" );
			cs_set_user_bpammo( id, CSW_AWP, 100 );
		}
		
		case MP5:
		{
			give_item( id, "weapon_mp5navy" );
			cs_set_user_bpammo( id, CSW_MP5NAVY, 300 );
		}
		
		case SCOUT:
		{
			give_item( id, "weapon_scout" );
			cs_set_user_bpammo( id, CSW_SCOUT, 90 );
		}
	}
	
	give_item( id, "weapon_deagle" );
	cs_set_user_bpammo( id, CSW_DEAGLE, 100 );
	
	give_item( id, "weapon_hegrenade" );
	
	return PLUGIN_HANDLED;
}

public RemoveAllTasks()
{
	if( task_exists( TASK_HEGRENADE ) )
	{
		remove_task( TASK_HEGRENADE );
	}
	
	if( task_exists( TASK_DODGEBALL ) )
	{
		remove_task( TASK_DODGEBALL );
	}	
	
	if( task_exists( TASK_HIDENSEEK ) )
		remove_task( TASK_HIDENSEEK );
	
}

public Reset()
{
	if( get_cvar_num( "sv_gravity" ) != 800 )
		server_cmd( "sv_gravity 800" );
	
	if( get_cvar_num( "mp_friendlyfire" ) )
		server_cmd( "mp_friendlyfire 0" );
	
	if( get_cvar_num( "decalfrequency" ) == 15 )
		server_cmd( "decalfrequency 60" );
		
	/* Reset ALL variables */
	g_iCurrentDay = -1;
	g_iFreedayType = -1;
	g_iSharkType = -1;
	g_iNightcrawlerType = -1;
	g_iZombieType = -1;
}

public setup_buttons()
{
	new ent = 1 
	new ent3 
	new Float:origin[3] 
	new Float:radius = 200.0 
	new class[32] 
	new name[32]
	new pos 
	while((pos <= sizeof(g_iButtons)) && (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_deathmatch"))) // info_player_deathmatch = tspawn
	{ 
			new ent2 = 1 
			pev(ent, pev_origin, origin) 
			while((ent2 = engfunc(EngFunc_FindEntityInSphere, ent2, origin, radius)))  // find doors near T spawn
			{ 
					if(!pev_valid(ent2)) 
							continue 

					pev(ent2, pev_classname, class, charsmax(class)) 
					if(!equal(class, "func_door")) // if it's not a door, move on to the next iteration
							continue 

					pev(ent2, pev_targetname, name, charsmax(name)) 
					ent3 = engfunc(EngFunc_FindEntityByString, 0, "target", name) // find button that opens this door
					if(pev_valid(ent3) && (in_array(ent3, g_iButtons, sizeof(g_iButtons)) < 0)) 
					{ 
							ExecuteHamB(Ham_Use, ent3, 0, 0, 1, 1.0) // zomg poosh it
							g_iButtons[pos] = ent3 
							pos++ // next
							break // break from current while loop
					} 
			} 
	} 
	return pos 
}

public Push_Button()
{
	static i
	for(i = 0; i < sizeof(g_iButtons); i++)
	{
		if(g_iButtons[i])
		{
			ExecuteHamB(Ham_Use, g_iButtons[i], 0, 0, 1, 1.0)
			entity_set_float(g_iButtons[i], EV_FL_frame, 0.0)
		}
	}
}

// By ConnorMcLeod - Prevent Weapon Pickup Glitch

#define OFFSET_PRIMARYWEAPON        116 

public StripPlayerWeapons(id) 
{ 
    strip_user_weapons(id) 
    set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0) 
}  

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++)
	{
		if(data[i] == needle)
			return i
	}
	return -1
}

set_user_gnvision(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}