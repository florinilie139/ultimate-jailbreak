#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zones>
#include <ujbm>

#define MAX_NETS 10
#define TASK_LASTTOUCH 3300
#define TASK_SHOWNET 1000
#define REFRESH_TIME 2.0
#define CHANGE_TIME 5.0
#define MAX_HEALTH 150
#define MAX_EATEN 300

new const PLUGIN_NAME[] = "Zones"
new const PLUGIN_AUTHOR[] = "(|EcLiPsE|)"
new const PLUGIN_VERSION[] = "1.0"
new const PLUGIN_PREFIX[] = "UTIL"

enum
{
    FIRST_POINT = 0,
    SECOND_POINT
}

enum _FOOD
{
    _name[20], _price, _health, _energizer
}

new _szType[][32]=
{
    "CTZONE",
    "CANTEEN",
    "CELLS",
    "WORKOUT"
}

new _colors[][3] = 
{
    {   0,   0, 255},
    {   0, 255, 255},
    { 255, 255, 255},
    { 255,   0, 255}
}

new g_szFile[128]
new g_szFoodFile[128]
new g_szMapname[32]
new g_buildingstage[33]
new g_buildingnettype[33]
new countnets = 0
new g_iTrailSprite

new bool:g_bHighlight[33]
new bool:g_buildingNet[33]

new Float:g_fOriginBox[33][2][3]
new Float:g_fLastTouch[33]
new g_LastTouch[33]
new g_FoodList[30][_FOOD];
new g_NrFood;
new g_TotalEaten[33];
new g_MenuType[33];

new g_iMainMenu;
new g_iNetMenu;

new g_SayText

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    register_forward(FM_PlayerPreThink, "PlayerPreThink", 0)
    //register_forward(FM_Touch, "FwdTouch", 0)
    for(new i = 0; i < typeZn; i ++)
    {
        register_touch(_szType[i], "player", "FwdTouch");
    }
    for(new i = 1; i < 33; i ++)
    {
        g_LastTouch[i] = -1;
        g_MenuType[i] = 0;
    }
    
    RegisterHam(Ham_Killed, "player", "player_killed", 1)
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
    
    CreateMenus()
    
    register_clcmd("say /zones", "ShowMainMenu")
    register_clcmd("say /mancare","ShowFoodMenu")
    
    
    g_SayText = get_user_msgid("SayText")
    
}

public plugin_natives() 
{ 
    register_library("zones"); 
    register_native ("whatzoneisin", "_whatzoneisin",0)
} 

public _whatzoneisin(iPlugin, iParams) 
{ 
    new id = get_param(1);
    return g_LastTouch[id];
}

public CreateMenus()
{
    g_iMainMenu = register_menuid("Jailzones Main")
    g_iNetMenu = register_menuid("Jailzones Net")

    register_menucmd(g_iMainMenu, 1023, "HandleMainMenu")
    register_menucmd(g_iNetMenu, 1023, "HandleNetMenu")
}

public plugin_precache()
{
    g_iTrailSprite = precache_model("sprites/laserbeam.spr")
    
    get_mapname(g_szMapname, 31)
    strtolower(g_szMapname )
    
    new szDatadir[64]
    get_localinfo("amxx_configsdir", szDatadir, charsmax(szDatadir))
    
    formatex(g_szFoodFile, charsmax(g_szFoodFile), "%s/food.ini",szDatadir)
    formatex(szDatadir, charsmax( szDatadir ), "%s/zones", szDatadir)
    
    if(!dir_exists( szDatadir))
        mkdir(szDatadir)
    
    formatex(g_szFile, charsmax(g_szFile), "%s/%s.ini",szDatadir, g_szMapname)
    
    if(file_exists(g_szFile))
    {
        LoadAll(0)
    }
    LoadFood()
    
}

