// no g_Gamemode 
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <ujbm>
#include <vip_base>
#include <nvault>
#include <xs>

#define PLUGIN_NAME    "Skills Mod"
#define PLUGIN_AUTHOR    "Mister X"
#define PLUGIN_VERSION    "1.0"
#define PLUGIN_CVAR    "Skills Mod"
#define SERVER_IP "93.119.25.96"

#define NO_RECOIL_WEAPONS_BITSUM  (1<<2 | 1<<CSW_KNIFE | 1<<CSW_HEGRENADE | 1<<CSW_FLASHBANG | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)
#define BASE_COUNTER_CAMO 30
#define BASE_COUNTER_HEAL 9
#define PEACETIME 45.0
#define DODGE_CHANCE 5 //DAVID


new const _WeaponsFree[][] = { "weapon_m4a1", "weapon_deagle", "weapon_g3sg1", "weapon_scout", "weapon_ak47", "weapon_mp5navy", "weapon_m3" }
new const _WeaponsFreeCSW[] = { CSW_M4A1, CSW_DEAGLE, CSW_G3SG1, CSW_SCOUT, CSW_AK47, CSW_MP5NAVY, CSW_M3 }
new const _WeaponsFreeAmmo[] = { 120, 70, 120, 120, 120, 300, 40 }

new weapons[31][10]={"None","P228","","Scout","HE","XM1014","C4",
    "MAC-10","AUG","Smoke","Elite","Fiveseven",
    "UMP45","SIG550","Galil","Famas","USP",
    "Glock","AWP","MP5","M249","M3","M4A1",
    "TMP","G3SG1","Flash","Deagle","SG552",
    "AK47","Knife","P90"}
    
enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
// HudSync: 0=ttinfo / 1=info / 2=ctinfo / 3=player / 4=center / 5=help / 6=timer
new const g_HudSync[][_hud] =
{
    {0,  0.46, 0.18, 5.0},
    {0,  0.74, 0.60, 5.0},
    {0,  0.74, 0.66, 5.0},
    {0,  0.74, 0.72, 5.0},
    {0,  0.74, 0.78, 5.0},
    {0,  0.74, 0.84, 5.0},
    {0, -1.0,  0.35, 5.0},
    {0, -1.0,  0.3,  5.0}
}

#define REFRESH_TIME 0.3

enum _:skills{
    PUTERE=1,   
    VITEZA,   
    CAMUFLAJ, 
    DEGHIZARE,
    SARITURA, 
    REZISTENTA,
    FURT,     
    INGHETARE,
    INFRAROSU,
    VINDECARE,
    INVIERE,  
    LACATUS,  
    RECUL,
    DODGE,
    SILENTIOS,
    ACURATETE,
    MAXSKILL
}

new const esp_colors[5][3]={{0,255,0},{100,60,60},{60,60,100},{255,0,255},{128,128,128}}

new g_PlayerSkill [MAX_PLAYERS+1][MAXSKILL]
new g_PlayerPoints[MAX_PLAYERS+1][2]
new bool:g_PlayerRevived[MAX_PLAYERS+1]

new const g_Prices[] = { 5, 10, 15, 20, 25, 30, 35, 40} //  5, 10, 15, 20, 25, 30, 35, 40
new const g_Alpha[] =  { 255, 140, 80, 15, 0}
new const Float:g_Gravity[] = { 1.0, 0.8125, 0.625, 0.4375, 0.25}
new const g_maxhp[] = { 100, 125, 150, 200, 300}
new const Float:g_freezet[] = {0.0, 0.5, 1.0, 1.5, 2.0}

new laser

new g_IsDisguise[MAX_PLAYERS+1];
new g_UsedDisguise[MAX_PLAYERS+1];
new g_UsedThief[MAX_PLAYERS+1];
new bool:g_Players4[MAX_PLAYERS+1];
new g_IsCamo[MAX_PLAYERS+1];
new bool:g_UseInfra[MAX_PLAYERS+1];
new origins[MAX_PLAYERS+1][3], tmp_origin[3], counter[MAX_PLAYERS+1];
new g_Killed[MAX_PLAYERS+1];
new g_Simon;
new g_Duel;
new g_Gamemode;
new g_PeaceTime;
new g_DayOfTheWeek;
new bool:ShowAc [MAX_PLAYERS+1]
new bool:firstRound = false

new Float:cl_pushangle[MAX_PLAYERS+1][3]

new myVault
enum _:_vip { _name[100], _pass[100], _sk[20]}
new Vip[100][_vip]
new MaxVip
new IsVip[MAX_PLAYERS+1]

new Resetused[MAX_PLAYERS+1]

enum _:_arg { _nume[100], _skill[MAXSKILL], _points[2] }
new Leaved[200][_arg]
new TotalSaved
new gp_SpecialVip

public plugin_init ()
{
    new ip[36];
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    get_user_ip(0,ip,35,0);
    if(equal(ip,SERVER_IP))
    {
        return PLUGIN_CONTINUE;
    }
    LoadVips()
    
    register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
    RegisterHam(Ham_TakeDamage, "player", "player_damage")
    RegisterHam(Ham_Killed, "player", "player_killed")
    RegisterHam(Ham_TraceAttack, "func_door_rotating", "cmd_picklock") 
    RegisterHam(Ham_TraceAttack, "func_door", "cmd_picklock")
    
    new weapon_name[20]
    for (new i=CSW_P228;i<=CSW_P90;i++) 
    {         
        if(!(NO_RECOIL_WEAPONS_BITSUM & (1<<i)) && get_weaponname(i, weapon_name, charsmax(weapon_name))) 
        { 
            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_primary_attack")
            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_primary_attack_post",1) 
        } 
    }
    
    register_dictionary("skills.txt")
    register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
    register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
    register_logevent("round_end", 2, "1=Round_End")
    register_clcmd("disguise","cmd_disguise")
    register_clcmd("thief","cmd_thief")
    register_clcmd("infrared","cmd_infrared")
    register_clcmd("showac","cmd_showac")
    register_clcmd("say /points", "cmd_showpoints")
    register_clcmd("say /skill", "cmd_player_skill")
    register_clcmd("say /akunamamta","cmd_cheater")
    register_clcmd("say /levelnoua","cmd_level4")
    register_clcmd("say /skillhelp","cmd_help")
    register_clcmd("say /top","cmd_top")
    register_clcmd("say /list","cmd_list")
    register_clcmd("say /rskill","cmd_askreset")
    register_clcmd("say /damipomanatati","_give_points_all")
    register_concmd("amx_reload_skills", "cmd_reload_skills_all", ADMIN_RCON, "Reloads all skills" );
    register_srvcmd("give_points","_give_points")
    new skillh = register_cvar("skill_help", "1")
    gp_SpecialVip = register_cvar("special_vip","0")
    register_concmd("amx_addpoints","admin_points",ADMIN_LEVEL_E,"<nick> <Points to give>")
    register_concmd("amx_skills","admin_verify_skills",ADMIN_ALL,"<nick> # Verify a player's skills")
    myVault = nvault_open("vipskills")
    if (myVault == INVALID_HANDLE) log_amx("Failed loading the vault")
    //for(new i = 0; i < sizeof(g_HudSync); i++)
    //    g_HudSync[i][_hudsync] = CreateHudSyncObj()
    set_task(REFRESH_TIME, "check_players", _, _, _, "b")
    if(skillh == 1)
        set_task(120.0, "helps", _, _, _, "b")
    return PLUGIN_CONTINUE
}

public _give_points (id,level,cid)
{
    new ids[3],points[3]
    read_argv(1, ids, 2)
    read_argv(2, points, 2)
    
    add_points(str_to_num(ids),str_to_num(points))
}

public _give_points_all (id,level,cid)
{
    new points[3]
    read_argv(1, points, 2)
    
    for(new i =1;i<=MAX_PLAYERS;i++)
    {
        if(is_user_connected(i))
        {
            add_points(i,str_to_num(points))
        }
    }
    
}

public LoadVips ()
{
    new file[250]
    new data[250], len, line = 0,id
    
    get_configsdir(file, 249)
    format(file, 249, "%s/skill.ini", file)
    if(file_exists(file))
    {
        while((line = read_file(file , line , data , 249 , len) ) != 0 )
        {
            if ((data[0] == ';') || equal(data, "")) continue
            parse(data,Vip[id][_name],99,Vip[id][_pass],99,Vip[id][_sk],19)
            //log_amx(data)
            //log_amx("a fost incarcat %s cu parola %s, %s",Vip[id][_name],Vip[id][_pass],Vip[id][_sk])
            id++
        }
        log_amx("%d Vip cu skills au fost incarcati",id)
        MaxVip = id
    }
    else
        log_amx("fisierul %s nu exista",file)
}

