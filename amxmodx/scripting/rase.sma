#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

#define FLASH_SPEED 		350.0		// viteza care o are Flash
#define HULK_GRAVITY		0.75		// gravitatea setata lui hulk ( 1.0 = 800 )
#define PREDATOR_MULTIPLY	1.8		// damage facut inmultit cu 1.5 sau cat pui.
#define ELF_INVISIBILITY	76		// ( 0 - 255 ) 2.55 este aproximativ 1% deci 76 vine cam 30% vizibil

#define PLUGIN "Plugin Nou"
#define VERSION "1.0"

new  const  Models[  6  ][    ]  =
{
	
	"",		//Null
	"kaili",		//Flash
	"grafff",		//Hulk
	"termi",		//Predator
	"elfzoor",		//Elf
	"vip_skin_aaa"		//Vip
	
};

new  const  kModels[  6  ][    ]  =
{
	
	"",			//Null
	"models/v_flasher.mdl",		//Flash
	"models/v_grafff.mdl",		//Hulk
	"models/v_termiii.mdl",		//Predator
	"models/v_elfwow.mdl",		//Elf
	"models/v_viaiiipi.mdl"		//Vip
	
};

new  const  MenuName[    ]  =  " \wRase \rHuman^n";
new  const  NumeSite[    ]  =  "\yRase Human";

new  bool:UserIsFlash[  33  ];
new  bool:UserIsHulk[  33  ];
new  bool:UserIsPredator[  33  ];
new  bool:UserIsElf[  33  ];
new  bool:UserIsVIp[  33  ];
new  bool:UserChoosed[  33  ];

public  plugin_precache(    )
{
	
	new  ModelPath[  64  ];
	
	for(  new  i  = 1;  i  <  6;  i++  )
	{
		formatex(  ModelPath,  sizeof  (  ModelPath  )  -1, "models/player/%s/%s.mdl",  Models[  i  ],  Models[  i  ]  );
		precache_model(  ModelPath  );
		
	}
	for(  new  i  = 1;  i  <  6;  i++  )
	{
		precache_model(  kModels[  i  ]  );
	}
}

public plugin_cfg(    )    set_cvar_float(  "sv_maxspeed",  FLASH_SPEED  );

public plugin_init(    ) 
{
	register_plugin(  PLUGIN,  VERSION, "Askhanar"  );
	register_clcmd(  "say /race",  "sayRace"  );
	
	RegisterHam(  Ham_Spawn,  "player",  "Ham_PlayerSpawnPost",  true  );
	RegisterHam(  Ham_TakeDamage,  "player", "Ham_PlayerTakeDamage", false  );
	register_event( "CurWeapon", "evCurWeapon", "be", "1=1" );
	register_event( "HLTV", "evHookRoundStart", "a", "1=0", "2=0" );
}

public client_connect(id)
{
	SetCl_Settings(  id  ,  0  );
	UserIsFlash[  id  ]  =  false;
	UserIsHulk[  id  ]  =  false;
	UserIsPredator[  id  ]  =  false;
	UserIsElf[  id  ]  =  false;
	UserIsVIp[  id  ]  =  false;
	UserChoosed[  id  ]  =  false;
}

public client_disconnect(id)
{
	SetCl_Settings(  id,  0  );
	UserIsFlash[  id  ]  =  false;
	UserIsHulk[  id  ]  =  false;
	UserIsPredator[  id  ]  =  false;
	UserIsElf[  id  ]  =  false;
	UserIsVIp[  id  ]  =  false;
	UserChoosed[  id  ]  =  false;
}

public sayRace(  id  )
{
	if( UserChoosed[  id  ]  )
	{
		client_print( id, print_chat, "* Ti-ai ales deja rasa runda aceasta !" );
		return 1;
	}
	if(  cs_get_user_team(  id  )  ==  CS_TEAM_CT   )   MainMenu(  id  );
	
	return 0;
}

public Ham_PlayerSpawnPost(  id  ) 
{
	
	if(  !is_user_alive(  id  )  ||  UserChoosed[  id  ]  )  return HAM_IGNORED;
	
	if( UserChoosed[  id  ]  )
	{
		client_print( id, print_chat, "* Ti-ai ales deja rasa runda aceasta !" );
		return HAM_IGNORED;
	}
	
	ResetUserSettings(  id  );
	if(  cs_get_user_team(  id  )  ==  CS_TEAM_CT )  client_print( id, print_chat, "* Scrie /race ca sa iti alegi rasa" );
	
	cs_reset_user_model(  id  );
	
	return HAM_IGNORED;
}

public Ham_PlayerTakeDamage(  id,  iInflictor,  iAttacker,  Float:flDamage,  bitsDamageType  )
{
	
	if(  !iAttacker ||  id  ==  iAttacker  ||  !is_user_connected(  iAttacker  )  ||  !is_user_connected(  id  )
		||  get_user_team(  id  )  ==  get_user_team(  iAttacker  )
			|| !UserIsPredator[  iAttacker  ]  || !UserIsVIp[  id  ] ) return HAM_IGNORED;
	
	SetHamParamFloat(  4, flDamage * PREDATOR_MULTIPLY  );
	
	return HAM_IGNORED;
}

