/***********************************************************************************\
*    Hook By P34nut    *    Thanks to Joka69, Chaosphere for testing and stuff!        *
*************************************************************************************
* Commands/ bindings:           
*    +hook to throw the hook  
*    -hook to delete your hook
* 
* Cvars:
*    sv_hook - Turns hook on or off 
*    sv_hookthrowspeed - Throw speed (default: 1000)
*    sv_hookspeed - Speed to hook (default: 300)
*    sv_hookwidth - Width of the hook (default: 32)
*    sv_hooksound - Sounds of the hook on or off (default: 1)
*    sv_hookcolor - The color of the hook 0 is white and 1 is team color (default: 1)
*    sv_hookplayers - If set 1 you can hook on players (default: 0)
*    sv_hookinterrupt - Remove the hook when something comes in its line (default: 0)
*    sv_hookadminonly - Hook for admin only (default: 0)
*    sv_hooksky - If set 1 you can hook in the sky (default: 0)
*    sv_hookopendoors - If set 1 you can open doors with the hook (default: 1)
*    sv_hookbuttons - If set 1 you can use buttons with the hook (default: 0)
*    sv_hookpickweapons - If set 1 you can pickup weapons with the hook (default: 1)
*    sv_hookhostflollow - If set 1 you can make hostages follow you (default 1)
*    sv_hookinstant - Hook doesnt throw (default: 0)
*    sv_hooknoise - adds some noise to the hook line (default: 0)
*    sv_hookmax - Maximun numbers of hooks a player can use in 1 round
*           - 0 for infinitive hooks (default: 0)
*    sv_hookdelay - delay on the start of each round before a player can hook
*                 - 0.0 for no delay (default: 0.0)
*
* ChangeLog:
*    1.0: Release
*    1.5: added cvars:
*        sv_hooknoise
*        sv_hookmax
*        sv_hookdelay
*        public cvar: sv_amxxhookmod
*         added commands:
*        amx_givehook <username>
*        amx_takehook <username>
*
\***********************************************************************************/

// Players admin level
#define ADMINLEVEL ADMIN_LEVEL_E

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <xs>
#include <ujbm>

#define message_begin_f(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)

//Cvars
new pHook, pThrowSpeed, pSpeed, pWidth, pSound, pColor
new pInterrupt, pAdmin, pHookSky, pOpenDoors, pPlayers
new pUseButtons, pHostage, pWeapons, pInstant, pHookNoise
new pMaxHooks, pRndStartDelay
// Sprite
new sprBeam

// Players hook entity
new Hook[33]

// MaxPlayers
new gMaxPlayers

// some booleans
new bool:gHooked[33]
new bool:canThrowHook[33]
new bool:rndStarted

// Player Spawn
new bool:gRestart[33] = {false, ...}
new bool:gUpdate[33] = {false, ...}

new gHooksUsed[33] // Used with sv_hookmax
new bool:g_bHookAllowed[33] // Used with sv_hookadminonly

new g_GameMode

