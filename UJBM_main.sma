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

#define PLUGIN_NAME    "[UJBM] Main"
#define PLUGIN_AUTHOR    "Mister X"
#define PLUGIN_VERSION    "1.5"
#define PLUGIN_CVAR    "Ultimate JailBreak Manager"
#define SERVER_IP "93.119.25.96"

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


#define get_bit(%1,%2)         ( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)         %1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)    %1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)            floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)        ( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)        ( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

#define JBMODELLOCATION "models/player/jbbossi_temp/jbbossi_temp.mdl"
#define JBMODELSHORT "jbbossi_temp"

// Offsets
#define m_iPrimaryWeapon    116
#define m_iVGUI            510
#define m_fGameHUDInitialized    349
#define m_fNextHudTextArgsGameTime    198

#define FLASHCOST    3500
#define HECOST    4000
#define SMOKECOST    3000
#define SHIELDCOST    16000
#define FDCOST    16000
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
//new g_CountKilled[33]

enum _:days{
    AlienDayT =-2,
    ZombieDayT,       //-1
    Freeday,          //0
    NormalDay,        //1
    ZombieDay,        //2
    HnsDay,           //3
    AlienDay,         //13
    AlienHiddenDay,   //4
    GunDay,           //5
    ColaDay,          //6
    GravityDay,       //7
    FireDay,          //8
    BugsDay,          //9
    NightDay,         //10
    SpartaDay,        //11
    FunDay,           //12
    //AscunseleaDay,  //14
    //PrinseleaDay,   //15
    OneBullet         //16
}

// Precache
new const _RpgModels[][] = { "models/p_rpg.mdl", "models/v_rpg.mdl" , "models/w_rpg.mdl", "models/rpgrocket.mdl" }
new const _RpgSounds[][] = { "weapons/rocketfire1.wav", "weapons/explode3.wav", "weapons/rocket1.wav" }

new SpriteExplosion

