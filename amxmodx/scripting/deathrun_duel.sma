#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Deathrun Duel"
#define VERSION "4.0"
#define AUTHOR "[Vicious Vixen]"
#define PREFIX "[DeathRun]"

#define is_valid_player(%1) (1 <= %1 <= 32)

#define GODTID 100500
#define TIMERTID 100501
#define TIMER2TID 100502
#define INFORMERTID 100503
#define WAITTIMERTID 100504
#define MCOUNT 9
#define SCOUNT 20
#define DCOUNT 13
#define DAMMO 1
#define KWPN "world"
#define KHS 1
#define MENUBODY 1024
#define MAXORIGINS 2
#define MAXWORDS 100

#define MAX_BUTTONS 100
#define KeysButtonsMenu (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9) // Keys: 137890
#define KeysOptionsMenu (1<<0)|(1<<1)|(1<<8) //129
#define KeysDelayMenu (1<<0)|(1<<1)|(1<<2)|(1<<8) //1239

#define ANNOUNCE_TASK 10000

#define m_flWait 44

//Main

new gEnt[MAX_BUTTONS];
new gUsed[MAX_BUTTONS];
new giPointer=0;
new gOnStart[MAX_BUTTONS];
new Float:gDefaultDelay[MAX_BUTTONS];
new Float:gDelay[MAX_BUTTONS];

new gInMenu[33];

new gszFile[128];

new giSprite;

new gcvarDefault, gcvarTeam, gcvarFreeRun;
new gcvarLimit, gcvarLimitMode, gcvarPrivilege;
new gcvarMessage, gcvarRestore;

//VOTE

#define TASK_SHOWMENU 432
#define TASK_RES 123

#define MAX_ROUNDS 999

#define KeysFFVote (1<<0)|(1<<1) // Keys: 12

new gcvarFRVoteTime;

new giVoteStart, giVoteTime;

new bool:gbFreeRun=false;
new bool:gbVote=false;

#define VOTE_ON 0
#define VOTE_OFF 1

new giVotes[33][2];

new giRounds=MAX_ROUNDS, giTime=0;

new MaxPlayers
new ChoosedDuel
new DuelNum
new SayText
new BeaconSprite
new CounterID
new TerroristID
new MathAnswer
new RussianRouletteID
new RussianRouletteBullet
new Index
new Timer
new OriginsNum
new WordsNum

new g_MsgHud1
new g_MsgHud2
new g_MsgHud3

new PcvarDuels
new PcvarMusic
new PcvarTimer
new PcvarTimeLimit
new PcvarSpawnGod
new PcvarEffects
new PcvarInformer
new PcvarLastMenu
new PcvarWait
new PcvarMode
new PcvarTele

new MenuPosition[33]
new MenuTs[33]
new RussianRouletteName[64]
new MathTask[64]
new ConfigsDir[64]
new WordsFile[64]
new OriginsFile[128]
new WordAnswer[128]
new RRammo[33][10]

new MenuBody[MENUBODY + 1]

new bool:Last
new bool:Duel
new bool:FPage
new bool:TouchWeapons[33]
new bool:Once[33]
new bool:InDuel[33]
new bool:Knife[33]
new bool:Deagle[33]
new bool:M4a1[33]
new bool:Ak47[33]
new bool:Mp5navy[33]
new bool:Grenade[33]
new bool:Scout[33]
new bool:Drob[33]
new bool:Awp[33]
new bool:Math[33]
new bool:Word[33]
new bool:RussianRoulette[33]
new bool:Used[33]
new bool:Boom[33]
new bool:NotYou[33]
new bool:DoIt[33]
new bool:Start[33]
new bool:Famas[33]

new Origins[MAXORIGINS][128]
new Words[MAXWORDS][192]

new Music[MCOUNT][] = 
{
"media/Half-Life01.mp3",
"media/Half-Life02.mp3",
"media/Half-Life03.mp3",
"media/Half-Life08.mp3",
"media/Half-Life11.mp3",
"media/Half-Life12.mp3",
"media/Half-Life13.mp3",
"media/Half-Life16.mp3",
"media/Half-Life17.mp3"
}

new Sound[SCOUNT][] =
{
"fvox/one",
"fvox/two",
"fvox/three",
"fvox/four",
"fvox/five",
"fvox/six",
"fvox/seven",
"fvox/eight",
"fvox/nine",
"fvox/ten",
"fvox/eleven",
"fvox/twelve",
"fvox/thirteen",
"fvox/fourteen",
"fvox/fifteen",
"fvox/sixteen",
"fvox/seventeen",
"fvox/eighteen",
"fvox/nineteen",
"fvox/twenty"
}

new Duels[DCOUNT][] =
{
"DUEL_1",
"DUEL_2",
"DUEL_3",
"DUEL_4",
"DUEL_5",
"DUEL_6",
"DUEL_7",
"DUEL_8",
"DUEL_9",
"DUEL_10",
"DUEL_11",
"DUEL_12",
"DUEL_13"
}
public plugin_init()
{
register_plugin(PLUGIN, VERSION, AUTHOR)
register_event("HLTV", "RoundStart", "a", "1=0", "2=0")
register_logevent("RoundEnd", 2, "1=Round_End")
RegisterHam(Ham_Touch, "weaponbox", "TouchWeapon")
RegisterHam(Ham_Touch, "armoury_entity", "TouchWeapon")
RegisterHam(Ham_Touch, "weapon_shield", "TouchWeapon")
RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1)
RegisterHam(Ham_Killed, "player", "PlayerKilled")
register_forward(FM_CmdStart,"CmdStart",1)
register_forward(FM_UpdateClientData, "UpdateClientData", 1)
register_clcmd("say /duel", "CmdDuelsMenu")
register_clcmd("say /dd", "CmdDuelsMenu")
register_clcmd("say_team /duel", "CmdDuelsMenu")
register_clcmd("say_team /dd", "CmdDuelsMenu")
register_clcmd("deathrun_duels", "CmdDuelsMenu")
register_clcmd("say", "hooksay")
register_clcmd("say_team", "hooksay_team")
register_concmd("dd_origin_menu", "CmdOriginsMenu", ADMIN_RCON)
PcvarDuels = register_cvar("dd_duels", "abcdefghijklm")
PcvarMusic = register_cvar("dd_music", "0")
PcvarTimer = register_cvar("dd_timer", "0")
PcvarTimeLimit = register_cvar("dd_timelimit", "60")
PcvarSpawnGod = register_cvar("dd_spawngod", "1")
PcvarEffects = register_cvar("dd_effects", "3")
PcvarWait = register_cvar("dd_wait", "5")
PcvarInformer = register_cvar("dd_informer", "1")
PcvarLastMenu = register_cvar("dd_lastmenu", "1")
PcvarTele = register_cvar("dd_teleport", "1")
PcvarMode = register_cvar("deathrun_mode", "BUTTONS", FCVAR_SERVER)
register_cvar("Deathrun Duels", "v2.5 by [I.G.]", FCVAR_SERVER|FCVAR_SPONLY)
register_menucmd(register_menuid("Duels Menu"), MENUBODY - 1, "ActionDuelsMenu")
register_menucmd(register_menuid("Enemy Menu"), MENUBODY - 1, "ActionEnemyMenu")
register_menucmd(register_menuid("Roulette Menu"), MENUBODY - 1, "ActionRussianRouletteMenu")
register_menucmd(register_menuid("Last Menu"), MENUBODY - 1, "ActionLastMenu")
register_menucmd(register_menuid("Origins Menu"), MENUBODY - 1, "ActionOriginsMenu")
SayText = get_user_msgid("SayText")
MaxPlayers = get_maxplayers()
g_MsgHud1 = CreateHudSyncObj()
g_MsgHud2 = CreateHudSyncObj()
g_MsgHud3 = CreateHudSyncObj()
register_dictionary("deathrun_duel.txt")
set_task(1.0, "Informer", INFORMERTID, "", 0, "b")
register_dictionary("common.txt");
register_dictionary("adminvote.txt");

register_menucmd(register_menuid("FRVote"), KeysFFVote, "PressedFRVote");
register_menucmd(register_menuid("ButtonsMenu"), KeysButtonsMenu, "PressedButtonsMenu");
register_menucmd(register_menuid("OptionsMenu"), KeysOptionsMenu, "PressedOptionsMenu");
register_menucmd(register_menuid("DelayMenu"), KeysDelayMenu, "PressedDelayMenu");

register_clcmd("amx_buttons","cmd_amx_buttons",ADMIN_CFG,": Buttons Menu");

//Default count of uses
gcvarDefault=register_cvar("amx_buttons_default","1");
//Who plugin analyze
//0 - anyone(plugin disabled?)
//1 - Te
//2 - Ct
//3 - Te+Ct
gcvarTeam=register_cvar("amx_buttons_team","1");
//Enabled FreeRun mode?
gcvarFreeRun=register_cvar("amx_buttons_freerun","1");
//Vote time
gcvarFRVoteTime=register_cvar("amx_freerun_votetime","10");

