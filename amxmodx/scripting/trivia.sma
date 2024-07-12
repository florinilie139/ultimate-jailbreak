#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <vip_base>

#define PLUGIN_NAME    "Trivia Manager"
#define PLUGIN_AUTHOR    "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION    "1.0"

#define TASK_GLOW 1100

//cvars
new gp_TriviaFilelist;
new gp_TriviaSpecialFile;
new gp_TriviaSpecialDelay;

#define MAXTRIVIAQUESTIONS 1000

enum _trivia { _enun[100], _ras[50], _ap, _type}
new TriviaList[MAXTRIVIAQUESTIONS][_trivia]
new TriviaType[100][100]
new TotalTrivia
new TotalTriviaType
new bool:InTrivia[33]
new Toptrivia[33]
new ShowedTrivia
new CurrentTrivia
new TimeTrivia

new QuestionForTriviaDeadPlayer[250]
new QuestionForGameTrivia[250]
new QuestionForSpecialTrivia[250]

new GameTrivia
new GameTimeTrivia
new GameCurrentTrivia
new GameCurrentType
new WinGameTrivia[2]
new LeftTopTrivia[33]
new LeftTopTriviaName[33][30]
new LeftTrivia
new DuelTrivia,DuelA,DuelB

new MoneyMade[33]
new g_MaxClients

new TriviaSpecialList[100][_trivia]
new TotalTriviaSpecial;
new SpecialTimeTrivia;
new CurrentSpecialTrivia;
new SpecialTrivia;
new Float:SpecialTriviaTriggerTime;

enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }

new const g_HudSync[][_hud] ={
    {0, -1.0,  0.8,  2.0},
    {0, -1.0,  0.85, 2.0}
}

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

    gp_TriviaFilelist = register_cvar("trivia_filelist", "TriviaList.ini");
    gp_TriviaSpecialFile = register_cvar("trivia_special_file", "TriviaSpecialFile.ini");
    gp_TriviaSpecialDelay = register_cvar("trivia_special_delay", "150.0");

    LoadTrivia();
    
    register_logevent("round_end", 2, "1=Round_End")
    
    register_clcmd("say !top", "ShowTriviaTop");
    register_clcmd("say !triviatop", "ShowTriviaTop");
    register_clcmd("say !trivia", "ShowTriviaTop");
    register_clcmd("say", "cmd_trivia");
    register_clcmd("trivia", "cmd_trivia");
    register_clcmd("say /trivia", "Trivia");
    register_srvcmd("simon_trivia","simon_trivia");
    register_srvcmd("duel_trivia", "duel_trivia");

    g_MaxClients = get_global_int(GL_maxClients)

    //for(new i = 0; i < sizeof(g_HudSync); i++)
    //    g_HudSync[i][_hudsync] = CreateHudSyncObj()
}

public plugin_precache()
{
    precache_sound("jbextreme/brass_bell_C.wav")
}

public client_putinserver (id)
{
    Toptrivia[id]=0
    InTrivia[id] = false
    check_toptrivia(id)
}

public client_disconnected (id)
{
    put_in_top_trivia(id)
}

public LoadTriviaFromFile(const FilePath[], const ListToTriviaToAdd[][], IndexFrom, TriviaType)
{
    new lineNum = 0, line[150], iLen2;
    new triviaAdded = IndexFrom;
    while (read_file(FilePath, lineNum++, line, 149, iLen2))
    {
        if (iLen2 > 0) {
            trim(line);
            strtok(line, ListToTriviaToAdd[triviaAdded][_enun], 99, ListToTriviaToAdd[triviaAdded][_ras], 49, ';');
            ListToTriviaToAdd[triviaAdded][_ap] = 0;
            ListToTriviaToAdd[triviaAdded][_type] = TriviaType;
            triviaAdded++;
        }
        if(triviaAdded >= MAXTRIVIAQUESTIONS)
        {
            log_amx("Nu se mai pot incarca intrebari, numarul maxim a fost atins");
            return triviaAdded;
        }
    }
    return triviaAdded;
}

