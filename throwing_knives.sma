#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <ujbm>

new bool:knifeout[33]
new bool:roundfreeze
new Float:tossdelay[33]
new knifeammo[33]
new holdammo[33]

public player_death() {
    new id = read_data(2)
    knife_drop(id)
}

public knife_drop(id) {
    
    if(!get_cvar_num("amx_dropknives") || knifeammo[id] <= 0 || !get_cvar_num("amx_throwknives")) return

    new Float: Origin[3], Float: Velocity[3]
    entity_get_vector(id, EV_VEC_origin, Origin)

    new knifedrop = create_entity("info_target")
    if(!knifedrop) return

    entity_set_string(knifedrop, EV_SZ_classname, "knife_pickup")
    entity_set_model(knifedrop, "models/w_knifepack.mdl")

    new Float:MinBox[3] = {-1.0, -1.0, -1.0}
    new Float:MaxBox[3] = {1.0, 1.0, 1.0}
    entity_set_vector(knifedrop, EV_VEC_mins, MinBox)
    entity_set_vector(knifedrop, EV_VEC_maxs, MaxBox)

    entity_set_origin(knifedrop, Origin)

    entity_set_int(knifedrop, EV_INT_effects, 32)
    entity_set_int(knifedrop, EV_INT_solid, 1)
    entity_set_int(knifedrop, EV_INT_movetype, 6)
    entity_set_edict(knifedrop, EV_ENT_owner, id)

    VelocityByAim(id, 400 , Velocity)
    entity_set_vector(knifedrop, EV_VEC_velocity ,Velocity)
    holdammo[id] = knifeammo[id]
    knifeammo[id] = 0
}

public check_knife(id) {
    if(!get_cvar_num("amx_throwknives")) return

    new weapon = read_data(2)
    if(weapon == CSW_KNIFE) {
        knifeout[id] = true
        client_print(id, print_center,"Ai %d %s de aruncat.",knifeammo[id], knifeammo[id] == 1 ? "cutit" : "cutite")
    }
    else {
        knifeout[id] = false
    }
}

public kill_all_entity(classname[]) {
    new iEnt = find_ent_by_class(-1, classname)
    new tEnt
    while(iEnt > 0) {
        tEnt = iEnt
        iEnt = find_ent_by_class(iEnt, classname)
        remove_entity(tEnt)
    }
}

public new_spawn(id) {

    if(knifeammo[id] < get_cvar_num("amx_knifeammo")) knifeammo[id] = get_cvar_num("amx_knifeammo")
    if(knifeammo[id] > get_cvar_num("amx_maxknifeammo")) knifeammo[id] = get_cvar_num("amx_maxknifeammo")
    tossdelay[id] = 0.0
}

public client_connect(id) {

    knifeammo[id] = get_cvar_num("amx_knifeammo")
    holdammo[id] = 0
    tossdelay[id] = 0.0
    knifeout[id] = false
}

public client_disconnect(id) {

    knifeammo[id] = 0
    holdammo[id] = 0
    tossdelay[id] = 0.0
    knifeout[id] = false
}

public round_start() {
    roundfreeze = false
}
public round_end() {
    roundfreeze = true
    kill_all_entity("throwing_knife")
    kill_all_entity("knife_pickup")
}