new const _RemoveEntities[][] = {
    "func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
    "hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new const _WeaponsFree[][] = { "weapon_m4a1", "weapon_deagle", "weapon_g3sg1", "weapon_scout", "weapon_ak47", "weapon_mp5navy", "weapon_m3" }
new const _WeaponsFreeCSW[] = { CSW_M4A1, CSW_DEAGLE, CSW_G3SG1, CSW_SCOUT, CSW_AK47, CSW_MP5NAVY, CSW_M3 }
new const _WeaponsFreeAmmo[] = { 999, 999, 999, 999, 999, 999, 999, 999 }


new const _Duel[][_duel] =
{
    { "Deagle",        CSW_DEAGLE,     "weapon_deagle",     "UJBM_MENU_LASTREQ_OPT4",     "UJBM_MENU_LASTREQ_SEL4"  },
    //{ "Grenades",     CSW_FLASHBANG,     "weapon_flashbang", "UJBM_MENU_LASTREQ_OPT5",     "UJBM_MENU_LASTREQ_SEL5"  }, //rpg!!!
    ///rpg
    { "Grenades",     CSW_HEGRENADE,     "weapon_hegrenade", "UJBM_MENU_LASTREQ_OPT6",    "UJBM_MENU_LASTREQ_SEL6"  },
    { "m249",        CSW_M249,         "weapon_m249",         "UJBM_MENU_LASTREQ_OPT8",     "UJBM_MENU_LASTREQ_SEL8"  },
    { "Awp",         CSW_AWP,         "weapon_awp",         "UJBM_MENU_LASTREQ_OPT7",     "UJBM_MENU_LASTREQ_SEL7"  },
    { "Scout",         CSW_SCOUT,         "weapon_scout",     "UJBM_MENU_LASTREQ_OPT9",     "UJBM_MENU_LASTREQ_SEL9"  },
    { "Rulette",     33,             "weapon_deagle",     "UJBM_MENU_LASTREQ_OPT10",     "UJBM_MENU_LASTREQ_SEL10" }
//    { "Trivia",        34,                "weapon_knife",        "UJBM_MENU_LASTREQ_OPT11",     "UJBM_MENU_LASTREQ_SEL11" }
    
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
    "UJBM_PRISONER_REASON_10"
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help / 8=timer
new const g_HudSync[][_hud] =
{
    {0,  0.81,  0.08,  1.0},
    {0, -1.0,  0.7,  5.0},
    {0,  0.05,  0.08,  1.0},
    {0,  0.05,  0.3,  1.0},
    {0, -1.0,  0.9,  1.0},
    {0,  0.6,  0.1,  1.0},
    {0, -1.0,  0.6,  1.0},
    {0,  0.8,  0.3, 20.0},
    {0, -1.0,  0.4,  1.0},
    {0,  0.05,  0.5,  1.0},
    {0, -1.0,  0.45, 1.0}
}
// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {0, 0, 255}, {255, 0, 0} }
//new CsTeams:g_PlayerTeam[33]
new Trie:g_CellManagers
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerSpect[33]
new g_PlayerSimon[33]
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

new g_NoShowShop = 0
new g_BoxStarted
new g_Simon
new g_SimonAllowed
new g_SimonTalking
new g_SimonVoice
new g_RoundStarted
new g_RoundEnd
new m_iTrail
new g_Duel
new g_DuelA
new g_DuelB
new g_Buttons[10]
new g_GameMode = NormalDay
new g_GamePrepare = 0
new g_nogamerounds
new gmsgSetFOV
new gp_Bind
new g_BackToCT = 0
new g_Fonarik = 0
new CTallowed[31]
new Tallowed[31]
new bindstr[33]

new gmsgBombDrop
new ding_on = 1
new killed = 0
new killedonlr = 0
new Simons[33]
new BoxPartener[33]
new fun_light[2] = "i",fun_gravity=800,fun_god=0,fun_clip=0;
new bool:g_GamesAp[days]
//new bool:Matadinnou
//new Mata
new g_DoNotAttack //0 attack  1 not 2 t 3 t
new g_FriendlyFire
new g_GameWeapon[2]

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

//last guns    Pcvars        maxplayers
new G_Last[33][4],P_Cvars[34]

//Page and rebuy cost
new G_Info[2][33]

//price and names,other info etc
new Weapons_Price[33]
new Weapons_Info[3][33][22]

new g_Map[40]
new BuyTimes[33]
new g_IsFG

new g_ResultVote[33]
new g_DayTimer = 0

public plugin_init()
{
    new ip[36];
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    get_user_ip(0,ip,35,0);
    if(equal(ip,SERVER_IP))
    {
        return PLUGIN_CONTINUE;
    }
    Load();
    unregister_forward(FM_Spawn, gp_PrecacheSpawn)
    unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)
    //register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
    register_dictionary("ujbm.txt")
    g_MsgStatusText = get_user_msgid("StatusText")
    g_MsgStatusIcon = get_user_msgid("StatusIcon")
    g_MsgMOTD = get_user_msgid("MOTD")
    gmsgBombDrop   = get_user_msgid("BombDrop")

    register_message(g_MsgStatusText, "msg_statustext")
    register_message(g_MsgStatusIcon, "msg_statusicon")
    register_message(g_MsgMOTD, "msg_motd")

    //register_event("CurWeapon", "current_weapon_fl", "be", "1=1", "2=25")
    register_event("StatusValue", "player_status", "be", "1=2", "2!0")
    register_impulse(100, "impulse_100")
    
    //RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "rpg_pre")
    //RegisterHam(Ham_Weapon_Reload, "weapon_flashbang", "rpg_reload")
    //register_touch("rpg_missile", "worldspawn",    "rocket_touch")
    //register_touch("rpg_missile", "player",        "rocket_touch")
    
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
    RegisterHam(Ham_TakeDamage, "player", "player_damage")
    RegisterHam(Ham_TraceAttack, "player", "player_attack")
    RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
    RegisterHam(Ham_Killed, "player", "player_killed")
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
    register_clcmd("say /choosesimon","cmd_adminchoosesimon")
    register_clcmd("say_team /gunshop","gunsmenu")
    //register_clcmd("say /motiv","cmd_motiv")
    register_clcmd("say /listfd","cmd_listfd")
    
    gp_GlowModels = register_cvar("jb_glowmodels", "0")
    gp_SimonSteps = register_cvar("jb_simonsteps", "1")
    gp_BoxMax = register_cvar("jb_boxmax", "4")
    gp_RetryTime = register_cvar("jb_retrytime", "120.0")
    gp_AutoLastresquest = register_cvar("jb_autolastrequest", "1")
    gp_LastRequest = register_cvar("jb_lastrequest", "1")
    gp_Motd = register_cvar("jb_motd", "1")
    gp_TalkMode = register_cvar("jb_talkmode", "2")    // 0-alltak / 1-tt talk / 2-tt no talk
    gp_VoiceBlock = register_cvar("jb_blockvoice", "0")    // 0-dont block / 1-block voicerecord / 2-block voicerecord except simon
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
    setup_buttons()
    g_PlayerLastVoiceSetting = 0
    return PLUGIN_CONTINUE
}
public plugin_precache()
{
    precache_model(JBMODELLOCATION)
    static i
    BeaconSprite = precache_model("sprites/shockwave.spr")    
    for(i = 0; i < sizeof(_RpgModels); i++)
            precache_model(_RpgModels[i])
    for(i = 0; i < sizeof(_RpgSounds); i++)
            precache_sound(_RpgSounds[i])
    SpriteExplosion = precache_model("sprites/fexplo1.spr")     
    m_iTrail = precache_model("sprites/smoke.spr")
    precache_sound("alien_alarm.wav")
    precache_sound("jbextreme/nm_goodbadugly.wav")
    precache_sound("jbextreme/rumble.wav")
    precache_sound("jbextreme/brass_bell_C.wav")
    precache_sound("jbextreme/money.wav")
    precache_sound("ambience/the_horror2.wav")
    precache_sound("debris/metal2.wav")
    precache_sound("items/gunpickup2.wav")
    precache_sound("jbextreme/simondead2.wav")
    precache_sound("jbextreme/opendoor3.wav")

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
    g_PlayerSimon[id] = 0
    Simons[id]=0
    BoxPartener[id]=0
    BuyTimes[id]=0
    first_join(id)
    //g_CountKilled[id] = 0
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
    /*if(Mata == id)
        cmd_moaremata();*/
    task_last()
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
        write_coord(origin[2])    //Z Coordinate
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
            if (player == g_Simon) return PLUGIN_HANDLED
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
        case  AlienDay:
        {
            if (g_Simon == id) set_user_maxspeed(id ,450.0)
        }
        case  AlienHiddenDay: 
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
    if (!get_bit(g_NoShowShop,id)) cmd_shop(id)
    
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
            //g_PlayerReason[id] = random_num(1, 10)
            //player_hudmessage(id, 8, 60.0, {255, 0, 255}, "%L %L", LANG_SERVER, "UJBM_PRISONER_REASON",LANG_SERVER, g_Reasons[g_PlayerReason[id]])
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
            G_Info[0][id]=0
            g_PlayerSimon[id]++
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

public player_damage(victim, ent, attacker, Float:damage, bits)
{
    if (!is_user_connected(victim) || !is_user_connected(attacker))
        return HAM_IGNORED;
    if(g_GameMode == FunDay && fun_god == 1)
        return HAM_SUPERCEDE
    if (g_GameMode  ==  AlienHiddenDay && g_Simon  ==  attacker || g_GameMode == AlienDayT && cs_get_user_team(attacker)==CS_TEAM_T)
    {
        set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0 )
        remove_task(TASK_INVISIBLE+attacker)
        set_task(3.1, "task_inviz",TASK_INVISIBLE + attacker, _, _, "b");
    }
    if(cs_get_user_team(attacker) == CS_TEAM_SPECTATOR || cs_get_user_team(victim) == CS_TEAM_SPECTATOR)
        return HAM_SUPERCEDE
    if((cs_get_user_team(victim)==cs_get_user_team(attacker) || victim==attacker) && (bits & (1<<24))) 
        return HAM_SUPERCEDE
    switch(g_Duel)
    {
        case(0):
        {
            return HAM_IGNORED
        }
        case(2):
        {
            if(attacker != g_PlayerLast || (bits & (1<<24)))
                return HAM_SUPERCEDE
        }
        default:
        {
            if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
                if(g_Duel> 3 && get_user_weapon(attacker) ==  _Duel[g_Duel - 4][_csw] || g_Duel == 3 && get_user_weapon(attacker)==CSW_KNIFE)
                    return HAM_IGNORED
            return HAM_SUPERCEDE
        }
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
    if(g_RoundEnd || g_GamePrepare == 1 || (g_GameMode == NormalDay && g_JailDay%7 == 6) || cs_get_user_team(attacker) == CS_TEAM_SPECTATOR || cs_get_user_team(victim) == CS_TEAM_SPECTATOR)
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
                    if(!g_PlayerRevolt)
                    revolt_start()
                    set_bit(g_PlayerRevolt, attacker)
                    clear_bit(g_PlayerFreeday, attacker)
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
            case(2):
            {
                if(attacker != g_PlayerLast)
                    return HAM_SUPERCEDE
            }
            case(10, 11):
            {
                return HAM_SUPERCEDE
            }
            default:
            {
                if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA)){
                    if(g_Duel==3)
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
            g_PlayerLastVoiceSetting = get_bit(g_PlayerVoice, g_PlayerLast)
            set_bit(g_PlayerVoice, g_PlayerLast)
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
    new nameCT[32],nameT[32],message[200]
    if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
        kteam = CS_TEAM_UNASSIGNED
    else
        kteam = cs_get_user_team(attacker)
    vteam = cs_get_user_team(victim)
    
    if(cs_get_user_team(victim) == CS_TEAM_T && !(get_user_flags(victim) & VOICE_ADMIN_FLAG))
    {
        cmd_voiceoff(victim)
    }
    
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
                BoxPartener[attacker] = 0
                BoxPartener[victim] = 0
                cs_set_user_money(attacker, cs_get_user_money(attacker) + 2800)
                set_user_health(attacker, 100)    
            }
            if(g_Simon == victim)
            {
                g_Simon = 0
                resetsimon()
                emit_sound(0, CHAN_AUTO, "jbextreme/simondead2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
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
                                
                                format(message, 200,"^x04[JB]^x01Prizonierul ^x03%s^x01 a devenit rebel",nameCT)
                                message_begin(MSG_BROADCAST, g_iMsgSayText, {0,0,0});
                                write_string(message);
                                message_end();
                            }
                        }
                        case(CS_TEAM_T):
                        { 
                            if(kteam == CS_TEAM_CT)
                            {
                                /*g_CountKilled[attacker]++
                                    if(g_CountKilled[attacker] == 5)
                                    {
                                    user_kill(attacker);
                                    format(message, 200, "[Anti-Fk] %s a fost pedepsit",nameCT);
                                    message_begin(MSG_BROADCAST, g_iMsgSayText, {0,0,0});
                                    write_string(message);
                                    message_end();
                                }*/
                                if(get_bit(g_PlayerWanted,victim))
                                {
                                    format(message, 200,"^x04[JB]^x01Gardianul ^x03%s^x01 a omorat rebelul ^x03%s",nameCT,nameT)
                                }
                                else if(get_bit(g_PlayerFreeday,victim))
                                {
                                    format(message, 200,"^x04[JB]^x01Gardianul ^x03%s^x01 a omorat prizonierul cu freeday ^x03%s",nameCT,nameT)
                                }
                                message_begin(MSG_BROADCAST, g_iMsgSayText, {0,0,0});
                                write_string(message);
                                message_end();
                            }
                            clear_bit(g_PlayerRevolt, victim)
                            clear_bit(g_PlayerWanted, victim)
                        }
                    }
                }
                default:
                {
                    if(g_Duel != 2)
                    {
                        if(victim == g_DuelA || victim == g_DuelB){
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
                            g_Duel = 0
                            g_DuelA = 0
                            g_DuelB = 0
                            server_cmd("jb_unblock_weapons")
                        }
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
    if (g_Duel > 3 && _Duel[g_Duel - 4][_csw] == 33 && ( g_DuelA==id || g_DuelB==id)){
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
        
    if(g_Duel > 3)
    {
        if(g_DuelA != id && g_DuelB != id)
            return FMRES_IGNORED
        if (_Duel[g_Duel - 4][_csw] != CSW_M249 && _Duel[g_Duel - 4][_csw]!=33)     cs_set_user_bpammo(id, _Duel[g_Duel - 4][_csw], 1)
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
    for(new i = 1; i <= g_MaxClients; i++)
    {
        g_PlayerSimon[i] = 0
        
    }
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
    g_PlayerRevolt = 0
    if(g_JailDay%7 > 0 && g_JailDay%7 < 6 && is_not_game()){
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
    g_Fonarik = 0
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
    
    if(g_GameMode == GravityDay || g_GameMode == FunDay )//|| g_GameMode == 15)
        set_cvar_num("sv_gravity",800)
    new Players[32]     
    new playerCount, i 
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
    g_GamePrepare = 0
    g_GameMode = NormalDay
}

public SimonAllowed()
{
    g_SimonAllowed = 1
}
public round_start()
{
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
        case 3: Day = "Miercuri"
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
            set_task(360.0,"cmd_expire_time",TASK_ROUND)
        }
    }
    
    set_dhudmessage( random_num( 1, 255 ), random_num( 1, 255 ), random_num( 1, 255 ), -1.0, 0.71, 2, 6.0, 3.0, 0.1, 1.5 );
    show_dhudmessage( 0, "[ Ziua %d, %s ]^n[ %s ]", g_JailDay, Day, g_Time, g_Map);
    
    if(g_RoundEnd)
        return
    new bool:ok=false
    for(new i = ZombieDay; i<days;i++)
        ok = ok | g_GamesAp[i]
    if(ok == false)
        for(new i = ZombieDay; i<days;i++)
            g_GamesAp[i]=false
    set_task(HUD_DELAY, "hud_status", TASK_STATUS, _, _, "b")
    set_task(random_float(2.0,5.0), "SimonAllowed")
    set_task(5.0, "task_last", TASK_LAST)
    server_cmd("bh_enabled 1")    
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
        Simons[id]=1;
        g_Simon = id
        get_user_name(id, name, charsmax(name))
        entity_set_int(id, EV_INT_body, 1)
        g_PlayerSimon[id]--
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
    if(id == g_Simon || (get_user_flags(id) & ADMIN_SLAY)|| !is_not_game()){
        jail_open()
        new name[32]
        get_user_name(id, name, 31)
        client_print(0, print_chat, "%s a deschis usa",name)
        emit_sound(0, CHAN_AUTO, "jbextreme/opendoor3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
    return PLUGIN_HANDLED
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
                set_cvar_num("mp_tkpunish", 0)
                set_cvar_num("mp_friendlyfire", 1)
                g_BoxStarted = 1
                player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_BOX_START")
                emit_sound(0, CHAN_AUTO, "jbextreme/rumble.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            }
            else{
                new dst[50]
                get_user_name(id, dst, 49)
                set_cvar_num("mp_tkpunish", 0)
                set_cvar_num("mp_friendlyfire", 0)
                g_BoxStarted = 0
                client_print(0, print_console, "%s A DEZACTIVAT BOX", dst)
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
    if(!is_user_alive(id) || g_Duel >=2 || !is_not_game() || g_JailDay%7 == 6 || cs_get_user_team(id) == CS_TEAM_CT)
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}
public cmd_adminchoosesimon(id)
{
    if (g_SimonAllowed == 1 && is_not_game() && (get_user_flags(id) & ADMIN_SLAY) && g_Simon==0)
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
    
    client_print(0, print_console, "%s a ales simon pe %s", dst,simonname)
    log_amx("%s a ales simon pe %s", dst,simonname)
    
    cmd_simon(player)
    
    return PLUGIN_HANDLED
}
public cmd_freeday(id)
{
    if (g_GameMode == NormalDay)
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
            if((id == g_Simon) || (get_user_flags(id) & ADMIN_SLAY))
            {
                g_Simon = 0
                get_user_name(id, dst, charsmax(dst))
                client_print(0, print_console, "%s gives freeday for everyone", dst)
                server_print("JBE Client %i gives freeday for everyone", id)
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
    static i, num[5], menu, menuname[32], option[64]
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
    
    for(i = 0; i < sizeof(_Duel); i++)
    {
        num_to_str(i + 4, num, charsmax(num))
        formatex(option, charsmax(option), "%L", LANG_SERVER, _Duel[i][_opt])
        menu_additem(menu, option, num, 0)
    }
    menu_display(id, menu)
    return PLUGIN_CONTINUE
}
public lastrequest_select(id, menu, item)
{
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel != 0 || g_PlayerLast !=id || !is_user_alive(id) || !is_not_game() || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static i, dst[32], data[5], access, callback, option[64],nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    get_user_name(id, dst, charsmax(dst))
    nr = str_to_num(data)
    switch(nr)
    {
        case(1):
        {
            emit_sound(0, CHAN_AUTO, "jbextreme/money.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            user_silentkill(id)
            cs_set_user_money(id,cs_get_user_money(id)+16000,1)
        }
        case(2):
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL2", dst)
            player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
            player_strip_weapons_all()
            i = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(id, _WeaponsFree[i])
            server_cmd("jb_block_weapons")
            cs_set_user_bpammo(id, _WeaponsFreeCSW[i], _WeaponsFreeAmmo[i])
            set_task(120.0,"cmd_expire_time",TASK_ROUND)
            g_Countdown=120
            cmd_saytime()
            g_Duel = nr
            
        }
        case(3):
        {
            menu_players(id, CS_TEAM_CT, 0, 1, "duel_knives", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
            g_Duel = nr
        }
        case(0):
        {
            cmd_lrgame(id)
        }
        default:
        {
            //server_cmd("bh_noslowdown 0")
            menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
            g_Duel = nr
        }
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
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
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac", "CT")        
    if(playerCount>=2 && (cs_get_user_money(id)>=16000 ||get_vip_type(id)> 0)){
        server_cmd("bh_enabled 1")
        if(get_vip_type(id) == 0)
            cs_set_user_money(id,cs_get_user_money(id)-16000);
        switch(data[0])
        {
            case('1'):
            {
                g_GameMode = ZombieDayT
                g_BoxStarted = 0
                server_cmd("jb_block_weapons")
                g_Simon = 0
                g_SimonAllowed = 0
                g_DoNotAttack = 1;
                g_GameWeapon[1] = CSW_KNIFE
                g_GameWeapon[0] = CSW_M3
                for (i=0; i<playerCount; i++) 
                {
                    strip_user_weapons(Players[i])
                    give_item(Players[i], "weapon_knife")
                    set_user_maxspeed(Players[i], 200.0)
                    set_user_health(Players[i], 300)
                    give_item(Players[i], "item_assaultsuit")
                    cs_set_user_nvg (Players[i],true);
                    entity_set_int(Players[i], EV_INT_body, 6)
                    message_begin( MSG_ONE, gmsgSetFOV, _, Players[i] )
                    write_byte(170)
                    message_end()
                }
                strip_user_weapons(id)
                give_item(id, "weapon_knife")
                give_item(id, "weapon_m3")
                give_item(id, "weapon_hegrenade")
                give_item(id, "weapon_flashbang")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                give_item(id, "ammo_buckshot")
                if(playerCount>3)
                    set_user_health(id, 100+50*(playerCount-3))
                else
                    set_user_health(id, 100)
                set_user_maxspeed(id, 250.0)
                set_bit(g_Fonarik, id)
                client_cmd(id, "impulse 100")
                player_glow(id, g_Colors[2])
                
                emit_sound(0, CHAN_AUTO, "ambience/the_horror2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                new effect = get_pcvar_num (gp_Effects)
                if (effect > 0)
                {
                    set_lights("b")
                    if (effect > 1) fog(true)
                }    
                player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM")
                set_task(300.0,"cmd_expire_time",TASK_ROUND)
                
            }
            case('2'):
            {
                g_GameMode = AlienDayT
                g_DoNotAttack = 2;
                g_GameWeapon[0] = CSW_KNIFE
                server_cmd("jb_block_weapons")
                server_cmd("jb_block_teams")
                hud_status(0)
                for (i=0; i<playerCount; i++) 
                {
                    strip_user_weapons(Players[i])
                    
                    give_item(Players[i], "weapon_knife")
                    new j = random_num(0, sizeof(_WeaponsFree) - 1)
                    give_item(Players[i], _WeaponsFree[j])
                    cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
                    new n = random_num(0, sizeof(_WeaponsFree) - 1)
                    while (n == j) { 
                        n = random_num(0, sizeof(_WeaponsFree) - 1) 
                    }
                    give_item(Players[i], _WeaponsFree[n])
                    cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
                }
                strip_user_weapons(id)
                set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 )
                message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
                write_short(~0)
                write_short(~0)
                write_short(0x0004) // stay faded
                write_byte(ALIEN_RED)
                write_byte(ALIEN_GREEN)
                write_byte(ALIEN_BLUE)
                write_byte(100)
                message_end()
                set_user_maxspeed(id, 320.0)
                entity_set_int(id, EV_INT_body, 7)
                new hp = get_pcvar_num(gp_GameHP)
                if (hp < 20) hp = 200
                set_user_health(id, hp*playerCount)
                set_task(20.0, "give_items_alien_t", TASK_GIVEITEMS+id)
                set_task(2.5, "radar_alien_t", TASK_RADAR+id, _, _, "b")
                set_task(3.1, "task_inviz",TASK_INVISIBLE + id, _, _, "b");
                
                set_lights("z")
                emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
                set_task(5.0, "stop_sound")
                set_task(300.0,"cmd_expire_time",TASK_ROUND)
                return PLUGIN_HANDLED
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
    new playerCount, i,TAlive,TAll
    new szStatus[64]
    get_players(Players, playerCount, "c") 
    for (i=0; i<playerCount; i++) 
    {
        if (is_user_connected(Players[i])) 
            if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
            {
                TAll++;
                if (is_user_alive(Players[i])) TAlive++;
            }
    }
    formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS", TAlive,TAll)
    message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
    write_byte(0)
    write_string(szStatus)
    message_end()
}

public hud_status(task)
{
    static i, n
    new name[32], szStatus[64], wanted[512], fdlist[512]    
    if(g_RoundStarted < gp_RetryTime)
        g_RoundStarted++
    show_count()
    switch (g_GameMode)        
    {
        case Freeday:
        {
            n = 0
            formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "UJBM_PRISONER_WANTED")
            n = strlen(wanted)
            for(i = 0; i < g_MaxClients; i++)
            {
                if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T && n < charsmax(wanted))
                {
                    get_user_name(i, name, charsmax(name))
                    n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
                    n += copy(wanted[n], charsmax(wanted) - n, name)
                    if(check_model(i)==false)
                        set_user_rendering(i, kRenderFxGlowShell, 700, 0, 0, kRenderNormal, 25)
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
                for(i = 0; i < g_MaxClients; i++)
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
                for(i = 0; i < g_MaxClients; i++)
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
            player_hudmessage(0, 0, HUD_DELAY, {0, 255, 0}, "[ Ziua %d, %s ]^nwww.evils.ro/jb^nGreNN. ne suge pl", g_JailDay, Day)
            if(g_Simon==0 && g_SimonAllowed==1 && g_GameMode!=Freeday && is_not_game() && !is_user_alive(g_PlayerLast))
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
        case FunDay:
        {
            get_user_name(g_Simon, name, charsmax(name))
            player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_FUNDAY",name)
        }
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
    client_print(0,print_console,"%s a setat lui %s paint",src,dst)
    
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
    
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel!=3 || !is_user_connected(player) || !is_user_alive(player) || get_bit(g_PlayerWanted, id))
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
    
    if(item == MENU_EXIT || !get_pcvar_num(gp_LastRequest) || g_Duel-4<0 || g_Duel-4>sizeof(_Duel)-1 || !is_user_alive(player) ||  !is_user_alive(id) || get_bit(g_PlayerWanted, id))
    {
        menu_destroy(menu)
        g_Duel = 0
        return PLUGIN_HANDLED
    }
    
    get_user_name(id, src, charsmax(src))
    formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, _Duel[g_Duel - 4][_sel], src, LANG_SERVER, "UJBM_MENU_DUEL_SEL", src, dst)
    if(g_Duel != 11)
        emit_sound(0, CHAN_AUTO, "jbextreme/nm_goodbadugly.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        
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
    
    switch (_Duel[g_Duel - 4][_csw])
    {
        case  CSW_M249:
        {
           
            gun = give_item(g_DuelA, _Duel[g_Duel - 4][_entname])
            cs_set_weapon_ammo(gun, 2000)
            cs_set_user_bpammo(g_DuelA,CSW_M249,0)
            set_user_health(g_DuelA, 2000)
            entity_set_int(g_DuelA, EV_INT_body, 6)
           
            gun = give_item(g_DuelB, _Duel[g_Duel - 4][_entname])
            cs_set_weapon_ammo(gun, 2000)
            set_user_health(g_DuelB, 2000)
            cs_set_user_bpammo(g_DuelB,CSW_M249,0)
            entity_set_int(g_DuelB, EV_INT_body, 6)
            server_cmd("jb_block_weapons")
        }
        case  CSW_FLASHBANG:
        {
            gun = give_item(g_DuelA, _Duel[g_Duel - 4][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelA, 2000)
            entity_set_int(g_DuelA, EV_INT_body, 6)
            current_weapon_fl(g_DuelA)
            
            gun = give_item(g_DuelB, _Duel[g_Duel - 4][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelB, 2000)
            entity_set_int(g_DuelB, EV_INT_body, 6)
            current_weapon_fl(g_DuelB)
            server_cmd("jb_block_weapons")
        }
        case 33:
        {
            if(random_num(1,2) == 1)
                gun = give_item(g_DuelA, _Duel[g_Duel - 4][_entname])
            else
                gun = give_item(g_DuelB, _Duel[g_Duel - 4][_entname])
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
            
            gun = give_item(g_DuelA, _Duel[g_Duel - 4][_entname])
            cs_set_weapon_ammo(gun, 1)
            set_user_health(g_DuelA, 100)
                        
            gun = give_item(g_DuelB, _Duel[g_Duel - 4][_entname])
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
            client_print(0,print_chat,"%s si-a cumparat FD",dst)
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
        if (get_vip_type(id) == 0 && g_GameMode != FunDay && id != g_Simon && !(get_user_flags(id) & ADMIN_SLAY) && cs_get_user_team(id) != CS_TEAM_SPECTATOR)
            set_user_info(id, "model", JBMODELSHORT)
    }     
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
    new word[10];
    num_to_word(g_Countdown, word, 9);
    remove_task(TASK_SAYTIME)
    if(g_Countdown > 60){
        num_to_word(g_Countdown/60,word, 9)
        client_cmd(0, "spk ^"vox/%s minutes remaining^"", word);
        g_Countdown -= 60;
        set_task(60.0,"cmd_saytime",TASK_SAYTIME)
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
    if (containi(allowed,"i") >= 0  && bool:g_GamesAp[FireDay]==false)
    {    
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_FIREDAY")
        menu_additem(menu, option, "8", 0)
    }
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
        bigger = random_num(ZombieDay,SpartaDay);
        
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
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE ALIEN DAY")
                log_amx("IN ACEASTA SAMBATA ESTE ALIEN DAY")
                cmd_game_alien2()
            }
            case(ZombieDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE ZOMBIE DAY")
                log_amx("IN ACEASTA SAMBATA ESTE ZOMBIE DAY")
                cmd_pregame("cmd_game_zombie",1, 0, 30.0)
            }
            case(HnsDay): 
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE HNS DAY")
                log_amx("IN ACEASTA SAMBATA ESTE HNS DAY")
                cmd_pregame("cmd_game_hns", 2, 0, 60.0)
            }
            case(AlienDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE ALIEN DAY")
                log_amx("IN ACEASTA SAMBATA ESTE ALIEN DAY")
                cmd_game_alien2() //de scos
            }
            case(GunDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE GUN DAY")
                log_amx("IN ACEASTA SAMBATA ESTE GUNDAY")
                cmd_pregame("cmd_game_gunday", 1, 0, 30.0)
            }
            case(SpartaDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE SPARTA DAY")
                log_amx("IN ACEASTA SAMBATA ESTE SPARTA DAY")
                cmd_game_sparta()
            }
            case(GravityDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE GRAVITY DAY")
                log_amx("IN ACEASTA SAMBATA ESTE GRAVITY DAY")
                set_cvar_num("sv_gravity",250)
                cmd_pregame("cmd_game_gravity", 2, 0, 30.0)
            }
            case(FireDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE FIRE DAY")
                log_amx("IN ACEASTA SAMBATA ESTE FIRE DAY")
                cmd_pregame("cmd_game_fire", 2, 1, 30.0)
            }
            case(BugsDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE BUGs DAY")
                log_amx("IN ACEASTA SAMBATA ESTE BUGs DAY")
                cmd_game_bugs()
            }
            case(NightDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE NIGHTCRAWLER")
                log_amx("IN ACEASTA SAMBATA ESTE NIGHTCRAWLER")
                cmd_game_nightcrawler()
            }
            case(ColaDay):
            {
                client_print(0, print_console, "IN ACEASTA SAMBATA ESTE COLADAY")
                log_amx("IN ACEASTA SAMBATA ESTE COLADAY")
                cmd_pregame("cmd_game_coladay", 1, 0, 30.0)
            }
            case(OneBullet):
            {
                client_print(0, print_console, "server gives onebullet")
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
public cmd_done_game_prepare ()
{
    g_GamePrepare = 0;
}

public cmd_expire_time()
{
    new Players[32] 
    new playerCount, i 
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
        case AlienDayT,GunDay:
            for (i=0; i<playerCount && g_RoundEnd==0; i++) 
                if (cs_get_user_team(Players[i]) == CS_TEAM_T)
                    user_kill(Players[i],1)
        case HnsDay,AlienDay,AlienHiddenDay,GravityDay,BugsDay,NightDay: //,PrinseleaDay
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
    if(g_GameMode==ZombieDay || g_GameMode == ZombieDayT)
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
    for (player=1; player<g_MaxClients; player++) 
    {

        if(!is_user_alive(player))
            continue;
        
        strip_user_weapons(player)
        set_user_gravity(player, 1.0)
        set_user_maxspeed(player, 250.0)
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
    set_task(countdown,gameName,TASK_GIVEITEMS)
    g_Countdown=floatround(countdown)
    cmd_saytime()
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
    player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM")
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
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
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_HNS")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
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
    g_GameWeapon[1] = CSW_KNIFE
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
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
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
    cmd_saytime()
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
    new Players[32] 
    new playerCount, i 
    get_players(Players, playerCount, "ac")
    for (i=0; i<playerCount; i++) 
    {
        strip_user_weapons(Players[i])
        set_user_gravity(Players[i], 1.0)
        set_user_maxspeed(Players[i], 250.0)
        if ( g_Simon != Players[i])
        {
            if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
            {
                set_bit(g_BackToCT, Players[i])
                cs_set_user_team2(Players[i], CS_TEAM_T)
            }
            give_item(Players[i], "weapon_knife")
            new j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(Players[i], _WeaponsFree[j])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
            new n = random_num(0, sizeof(_WeaponsFree) - 1)
            while (n == j) { 
                n = random_num(0, sizeof(_WeaponsFree) - 1) 
            }
            give_item(Players[i], _WeaponsFree[n])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
        }
    }
    set_user_rendering(g_Simon, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 )
    message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, g_Simon)
    write_short(~0)
    write_short(~0)
    write_short(0x0004) // stay faded
    write_byte(ALIEN_RED)
    write_byte(ALIEN_GREEN)
    write_byte(ALIEN_BLUE)
    write_byte(100)
    message_end()
    set_user_maxspeed(g_Simon, 500.0)
    entity_set_int(g_Simon, EV_INT_body, 7)
    new hp = get_pcvar_num(gp_GameHP)
    if (hp < 20) hp = 200
    set_user_health(g_Simon, hp*playerCount)
    set_task(20.0, "give_items_alien", TASK_GIVEITEMS)
    set_task(20.0, "cmd_done_game_prepare",TASK_SAFETIME)
    set_lights("z")
    emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
    set_task(2.5, "radar_alien", TASK_RADAR, _, _, "b")
    set_task(5.0, "stop_sound")
    set_task(3.1, "task_inviz",TASK_INVISIBLE + g_Simon, _, _, "b");
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
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
        cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
        new n = random_num(0, sizeof(_WeaponsFree) - 1)
        while (n == j) { 
            n = random_num(0, sizeof(_WeaponsFree) - 1) 
        }
        give_item(Players[i], _WeaponsFree[n])
        cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
        set_user_gravity(Players[i], 1.0)
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    jail_open()
    new sz_msg[256];
    formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_GUNDAY")
    client_print(0, print_center , sz_msg)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
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
    cmd_saytime()
    return PLUGIN_CONTINUE
}
public  cmd_game_fire()
{
    if (g_Simon == 0)
    {
        log_amx("no simon on fireday")
        return PLUGIN_HANDLED
    }
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
       
        fade_screen(Players[i],false)
        set_pev(Players[i], pev_flags, pev(Players[i], pev_flags) & ~FL_FROZEN) 

    }
    set_user_health(g_Simon,999999);
    static dst[32]
    get_user_name(g_Simon, dst, charsmax(dst))
    server_cmd("amx_fire %s",dst);
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
    return PLUGIN_HANDLED
}
public  cmd_game_bugs()
{
    g_SimonAllowed = 0
    g_Simon = 0
    g_nogamerounds = 0
    g_BoxStarted = 0
    jail_open()
    g_GameMode = BugsDay
    g_GamesAp[BugsDay]=true
    g_DoNotAttack = 3;
    g_GameWeapon[1] = CSW_KNIFE
    server_cmd("jb_block_weapons")
    server_cmd("jb_block_teams")
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
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
            new n = random_num(0, sizeof(_WeaponsFree) - 1)
            while (n == j) { 
                n = random_num(0, sizeof(_WeaponsFree) - 1) 
            }
            give_item(Players[i], _WeaponsFree[n])
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
    return PLUGIN_HANDLED
}
public  cmd_game_nightcrawler()
{
    g_SimonAllowed = 0
    g_Simon = 0
    g_BoxStarted = 0
    g_nogamerounds = 0
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
            cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
        }
        else
        { 
            set_user_maxspeed(Players[i], 400.0)            
            entity_set_int(Players[i], EV_INT_body, 7)
            set_user_health(Players[i], 20)
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
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
    return PLUGIN_HANDLED
}
public cmd_game_sparta()
{
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
            disarm_player(Players[i])
            give_item(Players[i], "weapon_shield")
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
    set_task(300.0,"cmd_expire_time",TASK_ROUND)
    g_Countdown=300
    cmd_saytime()
    return PLUGIN_HANDLED
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
    cmd_saytime()
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
    cmd_saytime()
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
    cmd_saytime()
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
    cmd_saytime()
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
        if (containi(Tallowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_SHIELD",SHIELDCOST)
            menu_additem(menu, option, "5", 0)
        }
        if (containi(Tallowed,"f") >= 0 && !get_bit(g_PlayerWanted, id))
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FD", FDCOST)
            menu_additem(menu, option, "6", 0)
        }
        /*if (containi(Tallowed,"g") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHLIGHT", FLASHLIGHTCOST)
            menu_additem(menu, option, "7", 0)
        }*/
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
        if (containi(CTallowed,"e") >= 0)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NVG",NVGCOST)
            menu_additem(menu, option, "5", 0)
        }
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
    if(item == MENU_EXIT || !is_user_alive(id) || BuyTimes[id] == 2)
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
            if (money >= SHIELDCOST) 
            {
                cs_set_user_money (id, money - SHIELDCOST, 0)
                Give_Item(id,0)
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
            if (money >= FDCOST && !get_bit(g_PlayerWanted, id)) 
            {
                cs_set_user_money (id, money - FDCOST, 0)
                freeday_set(0, id, false)
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
        
    }
    if (!get_bit(g_NoShowShop, id)) cmd_shop(id)
    return PLUGIN_HANDLED
}
public gunsmenu(id)
{
    if(G_Info[0][id] != 0 || g_RoundStarted >= gp_RetryTime || !is_user_alive(id) || is_user_bot(id) || is_user_hltv(id) ||    g_Duel!=0 || !is_not_game())return
    G_Info[0][id] = 1
    set_task(2.0,"Show_Menu",id)
}
public Show_Menu(id)
{
    if(cs_get_user_team(id) == CS_TEAM_CT)
    {
        new menu = menu_create("\rGun Menu", "Menu_Handler")
        
        new nr[4],Name[26],i,Cost
        for (new i2=G_Size[0][G_Info[0][id]-1]; i2<=G_Size[1][G_Info[0][id]-1]; i2++)
        {
            i = i2
            if(get_pcvar_num(P_Cvars[i]) == 1)
            {    
                Cost = Weapons_Price[i]
                format(nr,3,"%i",i)
                if(!i)Cost += G_Info[1][id]
                if(!Cost)format(Name,25,"%s",Weapons_Info[0][i])
                else format(Name,25,"%s %i$",Weapons_Info[0][i], Cost)
                
                menu_additem(menu ,Name, nr , 0)
            }
        }
        menu_setprop(menu , MPROP_EXIT , MEXIT_ALL);
        menu_display(id , menu , 0)
        G_Info[0][id] +=1
    }
}
public Menu_Handler(id, menu, item)
{
    if(!is_user_alive(id)){
        menu_destroy(menu)
        return
    }
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        
        new arg[2]
        read_argv(2,arg,1)
        if(arg[0] != 49)
        {
            G_Info[1][id] -= Weapons_Price[G_Last[id][G_Info[0][id]-2]]
            G_Last[id][G_Info[0][id]-2] = 0
            if(G_Info[0][id] < 4)Show_Menu(id)
        }
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
        
        G_Info[1][id] -= Weapons_Price[G_Last[id][G_Info[0][id]-2]]
        G_Info[1][id] += Weapons_Price[key]
        G_Last[id][G_Info[0][id]-2] = key
        Give_Item(id,key)
    }
    else
    {
        client_print(id,print_chat,"[Gun Menu]Not enough cash to buy %s",Weapons_Info[0][key])
        G_Info[0][id] -= 1
    }
    
    menu_destroy(menu)
    if(G_Info[0][id] < 5)Show_Menu(id)
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
    static src[32], dst[32], data[5], access, callback,i
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
                get_user_name(i, dst, charsmax(dst))
                player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEENABLED", src, dst)
            }
        }
        case('3'):
        {
            for(i = 1; i <= g_MaxClients; i++)
            {
                if(!is_user_connected(i) || !is_user_alive(i) || cs_get_user_team(i) == CS_TEAM_CT)
                    continue
                clear_bit(g_PlayerVoice, i)
                get_user_name(i, dst, charsmax(dst))
                player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEDISABLED", src, dst)
            }
        }
    }
    return PLUGIN_HANDLED
}

public  na2team(id) {
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
    {
        new s = get_pcvar_num (gp_ShowColor)
        new playerCount, i 
        new Players[32] 
        new bool:orange = true
        get_players(Players, playerCount, "ac") 
        for (i=0; i<playerCount; i++) 
        {
            if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && !get_bit(g_PlayerFreeday, Players[i]) && !get_bit(g_PlayerWanted, Players[i]))
            {
                if (orange)
                {        
                    entity_set_int(Players[i], EV_INT_skin, 1)
                    orange=false;
                    if (s == 1) show_color(Players[i])
                }
                else 
                {
                    entity_set_int(Players[i], EV_INT_skin, 2)
                    orange=true;
                    if (s == 1) show_color(Players[i])
                }
            }
        }
    }
    return PLUGIN_HANDLED
}
bool:GameAllowed()
{
    if (!is_not_game() || g_JailDay%7!=6 && g_JailDay>0 || killed == 1)
        return false    
    return true;
}
public  cmd_simonmenu(id)
{
    if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
    {
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
        }
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE")
        menu_additem(menu, option, "4", 0)
        formatex(option, charsmax(option), "\y%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_GONG")
        menu_additem(menu, option, "5", 0)
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_PUNISH")
        menu_additem(menu, option, "6", 0)
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_PAINT")
        menu_additem(menu, option, "a", 0)
        if(g_GameMode == NormalDay)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_SIMON_GAMES")
            menu_additem(menu, option, "7", 0)
        }
        else if(g_GameMode == FunDay)
        {
            formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_SIMON_FUNMENU")
            menu_additem(menu, option, "9", 0)
        }
        formatex(option, charsmax(option), "%L",LANG_SERVER, "UJBM_MENU_BIND",bindstr)
        menu_additem(menu, option, "8", 0)
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
            jail_open()
            new name[32]
            get_user_name(id, name, 31)
            client_print(0, print_chat, "%s a deschis usa",name)
            emit_sound(0, CHAN_AUTO, "jbextreme/opendoor3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            cmd_simonmenu(id)
        }
        case('2'): cmd_freeday(id)
        case('3'): na2team(id)
        case('4'): cmd_simon_micr(id)
        case('5'): 
        {
            if(ding_on == 1)
            {
                emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                new name[32]
                get_user_name(id, name, 31)
                client_print(0, print_chat, "%s a dat ding",name)
                ding_on = 0
                set_task(5.0,"power_ding",5146)
            }
            cmd_simonmenu(id)
        }        
        case('6'): cmd_punish(id)
        case('7'): cmd_simongamesmenu(id)
        case('8'): client_cmd(id,"bind ^"%s^" ^"say /menu^"", bindstr)
        case('9'): cmd_funmenu(id)
        case('a'): menu_players(id, CS_TEAM_T, id, 1, "paint_select", "%L", LANG_SERVER, "UJBM_MENU_PAINT")
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
            if (containi(allowed,"i") >= 0  && bool:g_GamesAp[FireDay]==false && is_user_alive(g_Simon))
            {    
                formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_FIREDAY")
                menu_additem(menu, option, "10", 0)
            }
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
        }
        case(4):
        {
            client_print(0, print_console, "%s A DAT ALIEN DAY", dst)
            log_amx("%s A DAT ALIEN DAY", dst)
            cmd_game_alien()
        }
        case(5):
        {
            client_print(0, print_console, "%s A DAT BOX", dst)
            log_amx("%s A DAT BOX", dst)
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
        }
        case(10):
        {
            client_print(0, print_console, "%s A DAT FIRE DAY", dst)
            log_amx("%s A DAT FIRE DAY", dst)
            cmd_pregame("cmd_game_fire", 2, 1, 30.0)
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
    if (g_Duel > 3 && _Duel[g_Duel - 4][_csw] == CSW_FLASHBANG)
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
    if (g_Duel > 3 && _Duel[g_Duel - 4][_csw] == CSW_FLASHBANG )
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
    new gun = give_item(id, _Duel[g_Duel - 4][_entname])
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