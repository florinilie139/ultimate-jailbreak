/*
Jocuri: Slender man
        One in the chamber
        Hold the flag
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <vip_base>
#include <colorchat>

#define PLUGIN_NAME    "[UJBM] Main"
#define PLUGIN_AUTHOR    "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION    "1.6"
#define PLUGIN_CVAR    "Ultimate JailBreak Manager"

#define USE_TOGGLE 3
#define MAX_BACKWARD_UNITS    -150.0
#define MAX_FORWARD_UNITS    200.0

#define TASK_STATUS        2487000
#define TASK_FREEDAY    2487100
#define TASK_ROUND        2487200
#define TASK_HELP        2487300
#define TASK_SAFETIME    2487400
#define TASK_FREEEND    2487500
#define TASK_GIVEITEMS    2487600
#define TASK_DAYTIMER     2487700
#define TASK_INVISIBLE     7447
#define TASK_RADAR      666
#define TASK_LAST       677365
#define TASK_SAYTIME    9143
#define TASK_INFO       222200
#define TEAM_MENU        "#Team_Select_Spect"
#define TEAM_MENU2        "#Team_Select"
#define HUD_DELAY        Float:1.0
#define CELL_RADIUS        Float:200.0
#define VOICE_ADMIN_FLAG ADMIN_KICK
#define TASK_FD_TIMER      83458345
#define TASK_RANDOM      1100

#define m_LastHitGroup 75

#define get_bit(%1,%2)         ( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)         %1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)    %1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)            floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)        ( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)        ( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

#define JBMODELLOCATION "models/player/jblaleagane41/jblaleagane41.mdl"
#define JBMODELSHORT "jblaleagane41"

// Offsets
#define m_iPrimaryWeapon    116
#define m_iVGUI            510
#define m_fGameHUDInitialized    349
#define m_fNextHudTextArgsGameTime    198

#define FLASHCOST    3500
#define HECOST  4000    
#define SMOKECOST    3000
#define ARMORCOST    4000
#define FDCOST    16000
#define SHIELDCOST    16000
//#define KNIFESCOST    10000
#define CROWBARCOST    16000
#define CTDEAGLECOST 1000
#define CTFLASHCOST 3000
#define HPCOST 4000
#define NVGCOST 1500
#define CTSMOKECOST 3000
#define FLASHLIGHTCOST 2000
#define GLOCKCOST 8000

#define ALIEN_RED 180
#define ALIEN_GREEN 240
#define ALIEN_BLUE 140


#define OFFSET_TEAM         114
#define OFFSET_PAINSHOCK 108
#define OFFSET_LINUX 5
#define Keyscl_min (1<<0)|(1<<1) // Keys: 12

#if cellbits == 32
    #define OFFSET_CSMONEY  115
 #else
    #define OFFSET_CSMONEY  140
 #endif


enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
enum _lastrequest { _knife, _deagle, _freeday, _weapon }
enum _duel { _name[16], _csw, _entname[32], _opt[32], _sel[32] }
enum _:_lrsong { _name[100], _song[100], };
new Songs[100][_lrsong];
new MaxVip = 0;

new g_iPlayerCamera[33], Float:g_camera_position[33];

new FreedayTime
new FreedayRemoved
new BeaconSprite
new gp_PrecacheSpawn
new gp_PrecacheKeyValue
new gp_BoxMax
new gp_TalkMode
new gp_VoiceBlock
new gp_RetryTime
new gp_FDLength
new gp_ButtonShoot
new gp_SimonSteps
new gp_GlowModels
new gp_AutoLastresquest
new gp_LastRequest
new gp_Motd
new gp_TShop
new gp_CTShop
new gp_GameHP
new gp_Games
new gp_ShowColor
new gp_Effects
new gp_ShowFD
new gp_ShowWanted
new g_MaxClients
new g_MsgStatusText
new g_iMsgSayText
new g_MsgStatusIcon
new g_MsgMOTD
new gc_TalkMode
new gc_VoiceBlock
new gc_SimonSteps
new gc_ButtonShoot
new gp_Help
new g_Countdown
new Day[26]
new g_Info
new FDnr
new Tnr
new Wnr
new g_newChance
new g_CantChoose
new g_canTrivia
new g_WasBoxDay
new g_TimeRound
//new g_CountKilled[33]

enum _:_days{
    AlienDayT =-2,
    ZombieDayT,       //-1
    Freeday,          //0
    NormalDay,        //1
    ZombieDay,        //2
    HnsDay,           //3
    AlienDay,         //4
    AlienHiddenDay,   //5
    GunDay,           //6
    ColaDay,          //7
    GravityDay,       //8
    FireDay,          //9
    BugsDay,          //10
    NightDay,         //11
    SpartaDay,        //12
    SpiderManDay,     //13
    CowboyDay,        //14
    SpartaTeroDay,    //15
    FreezeTagDay,     //16
    ZombieTeroDay,    //17
    ScoutDay,         //18
    BoxDay,           //19
    StarWarsDay,      //20
    RipperDay,        //21
    FunDay,           //22
    //AscunseleaDay,  //23
    //PrinseleaDay,   //24
    OneBullet         //25
}

enum _:lastrequests{
    LrGame = 0,
    LrMoney,
    FreeGun,
    DuelKnives,
    Catea,
    Grenada,
    Ruleta,
    Trivia,
    HeadShot,
    //Reactie,
    Shot4Shot
}

new DuelWeapon;

// Precache
new const _RpgModels[][] = { "models/p_rpg.mdl", "models/v_rpg.mdl" , "models/w_rpg.mdl", "models/rpgrocket.mdl" }
new const _RpgSounds[][] = { "weapons/rocketfire1.wav", "weapons/explode3.wav", "weapons/rocket1.wav" }

//sunete craciun
//new const _PoliceSounds[][] = { "jbextreme/hohojb.wav", "jbextreme/mcjb.wav", "jbextreme/hohohomcjb.wav"}

//sunete david
new const _PoliceSounds[][] = { "jbdobs/police/radio1.wav", "jbdobs/police/radio2.wav", "jbdobs/police/radio3.wav", "jbdobs/police/radio4.wav"}

new const GucciModels[][] = { "vader" , "obiwan" }

new SpriteExplosion

new const _RemoveEntities[][] = {
    "func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
    "hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new g_HsOnly = 0
new HsOnlyWeapon = 0
new const _HsOnlyWeapons [][] = { "weapon_m4a1", "weapon_deagle", "weapon_g3sg1", "weapon_ak47", "weapon_aug", "weapon_galil", "weapon_sg552", "weapon_famas", "weapon_m249", "weapon_sg550" }
new const _HsOnlyWeaponsCSW[] = { CSW_M4A1, CSW_DEAGLE, CSW_G3SG1, CSW_AK47, CSW_AUG, CSW_GALIL, CSW_SG552, CSW_FAMAS, CSW_M249, CSW_SG550 }

new const _WeaponsFree[][] = { "weapon_m4a1", "weapon_deagle", "weapon_g3sg1", "weapon_scout", "weapon_ak47", "weapon_mp5navy", "weapon_m3", "weapon_aug", "weapon_galil", "weapon_sg552", "weapon_famas", "weapon_sg550", "weapon_ump45", "weapon_p90" }
new const _WeaponsFreeCSW[] = { CSW_M4A1, CSW_DEAGLE, CSW_G3SG1, CSW_SCOUT, CSW_AK47, CSW_MP5NAVY, CSW_M3, CSW_AUG, CSW_GALIL, CSW_SG552, CSW_FAMAS, CSW_SG550, CSW_UMP45, CSW_P90 }
new const _WeaponsFreeAmmo = 999

new const _Duel[][_duel] =
{
    { "m249",        CSW_M249,         "weapon_m249",        "M249",                "S-a selectat M249 Duel"        },
    { "Grenades",    CSW_HEGRENADE,    "weapon_hegrenade",   "HE",                  "S-a selectat HE Duel"          },
    { "Rulette",     33,               "weapon_deagle",      "Ruleta ruseasca",     "S-a selectat Ruleta ruseasca"  },
    { "Trivia",      34,               "weapon_knife",       "Trivia",              "S-a selectat Trivia Duel"      },
    //{ "Reactie",      35,               "weapon_knife",       "Reactii",              "S-a selectat Duel de reactie"      },
    { "HeadShot",      36,               "weapon_knife",       "HeadShot Only",              "S-a selectat Duel HS Only"      },
    
    //{ "Grenades",     CSW_FLASHBANG,     "weapon_flashbang", "UJBM_MENU_LASTREQ_OPT5",     "UJBM_MENU_LASTREQ_SEL5"  }, //rpg!!!
    
    { "Deagle",      CSW_DEAGLE,       "weapon_deagle",      "Deagle",              "S-a selectat Deagle Duel"      },
    { "P228",        CSW_P228,         "weapon_p228",        "P228",                "S-a selectat P228 Duel"        },
    { "Fiveseven",   CSW_FIVESEVEN,    "weapon_fiveseven",   "Fiveseven",           "S-a selectat Fiveseven Duel"   },
    { "USP",         CSW_USP,          "weapon_usp",         "USP",                 "S-a selectat USP Duel"         },
    { "Glock",       CSW_GLOCK18,      "weapon_glock18",     "Glock",               "S-a selectat Glock Duel"       },
    { "Elite",       CSW_ELITE,        "weapon_elite",       "Elite",               "S-a selectat Elite Duel"       },
     
    //{ "XM1014",      CSW_XM1014,       "weapon_xm1014",      "XM1014",              "S-a selectat XM1014 Duel"      },
    //{ "M3",          CSW_M3,           "weapon_m3",          "M3",                  "S-a selectat M3 Duel"          },
    
    { "Mac10",       CSW_MAC10,        "weapon_mac10",       "Mac-10",              "S-a selectat Mac-10 Duel"      },
    { "UMP45",       CSW_UMP45,        "weapon_ump45",       "UMP45",               "S-a selectat UMP45 Duel"       },
    { "MP5Navy",     CSW_MP5NAVY,      "weapon_mp5navy",     "MP5",                 "S-a selectat MP5 Duel"         },
    { "Tmp",         CSW_TMP,          "weapon_tmp",         "Tmp",                 "S-a selectat Tmp Duel"         },
    { "P90",         CSW_P90,          "weapon_p90",         "P90",                 "S-a selectat P90 Duel"         },
        
    { "Galil",       CSW_GALIL,        "weapon_galil",       "Galil",               "S-a selectat Galil Duel"       },
    { "Famas",       CSW_FAMAS,        "weapon_famas",       "Famas",               "S-a selectat Famas Duel"       },
    { "M4A1",        CSW_M4A1,         "weapon_m4a1",        "M4A1",                "S-a selectat M4A1 Duel"        },
    { "Ak47",        CSW_AK47,         "weapon_ak47",        "AK-47",                "S-a selectat AK-47 Duel"        },
    
    { "G3sg1",       CSW_G3SG1,        "weapon_g3sg1",       "G3sg1",               "S-a selectat G3sg1 Duel"       },
    { "Aug",         CSW_AUG,          "weapon_aug",         "Aug",                 "S-a selectat Aug Duel"         },
    { "Sg552",       CSW_SG552,        "weapon_sg552",       "Sg552",               "S-a selectat Sg552 Duel"       },
    { "Sg550",       CSW_SG550,        "weapon_sg550",       "Sg550",               "S-a selectat Sg550 Duel"       },
    { "Awp",         CSW_AWP,          "weapon_awp",         "Awp",                 "S-a selectat Awp Duel"         },
    { "Scout",       CSW_SCOUT,        "weapon_scout",       "Scout",               "S-a selectat Scout Duel"       }

}
// Reasons
new const g_Reasons[][] =  {
    "",
    "UJBM_PRISONER_REASON_1",
    "UJBM_PRISONER_REASON_2",
    "UJBM_PRISONER_REASON_3",
    "UJBM_PRISONER_REASON_4",
    "UJBM_PRISONER_REASON_5",
    "UJBM_PRISONER_REASON_6",
    "UJBM_PRISONER_REASON_7",
    "UJBM_PRISONER_REASON_8",   
    "UJBM_PRISONER_REASON_9",
    "UJBM_PRISONER_REASON_10",
    "UJBM_PRISONER_REASON_11",
    "UJBM_PRISONER_REASON_12",
    "UJBM_PRISONER_REASON_13",
    "UJBM_PRISONER_REASON_14",
    "UJBM_PRISONER_REASON_15",
    "UJBM_PRISONER_REASON_16",
    "UJBM_PRISONER_REASON_17",
    "UJBM_PRISONER_REASON_18",
    "UJBM_PRISONER_REASON_19",
    "UJBM_PRISONER_REASON_20"
    
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help / 8=timer
new const g_HudSync[][_hud] =
{
    {0,  0.81,  0.08,  1.0},                //0
    {0, -1.0,  0.7,  5.0},                  //1
    {0,  0.05,  0.08,  1.0},                //2
    {0,  0.05,  0.3,  1.0},                 //3
    {0,  0.6,  0.2,  1.0},                  //4
    {0,  0.6,  0.1,  1.0},                  //5
    {0, -1.0,  0.6,  1.0},                  //6
    {0,  0.8,  0.3, 20.0},                  //7
    {0, -1.0,  0.4,  1.0},                  //8
    {0,  0.05,  0.5,  1.0},                 //9
    {0, -1.0,  0.45, 1.0},
    {0,  0.6,  0.25,  1.0},
    {0,  0.05,  0.2,  1.0}
}
// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {0, 0, 255}, {255, 0, 0} }
//new CsTeams:g_PlayerTeam[33]
new Trie:g_CellManagers
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerSpect[33]
//new bool:g_Savedhns[33]
new RRammo[10]
new RRturn
new RussianRouletteBullet

new g_PlayerWanted
new g_PlayerVoice
new g_PlayerRevolt
new g_PlayerHelp
new g_PlayerFreeday
new g_PlayerLastFreeday
new g_PlayerNextFreeday
new g_PlayerLast
new g_PlayerLastVoiceSetting

new g_NoShowShop = 0;
new g_BoxStarted;
new g_Simon;
new g_SimonAllowed;
new g_SimonTalking;
new g_SimonVoice;
new g_RoundStarted;
new g_RoundEnd;
new m_iTrail;
new g_Duel;
new g_DuelA;
new g_DuelB;
new g_Buttons[10];
new g_GameMode = NormalDay;
new g_GamePrepare = 0;
new g_nogamerounds;
new gmsgSetFOV;
new gp_Bind;
new g_BackToCT = 0;
new g_Fonarik = 0;
new CTallowed[31];
new Tallowed[31];
new bindstr[33];
new g_Scope;
new g_DuelReaction;
new g_DuelJumped[33];
new g_DuelDucked[33];
new g_DuelReactionStarted;
new g_Donated[33];
new g_DamageDone[33];
new g_BoxLastY[33];
new g_HatEnt[33];

stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW);

new gmsgBombDrop;
new ding_on = 1;
new g_CanOpen = 1;
new killed = 0;
new killedonlr = 0;
new Simons[33];
new SimonTimes[33];
new BoxPartener[33];
new fun_light[2] = "i",fun_gravity=800,fun_god=0,fun_clip=0;
new bool:g_GamesAp[_days];
//new bool:Matadinnou
//new Mata

//0 attack  1 not 2 t 3 t
new g_DoNotAttack;
new g_FriendlyFire;
new g_GameWeapon[2];

//what guns on menu^^
new G_Size[2][4] ={{
        //Min Value
        0,
        15,
        20,
        24
        },{
        //Max Value
        14,
        19,
        23,
        25
    }
}

//Pcvars maxplayers
new P_Cvars[34]

//Page
new G_Info_page[33]

//price and names,other info etc
new Weapons_Price[33]
new Weapons_Info[3][33][22]

new g_Map[40]
new BuyTimes[33]
new g_IsFG

new g_ResultVote[33]
new g_DayTimer = 0

new SVC_SCREENFADE
#define SF_FADEOUT 0

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    Load();
    unregister_forward(FM_Spawn, gp_PrecacheSpawn)
    unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)
    //register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
    register_dictionary("ujbm.txt")
    g_MsgStatusText = get_user_msgid("StatusText")
    g_MsgStatusIcon = get_user_msgid("StatusIcon")
    g_MsgMOTD = get_user_msgid("MOTD")
    gmsgBombDrop = get_user_msgid("BombDrop")
    SVC_SCREENFADE = get_user_msgid( "ScreenFade" )

    register_message(g_MsgStatusText, "msg_statustext")
    register_message(g_MsgStatusIcon, "msg_statusicon")
    register_message(g_MsgMOTD, "msg_motd")
    
    register_message(get_user_msgid("SayText"), "message_SayText")
    
    register_message(get_user_msgid("TextMsg"), "block_FITH_message")
    register_message(get_user_msgid("SendAudio"), "block_FITH_audio")

    //register_event("CurWeapon", "current_weapon_fl", "be", "1=1", "2=25")
    register_event("StatusValue", "player_status", "be", "1=2", "2!0")
    register_impulse(100, "impulse_100")
    
    //RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "rpg_pre")
    //RegisterHam(Ham_Weapon_Reload, "weapon_flashbang", "rpg_reload")
    //register_touch("rpg_missile", "worldspawn",    "rocket_touch")
    //register_touch("rpg_missile", "player",        "rocket_touch")
    
    register_clcmd("say /cam", "camera_menu")
    register_clcmd("say_team /cam", "camera_menu")
    register_forward(FM_SetView, "SetView") 
    RegisterHam(Ham_Think, "trigger_camera", "Camera_Think")
    
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
    RegisterHam(Ham_TakeDamage, "player", "player_damage")
    RegisterHam(Ham_TraceAttack, "player", "player_attack")
    RegisterHam(Ham_TakeHealth, "player", "player_heal")
    RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
    RegisterHam(Ham_Killed, "player", "player_killed")
    RegisterHam(Ham_Touch, "player", "Fwd_PlayerTouch");
    RegisterHam(Ham_Item_PreFrame, "player", "player_maxspeed", 1 );
    register_forward(FM_SetClientKeyValue, "set_client_kv")
    register_forward(FM_Voice_SetClientListening, "voice_listening")
    RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_deagle", "Rulette" );
    register_forward(FM_CmdStart, "player_cmdstart", 1)
    register_logevent("round_end", 2, "1=Round_End")
    
    register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
    register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
    register_forward(FM_ClientKill, "fwd_FM_ClientKill");
    register_clcmd("+simonvoice", "cmd_voiceon")
    register_clcmd("+voicerecord", "cmd_voiceon")
    register_clcmd("-simonvoice", "cmd_voiceoff")
    register_clcmd("-voicerecord", "cmd_voiceoff")
    register_clcmd("say /dorinta", "cmd_lastrequest")
    register_clcmd("say /ajutor", "cmd_help")
    register_clcmd("say /dorm", "cmd_nosleep")
    register_clcmd("say /voice", "cmd_simon_micr")    
    register_clcmd("say /micr", "cmd_simon_micr")    
    register_clcmd("say /shop", "cmd_shop")
    register_clcmd("say /fd", "cmd_freeday")
    register_clcmd("say /damibani", "cmd_givemoneyForTest")
    register_clcmd("say /removefd", "cmd_removefd")
    register_clcmd("say /menu", "cmd_simonmenu")
    register_clcmd("say /freeday", "cmd_freeday")
    register_clcmd("say /day", "cmd_freeday")
    register_clcmd("say /lr", "cmd_lastrequest")
    register_clcmd("say /lastrequest", "cmd_lastrequest")
    register_clcmd("say /duel", "cmd_lastrequest")
    register_clcmd("say /box","cmd_box")
    register_clcmd("say /simon", "cmd_simon")
    register_clcmd("say /open", "cmd_open")
    register_clcmd("say /help", "cmd_help")
    register_clcmd("say /rules", "cmd_help")
    register_clcmd("say /reguli", "cmd_help")
    register_clcmd("say /whosimon","cmd_whosimon")
    register_clcmd("say /gunshop","gunsmenu")
    register_clcmd("say /simonel","cmd_adminchoosesimon")
    register_clcmd("say_team /gunshop","gunsmenu")
    register_clcmd("say /motiv","cmd_motiv")
    register_clcmd("say /listfd","cmd_listfd")
    register_clcmd("say /unsimon", "cmd_unsimon", ADMIN_LEVEL_E, "- nu mai esti Simon");
    register_clcmd("say","cmd_donate")
    register_clcmd("say /sounds", "cmd_soundmenu")
    register_clcmd("say /sunete", "cmd_soundmenu")
    register_clcmd("say /reactii", "cmd_reactionsmenu")
    register_clcmd("say /reactie", "cmd_reactionsmenu")
    register_clcmd("say /flip", "chat_flip")
    register_clcmd("say /roll", "chat_roll")
    register_clcmd("say /tryshield", "cmd_incercare")
    
    register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")    
    register_event("CurWeapon", "Event_CurWeapon", "be","1=1")
    register_logevent("JoinTeam", 3, "1=joined team")

    register_cvar("amx_donate_max","16000")
    
    gp_GlowModels = register_cvar("jb_glowmodels", "0")
    gp_SimonSteps = register_cvar("jb_simonsteps", "1")
    gp_BoxMax = register_cvar("jb_boxmax", "4")
    gp_RetryTime = register_cvar("jb_retrytime", "120.0")
    gp_AutoLastresquest = register_cvar("jb_autolastrequest", "1")
    gp_LastRequest = register_cvar("jb_lastrequest", "1")
    gp_Motd = register_cvar("jb_motd", "1")
    gp_TalkMode = register_cvar("jb_talkmode", "2")          // 0-alltak / 1-tt talk / 2-tt no talk
    gp_VoiceBlock = register_cvar("jb_blockvoice", "0")      // 0-dont block / 1-block voicerecord / 2-block voicerecord except simon
    gp_ButtonShoot = register_cvar("jb_buttonshoot", "1")    // 0-standard / 1-func_button shoots!
    gp_TShop = register_cvar("jb_tshop", "abcdefg")
    gp_CTShop = register_cvar("jb_ctshop", "abcdefg")
    gp_Games = register_cvar("jb_games", "abcdefghijklmno")
    gp_Bind = register_cvar("jb_bindkey","v")
    gp_Help = register_cvar("jb_autohelp","2")
    gp_FDLength = register_cvar("jb_fdlen","300.0")
    gp_GameHP = register_cvar("jb_hpmultiplier","200")
    gp_ShowColor = register_cvar("jb_hud_showcolor","0")
    gp_ShowFD = register_cvar("jb_hud_showfd","1")
    gp_ShowWanted = register_cvar("jb_hud_show_wanted","1")
    gp_Effects= register_cvar("jb_game_effects","2")
    g_MaxClients = get_global_int(GL_maxClients)
    get_mapname(g_Map, 39)
    //for(new i = 0; i < sizeof(g_HudSync); i++)
    //    g_HudSync[i][_hudsync] = CreateHudSyncObj()
    gmsgSetFOV = get_user_msgid( "SetFOV" )
    g_iMsgSayText = get_user_msgid("SayText");
    set_task(320.0, "help_trollface", _, _, _, "b")
    set_task(50.0, "play_sound_police", _, _, _, "b") //secunde police sound
    setup_buttons()
    g_PlayerLastVoiceSetting = 0
    
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_awp",   "fw_player_scope" )
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_scout", "fw_player_scope" )
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_sg550", "fw_player_scope" )
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_g3sg1", "fw_player_scope" )
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_aug",   "fw_player_scope" )
    RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_sg552", "fw_player_scope" )
    
    RegisterHam(Ham_Player_Jump, "player", "player_jump", 0)
    RegisterHam(Ham_Player_Duck, "player", "player_duck", 0)
    
    return PLUGIN_CONTINUE
}

new SPARTA_P[] = "models/shield/p_sparta.mdl"
new SPARTA_V[] = "models/shield/v_sparta.mdl"
new COLA_P[] = "models/p_cola.mdl"
new COLA_V[] = "models/v_cola.mdl"


public plugin_precache()
{
    precache_model(JBMODELLOCATION)
    precache_model(SPARTA_P)
    precache_model(SPARTA_V)
    precache_model(COLA_P)
    precache_model(COLA_V)
    precache_model("models/hat/cowboy.mdl")
    precache_model("models/player/vader/vader.mdl")
    
    static i
    BeaconSprite = precache_model("sprites/shockwave.spr")    
/*    for(i = 0; i < sizeof(_RpgModels); i++)
            precache_model(_RpgModels[i])
    for(i = 0; i < sizeof(_RpgSounds); i++)
            precache_sound(_RpgSounds[i])*/
    for(i = 0; i < sizeof(_PoliceSounds); i++)
            precache_sound(_PoliceSounds[i])    
    //SpriteExplosion = precache_model("sprites/fexplo1.spr")     
    //m_iTrail = precache_model("sprites/smoke.spr")
    precache_sound("alien_alarm.wav")
    precache_sound("jbextreme/mareduel.wav")
    precache_sound("jbextreme/rumble.wav")
    precache_sound("jbextreme/brass_bell_C.wav")
    //precache_sound("jbextreme/money.wav")
    precache_sound("ambience/the_horror2.wav")
    precache_sound("debris/metal2.wav")
    precache_sound("items/gunpickup2.wav")
    precache_sound("jbextreme/simondead2.wav")
    precache_sound("jbextreme/oof.wav")
    precache_sound("jbextreme/opendoor3.wav")
    precache_sound("jbextreme/sparta1.wav")
    precache_sound("jbextreme/hns.wav")
    precache_sound("jbextreme/lina.wav")
    precache_sound("jbextreme/fatality.wav")
    precache_sound("jbextreme/jump_.wav")
    precache_sound("jbextreme/duck_.wav")
    precache_sound("jbextreme/duckjump_.wav")
    precache_sound("jbextreme/jump_last.wav")
    precache_sound("jbextreme/duck_last.wav")
    precache_sound("jbextreme/duckjump_last.wav")
    precache_sound("jbextreme/start_.wav")
    precache_sound("jbextreme/horn_.wav")
    precache_sound("jbextreme/horn2_.wav")
    precache_sound("jbextreme/voicestart_.wav")
    precache_sound("jbextreme/dingdingding.wav")
    precache_sound("jbextreme/kaching.wav")
    precache_sound("jbextreme/spider.wav")
    precache_sound("jbextreme/cowboy.wav")
    precache_sound("jbextreme/boxwin.wav")
    
    load_songs()
    for(new j = 1; j < MaxVip; j++)
        precache_sound(Songs[j][_song])

    g_CellManagers = TrieCreate()
    gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
    gp_PrecacheKeyValue = register_forward(FM_KeyValue, "precache_keyvalue", 1)
}

public plugin_natives() 
{ 
    register_library("ujbm"); 
    register_native ("get_simon", "_get_simon",0)
    register_native ("get_gamemode", "_get_gamemode",0)
    register_native ("get_duel", "_get_duel",0)
    register_native ("get_fd", "_get_fd",0)
    register_native ("get_wanted", "_get_wanted",0)
    register_native ("set_wanted", "_set_wanted",0)
    register_native ("remove_fd", "_remove_fd",0)
    register_native ("get_last", "_get_last",0)
    register_native ("get_model","_get_model",0)
    register_native ("get_day","_get_day",0)
} 
public _get_simon(iPlugin, iParams)
{ 
    return g_Simon;
}  
public _get_last(iPlugin, iParams) 
{ 
    return g_PlayerLast;
}  
public _get_gamemode(iPlugin, iParams) 
{ 
    return g_GameMode;
}
public _get_duel(iPlugin, iParams) 
{ 
    return g_Duel;
}  
public bool:_get_fd(iPlugin, iParams) 
{ 
    new id = get_param(1);
    if (get_bit(g_PlayerFreeday, id))return true;
    return false;
}  
public bool:_get_wanted(iPlugin, iParams) 
{ 
    new id = get_param(1);
    if (get_bit(g_PlayerWanted, id))return true;
    return false;
} 
public _set_wanted(iPlugin, iParams)
{
    new id = get_param(1)
    if(!g_PlayerRevolt)
        revolt_start()
    clear_bit(g_PlayerFreeday, id)
    set_bit(g_PlayerWanted, id)
    entity_set_int(id, EV_INT_skin, 5)
    
}
public _remove_fd(iPlugin, iParams)
{
    new id = get_param(1)
    new ok=0
    if(get_bit(g_PlayerFreeday, id))
        ok=1
    if(!g_PlayerRevolt)
        revolt_start()
    set_bit(g_PlayerRevolt, id)
    clear_bit(g_PlayerFreeday, id)
    if(!get_bit(g_PlayerWanted, id) && ok)
        if(check_model(id)==false)
            set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
        else
            entity_set_int(id, EV_INT_skin, 1)
}
public _get_model(iPlugin, iParams) 
{ 
    set_string(1, JBMODELSHORT, get_param(2));  
}
public _get_day(iPlugin, iParams)
{
    return g_JailDay;
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
public client_putinserver(id)
{
    client_cmd(id,"mp_consistency 0")
    client_cmd(id,"rate 25000")
    client_cmd(id,"voice_scale 1")
    client_cmd(id,"sv_voicecodec voice_speex")
    client_cmd(id,"sv_voicequality 10")
    client_cmd(id,"cl_updaterate 101")
    client_cmd(id,"cl_cmdrate 101")
    client_cmd(id,"cl_lc 1")
    client_cmd(id,"cl_lw 1")
    client_cmd(id,"cl_dynamiccrosshair 0")
    clear_bit(g_PlayerJoin, id)
    clear_bit(g_PlayerHelp, id)
    clear_bit(g_PlayerWanted, id)
    clear_bit(g_PlayerVoice, id)
    clear_bit(g_SimonTalking, id)
    clear_bit(g_SimonVoice, id)
    clear_bit(g_PlayerFreeday, id)
    g_PlayerSpect[id] = 0
    Simons[id]=0
    SimonTimes[id]=0
    BoxPartener[id]=0
    BuyTimes[id]=0
    first_join(id)
    //g_CountKilled[id] = 0
    g_iPlayerCamera[id] = 0
    g_camera_position[id] = -100.0;
}

public client_disconnect(id)
{
    if(g_Simon == id)
    {
        g_Simon = 0
        //ClearSyncHud(0, g_HudSync[2][_hudsync])
        player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "UJBM_SIMON_HASGONE")
        if(g_GameMode == AlienDay || g_GameMode == AlienHiddenDay || g_GameMode == FireDay)
            cmd_expire_time();
    }
    else if(g_Duel && (id == g_DuelA || id == g_DuelB))
    {
        g_Duel = 0
        g_DuelA = 0
        g_DuelB = 0
        server_cmd("jb_unblock_weapons")
    }
    hud_status(0)
    /*if(Mata == id)
        cmd_moaremata();*/
    task_last()
}

