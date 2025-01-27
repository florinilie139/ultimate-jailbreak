#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <vip_base>
#include <cstrike>

#define PLUGIN "Magic Marker"
#define VERSION "3.1"
#define AUTHOR "stupok69"

#define USAGE_LEVEL ADMIN_KICK

new Float:origin[MAX_PLAYERS+1][3]
new prethink_counter[MAX_PLAYERS+1]
new bool:is_drawing[MAX_PLAYERS+1]
new bool:is_holding[MAX_PLAYERS+1]
new bool:is_paint[MAX_PLAYERS+1]

new spriteid

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_clcmd("+paint", "paint_handler", USAGE_LEVEL, "Paint on the walls!")
    register_clcmd("-paint", "paint_handler", USAGE_LEVEL, "Paint on the walls!")
    register_srvcmd("painttero", "enable_disable_paint")
    register_forward(FM_PlayerPreThink, "forward_FM_PlayerPreThink", 0)
    RegisterHam(Ham_Killed, "player", "player_killed")
    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
}

public plugin_precache()
{
    spriteid = precache_model("sprites/lgtning.spr")
}

public client_connect(id)
{
    is_paint[id] = false
    is_drawing[id] = false
    is_holding[id] = false
}

public round_start()
{
    for(new i = 1;i <= MAX_PLAYERS; i++)
        is_paint[i] = false
}

public enable_disable_paint(id,level,cid)
{
    new ids[3], dest
    read_argv(1, ids, 2)
    dest = str_to_num(ids);
    if(is_paint[dest] == true)
    {
        is_paint[dest] = false;
    }
    else
    {
        is_paint[dest] = true;
    }
}

public paint_handler(id, level, cid)
{
    if(get_vip_type(id) == 0 && ( is_paint[id] == false || cs_get_user_team(id) != CS_TEAM_T ) && !cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED
    
    if(!is_user_alive(id))
    {
        client_print(id, print_chat, "* Nu poti folosi paint cand esti mort.")
        return PLUGIN_HANDLED
    }
    
    static cmd[2]
    read_argv(0, cmd, 1)
    
    switch(cmd[0])
    {
        case '+': is_drawing[id] = true
        case '-': is_drawing[id] = false
    }
    return PLUGIN_HANDLED
}

public forward_FM_PlayerPreThink(id)
{
    if(prethink_counter[id]++ > 5)
    {
        if(is_drawing[id] && !is_aiming_at_sky(id))
        {
            static Float:cur_origin[3], Float:distance

            cur_origin = origin[id]
            
            if(!is_holding[id])
            {
                fm_get_aim_origin(id, origin[id])
                move_toward_client(id, origin[id])
                is_holding[id] = true
                return FMRES_IGNORED
            }
            
            fm_get_aim_origin(id, origin[id])
            move_toward_client(id, origin[id])
            
            distance = get_distance_f(origin[id], cur_origin)
            
            if(distance > 2)
            {
                draw_line(origin[id], cur_origin)
            }
        }
        else
        {
            is_holding[id] = false
        }
        prethink_counter[id] = 0
    }
    
    return FMRES_IGNORED
}

stock draw_line(Float:origin1[3], Float:origin2[3])
{
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_BEAMPOINTS)
    engfunc(EngFunc_WriteCoord, origin1[0])
    engfunc(EngFunc_WriteCoord, origin1[1])
    engfunc(EngFunc_WriteCoord, origin1[2])
    engfunc(EngFunc_WriteCoord, origin2[0])
    engfunc(EngFunc_WriteCoord, origin2[1])
    engfunc(EngFunc_WriteCoord, origin2[2])
    write_short(spriteid)
    write_byte(0)
    write_byte(10)
    write_byte(255)
    write_byte(50)
    write_byte(0)
    write_byte(random(255))
    write_byte(random(255))
    write_byte(random(255))
    write_byte(255)
    write_byte(0)
    message_end()
}

//from fakemeta_util.inc
stock fm_get_aim_origin(index, Float:origin[3])
{
    static Float:start[3], Float:view_ofs[3]
    pev(index, pev_origin, start)
    pev(index, pev_view_ofs, view_ofs)
    xs_vec_add(start, view_ofs, start)
    
    static Float:dest[3]
    pev(index, pev_v_angle, dest)
    engfunc(EngFunc_MakeVectors, dest)
    global_get(glb_v_forward, dest)
    xs_vec_mul_scalar(dest, 9999.0, dest)
    xs_vec_add(start, dest, dest)
    
    engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
    get_tr2(0, TR_vecEndPos, origin)
    
    return 1
}

stock move_toward_client(id, Float:origin[3])
{        
    static Float:player_origin[3]
    
    pev(id, pev_origin, player_origin)
    
    origin[0] += (player_origin[0] > origin[0]) ? 1.0 : -1.0
    origin[1] += (player_origin[1] > origin[1]) ? 1.0 : -1.0
    origin[2] += (player_origin[2] > origin[2]) ? 1.0 : -1.0
}
//Thanks AdaskoMX!
bool:is_aiming_at_sky(index)
{
    new Float:origin[3];
    fm_get_aim_origin(index, origin);

    return engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY;
}

public player_killed(victim, attacker, shouldgib)
{
    if(0 < victim < MAX_PLAYERS + 1)
    {
        return HAM_IGNORED
    }
    
    is_paint[victim] = false
    is_drawing[victim] = false
    is_holding[victim] = false
    return HAM_IGNORED
}