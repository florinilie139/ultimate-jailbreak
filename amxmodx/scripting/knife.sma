#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <ujbm>
#include <vip_base>

#define PLUGIN_NAME    "Knife"
#define PLUGIN_AUTHOR    "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION    "1.0"

#define CROWBARCOST    16000

new const gszOldSounds[][]={
    "weapons/knife_hit1.wav",
    "weapons/knife_hit2.wav",
    "weapons/knife_hit3.wav",
    "weapons/knife_hit4.wav",
    "weapons/knife_stab.wav",
    "weapons/knife_hitwall1.wav",
    "weapons/knife_slash1.wav",
    "weapons/knife_slash2.wav",
    "weapons/knife_deploy1.wav"
};
new const gszNewSounds[sizeof gszOldSounds][]={
    "weapons/ls_hitbod1.wav",
    "weapons/ls_hitbod2.wav",
    "weapons/ls_hitbod3.wav",
    "weapons/ls_hitbod3.wav",
    "weapons/ls_hit2.wav",
    "weapons/ls_hit1.wav",
    "weapons/ls_miss.wav",
    "weapons/ls_miss.wav",
    "weapons/ls_pullout.wav"
};

new const _BlueSaber[][]      = { "models/p_light_saber_blue.mdl", "models/v_light_saber_blue.mdl" }
new const _RedSaber[][]       = { "models/p_light_saber_red.mdl", "models/v_light_saber_red.mdl" }
new const _FistModels[][]     = { "models/p_bknuckles.mdl", "models/v_pumni.mdl"}
new const _BoxModels[][]      = { "models/p_bocs.mdl", "models/v_boxx.mdl"}
new const _CrowbarModels[][]  = { "models/jbdobs/p_rangallg.mdl", "models/jbdobs/v_rangallg.mdl" , "models/w_crowbar.mdl" }
new const _FistSounds[][]     = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _ClawsModels[]      = "models/v_hands.mdl"


new const palo_deploy[]       = { "weapons/knife_deploy1.wav" }
new const palo_slash1[]       = { "weapons/knife_slash1.wav" }
new const palo_slash2[]       = { "weapons/knife_slash2.wav" }
new const palo_wall[]         = { "/pumni/PHitWall.wav" } 
new const palo_hit1[]         = { "/pumni/PHit1.wav" } 
new const palo_hit2[]         = { "/pumni/PHit2.wav" } 
new const palo_hit3[]         = { "/pumni/PHit3.wav" } 
new const palo_hit4[]         = { "/pumni/PHit4.wav" } 
new const palo_stab[]         = { "/pumni/PStab.wav" }

new giColor[33]=0

enum {
    All,
    Tero,
    Counter,
    Admin,
    Vip
}

new _KnifesName[20][30]
new _KnifesModels[20][50]
new _KnifesModels2[20]
new _KnifesType[20]
new _KnifesPModels[20][50]
new _KnifesPModels2[20]
new _MAXKNV


new gp_MultiDMG = 1
new g_Simon
new g_Duel
new g_GameMode
new g_HasCrowbar[33]
new gp_CrowbarMul
new Float:gc_CrowbarMul
new g_MaxClients

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

    register_touch("crowbar", "worldspawn",    "cr_bar_snd")
    register_forward(FM_Touch, "crowbar_touch")
    register_forward(FM_EmitSound, "sound_emit")
    register_clcmd("drop","drop",0,"")
    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
    register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
    register_clcmd("say /crowbar", "cmdShopCrowbar")
    register_clcmd("say /ranga", "cmdShopCrowbar")
    register_srvcmd("give_crowbar","give_crowbar_server")
    RegisterHam(Ham_TakeDamage, "player", "player_damage")
    RegisterHam(Ham_Killed, "player", "player_killed")
    RegisterHam(Ham_Weapon_SendWeaponAnim, "weapon_knife","Handl_Animation")
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Handl_Deploy")
    gp_CrowbarMul = register_cvar("jb_crowbarmultiplier", "40.0")
    //set_task(0.5, "check", _, _, _, "b")
    set_task(5.0, "get_jb_data", _, _, _, "b")
    register_clcmd("say /saber", "cmdChooseSabre");
    register_srvcmd("sabers_off", "sabersOff");
    register_clcmd("say /sabersoff", "sabersOff");
    register_srvcmd("sabers_on", "sabersOn");
    g_MaxClients = get_global_int(GL_maxClients)
    return PLUGIN_CONTINUE
}