public plugin_precache(){
    laser=precache_model("sprites/laserbeam.spr") 
}

public client_putinserver(id)
{
    reload_skills(id)
}

public cmd_reload_skills_all(id, level, cid )
{
    if( !cmd_access( id, level, cid, 1 ) )
    return PLUGIN_HANDLED;
    
    reload_skills_all();
    
    return PLUGIN_HANDLED;
}

public reload_skills_all()
{
    for(new i =1;i<=MAX_PLAYERS;i++)
        if(is_user_connected(i))
            reload_skills(i);
}

public reload_skills(id)
{
    for(new j = 0; j < MAXSKILL; j++)
        g_PlayerSkill[id][j] = 0
    g_PlayerPoints[id][0] = 0
    g_PlayerPoints[id][1] = 0
    g_IsDisguise[id] = 0
    g_UsedDisguise[id] = 0
    g_UsedThief[id] = 0
    g_Players4[id] = false
    g_PlayerRevived[id] = false
    g_UseInfra[id] = false
    g_Killed[id] = 0
    ShowAc[id] = false
    IsVip[id] = 0
    Resetused[id] = false
    set_user_rendering(id)
    set_user_footsteps(id,0)
    if(firstRound == false)
    {
        if(get_pcvar_num(gp_SpecialVip)!=0)
            load_vip_special(id)
        else
        {
            load_vip(id)
            new name[100]
            get_user_name(id,name,99)
            for(new id2 = 0; id2<TotalSaved;id2++)
                if(equal(name,Leaved[id2][_name])){
                    for(new i = 1; i<MAXSKILL; i++){
                        g_PlayerSkill[id][i] = Leaved[id2][_skill + i];
                    }
                    g_PlayerPoints[id][0] = Leaved[id2][_points];
                    g_PlayerPoints[id][1] = Leaved[id2][_points+1];
                    break;
                }
        }
    }
}
public client_infochanged( id )
{
    if (is_user_connected(id))
    {
        load_vip(id)
    }
}
public load_vip (id)
{
    new name[100],pass[100]
    get_user_name(id,name,99)
    for(new i = 0;i<MaxVip;i++)
    {
        if(equal(name,Vip[i][_name])){
            get_user_info(id,"_skill",pass,99)
            if(strlen(Vip[i][_pass]) == 0 || equal(pass,Vip[i][_pass])){
                new string[20]
                formatex(string,19,"%s",Vip[i][_sk])
                if(strlen(string)>0){
                    for(new j=0;j<strlen(string);j++){
                        new skil = string[j]-'a' + 1
                        switch(skil){
                            case 1..6,8,10:g_PlayerSkill[id][skil] = 3
                            case 7,9,11,12:g_PlayerSkill[id][skil] = 2
                            case 13:g_PlayerSkill[id][skil]=1
                            default: continue
                        }
                    }
                }else{
                    getData(id)
                }
                IsVip[id] = i+1
                log_amx("%s a fost logat ca Vip Skill",name)
                //client_print(id,print_chat,"Skillurile tale salvate au fost incarcate, distractie placuta")
            }
        }
    }
}
public load_vip_special (id)
{
    new limit[15]
    if(get_pcvar_num(gp_SpecialVip)==2)
        formatex(limit,14,"abcdefghijklm")
    else
        formatex(limit,14,"abef")
        
    for(new j=0;j<strlen(limit);j++){
        new skil = limit[j]-'a' + 1
        switch(skil){
            case 1..6,8,10:g_PlayerSkill[id][skil] = 3
            case 7,9,11,12:g_PlayerSkill[id][skil] = 2
            case 13:g_PlayerSkill[id][skil]=1
            default: continue
        }
    }
}
public save_vip(id)
{
    if(IsVip[id]>0){
        new string [20]
        formatex(string,19,"%s",Vip[IsVip[id]-1][_sk])
        if(strlen(string)<=0){
            setData(id)
            return
        }
    }
    new ok = 0,name[100]
    get_user_name(id, name, 99)
    for(new id2 = 0; id2<TotalSaved;id2++)
    if(equal(name,Leaved[id2][_nume])){
        ok = 1
        for(new i = 1; i<MAXSKILL;i++)
        Leaved[id2][_skill + i] = g_PlayerSkill[id][i];
        Leaved[id2][_points] = g_PlayerPoints[id][0]
        Leaved[id2][_points + 1] = g_PlayerPoints[id][1]
        break;
    }
    if(ok==0){
        get_user_name(id, Leaved[TotalSaved][_nume], 99)
        for(new i = 1; i<MAXSKILL;i++)
        Leaved[TotalSaved][_skill+i]=g_PlayerSkill[id][i];
        Leaved[TotalSaved][_points] = g_PlayerPoints[id][0]
        Leaved[TotalSaved][_points + 1] = g_PlayerPoints[id][1]
        TotalSaved++;
    }
}

