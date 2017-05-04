/*  */


#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <nvault>
#include <ujbm>
#include <vip_base>



#define PLUGIN "AMXX Admin Model"
#define VERSION "1.0.4"
#define AUTHOR "mogel"



new myVault
new szDefault[32]


#define MAXMODELS 20    /* davon entfallen 3 als STD-Models */
new maxmodels        // soviele Models werden diese Runde verwendet
enum MODELTYPE {
    MT_BEFEHL,    // der Befehl
    MT_CTSIDE,    // Model für CT
    //MT_CTNR
    MT_TESIDE    // Model für T
    //MT_TENR
    //MT_TYPE
}
new model[MAXMODELS][MODELTYPE][50]
new bool:g_reset[33]

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_logevent("Event_JoinTeam", 3, "1=joined team")
    myVault = nvault_open("x8bit.models")
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
    if (myVault == INVALID_HANDLE) log_amx("konnte Vault nicht öffnen")
    
    nvault_pset(myVault, "model.BOT", "/special")    // hardcoding
    get_model(szDefault,sizeof(szDefault))
    return PLUGIN_CONTINUE
}
public client_connect (id)
{
    g_reset[id] = false
}
public Event_JoinTeam() {
    new Arg1[64]
    read_logargv(0, Arg1, 63)

    new name[13], userid
    parse_loguser(Arg1, name, 12, userid)
    new player = find_player("k", userid)
    set_task(1.0, "ResetPlayerModel", player)
}
public player_spawn (id)
{
    new flags = get_user_flags(id)
    if (((flags & ADMIN_MENU) || get_vip_type(id) != 0) && g_reset[id] == true)
        set_task(1.0, "reset",id)
}
public reset (player)
{
    if (player < 0 && player >32)
        return PLUGIN_HANDLED
    new pm[50]
    new name[35]
    get_user_name(player, name, 34)
    format(pm, 49, getData(player, "model"))
    SetPlayerModel(player, pm)
    return PLUGIN_CONTINUE
}
public setData(player, key[], data[]) {
    
    if (myVault == INVALID_HANDLE) return PLUGIN_CONTINUE
    
    new name[35]
    get_user_name(player, name, 34)
    
    new vaultkey[50]
    format(vaultkey, 49, "%s.%s", key, name)

    nvault_pset(myVault, vaultkey, data)

    return PLUGIN_CONTINUE
}
stock getData(player, key[]) {
    // Crash für den Compiler
    // if (myVault == INVALID_HANDLE) return "empty"
    
    new name[35]
    get_user_name(player, name, 34)
    
    new vaultkey[50]
    format(vaultkey, 49, "%s.%s", key, name)
    
    new vaultdata[50]
    nvault_get(myVault, vaultkey, vaultdata, 49)
    
    return vaultdata
}
public model_precache(model[]) {
    new name[200]
    format(name, 199, "models/player/%s/%s.mdl", model, model)
    if (file_exists(name))
    {
        precache_model(name)
        log_amx("precache -> '%s'", model)
        format(name, 199, "models/player/%s/%sT.mdl", model, model)
        if (file_exists(name))
            precache_model(name)
    } else
    {
        log_amx("'%s' nu exista", name)
    }
}
public plugin_precache() {
    
    new CVar_Flags = FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED
    
    register_cvar("aam_version", VERSION, CVar_Flags)
    server_cmd("aam_version %s", VERSION)
    
    ParseIni();
    
    // jetzt erstmal durch alle Befehle bzw. Models laufen und sammeln
    for(new i = 0; i < maxmodels; i++)
    {
        model_precache(model[i][MT_CTSIDE])
        model_precache(model[i][MT_TESIDE])
    }
    
    return PLUGIN_CONTINUE
}
public client_command(player) {
    
    // "Befehl" holen
    new cmd[50]
    read_argv(1, cmd, 49)

    // alles weiter reichen
    if (cmd[0] != '/') return PLUGIN_CONTINUE

    // jetzt die Befehle durchtesten
    if (equali(cmd,"/stopreset"))
    {
        if(g_reset[player]==true)
        {
            g_reset[player]=false
            client_print(player,print_chat,"Nu ti se va mai reseta modelul")
        }
    }
    if (equali(cmd,"/startreset"))
    {
        if(g_reset[player]==false)
            {
                g_reset[player]=true
                client_print(player,print_chat,"Ti se va reseta modelul la fiecare spawn")
            }
    }
    
    if (equali(cmd, "/skinmenu"))
        SkinMenu(player)
    if(SetPlayerModel(player, cmd) == 1)
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}