public LoadTrivia()
{
    new trivialists[100], configDir[100], iLen, fileline = 0, triviaFileList[50];
    TotalTriviaType = 1;
    TotalTrivia = 0;
    TotalTriviaSpecial = 0;
    get_configsdir(configDir, 65);
    get_pcvar_string(gp_TriviaFilelist, triviaFileList, 50);
    format(trivialists, 100, "%s/%s", configDir, triviaFileList);
    if(file_exists(trivialists)){
        while(read_file(trivialists, fileline++, TriviaType[TotalTriviaType],99,iLen)) 
        {
            if(iLen>0 && TriviaType[TotalTriviaType][0] != ';'){
                new triviaq[150]
                format(triviaq,149,"%s/TriviaList/%s", configDir,TriviaType[TotalTriviaType])
                if(file_exists(triviaq)){
                    TotalTrivia = LoadTriviaFromFile(triviaq, TriviaList, TotalTrivia, TotalTriviaType);

                    for(new parg = 0;parg < iLen; parg ++)
                    {
                        if(TriviaType[TotalTriviaType][parg] == '_' || TriviaType[TotalTriviaType][parg] == '-')
                            TriviaType[TotalTriviaType][parg] = ' '
                        else if(TriviaType[TotalTriviaType][parg] == '.'){
                            TriviaType[TotalTriviaType][parg] = 0
                            break
                        }
                    }
                    TotalTriviaType++
                    if(TotalTrivia >= MAXTRIVIAQUESTIONS)
                    {
                        break;
                    }
                }
                else{
                    log_amx("Nu sa gasit %s",TriviaType[TotalTriviaType])
                }
            }
        }
    }
    else{
        log_amx("Nu sa gasit TriviaList.ini")
    }

    get_pcvar_string(gp_TriviaSpecialFile, triviaFileList, 50);
    format(trivialists, 100, "%s/%s", configDir, triviaFileList);

    if (file_exists(trivialists)) {
        TotalTriviaSpecial = LoadTriviaFromFile(trivialists, TriviaSpecialList, TotalTriviaSpecial, 0)
    }
    else {
        log_amx("Nu sa gasit TriviaSpecialFile.ini")
    }

    if (TotalTrivia > 0)
        ShowQuestion();

    SpecialTriviaTriggerTime = get_pcvar_float(gp_TriviaSpecialDelay);

    if(TotalTriviaSpecial>0)
        set_task(SpecialTriviaTriggerTime, "SpecialShowQuestion", 54321, "", 0, "", 0);
}

public round_end ()
{
    GameTrivia = 0
    GameTimeTrivia = 0
    DuelTrivia = 0
    DuelA = 0
    DuelB = 0
    remove_task(222200);
    for(new i = 1; i <= g_MaxClients; i++)
        MoneyMade[i] = 0
}

public Trivia (id)
{
    if(InTrivia[id] == false){
        message_begin( MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id );
        write_byte  ( id );
        write_string( "^x03[Trivia]^x04 Bine ai venit la trivia, pentru a raspunde scrie ^x01/r" );
        message_end ();
        InTrivia[id] = true
    }else{
        message_begin( MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id );
        write_byte  ( id );
        write_string( "^x03[Trivia]^x04 Multumim ca ai jucat trivia");
        message_end ();
        InTrivia[id] = false
    }
}

public SelectQuestionForTriviaDeadPlayer(StringToSaveText[], LengthForText)
{
    if (ShowedTrivia == TotalTrivia)
    {
        for (new parg = 0; parg < TotalTrivia; parg++)
        {
            TriviaList[parg][_ap] = 0;
        }
        ShowedTrivia = 0;
    }
    new RndNum = random_num(0, TotalTrivia - 1);
    while (TriviaList[RndNum][_ap] == 1)
    {
        RndNum = random_num(0, TotalTrivia - 1);
    }
    ShowedTrivia++;
    CurrentTrivia = RndNum;
    TimeTrivia = 30;
    TriviaList[RndNum][_ap] = 1;

    format(StringToSaveText, LengthForText, "%s : %s", TriviaType[TriviaList[RndNum][_type]], TriviaList[RndNum][_enun])
}

