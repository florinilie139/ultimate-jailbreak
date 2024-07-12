/*

Weapon Throwing

Current Version - 1.0.0

- Description -

There are situations when in the middle of a battle you run out of ammo. You're relying on your secondary weapon.
But what if there's no ammo for your secondary weapon? I've always felt that counter-strike was missing a feature
to throw weapons. I can bet that i am not the only one. Sometimes knife can't save you. For example a 100m2(10m x 10m)
room without furniture. One player stands in a door, but the other one stands in a door opposite the first player.
The second player has an ak47, but the first one is out of ammo, but has a usp and a m4a1.
You can't knife your opponent that's 10meters away. You can try to run away, but it'll most likely fail.
This plugin allows you to throw weapons and kill players with them. Weapons are rotating in air with a random speed
and angle. It detects headshots and non-headshots. You can throw weapons holding E and pressing G, by default,
but that's changeable with cvars. See below.

- Cvars -

amx_wp_base_damage < "## ##" > < Base min and max damage. > < Default: "20 40" >

amx_wp_headshot_multi < #.# > < Headshot multiplier. Float. > < Default: 3.0 >

amx_wp_throw_c4 < 0 / 1 > < If 0, you can't throw C4. > < Default: 0 >
amx_wp_use_e < 0 / 1 > < If 0, you have don't have to hold E to throw weapons, you'll be able to throw them
by pressing only the G(drop) key. < Default: 1 >
amx_wp_throw_type < 0 / 1 / 2 > < If 0, you'll throw all weapons flat, but they still will rotate. If 1,
you'll throw all weapons vertical. If 2, plugin will choose a random type between 0 and 1 every time you throw a weapon.
amx_wp_use_for_damage < 0 / 1 > < If 1, damage will be calculated using the weapon weight table. For example,
you'll get more damage with awp than with usp. > < Default: 1 >
amx_wp_base_throw_speed < #### > < Weapon base throw speed. > < Default: 1000 >
amx_wp_use_for_throw_speed < 0 / 1 > < If 1, throw speed will be calculated using the weapon weight table. > < Default: 1 >

- Media -

Video: http://www.youtube.com/watch?v=gve5_1fvPvU

- Notes -

Modification is Counter-Strike because it uses a Weight table for cs weapons.
Turning both cvars that use the weight table should make this work for
hl and all its mods.
Cvar changes will only take effect at the next round.

- Change Log -

1.0.0
* Initial Release

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <ujbm>
#include <cstrike>

#define VERSION    "1.0.0"

#define MAXPLAYERS 32 + 1

#define MAX_WEAPONS_INAIR 64

#define HANDLER_THINK_TIME 0.01

#define MIN_ROT_SPEED 1
#define MAX_ROT_SPEED 7

#define MAX_DIFF_FROM_HEAD 10.0

#define MIN_TOUCH_GMT 0.1

#define NULL 0.0

enum Data
{
    EntID,
    bFirstThink,
    RotAngle,
    RotSpeed,
    WeaponIndex
}

enum iCvars
{
    BaseSpeed,
    UseDamage,
    UseThrowing,
    DropType,
    DropC4,
    OnlyUse
}

enum fCvars
{
    Float:MinBaseDamage,
    Float:MaxBaseDamage,
    
    Float:HeadMulti
}

enum sCvars
{
    BaseDamage
}

new const Float:g_WeaponWeight[CSW_P90 + 1] = {
    
    NULL,
    1.0,     //p228
    0.0,     //shield
    0.7,     //scout
    0.0,     //he
    0.7,     //xm1014
    0.75,     //c4
    0.9,     //mac10
    0.65,     //aug
    0.0,     //smoke
    0.8,     //elite
    1.0,     //fiveseven
    0.9,     //ump45
    0.6,    //sg550
    0.7,     //galil
    0.7,     //famas
    1.0,     //usp
    1.0,     //glock
    0.5,     //awp
    0.9,     //mp5
    0.5,     //m249
    0.6,     //m3
    0.7,     //m4a1
    1.0,     //tmp
    0.65,     //g3sg1
    0.0,     //flash
    0.9,     //deagle
    0.65,     //sg552
    0.7,     //ak47
    NULL,     //knife
    0.85     //p90
}

new c_sCvars[sCvars]
new c_fCvars[fCvars], Float:g_fCvars[fCvars]
new c_Cvars[iCvars], g_Cvars[iCvars]

new g_DeathMsg

new g_WeaponsOnGround

new g_WeaponData[MAX_WEAPONS_INAIR][Data]
new g_WeaponName[MAX_WEAPONS_INAIR][12]

new Float:g_WeaponDropGmt[MAX_WEAPONS_INAIR]
new Float:g_WeaponAngles[MAX_WEAPONS_INAIR][3]

new g_HandlerEnt

new cp_FF

public plugin_init() {
    
    register_plugin("Weapon Throwing",VERSION,"shine")
    
    register_cvar("weapon_throwing",VERSION,FCVAR_SERVER|FCVAR_SPONLY)
    
    c_sCvars[sCvars:BaseDamage] = register_cvar("amx_wp_base_damage","20 40")
    
    c_fCvars[fCvars:HeadMulti] = register_cvar("amx_wp_headshot_multi","3.0")
    
    c_Cvars[iCvars:DropC4] = register_cvar("amx_wp_throw_c4","0")
    c_Cvars[iCvars:OnlyUse] = register_cvar("amx_wp_use_e","1")
    c_Cvars[iCvars:DropType] = register_cvar("amx_wp_throw_type","2")
    c_Cvars[iCvars:UseDamage] = register_cvar("amx_wp_use_for_damage","1")
    c_Cvars[iCvars:BaseSpeed] = register_cvar("amx_wp_base_throw_speed","1000")
    c_Cvars[iCvars:UseThrowing] = register_cvar("amx_wp_use_for_throw_speed","1")
    
    //Events
    register_event("HLTV","RoundStart","a","1=0","2=0")
    
    //Ham Forwards
    RegisterHam(Ham_Touch,"weaponbox","HookTouch")
    RegisterHam(Ham_Spawn,"weaponbox","HookSpawn",1)
    RegisterHam(Ham_Think,"info_target","HandlerThink")
    
    //Messages
    g_DeathMsg = get_user_msgid("DeathMsg")
    
    //Cvar Pointers
    cp_FF = 0
    
    //Load Cvars
    LoadCvars()
    
    //Make Handler
    MakeHandler()
}

public MakeHandler() {
    
    g_HandlerEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
    
    set_pev(g_HandlerEnt,pev_classname,"wpnTHandler")
    
    set_pev(g_HandlerEnt,pev_nextthink,get_gametime() + HANDLER_THINK_TIME)
}

public HookTouch(Ent,id) {
    
    static WeaponID
    WeaponID = GetWeaponByEnt(Ent)
    
    if(WeaponID > -1) {
        
        static Owner
        Owner = pev(Ent,pev_owner)
        
        if(get_gametime() - g_WeaponDropGmt[WeaponID] <= MIN_TOUCH_GMT && id == Owner) {
            
            return HAM_IGNORED
        }
        else {
            
            if(Owner != id && is_user_alive(id) && cs_get_user_team(id) != cs_get_user_team(Owner) && cs_get_user_team(id)!=CS_TEAM_SPECTATOR && get_duel()!=2) {
                
                static bool:HeadShot
                static Float:Vel[3], Float:KnockVel[3], Float:EntOrigin[3], Float:HeadOrigin[3], Float:Damage, Float:rDamage
                
                pev(Ent,pev_velocity,Vel)
                pev(Ent,pev_origin,EntOrigin)
                pev(id,pev_origin,HeadOrigin)
                
                set_pev(Ent,pev_velocity,Float:{0.0, 0.0, 0.0})
                
                HeadOrigin[2] += (pev(id,pev_button) & IN_DUCK) ? 6.0 : 22.0
                
                HeadShot = (floatabs(HeadOrigin[2] - EntOrigin[2]) < MAX_DIFF_FROM_HEAD) ? true : false
                
                //30.0 * 1.0 / 1.0 = 30.0
                //30.0 * 3.0 / 1.0 = 90.0
                //30.0 * 1.0 / 0.5 = 60.0
                //20.0 * 1.0 / 0.5 = 40.0
                //40.0 * 3.0 / 0.5 = 240.0
                
                Damage = 
                (
                    random_float(g_fCvars[fCvars:MinBaseDamage],g_fCvars[fCvars:MaxBaseDamage])
                ) * (
                    HeadShot ? (g_fCvars[fCvars:HeadMulti]) : 1.0
                ) / (
                    g_Cvars[iCvars:UseDamage] ? (g_WeaponWeight[g_WeaponData[WeaponID][Data:WeaponIndex]]) : 1.0
                )
                
                rDamage = get_user_team(id) == get_user_team(Owner) ? Damage / 2.9 : Damage
                
                if(pev(id,pev_health) - rDamage <= 0.0) {
                    
                    user_silentkill2(id)
                    
                    set_wanted(Owner)
                    
                    message_begin(MSG_ALL,g_DeathMsg)
                    write_byte(Owner)
                    write_byte(id)
                    write_byte(HeadShot ? 1 : 0)
                    write_string(g_WeaponName[WeaponID])
                    message_end()
                }
                else {
                    
                    VecMulti(Vel,KnockVel,0.1)
                    
                    ExecuteHam(Ham_TakeDamage,id,Owner,Owner,Damage,DMG_BULLET)
                    
                    set_pev(id,pev_velocity,KnockVel)
                }
            }
            
            //ClearVec(g_WeaponAngles[WeaponID])
            
            g_WeaponAngles[WeaponID][0] = 0.0
            g_WeaponAngles[WeaponID][2] = 0.0
            
            set_pev(g_WeaponData[WeaponID][Data:EntID],pev_angles,g_WeaponAngles[WeaponID])
            
            MoveWeaponIDDown(WeaponID)
        }
    }
    
    return HAM_IGNORED
}

public RoundStart() {
    
    static i, x
    
    for(i = 0; i < MAX_WEAPONS_INAIR; i++) {
        
        for(x = 0; x < _:Data; x++) {
            
            g_WeaponData[i][Data:x] = 0
        }
        
        ClearVec(g_WeaponAngles[i])
    }
    
    g_WeaponsOnGround = 0
    
    //Load Cvars
    LoadCvars()
}

public HookSpawn(Ent) {
    
    static Owner
    Owner = pev(Ent,pev_owner)
    
    if
    (
        is_user_alive(Owner)
        &&
        (
            (
                g_Cvars[iCvars:OnlyUse]
                &&
                pev(Owner,pev_button) & IN_USE
            )
            ||
            (
                !g_Cvars[iCvars:OnlyUse]
            )
        )
    ) {
        
        static Float:PlayerAngles[3], Type
        pev(Owner,pev_v_angle,PlayerAngles)
        
        g_WeaponData[g_WeaponsOnGround][Data:EntID] = Ent
        g_WeaponData[g_WeaponsOnGround][Data:bFirstThink] = 1
        
        g_WeaponDropGmt[g_WeaponsOnGround] = get_gametime()
        
        Type = (g_Cvars[iCvars:DropType] == 2 ? random(2) : g_Cvars[iCvars:DropType])
        
        if(Type) {
            
            g_WeaponAngles[g_WeaponsOnGround][1] = PlayerAngles[1]
            g_WeaponAngles[g_WeaponsOnGround][2] = 90.0
            
            g_WeaponData[g_WeaponsOnGround][Data:RotAngle] = 0
            g_WeaponData[g_WeaponsOnGround][Data:RotSpeed] = -random_num(MIN_ROT_SPEED,MAX_ROT_SPEED)
        }
        else {
            
            g_WeaponAngles[g_WeaponsOnGround][2] = PlayerAngles[2]
            
            g_WeaponData[g_WeaponsOnGround][Data:RotAngle] = 1
            g_WeaponData[g_WeaponsOnGround][Data:RotSpeed] = random_num(MIN_ROT_SPEED,MAX_ROT_SPEED)
        }
        
        g_WeaponsOnGround++
    }
}

public HandlerThink(Ent) {
    
    if(Ent == g_HandlerEnt) {
        
        static Item, i
        
        for(i = 0; i < g_WeaponsOnGround; i++) {
            
            if(pev_valid(g_WeaponData[i][Data:EntID])) {
                
                if(g_WeaponData[i][Data:bFirstThink]) {
                    
                    static Float:Vel[3], Float:PlayerVel[3], Model[64], WeaponName[33], Owner
                    
                    pev(g_WeaponData[i][Data:EntID],pev_model,Model,63)
                    
                    replace(Model,63,"models/w_","")
                    replace(Model,63,".mdl","")
                    replace(Model,63,"backpack","c4")
                    
                    if(equal(Model,"c4") && !g_Cvars[iCvars:DropC4]) {
                        
                        Item = i + 1
                        
                        continue
                    }
                    
                    copy(g_WeaponName[i],11,Model)
                    
                    formatex(WeaponName,32,"weapon_%s",Model)
                    
                    Owner = pev(g_WeaponData[i][Data:EntID],pev_owner)
                    
                    pev(Owner,pev_velocity,PlayerVel)
                    
                    g_WeaponData[i][Data:WeaponIndex] = get_weaponid(WeaponName)
                    
                    velocity_by_aim(Owner,floatround(g_Cvars[iCvars:BaseSpeed] * (g_Cvars[iCvars:UseThrowing] == 1 ? (g_WeaponWeight[g_WeaponData[i][Data:WeaponIndex]]) : 1.0)),Vel)
                    
                    VecAdd(Vel,PlayerVel,Vel)
                    
                    set_pev(g_WeaponData[i][Data:EntID],pev_velocity,Vel)
                    
                    g_WeaponData[i][Data:bFirstThink] = 0
                }
                
                g_WeaponAngles[i][g_WeaponData[i][Data:RotAngle]] += g_WeaponData[i][Data:RotSpeed]
                
                if(g_WeaponAngles[i][g_WeaponData[i][Data:RotAngle]] >= float(degrees)) {
                    
                    g_WeaponAngles[i][g_WeaponData[i][Data:RotAngle]] -= float(degrees)
                }
                
                set_pev(g_WeaponData[i][Data:EntID],pev_angles,g_WeaponAngles[i])
            }
        }
        
        if(Item) {
            
            MoveWeaponIDDown(Item - 1)
            
            Item = 0
        }
        
        set_pev(Ent,pev_nextthink,get_gametime() + HANDLER_THINK_TIME)
    }
}

public user_silentkill2(id) {
    
    static MsgBlock
    MsgBlock = get_msg_block(g_DeathMsg)
    
    set_msg_block(g_DeathMsg,BLOCK_ONCE)    
    user_kill(id,1)
    set_msg_block(g_DeathMsg,MsgBlock)
}

LoadCvars() {
    
    //Load Cvars
    
    static Cvar[10], Damage[2][5], i
    
    get_pcvar_string(c_sCvars[sCvars:BaseDamage],Cvar,9)
    
    parse(Cvar,Damage[0],4,Damage[1],4)
    
    g_fCvars[fCvars:MinBaseDamage] = str_to_float(Damage[0])
    g_fCvars[fCvars:MaxBaseDamage] = str_to_float(Damage[1])
    
    for(i = 0; i < _:iCvars; i++) g_Cvars[iCvars:i] = get_pcvar_num(c_Cvars[iCvars:i])
    
    for(i = 2; i < _:fCvars; i++) g_fCvars[fCvars:i] = get_pcvar_float(c_fCvars[fCvars:i])
}

ClearVec(Float:Vec[3]) {
    
    Vec[0] = 0.0
    Vec[1] = 0.0
    Vec[2] = 0.0
}

CopyVec(Float:Vec[3],Float:eVec[3]) {
    
    eVec[0] = Vec[0]
    eVec[1] = Vec[1]
    eVec[2] = Vec[2]
}

VecMulti(Float:Vec[3],Float:oVec[3],Float:Multi) {
    
    oVec[0] = Vec[0] * Multi
    oVec[1] = Vec[1] * Multi
    oVec[2] = Vec[2] * Multi
}

VecAdd(Float:Vec[3],Float:aVec[3],Float:oVec[3]) {
    
    oVec[0] = Vec[0] + aVec[0]
    oVec[1] = Vec[1] + aVec[1]
    oVec[2] = Vec[2] + aVec[2]
}

MoveWeaponIDDown(StartFrom) {
    
    static i, x
    
    for(i = StartFrom; i < g_WeaponsOnGround; i++) {
        
        for(x = 0; x < _:Data; x++) {
            
            g_WeaponData[i][Data:x] = g_WeaponData[i + 1][Data:x]
        }
        
        g_WeaponDropGmt[i] = g_WeaponDropGmt[i + 1]
        
        copy(g_WeaponName[i + 1],15,g_WeaponName[i])
        
        CopyVec(g_WeaponAngles[i + 1],g_WeaponAngles[i])
    }
    
    g_WeaponsOnGround--
}

GetWeaponByEnt(Ent) {
    
    static i
    
    for(i = 0; i < g_WeaponsOnGround; i++) {
        
        if(g_WeaponData[i][Data:EntID] == Ent) return i
    }
    
    return -1
}
////
