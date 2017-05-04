/* Plugin generated by AMXX-Studio */
/* Original code "Cam by XunTric" */
#include <amxmodx>
#include <engine>
#include <colorchat>

#define PLUGIN "Camera Plugin"
#define VERSION "2.0"
#define AUTHOR "eNd."
#pragma semicolon 1
//Prefix//
new 
const szPrefix[] = "JBRomania.Ro";
/////////
//Cvar//
new
cam_on, cam_3d_on , cam_top_on , cam_left_on, cam_normal_on, cam_alien_on, cam_msg_type;
/////////
//Bool//
new bool:
CamOn[33], DOn[33], TopOn[33], NormalOn[33], LeftOn[33];
new bool:
Alien3D[33],  AlienTop[33] ,AlienNormal[33], AlienLeft[33];
////////
//Hud//
new
g_bHud;
////////
public plugin_init() {
   register_plugin(PLUGIN, VERSION, AUTHOR);
   //////////////////////////////////////////////////////
   //Cvar
   cam_on = register_cvar("cam_on", "1");
   cam_3d_on = register_cvar("cam_3d_on", "1");
   cam_top_on = register_cvar("cam_top_on", "1");
   cam_left_on = register_cvar("cam_left_on", "1");
   cam_normal_on = register_cvar("cam_normal_on", "1");
   cam_alien_on = register_cvar("cam_alien_on", "1");
   //Msg Type , 1 = color , 2 =normal , 3 = hud.
   cam_msg_type = register_cvar("cam_msg_type", "1");
   //Hook
   register_clcmd("say", "hook_say");
   register_clcmd("say_team", "hook_say");
   //////////////////////////////////////////////////////   
}
public hook_say(id) {
   static Arg[192];
   
   read_args(Arg, sizeof(Arg) - 1);
   remove_quotes(Arg);
   
   if(equal(Arg, "/cam", 5) || equal(Arg,"/camera",10)) {
      replace(Arg, sizeof(Arg) - 1, "/", "");
      Menu_Cam(id);
   }   
      
   return PLUGIN_CONTINUE;
}

public plugin_precache()
{
   g_bHud = CreateHudSyncObj();
   precache_model("models/rpgrocket.mdl");
}

public Menu_Cam(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   if(!is_user_alive(id) || is_user_bot(id))
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 poti folosi comanda doar cand esti^x03 viu.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s poti folosi comanda doar cand esti viu.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s poti folosi comanda doar cand esti viu.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }
   if(get_pcvar_num(cam_on) && !CamOn[id]) 
      Show_Menu_Cam(id);
   
   else if(!get_pcvar_num(cam_on))
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 pluginul cam este^x03 dezactivat.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s pluginul cam este dezactivat.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s pluginul cam este dezactivat.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }   
   else if(CamOn[id])
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in meniul^x03 cam.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s esti deja in meniul cam.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in meniul cam.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }   
   DOn[id] = false;
   TopOn[id] = false;
   NormalOn[id] = false;
   Alien3D[id] = false;
   AlienTop[id] = false;
   AlienNormal[id] = false;
   AlienLeft[id] = false;
   LeftOn[id] = false;
   ResetFov(id);
   return PLUGIN_HANDLED;
}