public ShowQuestionToPlayers(Text[], TimeForQuestion)
{
    new textForChat[250];
    format(textForChat, 250, "^x03[Trivia]^x01%s", Text);

    for (new Player = 1; Player <= g_MaxClients; Player++)
    {
        if (cmd_is_in_trivia(Player) != 1)
            continue;

        message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
        write_byte(Player);
        write_string(textForChat);
        message_end();
        player_hudmessage(Player, 0, 1.0, { 200, 100, 0 }, textForChat);
        player_hudmessage(Player, 1, 1.0, { 200, 100, 0 }, "Timp : %d", TimeForQuestion);
    }
}

public ShowQuestion()
{
    if(task_exists(2222))
        remove_task(2222);
    if(TimeTrivia == 0)
    {
        SelectQuestionForTriviaDeadPlayer(QuestionForTriviaDeadPlayer, 250);
        ShowQuestionToPlayers(QuestionForTriviaDeadPlayer, TimeTrivia);
    }
    else{
        for(new Player  = 1 ; Player <= g_MaxClients; Player ++)
        {            
            if (cmd_is_in_trivia(Player) != 1)
                continue;
            
            player_hudmessage(Player, 0, 1.0, {200, 100, 0}, QuestionForTriviaDeadPlayer)
            player_hudmessage(Player, 1, 1.0, {200, 100, 0}, "Timp : %d",TimeTrivia)
        }
        TimeTrivia--
    }
    set_task(1.0, "ShowQuestion", 2222, "", 0, "", 0);
}

public ShowGameQuestionToPlayers(Text[], TimeForQuestion)
{
    new textForChat[250];
    format(textForChat, 250, "^x03[Trivia]^x01%s", Text);

    for (new Player = 1; Player <= g_MaxClients; Player++)
    {
        if (!is_user_connected(Player))
            continue;
        
        message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
        write_byte(Player);
        write_string(textForChat);
        message_end();
        player_hudmessage(Player, 0, 1.0, { 200, 100, 0 }, textForChat);
        player_hudmessage(Player, 1, 1.0, { 200, 100, 0 }, "Timp : %d", TimeForQuestion);
    }
}

public GameShowQuestion()
{
    if(task_exists(222200))
        remove_task(222200);
    if(GameTrivia==0)
        return
    if(GameTimeTrivia == 0){
        new RndNum = random_num(0, TotalTrivia - 1);

        GameTimeTrivia = 30
        if(GameCurrentType != 0){
            while(TriviaList[RndNum][_type] != GameCurrentType)
                RndNum = random_num(0, TotalTrivia - 1);
        }
        GameCurrentTrivia = RndNum;
        
        format(QuestionForGameTrivia, 250, "%s : %s", TriviaType[TriviaList[RndNum][_type]], TriviaList[RndNum][_enun]);
        ShowGameQuestionToPlayers(QuestionForGameTrivia, GameTimeTrivia);
    }
    else{

        for(new Player = 1 ; Player <= g_MaxClients; Player++)
        {            
            if(!is_user_connected(Player))
                continue;
            
            player_hudmessage(Player, 0, 1.0, { 200, 100, 0 }, QuestionForGameTrivia);
            player_hudmessage(Player, 1, 1.0, { 200, 100, 0 }, "Timp : %d", GameTimeTrivia);
        }
        GameTimeTrivia--;
    }

    set_task(1.0, "GameShowQuestion", 222200, "", 0, "", 0);
}

public SelectQuestionForSpecialTrivia(StringToSaveText[], LengthForText)
{
    new RndNum = random_num(0, TotalTriviaSpecial - 1);
    while (TriviaSpecialList[RndNum][_ap] == 1)
    {
        RndNum = random_num(0, TotalTriviaSpecial - 1);
    }
    CurrentSpecialTrivia = RndNum;
    SpecialTimeTrivia = 30;
    TriviaSpecialList[RndNum][_ap] = 1;

    format(StringToSaveText, LengthForText, "Scrie cuvantul acesta pentru puncte de skilluri : %s", TriviaSpecialList[RndNum][_enun])
}


