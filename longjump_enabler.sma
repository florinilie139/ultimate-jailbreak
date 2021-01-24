/*
 * AMX Mod plugin
 *
 * LongJump Enabler, v0.2
 *
 * (c) Copyright 2013 - AMX Mod Dev
 * This file is provided as is (no warranties).
 *
 */

/*
 * Description:
 *   This plugin enables back the LongJump module to make it work again under latest CRAP CS updates.
 *   If you pickup the LongJump (item_longjump) or if it's given from an external plugin, it will work.
 *   You have cvars to set up that you want (speed, etc.).
 *   Was made due to some requests, and also because this feature is cool!
 *
 *
 * Cvars:
 *   longjump_minspeed "50" - minimal required speed to make work the longjump
 *   longjump_speed "350" - speed of the longjump
 *   longjump_upspeed "300" - up speed of the longjump (vertical velocity)
 *   longjump_punchangle "-5" - punch angle distortion for X axis (vertical crosshair movement)
 *   longjump_sound <0|1> (default: 1)
 *     0 - disable the pickup and fvox sounds (on LongJump pickup)
 *     1 - enable the pickup and fvox sounds (on LongJump pickup)
 *
 *
 * Requirements:
 *   AMX Mod 2010.1 or higher.
 *   Counter-Strike 1.6 or Condition Zero (48 protocol).
 *   Note: Adviced to have these following modes above since it's locked on them, but it's not required.
 *
 *
 * Setup:
 *   Put the .amx file in your plugins directory then add the plugin name
 *   in your plugins.ini file (or in another plugins file).
 *
 *
 * Configuration:
 *   You can make compatible the plugin for the future AMX Mod version by uncommenting the #define AMXMOD_RISE_OF_THE_MYTH.
 *   But no one has it yet!
 *
 *
 * Credit:
 *   Half-Life SDK.
 *
 *
 * Changelog:
 *   0.2  o improved the code (I was forgotten an event was still available for LongJump on the fucking CS update)
 *   0.1  o first release
 *
 */

/******************************************************************************/
// If you change one of the following settings, do not forget to recompile
// the plugin and to install the new .amx file on your server.

// Uncomment if you are using the unreleased future AMX Mod version!
//#define AMXMOD_RISE_OF_THE_MYTH

/******************************************************************************/

#include <amxmod>
  #if defined AMXMOD_RISE_OF_THE_MYTH
  #include <fun>
  #endif


new g_cvarLongJumpMinSpeed
new g_cvarLongJumpSpeed
new g_cvarLongJumpUpSpeed
new g_cvarLongJumpPunchAngle
new g_cvarLongJumpSound


new bool:g_bHasLongJump[33]



public plugin_init() {
  register_plugin("LongJump Enabler", "0.2", "AMX Mod Dev")

  g_cvarLongJumpMinSpeed = register_cvar("longjump_minspeed", "50")
  g_cvarLongJumpSpeed = register_cvar("longjump_speed", "350")
  g_cvarLongJumpUpSpeed = register_cvar("longjump_upspeed", "300")
  g_cvarLongJumpPunchAngle = register_cvar("longjump_punchangle", "-5")
  g_cvarLongJumpSound = register_cvar("longjump_sound", "0") // enable back pick up and fvox sounds (pick up is new)


  register_event("ResetHUD", "eventDisabledLongJump", "be")
  register_event("Health", "eventDisabledLongJump", "bd", "1<1")

  register_event("ItemPickup", "eventItemPickup", "be", "1=item_longjump")
}

public client_connect(id) {
  g_bHasLongJump[id] = false
}

public client_disconnect(id) {
  g_bHasLongJump[id] = false
}

public eventDisabledLongJump(id) {
  g_bHasLongJump[id] = false
}


public eventItemPickup(id) {

  g_bHasLongJump[id] = true // only normal way

}


public client_prethink(id) {
  if(!g_bHasLongJump[id]/* || !is_user_alive(id)*/)
    return PLUGIN_CONTINUE

  static iFlags
  iFlags = entity_get_int(id, EV_INT_flags)

  if(!(iFlags & FL_ONGROUND))
    return PLUGIN_CONTINUE

  static iButtons
  iButtons = entity_get_int(id, EV_INT_button)

  if((iButtons & (IN_DUCK | IN_JUMP)) == (IN_DUCK | IN_JUMP)
  && (iFlags & FL_DUCKING || entity_get_int(id, EV_INT_bInDuck))
  && entity_get_int(id, EV_INT_flDuckTime)
  && !(entity_get_int(id, EV_INT_waterlevel) >= 2)) {
    static Float:vVelocity[3]
    entity_get_vector(id, EV_VEC_velocity, vVelocity)

    if(vector_length(vVelocity) > get_pcvar_float(g_cvarLongJumpMinSpeed)) {
      new Float:flLongJumpSpeed
      new Float:vViewAngles[3]
      new Float:vPunchAngles[3]
      new Float:vForwardDirection[3]

      const SEQUENCE_LONGJUMP = 7
      entity_set_int(id, EV_INT_gaitsequence, SEQUENCE_LONGJUMP)

      entity_get_vector(id, EV_VEC_punchangle, vPunchAngles)
      vPunchAngles[0] = get_pcvar_float(g_cvarLongJumpPunchAngle)

      entity_get_vector(id, EV_VEC_v_angle, vViewAngles)
      make_vectors(vViewAngles)
      global_get_vector(GV_VEC_v_forward, vForwardDirection)

      flLongJumpSpeed = get_pcvar_float(g_cvarLongJumpSpeed) * 1.6

      vVelocity[0] = vForwardDirection[0] * flLongJumpSpeed
      vVelocity[1] = vForwardDirection[1] * flLongJumpSpeed
      vVelocity[2] = get_pcvar_float(g_cvarLongJumpUpSpeed)

      entity_set_vector(id, EV_VEC_velocity, vVelocity)
      entity_set_vector(id, EV_VEC_punchangle, vPunchAngles)

      return PLUGIN_HANDLED
    }
  }
  return PLUGIN_CONTINUE
}

