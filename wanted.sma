#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>

new bool:is_wanted[33]=false,placed_amount[33]=0
static tname[33]

public plugin_init()
{
    RegisterHam(Ham_Killed, "player", "player_killed");
}

public client_command(id)
{
    new Said[195]
    read_args(Said,charsmax(Said))
    remove_quotes(Said)
    
    static szArg1[32],szArg2[32],szArg3[32]
    
    szArg1[0]='^0'
    szArg2[0]='^0'
    szArg3[0]='^0'
    
    parse(Said,szArg1,31,szArg2,31,szArg3,32)
    
    if(equal(szArg1,"/wanteds",strlen("/wanteds")))
    {
        new wantedsnames[33][32],message[256],players,count,x,len
        
        for(players=1;players<=get_maxplayers();players++)
            if(is_user_connected(players)&&is_wanted[players])
                get_user_name(players,wantedsnames[count++],31)
        
        len=formatex(message,charsmax(message),"!v[AMXX]!n Recompense puse: ")
        
        if(count>0)
        {
            for(x=0;x<count;x++)
            {
                len+=formatex(message[len],charsmax(message)-len,"!n[!e %s!n ]!v %s!n ",wantedsnames[x],x<(count-1)?" | ": "")
                
                if(len>96)
                {
                    len=formatex(message,charsmax(message),"")
                    xCoLoR(id,message)
                }
            }
            xCoLoR(id,message)
        }
        else
        {
            len+=formatex(message[len],charsmax(message)-len,"!nNu sunt!e Recompense!n de afisat!")
            xCoLoR(id,message)
        }
    }
    else if(equal(szArg1,"/wanted",8))
    {
        new amount=str_to_num(szArg3)
        new tgt=cmd_target(id,szArg2,CMDTARGET_NO_BOTS)
        if(!tgt||id==tgt||get_user_team(tgt)==3||get_user_team(tgt)==6)    return PLUGIN_HANDLED
        if(!amount||amount<=0)    
            return PLUGIN_HANDLED
        if(cs_get_user_money(id) < amount)
        {
            xCoLoR(id,"!v[AMXX]!n Nu detii acesta suma!n !")
            return PLUGIN_HANDLED
        }
        if(amount>16000)
        {
            xCoLoR(id,"!v[AMXX]!n Suma maxima pentru Recompensa Oferita, nu poate fi mai mare de!e 16,000$!n !")
            return PLUGIN_HANDLED
        }
        if(get_user_team(id)!=1)
        {
            xCoLoR(id,"!v[AMXX]!n Doar!e T!n poate pune!v RECOMPENSE!n !")
            return PLUGIN_HANDLED
        }
        if(get_user_team(tgt)!=2)
        {
            xCoLoR(id,"!v[AMXX]!n Se pot pune Recompense doar pe cei de la!e CT!n !")
            return PLUGIN_HANDLED
        }
        if(!is_user_alive(tgt))
        {
            xCoLoR(id,"!v[AMXX]!n Jucatorul specificat nu este in!e Viata!n !")
            return PLUGIN_HANDLED
        }
        is_wanted[tgt]=true
        if(placed_amount[tgt] + amount>40000)
        {
            xCoLoR(id,"!v[AMXX]!n Suma totala pentru Recompensa Oferita, nu poate fi mai mare de!e 40,000$!n !")
            if(placed_amount[tgt]-amount<40000)
                xCoLoR(id,"!v[AMXX]!n Poti paria momentan doar!e %s$!n!",placed_amount[tgt])
            return PLUGIN_HANDLED
        }
        cs_set_user_money(id, cs_get_user_money(id) - amount);
        placed_amount[tgt] = placed_amount[tgt] + amount;
        get_user_name(tgt,tname,charsmax(tname))
        xCoLoR(0,"!v[AMXX]!n S-a pus o recompensă pe capul lui.e %s!n , in valoare de!v %s$!n.",tname,amount)
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE;
}

public player_killed(victim, attacker, shouldgib)
{
    if(!is_user_alive(victim)||!is_user_connected(attacker))    
        return HAM_IGNORED
    if(is_user_alive(victim) && get_user_team(victim) == 2
        && is_wanted[victim] && get_user_team(attacker) == 1)
    {
        new kname[33],vname[33]
        get_user_name(attacker,kname,charsmax(kname))
        get_user_name(victim,vname,charsmax(vname))
        cs_set_user_money(attacker,cs_get_user_money(attacker)+placed_amount[victim])
        xCoLoR(0,"!v[AMXX]!n Se pare ca!e %s!n l-a ucis pe!v %s!n, acesta primid recompensa de!v %s$!n.",kname,vname,placed_amount[victim])
        placed_amount[victim]=0
        is_wanted[victim]=false
    }
    return HAM_IGNORED
}

stock xCoLoR(const id,const input[],any:...)
{
    new count=1,players[32]
    static msg[195]
    
    vformat(msg,charsmax(msg),input,3)
    
    replace_all(msg,charsmax(msg),"!v","^4");
    replace_all(msg,charsmax(msg),"!n","^1");
    replace_all(msg,charsmax(msg),"!e","^3");
    replace_all(msg,charsmax(msg),"!e2","^0");
    
    if(id)
        players[0]=id
    else 
        get_players(players,count,"ch")

    for(new i=0;i<=count;i++)
        if(is_user_connected(players[i]))
        {
            message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i])
            write_byte(players[i])
            write_string(msg)
            message_end()
        }
}