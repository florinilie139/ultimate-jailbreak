#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#pragma tabsize 0
  

//Drop Crowbar
enum _: iCrowbarSequences
{
	CrowbarIdle = 0,
	CrowbarFloat,
	CrowbarSpin
};
new const gCrowbarClassname[ ] = "crowbar$";
new const gCrowbarModel[ ] = "models/w_cbd.mdl";

//native
native jb_starttag()
native jb_game_killball()
native give_rifle(id);
native give_conc_bomb(id);
native give_jump_bomb(id);
native open_football_menu(id);


#define JB_PREFIX	"!y[!gSimonMenu!y]"


#pragma tabsize 0
#define PLUGIN_NAME	"JailBreak Romania"
#define PLUGIN_AUTHOR	"Fantasy / Joropito"
#define PLUGIN_VERSION	"2.0"
#define PLUGIN_CVAR	"jbevils"

#define ADMIN_ACCESS ADMIN_MAP

#define TASK_STATUS	2487000
#define TASK_FREEDAY	2487100
#define TASK_ROUND	2487200
#define TASK_HELP		2487300
#define TASK_SAFETIME	2487400
#define TASK_FREEEND	2487500
#define TEAM_MENU		"#Team_Select_Spect"
#define TEAM_MENU2	"#Team_Select_Spect"
#define HUD_DELAY		Float:4.0
#define CELL_RADIUS	Float:200.0

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)		floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)		( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

// Offsets
#define m_iPrimaryWeapon	116
#define m_iVGUI			510
#define m_fGameHUDInitialized	349
#define m_fNextHudTextArgsGameTime	198
 
enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
enum _lastrequest { _knife, _deagle, _freeday, _weapon }
enum _duel { _name[16], _csw, _entname[32], _opt[32], _sel[32] }

new gp_PrecacheSpawn
new gp_PrecacheKeyValue

new gp_CrowbarMax
new gp_CrowbarMul
new gp_TeamRatio
new gp_CtMax
new gp_BoxMax
new gp_TalkMode
new gp_VoiceBlock
new gp_RetryTime
new gp_RoundMax
new gp_ButtonShoot
new gp_SimonSteps
new gp_SimonRandom
new gp_GlowModels
new gp_AutoLastresquest
new gp_LastRequest
new gp_Motd
new gp_SpectRounds
new gp_NosimonRounds
new gp_AutoOpen
new gp_TeamChange

new g_MaxClients
new g_MsgStatusText
new g_MsgStatusIcon
new g_MsgVGUIMenu
new g_MsgShowMenu
new g_MsgClCorpse
new g_MsgMOTD

new gc_TalkMode
new gc_VoiceBlock
new gc_SimonSteps
new gc_ButtonShoot
new Float:gc_CrowbarMul

// Precache
new const _FistModels[][] = { "models/lunetistiimodels/p_pumni.mdl", "models/lunetistiimodels/v4_pumni.mdl" }
new const _CrowbarModels[][] = { "models/lunetistiimodels/p_ranga.mdl", "models/lunetistiimodels/v_ranga.mdl" }
new const _FistSounds[][] = { "weapons/ranga/hit1.wav", "weapons/ranga/hit2.wav", "weapons/pumni/hit1.wav", "weapons/pumni/hit2.wav" }
new const gs_ViewModel[ ] = "models/lunetistiimodels/v_bulan.mdl";
new const gs_WeaponModel[ ] = "models/lunetistiimodels/p_bulan.mdl";
new const game_box[] = { "sound/jbsounds/jb_box3.mp3" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new const _Duel[][_duel] =
{
	{ "Deagle", CSW_DEAGLE, "weapon_deagle", "JBE_MENU_LASTREQ_OPT4", "JBE_MENU_LASTREQ_SEL4" },
	{ "Scout", CSW_SCOUT, "weapon_scout", "JBE_MENU_LASTREQ_OPT5", "JBE_MENU_LASTREQ_SEL5" },
	{ "Grenades", CSW_HEGRENADE, "weapon_hegrenade", "JBE_MENU_LASTREQ_OPT6", "JBE_MENU_LASTREQ_SEL6" },
	{ "Awp", CSW_AWP, "weapon_awp", "JBE_MENU_LASTREQ_OPT7", "JBE_MENU_LASTREQ_SEL7" },
	{ "M4A1", CSW_M4A1, "weapon_m4a1", "JBE_MENU_LASTREQ_OPT8", "JBE_MENU_LASTREQ_SEL8" },
    { "M249", CSW_M249, "weapon_m249", "JBE_MENU_LASTREQ_OPT9", "JBE_MENU_LASTREQ_SEL9" }
}

//Shop
#define is_valid_player(%1) (1 <= %1 <= 32)
#define CharsMax(%1) sizeof %1 - 1
#define MAX_LINES 512
#define MAX_LEN 256
new g_szTag [] = "[Jb.Lunetistii.Ro]"
new g_cranii[33], take[33], give[33], gidPlayer[33]
new g_killcranii, g_killhscranii, g_startcranii, g_maxcranii, syncObj
new bool: GodmodeFolosit[33]
new w_machete[33], w_benzo[33], w_electro[33]
new const g_vipflag = ADMIN_LEVEL_G

//DaysMenu
#define is_valid_player(%1) (1 <= %1 <= 32)
const CountSeconds = 90;
new g_iCountTime;
new bool: GodmodeDay;
new bool: frezz[32]
new g_msgSayText, gmsgScreenFade
new day = 0;
new const PREFIX[] = "[Jb.Lunetistii.Ro]";

new g_iSpecialDay = -1;
new const g_szDaysText[ 16 ][] = {
	"Zombie",
	"Spartan",
	"Gravity",
	"NightCrawler",
	"Box",
	"War",
	"HNS",
	"NoClip",
	"GodMode",
	"MagicDay",
	"Tag",
	"DodgeBall",
	"Grenade",
	"Ramboo",
	"1HP",
	"Reverse Zombie"
}

// Reasons
new const g_Reasons[][] =  {
	"",
	"JBE_PRISONER_REASON_1",
	"JBE_PRISONER_REASON_2",
	"JBE_PRISONER_REASON_3",
	"JBE_PRISONER_REASON_4",
	"JBE_PRISONER_REASON_5",
	"JBE_PRISONER_REASON_6"
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help / 8=timer
new const g_HudSync[][_hud] =
{
	{0,  0.6,  0.2,  2.0},
	{0, -1.0,  0.7,  5.0},
	{0,  0.1,  0.2,  2.0},
	{0,  0.1,  0.3,  2.0},
	{0, -1.0,  0.9,  3.0},
	{0,  0.6,  0.1,  3.0},
	{0, -1.0,  0.6,  3.0},
	{0,  0.8,  0.3, 20.0},
	{0, -1.0,  0.4,  3.0}
}

// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {0, 0, 255}, {255, 0, 0} }

new CsTeams:g_PlayerTeam[33]
new Float:g_SimonRandom
new Trie:g_CellManagers
new g_HelpText[512]
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerSpect[33]
new g_PlayerSimon[33]
new g_PlayerNomic
new g_PlayerWanted
new g_PlayerCrowbar
new g_PlayerRevolt
new g_PlayerHelp
new g_PlayerFreeday
new g_PlayerLast
new g_FreedayAuto
new g_FreedayNext
new g_TeamCount[CsTeams]
new g_TeamAlive[CsTeams]
new g_BoxStarted
new g_CrowbarCount
new g_Simon
new g_SimonAllowed
new g_SimonTalking
new g_SimonVoice
new g_RoundStarted
new g_LastDenied
new g_Freeday
new g_BlockWeapons
new g_RoundEnd
new g_Duel
new g_DuelA
new g_DuelB
new g_SafeTime
new g_Buttons[10]
 
public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)
	unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	register_dictionary("jbextreme.txt")
      
	g_MsgStatusText = get_user_msgid("StatusText")
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgMOTD = get_user_msgid("MOTD")
	g_MsgClCorpse = get_user_msgid("ClCorpse")

	register_message(g_MsgStatusText, "msg_statustext")
	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_vguimenu")
	register_message(g_MsgShowMenu, "msg_showmenu")
	register_message(g_MsgMOTD, "msg_motd")
	register_message(g_MsgClCorpse, "msg_clcorpse")
	

	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
	register_event("StatusValue", "player_status", "be", "1=2", "2!0")
	register_event("StatusValue", "player_status", "be", "1=1", "2=0")
    //register_event("SendAudio", "music1", "a", "2&%!MRAD_music") 
	//register_event("SendAudio", "music2", "a", "2&%!MRAD_music") 
	//register_event("SendAudio", "music3", "a", "2&%!MRAD_music")
	register_event("CurWeapon","HookCurWeapon", "be", "1=1")

	register_impulse(100, "impulse_100")
	// Crowbar Drop
	register_event( "DeathMsg", "Hook_DeathMessage", "a" );
	register_touch( gCrowbarClassname, "player", "Forward_TouchCrowbar" );
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	RegisterHam(Ham_TraceAttack, "player", "player_attack")
	RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
	RegisterHam(Ham_Killed, "player", "player_jb_killed", 1)
	RegisterHam(Ham_Touch, "weapon_hegrenade", "player_touchweapon")
	RegisterHam(Ham_Touch, "weaponbox", "player_touchweapon")
	RegisterHam(Ham_Touch, "armoury_entity", "player_touchweapon")
	RegisterHam ( Ham_Spawn,"player","HookPlayerSpawn", 1 )
	RegisterHam(Ham_TakeDamage, "player", "fwdTakeDamage")

	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")
	register_forward(FM_CmdStart, "player_cmdstart", 1)
	register_forward(FM_EmitSound, "fw_EmitSound")
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
	register_logevent("eRoundEnd", 2, "1=Round_End");
	//register_logevent( "eRoundStart", 2, "1=Round_Start" );

	register_menucmd(register_menuid(TEAM_MENU), 51, "team_select") 
	register_menucmd(register_menuid(TEAM_MENU2), 51, "team_select") 

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("joinclass", "cmd_joinclass")
	register_clcmd("+simonvoice", "cmd_voiceon")
	register_clcmd("-simonvoice", "cmd_voiceoff")
	
    register_clcmd("say /fd", "cmd_freeday")
	register_clcmd("say /freeday", "cmd_freeday")
	register_clcmd("say /day", "cmd_freeday")
	register_clcmd("say /lr", "cmd_lastrequest")
	register_clcmd("say /lr", "cmd_lastrequest")
	register_clcmd("say /duel", "cmd_lastrequest")
	register_clcmd("say /simon", "cmd_simon")
	register_clcmd("say /open", "cmd_open")
	register_clcmd("say /nomic", "cmd_nomic")
	register_clcmd("say /box", "cmd_boxmenu")
	register_clcmd( "say /days", "cmd_daysmenu" )
	register_clcmd("say /daysmenu", "cmd_daysmenu")
	register_clcmd("say /shop", "ShopMenu")
    register_clcmd("say_team /shop", "ShopMenu")
	register_clcmd("say /mc", "MenuCranii")
	register_clcmd("say !mc", "MenuCranii")
	register_clcmd("say_team /mc", "MenuCranii")
	register_clcmd("say_team !mc", "MenuCranii")
	register_clcmd("Cantitate", "player")
	//register_clcmd("say /boxoff", "cmd_boxoff")
	//register_clcmd("say /boxinstant", "cmd_box")
	register_clcmd("say /help", "cmd_help")
	//register_clcmd("say /music", "cmd_music")
	register_clcmd("say /menu", "cmd_simonmenu")
	register_clcmd("say /simonmenu", "cmd_simonmenu")
	
	g_killcranii = register_cvar("jb_killcranii", "1"); 
	g_killhscranii = register_cvar("jb_bonushscranii","2");
	g_startcranii = register_cvar("jb_startcranii","2"); 
	g_maxcranii = register_cvar("jb_maxgivecranii","10000");
	
	syncObj = CreateHudSyncObj()
	
	register_dictionary( "jbextreme.txt" );
	
	register_clcmd("jbe_freeday", "adm_freeday", ADMIN_ACCESS)
	register_concmd("jbe_nomic", "adm_nomic", ADMIN_ACCESS)
	register_concmd("jbe_open", "adm_open", ADMIN_ACCESS)
	register_concmd("jbe_box", "adm_box", ADMIN_ACCESS)
	register_concmd("jbe_boxoff", "adm_boxoff", ADMIN_ACCESS)
	register_concmd("jbe_simonreset", "cmd_simonreset", ADMIN_ACCESS)

    gp_GlowModels = register_cvar("jbe_glowmodels", "0")
	gp_SimonSteps = register_cvar("jbe_simonsteps", "0")
	gp_CrowbarMul = register_cvar("jbe_crowbarmultiplier", "25.0")
	gp_CrowbarMax = register_cvar("jbe_maxcrowbar", "1")
	gp_TeamRatio = register_cvar("jbe_teamratio", "3")
	gp_TeamChange = register_cvar("jbe_teamchange", "0") // 0-disable team change for tt / 1-enable team change
	gp_CtMax = register_cvar("jbe_maxct", "6")
	gp_BoxMax = register_cvar("jbe_boxmax", "32")
	gp_RetryTime = register_cvar("jbe_retrytime", "10.0")
	gp_RoundMax = register_cvar("jbe_freedayround", "240.0")
	gp_AutoLastresquest = register_cvar("jbe_autolastrequest", "1")
	gp_LastRequest = register_cvar("jbe_lastrequest", "1")
	gp_Motd = register_cvar("jbe_motd", "1")
	gp_SpectRounds = register_cvar("jbe_spectrounds", "3")
	gp_NosimonRounds = register_cvar("jbe_nosimonrounds", "7")
	gp_SimonRandom = register_cvar("jbe_randomsimon", "0")
	gp_AutoOpen = register_cvar("jbe_autoopen", "1")
	gp_TalkMode = register_cvar("jbe_talkmode", "2")	// 0-alltak / 1-tt talk / 2-tt no talk
	gp_VoiceBlock = register_cvar("jbe_blockvoice", "2")	// 0-dont block / 1-block voicerecord / 2-block voicerecord except simon
	gp_ButtonShoot = register_cvar("jbe_buttonshoot", "1")	// 0-standard / 1-func_button shoots!
	
	g_MaxClients = get_global_int(GL_maxClients)
	g_msgSayText = get_user_msgid("SayText")
	gmsgScreenFade = get_user_msgid("ScreenFade")
	
	RegisterHam(Ham_Killed,	"player", "fw_player_killed")
    RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage")
    RegisterHam(Ham_Spawn, "player", "Spawn_player", 1)
    set_task(120.0, "mesajgodmode");
	
	for(new i = 0; i < sizeof(g_HudSync); i++)
		g_HudSync[i][_hudsync] = CreateHudSyncObj()
	
	formatex(g_HelpText, charsmax(g_HelpText), "%L^n^n%L^n^n%L^n^n%L",
	LANG_SERVER, "JBE_HELP_TITLE",
	LANG_SERVER, "JBE_HELP_BINDS",
	LANG_SERVER, "JBE_HELP_GUARD_CMDS",
	LANG_SERVER, "JBE_HELP_PRISONER_CMDS")
	
	setup_buttons()

	  
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	static i
        precache_model("models/player/jb_lunetistii_v2/jb_lunetistii_v2.mdl")
		precache_model("models/player/jb_lunetistii_v2/jb_lunetistii_v2T.mdl")
        precache_model("models/w_cbd.mdl")
	precache_model ( gs_ViewModel )
	precache_model ( gs_WeaponModel )
        precache_generic("sound/jbsounds/florin1.mp3")
	precache_generic("sound/jbsounds/ST1.mp3")
	precache_generic("sound/jbsounds/Susa1.mp3")
	precache_generic(game_box)
 
	for(i = 0; i < sizeof(_FistModels); i++)
		precache_model(_FistModels[i])
 
	for(i = 0; i < sizeof(_CrowbarModels); i++)
		precache_model(_CrowbarModels[i])
 
	for(i = 0; i < sizeof(_FistSounds); i++)
		precache_sound(_FistSounds[i])
     
	precache_sound("ambience/siren.wav")
	precache_sound("jbsounds/jb_lr.wav")
    precache_sound("jbsounds/jb_box3.mp3")
	precache_sound("jbsounds/jb_ding.wav")
	precache_sound("jbsounds/jb_kill.wav")
	precache_sound("jbsounds/jb_open.wav")
	

	precache_model( "models/ShopJB/benzo/v_benzo.mdl" )
   precache_model( "models/ShopJB/benzo/p_benzo.mdl" )
   precache_model( "models/ShopJB/Machete/v_Machete.mdl" )
   precache_model( "models/ShopJB/Machete/p_Machete.mdl" )
   precache_model( "models/ShopJB/electro/v_electro.mdl" )
   precache_model( "models/ShopJB/electro/p_electro.mdl" )
   precache_sound("ShopJB/benzo/MTSlash.wav")
   precache_sound("ShopJB/benzo/MTConvoca.wav")
   precache_sound("ShopJB/benzo/MTHitWall.wav")
   precache_sound("ShopJB/benzo/MTHit2.wav")
   precache_sound("ShopJB/benzo/MTStab.wav")
   precache_sound("ShopJB/machete/EConvoca.wav")
   precache_sound("ShopJB/machete/EHitWall.wav")
   precache_sound("ShopJB/machete/EHit2.wav")
   precache_sound("ShopJB/machete/ESlash.wav")
   precache_sound("ShopJB/machete/EStab.wav")
	
 	g_CellManagers = TrieCreate()
	gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
	gp_PrecacheKeyValue = register_forward(FM_KeyValue, "precache_keyvalue", 1)
}

//Shop
bool:is_user_vip(id)
{
	if(id < 0 || id > 32)
		return false
	
	if( !(get_user_flags(id) & g_vipflag) )
		return false
	
	return true
}
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;
		
	if (w_benzo[id] && equal(sample[8], "kni", 3))
	{
		volume = 0.6;
		
		if (equal(sample[14], "sla", 3))
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/benzo/MTSlash.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if(equal(sample,"weapons/knife_deploy1.wav"))
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/benzo/MTConvoca.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') 
			{
				engfunc(EngFunc_EmitSound, id, channel,"ShopJB/benzo/MTHitWall.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			else 
			{
				engfunc(EngFunc_EmitSound, id, channel, "ShopJB/benzo/MTHit2.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) 
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/benzo/MTStab.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	if (w_machete[id] && equal(sample[8], "kni", 3))
	{
		volume = 0.6;
		
		if (equal(sample[14], "sla", 3))
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/machete/ESlash.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if(equal(sample,"weapons/knife_deploy1.wav"))
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/machete/EConvoca.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') 
			{
				engfunc(EngFunc_EmitSound, id, channel,"ShopJB/machete/EHitWall.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			else 
			{
				engfunc(EngFunc_EmitSound, id, channel, "ShopJB/machete/EHit2.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) 
		{
			engfunc(EngFunc_EmitSound, id, channel, "ShopJB/machete/EStab.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public precache_spawn(ent)
{
	if(is_valid_ent(ent))
	{
		static szClass[33]
		entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
				remove_entity(ent)
	}
}
public Player_TakeDamage(victim, inflicator, attacker, Float:damage, damage_type, bitsDamage)
{
        if(is_user_connected(attacker) && get_user_weapon(attacker) != CSW_KNIFE)
		return;

        if(pev(attacker, pev_button) & IN_ATTACK && w_benzo[attacker])
	{
               if(get_user_team(attacker) == get_user_team(victim))
                                            return;

               SetHamParamFloat(4, damage = 500.0)
	}
	else if(pev(attacker, pev_button) & IN_ATTACK2 && w_benzo[attacker])
	{ 
               SetHamParamFloat(4, damage = 500.0)
	}

        if(pev(attacker, pev_button) & IN_ATTACK && w_electro[attacker])
	{
               if(get_user_team(attacker) == get_user_team(victim))
                                            return;

               SetHamParamFloat(4, damage = 75.0)
	}
	else if(pev(attacker, pev_button) & IN_ATTACK2 && w_electro[attacker])
	{ 
               SetHamParamFloat(4, damage = 75.0)
	}
}  
public MenuCranii(id)
{	
	if(!is_user_vip(id))
	{
		ChatColor(id, "!g[CrediteManager] Nu ai acces la aceasta comanda !", g_szTag )
		return PLUGIN_HANDLED
	}
	
	new menu = menu_create("\rCredite Manager", "CraniiHandler");
	
	menu_additem(menu, "Give Credite", "1")
	menu_additem(menu, "Take Credite", "2")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}
public CraniiHandler(id, menu, item)
{
	
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, Callback)
	
	new Key = str_to_num(Data)
	
	switch (Key)
	{
		case 1:
		{	
			give[id] = 1
			take[id] = 0	
			Choose(id)
		}
		case 2: 
		{	
			take[id] = 1
			give[id] = 0
			Choose(id)
		}
	}
	
	menu_destroy(menu)	
	return PLUGIN_HANDLED
}
public Choose(id)
{
	static opcion[64]
	
	
	new iMenu = menu_create("\rAlege playerul", "cantitate")
	
	new players[32], pnum, tempid
	new szName[32], szTempid[10]
	
	get_players(players, pnum, "a")
	
	for( new i; i<pnum; i++ )
	{
		tempid = players[i]
		
		get_user_name(tempid, szName, 31)
		num_to_str(tempid, szTempid, 9)
		
		formatex(opcion, charsmax(opcion), "\y%s \gCranii [ %d ]", szName, g_cranii[tempid])
		menu_additem(iMenu, opcion, szTempid, 0)
	}
	
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}
public cantitate(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new Data[6], Name[64]
	new Access, Callback
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, Callback)
	
	new tempid = str_to_num(Data)
	
	gidPlayer[id] = tempid
	client_cmd(id, "messagemode Cantitate")
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public player(id)
{
	new say[300]
	read_args(say, charsmax(say))
	
	remove_quotes(say)
	
	if(!is_str_num(say) || equal(say, ""))
		return PLUGIN_HANDLED
	
	cranii(id, say)    
	
	return PLUGIN_CONTINUE
}
cranii(id, say[]) 
{        
	new amount = str_to_num(say)
	new victim = gidPlayer[id]
	
	new vname[32]
	
	if(victim > 0)
	 {    
		get_user_name(victim, vname, 31)
		
		if(give[id])
		 {    
			if(amount > get_pcvar_num(g_maxcranii))
			 {
				g_cranii[victim] = get_pcvar_num(g_maxcranii)
			 }
			else
			 {
				g_cranii[victim] = g_cranii[victim] + amount
			 }
			ChatColor(0, "[!gJb.Lunetistii.Ro]!gAdmin i-a dat !team%d !gCredite !glui !team%s ", amount, vname)
		 }  
		if(take[id])
		 {
			if(amount > g_cranii[victim])
			{
				g_cranii[victim] = 0
				ChatColor(0, "[!gJb.Lunetistii.Ro]!gAdmin i-a luat Creditele lui !e%s", vname)
			}
			else 
			{
				g_cranii[victim] = g_cranii[victim] - amount
				ChatColor(0, "[!gJb.Lunetistii.Ro]!gAdmin !team%d !gi-a luat toate Creditele !glui !team%s", amount, vname)
			}
			
		}		
	}
	
	return PLUGIN_HANDLED
}
public fw_player_killed(victim, attacker, shouldgib)
{
	if(get_user_team(attacker) == 1)
	{
		g_cranii[attacker] += get_pcvar_num(g_killcranii) 
		
		if(get_pdata_int(victim, 75) == HIT_HEAD)
		{
			g_cranii[attacker] += get_pcvar_num(g_killhscranii)
		}
	}
}
public Event_CurWeapon(player)
{
        if(!is_user_alive(player))
		return PLUGIN_CONTINUE

        if(read_data(2) == CSW_KNIFE && w_benzo[player])
	    {
            set_pev(player, pev_viewmodel2, "models/ShopJB/benzo/v_benzo.mdl")
	    set_pev(player, pev_weaponmodel2, "models/ShopJB/benzo/p_benzo.mdl")
        }

        if(read_data(2) == CSW_KNIFE  && w_machete[player])
        {
            set_pev(player, pev_viewmodel2, "models/ShopJB/Machete/v_Machete.mdl")
	    set_pev(player, pev_weaponmodel2, "models/ShopJB/Machete/p_Machete.mdl")    
        }

        if(read_data(2) == CSW_KNIFE  && w_electro[player])
        {
            set_pev(player, pev_viewmodel2, "models/ShopJB/electro/v_electro.mdl")
	    set_pev(player, pev_weaponmodel2, "models/ShopJB/electro/p_electro.mdl")    
        }
	return PLUGIN_CONTINUE
}
public ShopMenu(id)
{
   if(get_user_team(id)==1)
   {
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPT_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuT_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPT_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPT_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPT_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPT_ITEM_4" );
      menu_additem( vip_menu, szText, "4", 0 );
	  
      menu_display( id, vip_menu, 0)
   }else
   if(get_user_team(id)==2)
   {
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuCT_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );
	  
	  formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_ITEM_4" );
      menu_additem( vip_menu, szText, "4", 0 );
	  
	    formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPCT_ITEM_5" );
      menu_additem( vip_menu, szText, "5", 0 );

      menu_display( id, vip_menu, 0)
    }
}
public ShopMenuT_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
        {
            ShopMenuTequipment(id)
        }
        case 2:
        {
            ShopMenuTability(id)
        }
        case 3:
        {
            ShopMenuTequipmenty(id)
        }
        case 4:
		{
	    ShopMenuTValuta(id)
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
} 

public ShopMenuTequipment(id)
{
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuTequipment_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_4" );
      menu_additem( vip_menu, szText, "4", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_5" );
      menu_additem( vip_menu, szText, "5", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_6" );
      menu_additem( vip_menu, szText, "6", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTE_ITEM_7" );
      menu_additem( vip_menu, szText, "7", 0 );

      menu_display( id, vip_menu, 0)
}

public ShopMenuTequipment_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
        {
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=8)
               {
                  engclient_cmd(id, "weapon_knife")
                  w_machete[id] = true
                  set_pev(id, pev_viewmodel2, "models/ShopJB/Machete/v_Machete.mdl")
	          set_pev(id, pev_weaponmodel2, "models/ShopJB/Machete/p_Machete.mdl")    
                  ChatColor(id, "%L",0,"YOUR_MACHETE")  
                  g_cranii[id]=g_cranii[id]-8
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 2:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=10)
               {
                  engclient_cmd(id, "weapon_knife")
                  w_benzo[id] = true
                  set_pev(id, pev_viewmodel2, "models/ShopJB/benzo/v_benzo.mdl")
                  set_pev(id, pev_weaponmodel2, "models/ShopJB/benzo/p_benzo.mdl")    
                  ChatColor(id, "%L",0,"YOUR_BENZO") 
                  g_cranii[id]=g_cranii[id]-10
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 3:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=16)
               {
                  entity_set_int(id, EV_INT_body, 7)
                  ChatColor(id, "%L",0,"YOUR_FD") 
                  g_cranii[id]=g_cranii[id]-16
                  return PLUGIN_HANDLED
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 4:
	{
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=4)
               {
                  give_item(id, "weapon_hegrenade")
                  give_item(id, "weapon_flashbang")
                  give_item(id, "weapon_flashbang")
                  give_item(id, "weapon_smokegrenade")
                  ChatColor(id, "%L",0,"YOUR_GRENADE")
                  g_cranii[id]=g_cranii[id]-4
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 5:
	{
            if(is_user_alive(id))
	    {
               if(g_cranii[id]>=16)
               {
	          entity_set_int(id, EV_INT_body, 3)
                  ChatColor(id, "%L",0,"YOUR_MASK")
                  g_cranii[id]=g_cranii[id]-16
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
	    }
        }
        case 6:
	{
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=8)
               {
                  give_item(id, "weapon_shield")
                  ChatColor(id, "%L",0,"YOUR_SHIELD")
                  g_cranii[id]=g_cranii[id]-8
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 7:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=10)
               {
                  client_cmd(id, "set_micro_cheper")
                  ChatColor(id, "%L",0,"YOUR_MICRO") 
                  g_cranii[id]=g_cranii[id]-10
                  return PLUGIN_HANDLED
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
} 

public ShopMenuTability(id)
{
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuTability_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_ITEM_4" );
      menu_additem( vip_menu, szText, "4", 0 );
      
      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTA_ITEM_5" );
      menu_additem( vip_menu, szText, "5", 0 );

      menu_display( id, vip_menu, 0)
}

public ShopMenuTability_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
        {
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=16)
               {
                  set_user_gravity(id, 0.2)
                  ChatColor(id, "%L",0,"YOUR_GRAVITY")  
                  g_cranii[id]=g_cranii[id]-16
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 2:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=15)
               {
                  set_user_maxspeed(id, 500.0)
                  ChatColor(id, "%L",0,"YOUR_SPEED")  
                  g_cranii[id]=g_cranii[id]-15
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 3:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=14)
               {
                  set_user_health(id, 255)
                  ChatColor(id, "%L",0,"YOUR_HP") 
                  g_cranii[id]=g_cranii[id]-14
                  return PLUGIN_HANDLED
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 4:
	{
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=12)
               {
                  set_user_armor(id, 255)
                  ChatColor(id, "%L",0,"YOUR_ARMOR") 
                  g_cranii[id]=g_cranii[id]-12
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
       case 5:
	{
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=7)
               {
                  set_user_footsteps(id, 1)
                  ChatColor(id, "%L",0,"YOUR_FOOTSTEPS")
                  g_cranii[id]=g_cranii[id]-7
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
} 

public ShopMenuTequipmenty(id)
{
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTEQ_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuTequipmenty_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTEQ_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTEQ_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTEQ_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );

      menu_display( id, vip_menu, 0)
}   

public ShopMenuTequipmenty_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
        {
            if( is_user_alive(id))
            {
               if(g_cranii[id]>=14)
               {
                  give_item(id, "weapon_glock18")
                  ChatColor(id, "%L",0,"YOUR_GLOCK")  
                  g_cranii[id]=g_cranii[id]-14
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 2:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=16)
               {
                  give_item(id, "weapon_tmp")
                  ChatColor(id, "%L",0,"YOUR_TMP")  
                  g_cranii[id]=g_cranii[id]-16
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 3:
        {
            if(is_user_alive(id))
            {
               if(g_cranii[id]>=15)
               {
                  give_item(id, "weapon_deagle")
                  ChatColor(id, "%L",0,"YOUR_DEAGLE") 
                  g_cranii[id]=g_cranii[id]-15
               }else{
                  ChatColor(id, "%L",0,"NOT_CHEREP")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
} 
public ShopMenuTValuta(id)

{
      new szText[ 555 char ];

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_TITLE");
      new vip_menu = menu_create( szText, "ShopMenuTValuta_handler" );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_ITEM_1" );
      menu_additem( vip_menu, szText, "1", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_ITEM_2" );
      menu_additem( vip_menu, szText, "2", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_ITEM_3" );
      menu_additem( vip_menu, szText, "3", 0 );

      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_ITEM_4" );
      menu_additem( vip_menu, szText, "4", 0 );
    
      formatex( szText, charsmax( szText ), "%L", id, "MAIN_SHOPTVAL_ITEM_5" );
      menu_additem( vip_menu, szText, "5", 0 );

      menu_display( id, vip_menu, 0)
}  
public ShopMenuTValuta_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
	    {
           if(cs_get_user_money(id)>=3200)
           {
               g_cranii[id] = g_cranii[id]+1
               cs_set_user_money(id, cs_get_user_money(id)-3200)
           }else{
                ChatColor(id, "%L",0,"NOT_MONEY")  
           }
        }
        case 2:
	    {
           if(cs_get_user_money(id)>=6400)
           {
               g_cranii[id] = g_cranii[id]+2
               cs_set_user_money(id, cs_get_user_money(id)-6400)
           }else{
                ChatColor(id, "%L",0,"NOT_MONEY")  
           }
        }
        case 3:
	    {
           if(cs_get_user_money(id)>=9600)
           {
               g_cranii[id] = g_cranii[id]+3
               cs_set_user_money(id, cs_get_user_money(id)-9600)
           }else{
                ChatColor(id, "%L",0,"NOT_MONEY")  
           }
        }
        case 4:
        {
           if(cs_get_user_money(id)>=12800)
           {
               g_cranii[id] = g_cranii[id]+4
               cs_set_user_money(id, cs_get_user_money(id)-12800)
           }else{
                ChatColor(id, "%L",0,"NOT_MONEY")  
           }
        }
         case 5:
        {
           if(cs_get_user_money(id)>=16000)
           {
               g_cranii[id] = g_cranii[id]+6
               cs_set_user_money(id, cs_get_user_money(id)-16000)
           }else{
                ChatColor(id, "%L",0,"NOT_MONEY")  
           }
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
}

public ShopMenuCT_handler( id, menu, item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu )
        return PLUGIN_HANDLED
    }
    new data[6], iName[64]
    new access, callback

    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
    new key = str_to_num( data )
    switch( key )
    {
        case 1:
        {
            if( is_user_alive(id))
            {
               if(cs_get_user_money(id)>=6000)
               {
                  engclient_cmd(id, "weapon_knife")
                  w_electro[id] = true
                  set_pev(id, pev_viewmodel2, "models/ShopJB/electro/v_electro.mdl")
	          set_pev(id, pev_weaponmodel2, "models/ShopJB/electro/p_electro.mdl")    
                  ChatColor(id, "%L",0,"YOUR_ELECTRO")  
                  cs_set_user_money(id, cs_get_user_money(id)-6000)
               }else{
                  ChatColor(id, "%L",0,"NOT_MONEY")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
        case 2:
	{
            if( is_user_alive(id))
            {
               if(cs_get_user_money(id)>=14000)
               {
                  set_user_maxspeed(id, 700.0)
                  ChatColor(id, "%L",0,"YOUR_SPEED")  
                  cs_set_user_money(id, cs_get_user_money(id)-14000)
               }else{
                  ChatColor(id, "%L",0,"NOT_MONEY")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
          case 3:
        {
            if( is_user_alive(id))
            {
               if(cs_get_user_money(id)>=10000)
               {
                  set_user_gravity(id, 0.2)
                  ChatColor(id, "%L",0,"YOUR_GRAVITY2")  
                  cs_set_user_money(id, cs_get_user_money(id)-10000)
               }else{
                  ChatColor(id, "%L",0,"NOT_MONEY")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
          case 4:
        {
            if( is_user_alive(id))
            {
               if(cs_get_user_money(id)>=12000)
               {
                  set_user_godmode(id, 1 );
				  set_task(6.0, "scoategodmode", id);
                  ChatColor(id, "%L",0,"YOUR_GODMOD")  
                  cs_set_user_money(id, cs_get_user_money(id)-12000)
               }else{
                  ChatColor(id, "%L",0,"NOT_MONEY")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
		  case 5:
        {
            if( is_user_alive(id))
            {
               if(cs_get_user_money(id)>=8000)
               {
                  set_user_health(id, 300)
				  set_user_armor(id, 250)
                  ChatColor(id, "%L",0,"YOUR_HPAR")  
                  cs_set_user_money(id, cs_get_user_money(id)-8000)
               }else{
                  ChatColor(id, "%L",0,"NOT_MONEY")  
               }
            }else{
               ChatColor(id, "%L",0,"YOUR_DEAD")  
            }
        }
    }
    menu_destroy( menu )
    return PLUGIN_HANDLED
} 
public mesajgodmode() 
{
	ChatColor(0, "^x04[Jb.Lunetistii.Ro] Pentru a cumpara ceva tasteaza /shop !");
}
public scoategodmode(id) {
	set_user_godmode(id, 0 );
	ChatColor(id, "^x04[Jb.Lunetistii.Ro] Au exiprat cele 6 secunde de godmode !");
	GodmodeFolosit[id] = true;
}

// CrowBar Drop
public Hook_DeathMessage( )
	{
	new iVictim = read_data( 2 );
	
	if( read_data( 1 ) == iVictim )
		{
		return;
	}
	
	new Float:flPlayerOrigin[ 3 ];
	pev( iVictim, pev_origin, flPlayerOrigin );
	
	flPlayerOrigin[ 2 ] += 4.0;
	
	new iEntityCB = create_entity( "info_target" );
	
	if( !pev_valid( iEntityCB ) )
		{
		return;
	}
	
	if(get_user_team(iVictim) == 1 && get_bit(g_PlayerCrowbar, iVictim))
		{
		engfunc( EngFunc_SetOrigin, iEntityCB, flPlayerOrigin )
		set_pev( iEntityCB, pev_classname, gCrowbarClassname );
		engfunc( EngFunc_SetModel, iEntityCB, gCrowbarModel );
		set_pev( iEntityCB, pev_solid, SOLID_SLIDEBOX );
		set_pev( iEntityCB, pev_movetype, MOVETYPE_NONE );
		set_pev( iEntityCB, pev_framerate, 1.0 );
		set_pev( iEntityCB, pev_sequence, CrowbarFloat );
		engfunc( EngFunc_SetSize, iEntityCB, Float:{ -10.0, -10.0, -10.0 }, Float:{ 10.0, 10.0, 10.0 } );
		engfunc( EngFunc_DropToFloor, iEntityCB );
		set_pev( iEntityCB, pev_nextthink, get_gametime( ) + 1.0 );
		set_rendering( iEntityCB, kRenderFxGlowShell, (random_num(1, 255)),  (random_num(1, 255)),  (random_num(1, 255)), kRenderNormal, 75 );
		
		clear_bit(g_PlayerCrowbar, iVictim)
	}
}

public Forward_TouchCrowbar( iEntityCB, id )
	{
	if( pev_valid( iEntityCB ) && get_user_team(id) == 1 )
		{
		engclient_cmd ( id, "weapon_knife" );
		g_CrowbarCount++
		set_bit(g_PlayerCrowbar, id)
		current_weapon(id)
		set_pev( iEntityCB, pev_flags, FL_KILLME );
	}
	/*   if( pev_valid( iEntityCB ) && get_user_team(id) == 2 )
	{
		set_pev( iEntityCB, pev_solid, SOLID_NOT );
	}*/
	
	return PLUGIN_CONTINUE;
}
public precache_keyvalue(ent, kvd_handle)
{
	static info[32]
	if(!is_valid_ent(ent))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_ClassName, info, charsmax(info))
	if(!equal(info, "multi_manager"))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_KeyName, info, charsmax(info))
	TrieSetCell(g_CellManagers, info, ent)
	return FMRES_IGNORED
}

//DaysMenu

public RoundStart()
{
	day = 0; //F*KIN script,be sure that day == 0
	g_iSpecialDay = -1;
}
public fwdTakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDmgBits)
{
	if( is_valid_player( iAttacker ) && get_user_weapon( iAttacker) == CSW_KNIFE && frezz[ iAttacker ] ) {
		if(cs_get_user_team(iAttacker) == CS_TEAM_CT)
		{
			if(cs_get_user_team(iVictim) == CS_TEAM_T)
			{
				set_pev(iVictim, pev_flags, pev(iVictim, pev_flags) | FL_FROZEN);
			}
		}
		if(cs_get_user_team(iAttacker) == CS_TEAM_T)
		{
			if(cs_get_user_team(iVictim) == CS_TEAM_T)
			{
				set_pev(iVictim, pev_flags, pev(iVictim, pev_flags) & ~FL_FROZEN);
			}
		}
	}
}
public eRoundEnd()
{
	day = 0;
	g_iSpecialDay = -1;
	remove_task()
}
public ResModel(id)
{
	new iPlayers[32], iNum, iPid;
	get_players( iPlayers, iNum, "a" );
	
	for( new i; i < iNum; i++ )
	{
		iPid = iPlayers[i];
		cs_reset_user_model(iPid)
	}
}
public cmd_daysmenu(id)
{
	
	if(g_Simon == id)
	{
		if(is_user_alive(id))
		{
			if(day == 0)
			{
				JBDay(id);
			}
			else
			{
				colored_print(id, "^x04[ManagerDays] O zi a fost deja aleasa pentru aceasta runda!^x03")
			}
		}
	}
	else
	{
		colored_print(id, "^x04[ManagerDays] Tu nu esti Simon sau este FreeDay !^x03");
	}
}
public Count()
{
	if(GodmodeDay) {
		if(g_iCountTime == 0) {
			set_user_godmode(0, 0)
		}
	}
	set_hudmessage( 0 , 255 , 0 , -1.0 , 0.28 , 2 , 1.1 , 1.1 , 0.01 , 0.01 );
	show_hudmessage( 0 , "Prizonierii au %d secunde pentru a ascunde!" , g_iCountTime-- );
}

public JBDay(id)
{
	new menu = menu_create("DaysMenu Jb.Lunetistii.Ro", "menu_handler");
	
	menu_additem(menu, "Zombie Day", "1", 0);
	menu_additem(menu, "Spartan Day", "2", 0);
	menu_additem(menu, "Gravity Day", "3", 0);
	menu_additem(menu, "NightCrawler Day", "4", 0);
	menu_additem(menu, "Knife Day", "5", 0);
	menu_additem(menu, "War Day", "6", 0);
	menu_additem(menu, "HNS Day", "7", 0);
	menu_additem(menu, "Noclip Day", "8", 0);
	menu_additem(menu, "GodMode Day", "9", 0);
	menu_additem(menu, "Magic Day", "10", 0);
	menu_additem(menu, "Tag Day", "11", 0);
	menu_additem(menu, "DodgeBall Day", "12", 0);
	menu_additem(menu, "Grenade Day", "13", 0);
	menu_additem(menu, "Ramboo Day", "14", 0);
	menu_additem(menu, "1HP Day", "15", 0);
	menu_additem(menu, "Reverse Zombie Day", "16", 0);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public menu_handler(id, menu, item)
{
	
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1:
		{
			ZombieDay(id)
			g_iSpecialDay = 0;
			ResModel(id)
			day = 1;
			frezz[id] = false
		}
		case 2:
		{
			SpartanDay(id)
			g_iSpecialDay = 1;
			day = 1;
			frezz[id] = false
		}
		case 3:
		{
			Gravity(id)
			g_iSpecialDay = 2;
			day = 1;
			frezz[id] = false
		}
		case 4:
		{
			NightDay(id)
			g_iSpecialDay = 3;
			day = 1;
			frezz[id] = false
		}
		case 5:
		{
			KnifeDay(id)
			g_iSpecialDay = 4;
			day = 1;
			frezz[id] = false
		}
		case 6:
		{
			WarDay(id)
			g_iSpecialDay = 5;
			day = 1;
			frezz[id] = false
		}
		case 7:
		{
			HideDay(id)
			g_iSpecialDay = 6;
			day = 2;
			frezz[id] = false
		}
		case 8:
		{
			SharkDay(id)
			g_iSpecialDay = 7;
			day = 2;
			frezz[id] = false
		}
		case 9:
		{
			Godmode(id)
			g_iSpecialDay = 8;
			day = 2;
			frezz[id] = false
		}
		case 10:
		{
			MagicDay(id)
			g_iSpecialDay = 9;
			day = 2;
			frezz[id] = false
		}
		case 11:
		{
			TagDay(id)
			g_iSpecialDay = 10;
			day = 1;
			frezz[id] = false
		}
		case 12:
		{
			DodgeballDay(id)
			g_iSpecialDay = 11;
			day = 1;
			frezz[id] = false
        }
		case 13:
		{
			grenade(id)
			g_iSpecialDay = 12;
			day = 1;
			frezz[id] = false
		}
		case 14:
		{
			RamboDay(id) 
			g_iSpecialDay = 13;
			day = 1;
			frezz[id] = false
		}
		case 15:
		{
			hpg(id)
			g_iSpecialDay = 14;
			day = 1;
			frezz[id] = false
		}
		case 16:
		{
			RevZombie(id)
			g_iSpecialDay = 15;
			day = 1;
			frezz[id] = false
		}
		
	}
	
	ShowSpecialHudDay( id );
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public SharkDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: NoClip Day")
		
		
		colored_print(id, "^x04%s^x01 Astazi este Noclip Day !", PREFIX)
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_health(id, 250);
			set_user_noclip (id, true);
		}
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_health(id, 100);
			fm_give_item(id, "weapon_ak47")
			cs_set_user_bpammo( id, CSW_AK47, 300 );
			fm_give_item(id, "weapon_deagle");
			cs_set_user_bpammo( id, CSW_DEAGLE, 200 );
			
		}
		
	}
}

public NightDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: NightCrawler Day")
		
		colored_print(id, "^x04%s^x01 Astazi este NightCrawler Day !", PREFIX)
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_health(id, 150);
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
			
		}
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_health(id, 100);
			fm_give_item(id, "weapon_ak47")
			cs_set_user_bpammo( id, CSW_AK47, 300 );
			fm_give_item(id, "weapon_deagle");
			cs_set_user_bpammo( id, CSW_DEAGLE, 200 );
			
		}
		
	}
}
public ZombieDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: Zombie Day")
		
		colored_print(id, "^x04%s^x01 Virusul este scapat de sub control!^x04 Prizonierii^x01 au fost infectati!", PREFIX)
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		
		
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			fm_give_item(id, "weapon_ak47")
			fm_give_item(id, "weapon_m4a1")
			fm_give_item(id, "weapon_deagle")
			cs_set_user_bpammo( id, CSW_AK47, 999 );
			cs_set_user_bpammo( id, CSW_M4A1, 999 );
			cs_set_user_bpammo( id, CSW_DEAGLE, 999 );
			set_user_health(id, 500)
			
		}
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_health(id, 3000);
			give_jump_bomb(id);
			give_conc_bomb(id);
			
		}
		
	}
}

public SpartanDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if(cs_get_user_team(id) == CS_TEAM_T)
		{
			
		}
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: Spartan Day")
		
		colored_print(id, "^x04%s^x01 Astazi vom juca in stil^x04 spartan !", PREFIX)
		
		if(cs_get_user_team(id) == CS_TEAM_T)
		{
			fm_give_item( id, "weapon_knife" )
			fm_give_item( id, "weapon_deagle")
			fm_give_item( id, "weapon_shield")
			cs_set_user_bpammo( id, CSW_DEAGLE, 200 );
			set_user_health(id, 200);
		}
		
	}
}

public KnifeDay(id)
{
	
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive(id) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: Knife Day")
		
		colored_print(id, "^x04%s^x01 Knife^x04 Day^x01, esti pregatit ?", PREFIX)
		
		
		fm_give_item( id, "weapon_knife" )
		set_user_health(id, 100);
	}
}

public WarDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
		show_hudmessage(id, "Astazi este: War Day")
		
		colored_print(id, "^x04%s^x01 Astazi vom juca^x04 War Day^x01. Cel mai bun mod de castig este munca in^x03 echipa!", PREFIX)
		
		
		fm_give_item(id, "weapon_knife")
		fm_give_item( id, "weapon_deagle")
		fm_give_item(id, "weapon_ak47")
		fm_give_item(id, "weapon_awp")
		fm_give_item(id, "weapon_m4a1")
		cs_set_user_bpammo( id, CSW_DEAGLE, 999 )
		cs_set_user_bpammo( id, CSW_AK47, 999 )
		cs_set_user_bpammo( id, CSW_AWP, 999 )
		cs_set_user_bpammo( id, CSW_M4A1, 999 )
		set_user_health(id, 150)
	}
}
public HideDay(id)
{
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: HNS Day")
	
	colored_print(id, "^x04%s^x01 Azi vom juca^x04  HNS Day.^x03 Prizonieri^x01, ascundeti-va! Ai^x04 90^x01 de secunde!", PREFIX)
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		
		fm_give_item( id, "weapon_knife" )
		set_task(90.0, "reset", id)
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})      
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN); 
			set_user_godmode(id, true);
			Fade_To_Black(id)
		}   
	}
	g_iCountTime = CountSeconds;
	set_task( 1.0 , "Count" , _ , _ , _ , "a" , g_iCountTime );
}
public Godmode(id)
{
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: GodMode Day")
	
	colored_print(id, "^x04%s Astazi este^x04 GodMode.", PREFIX)
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_godmode(id,1);
	        set_user_godmode(id,1);
		    
		    fm_give_item( id, "weapon_knife" )
		    fm_give_item( id, "weapon_deagle" )
            cs_set_user_bpammo( id, CSW_DEAGLE, 35 )
		}
	}
}
public MagicDay(id)
{
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		give_rifle(id)
		
		fm_give_item( id, "weapon_knife" )
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_health(id, 200);
		}
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_health(id, 100);
		}
	}
}
public Gravity(id)
{
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Gravity Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 Gravity Day !.", PREFIX)
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		set_user_gravity(id, 0.375);
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			fm_give_item( id, "weapon_deagle" )
			cs_set_user_bpammo( id, CSW_DEAGLE, 999 )
			set_user_gravity(id, 0.375);
		}
	}
}
public grenade(id)
{
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Grenade Day")
	
	colored_print(id, "^x04%s^x01 Astati este^x04 Grenade Day !.", PREFIX)
	new iPlayers[32]
	new iNum
	new id
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		id = iPlayers[i]
		if( !is_user_alive( id ) )
		{
			continue;
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		fm_give_item( id, "weapon_knife" )
		fm_give_item( id, "weapon_grenade" )
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			fm_give_item( id, "weapon_hegrenade" )
			cs_set_user_bpammo( id, CSW_HEGRENADE, 200 ); 
		}
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			fm_give_item( id, "weapon_hegrenade" )
			cs_set_user_bpammo( id, CSW_HEGRENADE, 200 ); 
		}
	}
}
public RamboDay(id) 
{ 
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Ramboo Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 Ramboo Day !.", PREFIX)
	new iPlayers[32] 
	new iNum 
	new id 
	
	get_players( iPlayers, iNum ) 
	
	for( new i = 0; i < iNum; i++ ) 
	{ 
		id = iPlayers[i] 
		if( !is_user_alive( id ) ) 
		{ 
			continue; 
		}
		 
		 player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		 
		
		fm_give_item( id, "weapon_knife" ) 
		
		if (cs_get_user_team(id) == CS_TEAM_CT) 
		{ 
			fm_give_item(id, "weapon_m4a1")
            fm_give_item(id, "weapon_ak47") 			
			cs_set_user_bpammo( id, CSW_M4A1, 999 );
			cs_set_user_bpammo( id, CSW_AK47, 999 );
			set_user_health(id, 150); 
		} 
		
		if (cs_get_user_team(id) == CS_TEAM_T) 
		{ 
			fm_give_item(id, "weapon_m249") 
			cs_set_user_bpammo( id, CSW_M249, 999 ); 
			set_user_health(id, 100); 
		} 
	} 
}
public hpg(id) 
{ 
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: 1Hp Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 1Hp Day !.", PREFIX)
	new iPlayers[32] 
	new iNum 
	new id 
	
	get_players( iPlayers, iNum ) 
	
	for( new i = 0; i < iNum; i++ ) 
	{ 
		id = iPlayers[i] 
		if( !is_user_alive( id ) ) 
		{ 
			continue; 
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		 
		
		fm_give_item( id, "weapon_knife" ) 
		
		if (cs_get_user_team(id) == CS_TEAM_CT) 
		{ 
			set_user_health(id, 25); 
		} 
		
		if (cs_get_user_team(id) == CS_TEAM_T) 
		{ 
			set_user_health(id, 1); 
		} 
	} 
}
public TagDay(id) 
{ 
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Tag Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 Tag Day !.", PREFIX)
	new iPlayers[32] 
	new iNum 
	new id 
	
	get_players( iPlayers, iNum ) 
	
	for( new i = 0; i < iNum; i++ ) 
	{ 
		id = iPlayers[i] 
		if( !is_user_alive( id ) ) 
		{ 
			continue; 
		}
		 
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		
		fm_give_item( id, "weapon_knife" ) 
		
		if (cs_get_user_team(id) == CS_TEAM_CT) 
		{ 
			set_user_health(id, 100);
			jb_starttag()
		} 
		
		if (cs_get_user_team(id) == CS_TEAM_T) 
		{ 
			set_user_health(id, 100); 
		} 
	} 
}
public DodgeballDay(id) 
{ 
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Dodgeball Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 Dodgeball Day !.", PREFIX)
	new iPlayers[32] 
	new iNum 
	new id 
	
	get_players( iPlayers, iNum ) 
	
	for( new i = 0; i < iNum; i++ ) 
	{ 
		id = iPlayers[i] 
		if( !is_user_alive( id ) ) 
		{ 
			continue; 
		}
		 
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		 
		
		fm_give_item( id, "weapon_knife" ) 
		
		if (cs_get_user_team(id) == CS_TEAM_CT) 
		{ 
			set_user_health(id, 100);
			jb_game_killball()
		} 
		
		if (cs_get_user_team(id) == CS_TEAM_T) 
		{ 
			set_user_health(id, 100); 
		} 
	} 
}
public RevZombie(id) 
{ 
	set_hudmessage(255, 0, 42, 0.0, 0.14, 0, 6.0, 10.0)
	show_hudmessage(id, "Astazi este: Reverse Zombie Day")
	
	colored_print(id, "^x04%s^x01 Astazi este^x04 Reversse Zombie Day !.", PREFIX)
	new iPlayers[32] 
	new iNum 
	new id 
	
	get_players( iPlayers, iNum ) 
	
	for( new i = 0; i < iNum; i++ ) 
	{ 
		id = iPlayers[i] 
		if( !is_user_alive( id ) ) 
		{ 
			continue; 
		}
		
		player_strip_weapons(id)
		g_BlockWeapons = 1
		g_LastDenied = 1
		
		
		fm_give_item( id, "weapon_knife" ) 
		
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_health(id, 3000);
			give_jump_bomb(id);
			give_conc_bomb(id);
		}
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			fm_give_item(id, "weapon_ak47")
			fm_give_item(id, "weapon_m4a1")
			fm_give_item(id, "weapon_deagle")
			cs_set_user_bpammo( id, CSW_AK47, 999 );
			cs_set_user_bpammo( id, CSW_M4A1, 999 );
			cs_set_user_bpammo( id, CSW_DEAGLE, 999 );
			set_user_health(id, 500)
		} 
	} 
}
public ShowSpecialHudDay( id ) {
	if( g_iSpecialDay >= 0 ) {
	        set_hudmessage ( 0, 176, 0, 0.0, 0.15, 0, 6.0, 3.0, _, _, 1 );
		show_hudmessage( 0, " %s Day", g_szDaysText[ g_iSpecialDay ] );
		set_task( 1.0, "ShowSpecialHudDay" );
	}
	return PLUGIN_HANDLED;
}

colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= get_maxplayers(); player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
public Fade_To_Black(id)
{
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id)
	write_short((1<<3)|(1<<8)|(1<<10))
	write_short((1<<3)|(1<<8)|(1<<10))
	write_short((1<<0)|(1<<2))
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()
	
}
public Reset_Screen(id)
{
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id)
	write_short(1<<2)
	write_short(0)
	write_short(0)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	message_end()
	
}
public reset(id)
{
	if (cs_get_user_team(id) == CS_TEAM_CT)
	{
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
		Reset_Screen(id)
	}
	if (cs_get_user_team(id) == CS_TEAM_T)
	{    
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
	}
}


