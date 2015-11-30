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
#include <cstrike>
#include <hamsandwich>

static const sound1[32] = "sleep.wav"
static const sound2[32] = "bagyawn.wav"
static const sound1b[32] = "sound/sleep.wav"
static const sound2b[32] = "sound/bagyawn.wav"

new bool:playsound1
new bool:playsound2

new bool:asleep[33]

new sleep_enabled
new max_health

public plugin_init()
{
    register_plugin("Sleep Mod",VERSION,"GHW_Chronic")

    register_clcmd("say /dorm","cmd_sleep")
    register_clcmd("say /treaz","cmd_wakeup")

    sleep_enabled = register_cvar("sleep_enabled","1")
    max_health = register_cvar("sleep_maxhp","150")

    RegisterHam(Ham_TakeHealth, "player", "Player_TakeHealth")
    
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
    if(!asleep[id]) client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOWAKEUP")
    else asleep[id]=false
}

public cmd_sleep(id)
{
    if(asleep[id] || cs_get_user_team(id) == CS_TEAM_CT || get_pcvar_num(sleep_enabled) == 0) client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOSLEEP")
    else if(!is_user_alive(id)) client_print(id,print_chat," %L",id,"MSG_NOSLEEP2")
    else
    {
        asleep[id]=true
        set_task(0.2,"fadeout",id,"",0,"b")
        client_print(id,print_center,"[AMXX] %L",id,"MSG_SLEEP")
        client_print(id,print_chat,"[AMXX] %L",id,"MSG_WAKEUP")
        if(playsound1) emit_sound(id,CHAN_VOICE,sound1,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
    }
}

public Player_TakeHealth (id, Float:flHealth, bitsDamageType)
{
    if( get_pcvar_num(sleep_enabled) == 0)
    {
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}


public fadeout(id)
{
    if(is_user_alive(id) && (!asleep[id] || get_pcvar_num(sleep_enabled) == 0))
    {
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
    else if(!is_user_alive(id))
    {
        asleep[id]=false
    }
    else
    {
        new health = get_user_health(id)
        if(health>=get_pcvar_num(max_health))
        {
            asleep[id]=false
            set_task(0.01,"fadeout",id)
        }
        else
        {
            client_cmd(id,"+duck")

            set_user_health(id,health + 1)

            set_user_rendering(id,kRenderFxGlowShell,0,255,0,kRenderTransAlpha,5)

            message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id)
            write_short(~0)
            write_short(~0)
            write_short(1<<12)
            write_byte(0)
            write_byte(0)
            write_byte(0)
            write_byte(255)
            message_end()
        }
    }
}
