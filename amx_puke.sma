/*************************************************************************************************************

  Plugin: AMX Puke
  Version: 0.3
  Author: KRoT@L

  0.1  Release
  0.2  Added another sound
  0.3  Improved the code
       Renamed cvar amx_maxpukes into "amx_puke_max"
       Renamed cvar amx_puke_admin into "amx_puke_admins"
       Added cvars amx_puke_active and amx_puke_range
       Removed #define NO_CS_CZ (you can now puke anywhere if "amx_puke_range" is lower than 30)
       Added #define PRINT_TYPE to be able to change the type of information message (print_console or print_chat)


  Commands:

    puke - pukes on a dead body or anywhere
    say /puke_help - displays puke help

    To puke on a dead body or anywhere you have to bind a key to "puke".
    Open your console and type: bind "key" "puke"
    Example: bind "x" "puke"
    Then stand still above a dead player, press your key and you'll puke on him!
    You can control the direction of the stream with your mouse!

    Players can write "/puke_help" in the chat to get some help.


  Cvars:

    amx_puke_active <0|1> - disable/enable the plugin (default: 1)

    amx_puke_admins <0|1> - disable/enable the usage of the plugin only for admins (default: 0)

    amx_puke_max "3" - maximum number of times a player is allowed to puke per each spawning

    amx_puke_range "80" - maximum range between a dead body and a player who wants puke (must be between 30 and 300)
    Note: Set to a value lower than 30 (MIN_RANGE) to be able to puke anywhere you want.


  Requirement:

    AMX Mod 2010.1 or higher.


************************************************************************************************************/

/******************************************************************************/
// If you change one of the following settings, do not forget to recompile
// the plugin and to install the new .amx file on your server.
// You can find the list of admin flags in the amx/examples/include/amxconst.inc file.

#define FLAG_PUKE      ADMIN_ALL
#define FLAG_PUKE_HELP ADMIN_ALL

// Mode of print for puke info messages from the "puke" command.
// Values are either "print_console", "print_chat" or "print_center".
#define PRINT_TYPE print_chat

// Edit here the minimal & maximal range value in units.
// Notes: This is used to check the distance between a player who wants puke on a dead body.
// If the cvar "amx_puke_range" is lower than MIN_RANGE, players can puke anywhere.
#define MIN_RANGE 30
#define MAX_RANGE 300

// Puke sounds files.
new const g_szSoundFiles[][] = {"sound/puke/puke.wav", "sound/puke/puke2.wav"}

/******************************************************************************/

#include <translator>
#include <amxmod>
#include <amxmisc>

new g_iPlayerCounter[33]
new g_iPlayerPukeNum[33]
new g_iPlayerOrigins[33][3]

#define MAX_COUNTER 10
#define TASKID_make_puke 37931976

public plugin_precache() {
  load_translations("amx_puke")

  for(new i = 0; i < sizeof(g_szSoundFiles); i++) {
    if(file_exists(g_szSoundFiles[i])) {
      precache_sound(g_szSoundFiles[i][6])
    }
    else {
      log_amx(_T("AMX Puke: WARNING! Sound file ^"%s^" doesn't exist on the server."), g_szSoundFiles[i])
    }
  }
}

public plugin_init() {
  register_plugin(_T("AMX Puke"),"0.3","KRoT@L")
  register_clcmd("puke", "puke_on_player", FLAG_PUKE, _T("- pukes on a dead body or anywhere"))
  register_clcmd("say /puke_help", "puke_help", FLAG_PUKE_HELP, _T("- displays puke help"))
  register_cvar("amx_puke_active", "1")
  register_cvar("amx_puke_admins", "0")
  register_cvar("amx_puke_max", "3")
  register_cvar("amx_puke_range", "80")
  register_event("ResetHUD", "reset_hud", "be")
  register_event("DeathMsg", "death_event", "a")
}

public client_putinserver(id) {
  g_iPlayerCounter[id] = 0
  g_iPlayerPukeNum[id] = 0
}

public client_disconnect(id) {
  if(g_iPlayerCounter[id]) {
    reset_puke(id)
  }
}

