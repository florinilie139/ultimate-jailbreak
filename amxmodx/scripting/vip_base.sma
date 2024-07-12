//Mai este de adaugat armura la inceput de runda la vip pentru pachetul 3 !
//Si de facut aia cu tipul vip-ului si configurat pentru fiecare cum trb.

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <ujbm>

#define PLUGIN_NAME "Vip Main"
#define PLUGIN_AUTHOR "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION "1"
#define PLUGIN_CVAR "Vip Manager"
#define VIP_TYPE_2_MONEY 5000

enum _:_vip { _name[100], _pass[100], _tipvip };
new Vip[100][_vip];
new MaxVip = 0;
new IsVip[33];
new WasWantedVIP2[33];
new GuardDiedVIP2[33];
new g_MaxClients;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)    
    LoadVips();

    register_logevent("round_end", 2, "1=Round_End")
    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")

    register_event("DeathMsg", "Kill_Death", "a", "1 > 0")

    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)

    register_forward(FM_CmdStart, "player_cmdstart", 1)
    register_forward(FM_ClientKill, "fwd_FM_ClientKill");

    g_MaxClients = get_global_int(GL_maxClients)

    return PLUGIN_CONTINUE
}

public plugin_natives() 
{
    register_library("vip_base");
    register_native("get_vip_type", "_get_vip", 0)
}

public _get_vip(iPlugin, iParams) 
{ 
    new id = get_param(1);
    return get_vip_type(id);
}

public get_vip_type(id)
{
    return Vip[IsVip[id]][_tipvip];
}

public client_putinserver(id)
{
    IsVip[id] = 0;
    WasWantedVIP2[id] = 0;
    GuardDiedVIP2[id] = 0;
    load_vip(id)
}

public client_disconnect(id)
{
    WasWantedVIP2[id] = 0;
    GuardDiedVIP2[id] = 0;
}

public client_infochanged(id)
{
    load_vip(id)
}

public LoadVips()
{
    new file[250]
    new data[250], len, line = 0, i = 1
    new type[10]
    get_configsdir(file, 249)
    format(file, 249, "%s/vip.ini", file)
    if(file_exists(file))
    {
        while((line = read_file(file , line , data , 249 , len)) != 0)
        {
            if ((data[0] == ';') || equal(data, "")) continue;
            parse(data, Vip[i][_name], 99, Vip[i][_pass], 99, type, 10);
            Vip[i][_tipvip] = str_to_num(type);
            i++;
            if(i==100)
            {
                log_amx("Nu se pot incarca mai mult de 100")
            }
        }
        log_amx("%d Vip cu skills au fost incarcati", i)
        MaxVip = i;
    }
    else
        log_amx("fisierul %s nu exista", file)
}

public load_vip (id)
{
    new name[100], pass[100]
    get_user_name(id, name, 99)
    for(new i = 0; i < MaxVip; i++)
    {
        if(equal(name, Vip[i][_name]))
        {
            get_user_info(id, "_vip", pass, 99)
            if(strlen(Vip[i][_pass]) == 0 || equal(pass,Vip[i][_pass]))
            {
                IsVip[id] = i;
                log_amx("%s a fost logat ca Vip JB", name)
                //client_print(id,print_chat,"Skillurile tale salvate au fost incarcate, distractie placuta")
            }
        }
    }
}

public player_spawn(id)
{
    if(!is_user_connected(id) || !is_user_alive(id))
    return HAM_IGNORED
    
    WasWantedVIP2[id] = 0;
    GuardDiedVIP2[id] = 0;

    if(get_vip_type(id) > 0)
    {
        set_user_health(id, 150)

        if(cs_get_user_team(id) == CS_TEAM_T)
        {
            new rand = random_num(1, 10) 
            if(rand == 1 && get_vip_type(id) == 2)
            {
                set_task(3.0,"task_give_deagle",id)
            }
            if(get_vip_type(id) == 3)
            {
                set_task(3.0,"task_give_armor",id)
            }
        }
        if(get_vip_type(id) == 4)
            set_task(3.0,"task_give_nades",id)
        
    }

    return HAM_IGNORED;
}

public task_give_armor (id)
{
    if(id > g_MaxClients || !is_user_alive(id))
        return
    give_item(id, "item_assaultsuit")
}

public task_give_deagle (id)
{
    if(id > g_MaxClients || !is_user_alive(id))
        return
    new iEnt = give_item(id, "weapon_deagle")
    if (is_valid_ent(iEnt))
        cs_set_weapon_ammo(iEnt, 7)
}

public task_give_nades (id)
{
    if(id > g_MaxClients || !is_user_alive(id))
        return
    give_item(id,"weapon_flashbang")
    give_item(id,"weapon_flashbang")
    give_item(id,"weapon_smokegrenade")
    give_item(id,"weapon_hegrenade")
}

public round_end()
{
    new alT=0, alC=0;
    new player;
    for (player=0; player < g_MaxClients; player++)
    {
        if(!is_user_connected(player) || !is_user_alive(player))
            continue;
        if(cs_get_user_team(player) == CS_TEAM_CT)
            alC = 1;
        else
            alT = 1;
        if(get_vip_type(player) == 1)
            if(cs_get_user_team(player) == CS_TEAM_CT && alC == 1 || cs_get_user_team(player) == CS_TEAM_T && alT == 1)
                cs_set_user_money(player, cs_get_user_money(player) + 3250);
        if(get_vip_type(player) == 2)
        {
            if(!WasWantedVIP2[player] && cs_get_user_team(player) == CS_TEAM_T ||
            !GuardDiedVIP2[player] && cs_get_user_team(player) == CS_TEAM_CT)
            {
                cs_set_user_money(player, cs_get_user_money(player) + VIP_TYPE_2_MONEY)
            }
            else 
                client_print(player, print_chat, "Nu ai primit %d$!",VIP_TYPE_2_MONEY)
        }
    }
}

public round_start()
{
   
}

public Kill_Death()
{
    static Killer, Victim /*, HeadShot, MoneyClamp*/

    Killer = read_data(1)
    Victim = read_data(2)
    //HeadShot = read_data(3)

    if(get_wanted(Killer) && get_user_team(Killer) == 1)
        WasWantedVIP2[Killer] = 1;
    else if(get_user_team(Victim) == 2)
        GuardDiedVIP2[Victim] = 1;
}