public evCurWeapon( id )
{
	if( is_user_alive( id ) )
	{
		
		if( cs_get_user_team(  id  )  ==  CS_TEAM_CT  )
		{
			
			new clip, ammo, wpnid = get_user_weapon( id, clip, ammo );
				
			if( wpnid == CSW_KNIFE  )
			{
			
				if( UserIsFlash[ id ] )
				{
					entity_set_string( id, EV_SZ_viewmodel, kModels[ 1 ] );
				}
				else if( UserIsHulk[ id ] )
				{
					entity_set_string( id, EV_SZ_viewmodel, kModels[ 2 ] );
				}
				else if( UserIsPredator[ id ] )
				{
					entity_set_string( id, EV_SZ_viewmodel, kModels[ 3 ] );
				}
				else if( UserIsElf[ id ] )
				{
					entity_set_string( id, EV_SZ_viewmodel, kModels[ 4 ] );
				}
				else if(  UserIsVIp[  id  ]  )
				{
				
					entity_set_string( id, EV_SZ_viewmodel, kModels[ 5 ] );
				}
			}
		}
		
	}
	
	return 0;
}
public evHookRoundStart( )
{
	new iPlayers[ 32 ];
	new iPlayersNum;

	get_players( iPlayers, iPlayersNum, "ch" );		
	for( new i = 0 ; i < iPlayersNum ; i++ )
	{
		UserChoosed[  iPlayers[  i  ]  ]  =  false;
	}
	
}
public client_PreThink(  id  )
{
	if(  is_user_alive(  id  ) && is_user_connected(  id  )  &&  cs_get_user_team(  id  )  ==  CS_TEAM_CT  )
	{
		if( UserIsFlash[  id  ]  ||  UserIsVIp[  id  ] )
		{
			set_user_maxspeed(  id,  FLASH_SPEED  );
		}
	}
	
}
	
public MainMenu( id )
{
	new  menu  =  menu_create(  MenuName,  "MainMenuHandler"  );	
	
	menu_additem(  menu,  "SpeeD QueeN \r[\yViteza Mare \w+ \yM4a1 \w+ \yDeagle\r]",  "1",  0  );
	menu_additem(  menu,  "GraFFeR Boy \r[\yGravitatie \w+ \yAk47 \w+ \yDeagle\r]",  "2",  0  );
	menu_additem(  menu,  "TerminaToR \r[\yDamage Ridicat \w+ \yM249 \w+ \yUsp\r]",  "3",  0  );
	menu_additem(  menu,  "ELF \r[\yInvizibilitate \w+ \yM4a1 \w+ \yUsp\r]^n",  "4",  0  );
	menu_additem(  menu,  "\rV\wi\rp \w[\rGravitatie \y+ \rViteza \y+ \rInvizibilitate \y+ \rDamage Dublu \y+ \rALL WEAPONS\w]",  "5",  0  );
	
	menu_setprop(  menu,  MPROP_EXITNAME,  NumeSite  );
	
	menu_display(  id,  menu,  0  );

}

/*=======================================================================================s=P=u=f=?*/

