#include < amxmodx >
#include < fakemeta >
#include < orpheu >
#include < orpheu_stocks >

#define PLUGIN "PM_CheckVelocity debugger"
#define VERSION "0.1"
#define AUTHOR "meTaLiCroSS"

new OrpheuStruct:g_pPMove

public plugin_init( )
{
    register_plugin( PLUGIN, VERSION, AUTHOR )
    
    OrpheuRegisterHook( OrpheuGetDLLFunction( "pfnPM_Move", "PM_Move" ), "PM_Move" );
    OrpheuRegisterHook( OrpheuGetFunction( "PM_CheckVelocity" ), "PM_CheckVelocity" );
}

public PM_Move( OrpheuStruct:ppmove, server )
{
    g_pPMove = ppmove;
}

public PM_CheckVelocity( )
{
    static i, iPlayer, szConsolePrint[64], Float:flMaxVelocity, Float:vecVelocity[3]
    iPlayer = OrpheuGetStructMember( g_pPMove, "player_index" ) + 1;
    flMaxVelocity = Float:OrpheuGetStructMember( OrpheuStruct:OrpheuGetStructMember( g_pPMove, "movevars" ), "maxvelocity" );
    OrpheuGetStructMember( g_pPMove, "velocity", vecVelocity );
    
    for(i = 0; i < 3; i++)
    {
		if(		vecVelocity[i]
        if(vecVelocity[i] > flMaxVelocity)
        {
            formatex( szConsolePrint, charsmax(szConsolePrint), "PM %d Got a velocity too high on %d^n", iPlayer, i );
            engfunc( EngFunc_AlertMessage, at_aiconsole, szConsolePrint )
            
            vecVelocity[i] = flMaxVelocity // skip original engine message
            OrpheuSetStructMember( g_pPMove, "velocity", vecVelocity )
            
        }
        else if(vecVelocity[i] < -flMaxVelocity)
        {
            formatex( szConsolePrint, charsmax(szConsolePrint), "PM %d Got a velocity too low on %d^n", iPlayer, i );
            engfunc( EngFunc_AlertMessage, at_aiconsole, szConsolePrint )
            
            vecVelocity[i] = -flMaxVelocity // skip original engine message
            OrpheuSetStructMember( g_pPMove, "velocity", vecVelocity )
        }
    }
    /*
    if (pmove->velocity[i] > pmove->movevars->maxvelocity) 
    {
        pmove->Con_DPrintf ("PM  Got a velocity too high on %i\n", i);
        pmove->velocity[i] = pmove->movevars->maxvelocity;
    }
    else if (pmove->velocity[i] < -pmove->movevars->maxvelocity)
    {
        pmove->Con_DPrintf ("PM  Got a velocity too low on %i\n", i);
        pmove->velocity[i] = -pmove->movevars->maxvelocity;
    }*/
} 