public disconnect_camera(id)
{
    new iEnt = g_iPlayerCamera[id];
    if(pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt);
    g_iPlayerCamera[id] = 0;
    g_camera_position[id] = -100.0;
}
public client_PostThink(id)
{
    if(id != g_Simon && (g_GameMode != AlienDayT || cs_get_user_team(id)!=CS_TEAM_T) && (g_GameMode != NightDay || cs_get_user_team(id)!=CS_TEAM_CT) || !gc_SimonSteps || !is_user_alive(id) ||
    !(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) || entity_get_int(id, EV_ENT_groundentity))
    return PLUGIN_CONTINUE
    static Float:origin[3]
    static Float:last[33][3]
    entity_get_vector(id, EV_VEC_origin, origin)
    if(get_distance_f(origin, last[id]) < 32.0)
    {
        return PLUGIN_CONTINUE
    }
    vec_copy(origin, last[id])
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
public power_ding()
{
    remove_task(5146)
    ding_on = 1
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
public msg_motd(msgid, dest, id)
{
    if(get_pcvar_num(gp_Motd))
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}
//load info
public Load()
{
    new lineNum   =  0,pointNum  = -1,filename[66],configLine[80],iLen,price[6],Name[30]
    get_configsdir(filename, 65)
    format(filename, 65, "%s/Gun_Menu.ini", filename)
    if(file_exists(filename)){
        while(read_file(filename,lineNum++,configLine,79,iLen)) 
        {
            if (iLen > 0)
            {
                pointNum++
                parse(configLine, Weapons_Info[0][pointNum], 19, price, 5, Weapons_Info[1][pointNum], 21, Weapons_Info[2][pointNum], 21)
                
                Name = Weapons_Info[0][pointNum] 
                format(Name,29,"gunmenu_%s",Name)
                P_Cvars[pointNum] = register_cvar(Name,"1")
                Weapons_Price[pointNum] = str_to_num(price)
            }
        }
    }
    return PLUGIN_CONTINUE
}

public radar_alien()
{
    if(is_user_alive(g_Simon)){
        new origin[3]
        get_user_origin(g_Simon,origin)
        message_begin(MSG_ALL, gmsgBombDrop, {0,0,0}, 0)
        write_coord(origin[0])    //X Coordinate
        write_coord(origin[1])    //Y Coordinate
        write_coord(origin[2])    //Z Coordinatew
        write_byte(0)            //?? This byte seems to always be 0...so, w/e
        message_end()
    }
    else
        remove_task(TASK_RADAR)        
}
public radar_alien_t(id)
{
    if(id>TASK_RADAR)
        id-=TASK_RADAR
    if(is_user_alive(id))
    {
        new origin[3]
        get_user_origin(id,origin)
        message_begin(MSG_ALL, gmsgBombDrop, {0,0,0}, 0)
        write_coord(origin[0])    //X Coordinate
        write_coord(origin[1])    //Y Coordinate
        write_coord(origin[2])    //Z Coordinate
        write_byte(0)            //?? This byte seems to always be 0...so, w/e
        message_end()
    }
    else
        remove_task(TASK_RADAR+id)
}
public give_items_alien()
{
    if(!is_user_connected(g_Simon) || !is_user_alive(g_Simon))
        return
    give_item(g_Simon, "item_assaultsuit")
    give_item(g_Simon, "item_longjump")
    give_item(g_Simon, "weapon_knife")
    server_cmd("give_crowbar %d 1",g_Simon)
    set_user_maxspeed(g_Simon, 500.0)
    
}
public give_items_alien_t(id)
{
    if(id>TASK_GIVEITEMS)
        id-=TASK_GIVEITEMS
    if(!is_user_connected(id) || !is_user_alive(id))
        return
    give_item(id, "item_assaultsuit")
    give_item(id, "item_longjump")
    give_item(id, "weapon_knife")
    server_cmd("give_crowbar %d 1",id)
    set_user_maxspeed(id, 500.0)
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
            //ClearSyncHud(id, g_HudSync[1][_hudsync])
        }
        case(2):
        {
            if (!is_user_connected(player)) return PLUGIN_HANDLED
            if (player == g_Simon) 
            {
                health = get_user_health(player)
                get_user_name(player, name, charsmax(name))
                player_hudmessage(id, 6, 0.5, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_SIMON_STATUS", name, health)
                return PLUGIN_HANDLED
            }
            team = cs_get_user_team(player)
            if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
                return PLUGIN_HANDLED
            
            if(!get_bit(g_Info,id))
            {
                health = get_user_health(player)
                get_user_name(player, name, charsmax(name))
                if(team == CS_TEAM_T)
                {
                    if(get_bit(g_PlayerFreeday,player))
                        player_hudmessage(id, 6, 0.5, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_STATUS_FD", name, health)
                    else
                        player_hudmessage(id, 6, 0.5, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_STATUS", name, health)
                }
                else
                    player_hudmessage(id, 6, 0.5, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_STATUS", name, health)
                set_bit(g_Info,id)
                remove_task(TASK_INFO+id)
                set_task(0.5,"no_info",TASK_INFO+id)
            }
        }
    }
    return PLUGIN_HANDLED
}

public no_info(id)
{
    if(id>TASK_INFO)
    {
        id-=TASK_INFO;
    }
    clear_bit(g_Info,id)
}
public impulse_100(id)
{
    if(!get_bit(g_Fonarik,id))
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}
public  player_maxspeed(id)
{
    if(!is_user_connected(id))
        return HAM_IGNORED
    switch (g_GameMode)
    {
        case HnsDay: 
        {
            if (cs_get_user_team(id) == CS_TEAM_T) set_user_maxspeed(id ,310.0)
        }
        case AlienDay:
        {
            if (g_Simon == id) set_user_maxspeed(id ,450.0)
        }
        case AlienHiddenDay: 
        { 
            if (g_Simon == id) set_user_maxspeed(id ,320.0)
        }
        default:
        {
            
        }
    }
    return HAM_HANDLED
}

public player_spawn(id)
{
    static CsTeams:team
    new rez = random_num(1,2)
    if(!is_user_connected(id))
        return HAM_IGNORED
    set_pdata_float(id, m_fNextHudTextArgsGameTime, get_gametime() + 999999.0)
    if(g_RoundEnd)
    {
        g_RoundEnd = 0
        g_JailDay++
    }
    message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id )
    write_short(12288)    // Duration
    write_short(12288)    // Hold time
    write_short(0x0000)    // Fade type
    write_byte (0)        // Red
    write_byte (0)        // Green
    write_byte (0)        // Blue
    write_byte (255)    // Alpha
    message_end()
    
    BuyTimes[id]= 0
    set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
    strip_user_weapons(id)
    //g_CountKilled[id] = 0
    give_item(id,"weapon_knife")
    set_pdata_int(id, m_iPrimaryWeapon, 0)
    clear_bit(g_PlayerWanted, id)
    team = cs_get_user_team(id)
    if (!get_bit(g_NoShowShop,id)) 
       set_task(5.0,"cmd_shop",id)
    
    switch(team)
    {
        case(CS_TEAM_T):
        {
            if( g_PlayerLast != 0)
            {
                if(!g_PlayerLastVoiceSetting)
                {
                    clear_bit(g_PlayerVoice, g_PlayerLast)
                }
            }
            g_PlayerLast = 0
            BoxPartener[id] = 0
            g_PlayerReason[id] = random_num(1, 20)
            player_hudmessage(id, 8, 60.0, {255, 0, 255}, "%L %L", LANG_SERVER, "UJBM_PRISONER_REASON",LANG_SERVER, g_Reasons[g_PlayerReason[id]])
            client_infochanged(id)
            set_user_info(id, "model", JBMODELSHORT)
            if( rez == 1 || rez == 2)
            {
                entity_set_int(id, EV_INT_body, 1+rez)
            }
            else
            {
                log_amx("Caugth rez to bee %d",rez)
                entity_set_int(id, EV_INT_body, 2)
            }
            if (g_GameMode == Freeday || get_bit(g_PlayerFreeday,id))
            { 
                entity_set_int(id, EV_INT_skin, 4)
            }
            else
            {
                rez = random_num(0, 3)
                if( rez >= 0 && rez <= 3)
                {
                    entity_set_int(id, EV_INT_skin, rez)
                }
                else
                {
                    log_amx("Caugth rez to bee %d",rez)
                    entity_set_int(id, EV_INT_body, 0)
                }
                
            }
            cs_set_user_armor(id, 0, CS_ARMOR_NONE)
            set_pev(id, pev_flags, pev(id, pev_flags)| FL_FROZEN)
            set_task(5.0, "task_unfreeze", TASK_SAFETIME + id);
        }
        case(CS_TEAM_CT):
        {
            G_Info_page[id]=0
            set_user_info(id, "model", JBMODELSHORT)
            if( rez == 1 || rez == 2)
            {
                entity_set_int(id, EV_INT_body, 3+rez)
            }
            else
            {
                log_amx("Caugth rez to bee %d",rez)
                entity_set_int(id, EV_INT_body, 4)
            }
            
            cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
            /*new r = random_num(1,3)
            switch (r)
            {
                case 1:
                {
                    set_dhudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 6.0)
                    show_dhudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_FK")
                }
                case 2:
                {
                    set_dhudmessage(0, 255, 0, -1.0, 0.60, 0, 6.0, 6.0)
                    show_dhudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_RULES")
                }
                default:
                {
                    set_dhudmessage(0, 212, 255, -1.0, 0.80, 0, 6.0, 6.0)
                    show_dhudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_MICR")
                }
            }*/
        }
    }
    /*if(g_RoundStarted >= (get_pcvar_num(gp_RetryTime) / 2))
    {    
        user_silentkill(id)
        return HAM_SUPERCEDE
    }*/
    return HAM_IGNORED
}
public task_unfreeze(id)
{
    if(id > g_MaxClients)
        id -= TASK_SAFETIME
    
    remove_task(TASK_SAFETIME + id)
    
    if( is_user_alive(id))
        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
}
public task_inviz(id)
{
    if(id>32)
        id-=TASK_INVISIBLE
    if(is_user_alive(id)){
        set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
        write_short(~0)
        write_short(~0)
        write_short(0x0004) // stay faded
        write_byte(ALIEN_RED)
        write_byte(ALIEN_GREEN)
        write_byte(ALIEN_BLUE)
        write_byte(100)
        message_end()
    }
    else
        remove_task(TASK_INVISIBLE+id)
}

public player_heal()
{    
    if(g_GameMode != NormalDay && g_GameMode != Freeday)
        return HAM_SUPERCEDE
    return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
    static CsTeams:vteam, CsTeams:ateam
    if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
        return HAM_IGNORED
    vteam = cs_get_user_team(victim)
    ateam = cs_get_user_team(attacker)   
    if(g_GameMode == BoxDay && !g_GamePrepare)
        if(vteam != ateam)
            return HAM_SUPERCEDE
    if(g_GameMode == FunDay && fun_god == 1)
        return HAM_SUPERCEDE
    if (g_GameMode  ==  AlienHiddenDay && g_Simon  ==  attacker || g_GameMode == AlienDayT && ateam==CS_TEAM_T)
    {
        set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0 )
        remove_task(TASK_INVISIBLE+attacker)
        set_task(3.1, "task_inviz",TASK_INVISIBLE + attacker, _, _, "b");
    }
    if (g_GameMode == GunDay && g_HsOnly)
        if(get_pdata_int(victim, m_LastHitGroup, 5) != HIT_HEAD)
            return HAM_SUPERCEDE
    if(ateam == CS_TEAM_SPECTATOR || vteam == CS_TEAM_SPECTATOR)
        return HAM_SUPERCEDE
    if(vteam == ateam && (bits & (1<<24))) 
        return HAM_SUPERCEDE
    switch(g_Duel)
    {
        case(LrGame):
        {
            return HAM_IGNORED
        }
        case(FreeGun):
        {
            if(attacker != g_PlayerLast || (bits & (1<<24)))
                return HAM_SUPERCEDE
        }
        default:
        {
            if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
            {
                if(g_Duel != Ruleta && (g_Duel> DuelKnives && get_user_weapon(attacker) == _Duel[DuelWeapon][_csw] || g_Duel == DuelKnives && get_user_weapon(attacker)==CSW_KNIFE))
                    return HAM_IGNORED
                if(g_Duel == HeadShot && get_user_weapon(attacker) == HsOnlyWeapon && get_pdata_int(victim, m_LastHitGroup, 5) == HIT_HEAD)
                    return HAM_IGNORED               
            }        
            return HAM_SUPERCEDE
        }
    }
    if (g_GameMode == FireDay)
    {
        SetHamParamFloat(4, 1.0)
        return HAM_OVERRIDE
    }
    return HAM_IGNORED
}
public  player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
    static CsTeams:vteam, CsTeams:ateam
    if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
        return HAM_IGNORED
    vteam = cs_get_user_team(victim)
    ateam = cs_get_user_team(attacker)   
    if(g_GameMode == BoxDay && !g_GamePrepare)
    {
        if(vteam != ateam)
            return HAM_SUPERCEDE
        if(ateam == CS_TEAM_T && ateam == vteam && get_user_weapon(attacker) == CSW_KNIFE)
        {
            SetHamParamFloat(3, damage/2)
            return HAM_OVERRIDE
        }
    }
    if(g_RoundEnd || g_GamePrepare == 1 || (g_GameMode == NormalDay && g_JailDay%7 == 6 && !g_WasBoxDay) || /*(g_GameMode == NormalDay && g_JailDay%7 == 3 && !g_WasBoxDay) ||*/ ateam == CS_TEAM_SPECTATOR || vteam == CS_TEAM_SPECTATOR)
        return HAM_SUPERCEDE
    if(!is_not_game()){
        if(g_FriendlyFire == 0 && ateam == vteam)
        {
            return HAM_SUPERCEDE
        }
        /*if(get_user_weapon(attacker) == CSW_KNIFE && g_GameMode == Mata && ateam == CS_TEAM_CT && Matadinnou == true)
        {
            Mata = victim
            set_user_maxspeed(victim, 400.0)
            set_user_maxspeed(attacker, 260.0)
            cs_set_user_team2(victim,CS_TEAM_CT)
            cs_set_user_team2(attacker, CS_TEAM_T)
            entity_set_int(victim, EV_INT_body, 1)
            entity_set_int(attacker, EV_INT_body, 1+random_num(1,2))
            set_user_health(victim,999999)
            set_user_health(attacker,100)
            cs_set_user_nvg(attacker,1)
            cs_set_user_nvg(victim,0)
            Matadinnou = false
            set_task(2.0,"cmd_dinnoumata")
            emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            return HAM_SUPERCEDE
        }*/
        new team = (ateam == CS_TEAM_CT);
        if(g_DoNotAttack == 1 && (g_GameWeapon[team] == 0 || g_GameWeapon[team]!=get_user_weapon(attacker)))
            return HAM_SUPERCEDE
        if(g_DoNotAttack == 2 && !team && (g_GameWeapon[0] == 0 || g_GameWeapon[0]!=get_user_weapon(attacker)))
            return HAM_SUPERCEDE
        if(g_DoNotAttack == 3 && team && (g_GameWeapon[1] == 0 || g_GameWeapon[1]!=get_user_weapon(attacker)))
            return HAM_SUPERCEDE
    }
    else
    {
        if(ateam == vteam && ateam == CS_TEAM_CT)
            return HAM_SUPERCEDE
        switch(g_Duel)
        {
            case(0):
            {
                if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT)
                {
                    new ok=0
                    if(get_bit(g_PlayerFreeday, attacker))
                        ok=1
                    if(!g_PlayerRevolt)
                        revolt_start()
                    set_bit(g_PlayerRevolt, attacker)
                    clear_bit(g_PlayerFreeday, attacker)
                    if(!get_bit(g_PlayerWanted, attacker) && ok)
                        if(check_model(attacker)==false)
                            set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
                        else
                            entity_set_int(attacker, EV_INT_skin, 1)
                }
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
            case(FreeGun):
            {
                if(attacker != g_PlayerLast)
                    return HAM_SUPERCEDE
            }
            case(Trivia, Ruleta):
            {
                return HAM_SUPERCEDE
            }
            default:
            {
                if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA)){
                    if(g_Duel==DuelKnives)
                    {
                        SetHamParamFloat(3, damage/2)
                        return HAM_OVERRIDE
                    }
                    return HAM_IGNORED
                }
                return HAM_SUPERCEDE
            }
        }
        if(cs_get_user_team(victim) == CS_TEAM_T && cs_get_user_team(victim)==cs_get_user_team(attacker) )
        {
            if(!g_BoxStarted || (get_user_weapon(attacker) != CSW_KNIFE && (!get_bit(g_PlayerWanted, attacker) || BoxPartener[attacker] != victim)))
                return HAM_SUPERCEDE
            if(g_BoxStarted)
            {
                if(BoxPartener[victim] != attacker)
                {
                    set_user_health(victim,100)
                    BoxPartener[victim] = attacker
                }
                if(BoxPartener[attacker] != victim)
                {
                    BoxPartener[attacker] = victim;
                }
            }
        }
        
    }
    return HAM_IGNORED
}
public fwd_FM_ClientKill(id)
{
    if(is_user_alive(id))
    {
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}
public button_attack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
    if(is_valid_ent(button) && gc_ButtonShoot && is_user_alive(id) && cs_get_user_team(id)!=CS_TEAM_SPECTATOR)
    {
        ExecuteHamB(Ham_Use, button, id, 0, 2, 1.0)
        entity_set_float(button, EV_FL_frame, 0.0)
    }
    return HAM_IGNORED
}
public task_last()
{
    new Players[32], player 
    new playerCount, i, TAlive=0, CTAlive=0
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        player = Players[i]
        if (cs_get_user_team(player) == CS_TEAM_T )
        {
            TAlive++;
            g_PlayerLast = player;
        }
        if (cs_get_user_team(player) == CS_TEAM_CT )
        {
            CTAlive++;
        }
    }    
    if (TAlive == 1 && CTAlive >= 1) 
    {
        if (get_pcvar_num(gp_AutoLastresquest) && is_not_game()){
            clear_bit(g_PlayerWanted, g_PlayerLast)
            set_bit(g_PlayerVoice, g_PlayerLast)
            g_PlayerLastVoiceSetting = get_bit(g_PlayerVoice, g_PlayerLast)
            cmd_lastrequest(g_PlayerLast)
        }
    }
    else
        g_PlayerLast = 0
    return PLUGIN_CONTINUE
}
public player_killed(victim, attacker, shouldgib)
{
    static CsTeams:vteam, CsTeams:kteam
    new nameCT[32],nameT[32]
    if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
        kteam = CS_TEAM_UNASSIGNED
    else
        kteam = cs_get_user_team(attacker)
    vteam = cs_get_user_team(victim)
    
    if(cs_get_user_team(victim) == CS_TEAM_T && !(get_user_flags(victim) & VOICE_ADMIN_FLAG))
    {
        cmd_voiceoff(victim)
    }
    
    remove_all_fd()

    get_user_name(attacker,nameCT,31)
    get_user_name(victim,nameT,31)
    switch (g_GameMode)
    {
        case AlienDayT:
        {
            if (kteam == CS_TEAM_T) set_user_health(attacker, get_user_health(attacker) + 100)
        }
        case ZombieDay:
        {
            if (vteam == CS_TEAM_T && kteam == CS_TEAM_CT)
                give_item(attacker, "ammo_buckshot")
        }
        case ZombieTeroDay:
        {
            if (vteam == CS_TEAM_CT && kteam == CS_TEAM_T)
            {
                give_item(attacker, "ammo_buckshot")
                give_item(attacker, "ammo_buckshot")
                give_item(attacker, "ammo_buckshot")
                give_item(attacker, "ammo_buckshot")
            }
        }
        case AlienDay:
        {
            if (victim == g_Simon && kteam == CS_TEAM_T)
            {
                cs_set_user_money(attacker, 16000+cs_get_user_money(attacker))
            }
            else if (attacker == g_Simon) set_user_health(g_Simon, get_user_health(g_Simon) + 150)
        }
        case AlienHiddenDay:
        {
            if (victim == g_Simon && kteam == CS_TEAM_T){
                cs_set_user_money(attacker, 16000 + cs_get_user_money(attacker))
            }
            else if (attacker == g_Simon) 
            {
                set_user_health(g_Simon, get_user_health(g_Simon) + 200)
            }
        }
        case NightDay:
        {
            if (kteam == CS_TEAM_CT) set_user_health(attacker, get_user_health(attacker) + 10)
            else if(vteam == CS_TEAM_CT)
            {
                if(kteam == CS_TEAM_T)
                    cs_set_user_money(attacker, cs_get_user_money(attacker)+4000)
                remove_task(TASK_INVISIBLE+victim)
            }
        }
        /*case 15:
        {
            if (Mata == victim){
                cmd_moaremata()
            }
        }*/
        default:
        {
            message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, victim )
            write_short(12288)    // Duration
            write_short(12288)    // Hold time
            write_short(0x0001)    // Fade type
            write_byte (0)        // Red
            write_byte (0)        // Green
            write_byte (0)        // Blue
            write_byte (255)    // Alpha
            message_end()
            
            if (vteam == CS_TEAM_T)
            {
                killed = 1;
                remove_task(TASK_LAST)
                set_task(2.1, "task_last", TASK_LAST)
            }
            if (vteam == CS_TEAM_CT && kteam == CS_TEAM_T){
                if (victim == g_Simon)
                    cs_set_user_money(attacker, cs_get_user_money(attacker) + 3500)
                else 
                    cs_set_user_money(attacker, cs_get_user_money(attacker) + 500)
            }
            else  if (vteam == CS_TEAM_T && kteam == CS_TEAM_T){
                if(g_GameMode == BoxDay)
                    set_user_health(attacker, 100)
                else
                {
                    BoxPartener[attacker] = 0
                    BoxPartener[victim] = 0
                    cs_set_user_money(attacker, cs_get_user_money(attacker) + 2800)
                    set_user_health(attacker, 100)    
                }
            }
            if(g_Simon == victim)
            {
                server_cmd("painttero %d", g_Simon)
                g_Simon = 0
                resetsimon()
                new lmao
                lmao = random_num(0,1)
                if(lmao)
                    emit_sound(0, CHAN_AUTO, "jbextreme/simondead2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                else
                    emit_sound(0, CHAN_AUTO, "jbextreme/oof.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                //ClearSyncHud(0, g_HudSync[2][_hudsync])
                //player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "UJBM_SIMON_KILLED")
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
                                entity_set_int(attacker, EV_INT_skin, 5)
                                
                                ColorChat(0, RED, "^x01 Prizonierul^x03 %s^x01 a devenit^x03 rebel^x01!", nameCT) 
                            }
                        }
                        case(CS_TEAM_T):
                        { 
                            if(kteam == CS_TEAM_CT)
                            {
                                if(get_bit(g_PlayerWanted,victim))
                                {
                                    ColorChat(0, NORMAL, "Gardianul^x03 %s^x01 a omorat rebelul^x03 %s^x01!", nameCT, nameT) 
                                }
                                else if(get_bit(g_PlayerFreeday,victim))
                                {
                                    ColorChat(0, BLUE, "^x01 Gardianul^x03 %s^x01 a omorat prizonierul cu Freeday^x04 %s^x01!", nameCT, nameT) 
                                }
                            }
                            clear_bit(g_PlayerRevolt, victim)
                            clear_bit(g_PlayerWanted, victim)
                        }
                    }
                    if(get_pdata_int(victim, m_LastHitGroup, 5) == HIT_HEAD)
                    {
                        client_cmd(victim,"spk fvox/flatline.wav")
                    }
                }
                case (2):
                {
                    
                }
                default:
                {
                    if(victim == g_DuelA || victim == g_DuelB){
                        new g_CustomSound = 0
                        if(g_Duel != Trivia && g_Duel != Ruleta)
                        {
                            for(new i = 1; i < MaxVip; i++)
                            {
                                if(equal(nameCT, Songs[i][_name]))
                                {
                                    set_cvar_num("ers_enabled", 0)
                                    client_cmd(0,"spk %s", Songs[i][_song])
                                    g_CustomSound = 1
                                    break
                                }
                            }
                        }
                        if(!g_CustomSound && get_pdata_int(victim, m_LastHitGroup, 5) == HIT_HEAD)
                                client_cmd(0,"spk jbextreme/fatality.wav")
                        killedonlr = 1    
                        set_user_rendering(victim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
                        if(is_user_alive(attacker))
                            set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
                        if (kteam == CS_TEAM_T) 
                        {
                            set_user_health(attacker,100)
                            strip_user_weapons(attacker)
                            give_item(attacker,"weapon_knife")
                            cmd_lastrequest(attacker)
                        }
                        if (kteam == CS_TEAM_CT)
                            clear_bit(g_PlayerVoice, victim)
                        g_Duel = 0
                        g_DuelA = 0
                        g_DuelB = 0
                        g_Scope = 1
                        g_DuelReactionStarted = 0
                        DuelWeapon = 0
                        server_cmd("jb_unblock_weapons")
                    }                    
                }
            }
            hud_status(0)
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

public voice_listening(receiver, sender, bool:listen)
{
    if(!is_user_connected(receiver) || !is_user_connected(sender) || receiver == sender)
        return FMRES_IGNORED
    if(get_user_flags(sender)&VOICE_ADMIN_FLAG || get_vip_type(sender) > 0)
    {
        engfunc(EngFunc_SetClientListening, receiver, sender, true)
        return FMRES_SUPERCEDE
    }
    switch(gc_VoiceBlock)
    {
        case(2):
        {
            if((sender != g_Simon) && !get_bit(g_SimonVoice, sender))
            {
                engfunc(EngFunc_SetClientListening, receiver, sender, false)
                return FMRES_SUPERCEDE
            }
        }
        case(1):
        {
            if(!get_bit(g_SimonVoice, sender))
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
    if(get_bit(g_PlayerVoice, sender))
    {
        engfunc(EngFunc_SetClientListening, receiver, sender, true)
        return FMRES_SUPERCEDE
    }
    listen = true
    if(g_SimonTalking && (sender != g_Simon))
        listen = false
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
public Rulette (weaponid)
{
    new id = get_pdata_cbase(weaponid, 41, 4) 
    if (g_Duel == Ruleta && ( g_DuelA==id || g_DuelB==id)){
        if(is_user_alive(id)  && (g_DuelA==id && RRturn == 1 || g_DuelB==id && RRturn == 2)){
            new RuletteRandom
            do{
                RuletteRandom = random_num(1, 6)
            }while(RRammo[RuletteRandom]==1);
            RRammo[RuletteRandom]=1
            if(RussianRouletteBullet == RuletteRandom)
                user_kill(id)
            else{
                if(RRturn == 2){
                    RRturn = 1
                }else{
                    RRturn = 2
                }
                player_hudmessage(id, 10, HUD_DELAY + 10.0, {200, 100, 0}, "%L", LANG_SERVER, "UJBM_PASSWEAPON")
            }
        }else{
            set_pdata_float(weaponid, 46, 1.0, 4)
            return HAM_SUPERCEDE
        }
    }
    return HAM_HANDLED
}

public player_cmdstart(id, uc, seed)
{
    if(!is_user_alive(id))
        return FMRES_IGNORED
    
    if(g_Duel > 3 && g_Duel != Trivia && g_Duel != Ruleta)
    {
        if(g_DuelA != id && g_DuelB != id)
            return FMRES_IGNORED
        if (_Duel[DuelWeapon][_csw] != CSW_M249 && _Duel[DuelWeapon][_csw]!=33 && _Duel[DuelWeapon][_csw]!=36)
            cs_set_user_bpammo(id, _Duel[DuelWeapon][_csw], 1)
        if(g_Duel == HeadShot)
            cs_set_user_bpammo(id, HsOnlyWeapon, 1)
    }
    else
    {
        if (g_GameMode == ColaDay)  cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
        else if(g_GameMode == SpartaDay && cs_get_user_team(id)==CS_TEAM_T)  cs_set_user_bpammo(id, CSW_DEAGLE, 1)
    }
    
    return FMRES_HANDLED
}
public round_first()
{
    g_JailDay = -2

    set_cvar_num("sv_alltalk", 1)
    set_cvar_num("mp_roundtime", 5)
    set_cvar_num("mp_limitteams", 0)
    set_cvar_num("mp_autoteambalance", 0)
    set_cvar_num("mp_tkpunish", 0)
    set_cvar_num("mp_friendlyfire", 1)
    server_cmd("bh_enabled 1")
    server_cmd("sleep_enabled 1")
    round_end()
    g_GameMode = NormalDay    
}
public round_end()
{
    server_cmd("jb_unblock_weapons")
    server_cmd("bh_enabled 1")
    server_cmd("sleep_enabled 1")
    set_cvar_num("sv_hookadminonly", 1)
    set_cvar_num("sv_hookspeed", 1000)
    set_cvar_num("sv_parachute", 1)
    set_cvar_num("amx_climb", 0)
    g_PlayerRevolt = 0
    if(g_JailDay%7 >= 0 && g_JailDay%7 <= 5 && /*g_JailDay%7 != 3 &&*/ is_not_game()){
        g_PlayerLastFreeday = g_PlayerFreeday
        g_PlayerFreeday = g_PlayerNextFreeday
        g_PlayerNextFreeday = 0
    }
    g_BoxStarted = 0
    g_Simon = 0
    g_SimonAllowed = 0
    g_RoundStarted = 0
    new Ent = -1 
    while((Ent = find_ent_by_class(Ent, "rpg_off")))
    {
        remove_entity(Ent)
    }
    g_RoundEnd = 1
    g_Duel = 0
    g_Scope = 1
    g_DuelReactionStarted = 0
    DuelWeapon = 0
    HsOnlyWeapon = 0
    g_WasBoxDay = 0
    g_HsOnly = 0
    g_Fonarik = 0
    g_TimeRound = 0
    //for(new i = 0; i < sizeof(g_HudSync); i++)
    //    ClearSyncHud(0, g_HudSync[i][_hudsync])
    set_lights("#OFF");
    fog(false)    
    
    if( g_PlayerLast != 0)
    {
        if(!g_PlayerLastVoiceSetting)
        {
            clear_bit(g_PlayerVoice, g_PlayerLast)
        }
    }
    g_PlayerLast = 0
    new i
    set_cvar_num("sv_gravity",800)
    new Players[32]     
    new playerCount
    get_players(Players, playerCount, "c") 
    for (i=0; i<playerCount; i++) 
    {
        if (!is_not_game()) 
        {
            if (is_user_connected(Players[i]))
            {
                set_user_footsteps( Players[i], 0)
                remove_task(TASK_INVISIBLE+Players[i])
                remove_task(TASK_RADAR+Players[i])
                if (get_bit(g_BackToCT, Players[i])) cs_set_user_team2(Players[i], CS_TEAM_CT)                
                client_infochanged(Players[i])
                set_user_maxspeed(Players[i], 250.0)
                menu_cancel(Players[i])
                if(g_GameMode == FireDay)
                    set_user_health(Players[i],1)
                if(g_GameMode == BugsDay && cs_get_user_team(Players[i]) == CS_TEAM_CT)
                {
                    set_pev(Players[i], pev_movetype, MOVETYPE_WALK)
                }
            }
        }
        if(is_user_alive(Players[i])){
            
            message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, Players[i] )
            write_short(12288)    // Duration
            write_short(12288)    // Hold time
            write_short(0x0001)    // Fade type
            write_byte (0)        // Red
            write_byte (0)        // Green
            write_byte (0)        // Blue
            write_byte (255)    // Alpha
            message_end()
        }
    }
    
    new max = 0, maxT = 0, maxCT = 0, maxdmg = 0, maxdmgT = 0, maxdmgCT = 0
    new name[32], name2[32]
    switch(g_GameMode)
    {
        case AlienHiddenDay, BugsDay, SpartaDay, SpartaTeroDay, NightDay, ZombieDay, ZombieTeroDay, GravityDay, HnsDay:
        {
            for (i=0; i<playerCount; i++)
                if(g_DamageDone[Players[i]] > maxdmg)
                {
                    max = Players[i]
                    maxdmg = g_DamageDone[max]
                }
            if(maxdmg > 0)
            {    
                get_user_name(max, name, charsmax(name))
                ColorChat(0, TEAM_COLOR, "^x03%s^x01 a facut cel mai mult damage (^x04 %d^x01 ) in acest Day. A primit un bonus de^x04 bani^x01 si^x04 puncte^x01.", name, g_DamageDone[max])
                cs_set_user_money(max, cs_get_user_money(max) + 8000)
                server_cmd("give_points %d 8", max)
            }
        }
        case ColaDay, GunDay, SpiderManDay, CowboyDay, ScoutDay:
        {
            for (i=0; i<playerCount; i++)
            {
                if(cs_get_user_team(Players[i]) == CS_TEAM_T)
                    if(g_DamageDone[Players[i]] > maxdmgT)
                    {
                        maxT = Players[i]
                        maxdmgT = g_DamageDone[maxT]
                    }
                if(cs_get_user_team(Players[i]) == CS_TEAM_CT)
                    if(g_DamageDone[Players[i]] > maxdmgCT)
                    {
                        maxCT = Players[i]
                        maxdmgCT = g_DamageDone[maxCT]
                    }
            }
            if(maxdmgCT > 0 && maxdmgT > 0)
            {
                get_user_name(maxT, name, charsmax(name))
                get_user_name(maxCT, name2, charsmax(name2))
                ColorChat(0, RED, "^x03%s^x01 este Prizonierul care a facut cel mai mult damage (^x04 %d^x01 ). A primit un bonus de^x04 bani^x01 si^x04 puncte^x01.", name, g_DamageDone[maxT])
                cs_set_user_money(maxT, cs_get_user_money(maxT) + 8000)
                server_cmd("give_points %d 8", maxT)
                ColorChat(0, BLUE, "^x03%s^x01 este Gardianul care a facut cel mai mult damage (^x04 %d^x01 ). A primit un bonus de^x04 bani^x01 si^x04 puncte^x01.", name2, g_DamageDone[maxCT])
                cs_set_user_money(maxCT, cs_get_user_money(maxCT) + 8000)
                server_cmd("give_points %d 8", maxCT)
            }
        }
    }
    for (i=1; i<=g_MaxClients; i++)
    {
        g_Donated[i] = 0
        g_DamageDone[i] = 0
        g_BoxLastY[i] = 0
        Set_Hat(i, 0)
    }
    set_dhudmessage( random_num( 1, 255 ), random_num( 1, 255 ), random_num( 1, 255 ), -1.0, 0.71, 2, 6.0, 3.0, 0.1, 1.5 );
    show_dhudmessage( 0, "[ Ziua a luat sfarsit ]^n[ Toata lumea la somn ]");
    g_Countdown = 0
    remove_task(TASK_RADAR)
    g_BackToCT = 0
    server_cmd("jb_unblock_teams")
    g_DoNotAttack = 0
    g_FriendlyFire = 0
    g_GameWeapon[0]=g_GameWeapon[1]= 0

    remove_task(TASK_STATUS)
    remove_task(TASK_FREEDAY)
    remove_task(TASK_FREEEND)
    remove_task(TASK_ROUND)
    remove_task(TASK_GIVEITEMS)
    remove_task(TASK_FD_TIMER)
    g_GamePrepare = 0
    g_GameMode = NormalDay
    FreedayTime = 1
}

public SimonAllowed()
{
    g_SimonAllowed = 1 
}
public remove_all_fd()
{
    if(g_GameMode != NormalDay || FreedayRemoved == 1 || FreedayTime == 1)
        return PLUGIN_CONTINUE
    new playerCount, i 
    new Players[32] 
    new rez
    FDnr = 0
    Tnr = 0
    Wnr = 0
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++)
        if(cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]))
        {
            if(!get_bit(g_PlayerWanted, Players[i]) && get_bit(g_PlayerFreeday, Players[i]))
                FDnr++
            else if(!get_bit(g_PlayerWanted, Players[i]) && !get_bit(g_PlayerFreeday, Players[i]))
                Tnr++
            else if(get_bit(g_PlayerWanted, Players[i]))
                Wnr++
        }
    if(FDnr > 0 && Tnr <= 1 && Wnr == 0)
    {
        for (i=0; i<playerCount; i++) 
        {
            if(cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && get_bit(g_PlayerFreeday, Players[i]) && !get_bit(g_PlayerWanted, Players[i]))
            {
                clear_bit(g_PlayerFreeday, Players[i])
                if(check_model(Players[i])==false)
                    set_user_rendering(Players[i], kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
                rez = random_num(0,3)
                if( rez >= 0 && rez <= 3)
                {
                    entity_set_int(Players[i], EV_INT_skin, rez)
                }
                else{
                    log_amx("Caugth rez to be %d",rez)
                    entity_set_int(Players[i], EV_INT_body, 0)
                }
                if (get_pcvar_num (gp_ShowColor) == 1 ) show_color(Players[i])    
            }
        }
        ColorChat(0, RED, "^x01 Toti prizonierii care aveau^x04 FD^x01 trebuie sa se prezinte la^x03 comenzi^x01.")
        emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        set_dhudmessage(0, 255, 0, -1.0, 0.35, 0, 6.0, 15.0)
        show_dhudmessage(0, "%L", LANG_SERVER, "UJBM_STATUS_ENDFREEDAY")
        FreedayRemoved = 1
    }
    return PLUGIN_CONTINUE
}
public FreedayTimeDone()
{
    FreedayTime = 0
    remove_all_fd()
    switch(g_JailDay%7)
    {
        case 1, 2, 4:
        {
            ColorChat(0, RED, "^x01 De acum se poate primi/cumpara^x04 FD^x01 doar pentru^x03 runda urmatoare^x01.")
        }
        case 5:
        {
            ColorChat(0, RED, "^x01 De acum nu se mai poate primi/cumpara^x04 FD^x01. Daca un gardian va da^x04 FD^x01 pentru ziua urmatoare il veti primi automat^x03 luni^x01.")
        }
    }
}

public round_start()
{
    set_cvar_num("ers_enabled", 1)
    FreedayTime = 1
    FreedayRemoved = 0
    g_newChance = 1
    g_CantChoose = 0
    set_task(100.0,"FreedayTimeDone",TASK_FD_TIMER)
    gc_TalkMode = get_pcvar_num(gp_TalkMode)
    gc_VoiceBlock = get_pcvar_num(gp_VoiceBlock)
    gc_SimonSteps = get_pcvar_num(gp_SimonSteps)
    gc_ButtonShoot = get_pcvar_num(gp_ButtonShoot)
    get_pcvar_string(gp_TShop, Tallowed,31)
    get_pcvar_string(gp_CTShop, CTallowed,31)
    get_pcvar_string(gp_Bind, bindstr,32)
    g_GameMode = NormalDay
    g_SimonAllowed = 0
    killed = 0
    killedonlr = 0
    g_nogamerounds++
    resetsimon()

    new g_Time[ 9 ];
    get_time( "%H:%M:%S", g_Time, 8 )
    
    g_IsFG = random_num(0,6)
    
    switch( g_JailDay%7 )
    {
        case 1: Day = "Luni"
        case 2: Day = "Marti"
        case 3: {
            Day = "Miercuri" // "Miercurea Speciala"
            //g_GamePrepare = 1;
            //set_task(1.0,"CheckVoteDay",TASK_ROUND)
            }
        case 4: Day = "Joi"
        case 5: Day = "Vineri"
        case 6: {
            Day = "Sambata Speciala"
            //client_cmd( 0, "mp3 play ^"%s^"", sDay )
            //set_task(5.0, "ActionRandomDay")
            if(g_JailDay==-1){
                set_task(10.0,"cmd_expire_time",TASK_ROUND)
            }
            else{
                g_GamePrepare = 1;
                set_task(1.0,"CheckVoteDay",TASK_ROUND)
            }
        }
        case 0: {
            
            Day = "Duminica Libera"
            g_Simon = 0
            g_SimonAllowed = 0
            g_GameMode = Freeday
            emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            hud_status(0)
            jail_open()
            new Players[32] 
            new playerCount, i 
            get_players(Players, playerCount, "ac")
            for (i=0; i<playerCount; i++) 
            {
                entity_set_int(Players[i], EV_INT_skin, 4)
            }
            set_task(300.0,"cmd_expire_time",TASK_ROUND)
        }
    }
    
    set_dhudmessage( random_num( 1, 255 ), random_num( 1, 255 ), random_num( 1, 255 ), -1.0, 0.71, 2, 6.0, 3.0, 0.1, 1.5 );
    show_dhudmessage( 0, "[ Ziua %d, %s ]^n[ %s ]", g_JailDay, Day, g_Time, g_Map);
    
    if(g_RoundEnd)
        return
    new bool:ok=false
    for(new i = ZombieDay; i<_days;i++)
        ok = ok | g_GamesAp[i]
    if(ok == false)
        for(new i = ZombieDay; i<_days;i++)
            g_GamesAp[i]=false
    set_task(HUD_DELAY, "hud_status", TASK_STATUS, _, _, "b")
    set_task(random_float(2.0,5.0), "SimonAllowed")
    set_task(5.0, "task_last", TASK_LAST)
    server_cmd("bh_enabled 1")    
}

public play_sound_police ()
{    
    new sunet = random_num(0, sizeof(_PoliceSounds) - 1)
    for(new i = 1; i <= g_MaxClients; i++)
    {
        if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
            emit_sound(i, CHAN_AUTO, _PoliceSounds[sunet], 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
}

public resetsimon ()
{
    new Players[32]     
    new playerCount, i, ok=0
    get_players(Players, playerCount, "a") 
    for (i=0; i<playerCount; i++) 
    {
        if (cs_get_user_team(Players[i])==CS_TEAM_CT && Simons[Players[i]]==0)
        {
            ok=1;
            break;
        }
    }
    if(ok == 0)
    {
        for (i=0; i<playerCount; i++) 
        {
            if (cs_get_user_team(Players[i])==CS_TEAM_CT)
                Simons[Players[i]]=0
        }
    }
}
public cmd_whosimon(id)
{
    new Players[32], name[32]    
    new playerCount, i
    get_players(Players, playerCount, "a") 
    for (i=0; i<playerCount; i++) 
    {
        if (cs_get_user_team(Players[i])==CS_TEAM_CT)
        {
            get_user_name(Players[i], name, charsmax(name))
            client_print(id,print_chat,"%s : %d",name,Simons[Players[i]])
        }
    }
}
public cmd_voiceon(id)
{
    client_cmd(id, "+voicerecord")
    set_bit(g_SimonVoice, id)
    if(g_Simon == id || get_user_flags(id) & VOICE_ADMIN_FLAG)
        set_bit(g_SimonTalking, id)
    return PLUGIN_HANDLED
}
public cmd_voiceoff(id)
{
    client_cmd(id, "-voicerecord")
    clear_bit(g_SimonVoice, id)
    if(g_Simon == id || get_user_flags(id) & VOICE_ADMIN_FLAG)
        clear_bit(g_SimonTalking, id)
    return PLUGIN_HANDLED
}
public cmd_simon(id)
{
    static CsTeams:team, name[32]
    if(!is_user_connected(id))
        return PLUGIN_HANDLED
    team = cs_get_user_team(id)
    if(g_SimonAllowed == 1 && is_not_game() && team == CS_TEAM_CT && is_user_alive(id) && !g_Simon && Simons[id]==0  && !is_user_alive(g_PlayerLast) && g_JailDay%7!=0)
    {
        Simons[id]=1
        SimonTimes[id]++
        g_Simon = id
        server_cmd("painttero %d",g_Simon)
        get_user_name(id, name, charsmax(name))
        entity_set_int(id, EV_INT_body, 1)
        
        if(get_pcvar_num(gp_GlowModels))
            player_glow(id, g_Colors[0])
        give_item(id, "weapon_p228")
        give_item(id, "ammo_357sig")
        give_item(id, "ammo_357sig")
        give_item(id, "ammo_357sig")
        give_item(id, "ammo_357sig")
        cmd_simonmenu(id)
        //hud_status(0)
    }
    return PLUGIN_HANDLED
}
public cmd_open(id)
{
    if(!g_CanOpen)
        return PLUGIN_HANDLED
    if(id == g_Simon || (get_user_flags(id) & ADMIN_SLAY) || !is_not_game() || g_GameMode == Freeday){
        jail_open()
        new name[32]
        get_user_name(id, name, 31)
        ColorChat(0, BLUE, "^x03%s^x01 A DESCHIS^x04 USA^x01!!!", name)
        emit_sound(0, CHAN_AUTO, "jbextreme/opendoor3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        g_CanOpen = 0
        set_task(5.0, "resetOpen")
    }
    return PLUGIN_HANDLED
}

public resetOpen()
{
    g_CanOpen = 1
}

public cmd_box(id)
{
    if((id == g_Simon || (get_user_flags(id) & ADMIN_SLAY)) && g_GameMode == NormalDay)
    {
        new Players[32] 
        new playerCount, i, TAlive
        
        get_players(Players, playerCount, "ac") 
        for (i=0; i<playerCount; i++) 
        {
            if (is_user_connected(Players[i])) 
                if ( cs_get_user_team(Players[i]) == CS_TEAM_T )
                    TAlive++;
        }
        if(TAlive<= get_pcvar_num(gp_BoxMax) && TAlive > 1)
        {
            if(g_BoxStarted == 0){
                for(i = 1; i <= g_MaxClients; i++)
                    if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
                    set_user_health(i, 100)
                new dst[50]
                get_user_name(id, dst, 49)
                set_cvar_num("mp_tkpunish", 0)
                set_cvar_num("mp_friendlyfire", 1)
                g_BoxStarted = 1
                player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_BOX_START")
                emit_sound(0, CHAN_AUTO, "jbextreme/rumble.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                ColorChat(0, BLUE, "^x03%s^x01 A ACTIVAT^x04 BOX^x01!!!", dst)
                client_print(0, print_console, "%s A ACTIVAT BOX!!!", dst)
                log_amx("%s A ACTIVAT BOX", dst)
            }
            else{
                new dst[50]
                get_user_name(id, dst, 49)
                set_cvar_num("mp_tkpunish", 0)
                set_cvar_num("mp_friendlyfire", 0)
                g_BoxStarted = 0
                player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_BOX_STOP")
                ColorChat(0, BLUE, "^x03%s^x01 A DEZACTIVAT^x04 BOX^x01!!!", dst)
                client_print(0, print_console, "%s A DEZACTIVAT BOX!!!", dst)
                log_amx("%s A DEZACTIVAT BOX", dst)
            }
        }
        else
        {
            client_print(id, print_center, "%L", LANG_SERVER, "UJBM_GUARD_CANTBOX")
        }
    }
    return PLUGIN_HANDLED
}
public cmd_help(id)
{
    if(id > g_MaxClients)
        id -= TASK_HELP
    
    remove_task(TASK_HELP + id)
    
    show_motd(id,"rules.txt","Ultimate Jail Break Manager");
}
public cmd_minmodels(id)
{
    if(id > g_MaxClients)
        id -= TASK_HELP
    remove_task(TASK_HELP + id)
    if(is_user_bot(id) || !is_user_connected(id))
        return
    query_client_cvar(id, "cl_minmodels", "cvar_result_func"); 
}

public cmd_nosleep(id)
{
    if(!is_user_alive(id) || g_Duel >=FreeGun || !is_not_game() || /*g_JailDay%7 == 3 ||*/  g_JailDay%7 == 6 || cs_get_user_team(id) == CS_TEAM_CT)
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}
public cmd_adminchoosesimon(id)
{
    if (g_SimonAllowed == 1 && g_GameMode == NormalDay && is_not_game() && (get_user_flags(id) & ADMIN_SLAY) && g_Simon==0)
    {
        static i, name[32], num[5], menu, menuname[32]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMON")
        menu = menu_create(menuname, "admin_select_simon")
        for(i = 1; i <= g_MaxClients; i++)
        {
            if(!is_user_connected(i) || !is_user_alive(i) || (id == i))
                continue
            if(Simons[i] == 0 && CS_TEAM_CT == cs_get_user_team(i))
            {
                get_user_name(i, name, charsmax(name))
                num_to_str(i, num, charsmax(num))
                menu_additem(menu, name, num, 0)
            }
        }
        menu_display(id, menu)
    }
}

public admin_select_simon(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    
    static dst[32], data[5], player, access, callback, simonname[32]
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    player = str_to_num(data)
    
    if(g_SimonAllowed != 1 || !is_not_game() || !is_user_connected(player) || !is_user_alive(player) || g_Simon!=0 || Simons[player] != 0 || CS_TEAM_CT != cs_get_user_team(player))
    {
        return PLUGIN_HANDLED
    }
    
    get_user_name(id, dst, charsmax(dst))
    get_user_name(player,simonname,charsmax(simonname))
    
    client_print(0, print_console, "%s l-a ales ca Simon pe %s", dst, simonname)
    log_amx("%s l-a ales ca Simon pe %s", dst, simonname)
    ColorChat(0, BLUE, "^x03%s^x01 l-a ales ca^x04 Simon^x01 pe^x03 %s^x01!", dst, simonname)
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_CHOOSE_SIMON", dst, simonname)
    client_cmd(0,"spk vox/dadeda")
    cmd_simon(player)
    
    return PLUGIN_HANDLED
}
public cmd_removefd(id)
{
    if(get_user_flags(id) & ADMIN_KICK)
        menu_players(id, CS_TEAM_T, id, 1, "removefd_select", "%L", LANG_SERVER, "UJBM_MENU_REMOVE_FD")
}
public removefd_select(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    
    static src[32], dst[32], data[5], player, access, callback
    new rez
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    get_user_name(id, src, charsmax(src))
    get_user_name(player, dst, charsmax(dst))
    if(get_bit(g_PlayerFreeday, player))
    {
        clear_bit(g_PlayerFreeday, player)
        if(check_model(player)==false)
            set_user_rendering(player, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
        rez = random_num(0,3)
        if( rez >= 0 && rez <= 3)
        {
            entity_set_int(player, EV_INT_skin, rez)
        }
        else{
            log_amx("Caugth rez to be %d",rez)
            entity_set_int(player, EV_INT_body, 0)
        
        }
        ColorChat(0, RED, "^x03%s^x01 i-a scos^x04 FD-ul^x01 lui^x03 %s^x01!", src, dst)
        client_print(0, print_console, "%s i-a scos FD-ul lui %s", src, dst)
    }
    menu_destroy(menu)
    
    return PLUGIN_HANDLED
}

public cmd_givemoneyForTest(id)
{
    cs_set_user_money(id,16000);
}

public cmd_freeday(id)
{
    if (g_GameMode == NormalDay && FreedayTime == 1)
    {
        static menu, menuname[32], option[64]
        if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || (get_user_flags(id) & ADMIN_SLAY))
        {
            formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
            menu = menu_create(menuname, "freeday_choice")
            
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_PLAYER")
            menu_additem(menu, option, "1", 0)
            
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_PLAYER_NEXT")
            menu_additem(menu, option, "2", 0)
            
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_ALL")
            menu_additem(menu, option, "3", 0)
            
            menu_display(id, menu)
        }
    }
    if (g_GameMode == Freeday || (g_GameMode == NormalDay && !FreedayTime))
    {
        static menu, menuname[32], option[64]
        if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || (get_user_flags(id) & ADMIN_SLAY))
        {
            formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
            menu = menu_create(menuname, "freeday_choice_fdall")         
            
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_PLAYER_NEXT")
            menu_additem(menu, option, "1", 0)
            
            menu_display(id, menu)
        }
    }
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
            cmd_freeday_player(id,false)
        }
        case('2'):
        {
            cmd_freeday_player(id,true)
        }
        case('3'):
        {
            if((id == g_Simon && SimonTimes[id] >= 2) || (get_user_flags(id) & ADMIN_SLAY))
            {
                g_Simon = 0
                get_user_name(id, dst, charsmax(dst))
                client_print(0, print_console, "%s a dat FD All", dst)
                ColorChat(0, BLUE, "^x03%s^x01 a dat^x04 FD All^x01!", dst)
                server_print("JBE Client %i a dat FD All", id)
                g_GameMode = Freeday
                emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                hud_status(0)
                jail_open()
                new Players[32] 
                new playerCount, i 
                get_players(Players, playerCount, "ac")
                for (i=0; i<playerCount; i++) 
                {
                    entity_set_int(Players[i], EV_INT_skin, 4)
                }
                new Float:FDLEN = get_pcvar_float(gp_FDLength) 
                if (FDLEN < 20.0) FDLEN = 99999.0
                set_task(FDLEN, "task_freeday_end",TASK_FREEEND)
            }
        }
    }
    return PLUGIN_HANDLED
}
public freeday_choice_fdall(id, menu, item)
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
            cmd_freeday_player(id,true)
        }
    }
    return PLUGIN_HANDLED
}
public cmd_freeday_player(id,bool:next)
{
    if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || (get_user_flags(id) & ADMIN_SLAY))
    {
        if(next == true)
            menu_players(id, CS_TEAM_T, id, 2, "freeday_select_next", "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
        else
            menu_players(id, CS_TEAM_T, id, 1, "freeday_select", "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
    }
    return PLUGIN_CONTINUE
}
public cmd_punish(id)
{
    if((id  == g_Simon) || (get_user_flags(id) & ADMIN_SLAY) )
        menu_players(id, CS_TEAM_CT, id, 1, "cmd_punish_ct", "%L", LANG_SERVER, "UJBM_MENU_PUNISH")
    return PLUGIN_CONTINUE
}
public is_not_game()
    return  ((g_GameMode == Freeday || g_GameMode == NormalDay) && g_GamePrepare==0)
    
public cmd_lastrequest(id)
{   
    static i, menu, menuname[32], option[64]
    if (!is_user_alive(g_PlayerLast))
        return PLUGIN_CONTINUE
    new Players[32] 
    new playerCount, CTAlive =0
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT )            CTAlive++;
    }    
    if(!get_pcvar_num(gp_LastRequest) || !is_not_game() || g_Duel != 0 || g_PlayerLast !=id || !is_user_alive(id) || CTAlive==0 || get_bit(g_PlayerWanted, id))
        return PLUGIN_CONTINUE
    
    if(g_JailDay%7 == 0)
    {
        remove_task(TASK_ROUND)
    }
    server_cmd("bh_enabled 0")
    server_cmd("sleep_enabled 0")
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ")
    menu = menu_create(menuname, "lastrequest_select")
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT1")
    menu_additem(menu, option, "1", 0)
    if (killedonlr == 0)
    {    
        formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_SIMON_GAMES")
        menu_additem(menu, option, "0", 0)
        if(g_IsFG == 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT2")
            menu_additem(menu, option, "2", 0)
        }
    }
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT3")
    menu_additem(menu, option, "3", 0)
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT4")
    menu_additem(menu, option, "4", 0)
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT5")
    menu_additem(menu, option, "5", 0)
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT6")
    menu_additem(menu, option, "6", 0)
    
    
    if(g_newChance)
    {
        g_canTrivia = CTAlive/2
        g_newChance = 0
    }
    if(g_canTrivia)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT7")
        menu_additem(menu, option, "7", 0)
    }
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT8")
    menu_additem(menu, option, "8", 0)
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT9")
    menu_additem(menu, option, "9", 0)
    
    menu_display(id, menu)
    return PLUGIN_CONTINUE
}
public lastrequest_select(id, menu, item)
{
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel != 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id) || g_RoundEnd || g_CantChoose)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static i, dst[32], data[5], access, callback, option[64],nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    get_user_name(id, dst, charsmax(dst))
    nr = str_to_num(data)
    g_Duel = nr
    switch(nr)
    {
        case(LrMoney):
        {
            client_cmd(0, "spk jbDobs/SurpriseMotherfucker.wav")
            user_silentkill(id)
            cs_set_user_money(id,cs_get_user_money(id)+16000,1)
            ColorChat(0, RED, "^x03%s^x01 a selectat^x04 16000$^x01!", dst)
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL1", dst)
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
        }
        case(FreeGun):
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL2", dst)
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
            player_strip_weapons_all()
            i = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(id, _WeaponsFree[i])
            server_cmd("jb_block_weapons")
            cs_set_user_bpammo(id, _WeaponsFreeCSW[i], _WeaponsFreeAmmo)
            set_task(120.0,"cmd_expire_time",TASK_ROUND)
            g_Countdown=120
            set_task(1.0,"cmd_saytime",TASK_SAYTIME);
            
        }
        case(DuelKnives):
        {
            menu_players(id, CS_TEAM_CT, 0, 1, "duel_knives", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
        }
        case(LrGame):
        {
            cmd_lrgame(id)
        }
        case(Shot4Shot):
        {
            //server_cmd("bh_noslowdown 0")
            shoot4shootmenu(id)
        }
        default:
        {
            menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
            DuelWeapon = nr-Catea;
        }
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public shoot4shootmenu(id)
{
    static i, menu_s4s, menuname[32], num[5],  option[64]
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_S4S")
    menu_s4s = menu_create(menuname, "shot4shot_select")

    for(i = 5; i < sizeof(_Duel); i++)
    {
        num_to_str(i, num, charsmax(num))
        formatex(option, charsmax(option), "%s", _Duel[i][_opt])
        menu_additem(menu_s4s, option, num, 0)
    }
    menu_display(id, menu_s4s)
    return PLUGIN_CONTINUE
}

public shot4shot_select(id, menu, item)
{
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel == 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        g_Duel = 0
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback,nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    nr = str_to_num(data)
    DuelWeapon = nr
    switch(_Duel[nr][_csw])
    {
        case CSW_SCOUT, CSW_AWP, CSW_AUG, CSW_G3SG1, CSW_SG550, CSW_SG552:
        {
            scope_menu(id)
        }
        default:
        {
            menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
        }
        
    }
    menu_destroy(menu)
    return PLUGIN_CONTINUE
}

public scope_menu(id)
{
    static  menu_scope, menuname[32], option[64]
    
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SCOPE")
    menu_scope = menu_create(menuname, "scope_select")
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SCOPE1")
    menu_additem(menu_scope, option, "1", 0)

    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SCOPE0")
    menu_additem(menu_scope, option, "0", 0)
    
    menu_display(id, menu_scope)
}

public scope_select(id, menu, item)
{
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel == 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        g_Duel = 0
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback,nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    nr = str_to_num(data)
    if(nr == 1)
    {
        g_Scope = 1
    }
    else
    {
        g_Scope = 0
    }
    menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
    menu_destroy(menu)
    return PLUGIN_CONTINUE
}

public cmd_lrgame(id)
{
    static menu, menuname[32], option[64]
    if(!get_pcvar_num(gp_LastRequest) || !get_pcvar_num(gp_LastRequest) || g_Duel != 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id))
        return PLUGIN_CONTINUE    
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ")
    menu = menu_create(menuname, "lastrequestgames_select")
    
    formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZM")
    menu_additem(menu, option, "1", 0)

    formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_ALIEN2")
    menu_additem(menu, option, "2", 0)
    
    menu_display(id, menu)
    return PLUGIN_CONTINUE
}
public lastrequestgames_select(id, menu, item)
{
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel != 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    get_user_name(id, dst, charsmax(dst))
    clear_bit(g_PlayerFreeday,id)
    new CTcount = 0;
    for (new i = 1; i <= g_MaxClients; i++)
        if (is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
        {
            CTcount++;
        }

    if(CTcount >=2 && (cs_get_user_money(id)>=16000 || get_vip_type(id)> 0)){
        server_cmd("bh_enabled 1")
        if(get_vip_type(id) == 0)
            cs_set_user_money(id,cs_get_user_money(id)-16000);
        switch(data[0])
        {
            case('1'):
            {
                cmd_pregame("start_Zombie_Tero", 1, 0, 15.0)                
            }
            case('2'):
            {
                cmd_pregame("start_Alien_Tero", 1, 0, 15.0)
            }
            default:
            {
                cmd_lrgame(id);
            }
        }
    }else{
        client_print(id,print_center,"Trebuie  sa fie minim 2 ct si sa ai 16000$")
        cmd_lrgame(id);
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public start_Zombie_Tero()
{
    new TeroPlayer = 0;
    new playerCount = 0;
    g_GameMode = ZombieDayT;
    g_DoNotAttack = 1;
    g_GameWeapon[1] = CSW_KNIFE;
    g_GameWeapon[0] = CSW_M3;
    for (new i = 1; i <= g_MaxClients; i++)
    {
        if (is_user_alive(i))
        {
            if (cs_get_user_team(i) == CS_TEAM_CT)
            {
                playerCount++;
                give_item(i, "weapon_knife");
                set_user_maxspeed(i, 200.0);
                set_user_health(i, 300);
                give_item(i, "item_assaultsuit");
                cs_set_user_nvg(i, true);
                entity_set_int(i, EV_INT_body, 6);
                message_begin(MSG_ONE, gmsgSetFOV, _, i);
                write_byte(170);
                message_end();
            }
            else
            {
                TeroPlayer = i;
                give_item(TeroPlayer, "weapon_knife")
                give_item(TeroPlayer, "weapon_m3")
                give_item(TeroPlayer, "weapon_hegrenade")
                give_item(TeroPlayer, "weapon_flashbang")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
                give_item(TeroPlayer, "ammo_buckshot")
            }
        }
    }

    if (playerCount > 3)
        set_user_health(TeroPlayer, 100 + 50 * (playerCount - 3))
    else
        set_user_health(TeroPlayer, 100);
    set_user_maxspeed(TeroPlayer, 250.0);
    set_bit(g_Fonarik, TeroPlayer);
    client_cmd(TeroPlayer, "impulse 100");
    player_glow(TeroPlayer, g_Colors[2]);

    emit_sound(0, CHAN_AUTO, "ambience/the_horror2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new effect = get_pcvar_num(gp_Effects)
    if (effect > 0)
    {
        set_lights("b")
        if (effect > 1) 
            fog(true)
    }
    player_hudmessage(0, 2, HUD_DELAY + 1.0, { 0, 255, 0 }, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM");
    set_task(300.0, "cmd_expire_time", TASK_ROUND);
    g_Countdown = 300;
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED;
}

public start_Alien_Tero()
{
    new TeroPlayer = 0;
    new playerCount = 0;
    g_GameMode = AlienDayT;
    g_DoNotAttack = 2;
    g_GameWeapon[0] = CSW_KNIFE;
    hud_status(0);
    for (new i = 1; i <= g_MaxClients; i++)
    {
        if (is_user_alive(i))
        {
            if (cs_get_user_team(i) == CS_TEAM_CT)
            {
                playerCount++;
                give_item(i, "weapon_knife");
                new j = random_num(0, sizeof(_WeaponsFree) - 1);
                give_item(i, _WeaponsFree[j]);
                cs_set_user_bpammo(i, _WeaponsFreeCSW[j], _WeaponsFreeAmmo);
                new n = random_num(0, sizeof(_WeaponsFree) - 1);
                while (n == j) {
                    n = random_num(0, sizeof(_WeaponsFree) - 1);
                }
                give_item(i, _WeaponsFree[n]);
                cs_set_user_bpammo(i, _WeaponsFreeCSW[n], _WeaponsFreeAmmo)
            }
            else
            {
                TeroPlayer = i;
                strip_user_weapons(i);
                task_inviz(i);
                set_user_maxspeed(i, 320.0);
                entity_set_int(i, EV_INT_body, 7);
                
                set_task(20.0, "give_items_alien_t", TASK_GIVEITEMS + i)
                set_task(2.5, "radar_alien_t", TASK_RADAR + i, _, _, "b")
                set_task(3.1, "task_inviz", TASK_INVISIBLE + i, _, _, "b");

            }
        }
    }
    new hp = get_pcvar_num(gp_GameHP)
    if (hp < 20) 
        hp = 200
    set_user_health(TeroPlayer, hp * playerCount)
    set_lights("z")
    emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
    set_task(5.0, "stop_sound")
    set_task(300.0, "cmd_expire_time", TASK_ROUND)
    g_Countdown = 300;
    set_task(1.0, "cmd_saytime", TASK_SAYTIME)
    return PLUGIN_HANDLED;
}

public Beacon(id)
{
    if(g_Duel == 0 || !is_user_alive(id))
        return 0
    if(cs_get_user_team(id) == CS_TEAM_CT)
    {
        static origin[3]
        get_user_origin(id, origin)
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_BEAMCYLINDER)
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-20)    
        write_coord(origin[0]) 
        write_coord(origin[1]) 
        write_coord(origin[2]+200)
        write_short(BeaconSprite)
        write_byte(0)
        write_byte(1)
        write_byte(6)
        write_byte(2) 
        write_byte(1) 
        write_byte(0) 
        write_byte(0) 
        write_byte(255) 
        write_byte(255)
        write_byte(0)
        message_end()
    }
    else
    {
        static origin[3]
        get_user_origin(id, origin)
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_BEAMCYLINDER)
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-20)    
        write_coord(origin[0]) 
        write_coord(origin[1])
        write_coord(origin[2]+200)
        write_short(BeaconSprite)
        write_byte(0)
        write_byte(1)
        write_byte(6)
        write_byte(2) 
        write_byte(1) 
        write_byte(255) 
        write_byte(0) 
        write_byte(0) 
        write_byte(255)
        write_byte(0)
        message_end()
    }
    set_task(1.0, "Beacon", id)    
    return PLUGIN_CONTINUE
}

public adm_freeday(id)
{
    static player, user[32]
    if(!(get_user_flags(id) & ADMIN_SLAY))
        return PLUGIN_CONTINUE
    read_argv(1, user, charsmax(user))
    player = cmd_target(id, user, 2)
    if(is_user_connected(player) && cs_get_user_team(player) == CS_TEAM_T)
    {
        freeday_set(id, player, false)
    }
    return PLUGIN_HANDLED
}
public adm_open(id)
{
    if(!(get_user_flags(id) & ADMIN_SLAY))
        return PLUGIN_CONTINUE
    
    jail_open()
    return PLUGIN_HANDLED
}
public adm_box(id)
{
    if(!(get_user_flags(id) & ADMIN_SLAY))
        return PLUGIN_CONTINUE
    
    cmd_box(-1)
    return PLUGIN_HANDLED
}
public revolt_start()
{    
    client_cmd(0,"speak ambience/siren")
    set_task(8.0, "stop_sound")
    hud_status(0)
}
public stop_sound(task)
{
    client_cmd(0, "stopsound")
}
public show_color(id)
{
    new n = 0;
    if (id == 0)
    {
        new Players[32] 
        new playerCount, i 
        get_players(Players, playerCount, "ac") 
        for (i=0; i<playerCount; i++) 
        {
            if (is_user_connected(Players[i]) && cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]))
            {
                n=entity_get_int(Players[i], EV_INT_skin);
                switch (n)
                {
                    case 0: 
                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_BLACK")
                    }
                    case 1: 
                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_ORANGE")
                    }
                    case 2: 

                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {255, 255, 255}, "%L", LANG_SERVER,    "UJBM__COLOR_WHITE")
                    }
                    case 3: 

                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {150, 200, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_YELLOW")
                    }
                    case 4: 

                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {0, 200, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_GREEN")
                    }
                    case 5: 

                    {
                        player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {200, 0, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_RED")
                    }
                }
                
            }
        }
    }
    else        
    {
        n=entity_get_int(id, EV_INT_skin);
        switch (n)
        {
            case 0: 
            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_BLACK")
            }
            case 1: 
            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_ORANGE")
            }
            case 2: 

            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {255, 255, 255}, "%L", LANG_SERVER,    "UJBM__COLOR_WHITE")
            }
            case 3: 

            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {150, 200, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_YELLOW")
            }
            case 4: 

            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {0, 200, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_GREEN")
            }
            case 5: 

            {
                player_hudmessage(id, 10, HUD_DELAY + 1.0, {200, 0, 0}, "%L", LANG_SERVER,    "UJBM__COLOR_RED")
            }
        }    
        
    }
}
stock show_count()
{
    new Players[32] 
    new playerCount, i,TAlive,TAll, TWanted, TFreeday, CTs
    new szStatus[64]
    get_players(Players, playerCount, "c") 
    for (i=0; i<playerCount; i++) 
    {
        if (is_user_connected(Players[i])) 
            if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
            {
                TAll++;
                if (is_user_alive(Players[i])) 
                {
                    if(!get_bit(g_PlayerWanted, Players[i]) && get_bit(g_PlayerFreeday, Players[i]))
                        TFreeday++
                    else if(!get_bit(g_PlayerWanted, Players[i]) && !get_bit(g_PlayerFreeday, Players[i]))
                    {
                        if(g_GameMode == Freeday)
                            TFreeday++
                        else
                            TAlive++
                    }
                    else if(get_bit(g_PlayerWanted, Players[i]))
                        TWanted++
                }
            }
        if ( cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
                CTs++
        }
    }
    TAll--
    CTs++
    if(TAll/CTs >= 2 && CTs <= 8)
    {
        formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_YES", TAlive, TWanted, TFreeday)
        message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
        write_byte(0)
        write_string(szStatus)
        message_end()
    }
    else
    {
        formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_NO", TAlive, TWanted, TFreeday)
        message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
        write_byte(0)
        write_string(szStatus)
        message_end()
    }
}