public MainMenuHandler(  id,  menu,  item  )
{
	if(  item  ==  MENU_EXIT  )
	{
		set_task(  0.1,  "MainMenu",  id  );
		return 1;
	}
	
	if(  cs_get_user_team(  id  )  !=  CS_TEAM_CT  ) return 1;
	
	new  data[  6  ],  iName[  64  ];
	new  iaccess,  callback;
	
	menu_item_getinfo(  menu,  item,  iaccess,  data,  5,  iName,  sizeof  (  iName  )  -1,  callback  );
	
	new  key  =  str_to_num(  data  );
	
	switch(  key  )
	{
		case 1:
		{
			UserChoosed[  id  ]  =  true;
			ResetUserSettings(  id  );
			GiveUserPower( id,  1 );
			cs_set_user_model(  id,  Models[  1  ]  );
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo ( id, CSW_M4A1, 999);
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo ( id, CSW_DEAGLE, 999);
			engclient_cmd( id, "weapon_knife" );
			return 1;
		}
		case 2:
		{
			UserChoosed[  id  ]  =  true;
			ResetUserSettings(  id  );
			GiveUserPower( id,  2 );
			cs_set_user_model(  id,  Models[  2  ]  );
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo ( id, CSW_AK47, 999);
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo ( id, CSW_DEAGLE, 999);
			engclient_cmd( id, "weapon_knife" );
			return 1;
		}
		case 3:
		{
			UserChoosed[  id  ]  =  true;
			ResetUserSettings(  id  );
			GiveUserPower( id,  3 );
			cs_set_user_model(  id,  Models[  3  ]  );
			give_item(id, "weapon_m249");
			cs_set_user_bpammo ( id, CSW_M249, 999);
			give_item(id, "weapon_usp");
			cs_set_user_bpammo ( id, CSW_USP, 999);
			engclient_cmd( id, "weapon_knife" );
			return 1;
		}
		case 4:
		{
			UserChoosed[  id  ]  =  true;
			ResetUserSettings(  id  );
			GiveUserPower( id,  4 );
			cs_set_user_model(  id,  Models[  4  ]  );
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo ( id, CSW_M4A1, 999);
			give_item(id, "weapon_usp");
			cs_set_user_bpammo ( id, CSW_USP, 999);
			engclient_cmd( id, "weapon_knife" );
			return 1;
		}
		case 5:
		{
			if(  UserIsVip(  id  ) )
			{
				UserChoosed[  id  ]  =  true;
				ResetUserSettings(  id  );
				GiveUserPower( id,  5 );
				cs_set_user_model(  id,  Models[  5  ]  );
				give_item(id, "weapon_ak47");
				cs_set_user_bpammo ( id, CSW_AK47, 999);
				give_item(id, "weapon_deagle");
				cs_set_user_bpammo ( id, CSW_DEAGLE, 999);
				give_item(id, "weapon_m249");
				cs_set_user_bpammo ( id, CSW_M249, 999);
				give_item(id, "weapon_m4a1");
				cs_set_user_bpammo ( id, CSW_M4A1, 999);
				give_item(id, "weapon_usp");
				cs_set_user_bpammo ( id, CSW_USP, 999);
				engclient_cmd( id, "weapon_knife" );
				return 1;
			}
			else
			{
				MainMenu(  id  );
				return 1;
			}
		}
	}
	
	return 0;
}

public GiveUserPower(  id,  const  Class  )
{
	
	switch(  Class  )
	{
		case 1:
		{
			
			//slow hacking ?:O
			SetCl_Settings(  id,  1  );
			set_user_maxspeed(  id,  FLASH_SPEED  );
			UserIsFlash[  id  ]  =  true;
			
			return 1;
			
		}
		case 2:
		{
			set_user_gravity(  id,  HULK_GRAVITY  );
			UserIsHulk[  id  ]  =  true;
			
			return 1;
		}
		case 3:
		{
			UserIsPredator[  id  ]  =  true;
			return 1;
		}
		case 4:
		{
			set_user_rendering(  id,  kRenderFxNone,  0,  0,  0,  kRenderTransAlpha,  ELF_INVISIBILITY );
			UserIsElf[  id  ]  =  true;
			
			return 1;
		}
		case 5:
		{
			//Il facem Flash
			SetCl_Settings(  id,  1  );
			
			set_user_maxspeed(  id,  FLASH_SPEED  );
			
			//Il facem Hulk
			set_user_gravity(  id,  HULK_GRAVITY  );
			
			//Il facem Predator
			
			//Il facem Elf
			set_user_rendering(  id,  kRenderFxNone,  0,  0,  0,  kRenderTransAlpha,  ELF_INVISIBILITY );
			
			UserIsVIp[  id  ]  =  true;
			return 1;
		}
	}
	
	return 0;
	
}

public ResetUserSettings(  id  )
{
	if(  UserIsFlash[  id  ]  )    set_user_maxspeed(  id,  255.0  );
	
	if(  UserIsHulk[  id  ]  )     set_user_gravity(  id,  1.0  );
		
	if(  UserIsElf[  id  ]  )    set_user_rendering(  id,  kRenderFxNone,  0,  0,  0,  kRenderNormal,  0  );
	
	if( UserIsVIp[  id  ]  )
	{
		set_user_maxspeed(  id,  255.0  );
	
		set_user_gravity(  id,  1.0  );
			
		set_user_rendering(  id,  kRenderFxNone,  0,  0,  0,  kRenderNormal,  0  );
	}
		
	
	SetCl_Settings(  id,  0  );
	UserIsFlash[  id  ]  =  false;
	UserIsHulk[  id  ]  =  false;
	UserIsPredator[  id  ]  =  false;
	UserIsElf[  id  ]  =  false;
	UserIsVIp[  id  ]  =  false;
	
}
public SetCl_Settings(  id,  const  OnOff  )
{
	
	if(  OnOff  >  0  )
	{
		client_cmd(  id, "cl_backspeed %.1f",  FLASH_SPEED  );
		client_cmd(  id, "cl_forwardspeed %.1f",  FLASH_SPEED  );
		client_cmd(  id, "cl_sidespeed %.1f",  FLASH_SPEED  );
		
		return 1;
		
	}
	
	client_cmd(  id, "cl_backspeed 400"  );
	client_cmd(  id, "cl_forwardspeed 400"  );
	client_cmd(  id, "cl_sidespeed 400"  );
	
	return 0;
	
}

stock bool:UserIsVip(  id  )
{
	
	if(  get_user_flags(  id  )  &  read_flags(  "c"  )  )
		return true;
		
	return false;
	
}