//Type of limit
//0 - enabled after 'amx_freerun_limit' rounds
//1 - enabled after 'amx_freerun_limit' minutes
gcvarLimitMode=register_cvar("amx_freerun_limit_mode","0");
//Size of Limit
gcvarLimit=register_cvar("amx_freerun_limit","5");

//Interval of message
gcvarMessage=register_cvar("amx_freerun_info","120.0",0,120.0);

//Terrorist`s privilege
//if he use /free FreeRun will start without vote, can he?
gcvarPrivilege=register_cvar("amx_freerun_tt_privilege","1");

//restore buttons on new round
gcvarRestore=register_cvar("amx_restore_buttons","1");

register_clcmd("say /free","cmdVoteFreeRun");
register_clcmd("say_team /free","cmdVoteFreeRun");
register_clcmd("say free","cmdVoteFreeRun");
register_clcmd("say_team free","cmdVoteFreeRun");

register_clcmd("say /freerun","cmdVoteFreeRun");
register_clcmd("say_team /freerun","cmdVoteFreeRun");
register_clcmd("say freerun","cmdVoteFreeRun");
register_clcmd("say_team freerun","cmdVoteFreeRun");

register_clcmd("say /fr","cmdVoteFreeRun");
register_clcmd("say_team /fr","cmdVoteFreeRun");
register_clcmd("say fr","cmdVoteFreeRun");
register_clcmd("say_team fr","cmdVoteFreeRun");

if( engfunc(EngFunc_FindEntityByString,-1 ,"classname", "func_button"))
RegisterHam(Ham_Use, "func_button", "fwButtonUsed");

if(engfunc(EngFunc_FindEntityByString,-1 ,"classname","func_rot_button"))
RegisterHam(Ham_Use, "func_rot_button", "fwButtonUsed");

if(engfunc(EngFunc_FindEntityByString,-1 ,"classname", "button_target"))
RegisterHam(Ham_Use, "button_target", "fwButtonUsed");

register_logevent( "ResetButtons", 2, "0=World triggered", "1=Round_Start");

fillButtons("func_button");
fillButtons("func_rot_button");
fillButtons("button_target");
return PLUGIN_CONTINUE
}
public plugin_cfg(){
setButtons();

new iLen=0, iMax=charsmax(gszFile);
iLen=get_configsdir(gszFile, iMax );
iLen+=copy(gszFile[iLen], iMax-iLen, "/dr_buttons/");

if(!dir_exists(gszFile)){
set_fail_state("Not found dir: configs/dr_buttons");
return;
}
new szMap[32];
get_mapname(szMap, 31);
formatex(gszFile[iLen], charsmax(gszFile)-iLen, "%s.ini", szMap);
if(!file_exists(gszFile)){
return;
}
new szLine[51];
new szButton[4], szTimes[3], szDelay[5];
new Float:fDelay;
for(new i=0;read_file(gszFile, i, szLine, 50, iLen);i++){
if(iLen==0) continue;
trim(szLine);
if(szLine[0]==';') continue;
parse(szLine, szButton, 3, szTimes, 2, szDelay, 4);
fDelay=szDelay[0]?str_to_float(szDelay):-1.0;
set_start_value(str_to_num(szButton), str_to_num(szTimes), fDelay);
}
new Float:fInterval=get_pcvar_float(gcvarMessage);
if(fInterval > 0.0)
set_task(120.0, "announceVote",ANNOUNCE_TASK,_,_,"b");
}
public plugin_precache() 
{    
giSprite=precache_model("sprites/flare1.spr");
BeaconSprite = precache_model("sprites/shockwave.spr")
get_configsdir(ConfigsDir, charsmax(ConfigsDir))
format(WordsFile, charsmax(WordsFile), "%s/deathrun_duels.ini", ConfigsDir)
new cmap[32], Len, dddir[128]
format(dddir, 127, "%s/deathrun_duels", ConfigsDir)
if(!dir_exists(dddir))
{
mkdir(dddir)
}
get_mapname(cmap, 31)
format(OriginsFile, charsmax(OriginsFile), "%s/deathrun_duels/%s.ini", ConfigsDir, cmap)
new i = 0
if(file_exists(WordsFile))
{
while(i < MAXWORDS && read_file(WordsFile, i , Words[WordsNum], 191, Len))
{
i++
if(Words[WordsNum][0] == ';' || Len == 0)
{
continue
}
WordsNum++
}
}
i = 0
if(file_exists(OriginsFile))
{
while(i < MAXORIGINS && read_file(OriginsFile, i ,Origins[OriginsNum], 127, Len))
{
i++
if(Origins[OriginsNum][0] == ';' || Len == 0)
{
continue
}
OriginsNum++
}
}
return PLUGIN_CONTINUE
}
public RoundStart()
{
Duel = false
Last = false
if(get_pcvar_num(PcvarTimer))
{
remove_task(TIMERTID)
}
remove_task(TIMER2TID)
remove_task(WAITTIMERTID)
set_pcvar_string(PcvarMode, "BUTTONS")
return PLUGIN_CONTINUE
}
public RoundEnd()
{
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
if(get_pcvar_num(PcvarTimer))
{
remove_task(TIMERTID)
}
remove_task(TIMER2TID)
remove_task(WAITTIMERTID)
return PLUGIN_CONTINUE
}