public client_infochanged (id)
{
    if(is_user_connected(id))
    {
        new szModel[50]
        new ok = 0
        get_user_info(id,"model",szModel,sizeof(szModel))
        for(new i = 0; i < maxmodels; i++)
        {
            if(equali(szModel,model[i][MT_CTSIDE]) || equali(szModel,model[i][MT_TESIDE]))
            {
                ok = 1;
                break;
            }
        }
        if( ok == 1 || equali(szModel,szDefault))
        {
            return
        }
        set_user_info(id,"model",szDefault)
    }
}
public client_disconnect (id)
{
    remove_task(id);
}
public SkinMenu(player){
    static menu, menuname[32], option[64], num[5]
    formatex(menuname, charsmax(menuname), "Meniu Skinuri")
    menu = menu_create(menuname, "Skinchoice")
    for(new i = 0; i < maxmodels; i++) {
        num_to_str( i, num, charsmax(num))
        formatex(option, charsmax(option), model[i][MT_BEFEHL])
        menu_additem(menu, option, num, 0) 
    }
    menu_display(player, menu)
    return PLUGIN_CONTINUE
}
public Skinchoice (player, menu, item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback,nr
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    nr = str_to_num(data)
    SetPlayerModel(player,model[nr][MT_BEFEHL])
    menu_destroy(menu)
    return PLUGIN_HANDLED
}
public SetPlayerModel(player, cmd[]) {
    if(!is_user_connected(player))
    {
        return 0
    }
    new flags = get_user_flags(player)
    if ((!(flags & ADMIN_MENU) && get_vip_type(player) == 0))
    {
        new name[33]
        get_user_name(player, name, 32)
        client_print(player, print_chat, "%s trebuie sa ai admin pentru modele", name)
        return 0
    }
    
    if (equali(cmd, "/default"))
    {
        cs_reset_user_model(player)
        return 1
    }
    
    for(new i = 0; i < maxmodels; i++)
    {
        if (equali(cmd, model[i][MT_BEFEHL]))
        {
            if (cs_get_user_team(player) == CS_TEAM_CT)
            {
                set_user_info(player,"model", model[i][MT_CTSIDE])
            } else
            {
                set_user_info(player,"model", model[i][MT_TESIDE])
            }
            setData(player, "model", cmd)
            return 1
        }
    }
    return 0
}
public ResetPlayerModel(player) {
    new pm[50]
    new name[35]
    get_user_name(player, name, 34)
    format(pm, 49, getData(player, "model"))
    log_amx("Restore model for %s -> '%s'", name, pm)
    SetPlayerModel(player, pm)
}
public ParseIni() {
    new aamfile[250]
    new data[250], len, line = 0
    
    get_configsdir(aamfile, 249)
    format(aamfile, 249, "%s/aam.ini", aamfile)
    log_amx("INI -> %s", aamfile)
    
    if (!file_exists(aamfile))
    {
        log_amx("keine INI gefunden")
        return
    }

    maxmodels = 0
    
    // INI zerlegen
    while((line = read_file(aamfile , line , data , 249 , len) ) != 0 )
    {
        new cmd[50]    // Befehl
        new ctm[50]    // CT-Model
        
        new tem[50]    // TE-Model
        
        
        
        if ((data[0] == ';') || equal(data, "")) continue
        
        // zerlegen
        parse(data, cmd, 49, ctm, 49, tem, 49)
        
        log_amx("'/%s' gefunden -> '%s' & '%s'", cmd, ctm, tem)
        
        // jetzt noch merken
        format(model[maxmodels][MT_BEFEHL], 49, "/%s", cmd)
        format(model[maxmodels][MT_CTSIDE], 49, "%s", ctm)
        
        format(model[maxmodels][MT_TESIDE], 49, "%s", tem)
        
        
        
        maxmodels++
        /*new cmd[50]    // Befehl
        new ctm[50]    // CT-Model
        new ctn[3]
        new tem[50]    // TE-Model
        new ten[3]
        new type[10]
        
        if ((data[0] == ';') || equal(data, "")) continue
        
        // zerlegen
        parse(data, cmd, 49, ctm, 49, ctn, 2, tem, 49, ten, 2, type, 9)
        
        log_amx("'/%s' gefunden -> '%s' & '%s'", cmd, ctm, tem)

        // jetzt noch merken
        format(model[maxmodels][MT_BEFEHL], 49, "/%s", cmd)
        format(model[maxmodels][MT_CTSIDE], 49, "%s", ctm)
        model[maxmodels][MT_CTNR]= str_to_num(ctn)
        format(model[maxmodels][MT_TESIDE], 49, "%s", tem)
        model[maxmodels][MT_TENR]= str_to_num(ten)
        
        
        maxmodels++*/
    }
    //format(model[maxmodels][MT_BEFEHL], 49, "/myprecious")
    //format(model[maxmodels][MT_CTSIDE], 49, "jill")
    //format(model[maxmodels][MT_TESIDE], 49, "alex")
    log_amx("%i modele (sau comenzi) gasite", maxmodels)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1031\\ f0\\ fs16 \n\\ par }
*/