public LoadKnifes ()
{
    new file[250]
    new data[250],num[2][3],type[10], len, line = 0,id
    
    get_configsdir(file, 249)
    format(file, 249, "%s/knifes.ini", file)
    if(file_exists(file))
    {
        while((line = read_file(file , line , data , 249 , len) ) != 0 && _MAXKNV<20)
        {
            if ((data[0] == ';') || equal(data, "")) continue
            parse(data,    _KnifesName[_MAXKNV],49,    _KnifesPModels[_MAXKNV],49,    num[0],2,    _KnifesModels[_MAXKNV],49,    num[1],2    ,type,9)
            //log_amx(data) 
            _KnifesPModels2[_MAXKNV]=str_to_num(num[0])
            _KnifesModels2[_MAXKNV]=str_to_num(num[1])
            if(equali(type,"All",3)==1)
                _KnifesType[_MAXKNV]=0;
            else if(equali(type,"Tero",4)==1)
                _KnifesType[_MAXKNV]=1;
            else if(equali(type,"Counter",7)==1)
                _KnifesType[_MAXKNV]=2;
            else if(equali(type,"Admin",5)==1)
                _KnifesType[_MAXKNV]=3;
            else if(equali(type,"Vip",3)==1)
                _KnifesType[_MAXKNV]=4;
            else{
                log_amx("Eroare la incarcare %d",id)
                _MAXKNV--
            }
            //log_amx("%s %s %d %s %d %d",_KnifesName[_MAXKNV],_KnifesPModels[_MAXKNV],_KnifesPModels2[_MAXKNV],_KnifesModels[_MAXKNV],_KnifesModels2[_MAXKNV],_KnifesType[_MAXKNV]) 
            _MAXKNV++
            id++
        }
        log_amx("%d cutite au fost incarcate",_MAXKNV)
    }
    else
        log_amx("fisierul %s nu exista",file)
}


public plugin_precache ()
{
    LoadKnifes()
    static i
    for(i = 0; i < sizeof(_BlueSaber); i++)
        precache_model(_BlueSaber[i])
    for(i = 0; i < sizeof(_RedSaber); i++)
        precache_model(_RedSaber[i])
    for(i = 0; i < sizeof(_FistModels); i++)
        precache_model(_FistModels[i])
    for(i = 0; i < sizeof(_BoxModels); i++)
        precache_model(_BoxModels[i])
    for(i = 0; i < sizeof(_CrowbarModels); i++)
        precache_model(_CrowbarModels[i])
    for(i = 0; i < sizeof(_FistSounds); i++)
        precache_sound(_FistSounds[i])
    for(i = 0; i < _MAXKNV; i++){
        precache_model(_KnifesModels[i])
        precache_model(_KnifesPModels[i])
    }

    precache_model(_ClawsModels)
    precache_sound("weapons/cbar_hit1.wav")
    precache_sound("weapons/cbar_miss1.wav")
    precache_sound("debris/metal2.wav")
    //precache_sound("jbDobs/halloween/EvilLaugh.wav")
    precache_sound("jbDobs/SurpriseMotherfucker.wav")
    precache_sound(palo_deploy)
    precache_sound(palo_slash1)
    precache_sound(palo_slash2)
    precache_sound(palo_stab)
    precache_sound(palo_wall)
    precache_sound(palo_hit1)
    precache_sound(palo_hit2)
    precache_sound(palo_hit3)
    precache_sound(palo_hit4)
    
    for(new i=0;i<sizeof gszNewSounds;i++)
        precache_sound(gszNewSounds[i]);
    precache_model("models/player/vader/vader.mdl")
    precache_model("models/player/obiwan/obiwan.mdl")
}

public round_start (){
    gc_CrowbarMul = get_pcvar_float(gp_CrowbarMul);
    new ent = -1
    
    while((ent = find_ent_by_class(ent, "crowbar")))
    {
        if (is_valid_ent(ent)) remove_entity(ent)
    }

    get_jb_data()
}