public PlayerSpawn(id)
{
if(!is_user_alive(id) || !cs_get_user_team(id) || is_user_bot(id))
{
return PLUGIN_CONTINUE
}
if(get_pcvar_num(PcvarSpawnGod))
{
set_pev(id, pev_takedamage, 0)
set_task(3.0, "GodOff", id + GODTID)
}
set_user_rendering(id)
remove_task(id)
TouchWeapons[id] = false
Once[id] = false
Knife[id] = false
Deagle[id] = false
M4a1[id] = false
Ak47[id] = false
Mp5navy[id] = false
Grenade[id] = false
Scout[id] = false
Drob[id] = false
Awp[id] = false
Math[id] = false
Word[id] = false
RussianRoulette[id] = false
Used[id] = false
NotYou[id] = false
DoIt[id] = false
Start[id] = false
InDuel[id] = false
Famas[id] = false

return PLUGIN_CONTINUE
}    
public TouchWeapon(weapon, id)
{
if(!is_user_connected(id))
{
return HAM_IGNORED
}
if(TouchWeapons[id] || cs_get_user_team(id) == CS_TEAM_SPECTATOR)
{
return HAM_SUPERCEDE
}
return HAM_IGNORED
}
public CmdStart(player, uc_handle, random_seed)
{
if(!is_user_alive(player) || player < 1 || player > 32)
{
return FMRES_IGNORED
}
new Buttons = get_uc(uc_handle, UC_Buttons)
if(Buttons & IN_ATTACK && Used[player])
{
if(Famas[player] && get_user_weapon(player, _, _) == CSW_FAMAS)
{
new wEnt = fm_find_ent_by_owner(-1, "weapon_famas", player);
cs_set_weapon_burst(wEnt, 1)
}
if(!NotYou[player])
{
if(player == RussianRouletteID && DoIt[player])
{    
new id = player
get_user_name(id, RussianRouletteName, 63)
set_hudmessage(255, 255, 0, -1.0, 0.3, 0, 1.0, 2.0, 0.5, 0.5, 2)
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "RRDOING", RussianRouletteName)
set_task(3.0, "RussianRouletteStop", id)
DoIt[id] = false
Start[id] = true
}
else if(player == RussianRouletteID && Start[player])
{
client_print(player, print_center, "%L", LANG_PLAYER, "RRWAIT")
}
else
{
client_print(player, print_center, "%L", LANG_PLAYER, "RRNOTYOU")
}
}
else if(Boom[player])
{
get_user_name(player, RussianRouletteName, 63)
set_hudmessage(255, 0, 0, -1.0, 0.2, 1, 1.0, 5.0, 1.0, 1.0, 4)
ShowSyncHudMsg(0, g_MsgHud3, "%L", LANG_PLAYER, "RRBOOM", RussianRouletteName)
client_cmd(0, "spk weapons/deagle-1")
set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
DeathMsg(player, player, KHS, KWPN)
Kill(player)
Used[CounterID] = false
Used[TerroristID] = false
}
else if(!Boom[player])
{
if(player == CounterID)
{
get_user_name(TerroristID, RussianRouletteName, 63)
RussianRouletteMenu(TerroristID)
NotYou[player] = false
DoIt[TerroristID] = true
RussianRouletteID = TerroristID
}
else if(player == TerroristID)
{
get_user_name(CounterID, RussianRouletteName, 63)
RussianRouletteMenu(CounterID)
NotYou[player] = false
DoIt[CounterID] = true
RussianRouletteID = CounterID
}
set_hudmessage(0, 255, 0, -1.0, 0.2, 0, 1.0, 3.0, 0.5, 0.5, 4)
ShowSyncHudMsg(0, g_MsgHud3, "%L", LANG_PLAYER, "RRNOTBOOM", RussianRouletteName)
client_cmd(0, "spk weapons/dryfire_pistol")
}
Buttons &= ~IN_ATTACK
set_uc(uc_handle, UC_Buttons, Buttons)
}
if(Deagle[player])
{
cs_set_user_bpammo(player, CSW_DEAGLE, 1)
}
if(M4a1[player])
{
cs_set_user_bpammo(player, CSW_M4A1, 3)
}
if(Ak47[player])
{
cs_set_user_bpammo(player, CSW_AK47, 3)
}
if(Mp5navy[player])
{
cs_set_user_bpammo(player, CSW_MP5NAVY, 3)
}
if(Scout[player])
{
cs_set_user_bpammo(player, CSW_SCOUT, 1)
}
if(Drob[player])
{
cs_set_user_bpammo(player, CSW_M3, 1)
}
if(Awp[player])
{
cs_set_user_bpammo(player, CSW_AWP, 1)
}
if(Famas[player] && get_user_weapon(player, _, _) == CSW_FAMAS)
{
new wEnt = fm_find_ent_by_owner(-1, "weapon_famas", player)
if(wEnt)
{
cs_set_weapon_burst(wEnt, 1)
cs_set_user_bpammo(player, CSW_FAMAS, 3)
}
}
return FMRES_HANDLED
}
public UpdateClientData(id, sendweapons, cd_handle)
{
if(!is_user_alive(id))
{
return FMRES_IGNORED
}
if(Used[id] && InDuel[id])
{
set_cd(cd_handle, CD_ID, 0)
}
return FMRES_HANDLED
}
public PlayerKilled(victim, attacker, shouldgib)
{
if(victim <= 0 || attacker <= 0 || victim >= 33 || attacker >= 33)
{
return PLUGIN_HANDLED
}
if(Duel)
{
if(cs_get_user_team(victim) == CS_TEAM_CT && InDuel[victim])
{
if(RussianRoulette[victim] || Math[victim] || Word[victim])
{
if(victim == CounterID)
{
attacker = TerroristID
}
else if(victim == TerroristID)
{
attacker = CounterID
}
TouchWeapons[attacker] = false
Once[attacker] = false
Knife[attacker] = false
Deagle[attacker] = false
M4a1[attacker] = false
Ak47[attacker] = false
Mp5navy[attacker] = false
Grenade[attacker] = false
Scout[attacker] = false
Drob[attacker] = false
Awp[attacker] = false
Math[attacker] = false
Word[attacker] = false
RussianRoulette[attacker] = false
Used[attacker] = false
NotYou[attacker] = false
DoIt[attacker] = false
Start[attacker] = false
InDuel[attacker] = false
Famas[attacker] = false
Duel = false
}
}
}
remove_task(attacker)
remove_task(victim)
return PLUGIN_CONTINUE
}
public CmdDuelsMenu(id)
{
if(!is_user_alive(id))
{
return PLUGIN_HANDLED
}
if (!Once[id])
{
if(cs_get_user_team(id) == CS_TEAM_CT)
{
new CTsNum = GetCTsNum(1)
new TsNum = GetTsNum(1)
if(CTsNum == 1 && TsNum >= 1)
{
DuelsMenu(id, MenuPosition[id] = 0)
}
else if(TsNum < 1)
{
ColorChat(id, "^4%s %L^3", PREFIX, LANG_PLAYER,"NOT_TS")
}
else if(CTsNum > 1)
{
ColorChat(id, "^4%s %L^3", PREFIX, LANG_PLAYER,"ONLY_LAST")
}
}
else
{
ColorChat(id, "^4%s %L^3", PREFIX, LANG_PLAYER, "ONLY_CTS")
}
}
return PLUGIN_HANDLED
}