public hud_status(task)
{
    static i, n
    new name[32], szStatus[64], wanted[512], fdlist[512], playerCount, Players[32], Tnum = 0, CTnum = 0, ok = 0, Talive = 0
    if(g_RoundStarted < gp_RetryTime)
        g_RoundStarted++
    show_count()
    if(g_TimeRound != 0)
    {
        player_hudmessage(0, 12, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_TIMER", g_TimeRound)  
        g_TimeRound--
    }
    get_players(Players, playerCount, "c") 
    for (i=0; i<playerCount; i++)
    {
        if(cs_get_user_team(Players[i]) == CS_TEAM_CT)
            CTnum++
        if(cs_get_user_team(Players[i]) == CS_TEAM_T)
        {    
            Tnum++
            if(is_user_alive(Players[i]))
                Talive++
        }
    }
    if(g_GameMode == BoxDay && Talive == 1)
    {
        g_GameMode = NormalDay
        emit_sound(0, CHAN_AUTO, "jbextreme/boxwin.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        g_WasBoxDay = 1
        remove_task(TASK_ROUND)
        remove_task(TASK_SAYTIME)
    }
    Tnum--
    CTnum++
    if(Tnum/CTnum >= 2 && CTnum <= 8)
        ok=1
    if(ok)
        player_hudmessage(0, 4, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_LOCY")
    else
        player_hudmessage(0, 4, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_LOCN")      
    player_hudmessage(0, 11, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_OFERTA")  
    switch (g_GameMode)        
    {
        case Freeday:
        {
            if(g_BoxStarted == 0)
                box_last()
            n = 0
            n = formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "UJBM_PRISONER_WANTED")
            for(i = 1; i <= g_MaxClients; i++)
            {
                if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T && n < charsmax(wanted))
                {
                    get_user_name(i, name, charsmax(name))
                    n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
                    n += copy(wanted[n], charsmax(wanted) - n, name)
                    if(check_model(i)==false)
                        set_user_rendering(i, kRenderFxGlowShell, 70, 0, 0, kRenderNormal, 25)
                }
            }
            player_hudmessage(0, 2, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_FREEDAY")
            if(g_PlayerWanted)
                player_hudmessage(0, 3, HUD_DELAY, {255, 25, 50}, "%s", wanted)
            else if(g_PlayerRevolt)
                player_hudmessage(0, 3, HUD_DELAY, {255, 25, 50}, "%L", LANG_SERVER, "UJBM_PRISONER_REVOLT")
        }
        case NormalDay:
        {
            if (get_pcvar_num (gp_ShowColor) == 1 && g_Duel == 0) show_color(0)
            if (get_pcvar_num (gp_ShowFD) == 1) 
            {
                n = 0
                formatex(fdlist, charsmax(fdlist), "%L", LANG_SERVER, "UJBM_FREEDAY_SINGLE")
                n = strlen(fdlist)
                for(i = 1; i <= g_MaxClients; i++)
                {
                    if(get_bit(g_PlayerFreeday, i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T  && n < charsmax(fdlist))
                    {
                        get_user_name(i, name, charsmax(name))
                        n += copy(fdlist[n], charsmax(fdlist) - n, "^n^t")
                        n += copy(fdlist[n], charsmax(fdlist) - n, name)
                        if(check_model(i)==false )
                            set_user_rendering(i, kRenderFxGlowShell, 0, 70, 0, kRenderNormal, 25)
                    }
                }
                if(g_PlayerFreeday)        
                    player_hudmessage(0, 9, HUD_DELAY, {0, 255, 0}, "%s", fdlist)        
            }
            if (get_pcvar_num (gp_ShowWanted) == 1) 
            {    
                n = 0
                formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "UJBM_PRISONER_WANTED")
                n = strlen(wanted)
                for(i = 1; i <= g_MaxClients; i++)
                {
                    if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T && n < charsmax(wanted))
                    {
                        get_user_name(i, name, charsmax(name))
                        n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
                        n += copy(wanted[n], charsmax(wanted) - n, name)
                        if(check_model(i)==false)
                            set_user_rendering(i, kRenderFxGlowShell, 70, 0, 0, kRenderNormal, 25)
                    }
                }
                if(g_PlayerWanted)
                    player_hudmessage(0, 3, HUD_DELAY, {255, 25, 50}, "%s", wanted)
            }
            player_hudmessage(0, 0, HUD_DELAY, {0, 255, 0}, "[ Ziua %d, %s ]", g_JailDay, Day)
            if(g_Simon==0 && g_SimonAllowed==1 && g_JailDay!=-1 && g_GameMode!=Freeday && g_Duel == 0 && is_not_game() && !is_user_alive(g_PlayerLast))
            {
                resetsimon()
                cmd_simon(random_num(1,g_MaxClients))
            }
            else  if (g_Simon  != 0)
            {
                get_user_name(g_Simon, name, charsmax(name))
                player_hudmessage(0, 2, HUD_DELAY, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_SIMON_FOLLOW", name)
            }
            if(g_PlayerRevolt)
                player_hudmessage(0, 3, HUD_DELAY, {255, 25, 50}, "%L", LANG_SERVER, "UJBM_PRISONER_REVOLT")
        }
        case ZombieDay:    
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ZOMBIEDAY")
        }
        case ZombieTeroDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ZOMBIETERODAY")
        }
        case HnsDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_HNS")
        }
        case AlienDay:
        {
            get_user_name(g_Simon, name, charsmax(name))
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ALIENDAY", name)
            formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_ALIENHP", get_user_health(g_Simon))
            message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
            write_byte(0)
            write_string(szStatus)
            message_end()
        }
        case AlienHiddenDay:
        {
            get_user_name(g_Simon, name, charsmax(name))
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ALIENDAY", name)
            formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_ALIENHP", get_user_health(g_Simon))
            message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
            write_byte(0)
            write_string(szStatus)
            message_end()
        }
        case GunDay:
        {
            if(g_HsOnly)
                player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_GUNDAY_HS")
            else
                player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_GUNDAY")
        }
        case ColaDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_COLADAY")
        }
        case GravityDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GRAVITY")
        }
        case FireDay:
        {
            get_user_name(g_Simon, name, charsmax(name))
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_FIREDAY",name)
        }
        case BugsDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_BUGSDAY")
        }
        case NightDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_NIGHTCRAWLER")
        }
        case SpartaDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_SPARTA")
        }
        case SpartaTeroDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_SPARTA")
        }
        case ScoutDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_SCOUTS")
        }
        case BoxDay:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_BOX")
        }
        case FunDay:
        {
            get_user_name(g_Simon, name, charsmax(name))
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_FUNDAY",name)
        }
        case SpiderManDay:
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_SPIDER")
        case CowboyDay:
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_COWBOY")
        /*case 15:
        {
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_PRINSELEA")
            player_hudmessage(Mata, 10, HUD_DELAY + 1.0, {200, 0, 0}, "%L", LANG_SERVER, "UJBM_GRAVITY_CATCHER")
            client_print(Mata,print_center,"%L",LANG_SERVER, "UJBM_GRAVITY_CATCHER")
        }*/
    }
}
public paint_select(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    
    static src[32], dst[32], data[5], player, access, callback
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    server_cmd("painttero %d",player)
    menu_destroy(menu)
    get_user_name(id, src, charsmax(src))
    ColorChat(0, BLUE, "^x03%s^x01 A SETAT LUI^x03 %s^x01 PAINT!", src, dst)
    return PLUGIN_HANDLED
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
    freeday_set(id, player, false)
    menu_destroy(menu)
    
    return PLUGIN_HANDLED
}
public freeday_select_next(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    
    static dst[32], data[5], player, access, callback
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    freeday_set(id, player, true)
    menu_destroy(menu)
    
    return PLUGIN_HANDLED
}

