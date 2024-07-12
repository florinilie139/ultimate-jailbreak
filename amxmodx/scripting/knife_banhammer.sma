/*

 Copyleft 2014
 Plugin thread: https://forums.alliedmods.net/showthread.php?t=244336
 
 KNIFE: BANHAMMER
 =================================
 
 Description:

	This plugin adds a new admin knife to the server called Banhammer. Banhammer deals insane damage on both primary and secondary hit (around 100,000), 
        however the secondary attack also bans the player for X minutes and shows some explosion effects. This is like the best plugin ever.
    Admins with the necessary flag (ADMIN_RCON by default) receive the knife automatically on their spawn. 
        The knife is not droppable and it's possible to switch to a different knife using the R(reload) key.
    Admins with the protection flag (ADMIN_IMMUNITY by default) cannot be attacked by the banhammer at all.
	
 Credits:
 
	Mario AR. - Testing
    Black Rose - Testing
    Kia - fx_ functions

 Changelog:
 
    Jul 17, 2014 - v1.0     -   Initial Release
    Jul 17, 2014 - v1.1     -   Now ignores Friendly Fire
    Jul 21, 2014 - v1.2     -   No longer equipped immediately
    
*/

#include <amxmodx>
#include <knifeapi>
#include <hamsandwich>

#define VERSION "1.2"

new g_Banhammer

#define V_MODEL "models/knifeapi/banhammer/v_banhammer.mdl"
#define P_MODEL "models/knifeapi/banhammer/p_banhammer.mdl"

#define SOUND_DRAW "knifeapi/banhammer/banhammer_deploy.wav"
#define SOUND_HIT "knifeapi/banhammer/banhammer_hit.wav"
#define SOUND_STAB "knifeapi/banhammer/banhammer_stab.wav"
#define SOUND_WALL "knifeapi/banhammer/banhammer_hitwall.wav"
#define SOUND_WHIFF "knifeapi/banhammer/banhammer_whiff.wav"

#define ACCESS_FLAG     ADMIN_RCON
#define IMMUNITY_FLAG   ADMIN_IMMUNITY

public plugin_precache()
{
    precache_model(V_MODEL)
    precache_model(P_MODEL)
    
    precache_sound(SOUND_DRAW)
    precache_sound(SOUND_HIT)
    precache_sound(SOUND_STAB)
    precache_sound(SOUND_WALL)
    precache_sound(SOUND_WHIFF)
}

new g_CvarTime, g_CvarAmxbans

public plugin_init()
{
    
    register_plugin("Banhammer", VERSION, "idiotstrike")

    g_Banhammer = Knife_Register(
        "Banhammer",
        V_MODEL,
        P_MODEL,
        _,
        SOUND_DRAW,
        SOUND_HIT,
        SOUND_STAB,
        SOUND_WHIFF,
        SOUND_WALL,
        500.0,
        500.0
    )
    
    const DMG_BULLET = (1<<1)
    const DMG_ALWAYSGIB = (1<<13)
    
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryRange, 50.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryRange, 70.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryNextAttack, 2.1)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryNextAttack, 3.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryDamageDelay, 1.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryDmgBits, DMG_BULLET|DMG_ALWAYSGIB)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryDmgBits, DMG_BULLET|DMG_ALWAYSGIB)
    Knife_SetProperty(g_Banhammer, KN_CLL_IgnoreFriendlyFire, true)
    
    g_CvarTime = register_cvar("banhammer_time", "15")
    g_CvarAmxbans = register_cvar("banhammer_amxbans", "0")
    
    RegisterHam(Ham_Spawn, "player", "@PlayerSpawn", true)
}

// because I want to make my code unreadable
@PlayerSpawn(Player)
{
    if(!Knife_PlayerHas(Player, g_Banhammer) && get_user_flags(Player) & ACCESS_FLAG)
    {
        Knife_PlayerGive(Player, g_Banhammer, false)
    }
}


public KnifeAction_DealDamage(Attacker, Victim, Knife, Float:Damage, bool:PrimaryAttack, DmgBits, bool:Backstab)
{
    if(Knife != g_Banhammer || !Victim)
    {
        return KnifeAction_DoNothing
    }
    
    if(get_user_flags(Victim) & IMMUNITY_FLAG)
    {
        client_print(Attacker, print_center, "This user is immune.")
        return KnifeAction_Block
    }
    
    new PlayerOrigin[3]
    get_user_origin(Victim, PlayerOrigin)
    
    if(!PrimaryAttack)
    {
        // spawn some silly effects
        fx_TE_LAVASPLASH(PlayerOrigin)
        fx_TE_TELEPORT(PlayerOrigin)
        fx_TE_EXPLOSION2(PlayerOrigin, 150, 5)
        
        // ban the player
        new Authid[34], Name[32]
        get_user_authid(Victim, Authid, charsmax(Authid))
        get_user_name(Victim, Name, charsmax(Name))
        
        client_print(0, print_chat, "%s <%s> has been hit by the banhammer! Banning for %d minutes.",
            Name, Authid, get_pcvar_num(g_CvarTime)
        )
        
        set_task(3.0, "_tSendBan", Attacker, Authid, sizeof Authid)
    }
    
    return KnifeAction_DoNothing
}

public _tSendBan(Authid[], Attacker)
{
    if(get_pcvar_num(g_CvarAmxbans))
    {
        //amx_ban TIME "STEAMID" "Hit by the Banhammer"
        client_cmd(Attacker, "amx_ban %d ^"%s^" ^"Hit by the Banhammer^"",
            get_pcvar_num(g_CvarTime), Authid
        )
    }
    else
    {
        client_cmd(Attacker, "amx_addban ^"%s^" %d ^"Hit by the Banhammer^"",
            Authid, get_pcvar_num(g_CvarTime)
        )
        
        new Banned = find_player("c", Authid)
        if(Banned)
        {
            server_cmd("kick #%d", get_user_userid(Banned))
        }
    }
}


fx_TE_LAVASPLASH(Origin[3])
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_LAVASPLASH)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        message_end()
}

 
fx_TE_TELEPORT(Origin[3])
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_TELEPORT)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        message_end()
}
 
 
fx_TE_EXPLOSION2(Origin[3], startcolor, colors)
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_EXPLOSION2)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        write_byte(startcolor) // starting color
        write_byte(colors) // num colors
        
        message_end()
}