public DuelsMenu(id, position)
{
if(position < 0)
{
return
}
FPage = false
new DuelsNum = GetFlagsNum(PcvarDuels)
new Flags = GetFlags(PcvarDuels)
new MenuStart = position * 8
if(MenuStart >= DuelsNum)
{
MenuStart = position = MenuPosition[id]
}
new MenuEnd = position * 8 + 8
if(MenuEnd >= DuelsNum && position != 0)
{
MenuEnd = DuelsNum
}
else if(MenuEnd >= DuelsNum && position == 0)
{
MenuEnd = DCOUNT
FPage = true
}
new Keys = MENU_KEY_0
new Len
new b
Len = format(MenuBody, MENUBODY - 1, "%L^n^n", LANG_PLAYER, "CHOOSE_DUEL")
for(new a = MenuStart; a < MenuEnd; a++)
{
if(Flags & (1 << a))
{
Keys |= (1 << b)
Len += format(MenuBody[Len], MENUBODY - Len, "%d. %L^n", ++b, LANG_PLAYER, Duels[a])
}
else
{
continue
}
}
if(MenuEnd != DuelsNum && !FPage)
{
Keys |= MENU_KEY_9
Len += format(MenuBody[Len], MENUBODY - Len, "^n9. %L^n0. %L^n^n %s", LANG_PLAYER, "DD_MENU_MORE", LANG_PLAYER, position ? "DD_MENU_BACK" : "DD_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
}
else
{
Len += format(MenuBody[Len], MENUBODY - Len, "^n0. %L^n^n %s", LANG_PLAYER, position ? "DD_MENU_BACK" : "DD_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
}
show_menu(id, Keys, MenuBody, -1, "Duels Menu")
}
public ActionDuelsMenu(id, key)
{
switch(key)
{
case 8:
{
DuelsMenu(id, ++MenuPosition[id])
}
case 9:
{
DuelsMenu(id, --MenuPosition[id])
}
default:
{
if(GetTsNum(1) || GetCTsNum(1) == 1|| is_user_alive(id))
{
ChoosedDuel = MenuPosition[id] * 8 + key
EnemyMenu(id, MenuPosition[id] = 0)
}
}
}    
}
public EnemyMenu(id, position)
{
if(position < 0)
{
return
}
new TsNum = 0
for(new aid = 1; aid <= MaxPlayers; aid++)
{
if(is_user_connected(aid) && is_user_alive(aid) && cs_get_user_team(aid) == CS_TEAM_T && !is_user_bot(aid))
{
MenuTs[TsNum++] = aid
}
}
new MenuStart = position * 8
if(MenuStart >= TsNum)
{
MenuStart = position = MenuPosition[id]
}
new MenuEnd = position + 8
if(MenuEnd > TsNum)
{
MenuEnd = TsNum
}
new Keys = MENU_KEY_0
new Len
new b = 0
new Names[32]
Len = format(MenuBody, MENUBODY - 1, "%L^n^n", LANG_PLAYER, "CHOOSE_ENEMY")
for(new a = MenuStart; a < MenuEnd; a++)
{
get_user_name(MenuTs[a], Names, 31)
Keys |= (1 << b)
Len += format(MenuBody[Len], MENUBODY - Len, "%d. %s^n", ++b, Names)
}
if(MenuEnd != TsNum)
{
Keys |= MENU_KEY_9
Len += format(MenuBody[Len], MENUBODY - Len, "^n9. %L^n0. %L^n^n %s", LANG_PLAYER, "DD_MENU_MORE", LANG_PLAYER, position ? "DD_MENU_BACK" : "DD_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
}
else
{
Len += format(MenuBody[Len], MENUBODY - Len, "^n0. %L^n^n %s", LANG_PLAYER, position ? "DD_MENU_BACK" : "DD_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
}
show_menu(id, Keys, MenuBody, -1, "Enemy Menu")
}
public ActionEnemyMenu(id, key)
{
switch(key)
{
case 8:
{
EnemyMenu(id, ++MenuPosition[id])
}
case 9:
{
EnemyMenu(id, --MenuPosition[id])
}
default:
{
if(GetTsNum(1) || GetCTsNum(1) == 1 || is_user_alive(id))
{
new Choosed = MenuPosition[id] * 8 + key
new Enemy = MenuTs[Choosed]
StartDuel(id, Enemy)
}
}
}    
}

public CmdOriginsMenu(id, level, cid)
{
if(!cmd_access(id, level, cid, 1))
{
return PLUGIN_HANDLED
}
else
{
ShowOriginsMenu(id)
}
return PLUGIN_CONTINUE
}

public ShowOriginsMenu(id)
{
new Keys = MENU_KEY_0
new Len
Len = format(MenuBody, MENUBODY, "%L^n^n", id, "ORIGINS_TITLE")
Keys |= (1 << 0)
Len += format(MenuBody[Len], MENUBODY - Len, "1. %L^n", id, "SAVE_POSITION")
Keys |= (1 << 1)
Len += format(MenuBody[Len], MENUBODY - Len, "2. %L^n", id, "DELETE_POSITIONS")
Len += format(MenuBody[Len], MENUBODY - Len, "^n0. %L^n^n %s", id, "DD_MENU_EXIT", PLUGIN, VERSION, AUTHOR)
show_menu(id, Keys, MenuBody, -1, "Origins Menu")
return PLUGIN_CONTINUE
}

public ActionOriginsMenu(id, key)
{
switch(key)
{
case 0:
{
new  vec[3]
get_user_origin(id, vec)
add_spawn(vec)
client_print(id, print_center, "*** Saved ***")
ShowOriginsMenu(id)
}
case 1:
{
if(file_exists(OriginsFile))
{
delete_file(OriginsFile)
client_print(id, print_center, "*** Deleted ***")
ShowOriginsMenu(id)
}
}
}
return PLUGIN_CONTINUE
}

public add_spawn(vecs[3])
{
new Line[128]
format(Line, 127, "%d %d %d",vecs[0], vecs[1], vecs[2])
write_file(OriginsFile, Line)
return PLUGIN_CONTINUE
}

public SetOrigins(ctid, terid)
{
if(!file_exists(OriginsFile) || !get_pcvar_num(PcvarTele))
{
return PLUGIN_CONTINUE
}
new pos[4][8]
parse(Origins[0], pos[1], 7, pos[2], 7, pos[3], 7)
new Vec[3]
Vec[0] = str_to_num(pos[1])
Vec[1] = str_to_num(pos[2])
Vec[2] = str_to_num(pos[3])
set_user_origin(ctid, Vec)
parse(Origins[1], pos[1], 7, pos[2], 7, pos[3], 7)
Vec[0] = str_to_num(pos[1])
Vec[1] = str_to_num(pos[2])
Vec[2] = str_to_num(pos[3])
set_user_origin(terid, Vec)
return PLUGIN_CONTINUE
}
public StartDuel(id, tempid)
{
if(!GetTsNum(1) || GetCTsNum(1) > 1|| !is_user_alive(tempid) || !is_user_alive(id) || cs_get_user_team(tempid) != CS_TEAM_T || cs_get_user_team(id) != CS_TEAM_CT || !is_user_connected(tempid) || !is_user_connected(id) || is_user_bot(id) || is_user_bot(tempid))
{
return PLUGIN_HANDLED
}
new challenger[32], challenged[32]
get_user_name(id, challenger, 31)
get_user_name(tempid, challenged, 31)
strip_user_weapons(id)
strip_user_weapons(tempid)
set_user_health(id, 175)
set_user_health(tempid, 175)
switch(get_pcvar_num(PcvarEffects))
{
case 1:
{
set_user_rendering(id, kRenderFxGlowShell, 0, 0, 150, kRenderNormal, 20)    
set_user_rendering(tempid, kRenderFxGlowShell, 150, 0, 0, kRenderNormal, 20)
}
case 2:
{
set_task(1.0, "Beacon", id)
set_task(1.0, "Beacon", tempid)
}
case 3:
{
set_user_rendering(id, kRenderFxGlowShell, 0, 0, 150, kRenderNormal, 20)    
set_task(1.0, "Beacon", id)
set_user_rendering(tempid, kRenderFxGlowShell, 150, 0, 0, kRenderNormal, 20)
set_task(1.0, "Beacon", tempid)
}
}
InDuel[tempid] = true
InDuel[id] = true
Once[id] = true 
TouchWeapons[id] = true
TouchWeapons[tempid] = true
CounterID = id
TerroristID = tempid
Timer = get_pcvar_num(PcvarWait)
Index = get_pcvar_num(PcvarTimeLimit) + 1
set_pcvar_string(PcvarMode, "DUEL")
new Flags = GetFlags(PcvarDuels)
DuelNum = 0
new DuelIndex
while(DuelIndex <= ChoosedDuel)
{
if(Flags & (1 << DuelNum))
{
DuelIndex++
}
DuelNum ++
}
SetOrigins(id, tempid)
switch(DuelNum)
{
case 1:
{
Knife[id] = true
Knife[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"KNIFE1",  challenger, challenged)     
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 2:
{
Deagle[id] = true
Deagle[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"DEAGLE1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"DEAGLE2")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED 
}
case 3:
{
M4a1[id] = true
M4a1[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"M4A11", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"M4A12")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED 
}
case 4:
{
Ak47[id] = true
Ak47[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"AK471", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"AK472")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED 
}
case 5:
{
Mp5navy[id] = true
Mp5navy[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"MP5NAVY1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"MP5NAVY2")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED 
}
case 6:
{
Grenade[id] = true
Grenade[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"GRENADE1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"GRENADE2") 
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 7:
{
Scout[id] = true
Scout[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"SCOUT1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"SCOUT2") 
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 8:
{
Drob[id] = true
Drob[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"DROB1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"DROB2") 
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 9:
{
Awp[id] = true
Awp[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"AWP1", challenger, challenged) 
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER,"AWP2") 
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 10:
{
Famas[id] = true
Famas[tempid] = true
Duel = true
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "FAMAS1", challenger, challenged)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "FAMAS2")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_HANDLED
}
case 11:
{
RussianRoulette[id] = true
RussianRoulette[tempid] = true
Duel = true
RussianRouletteBullet = random_num(1, 7)
for(new i=1;i<=7;i++)
{	
	RRammo[id][i]=0
	RRammo[tempid][i]=0;
}
cs_set_weapon_ammo(give_item(id, "weapon_deagle"), RussianRouletteBullet)
cs_set_weapon_ammo(give_item(tempid, "weapon_deagle"), RussianRouletteBullet)
StartRussianRoulette(id, tempid)
if(get_pcvar_num(PcvarMusic))
{
new musicnum = random_num(0, MCOUNT-1)
client_cmd(0, "mp3volume 0.9")
client_cmd(0, "mp3 play %s", Music[musicnum])
}
return PLUGIN_HANDLED
}
case 12:
{
Math[id] = true
Math[tempid] = true
Duel = true
StartMathDuel(id, tempid)
return PLUGIN_HANDLED
}
case 13:
{
Word[id] = true
Word[tempid] = true
Duel = true
StartWordDuel(id, tempid)
return PLUGIN_HANDLED
}
}
if(get_pcvar_num(PcvarMusic))
{
new musicnum = random_num(0, MCOUNT-1)
client_cmd(0, "mp3volume 0.9")
client_cmd(0, "mp3 play %s", Music[musicnum])
}
if(get_pcvar_num(PcvarTimer))
{
set_task(0.0, "DuelTimer", TIMERTID)
}
Duel = true
return PLUGIN_HANDLED
}
public DuelTimer()
{
Index--
if(Index > 60)
{
set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, MathTask)
}
else if(Word[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, WordAnswer)
}
else 
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER", Index)
}
set_task(1.0, "DuelTimer", TIMERTID)
}
else if(60 >= Index >= 46)
{
set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, MathTask)
}
else if(Word[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, WordAnswer)
}
else 
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER", Index)
}
set_task(1.0, "DuelTimer", TIMERTID)
}
else if(45 >= Index >= 31)
{
set_hudmessage(255, 255, 0, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, MathTask)
}
else if(Word[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, WordAnswer)
}
else 
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER", Index)
}
set_task(1.0, "DuelTimer", TIMERTID)
}
else if(30 >= Index >= 16)
{
set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, MathTask)
}
else if(Word[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, WordAnswer)
}
else 
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER", Index)
}
set_task(1.0, "DuelTimer", TIMERTID)
}
else if(Index <= 15)
{
set_hudmessage(255, 0, 0, -1.0, 0.25, 1, 1.0, 1.0, _, _, 2)
if(Index > 0)
{
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, MathTask)
}
else if(Word[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER2", Index, WordAnswer)
}
else 
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUEL_TIMER", Index)
}
}
else if(Index < 0)
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "NO_WINNER")
Kill(CounterID)
Kill(TerroristID)
remove_task(TIMERTID)
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
}
set_task(1.0, "DuelTimer", TIMERTID)
}
if(!is_user_alive(CounterID) || !is_user_alive(TerroristID))
{
remove_task(TIMERTID)
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
}
return PLUGIN_CONTINUE
}