public duel_knives(id, menu, item)
{
    static dst[32], data[5], access, callback, option[128], player, src[32]
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel!=DuelKnives || !is_user_connected(player) || !is_user_alive(player) || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        g_Duel = 0
        return PLUGIN_HANDLED
    }
    

    get_user_name(id, src, charsmax(src))
    formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL3", src, LANG_SERVER, "UJBM_MENU_DUEL_SEL", src, dst)
    emit_sound(0, CHAN_AUTO, "jbextreme/rumble.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
    
    server_cmd("jb_block_weapons")
    
    g_DuelA = id
    strip_user_weapons(id)
    give_item(id, "weapon_knife")
    player_glow(id, g_Colors[3])
    cs_set_user_armor(id, 0, CS_ARMOR_NONE)
    set_user_health(id, 100)
    set_task(1.0, "Beacon", g_DuelA)
    
    g_DuelB = player
    strip_user_weapons(player)
    give_item(player, "weapon_knife")
    player_glow(player, g_Colors[2])
    set_user_health(player, 100)
    cs_set_user_armor(player, 0, CS_ARMOR_NONE)
    set_task(1.0, "Beacon", g_DuelB)
    return PLUGIN_HANDLED
}

public duel_guns(id, menu, item)
{
    static gun, dst[32], data[5], access, callback, option[256], player, src[32]
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel<Catea || g_Duel>Shot4Shot || !is_user_alive(player) ||  !is_user_alive(id) || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        g_Duel = 0
        return PLUGIN_HANDLED
    }
    
    get_user_name(id, src, charsmax(src))
    formatex(option, charsmax(option), "%s^n%L", _Duel[DuelWeapon][_sel], LANG_SERVER, "UJBM_MENU_DUEL_SEL", src, dst)
    emit_sound(0, CHAN_AUTO, "jbextreme/mareduel.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
    
    g_DuelA = id
    strip_user_weapons(id)
    player_glow(id, g_Colors[3])
    cs_set_user_armor(id, 0, CS_ARMOR_NONE)
    set_user_gravity(id, 1.0)
    set_user_maxspeed(id, 250.0)
    
    g_DuelB = player
    strip_user_weapons(player)
    player_glow(player, g_Colors[2])
    cs_set_user_armor(player, 0, CS_ARMOR_NONE)
    set_user_gravity(player, 1.0)
    set_user_maxspeed(player, 250.0)
    
    switch (_Duel[DuelWeapon][_csw])
    {
        case  CSW_M249:
        {
           
            gun = give_item(g_DuelA, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 2000)
            cs_set_user_bpammo(g_DuelA,CSW_M249,0)
            set_user_health(g_DuelA, 2000)
            entity_set_int(g_DuelA, EV_INT_body, 6)
           
            gun = give_item(g_DuelB, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 2000)
            set_user_health(g_DuelB, 2000)
            cs_set_user_bpammo(g_DuelB,CSW_M249,0)
            entity_set_int(g_DuelB, EV_INT_body, 6)
            server_cmd("jb_block_weapons")
        }
        case  CSW_FLASHBANG:
        {
            gun = give_item(g_DuelA, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelA, 2000)
            entity_set_int(g_DuelA, EV_INT_body, 6)
            current_weapon_fl(g_DuelA)
            
            gun = give_item(g_DuelB, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelB, 2000)
            entity_set_int(g_DuelB, EV_INT_body, 6)
            current_weapon_fl(g_DuelB)
            server_cmd("jb_block_weapons")
        }
        case 33:
        {
            if(random_num(1,2) == 1)
                gun = give_item(g_DuelA, _Duel[DuelWeapon][_entname])
            else
                gun = give_item(g_DuelB, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 6)
            RRturn = 1
            
            RussianRouletteBullet = random_num(1, 6)
            for(new i=1;i<=6;i++)
            {    
                RRammo[i]=0
            }
            player_hudmessage(id, 10, HUD_DELAY + 10.0, {200, 100, 0}, "%L", LANG_SERVER, "UJBM_RRSTART")
            server_cmd("jb_unblock_weapons")
        }
        case 34:
        {
            server_cmd("duel_trivia %d %d", g_DuelA, g_DuelB)
            g_canTrivia--
        }
        case 35:
        {
            client_print(0, print_chat, "In 3 secunde veti afla ce comanda trebuie sa faceti.")
            set_task(3.0, "ReactionDuel")
        }
        case 36:
        {
            new i = random_num(0, sizeof(_HsOnlyWeapons) - 1)
            HsOnlyWeapon = _HsOnlyWeaponsCSW[i]
            
            gun = give_item(g_DuelA, _HsOnlyWeapons[i])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelA, 100)
            
            gun = give_item(g_DuelB, _HsOnlyWeapons[i])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelB, 100)
            
            server_cmd("jb_block_weapons")
        }
        case CSW_HEGRENADE:
        {    
            give_item( g_DuelA, "weapon_hegrenade" );
            cs_set_user_bpammo(g_DuelA, CSW_HEGRENADE, 1)
            set_user_health(g_DuelA, 200)

            give_item( g_DuelB, "weapon_hegrenade" );
            cs_set_user_bpammo(g_DuelB, CSW_HEGRENADE, 1)
            set_user_health(g_DuelB, 200)
            server_cmd("jb_block_weapons")
        }
        default:
        {
            
            gun = give_item(g_DuelA, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelA, 100)
                        
            gun = give_item(g_DuelB, _Duel[DuelWeapon][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelB, 100)
            server_cmd("jb_block_weapons")
            
        }    
    }
    set_task(1.0, "Beacon", g_DuelA)
    set_task(1.0, "Beacon", g_DuelB)
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

stock freeday_set(id, player,bool:next)
{
    static src[32], dst[32]
    get_user_name(player, dst, charsmax(dst))
    
    if(is_user_alive(player) && !get_bit(g_PlayerWanted, player))
    {
        set_bit(g_PlayerFreeday, player)
        fadeout(player, 0, 100, 0)
        entity_set_int(player, EV_INT_skin, 4)
        if(get_pcvar_num(gp_GlowModels))
            player_glow(player, g_Colors[1])
        
        if(0 < id <= g_MaxClients)
        {
            get_user_name(id, src, charsmax(src))
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_FREEDAYGIVE", src, dst)
            new sz_msg[256];
            formatex(sz_msg, charsmax(sz_msg), "%L", LANG_SERVER, "UJBM_GUARD_FREEDAYGIVE", src, dst)
            client_print(0,print_console,sz_msg)
        }
        else if(g_GameMode == NormalDay)
        {
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_HASFREEDAY", dst)
            ColorChat(0, RED, "^x03%s^x01 si-a cumparat^x04 FD^x01!", dst)
        }
    }
    if(next == true)
    {
        if(0 < id <= g_MaxClients && is_user_connected(id))
        {
            set_bit(g_PlayerNextFreeday, player)
            get_user_name(id, src, charsmax(src))
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_FREEDAYGIVE_NEXT", src, dst)
            new sz_msg[256];
            formatex(sz_msg, charsmax(sz_msg), "%L", LANG_SERVER, "UJBM_GUARD_FREEDAYGIVE_NEXT", src, dst)
            client_print(0,print_console,sz_msg)
        }
    }
}

stock first_join(id)
{
    if (get_bit(g_PlayerJoin, id)) return PLUGIN_CONTINUE
    
    switch (get_pcvar_num(gp_Help))
    {
        case 1:{
            set_task(5.0, "cmd_help", TASK_HELP + id)
        }
        case 2:{
            if (!(get_user_flags(id) & ADMIN_SLAY))    
                set_task(5.0, "cmd_help", TASK_HELP + id)
        }
    }
    set_task(20.0, "cmd_minmodels", TASK_HELP + id)
    set_bit(g_PlayerJoin, id)
    clear_bit(g_PlayerHelp, id)
    
    return PLUGIN_CONTINUE
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
    static text[512], Float:x, Float:y
    x = g_HudSync[hudid][_x]
    y = g_HudSync[hudid][_y]

    if(time > 0)
        set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
    else
        set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)
        
    vformat(text, charsmax(text), msg, 6)
    show_dhudmessage(id, text)
}