public vexd_pfntouch(pToucher, pTouched) {

    if ( !is_valid_ent(pToucher) ) return
    if (!get_cvar_num("amx_throwknives")) return

    new Classname[32]
    entity_get_string(pToucher, EV_SZ_classname, Classname, 31)
    new owner = entity_get_edict(pToucher, EV_ENT_owner)
    new Float:kOrigin[3]
    entity_get_vector(pToucher, EV_VEC_origin, kOrigin)

    if(equal(Classname,"knife_pickup")) {
        if ( !is_valid_ent(pTouched) ) return
        
        check_cvars()
        new Class2[32]     
        entity_get_string(pTouched, EV_SZ_classname, Class2, 31)
        if(!equal(Class2,"player") || knifeammo[pTouched] >= get_cvar_num("amx_maxknifeammo")) return

        if((knifeammo[pTouched] + holdammo[owner]) > get_cvar_num("amx_maxknifeammo")) {
            holdammo[owner] -= get_cvar_num("amx_maxknifeammo") - knifeammo[pTouched]
            knifeammo[pTouched] = get_cvar_num("amx_maxknifeammo")
            emit_sound(pToucher, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
        else {
            knifeammo[pTouched] += holdammo[owner]
            emit_sound(pToucher, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            remove_entity(pToucher)
        }
        client_print(pTouched, print_center,"Ai %i cutite de aruncat",knifeammo[pTouched])
    }

    else if(equal(Classname,"throwing_knife")) {
        check_cvars()
        if(is_user_alive(pTouched)) {
            new movetype = entity_get_int(pToucher, EV_INT_movetype)
            if(movetype == 0 && knifeammo[pTouched] < get_cvar_num("amx_maxknifeammo")) {
                if(knifeammo[pTouched] < get_cvar_num("amx_maxknifeammo")) knifeammo[pTouched] += 1
                client_print(pTouched,print_center,"Ai %i cutite de aruncat",knifeammo[pTouched])
                emit_sound(pToucher, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
                remove_entity(pToucher)
            }
            else if (movetype != 0) {
                if(owner == pTouched) return

                remove_entity(pToucher)

                if(get_user_team(pTouched) == get_user_team(owner)) return

                new pTdead[33]
                entity_set_float(pTouched, EV_FL_dmg_take, get_cvar_num("amx_knifedmg") * 1.0)

                if((get_user_health(pTouched) - get_cvar_num("amx_knifedmg")) <= 0) {
                    pTdead[pTouched] = 1
                }
                else {
                    set_user_health(pTouched, get_user_health(pTouched) - get_cvar_num("amx_knifedmg"))
                    remove_fd(owner)
                }
            

                emit_sound(pTouched, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

                if(pTdead[pTouched]) {
                    set_user_frags(owner, get_user_frags(owner) + 1)                 

                    new gmsgScoreInfo = get_user_msgid("ScoreInfo")
                    new gmsgDeathMsg = get_user_msgid("DeathMsg")

                    //Kill the victim and block the messages
                    set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
                    set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
                    user_kill(pTouched,1)

                    //Update killers scorboard with new info
                    message_begin(MSG_ALL,gmsgScoreInfo)
                    write_byte(owner)
                    write_short(get_user_frags(owner))
                    write_short(get_user_deaths(owner))
                    write_short(0)
                    write_short(get_user_team(owner))
                    message_end()

                    //Update victims scoreboard with correct info
                    message_begin(MSG_ALL,gmsgScoreInfo)
                    write_byte(pTouched)
                    write_short(get_user_frags(pTouched))
                    write_short(get_user_deaths(pTouched))
                    write_short(0)
                    write_short(get_user_team(pTouched))
                    message_end()

                    //Replaced HUD death message
                    message_begin(MSG_ALL,gmsgDeathMsg,{0,0,0},0)
                    write_byte(owner)
                    write_byte(pTouched)
                    write_byte(0)
                    write_string("knife")
                    message_end()

                    new tknifelog[16]
                    if (get_cvar_num("amx_tknifelog")) tknifelog = "throwing_knife"
                    else tknifelog = "knife"

                    new namea[32], authida[35], teama[32]
                    new namev[32], authidv[35], teamv[32]
                    get_user_name(owner,namea,31)
                    get_user_authid(owner,authida,34)
                    get_user_team(owner,teama,31)
                    get_user_name(pTouched,namev,31)
                    get_user_authid(pTouched,authidv,34)
                    get_user_team(pTouched,teamv,31)

                    log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
                    namea,get_user_userid(owner),authida,teama,namev,get_user_userid(pTouched),authidv,teamv,tknifelog)
                    set_wanted(owner)
                }
            }
        }
        else {
            entity_set_int(pToucher, EV_INT_movetype, 0)
            emit_sound(pToucher, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
    }
}


public command_knife(id) {

    if(!is_user_alive(id) || !get_cvar_num("amx_throwknives") || roundfreeze) return PLUGIN_HANDLED

    if(!is_knife_ok()) return PLUGIN_HANDLED
    
    if(get_cvar_num("amx_knifeautoswitch")) {
        knifeout[id] = true
        //engclient_cmd(id,"weapon_knife")
        client_cmd(id,"weapon_knife")
    }

    if(!knifeammo[id]) client_print(id,print_center,"Nu ai cutite de aruncat",knifeammo[id])
    if(!knifeout[id] || !knifeammo[id]) return PLUGIN_HANDLED

    if(tossdelay[id] > get_gametime() - 0.5) return PLUGIN_HANDLED
    else tossdelay[id] = get_gametime()

    knifeammo[id]--

    if (knifeammo[id] == 1) {
        client_print(id,print_center,"Ai %i cutit de aruncat",knifeammo[id])
    }
    else {
        client_print(id,print_center,"Ai %i cutite de aruncat",knifeammo[id])
    }

    new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent

    entity_get_vector(id, EV_VEC_origin , Origin)
    entity_get_vector(id, EV_VEC_v_angle, vAngle)

    Ent = create_entity("info_target")

    if (!Ent) return PLUGIN_HANDLED

    entity_set_string(Ent, EV_SZ_classname, "throwing_knife")
    entity_set_model(Ent, "models/w_throwingknife.mdl")

    new Float:MinBox[3] = {-1.0, -7.0, -1.0}
    new Float:MaxBox[3] = {1.0, 7.0, 1.0}
    entity_set_vector(Ent, EV_VEC_mins, MinBox)
    entity_set_vector(Ent, EV_VEC_maxs, MaxBox)

    vAngle[0] -= 90

    entity_set_origin(Ent, Origin)
    entity_set_vector(Ent, EV_VEC_angles, vAngle)

    entity_set_int(Ent, EV_INT_effects, 2)
    entity_set_int(Ent, EV_INT_solid, 1)
    entity_set_int(Ent, EV_INT_movetype, 6)
    entity_set_edict(Ent, EV_ENT_owner, id)

    VelocityByAim(id, get_cvar_num("amx_knifetossforce") , Velocity)
    entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
    
    return PLUGIN_HANDLED
}

public admin_tknife(id,level,cid){
    
    if (!cmd_access(id,level,cid,1))
        return PLUGIN_HANDLED

    new authid[35],name[32]
    get_user_authid(id,authid,34)
    get_user_name(id,name,31)

    if(get_cvar_num("amx_throwknives") == 0){
        set_cvar_num("amx_throwknives",1)
        client_print(0,print_chat,"[AMXX] Admin has enabled throwing knives")
        console_print(id,"[AMXX] You have enabled throwing knives")
        log_amx("Admin: ^"%s<%d><%s><>^" enabled throwing knives",name,get_user_userid(id),authid)
    }
    else {
        set_cvar_num("amx_throwknives",0)
        client_print(0,print_chat,"[AMXX] Admin has disabled throwing knives")
        console_print(id,"[AMXX] You have disabled throwing knives")
        log_amx("Admin: ^"%s<%d><%s><>^" disabled throwing knives",name,get_user_userid(id),authid)
    }
    return PLUGIN_HANDLED
}


/************************************************************
* MOTD Popups
************************************************************/

public knife_help(id)
{
    new len = 1024
    new buffer[1025]
    new n = 0

#if !defined NO_STEAM
    n += copy(buffer[n],len-n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>")
#endif

    n += copy( buffer[n],len-n,"Pentru a putea folosi cutitele de aruncat trebuie sa iti setezi urmatorul bind:^n^n throw_knife^n^n")

    n += copy( buffer[n],len-n,"Ca sa iti pui bind-ul trebuie sa folosesti urmatoarea comanda, scrisa in consola: ^n^n")

    n += copy( buffer[n],len-n,"bind ^"tasta^" ^"throw_knife^" ^n^n")

    n += copy( buffer[n],len-n,"Acestea sunt cateva ^"exemple^" pe care le puteti folosi, dar se pot utiliza oricare altele:^n^n")
    n += copy( buffer[n],len-n,"    bind f throw_knife         bind MOUSE3 throw_knife^n^n")
    n += copy( buffer[n],len-n,"- Cutitele de aruncat pot fi cumparate din /shop, atat la prizonieri cat si la gardieni^n")
    n += copy( buffer[n],len-n,"- Pentru suma de 10000$ primesti 3 cutite de aruncat, fiecare cutit da 50 damage^n")
    n += copy( buffer[n],len-n,"- Daca ai cumparat sau gasit cutite poti apasa tasta pe care ai setat bindul pentru a arunca un cutit^n")
    n += copy( buffer[n],len-n,"- Daca arunci un cutit si nu nimeresti pe nimeni, il poti ridica de pe jos, dar il poate ridica si altcineva^n")
    n += copy( buffer[n],len-n,"- Cand ridici un cutit sau un pachet de cutite iti va aparea pe mijlocul ecranului numarul de cutite pe care le ai^n")


#if !defined NO_STEAM
    n += copy( buffer[n],len-n,"</pre></body></html>")
#endif

    show_motd(id,buffer ,"Informatii legate de cutitele de aruncat:")
    return PLUGIN_CONTINUE
}

/************************************************************
* CORE PLUGIN FUNCTIONS
************************************************************/

public plugin_init()
{
    register_plugin("Throwing Knives","1.0.2","-]ToC[-Bludy/JTP10181")
    register_event("ResetHUD","new_spawn","b")
    register_event("CurWeapon","check_knife","b","1=1")
    register_event("DeathMsg", "player_death", "a")
    register_logevent("round_start", 2, "1=Round_Start") 
    register_logevent("round_end", 2, "1=Round_End")
    
    register_clcmd("throw_knife","command_knife",0,"- throws a knife if the plugin is enabled")
    register_concmd("amx_tknives","admin_tknife",ADMIN_LEVEL_E,"- toggles throwing knives on/off")
    register_clcmd("say /knifehelp","knife_help")
    register_clcmd("say /throwingknives","knife_help")

    register_cvar("amx_throwknives","1",FCVAR_SERVER)
    register_cvar("amx_knifeammo","0")
    register_cvar("amx_knifetossforce","1200")
    register_cvar("amx_maxknifeammo","3")
    register_cvar("amx_knifedmg","50")
    register_cvar("amx_dropknives","1")
    register_cvar("amx_knifeautoswitch","0")
    register_cvar("amx_tknifelog","0")

    register_srvcmd("give_knifes","_give_knifes")
    register_clcmd("say /tetau","get_knife")
    check_cvars()
}

public plugin_precache()
{
    precache_sound("weapons/knife_hitwall1.wav")
    precache_sound("weapons/knife_hit4.wav")
    precache_sound("weapons/knife_deploy1.wav")
    precache_model("models/w_knifepack.mdl")
    precache_model("models/w_throwingknife.mdl")
}

public check_cvars() {
    if (get_cvar_num("amx_knifeammo") > get_cvar_num("amx_maxknifeammo")) {
        server_print("[AMXX] amx_knifeammo can not be greater than amx_maxknifeammo, adjusting amx_maxknifeammo")
        set_cvar_num("amx_maxknifeammo",get_cvar_num("amx_knifeammo"))
    }
    if (get_cvar_num("amx_knifedmg") < 1 ) {
        server_print("[AMXX] amx_knifedmg can not be set lower than 1, setting cvar to 1 now.")
        set_cvar_num("amx_knifedmg",0)
    }
    if (get_cvar_num("amx_knifetossforce") < 200 ) {
        server_print("[AMXX] amx_knifetossforce can not be set lower than 200, setting cvar to 200 now.")
        set_cvar_num("amx_knifetossforce",200)
    }
}

bool:is_knife_ok()
{
    new g_Gamemode = get_gamemode()
    new g_Duel = get_duel()
    new g_DayOfTheWeek = get_day()
    if((g_Gamemode == Freeday || g_Gamemode == NormalDay) && g_Duel<2 && g_DayOfTheWeek%7!=6 && g_DayOfTheWeek%7!=3)
        return true
    return false
}

public _give_knifes (id,level,cid)
{
    new ids[3],knifes[3]
    read_argv(1, ids, 2)
    read_argv(2, knifes, 2)
    new idz = str_to_num(ids)
    
    if(knifeammo[idz] != 0)
        return false
    knifeammo[idz] = str_to_num(knifes)
    return true
}

public get_knife(id)
{
    if(is_user_alive(id))
        knifeammo[id] += 1
}    