public plugin_init()
{
    register_plugin("Hook", "1.5", "P34nut")
    
    // Hook commands
    register_clcmd("+hook", "make_hook")
    register_clcmd("-hook", "del_hook")
    
    register_concmd("amx_givehook", "give_hook", ADMINLEVEL, "<Username> - Give somebody access to the hook")
    register_concmd("amx_takehook", "take_hook", ADMINLEVEL, "<UserName> - Take away somebody his access to the hook")
    
    // Events for roundstart
    register_event("HLTV", "round_bstart", "a", "1=0", "2=0")
    register_logevent("round_estart", 2, "1=Round_Start") 
    
    // Player spawn stuff
    register_event("TextMsg", "Restart", "a", "2=#Game_will_restart_in")
    register_clcmd("fullupdate", "Update") 
    register_event("ResetHUD", "ResetHUD", "b")
    
    // Register cvars
    register_cvar("sv_amxxhookmod",  "version 1.5", FCVAR_SERVER) // yay public cvar
    pHook =     register_cvar("sv_hook", "1")
    pThrowSpeed =     register_cvar("sv_hookthrowspeed", "1000")
    pSpeed =     register_cvar("sv_hookspeed", "300")
    pWidth =     register_cvar("sv_hookwidth", "32")
    pSound =     register_cvar("sv_hooksound", "1")
    pColor =    register_cvar("sv_hookcolor", "1")
    pPlayers =     register_cvar("sv_hookplayers", "0")
    pInterrupt =     register_cvar("sv_hookinterrupt", "0")
    pAdmin =     register_cvar("sv_hookadminonly",  "1")
    pHookSky =     register_cvar("sv_hooksky", "0")
    pOpenDoors =     register_cvar("sv_hookopendoors", "1")
    pUseButtons =     register_cvar("sv_hookusebuttons", "1")
    pHostage =     register_cvar("sv_hookhostflollow", "1")
    pWeapons =    register_cvar("sv_hookpickweapons", "1")
    pInstant =    register_cvar("sv_hookinstant", "0")
    pHookNoise =     register_cvar("sv_hooknoise", "0")
    pMaxHooks =     register_cvar("sv_hookmax", "0")
    pRndStartDelay = register_cvar("sv_hookrndstartdelay", "0.0")
    
    
    // Touch forward
    register_forward(FM_Touch, "fwTouch")
    
    // Get maxplayers
    gMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    // Hook Model
    engfunc(EngFunc_PrecacheModel, "models/rpgrocket.mdl")
    
    // Hook Beam
    sprBeam = engfunc(EngFunc_PrecacheModel, "sprites/zbeam4.spr")
    
    // Hook Sounds
    engfunc(EngFunc_PrecacheSound, "weapons/xbow_hit1.wav") // good hit
    engfunc(EngFunc_PrecacheSound, "weapons/xbow_hit2.wav") // wrong hit
    
    engfunc(EngFunc_PrecacheSound, "weapons/xbow_hitbod1.wav") // player hit
    
    engfunc(EngFunc_PrecacheSound, "weapons/xbow_fire1.wav") // deploy
}


public make_hook(id)
{
    if (get_pcvar_num(pHook) && is_user_alive(id) && canThrowHook[id] && !gHooked[id]) {        
        if (get_pcvar_num(pAdmin))
        {
            // Only the admins can throw the hook
            // if(is_user_admin(id)) { <- does not work...        
            if (!(get_user_flags(id) & ADMINLEVEL) && !g_bHookAllowed[id])
            {
                // Show a message
                client_print(id, print_chat, "[Hook] %L",id,"NO_ACC_COM")
                console_print(id, "[Hook] %L",id,"NO_ACC_COM")
                
                return PLUGIN_HANDLED
            }
        }
        
        new iMaxHooks = get_pcvar_num(pMaxHooks)
        if (iMaxHooks > 0)
        {
            if (gHooksUsed[id] >= iMaxHooks)
            {
                client_print(id, print_chat, "[Hook] You already used your maximum ammount of hooks")
                statusMsg(id, "[Hook] %d of %d hooks used.", gHooksUsed[id], get_pcvar_num(pMaxHooks))
                
                return PLUGIN_HANDLED
            }
            else 
            {
                gHooksUsed[id]++
                statusMsg(id, "[Hook] %d of %d hooks used.", gHooksUsed[id], get_pcvar_num(pMaxHooks))
            }
        }
        new Float:fDelay = get_pcvar_float(pRndStartDelay)
        if (fDelay > 0 && !rndStarted)
            client_print(id, print_chat, "[Hook] You cannot use the hook in the first %0.0f seconds of the round", fDelay)
            
        throw_hook(id)
    }
    return PLUGIN_HANDLED
}

public del_hook(id)
{
    // Remove players hook
    if (!canThrowHook[id])
        remove_hook(id)
    
    return PLUGIN_HANDLED
}

public round_bstart()
{
    // Round is not started anymore
    if (rndStarted)
        rndStarted = false
    
    // Remove all hooks
    for (new i = 1; i <= gMaxPlayers; i++)
    {
        if (is_user_connected(i))
        {
            if(!canThrowHook[i])
                remove_hook(i)
        }
    }
}

public round_estart()
{
    new Float:fDelay = get_pcvar_float(pRndStartDelay)
    if (fDelay > 0.0)
        set_task(fDelay, "rndStartDelay")
    else
    {
        // Round is started...
        if (!rndStarted)
            rndStarted = true
    }
}