public DuelTimer2()
{
set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
if(Math[CounterID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUELTASK", MathTask)
}
if(Word[TerroristID])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "DUELTASK", WordAnswer)
}
set_task(1.0, "DuelTimer2", TIMER2TID)
if(!is_user_alive(CounterID) || !is_user_alive(TerroristID))
{
remove_task(TIMER2TID)
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
}
}
public StartMathDuel(ct, ter)
{
new num1,num2,num3,num4,mode, ctname[64], tername[64]
mode = random_num(0, 6)
num1 = random_num(1, 100)
num2 = random_num(1, 10)
num3 = random_num(1, 100)
num4 = random_num(1, 10)
get_user_name(ct, ctname, 63)
get_user_name(ter, tername, 63)
switch(mode)
{
case 0:
{
format(MathTask, 63, "%d + %d + %d + %d = ?", num1, num2, num3, num4)
MathAnswer = num1 + num2 + num3 + num4
}
case 1:
{
format(MathTask, 63, "%d + %d + %d - %d = ?", num1,num2,num3,num4)
MathAnswer = num1 + num2 + num3 - num4
}
case 2:
{
format(MathTask, 63, "%d + %d - %d + %d = ?", num1, num2, num3, num4)
MathAnswer = num1 + num2 - num3 + num4
}
case 3:
{
format(MathTask, 63, "%d - %d + %d + %d = ?", num1, num2, num3, num4)
MathAnswer = num1 - num2 + num3 + num4
}
case 4:
{
format(MathTask, 63, "%d + %d - %d - %d = ?", num1, num2, num3, num4)
MathAnswer = num1 + num2 - num3 - num4
}
case 5:
{
format(MathTask, 63, "%d - %d + %d - %d = ?", num1, num2, num3, num4)
MathAnswer = num1 - num2 + num3 - num4
}
case 6:
{
format(MathTask, 63, "%d - %d - %d + %d = ?", num1, num2, num3, num4)
MathAnswer = num1 - num2 - num3 + num4
}
}
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "MATH1", ctname, tername)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "MATH2")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_CONTINUE
}
public StartWordDuel(ct, ter)
{
new ctname[64], tername[64]
format(WordAnswer, charsmax(WordAnswer), "%s", Words[random_num(0, WordsNum)])
get_user_name(ct, ctname, 63)
get_user_name(ter, tername, 63)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "WORD1", ctname, tername)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "WORD2")
set_task(0.0, "StartWait", WAITTIMERTID)
return PLUGIN_CONTINUE
}
public StartWait()
{
set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 1.0, 1.0, _, _, 2)
switch(DuelNum)
{
case 1:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "KNIFE_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 2:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "DEAGLE_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 3:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "M4A1_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 4:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "AK47_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 5:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "MP5NAVY_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 6:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "GRENADE_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 7:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "SCOUT_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 8:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "DROB_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 9:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "AWP_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 10:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "FAMAS_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 11:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "MATH_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
case 12:
{
ShowSyncHudMsg(0, g_MsgHud2, "%L^n%L", LANG_PLAYER, "WORD_WAIT", LANG_PLAYER, "STARTAFTER", Timer)
}
}
Timer--
client_cmd(0, "spk %s", Sound[Timer])
if(Timer <= 0)
{
set_task(1.0, "StartGo")
}
else
{

set_task(1.0, "StartWait", WAITTIMERTID)
}
return PLUGIN_CONTINUE
}
public StartGo()
{
if(!is_user_alive(TerroristID) || !is_user_alive(CounterID) || !is_user_connected(TerroristID) || !is_user_connected(CounterID) || !is_valid_player(CounterID) || !is_valid_player(TerroristID))
{
return PLUGIN_HANDLED
}
switch(DuelNum)
{
case 1:
{
give_item(CounterID, "weapon_knife")
give_item(TerroristID, "weapon_knife")    
}
case 2:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_deagle"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_deagle"), DAMMO)
}
case 3:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_m4a1"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_m4a1"), DAMMO)
cs_set_user_bpammo(CounterID, CSW_M4A1, 200)        
cs_set_user_bpammo(TerroristID, CSW_M4A1, 200)
}
case 4:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_ak47"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_ak47"), DAMMO)
cs_set_user_bpammo(CounterID, CSW_AK47, 200)        
cs_set_user_bpammo(TerroristID, CSW_AK47, 200)
}
case 5:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_mp5navy"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_mp5navy"), DAMMO)
cs_set_user_bpammo(CounterID, CSW_MP5NAVY, 200)        
cs_set_user_bpammo(TerroristID, CSW_MP5NAVY, 200)
}
case 6:
{
give_item(CounterID, "weapon_hegrenade")
give_item(TerroristID, "weapon_hegrenade")
cs_set_user_bpammo(CounterID, CSW_HEGRENADE, 100)        
cs_set_user_bpammo(TerroristID, CSW_HEGRENADE, 100)
}
case 7:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_scout"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_scout"), DAMMO)
}
case 8:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_m3"), 8)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_m3"), 8)
}
case 9:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_awp"), DAMMO)
cs_set_weapon_ammo(give_item(TerroristID, "weapon_awp"), DAMMO)
}
case 10:
{
cs_set_weapon_ammo(give_item(CounterID, "weapon_famas"), 3)
new wEnt = fm_find_ent_by_owner(-1, "weapon_famas", CounterID)
if(wEnt)
{
cs_set_weapon_burst(wEnt, 1)
}
cs_set_weapon_ammo(give_item(TerroristID, "weapon_famas"), 3)
wEnt = fm_find_ent_by_owner(-1, "weapon_famas", TerroristID)
if(wEnt)
{
cs_set_weapon_burst(wEnt, 1)
}
}
}
if(get_pcvar_num(PcvarMusic))
{
new musicnum = random_num(0, MCOUNT-1)
client_cmd(0, "mp3volume 0.9")
client_cmd(0, "mp3 play %s", Music[musicnum])
}
if(get_pcvar_num(PcvarTimer))
{
set_task(0.0, "DuelTimer", TIMERTID)
}
else if(Math[CounterID] || Word[CounterID])
{
set_task(0.0, "DuelTimer2", TIMER2TID)
}
return PLUGIN_CONTINUE
}
public StartRussianRoulette(ct, ter)
{
new ctname[64], tername[64]
get_user_name(ct, ctname, 63)
get_user_name(ter, tername, 63)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "RR1", ctname, tername)
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "RR2")
ColorChat(0, "^4%s %L^3", PREFIX, LANG_PLAYER, "RR3", ctname)
set_hudmessage(0, 255, 0, -1.0, 0.2, 0, 1.0, 2.0, 0.5, 0.5, 4)
ShowSyncHudMsg(0, g_MsgHud3, "%L", LANG_PLAYER, "RRSTART", ctname, RussianRouletteBullet)
RussianRouletteMenu(ct)
Used[ct] = true
Used[ter] = true
NotYou[ct] = false
NotYou[ter] = false
RussianRouletteID = ct
return PLUGIN_CONTINUE
}
public RussianRouletteMenu(id)
{
new Len
new Keys = MENU_KEY_0
Len = format(MenuBody, MENUBODY - 1, "%L^n^n", LANG_PLAYER, "RRTITLE")
Keys |= (1 << 0)
Len += format(MenuBody[Len], MENUBODY - Len, "1. %L^n^n %s", LANG_PLAYER, "RRDO", PLUGIN, VERSION, AUTHOR)
DoIt[id] = true
show_menu(id, Keys, MenuBody, -1, "Roulette Menu")
return PLUGIN_CONTINUE
}
public ActionRussianRouletteMenu(id, Key)
{
if(!DoIt[id])
{
return PLUGIN_HANDLED
}
get_user_name(id, RussianRouletteName, 63)
set_hudmessage(255, 255, 0, -1.0, 0.3, 0, 1.0, 2.0, 0.5, 0.5, 2)
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "RRDOING", RussianRouletteName)
set_task(3.0, "RussianRouletteStop", id)
DoIt[id] = false
Start[id] = true
return PLUGIN_HANDLED
}
public RussianRouletteStop(id)
{
	new RuletteRandom
	do{
		RuletteRandom = random_num(1, 7)
	}while(RRammo[id][RuletteRandom]==1);
	RRammo[id][RuletteRandom]=1
	get_user_name(id, RussianRouletteName, 63)
	if(RussianRouletteBullet == RuletteRandom )
	{
		Boom[id] = true
	}
	else
	{
		Boom[id] = false
	}
	NotYou[id] = true
	Start[id] = false
	set_hudmessage(255, 255, 0, -1.0, 0.3, 0, 1.0, 2.0, 0.5, 0.5, 2)
	ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "RRPRESS", RussianRouletteName)
	return PLUGIN_CONTINUE
}
public hooksay(id)
{
if(!Math[id] && !Word[id])
{
return PLUGIN_CONTINUE
}
new Msg[256], smanswer[32], wname[32]
read_args(Msg, 255)
remove_quotes(Msg)
num_to_str(MathAnswer, smanswer, 31)
if((Math[id] && equal(Msg, smanswer)) || (Word[id] && equal(Msg, WordAnswer)))
{
if(get_pcvar_num(PcvarTimer))
{
remove_task(TIMERTID)
}
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
get_user_name(id, wname, 31)
//set_user_lifes(id, 1)
set_hudmessage(0, 255, 0, -1.0, 0.2, 0, 1.0, 10.0, 1.0, 1.0, 2)
if(Math[id])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "MATH_WINNER", wname, smanswer)
}
else if(Word[id])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "WORD_WINNER", wname)
}
if(id == CounterID)
{
set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
DeathMsg(CounterID, TerroristID, 1, KWPN)
Kill(TerroristID)
}
else if(id == TerroristID)
{
set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
DeathMsg(CounterID, TerroristID, 1, KWPN)
Kill(CounterID)
}
Math[CounterID] = false
Math[TerroristID] = false
Word[CounterID] = false
Word[TerroristID] = false
}
return PLUGIN_CONTINUE
}
public hooksay_team(id)
{
if(!Math[id] && !Word[id])
{
return PLUGIN_CONTINUE
}
new Msg[256], smanswer[32], wname[32]
read_args(Msg, 255)
remove_quotes(Msg)
num_to_str(MathAnswer, smanswer, 31)
if((Math[id] && equal(Msg, smanswer)) || (Word[id] && equal(Msg, WordAnswer)))
{
if(get_pcvar_num(PcvarTimer))
{
remove_task(TIMERTID)
}
if(get_pcvar_num(PcvarMusic))
{
client_cmd(0, "cd fadeout")
}
get_user_name(id, wname, 31)
//set_user_lifes(id, 1)
set_hudmessage(0, 255, 0, -1.0, 0.2, 0, 1.0, 10.0, 1.0, 1.0, 2)
if(Math[id])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "MATH_WINNER", wname, smanswer)
}
else if(Word[id])
{
ShowSyncHudMsg(0, g_MsgHud2, "%L", LANG_PLAYER, "WORD_WINNER", wname)
}
if(id == CounterID)
{
set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
DeathMsg(CounterID, TerroristID, 1, KWPN)
Kill(TerroristID)
}
else if(id == TerroristID)
{
set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
DeathMsg(CounterID, TerroristID, 1, KWPN)
Kill(CounterID)
}
Math[CounterID] = false
Math[TerroristID] = false
Word[CounterID] = false
Word[TerroristID] = false
}
return PLUGIN_CONTINUE
}
public client_disconnect(id)
{
remove_task(id)
TouchWeapons[id] = false
Once[id] = false
Knife[id] = false
Deagle[id] = false
M4a1[id] = false
Ak47[id] = false
Mp5navy[id] = false
Grenade[id] = false
Scout[id] = false
Drob[id] = false
Awp[id] = false
Math[id] = false
Word[id] = false
RussianRoulette[id] = false
Used[id] = false
NotYou[id] = false
DoIt[id] = false
Start[id] = false
InDuel[id] = false
Famas[id] = false
return PLUGIN_CONTINUE
}
public GodOff(tskid)
{
new id = tskid - GODTID
set_pev(id, pev_takedamage, 1)
return PLUGIN_CONTINUE
}
public Informer()
{
if(!get_pcvar_num(PcvarInformer))
{
remove_task(INFORMERTID)
return PLUGIN_HANDLED
}
new id, LastID, acts, cts, all, NextMap[32], CurrentTime[32], Terrorist[32], names[33][32], Message[512]
for(id = 1; id <= MaxPlayers; id++)
{
if(!is_user_connected(id))
{
continue
}
else if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
{
acts++
cts++
all ++
LastID = id
get_user_name(id, names[acts], 31)
}
else if(!is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
{
cts++
all++
}
else if(cs_get_user_team(id) == CS_TEAM_T && !is_user_bot(id))
{
get_user_name(id, Terrorist, 63)
all++
}
else
{
all++
}
}
if(acts == 1 && !Last && get_pcvar_num(PcvarLastMenu))
{
LastMenu(LastID)
Last = true
}
for(id = 1; id <= MaxPlayers; id++)
{
new Len, Mode[32]
get_pcvar_string(PcvarMode, Mode, 31)
Len = format(Message, 511, "%L: %L", LANG_PLAYER, "CURRENTMODE", LANG_PLAYER, Mode)
get_time("%H:%M:%S", CurrentTime, 31)
Len += format(Message[Len], 511 - Len, "^n%L: %s", LANG_PLAYER, "CURRENTTIME", CurrentTime)
if(get_cvar_float("mp_timelimit"))
{
new a = get_timeleft()
Len += format(Message[Len], 511 - Len, "^n%L: %d:%02d", LANG_PLAYER, "TLEFT", (a / 60), (a % 60))
}
else
{
Len += format(Message[Len], 511 - Len, "^n%L: %L", LANG_PLAYER, "TLEFT", LANG_PLAYER, "LASTR")
}
get_cvar_string("amx_nextmap", NextMap, 31)
Len += format(Message[Len], 511 - Len, "^n%L: %s", LANG_PLAYER, "NMAP", NextMap)
if(GetTsNum(0))
{
Len += format(Message[Len], 511 - Len, "^n%L: %s", LANG_PLAYER, "CTER", Terrorist)
}
else
{
Len += format(Message[Len], 511 - Len, "^n%L: %L", LANG_PLAYER, "CTER", LANG_PLAYER, "TNONE")
}
Len += format(Message[Len], 511 - Len, "^n%L: %d/%d", LANG_PLAYER, "ALIVECTS", acts,cts)
Len += format(Message[Len], 511 - Len, "^n%L: %d/%d", LANG_PLAYER, "APLAYERS", all, MaxPlayers)
if(acts > 3)
{
set_hudmessage(100, 100, 100, 0.01, 0.18, 0, 1.0, 1.0)
}
else if(acts == 3)
{
set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 1.0, 1.0)
Len += format(Message[Len], 511 - Len, "^n^n1. %s^n2. %s^n3. %s", names[1], names[2], names[3])
}
else if(acts == 2)
{
set_hudmessage(255, 255, 0, 0.01, 0.18, 0, 1.0, 1.0)
Len += format(Message[Len], 511 - Len, "^n^n1. %s^n2. %s", names[1], names[2])
}
else
{
set_hudmessage(255, 0, 0, 0.01, 0.18, 1, 1.0, 1.0, _, _, 1)
Len += format(Message[Len], 511 - Len, "^n^n1. %s", names[1])
}
ShowSyncHudMsg(id, g_MsgHud1, "%s", Message)    
}
return PLUGIN_CONTINUE
}
public LastMenu(id)
{
new Len
new Keys = MENU_KEY_0
Len = format(MenuBody, MENUBODY - 1, "%L ^n^n", LANG_PLAYER, "YOULAST")
Keys |= (1 << 0)
Len += format(MenuBody[Len], MENUBODY - Len, "1. %L^n", LANG_PLAYER, "LASTYES")
Keys |= (1 << 1)
Len += format(MenuBody[Len], MENUBODY - Len, "2. %L^n^n %s", LANG_PLAYER, "LASTNO", PLUGIN, VERSION, AUTHOR)
show_menu(id, Keys, MenuBody, -1, "Last Menu")
return PLUGIN_CONTINUE
}
public ActionLastMenu(id, key)
{
switch(key)
{
case 0:
{
client_cmd(id, "deathrun_duels")
}
case 1:
{
client_print(id, print_center, "%L", LANG_PLAYER, "FDUEL")
}
}
return PLUGIN_CONTINUE
}
public Beacon(id)
{
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
stock ColorChat(const id, const input[], any:...)
{
new count = 1, players[32]
static msg[190]
vformat(msg, 190, input, 3)
replace_all(msg, 190, "!g", "^4")
replace_all(msg, 190, "!y", "^1")
replace_all(msg, 190, "!team", "^3")
if (id) players[0] = id
else get_players(players, count, "ch")
for (new i = 0; i < count; i++)
{
if (is_user_connected(players[i]))
{
message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i])
write_byte(players[i])
write_string(msg)
message_end()
}
}
return PLUGIN_CONTINUE
}
stock DeathMsg(killer_id, victim_id, headshot, weaponname[])
{
message_begin(MSG_ALL, get_user_msgid("DeathMsg"))
write_byte(killer_id)
write_byte(victim_id)
write_byte(headshot)
write_string(weaponname)
message_end()
return PLUGIN_CONTINUE
}
stock GetFlagsNum(pcvar)
{
new Duels = GetFlags(pcvar)
new DuelsNum = 0
for(new a = 0; a < DCOUNT; a++)
{
if(Duels & (1 << a))
{
DuelsNum++
}
}
return DuelsNum
}
stock GetFlags(pcvar)
{
new Flags[32]
get_pcvar_string(pcvar, Flags, 31)
return read_flags(Flags)
}
stock GetCTsNum(alive)
{
new CTsNum = 0
for (new id = 1; id <= MaxPlayers; id++)
{
if(!is_user_connected(id))
{ 
continue
}
if(alive)
{
if(cs_get_user_team(id) == CS_TEAM_CT && is_user_alive(id))
{ 
CTsNum++
} 
}
else
{
if(cs_get_user_team(id) == CS_TEAM_CT)
{ 
CTsNum++
} 
}
}
return CTsNum
}
stock GetTsNum(alive)
{
new TsNum = 0
for (new id = 1; id <= MaxPlayers; id++)
{
if(!is_user_connected(id) || is_user_bot(id))
{ 
continue
}
if(alive)
{
if(cs_get_user_team(id) == CS_TEAM_T && is_user_alive(id))
{ 
TsNum++
} 
}
else
{
if(cs_get_user_team(id) == CS_TEAM_T)
{ 
TsNum++
} 
}
}
return TsNum
}