public LoadAll(id)
{
    new szData[512]
    new szType[32]
    new szfPoint[3][16], szlPoint[3][16]
    new iFile = fopen(g_szFile, "rt")
    
    while(!feof(iFile))
    {
        fgets(iFile, szData, charsmax(szData))
        
        if(!szData[0] || szData[0] == ';' || szData[0] == ' ' || ( szData[0] == '/' && szData[1] == '/' ))
            continue

        parse(szData, szType, 31,\
            szfPoint[0], 15, szfPoint[1], 15, szfPoint[2], 15,\
            szlPoint[0], 15, szlPoint[1], 15, szlPoint[2], 15)
        
        new Float:fPoint[3]
        new Float:lPoint[3]
        
        for(new j = 0; j < 3; j++)
        {
            fPoint[j] = str_to_float(szfPoint[j])
            lPoint[j] = str_to_float(szlPoint[j])
        }

        CreateNet(szType, fPoint, lPoint)

        countnets ++
        
    }
    
    fclose(iFile)
    
    ColorChat(id, "Inarcare cu succes")
}

public LoadFood()
{
    new lineNum   =  0,pointNum  = 0,configLine[80],iLen,price[6],health[10],energizer[3]

    if(file_exists(g_szFoodFile)){
        while(read_file(g_szFoodFile,lineNum++,configLine,79,iLen)) 
        {
            if(!configLine[0] || configLine[0] == ';' || configLine[0] == ' ' || ( configLine[0] == '/' && configLine[1] == '/' ))
            continue
            
            if (iLen > 0)
            {
                parse(configLine, g_FoodList[pointNum][_name], 19, price, 5, health, 9, energizer, 2)
                
                g_FoodList[pointNum][_price] = str_to_num(price)
                g_FoodList[pointNum][_health] = str_to_num(health)
                g_FoodList[pointNum][_energizer] = str_to_num(energizer)
                
                pointNum++
            }
        }
    }
    g_NrFood = pointNum
    return PLUGIN_CONTINUE
}


public SaveAll(id)
{
    new ent
    new Float:fMaxs[3]
    new Float:fOrigin[3]
    new Float:vfPoint[3]
    new Float:vlPoint[3]
    new szString[512]
    
    new iFile = fopen(g_szFile, "wt")
    
    write_file(g_szFile, "// Jailbreak Zones Spawn Editor", -1)
    write_file(g_szFile, "// Do not modify ", -1)
    
    for(new i = 0; i < typeZn; i ++)
    {
        ent = 0
        while((ent = find_ent_by_class(ent, _szType[i])) > 0)
        {
        
            entity_get_vector(ent, EV_VEC_origin, fOrigin)
            entity_get_vector(ent, EV_VEC_maxs, fMaxs)
            
            for(new j = 0; j < 3; j++)
            {
                vfPoint[j] = fOrigin[j] + fMaxs[j]
                vlPoint[j] = fOrigin[j] - fMaxs[j]
            }
            formatex(szString, 511, "%s %f %f %f %f %f %f", _szType[i],\
            vfPoint[0], vfPoint[1], vfPoint[2], vlPoint[0], vlPoint[1], vlPoint[2])
            
            write_file(g_szFile, szString,-1)
        }
    }
    
    fclose(iFile)
            
    ColorChat(id, "Salvare cu succes")
    
    return PLUGIN_HANDLED
}

public DeleteAll(id)
{
    new ent
    new net
    
    for(new i = 0; i < typeZn; i ++)
    {
        ent = 0    
        while((ent = find_ent_by_class(ent, _szType[i])) > 0)
        {
            remove_entity(ent)
            countnets--
            net++
        }
    }
    ColorChat(id, "Stergere cu succes a ^x03 %d^x01 zone", net)
}

public ShowMainMenu(id)
{
    new szBuffer[512], iLen
    new col[3], col2[3]
    
    col = (get_user_flags(id) & ADMIN_RCON) ? "\r" : "\d"
    col2 = (get_user_flags(id) & ADMIN_RCON) ? "\w" : "\d"
    
    iLen = formatex(szBuffer, sizeof szBuffer - 1, "\r[\y%s`\r] \wJail zones^n^n", PLUGIN_PREFIX)
    
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r1. \wNet Menu^n^n")
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s2. %sLoad All^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s3. %sDelete All^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s4. %sSave All^n^n^n^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \yExit", col, col2)
    
    new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<9 )
    show_menu(id, iKeys, szBuffer, -1, "Jailzones Main")
}

