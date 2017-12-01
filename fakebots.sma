#include < amxmodx >
#include < fakemeta >

#define BotsNum 3

#define PLUGIN "NU SUNT DATE BUNE"
#define VERSION "NU SUNT DATE BUNE"
#define AUTHOR  "Askhanar"

new const BotNames [ BotsNum ][ ] =
{
   "JB.EVILS.RO",
   "VIPJB NOU! Scrie /vipjb",
   "www.evils.ro/jb"
}

new g_pEnable;
new g_pMaxPlayers;

new BotsCreated = 0;	

public plugin_init ( )
{
   register_plugin ( PLUGIN , VERSION , AUTHOR );

   g_pEnable = register_cvar ( "bw_enable" , "1" );
   g_pMaxPlayers = register_cvar ( "bw_maxplayers" , "29" );

   if ( get_pcvar_num ( g_pEnable ) )
   {
      BotsCreated = 0;
      for ( new i = 0; i < BotsNum; i++ )
      {
         CreateBot ( BotNames [ i ] );
      }
   }
}

public client_connect( id )
{
   if ( is_user_bot( id ) )  return 0;

   if ( get_playersnum ( ) >= get_pcvar_num ( g_pMaxPlayers ) )
   {
      BotsCreated--;
      server_cmd ( "kick ^"%s^"" ,  BotNames [ BotsCreated ] );
   }
   return 1;
}

public client_disconnect ( id )
{
   if ( is_user_bot ( id ) ) return 0;

   if ( get_playersnum ( ) < get_pcvar_num ( g_pMaxPlayers ) && BotsCreated < BotsNum )
   {
      CreateBot ( BotNames [ BotsCreated ] );
   }
   return 0;
}

public CreateBot ( const BotName [ ] )
{
   new id = engfunc ( EngFunc_CreateFakeClient , BotNames [ BotsCreated ] );
   engfunc ( EngFunc_FreeEntPrivateData , id );
   set_pev ( id , pev_flags , pev ( id , pev_flags ) | FL_FAKECLIENT );

   new szMsg [ 128 ];
   dllfunc ( DLLFunc_ClientConnect , id , BotNames [ BotsCreated ] , "127.0.0.1" , szMsg );
   dllfunc ( DLLFunc_ClientPutInServer , id );

   BotsCreated++;
}