public client_putinserver(id){
if(!is_user_bot(id))
eventInGame(id);
}
public client_connect(id){
giVotes[id][VOTE_ON]=0;
giVotes[id][VOTE_OFF]=0;

return 1
}
public announceVote(){
if(get_pcvar_num(gcvarFreeRun))
ColorChat(0, "!g[!teamFreeRun!g]!team %L",LANG_SERVER, "ANNOUNCE");
}
setButtons(){
new iDef=get_pcvar_num(gcvarDefault);
for(new i=0;i<giPointer;i++){
gUsed[i]=iDef;
gOnStart[i]=iDef;
gDelay[i]=get_pdata_float(gEnt[i],m_flWait);
gDefaultDelay[i]=gDelay[i];
}
}
fillButtons(const szClass[]){
new ent = -1;
while((ent = engfunc(EngFunc_FindEntityByString,ent ,"classname", szClass)) != 0){
gEnt[giPointer++]=ent;
set_pev(ent, pev_iuser4, giPointer);
}
}
set_start_value(ent, times, Float:delay){
new index=get_ent_index(ent);
if(index!=-1){
gOnStart[index]=times;
if(delay>=0.0)
gDelay[index]=delay;
}
}
get_ent_index(ent){
/*
for(new i=0;i<giPointer;i++)
if(gEnt[i]==ent) return i;
return -1;
*/
return pev(ent, pev_iuser4)-1;
}
restoreButton(ent){
if(pev(ent, pev_frame) > 0.0){
new Float:Life;
pev(ent, pev_nextthink, Life);
set_pev(ent, pev_ltime, Life-0.01);
}
}
public ResetButtons(){
gbFreeRun=false;
gbVote=false;
new bool:bRestore=get_pcvar_num(gcvarRestore)!=0;
for(new i=0;i<MAX_BUTTONS;i++){
gUsed[i]=gOnStart[i];
if(bRestore){
restoreButton(gEnt[i]);
}
}
giRounds++;
}
public fwButtonUsed(this, idcaller, idactivator, use_type, Float:value){
if(idcaller!=idactivator) return HAM_IGNORED;

if(pev(this, pev_frame) > 0.0)
return HAM_IGNORED;
new index=get_ent_index(this);
if(index==-1) 
return HAM_IGNORED;
if(get_user_team(idcaller)&get_pcvar_num(gcvarTeam)){

if(gbFreeRun){
ColorChat(idcaller, "!y[!gFreeRun!y]!team %L",idcaller, "BUTTON_FREERUN");
return HAM_SUPERCEDE;
}
else if(gUsed[index]<=0 && gOnStart[index]!=-1){
ColorChat(idcaller, "!y[!gInfo!y]!team %L",idcaller,"BUTTON_NOMORE");
return HAM_SUPERCEDE;
}
else{
if(gUsed[index]>0)
if(--gUsed[index]){
ColorChat(idcaller, "!y[!gInfo!y]!team %L", idcaller, "BUTTON_LEFT", gUsed[index]);
}else
ColorChat(idcaller, "!y[!gInfo!y]!team %L", idcaller, "BUTTON_ENDOFLIMIT");
}
}

set_task(0.1,"setDelay",this);

return HAM_IGNORED;
}
public setDelay(this){
new index=get_ent_index(this);
set_pev(this, pev_nextthink, pev(this, pev_ltime)+gDelay[index]+0.01);
}

