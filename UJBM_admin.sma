/* Plugin generated by AMXX-Studio */


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>



#define PLUGIN "[UJBM] Admin Menu"
#define VERSION "1.0"
#define AUTHOR "R_O_O_T"
new bool:Locked = false;
new bool:WeaponsLocked = false;
new g_MaxClients

public plugin_init() {

    register_plugin(PLUGIN, VERSION, AUTHOR)
    new map[33]
    get_mapname(map,32)
    register_clcmd("say /adminmenu", "cmd_adminmenu")
    register_clcmd("UJBM_adminmenu","cmd_adminmenu",0,"")
    register_clcmd("chooseteam","chooseteamfunc",0,"")
    register_dictionary("ujbm.txt")
    RegisterHam( Ham_Use, "func_button", "equip_touch" );
    RegisterHam( Ham_Use, "button_target", "equip_touch" );
    RegisterHam(Ham_Touch, "weapon_hegrenade", "player_touchweapon")
    RegisterHam(Ham_Touch, "weaponbox", "player_touchweapon")
    RegisterHam(Ham_Touch, "armoury_entity", "player_touchweapon")
    RegisterHam(Ham_Touch, "weapon_shield", "player_touchweapon")
    
    
    register_concmd("jb_block_teams", "adm_blockteams", ADMIN_RCON)
    register_concmd("jb_unblock_teams", "adm_unblockteams", ADMIN_RCON)
    
    register_concmd("jb_block_weapons", "adm_blockweapons", ADMIN_RCON)
    register_concmd("jb_unblock_weapons", "adm_unblockweapons", ADMIN_RCON)
    register_clcmd("drop","drop",0,"")
    
    g_MaxClients = get_global_int(GL_maxClients)
    Locked = false
    WeaponsLocked = false
    return PLUGIN_CONTINUE
}



public  admin_choice(id, menu, item)
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
            if (cmd_access(id,ADMIN_RCON,0,0))
            {
                if (WeaponsLocked)
                    WeaponsLocked = false
                else 
                    WeaponsLocked = true
                
            }
            else
            {
                client_print(id,print_console, "You have no rights to lock teams")
                return PLUGIN_HANDLED
            }
            
            if (WeaponsLocked)
            {
                new name[32]
                get_user_name(id,name,32)
                console_print(0, "[JB] Admin ^"%s^" Locked Weapons",name)
                log_amx("[JB] Admin ^"%s^" Locked Weapons",name)
            }
            else
            {
                new name[32]
                get_user_name(id,name,32)
                console_print(0, "[JB] Admin ^"%s^" unLocked Weapons",name)
                log_amx("[JB] Admin ^"%s^" unLocked Weapons",name)
            }
            cmd_adminmenu(id)
        }
        
        case'2':
        {
            NomicMenu(id)
        }
        
        case'3':
        {
            if (cmd_access(id,ADMIN_IMMUNITY,0,0))
            {
                if (Locked)
                    Locked = false
                else 
                    Locked = true
                
            }
            else
            {
                client_print(id,print_console, "You have no rights to lock teams")
                return PLUGIN_HANDLED
            }
            
            if (Locked)
            {
                new name[32]
                get_user_name(id,name,32)
                console_print(0, "[JB] Admin ^"%s^" Locked Team Menu",name)
                log_amx("[JB] Admin ^"%s^" Locked Team Menu",name)
            }
            else
            {
                new name[32]
                get_user_name(id,name,32)
                console_print(0, "[JB] Admin ^"%s^" unLocked Team Menu",name)
                log_amx("[JB] Admin ^"%s^" unLocked Team Menu",name)
            }
            cmd_adminmenu(id)
        }
        
        
    }        
    return PLUGIN_HANDLED
}


public  cmd_adminmenu(id)  
{
    if (get_user_flags(id) & ADMIN_KICK)
    {
        static menu, menuname[32], option[64]
        
        formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_ADMINMENU")
        menu = menu_create(menuname, "admin_choice")
        if (WeaponsLocked)
        {
            formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_ADMIN_WEAP_LOCKED")
            menu_additem(menu, option, "1", 0)
            
        }
        else
        {
            formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_ADMIN_WEAP_UNLOCKED")
            menu_additem(menu, option, "1", 0)    
        }
        
        formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_ADMIN_NOMIC")
        menu_additem(menu, option, "2", 0)
        
        if (!Locked)
        {
            formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_ADMIN_LOCK_TEAMS_UNLOCKED")
            menu_additem(menu, option, "3", 0)
        }
        else
        {
            formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_ADMIN_LOCK_TEAMS_LOCKED")
            menu_additem(menu, option, "3", 0)    
        }

        menu_display(id, menu)
    }
    return PLUGIN_HANDLED
}




stock NomicMenu(id)
{
    if(get_user_flags(id) & ADMIN_KICK)
        menu_players(id, CS_TEAM_CT, 0, 0, "nomic_select", "%L", LANG_SERVER, "UJBM_ADMIN_NOMIC_SEL")
}

public nomic_select(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    
    static dst[32], data[5], player, access, callback
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    player = str_to_num(data)
    new name[32],name_admin[32]
    get_user_name(player,name,32)
    get_user_name(id,name_admin,32)
    server_cmd("jb_nomic ^"%s^"", name)
    console_print(0, "[JB] Admin ^"%s^" locked to play CT ^"%s^"", name_admin,name)
    log_amx("[JB] Admin ^"%s^" locked to play CT ^"%s^"", name_admin,name)
    
    
    return PLUGIN_HANDLED
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

public adm_blockteams(id)
{
    if (cmd_access(id,ADMIN_RCON,0,0)) Locked = true;
    return PLUGIN_HANDLED;
}

public adm_unblockteams(id)
{
    if (cmd_access(id,ADMIN_RCON,0,0)) Locked = false;
    return PLUGIN_HANDLED;
}
public adm_blockweapons(id)
{
    if (cmd_access(id,ADMIN_RCON,0,0)) WeaponsLocked = true;
    return PLUGIN_HANDLED;
}

public adm_unblockweapons(id)
{
    if (cmd_access(id,ADMIN_RCON,0,0)) WeaponsLocked = false;
    return PLUGIN_HANDLED;
}

public player_touchweapon(id, ent)
{
    if(WeaponsLocked)
        return HAM_SUPERCEDE
    
    return HAM_IGNORED
}

public equip_touch( iEntity, id, iActivator, iUseType, Float:flValue )
{
    new szInfo[ 32 ]
    new iTarget
    if(WeaponsLocked)
    {
        pev( iEntity, pev_target, szInfo, charsmax( szInfo ) );
        iTarget = engfunc( EngFunc_FindEntityByString, -1, "targetname", szInfo );
        
        if( iTarget )
            pev( iTarget, pev_classname, szInfo, charsmax( szInfo ) );
        
        return equal( szInfo, "multi_manager" ) || equal( szInfo, "game_player_equip" ) ? HAM_SUPERCEDE : HAM_IGNORED;
    }
    return HAM_IGNORED
}

public chooseteamfunc(id)
{
    if (Locked) return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE
}

public drop(id)
{
    if (WeaponsLocked) return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}