public HandleMainMenu(id, key)
{
    if((key == 1 || key == 2 || key == 3) && !(get_user_flags(id) & ADMIN_RCON)) {
        ShowMainMenu(id)
        return PLUGIN_HANDLED
    }
    
    switch(key)
    {
        case 0:
        {
            ShowNetMenu(id)
            return PLUGIN_HANDLED
        }
        case 1:
        {
            DeleteAll(id)
            LoadAll(id)            
        }
        case 2:
        {
            DeleteAll(id)
        }
        case 3: SaveAll(id)
        case 9: return PLUGIN_HANDLED
    }
    
    ShowMainMenu(id)

    return PLUGIN_HANDLED
}


public ShowNetMenu(id)
{
    new szBuffer[512], iLen
    new col[3], col2[3]

    col = (get_user_flags(id) & ADMIN_RCON)? "\r" : "\d"
    col2 = (get_user_flags(id) & ADMIN_RCON)? "\w" : "\d"
    
    iLen = formatex(szBuffer, sizeof szBuffer - 1, "\r[\y%s`\r] \wJail Net^n^n", PLUGIN_PREFIX)
    
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s1. %sCreate Net^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s2. %sHighlight Net^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s3. %sDelete Net^n^n", col, col2)
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "%s4. %sNet Type: %s^n^n^n^n^n", col, col2,_szType[g_buildingnettype[id]])
    iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \yBack")
    
    new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<9 )
    show_menu(id, iKeys, szBuffer, -1, "Jailzones Net")
}

public HandleNetMenu(id, key)
{
    if(key != 9 && !(get_user_flags(id) & ADMIN_RCON)) {
        ShowNetMenu(id)
        return PLUGIN_HANDLED
    }
    
    switch(key)
    {
        case 0:
        {
            if(g_buildingNet[id])
            {
                ColorChat(id, "Deja in modul de creare a plasei")
                ShowNetMenu(id)
                
                return PLUGIN_HANDLED
            }
            if(countnets >= MAX_NETS)
            {
                ColorChat(id, "Scuze, sa atins limita de plase (%d).", countnets)
                ShowNetMenu(id)
                
                return PLUGIN_HANDLED
            }
            
            g_buildingNet[id] = true
            
            ColorChat(id, "Seteaza originea din dreapta sus a cutitei")
        }
        case 1:
        {
            if(!g_bHighlight[id])
            {
                set_task(1.0, "taskShowNet", TASK_SHOWNET + id, "", 0, "b", 0)
                g_bHighlight[id] = true
                
                ColorChat(id, "Net highlight has been^x04 Enabled^x01.")
            } else {
                remove_task(TASK_SHOWNET+id)
                g_bHighlight[id] = false
                
                ColorChat(id, "Net highlight has been^x03 Disabled^x01.")
            }
        }
        case 2:
        {
            new ent, body
            new bool:bFound = false
            static classname[32]
        
            get_user_aiming(id, ent, body, 9999)
            entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname))
            
            for(new i = 0; i < typeZn; i ++)
            {
                if(is_valid_ent(ent) && equal(classname, _szType[i]))
                {
                    remove_entity(ent)
                    countnets--
                        
                    bFound = true
                    break;
                }
            }
            if(bFound == false)
            {
                new Float:fPlrOrigin[3], Float:fNearestDist = 9999.0, iNearestEnt
                new Float:fOrigin[3], Float:fCurDist
    
                pev(id, pev_origin, fPlrOrigin)
    
                new ent = -1
                for(new i = 0; i < typeZn && bFound == false; i ++)
                {
                    while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", _szType[i])) != 0)
                    {
                        pev(ent, pev_origin, fOrigin)
            
                        fCurDist = vector_distance(fPlrOrigin, fOrigin)
            
                        if(fCurDist < fNearestDist)
                        {
                            iNearestEnt = ent
                            fNearestDist = fCurDist
                        }
                    }
                }
                if(iNearestEnt > 0 && is_valid_ent(iNearestEnt))
                {
                    remove_entity(iNearestEnt)
                    countnets--
                    bFound = true
                }
                
            }
            if(bFound)
                ColorChat(id, "Plasa stearsa cu succes")
            else
                ColorChat(id, "Plasa nu a fost gasita")
        }
        case 3:
        {
            if(g_buildingnettype[id] + 1 >= typeZn)
            {
                g_buildingnettype[id] = 0;
            }
            else
            {
                g_buildingnettype[id]++;
            }
        }
        case 9:
        {
            ShowMainMenu(id)
            return PLUGIN_HANDLED
        }
    }
    
    ShowNetMenu(id)
    return PLUGIN_HANDLED
}