public rndStartDelay()
{
    if (!rndStarted)
        rndStarted = true
}

public Restart()
{
    for (new id = 0; id < gMaxPlayers; id++)
    {
        if (is_user_connected(id))
            gRestart[id] = true
    }
}

public Update(id)
{
    if (!gUpdate[id])
        gUpdate[id] = true
    
    return PLUGIN_CONTINUE
}

public ResetHUD(id)
{
    if (gRestart[id])
    {
        gRestart[id] = false
        return
    }
    if (gUpdate[id])
    {
        gUpdate[id] = false
        return
    }
    if (gHooked[id])
    {
        remove_hook(id)
    }
    if (get_pcvar_num(pMaxHooks) > 0)
    {
        gHooksUsed[id] = 0
        statusMsg(0, "[Hook] 0 of %d hooks used.", get_pcvar_num(pMaxHooks))
    }
}

public fwTouch(ptr, ptd)
{
    if (!pev_valid(ptr))
        return FMRES_IGNORED
    
    new id = pev(ptr, pev_owner)
    
    // Get classname
    static szPtrClass[32]    
    pev(ptr, pev_classname, szPtrClass, charsmax(szPtrClass))
    
    if (equali(szPtrClass, "Hook"))
    {        
        static Float:fOrigin[3]
        pev(ptr, pev_origin, fOrigin)
        
        if (pev_valid(ptd))
        {
            static szPtdClass[32]
            pev(ptd, pev_classname, szPtdClass, charsmax(szPtdClass))
                        
            if (!get_pcvar_num(pPlayers) && /*equali(szPtdClass, "player")*/ is_user_alive(ptd))
            {
                // Hit a player
                if (get_pcvar_num(pSound))
                    emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                remove_hook(id)
                
                return FMRES_HANDLED
            }
            else if (equali(szPtdClass, "hostage_entity"))
            {
                // Makes an hostage follow
                if (get_pcvar_num(pHostage) && get_user_team(id) == 2)
                {                    
                    //cs_set_hostage_foll(ptd, (cs_get_hostage_foll(ptd) == id) ? 0 : id)
                    // With the use function we have the sounds!
                    dllfunc(DLLFunc_Use, ptd, id)
                }
                if (!get_pcvar_num(pPlayers))
                {
                    if(get_pcvar_num(pSound))
                        emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                    remove_hook(id)
                }
                return FMRES_HANDLED
            }
            else if (get_pcvar_num(pOpenDoors) && equali(szPtdClass, "func_door") || equali(szPtdClass, "func_door_rotating"))
            {
                // Open doors
                // Double doors tested in de_nuke and de_wallmart
                static szTargetName[32]
                pev(ptd, pev_targetname, szTargetName, charsmax(szTargetName))
                if (strlen(szTargetName) > 0)
                {    
                    static ent
                    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "target", szTargetName)) > 0)
                    {
                        static szEntClass[32]
                        pev(ent, pev_classname, szEntClass, charsmax(szEntClass))
                        
                        if (equali(szEntClass, "trigger_multiple"))
                        {
                            dllfunc(DLLFunc_Touch, ent, id)
                            goto stopdoors // No need to touch anymore
                        }
                    }
                }
                
                // No double doors.. just touch it
                dllfunc(DLLFunc_Touch, ptd, id)
stopdoors:                
            }
            else if (get_pcvar_num(pUseButtons) && equali(szPtdClass, "func_button"))
            {
                if (pev(ptd, pev_spawnflags) & SF_BUTTON_TOUCH_ONLY)
                    dllfunc(DLLFunc_Touch, ptd, id) // Touch only
                else            
                    dllfunc(DLLFunc_Use, ptd, id) // Use Buttons            
            }
        }
        
        // If cvar sv_hooksky is 0 and hook is in the sky remove it!
        new iContents = engfunc(EngFunc_PointContents, fOrigin)
        if (!get_pcvar_num(pHookSky) && iContents == CONTENTS_SKY)
        {
            if(get_pcvar_num(pSound))
                emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            remove_hook(id)
            return FMRES_HANDLED
        }
        
        // Pick up weapons..
        if (get_pcvar_num(pWeapons))
        {
            static ent
            while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, fOrigin, 15.0)) > 0)
            {
                static szentClass[32]
                pev(ent, pev_classname, szentClass, charsmax(szentClass))
                
                if (equali(szentClass, "weaponbox") || equali(szentClass, "armoury_entity"))
                    dllfunc(DLLFunc_Touch, ent, id)
            }
        }
        
        // Player is now hooked
        gHooked[id] = true
        // Play sound
        if (get_pcvar_num(pSound))
            emit_sound(ptr, CHAN_STATIC, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        
        // Make some sparks :D
        message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
        write_byte(9) // TE_SPARKS
        write_coord_f(fOrigin[0]) // Origin
        write_coord_f(fOrigin[1])
        write_coord_f(fOrigin[2])
        message_end()        
        
        // Stop the hook from moving
        set_pev(ptr, pev_velocity, Float:{0.0, 0.0, 0.0})
        set_pev(ptr, pev_movetype, MOVETYPE_NONE)
        
        //Task
        if (!task_exists(id + 856))
        { 
            static TaskData[2]
            TaskData[0] = id
            TaskData[1] = ptr
            gotohook(TaskData)
            
            set_task(0.1, "gotohook", id + 856, TaskData, 2, "b")
        }
    }
    return FMRES_HANDLED
}