public client_disconnect (id)
{
    if(get_pcvar_num(gp_SpecialVip)==0)
        save_vip(id)
}
public setData(player) {
    
    if (myVault == INVALID_HANDLE) return PLUGIN_CONTINUE
    
    new name[35]
    get_user_name(player, name, 34)
    
    new vaultkey[50], data[200]
    format(vaultkey, 49, "skill.%s",name)

    new Len = 0
    for(new i = 1; i < MAXSKILL; i++)
        Len += format(data[Len], (sizeof data - 1) - Len,"%d, ",g_PlayerSkill[player][i]);
    
    Len += format(data[Len], (sizeof data - 1) - Len,"%d, %d",g_PlayerPoints[player][0],g_PlayerPoints[player][1]);
    
    nvault_pset(myVault, vaultkey, data)

    return PLUGIN_CONTINUE
}
stock getData(player) {
    // Crash für den Compiler
    // if (myVault == INVALID_HANDLE) return "empty"
    
    new name[35]
    get_user_name(player, name, 34)
    
    new vaultkey[50]
    format(vaultkey, 49, "skill.%s", name)
    
    new vaultdata[200],num[100]
    nvault_get(myVault, vaultkey, vaultdata, 199)
    //log_amx(vaultdata)
    for(new i = 1; i<MAXSKILL;i++)
    {
        strtok(vaultdata,num,99,vaultdata,199,',')
        g_PlayerSkill[player][i]=str_to_num(num)
    }
    strtok(vaultdata,num,99,vaultdata,199,',')
    g_PlayerPoints[player][0]=str_to_num(num)
    g_PlayerPoints[player][1]=str_to_num(vaultdata)
    
}
public helps ()
{
    new Msg[512];
    new number = random_num(0,4)
    if(number==0)
        format(Msg, 511, "^x01Scrie ^x03/skillhelp^x01 pentru nelamuriri fata de skilluri");
    else if(number == 1)
        format(Msg, 511, "^x01Scrie ^x03showac^x01 in consola pentru a afisa de ce ai luat puncte");
    else if(number == 2)
        format(Msg, 511, "^x01Scrie ^x03/top^x01 ca sa vezi topul cu cei care au cele mai multe puncte de skill");
    else if(number == 3)
        format(Msg, 511, "^x01Scrie ^x03/rskill^x01 ca sa iti resetezi skilurile");
    new iPlayers[32], iNum, i;
    get_players(iPlayers, iNum);
    for(i = 0; i <= iNum; i++)
    {
        new x = iPlayers[i];
        
        if(!is_user_connected(x) || is_user_bot(x)) continue;
        message_begin( MSG_ONE, get_user_msgid("SayText"), {0,0,0}, x );
        write_byte  ( x );
        write_string( Msg );
        message_end ();
        
        save_vip(i);
    }
    return PLUGIN_CONTINUE
}
public cmd_help(id)
{
    show_motd(id,"<html><body><iframe src=^"http://fc03.deviantart.net/fs70/f/2013/124/2/8/skills_by_ieclipsei-d645cxs.png^" width=^"100%%^" height=^"100%%^" scrolling=^"yes^"></iframe></body></html>","Skills help");
    return PLUGIN_HANDLED
}
public cmd_showpoints(id)
{
    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_POINTS",g_PlayerPoints[id][0])
    return PLUGIN_HANDLED
}
public cmd_list (id)
{
    new Msg[2049],Len = 0;
    Len += format(Msg[Len], 2048 - Len,"<html><body style=^"background-color:black;color:white^"><table width=^"100%%^"><tr align=^"center^"><th>Nume</th><th>Skilluri</th></tr>")
    new Players [32],inum;
    new name[256],lvip
    get_players(Players,inum)
    for(new pl=0;pl<inum;pl++){
        new player = Players[pl]
        if(IsVip[player] != 0){
            lvip = IsVip[player] - 1
            get_user_name(player,name,255)
            Len += format(Msg[Len], 2048 - Len,"<tr align=^"center^"><td>%s</td><td>",name)
            if(strlen(Vip[lvip][_sk])>0)
                Len += format(Msg[Len], 2048 - Len,"%s</td></tr>",Vip[lvip][_sk])
            else
                Len += format(Msg[Len], 2048 - Len,"Full skills</td></tr>")
        }
        if(get_vip_type(player)){
            get_user_name(player,name,255)
            Len += format(Msg[Len], 2048 - Len,"<tr align=^"center^"><td>%s</td><td>Vip JB %d</td></tr>",name,get_vip_type(player))
        }
    }
    Len += format(Msg[Len], 2048 - Len,"</table></body></html>")
    //write_file("help.txt",Msg,0)
    show_motd(id,Msg,"Vip list")
    return PLUGIN_HANDLED
}
public cmd_top (id)
{
    new Msg[2049],Len = 0;
    Len += format(Msg[Len], 2048 - Len,"<html><body style=^"background-color:black;color:white^"><table width=^"100%%^"><tr><th>Nume</th><th>Puncte</th><th>Skilluri</th>")
    new Players [32],inum;
    get_players(Players,inum)
    static bool:PlayerAp[MAX_PLAYERS+1]
    for(new i=0; i<=MAX_PLAYERS;i++)
        PlayerAp[i]=false
    for(new times=0;times<inum;times++){
        new plmax=0,maxim=-1;
        for(new pl=0;pl<inum;pl++){
            new player = Players[pl]
            if(PlayerAp[player] == false){
                if(maxim<g_PlayerPoints[player][1] || maxim==g_PlayerPoints[player][1] && g_PlayerPoints[plmax][0]>g_PlayerPoints[player][0]){
                    plmax=player;
                    maxim=g_PlayerPoints[player][1]
                }    
            }
        }
        PlayerAp[plmax]=true
        new name[256]
        get_user_name(plmax,name,255)
        Len += format(Msg[Len], 2048 - Len,"<tr><td>%s</td><th>%d</th><th>",name,g_PlayerPoints[plmax][0])
        for(new skil = 1;skil<=MAXSKILL;skil++)
            Len += format(Msg[Len], 2048 - Len,"%d ",g_PlayerSkill[plmax][skil])
        Len += format(Msg[Len], 2048 - Len,"</th></tr>")
    }
    Len += format(Msg[Len], 2048 - Len,"</table></body></html>")
    //write_file("help.txt",Msg,0)
    show_motd(id,Msg,"Skill Top")
    return PLUGIN_HANDLED
}
public cmd_askreset (id)
{
    if(g_PlayerPoints[id][1]!=g_PlayerPoints[id][0] && Resetused[id] == 0){
        askwhy(id,"cmd_reset","%L",LANG_SERVER, "SKILLS_RESET");
        //client_print(id,print_chat,"tea intrebat");
    }
    else
        client_print(id,print_chat,"Nu poti reseta");
    return PLUGIN_CONTINUE
}
public cmd_reset (id, menu, item)
{
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    if(data[0]=='1')
    {
        for(new j = 0; j < MAXSKILL; j++)
            g_PlayerSkill[id][j] = 0
        g_PlayerPoints[id][0] = g_PlayerPoints[id][1]
        if(is_user_alive(id))
        {    
            set_user_rendering(id)
            if(g_IsDisguise[id] == 1 && is_skills_ok())
            {
                set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
                set_user_info(id, "model", "jbbossi_temp")
                entity_set_int(id, EV_INT_body, 3+random_num(1,2))
            }
        }
        set_user_footsteps(id,0)
        g_IsDisguise[id] = 0
        g_UseInfra[id] = false
        g_Killed[id] = 0
        Resetused[id] ++ 
        load_vip(id)//load_vip_special(id)
    }
    return PLUGIN_HANDLED
}
stock askwhy(id, callback[], title[], any:...)
{
    static option[32], menu, menuname[32]
    vformat(menuname, charsmax(menuname), title, 4)
    menu = menu_create(menuname, callback)
    
    formatex(option, charsmax(option), "Da")
    menu_additem(menu, option, "1", 0)

    formatex(option, charsmax(option), "Nu")
    menu_additem(menu, option, "2", 0)
    
    menu_display(id, menu)
}
public check_players ()
{
    g_Simon = get_simon()
    g_Duel = get_duel()
    g_Gamemode = get_gamemode()
    new Players [32],inum;
    get_players(Players,inum,"a")
    for(new i=0; i<inum; i++)
    {
        new player = Players[i]
        if((g_PlayerSkill[player][CAMUFLAJ] != 0 && cs_get_user_team(player) == CS_TEAM_T) || (g_PlayerSkill[player][VINDECARE]!=0 && cs_get_user_team(player)== CS_TEAM_CT)){
            get_user_origin(player, tmp_origin)
            if(tmp_origin[0] == origins[player][0] &&  tmp_origin[1] == origins[player][1] && tmp_origin[2] == origins[player][2] && is_skills_ok() && get_user_weapon(player) == CSW_KNIFE){
                counter[player]++ //player has not moved since last check
                if(counter[player] >= BASE_COUNTER_CAMO - g_PlayerSkill[player][CAMUFLAJ]*6  && cs_get_user_team(player)== CS_TEAM_T){  //player was not moving during last HEAL_INTERVAL seconds
                    if(counter[player] == BASE_COUNTER_CAMO - g_PlayerSkill[player][CAMUFLAJ]*6){
                        set_user_rendering(player, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, g_Alpha[g_PlayerSkill[player][CAMUFLAJ]]);
                        g_IsCamo[player]=1;
                    }
                    client_print(player, print_center, "%L", LANG_SERVER, "SKILLS_CAMO_DONE");    
                }
                if(counter[player] >= BASE_COUNTER_HEAL && cs_get_user_team(player)== CS_TEAM_CT && get_user_health(player) < g_maxhp[g_PlayerSkill[player][VINDECARE]] && is_skills_ok()){  //player was not moving during last HEAL_INTERVAL seconds
                    new health = get_user_health(player)
                    if(health + g_PlayerSkill[player][VINDECARE]> g_maxhp[g_PlayerSkill[player][VINDECARE]])
                        set_user_health(player, g_maxhp[g_PlayerSkill[player][VINDECARE]])
                    else
                        set_user_health(player, health + g_PlayerSkill[player][VINDECARE])
                    client_print(player, print_center, "%L", LANG_SERVER, "SKILLS_HEALING_DONE");    
                }
            }else{
                counter[player] = 0 //player has moved since last check
                if(cs_get_user_team(player) == CS_TEAM_T){
                    set_user_rendering(player)
                    g_IsCamo[player]=0
                }
                origins[player][0] = tmp_origin[0]
                origins[player][1] = tmp_origin[1]
                origins[player][2] = tmp_origin[2]
            }
        }
        if((g_PlayerSkill[player][INFRAROSU] == 1 && g_UseInfra[player] == true || g_PlayerSkill[player][INFRAROSU] == 2) && is_skills_ok() && cs_get_user_team(player) == CS_TEAM_CT){
            new spec_id=player, Float:my_origin[3], Float:smallest_angle=180.0, smallest_id=0, Float:xp=2.0,Float:yp=2.0
            entity_get_vector(player,EV_VEC_origin,my_origin)
            
            new Targets[32],inum2;
            get_players(Targets,inum2,"a")
            for (new s=0;s<inum2;s++){
                new target = Targets[s]
                if (g_IsCamo[target]==0){
                    new target_team
                    if(cs_get_user_team(target)==CS_TEAM_T)
                        target_team = 1
                    else
                        target_team = 2
                    if (!(cs_get_user_team(target)==CS_TEAM_SPECTATOR)){ 
                        if (spec_id!=target){ 
                            new Float:target_origin[3]
                            entity_get_vector(target,EV_VEC_origin,target_origin)
                            new Float:distance=vector_distance(my_origin,target_origin)
                            new Float:v_middle[3]
                            subVec(target_origin,my_origin,v_middle)
                            new Float:v_hitpoint[3]
                            trace_line (-1,my_origin,target_origin,v_hitpoint)
                            new Float:distance_to_hitpoint=vector_distance(my_origin,v_hitpoint)
                            new Float:scaled_bone_len
                            scaled_bone_len=distance_to_hitpoint/distance*50.0
                            new Float:scaled_bone_width=distance_to_hitpoint/distance*150.0
                            new Float:v_bone_start[3],Float:v_bone_end[3]
                            new Float:offset_vector[3]
                            normalize(v_middle,offset_vector,distance_to_hitpoint-10.0)
                            new Float:eye_level[3]
                            copyVec(my_origin,eye_level)
                            eye_level[2]+=17.5
                            addVec(offset_vector,eye_level)
                            copyVec(offset_vector,v_bone_start)
                            copyVec(offset_vector,v_bone_end)
                            v_bone_end[2]-=scaled_bone_len
                            new Float:distance_target_hitpoint=distance-distance_to_hitpoint
                            new actual_bright=255
                            if (distance_target_hitpoint<510.0){    
                                actual_bright=(255-floatround(distance_target_hitpoint/12.0))
                            }
                            new color
                            if (distance_to_hitpoint!=distance){
                                color=0
                            }else{
                                color = target_team
                            }
                            if(distance_target_hitpoint<255.0*g_PlayerSkill[player][INFRAROSU]){
                                if(g_UseInfra[player]== true)
                                    make_TE_BEAMPOINTS(player,color,v_bone_start,v_bone_end,floatround(scaled_bone_width),target_team,actual_bright)
                                if(g_PlayerSkill[player][INFRAROSU] == 2){
                                    new Float:ret[2]
                                    new Float:x_angle=get_screen_pos(spec_id,v_middle,ret)
                                    if (smallest_angle>floatabs(x_angle)){
                                            if (floatabs(x_angle)!=0.0){
                                                smallest_id=target 
                                                xp=ret[0] 
                                                yp=ret[1]
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(g_PlayerSkill[player][INFRAROSU] == 2 && smallest_id>0 && smallest_id<=MAX_PLAYERS)
            {
                set_hudmessage(255, 255, 0, floatabs(xp), floatabs(yp), 0, 0.0, REFRESH_TIME, 0.0, 0.0)
                new guns[32], weapon[2]
                new numWeapons = 0, j
                get_user_weapons(smallest_id, guns, numWeapons)
                for (j=0; j<numWeapons; j++)
                {
                    switch(guns[j])
                    {
                        case 3,5,7,8,12,15,18..24,27,28,30:weapon[0]=guns[j]
                        case 1,10,11,16,17,26:weapon[1]=guns[j]
                    }
                }
                show_hudmessage(player, "P:%s^nS:%s",weapons[weapon[0]],weapons[weapon[1]])
            }
        }
    }
    return PLUGIN_CONTINUE
}
public client_PreThink(id)
{
    if(is_user_alive(id) && is_skills_ok()){
        if(g_PlayerSkill[id][VITEZA]!=0){
            //if(get_user_button(id) & IN_FORWARD)
                set_user_maxspeed(id, 250.0 + g_PlayerSkill[id][VITEZA] * 30 )
            //else if(!(get_user_button(id) & IN_FORWARD))
            //    set_user_maxspeed(id, 250.0)
        }
        if(g_PlayerSkill[id][SARITURA]!=0){
            if(get_user_button(id) & IN_JUMP)
                set_user_gravity(id, g_Gravity[g_PlayerSkill[id][SARITURA]])
            if( entity_get_float(id, EV_FL_flFallVelocity) > 0){
                set_user_gravity(id, 1.0)
            }
        }
    }    
}
public cmd_disguise (id)
{
    if (!is_user_alive(id) || g_PlayerSkill[id][DEGHIZARE]== 0 || !is_skills_ok() || cs_get_user_team(id) != CS_TEAM_T)
        return PLUGIN_HANDLED
        
    new player_origin[3],player_origins[3], players[MAX_PLAYERS], inum=0, dist, last_dist=99999, last_id
    
    get_user_origin(id,player_origin,0)
    get_players(players,inum,"b")
    if (inum>0) {
        for (new i=0;i<inum;i++) {
            if (players[i]!=id && cs_get_user_team(players[i]) == CS_TEAM_CT) {
                get_user_origin(players[i],player_origins,0)
                dist = get_distance(player_origin,player_origins)
                if (dist<last_dist) {
                    last_id = players[i]
                    last_dist = dist
                }
            }
        }
        if (last_dist<80) {
            if(g_UsedDisguise[last_id] == 0 && g_IsDisguise[id] == 0){
                set_pev(id, pev_flags, pev(id, pev_flags)| FL_FROZEN)
                g_UsedDisguise[last_id] = 1
                g_IsDisguise[id] = 1
                set_task(10.0 - g_PlayerSkill[id][DEGHIZARE] * 2,"disguise_done", 3900 + id);
            }else{
                client_print(id,print_center,("Hainele i-au fost luate deja"))
                return PLUGIN_HANDLED
            }
        }else{
            client_print(id,print_center,("Nu sunt corpuri in preajma"))
            return PLUGIN_HANDLED
        }
    }
    return PLUGIN_HANDLED
}

bool:is_skills_ok()
{
	if((g_Gamemode == Freeday || g_Gamemode == NormalDay) && g_Duel<2 && g_DayOfTheWeek%7!=6)
		return true
	return false
}

public disguise_done (id)
{
    if(id > MAX_PLAYERS)
        id -= 3900
    
    remove_task(3900 + id)
    
    if(g_IsDisguise[id] == 1 && is_skills_ok())
    {
        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
        set_user_info(id, "model", "jbbossi_temp")
        entity_set_int(id, EV_INT_body, 4)
        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_DIGUISE_DONE")
    }
}
public unfreeze (id)
{
    if(id > MAX_PLAYERS)
        id -= 5300
    
    remove_task(5300 + id)
    
    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
}

public cmd_thief (id)
{
    if (!is_user_alive(id)|| !is_skills_ok() || g_PlayerSkill[id][FURT]== 0 || cs_get_user_team(id) != CS_TEAM_T || g_PeaceTime == 1)
        return PLUGIN_HANDLED
        
    new player_origin[3],player_origins[3], players[32], inum=0, dist, last_dist=99999, last_id
    
    get_user_origin(id,player_origin,0)
    get_players(players,inum,"a")
    if (inum>0) {
        for (new i=0;i<inum;i++) {
            if (players[i]!=id) {
                get_user_origin(players[i],player_origins,0)
                dist = get_distance(player_origin,player_origins)
                if (dist<last_dist) {
                    last_id = players[i]
                    last_dist = dist
                }
            }
        }
        if (last_dist<80) {
            if(g_UsedThief[last_id] < 2){
                if(random_num(0,(3 + g_UsedThief[last_id] - g_PlayerSkill[id][FURT])*2) == 0){
                    g_UsedThief[last_id] ++
                    new money = 1500 * g_PlayerSkill[id][FURT]
                    new money1 =  cs_get_user_money(id)
                    new money2 = cs_get_user_money(last_id)
                    if(money > money2)
                        money = money2
                    cs_set_user_money(id,money+money1)
                    cs_set_user_money(last_id,money2-money)
                    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_THIEF_DONE",money)
                    if(cs_get_user_team(last_id)== CS_TEAM_CT){
                        if(random_num(0,(g_PlayerSkill[id][FURT]+1))==0){
                            set_wanted(id)
                            client_print(id, print_center, "%L", LANG_SERVER,"SKILLS_THIEF_CAUGHT")
                        }
                    }else
                        if(random_num(0,(g_PlayerSkill[id][FURT]+2))==0){
                            set_wanted(id)
                            client_print(id, print_center, "%L", LANG_SERVER,"SKILLS_THIEF_CAUGHT")
                        }
                }else{
                    if(random_num(0,g_PlayerSkill[id][FURT])==0)
                        g_UsedThief[last_id] ++
                    client_print(id, print_center,"%L", LANG_SERVER, "SKILLS_THIEF_LOSE",(3 + g_UsedThief[last_id] - g_PlayerSkill[id][FURT])*2)
                }
            }else{
                client_print(id,print_center,("I-au fost luati bani deja"))
                return PLUGIN_HANDLED
            }
        }else{
            client_print(id,print_center,("Nu e nimeni in preajma"))
            return PLUGIN_HANDLED
        }
    }
    return PLUGIN_HANDLED
}
public cmd_askinfrared (id)
{
    askwhy(id,"cmd_menuinfrared","%L",LANG_SERVER, "SKILLS_ASKINFRARED");
}
public cmd_menuinfrared (id, menu, item)
{
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    if(data[0]=='1')
    {
        g_UseInfra[id] = true
        client_print(id, print_center, "INFRARED ON")
    }
    return PLUGIN_HANDLED
}
public cmd_infrared(id)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED
    if(g_UseInfra[id] == true){
        g_UseInfra[id] = false
        client_print(id, print_center, "INFRARED OFF")
    }
    else{
        g_UseInfra[id] = true
        client_print(id, print_center, "INFRARED ON")
    }
    return PLUGIN_CONTINUE
}
public cmd_showac(id)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED
    if(ShowAc[id] == true){
        ShowAc[id] = false
        client_print(id, print_center, "POINTS HELP OFF")
    }
    else{
        ShowAc[id] = true
        client_print(id, print_center, "POINTS HELP ON")
    }
    return PLUGIN_CONTINUE
}
public cmd_picklock(iEnt, id)
{
    if(!is_user_alive(id) || !is_skills_ok() || g_PlayerSkill[id][LACATUS]==0 || cs_get_user_team(id)!=CS_TEAM_T || cs_get_user_money(id)<500 || get_user_weapon(id)!=CSW_KNIFE ){
        return HAM_IGNORED
    }
    if(pev(iEnt,pev_iuser4)){
        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_PICKLOCK_CANT")
        return HAM_IGNORED
    }
    
    new money = cs_get_user_money(id);
    new arg[2]
    arg[0]=iEnt
    cs_set_user_money(id, money-500);
    set_pev(id, pev_flags, pev(id, pev_flags)| FL_FROZEN)
    set_task(10.0 - g_PlayerSkill[id][LACATUS]*2,"finish_picklocking",5100+id,arg,2)
    return HAM_HANDLED
}
public finish_picklocking(param[], id)
{
    if(id>32)
        id-=5100;
    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
    if(random_num(0,3-g_PlayerSkill[id][LACATUS])==0)
    {
        new iEnt
        iEnt = param[0]
        ExecuteHamB(Ham_Use,iEnt,0,0,1,1.0)
        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_PICKLOCK_DONE")
    }else{
        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_PICKLOCK_LOSE",3-(g_PlayerSkill[id][LACATUS]-1)/2)
    }
}

public revive (id)
{
    if(id>5300)
        id-=5300;
    if(is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_CT){
        ExecuteHamB(Ham_CS_RoundRespawn, id)
        dllfunc(DLLFunc_Spawn, id)
        give_item(id,"weapon_knife")
        if(g_PlayerSkill[id][INVIERE] >= 2){
            set_user_health(id, 150)
            new j = random_num(0, sizeof(_WeaponsFree) - 1)
            give_item(id, _WeaponsFree[j])
            cs_set_user_bpammo(id, _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
        }
        g_PlayerRevived[id] = true
        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_REVIVE_DONE");
    }
}

public player_spawn(id)
{
    if(!is_user_connected(id))
        return HAM_IGNORED    
    if(cs_get_user_team(id) == CS_TEAM_CT){
        g_UsedDisguise[id] = 0
        g_PlayerRevived[id] = false
    }else{
        if(g_PlayerSkill[id][DEGHIZARE] == 3 && g_IsDisguise[id] == 1)
            set_task(1.0 ,"disguise_done", 3900 + id);
        else
            g_IsDisguise[id] = 0
        if(g_PlayerSkill[id][SILENTIOS])
        {
            set_user_footsteps(id,1)
        }
    }
    Resetused[id] = 0
    g_UsedThief[id] = 0
    g_Killed[id] = 0
            
    return HAM_IGNORED
}
public return_peace()
{
    g_PeaceTime = 0;
}

public get_dayoftheweek()
{
    g_DayOfTheWeek = get_day()
}

public round_first()
{
    firstRound = true;
    reload_skills_all();
}

public round_end()
{
    static reload = 0;
    if(reload == 0){
        set_task(0.1,"round_end")
        g_PeaceTime = 1;
        set_task(PEACETIME,"return_peace");
        set_task(5.0,"get_dayoftheweek");
        reload = 1;
    }
    else{
        if(firstRound == true)
        {
            firstRound = false;
            reload_skills_all();
        }
        reload = 0;
        new Players[MAX_PLAYERS],playerCount, i, Talive=0, CTalive = 0, Ttotal = 0, CTtotal = 0;
        get_players(Players, playerCount)
        for (i=0; i<playerCount; i++) 
        {
            if(cs_get_user_team(Players[i])== CS_TEAM_T )
            {
                if(is_user_alive(Players[i]))
                    Talive++
                Ttotal++
            }else if(cs_get_user_team(Players[i])== CS_TEAM_CT)
            {
                if(is_user_alive(Players[i]))
                    CTalive++
                CTtotal++;
            }
        }
        get_players(Players, playerCount, "a") 
        for (i=0; i<playerCount; i++) 
        {
            if(cs_get_user_team(Players[i])== CS_TEAM_T )
            {
                new sum = 0;
                if(g_Killed[Players[i]] == CTtotal && CTtotal>1 && g_Duel!=2 && (g_Gamemode == Freeday || g_Gamemode == NormalDay)){
                    sum += CTtotal*2;
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+%d Spaima gardienilor",CTtotal*2);    
                }
                if(Talive == 1 && g_Duel!= 2)
                {
                    if((g_Gamemode == Freeday || g_Gamemode == NormalDay) && g_Killed[Players[i]]==0 && CTtotal>1){
                        sum+=10;
                        if(ShowAc[Players[i]]==true)
                            client_print(Players[i], print_chat, "+10 Ultimul in viata si nu esti rebel")
                    }else{
                        sum+=5
                        if(ShowAc[Players[i]]==true)
                            client_print(Players[i], print_chat, "+5 Ultimul in viata")
                    }
                }
                else if(g_Gamemode > NormalDay || g_Gamemode < Freeday ){
                    sum+=3;
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+3 Ai castigat un joc")
                }
                else if(Talive <= Ttotal/3){
                    sum+=2;
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+2 Ai ramas in viata")
                }
                if(sum!=0)
                    add_points(Players[i],sum);
            }
            else if(cs_get_user_team(Players[i])== CS_TEAM_CT)
            {
                if(g_Duel == 2){
                    add_points(Players[i],5)
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+5 Ai scapat de masacrul prizonierului")
                }else if(CTalive == 1){
                    add_points(Players[i],5)
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+5 Ultimul in viata")
                }else if(g_Gamemode > 1 || g_Gamemode<0){
                    add_points(Players[i],3)
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+3 Ai castigat un joc")
                }else{
                    add_points(Players[i],2)
                    if(ShowAc[Players[i]]==true)
                        client_print(Players[i], print_chat, "+2 Ai ramas in viata")
                }
            }
        }
    }
}


public fw_primary_attack(ent)
{
    new id = pev(ent,pev_owner)
    pev(id,pev_punchangle,cl_pushangle[id])
    
    return HAM_IGNORED
}

public fw_primary_attack_post(ent)
{
    new id = pev(ent,pev_owner)
    if(g_Gamemode == Freeday || g_Gamemode == NormalDay){
        new Float:push[3]
        pev(id,pev_punchangle,push)
        xs_vec_sub(push,cl_pushangle[id],push)
        xs_vec_mul_scalar(push,(1.0 - 0.5*g_PlayerSkill[id][RECUL]),push)
        xs_vec_add(push,cl_pushangle[id],push)
        set_pev(id,pev_punchangle,push)
    }
    return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
    if(!is_skills_ok())
        return HAM_IGNORED
    if(is_user_connected(attacker) && is_user_connected(victim)){
        if(damage / 100 >= 1 && get_user_weapon(attacker)==CSW_KNIFE && damage/100<3){
            new sum = floatround(damage)
            sum /= 100
            add_points(attacker,sum)
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat, "+%d pentru %.2f damage",sum,damage)
        }
        if(cs_get_user_team(attacker) == CS_TEAM_CT && get_user_weapon(attacker) == CSW_GLOCK18 && g_PlayerSkill[attacker][INGHETARE] > 0)
        {
            set_pev(victim, pev_flags, pev(victim, pev_flags)| FL_FROZEN)
            set_task(g_freezet[g_PlayerSkill[attacker][INGHETARE]],"unfreeze",5300 + victim)
            return HAM_SUPERCEDE
        }
    }
    if(is_user_alive(attacker) && get_user_weapon(attacker)!=CSW_KNIFE && 
        g_PlayerSkill[victim][DODGE] && random_num(0,DODGE_CHANCE) == 0)
    {
        SetHamParamFloat(4, 0.0)
        return HAM_OVERRIDE
    }
    new Float:dmg = 0.0
    if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
        dmg = damage * (15 * g_PlayerSkill[attacker][PUTERE])/100
    dmg = dmg - damage * (15 * g_PlayerSkill[victim][REZISTENTA])/100
    SetHamParamFloat(4, (damage + dmg > 0)?(damage + dmg):(0.0))
    return HAM_OVERRIDE
    
}

public player_killed(victim, attacker,Float:damage)
{
    if(!is_user_connected(victim) || !is_user_connected(attacker))
        return HAM_IGNORED
    if(cs_get_user_team(victim) == CS_TEAM_T && g_PlayerSkill[victim][DEGHIZARE] >= 3 && g_IsDisguise[victim] == 1)
        g_IsDisguise[victim] = 0
    if(cs_get_user_team(victim) == CS_TEAM_CT && g_PlayerSkill[victim][INVIERE] >= 1 && g_PlayerRevived[victim] == false && is_skills_ok())
    {
        new Players[MAX_PLAYERS]     
        new playerCount, i, CTalive = 0
        get_players(Players, playerCount, "a") 
        for (i=0; i<playerCount; i++) 
        {
            if (is_user_connected(Players[i]) && cs_get_user_team(Players[i])== CS_TEAM_CT)
                CTalive++
        }
        if(CTalive > 0){
            set_task(0.1,"revive",5300+victim)
        }
    }
    if(!is_user_connected(attacker))
        return HAM_IGNORED
    if(cs_get_user_team(attacker) == CS_TEAM_T && cs_get_user_team(victim) == CS_TEAM_CT)
    {
        new sum = 0
        if(g_Gamemode > NormalDay || g_Gamemode < Freeday){
            if(g_Gamemode == AlienDay || g_Gamemode == AlienHiddenDay)
                sum+= g_Killed[victim]
            else
                sum +=3
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+3 ai omorat un gardian la un joc")
        }else{
            sum +=1
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+1 ai omorat un gardian")
        }
        if(g_Simon== victim){
            sum*=2;
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"X2 L-ai omorat pe sefu")
        }
        if(g_IsDisguise[attacker]==1 && g_Duel==0){
            sum+=1
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+1 ai omorat fiind deghizat")
        }
        if(g_Duel > 2){
            sum += 1
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+1 ai omorat la un duel")
        }
        if(g_Duel < 2 && g_PlayerRevived[victim] == false)
            g_Killed[attacker] ++;
        add_points(attacker,sum)
        
    }
    if(cs_get_user_team(attacker) == CS_TEAM_CT && cs_get_user_team(victim) == CS_TEAM_T)
    {
        new sum = 0
        if(g_Gamemode > NormalDay || g_Gamemode < Freeday ){
            if(g_Gamemode == AlienDay || g_Gamemode == AlienHiddenDay){
                sum += 2
                g_Killed[attacker]++
            }else
                sum += 3
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+3 Ai omorat un prizonnier la un joc")
        }else if(g_Duel> 2){
            sum += 4
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+4 I-ai indeplinit ultima dorinta")
        }else if(get_user_weapon(victim)!= CSW_KNIFE){
            sum += 1
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+1 fiindca avea arma")
        }
        if(g_Killed[victim] > 0 && get_wanted(victim)){
            sum += g_Killed[victim] * 2
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+%d ai omorat un prizonnier rebel",g_Killed[victim] * 2)
        }
        if(g_IsDisguise[victim]==1){
            sum += 2
            if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+2 ai omorat un prizonnier deghizat")
        }
        add_points(attacker, sum)
        if(g_Gamemode == NormalDay){
            new Players[32],playerCount, i, Talive=0, Ttotal = 0;
            get_players(Players, playerCount)
            for (i=0; i<playerCount; i++) 
            {
                if(cs_get_user_team(Players[i])== CS_TEAM_T )
                {
                    if(is_user_alive(Players[i]))
                        Talive++
                    Ttotal++
                }
            }
            if(Talive == 1 && Talive<=Ttotal/3)
            {
                add_points(victim, 3)
                if(ShowAc[victim]==true)
                    client_print(victim, print_chat,"+3 atat de aproape")
            }
            else if(Talive == 2 && Talive<=Ttotal/3)
            {
                add_points(victim, 2)
                if(ShowAc[victim]==true)
                    client_print(victim, print_chat,"+2 si locul 3 e bun")
            }
            else if(Talive+1<=Ttotal/3 && Talive!=1)
            {
                add_points(victim, 1)
                if(ShowAc[victim]==true)
                    client_print(victim, print_chat,"+1 te-ai straduit")
            }
        }
    }
    if(cs_get_user_team(attacker) == CS_TEAM_T && cs_get_user_team(victim) == CS_TEAM_T && !get_wanted(attacker))
    {
        add_points(attacker,1)
        if(ShowAc[attacker]==true)
                client_print(attacker, print_chat,"+1 ai omorat un prizonnier la box")
    }
    return HAM_IGNORED
}

public cmd_player_skill (id)
{
    static menu, menuname[32], option[64]
    formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "SKILLS_BUY")
    menu = menu_create(menuname, "skills_shop")
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TIER I ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if(g_PlayerSkill[id][PUTERE] < 3 || (g_PlayerSkill[id][PUTERE] < 4 && g_Players4[id]))
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_STRENGH",g_PlayerSkill[id][PUTERE]+1, g_Prices[g_PlayerSkill[id][PUTERE]])
        menu_additem(menu, option, "1", 0)    
    }
    if(g_PlayerSkill[id][VITEZA] < 3 || (g_PlayerSkill[id][VITEZA] < 4 && g_Players4[id]))
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_SPEED",g_PlayerSkill[id][VITEZA]+1, g_Prices[g_PlayerSkill[id][VITEZA]])
        menu_additem(menu, option, "2", 0)
    }
    if(g_PlayerSkill[id][SARITURA] < 3 || (g_PlayerSkill[id][SARITURA] < 4 && g_Players4[id]))
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_GRAVITY",g_PlayerSkill[id][SARITURA]+1, g_Prices[g_PlayerSkill[id][SARITURA]])
        menu_additem(menu, option, "5", 0)
    }
    if(g_PlayerSkill[id][DODGE] == 0 && (g_PlayerSkill[id][REZISTENTA] < 3 || (g_PlayerSkill[id][REZISTENTA] < 4 && g_Players4[id])))
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_HARD_SKIN",g_PlayerSkill[id][REZISTENTA]+1, g_Prices[g_PlayerSkill[id][REZISTENTA]])
        menu_additem(menu, option, "6", 0)
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TIER II ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if((g_PlayerSkill[id][CAMUFLAJ] < 3 || (g_PlayerSkill[id][CAMUFLAJ] < 4 && g_Players4[id])) && cs_get_user_team(id)==CS_TEAM_T)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_HIDE",g_PlayerSkill[id][CAMUFLAJ]+1, g_Prices[g_PlayerSkill[id][CAMUFLAJ]+1])
        menu_additem(menu, option, "3", 0)
    }
    if((g_PlayerSkill[id][DEGHIZARE] < 3 || (g_PlayerSkill[id][DEGHIZARE] < 4 && g_Players4[id])) && cs_get_user_team(id)==CS_TEAM_T)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_DISGUISE",g_PlayerSkill[id][DEGHIZARE]+1, g_Prices[g_PlayerSkill[id][DEGHIZARE]+1])
        menu_additem(menu, option, "4", 0)
    }
    if((g_PlayerSkill[id][INGHETARE] < 3 || (g_PlayerSkill[id][INGHETARE] < 4 && g_Players4[id])) && cs_get_user_team(id)==CS_TEAM_CT)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_FREEZE",g_PlayerSkill[id][INGHETARE]+1, g_Prices[g_PlayerSkill[id][INGHETARE]])
        menu_additem(menu, option, "8", 0)
    }
    if((g_PlayerSkill[id][VINDECARE] < 3 || (g_PlayerSkill[id][VINDECARE] < 4 && g_Players4[id])) && cs_get_user_team(id)==CS_TEAM_CT)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_HEALING",g_PlayerSkill[id][VINDECARE]+1, g_Prices[g_PlayerSkill[id][VINDECARE]])
        menu_additem(menu, option, "10", 0)
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TIER III ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if(g_PlayerSkill[id][INFRAROSU] < 2 && cs_get_user_team(id)==CS_TEAM_CT)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_INFRARED",g_PlayerSkill[id][INFRAROSU]+1, g_Prices[g_PlayerSkill[id][INFRAROSU]*2+3])
        menu_additem(menu, option, "9", 0)
    }
    if(g_PlayerSkill[id][INVIERE] < 2 && cs_get_user_team(id)==CS_TEAM_CT)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_REVIVE",g_PlayerSkill[id][INVIERE]+1, g_Prices[g_PlayerSkill[id][INVIERE]*2+3])
        menu_additem(menu, option, "11", 0)
    }
    if((g_PlayerSkill[id][FURT] < 2) && cs_get_user_team(id)==CS_TEAM_T)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_THIEF",g_PlayerSkill[id][FURT]+1, g_Prices[g_PlayerSkill[id][FURT]*2+3])
        menu_additem(menu, option, "7", 0)
    }
    if((g_PlayerSkill[id][LACATUS] < 2) && cs_get_user_team(id)==CS_TEAM_T)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_PICKLOCK",g_PlayerSkill[id][LACATUS]+1, g_Prices[g_PlayerSkill[id][LACATUS]*2+3])
        menu_additem(menu, option, "12", 0)
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TIER IV ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if(g_PlayerSkill[id][RECUL] < 1 || (g_PlayerSkill[id][RECUL] < 2 && g_Players4[id]))
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_RECOIL",g_PlayerSkill[id][RECUL]+1, g_Prices[g_PlayerSkill[id][RECUL]*2+3])
        menu_additem(menu, option, "13", 0)
    }
    if(g_PlayerSkill[id][DODGE] < 1  && g_PlayerSkill[id][REZISTENTA] == 0)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_DODGE",g_PlayerSkill[id][DODGE]+1, g_Prices[g_PlayerSkill[id][DODGE]*2+3])
        menu_additem(menu, option, "14", 0)
    }
    if(g_PlayerSkill[id][SILENTIOS] < 1 && cs_get_user_team(id)==CS_TEAM_T)
    {
        formatex(option, charsmax(option), "%L", LANG_SERVER, "SKILLS_SILENTIOS",g_PlayerSkill[id][SILENTIOS]+1, g_Prices[g_PlayerSkill[id][SILENTIOS]*2+3])
        menu_additem(menu, option, "15", 0)
    }
    menu_display(id, menu)
    
    return PLUGIN_HANDLED
}