public ShowFoodMenu (id)
{
    static menu, option[64], num[2];
    if(!is_user_alive(id) || (get_gamemode() != 0 && get_gamemode() != 1) || get_wanted(id) || g_LastTouch[id]!=CANTEEN || g_TotalEaten[id]>=MAX_EATEN)
        return PLUGIN_CONTINUE    
        
    g_MenuType[id]=g_MenuType[id]|1;
    new money;
    money = cs_get_user_money(id);
    
    menu = menu_create("Meniu Cantina", "FoodMenuSelect")
    
    if(g_MenuType[id]&2)
    {
        menu_additem(menu,"Arata din nou meniul","showmenu",0)
    }
    else
    {
        menu_additem(menu,"Nu mai arata meniul","showmeun",0)
    }
    
    for(new i = 0; i < g_NrFood; i++)
    {
        if(money < g_FoodList[i][_price])
        {
            formatex(option, charsmax(option), "\d%s Pret $%d HP %d\w", g_FoodList[i][_name],g_FoodList[i][_price],g_FoodList[i][_health])
            menu_additem(menu, option, "exit", 0)   
        }
        else
        {
            if(g_FoodList[i][_energizer] == 1)
            {
                formatex(option, charsmax(option), "\r%s Pret $%d HP %d\w", g_FoodList[i][_name],g_FoodList[i][_price],g_FoodList[i][_health])
            }
            else
            {
                formatex(option, charsmax(option), "%s Pret $%d HP %d", g_FoodList[i][_name],g_FoodList[i][_price],g_FoodList[i][_health])
            }
            formatex(num, charsmax(option), "%d", i)
            menu_additem(menu, option, num, 0)   
        }
    }
    menu_display(id, menu)
    return PLUGIN_CONTINUE
    
}