public client_putinserver(id)
{
	clear_bit(g_PlayerJoin, id)
	clear_bit(g_PlayerHelp, id)
	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerNomic, id)
	clear_bit(g_PlayerWanted, id)
	clear_bit(g_SimonTalking, id)
	clear_bit(g_SimonVoice, id)
	g_PlayerSpect[id] = 0
	g_PlayerSimon[id] = 0
	g_cranii[id] = get_pcvar_num(g_startcranii) 
	set_task(1.0, "CraniiPack", id, _, _, "b")
}
public Spawn_player(id)
{
   if(is_user_alive(id) && is_user_connected(id))
   {
      w_machete[id] = false
      w_benzo[id] = false
      ++g_cranii[id]
   }
}
public CraniiPack(id)
{
	set_hudmessage( 142, 239, 39, -1.1, 0.60, 0, 6.0, 1.2);
	ShowSyncHudMsg(id, syncObj,"Credite = [%i]", g_cranii[id])
}
public client_connect( id )
{
   g_cranii[id] = 2
}

public client_disconnect(id)
{
	if(g_Simon == id)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
	player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_HASGONE")
	}
	else if(g_PlayerLast == id || (g_Duel && (id == g_DuelA || id == g_DuelB)))
	{
		g_Duel = 0
		g_DuelA = 0
		g_DuelB = 0
		g_LastDenied = 0
		g_BlockWeapons = 0
		g_PlayerLast = 0
	}
	team_count()
}