public SpecialShowQuestion()
{
    if (task_exists(54321))
        remove_task(54321);
    if (SpecialTrivia == 0){
        SpecialTrivia = 1
        SelectQuestionForSpecialTrivia(QuestionForSpecialTrivia, 250)
        for (new Player = 1; Player <= g_MaxClients; Player++)
        {
            if (!is_user_connected(Player))
                continue;

            message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
            write_byte(Player);
            write_string(QuestionForSpecialTrivia);
            message_end();
        }
        set_task(1.0, "SpecialShowQuestion", 54321, "", 0, "", 0);
    }
    else if (SpecialTimeTrivia == 0)
    {
        SpecialTrivia = 0;
        for (new Player = 1; Player <= g_MaxClients; Player++)
        {
            if (!is_user_connected(Player))
                continue;

            message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
            write_byte(Player);
            write_string("Nimeni nu a raspuns la trivia skill!");
            message_end();
        }
        set_task(SpecialTriviaTriggerTime, "SpecialShowQuestion", 54321, "", 0, "", 0);
    }
    else {
        SpecialTimeTrivia--;
        set_task(1.0, "SpecialShowQuestion", 54321, "", 0, "", 0);
    }

}

public cmd_is_in_trivia(id)
{
    if (is_user_connected(id))
    {
        if (InTrivia[id] && (!is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR))
        {
            return 1;
        }
        if ((DuelTrivia == 1 && (DuelA == id || DuelB == id) || GameTrivia == 1 && cs_get_user_team(id) == CS_TEAM_T) && is_user_alive(id))
        {
            return 2;
        }
    }
    return 0;
}