public FoodMenuSelect (id, menu, item)
{
    if(item == MENU_EXIT )
    {
        g_MenuType[id]=g_MenuType[id]&3;
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    
    if(equal(data,"exit"))
    {
        g_MenuType[id]=g_MenuType[id]&2;
        client_print(id,print_center,"Nu ai destui bani");
        ShowFoodMenu(id)
        return PLUGIN_HANDLED
    }
    if(equal(data,"showmenu"))
    {
        g_MenuType[id]=g_MenuType[id]^2;
        return PLUGIN_HANDLED
    }
    
    new num = str_to_num(data)
    new money = cs_get_user_money(id)
    
    if(money < g_FoodList[num][_price])
    {
        client_print(id,print_center,"Nu ai destui bani");
        ShowFoodMenu(id)
        return PLUGIN_HANDLED
    }
    cs_set_user_money(id,money - g_FoodList[num][_price])
    new health = get_user_health(id) + g_FoodList[num][_health]
    if(health  > MAX_HEALTH)
    {
        fm_set_user_health(id,MAX_HEALTH)
    }
    else
    {
        fm_set_user_health(id,health)
    }
    g_TotalEaten[id]+=g_FoodList[num][_health];
    if(g_TotalEaten[id]>=MAX_EATEN)
    {
        new ids[1]
        ids[0]=id
        set_task(1.0,"make_puke",4210+id,ids,1,"a",4)
    }
    if(g_FoodList[num][_energizer]==1)
    {
        server_cmd("give_coffee %d",id);
    }
    client_print(id,print_center,"Ai terminat de mancat");
    return PLUGIN_HANDLED
}


public make_puke(ids[]) 
{ 
    new id=ids[0]
    new vec[3] 
    new aimvec[3] 
    new velocityvec[3] 
    new length 
    get_user_origin(id,vec) 
    get_user_origin(id,aimvec,3) 

    vec[2]+=20
    
    new distance = get_distance(vec,aimvec) 
    new speed = floatround(distance*1.9)
    
    velocityvec[0]=aimvec[0]-vec[0] 
    velocityvec[1]=aimvec[1]-vec[1] 
    velocityvec[2]=aimvec[2]-vec[2] 

    length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 

    velocityvec[0]=velocityvec[0]*speed/length 
    velocityvec[1]=velocityvec[1]*speed/length 
    velocityvec[2]=velocityvec[2]*speed/length 

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(101)
    write_coord(vec[0])
    write_coord(vec[1])
    write_coord(vec[2])
    write_coord(velocityvec[0]) 
    write_coord(velocityvec[1]) 
    write_coord(velocityvec[2]) 
    write_byte(195) // color
    write_byte(160) // speed
    message_end()

} 

public sqrt(num) 
{ 
	new div = num 
	new result = 1 
	while (div > result) { 
		div = (div + result) / 2 
		result = num / div 
	} 
	return div 
} 

CreateNet(szType[32], Float:firstPoint[3], Float:lastPoint[3])
{
    new ent
    new Float:fCenter[3], Float:fSize[3]
    new Float:fMins[3], Float:fMaxs[3]
        
    for ( new i = 0; i < 3; i++ )
    {
        fCenter[i] = (firstPoint[i] + lastPoint[i]) / 2.0
                
        fSize[i] = get_float_difference(firstPoint[i], lastPoint[i])
                
        fMins[i] = fSize[i] / -2.0
        fMaxs[i] = fSize[i] / 2.0
    }
    
    ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    
    if (ent) {
        engfunc(EngFunc_SetOrigin, ent, fCenter)
        
        set_pev(ent, pev_classname, szType)
    
        dllfunc(DLLFunc_Spawn, ent)
    
        set_pev(ent, pev_movetype, MOVETYPE_FLY)
        set_pev(ent, pev_solid, SOLID_TRIGGER)
    
        engfunc(EngFunc_SetSize, ent, fMins, fMaxs)
    }
}

public PlayerPreThink(id)
{
    if(!is_user_alive(id))
        return PLUGIN_CONTINUE
    
    if(pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE) && g_buildingNet[id]) {
        new Float:fOrigin[3], fOriginn[3]
        get_user_origin(id, fOriginn, 3)
    
        IVecFVec(fOriginn, fOrigin)
        if(g_buildingstage[id] == FIRST_POINT)
        {
            g_buildingstage[id] = SECOND_POINT
            
            g_fOriginBox[id][FIRST_POINT] = fOrigin
            
            ColorChat(id, "Acum selecteaza originea pentru partea de stanga jos a cutiei.")
        }
        else
        {
            g_buildingstage[id] = FIRST_POINT
            g_buildingNet[id] = false
            
            g_fOriginBox[id][SECOND_POINT] = fOrigin
            
            CreateNet(_szType[g_buildingnettype[id]],g_fOriginBox[id][FIRST_POINT], g_fOriginBox[id][SECOND_POINT])
            
            ColorChat(id, "Cutie #%d creata cu succes", ++countnets)
        }
    }
    
    return PLUGIN_HANDLED
}

public getZonesType (Classname[32])
{
    for(new i = 0; i <typeZn; i++)
    {
        if(equal(Classname,_szType[i]))
        {
            return i
        }
    }
    return -1
}

public FwdTouch(ent, id)
{
    if(is_user_alive(id))
    {
        static szNameEnt[32]
        pev(ent,pev_classname, szNameEnt,sizeof szNameEnt - 1)
        
        static Float:fGameTime
        fGameTime = get_gametime()
        if((fGameTime - g_fLastTouch[id]) > REFRESH_TIME)
        {
            //set_hudmessage(255, 20, 20, -1.0, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
            //show_hudmessage(id, "** Esti in %s ! **",szNameEnt)
            if(g_LastTouch[id] == CTZONE && cs_get_user_team(id) == CS_TEAM_T && !get_wanted(id))
            {
                client_print(id,print_center, "Esti in zona ct")
            }
            
            g_fLastTouch[id] = fGameTime
            g_LastTouch[id] = getZonesType(szNameEnt)
            remove_task(TASK_LASTTOUCH + id)
            set_task(CHANGE_TIME,"resetLastTouch",TASK_LASTTOUCH + id)
            
            if(g_LastTouch[id] == CANTEEN && g_MenuType[id]==0)
            {
                ShowFoodMenu(id);
            }
            else if(g_LastTouch[id] != CANTEEN)
            {
                g_MenuType[id]=g_MenuType[id]&2;
            }
        }
    }
}