//MENU--------------
public cmd_amx_buttons(id, level, cid){
if(!cmd_access(id, level, cid, 1))
return PLUGIN_HANDLED;
if(giPointer==0)
client_print(id, print_chat, "%L", id,"NO_BUTTONS");
else
ShowButtonsMenu(id);
return PLUGIN_HANDLED;
}
ShowButtonsMenu(id, trace=1){
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id, "MUST_B_ALIVE");
return;
}
new iNow=gInMenu[id];
new iKeys=(1<<0)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<9);
new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
new szNoLimit[32];
formatex(szNoLimit,31,"(%L)",id,"NOLIMIT");
iLen=copy(szMenu, iMax,"Buttons Menu^n");
iLen+=formatex(szMenu[iLen], iMax-iLen,"Ent #%d^n^n",gEnt[iNow]);
iLen+=formatex(szMenu[iLen], iMax-iLen,"%L: %d %s^n 1. %L ",id, "USAGE",gOnStart[iNow],(gOnStart[iNow]==-1)?szNoLimit:"", id, "MORE");

if(gOnStart[iNow]>=0){
iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %L",id, "WORD_LESS");
iKeys|=(1<<1);
}else
iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %L",id,"WORD_LESS");
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n^n3. %L^n^n4. %L^n^n",id, "DELAY_EDITOR",id,"OPTIONS");

iLen+=formatex(szMenu[iLen], iMax-iLen,"5. %sNo Clip^n",isNoClip(id)?"r":"");
iLen+=formatex(szMenu[iLen], iMax-iLen,"6. %sGodMode^n",isGodMode(id)?"r":"");

iLen+=formatex(szMenu[iLen], iMax-iLen,"^n7. %L^nw",id, "WORD_SAVE");

if(iNow>0){
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n8. %L",id, "BACK");
iKeys|=(1<<7);
}
if(iNow<giPointer-1){
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n9. %L",id, "WORD_NEXT");
iKeys|=(1<<8);
}
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n0. %L", id, "EXIT");
show_menu(id, iKeys, szMenu, -1, "ButtonsMenu");
if(trace){
new Float:fOrigin[3], Float:fOrigin2[3];
fm_get_brush_entity_origin(gEnt[gInMenu[id]], fOrigin);
pev(id, pev_origin, fOrigin2);
Create_TE_BEAMPOINTS(fOrigin, fOrigin2, giSprite, 0, 10, 20, 5, 1, 255, 0, 0, 100, 50);
}
}
bool:isNoClip(id)
return pev(id, pev_movetype)==MOVETYPE_NOCLIP;

bool:isGodMode(id)
return pev(id, pev_takedamage)==0.0;

