#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <ujbm>

#define PLUGIN_NAME      "Catuse"
#define PLUGIN_AUTHOR    "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION   "1.0"

new g_MaxClients = 32;

new bool:g_HasCuffs[33];
new g_NrOfHandCuffs;

#define MAX_OF_HANDCUFFS 2
#define PRICE_FOR_CUFFS 300
#define PRICE_UNCUFFS 8000

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam(Ham_Use, "func_button", "equip_touch");
    RegisterHam(Ham_Use, "button_target", "equip_touch");
    register_touch("weaponbox", "player", "player_touchweapon");
    register_touch("armoury_entity", "player", "player_touchweapon"); 
    register_touch("weapon_hegrenade", "player", "player_touchweapon");
    register_touch("weapon_shield", "player", "player_touchweapon"); 

    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start");

    register_clcmd("say /buyhandcuffs", "cmd_buy_handcuffs");
    register_clcmd("say /buyuncuffs", "cmd_buy_uncuffs");
    register_clcmd("say /uncuffall", "cmd_uncuff_all");

    RegisterHam(Ham_Killed, "player", "player_killed");
}

public reset_cuffs()
{
    for (new player = 1; player <= g_MaxClients; player++) {
        g_HasCuffs[player] = false;
    }
    g_NrOfHandCuffs = 0;
}

public round_start()
{
    reset_cuffs();
}

public cmd_uncuff_all(id)
{
    if (cs_get_user_team(id) == CS_TEAM_T)
        return PLUGIN_CONTINUE;

    for (new player = 1; player <= g_MaxClients; player++) {
        g_HasCuffs[player] = false;
    }

    return PLUGIN_CONTINUE;
}

public player_killed(victim, attacker, Float:damage)
{
    if (cs_get_user_team(victim) == CS_TEAM_T)
    {
        new teroCount = 0;
        for (new player = 1; player <= g_MaxClients; player++) {
            if (is_user_alive(player) && cs_get_user_team(player) == CS_TEAM_T)
            {
                teroCount++;
            }
        }
        if (teroCount == 1)
        {
            for (new player = 1; player <= g_MaxClients; player++) {
                g_HasCuffs[player] = false;
            }

        }
    }
}


public cmd_buy_handcuffs(id)
{
    if (g_NrOfHandCuffs >= MAX_OF_HANDCUFFS || cs_get_user_team(id) == CS_TEAM_T)
        return PLUGIN_CONTINUE;

    menu_players(id, CS_TEAM_T, 0, 1, "handcuffs_select", "Alege pe cineva pentru catuse $%d (%d/%d)", PRICE_FOR_CUFFS, g_NrOfHandCuffs, MAX_OF_HANDCUFFS);

    return PLUGIN_CONTINUE;
}

public handcuffs_select(id, menu, item)
{
    static dst[32], data[5], access, callback, player, src[32], vict[32];

    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback);
    player = str_to_num(data);

    new idMoney;
    new korigin[3];
    new pOrigin[3];

    idMoney = cs_get_user_money(id);

    get_user_origin(id, korigin);
    get_user_origin(player, pOrigin);

    if (item == MENU_EXIT || (g_NrOfHandCuffs >= MAX_OF_HANDCUFFS) ||
        !is_user_alive(player) || get_wanted(player) || idMoney < PRICE_FOR_CUFFS || get_distance(korigin,pOrigin) > 256)
    {
        menu_destroy(menu);
        if (idMoney < PRICE_FOR_CUFFS)
        {
            client_print(id, print_center, "Nu ai destui bani pentru catuse");
        }
        if (get_wanted(player))
        {
            client_print(id, print_center, "Nu poti pune catuse unui prizonier urmarit");
        }
        if(get_distance(korigin,pOrigin) > 256)
        {
            client_print(id, print_center, "Esti prea departe de acel prizonier");
        }
        return PLUGIN_HANDLED;
    }


    get_user_name(id, src, charsmax(src));
    get_user_name(player, vict, charsmax(vict));
    client_print(0, print_chat, "%s a pus catuse lui %s", src, vict);
    client_print(player, print_center, "Ti s-au pus catuse");
    g_HasCuffs[player] = true;
    g_NrOfHandCuffs++;
    cs_set_user_money(id, idMoney - PRICE_FOR_CUFFS);
    if (g_NrOfHandCuffs < MAX_OF_HANDCUFFS)
    {
        cmd_buy_handcuffs(id);
    }

    return PLUGIN_HANDLED;
}

public cmd_buy_uncuffs(id)
{
    if (is_user_alive(id))
    {
        new player_money = cs_get_user_money(id);
        if (player_money >= PRICE_UNCUFFS)
        {
            cs_set_user_money(id, player_money - PRICE_UNCUFFS);
            g_HasCuffs[id] = false;
        }
        else
        {
            client_print(id, print_center, "Nu ai destui bani pentru a desface catusele");
        }
    }
    return PLUGIN_CONTINUE;
}

public client_PreThink(id)
{
    if (!is_user_alive(id) || !g_HasCuffs[id])
        return PLUGIN_CONTINUE;

    entity_set_int(id, EV_INT_button, entity_get_int(id, EV_INT_button) & ~IN_ATTACK);

    entity_set_int(id, EV_INT_button, entity_get_int(id, EV_INT_button) & ~IN_ATTACK2);

    return PLUGIN_CONTINUE;
}

public player_touchweapon(id, ent)
{
    if (is_user_alive(ent) && g_HasCuffs[ent])
        return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}

public equip_touch(iEntity, id, iActivator, iUseType, Float:flValue)
{
    new szInfo[32];
    new iTarget;
    if (id < 33 && g_HasCuffs[id])
    {
        pev(iEntity, pev_target, szInfo, charsmax(szInfo));
        iTarget = engfunc(EngFunc_FindEntityByString, -1, "targetname", szInfo);

        if (iTarget)
            pev(iTarget, pev_classname, szInfo, charsmax(szInfo));

        return equal(szInfo, "multi_manager") || equal(szInfo, "game_player_equip") ? HAM_SUPERCEDE : HAM_IGNORED;
    }
    return HAM_IGNORED
}

stock menu_players(id, CsTeams:team, skip, alive, callback[], title[], any:...)
{
    static i, name[32], num[5], menu, menuname[80];
    vformat(menuname, charsmax(menuname), title, 7);
    menu = menu_create(menuname, callback);
    for (i = 1; i <= g_MaxClients; i++)
    {
        if (!is_user_connected(i) || (alive && !is_user_alive(i)) || (skip == i))
            continue;

        if (!(team == CS_TEAM_T || team == CS_TEAM_CT) || ((team == CS_TEAM_T || team == CS_TEAM_CT) && (cs_get_user_team(i) == team)))
        {
            get_user_name(i, name, charsmax(name));
            num_to_str(i, num, charsmax(num));
            menu_additem(menu, name, num, 0);
        }
    }
    menu_display(id, menu);
}