public give_crowbar_server ()
{
    new id[3],cmd[3]
    read_argv(1, id, 2)
    read_argv(2, cmd, 2)
    new crowbar= str_to_num(cmd);
    new player = str_to_num(id);
    give_crowbar(player, crowbar)
}

public get_jb_data()
{
    g_Simon = get_simon()
    g_GameMode = get_gamemode()
    g_Duel = get_duel()
}

public give_crowbar (player, crowbar)
{
    if(player){
        if(crowbar>=0 && crowbar<=_MAXKNV+1){
            g_HasCrowbar[player]=crowbar
            if (get_user_weapon(player) == CSW_KNIFE) current_weapon(player)
        }
        else
            log_amx("Invalid crowbar")
    }
    else{
        log_amx("Player not found");
    }
}

public cmdShopCrowbar (player){
    if(!is_user_alive(player))
        return PLUGIN_CONTINUE
    static menu, menuname[32], option[64], num[5]
    formatex(menuname, charsmax(menuname), "Meniu Cutite, %d$ fiecare",CROWBARCOST)
    menu = menu_create(menuname, "CrowbarChoice")
    num_to_str( 1, num, charsmax(num))
    formatex(option, charsmax(option),"\wCrowbar\r (Prizonieri)")
    menu_additem(menu, option, num, 0) 
    for(new i = 0; i < _MAXKNV; i++) {
        num_to_str( i+2, num, charsmax(num))
        if(_KnifesType[i] == Tero)
            formatex(option, charsmax(option),"\w%s\r (Prizonieri)", _KnifesName[i])
        else if(_KnifesType[i] == Counter)
            formatex(option, charsmax(option),"\w%s\r (Gardieni)", _KnifesName[i])
        else if(_KnifesType[i] == Admin)
            formatex(option, charsmax(option),"\w%s\r (Admini)", _KnifesName[i])
        else if(_KnifesType[i] == Vip)
            formatex(option, charsmax(option),"\w%s\d (Vip)", _KnifesName[i])
        else
            formatex(option, charsmax(option),"%s", _KnifesName[i])
        menu_additem(menu, option, num, 0) 
    }
    menu_display(player, menu)
    return PLUGIN_CONTINUE
}