public  skills_shop(id, menu, item)
{
    if(item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    
    new skil = str_to_num(data)
    switch(skil){
        case 3,4:
            if(g_PlayerSkill[id][skil] < 3 || (g_PlayerSkill[id][skil] < 4 && g_Players4[id])){
                if(g_PlayerPoints[id][0] >= g_Prices[g_PlayerSkill[id][skil]+1]){
                    g_PlayerPoints[id][0] -= g_Prices[g_PlayerSkill[id][skil]+1]
                    g_PlayerSkill[id][skil] += 1
                    if(skil == 3)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_HIDE",g_PlayerSkill[id][skil])
                    else if(skil == 4)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_DISGUISE",g_PlayerSkill[id][skil])
                }else{
                    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_NOT_ENOUGH",g_Prices[g_PlayerSkill[id][skil]+1] - g_PlayerPoints[id][0])
                }
            }
        case 1,2,5,6,8,10:
            if(g_PlayerSkill[id][skil] < 3 || (g_PlayerSkill[id][skil] < 4 && g_Players4[id]))
            {
                if(g_PlayerPoints[id][0] >= g_Prices[g_PlayerSkill[id][skil]])
                {
                    g_PlayerPoints[id][0] -= g_Prices[g_PlayerSkill[id][skil]]
                    g_PlayerSkill[id][skil] += 1
                    switch(skil)
                    {
                        case(1):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_STRENGH",g_PlayerSkill[id][skil])
                        case(2):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_SPEED",g_PlayerSkill[id][skil])
                        case(5):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_GRAVITY",g_PlayerSkill[id][skil])
                        case(6):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_HARD_SKIN",g_PlayerSkill[id][skil])
                        case(8):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_FREEZE",g_PlayerSkill[id][skil])
                        case(10):
                            client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_HEALING",g_PlayerSkill[id][skil])
                    }
                }else{
                    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_NOT_ENOUGH",g_Prices[g_PlayerSkill[id][skil]] - g_PlayerPoints[id][0])
                }
            }
        case 7,9,11,12,13,14,15:
            if(g_PlayerSkill[id][skil] < 2)
            {
                if(g_PlayerPoints[id][0] >= g_Prices[g_PlayerSkill[id][skil]*2+3]){
                    g_PlayerPoints[id][0] -= g_Prices[g_PlayerSkill[id][skil]*2+3]
                    g_PlayerSkill[id][skil] += 1
                    if(skil == FURT)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_THIEF",g_PlayerSkill[id][skil])
                    else if(skil == INFRAROSU){
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_INFRARED",g_PlayerSkill[id][skil])
                        if(g_UseInfra[id]==false)
                            set_task(1.0,"cmd_askinfrared",id)
                    }
                    else if(skil == INVIERE)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_REVIVE",g_PlayerSkill[id][skil])
                    else if(skil == LACATUS)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_PICKLOCK",g_PlayerSkill[id][skil])
                    else if(skil == RECUL)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_RECOIL",g_PlayerSkill[id][skil])
                    else if(skil == DODGE)
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_DODGE",g_PlayerSkill[id][skil])
                    else if(skil == SILENTIOS){
                        client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_UPGRADE_SILENTIOS",g_PlayerSkill[id][skil])
                        set_user_footsteps(id,1)
                    }
                }else{
                    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_NOT_ENOUGH",g_Prices[g_PlayerSkill[id][skil]*2+3] - g_PlayerPoints[id][0])
                }
            }      
        default:
            client_print(id, print_center, "INVALID REQUEST");
    }
    cmd_player_skill (id)
    return PLUGIN_HANDLED
}

public admin_points(id,level,cid)
{
    if (!cmd_access(id,level,cid,3)) 
        return PLUGIN_HANDLED

    new arg[32], arg2[8]
    new name[32], name2[32], authid[36], authid2[36]
    read_argv(1,arg,31)
    read_argv(2,arg2,7)
    get_user_name(id,name,31)
    get_user_authid(id,authid,35)
    new PtsGive = str_to_num(arg2)

    if (PtsGive <= 0) {
        console_print(id,"Trebuie un numar mai mare ca 0")
        return PLUGIN_HANDLED
    }
    new player = cmd_target(id,arg,6)
    if (!player) return PLUGIN_HANDLED

    add_points(player,PtsGive)
    
    get_user_name(player,name2,31)
    get_user_authid(player,authid2,35)

    client_print(0,print_console,"%L", LANG_SERVER, "SKILLS_GIVE_POINTS",name,PtsGive,name2)
    
    return PLUGIN_HANDLED
}

public admin_verify_skills(id,level,cid)
{
    new arg[32]
    new name[32]
    
    read_argv(1,arg,31)
        
    new player = cmd_target(id,arg,0)
    if (!player) return PLUGIN_HANDLED

    
    get_user_name(player,name,31)

    client_print(id,print_console,"/////////////////////////////////")
    client_print(id,print_console,"//Nume:           %s",name)
    client_print(id,print_console,"//Puncte:        %d",g_PlayerPoints[player][0])
    client_print(id,print_console,"//Puncte totale:    %d",g_PlayerPoints[player][1])
    client_print(id,print_console,"//===============================")
    client_print(id,print_console,"//Putere:         %d",g_PlayerSkill[player][PUTERE])
    client_print(id,print_console,"//Viteza:         %d",g_PlayerSkill[player][VITEZA])
    client_print(id,print_console,"//Camuflaj:       %d",g_PlayerSkill[player][CAMUFLAJ])
    client_print(id,print_console,"//Deghizare:      %d",g_PlayerSkill[player][DEGHIZARE])
    client_print(id,print_console,"//Saritura:       %d",g_PlayerSkill[player][SARITURA])
    client_print(id,print_console,"//Rezistenta:     %d",g_PlayerSkill[player][REZISTENTA])
    client_print(id,print_console,"//Furt:           %d",g_PlayerSkill[player][FURT])
    client_print(id,print_console,"//Inghetare:        %d",g_PlayerSkill[player][INGHETARE])
    client_print(id,print_console,"//Infrarosu:        %d %d",g_PlayerSkill[player][INFRAROSU], g_UseInfra[player])
    client_print(id,print_console,"//Vindecare:        %d",g_PlayerSkill[player][VINDECARE])
    client_print(id,print_console,"//Inviere:        %d",g_PlayerSkill[player][INVIERE])
    client_print(id,print_console,"//Lacatus:        %d",g_PlayerSkill[player][LACATUS])
    client_print(id,print_console,"//Recul:            %d",g_PlayerSkill[player][RECUL])
    client_print(id,print_console,"//Acuratete:          %d",g_PlayerSkill[player][ACURATETE])
    client_print(id,print_console,"//////////////////////////////////")
    return PLUGIN_HANDLED
}
public cmd_cheater (id)
{
    client_print(id,print_center,"FUCK YOU CHEATER")
    add_points(id,180)
    return PLUGIN_HANDLED
}
public cmd_level4 (id)
{
    g_Players4[id] = true
    return PLUGIN_HANDLED
}
public add_points (id, sum)
{
    if(!is_user_connected(id) || sum == 0)
        return PLUGIN_HANDLED    
    
    g_PlayerPoints[id][0] += sum
    g_PlayerPoints[id][1] += sum
    client_print(id, print_center, "%L", LANG_SERVER, "SKILLS_GOT_POINTS",sum)
    
    return PLUGIN_HANDLED
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


public copyVec(Float:Vec[3],Float:Ret[3]){
    Ret[0]=Vec[0]
    Ret[1]=Vec[1]
    Ret[2]=Vec[2]
}

public subVec(Float:Vec1[3],Float:Vec2[3],Float:Ret[3]){
    Ret[0]=Vec1[0]-Vec2[0]
    Ret[1]=Vec1[1]-Vec2[1]
    Ret[2]=Vec1[2]-Vec2[2]
}

public addVec(Float:Vec1[3],Float:Vec2[3]){
    Vec1[0]+=Vec2[0]
    Vec1[1]+=Vec2[1]
    Vec1[2]+=Vec2[2]
}

public normalize(Float:Vec[3],Float:Ret[3],Float:multiplier){
    new Float:len=getVecLen(Vec)
    copyVec(Vec,Ret)
    Ret[0]/=len
    Ret[1]/=len
    Ret[2]/=len
    Ret[0]*=multiplier
    Ret[1]*=multiplier
    Ret[2]*=multiplier
}

public Float:getVecLen(Float:Vec[3]){
    new Float:VecNull[3]={0.0,0.0,0.0}
    new Float:len=vector_distance(Vec,VecNull)
    return len
}


public Float:get_screen_pos(id,Float:v_me_to_target[3],Float:Ret[2]){
    new Float:v_aim[3]
    VelocityByAim(id,1,v_aim) // get aim vector
    new Float:aim[3]
    copyVec(v_aim,aim) // make backup copy of v_aim
    v_aim[2]=0.0 // project aim vector vertically to x,y plane
    new Float:v_target[3]
    copyVec(v_me_to_target,v_target)
    v_target[2]=0.0 // project target vector vertically to x,y plane
    // both v_aim and v_target are in the x,y plane, so angle can be calculated..
    new Float:x_angle
    new Float:x_pos=get_screen_pos_x(v_target,v_aim,x_angle) // get the x coordinate of hudmessage..
    new Float:y_pos=get_screen_pos_y(v_me_to_target,aim) // get the y coordinate of hudmessage..
    Ret[0]=x_pos 
    Ret[1]=y_pos
    return x_angle
}

public Float:get_screen_pos_x(Float:target[3],Float:aim[3],&Float:xangle){
    new Float:x_angle=floatacos(vectorProduct(aim,target)/(getVecLen(aim)*getVecLen(target)),1) // get angle between vectors
    new Float:x_pos
    //this part is a bit tricky..
    //the problem is that the 'angle between vectors' formula returns always positive values
    //how can be determined if the target vector is on the left or right side of the aim vector? with only positive angles?
    //the solution:
    //the scalar triple product returns the volume of the parallelepiped that is created by three input vectors
    //
    //i used the aim and target vectors as the first two input parameters
    //and the third one is a vector pointing straight upwards [0,0,1]
    //if now the target is on the left side of spectator origin the created parallelepipeds volume is negative 
    //and on the right side positive
    //now we can turn x_angle into a signed value..
    if (scalar_triple_product(aim,target)<0.0) x_angle*=-1 // make signed
    if (x_angle>=-45.0 && x_angle<=45.0){ // if in fov of 90
        x_pos=1.0-(floattan(x_angle,degrees)+1.0)/2.0 // calulate y_pos of hudmessage
        xangle=x_angle
        return x_pos
    }
    xangle=0.0
    return -2.0
}

public Float:get_screen_pos_y(Float:v_target[3],Float:aim[3]){
    new Float:target[3]
    
    // rotate vector about z-axis directly over the direction vector (to get height angle)
    rotateVectorZ(v_target,aim,target)
    
    // get angle between aim vector and target vector
    new Float:y_angle=floatacos(vectorProduct(aim,target)/(getVecLen(aim)*getVecLen(target)),1) // get angle between vectors
    
    new Float:y_pos
    new Float:norm_target[3],Float:norm_aim[3]
    
    // get normalized target and aim vectors
    normalize(v_target,norm_target,1.0)
    normalize(aim,norm_aim,1.0)
    
    //since the 'angle between vectors' formula returns always positive values
    if (norm_target[2]<norm_aim[2]) y_angle*=-1 //make signed
    
    if (y_angle>=-45.0 && y_angle<=45.0){ // if in fov of 90
        y_pos=1.0-(floattan(y_angle,degrees)+1.0)/2.0 // calulate y_pos of hudmessage
        if (y_pos>=0.0 && y_pos<=1.0) return y_pos
    }
    return -2.0
}

public Float:vectorProduct(Float:Vec1[3],Float:Vec2[3]){
    return Vec1[0]*Vec2[0]+Vec1[1]*Vec2[1]+Vec1[2]*Vec2[2]
}

public Float:scalar_triple_product(Float:a[3],Float:b[3]){
    new Float:up[3]={0.0,0.0,1.0}
    new Float:Ret[3]
    Ret[0]=a[1]*b[2]-a[2]*b[1]
    Ret[1]=a[2]*b[0]-a[0]*b[2]
    Ret[2]=a[0]*b[1]-a[1]*b[0]
    return vectorProduct(Ret,up)
}

public rotateVectorZ(Float:Vec[3],Float:direction[3],Float:Ret[3]){
    // rotates vector about z-axis
    new Float:tmp[3]
    copyVec(Vec,tmp)
    tmp[2]=0.0
    new Float:dest_len=getVecLen(tmp)
    copyVec(direction,tmp)
    tmp[2]=0.0
    new Float:tmp2[3]
    normalize(tmp,tmp2,dest_len)
    tmp2[2]=Vec[2]
    copyVec(tmp2,Ret)
}

public make_TE_BEAMPOINTS(id,color,Float:Vec1[3],Float:Vec2[3],width,target_team,brightness){
    message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id) //message begin
    write_byte(0)
    write_coord(floatround(Vec1[0])) // start position
    write_coord(floatround(Vec1[1]))
    write_coord(floatround(Vec1[2]))
    write_coord(floatround(Vec2[0])) // end position
    write_coord(floatround(Vec2[1]))
    write_coord(floatround(Vec2[2]))
    write_short(laser) // sprite index
    write_byte(3) // starting frame
    write_byte(0) // frame rate in 0.1's
    write_byte(floatround(get_cvar_float("esp_timer")*10)) // life in 0.1's
    write_byte(width) // line width in 0.1's
    write_byte(0) // noise amplitude in 0.01's
    write_byte(esp_colors[color][0])
    write_byte(esp_colors[color][1])
    write_byte(esp_colors[color][2])
    write_byte(brightness) // brightness)
    write_byte(0) // scroll speed in 0.1's
    message_end()
}