public puke_on_player(id, iLevel) {
  if(!access(id, iLevel)) {
    console_print(id, _T("You have no access to that command."))
    return PLUGIN_HANDLED
  }

  if(g_iPlayerCounter[id]) {
    client_print(id, PRINT_TYPE, _T("You are already in puking."))
    return PLUGIN_HANDLED
  }

  if(get_cvar_num("amx_puke_active") <= 0) {
    client_print(id, PRINT_TYPE, _T("The plugin ^"AMX Puke^" is disabled."))
    return PLUGIN_HANDLED
  }

  new iPukeRange
  if(get_cvar_num("amx_puke_admins") > 0 && !is_user_admin(id)) {
    if((iPukeRange = get_cvar_num("amx_puke_range")) >= MIN_RANGE) {
      client_print(id, PRINT_TYPE, _T("Only admins can puke on a dead body."))
    }
    else {
      client_print(id, PRINT_TYPE, _T("Only admins can puke."))
    }
    return PLUGIN_HANDLED
  }

  if(!is_user_alive(id)) {
    client_print(id, PRINT_TYPE, _T("You can't puke when you are dead."))
    return PLUGIN_HANDLED
  }

  new iPukeMax = get_cvar_num("amx_puke_max")
  if(g_iPlayerPukeNum[id] >= iPukeMax) {
    client_print(id, PRINT_TYPE, _T("You can't puke more than %d time(s) per each spawning."), iPukeMax)
    return PLUGIN_HANDLED
  }

  iPukeRange = get_cvar_num("amx_puke_range")
  if(iPukeRange >= MIN_RANGE) {
    new iOrigin[3], iPlayers[32], iPlayersNum, iPlayer
    new iCurrentDistance, iDeadBody, iMinDistance = clamp(iPukeRange, MIN_RANGE, MAX_RANGE)

    if(iPukeRange > MAX_RANGE) {
      set_cvar_num("amx_puke_range", MAX_RANGE)
    }

    get_user_origin(id, iOrigin)
    get_players(iPlayers, iPlayersNum, "bh")

    for(--iPlayersNum; iPlayersNum >= 0; iPlayersNum--) {
      iPlayer = iPlayers[iPlayersNum]
      iCurrentDistance = get_distance(iOrigin, g_iPlayerOrigins[iPlayer])
      if(iCurrentDistance < iMinDistance) {
        iMinDistance = iCurrentDistance
        iDeadBody = iPlayer
      }
    }

    if(iDeadBody > 0) {
      new szPlayerName[32]
      get_user_name(iDeadBody, szPlayerName, charsmax(szPlayerName))

      if((get_user_flags(iDeadBody) & ADMIN_IMMUNITY) && (get_user_flags(id) & ADMIN_SUPREME) == 0) {
        client_print(id, PRINT_TYPE, _T("Player ^"%s^" has immunity."), szPlayerName)
        return PLUGIN_HANDLED
      }

      new szName[32]
      get_user_name(id, szName, charsmax(szName))
      client_print(0, print_chat, _T("%s Is Puking On %s's Dead Body!! MuHaHaHaHa!!"), szName, szPlayerName)
    }
    else {
      client_print(id, PRINT_TYPE, _T("There is no dead body around you."))
      return PLUGIN_HANDLED
    }
  }
  else {
    new szName[32]
    get_user_name(id, szName, charsmax(szName))
    client_print(0, print_chat, _T("%s Is Puking!"), szName)
  }

  g_iPlayerCounter[id] = 1
  g_iPlayerPukeNum[id]++

  emit_sound(id, CHAN_VOICE, g_szSoundFiles[random(sizeof(g_szSoundFiles))][6], 1.0, ATTN_NORM, 0, PITCH_NORM)
  set_task(0.3, "make_puke", id + TASKID_make_puke, _, _, "a", MAX_COUNTER - 1)

  return PLUGIN_HANDLED
}

public puke_help(id, iLevel) {
  new szArgs[18]
  new iArgsLen = read_args(szArgs, charsmax(szArgs))
  new iPrintType = (szArgs[0] == '"' && szArgs[iArgsLen - 1] == '"') ? print_chat : print_console

  if(!access(id, iLevel)) {
    client_print(id, iPrintType, _T("You have no access to that command."))
    return PLUGIN_HANDLED
  }

  client_print(id, iPrintType, _T("To puke on a dead body or anywhere you have to bind a key to ^"puke^"."))
  client_print(id, iPrintType, _T("Open your console and write: bind ^"key^" ^"puke^""))
  client_print(id, iPrintType, _T("Example: bind ^"x^" ^"puke^""))

  return PLUGIN_HANDLED
}

public make_puke(id) {
  id -= TASKID_make_puke

  new iOrigin[3], iVelocity[3], Float:fVelocity[3]
  get_user_origin(id, iOrigin, 1)
  iOrigin[2] -= 4
  VelocityByAim(id, 3, fVelocity)
  FVecIVec(fVelocity, iVelocity)

  message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
  write_byte(TE_BLOODSTREAM)
  write_coord(iOrigin[0])
  write_coord(iOrigin[1])
  write_coord(iOrigin[2])
  write_coord(iVelocity[0])
  write_coord(iVelocity[1])
  write_coord(iVelocity[2])
  write_byte(82) // color
  write_byte(165) // speed
  message_end()

  if(++g_iPlayerCounter[id] == MAX_COUNTER + 1) {
    g_iPlayerCounter[id] = 0
  }
}

public reset_hud(id) {
  if(g_iPlayerCounter[id]) {
    reset_puke(id)
  }

  g_iPlayerPukeNum[id] = 0
}

public death_event() {
  new victim = read_data(2)
  get_user_origin(victim, g_iPlayerOrigins[victim], 0)

  if(g_iPlayerCounter[victim]) {
    reset_puke(victim)
  }
}

reset_puke(id) {
  g_iPlayerCounter[id] = 0
  remove_task(id + TASKID_make_puke)
  emit_sound(id, CHAN_VOICE, g_szSoundFiles[0][6], 0.0, ATTN_NORM, 0, PITCH_NORM)
}