public client_PostThink(id)
{
	if(id != g_Simon || !gc_SimonSteps || !is_user_alive(id) ||
		!(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) || entity_get_int(id, EV_ENT_groundentity))
		return PLUGIN_CONTINUE
	
	static Float:origin[3]
	static Float:last[3]

	entity_get_vector(id, EV_VEC_origin, origin)
	if(get_distance_f(origin, last) < 32.0)
	{
		return PLUGIN_CONTINUE
	}

	vec_copy(origin, last)
	if(entity_get_int(id, EV_INT_bInDuck))
		origin[2] -= 18.0
	else
		origin[2] -= 36.0


	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
	write_byte(TE_WORLDDECAL)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(105)
	message_end()

	return PLUGIN_CONTINUE
}

 
public msg_statustext(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public msg_statusicon(msgid, dest, id)
{
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z')
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_vguimenu(msgid, dest, id)
{
	static msgarg1
	static CsTeams:team

	msgarg1 = get_msg_arg_int(1)
	if(msgarg1 == 2)
	{
		team = cs_get_user_team(id)
		if((team == CS_TEAM_T) && !is_user_admin(id) && (is_user_alive(id) || !get_pcvar_num(gp_TeamChange)))
		{
			client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
			return PLUGIN_HANDLED
		}
		show_menu(id, 51, TEAM_MENU, -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_showmenu(msgid, dest, id)
{
	static msgarg1, roundloop
	static CsTeams:team
	msgarg1 = get_msg_arg_int(1)

	if(msgarg1 != 531 && msgarg1 != 563)
		return PLUGIN_CONTINUE

	roundloop = floatround(get_pcvar_float(gp_RetryTime) / 2)
	team = cs_get_user_team(id)

	if(team == CS_TEAM_T)
	{
		if(!is_user_admin(id) && (is_user_alive(id) || (g_RoundStarted >= roundloop) || !get_pcvar_num(gp_TeamChange)))
		{
			client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
			return PLUGIN_HANDLED
		}
		else
		{
			show_menu(id, 51, TEAM_MENU, -1)
			return PLUGIN_HANDLED
		}
	}
	else
	{
		show_menu(id, 51, TEAM_MENU, -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_motd(msgid, dest, id)
{
	if(get_pcvar_num(gp_Motd))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public current_weapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(get_bit(g_PlayerCrowbar, id))
	{
		set_pev(id, pev_viewmodel2, _CrowbarModels[1])
		set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
	}
	else
	{
		set_pev(id, pev_viewmodel2, _FistModels[1])
		set_pev(id, pev_weaponmodel2, _FistModels[0])
	}
	return PLUGIN_CONTINUE
}

public HookPlayerSpawn ( const id )
	{
	if ( get_user_team ( id ) == 2 )
		{
		give_item ( id, "weapon_knife" );
		engclient_cmd ( id, "weapon_knife" );
	}
}

public HookCurWeapon ( id )
	{
	if ( get_user_team ( id ) != 2 )
		return 0;
	
	if ( read_data ( 2 ) != CSW_KNIFE )
		return 0;
	
	entity_set_string ( id, EV_SZ_viewmodel, gs_ViewModel );
	entity_set_string ( id, EV_SZ_weaponmodel, gs_WeaponModel );
	return 0;
}

public player_status(id)
{
	static type, player, CsTeams:team, name[32], health
	type = read_data(1)
	player = read_data(2)
	switch(type)
	{
		case(1):
		{
			ClearSyncHud(id, g_HudSync[1][_hudsync])
		}
		case(2):
		{
			team = cs_get_user_team(player)
			if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
				return PLUGIN_HANDLED

			health = get_user_health(player)
			get_user_name(player, name, charsmax(name))
			player_hudmessage(id, 4, 2.0, {0, 255, 255}, "%L", LANG_SERVER,
				(team == CS_TEAM_T) ? "JBE_PRISONER_STATUS" : "JBE_GUARD_STATUS", name, health)
		}
	}
	
	return PLUGIN_HANDLED
}

public impulse_100(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}
public cmd_simonmenu(id)
	{	
	if (g_Simon == id)
		{
		static menu, menuname[32], option[64]
		
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JB_MENU_SIMONMENU")
		menu = menu_create(menuname, "simon_choice")
		
		formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_OPEN")
		menu_additem(menu, option, "1", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_FD")
		menu_additem(menu, option, "2", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_BOX")
	        menu_additem(menu, option, "3", 0)
			
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_MUSIC")
	        menu_additem(menu, option, "4", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_DAYS")
		menu_additem(menu, option, "5", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_FOOTBALL")
		menu_additem(menu, option, "6", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_RESET")
		menu_additem(menu, option, "7", 0)
		
		formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "JB_MENU_SIMONMENU_REVIVE")
		menu_additem(menu, option, "8", 0)
		
		formatex(option, charsmax(option), "%L",LANG_SERVER, "JB_MENU_2_SIMONMENU")
		menu_additem(menu, option, "9", 0)
		
		menu_display(id, menu)	
	}
	else {
		client_print( id, print_chat, "*** Nu esti SIMON deci nu poti accesa SIMON MENU !");
	}
	return PLUGIN_HANDLED
}
public simon_choice(id, menu, item)
	{
	if(item == MENU_EXIT || !(id == g_Simon) )
		{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], access, callback
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	get_user_name(id, dst, charsmax(dst))
	
	switch(data[0])
	{
		case('1'): 
		{
			jail_open()
                        emit_sound(0, CHAN_AUTO, "jbsounds/jb_open.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			cmd_simonmenu(id)
		}
		case('2'): cmd_freeday(id)
		case('3'): cmd_boxmenu(id)
		case('4'): 
		{
		cmd_meniusounduri(id)
		}		
		case('5'): 
                {
			client_cmd(id,"say /days")
		}
		case('6'): 
               {
                open_football_menu(id)
		}
		case('7'): 
                {
			cmd_simonreset(id)
		}
		case('8'): 
		{
			cmd_simonrevive(id)
		}
		case('9'): 
		{
			//cmd_menu2_2(id)
		}
	}		
	return PLUGIN_HANDLED
}
public cmd_meniusounduri(id)
{
     new menu = menu_create( "Meniu Sounduri", "sound_handler" );
     
     menu_additem(menu, "Ding", "1", 0); 
     menu_additem(menu, "Melodii", "2", 0);
    
     menu_setprop( menu, MPROP_EXITNAME, "Exit")
     menu_display( id, menu, 0);
}
public sound_handler(id, menu ,item)
{
 if( item == MENU_EXIT )
     {    
          menu_destroy( menu );
          return PLUGIN_HANDLED;
     }

     new data[ 6 ], iName[ 64 ], access, callback;
     menu_item_getinfo( menu, item, access, data, charsmax( data ), iName, charsmax( iName ), callback );

     new key = str_to_num( data );
	
     switch( key )
     {
          case 1:
          {
          emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	      cmd_meniusounduri(id)
          }
          case 2:
          {
          cmd_music(id)
          }
     }
      return PLUGIN_HANDLED
}

public cmd_music(id)
	{
	if(id == g_Simon)
		{
		static menu, menuname[32], option[64]
		
		formatex(menuname, charsmax(menuname), "\y%L", LANG_SERVER, "JBE_MUSIC_MENU")
		menu = menu_create(menuname, "music_handler")
		
		formatex(option, charsmax(option), "\w%L", LANG_SERVER, "JBE_MUSIC1")
		menu_additem(menu, option, "1", 0)
		
		formatex(option, charsmax(option), "\w%L", LANG_SERVER, "JBE_MUSIC2")
		menu_additem(menu, option, "2", 0)
		
		formatex(option, charsmax(option), "\w%L", LANG_SERVER, "JBE_MUSIC3")
		menu_additem(menu, option, "3", 0)

			
		formatex(option, charsmax(option), "\w%L", LANG_SERVER, "JBE_STOP")
		menu_additem(menu, option, "9", 0)
		
		menu_display(id, menu)
	}
}
public music_handler(id,menu,item)
	{
	if(item == MENU_EXIT)
		{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], access, callback
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	get_user_name(id, dst, charsmax(dst))
	
	switch(data[0])
	{
		case('1'):
		{
	        client_cmd(0, "mp3 play sound/jbsounds/Florin1.mp3")
	        set_hudmessage(20, 255, 20, -1.0, 0.17, 1, 0.0, 5.0, 15.0, 1.0, -1)
	        show_hudmessage(0, "!!!Simon a pornit MUZICA!!!")
	        cmd_music(id)
		}
		
		case('2'):
		{
	        client_cmd(0, "mp3 play sound/jbsounds/ST1.mp3")
	        set_hudmessage(20, 255, 20, -1.0, 0.17, 1, 0.0, 5.0, 5.0, 1.0, -1)
	        show_hudmessage(0, "!!!Simon a pornit MUZICA!!!")
	        cmd_music(id)
		}
		
		case('3'):
		{
	        client_cmd(0, "mp3 play sound/jbsounds/Susa1.mp3")
	        set_hudmessage(20, 255, 20, -1.0, 0.17, 1, 0.0, 5.0, 5.0, 1.0, -1)
	        show_hudmessage(0, "!!!Simon a pornit MUZICA!!!")
	        cmd_music(id)
		}				
		case('4'):
		{
	        client_cmd(0,"mp3 stop")
	        set_hudmessage(49, 119, 11, 0.42, 0.32, 0, 6.0, 10.0)
	        show_hudmessage(id, "!!!Simon a inchis MUZICA!!!")
	        cmd_music(id)
			
		}
	}
	return PLUGIN_HANDLED
}
/*
public cmd_menu2_2(id)
{
     new menu = menu_create( "Meniu 2 SimonMenu v1.2.3", "cmd_menu_2_2_handler" );
     
     menu_additem(menu, "Scoate Wanted-ul la un prizonier", "1", 0); 
     menu_additem(menu, "Meniu HP Prizonieri", "2", 0);
    
     menu_setprop( menu, MPROP_EXITNAME, "Exit")
     menu_display( id, menu, 0);
}
public cmd_menu_2_2_handler(id, menu ,item)
{
 if( item == MENU_EXIT )
     {    
          menu_destroy( menu );
          return PLUGIN_HANDLED;
     }

     new data[ 6 ], iName[ 64 ], access, callback;
     menu_item_getinfo( menu, item, access, data, charsmax( data ), iName, charsmax( iName ), callback );

     new key = str_to_num( data );
	
     switch( key )
     {
          case 1:
          {
          cmd_wanted_remove(id)
          }
          case 2:
          {
          cmd_hp_menu_t(id)
          }
     }
      return PLUGIN_HANDLED
}

GetPlayersNum( iTeam, iAlive )
{
        new iPlayersNum;
 
        for( new iPlayers = get_maxplayers( ); iPlayers > 0; iPlayers-- )
        {
                if( !is_user_connected( iPlayers ) )
                        continue;
 
                if( get_user_team( iPlayers ) == iTeam && ( is_user_alive( iPlayers ) == iAlive || iAlive == 2 ) )
                {
                        iPlayersNum++;
                }
        }
 
        return iPlayersNum;
}
public cmd_wanted_remove(id)
{
	if(GetPlayersNum(1, 1) < 1)
	{
		ChatColor(id, "%L", id, "NO_WANTED", JB_PREFIX)
		return PLUGIN_HANDLED
	}
	new i_Menu = menu_create("\yCui??", "remove_wanted_handler")
	new s_Players[32], i_Num, i_Player
	new s_Name[32], s_Player[10]
	
	get_players(s_Players, i_Num)
	
	for (new i; i < i_Num; i++)
	{ 
		i_Player = s_Players[i]
	
		if(is_user_alive(i_Player) && id != i_Player && get_user_team(i_Player) == 1 && get_bit(g_PlayerWanted, i_Player))
		{
			get_user_name(i_Player, s_Name, charsmax(s_Name))
			num_to_str(i_Player, s_Player, charsmax(s_Player))

			menu_additem(i_Menu, s_Name, s_Player, 0)
		}
	}
	menu_display(id, i_Menu, 0)
	return PLUGIN_HANDLED
}

public cmd_wanted_remove_handler(id, i_Menu, item)
{
	if(item == MENU_EXIT || g_Simon != id)
	{
		menu_destroy(i_Menu)
		return PLUGIN_HANDLED
	}

	new s_Data[6], s_Name[64], i_Access, i_Callback
	menu_item_getinfo(i_Menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback)

	new i_Player = str_to_num(s_Data)

	new name[32], name_player[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(i_Player, name_player, charsmax(name_player))

	if(g_Simon == id && id != i_Player && is_user_alive(i_Player) && get_user_team(i_Player) == 1 && get_bit(g_PlayerWanted, i_Player))
	{
		set_hudmessage(0, 255, 255, -1.0, 0.74, 0, 6.0, 8.0)
		show_hudmessage(0, "%L", id, "CLEAR_WANTED_LIST", name, name_player)

		clear_bit(g_PlayerWanted, i_Player)
		set_pev(i_Player, pev_skin, random_num(0, 4))
		g_WantedNum--
	}

	menu_destroy(i_Menu)
	return PLUGIN_HANDLED
}

public cmd_hp_menu_t(id)
{
	if(GetPlayersNum(1, 1) < 1)
	{
		ChatColor(id, "%L", id, "HAVENT_PIRSONERS", JB_PREFIX)
		return PLUGIN_HANDLED
	}
	new Buffer[512]
	formatex(Buffer, charsmax(Buffer), "%L", id, "WHO_CURE")
	new i_Menu = menu_create(Buffer, "cure_handler")

	new s_Players[32], i_Num, i_Player
	new s_Name[32], s_Player[10]
	
	get_players(s_Players, i_Num)
	
	for (new i; i < i_Num; i++)
	{ 
		i_Player = s_Players[i]
	
		if(is_user_alive(i_Player) && id != i_Player && get_user_team(i_Player) == 1 && get_user_health(i_Player) < 100)
		{
			get_user_name(i_Player, s_Name, charsmax(s_Name))
			num_to_str(i_Player, s_Player, charsmax(s_Player))
			
			formatex(Buffer, charsmax(Buffer), "%s \r[ HP: %d ]", s_Name, get_user_health(i_Player))
			menu_additem(i_Menu, Buffer, s_Player, 0)
		}
	}
	menu_display(id, i_Menu, 0)
	return PLUGIN_HANDLED
}

public cmd_hp_menu_t_handler(id, i_Menu, item)
{
	if(item == MENU_EXIT || g_Simon != id)
	{
		menu_destroy(i_Menu)
		return PLUGIN_HANDLED
	}

	new s_Data[6], s_Name[64], i_Access, i_Callback
	menu_item_getinfo(i_Menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback)

	new i_Player = str_to_num(s_Data)

	new name[32], name_player[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(i_Player, name_player, charsmax(name_player))

	if(g_Simon == id && id != i_Player && is_user_alive(i_Player) && get_user_team(i_Player) == 1 && get_user_health(i_Player) < 100)
	{
		ChatColor(0, "%L", id, "CURED_PIRSONERS", JB_PREFIX, name, name_player)
		set_user_health(i_Player, 100)
	}

	menu_destroy(i_Menu)
	return PLUGIN_HANDLED
}*/


public player_spawn(id)
{
	static CsTeams:team

	if(!is_user_connected(id))
		return HAM_IGNORED

	set_pdata_float(id, m_fNextHudTextArgsGameTime, get_gametime() + 999999.0)
	player_strip_weapons(id)
	if(g_RoundEnd)
	{
		g_RoundEnd = 0
		g_JailDay++
	}

	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)

	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerWanted, id)
	team = cs_get_user_team(id)

	switch(team)
	{
		case(CS_TEAM_T):
		{
			g_PlayerLast = 0
			if(!g_PlayerReason[id])
				g_PlayerReason[id] = random_num(1, 6)

			player_hudmessage(id, 0, 5.0, {255, 0, 255}, "%L %L", LANG_SERVER, "JBE_PRISONER_REASON",
				LANG_SERVER, g_Reasons[g_PlayerReason[id]])

			set_user_info(id, "model", "jb_lunetistii_v2")
			entity_set_int(id, EV_INT_body, 2)
			if(is_freeday() || get_bit(g_FreedayAuto, id))
			{
				freeday_set(0, id)
				clear_bit(g_FreedayAuto, id)
			}
			else
			{
				entity_set_int(id, EV_INT_skin, random_num(0, 2))
			}

			if(g_CrowbarCount < get_pcvar_num(gp_CrowbarMax))
			{
				if(random_num(0, g_MaxClients) > (g_MaxClients / 2))
				{
					g_CrowbarCount++
					set_bit(g_PlayerCrowbar, id)
				}
			}
			cs_set_user_armor(id, 0, CS_ARMOR_NONE)
		}
		case(CS_TEAM_CT):
		{
			g_PlayerSimon[id]++
			set_user_info(id, "model", "jb_lunetistii_v2")
			entity_set_int(id, EV_INT_body, 3)
			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
		}
	}
	first_join(id)
	return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED

	switch(g_Duel)
	{
		case(0):
		{
			if(attacker == ent && get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker) && cs_get_user_team(victim) != CS_TEAM_T)
			{
				SetHamParamFloat(4, damage * gc_CrowbarMul)
				return HAM_OVERRIDE
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		default:
		{
			if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
				return HAM_IGNORED
	
			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

public player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	static CsTeams:vteam, CsTeams:ateam
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED

	vteam = cs_get_user_team(victim)
	ateam = cs_get_user_team(attacker)

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_CT)
		return HAM_SUPERCEDE

	switch(g_Duel)
	{
		case(0):
		{
			if(ateam == CS_TEAM_CT && vteam == CS_TEAM_T)
			{
				if(get_bit(g_PlayerRevolt, victim))
				{
					clear_bit(g_PlayerRevolt, victim)
					hud_status(0)
				}
				return HAM_IGNORED
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		default:
		{
			if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
				return HAM_IGNORED

			return HAM_SUPERCEDE
		}
	}

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_T && !g_BoxStarted)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT)
	{
		if(!g_PlayerRevolt)
			revolt_start()
		set_bit(g_PlayerRevolt, attacker)
	}

	return HAM_IGNORED
}

public button_attack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(is_valid_ent(button) && gc_ButtonShoot)
	{
		ExecuteHamB(Ham_Use, button, id, 0, 2, 1.0)
		entity_set_float(button, EV_FL_frame, 0.0)
	}

	return HAM_IGNORED
}

public player_jb_killed(victim, attacker, shouldgib)
{
	static CsTeams:vteam, CsTeams:kteam
	if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
		kteam = CS_TEAM_UNASSIGNED
	else
		kteam = cs_get_user_team(attacker)

	vteam = cs_get_user_team(victim)
	if(g_Simon == victim)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
		player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_KILLED")
                emit_sound(0, CHAN_AUTO, "jbsounds/jb_kill.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	switch(g_Duel)
	{
		case(0):
		{
			switch(vteam)
			{
				case(CS_TEAM_CT):
				{
					if(kteam == CS_TEAM_T && !get_bit(g_PlayerWanted, attacker))
					{
						set_bit(g_PlayerWanted, attacker)
						entity_set_int(attacker, EV_INT_skin, 4)
                                                emit_sound(0, CHAN_AUTO, "jbsounds/jb_kill.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					}
				}
				case(CS_TEAM_T):
				{
					clear_bit(g_PlayerRevolt, victim)
					clear_bit(g_PlayerWanted, victim)
				}
			}
		}
		default:
		{
			if(g_Duel != 4 && (attacker == g_DuelA || attacker == g_DuelB))
			{
				set_user_rendering(victim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				g_Duel = 0
				g_LastDenied = 0
				g_BlockWeapons = 0
				g_PlayerLast = 0
				team_count()
			}
		}
	}
	hud_status(0)
	return HAM_IGNORED
}

public player_touchweapon(id, ent)
{
	static model[32], class[32]
	if(g_BlockWeapons)
		return HAM_SUPERCEDE

	if(is_valid_ent(id) && g_Duel != 6 && is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		entity_get_string(id, EV_SZ_model, model, charsmax(model))
		if(model[7] == 'w' && model[9] == 'h' && model[10] == 'e' && model[11] == 'g')
		{
			entity_get_string(id, EV_SZ_classname, class, charsmax(class))
			if(equal(class, "weapon_hegrenade"))
				remove_entity(id)

			return HAM_SUPERCEDE
		}

	}

	return HAM_IGNORED
}

public set_client_kv(id, const info[], const key[])
{
	if(equal(key, "model"))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public sound_emit(id, channel, sample[])
{
	if(is_user_alive(id) && equal(sample, "weapons/knife_", 14))
	{
		switch(sample[17])
		{
			case('b'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/pumni/hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/pumni/hit2.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/ranga/hit1.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
		}
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public voice_listening(receiver, sender, bool:listen)
{
	if((receiver == sender))
		return FMRES_IGNORED

	if(is_user_admin(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}

	switch(gc_VoiceBlock)
	{
		case(2):
		{
			if((sender != g_Simon) && (!get_bit(g_SimonVoice, sender) && gc_VoiceBlock))
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
		case(1):
		{
			if(!get_bit(g_SimonVoice, sender) && gc_VoiceBlock)
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
	}
	if(!is_user_alive(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}

	if(sender == g_Simon)
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}

	listen = true

	if(g_SimonTalking && (sender != g_Simon))
	{
		listen = false
	}
	else
	{
		static CsTeams:steam
		steam = cs_get_user_team(sender)
		switch(gc_TalkMode)
		{
			case(2):
			{
				listen = (steam == CS_TEAM_CT)
			}
			case(1):
			{
				listen = (steam == CS_TEAM_CT || steam == CS_TEAM_T)
			}
		}
	}

	engfunc(EngFunc_SetClientListening, receiver, sender, listen)
	return FMRES_SUPERCEDE
}

public player_cmdstart(id, uc, random)
{
	if(g_Duel > 3)
	{
		cs_set_user_bpammo(id, _Duel[g_Duel - 4][_csw], 1)
	}
}

public round_first()
{
	g_JailDay = 0
	for(new i = 1; i <= g_MaxClients; i++)
		g_PlayerSimon[i] = 0

	set_cvar_num("sv_alltalk", 1)
	set_cvar_num("mp_roundtime", 2)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_tkpunish", 0)
	set_cvar_num("mp_friendlyfire", 0)
	round_end()
}

public round_end()
{
	static CsTeams:team
	static maxnosimon, spectrounds
	g_SafeTime = 0
	g_PlayerRevolt = 0
	g_PlayerFreeday = 0
	g_PlayerLast = 0
	g_BoxStarted = 0
	g_CrowbarCount = 0
	g_Simon = 0
	g_SimonAllowed = 0
	g_RoundStarted = 0
	g_LastDenied = 0
	g_BlockWeapons = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_Freeday = 0
	g_FreedayNext = (random_num(0,99) >= 95)
	g_RoundEnd = 1
	g_Duel = 0

	remove_task(TASK_STATUS)
	remove_task(TASK_FREEDAY)
	remove_task(TASK_FREEEND)
	remove_task(TASK_ROUND)
	maxnosimon = get_pcvar_num(gp_NosimonRounds)
	spectrounds = get_pcvar_num(gp_SpectRounds)
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i))
			continue

		menu_cancel(i)
		team = cs_get_user_team(i)
		player_strip_weapons(i)
		switch(team)
		{
			case(CS_TEAM_CT):
			{
				if(g_PlayerSimon[i] > maxnosimon)
				{
					cmd_nomic(i)
				}
			}
			case(CS_TEAM_SPECTATOR,CS_TEAM_UNASSIGNED):
			{
				g_PlayerSpect[i]++
				if(g_PlayerSpect[i] > spectrounds)
				{
					client_cmd(i, "disconnect")
					server_print("JBE Disconnected spectator client #%i", i)
				}
				else
				{
					show_menu(i, 51, TEAM_MENU, -1)
				}
			}
		}
	}
	for(new i = 0; i < sizeof(g_HudSync); i++)
		ClearSyncHud(0, g_HudSync[i][_hudsync])

}

public round_start()
{
	if(g_RoundEnd)
		return

	team_count()
	if(!g_Simon && is_freeday())
	{
		g_Freeday = 1
		emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		check_freeday(TASK_FREEDAY)
	}
	else
	{
		set_task(60.0, "check_freeday", TASK_FREEDAY)
	}
	set_task(HUD_DELAY, "hud_status", TASK_STATUS, _, _, "b")
	set_task(get_pcvar_float(gp_RetryTime) + 1.0, "safe_time", TASK_SAFETIME)
	set_task(120.0, "freeday_end", TASK_FREEDAY)
	g_SimonRandom = get_pcvar_num(gp_SimonRandom) ? random_float(15.0, 45.0) : 0.0
	g_SimonAllowed = 1
	g_FreedayNext = 0
}

public cmd_jointeam(id)
{
	return PLUGIN_HANDLED
}

public cmd_joinclass(id)
{
	return PLUGIN_HANDLED
}

public cmd_voiceon(id)
{
	client_cmd(id, "+voicerecord")
	set_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		set_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_voiceoff(id)
{
	client_cmd(id, "-voicerecord")
	clear_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		clear_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_simon(id)
	{
	static CsTeams:team, name[32]
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	
	team = cs_get_user_team(id)
	if(g_SimonAllowed && !g_Freeday && is_user_alive(id) && team == CS_TEAM_CT && !g_Simon)
		{
		g_Simon = id
		get_user_name(id, name, charsmax(name))
		set_pev(id, pev_body, 1)
		g_PlayerSimon[id]--
		if(get_pcvar_num(gp_GlowModels))
		player_glow(id, g_Colors[0])
		set_user_info(id, "model", "jb_lunetistii_v2")
		client_print( id, print_chat, "***Acum este simon, da-le comenzi PRIZONIERILOR !***");
		cmd_simonmenu(id)
		
		hud_status(0)
	}
	return PLUGIN_HANDLED
}

public cmd_simonreset(id)
	{
	if((id  == g_Simon) || is_user_admin(id) )
		menu_players(id, CS_TEAM_CT, id, 1, "cmd_simon_ct", "\rCine vrei sa fie SIMON in loc?")
		
	return PLUGIN_CONTINUE
}

public cmd_simon_ct(id, menu, item)
	{
	
	if(item == MENU_EXIT ||( g_Simon != id))
		{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32],src[32], data[5], player, access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	if (g_Simon == player) return PLUGIN_CONTINUE
	g_Simon = 0
	cmd_simon(player)
	get_user_name(player, dst, charsmax(dst))
	get_user_name(id, src, charsmax(src))
	set_hudmessage(255, 255, 255, -1.0, -0.35, 0, 6.0, 10.0)
	show_hudmessage(0, "%s a predat grad-ul de SIMON lui %s",  src, dst)
	set_user_info(id, "model", "jb_lunetistii_v2")
	set_pev(id, pev_body, 3)
	
	return PLUGIN_HANDLED
}

public cmd_simonrevive(id)
	{
	if((id  == g_Simon) || is_user_admin(id) )
		menu_players(id, CS_TEAM_T, id, 0, "cmd_simon_re", "\rPe cine ai vrea s-a reinvii?")
	return PLUGIN_CONTINUE
}

public cmd_simon_re(id, menu, item)
	{
	if(item == MENU_EXIT ||( g_Simon != id))
		{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	static dst[32],src[32], data[5], player, access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	get_user_name(player, dst, charsmax(dst))
	get_user_name(id, src, charsmax(src))
	
	if(is_user_alive(player))
		{
		ChatColor(id, "!g[SimonMenu] !yPrizonierul !g%s !yeste viu deja", dst)
		cmd_simonrevive(id)
		return PLUGIN_HANDLED;
	}
	if (g_Simon == player) return PLUGIN_CONTINUE
	ChatColor(0, "!g[SimonMenu] !ySimon !g%s !ya dat revive prizonierului !g%s", src, dst)
	cmd_simonrevive(id)
	Revive(player,100,0);
	
	return PLUGIN_HANDLED
}

public cmd_open(id)
	{
	if(id == g_Simon){
		jail_open()
		
		emit_sound(0, CHAN_AUTO, "jbsounds/jb_open.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return PLUGIN_HANDLED
}

public cmd_nomic(id)
	{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	static CsTeams:team
	team = cs_get_user_team(id)
	if(team == CS_TEAM_CT)
		{
		server_print("JBE Transfered guard to prisoners team client #%i", id)
		if(g_Simon == id)
			{
			g_Simon = 0
			static szName[ 33 ];
			get_user_name( id, szName, 32 );
			player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_TRANSFERED", szName);
			//ChatColor(0, "%L",0,"JBE_SIMON_TRANSFERED", szName)
		}
		if(!is_user_admin(id))
			set_bit(g_PlayerNomic, id)
		
		user_silentkill(id)
		cs_set_user_team(id, CS_TEAM_T)
	}
	return PLUGIN_HANDLED
}

public cmd_boxmenu(id){
	if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT))
		{
		new szText[ 555 char ];
		
		formatex( szText, charsmax( szText ), "%L", id, "BOXMENU_TITLE");
		new menu = menu_create( szText, "box_handler" );
		
		formatex( szText, charsmax( szText ), "%L", id, "BOXMENU_M1" );
		menu_additem( menu, szText, "1", 0 );
		
		formatex( szText, charsmax( szText ), "%L", id, "BOXMENU_M2" );
		menu_additem( menu, szText, "2", 0 );
		
		menu_display( id, menu, 0)
	}
	else{
		ChatColor(id, "%L",0,"BOX_ACCES")
	}
}

public box_handler( id, menu, item )
	{
	if( item == MENU_EXIT )
		{
		menu_destroy( menu )
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo( menu, item, access, data,5, iName, 63, callback )
	new key = str_to_num( data )
	switch( key )
	{
		case 1:
		{
			cmd_box(id)
		}
		case 2:
		{
			cmd_boxoff(id)
		}	
	}
	menu_destroy( menu )
	return PLUGIN_HANDLED
} 

public cmd_box(id)
	{
	static i
	if((id < 0) || (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT))
		{
		if(g_TeamAlive[CS_TEAM_T] <= get_pcvar_num(gp_BoxMax) && g_TeamAlive[CS_TEAM_T] > 1)
			{
			for(i = 1; i <= g_MaxClients; i++)
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
				set_user_health(i, 100)
			
			client_cmd(0, "mp3 play ^"%s^"", game_box)
			set_cvar_num("mp_tkpunish", 0)
			set_cvar_num("mp_friendlyfire", 1)
			g_BoxStarted = 1
			new name[32]
			get_user_name(id, name, 63)
			ChatColor(0, "%L",0,"BOX_START", name)
			player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_BOX")
		}
		else
		{
			player_hudmessage(id, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_CANTBOX")
		}
	}
	return PLUGIN_HANDLED
}

public cmd_boxoff(id)
	{
	static i
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
		{
		for(i = 1; i <= g_MaxClients; i++)
			if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
			set_user_health(i, 100)
		
		set_cvar_num("mp_tkpunish", 0)
		set_cvar_num("mp_friendlyfire", 0)
		g_BoxStarted = 0
		new name[32]
		get_user_name(id, name, 63)
		ChatColor(0, "%L",0,"BOX_STOP", name)
		player_hudmessage(0, 1, 3.0, _, "%s a anulat BOX-UL !!!", name)
	}
	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	if(id > g_MaxClients)
		id -= TASK_HELP

	remove_task(TASK_HELP + id)
	switch(get_bit(g_PlayerHelp, id))
	{
		case(0):
		{
			set_bit(g_PlayerHelp, id)
			player_hudmessage(id, 7, 15.0, {230, 100, 10}, "%s", g_HelpText)
			set_task(15.0, "cmd_help", TASK_HELP + id)
		}
		default:
		{
			clear_bit(g_PlayerHelp, id)
			ClearSyncHud(id, g_HudSync[7][_hudsync])
		}
	}
}

public cmd_freeday(id)
{
	static menu, menuname[32], option[64]
	if(!is_freeday() && ((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id)))
	{
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_FREEDAY")
		menu = menu_create(menuname, "freeday_choice")

		formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_FREEDAY_PLAYER")
		menu_additem(menu, option, "1", 0)

		formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_FREEDAY_ALL")
		menu_additem(menu, option, "2", 0)

		menu_display(id, menu)
	}
	return PLUGIN_HANDLED
}

public cmd_freeday_player(id)
{
	if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id))
		menu_players(id, CS_TEAM_T, id, 1, "freeday_select", "%L", LANG_SERVER, "JBE_MENU_FREEDAY")

	return PLUGIN_CONTINUE
}

public cmd_lastrequest(id)
{
	static i, num[5], menu, menuname[32], option[64]
	if(!get_pcvar_num(gp_LastRequest) || g_Freeday || g_LastDenied || id != g_PlayerLast || g_RoundEnd || get_bit(g_PlayerWanted, id) || get_bit(g_PlayerFreeday, id) || !is_user_alive(id))
		return PLUGIN_CONTINUE

	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_LASTREQ")
	menu = menu_create(menuname, "lastrequest_select")

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT1")
	menu_additem(menu, option, "1", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT2")
	menu_additem(menu, option, "2", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT3")
	menu_additem(menu, option, "3", 0)

	for(i = 0; i < sizeof(_Duel); i++)
	{
		num_to_str(i + 4, num, charsmax(num))
		formatex(option, charsmax(option), "%L", LANG_SERVER, _Duel[i][_opt])
		menu_additem(menu, option, num, 0)
	}

	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public adm_freeday(id)
{
	static player, user[32]
	
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
	    new nume[21]
	    get_user_name(id, nume, 20)
	    read_argv(1, user, charsmax(user))
	    player = cmd_target(id, user, 2)
	    if(is_user_connected(player) && cs_get_user_team(player) == CS_TEAM_T)
	    {
		    freeday_set(id, player)
		    ChatColor(0, "!g[AdminControl] !yAdmin-ul !g[%s] !ya dat zi libera lui !g[%s].", nume, user)
		    log_to_file("LogJailBreak.log","[ JBE_FREEDAY ] Admin-ul [ %s ] a dat zi libera lui [ %s ].",nume,user)
                    emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	    }
    }
	else
	{
		ChatColor(id, "!g[AdminControl] !yNu ai !gacces !yla aceasta comanda.")
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}
public adm_nomic(id)
	{
	static player, user[32]
	
	if(id == 0 && get_user_flags(id) & ADMIN_ACCESS)
	{
		new nume[21]
		get_user_name(id, nume, 20)
		new numeplayer[21]
		get_user_name(player, numeplayer, 20)
		read_argv(1, user, charsmax(user))
		player = cmd_target(id, user, 3)
		if(is_user_connected(player))
	    {
			cmd_nomic(player);
			ChatColor(0, "!g[AdminControl] !yAdmin-ul !g[%s] !yl-a mutat la !gPrizonieri !ype !g[%s].", nume, numeplayer)
			log_to_file("LogJailBreak.log","[JBE_NOMIC] Admin-ul [ %s ] l-a mutat la T pe [%s].", nume, numeplayer)
		}
	}
	else
	{
		ChatColor(id, "!g[AdminControl] !yNu ai !gacces !yla aceasta comanda.")
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED;
}

public adm_open(id)
	{
	if(get_user_flags(id) & ADMIN_ACCESS)
	{	
	    new nume[18]
	    get_user_name(id, nume, 17)
	    ChatColor(0, "!g[AdminControl]!y Admin-ul !g[%s] !ya folosit!g [jbe_open].", nume)
	    log_to_file("LogJailBreak.log","[JBE_OPEN] Admin-ul [ %s ] a deschis celulele prin JBE_OPEN ",nume)
	    emit_sound(0, CHAN_AUTO, "jbsounds/jb_open.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	    jail_open()
	}
	else
	{
		ChatColor(id, "!g[AdminControl] !yNu ai !gacces !yla aceasta comanda.")
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}

public adm_box(id)
	{
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
	    new nume[16]
	    get_user_name(id, nume, 15)
	    //print(0, "^x04[AdminJail]^x01 Admin-ul^x03 [ %s ]^x01 a folosit^x03 JBE_BOX.^x01",nume)
	    ChatColor(0, "!g[AdminControl]!y Admin-ul !g[%s] !ya folosit!g [jbe_box].", nume)
	    log_to_file("LogJailBreak.log","[ JBE_BOX ] Admin-ul [ %s ] a dat BOX prin JBE_BOX ", nume)
	    cmd_box(id)
	}
	else
	{
		ChatColor(id, "!g[AdminControl] !yNu ai !gacces !yla aceasta comanda.")
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}

public adm_boxoff(id)
	{
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
	    new nume[16]
	    get_user_name(id, nume, 15)
	    ChatColor(0, "!g[AdminControl]!y Admin-ul !g%s !ya folosit!g JBE_BOXOFF.", nume)
	    log_to_file("LogJailBreak.log","[ JBE_BOX ] Admin-ul [ %s ] a dat BOX-OFF prin JBE_BOXOFF ", nume)
	    cmd_boxoff(id)
	}
	else
	{
		ChatColor(id, "!g[AdminControl] !yNu ai !gacces !yla aceasta comanda.")
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
}

public team_select(id, key)
{
	static CsTeams:team, roundloop, admin

	roundloop = get_pcvar_num(gp_RetryTime) / 2
	team = cs_get_user_team(id)
	admin = is_user_admin(id)
	team_count()

	if(!admin && (team == CS_TEAM_UNASSIGNED) && (g_RoundStarted >= roundloop) && g_TeamCount[CS_TEAM_CT] && g_TeamCount[CS_TEAM_T] && !is_user_alive(id))
	{
		team_join(id, CS_TEAM_SPECTATOR)
		client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTJOIN")
		return PLUGIN_HANDLED
	}


	switch(key)
	{
		case(0):
		{
			if(team == CS_TEAM_T)
				return PLUGIN_HANDLED

			g_PlayerReason[id] = random_num(1, 6)

			team_join(id, CS_TEAM_T)
		}
		case(1):
		{
			if(team == CS_TEAM_CT || (!admin && get_bit(g_PlayerNomic, id)))
				return PLUGIN_HANDLED

			if(g_TeamCount[CS_TEAM_CT] < ctcount_allowed() || admin)
				team_join(id, CS_TEAM_CT)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CTFULL")
		}
		case(5):
		{
			user_silentkill(id)
			team_join(id, CS_TEAM_SPECTATOR)
		}
	}
	return PLUGIN_HANDLED
}

public team_join(id, CsTeams:team)
{
	static restore, vgui, msgblock

	restore = get_pdata_int(id, m_iVGUI)
	vgui = restore & (1<<0)
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore & ~(1<<0))

	switch(team)
	{
		case CS_TEAM_SPECTATOR:
		{
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			dllfunc(DLLFunc_ClientPutInServer, id)
			set_msg_block(g_MsgShowMenu, msgblock)
			set_pdata_int(id, m_fGameHUDInitialized, 1)
			engclient_cmd(id, "jointeam", "6")
		}
		case CS_TEAM_T, CS_TEAM_CT:
		{
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			engclient_cmd(id, "jointeam", (team == CS_TEAM_CT) ? "2" : "1")
			engclient_cmd(id, "joinclass", "1")
			set_msg_block(g_MsgShowMenu, msgblock)
			g_PlayerSpect[id] = 0
		}
	}
	
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore)
}

public team_count()
{
	static CsTeams:team, last
	g_TeamCount[CS_TEAM_UNASSIGNED] = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_TeamCount[CS_TEAM_SPECTATOR] = 0
	g_TeamAlive[CS_TEAM_UNASSIGNED] = 0
	g_TeamAlive[CS_TEAM_T] = 0
	g_TeamAlive[CS_TEAM_CT] = 0
	g_TeamAlive[CS_TEAM_SPECTATOR] = 0
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_connected(i))
		{
			team = cs_get_user_team(i)
			g_TeamCount[team]++
			g_PlayerTeam[i] = team
			if(is_user_alive(i))
			{
				g_TeamAlive[team]++
				if(team == CS_TEAM_T)
					last = i
			}
		}
		else
		{
			g_PlayerTeam[i] = CS_TEAM_UNASSIGNED
		}
	}
	if(g_TeamAlive[CS_TEAM_T] == 1)
	{
		if(last != g_PlayerLast && g_SafeTime)
		{
			prisoner_last(last)
		}
	}
	else
	{
		if(g_Duel || g_DuelA || g_DuelB)
		{
			if(is_user_alive(g_DuelA))
			{
				set_user_rendering(g_DuelA, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				player_strip_weapons(g_DuelA)
			}

			if(is_user_alive(g_DuelB))
			{
				set_user_rendering(g_DuelB, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				player_strip_weapons(g_DuelB)
			}

		}
		g_PlayerLast = 0
		g_DuelA = 0
		g_DuelB = 0
		g_Duel = 0
	}
}

public revolt_start()
{
	emit_sound(0, CHAN_AUTO, "ambience/siren.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(8.0, "stop_sound")
	hud_status(0)
}
public stop_sound(task)
{
	client_cmd(0, "stopsound")
}

public hud_status(task)
{
	static i, n
	new name[32], szStatus[64], wanted[1024]
 
	if(g_RoundStarted < (get_pcvar_num(gp_RetryTime) / 2))
		g_RoundStarted++

	if(!g_Freeday && !g_Simon && g_SimonAllowed && (0.0 < g_SimonRandom < get_gametime()))
	{
		cmd_simon(random_num(1, g_MaxClients))
	}

	n = 0
	formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "JBE_PRISONER_WANTED")
	n = strlen(wanted)
	for(i = 0; i < g_MaxClients; i++)
	{
		if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && n < charsmax(wanted))
		{
			get_user_name(i, name, charsmax(name))
			n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
			n += copy(wanted[n], charsmax(wanted) - n, name)
		}
	}

	team_count()
	formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "JBE_STATUS", g_TeamAlive[CS_TEAM_T], g_TeamCount[CS_TEAM_T])
	message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
	write_byte(0)
	write_string(szStatus)
	message_end()

   if(g_Simon)
   {
      get_user_name(g_Simon, name, charsmax(name))
      player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 255}, "%s este Simon :: Ziua %d :: Jb.Lunetistii.Ro ", name, g_JailDay)
   }else{
      player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 255}, "Nu este Simon :: Ziua %d :: Jb.Lunetistii.Ro", g_JailDay)
   }
   if(g_Freeday)
   {
   player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 255}, "Nu este Simon :: Zi Libera :: Jb.Lunetistii.Ro", g_JailDay)
   }
   
   if(g_PlayerWanted)
      player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%s", wanted)
   else if(g_PlayerRevolt)
      player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%L", LANG_SERVER, "JBE_PRISONER_REVOLT")
   
	gc_TalkMode = get_pcvar_num(gp_TalkMode)
	gc_VoiceBlock = get_pcvar_num(gp_VoiceBlock)
	gc_SimonSteps = get_pcvar_num(gp_SimonSteps)
	gc_ButtonShoot = get_pcvar_num(gp_ButtonShoot)
	gc_CrowbarMul = get_pcvar_float(gp_CrowbarMul)

}

public safe_time(task)
{
	g_SafeTime = 1
}

public check_freeday(task)
{
	static Float:roundmax, i
	if(!g_Simon && !g_PlayerLast)
	{
		g_Freeday = 1
		hud_status(0)
		roundmax = get_pcvar_float(gp_RoundMax)
		if(roundmax > 0.0)
		{
			for(i = 1; i <= g_MaxClients; i++)
			{
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					freeday_set(0, i)
			}
			emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			player_hudmessage(0, 8, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_STATUS_ENDTIMER", floatround(roundmax - 60.0))
			remove_task(TASK_ROUND)
			set_task(roundmax - 60.0, "check_end", TASK_ROUND)
		}
	}

	if(get_pcvar_num(gp_AutoOpen))
		jail_open()
}

public freeday_end(task)
{
	if(g_Freeday || g_PlayerFreeday)
	{
		emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		player_hudmessage(0, 8, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_STATUS_ENDFREEDAY")
	}
}

public check_end(task)
{
	team_count()
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_T && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_CT && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	player_hudmessage(0, 6, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_STATUS_ROUNDEND")
}

public prisoner_last(id)
{
	static name[32], Float:roundmax
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
	{
		roundmax = get_pcvar_float(gp_RoundMax)
		get_user_name(id, name, charsmax(name))
		g_PlayerLast = id
		player_hudmessage(0, 6, 5.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_PRISONER_LAST", name)
		remove_task(TASK_ROUND)
		if(roundmax > 0.0)
		{
			player_hudmessage(0, 8, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_STATUS_ENDTIMER", floatround(roundmax - 60.0))
			set_task(roundmax - 60.0, "check_end", TASK_ROUND)
		}
		if((g_TeamAlive[CS_TEAM_CT] > 0) && get_pcvar_num(gp_AutoLastresquest))
			cmd_lastrequest(id)
	}
}

public freeday_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], player, access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	freeday_set(id, player)
	return PLUGIN_HANDLED
}

public duel_knives(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], access, callback, option[128], player, src[32]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL3", src, LANG_SERVER, "JBE_MENU_DUEL_SEL", src, dst)
	emit_sound(0, CHAN_AUTO, "jbsounds/jb_box3.mp3", 1.0, ATTN_NORM, 0, PITCH_NORM)
	player_hudmessage(0, 6, 3.0, {0, 255, 255}, option)

	g_DuelA = id
	clear_bit(g_PlayerCrowbar, id)
	player_strip_weapons(id)
	player_glow(id, g_Colors[3])
	set_user_health(id, 100)

	g_DuelB = player
	player_strip_weapons(player)
	player_glow(player, g_Colors[2])
	set_user_health(player, 100)
	g_BlockWeapons = 1
	return PLUGIN_HANDLED
}
public duel_guns(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		g_Duel = 0
		return PLUGIN_HANDLED
	}

	static gun, dst[32], data[5], access, callback, option[128], player, src[32]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, _Duel[g_Duel - 4][_sel], src, LANG_SERVER, "JBE_MENU_DUEL_SEL", src, dst)
	emit_sound(0, CHAN_AUTO, "jbsounds/jb_lr.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	player_hudmessage(0, 6, 3.0, {0, 255, 255}, option)

	g_DuelA = id
	clear_bit(g_PlayerCrowbar, id)
	player_strip_weapons(id)
	gun = give_item(id, _Duel[g_Duel - 4][_entname])
	cs_set_weapon_ammo(gun, 1)
	set_user_health(id, 100)
	player_glow(id, g_Colors[3])

	g_DuelB = player
	player_strip_weapons(player)
	gun = give_item(player, _Duel[g_Duel - 4][_entname])
	cs_set_weapon_ammo(gun, 1)
	set_user_health(player, 100)
	player_glow(player, g_Colors[2])

	g_BlockWeapons = 1
	return PLUGIN_HANDLED
}

public freeday_choice(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	get_user_name(id, dst, charsmax(dst))
	switch(data[0])
	{
		case('1'):
		{
			cmd_freeday_player(id)
		}
		case('2'):
		{
			if((id == g_Simon) || is_user_admin(id))
			{
				g_Simon = 0
				get_user_name(id, dst, charsmax(dst))
				client_print(0, print_console, "%s gives freeday for everyone", dst)
				server_print("JBE Client %i gives freeday for everyone", id)
				check_freeday(TASK_FREEDAY)		
                                emit_sound(0, CHAN_AUTO, "jbsounds/jb_ding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		}
	}
	return PLUGIN_HANDLED
}

public lastrequest_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], access, callback, option[64]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, dst, charsmax(dst))
	switch(data[0])
	{
		case('1'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL1", dst)
			player_hudmessage(0, 6, 3.0, {0, 255, 255}, option)
			set_bit(g_FreedayAuto, id)
			user_silentkill(id)
		}
		case('2'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL2", dst)
			player_hudmessage(0, 6, 3.0, {0, 255, 255}, option)
		        cs_set_user_money(id,cs_get_user_money(id) + 16000)
			user_silentkill(id)
		}
		case('3'):
		{
			g_Duel = 3
			menu_players(id, CS_TEAM_CT, 0, 1, "duel_knives", "%L", LANG_SERVER, "JBE_MENU_DUEL")
		}
		default:
		{
			g_Duel = str_to_num(data)
			menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "JBE_MENU_DUEL")
		}
	}
	g_LastDenied = 1
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public setup_buttons()
{
	new ent[3]
	new Float:origin[3]
	new info[32]
	new pos

	while((pos <= sizeof(g_Buttons)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "info_player_deathmatch")))
	{
		pev(ent[0], pev_origin, origin)
		while((ent[1] = engfunc(EngFunc_FindEntityInSphere, ent[1], origin, CELL_RADIUS)))
		{
			if(!is_valid_ent(ent[1]))
				continue

			entity_get_string(ent[1], EV_SZ_classname, info, charsmax(info))
			if(!equal(info, "func_door"))
				continue

			entity_get_string(ent[1], EV_SZ_targetname, info, charsmax(info))
			if(!info[0])
				continue

			if(TrieKeyExists(g_CellManagers, info))
			{
				TrieGetCell(g_CellManagers, info, ent[2])
			}
			else
			{
				ent[2] = engfunc(EngFunc_FindEntityByString, 0, "target", info)
			}

			if(is_valid_ent(ent[2]) && (in_array(ent[2], g_Buttons, sizeof(g_Buttons)) < 0))
			{
				g_Buttons[pos] = ent[2]
				pos++
				break
			}
		}
	}
	TrieDestroy(g_CellManagers)
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

stock freeday_set(id, player)
{
	static src[32], dst[32]
	get_user_name(player, dst, charsmax(dst))

	if(is_user_alive(player) && !get_bit(g_PlayerWanted, player))
	{
		set_bit(g_PlayerFreeday, player)
		entity_set_int(player, EV_INT_skin, 3)
		if(get_pcvar_num(gp_GlowModels))
			player_glow(player, g_Colors[1])

		if(0 < id <= g_MaxClients)
		{
			get_user_name(id, src, charsmax(src))
			player_hudmessage(0, 6, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_GUARD_FREEDAYGIVE", src, dst)
		}
		else if(!is_freeday())
		{
			player_hudmessage(0, 6, 3.0, {0, 255, 255}, "%L", LANG_SERVER, "JBE_PRISONER_HASFREEDAY", dst)
		}
	}
}

stock first_join(id)
{
	if(!get_bit(g_PlayerJoin, id))
	{
		set_bit(g_PlayerJoin, id)
		clear_bit(g_PlayerHelp, id)
		set_task(5.0, "cmd_help", TASK_HELP + id)
	}
}

stock ctcount_allowed()
{
	static count
	count = ((g_TeamCount[CS_TEAM_T] + g_TeamCount[CS_TEAM_CT]) / get_pcvar_num(gp_TeamRatio))
	if(count < 2)
		count = 2
	else if(count > get_pcvar_num(gp_CtMax))
		count = get_pcvar_num(gp_CtMax)

	return count
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 255}, msg[], any:...)

{

   static text[512], Float:x, Float:y

   x = g_HudSync[hudid][_x]

   y = g_HudSync[hudid][_y]

   

   if(time > 0)

      set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)

   else

      set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)



   vformat(text, charsmax(text), msg, 6)

   ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)

}

stock menu_players(id, CsTeams:team, skip, alive, callback[], title[], any:...)
{
	static i, name[32], num[5], menu, menuname[32]
	vformat(menuname, charsmax(menuname), title, 7)
	menu = menu_create(menuname, callback)
	for(i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i) || (alive && !is_user_alive(i)) || (skip == i))
			continue

 		if(!(team == CS_TEAM_T || team == CS_TEAM_CT) || ((team == CS_TEAM_T || team == CS_TEAM_CT) && (cs_get_user_team(i) == team)))
		{
			get_user_name(i, name, charsmax(name))
			num_to_str(i, num, charsmax(num))
			menu_additem(menu, name, num, 0)
		}
	}
	menu_display(id, menu)
}

stock player_glow(id, color[3], amount=40)
{
	set_user_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, amount)
}

stock player_strip_weapons(id)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	set_pdata_int(id, m_iPrimaryWeapon, 0)
}

stock player_strip_weapons_all()
{
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_alive(i))
		{
			player_strip_weapons(i)
		}
	}
}

stock is_freeday()
{
	return (g_FreedayNext || g_Freeday || (g_JailDay == 1))
}

public jail_open()
{
	static i
	for(i = 0; i < sizeof(g_Buttons); i++)
	{
		if(g_Buttons[i])
		{
			ExecuteHamB(Ham_Use, g_Buttons[i], 0, 0, 1, 1.0)
			entity_set_float(g_Buttons[i], EV_FL_frame, 0.0)
		}
	}
}
Revive(index,hp,armor)
{
	set_pev(index,pev_deadflag,DEAD_RESPAWNABLE);
	set_pev(index,pev_iuser1,0);
	dllfunc(DLLFunc_Think,index);
	engfunc(EngFunc_SetOrigin,index,Float:{-4800.0,-4800.0,-4800.0});
	new array[3];
	array[0] = index;
	array[1] = hp;
	array[2] = armor
	set_task(0.5,"respawn",0,array,3);
}

public respawn(array[3])
	{
	new index = array[0];
	new hp = array[1];
	new armor = array[2];
	if(is_user_connected(index))
		{
		dllfunc(DLLFunc_Spawn,index);
		set_pev(index,pev_health,float(hp));
		set_pev(index,pev_armorvalue,float(armor));
		Fade(index,0,255,0,30);
	}
}

stock Fade(index,red,green,blue,alpha)
	{
	message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},index);
	write_short(1<<10);
	write_short(1<<10);
	write_short(1<<12);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}

stock ChatColor(const id, const input[], any:...)
	{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!team", "^3")
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
			{
			if (is_user_connected(players[i]))
				{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}