public CrowbarChoice (player, menu, item){
    if(item == MENU_EXIT || !is_user_alive(player)){
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback, nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    nr = str_to_num(data)
    if(cs_get_user_money(player)<CROWBARCOST)
        client_print(player,print_chat,"N-ai destui bani")
    else if(nr!=1 && _KnifesType[nr-2] == Admin && !(get_user_flags(player)&ADMIN_KICK) && !get_vip_type(player))
        client_print(player,print_chat,"Trebuie sa ai admin ca sa il iei")
    else if((nr == 1 && cs_get_user_team(player)==CS_TEAM_CT) || nr!=1 && (_KnifesType[nr-2] == Tero || _KnifesType[nr-2] == Counter)  && CsTeams:_KnifesType[nr-2] != cs_get_user_team(player))
        client_print(player,print_chat,"Nu e pentru echipa ta")
    else{
        cs_set_user_money(player, cs_get_user_money(player) - CROWBARCOST)
        if(g_HasCrowbar[player]!=0)
            spawn_crowbar(player)
        give_crowbar(player,nr)
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public player_damage(victim, ent, attacker, Float:damage, bits){
    if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker || gp_MultiDMG==0)
        return HAM_IGNORED
    //client_print(0, print_chat, "e %d", g_GameMode)
    switch (g_GameMode)
    {
    case Freeday, NormalDay:
    {
        if (attacker == ent && (g_Duel == 0 || g_Duel == 2) && g_HasCrowbar[attacker] != 0 &&
            get_user_weapon(attacker) == CSW_KNIFE && cs_get_user_team(victim) != cs_get_user_team(attacker))
        {
            SetHamParamFloat(4, damage * gc_CrowbarMul)
            //client_print(0, print_chat, "Sunt aici, in cazul de ranga, in Freeday, NormalDay");
            return HAM_OVERRIDE
        }
        //client_print(0, print_chat, "Sunt aici, afara, in Freeday, NormalDay");
    }
    case GravityDay, SpiderManDay, ZombieTeroDay, ScoutDay, BoxDay:
    {
        return HAM_IGNORED;
    }
    case AlienDay, AlienHiddenDay, SpartaDay, BugsDay:
    {
        if (attacker == ent && get_user_weapon(attacker) == CSW_KNIFE &&
            cs_get_user_team(victim) != cs_get_user_team(attacker) && cs_get_user_team(attacker) == CS_TEAM_CT)
        {
            SetHamParamFloat(4, damage * gc_CrowbarMul)
            //client_print(0, print_chat, "Sunt aici, in cazul de ranga, in AlienDay, AlienHiddenDay, SpartaDay, BugsDay");
            return HAM_OVERRIDE
        }
        //client_print(0, print_chat, "Sunt aici, afara, in AlienDay, AlienHiddenDay, SpartaDay, BugsDay");
    }
    case SpartaTeroDay:
    {
        if (attacker == ent && get_user_weapon(attacker) == CSW_KNIFE &&
            cs_get_user_team(victim) != cs_get_user_team(attacker) && cs_get_user_team(attacker) == CS_TEAM_T)
        {
            SetHamParamFloat(4, damage * gc_CrowbarMul)
            //client_print(0, print_chat, "Sunt aici, in cazul de ranga, in SpartaTeroDay");
            return HAM_OVERRIDE
        }
        //client_print(0, print_chat, "Sunt aici, afara, in SpartaTeroDay");
    }
    case ZombieDayT, ZombieDay, ColaDay:
    {
        //client_print(0, print_chat, "Sunt aici, in ZombieDayT, ZombieDay, ColaDay");
    }
    default:
    {
        if (attacker == ent && g_HasCrowbar[attacker] != 0 && get_user_weapon(attacker) == CSW_KNIFE && cs_get_user_team(victim) != cs_get_user_team(attacker))
        {
            SetHamParamFloat(4, damage * gc_CrowbarMul)
            //client_print(0, print_chat, "Sunt aici, in cazul de ranga, in default");
            return HAM_OVERRIDE
        }
        //client_print(0, print_chat, "default");
    }
    }
    return HAM_IGNORED
}

public player_killed(victim, attacker, shouldgib)
{
    if (g_GameMode == Freeday || g_GameMode == NormalDay)
    {
        if(g_HasCrowbar[victim]>0){
            spawn_crowbar(victim)
            g_HasCrowbar[victim] = 0
            client_print(0, print_chat, "Sunt aici, in dat ranga jos, pentru %d day", g_GameMode);
        }
        if(is_user_alive(attacker) && cs_get_user_team(attacker) == CS_TEAM_T && g_HasCrowbar[attacker]>0 && get_user_weapon(attacker) == CSW_KNIFE && cs_get_user_team(victim)==CS_TEAM_CT)
            client_cmd(0, "spk jbDobs/SurpriseMotherfucker.wav")//client_cmd(0, "spk jbDobs/halloween/EvilLaugh.wav")//
    }
    giColor[victim] = 0
    return HAM_IGNORED
}

public Handl_Animation (Entity, iAnim, skiplocal)
{
    new iPlayer = pev( Entity, pev_owner)
    if ( is_user_connected( iPlayer )  ) {
        if(g_HasCrowbar[iPlayer]!=0 && (g_GameMode == AlienDay || g_GameMode == AlienHiddenDay) && iPlayer == g_Simon || g_GameMode == AlienDayT && cs_get_user_team(iPlayer) == CS_TEAM_T || g_GameMode == NightDay && cs_get_user_team(iPlayer) == CS_TEAM_CT){
            SendWeaponAnim( iPlayer, iAnim, 1)
        }
        else if(g_HasCrowbar[iPlayer]>1)
            SendWeaponAnim( iPlayer, iAnim, _KnifesModels2[g_HasCrowbar[iPlayer]-2])
    }
}

public Handl_Deploy (Entity)
{
    new iPlayer = pev( Entity, pev_owner)
    if(is_user_connected(iPlayer)){
        if(g_HasCrowbar[iPlayer]>1)
            set_pev(Entity,pev_body,_KnifesPModels2[g_HasCrowbar[iPlayer]-2])
    }
}

public current_weapon(id)
{
    if(!is_user_alive(id) || cs_get_user_shield(id) )
        return PLUGIN_CONTINUE
    if(giColor[id] == 1)
    {
        set_pev(id, pev_viewmodel2, _RedSaber[1])
        set_pev(id, pev_weaponmodel2, _RedSaber[0])
    }
    else if(giColor[id] == 2)
    {
        set_pev(id, pev_viewmodel2, _BlueSaber[1])
        set_pev(id, pev_weaponmodel2, _BlueSaber[0])
    }
    else if(g_GameMode == BoxDay && cs_get_user_team(id) == CS_TEAM_T)
    {
        set_pev(id, pev_viewmodel2, _BoxModels[1])
        set_pev(id, pev_weaponmodel2, _BoxModels[0])
    }
    else if(g_HasCrowbar[id]!=0 && (g_GameMode == AlienDay || g_GameMode == AlienHiddenDay) && id == g_Simon 
        || (g_GameMode == AlienDayT ||  g_GameMode == ZombieDay) && cs_get_user_team(id) == CS_TEAM_T ||
        (g_GameMode == ZombieDayT || g_GameMode == NightDay || g_GameMode == ZombieTeroDay) && cs_get_user_team(id) == CS_TEAM_CT)
    {
        set_pev(id, pev_viewmodel2, _ClawsModels)
        set_pev(id, pev_weaponmodel2, _FistModels[0])
    }
    else if(g_HasCrowbar[id]>1)
    {
        set_pev(id, pev_viewmodel2, _KnifesModels[g_HasCrowbar[id]-2])
        set_pev(id, pev_weaponmodel2, _KnifesPModels[g_HasCrowbar[id]-2])
    }
    else if(g_HasCrowbar[id]==1)
    {
        set_pev(id, pev_viewmodel2, _CrowbarModels[1])
        set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
    }
    else
    {
        set_pev(id, pev_viewmodel2, _FistModels[1])
        set_pev(id, pev_weaponmodel2, _FistModels[0])
    }
    return PLUGIN_CONTINUE
}

public drop(id)
{
    if (g_HasCrowbar[id]!=0 && (get_user_weapon(id) == CSW_KNIFE)) 
    {
        spawn_crowbar(id)
        g_HasCrowbar[id]=0
        current_weapon(id)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE    
}

public spawn_crowbar(id)
{
    new  ent
    new Float:where[3]
    ent = create_entity("info_target")
    set_pev(ent, pev_classname, "crowbar")
    set_pev(ent, pev_solid, SOLID_TRIGGER)
    set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
    set_pev(ent, pev_groupinfo, g_HasCrowbar[id])
    entity_set_model(ent, _CrowbarModels[2])
    pev(id, pev_origin, where)
    where[2] += 50.0;
    where[0] += random_float(-20.0, 20.0)
    where[1] += random_float(-20.0, 20.0)
    entity_set_origin(ent, where)
    where[0] = 0.0
    where[2] = 0.0
    where[1] = random_float(0.0, 180.0)
    entity_set_vector(ent, EV_VEC_angles, where)
    velocity_by_aim(id, 200, where)
    entity_set_vector(ent,EV_VEC_velocity,where)
    return PLUGIN_HANDLED
}

public cr_bar_snd(id, world)
{
    new Float:v[3]
    new Float:volume
    entity_get_vector(id, EV_VEC_velocity, v)
    v[0] = (v[0] * 0.45)
    v[1] = (v[1] * 0.45)
    v[2] = (v[2] * 0.45)
    entity_set_vector(id, EV_VEC_velocity, v)
    volume = get_speed(id) * 0.005; 
    if (volume > 1.0) volume = 1.0
    if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM)
    return PLUGIN_CONTINUE    
}
public crowbar_touch(ent, player)
{
    static touch_class[32]
    if (!pev_valid(ent))
        return FMRES_IGNORED
    pev(ent, pev_classname, touch_class, 31)
    if (!is_user_alive(player) || is_user_bot(player))
        return FMRES_IGNORED
    if (equal(touch_class, "crowbar") && (g_GameMode == Freeday || g_GameMode == NormalDay) && g_HasCrowbar[player]==0)
    {
        g_HasCrowbar[player] = pev(ent, pev_groupinfo)
        remove_entity(ent)
        if (get_user_weapon(player) == CSW_KNIFE) current_weapon(player)
        emit_sound(player, CHAN_AUTO, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public sound_emit(id, channel, sample[], Float:volume, Float:attenuation, fFlags, pitch)
{    
    if(is_user_alive(id))
    {
        if(giColor[id] != 0)
        {
            if(channel==1 || channel==3){
                for(new i=0;i<sizeof gszOldSounds;i++)
                    if(equal(sample,gszOldSounds[i])){
                        engfunc(EngFunc_EmitSound, id, channel, gszNewSounds[i], volume, attenuation, fFlags, pitch);
                        return FMRES_SUPERCEDE;
                    }
            }
        }
        else
        {
            if (equal(sample, "weapons/knife_", 14))
                switch(sample[17])
                {
                    case('l'):
                    {
                        emit_sound(id, CHAN_WEAPON, palo_deploy, 1.0, ATTN_NORM, 0, PITCH_NORM)
                    }
                    case('b'):
                    {
                        emit_sound(id, CHAN_WEAPON, palo_stab, 1.0, ATTN_NORM, 0, PITCH_NORM)
                    }
                    case('w'):
                    {
                        if (g_HasCrowbar[id]!=0)
                            emit_sound(id, CHAN_WEAPON, "weapons/cbar_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
                        else
                            emit_sound(id, CHAN_WEAPON, palo_wall, 1.0, ATTN_NORM, 0, PITCH_LOW)
                    }
                    case('1', '2', '3', '4'):
                    {
                        switch (random_num(1, 4))
                        {
                            case 1:emit_sound(id, CHAN_WEAPON, palo_hit1, 1.0, ATTN_NORM, 0, PITCH_LOW)
                            case 2:emit_sound(id, CHAN_WEAPON, palo_hit2, 1.0, ATTN_NORM, 0, PITCH_LOW)
                            case 3:emit_sound(id, CHAN_WEAPON, palo_hit3, 1.0, ATTN_NORM, 0, PITCH_LOW)
                            case 4:emit_sound(id, CHAN_WEAPON, palo_hit4, 1.0, ATTN_NORM, 0, PITCH_LOW)
                        }
                    }    
                    case('s'):
                    {
                        if (g_HasCrowbar[id]!=0)
                            emit_sound(id, CHAN_WEAPON, "weapons/cbar_miss1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                        else{
                            switch (random_num(1, 2))
                            {
                                case 1: emit_sound(id, CHAN_WEAPON, palo_slash1, 1.0, ATTN_NORM, 0, PITCH_LOW)
                                case 2: emit_sound(id, CHAN_WEAPON, palo_slash2, 1.0, ATTN_NORM, 0, PITCH_LOW)
                            }
                        }
                    }
                } 
            return FMRES_SUPERCEDE
        }
    }
    return FMRES_IGNORED
}

stock SendWeaponAnim(Player, Sequence, Body) 
{
    set_pev(Player, pev_weaponanim, Sequence) 

    message_begin(MSG_ONE, SVC_WEAPONANIM, .player = Player ) 
    write_byte( Sequence ) 
    write_byte( Body ) 
    message_end( )
}

public sabersOff()
{
    for (new i = 1; i <= g_MaxClients; i++)
    {
        giColor[i] = 0
        set_user_info(i, "model", "jbllgxmas")
    }
}

public sabersOn()
{
    for (new i = 1; i <= g_MaxClients; i++)
    {
        if (!is_user_alive(i))
            continue;
        if (cs_get_user_team(i) == CS_TEAM_T)
        {
            giColor[i] = 1;
            set_user_info(i, "model", "vader")
        }
        else if (cs_get_user_team(i) == CS_TEAM_CT)
        {
            giColor[i] = 2;
            set_user_info(i, "model", "obiwan")
        }
    }
}

public cmdChooseSabre(id)
{
    if (get_user_flags(id) & ADMIN_LEVEL_E)
    {
        if (cs_get_user_team(id) == CS_TEAM_T)
        {
            giColor[id] = 1;
            set_user_info(id, "model", "vader")
        }
        else if (cs_get_user_team(id) == CS_TEAM_CT)
        {
            giColor[id] = 2;
            set_user_info(id, "model", "obiwan")
        }
    }
}