stock menu_players(id, CsTeams:team, skip, alive, callback[], title[], any:...)
{
    static i, name[32], num[5], menu, menuname[32]
    vformat(menuname, charsmax(menuname), title, 7)
    menu = menu_create(menuname, callback)
    for(i = 1; i <= g_MaxClients; i++)
    {
        if(!is_user_connected(i) || (alive == 1 && !is_user_alive(i) || alive == 2 && is_user_alive(i)) || (skip == i))
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

stock player_strip_weapons_all()
{
    for(new i = 1; i <= g_MaxClients; i++)
    {
        if(is_user_alive(i))
        {
            disarm_player(i)
        }
    }
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

public fog(bool:on)
{
    if (on)
    {
        message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
        write_byte(random_num(180,244))  // R
        write_byte(1)  // G
        write_byte(1)  // B
        write_byte(10) // SD
        write_byte(41)  // ED
        write_byte(95)   // D1
        write_byte(59)  // D2
        message_end()    
        
    }
    else
    {
        message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
        write_byte(0)  // R
        write_byte(0)  // G
        write_byte(0)  // B
        write_byte(0) // SD
        write_byte(0)  // ED
        write_byte(0)   // D1
        write_byte(0)  // D2
        message_end()
    }
}
public client_infochanged(id) 
{ 
    if (is_user_connected(id))
    {
        new szModel[50]
        new ok = 0
        get_user_info(id,"model",szModel,sizeof(szModel))
        new i
        for(i = 0; i < sizeof(GucciModels); i++)
            if(equali(szModel,GucciModels[i]))
            {
                ok = 1
                break
            }
        if (get_vip_type(id) == 0 && g_GameMode != FunDay && id != g_Simon && !(get_user_flags(id) & ADMIN_SLAY) && cs_get_user_team(id) != CS_TEAM_SPECTATOR && !ok)
            set_user_info(id, "model", JBMODELSHORT)
    }    
    return PLUGIN_CONTINUE
} 

public cvar_result_func(id, const cvar[], const value[]) 
{ 
    if (value[0] != '0') Showcl_min(id)
}
public fade_screen (id, bool:on)
{
    if(on)
    {
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
        write_short(~0)      // Duration
        write_short(~0)      // Hold time
        write_short(0x0004)      // Fade type
        write_byte (0)           // Red
        write_byte (0)            // Green
        write_byte (0)            // Blue
        write_byte (255)        // Alpha
        message_end()
    }
    else
    {
        message_begin( MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
        write_short( 0 )
        write_short( 0 )
        write_short( 0 )
        write_byte( 0 )
        write_byte( 0 )
        write_byte( 0 )
        write_byte( 0 )
        message_end( );
    }
}
public cmd_saytime()
{
    g_TimeRound = g_Countdown;
    new word[10];
    num_to_word(g_Countdown, word, 9);
    remove_task(TASK_SAYTIME);
    if(g_Countdown > 60){
        num_to_word(g_Countdown/60,word, 9);
        client_cmd(0, "spk ^"vox/%s minutes remaining^"", word);
        g_Countdown -= 60;
        set_task(60.0,"cmd_saytime",TASK_SAYTIME);
    }else if(g_Countdown > 10){
        client_cmd(0, "spk ^"vox/%s seconds remaining^"", word);
        g_Countdown -= 10;
        set_task(10.0,"cmd_saytime",TASK_SAYTIME)
    }else if(g_Countdown > 0){
        client_cmd(0, "spk ^"vox/%s^"", word);
        g_Countdown --;
        set_task(1.0,"cmd_saytime",TASK_SAYTIME)
    }
}

public CheckVoteDay()
{
    //new player
    //for(player = 1; player < 33; player++ ){
    //    if(!is_user_alive(player))
    //        continue
    //    remove_task(TASK_SAFETIME + player);
    //    set_pev(player, pev_flags, pev(player, pev_flags)| FL_FROZEN)
    //      StartVote(player);
    //}
    g_DayTimer = 0;
    EndVote()
}

public StartVote(id){
    static menu, menuname[32], option[64]
    formatex(menuname, charsmax(menuname), "Votati ce day vreti:")
    menu = menu_create(menuname, "vote_game")
    new allowed[31];
    get_pcvar_string(gp_Games, allowed,31)
    if (strlen(allowed) <= 0 ) return PLUGIN_CONTINUE

    if( !task_exists(TASK_DAYTIMER) )
    {
        g_DayTimer = 15;
        set_task( 1.0, "EndVote", TASK_DAYTIMER, _, _, "b" );
    }
    
    if (containi(allowed,"a") >= 0 && bool:g_GamesAp[AlienHiddenDay]==false)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ALIEN2")
        menu_additem(menu, option, "1", 0)
    }
    
    if (containi(allowed,"b") >= 0  && bool:g_GamesAp[ZombieDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZM")
        menu_additem(menu, option, "2", 0)
    }
    if (containi(allowed,"c") >= 0  && bool:g_GamesAp[HnsDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_HNS")
        menu_additem(menu, option, "3", 0)
    }
    if (containi(allowed,"d") >= 0  && bool:g_GamesAp[AlienDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ALIEN")
        menu_additem(menu, option, "4", 0)
    }
    if (containi(allowed,"f") >= 0  && bool:g_GamesAp[GunDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GUNDAY")
        menu_additem(menu, option, "5", 0)
    }
    if (containi(allowed,"g") >= 0  && bool:g_GamesAp[ColaDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_COLADAY")
        menu_additem(menu, option, "6", 0)
    }
    if (containi(allowed,"h") >= 0  && bool:g_GamesAp[GravityDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GRAVITY")
        menu_additem(menu, option, "7", 0)
    }
    /*if (containi(allowed,"i") >= 0  && bool:g_GamesAp[FireDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_FIREDAY")
        menu_additem(menu, option, "8", 0)
    }*/
    if (containi(allowed,"j") >= 0  && bool:g_GamesAp[BugsDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_BUGSDAY")
        menu_additem(menu, option, "9", 0)
    }
    if (containi(allowed,"k") >= 0  && bool:g_GamesAp[NightDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_NIGHTCRAWLER")
        menu_additem(menu, option, "10", 0)
    }
    if (containi(allowed,"l") >= 0  && bool:g_GamesAp[SpartaDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_SPARTA")
        menu_additem(menu, option, "11", 0)
    }
    
    //if (containi(allowed,"n") >= 0 && bool:g_GamesAp[OneBullet]==false)
    //{
    //    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ONEBULLET")
    //    menu_additem(menu, option, "12", 0)
    //}
    menu_display(id, menu)
    return PLUGIN_HANDLED
}
public  vote_game(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    new num = str_to_num(data)
    
    g_ResultVote[num]++;
        
    return PLUGIN_HANDLED
}
public EndVote()
{
    g_DayTimer--;
    
    if( g_DayTimer <= 0 ) // if for some reason it glitches and gets below zero
    {
        remove_task(TASK_DAYTIMER);
        new bigger = 0;
        bigger = random_num(ZombieDay,BoxDay);
        
        //for( new i=1; i<12; i++ )
        //{
        //    if( g_ResultVote[i] > g_ResultVote[bigger] )
        //    {
        //        bigger = i;
        //    }
        //}
        
        //if( bigger == 0 )
        //{
            
            //fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M15");
        //}
        g_DayTimer = 0;
        //for( new i=0; i<12; i++ )
        //{
        //    g_ResultVote[i] = 0;
        //}
        if(!is_user_alive(g_Simon) && (bigger == AlienDay || bigger == AlienHiddenDay || bigger == FireDay ))
        {
            new Players[32],playerCount;
            get_players(Players, playerCount, "ae", "CT") 
            if(playerCount==0)
            {
                return
            }
            new select = random_num(0,playerCount-1)
            if(select >= playerCount)
            {
                select = Players[0]
            }
            log_amx("day %d select %d",bigger,select)
            log_amx("simon %d",Players[select])
            g_Simon = Players[select];
        }
        new player
        for(player = 1; player < 33; player++){
            if(!is_user_alive(player))
                continue
            set_pev(player, pev_flags, pev(player, pev_flags)& ~FL_FROZEN)
        }
        g_GamePrepare = 0;
        switch(bigger)
        {
            case(AlienHiddenDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 ALIEN DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE ALIEN DAY!!!")
                cmd_game_alien2()
            }
            case(ZombieDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 ZOMBIE DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE ZOMBIE DAY!!!")
                cmd_pregame("cmd_game_zombie",1, 0, 30.0)
            }
            case(ZombieTeroDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 REVERSE ZOMBIE DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE REVERSE ZOMBIE DAY!!!")
                cmd_pregame("cmd_game_zombie_tero",2, 0, 30.0)
                jail_open()
            }
            case(FreezeTagDay):
            {
                EndVote()
            }
            case(HnsDay): 
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 HNS DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE HNS DAY!!!")
                cmd_pregame("cmd_game_hns", 2, 0, 60.0)
                jail_open()
            }
            case(AlienDay):
            {
                EndVote()
            }
            case(GunDay):
            {
                g_HsOnly = random_num(0, 1)
                if(g_HsOnly)
                {
                    ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 GUN DAY HeadShot Only^x01!!!")
                    log_amx("IN ACEASTA SAMBATA ESTE GUNDAY HS ONLY!!!")
                }
                else
                {
                    ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 GUN DAY^x01!!!")
                    log_amx("IN ACEASTA SAMBATA ESTE GUNDAY!!!")
                }
                cmd_pregame("cmd_game_gunday", 1, 0, 30.0)
            }
            case(SpartaDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 SPARTA DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE SPARTA DAY!!!")
                cmd_game_sparta()
            }
            case(ScoutDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 SNIPER DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE SNIPER DAY!!!")
                cmd_game_scouts()
            }
            case(SpartaTeroDay):
            {
                EndVote()
                //ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 REVERSE SPARTA DAY^x01!!!")
                //log_amx("IN ACEASTA SAMBATA ESTE REVERSE SPARTA DAY!!!")
                //cmd_pregame("cmd_game_sparta_tero", 1, 0, 30.0)
            }
            case(SpiderManDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 SPIDER-MAN DAY^x01!!!")
                ColorChat(0, GREEN, "PENTRU A PUTEA FOLOSI HOOK-UL TREBUIE SA VA PUNETI BIND:^x03 bind tasta +hook^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE SPIDER-MAN DAY!!!")
                cmd_game_spider()
            }
            case(CowboyDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 COWBOY DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE COWBOY DAY!!!")
                cmd_pregame("cmd_game_cowboy", 1, 0, 30.0)
            }
            case(GravityDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 GRAVITY DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE GRAVITY DAY!!!")
                set_cvar_num("sv_gravity",250)
                cmd_pregame("cmd_game_gravity", 2, 0, 30.0)
                jail_open()
            }
            case(FireDay):
            {
                /*ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 FIRE DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE FIRE DAY!!!")
                cmd_pregame("cmd_game_fire", 2, 1, 30.0)
                jail_open()*/                
                EndVote()
            }
            case(BugsDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 BUGS DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE BUGs DAY!!!")
                cmd_game_bugs()
            }
            case(NightDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 NIGHTCRAWLER DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE NIGHTCRAWLER!!!")
                cmd_game_nightcrawler()
            }
            case(ColaDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 COLA DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE COLADAY!!!")
                cmd_pregame("cmd_game_coladay", 1, 0, 30.0)
            }
            case(BoxDay):
            {
                ColorChat(0, GREEN, "IN ACEASTA SAMBATA ESTE^x03 BOX DAY^x01!!!")
                log_amx("IN ACEASTA SAMBATA ESTE BOX DAY!!!")
                cmd_game_box()
            }
            case(OneBullet):
            {
                client_print(0, print_chat, "server gives onebullet")
                log_amx("server gives onebullet")
                cmd_pregame("cmd_game_onebullet", 0, 0, 30.0)
            }
            default:
            {
                log_amx("day %d",bigger)
                EndVote()
            }
        }
    }
}
public cmd_done_game_prepare()
{
    g_GamePrepare = 0;
    if(g_GameMode == SpartaDay || g_GameMode == NightDay || g_GameMode == BugsDay || g_GameMode == SpiderManDay || g_GameMode == ScoutDay || g_GameMode == BoxDay)
    {
        if(g_GameMode == BoxDay)
            emit_sound(0, CHAN_AUTO, "jbextreme/rumble.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        else
            client_cmd(0,"spk radio/com_go")
        ColorChat(0, BLUE, "^x03 Timpul de pregatire s-a terminat.^x04 ATACATI^x01!")
        player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_DONE")
    }
    
}

public cmd_expire_time()
{
    new Players[32] 
    new playerCount, i 
    g_CantChoose = 1
    get_players(Players, playerCount, "ac")
    if(g_Duel == 2){
        for (i=0; i<playerCount && g_RoundEnd==0; i++)
            if(cs_get_user_team(Players[i]) == CS_TEAM_T)
                user_kill(Players[i],1)
    }
    switch (g_GameMode)
    { 
        /*case AscunseleaDay:
            new Ttotal,Talive
            for(i=0; i<playerCount; i++)
            if(cs_get_user_team(Players[i])==CS_TEAM_T){
                Ttotal++
                if(is_user_alive(Players[i]))
                Talive++
            }
            if(Ttotal/2>Talive){
                for (i=0; i<playerCount && g_RoundEnd==0; i++) 
                    if (cs_get_user_team(Players[i]) == CS_TEAM_T)
                        client_print(Players[i],print_chat,"gata jocul")//user_kill(Players[i],1)
            }else{
                for (i=0; i<playerCount && g_RoundEnd==0; i++) 
                    if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
                        user_kill(Players[i],1)
            }
            break*/
        case AlienDayT, GunDay, CowboyDay, ScoutDay, BoxDay, ZombieDay:
            for (i=0; i<playerCount && g_RoundEnd==0; i++) 
                if (cs_get_user_team(Players[i]) == CS_TEAM_T)
                    user_kill(Players[i],1)
        case HnsDay,AlienDay,AlienHiddenDay,GravityDay,BugsDay,NightDay, ZombieTeroDay: //,PrinseleaDay
            for (i=0; i<playerCount && g_RoundEnd==0; i++)
            {
                if (cs_get_user_team(Players[i]) == CS_TEAM_CT && !get_bit(g_BackToCT, Players[i]))
                    user_kill(Players[i],1)
                if (cs_get_user_team(Players[i]) == CS_TEAM_T)
                    cs_set_user_money(Players[i], cs_get_user_money(Players[i]) + 3000)
            }
        case FireDay:
            for (i=0; i<playerCount && g_RoundEnd==0; i++)
                set_user_health(Players[i],1)
        default:
            for (i=0; i<playerCount && g_RoundEnd==0; i++) 
                user_kill(Players[i],1)
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new sz_msg[256];
    if(g_GameMode==ZombieDay || g_GameMode == ZombieDayT || g_GameMode == ZombieTeroDay)
        formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_NUKED")
    else
        formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_EXPIRE")
    client_print(0, print_center , sz_msg)
    return PLUGIN_CONTINUE
}

public cmd_pregame(
    gameName[], //string with game name
    freeze, //0 none 1 - Tero 2- Ct
    change, //0 none 1 Ct2tero
    Float:countdown // time to start
    )
{
    new player
    g_nogamerounds = 0
    g_BoxStarted = 0
    g_SimonAllowed = 0
    g_GamePrepare = 1
    server_cmd("sleep_enabled 0")
    server_cmd("jb_block_weapons")
    
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    if( freeze == 1)
        player_hudmessage(0, 2, 30.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_CT_HIDE")
    if( freeze == 2)
        player_hudmessage(0, 2, 30.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_T_HIDE")
    for (player=1; player<=g_MaxClients; player++) 
    {

        if(!is_user_alive(player))
            continue;
        
        strip_user_weapons(player)
        set_user_gravity(player, 1.0)
        set_user_maxspeed(player, 250.0)
        set_user_health(player, 100)
        if(change==1 && cs_get_user_team(player) == CS_TEAM_CT && player!=g_Simon)
        {
            set_bit(g_BackToCT, player)
            cs_set_user_team2(player, CS_TEAM_T)
        }
        if ((freeze == 1 && cs_get_user_team(player)==CS_TEAM_T)
        || (freeze == 2 && cs_get_user_team(player) == CS_TEAM_CT))
        {
            set_pev(player, pev_flags, pev(player, pev_flags) | FL_FROZEN)  
            fade_screen(player,true)
        }
    }
    set_task(countdown, gameName, TASK_GIVEITEMS);
    g_Countdown = floatround(countdown);
    set_task(1.0, "cmd_saytime", TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_zombie()
{
    jail_open()
    g_GamePrepare = 0
    g_GameMode = ZombieDay
    g_GamesAp[ZombieDay]=true
    g_BoxStarted = 0
    g_DoNotAttack = 1;
    g_GameWeapon[0] = CSW_KNIFE
    g_GameWeapon[1] = CSW_M3
    g_Simon = 0
    g_nogamerounds = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        give_item(Players[i], "weapon_knife")
        set_user_gravity(Players[i], 1.0)
        if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            fade_screen(Players[i],false)
            set_user_maxspeed(Players[i], 200.0)
            set_user_health(Players[i], 800)
            give_item(Players[i], "item_assaultsuit")
            cs_set_user_nvg (Players[i],true);
            entity_set_int(Players[i], EV_INT_body, 6)
            message_begin( MSG_ONE, gmsgSetFOV, _, Players[i] )
            write_byte( 170  )
            message_end()
        }
        else if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            give_item(Players[i], "weapon_m3")
            give_item(Players[i], "weapon_hegrenade")
            give_item(Players[i], "weapon_flashbang")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            give_item(Players[i], "ammo_buckshot")
            set_user_health(Players[i], 100)
            set_user_maxspeed(Players[i], 250.0)
            set_bit(g_Fonarik, Players[i])
            client_cmd(Players[i], "impulse 100")
            player_glow(Players[i], g_Colors[2])
        }
    }
    emit_sound(0, CHAN_AUTO, "ambience/the_horror2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new effect = get_pcvar_num (gp_Effects)
    if (effect > 0)
    {
        set_lights("b")
        if (effect > 1) fog(true)
    }
    player_hudmessage(0, 2, HUD_DELAY + 1.0, { 0, 255, 0 }, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM")
    set_task(300.0, "cmd_expire_time", TASK_ROUND);
    g_Countdown = 300;
    set_task(1.0, "cmd_saytime", TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_zombie_tero()
{
    jail_open()
    g_GamePrepare = 0
    g_GameMode = ZombieTeroDay
    g_GamesAp[ZombieTeroDay]=true
    g_BoxStarted = 0
    g_DoNotAttack = 1;
    g_GameWeapon[0] = CSW_M3
    g_GameWeapon[1] = CSW_KNIFE
    g_Simon = 0
    g_nogamerounds = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        give_item(Players[i], "weapon_knife")
        set_user_gravity(Players[i], 1.0)
        if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            give_item(Players[i], "weapon_m3")
            give_item(Players[i], "weapon_hegrenade")
            give_item(Players[i], "weapon_flashbang")
            for(new bs = 0;bs<15; bs++)
                give_item(Players[i], "ammo_buckshot")
            set_user_health(Players[i], 100)
            set_user_maxspeed(Players[i], 250.0)
            set_bit(g_Fonarik, Players[i])
            client_cmd(Players[i], "impulse 100")
            player_glow(Players[i], g_Colors[2])
        }
        else if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            fade_screen(Players[i],false)
            set_user_maxspeed(Players[i], 350.0)
            set_user_health(Players[i], 2500)
            give_item(Players[i], "item_assaultsuit")
            cs_set_user_nvg (Players[i],true);
            entity_set_int(Players[i], EV_INT_body, 6)
            message_begin( MSG_ONE, gmsgSetFOV, _, Players[i] )
            write_byte( 170  )
            message_end()
        }
    }
    emit_sound(0, CHAN_AUTO, "ambience/the_horror2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new effect = get_pcvar_num (gp_Effects)
    if (effect > 0)
    {
        set_lights("b")
        if (effect > 1) fog(true)
    }
    player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_spider()
{
    set_cvar_num("sv_gravity",600)
    g_GameMode = SpiderManDay
    g_GamesAp[SpiderManDay]=true
    g_Simon = 0;
    g_GameWeapon[1] = CSW_KNIFE
    g_GameWeapon[0] = CSW_KNIFE
    g_BoxStarted = 0
    g_nogamerounds = 0
    g_GamePrepare = 1;
    g_DoNotAttack = 1;
    server_cmd("bh_enabled 0")
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    jail_open()
    set_cvar_num("sv_hookadminonly", 0)
    set_cvar_num("sv_hookspeed", 500)
    set_cvar_num("sv_parachute", 0)
    set_cvar_num("amx_climb", 1)
    hud_status(0)
    new Players[32]
    new playerCount, i
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++)
    {
        disarm_player(Players[i])
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            entity_set_int(Players[i], EV_INT_body, 10) //venom
            set_user_health(Players[i], 100)
        }
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            entity_set_int(Players[i], EV_INT_body, 11) //spider
            set_user_health(Players[i], 150)
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/spider.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 20 de secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_scouts()
{
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_cvar_num("sv_gravity",200)
    g_GameMode = ScoutDay
    g_GamesAp[ScoutDay]=true
    g_Simon = 0;
    g_GameWeapon[1] = CSW_AWP
    g_GameWeapon[0] = CSW_SCOUT
    g_BoxStarted = 0
    g_nogamerounds = 0
    g_GamePrepare = 1;
    g_DoNotAttack = 1;
    server_cmd("bh_enabled 0")
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    jail_open()
    hud_status(0)
    new Players[32]
    new playerCount, i
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++)
    {
        set_user_health(Players[i], 100)
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            give_item(Players[i], "weapon_scout")
            cs_set_user_bpammo(Players[i], CSW_SCOUT, 999)
        }   
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            give_item(Players[i], "weapon_awp")
            cs_set_user_bpammo(Players[i], CSW_AWP, 999)
        }
        
    }
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 20 de secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_hns()
{
    g_GameMode = HnsDay
    g_GamesAp[HnsDay]=true
    g_GamePrepare = 0
    g_DoNotAttack = 1;
    g_Simon = 0;
    g_GameWeapon[1] = CSW_KNIFE
    set_lights("b");
    server_cmd("bh_enabled 0")
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        set_user_gravity(Players[i], 1.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            /*give_item(Players[i], "weapon_knife")
            give_item(Players[i], "weapon_flashbang")
            give_item(Players[i], "weapon_smokegrenade")
            set_user_maxspeed(Players[i], 300.0)*/
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) | FL_FROZEN)
            cs_set_user_nvg (Players[i],true);
            set_user_health(Players[i], 100)
        }
        else
        {
            fade_screen(Players[i],false)
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            set_user_health(Players[i],999999);
            give_item(Players[i], "weapon_knife")
            give_item(Players[i], "weapon_smokegrenade")
            set_bit(g_Fonarik, Players[i])
            client_cmd(Players[i], "impulse 100")
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/hns.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_HNS")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}
public  cmd_game_alien()
{
    if (g_Simon == 0)
    { 
        log_amx("no simon on alien")
        return PLUGIN_HANDLED
    }
    g_BoxStarted = 0
    g_nogamerounds = 0
    jail_open()
    g_GameMode = AlienDay
    g_GamesAp[AlienDay]=true
    g_DoNotAttack = 3;
    g_GameWeapon[1] = CSW_KNIFE;
    server_cmd("sleep_enabled 0")
    server_cmd("jb_block_weapons")
    hud_status(0)
    new j = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        set_user_gravity(Players[i], 1.0)
        if ( g_Simon != Players[i])
        {
            set_user_maxspeed(Players[i], 250.0)
            if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
            {
                set_bit(g_BackToCT, Players[i])
                cs_set_user_team2(Players[i], CS_TEAM_T)
            }            
            give_item(Players[i], "weapon_knife")
            j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(Players[i], _WeaponsFree[j])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
        }
        else
        { 
            set_user_maxspeed(Players[i], 700.0)
            entity_set_int(Players[i], EV_INT_body, 7)
            set_user_health(Players[i], 130*playerCount)
            give_item(Players[i], "weapon_knife")
            give_item(Players[i], "item_assaultsuit")
            give_item(Players[i], "item_longjump")
            server_cmd("give_crowbar %d 1",Players[i])
        }        
    }
    new effect = get_pcvar_num (gp_Effects)
    if (effect > 0)
    {
        set_lights("z")
        if (effect > 1) fog(true)
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}
public  cmd_game_alien2()
{
    if (g_Simon == 0)
    {
        log_amx("no simon on alienday2")
        return PLUGIN_HANDLED    
    } 
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_DoNotAttack = 3;
    g_GamePrepare = 1;
    g_GameWeapon[1] = CSW_KNIFE
    g_GameMode = AlienHiddenDay
    g_GamesAp[AlienHiddenDay]=true
    server_cmd("jb_block_weapons")
    server_cmd("jb_block_teams")
    server_cmd("sleep_enabled 0")
    hud_status(0)

    new playerCount = 0
    for (new i=1; i<=g_MaxClients; i++)
    {
        if(!is_user_alive(i))
            continue;

        strip_user_weapons(i);
        set_user_gravity(i, 1.0);
        set_user_maxspeed(i, 250.0);
        if ( g_Simon != i)
        {
            if (cs_get_user_team(i) == CS_TEAM_CT)
            {
                set_bit(g_BackToCT, i);
                cs_set_user_team2(i, CS_TEAM_T);
            }
            give_item(i, "weapon_knife")
            new j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(i, _WeaponsFree[j])
            cs_set_user_bpammo(i, _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
            new n = random_num(0, sizeof(_WeaponsFree) - 1)
            while (n == j) { 
                n = random_num(0, sizeof(_WeaponsFree) - 1) 
            }
            give_item(i, _WeaponsFree[n])
            cs_set_user_bpammo(i, _WeaponsFreeCSW[n], _WeaponsFreeAmmo)
            playerCount++
        }
    }

    task_inviz(g_Simon);
    set_user_maxspeed(g_Simon, 500.0)
    entity_set_int(g_Simon, EV_INT_body, 7)

    new hp = get_pcvar_num(gp_GameHP)
    if (hp < 20) hp = 200
    set_user_health(g_Simon, hp*playerCount)

    client_print(0,print_chat,"Alien-ul va ataca in 20 de secunde! Pregatiti-va!")
    set_lights("z")
    emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)

    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    set_task(20.0, "give_items_alien", TASK_GIVEITEMS)
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    set_task(2.5, "radar_alien", TASK_RADAR, _, _, "b")
    set_task(5.0, "stop_sound")
    set_task(3.1, "task_inviz",TASK_INVISIBLE + g_Simon, _, _, "b");
    set_task(300.0,"cmd_expire_time",TASK_ROUND)    

    return PLUGIN_HANDLED
}

public cmd_game_gunday()
{
    g_GameMode = GunDay
    g_GamesAp[GunDay]=true
    g_GamePrepare = 0
    g_Simon = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        fade_screen(Players[i],false)
        set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
        give_item(Players[i], "weapon_knife")
        new j = random_num(0, sizeof(_WeaponsFree) - 1)
        give_item(Players[i], _WeaponsFree[j])
        cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
        new n = random_num(0, sizeof(_WeaponsFree) - 1)
        while (n == j) { 
            n = random_num(0, sizeof(_WeaponsFree) - 1) 
        }
        give_item(Players[i], _WeaponsFree[n])
        cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo)
        set_user_gravity(Players[i], 1.0)
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    jail_open()
    new sz_msg[256];
    if(g_HsOnly)
        formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_GUNDAY_HS")
    else
        formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_GUNDAY")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public cmd_game_cowboy()
{
    g_GameMode = CowboyDay
    g_GamesAp[CowboyDay]=true
    g_GamePrepare = 0
    g_Simon = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        fade_screen(Players[i],false)
        set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
        give_item(Players[i], "weapon_elite")
        cs_set_user_bpammo(Players[i], CSW_ELITE, 999)
        set_user_gravity(Players[i], 1.0)
        Set_Hat(Players[i],1)
        if(cs_get_user_team(Players[i]) == CS_TEAM_CT)
            set_user_health(Players[i], 150)
    }

    emit_sound(0, CHAN_AUTO, "jbextreme/cowboy.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    jail_open()
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_COWBOY")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}

public  cmd_game_coladay()
{
    server_cmd("jb_unblock_weapons")
    set_task(2.0,"cmd_game_coladay_post",TASK_ROUND)
    return PLUGIN_CONTINUE
}

public cmd_game_coladay_post()
{
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_GameMode = ColaDay
    g_GamesAp[ColaDay]=true
    g_SimonAllowed = 0
    g_Simon = 0
    g_DoNotAttack = 1;
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        fade_screen(Players[i],false)
        set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
        set_user_gravity(Players[i], 1.0)
        give_item( Players[i], "weapon_hegrenade" );
        cs_set_user_bpammo( Players[i], CSW_HEGRENADE, 1)
    }
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    server_cmd("jb_block_weapons")
}
public cmd_game_gravity()
{
    g_GameMode = GravityDay
    g_GamesAp[GravityDay]=true
    g_GamePrepare = 0
    g_DoNotAttack = 1;
    g_GameWeapon[1] = CSW_KNIFE
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 

    for (i=0; i<playerCount; i++) 
    {
        set_user_gravity(Players[i], 1.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            give_item(Players[i], "weapon_flashbang")
            give_item(Players[i], "weapon_smokegrenade")
            give_item(Players[i], "weapon_knife")
            cs_set_user_nvg(Players[i],1)
            set_user_maxspeed(Players[i], 300.0)
            set_user_health(Players[i], 100)
        }
        else
        {
            fade_screen(Players[i],false)
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            give_item(Players[i], "weapon_knife")
            set_user_health(Players[i],999999);

        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_GRAVITY")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}
public  cmd_game_fire()
{
    if (g_Simon == 0)
    {
        log_amx("no simon on fireday")
        return PLUGIN_HANDLED
    }
    g_GameWeapon[1] = CSW_KNIFE
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_GameMode = FireDay
    g_GamesAp[FireDay]=true
    g_DoNotAttack = 1;
    server_cmd("jb_block_weapons")
    server_cmd("jb_block_teams")
    server_cmd("sleep_enabled 0")
    hud_status(0)    
    new Players[32]
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        give_item(Players[i], "weapon_knife")
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
        set_user_health(Players[i], 500)
        fade_screen(Players[i],false)
        set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 

    }
    set_user_health(g_Simon,999999);
    static dst[32]
    get_user_name(g_Simon, dst, charsmax(dst))
    server_cmd("amx_fire %s",dst);
    entity_set_int(g_Simon, EV_INT_body, 9)
    emit_sound(0, CHAN_AUTO, "jbextreme/lina.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}
public  cmd_game_bugs()
{
    g_SimonAllowed = 0
    g_Simon = 0
    g_nogamerounds = 0
    g_BoxStarted = 0
    g_GamePrepare = 1
    jail_open()
    g_GameMode = BugsDay
    g_GamesAp[BugsDay]=true
    g_DoNotAttack = 3;
    g_GameWeapon[1] = CSW_KNIFE
    server_cmd("jb_block_weapons")
    server_cmd("jb_block_teams")
    server_cmd("bh_enabled 0")
    hud_status(0)
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        give_item(Players[i], "weapon_knife")
        set_user_gravity(Players[i], 1.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            set_user_health(Players[i], 100)
            set_pev(Players[i], pev_movetype, MOVETYPE_NOCLIP)
            set_user_maxspeed(Players[i], 400.0)
            
        }
        else if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            set_user_maxspeed(Players[i], 250.0)
            set_user_health(Players[i], 100)
            new j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(Players[i], _WeaponsFree[j])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
            new n = random_num(0, sizeof(_WeaponsFree) - 1)
            while (n == j) { 
                n = random_num(0, sizeof(_WeaponsFree) - 1) 
            }
            give_item(Players[i], _WeaponsFree[n])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo)
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 20 de secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}
public  cmd_game_nightcrawler()
{
    g_SimonAllowed = 0
    g_Simon = 0
    g_BoxStarted = 0
    g_nogamerounds = 0
    g_GamePrepare = 1
    jail_open()
    g_GameMode = NightDay
    g_GamesAp[NightDay]=true
    g_DoNotAttack = 3;
    g_GameWeapon[1] = CSW_KNIFE
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    hud_status(0)
    new j = 0
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        give_item(Players[i], "weapon_knife")
        set_user_gravity(Players[i], 1.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)    
        {
            set_user_maxspeed(Players[i], 250.0)    
            j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(Players[i], _WeaponsFree[j])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
        }
        else
        { 
            set_user_maxspeed(Players[i], 400.0)            
            entity_set_int(Players[i], EV_INT_body, 7)
            set_user_health(Players[i], 30)
            give_item(Players[i], "item_assaultsuit")
            give_item(Players[i], "item_longjump")
            cs_set_user_nvg (Players[i],true);
            set_user_rendering(Players[i], kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 )
            message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, Players[i])
            write_short(~0)
            write_short(~0)
            write_short(0x0004) // stay faded
            write_byte(ALIEN_RED)
            write_byte(ALIEN_GREEN)
            write_byte(ALIEN_BLUE)
            write_byte(100)
            message_end()
            set_user_footsteps( Players[i], 1 )
            server_cmd("give_crowbar %d 1",Players[i])
            set_task(3.1, "task_inviz",TASK_INVISIBLE + Players[i], _, _, "b");
        }        
    }
    new effect = get_pcvar_num (gp_Effects)
    if (effect > 0)
    {
        set_lights("b")
    }
    emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
    set_task(5.0, "stop_sound")
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 20 de secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}

public cmd_game_sparta()
{
    emit_sound(0, CHAN_AUTO, "jbextreme/sparta1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    g_Simon =0
    g_BoxStarted = 0
    g_nogamerounds = 0
    jail_open()
    g_GameMode = SpartaDay
    g_GamesAp[SpartaDay]=true
    g_GamePrepare = 1;
    g_DoNotAttack = 1;
    g_GameWeapon[0] = CSW_DEAGLE
    g_GameWeapon[1] = CSW_KNIFE
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    hud_status(0)
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++)
    {
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT)    
        {    
            entity_set_int(Players[i], EV_INT_body, 8)
            disarm_player(Players[i])
            give_item(Players[i], "weapon_shield")
            entity_set_string(Players[i], EV_SZ_viewmodel, SPARTA_V)  
            entity_set_string(Players[i], EV_SZ_weaponmodel, SPARTA_P) 
            set_user_health(Players[i], 200)
        }
        else
        {
            strip_user_weapons(Players[i])
            new gun = give_item(Players[i], "weapon_deagle")
            cs_set_weapon_ammo(gun, 1)
            set_user_health(Players[i], 100)
        }
    }
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 20 de secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}

public cmd_game_sparta_tero()
{
    emit_sound(0, CHAN_AUTO, "jbextreme/sparta1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    g_GameMode = SpartaTeroDay
    g_GamesAp[SpartaTeroDay]=true
    g_GamePrepare = 0
    g_Simon = 0
    g_BoxStarted = 0
    g_nogamerounds = 0
    g_DoNotAttack = 2
    g_GameWeapon[0] = CSW_KNIFE
    jail_open()
    hud_status(0)
    new j = 0
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")                 
    for (i=0; i<playerCount; i++) 
    {
        set_user_gravity(Players[i], 1.0)
        if(cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            set_user_maxspeed(Players[i], 250.0)   
            strip_user_weapons(Players[i])
            j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(Players[i], _WeaponsFree[j])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo)
            set_user_health(Players[i], 100)
        }
        if(cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            fade_screen(Players[i],false)
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            set_user_maxspeed(Players[i], 350.0)
            entity_set_int(Players[i], EV_INT_body, 8)
            disarm_player(Players[i])
            Give_Item(Players[i], 0)
            //entity_set_string(Players[i], EV_SZ_viewmodel, SPARTA_V)  
            //entity_set_string(Players[i], EV_SZ_weaponmodel, SPARTA_P) 
            set_user_health(Players[i], 200)
        }
    }
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_DONE")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}

public cmd_game_box()
{
    g_Simon = 0
    g_GamePrepare = 1
    g_BoxStarted = 0
    g_nogamerounds = 0
    jail_open()
    g_GameMode = BoxDay
    g_GamesAp[BoxDay]=true
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    server_cmd("bh_enabled 0")
    set_cvar_num("mp_tkpunish", 0)
    set_cvar_num("mp_friendlyfire", 1)
    hud_status(0)
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++)
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)   
        {
            set_user_gravity(Players[i], 1.0)
            set_user_maxspeed(Players[i], 250.0)
            set_user_health(Players[i], 100)
            new gun = give_item(Players[i], "weapon_glock18")
            cs_set_weapon_ammo(gun, 0)
        }
    set_task(0.5, "boxWep")
    set_task(10.0, "cmd_done_game_prepare",TASK_SAFETIME)
    ColorChat(0, NORMAL, "Aveti^x04 Godmode^x01 10 secunde pentru a va pregati!")
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PREPARE_START")
    set_task(120.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=120
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_HANDLED
}

public cmd_game_starwars()
{

}

/*public cmd_ascunsea_start()
{
    g_GameMode = 14
    g_GamesAp[14]=true
    g_GamePrepare = 0
    g_DoNotAttack = 1;
    g_GameWeapon[1] = CSW_KNIFE
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    new ent
    new Float:origin[3],Float:playerorigin[3]
    for (i=0; i<playerCount; i++) 
    {
        if (cs_get_user_team(Players[i]) == CS_TEAM_T)
        {
            entity_get_vector(Players[i],EV_VEC_origin, playerorigin)
            ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_start")
            while(ent)
            {
                entity_get_vector(ent,EV_VEC_origin, origin)
                new Float:distance = vector_distance(origin,playerorigin)
                if(distance < 200.0){
                    user_kill(Players[i])
                    break
                }
                ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_start")
            }
            if(!is_user_alive(Players[i]))
                continue
            give_item(Players[i], "weapon_knife")
            give_item(Players[i], "weapon_flashbang")
            give_item(Players[i], "weapon_smokegrenade")
            set_user_maxspeed(Players[i], 300.0)
            set_user_health(Players[i], 100)
        }
        else
        {
            fade_screen(Players[i],false)
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 
            set_user_health(Players[i],999999);
            give_item(Players[i], "weapon_knife")
            give_item(Players[i], "weapon_smokegrenade")
            set_bit(g_Fonarik, Players[i])
            client_cmd(Players[i], "impulse 100")
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}
public  cmd_game_ascunsea()
{
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_SimonAllowed = 0
    g_Simon = 0
    g_GamePrepare = 1
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    player_hudmessage(0, 2, 30.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_HNS")
    set_lights("b");
    server_cmd("jb_block_weapons")
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
        if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
        {
            set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) | FL_FROZEN)  
            fade_screen(Players[i],true)
        }
        else{
            g_Savedhns[i] = false
            cs_set_user_nvg (Players[i],true);
        }
    }
    set_task(30.0,"cmd_ascunsea_start",TASK_GIVEITEMS)
    g_Countdown=30
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}
public cmd_prinselea_start()
{
    g_GameMode = 15
    g_GamesAp[15]=true
    g_GamePrepare = 0
    Matadinnou = true
    g_DoNotAttack = 1;
    g_GameWeapon[1] = CSW_KNIFE
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    Mata=random_num(0,playerCount)
    for (i=0; i<playerCount; i++) 
    {

        if (Mata == i)
        {
            if(cs_get_user_team(Players[i]) == CS_TEAM_T)
                cs_set_user_team2(Players[i], CS_TEAM_CT)
            else
                set_bit(g_BackToCT, Players[i])
            
            give_item(Players[i], "weapon_knife");
            set_user_health(Players[i],999999);
            set_user_maxspeed(Players[i], 400.0)
            entity_set_int(Players[i], EV_INT_body, 1)
        }
        else
        {
            if(cs_get_user_team(Players[i]) == CS_TEAM_CT){
                cs_set_user_team2(Players[i], CS_TEAM_T)
                set_bit(g_BackToCT, Players[i])
            }
            entity_set_int(Players[i], EV_INT_body, 1+random_num(1,2))
            give_item(Players[i], "weapon_flashbang")
            give_item(Players[i], "weapon_smokegrenade")
            give_item(Players[i], "weapon_knife")
            cs_set_user_nvg(Players[i],1)
            set_user_health(Players[i], 100)
            set_user_maxspeed(Players[i], 260.0)
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_GRAVITY_START")
    client_print(0, print_center , sz_msg)

    set_task(30.0,"cmd_moaremata",TASK_ROUND)
    return PLUGIN_CONTINUE
}
public cmd_dinnoumata ()
{
    Matadinnou = true
    return PLUGIN_CONTINUE
}
public cmd_moaremata ()
{
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac") 
    if(playerCount >= 2){
        new mataant = Mata
        while(Mata == mataant)
            Mata = random(playerCount);
        cs_set_user_team2(Players[Mata], CS_TEAM_CT)
        cs_set_user_nvg(Players[Mata],0)
        set_task(30.0,"cmd_moaremata",TASK_ROUND)
        set_user_maxspeed(Players[i], 400.0)
        set_user_health(Players[i],999999)
        entity_set_int(Players[i], EV_INT_body, 1)
    }
    for (i=0; i<playerCount; i++) 
        if (Mata != i && cs_get_user_team(Players[i]) == CS_TEAM_CT){
            user_kill(Players[i])
            if(!get_bit(g_BackToCT, Players[i])) cs_set_user_team2(Players[i], CS_TEAM_T)
        }
    return PLUGIN_CONTINUE
}
public  cmd_game_prinselea()
{
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_SimonAllowed = 0
    g_Simon = 0
    g_GamePrepare = 1
    set_cvar_num("sv_gravity",250)
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    player_hudmessage(0, 2, 30.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_PRINSELEA")    
    server_cmd("jb_block_weapons")    
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
    }
    set_task(30.0,"cmd_prinselea_start",TASK_GIVEITEMS)
    g_Countdown=30
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
    return PLUGIN_CONTINUE
}*/
public cmd_game_funday ()
{
    fun_light[0] = 'i'
    fun_gravity=800
    fun_god=0
    fun_clip=0
    set_lights("i")
    g_BoxStarted = 0
    g_nogamerounds = 0
    jail_open()
    g_GameMode = FunDay
    server_cmd("jb_block_weapons")
    server_cmd("sleep_enabled 0")
    hud_status(0)
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++){
        strip_user_weapons(Players[i])
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
    }
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    set_task(1.0,"cmd_saytime",TASK_SAYTIME);
}
public cmd_funmenu (id)
{
    if(!is_user_alive(id) || id!=g_Simon)
        return PLUGIN_CONTINUE
    static menu, menuname[32], option[64]
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_FUN")
    menu = menu_create(menuname, "cmd_funmenu_select")
    
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_+LIGHT",fun_light)
    menu_additem(menu, option, "1", 0)
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_-LIGHT",fun_light)
    menu_additem(menu, option, "2", 0)
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_+GRAVITY",fun_gravity)
    menu_additem(menu, option, "3", 0)
    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_-GRAVITY",fun_gravity)
    menu_additem(menu, option, "4", 0)
    if(fun_god == 1)
    {
        formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_GODON")
        menu_additem(menu, option, "5", 0)
    }
    else{
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_GODOFF")
        menu_additem(menu, option, "5", 0)
    }
    if(fun_clip == 1)
    {
        formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_CLIPON")
        menu_additem(menu, option, "6", 0)
    }
    else{
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_CLIPOFF")
        menu_additem(menu, option, "6", 0)
    }
    menu_display(id, menu)
    return PLUGIN_HANDLED
}
public cmd_funmenu_select (id, menu, item)
{
    if(item == MENU_EXIT || !is_user_alive(id))
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
        case '1':
        {
            if(fun_light[0]<'z')
                fun_light[0]++;
            set_lights(fun_light)
        }
        case '2':
        {
            if(fun_light[0]>'a')
                fun_light[0]--;
            set_lights(fun_light)
        }
        case '3':
        {
            if(fun_gravity<1000)
                fun_gravity+=100;
            set_cvar_num("sv_gravity",fun_gravity)
        }
        case '4':
        {
            if(fun_gravity>0)
                fun_gravity-=100;
            set_cvar_num("sv_gravity",fun_gravity)
        }
        case '5':
        {
            fun_god = !fun_god;
        }
        case '6':
        {
            new Players[32] 
            new playerCount, i 
            get_players(Players, playerCount, "ac")
            if(fun_clip == 0)
                for (i=0; i<playerCount; i++) 
                    set_pev(Players[i], pev_movetype, MOVETYPE_NOCLIP)
            else
                for (i=0; i<playerCount; i++) 
                    set_pev(Players[i], pev_movetype, MOVETYPE_WALK)
            fun_clip=!fun_clip;
        }
    }
    cmd_funmenu(id)
    return PLUGIN_HANDLED
}

public cmd_game_onebullet()
{
    /*public Radar_Hook(msg_id, msg_dest, msg_entity)
    {
        if (csdm_get_ffa())
        {
            return PLUGIN_HANDLED
        }
        
        return PLUGIN_CONTINUE
    }*/
    
}

public cmd_shop(id)
{
    if(!is_user_alive(id) || !is_not_game() || (g_RoundStarted >= gp_RetryTime) || g_Duel != 0 || BuyTimes[id] == 2) return PLUGIN_CONTINUE
    static menu, menuname[32], option[64]
    if(cs_get_user_team(id) == CS_TEAM_T)
    {
        if (strlen(Tallowed) <= 0 ) return PLUGIN_CONTINUE
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SHOP")
        menu = menu_create(menuname, "shop_choice_T")
        if (containi(Tallowed,"a") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_CROWBAR",CROWBARCOST)
            menu_additem(menu, option, "1", 0)
        }
        if (containi(Tallowed,"b") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHBANG", FLASHCOST)
            menu_additem(menu, option, "2", 0)
        }
        if (containi(Tallowed,"c") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_SMOKE", SMOKECOST)
            menu_additem(menu, option, "3", 0)
        }
        if (containi(Tallowed,"d") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_HE", HECOST)
            menu_additem(menu, option, "4", 0)
        }
        if (containi(Tallowed,"f") >= 0 && !get_bit(g_PlayerWanted, id))
        {
            if(FreedayTime == 1)
            {
                if(/*g_JailDay%7 != 3 && */g_JailDay%7 !=0 && g_JailDay%7 != 6)
                {
                    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FD", FDCOST)
                    menu_additem(menu, option, "6", 0)
                }
            }
            else
            {
                if(/*g_JailDay%7 != 2 && g_JailDay%7 != 3 &&g_JailDay%7 !=0 &&  */g_JailDay%7 != 5 && g_JailDay%7 != 6)
                {
                    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FD_NEXT", FDCOST)
                    menu_additem(menu, option, "9", 0)
                }
            }
        }
        if (containi(Tallowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_ARMOR",ARMORCOST)
            menu_additem(menu, option, "5", 0)
        }
        if (containi(Tallowed,"g") >= 0)
        {
            formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SHOP_SHIELD", SHIELDCOST)
            menu_additem(menu, option, "7", 0)
        }
        /*if (containi(Tallowed,"g") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_KNIFES", KNIFESCOST)
            menu_additem(menu, option, "a", 0)
        }
        if (containi(Tallowed,"g") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHLIGHT", FLASHLIGHTCOST)
            menu_additem(menu, option, "7", 0)
        }
        formatex(option, charsmax(option), "\rMasca de fata\w $500")
        menu_additem(menu, option, "a", 0)

        formatex(option, charsmax(option), "\rServetel folosit\w $5000")
        menu_additem(menu, option, "b", 0)

        formatex(option, charsmax(option), "\Desface catusile\w $8000")
        menu_additem(menu, option, "c", 0)*/

        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NOSHOW")
        menu_additem(menu, option, "8", 0)
        menu_display(id, menu)
    }
    else if(cs_get_user_team(id) == CS_TEAM_CT)
    {
        if (strlen(CTallowed) <= 0 ) return PLUGIN_CONTINUE
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SHOP")
        menu = menu_create(menuname, "shop_choice_CT")
        if (containi(CTallowed,"a") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_WEAPON")
            menu_additem(menu, option, "1", 0)
        }
        if (containi(Tallowed,"a") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_CROWBAR",CROWBARCOST)
            menu_additem(menu, option, "9", 0)
        }
        if (containi(CTallowed,"b") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHBANG_CT", CTFLASHCOST)
            menu_additem(menu, option, "2", 0)
        }
        if (containi(CTallowed,"c") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_SMOKE_CT",CTSMOKECOST)
            menu_additem(menu, option, "3", 0)
        }
        if (containi(CTallowed,"d") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_HP",HPCOST)
            menu_additem(menu, option, "4", 0)
        }
        /*if (containi(CTallowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_KNIFES", KNIFESCOST)
            menu_additem(menu, option, "a", 0)
        }
        if (containi(CTallowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NVG",NVGCOST)
            menu_additem(menu, option, "5", 0)
        }*/
        if (containi(CTallowed,"f") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHLIGHT",FLASHLIGHTCOST)
            menu_additem(menu, option, "6", 0)
        }
        if (containi(CTallowed,"g") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_GLOCK",GLOCKCOST)
            menu_additem(menu, option, "8", 0)
        }
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NOSHOW")
        menu_additem(menu, option, "7", 0)    
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED
}
public shop_choice_T(id, menu, item)
{
    if(item == MENU_EXIT || !is_user_alive(id) || BuyTimes[id] == 2 || !is_not_game())
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    new money = cs_get_user_money (id);
    new sz_msg[256];
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    get_user_name(id, dst, charsmax(dst))
    switch(data[0])
    {
        case('2'):
        {
            if (money >= FLASHCOST) 
            {
                cs_set_user_money (id, money - FLASHCOST, 0)
                give_item(id, "weapon_flashbang")
                BuyTimes[id]++
            }
            else    
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('4'):
        {
            if (money >= HECOST) 
            {
                cs_set_user_money (id, money - HECOST, 0)
                give_item(id, "weapon_hegrenade")
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('3'):
        {
            if (money >= SMOKECOST) 
            {
                cs_set_user_money (id, money - SMOKECOST, 0)
                give_item(id, "weapon_smokegrenade")
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
                BuyTimes[id]++
            }
        }
        case('5'):
        {
            if (money >= ARMORCOST) 
            {
                cs_set_user_money (id, money - ARMORCOST, 0)
                give_item(id, "item_assaultsuit")
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('1'):
        {
            client_cmd(id,"say /crowbar")
        }
        case('6'):
        {
            if (money >= FDCOST && !get_bit(g_PlayerWanted, id) && FreedayTime == 1)
            {
                if(get_bit(g_PlayerFreeday, id))
                    ColorChat(id, GREEN, "Ai deja FreeDay!")
                else
                {
                cs_set_user_money (id, money - FDCOST, 0)
                freeday_set(0, id, false)
                BuyTimes[id]++
                }
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('9'):
        {
            if (money >= FDCOST && !get_bit(g_PlayerWanted, id) && FreedayTime == 0)
            {
                cs_set_user_money (id, money - FDCOST, 0)
                set_bit(g_PlayerNextFreeday, id)
                player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_HASFREEDAY_NEXT", dst)
                ColorChat(0, RED, "^x03%s^x01 si-a cumparat^x04 FD^x01 urmatoarea runda!", dst)
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('7'):
        {
            if(get_vip_type(id) != 4)
                client_print(id, print_center, "Nu poti cumpara Scut daca nu ai VIP JB 4")
            else if (money >= SHIELDCOST && get_vip_type(id) == 4)
            {
                cs_set_user_money (id, money - SHIELDCOST, 0)
                Give_Item(id, 0)
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('a'):
        {
            client_cmd(id, "say /buymask")
        }
        case('b'):
        {
            client_cmd(id, "say /buyusedpaper")
        }
        case('c'):
        {
            client_cmd(id, "say /buyuncuffs")
        }
    /*
        case('a'):
        {
            if (money >= KNIFESCOST)
            {
                new bool = server_cmd("give_knifes %d 3", id)
                if(bool)
                {
                    cs_set_user_money (id, money - KNIFESCOST, 0)
                    BuyTimes[id]++
                }
                else
                    client_print(id, print_center, "Nu poti cumpara cutite de aruncat daca ai deja.")
            }
            else
            {
            
            }
        }
	*/
        case('8'):
        {
            set_bit(g_NoShowShop, id)
            formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_SHOWHOW")
            client_print(id, print_center , sz_msg)
        }
    }
    if(get_vip_type(id) == 3)
       BuyTimes[id] = 0;
    return PLUGIN_HANDLED
}
public shop_choice_CT(id, menu, item)
{
    if(item == MENU_EXIT || BuyTimes[id] == 2)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    new money = cs_get_user_money (id);
    new sz_msg[256];
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    get_user_name(id, dst, charsmax(dst))
    switch(data[0])
    {
        case('1'):
        {
            gunsmenu(id)
        }
        case('2'):
        {
            if (money >= CTFLASHCOST) 
            {
                cs_set_user_money (id, money - CTFLASHCOST, 0)
                give_item(id, "weapon_flashbang")
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('3'):
        {
            if (money >= CTSMOKECOST) 
            {
                cs_set_user_money (id, money - CTSMOKECOST, 0)
                give_item(id, "weapon_smokegrenade")
                BuyTimes[id]++
            }
            else    
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('4'):
        {
            if (money >= HPCOST) 
            {
                cs_set_user_money (id, money - HPCOST, 0)
                if((g_GameMode == NormalDay || g_GameMode == Freeday) && g_Duel==0)
                    set_user_health(id, 150)
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('5'):
        {
            if (money >= NVGCOST) 
            {
                cs_set_user_money (id, money - NVGCOST, 0)
                cs_set_user_nvg (id,true);
                engclient_cmd(id, "nightvision") 
                BuyTimes[id]++
            }
            else    
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('6'):
        {
            if (money >= FLASHLIGHTCOST) 
            {
                cs_set_user_money (id, money - FLASHLIGHTCOST, 0)
                set_bit(g_Fonarik, id)
                client_cmd(id, "impulse 100")
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('7'):
        {
            set_bit(g_NoShowShop, id)
            formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_SHOWHOW")
            client_print(id, print_center , sz_msg)
            
        }
        case('8'):
        {
            if (money >= GLOCKCOST) 
            {
                cs_set_user_money (id, money - GLOCKCOST, 0)
                give_item(id,"weapon_glock18") 
                give_item(id,"ammo_9mm") 
                BuyTimes[id]++
            }
            else
            {
                formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
                client_print(id, print_center , sz_msg)
            }
        }
        case('9'):
        {
            client_cmd(id,"say /crowbar")
        }
	/*
        case('a'):
        {
            if (money >= KNIFESCOST)
            {
                new bool = server_cmd("give_knifes %d 3", id)
                if(bool)
                {
                    cs_set_user_money (id, money - KNIFESCOST, 0)
                    BuyTimes[id]++
                }
                else
                    client_print(id, print_center, "Nu poti cumpara cutite de aruncat daca ai deja.")
            }
            else
            {
            
            }
        }
	*/
        
    }
    if (!get_bit(g_NoShowShop, id)) cmd_shop(id)
    return PLUGIN_HANDLED
}
public gunsmenu(id)
{
    if(G_Info_page[id] != 0 || g_RoundStarted >= gp_RetryTime || !is_user_alive(id) || is_user_bot(id) || is_user_hltv(id) || g_Duel!=0 || !is_not_game()) return
    G_Info_page[id] = 1
    set_task(2.0,"Show_Menu",id)
}
public Show_Menu(id)
{
    if(cs_get_user_team(id) == CS_TEAM_CT)
    {
        new menu = menu_create("\rGun Menu", "Menu_Handler")
        
        new nr[4],Name[26],i,Cost
        new page = G_Info_page[id]-1;
        new i2=G_Size[0][page];
        new limit = G_Size[1][page];
        for (; i2<=limit; i2++)
        {
            i = i2
            if(get_pcvar_num(P_Cvars[i]) == 1)
            {    
                Cost = Weapons_Price[i]
                format(nr,3,"%i",i)
                if(!Cost)format(Name,25,"%s",Weapons_Info[0][i])
                else format(Name,25,"%s %i$",Weapons_Info[0][i], Cost)
                
                menu_additem(menu ,Name, nr, 0)
            }
        }
        menu_setprop(menu , MPROP_EXIT , MEXIT_ALL);
        menu_display(id , menu , 0)
        G_Info_page[id] +=1
    }
}
public Menu_Handler(id, menu, item)
{
    if(id > 32 || !is_user_alive(id)){
        menu_destroy(menu)
        return
    }
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return
    }
    
    new data[6], iName[22]
    new access, callback
    menu_item_getinfo(menu, item, access, data,5, iName, 21, callback)
    new key = str_to_num(data)
    
    new Cash = get_pdata_int(id,OFFSET_CSMONEY,5)
    if(Cash >= Weapons_Price[key] || get_vip_type(id) == 1)
    {
        if(get_vip_type(id) == 0)
            fm_set_user_money(id,Cash-Weapons_Price[key],1)
        
        Give_Item(id,key)
    }
    else
    {
        client_print(id,print_chat,"[Gun Menu]Not enough cash to buy %s",Weapons_Info[0][key])
        G_Info_page[id] -= 1
    }
    
    menu_destroy(menu)
    if(G_Info_page[id] < 5)Show_Menu(id)
}
public Give_Item(id,key)
{    
    if(get_pcvar_num(P_Cvars[key]) != 1)
    {
        client_print(id,print_chat,"[Gun Menu]Sry %s has been restricted by admin",Weapons_Info[0][key])
        fm_set_user_money(id,get_pdata_int(id,OFFSET_CSMONEY,5)+Weapons_Price[key],0)
        return
    }
    
    new weapons[2]
    Player_Guns(id,weapons)
    switch(key)
    {
        case 0..14:if(weapons[0] != 0)fm_strip_user_gun( id, weapons[0])
        case 15..19:if(weapons[1] != 0)fm_strip_user_gun( id, weapons[1])
    }
    if(Weapons_Info[1][key][9] == 108)
    {
        give_item(id,"weapon_flashbang")
        give_item(id,"weapon_flashbang")
        give_item(id,"weapon_smokegrenade")
        give_item(id,"weapon_hegrenade")
    }
    else give_item(id,Weapons_Info[1][key])
    if(Weapons_Info[2][key][0] != 0)
    {
        give_item(id,Weapons_Info[2][key])
        give_item(id,Weapons_Info[2][key])
        give_item(id,Weapons_Info[2][key])
    }
}
stock Player_Guns(id,weapons[2])
{
    new guns[32]
    new numWeapons=0, i, weapon 
    get_user_weapons(id, guns, numWeapons) 
    for (i=0; i<numWeapons; i++) 
    { 
        weapon = guns[i] 
        switch(weapon)
        {
            case 3,5,7,8,12,15,18..24,27,28,30:weapons[0]=weapon
            case 1,10,11,16,17,26:weapons[1]=weapon
        }
    } 
    return weapons
}
public enable_player_voice(id, player)
{
    static src[32], dst[32]
    get_user_name(player, dst, charsmax(dst))
    if (!get_bit(g_PlayerVoice, player)) 
    {
        set_bit(g_PlayerVoice, player)
        if(0 < id <= g_MaxClients)
        {
            get_user_name(id, src, charsmax(src))
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEENABLED", src, dst)
        }
    }
    else
    {
        clear_bit(g_PlayerVoice, player)
        if(0 < id <= g_MaxClients)
        {
            get_user_name(id, src, charsmax(src))
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEDISABLED", src, dst)
        }        
    }
}
public voice_enable_select(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    static dst[32], data[5], player, access, callback

    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    enable_player_voice(id, player)    
    cmd_simonmenu(id)
    return PLUGIN_HANDLED
}

public cmd_simon_micr(id)
{
    if (g_Simon == id || (get_user_flags(id) & VOICE_ADMIN_FLAG)) 
    {
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE")
        menu = menu_create(menuname, "cmd_simon_micr_choice")
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE_INDIVIDUAL")
        menu_additem(menu, option, "1", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE_ON_ALL")
        menu_additem(menu, option, "2", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE_OFF_ALL")
        menu_additem(menu, option, "3", 0)
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED  
}

public cmd_simon_micr_choice(id,menu, item)
{
    if(item == MENU_EXIT || !(id == g_Simon ||(get_user_flags(id) & ADMIN_SLAY)) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static src[32], data[5], access, callback,i
    menu_item_getinfo(menu, item, access, data, charsmax(data), src, charsmax(src), callback)
    menu_destroy(menu)
    get_user_name(id, src, charsmax(src))
    switch(data[0])
    {
        case('1'): 
        {
            menu_players(id, CS_TEAM_T, 0, 1, "voice_enable_select", "%L", LANG_SERVER, "UJBM_MENU_VOICE")
        }
        case('2'):
        {
            
            for(i = 1; i <= g_MaxClients; i++)
            {
                if(!is_user_connected(i) || !is_user_alive(i) || cs_get_user_team(i) == CS_TEAM_CT)
                    continue
                set_bit(g_PlayerVoice, i)
            }
            ColorChat(0, BLUE, "^x03%s^x01 a activat^x04 Vocea^x01 pentru toti prizonierii!!!", src)
            player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_VOICEENABLED_ALL")
            client_cmd(0,"spk fvox/voice_on")
        }
        case('3'):
        {
            for(i = 1; i <= g_MaxClients; i++)
            {
                if(!is_user_connected(i) || !is_user_alive(i) || cs_get_user_team(i) == CS_TEAM_CT)
                    continue
                clear_bit(g_PlayerVoice, i)
            }
            ColorChat(0, BLUE, "^x03%s^x01 a dezactivat^x04 Vocea^x01 pentru toti prizonierii!!!", src)
            player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_VOICEDISABLED_ALL")
            client_cmd(0,"spk fvox/voice_off")
        }
    }
    return PLUGIN_HANDLED
}

public  na2team(id) {
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
    {
        static src[32]
        get_user_name(id, src, charsmax(src))
        ColorChat(0, BLUE, "^x03%s^x01 a colorat prizonierii in^x04 2 echipe^x01!", src);
        player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_COLOR", src);
        log_amx("%s a colorat prizonierii in 2 echipe!", src);
        client_cmd(0,"spk vox/doop")

        new bool:orange = true

        for (new i=1; i<=g_MaxClients; i++) 
        {
            if(!is_user_connected(i))
                continue;
            if(!is_user_alive(i))
                continue;
            if(cs_get_user_team(i) != CS_TEAM_T)
                continue;
            if(get_bit(g_PlayerFreeday, i) || get_bit(g_PlayerWanted, i))
                continue;

            if (orange)
            {        
                entity_set_int(i, EV_INT_skin, 1)
                orange=false;
                set_user_rendering(i, kRenderFxGlowShell, 225, 125, 0, kRenderNormal, 25)
                player_hudmessage(i, 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER, "UJBM__COLOR_ORANGE")
                set_task(10.0,"turn_glow_off",TASK_RANDOM+i);

                get_user_name(i, src, charsmax(src));
                log_amx("%s a forst colorat in portocaliu", src);
            }
            else 
            {
                entity_set_int(i, EV_INT_skin, 2)
                orange=true;
                set_user_rendering(i, kRenderFxGlowShell, 225, 225, 225, kRenderNormal, 25)
                player_hudmessage(i, 10, HUD_DELAY + 1.0, {255, 255, 255}, "%L", LANG_SERVER, "UJBM__COLOR_WHITE")
                set_task(10.0,"turn_glow_off",TASK_RANDOM+i);

                get_user_name(i, src, charsmax(src));
                log_amx("%s a forst colorat in alb", src);
            }
        }
    }
    return PLUGIN_HANDLED
}
bool:GameAllowed()
{
    if (!is_not_game() || /*g_JailDay%7!= 3 || */g_JailDay%7!=6 && g_JailDay>0 || killed == 1)
        return false    
    return true;
}
public cmd_simonmenu(id)
{
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
    {
        client_cmd(id,"spk buttons/blip1.wav")
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU")
        menu = menu_create(menuname, "simon_choice")
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_OPEN")
        menu_additem(menu, option, "1", 0)
        if (g_GameMode == NormalDay)
        {    
            formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_FD")
            menu_additem(menu, option, "2", 0)
        
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_CLR")
            menu_additem(menu, option, "3", 0)    
            
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_SIMON_GAMES")
            menu_additem(menu, option, "4", 0)
        }

        formatex(option, charsmax(option), "\y%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_GONG")
        menu_additem(menu, option, "5", 0)

        if(g_GameMode == NormalDay)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_HEAL")
            menu_additem(menu, option, "6", 0)

            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_RANDOM")
            menu_additem(menu, option, "7", 0)

            formatex(option, charsmax(option), "\y%L\w", LANG_SERVER, "UJBM_MENU_REACTIONS")
            menu_additem(menu, option, "d", 0)

            //menu_additem(menu, "Pune catuse", "e", 0)

        }
        else if(g_GameMode == FunDay)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_SIMON_FUNMENU")
            menu_additem(menu, option, "9", 0)
        }

        //menu_additem(menu, "Desfa toate catusele", "f", 0)

        //formatex(option, charsmax(option), "%L",LANG_SERVER, "UJBM_MENU_BIND",bindstr)
        //menu_additem(menu, option, "8", 0)
        
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_PAINT")
        menu_additem(menu, option, "a", 0)
        
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_PUNISH")
        menu_additem(menu, option, "b", 0)
        
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE")
        menu_additem(menu, option, "c", 0)
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED
}
public  simon_choice(id, menu, item)
{
    if(item == MENU_EXIT || !(id == g_Simon ||(get_user_flags(id) & ADMIN_SLAY)) )
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
            cmd_open(id)
            cmd_simonmenu(id)
        }
        case('2'): cmd_freeday(id)
        case('3'): na2team(id)
        case('4'): cmd_simongamesmenu(id)
        case('5'): cmd_soundmenu(id)
        case('6'): heal_t(id)
        case('7'): random_t(id)
        case('8'): client_cmd(id,"bind v +simonvoice", bindstr)
        case('9'): cmd_funmenu(id)
        case('a'): menu_players(id, CS_TEAM_T, id, 1, "paint_select", "%L", LANG_SERVER, "UJBM_MENU_PAINT")
        case('b'): cmd_punish(id)
        case('c'): cmd_simon_micr(id)
        case('d'): cmd_reactionsmenu(id)
        case('e'): client_cmd(id, "say /buyhandcuffs")
        case('f'): client_cmd(id, "say /uncuffall")
    }        
    return PLUGIN_HANDLED
}

public  cmd_simongamesmenu(id)
{
    if ((g_Simon == id || (get_user_flags(id) & ADMIN_SLAY)) && is_not_game() && g_Duel==0 && g_DayTimer == 0)
    {
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU")
        menu = menu_create(menuname, "simon_gameschoice")
        new allowed[31];
        get_pcvar_string(gp_Games, allowed,31)
        if (strlen(allowed) <= 0 ) return PLUGIN_CONTINUE
        
        if (containi(allowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_GUARD_BOX")
            menu_additem(menu, option, "5", 0)
        }
        if (containi(allowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_GUARD_TRIVIA")
            menu_additem(menu, option, "100", 0)
        }
        
        if (GameAllowed() || ((get_user_flags(id) & ADMIN_SLAY) && killed == 0)) 
        {
            if (containi(allowed,"a") >= 0 && bool:g_GamesAp[AlienHiddenDay]==false && is_user_alive(g_Simon))
            {
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ALIEN2")
                menu_additem(menu, option, "1", 0)
            }
            
            if (containi(allowed,"b") >= 0  && bool:g_GamesAp[ZombieDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZM")
                menu_additem(menu, option, "2", 0)
            }
            if (containi(allowed,"c") >= 0  && bool:g_GamesAp[HnsDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_HNS")
                menu_additem(menu, option, "3", 0)
            }
            if (containi(allowed,"d") >= 0  && bool:g_GamesAp[AlienDay]==false && is_user_alive(g_Simon))
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ALIEN")
                menu_additem(menu, option, "4", 0)
            }
            if (containi(allowed,"f") >= 0  && bool:g_GamesAp[GunDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GUNDAY")
                menu_additem(menu, option, "7", 0)
            }
            if (containi(allowed,"g") >= 0  && bool:g_GamesAp[ColaDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_COLADAY")
                menu_additem(menu, option, "8", 0)
            }
            if (containi(allowed,"h") >= 0  && bool:g_GamesAp[GravityDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GRAVITY")
                menu_additem(menu, option, "9", 0)
            }
            /*if (containi(allowed,"i") >= 0  && bool:g_GamesAp[FireDay]==false && is_user_alive(g_Simon))
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_FIREDAY")
                menu_additem(menu, option, "10", 0)
            }*/
            if (containi(allowed,"j") >= 0  && bool:g_GamesAp[BugsDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_BUGSDAY")
                menu_additem(menu, option, "11", 0)
            }
            if (containi(allowed,"k") >= 0  && bool:g_GamesAp[NightDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_NIGHTCRAWLER")
                menu_additem(menu, option, "12", 0)
            }
            if (containi(allowed,"l") >= 0  && bool:g_GamesAp[SpartaDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_SPARTA")
                menu_additem(menu, option, "13", 0)
            }
            if (containi(allowed,"h") >= 0 && bool:g_GamesAp[SpiderManDay]==false)
            {
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_SPIDER")
                menu_additem(menu, option, "17", 0)
            }
            if (containi(allowed,"n") >= 0 && bool:g_GamesAp[CowboyDay]==false)
            {
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_COWBOY")
                menu_additem(menu, option, "18", 0)
            }
            if (containi(allowed,"l") >= 0  && bool:g_GamesAp[SpartaTeroDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_SPARTA_TERO")
                menu_additem(menu, option, "19", 0)
            }
            if (containi(allowed,"b") >= 0  && bool:g_GamesAp[ZombieTeroDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZMTERO")
                menu_additem(menu, option, "20", 0)
            }
            if (containi(allowed,"n") >= 0  && bool:g_GamesAp[ScoutDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_SCOUTS")
                menu_additem(menu, option, "21", 0)
            }
            if (containi(allowed,"n") >= 0  && bool:g_GamesAp[BoxDay]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_BOX")
                menu_additem(menu, option, "22", 0)
            }
            /*if (containi(allowed,"h") >= 0  && g_GamesAp[8]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_PRINSELEA")
                menu_additem(menu, option, "16", 0)
            }
            if (containi(allowed,"c") >= 0 && g_GamesAp[14]==false)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ASCUNSELEA")
                menu_additem(menu, option, "15", 0)
            }*/
            if (containi(allowed,"m") >= 0)
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_FUNDAY")
                menu_additem(menu, option, "14", 0)
            }
            //if (containi(allowed,"n") >= 0 && bool:g_GamesAp[OneBullet]==false)
            //{
            //    formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ONEBULLET")
            //    menu_additem(menu, option, "15", 0)
            //}
        }
        else
        {
            formatex(option, charsmax(option), "\d%L\w", LANG_SERVER,"UJBM_MENU_SIMONMENU_GAMENOAVE")
            menu_additem(menu, option, "0", 0)
        }
        if (containi(allowed,"f") >= 0 && is_plugin_loaded("[UJBM] Football"))
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_FOOTBALL")
            menu_additem(menu, option, "6", 0)
        }
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED
}

public heal_t(id)
{   if ((g_Simon == id || (get_user_flags(id) & ADMIN_KICK)) && g_Duel==0 && g_GameMode == NormalDay)
    {
        static src[32]
        get_user_name(id, src, charsmax(src))
        
        client_cmd(0,"spk fvox/medical_repaired")


        for (new i=1; i<=g_MaxClients; i++) 
        {
            if(!is_user_connected(i))
                continue;
            if(!is_user_alive(i))
                continue;
            if(cs_get_user_team(i) != CS_TEAM_T)
                continue;
            if(get_bit(g_PlayerWanted, i))
                continue;
            
            set_user_health(i, 150);
        }
        
        ColorChat(0, BLUE, "^x03%s^x01 a vindecat toti prizonierii pana la^x04 150 HP^x01!", src)
        log_amx("%s a vindecat toti prizonierii pana la 150 HP", src);
        player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_HEAL")
    }
    return PLUGIN_CONTINUE
}

public random_t(id)
{   
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
    {
        static src[32]
        get_user_name(id, src, charsmax(src))
        new Players[32],PlayersNr, RandomNr, RandomName[32]

        for (new i=1; i<=g_MaxClients; i++) 
        {
            if(!is_user_connected(i))
                continue;
            if(!is_user_alive(i))
                continue;
            if(cs_get_user_team(i) != CS_TEAM_T)
                continue;
            if(get_bit(g_PlayerFreeday, i) || get_bit(g_PlayerWanted, i))
                continue;

            Players[PlayersNr++] = i;
        }

        if(PlayersNr == 0)
            return PLUGIN_CONTINUE;

        RandomNr = Players[random(PlayersNr)];

        get_user_name(RandomNr, RandomName, 31)
        set_user_rendering(RandomNr, kRenderFxGlowShell, 225, 165, 0, kRenderNormal, 25)
        set_task(10.0,"turn_glow_off",TASK_RANDOM+RandomNr)
        ColorChat(0, BLUE, "^x03%s^x01 a ales la nimereala prizonierul^x04 %s^x01!", src, RandomName)
        log_amx("%s a ales la nimereala prizonierul %s", src, RandomName);
        player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_RANDOM_MSG", src, RandomName)
        client_cmd(0,"spk vox/bloop")
    }
    return PLUGIN_CONTINUE
}
public turn_glow_off (id)
{
    if(id > TASK_RANDOM)
    {
        id -= TASK_RANDOM;
    }
    if(is_user_alive(id))
    {
        set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
    }
}
public  simon_gameschoice(id, menu, item)
{
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    get_user_name(id, dst, charsmax(dst))
    new num = str_to_num(data)
    if(item == MENU_EXIT || !is_not_game() || (GameAllowed() == false && !(get_user_flags(id) & ADMIN_SLAY) || killed == 1) && num !=5 && num!=6 && num!=100)
    {
        cmd_simonmenu(id)
        return PLUGIN_HANDLED
    }
    switch(num)
    {
        case(1):
        {
            client_print(0, print_console, "%s A DAT ALIEN DAY", dst)
            log_amx("%s A DAT ALIEN DAY", dst)
            cmd_game_alien2()
        }
        case(2):
        {
            client_print(0, print_console, "%s A DAT ZOMBIE DAY", dst)
            log_amx("%s A DAT ZOMBIE DAY", dst)
            cmd_pregame("cmd_game_zombie",1, 0,30.0)
        }
        case(3): 
        {
            client_print(0, print_console, "%s A DAT HNS DAY", dst)
            log_amx("%s A DAT HNS DAY", dst)
            cmd_pregame("cmd_game_hns", 2, 0, 60.0)
            jail_open()
        }
        case(4):
        {
            client_print(0, print_console, "%s A DAT ALIEN DAY", dst)
            log_amx("%s A DAT ALIEN DAY", dst)
            cmd_game_alien()
        }
        case(5):
        {
            cmd_box(id)
        }
        case(6):
        {
            client_cmd(id,"say /ball");
        }
        case(7):
        {
            client_print(0, print_console, "%s A DAT GUNDAY", dst)
            log_amx("%s A DAT GUNDAY", dst)
            cmd_pregame("cmd_game_gunday", 1, 0, 30.0)
        }
        case(8):
        {
            client_print(0, print_console, "%s A DAT COLADAY", dst)
            log_amx("%s A DAT COLADAY", dst)
            cmd_pregame("cmd_game_coladay", 1, 0, 30.0)
        }
        case(9):
        {
            client_print(0, print_console, "%s A DAT GRAVITY DAY", dst)
            log_amx("%s A DAT GRAVITY DAY", dst)
            set_cvar_num("sv_gravity",250)
            cmd_pregame("cmd_game_gravity", 2, 0, 30.0)
            jail_open()
        }
        case(10):
        {
            client_print(0, print_console, "%s A DAT FIRE DAY", dst)
            log_amx("%s A DAT FIRE DAY", dst)
            cmd_pregame("cmd_game_fire", 2, 1, 30.0)
            jail_open()
        }
        case(11):
        {
            client_print(0, print_console, "%s A DAT BUGS DAY", dst)
            log_amx("%s A DAT BUGS DAY", dst)
            cmd_game_bugs()
        }
        case(12):
        {
            client_print(0, print_console, "%s A DAT NIGHTCRAWLER", dst)
            log_amx("%s A DAT NIGHTCRAWLER day", dst)
            cmd_game_nightcrawler()
        }
        case(13):
        {
            client_print(0, print_console, "%s A DAT SPARTA", dst)
            log_amx("%s A DAT SPARTA day", dst)
            cmd_game_sparta()
        }
        case(14):
        {
            client_print(0, print_console, "%s A DAT FUNDAY", dst)
            log_amx("%s A DAT FUNDAY", dst)
            cmd_game_funday()
            cmd_simonmenu(id)
        }
        case(15):
        {
            client_print(0, print_console, "%s gives onebullet", dst)
            log_amx("%s gives onebullet", dst)
            cmd_pregame("cmd_game_onebullet", 0, 0, 30.0)
        }
        /*case(15):
        {
            client_print(0, print_console, "%s gives ascunsea", dst)
            log_amx("%s gives ascunsea", dst)
            cmd_game_ascunsea()
        }
        case(16):
        {
            client_print(0, print_console, "%s gives prinselea day", dst)
            log_amx("%s gives prinselea day", dst)
            cmd_game_prinselea()
        }*/
        case(17):
        {
            client_print(0, print_console, "%s gives spider day", dst)
            log_amx("%s gives spider day", dst)
            cmd_game_spider()
        }
        case(18):
        {
            client_print(0, print_console, "%s gives cowboy day", dst)
            log_amx("%s gives cowboy day", dst)
            cmd_pregame("cmd_game_cowboy", 1, 0, 30.0)
        }
        case(19):
        {
            client_print(0, print_console, "%s gives reverse sparta day", dst)
            log_amx("%s gives reverse sparta day", dst)
            cmd_pregame("cmd_game_sparta_tero", 1, 0, 30.0)
        }
        case(20):
        {
            client_print(0, print_console, "%s A DAT REVERSE ZOMBIE DAY", dst)
            log_amx("%s A DAT REVERSE ZOMBIE DAY", dst)
            cmd_pregame("cmd_game_zombie_tero",2, 0,30.0)
            jail_open()
        }
        case(21):
        {
            client_print(0, print_console, "%s A DAT SNIPER DAY", dst)
            log_amx("%s A DAT SNIPER DAY", dst)
            cmd_game_scouts()
        }
        case(22):
        {
            client_print(0, print_console, "%s A DAT BOX DAY", dst)
            log_amx("%s A DAT BOX DAY", dst)
            cmd_game_box()
        }
        case(100):
        {
            client_print(0, print_console, "%s A DAT TRIVIA", dst)
            log_amx("%s A DAT TRIVIA", dst)
            server_cmd("simon_trivia %d",id)
        }
        default:
        {
            cmd_simonmenu(id)
        }
    }    
    return PLUGIN_HANDLED
}
stock cs_set_user_team2(index, {CsTeams,_}:team, update = 1)
{
    if (index == g_Simon)
    {
        g_Simon = 0
        hud_status(0)
    }
    set_pdata_int(index, OFFSET_TEAM, _:team)
    set_pev(index, pev_team, _:team)
    if(update)
    {
        static _msg_teaminfo; if(!_msg_teaminfo) _msg_teaminfo = get_user_msgid("TeamInfo")
        static teaminfo[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }
        message_begin(MSG_ALL, _msg_teaminfo)
        write_byte(index)
        write_string(teaminfo[_:team])
        message_end()
    }
    return 1
}
public  cmd_punish_ct(id, menu, item)
{
    if(item == MENU_EXIT ||( g_Simon != id && !(get_user_flags(id) & ADMIN_SLAY)))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32],src[32], data[5], player, access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    if (g_Simon == player) return PLUGIN_CONTINUE
    cs_set_user_team2(player, CS_TEAM_T)
    disarm_player(player)
    get_user_name(player, dst, charsmax(dst))
    get_user_name(id, src, charsmax(src))
    set_user_info(player, "model", JBMODELSHORT)
    new rez = random_num(1,2)
    if( rez == 1 || rez == 2)
    {
        entity_set_int(player, EV_INT_body, 1+rez)
    }
    else
    {
        log_amx("Caugth rez to bee %d",rez)
        entity_set_int(player, EV_INT_body, 2)
    }
    set_bit(g_PlayerWanted, player)
    entity_set_int(player, EV_INT_skin, 5)
    player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_SIMON_PUNISH", src, dst,dst)    
    return PLUGIN_HANDLED
}
public chooseteamfunc(id)
{
    if (g_GameMode == AlienDay || g_GameMode == AlienHiddenDay) return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE
}
public task_freeday_end()
{
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    g_GameMode = NormalDay
    set_dhudmessage(0, 255, 0, -1.0, 0.35, 0, 6.0, 15.0)
    show_dhudmessage(0, "%L", LANG_SERVER, "UJBM_STATUS_ENDFREEDAY")
    resetsimon()
    new playerCount, i 
    new Players[32] 
    new rez
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++) 
    {
        if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && !get_bit(g_PlayerFreeday, Players[i]) && !get_bit(g_PlayerWanted, Players[i]))
        {
            rez = random_num(0,3)
            if( rez >= 0 && rez <= 3)
            {
                entity_set_int(Players[i], EV_INT_skin, rez)
            }
            else{
                log_amx("Caugth rez to be %d",rez)
                entity_set_int(Players[i], EV_INT_body, 0)
            }
            if (get_pcvar_num (gp_ShowColor) == 1 ) show_color(Players[i])    
        }
    }
    return PLUGIN_CONTINUE
}
public rocket_touch(id, world)
{
    new Float:location[3]
    new players[32]
    new playercount
    entity_get_vector(id,EV_VEC_origin,location)
    emit_sound(id, CHAN_WEAPON, _RpgSounds[2], 0.0, 0.0, SND_STOP, PITCH_NORM)    
    explode(location, SpriteExplosion, 30, 10, 0)
    get_players(players,playercount,"a")
    for (new i=0; i<playercount; i++)
    {
        new Float:playerlocation[3]
        new Float:resultdistance
        pev(players[i], pev_origin, playerlocation)
        resultdistance = get_distance_f(playerlocation,location)
        if(resultdistance < 450.0)
        {
            if(players[i]==g_DuelA || players[i]==g_DuelB)
                fakedamage(players[i],"RPG",(1000.0 - (2.0*resultdistance)),DMG_BLAST)
        }
    }
    emit_sound(id, CHAN_AUTO, _RpgSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
    remove_entity(id)
    return PLUGIN_CONTINUE    
}
public current_weapon_fl(id)
{
    if(!is_user_alive(id))
        return PLUGIN_CONTINUE
    if (g_Duel > 3 && _Duel[DuelWeapon][_csw] == CSW_FLASHBANG)
    {
        set_pev(id, pev_viewmodel2, _RpgModels[1])
        set_pev(id, pev_weaponmodel2, _RpgModels[0])    
    }    
    return PLUGIN_CONTINUE
}
public rpg_touch(id, world)
{
    new Float:v[3]
    new Float:volume
    entity_get_vector(id, EV_VEC_velocity, v)
    v[0] = (v[0] * 0.45)
    v[1] = (v[1] * 0.45)
    v[2] = (v[2] * 0.45)
    entity_set_vector(id, EV_VEC_velocity, v)
    volume = get_speed(id) * 0.005; 
    if (volume > 1.0) volume = 1.0
    if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM)
    return PLUGIN_CONTINUE    
}
public explode(Float:startloc[3], spritename, scale, framerate, flags)
{
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(3) // TE_EXPLOSION
    write_coord(floatround(startloc[0]))
    write_coord(floatround(startloc[1]))
    write_coord(floatround(startloc[2])) // start location
    write_short(spritename) // spritename
    write_byte(scale) // scale of sprite
    write_byte(framerate) // framerate of sprite
    write_byte(flags) // flags
    message_end()
}
public rpg_pre(weapon)
{
    if (!is_valid_ent(weapon)) return PLUGIN_CONTINUE
    new id = entity_get_edict( weapon, EV_ENT_owner )
    if (g_Duel > 3 && _Duel[DuelWeapon][_csw] == CSW_FLASHBANG )
    {
        
        new  ent
        new Float:where[3]
        new gmsgShake = get_user_msgid("ScreenShake") 
        message_begin(MSG_ONE, gmsgShake, {0,0,0}, id)
        write_short(255<< 14 ) //ammount 
        write_short(1 << 14) //lasts this long 
        write_short(255<< 14) //frequency 
        message_end() 
        ent = create_entity("info_target")
        set_pev(ent, pev_classname, "rpg_missile")
        set_pev(ent, pev_solid, SOLID_TRIGGER)
        set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
        entity_set_model(ent, "models/rpgrocket.mdl")
        pev(id, pev_origin, where)
        where[2] += 50.0;
        where[0] += random_float(-20.0, 20.0)
        where[1] += random_float(-20.0, 20.0)
        entity_set_origin(ent, where)
        entity_get_vector(id,EV_VEC_angles,where)
        entity_set_vector(ent, EV_VEC_angles, where)
        velocity_by_aim(id, 700, where)
        entity_set_edict(ent,EV_ENT_owner,id)
        entity_set_vector(ent,EV_VEC_velocity,where)
        message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
        write_byte( TE_BEAMFOLLOW )
        write_short(ent) // entity
        write_short(m_iTrail)  // model
        write_byte( 10 )       // lifeffffff
        write_byte( 8 )        // width
        write_byte( 130)      // r, g, b
        write_byte( 130 )    // r, g, b
        write_byte( 130 )      // r, g, b
        write_byte( 196 )     // brightness
        message_end()
        emit_sound(id, CHAN_WEAPON, _RpgSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
        emit_sound(ent, CHAN_WEAPON, _RpgSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
        register_think("rpg_missile","fw_rocket_think");
        set_pev(ent, pev_nextthink, get_gametime()+0.25);
        set_pdata_float( weapon , 46 , 2.5, 4 );
        set_user_weaponanim(id, 2)
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}
stock set_user_weaponanim(id, anim)
{
    entity_set_int(id, EV_INT_weaponanim, anim)
    message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
    write_byte(anim)
    write_byte(entity_get_int(id, EV_INT_body))
    message_end()
}  
public rpg_reload(weapon)
{
    if (g_Duel > 3 && _Duel[g_Duel - 4][_csw] == CSW_FLASHBANG)
    {
        new id = entity_get_edict( weapon, EV_ENT_owner )
        set_user_weaponanim(id, 2)
    }
    return HAM_IGNORED
}
public cmd_lastrequest1(id)
{
    g_Duel = 5    
    g_DuelA = id
    disarm_player(id)
    new gun = give_item(id, _Duel[DuelWeapon][_entname])
    cs_set_weapon_ammo(gun, 1)
    set_user_health(id, 2000)
    entity_set_int(id, EV_INT_body, 6)
    player_glow(id, g_Colors[3])
    current_weapon_fl(id)
}
public fw_rocket_think(ent)
{

    new id = entity_get_edict( ent, EV_ENT_owner )
    new classname[32]
    entity_get_string(ent,EV_SZ_classname,classname,31)
    if(equali(classname,"rpg_missile")){
        new Float:where[3]
        entity_get_vector(id,EV_VEC_angles,where)
        entity_set_vector(ent, EV_VEC_angles, where)
        velocity_by_aim(id, 700, where)
        entity_set_vector(ent,EV_VEC_velocity,where)
        entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.25) 
    }
    return PLUGIN_CONTINUE
}
public sqrt(num) 
{ 
    // Cool - Newton's Method - Ludwig 
    new div = num, result = 1 
    while (div > result) 
    {  // end when div == result, or just below 
        div = (div + result) / 2 // take mean value as new divisor 
        result = num / div 
    } 
    return div 
}
public cmd_motiv (id)
{
    new Msg[2049],Len = 0;
    Len += format(Msg[Len], 2048 - Len,"<html><body style=^"background-color:black;color:white^"><table width=^"100%%^"><tr align=^"center^"><th>Nume</th><th>Motiv de incarcerare</th></tr>")
    new Players [32],inum;
    get_players(Players,inum)
    for(new pl=0;pl<inum;pl++){
        new player = Players[pl]
        if(cs_get_user_team(player) != CS_TEAM_CT && g_PlayerReason[player]>0){
            new name[256]
            get_user_name(player,name,255)
            Len += format(Msg[Len], 2048 - Len,"<tr align=^"center^"><td>%s</td><td>%L</td></tr>",name,LANG_SERVER, g_Reasons[g_PlayerReason[player]])
        }
    }
    Len += format(Msg[Len], 2048 - Len,"</table></body></html>")
    //write_file("help.txt",Msg,0)
    show_motd(id,Msg,"Motive")
    return PLUGIN_HANDLED
}

public cmd_listfd (id)
{
    new Msg[2049],Len = 0;
    Len += format(Msg[Len], 2048 - Len,"<html><body style=^"background-color:black;color:white^"><table width=^"100%%^"><tr align=^"center^"><th>Nume</th><th>Freeday?</th></tr>")
    new Players [32],inum;
    get_players(Players,inum)
    for(new pl=0;pl<inum;pl++){
        new player = Players[pl]
        if(cs_get_user_team(player) != CS_TEAM_CT){
            new name[256]
            get_user_name(player,name,255)
            Len += format(Msg[Len], 2048 - Len,"<tr align=^"center^"><td>%s</td><td>",name)
            if(get_bit(g_PlayerLastFreeday,player))
                Len += format(Msg[Len], 2048 - Len,"Da</td></tr>")
            else
                Len += format(Msg[Len], 2048 - Len,"Nu</td></tr>")
        }
    }
    Len += format(Msg[Len], 2048 - Len,"</table></body></html>")
    //write_file("help.txt",Msg,0)
    show_motd(id,Msg,"Fd list")
    return PLUGIN_HANDLED
}

public help_trollface()
{
    new Msg[512];
    format(Msg, 511, "%L",LANG_SERVER,"UJBM_HELP_CHAT");
    client_print(0,print_chat,Msg)
    format(Msg, 511, "^x01Powered by ^x03%s ^x01%s by ^x03%s",PLUGIN_CVAR,PLUGIN_VERSION,PLUGIN_AUTHOR);
    new iPlayers[32], iNum, i;
    get_players(iPlayers, iNum);
    for(i = 0; i < iNum; i++)
    {
        new x = iPlayers[i];
        
        if(!is_user_connected(x) || is_user_bot(x)) continue;
        message_begin( MSG_ONE, g_iMsgSayText, {0,0,0}, x );
        write_byte  ( x );
        write_string( Msg );
        message_end ();
    }
    return PLUGIN_CONTINUE
}
public Showcl_min(id) 
{
    new menu = menu_create("\yset cl_minmodels to 0? You will be able to see high quality models\w^n", "cl_choice")
    //formatex(option, charsmax(option),  )
    menu_additem(menu, "Yes", "1", 0)
    //formatex(option, charsmax(option), "\rNo^n")
    menu_additem(menu, "No, thanks", "2", 0)
    menu_display(id, menu)
}
public cl_choice(id, menu, item) 
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    if (data[0])
    {
        client_cmd(id,"cl_minmodels 0")
        client_print(id,print_console, "cl_minmodels is now 0, enjoy normal models :)")
    }
    return PLUGIN_CONTINUE
}

disarm_player(victim){
    
    if(is_user_alive(victim) && is_user_connected(victim))
    {
        new origin[3]
        get_user_origin(victim,origin)
        origin[2] -= 2000
        fm_set_user_origin(victim,origin)
        new iweapons[32], wpname[32], inum
        get_user_weapons(victim,iweapons,inum)
        for(new a=0;a<inum;++a){
            get_weaponname(iweapons[a],wpname,31)
            engclient_cmd(victim,"drop",wpname)
        }
        engclient_cmd(victim,"weapon_knife")
        origin[2] += 2005
        fm_set_user_origin(victim,origin)
    }
}
stock bool:fm_strip_user_gun(index, wid = 0, const wname[] = "")
{
    new ent_class[32]
    if (!wid && wname[0])copy(ent_class, sizeof ent_class - 1, wname)
    else
    {
        new weapon = wid, clip, ammo
        if (!weapon && !(weapon = get_user_weapon(index, clip, ammo)))return false
        get_weaponname(weapon, ent_class, sizeof ent_class - 1)
    }
    
    new ent_weap = fm_find_ent_by_owner(-1, ent_class, index)
    if (!ent_weap)return false
    
    engclient_cmd(index, "drop", ent_class)
    
    new ent_box = pev(ent_weap, pev_owner)
    if (!ent_box || ent_box == index)return false
    
    dllfunc(DLLFunc_Think, ent_box)
    
    return true
}
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
    new strtype[11] = "classname", ent = index
    switch (jghgtype)
    {
        case 1: strtype = "target"
        case 2: strtype = "targetname"
    }
    
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}
    return ent
}
stock fm_set_user_origin(index, /* const */ origin[3]) {
    new Float:orig[3]
    IVecFVec(origin, orig)

    return fm_entity_set_origin(index, orig)
}
stock fm_entity_set_origin(index, const Float:origin[3]) {
    new Float:mins[3], Float:maxs[3]
    pev(index, pev_mins, mins)
    pev(index, pev_maxs, maxs)
    engfunc(EngFunc_SetSize, index, mins, maxs)

    return engfunc(EngFunc_SetOrigin, index, origin)
}
stock fm_set_user_money(id,money,flash=1)
{
    set_pdata_int(id,OFFSET_CSMONEY,money,5)
    message_begin(MSG_ONE,get_user_msgid("Money"),{0,0,0},id)
    write_long(money)
    write_byte(flash)
    message_end()
}
bool:check_model(id)
{
    new model[32];
    get_user_info(id,"model",model,31);
    if(equali(model,JBMODELSHORT))
        return true;
    return false;
}

public block_FITH_message(msg_id, msg_dest, entity)
{
    if(g_BoxStarted == 1 || g_GameMode == BoxDay)
    {
        if ( get_msg_arg_int ( 1 ) == print_notify )
            {
                return PLUGIN_CONTINUE;
            }
        static s_Message[ 22 ];
        get_msg_arg_string  ( 2, s_Message, charsmax ( s_Message ) );
        
        if ( equal ( s_Message, "#Game_teammate_attack" ) || equal ( s_Message, "#Killed_Teammate" ) || equal ( s_Message, "#Game_teammate_kills" ) )
        {
            return PLUGIN_HANDLED;
        }
    }
    return PLUGIN_CONTINUE;
}

public block_FITH_audio(msg_id, msg_dest, entity)
{
    if(g_GameMode != ColaDay) return PLUGIN_CONTINUE
    if(get_msg_args() == 3)
    {
        if(get_msg_argtype(2) == ARG_STRING)
        {
            new value2[64];
            get_msg_arg_string(2 ,value2 ,63);
            if(equal(value2 ,"%!MRAD_FIREINHOLE"))
            {
                return PLUGIN_HANDLED;
            }
        }
    }
    return PLUGIN_CONTINUE;
}

public Event_CurWeapon(id) 
{     
    new weaponID = read_data(2)        
    if(g_GameMode == ColaDay)
    {
        if(weaponID != CSW_HEGRENADE)
            return PLUGIN_CONTINUE
        entity_set_string(id, EV_SZ_viewmodel, COLA_V)  
        entity_set_string(id, EV_SZ_weaponmodel, COLA_P) 
    }
    return PLUGIN_CONTINUE 
}

public fw_player_scope(const iWpnid)
{
    new id = entity_get_edict(iWpnid, EV_ENT_owner)
    if(g_Scope == 0 && (id == g_DuelA || id == g_DuelB))
        return HAM_SUPERCEDE;
    return HAM_IGNORED;
}

public cmd_unsimon(id)
{
    if(get_user_flags(id) & ADMIN_LEVEL_E)
    {
        set_user_info(g_Simon, "model", JBMODELSHORT)
        new rez = random_num(1,2)
        if( rez == 1 || rez == 2)
            {
                entity_set_int(g_Simon, EV_INT_body, 3+rez)
            }
            else
            {
                log_amx("Caugth rez to be %d",rez)
                entity_set_int(g_Simon, EV_INT_body, 4)
            }
        
        g_Simon = 0
        resetsimon()
    }
}

public ReactionDuel()
{    
    g_DuelReaction = random_num(0, 2)
    g_DuelJumped[g_DuelA] = 0
    g_DuelJumped[g_DuelB] = 0
    switch(g_DuelReaction)
    {
        case 0:
        {
            client_cmd(0,"spk jbextreme/jump_.wav")
            client_print(0, print_chat, "[Duel] Primul care face comanda traieste: JUMP.")
        }
        case 1:
        {
            client_cmd(0,"spk jbextreme/duck_.wav")
            client_print(0, print_chat, "[Duel] Primul care face comanda traieste: DUCK.")
        }
        case 2:
        {
            client_cmd(0,"spk jbextreme/duckjump_.wav")
            client_print(0, print_chat, "[Duel] Primul care face comanda traieste: DUCK JUMP.")
        }
    }
    g_DuelReactionStarted = 1
}

public player_jump(id)
{
    if(g_Duel == 0 || id != g_DuelA || id != g_DuelB)
        return PLUGIN_CONTINUE
    if(g_DuelReactionStarted == 0)
        return PLUGIN_CONTINUE
    new DuelA[32], DuelB[32]
    get_user_name(g_DuelA, DuelA, charsmax(DuelA))
    get_user_name(g_DuelB, DuelB, charsmax(DuelB))
    g_DuelJumped[id] = 1
    switch(g_DuelReaction)
    {
        case (0): 
        {
            if(id == g_DuelA)
                {
                    user_kill(g_DuelB)
                    server_cmd("give_points %d 3", g_DuelA)
                    client_print(0, print_chat, "%s a facut primul Jump si a castigat duelul.", DuelA)
                }
            if(id == g_DuelB)
                {
                    user_kill(g_DuelA)
                    server_cmd("give_points %d 3", g_DuelB)
                    client_print(0, print_chat, "%s a facut primul Jump si a castigat duelul.", DuelB)
                }    
        }
        case (1):
        {
            if(id == g_DuelA)
                {
                    user_kill(g_DuelA)
                    server_cmd("give_points %d 3", g_DuelB)
                    client_print(0, print_chat, "%s a facut o comanda gresita si a pierdut duelul.", DuelA)
                }
            if(id == g_DuelB)
                {
                    user_kill(g_DuelB)
                    server_cmd("give_points %d 3", g_DuelA)
                    client_print(0, print_chat, "%s a facut o comanda gresita si a pierdut duelul.", DuelB)
                }
        }
        case (2):
        {
            if(g_DuelDucked[id] == 1)
                {
                    if(id == g_DuelA)
                    {
                        user_kill(g_DuelB)
                        server_cmd("give_points %d 3", g_DuelA)
                        client_print(0, print_chat, "%s a facut primul Duck Jump si a castigat duelul.", DuelA)
                    }
                    if(id == g_DuelB)
                    {
                        user_kill(g_DuelA)
                        server_cmd("give_points %d 3", g_DuelB)
                        client_print(0, print_chat, "%s a facut primul Duck Jump si a castigat duelul.", DuelB)
                    }    
                }
        }
    }
    return PLUGIN_CONTINUE
}

public player_duck(id)
{
    if(g_Duel == 0 || id != g_DuelA || id != g_DuelB)
        return PLUGIN_CONTINUE
    if(g_DuelReactionStarted == 0)
        return PLUGIN_CONTINUE
    new DuelA[32], DuelB[32]
    get_user_name(g_DuelA, DuelA, charsmax(DuelA))
    get_user_name(g_DuelB, DuelB, charsmax(DuelB))
    g_DuelDucked[id] = 1
    switch(g_DuelReaction)
    {
        case (0): 
        {
            if(id == g_DuelA)
                {
                    user_kill(g_DuelA)
                    server_cmd("give_points %d 3", g_DuelB)
                    client_print(0, print_chat, "%s a facut o comanda gresita si a pierdut duelul.", DuelA)
                }
            if(id == g_DuelB)
                {
                    user_kill(g_DuelB)
                    server_cmd("give_points %d 3", g_DuelA)
                    client_print(0, print_chat, "%s a facut o comanda gresita si a pierdut duelul.", DuelB)
                }
        }    
        case (1):
        {
            if(id == g_DuelA)
                {
                    user_kill(g_DuelB)
                    server_cmd("give_points %d 3", g_DuelA)
                    client_print(0, print_chat, "%s a facut primul Duck si a castigat duelul.", DuelA)
                }
            if(id == g_DuelB)
                {
                    user_kill(g_DuelA)
                    server_cmd("give_points %d 3", g_DuelB)
                    client_print(0, print_chat, "%s a facut primul Duck si a castigat duelul.", DuelB)
                }    
        }
        case (2):
        {
            if(g_DuelJumped[id] == 1)
                {
                    if(id == g_DuelA)
                    {
                        user_kill(g_DuelB)
                        server_cmd("give_points %d 3", g_DuelA)
                        client_print(0, print_chat, "%s a facut primul Duck Jump si a castigat duelul.", DuelA)
                    }
                    if(id == g_DuelB)
                    {
                        user_kill(g_DuelA)
                        server_cmd("give_points %d 3", g_DuelB)
                        client_print(0, print_chat, "%s a facut primul Duck Jump si a castigat duelul.", DuelB)
                    }    
                }
        }
    }
    return PLUGIN_CONTINUE
}

stock str_explode(const string[], delimiter, output[][], output_size, output_len)
{
    new i, pos, len = strlen(string)
    
    do
    {
        pos += (copyc(output[i++], output_len, string[pos], delimiter) + 1)
    }
    while(pos < len && i < output_size)
    
    return i
}

public cmd_donate(id, level, cid)
{
    new sString[96]
    read_args(sString, charsmax(sString))
    remove_quotes(sString)
    
    new sOutput[4][16], userid, sName[32], iAmount
    str_explode(sString, ' ', sOutput, 4, 15)
    
    new maxmoney = get_cvar_num("amx_donate_max")
    
    if(equali(sOutput[0], "/donate"))
    {
        userid = cmd_target(id, sOutput[1], CMDTARGET_NO_BOTS)
        iAmount = str_to_num(sOutput[2])
        
        if(!is_user_alive(id))
        {
            client_print(id, print_chat, "Nu poti dona cand esti mort.")
            return 0
        }
        if(!is_user_alive(userid))
        {
            client_print(id, print_chat, "Nu poti dona unui player care este mort.")
            return 0
        }
        if(g_Donated[id] == 2)
        {
            client_print(id, print_chat, "Poti dona de maxim 2 ori intr-o runda.")
            return 0
        }
        if(userid == id)
        {
            client_print(id, print_chat, "Nu iti poti dona bani tie.")
            return 0
        }
        if(!strlen(sOutput[2]) || !iAmount || contain(sOutput[2], "-") != -1)
        {
            client_print(id, print_chat, "Nu ai introdus valoarea.")
            return 0
        }
        if(cs_get_user_money(id) < iAmount)
        {
            client_print(id, print_chat, "Nu ai destui bani.")
            return 0
        }
        if(iAmount > maxmoney)
        {
            client_print(id, print_chat, "Poti dona maxim $%s.", maxmoney)
            return 0
        }
        
        get_user_name(userid, sOutput[1], charsmax(sOutput[]))
        get_user_name(id, sName, charsmax(sName))
        cs_set_user_money(userid, iAmount+cs_get_user_money(userid), 0)
        cs_set_user_money(id, cs_get_user_money(id)-iAmount, 0)
        client_cmd(userid,"spk jbextreme/kaching.wav")    
        fadeout(userid, 0, 100, 0)
        ColorChat(0, RED, "^x03%s^x01 i-a donat lui^x03 %s^x01 suma de^x04 $%d^x01.", sName, sOutput[1], iAmount)      
        g_Donated[id] += 1
        return 1
    }
    return 0;
}

public cmd_soundmenu(id)
{
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY)) 
    {
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SOUNDMENU")
        menu = menu_create(menuname, "cmd_soundmenu_choice")
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_DING")
        menu_additem(menu, option, "1", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_START")
        menu_additem(menu, option, "2", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_HORN")
        menu_additem(menu, option, "3", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_HORN2")
        menu_additem(menu, option, "4", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_DOVUS")
        menu_additem(menu, option, "5", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SOUNDMENU_MOFO")
        menu_additem(menu, option, "6", 0)
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED  
}

public  cmd_soundmenu_choice(id, menu, item)
{
    if(item == MENU_EXIT || !(id == g_Simon ||(get_user_flags(id) & ADMIN_SLAY)) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    cmd_simonmenu(id)
    get_user_name(id, dst, charsmax(dst))
    if(ding_on == 1)
    {
        new name[32]
        get_user_name(id, name, 31)
        ColorChat(0, BLUE, "^x03%s^x01 A DAT UN^x04 SUNET^x01!!!", name)
        ding_on = 0
        set_task(5.0,"power_ding",5146)
        switch(data[0])    
        {        
            case('1'): emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            case('2'): emit_sound(0, CHAN_AUTO, "jbextreme/start_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            case('3'): emit_sound(0, CHAN_AUTO, "jbextreme/horn_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            case('4'): emit_sound(0, CHAN_AUTO, "jbextreme/horn2_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            case('5'): emit_sound(0, CHAN_AUTO, "jbextreme/voicestart_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            case('6'): emit_sound(0, CHAN_AUTO, "jbextreme/dingdingding.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        }    
    }
    return PLUGIN_HANDLED
}

public on_damage(id)
{
    static damage, attacker
    attacker = get_user_attacker(id)
    damage = read_data(2)
    if (is_user_connected(attacker))
        switch(g_GameMode)
        {
            case AlienHiddenDay, BugsDay, SpartaDay, NightDay, ZombieTeroDay:
                if(cs_get_user_team(attacker) == CS_TEAM_T)
                    g_DamageDone[attacker] += damage
            case ColaDay, GunDay, SpiderManDay, CowboyDay, ScoutDay:
                g_DamageDone[attacker] += damage
            case ZombieDay, GravityDay, HnsDay, SpartaTeroDay:
                if(cs_get_user_team(attacker) == CS_TEAM_CT)
                    g_DamageDone[attacker] += damage
        }
}

public camera_menu(id)
{
    if(!is_user_alive(id))
    {
        return 1;
    }
    
    new menu = menu_create("Alege o optiune!", "cam_m_handler"), sText[48], bool:mode = (g_iPlayerCamera[id] > 0) ? true:false;
    
    formatex(sText, charsmax(sText), "%s \rCamera 3D!", (mode) ? "\dOpreste":"\yPorneste")
    menu_additem(menu, sText)
    
    if(mode)
    {
        menu_additem(menu, "In fata! (Se poate apasa de mai multe ori)")
        menu_additem(menu, "In spate! (Se poate apasa de mai multe ori)")
    }
    
    menu_display(id, menu)
    return 1;
}

public cam_m_handler(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return 1;
    }
    
    menu_destroy(menu);
    
    if(g_iPlayerCamera[id] > 0 && item == 0)
    {
        disconnect_camera(id)
        engfunc(EngFunc_SetView, id, id);
    }
    else
    {
        switch( item )
        {
            case 0:
            {
                g_camera_position[id] = -150.0;
                enable_camera(id)
            }
            case 1: if(g_camera_position[id] < MAX_FORWARD_UNITS) g_camera_position[id] += 50.0;
            case 2: if(g_camera_position[id] > MAX_BACKWARD_UNITS) g_camera_position[id] -= 50.0;
        }
    }
    
    camera_menu(id)
    return 1;
}

public enable_camera(id)
{ 
    if(!is_user_alive(id)) return;
    
    new iEnt = g_iPlayerCamera[id] 
    if(!pev_valid(iEnt))
    {
        static iszTriggerCamera 
        if( !iszTriggerCamera ) 
        { 
            iszTriggerCamera = engfunc(EngFunc_AllocString, "trigger_camera") 
        } 
        
        iEnt = engfunc(EngFunc_CreateNamedEntity, iszTriggerCamera);
        set_kvd(0, KV_ClassName, "trigger_camera") 
        set_kvd(0, KV_fHandled, 0) 
        set_kvd(0, KV_KeyName, "wait") 
        set_kvd(0, KV_Value, "999999") 
        dllfunc(DLLFunc_KeyValue, iEnt, 0) 
    
        set_pev(iEnt, pev_spawnflags, SF_CAMERA_PLAYER_TARGET|SF_CAMERA_PLAYER_POSITION) 
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_ALWAYSTHINK) 
    
        dllfunc(DLLFunc_Spawn, iEnt)
    
        g_iPlayerCamera[id] = iEnt;
 //   }     
        new Float:flMaxSpeed, iFlags = pev(id, pev_flags) 
        pev(id, pev_maxspeed, flMaxSpeed)
        
        ExecuteHam(Ham_Use, iEnt, id, id, USE_TOGGLE, 1.0)
        
        set_pev(id, pev_flags, iFlags)
        // depending on mod, you may have to send SetClientMaxspeed here. 
        // engfunc(EngFunc_SetClientMaxspeed, id, flMaxSpeed) 
        set_pev(id, pev_maxspeed, flMaxSpeed)
    }
}

public SetView(id, iEnt) 
{ 
    if(is_user_alive(id))
    {
        new iCamera = g_iPlayerCamera[id] 
        if( iCamera && iEnt != iCamera ) 
        { 
            new szClassName[16] 
            pev(iEnt, pev_classname, szClassName, charsmax(szClassName)) 
            if(!equal(szClassName, "trigger_camera")) // should let real cams enabled 
            { 
                engfunc(EngFunc_SetView, id, iCamera) // shouldn't be always needed 
                return FMRES_SUPERCEDE 
            } 
        } 
    } 
    return FMRES_IGNORED 
}

get_cam_owner(iEnt) 
{ 
    new players[32], pnum;
    get_players(players, pnum, "ch");
    
    for(new id, i; i < pnum; i++)
    { 
        id = players[i];
        
        if(g_iPlayerCamera[id] == iEnt)
        {
            return id;
        }
    }
    
    return 0;
} 

public Camera_Think(iEnt)
{
    static id;
    if(!(id = get_cam_owner(iEnt))) return ;
    
    static Float:fVecPlayerOrigin[3], Float:fVecCameraOrigin[3], Float:fVecAngles[3], Float:fVec[3];
    
    pev(id, pev_origin, fVecPlayerOrigin) 
    pev(id, pev_view_ofs, fVecAngles) 
    fVecPlayerOrigin[2] += fVecAngles[2] 
    
    pev(id, pev_v_angle, fVecAngles) 
    
    angle_vector(fVecAngles, ANGLEVECTOR_FORWARD, fVec);
    static Float:units; units = g_camera_position[id];
    
    //Move back/forward to see ourself
    fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * units)
    fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * units) 
    fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * units) + 15.0
    
    static tr2; tr2 = create_tr2();
    engfunc(EngFunc_TraceLine, fVecPlayerOrigin, fVecCameraOrigin, IGNORE_MONSTERS, id, tr2)
    static Float:flFraction 
    get_tr2(tr2, TR_flFraction, flFraction)
    if( flFraction != 1.0 ) // adjust camera place if close to a wall 
    {
        flFraction *= units;
        fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * flFraction);
        fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * flFraction);
        fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * flFraction);
    }
    
    if(units > 0.0)
    {
        fVecAngles[0] *= fVecAngles[0] > 180.0 ? 1:-1
        fVecAngles[1] += fVecAngles[1] > 180.0 ? -180.0:180.0
    }
    
    set_pev(iEnt, pev_origin, fVecCameraOrigin); 
    set_pev(iEnt, pev_angles, fVecAngles);
    
    free_tr2(tr2);
}

public message_SayText()
{
    if(g_BoxStarted == 1 || g_GameMode == BoxDay)
    {
        if (get_msg_args() > 4)
            return PLUGIN_CONTINUE;
    
        static szBuffer[40];
        get_msg_arg_string(2, szBuffer, 39)
    
        if (!equali(szBuffer, "#Cstrike_TitlesTXT_Game_teammate_attack"))
            return PLUGIN_CONTINUE;
    
    }
    return PLUGIN_HANDLED;
}

public box_last()
{
    if(g_GameMode != Freeday || g_BoxStarted == 1)
        return PLUGIN_CONTINUE
    new playerCount, i
    new Players[32] 
    new tero_nr = 0
    new countY = 0
    new wanted_nr = 0
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++)
        if(cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]))
        {
            if(!get_bit(g_PlayerWanted, Players[i]))
                tero_nr++
            else if(get_bit(g_PlayerWanted, Players[i]))
                wanted_nr++
        }    
    if(wanted_nr == 0 && tero_nr == 2)
    {
        for (i=0; i<playerCount; i++)
        {
            if(cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && g_BoxLastY[Players[i]] == 0)
                box_last_menu(Players[i])
            if(g_BoxLastY[Players[i]] == 1)
                countY += 1
        }
        if(countY == 2 && g_BoxStarted == 0)
        {
            for(i = 1; i <= g_MaxClients; i++)
                if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
                    set_user_health(i, 100)
            set_cvar_num("mp_tkpunish", 0)
            set_cvar_num("mp_friendlyfire", 1)
            g_BoxStarted = 1
            player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_BOX_START")
            emit_sound(0, CHAN_AUTO, "jbextreme/rumble.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            ColorChat(0, RED, "^x01 Ultimii 2 prizonieri^x03 au fost de acord^x04 sa faca box^x01!")
            remove_task(TASK_ROUND)
        }
    }
    return PLUGIN_HANDLED
}

public box_last_menu(id)
{
    if(g_GameMode == Freeday && g_BoxStarted != 1)
    {
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_BOXLAST")
        menu = menu_create(menuname, "box_last_menu_choice")
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_BOXLAST_Y")
        menu_additem(menu, option, "1", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_BOXLAST_N")
        menu_additem(menu, option, "2", 0)
        menu_display(id, menu)    
    }
    return PLUGIN_HANDLED 
}

public box_last_menu_choice(id, menu, item)
{
    if(item == MENU_EXIT || g_GameMode != Freeday || g_BoxStarted == 1 || g_CantChoose == 1)
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
            g_BoxLastY[id] = 1
            box_last()
            ColorChat(0, RED, "^x01 Prizonierul^x03 %s^x01 este de acord sa faca^x04 box^x01!", dst)
        }
        case('2'): 
        {
            ColorChat(0, RED, "^x01 Prizonierul^x03 %s^x01 nu este de acord sa faca^x04 box^x01!", dst)
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_BOXLAST_N", dst)
            g_BoxLastY[id] = 2
        }
    }
    return PLUGIN_HANDLED
}

public cmd_reactionsmenu(id)
{
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY)) 
    {
        static menu, menuname[32], option[64]
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_REACTIONSMENU")
        menu = menu_create(menuname, "cmd_reactionsmenu_choice")
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_DUCK")
        menu_additem(menu, option, "1", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_JUMP")
        menu_additem(menu, option, "2", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_DUCKJUMP")
        menu_additem(menu, option, "3", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_DUCK_LAST")
        menu_additem(menu, option, "4", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_JUMP_LAST")
        menu_additem(menu, option, "5", 0)
        formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_REACTIONSMENU_DUCKJUMP_LAST")
        menu_additem(menu, option, "6", 0) 
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED  
}

public  cmd_reactionsmenu_choice(id, menu, item)
{
    if(item == MENU_EXIT || !(id == g_Simon ||(get_user_flags(id) & ADMIN_SLAY)) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    cmd_reactionsmenu(id)
    get_user_name(id, dst, charsmax(dst))
    new name[32]
    get_user_name(id, name, 31)
    ColorChat(0, BLUE, "^x03%s^x01 A DAT O^x04 REACTIE^x01!!!", name)
    switch(data[0])    
    {        
        case('1'): emit_sound(0, CHAN_AUTO, "jbextreme/duck_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        case('2'): emit_sound(0, CHAN_AUTO, "jbextreme/jump_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        case('3'): emit_sound(0, CHAN_AUTO, "jbextreme/duckjump_.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        case('4'): emit_sound(0, CHAN_AUTO, "jbextreme/duck_last.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        case('5'): emit_sound(0, CHAN_AUTO, "jbextreme/jump_last.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        case('6'): emit_sound(0, CHAN_AUTO, "jbextreme/duckjump_last.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    }    
    return PLUGIN_HANDLED
}
public load_songs()
{
    new file[250]
    new data[250], len, line = 0, i = 1
    get_configsdir(file, 249)
    format(file, 249, "%s/melodii.ini", file)
    if(file_exists(file))
    {
        while((line = read_file(file , line , data , 249 , len)) != 0)
        {
            if ((data[0] == ';') || equal(data, "")) continue;
            parse(data, Songs[i][_name], 99, Songs[i][_song], 99);
            i++;
            if(i==100)
            {
                log_amx("Nu se pot incarca mai mult de 100")
            }
        }
        log_amx("%d Vip cu melodie au fost incarcati", i)
        MaxVip = i;
    }
    else
        log_amx("fisierul %s nu exista", file)
}

public chat_flip(id)
{
    if(!is_user_alive(id))
    {
        ColorChat(id, RED, "Nu poti folosi aceasta comanda cand esti mort!")
        return PLUGIN_HANDLED
    }
    new flip, src[32]
    get_user_name(id, src, charsmax(src))
    flip = random_num(1,2)
    if (flip == 1)
    {
        ColorChat(0, TEAM_COLOR, "^x03%s^x01 a dat cu banul:^x04 CAP", src)
        client_print(0,print_console,"%s a dat cu banul: CAP",src)
    }
    else
    {    
        ColorChat(0, TEAM_COLOR, "^x03%s^x01 a dat cu banul:^x04 PAJURA", src)
        client_print(0,print_console,"%s a dat cu banul: PAJURA",src)
    }    
    return PLUGIN_CONTINUE
}

public chat_roll(id)
{
    if(!is_user_alive(id))
    {
        ColorChat(id, RED, "Nu poti folosi aceasta comanda cand esti mort!")
        return PLUGIN_HANDLED
    }
    new roll, src[32]
    get_user_name(id, src, charsmax(src))
    roll = random_num(0,100)
    ColorChat(0, TEAM_COLOR, "^x03%s^x01 a ales un numar la nimereala:^x04 %d", src, roll)
    client_print(0,print_console,"%s a ales un numar la nimereala: %d", src, roll)
    return PLUGIN_CONTINUE
}

public JoinTeam() {
    new loguser[80], name[32]
    read_logargv(0, loguser, 79)
    parse_loguser(loguser, name, 31)

    new id = get_user_index(name)

    if(is_user_bot(id))    
        return
        
    new temp[2]

    read_logargv(2, temp, 1)
    switch(temp[0])
    {
        case 'T' :
            ColorChat(0, RED, "^x03%s^x01 a intrat in echipa^x03 Prizonierilor^x01!", name)
        case 'C' :
            ColorChat(0, BLUE, "^x03%s^x01 a intrat in echipa^x03 Gardienilor^x01!", name)
    }
}

public Fwd_PlayerTouch( Touched, Toucher )
{
    if(g_GameMode == FreezeTagDay && is_user_alive(Toucher) && is_user_alive(Touched))
    {
        switch(cs_get_user_team(Toucher))
        {
            case CS_TEAM_CT:
            {
                static Flags
                Flags = entity_get_int( Touched, EV_INT_flags );
                if(cs_get_user_team(Touched) == CS_TEAM_T && !(Flags & FL_FROZEN))
                    set_pev(Touched, pev_flags, pev(Touched, pev_flags) | FL_FROZEN)  
                        
            }
            case CS_TEAM_T:
            {
            
            }
        }
    }
}
    
public Set_Hat(player, imodelnum) {
    new name[32]
    new tmpfile[101]
    format(tmpfile, 100, "models/hat/cowboy.mdl")
    get_user_name(player, name, 31)
    if (imodelnum == 0) {
        if(g_HatEnt[player] > 0) {
            fm_set_entity_visibility(g_HatEnt[player], 0)
        }
    } else if (file_exists(tmpfile)) {
        if(g_HatEnt[player] < 1) {
            g_HatEnt[player] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
            if(g_HatEnt[player] > 0) {
                set_pev(g_HatEnt[player], pev_movetype, MOVETYPE_FOLLOW)
                set_pev(g_HatEnt[player], pev_aiment, player)
                set_pev(g_HatEnt[player], pev_rendermode,     kRenderNormal)
                engfunc(EngFunc_SetModel, g_HatEnt[player], tmpfile)
            }
        } else {
            engfunc(EngFunc_SetModel, g_HatEnt[player], tmpfile)
        }
        glowhat(player)
    }
}

glowhat(id) {
    if (!pev_valid(g_HatEnt[id])) return
    set_pev(g_HatEnt[id], pev_renderfx,    kRenderFxNone)
    set_pev(g_HatEnt[id], pev_renderamt,    0.0)
    fm_set_entity_visibility(g_HatEnt[id], 1)
    return
}

public cmd_incercare(id)
{    
    if(get_user_flags(id) & ADMIN_LEVEL_E)
    {
        if(g_GameMode != NormalDay || g_GameMode != Freeday)
            server_cmd("jb_unblock_weapons")
        set_user_maxspeed(id, 350.0)
        entity_set_int(id, EV_INT_body, 8)
        disarm_player(id)
        fm_give_item(id, "weapon_shield")
        entity_set_string(id, EV_SZ_viewmodel, SPARTA_V)  
        entity_set_string(id, EV_SZ_weaponmodel, SPARTA_P)
        if(g_GameMode != NormalDay || g_GameMode != Freeday)
            server_cmd("jb_block_weapons")
    }
}

public boxWep()
{
    new playerCount, i
    new Players[32]
    get_players(Players, playerCount, "ac") 
    for (i=0; i<playerCount; i++)
        if(cs_get_user_team(Players[i]) == CS_TEAM_T)
            disarm_player(Players[i])
}

public fadeout(player, red, green, blue)
{
    if(!is_user_alive(player))
        return PLUGIN_CONTINUE
    message_begin( MSG_ONE, SVC_SCREENFADE, _, player )
    write_short( 10000 ) //duration
    write_short( 0 ) //hold
    write_short( SF_FADEOUT ) //flags
    write_byte( red ) //r
    write_byte( green ) //g
    write_byte( blue ) //b
    write_byte( 100 ) //a
    message_end( )
    return PLUGIN_CONTINUE
}

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
stock fm_give_item(index, const item[]) 
{
    if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
        return 0

    new ent = fm_create_entity(item)
    if (!pev_valid(ent))
        return 0

    new Float:origin[3]
    pev(index, pev_origin, origin)
    set_pev(ent, pev_origin, origin)
    set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
    dllfunc(DLLFunc_Spawn, ent)

    new save = pev(ent, pev_solid)
    dllfunc(DLLFunc_Touch, ent, index)
    if (pev(ent, pev_solid) != save)
        return ent

    engfunc(EngFunc_RemoveEntity, ent)

    return -1
}