public Show_Menu_Cam(id)
{
   new szCam = menu_create("\rVizualizare \dCamera^n\r", "Show_SubMenu_Cam");
   
   menu_additem(szCam, " \rVizualizare \d3D", "1", 0);
   menu_additem(szCam, " \rVizualizare \dde Sus", "2", 0);
   menu_additem(szCam, " \rVizualizare \dNormala", "3", 0);
   menu_additem(szCam, " \rVizualizare \dStanga", "4", 0);
   
   menu_setprop(szCam, MPROP_EXIT, MEXIT_ALL);
   menu_display(id, szCam, 0);
   CamOn[id] = true;
}
public Show_SubMenu_Cam(id, szCam, item)
{
   if( item == MENU_EXIT )
   {
      menu_destroy(szCam);
      CamOn[id] = false;
      return PLUGIN_HANDLED;
   }
   new data[6], iName[64];
   new access, callback;
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   menu_item_getinfo(szCam, item, access, data,5, iName, 63, callback);
   
   new key = str_to_num(data);
   
   switch(key)
   {
      case 1: Cam3D(id);
         case 2: CamTop(id);
         case 3: CamNormal(id);
         case 4: CamLeft(id);
      }
   menu_destroy(szCam);
   CamOn[id] = false;
   return PLUGIN_HANDLED;
}
public Cam3D(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   if(get_pcvar_num(cam_3d_on))
   {
      new sz3D = menu_create("\rVizualizare \d3D^n\r", "Show_SubMenu_3D");
      
      menu_additem(sz3D, " \rVizualizare \d3D", "1", 0);
      menu_additem(sz3D, " \rVizualizare \d3D & Alien", "2", 0);
      
      menu_setprop(sz3D, MPROP_EXIT, MEXIT_ALL);
      menu_display(id, sz3D, 0);
   }
   else
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 modul 3d este^x03 dezactivat.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s modul 3d este dezactivat.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s modul 3d este dezactivat.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }
   return PLUGIN_HANDLED;
}
public CamTop(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   if(get_pcvar_num(cam_top_on))
   {
      new szTop = menu_create("\rVizualizare \dTop^n\r", "Show_SubMenu_TOP");
      
      menu_additem(szTop, " \rVizualizare \dTop", "1", 0);
      menu_additem(szTop, " \rVizualizare \dTop & Alien", "2", 0);
      
      menu_setprop(szTop, MPROP_EXIT, MEXIT_ALL);
      menu_display(id, szTop, 0);
   }
   else 
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 modul top este^x03 dezactivat.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s modul top este dezactivat.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s modul top este dezactivat.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }
   return PLUGIN_HANDLED;
}
public CamNormal(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   if(get_pcvar_num(cam_normal_on))
   {
      new szNormal = menu_create("\rVizualizare \dNormal^n\r", "Show_SubMenu_NORMAL");
      
      menu_additem(szNormal, " \rVizualizare \dNormal", "1", 0);
      menu_additem(szNormal, " \rVizualizare \dNormal & Alien", "2", 0);
      
      menu_setprop(szNormal, MPROP_EXIT, MEXIT_ALL);
      menu_display(id, szNormal, 0);
   }
   else 
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 modul normal este^x03 dezactivat.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s modul normal este dezactivat.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s modul normal este dezactivat.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }
   return PLUGIN_HANDLED;
}
public CamLeft(id)
{
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   if(get_pcvar_num(cam_left_on))
   {
      new szLeft = menu_create("\rVizualizare \dStanga^n\r", "Show_SubMenu_LEFT");
      
      menu_additem(szLeft, " \rVizualizare \dStanga", "1", 0);
      menu_additem(szLeft, " \rVizualizare \dStanga & Alien", "2", 0);
      
      menu_setprop(szLeft, MPROP_EXIT, MEXIT_ALL);
      menu_display(id, szLeft, 0);
   }
   else 
   {
      switch(get_pcvar_num(cam_msg_type)) {
         case 1: 
         {
            ColorChat(id, GREEN,"%s^x03 %s^x01 modul left este^x03 dezactivat.^x01", szPrefix, szName);   
         }
         case 2: 
         {
            client_print(id, print_chat, "%s %s modul left este dezactivat.", szPrefix, szName);
         }
         case 3:
         {
            set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
            ShowSyncHudMsg(id, g_bHud, "%s %s modul alien este dezactivat.", szPrefix, szName);
         }
      }
      return PLUGIN_HANDLED;
   }
   return PLUGIN_HANDLED;
}
public Show_SubMenu_3D(id, sz3D, item)
{
   if( item == MENU_EXIT )
   {
      menu_destroy(sz3D);
      return PLUGIN_HANDLED;
   }
   new data[6], iName[64];
   new access, callback;
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   menu_item_getinfo(sz3D, item, access, data,5, iName, 63, callback);
   
   new key = str_to_num(data);
   
   switch(key)
   {
      case 1: 
      {
         if(DOn[id])
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 3D.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s esti deja in modul 3D.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul 3D.", szPrefix, szName);
               }
            }
            return PLUGIN_HANDLED;
         }
         else
         {
            DOn[id] = true;
            TopOn[id] = false;
            NormalOn[id] = false;
            LeftOn[id] = false;
            Alien3D[id] = false;
            AlienTop[id] = false;
            AlienNormal[id] = false;
            AlienLeft[id] = false;
            CamOn[id] = false;
            set_view(id, CAMERA_3RDPERSON);
            Show_Menu_Cam(id);
            ResetFov(id);
         }
      }
      case 2: 
      {
         if(get_pcvar_num(cam_alien_on))
         {
            if(Alien3D[id])
            {
               switch(get_pcvar_num(cam_msg_type)) {
                  case 1: 
                  {
                     ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 3D & Alien.^x01", szPrefix, szName);   
                  }
                  case 2: 
                  {
                     client_print(id, print_chat, "%s %s esti deja in modul 3D & Alien.", szPrefix, szName);
                  }
                  case 3:
                  {
                     set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                     ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul 3D & Alien.", szPrefix, szName);
                  }
               }
               return PLUGIN_HANDLED;
            }
            else
            {
               DOn[id] = false;
               TopOn[id] = false;
               NormalOn[id] = false;
               LeftOn[id] = false;
               Alien3D[id] = true;
               AlienTop[id] = false;
               AlienNormal[id] = false;
               AlienLeft[id] = false;
               CamOn[id] = false;
               set_view(id, CAMERA_3RDPERSON);
               Show_Menu_Cam(id);
               SeFov(id);
            }
         }
         else
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 modul Alien este^x03 dezactivat.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
            }
         }
      }
      
   }
   menu_destroy(sz3D);
   return PLUGIN_HANDLED;
}
public Show_SubMenu_TOP(id, szTop, item)
{
   if( item == MENU_EXIT )
   {
      menu_destroy(szTop);
      return PLUGIN_HANDLED;
   }
   new data[6], iName[64];
   new access, callback;
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   menu_item_getinfo(szTop, item, access, data,5, iName, 63, callback);
   
   new key = str_to_num(data);
   
   switch(key)
   {
      case 1: 
      {
         if(TopOn[id])
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Top.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s esti deja in modul Top.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Top.", szPrefix, szName);
               }
            }
            return PLUGIN_HANDLED;
         }
         else
         {
            DOn[id] = false;
            TopOn[id] = true;
            NormalOn[id] = false;
            LeftOn[id] = false;
            Alien3D[id] = false;
            AlienTop[id] = false;
            AlienNormal[id] = false;
            AlienLeft[id] = false;
            CamOn[id] = false;
            set_view(id, CAMERA_TOPDOWN);
            Show_Menu_Cam(id);
            ResetFov(id);
         }
      }
      case 2: 
      {
         if(get_pcvar_num(cam_alien_on))
         {
            if(AlienTop[id])
            {
               switch(get_pcvar_num(cam_msg_type)) {
                  case 1: 
                  {
                     ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Top & Alien.^x01", szPrefix, szName);   
                  }
                  case 2: 
                  {
                     client_print(id, print_chat, "%s %s esti deja in modul Top & Alien.", szPrefix, szName);
                  }
                  case 3:
                  {
                     set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                     ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Top & Alien.", szPrefix, szName);
                  }
               }
               return PLUGIN_HANDLED;
            }
            else
            {
               DOn[id] = false;
               TopOn[id] = false;
               NormalOn[id] = false;
               LeftOn[id] = false;
               Alien3D[id] = false;
               AlienTop[id] = true;
               AlienNormal[id] = false;
               AlienLeft[id] = false;
               CamOn[id] = false;
               set_view(id, CAMERA_TOPDOWN);
               Show_Menu_Cam(id);
               SeFov(id);
            }
         }
         else
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 modul Alien este^x03 dezactivat.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
            }
         }
      }
      
   }
   menu_destroy(szTop);
   return PLUGIN_HANDLED;
}
public Show_SubMenu_NORMAL(id, szNormal, item)
{
   if( item == MENU_EXIT )
   {
      menu_destroy(szNormal);
      return PLUGIN_HANDLED;
   }
   new data[6], iName[64];
   new access, callback;
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   menu_item_getinfo(szNormal, item, access, data,5, iName, 63, callback);
   
   new key = str_to_num(data);
   
   switch(key)
   {
      case 1: 
      {
         if(NormalOn[id])
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Normal.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s esti deja in modul Normal.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Normal.", szPrefix, szName);
               }
            }
            return PLUGIN_HANDLED;
         }
         else
         {
            DOn[id] = false;
            TopOn[id] = false;
            NormalOn[id] = true;
            LeftOn[id] = false;
            Alien3D[id] = false;
            AlienTop[id] = false;
            AlienNormal[id] = false;
            AlienLeft[id] = false;
            CamOn[id] = false;
            set_view(id, CAMERA_NONE);
            Show_Menu_Cam(id);
            ResetFov(id);
         }
      }
      case 2: 
      {
         if(get_pcvar_num(cam_alien_on))
         {
            if(AlienNormal[id])
            {
               switch(get_pcvar_num(cam_msg_type)) {
                  case 1: 
                  {
                     ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Normal & Alien.^x01", szPrefix, szName);   
                  }
                  case 2: 
                  {
                     client_print(id, print_chat, "%s %s esti deja in modul Normal & Alien.", szPrefix, szName);
                  }
                  case 3:
                  {
                     set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                     ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Top & Alien.", szPrefix, szName);
                  }
               }
               return PLUGIN_HANDLED;
            }
            else
            {
               DOn[id] = false;
               TopOn[id] = false;
               NormalOn[id] = false;
               LeftOn[id] = false;
               Alien3D[id] = false;
               AlienTop[id] = false;
               AlienNormal[id] = true;
               AlienLeft[id] = false;
               CamOn[id] = false;
               set_view(id, CAMERA_NONE);
               Show_Menu_Cam(id);
               SeFov(id);
            }
         }
         else
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 modul Alien este^x03 dezactivat.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
            }
         }
      }
      
   }
   menu_destroy(szNormal);
   return PLUGIN_HANDLED;
}
public Show_SubMenu_LEFT(id, szLeft, item)
{
   if( item == MENU_EXIT )
   {
      menu_destroy(szLeft);
      return PLUGIN_HANDLED;
   }
   new data[6], iName[64];
   new access, callback;
   new szName[32];
   get_user_name(id, szName, charsmax(szName));
   menu_item_getinfo(szLeft, item, access, data,5, iName, 63, callback);
   
   new key = str_to_num(data);
   
   switch(key)
   {
      case 1: 
      {
         if(LeftOn[id])
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Left.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s esti deja in modul Left.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Left.", szPrefix, szName);
               }
            }
            return PLUGIN_HANDLED;
         }
         else
         {
            DOn[id] = false;
            TopOn[id] = false;
            NormalOn[id] = false;
            LeftOn[id] = true;
            Alien3D[id] = false;
            AlienTop[id] = false;
            AlienNormal[id] = false;
            AlienLeft[id] = false;
            CamOn[id] = false;
            set_view(id, CAMERA_UPLEFT);
            Show_Menu_Cam(id);
            ResetFov(id);
         }
      }
      
      case 2: 
      {
         if(get_pcvar_num(cam_alien_on))
         {
            if(AlienLeft[id])
            {
               switch(get_pcvar_num(cam_msg_type)) {
                  case 1: 
                  {
                     ColorChat(id, GREEN,"%s^x03 %s^x01 esti deja in modul^x03 Left & Alien.^x01", szPrefix, szName);   
                  }
                  case 2: 
                  {
                     client_print(id, print_chat, "%s %s esti deja in modul Left & Alien.", szPrefix, szName);
                  }
                  case 3:
                  {
                     set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                     ShowSyncHudMsg(id, g_bHud, "%s %s esti deja in modul Left & Alien.", szPrefix, szName);
                  }
               }
               return PLUGIN_HANDLED;
            }
            else
            {
               DOn[id] = false;
               TopOn[id] = false;
               NormalOn[id] = false;
               LeftOn[id] = false;
               Alien3D[id] = false;
               AlienTop[id] = false;
               AlienNormal[id] = false;
               AlienLeft[id] = true;
               CamOn[id] = false;
               set_view(id, CAMERA_UPLEFT);
               Show_Menu_Cam(id);
               SeFov(id);
            }
         }
         else
         {
            switch(get_pcvar_num(cam_msg_type)) {
               case 1: 
               {
                  ColorChat(id, GREEN,"%s^x03 %s^x01 modul Alien este^x03 dezactivat.^x01", szPrefix, szName);   
               }
               case 2: 
               {
                  client_print(id, print_chat, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
               case 3:
               {
                  set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, -1.0, 0, 6.0, 12.0);
                  ShowSyncHudMsg(id, g_bHud, "%s %s modul Alien este dezactivat.", szPrefix, szName);
               }
            }
         }
      }
   }
   
   menu_destroy(szLeft);
   return PLUGIN_HANDLED;
}
public SeFov(id)
{
   message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id);
   write_byte(170);
   message_end();
}
public ResetFov(id)
{
   message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id);
   write_byte(90);
   message_end();
}