/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 12-30-07
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Added ML
*    -Optimized Code
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION    "2.0"

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <vip_base>

static const sound1[32] = "sleep.wav"
static const sound2[32] = "bagyawn.wav"
static const sound1b[32] = "sound/sleep.wav"
static const sound2b[32] = "sound/bagyawn.wav"

new bool:playsound1
new bool:playsound2

new bool:asleep[33]

new origins[33][3];

new max_health

public plugin_init()
{
    register_plugin("Sleep Mod",VERSION,"GHW_Chronic")

    register_clcmd("say /dorm","cmd_sleep")
    register_clcmd("say /treaz","cmd_wakeup")

    max_health = register_cvar("sleep_maxhp","150")

    register_dictionary("GHW_Sleepmod.txt")
}

public plugin_precache()
{
    if(file_exists(sound1b))
    {
        playsound1=true
        precache_sound(sound1)
    }
    if(file_exists(sound2b))
    {
        playsound2=true
        precache_sound(sound2)
    }
}

public client_connect(id) asleep[id]=false
public client_disconnect(id) asleep[id]=false

public cmd_wakeup(id)
{
    if(!is_user_alive(id))
        return PLUGIN_HANDLED
    if(!asleep[id])
    {
        client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOWAKEUP")
        return PLUGIN_HANDLED
    }
    else
    {
        asleep[id]=false
        client_cmd(id,"-duck")

        if(playsound2) emit_sound(id,CHAN_VOICE,sound2,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
        client_print(id,print_center,"[AMXX] %L",id,"MSG_WAKEUP2")

        set_user_rendering(id)

        message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
        write_short(~0)
        write_short(~0)
        write_short(1<<12)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        message_end()
        remove_task(id)
    }

    return PLUGIN_HANDLED
}

public cmd_sleep(id)
{
    if(!is_user_alive(id))
        return PLUGIN_HANDLED
    if(asleep[id]) 
    {
        client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOSLEEP")
        return PLUGIN_HANDLED
    }
    else if(!is_user_alive(id)) 
    {
        client_print(id,print_chat," %L",id,"MSG_NOSLEEP2")
        return PLUGIN_HANDLED
    }
    else
    {
        asleep[id]=true
        set_task(0.2,"fadeout",id,"",0,"b")
        client_print(id,print_center,"[AMXX] %L",id,"MSG_SLEEP")
        client_print(id,print_chat,"[AMXX] %L",id,"MSG_WAKEUP")
        get_user_origin(id, origins[id]);
        if(playsound1) emit_sound(id,CHAN_VOICE,sound1,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
    }
    return PLUGIN_HANDLED
}

public fadeout(id)
{
    new tmp_origin[3]
    if(!is_user_alive(id))
    {
        asleep[id]=false
        remove_task(id)
    }
    else if(!asleep[id])
    {
        //set_user_maxspeed(id,320.0)
        client_cmd(id,"-duck")

        if(playsound2) emit_sound(id,CHAN_VOICE,sound2,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
        client_print(id,print_center,"[AMXX] %L",id,"MSG_WAKEUP2")

        set_user_rendering(id)

        message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
        write_short(~0)
        write_short(~0)
        write_short(1<<12)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        write_byte(0)
        message_end()
        remove_task(id)
    }
    else
    {
        get_user_origin(id, tmp_origin);
        
        new health = get_user_health(id)
        if(health>=get_pcvar_num(max_health) || tmp_origin[0] != origins[id][0] ||  tmp_origin[1] != origins[id][1])
        {
            asleep[id]=false
            client_cmd(id,"-duck")

            if(playsound2) emit_sound(id,CHAN_VOICE,sound2,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
            client_print(id,print_center,"[AMXX] %L",id,"MSG_WAKEUP2")

            set_user_rendering(id)

            message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
            write_short(~0)
            write_short(~0)
            write_short(1<<12)
            write_byte(0)
            write_byte(0)
            write_byte(0)
            write_byte(0)
            message_end()
            remove_task(id)
        }
        else
        {
            //set_user_maxspeed(id,1.0)
            client_cmd(id,"+duck")
            
            if(get_vip_type(id) == 3)
            {
                set_user_health(id,health + 2)
            }
            else
            {
                set_user_health(id,health + 1)
            }
            set_user_rendering(id,kRenderFxGlowShell,0,255,0,kRenderTransAlpha,25)

            message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
            write_short(~0)
            write_short(~0)
            write_short(1<<12)
            write_byte(0)
            write_byte(0)
            write_byte(0)
            write_byte(255)
            message_end()
            
            
            origins[id][0] = tmp_origin[0]
            origins[id][1] = tmp_origin[1]
            origins[id][2] = tmp_origin[2]
        }
    }
}