public PressedButtonsMenu(id, key) {
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
return;
}
/* Menu:
* Buttons Menu
* Ent#<ent>
* 
* Uzyc: <ile>
* 1. Wiecej 2. Mniej
* 
* 3. Editor
*
* 4. Options
*
* 5. NoClip
* 6. GodMode
* 
* 7. Zapisz
* 
* 8. Poprzedni
* 9. Nastepny
* 0. Wyjdz
*/
new trace=0;
switch (key) {
case 0: { // 1
gOnStart[gInMenu[id]]++;
}
case 1: { // 2
gOnStart[gInMenu[id]]--;
}
case 2: { // 3
ShowDelayMenu(id);
return;
}
case 3:{ //4
ShowOptionsMenu(id);
return;
}
case 4:{ //5
set_pev(id, pev_movetype, isNoClip(id)?MOVETYPE_WALK:MOVETYPE_NOCLIP);	
}
case 5:{ //6
set_pev(id, pev_takedamage, isGodMode(id)?1.0:0.0);
}
case 6: { // 7
save2File(id);
}
case 7: { // 8
gInMenu[id]--;
trace=1;
}
case 8: { // 9
gInMenu[id]++;
trace=1;
}
case 9: { // 0
return;
}
}
ShowButtonsMenu(id, trace);
}
//--------------
ShowOptionsMenu(id){
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
return;
}
new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
iLen+=formatex(szMenu[iLen], iMax-iLen,"yOptions^n^n");
iLen+=formatex(szMenu[iLen], iMax-iLen,"w1. %L^n",id, "GOTO");
iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %L^n^n",id, "NEAREST");
iLen+=formatex(szMenu[iLen], iMax-iLen,"9. %L",id, "BACK");
show_menu(id, KeysOptionsMenu, szMenu, -1, "OptionsMenu");
}
public PressedOptionsMenu(id, key){
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
return;
}
new trace=0;
switch (key) {                                                                          
case 0: { // 1
go2Button(id);
}
case 1: { // 2
gInMenu[id]=findTheClosest(id);
trace=1;
}
}
ShowButtonsMenu(id, trace);
}
//-------------
ShowDelayMenu(id){
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
return;
}
new iNow=gInMenu[id];
new iKeys=(1<<0)|(1<<2)|(1<<8);
new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
iLen=copy(szMenu, iMax,"yDelay Menu^n");
iLen+=formatex(szMenu[iLen], iMax-iLen,"Ent#%d^n^n",gEnt[iNow]);
iLen+=formatex(szMenu[iLen], iMax-iLen,"%L: %.1f^n",id, "CURRENT_DELAY", gDelay[iNow]);
iLen+=formatex(szMenu[iLen], iMax-iLen,"1. %L ",id, "MORE");
if(gDelay[iNow]>0.0){
iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %L",id, "WORD_LESS");
iKeys|=(1<<1);
}else
iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %Lw",id,"WORD_LESS");
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n3. %L",id, "DEFAULT");
iLen+=formatex(szMenu[iLen], iMax-iLen,"^n^n9. %L",id, "BACK");
show_menu(id, iKeys, szMenu, -1, "DelayMenu");
}
public PressedDelayMenu(id, key){
new iNow=gInMenu[id];
switch(key){
case 0:{
gDelay[iNow]+=1.0;
}
case 1:{
gDelay[iNow]-=1.0;
if(gDelay[iNow] < 0.0)
gDelay[iNow]=0.0;
}
case 2:{
gDelay[iNow]=gDefaultDelay[iNow];
}
case 8:{
ShowButtonsMenu(id, 0);
return;
}
}
ShowDelayMenu(id);
}
//-------------
save2File(id){
if(file_exists(gszFile))
delete_file(gszFile);
write_file(gszFile, ";<ent> <count> <delay>");
new szLine[35];
for(new i=0;i<giPointer;i++){
formatex(szLine, 34, "%d %d %.1f",gEnt[i], gOnStart[i], gDelay[i]);
write_file(gszFile, szLine);
}
client_print(id, print_center, "%L!",id,"WORD_SAVED");
}
findTheClosest(id){
new Float:fPlayerOrig[3];
pev(id, pev_origin, fPlayerOrig);
new Float:fOrigin[3];
fm_get_brush_entity_origin(gEnt[0], fOrigin);

new Float:fRange=get_distance_f(fOrigin, fPlayerOrig), index=0;
new Float:fNewRange;
for(new i=1;i<giPointer;i++){
fm_get_brush_entity_origin(gEnt[i], fOrigin);
fNewRange=get_distance_f( fOrigin,  fPlayerOrig);
if(fNewRange < fRange){
fRange=fNewRange;
index=i;
}
}
return index;
}
go2Button(id, ent=-1){
if(ent==-1)
ent=gInMenu[id];
ent=gEnt[ent];
if(!pev_valid(ent)){
client_print(id, print_center, "%L",id,"NOTARGET");
return;
}
new Float:fOrigin[3];
fm_get_brush_entity_origin(ent, fOrigin);
set_pev(id, pev_origin, fOrigin);
client_print(id, print_chat, "PS. No Clip :)");
}
//FreeRun
public cmdVoteFreeRun(id){
if(get_pcvar_num(gcvarFreeRun)==0){
ColorChat(id, "!y[!gFreeRun!y]!team %L",id,"FREERUN_DISABLED");
return PLUGIN_HANDLED;
}
if(gbVote){
ColorChat(id, "!y[!gFreeRun!y]!team %L",id,"FREERUN_VOTE_IS_NOW");
return PLUGIN_HANDLED;
}
if(!is_user_alive(id)){
client_print(id, print_center, "%L",id, "MUST_B_ALIVE");
return PLUGIN_HANDLED;
}
if(get_pcvar_num(gcvarPrivilege)!=0 && !gbFreeRun && get_user_team(id)==1){
ColorChat(id, "!y[!gFreeRun!y]!team %L",id,"FREERUN_TT_DECIDED");
makeFreeRun(true);
return PLUGIN_HANDLED;
}
new iLimit=get_pcvar_num(gcvarLimit);
new iOffset=0;
if(get_pcvar_num(gcvarLimitMode)){
iOffset = ( giTime + iLimit * 60 )  - get_systime();
if( iOffset > 0 ){
ColorChat(id, "!y[!gFreeRun!y]!team %L",id,"FREERUN_NEXT_VOTE_TIME", iOffset/60, iOffset%60);
return PLUGIN_HANDLED;
}
}
else{
iOffset =  min(MAX_ROUNDS, iLimit) - giRounds;
if( iOffset > 0 ){
ColorChat(id, "!y[!gFreeRun!y]!team %L",id,"FREERUN_NEXT_VOTE_ROUNDS", iOffset);
return PLUGIN_HANDLED;
}
}

makeVote();
return PLUGIN_CONTINUE;
}
//FREERUN
public makeVote(){
giVoteTime=get_pcvar_num(gcvarFRVoteTime);
gbVote=true;
giVoteStart=get_systime();
set_task(float(giVoteTime), "resultsOfVote", TASK_RES);
new Players[32], playerCount;
new id;
get_players(Players, playerCount);
for (new i=0; i<playerCount; i++){
id = Players[i]; 
eventInGame(id);
}

}
public resultsOfVote(tid){
gbVote=false;

new giVotesOn=count(VOTE_ON);
new giVotesOff=count(VOTE_OFF);

ColorChat(0, "!y[!gFreeRun!y]!team %L %L(%d) vs %L(%d)",LANG_SERVER,"FREERUN_RESULTS",LANG_SERVER,"YES",giVotesOn,LANG_SERVER,"NO", giVotesOff);

if( giVotesOn == giVotesOff ){
ColorChat(0,"!y[!gFreeRun!y]!team %L",LANG_SERVER,"FREERUN_TIE");
return;
}
makeFreeRun((giVotesOn > giVotesOff));
ColorChat(0,"!y[!gFreeRun!y]!team %L ^x03%L",LANG_SERVER,"FREERUN_WINOPTION",LANG_SERVER, gbFreeRun?"YES":"NO");
}
makeFreeRun(bool:bFR=true){
gbFreeRun=bFR;
reset();
giRounds=0;
giTime=get_systime();

if(gbFreeRun){
set_pcvar_string(PcvarMode, "FreeRun")
set_hudmessage(0, 255, 255, 0.02, -1.0);
show_hudmessage(0, "FreeRun!");
}

}
count(VOTE_STATE){
new iCounter=0;
for(new i=1;i<33;i++)
if(giVotes[i][VOTE_STATE])
iCounter++;
return iCounter;
}
reset(){
for(new i=1;i<33;i++){
giVotes[i][VOTE_ON]=0;
giVotes[i][VOTE_OFF]=0;
}
}
public show_menu_(tid){
new id=tid-TASK_SHOWMENU;
new iTeam=get_user_team(id);
new menu_id, keys;
new menuUp = player_menu_info( id, menu_id, keys );
// Only display menu if another isn't shown
if ( iTeam && (menuUp <= 0 || menu_id < 0) ){
new iTime=get_pcvar_num(gcvarFRVoteTime);
new iOffset=get_systime()-giVoteStart;
iTime-=iOffset;
new szMenu[128];
formatex(szMenu, 127, "%L^n^n1. %L^n2. %L",id,"FREERUN_VOTEMENU",id,"YES",id,"NO");
show_menu(id, KeysFFVote, szMenu, iTime, "FRVote");
}else
set_task(1.0, "show_menu_", tid);
}
public eventInGame(id){
if(giVotes[id][VOTE_ON] || giVotes[id][VOTE_OFF])
return;
if(gbVote)
set_task(1.0, "show_menu_", id+TASK_SHOWMENU);
}
public PressedFRVote(id, key) {
if(gbVote==false) return;
switch (key) {
case VOTE_ON: { // 1
giVotes[id][VOTE_ON]=1;
}
case VOTE_OFF: { // 2
giVotes[id][VOTE_OFF]=1;
}
default:{
return;
}
}
new szName[32];
get_user_name(id, szName, 31);
client_print(0, print_chat, "* %L",LANG_PLAYER,(key==VOTE_ON)?"VOTED_FOR":"VOTED_AGAINST", szName);
}

stock Create_TE_BEAMPOINTS(Float:start[3], Float:end[3], iSprite, startFrame, frameRate, life, width, noise, red, green, blue, alpha, speed){
message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
write_byte( TE_BEAMPOINTS )
write_coord( floatround(start[0]) )
write_coord( floatround(start[1]) )
write_coord( floatround(start[2]) )
write_coord( floatround(end[0]) )
write_coord( floatround(end[1]) )
write_coord( floatround(end[2]) )
write_short( iSprite )			// model
write_byte( startFrame )		// start frame
write_byte( frameRate )			// framerate
write_byte( life )				// life
write_byte( width )				// width
write_byte( noise )				// noise
write_byte( red)				// red
write_byte( green )				// green
write_byte( blue )				// blue
write_byte( alpha )				// brightness
write_byte( speed )				// speed
message_end()
}

stock Kill(id)
{
user_kill(id, 1)
return PLUGIN_CONTINUE
} 