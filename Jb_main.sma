#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define PLUGIN_NAME    "JailBreak Main"
#define PLUGIN_AUTHOR    "(|EcLiPsE|)"
#define PLUGIN_VERSION    "2"
#define PLUGIN_CVAR    "JailBreak Manager"

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
new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }

new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
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
    register_dictionary("ujbm.txt")
    
    g_MsgStatusText = get_user_msgid("StatusText")
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgMOTD = get_user_msgid("MOTD")
	
    register_message(g_MsgStatusText, "msg_statustext")
	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_vguimenu")
	register_message(g_MsgShowMenu, "msg_showmenu")
	register_message(g_MsgMOTD, "msg_motd")
        
	register_event("StatusValue", "player_status", "be", "1=2", "2!0")
	register_event("StatusValue", "player_status", "be", "1=1", "2=0")
    register_impulse(100, "impulse_100")
    
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	RegisterHam(Ham_TraceAttack, "player", "player_attack")
	RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	RegisterHam(Ham_Touch, "weapon_hegrenade", "player_touchweapon")
	RegisterHam(Ham_Touch, "weaponbox", "player_touchweapon")
	RegisterHam(Ham_Touch, "armoury_entity", "player_touchweapon")
    
	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")
	register_forward(FM_CmdStart, "player_cmdstart", 1)
    
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
    
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
	register_clcmd("say /lastrequest", "cmd_lastrequest")
	register_clcmd("say /duel", "cmd_lastrequest")
	register_clcmd("say /simon", "cmd_simon")
	register_clcmd("say /open", "cmd_open")
	register_clcmd("say /nomic", "cmd_nomic")
	register_clcmd("say /box", "cmd_box")
	register_clcmd("say /help", "cmd_help")
    
	gp_GlowModels = register_cvar("jbe_glowmodels", "0")
	gp_SimonSteps = register_cvar("jbe_simonsteps", "1")
	gp_CrowbarMul = register_cvar("jbe_crowbarmultiplier", "25.0")
	gp_CrowbarMax = register_cvar("jbe_maxcrowbar", "1")
	gp_TeamRatio = register_cvar("jbe_teamratio", "3")
	gp_TeamChange = register_cvar("jbe_teamchange", "0") // 0-disable team change for tt / 1-enable team change
	gp_CtMax = register_cvar("jbe_maxct", "6")
	gp_BoxMax = register_cvar("jbe_boxmax", "6")
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
    
	for(new i = 0; i < sizeof(g_HudSync); i++)
    g_HudSync[i][_hudsync] = CreateHudSyncObj()
    
	formatex(g_HelpText, charsmax(g_HelpText), "%L^n^n%L^n^n%L^n^n%L",
    LANG_SERVER, "JBE_HELP_TITLE",
    LANG_SERVER, "JBE_HELP_BINDS",
    LANG_SERVER, "JBE_HELP_GUARD_CMDS",
    LANG_SERVER, "JBE_HELP_PRISONER_CMDS")
    
	setup_buttons()
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
            if (player == g_Simon) return PLUGIN_HANDLED
            team = cs_get_user_team(player)
            if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
                return PLUGIN_HANDLED
            
            health = get_user_health(player)
            get_user_name(player, name, charsmax(name))
            if(team == CS_TEAM_T)
            {
                if(get_bit(g_PlayerFreeday,player))
                    player_hudmessage(id, 6, 2.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_STATUS_FD", name, health)
                else
                    player_hudmessage(id, 6, 2.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_STATUS", name, health)
            }
            else
                player_hudmessage(id, 6, 2.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_STATUS", name, health)
        }
    }
    return PLUGIN_HANDLED
}