public hookthink(param[])
{
    new id = param[0]
    new HookEnt = param[1]
    
    if (!is_user_alive(id) || !pev_valid(HookEnt) || !pev_valid(id))
    {
        remove_task(id + 890)
        return PLUGIN_HANDLED
    }
    
    
    static Float:entOrigin[3]
    pev(HookEnt, pev_origin, entOrigin)
    
    // If user is behind a box or something.. remove it
    // only works if sv_interrupt 1 or higher is
    if (get_pcvar_num(pInterrupt) && rndStarted)
    {
        static Float:usrOrigin[3]
        pev(id, pev_origin, usrOrigin)
        
        static tr
        engfunc(EngFunc_TraceLine, usrOrigin, entOrigin, 1, -1, tr)
        
        static Float:fFraction
        get_tr2(tr, TR_flFraction, fFraction)
        
        if (fFraction != 1.0)
            remove_hook(id)
    }
    
    // If cvar sv_hooksky is 0 and hook is in the sky remove it!
    new iContents = engfunc(EngFunc_PointContents, entOrigin)
    if (!get_pcvar_num(pHookSky) && iContents == CONTENTS_SKY)
    {
        if(get_pcvar_num(pSound))
            emit_sound(HookEnt, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        remove_hook(id)
    }
    
    return PLUGIN_HANDLED
}

public gotohook(param[])
{
    new id = param[0]
    new HookEnt = param[1]

    if (!is_user_alive(id) || !pev_valid(HookEnt) || !pev_valid(id))
    {
        remove_task(id + 856)
        return PLUGIN_HANDLED
    }
    // If the round isnt started velocity is just 0
    static Float:fVelocity[3]
    fVelocity = Float:{0.0, 0.0, 1.0}
    
    // If the round is started and player is hooked we can set the user velocity!
    if (rndStarted && gHooked[id])
    {
        static Float:fHookOrigin[3], Float:fUsrOrigin[3], Float:fDist
        pev(HookEnt, pev_origin, fHookOrigin)
        pev(id, pev_origin, fUsrOrigin)
        
        fDist = vector_distance(fHookOrigin, fUsrOrigin)
        
        if (fDist >= 30.0)
        {
            new Float:fSpeed = get_pcvar_float(pSpeed)
            
            fSpeed *= 0.52
            
            fVelocity[0] = (fHookOrigin[0] - fUsrOrigin[0]) * (2.0 * fSpeed) / fDist
            fVelocity[1] = (fHookOrigin[1] - fUsrOrigin[1]) * (2.0 * fSpeed) / fDist
            fVelocity[2] = (fHookOrigin[2] - fUsrOrigin[2]) * (2.0 * fSpeed) / fDist
        }
    }
    // Set the velocity
    set_pev(id, pev_velocity, fVelocity)
    
    return PLUGIN_HANDLED
}
        
public throw_hook(id)
{
    g_GameMode = get_gamemode()
    
    // Get origin and angle for the hook
    static Float:fOrigin[3], Float:fAngle[3],Float:fvAngle[3]
    static Float:fStart[3]
    pev(id, pev_origin, fOrigin)
    
    pev(id, pev_angles, fAngle)
    pev(id, pev_v_angle, fvAngle)
    
    if (get_pcvar_num(pInstant))
    {
        get_user_hitpoint(id, fStart)
        
        if (engfunc(EngFunc_PointContents, fStart) != CONTENTS_SKY)
        {
            static Float:fSize[3]
            pev(id, pev_size, fSize)
            
            fOrigin[0] = fStart[0] + floatcos(fvAngle[1], degrees) * (-10.0 + fSize[0])
            fOrigin[1] = fStart[1] + floatsin(fvAngle[1], degrees) * (-10.0 + fSize[1])
            fOrigin[2] = fStart[2]
        }
        else
            xs_vec_copy(fStart, fOrigin)
    }

    
    // Make the hook!
    Hook[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
        
    if (Hook[id])
    {
        // Player cant throw hook now
        canThrowHook[id] = false
        
        static const Float:fMins[3] = {-2.840000, -14.180000, -2.840000}
        static const Float:fMaxs[3] = {2.840000, 0.020000, 2.840000}
        
        //Set some Data
        set_pev(Hook[id], pev_classname, "Hook")
        
        engfunc(EngFunc_SetModel, Hook[id], "models/rpgrocket.mdl")
        engfunc(EngFunc_SetOrigin, Hook[id], fOrigin)
        engfunc(EngFunc_SetSize, Hook[id], fMins, fMaxs)        
        
        //set_pev(Hook[id], pev_mins, fMins)
        //set_pev(Hook[id], pev_maxs, fMaxs)
        
        set_pev(Hook[id], pev_angles, fAngle)
        
        set_pev(Hook[id], pev_solid, 2)
        set_pev(Hook[id], pev_movetype, 5)
        set_pev(Hook[id], pev_owner, id)
        
        //Set hook velocity
        static Float:fForward[3], Float:Velocity[3]
        new Float:fSpeed = get_pcvar_float(pThrowSpeed)
        
        engfunc(EngFunc_MakeVectors, fvAngle)
        global_get(glb_v_forward, fForward)
        
        Velocity[0] = fForward[0] * fSpeed
        Velocity[1] = fForward[1] * fSpeed
        Velocity[2] = fForward[2] * fSpeed
        
        set_pev(Hook[id], pev_velocity, Velocity)

        // Make the line between Hook and Player
        message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0)
        if (get_pcvar_num(pInstant))
        {
            write_byte(1) // TE_BEAMPOINT
            write_short(id) // Startent
            write_coord_f(fStart[0]) // End pos
            write_coord_f(fStart[1])
            write_coord_f(fStart[2])
        }
        else
        {
            write_byte(8) // TE_BEAMENTS
            write_short(id) // Start Ent
            write_short(Hook[id]) // End Ent
        }
        write_short(sprBeam) // Sprite
        write_byte(1) // StartFrame
        write_byte(1) // FrameRate
        write_byte(600) // Life
        write_byte(get_pcvar_num(pWidth)) // Width
        write_byte(get_pcvar_num(pHookNoise)) // Noise
        // Colors now
        if (get_pcvar_num(pColor))
        {
            if (get_user_team(id) == 1) // Terrorist
            {
                if(g_GameMode == 13)
                {
                    write_byte(50)   // R
                    write_byte(50)    // G
                    write_byte(255)    // B
                }
                else
                {
                    write_byte(255) // R
                    write_byte(0)    // G
                    write_byte(0)    // B
                }
            }
            else if(get_user_team(id) == 2) // CT
            {
                if(g_GameMode == 13)
                {
                    write_byte(255)    // R
                    write_byte(255)    // G
                    write_byte(255)    // B
                }
                else
                {
                    write_byte(0)    // R
                    write_byte(0)    // G
                    write_byte(255)    // B
                }
            }
            else
            {
                write_byte(255) // R
                write_byte(255) // G
                write_byte(255) // B
            }
        }
        else
        {
            write_byte(255) // R
            write_byte(255) // G
            write_byte(255) // B
        }
        write_byte(192) // Brightness
        write_byte(0) // Scroll speed
        message_end()
        
        if (get_pcvar_num(pSound) && !get_pcvar_num(pInstant))
            emit_sound(id, CHAN_BODY, "weapons/xbow_fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
        
        static TaskData[2]
        TaskData[0] = id
        TaskData[1] = Hook[id]
        
        set_task(0.1, "hookthink", id + 890, TaskData, 2, "b")
    }
    else
        client_print(id, print_chat, "Can't create hook")
}

public remove_hook(id)
{
    //Player can now throw hooks
    canThrowHook[id] = true
    
    // Remove the hook if it is valid
    if (pev_valid(Hook[id]))
        engfunc(EngFunc_RemoveEntity, Hook[id])
    Hook[id] = 0
    
    // Remove the line between user and hook
    if (is_user_connected(id))
    {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, id)
        write_byte(99) // TE_KILLBEAM
        write_short(id) // entity
        message_end()
    }
    
    // Player is not hooked anymore
    gHooked[id] = false
    return 1
}

public give_hook(id, level, cid)
{
    if (!cmd_access(id ,level, cid, 1))
        return PLUGIN_HANDLED
        
    if (!get_pcvar_num(pAdmin))
    {
        console_print(id, "[Hook] Admin only mode is currently disabled")
        return PLUGIN_HANDLED
    }
    
    static szTarget[32]
    read_argv(1, szTarget, charsmax(szTarget))
    
    new iUsrId = cmd_target(id, szTarget)
    
    if (!iUsrId)
        return PLUGIN_HANDLED
        
    static szName[32]
    get_user_name(iUsrId, szName, charsmax(szName))
    
    if (!g_bHookAllowed[iUsrId])
    {
        g_bHookAllowed[iUsrId] = true
        
        console_print(id, "[Hook] You gave %s access to the hook", szName)
    }
    else
        console_print(id, "[Hook] %s already have access to the hook", szName)
    
    return PLUGIN_HANDLED
}

public take_hook(id, level, cid)
{
    if (!cmd_access(id ,level, cid, 1))
        return PLUGIN_HANDLED
    
    if (!get_pcvar_num(pAdmin))
    {
        console_print(id, "[Hook] Admin only mode is currently disabled")
        return PLUGIN_HANDLED
    }
        
    static szTarget[32]
    read_argv(1, szTarget, charsmax(szTarget))
    
    new iUsrId = cmd_target(id, szTarget)
    
    if (!iUsrId)
        return PLUGIN_HANDLED
        
    static szName[32]
    get_user_name(iUsrId, szName, charsmax(szName))
    
    if (g_bHookAllowed[iUsrId])
    {
        g_bHookAllowed[iUsrId] = false
        
        console_print(id, "[Hook] You took away %s his access to the hook", szName)
    }
    else
        console_print(id, "[Hook] %s does not have access to the hook", szName)
    
    return PLUGIN_HANDLED
}

// Stock by Chaosphere
stock get_user_hitpoint(id, Float:hOrigin[3])
{
    if (!is_user_alive(id))
        return 0
    
    static Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]
    static Float:fTemp[3]
    
    pev(id, pev_origin, fOrigin)
    pev(id, pev_v_angle, fvAngle)
    pev(id, pev_view_ofs, fvOffset)
    
    xs_vec_add(fOrigin, fvOffset, fvOrigin)
    
    engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp)
    
    xs_vec_mul_scalar(feOrigin, 8192.0, feOrigin)
    xs_vec_add(fvOrigin, feOrigin, feOrigin)
    
    static tr
    engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id, tr)
    get_tr2(tr, TR_vecEndPos, hOrigin)
    //global_get(glb_trace_endpos, hOrigin)
    
    return 1
}

stock statusMsg(id, szMsg[], {Float,_}:...)
{
    static iStatusText
    if (!iStatusText)
        iStatusText = get_user_msgid("StatusText")
    
    static szBuffer[512]
    vformat(szBuffer, charsmax(szBuffer), szMsg, 3)
    
    message_begin((id == 0) ? MSG_ALL : MSG_ONE, iStatusText, _, id)
    write_byte(0) // Unknown
    write_string(szBuffer) // Message
    message_end()
    
    return 1
}