public resetLastTouch ( id )
{
    id -= TASK_LASTTOUCH;
    g_LastTouch[id] = -1;
}

public player_killed(victim, attacker, shouldgib)
{
    new szName[50]
    if(g_LastTouch[victim] == CTZONE)
    {
        get_user_name(victim,szName,50)
        ColorChat(0,"%s a murit in Zona Ct",szName)
    }
}

public player_spawn (id)
{
    g_TotalEaten[id] = 0;
}

stock Float:get_float_difference(Float:num1, Float:num2)
{
    if(num1 > num2)
        return (num1-num2)
    else if(num2 > num1)
        return (num2-num1)
    
    return 0.0
}


public taskShowNet(id)
{
    id -= TASK_SHOWNET
    
    if(!is_user_connected(id))
    {
        remove_task(TASK_SHOWNET + id)
        return
    }
    
    new ent
    new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3]
    new vMaxs[3], vMins[3]
    for(new i = 0; i < typeZn; i ++)
    {
        ent = 0
        while((ent = find_ent_by_class(ent, _szType[i])) > 0)
        {
            pev(ent, pev_mins, fMins)
            pev(ent, pev_maxs, fMaxs)
            pev(ent, pev_origin, fOrigin)
        
            fMins[0] += fOrigin[0]
            fMins[1] += fOrigin[1]
            fMins[2] += fOrigin[2]
            fMaxs[0] += fOrigin[0]
            fMaxs[1] += fOrigin[1]
            fMaxs[2] += fOrigin[2]
            
            FVecIVec(fMins, vMins)
            FVecIVec(fMaxs, vMaxs)

            fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], _colors[i])
            fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], _colors[i])
            fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], _colors[i])
            fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], _colors[i])
            fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], _colors[i])
            fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], _colors[i])
            fm_draw_line(id, vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], _colors[i])
            fm_draw_line(id, vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], _colors[i])
            fm_draw_line(id, vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], _colors[i])
            fm_draw_line(id, vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], _colors[i])
            fm_draw_line(id, vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], _colors[i])
            fm_draw_line(id, vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], _colors[i])
        }
    }
}

stock fm_draw_line(id, x1, y1, z1, x2, y2, z2, g_iColor[3])
{
    message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id ? id : 0)
    
    write_byte(TE_BEAMPOINTS)
    
    write_coord(x1)
    write_coord(y1)
    write_coord(z1)
    
    write_coord(x2)
    write_coord(y2)
    write_coord(z2)
    
    write_short(g_iTrailSprite)
    write_byte(1)
    write_byte(1)
    write_byte(10)
    write_byte(5)
    write_byte(0)
    
    write_byte(g_iColor[0])
    write_byte(g_iColor[1])
    write_byte(g_iColor[2])
    
    write_byte(200)
    write_byte(0)
    
    message_end()
}

stock ColorChat(const id, const string[], {Float, Sql, Resul,_}:...) {
    new msg[191], players[32], count = 1
    
    static len
    len = formatex(msg, charsmax(msg), "^x04[^x03 %s^x04 ]^x01 ", PLUGIN_PREFIX)
    vformat(msg[len], charsmax(msg) - len, string, 3)

    if(id)
        players[0] = id
    else
        get_players(players,count,"ch")

    for (new i = 0; i < count; i++)
    {
        if(is_user_connected(players[i]))
        {
            message_begin(MSG_ONE_UNRELIABLE, g_SayText,_, players[i])
            write_byte(players[i])
            write_string(msg)
            message_end()
        }
    }
}