public show_winner_of_trivia(id, prize[])
{
    new Name[50]
    get_user_name(id, Name, 49);

    new text[250];
    format(text, 249, "^x03[Trivia]^x01 %s a raspuns correct, a castigat %s", Name, prize);

    for (new Player = 1; Player <= g_MaxClients; Player++)
    {
        if (!is_user_connected(Player) || cmd_is_in_trivia(Player) != 1)
            continue;

        message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
        write_byte(Player);
        write_string(text);
        message_end();

        //emit_sound(Player, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
}

public DealWithTheDuel(id)
{
    if (id == DuelA)
        WinGameTrivia[0]++;
    else
        WinGameTrivia[1]++;

    if (WinGameTrivia[0] >= 3)
    {
        user_kill(DuelB);
        DuelTrivia = 0;
        server_cmd("give_points %d 3", DuelA);
        DuelA = 0;
        DuelB = 0;
    }
    else if (WinGameTrivia[1] >= 3)
    {
        user_kill(DuelA);
        DuelTrivia = 0;
        server_cmd("give_points %d 1", DuelB);
        DuelA = 0;
        DuelB = 0;
    }
    else
    {
        GameTimeTrivia = 0;
        GameCurrentTrivia = 0;
        remove_task(222200);
        set_task(5.0, "GameShowQuestion", 222200, "", 0, "", 0);
    }
}

public show_winner_of_game_trivia(id)
{
    new Name[50];
    new text[250];
    new score[250];
    get_user_name(id, Name, 49);
    format(text, 249, "^x03[Trivia]^x01 %s a raspuns correct", Name);
    if(DuelTrivia == 1)
        format(score, 249, "^x03[Trivia]^x01 Scorul este %d:%d", WinGameTrivia[0], WinGameTrivia[1]);

    for (new Player = 1; Player <= g_MaxClients; Player++)
    {
        if (!is_user_connected(Player))
            continue;

        message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
        write_byte(Player);
        write_string(text);
        message_end();

        if (DuelTrivia == 1) {
            message_begin(MSG_ONE, get_user_msgid("SayText"), { 0,0,0 }, Player);
            write_byte(Player);
            write_string(score);
            message_end();
        }
    }
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public cmd_trivia (id)
{
    if(is_user_connected(id))
    {
        new Args[256];
        new line = read_argv(0, Args, 255);

        Args[line++]=' ';
        read_argv(1, Args[line], 255);

        if((equali(Args,"trivia",6) || equali(Args,"say /r ",6)) && (cmd_is_in_trivia(id) != 0)){
            if(cmd_is_in_trivia(id) == 1 && containi(Args, TriviaList[CurrentTrivia][_ras]) != -1){
                if(MoneyMade[id] > 16000)
                {
                    message_begin( MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id );
                    write_byte  ( id );
                    write_string( "^x03[Trivia]^x04 Nu mai poti raspunde la intrebari deoarece deja ai facut ^x01$16000!");
                    message_end ();
                    return PLUGIN_CONTINUE
                }
                new PrizeMoney = 0;
                new PrizeString[50];
                
                if(get_vip_type(id) == 2)
                {
                    PrizeMoney = TimeTrivia*40;
                }
                else
                {
                    PrizeMoney = TimeTrivia * 20;
                }

                cs_set_user_money(id, cs_get_user_money(id) + PrizeMoney);
                Toptrivia[id] ++;
                if (Toptrivia[id] % 20 == 0) //every 20 questions answered right, it gets a point
                    server_cmd("give_points %d 1", id);

                format(PrizeString, 50, "^x01$%d!", PrizeMoney);
                show_winner_of_trivia(id, PrizeString);
                TimeTrivia = 0;
                ShowQuestion();
            }
            else if (cmd_is_in_trivia(id) == 2 && containi(Args, TriviaList[GameCurrentTrivia][_ras]) != -1) {
                remove_task(222200);

                set_user_rendering(id, kRenderFxGlowShell, 225, 165, 0, kRenderNormal, 25);
                set_task(10.0, "turn_glow_off", TASK_GLOW + id);

                if (GameTrivia == 1) {
                    server_cmd("give_points %d 1", id);
                    GameTrivia = 0;
                    GameTimeTrivia = 0;
                }
                else if (DuelTrivia == 1)
                {
                    DealWithTheDuel(id);
                }

                show_winner_of_game_trivia(id);
            }
            return PLUGIN_HANDLED;
        }
        if (SpecialTrivia == 1 && containi(Args, TriviaSpecialList[CurrentSpecialTrivia][_ras]) != -1)
        {
            remove_task(54321);
            server_cmd("give_points %d 2", id);
            show_winner_of_trivia(id, "2 Puncte Skill");
            SpecialTrivia = 0;
            SpecialTimeTrivia = 0;
            set_task(SpecialTriviaTriggerTime, "SpecialShowQuestion", 54321, "", 0, "", 0);
        }
    }
    return PLUGIN_CONTINUE;
}

public turn_glow_off (id)
{
    if(id > TASK_GLOW)
    {
        id -= TASK_GLOW;
    }
    if(is_user_alive(id))
    {
        set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
    }
}

public ShowTriviaTop (id)
{
    static Sort[100][2];
    new Count;
    
    for(new Player = 1 ; Player <= g_MaxClients ; Player++)
    {
        if (!is_user_connected(Player))
            continue;

        
        Sort[Count][0] = Player;
        Sort[Count][1] = Toptrivia[Player];
        
        Count++;
    }
    for(new i = 0 ; i < LeftTrivia ; i++)
    {
        Sort[Count][0] = 100+i;
        Sort[Count][1] = LeftTopTrivia[i];
        
        Count++;
    }
    
    SortCustom2D(Sort, Count, "points_compare");
    
    new Motd[1024], Len;    
    
    Len = format(Motd, sizeof Motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
    Len += format(Motd[Len], (sizeof Motd - 1) - Len,"%s %-22.22s %3s^n", "#", "Name", "Trivia Points");
    
    
    new b = clamp(Count, 0, 10);
    
    new Name[32], User;
    
    for(new a = 0; a < b; a++)
    {
        User = Sort[a][0];
        
        if(User<100)
            get_user_name(User, Name, sizeof Name - 1);        
        if(User>100)
            format(Name,31,"%s",LeftTopTriviaName[User-100])
        Len += format(Motd[Len], (sizeof Motd - 1) - Len,"%d %-22.22s %d^n", a + 1, Name, Sort[a][1]);
    }
    Len += format(Motd[Len], (sizeof Motd - 1) - Len,"</body></font></pre>");
    
    show_motd(id, Motd, "Trivia Top 10");
}

public points_compare(elem1[], elem2[])
{
    if(elem1[1] > elem2[1])
        return -1;
    else if(elem1[1] < elem2[1])
        return 1;
    
    return 0;
}
public sort_trivia ()
{
    for(new parg=0;parg<LeftTrivia-1;parg++)
        for(new parg2=0;parg2<LeftTrivia;parg2++)
            if(LeftTopTrivia[parg]<LeftTopTrivia[parg2]){
                new name[30],nr
                format(name,29,"%s",LeftTopTriviaName[parg])
                format(LeftTopTriviaName[parg],29,"%s",LeftTopTriviaName[parg2])
                format(LeftTopTriviaName[parg2],29,"%s",name)
                nr = LeftTopTrivia[parg]
                LeftTopTrivia[parg] = LeftTopTrivia[parg2]
                LeftTopTrivia[parg2] = nr
            }
}

public simon_trivia ()
{
    new id[3]
    read_argv(1, id, 2)
    GameTrivia = 1
    menu_trivia(str_to_num(id))
}    
public menu_trivia(id)
{
    static i, num[5], menu, menuname[32];
    formatex(menuname, charsmax(menuname), "Trivia list")
    menu = menu_create(menuname, "select_list")
    menu_additem(menu, "Toate categoriile", "0", 0)
    for(i = 1; i < TotalTriviaType; i++)
    {
        num_to_str(i,num,4)
        menu_additem(menu, TriviaType[i], num, 0)
    }
    menu_display(id, menu)
}
public select_list (id, menu, item)
{
    if(item == MENU_EXIT)
    {
        GameCurrentType = 0
        GameTimeTrivia = 0
        GameTrivia = 0
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    static dst[32], data[5], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
    menu_destroy(menu)
    GameCurrentType = str_to_num(data)
    GameTimeTrivia = 0
    GameShowQuestion()
    emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    return PLUGIN_CONTINUE
}

public duel_trivia ()
{
    new id[3],player[3]
    if(DuelTrivia != 0)
    {
        return;
    }
    read_argv(1, id, 2)
    read_argv(2, player, 2)
    WinGameTrivia[0] = 0
    WinGameTrivia[1] = 0
    DuelA = str_to_num(id)
    DuelB = str_to_num(player)
    DuelTrivia = 1;
    GameTrivia = 1;
    /* in ujbm main
    player_glow(id, g_Colors[3])
    player_glow(player, g_Colors[2])*/
    menu_trivia(DuelA)
}

public put_in_top_trivia (id)
{
    get_user_name(id,LeftTopTriviaName[LeftTrivia],29)
    LeftTopTrivia[LeftTrivia] = Toptrivia[id]
    if(LeftTrivia<32)
    LeftTrivia++
    sort_trivia();
}

public check_toptrivia (id)
{
    new name[32]
    get_user_name(id,name, 31)
    for(new parg=0; parg<LeftTrivia; parg++)
    if(contain(LeftTopTriviaName[parg],name) != -1){
        Toptrivia[id]=LeftTopTrivia[parg]
        LeftTopTrivia[parg]=-1
        sort_trivia()
        LeftTrivia--
        break;
    }
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
    static text[512], Float:x, Float:y
    x = g_HudSync[hudid][_x]
    y = g_HudSync[hudid][_y]

    if(time > 0)
        set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
    else
        set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)
        
    vformat(text, charsmax(text), msg, 6)
    show_dhudmessage(id, text)
}