/*
 * AMX Mod plugin
 *
 * Admin Gag, v3.0-beta
 *
 * (C) Copyright - AMX Mod Dev
 * This file is provided as is (no warranties).
 *
 */

/*
 * Description:
 *   This plugin allows an admin with the ADMIN_SLAY flag to gag/mute a specified player with
 *   different choosen flags, which can be say, say_team, say_team (admin), micro (voice), radio (CS only).
 *   It is capable of saving the time (which is handled in minutes) in a file, and can support non-connected clients (by AuthID or IP).
 *   It is also capable to handle global gag or gag "per recipient", that means you can gag someone for only one client rather than everyone.
 *   It's also possible to ungag a specified player (for everyone or for a single client).
 *
 *   Keep in mind the global gag system (by using the parameter "@global" as recipient) is using a different system than the "per recipient".
 *   Also, in case of you do something like "amx_ungag player @global", this will ungag the client globally, but not the gag per recipient (so if the client is still gagged for some AuthIDs/IPs, this will persist).
 *   So if you want to also ungag the "per recipient" gags, you have to use the parameter "@complete" as recipient, this will simply clean up all the gags and delete the file related to an AuthID or IP.
 *
 *   At the end, this is an unique version very enhanced, except the fact there is not much CVars for customization, neither a backup via SQL (I know shit about that).
 *   But it's still a "beta", so further modifications could be performed on it!
 *
 * Commands:
 *   amx_gag <target: name|#UserID|AuthID|IP> <recipient: name|#UserID|AuthID|IP|"@global"> <a = say, b = say_team, c = say_team @, d = micro, e = radio> <time in minutes> - Gag.
 *   amx_ungag <target: name|#UserID|AuthID|IP> <recipient: name|#UserID|AuthID|IP|"@global"|"@complete"> - Ungag.
 *
 *   Examples:
 *     amx_gag jack @global b 1 -> Gag client "jack" with "say_team" for one minute.
 *     amx_gag paul @global abcde 1440 -> Gag client "paul" with "say, say_team, say_team @, micro, radio" for one day.
 *     amx_gag dracula @global abd 10 -> Gag client "dracula" with "say, say_team, micro" for ten minutes.
 *     amx_gag "STEAM_0:0:172726" @global abcde 0 -> Gag AuthID "STEAM_0:0:172726" with "say, say_team, say_team @, micro, radio" for ever (good! hehehehehe!).
 *     amx_gag "STEAM_0:1:47467973" "175.24.10.2" cd 120 -> Gag AuthID "STEAM_0:1:47467973" for recipient IP "175.24.10.2" with "say_team @, micro" for 120 minutes.
 *     amx_gag mummy paul d 20 -> Gag client "mummy" for recipient "paul" with "micro" and for twenty minutes.
 *     amx_ungag jack @global -> Ungag client "jack" for everyone (globally).
 *     amx_ungag dracula @complete -> Ungag client "dracula" for everyone (complete, which is globally and for all recipients).
 *     amx_ungag mummy paul -> Ungag client "jack" for recipient "paul".
 *     amx_ungag "STEAM_0:1:47467973" "175.24.10.2" -> Ungag AuthID "STEAM_0:1:47467973" for recipient IP "175.24.10.2".
 *
 * CVar:
 *   amx_gag_default_flags "abcde abcde" - Default flags used in the gag menu (two values, first one is for "per recipient", second one is for "global").
 *   amx_gag_default_time "0 0" - Default time used in the gag menu (two values, first one is for "per recipient", second one is for "global").
 *
 * Requirement:
 *   AMX Mod v2010.1 or higher to compile or correctly run this plugin on your server.
 *
 * Setup:
 *   Extract the content of this .zip archive on your computer, then upload the "addons" folder in your moddir (folder of your game).
 *   The non-existent files will be automatically added.
 *   Add the plugin name in your plugins.ini file (or in another plugins file).
 *
 * Configuration:
 *   You can enable if you want, the AMX logs registered in the AMX log folder.
 *   To do that, just uncomment the #define USE_LOGS below, save the file, then recompile
 *   it and replace the new .amx file in your plugins folder.
 *   You can enable/disable the high priority (at the beginning) on call for the AMX messages hooks used by this plugin, just uncomment the #define USE_AHPT_BEGINNING below.
 *   You can customize the data folder by modifying the #define FOLDER_GAGGED below.
 *   You can customize the default gag times by modifying the "g_iGagMenuDefaultTimes_<Single|Global>" global variables below.
 *   For information, this plugin can work with the colored admin activity feature, to enable this
 *   thing, make sure your #define COLORED_ACTIVITY has been uncommented (amx/examples/include/amxconst.inc)
 *   then recompile the plugin and replace the new .amx file on your server.
 *   You can also modify the admin flag required for the commands (see below) or use the
 *   "amx_changecmdaccess" command (put it with the parameters in your amx.cfg for example).
 *
 * Credits:
 *   tcquest78 and EKS for made the previous versions.
 *
 * Changelog:
 *   3.0-beta      o Major update (rewritten the plugin from scratch):
 *                   - Simplified the plugin by removing commands "amx_addgag" and "amx_removegag" (the both others became "all-in-one").
 *                   - Moved flag "c" (micro) to "d" (since there is a new one below).
 *                   - Added new flag "c" destined to support admin team chat (say_team @).
 *                   - Added new flag "e" destined to support radio gag under Retro CS, CS v1.* and CZ.
 *                   - Added possibility to properly gag a client with a specific duration (on the past this was badly made and so not properly saved, which means, cancelled on his disconnect, except on permanent gag).
 *                     Note: The gagged clients are now saved in the "amx/data/gagged_clients" directory, via AuthID or IP.
 *                   - Added possibility to specify a recipient, that means the gag can take effect for only one client (saved via AuthID/IP), or everyone.
 *                     Note: The internal gag code used for the "per recipient" method is different than the global one, the "per recipient" one blocks some messages while the global one blocks the main commands (and also inform client about his gag).
 *                   - Added command "amx_gagmenu" which allows all the features previously explained, and by default everyone has access to it in order to let clients gag others, but non-admins can not gag admins, neither have access to the "global gag".
 *                   - Removed name change lock when a client is gagged (I think it's better to use a third-party plugin for this, as "Constant Names").
 *                   - Removed predefined limit of gagged clients (the new design using one file per AuthID/IP comes without limits of clients/AuthIDs/IPs you can gag).
 *                   - Added CVars "amx_gag_default_flags" and "amx_gag_default_time" in order to prepare the default flags and time used for gag (but it's only used for the menu, not for the command where you have to manually specify them).
 *                     Note: Those CVars support two parameters, the first one is used for "per recipient" flags/time, the second one for "global" flags/time.
 *                   - Removed CVar "amx_gag_inform" which was used to inform admins about a gagged client who join the server.
 *                   - Removed Barney's sound "You talk to much" when a gagged client try to talk in the chat.
 *                   - Modified the gag information message when a gagged client uses the commands (say, say_team, say_team @, radio) by telling him the flags and the expiration, also, it will be displayed to the right channel (console or chat).
 *                   - Added support for commands registered by AMX and using the "say" and "say_team" prefixes (a gagged client is still capable of using them).
 *                   - Added better compatibility for all the games.
 *                   - Added #define USE_AHPT_BEGINNING to enable/disable high priority of the call of the messages hooks of this plugin (enabled by default).
 *                   - Added possibility to "easily" customize default gag times via the following "g_iGagMenuDefaultTimes_<Single|Global>" global variables (but I could add a CVar for this).
 *   2.4           o Updated codes for a better working:
 *                   - Added SteamID/IP support in an all-in-one version.
 *                   - Added cvar amx_gag_inform.
 *                   - Added non-Steam support (can work on non-Steam servers without the #define NO_STEAM uncommented).
 *   2.3-IP        o Added IP support and removed authid support (only for this version).
 *                   - Was originally done for the NoSteam users, from hacked servers, where dproto module is using...
 *   2.3           o Slight improvements of amx_addgag and amx_removegag commands.
 *   2.2           o Added commands amx_addgag and amx_removegag.
 *   2.1           o Added a "gagged_players.ini" file to add authids permanently gagged (with specific flags).
 *   2.0           o Improved version by the AMX Mod Team.
 *                   - Changed system feature of the plugin.
 *                   - Added supreme admin support.
 *                   - Added colored admin activity support.
 *                   - Added #define USE_LOGS to enable/disable AMX logging.
 *                   - Added "*" argument to the "amx_ungag" command (to make the action to all players).
 *                   - Improved and cleaning up for all codes.
 *                   - Added multilingual support.
 *   1.0 -> 1.8.3  o Improved versions by EKS.
 *   0.9.0         o First release by tcquest78.
 *
 */

/******************************************************************************/
// If you change one of the following settings, do not forget to recompile
// the plugin and to install the new .amx file on your server.
// You can find the list of admin flags in the amx/examples/include/amxconst.inc file.

#define FLAG_AMX_GAG     ADMIN_SLAY
#define FLAG_AMX_UNGAG   ADMIN_SLAY
#define FLAG_AMX_GAGMENU ADMIN_ALL

// Uncomment the following line to enable the AMX logs for this plugin.
#define USE_LOGS

// Uncomment/Comment to enable/disable the high priority (at the beginning) on call for the AMX messages hooks.
// Notes:
//   This basically calls in priority the AMX messages hooks of this plugin before the ones of the other plugins (except for others that could have better priority).
//   Also, this enables compatibility with third-party plugins which alter some messages used (as the "info_zone.amx" plugin).
//   Meantime, when a message is blocked by the plugin, the following calls by other plugins will not be called.
//   The "future mighty AMX Mod version" will have a proper compatibility (via new features) regarding this problem, but right now there is no good alternative, because AMX Mod v2010.1 is weak!
//
//   Note that it's important to have the "admin_gag.amx" plugin in the top of the third-party plugins list in your "plugins.ini".
#define USE_AHPT_BEGINNING

// Uncomment/Comment to enable/disable ss1234's stuff.
// Notes:
//   ss1234 is an AMX Mod user who requested to have a menu command via the chat.
//   So enable this #define adds two commands ("say /mute" and "say /mutemenu") for clients.
#define USE_SS1234_FEATURES

// Folder on which one the gagged files are stored (AuthIDs and IPs).
// Note: This folder must be in the "amx/data" directory.
#define FOLDER_GAGGED "gagged_clients"

// Gag times (units in minutes).
// Note: Feel free to change any value as you wish, or remove/add more times.
// Default gag times for "per recipient gag" (in key #1 in the menu).
new const g_iGagMenuDefaultTimes_Single[] = {1, 60, 120, 1440, 10080, 20160, /*40320*/43200, 0}
// Default gag times for "global gag" (in key #2 in the menu).
new const g_iGagMenuDefaultTimes_Global[] = {1, 60, 120, 1440, 10080, 20160, /*40320*/43200, 0}

/******************************************************************************/

//#include <translator>
#include <amxmod>
#include <amxmisc>
#include <vexdum>

#define FLAG_GAG_SAY       (1<<0)
#define FLAG_GAG_SAY_TEAM  (1<<1)
#define FLAG_GAG_SAY_ADMIN (1<<2)
#define FLAG_GAG_MICRO     (1<<3)
#define FLAG_GAG_RADIO     (1<<4)
#define FLAG_GAG_ALL1      (FLAG_GAG_SAY | FLAG_GAG_SAY_TEAM | FLAG_GAG_SAY_ADMIN | FLAG_GAG_MICRO)
#define FLAG_GAG_ALL2      (FLAG_GAG_SAY | FLAG_GAG_SAY_TEAM | FLAG_GAG_SAY_ADMIN | FLAG_GAG_MICRO | FLAG_GAG_RADIO)

enum {
	GAGMODE_SAY_GLOBAL,
	GAGMODE_SAY_SINGLE,

	GAGMODE_SAY_TEAM_GLOBAL,
	GAGMODE_SAY_TEAM_SINGLE,

	GAGMODE_SAY_ADMIN_GLOBAL,
	GAGMODE_SAY_ADMIN_SINGLE, // No! This can not handle that! Or I'll need exporting the adminchat.amx's message!

	GAGMODE_MICRO_GLOBAL,
	GAGMODE_MICRO_SINGLE,

	GAGMODE_RADIO_GLOBAL,
	GAGMODE_RADIO_SINGLE,

	GAGMODE_ANY_GLOBAL,
	GAGMODE_ANY_SINGLE,
}

// To use with the "ActionInGagFile" function.
#define RESULTFLAG_LINE_FOUND  (1<<0)
#define RESULTFLAG_LINE_EDITED (1<<1) // Line edited or removed.
#define RESULTFLAG_LINE_ADDED  (1<<2) // New line.

#define TASK_CheckGaggedTimes_Delay 1.0
#define TASK_CheckGaggedTimes_ID    15413737

new const g_szGaggedFolder[] = FOLDER_GAGGED

new const g_szKey_IsHimSelfGagged[] = "IS_GAGGED"  // The AuthID/IP is gagged (@global/everyone).
new const g_szKey_HasOtherGagged[]  = "HAS_GAGGED" // The AuthID/IP has gagged someone...

#if !defined MAX_CLIENTS
	#define MAX_CLIENTS 32
#endif

enum {
	timeunit_seconds = 0,
	timeunit_minutes,
	timeunit_hours,
	timeunit_days,
	timeunit_weeks,
	timeunit_months,
};
#define SECONDS_IN_MINUTE 60
#define SECONDS_IN_HOUR   3600
#define SECONDS_IN_DAY    86400
#define SECONDS_IN_WEEK   604800
#define SECONDS_IN_MONTH  2592000

new g_iCSVersionType // 0 - Retro CS. 1 - CS v1.5. 2 - CS v1.6 or CZ.
new bool:g_bHasRadioSupport // CS only, but maybe other games could have this.
new bool:g_bHasMenusColored // Note: Should be per-user due to client-side support recently added, wait for next release.

new g_iGaggedFlags_Global[MAX_CLIENTS + 1] // When "@global" has been executed...
new g_iGaggedTimes_Global[MAX_CLIENTS + 1] // When "@global" has been executed...

// Target/Recipient.
new g_iGaggedFlags_Single[MAX_CLIENTS + 1][MAX_CLIENTS + 1] // Per user setting.
new g_iGaggedTimes_Single[MAX_CLIENTS + 1][MAX_CLIENTS + 1] // Per user time.

// Gag/Ungag menu.
enum GagMenuType {
	GagMenuType_None,

	GagMenuType_Main,
	GagMenuType_FlagsAndTime,
	GagMenuType_Clients,
}
new GagMenuType:g_iGagMenuType[MAX_CLIENTS + 1]
enum GagMenuMainType {
	GagMenuMainType_GagSingle,
	GagMenuMainType_GagGlobal,
	GagMenuMainType_UngagSingle,
	GagMenuMainType_UngagGlobal,
	GagMenuMainType_UngagComplete,
}
new GagMenuMainType:g_iGagMenuMainType[MAX_CLIENTS + 1]
new g_iGagMenuFlags[MAX_CLIENTS + 1][2]
new g_iGagMenuTime[MAX_CLIENTS + 1][2]
new g_iGagMenuOption[MAX_CLIENTS + 1]
new g_iGagMenuClientsIDs[MAX_CLIENTS + 1][MAX_CLIENTS]
new g_iGagMenuClientsNum[MAX_CLIENTS + 1]
new g_iGagMenuCommandCallerID = -1

new g_szDataDirectory[128], g_iDataDirectoryLength

new g_iMsgTypeID_SayText
new g_iMsgTypeID_SendAudio
new g_iMsgTypeID_TextMsg
#if !defined USE_AHPT_BEGINNING
new g_pMsgHandle_SayText
new g_pMsgHandle_SendAudio
new g_pMsgHandle_TextMsg
#endif
new g_iCurrentCommandSenderID
new bool:g_bCurrentCommandIsTeamChat // say/say_team detection.
new Float:g_flCurrentCommandTime

new g_pCVar_AMXGagDefaultFlags
new g_pCVar_AMXGagDefaultTime

public server_changelevel(szMapName[]) {
	// So you'll get them called in first! This is only for "say_team @" in fact...
	register_clcmd("say", "Command_Say")
	register_clcmd("say_team", "Command_SayTeam")
}

public plugin_init() {
	//load_translations("admin_gag")
	register_plugin("Admin Gag", "3.0-beta", "AMX Mod Dev")

	g_iCSVersionType   = get_cvar_pointer("humans_join_team") ? 2 : (is_running("cstrike") ? 1 : 0)
	g_bHasRadioSupport = (is_running("retrocs") || is_running("cstrike") || is_running("czero")) ? true : false
	g_bHasMenusColored = (g_bHasRadioSupport == true || is_running("dod")) ? true : false

	register_concmd("amx_gag", "Command_AMXGag", FLAG_AMX_GAG, "<target: name|#UserID|AuthID|IP> <recipient: name|#UserID|AuthID|IP|^"@global^"> <a = say, b = say_team, c = say_team @, d = micro, e = radio> <time in minutes> - Gag.")
	register_concmd("amx_ungag", "Command_AMXUnGag", FLAG_AMX_GAG, "<target: name|#UserID|AuthID|IP> <recipient: name|#UserID|AuthID|IP|^"@global^"|^"@complete^"> - Ungag.")
	register_clcmd("amx_gagmenu", "Command_AMXGagMenu", FLAG_AMX_GAGMENU, "- Display gag/ungag menu.")
	#if defined USE_SS1234_FEATURES
	register_clcmd("say /mute", "Command_AMXGagMenu", FLAG_AMX_GAGMENU, "- Display gag/ungag menu.")
	register_clcmd("say /mutemenu", "Command_AMXGagMenu", FLAG_AMX_GAGMENU, "- Display gag/ungag menu.")
	//register_clcmd("say_team /mute", "Command_AMXGagMenu", FLAG_AMX_GAGMENU, "- Display gag/ungag menu.")
	//register_clcmd("say_team /mutemenu", "Command_AMXGagMenu", FLAG_AMX_GAGMENU, "- Display gag/ungag menu.")
	#endif
	if(g_bHasRadioSupport == true) {
		register_clcmd("radio1", "Command_Radio")
		register_clcmd("radio2", "Command_Radio")
		register_clcmd("radio3", "Command_Radio")
		register_clcmd("radio4", "Command_Radio")
	}

	g_pCVar_AMXGagDefaultFlags = register_cvar("amx_gag_default_flags", "abcde abcde")
	g_pCVar_AMXGagDefaultTime  = register_cvar("amx_gag_default_time", "0 0")

	register_menucmd(register_menuid("GagUngagMenu_Main"), MENU_KEY_ALL, "ActionMenu_Gag_Main")
	register_menucmd(register_menuid("GagUngagMenu_FlagsAndTime"), MENU_KEY_ALL, "ActionMenu_Gag_FlagsAndTime")
	register_menucmd(register_menuid("GagUngagMenu_Clients"), MENU_KEY_ALL, "ActionMenu_Gag_Clients")

	g_iMsgTypeID_SayText   = get_user_msgid("SayText")   // Chat (say/say_team) via single.
	g_iMsgTypeID_SendAudio = get_user_msgid("SendAudio") // Radio via single.
	g_iMsgTypeID_TextMsg   = get_user_msgid("TextMsg")   // Radio via single.

	#if defined USE_AHPT_BEGINNING
	register_message(g_iMsgTypeID_SayText, "Message_SayText")
	register_message(g_iMsgTypeID_SendAudio, "Message_SendAudio")
	register_message(g_iMsgTypeID_TextMsg, "Message_TextMsg")
	#endif

	build_path(g_szDataDirectory, charsmax(g_szDataDirectory), "$basedir/data/%s", g_szGaggedFolder)
	g_iDataDirectoryLength = strlen(g_szDataDirectory)// + 1 // Add additive slash.
}

CmdAction_GetTargetAndRecipient(iPerformerID, bool:bIsCommandUngag, szTarget[32], &iTargetID, &iWhichTargetParamType, szRecipient[32], &iRecipientID, &iWhichRecipientParamType, &iGlobalMethodType) {
	new iTargetLength = read_argv(1, szTarget, charsmax(szTarget))

	iTargetID = CmdTargetExtra(iPerformerID, szTarget, 27, true)

	if(iTargetID == -1) // More than one found, or restrictions (immunity, etc.).
		return false

	new iPortPosition = -1

	iWhichTargetParamType = IsStringAuthIDOrIP(szTarget, iTargetLength)

	if(!iTargetID && iWhichTargetParamType == 0) {
		console_print(iPerformerID, "The AuthID/IP ^"%s^" of the target is invalid.", szTarget)
		return false
	}

	if(iWhichTargetParamType == 2) { // Strip port when it's an IP.
		iPortPosition = contain(szTarget, ":")

		if(iPortPosition > -1) {
			szTarget[iPortPosition] = EOS
			iPortPosition = -1
		}
	}

	if(!iTargetID) {
		strtoupper(szTarget)
	}
	else { // Target connected found by a type of parameter.
		GetClientAuthIDOrIP(iTargetID, szTarget, charsmax(szTarget), iWhichTargetParamType)
	}

	new iRecipientLength = read_argv(2, szRecipient, charsmax(szRecipient))

	iGlobalMethodType = equali(szRecipient, "@global") ? 1 : (equali(szRecipient, "@complete") ? 2 : 0)
	iRecipientID      = (iGlobalMethodType == 0) ? CmdTargetExtra(iPerformerID, szRecipient, 27, true) : 0

	if(iRecipientID == -1) // More than one found, or restrictions (immunity, etc.).
		return false

	iWhichRecipientParamType = IsStringAuthIDOrIP(szRecipient, iRecipientLength)

	if(iGlobalMethodType == 0 && !iRecipientID && iWhichRecipientParamType == 0) {
		console_print(iPerformerID, "The parameter ^"%s^" of the recipient is invalid.", szRecipient)
		return false
	}
	else if(iGlobalMethodType) {
		szRecipient[0] = EOS
	}

	if(iWhichRecipientParamType == 2) { // Strip port when it's an IP.
		iPortPosition = contain(szRecipient, ":")

		if(iPortPosition > -1) {
			szRecipient[iPortPosition] = EOS
			iPortPosition = -1
		}
	}

	/*if(iTargetID == iRecipientID || equal(szTarget, szRecipient)) {
		console_print(iPerformerID, "The target to gag can not be equal to the recipient.")
		return false
	}*/

	if(!iRecipientID) {
		strtoupper(szRecipient)
	}
	else { // Recipient connected found by a type of parameter.
		// Prevent gag against an admin when the recipient is a non-admin (I wish the admins be non-gaggable by lambda users, except on "global" one).
		if(bIsCommandUngag == false && iTargetID && is_user_realadmin(iTargetID) && !is_user_realadmin(iRecipientID)) {
			console_print(iPerformerID, "The non-admin recipients can not have an admin gagged as target.")
			return false
		}

		GetClientAuthIDOrIP(iRecipientID, szRecipient, charsmax(szRecipient), iWhichRecipientParamType)
	}

	return true
}

CmdAction_GetGagFlags(iPerformerID, szFlags[6], &iFlags, iGlobalMethodType) {
	read_argv(3, szFlags, charsmax(szFlags))
	iFlags = read_flags(szFlags)

	// Do I really should force all flags when nothing provided?
	if(iFlags == 0 || iFlags > ((g_bHasRadioSupport == false) ? FLAG_GAG_ALL1 : FLAG_GAG_ALL2)) {
		iFlags = (g_bHasRadioSupport == false) ? FLAG_GAG_ALL1 : FLAG_GAG_ALL2

		if(iGlobalMethodType == 0) {
			iFlags &= ~FLAG_GAG_SAY_ADMIN
		}

		get_flags(iFlags, szFlags, charsmax(szFlags))
	}
	else if(g_bHasRadioSupport == false && (iFlags & FLAG_GAG_RADIO)) {
		if(iFlags == FLAG_GAG_RADIO) {
			console_print(iPerformerID, "Gagging the radio is unavailable, the current game does not support it.")
			return false
		}

		iFlags &= ~FLAG_GAG_RADIO
		get_flags(iFlags, szFlags, charsmax(szFlags))

		console_print(iPerformerID, "Information: Gagged flag ^"e^" removed from the list since the current game does not support it.")
	}

	if(iGlobalMethodType == 0 && (iFlags & FLAG_GAG_SAY_ADMIN)) {
		if(iFlags == FLAG_GAG_SAY_ADMIN) {
			console_print(iPerformerID, "Gagging the admin team chat for a single recipient is unavailable.")
			return false
		}

		iFlags &= ~FLAG_GAG_SAY_ADMIN
		get_flags(iFlags, szFlags, charsmax(szFlags))

		console_print(iPerformerID, "Information: Gagged flag ^"c^" removed from the list since this is not supported with a single recipient.")
	}

	return true
}

public Command_AMXGag(iPerformerID, iCommandAccessFlags, iCommandID) {
	if(g_iGagMenuCommandCallerID >= 1) {
		iPerformerID = g_iGagMenuCommandCallerID
	}

	if(g_iGagMenuCommandCallerID <= 0 && !cmd_access(iPerformerID, iCommandAccessFlags, iCommandID, 5))
		return PLUGIN_HANDLED_MAIN

	// #1: Check target and recipient.
	// Note:
	//   Should I force a file per AuthID or IP if in case I find a target/recipient by using such parameter?
	//   If we consider the admin "really wanted to enforce AuthID/IP" as saving...
	//   I'm hesitating!
	new szTarget[32], szRecipient[32]
	new iTargetID, iRecipientID
	new iWhichTargetParamType, iWhichRecipientParamType
	new iGlobalMethodType

	if(!CmdAction_GetTargetAndRecipient(iPerformerID, false, szTarget, iTargetID, iWhichTargetParamType, szRecipient, iRecipientID, iWhichRecipientParamType, iGlobalMethodType))
		return PLUGIN_HANDLED_MAIN

	// #2: Check flags.
	new szFlags[6], iFlags

	if(!CmdAction_GetGagFlags(iPerformerID, szFlags, iFlags, iGlobalMethodType))
		return PLUGIN_HANDLED_MAIN

	// #3: Check time.
	new szTime[32]
	read_argv(4, szTime, charsmax(szTime))
	new iTime = max(str_to_num(szTime), 0) * 60 // Convert minutes to seconds.

	// #4: Set up things...
	new iFlagsToReturn, iTimeToReturn
	if((ActionInGagFile(0, szTarget, szRecipient, iFlags, iTime, iFlagsToReturn, iTimeToReturn) & RESULTFLAG_LINE_FOUND)
	&& iFlagsToReturn == iFlags
	&& iTimeToReturn == iTime) {
		if(g_iGagMenuCommandCallerID <= 0) {
			console_print(iPerformerID, "There is already a line with the same parameters (target, recipient, flags, time).")
		}
		else {
			client_print(iPerformerID, print_chat, "There is already a line with the same parameters (target, recipient, flags, time).")
		}
		return PLUGIN_HANDLED_MAIN
	}

	if(!(ActionInGagFile(1, szTarget, szRecipient, iFlags, iTime) & (RESULTFLAG_LINE_EDITED | RESULTFLAG_LINE_ADDED))) {
		if(g_iGagMenuCommandCallerID <= 0) {
			console_print(iPerformerID, "Failed to edit or add a new line in the file.")
		}
		else {
			client_print(iPerformerID, print_chat, "Failed to edit or add a new line in the file.")
		}
		return PLUGIN_HANDLED_MAIN
	}

	SetClientGagged(iTargetID, iRecipientID, iFlags, iTime, iGlobalMethodType ? true : false)

	// #5: Display action.
	new szGagFlagsFormat[128]
	BuildGagFlagsFormat(iFlags, szGagFlagsFormat, charsmax(szGagFlagsFormat))

	new szDuration[128]
	if(iTime > 0) {
		get_time_length(-1, iTime, timeunit_seconds, szDuration, charsmax(szDuration))
	}
	else {
		copy(szDuration, charsmax(szDuration), "permanent")
	}

	new szTargetName[32]
	if(iTargetID) {
		get_user_name(iTargetID, szTargetName, charsmax(szTargetName))
	}
	else {
		szTargetName = szTarget
	}

	new szRecipientName[32]
	if(iRecipientID) {
		get_user_name(iRecipientID, szRecipientName, charsmax(szRecipientName))
	}
	else {
		szRecipientName = szRecipient
	}

	new szAdminName[32]
	if(iPerformerID == 0) {
		szAdminName = "SERVER"
	}
	else {
		get_user_name(iPerformerID, szAdminName, charsmax(szAdminName))
	}

	#if defined USE_LOGS
	new szTargetDataToPrint[128]
	if(!iTargetID) {
		formatex(szTargetDataToPrint, charsmax(szTargetDataToPrint), "%s ^"%s^"", (iWhichTargetParamType == 1) ? "AuthID" : "IP", szTargetName)
	}
	else {
		new szTargetAuthID[32], szTargetIPAddress[32]
		get_user_authid(iTargetID, szTargetAuthID, charsmax(szTargetAuthID))
		get_user_ip(iTargetID, szTargetIPAddress, charsmax(szTargetIPAddress), 1)

		formatex(szTargetDataToPrint, charsmax(szTargetDataToPrint), "client ^"<%s><%d><%s><%s>^"", szTargetName, get_user_userid(iTargetID), szTargetAuthID, szTargetIPAddress)
	}

	new szRecipientDataToPrint[128]
	if(iGlobalMethodType == 0) {
		if(!iRecipientID) {
			formatex(szRecipientDataToPrint, charsmax(szRecipientDataToPrint), "%s ^"%s^"", (iWhichRecipientParamType == 1) ? "AuthID" : "IP", szRecipientName)
		}
		else {
			new szRecipientAuthID[32], szRecipientIPAddress[32]
			get_user_authid(iRecipientID, szRecipientAuthID, charsmax(szRecipientAuthID))
			get_user_ip(iRecipientID, szRecipientIPAddress, charsmax(szRecipientIPAddress), 1)

			formatex(szRecipientDataToPrint, charsmax(szRecipientDataToPrint), "client ^"<%s><%d><%s><%s>^"", szRecipientName, get_user_userid(iRecipientID), szRecipientAuthID, szRecipientIPAddress)
		}
	}
	#endif

	if(iGlobalMethodType == 0) {
		// Note: Keep it in console, "client_print" is too short!
		console_print(iPerformerID, "Target %s ^"%s^" gagged for recipient %s ^"%s^" (flags: ^"%s^" | duration: %s).",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName,
			szGagFlagsFormat, szDuration)

		// Note: Might not be displayed entierly, fuck the "TextMsg"...
		#if !defined COLORED_ACTIVITY
		show_activity(iPerformerID, szAdminName, "Gag %s ^"%s^" for recipient %s ^"%s^" (flags: ^"%s^" | duration: %s).",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName,
			szGagFlagsFormat, szDuration)
		#else
		show_activity_color(iPerformerID, szAdminName, "Gag %s ^"%s^" for recipient %s ^"%s^" (flags: ^"%s^" | duration: %s).",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName,
			szGagFlagsFormat, szDuration)
		#endif

		#if defined USE_LOGS
		if(iPerformerID == 0) {
			log_amx("Admin Gag: <%s> gag target %s for recipient %s (flags: ^"%s^" | duration: %s).",
				szAdminName,
				szTargetDataToPrint, szRecipientDataToPrint,
				szGagFlagsFormat, szDuration)
		}
		else {
			new szAdminAuthID[32], szAdminIPAddress[32]
			get_user_authid(iPerformerID, szAdminAuthID, charsmax(szAdminAuthID))
			get_user_ip(iPerformerID, szAdminIPAddress, charsmax(szAdminIPAddress), 1)

			log_amx("Admin Gag: ^"<%s><%d><%s><%s>^" gag target %s for recipient %s (flags: ^"%s^" | duration: %s).",
				szAdminName, get_user_userid(iPerformerID), szAdminAuthID, szAdminIPAddress,
				szTargetDataToPrint, szRecipientDataToPrint,
				szGagFlagsFormat, szDuration)
		}
		#endif
	}
	else {
		// Note: Keep it in console, "client_print" is too short!
		console_print(iPerformerID, "Target %s ^"%s^" gagged for everyone (flags: ^"%s^" | duration: %s).", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, szGagFlagsFormat, szDuration)

		// Note: Might not be displayed entierly, fuck the "TextMsg"...
		#if !defined COLORED_ACTIVITY
		show_activity(iPerformerID, szAdminName, "Gag %s ^"%s^" for everyone (flags: ^"%s^" | duration: %s).", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, szGagFlagsFormat, szDuration)
		#else
		show_activity_color(iPerformerID, szAdminName, "Gag %s ^"%s^" for everyone (flags: ^"%s^" | duration: %s).", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, szGagFlagsFormat, szDuration)
		#endif

		#if defined USE_LOGS
		if(iPerformerID == 0) {
			log_amx("Admin Gag: <%s> gag target %s for everyone (flags: ^"%s^" | duration: %s).", szAdminName, szTargetDataToPrint, szGagFlagsFormat, szDuration)
		}
		else {
			new szAdminAuthID[32], szAdminIPAddress[32]
			get_user_authid(iPerformerID, szAdminAuthID, charsmax(szAdminAuthID))
			get_user_ip(iPerformerID, szAdminIPAddress, charsmax(szAdminIPAddress), 1)

			log_amx("Admin Gag: ^"<%s><%d><%s><%s>^" gag target %s for everyone (flags: ^"%s^" | duration: %s).",
				szAdminName, get_user_userid(iPerformerID), szAdminAuthID, szAdminIPAddress, szTargetDataToPrint, szGagFlagsFormat, szDuration)
		}
		#endif
	}

	// Inform the recipient.
	if(iRecipientID) {
		client_print(iRecipientID, print_chat, "The %s ^"%s^" is now gagged for you.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName)
		client_print(iRecipientID, print_chat, "Flags: %s. Duration: %s.", szGagFlagsFormat, szDuration)
	}

	// #6: Check AMX hooks.
	if(iGlobalMethodType == 0 || iTime > 0) {
		new iClientsIDs[32], iClientsNum
		get_players(iClientsIDs, iClientsNum, "ch")
		CheckAMXHooksStatus(iClientsIDs, iClientsNum)
	}

	return PLUGIN_HANDLED_MAIN
}

public Command_AMXUnGag(iPerformerID, iCommandAccessFlags, iCommandID) {
	if(g_iGagMenuCommandCallerID >= 1) {
		iPerformerID = g_iGagMenuCommandCallerID
	}

	if(g_iGagMenuCommandCallerID <= 0 && !cmd_access(iPerformerID, iCommandAccessFlags, iCommandID, 3))
		return PLUGIN_HANDLED_MAIN

	// #1: Check target and recipient.
	new szTarget[32], szRecipient[32]
	new iTargetID, iRecipientID
	new iWhichTargetParamType, iWhichRecipientParamType
	new iGlobalMethodType

	if(!CmdAction_GetTargetAndRecipient(iPerformerID, true, szTarget, iTargetID, iWhichTargetParamType, szRecipient, iRecipientID, iWhichRecipientParamType, iGlobalMethodType))
		return PLUGIN_HANDLED_MAIN

	new iClientsIDs[32], iClientsNum, iClientID, iGaggedIDsBits
	get_players(iClientsIDs, iClientsNum, "ch")

	new iLoopNum = 1, szTargetData[2][32], iLineResult[2]
	new iTargetLength = copy(szTargetData[0], charsmax(szTargetData[]), szTarget)

	// If the target is an AuthID that means it is uncommon, however we will have an IP, so add IP as additionnal check.
	// Note: This is for adding support for both AuthID and IP of a target, because both files can exist, and when we have a target, we want everything to be removed.
	if(iTargetID && IsStringAuthIDOrIP(szTarget, iTargetLength) == 1) {
		iLoopNum = 2
		get_user_ip(iTargetID, szTargetData[1], charsmax(szTargetData[]), 1)
	}

	if(iGlobalMethodType <= 1) {
		// #2: Check if there is such data (based on target's AuthID/IP) in the file.
		for(new a = 0; a < iLoopNum; a++) {
			if(ActionInGagFile(0, szTargetData[a], szRecipient, 0, 0) & RESULTFLAG_LINE_FOUND) {
				iLineResult[0]++
			}
		}

		if(iLineResult[0] == 0) {
			if(g_iGagMenuCommandCallerID <= 0) {
				console_print(iPerformerID, "There is no line with such parameters (target, recipient).")
			}
			else {
				client_print(iPerformerID, print_chat, "There is no line with such parameters (target, recipient).")
			}
			return PLUGIN_HANDLED_MAIN
		}

		for(new a = 0; a < iLoopNum; a++) {
			if(ActionInGagFile(2, szTargetData[a], szRecipient, 0, 0) & RESULTFLAG_LINE_EDITED) {
				iLineResult[1]++
			}
		}

		if(iLineResult[1] == 0) { // Failed to remove both lines.
			if(g_iGagMenuCommandCallerID <= 0) {
				console_print(iPerformerID, "Failed to remove the %s in the file.", (iLineResult[0] == 1) ? "line" : "lines")
			}
			else {
				client_print(iPerformerID, print_chat, "Failed to remove the %s in the file.", (iLineResult[0] == 1) ? "line" : "lines")
			}
			return PLUGIN_HANDLED_MAIN
		}

		if(iLineResult[0] != iLineResult[1]) { // One of the line has failed to be removed.
			if(g_iGagMenuCommandCallerID <= 0) {
				console_print(iPerformerID, "Warning: Failed to remove a line in the file.")
			}
			else {
				client_print(iPerformerID, print_chat, "Warning: Failed to remove a line in the file.")
			}
		}

		SetClientUngagged(iTargetID, iRecipientID, iGlobalMethodType ? true : false)
	}
	else {
		new szUsableFilePath[128]

		for(new a = 0; a < iLoopNum; a++) {
			szUsableFilePath[0] = EOS

			if(GetClientAuthIDOrIPSavePath(szTargetData[a], szUsableFilePath, charsmax(szUsableFilePath)) <= 0)
				continue

			iLineResult[0]++
			delete_file(szUsableFilePath)
		}

		if(iLineResult[0] == 0) {
			if(g_iGagMenuCommandCallerID <= 0) {
				console_print(iPerformerID, "There is no file related to that target.")
			}
			else {
				client_print(iPerformerID, print_chat, "There is no file related to that target.")
			}
			return PLUGIN_HANDLED_MAIN
		}

		SetClientUngagged(iTargetID, iRecipientID, true)

		if(iClientsNum > 0) {
			for(new a = 0; a < iClientsNum; a++) {
				iClientID = iClientsIDs[a]

				if(!g_iGaggedFlags_Single[iClientID][iTargetID])
					continue

				iGaggedIDsBits |= (1<<iClientID - 1) // Target gagged for client ID.
				SetClientUngagged(iTargetID, iClientID, false)
			}
		}
	}

	// #3: Display action.
	new szTargetName[32]
	if(iTargetID) {
		get_user_name(iTargetID, szTargetName, charsmax(szTargetName))
	}
	else {
		szTargetName = szTarget
	}

	new szRecipientName[32]
	if(iRecipientID) {
		get_user_name(iRecipientID, szRecipientName, charsmax(szRecipientName))
	}
	else {
		szRecipientName = szRecipient
	}

	new szAdminName[32]
	if(iPerformerID == 0) {
		szAdminName = "SERVER"
	}
	else {
		get_user_name(iPerformerID, szAdminName, charsmax(szAdminName))
	}

	#if defined USE_LOGS
	new szTargetDataToPrint[128]
	if(!iTargetID) {
		formatex(szTargetDataToPrint, charsmax(szTargetDataToPrint), "%s ^"%s^"", (iWhichTargetParamType == 1) ? "AuthID" : "IP", szTargetName)
	}
	else {
		new szTargetAuthID[32], szTargetIPAddress[32]
		get_user_authid(iTargetID, szTargetAuthID, charsmax(szTargetAuthID))
		get_user_ip(iTargetID, szTargetIPAddress, charsmax(szTargetIPAddress), 1)

		formatex(szTargetDataToPrint, charsmax(szTargetDataToPrint), "client ^"<%s><%d><%s><%s>^"", szTargetName, get_user_userid(iTargetID), szTargetAuthID, szTargetIPAddress)
	}

	new szRecipientDataToPrint[128]
	if(iGlobalMethodType == 0) {
		if(!iRecipientID) {
			formatex(szRecipientDataToPrint, charsmax(szRecipientDataToPrint), "%s ^"%s^"", (iWhichRecipientParamType == 1) ? "AuthID" : "IP", szRecipientName)
		}
		else {
			new szRecipientAuthID[32], szRecipientIPAddress[32]
			get_user_authid(iRecipientID, szRecipientAuthID, charsmax(szRecipientAuthID))
			get_user_ip(iRecipientID, szRecipientIPAddress, charsmax(szRecipientIPAddress), 1)

			formatex(szRecipientDataToPrint, charsmax(szRecipientDataToPrint), "client ^"<%s><%d><%s><%s>^"", szRecipientName, get_user_userid(iRecipientID), szRecipientAuthID, szRecipientIPAddress)
		}
	}
	#endif

	if(iGlobalMethodType == 0) {
		// Note: Keep it in console, "client_print" is too short!
		console_print(iPerformerID, "Target %s ^"%s^" ungagged for recipient %s ^"%s^".",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName)

		// Note: Might not be displayed entierly, fuck the "TextMsg"...
		#if !defined COLORED_ACTIVITY
		show_activity(iPerformerID, szAdminName, "Ungag %s ^"%s^" for recipient %s ^"%s^".",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName)
		#else
		show_activity_color(iPerformerID, szAdminName, "Ungag %s ^"%s^" for recipient %s ^"%s^".",
			iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName,
			iRecipientID ? "client" : ((iWhichRecipientParamType == 1) ? "AuthID" : "IP"), szRecipientName)
		#endif

		#if defined USE_LOGS
		if(iPerformerID == 0) {
			log_amx("Admin Gag: <%s> ungag target %s for recipient %s.", szAdminName, szTargetDataToPrint, szRecipientDataToPrint)
		}
		else {
			new szAdminAuthID[32], szAdminIPAddress[32]
			get_user_authid(iPerformerID, szAdminAuthID, charsmax(szAdminAuthID))
			get_user_ip(iPerformerID, szAdminIPAddress, charsmax(szAdminIPAddress), 1)

			log_amx("Admin Gag: ^"<%s><%d><%s><%s>^" ungag target %s for recipient %s.", szAdminName, get_user_userid(iPerformerID), szAdminAuthID, szAdminIPAddress, szTargetDataToPrint, szRecipientDataToPrint)
		}
		#endif
	}
	else {
		// Note: Keep it in console, "client_print" is too short!
		console_print(iPerformerID, "Target %s ^"%s^" ungagged %s.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, (iGlobalMethodType == 1) ? "globally" : "for everyone")

		// Note: Might not be displayed entierly, fuck the "TextMsg"...
		#if !defined COLORED_ACTIVITY
		show_activity(iPerformerID, szAdminName, "Ungag %s ^"%s^" %s.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, (iGlobalMethodType == 1) ? "globally" : "for everyone")
		#else
		show_activity_color(iPerformerID, szAdminName, "Ungag %s ^"%s^" %s.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName, (iGlobalMethodType == 1) ? "globally" : "for everyone")
		#endif

		#if defined USE_LOGS
		if(iPerformerID == 0) {
			log_amx("Admin Gag: <%s> ungag target %s %s.", szAdminName, szTargetDataToPrint, (iGlobalMethodType == 1) ? "globally" : "for everyone")
		}
		else {
			new szAdminAuthID[32], szAdminIPAddress[32]
			get_user_authid(iPerformerID, szAdminAuthID, charsmax(szAdminAuthID))
			get_user_ip(iPerformerID, szAdminIPAddress, charsmax(szAdminIPAddress), 1)

			log_amx("Admin Gag: ^"<%s><%d><%s><%s>^" ungag target %s %s.", szAdminName, get_user_userid(iPerformerID), szAdminAuthID, szAdminIPAddress, szTargetDataToPrint, (iGlobalMethodType == 1) ? "globally" : "for everyone")
		}
		#endif
	}

	// Inform the recipients.
	if(iRecipientID) {
		client_print(iRecipientID, print_chat, "The %s ^"%s^" is no longer gagged for you.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName)
	}
	else if(iGaggedIDsBits) {
		for(new a = 0; a < iClientsNum; a++) {
			iClientID = iClientsIDs[a]

			if(!(iGaggedIDsBits & (1<<iClientID - 1)))
				continue

			client_print(iClientID, print_chat, "The %s ^"%s^" is no longer gagged for you.", iTargetID ? "client" : ((iWhichTargetParamType == 1) ? "AuthID" : "IP"), szTargetName)
		}
	}

	// #4: Check AMX hooks.
	CheckAMXHooksStatus(iClientsIDs, iClientsNum)

	return PLUGIN_HANDLED_MAIN
}

/*
How to:
#1: If admin, display both choices:
1. Gag a client for yourself
2. Gag a client for everyone <- "amx_gag" access required.
3. Ungag a client for yourself
4. Ungag a client for everyone <- "amx_ungag" access required.
0. Exit

#2: Select flags (only on gag):
1. Global chat (say)
2. Team chat (say_team)
3. Micro (voice)
4. Radio <- Only when supported
9. Next: Select time
0. Return

#3: Select duration (only on gag):
1. 1 minute
2. 1 hour
3. 2 hours
4. 1 day
5. 1 week
6. 2 weeks
7. 1 month
8. For ever
9. Next: Select client
0. Return

#4: Select client to gag/ungag.

Note: I would prefer selecting client first (as for the command),
then flags and time after, but I did the reverse for some reasons (more to prevent me from storing selected client infos).
Besides, when you "finalize the action", on a menu it's better to validate with the client, even if we could add a "Validate" key!
*/

public Command_AMXGagMenu(iPerformerID, iCommandAccessFlags, iCommandID) {
	if(!cmd_access(iPerformerID, iCommandAccessFlags, iCommandID, 1))
		return PLUGIN_HANDLED_MAIN

	g_iGagMenuType[iPerformerID]      = GagMenuType_Main
	g_iGagMenuMainType[iPerformerID]  = GagMenuMainType_GagSingle
	//g_iGagMenuFlags[iPerformerID][0]  = 0
	//g_iGagMenuFlags[iPerformerID][1]  = 0
	//g_iGagMenuTime[iPerformerID][0]   = g_iGagMenuDefaultTimes_Single[0]
	//g_iGagMenuTime[iPerformerID][1]   = g_iGagMenuDefaultTimes_Global[0]
	//g_iGagMenuTime[iPerformerID]      = max(get_cvarptr_num(g_pCVar_AMXGagDefaultTime), 0)
	g_iGagMenuOption[iPerformerID]    = 0

	DisplayMenu_Gag_Main(iPerformerID)

	#if defined USE_SS1234_FEATURES
	new szCommand[32]
	if(read_argv(0, szCommand, charsmax(szCommand)) && equal(szCommand, "say", 3))
		// Display chat echo in order to display the command to others noobs who do not know how to mute via the client!
		return PLUGIN_CONTINUE
	#endif

	return PLUGIN_HANDLED_MAIN
}

DisplayMenu_Gag_Main(iPerformerID) {
	new iKeysBits = (MENU_KEY_1 | MENU_KEY_3 | MENU_KEY_0)

	new szAccessFlags[32]
	if(!get_cmdaccess("amx_gag", szAccessFlags, charsmax(szAccessFlags))
	|| access(iPerformerID, read_flags(szAccessFlags))) {
		iKeysBits |= MENU_KEY_2
	}
	if(!get_cmdaccess("amx_ungag", szAccessFlags, charsmax(szAccessFlags))
	|| access(iPerformerID, read_flags(szAccessFlags))) {
		iKeysBits |= (MENU_KEY_4 | MENU_KEY_5)
	}

	new szMenuBody[512]
	new iMenuBodyLength = formatex(szMenuBody, charsmax(szMenuBody), (g_bHasMenusColored == false) ? "Gag/Ungag Menu: Main^n^n" : "\yGag/Ungag Menu: Main\w^n^n")

	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "1. %s^n", "Gag a client for yourself")
	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s. %s^n^n", (g_bHasMenusColored == false) ? ((iKeysBits & MENU_KEY_2) ? "2" : "#") : ((iKeysBits & MENU_KEY_2) ? "\w2" : "\d2"), "Gag a client for everyone")
	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s3. %s^n", (g_bHasMenusColored == false) ? "" : "\w", "Ungag a client for yourself")
	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s. %s^n", (g_bHasMenusColored == false) ? ((iKeysBits & MENU_KEY_4) ? "4" : "#") : ((iKeysBits & MENU_KEY_4) ? "\w4" : "\d4"), "Ungag a client for everyone")
	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s. %s^n^n", (g_bHasMenusColored == false) ? ((iKeysBits & MENU_KEY_5) ? "5" : "#") : ((iKeysBits & MENU_KEY_4) ? "\w5" : "\d5"), "Ungag a client for everyone (complete)")

	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s0. %s^n", (g_bHasMenusColored == false) ? "" : "\w", "Exit")

	show_menu(iPerformerID, iKeysBits, szMenuBody, -1, "GagUngagMenu_Main")
}

public ActionMenu_Gag_Main(iPerformerID, iKeyID) {
	switch(iKeyID) {
		// TO DO: Add base access to menu for "yourself"?
		case MENU_KEY_1_INT, MENU_KEY_2_INT: {
			g_iGagMenuType[iPerformerID]     = GagMenuType_FlagsAndTime
			g_iGagMenuMainType[iPerformerID] = (iKeyID == MENU_KEY_1_INT) ? GagMenuMainType_GagSingle : GagMenuMainType_GagGlobal

			DisplayMenu_Gag_FlagsAndTime(iPerformerID)
		}
		case MENU_KEY_3_INT, MENU_KEY_4_INT, MENU_KEY_5_INT: {
			g_iGagMenuType[iPerformerID]     = GagMenuType_Clients
			g_iGagMenuMainType[iPerformerID] = (iKeyID == MENU_KEY_3_INT) ? GagMenuMainType_UngagSingle : ((iKeyID == MENU_KEY_4_INT) ? GagMenuMainType_UngagGlobal : GagMenuMainType_UngagComplete)

			DisplayMenu_Gag_Clients(iPerformerID, g_iGagMenuOption[iPerformerID] = 0)
		}
		default: {
			g_iGagMenuType[iPerformerID] = GagMenuType_None
		}
	}

	return PLUGIN_HANDLED_MAIN
}

DisplayMenu_Gag_FlagsAndTime(iPerformerID) {
	new iGlobal = (g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1

	new iKeysBits = (MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_4 | MENU_KEY_8 | MENU_KEY_0)

	if(((iGlobal == 0) ? sizeof(g_iGagMenuDefaultTimes_Single) : sizeof(g_iGagMenuDefaultTimes_Global)) == 1
	&& g_iGagMenuTime[iPerformerID][iGlobal] == ((iGlobal == 0) ? g_iGagMenuDefaultTimes_Single[0] : g_iGagMenuDefaultTimes_Global[0])) {
		iKeysBits &= ~MENU_KEY_8
	}

	new szMenuBody[512]
	new iMenuBodyLength = formatex(szMenuBody, charsmax(szMenuBody), "%sGag Menu (%s): Select Flags and Time%s^n^n",
		(g_bHasMenusColored == false) ? "" : "\y", (g_iGagMenuMainType[iPerformerID] <= GagMenuMainType_GagSingle) ? "yourself" : "global", (g_bHasMenusColored == false) ? "" : "\w")

	if(g_bHasMenusColored == false) {
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "1. Global chat (say): %s^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY) ? "Active" : "Inactive")
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "2. Team chat (say_team): %s^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY_TEAM) ? "Active" : "Inactive")
		if(g_iGagMenuMainType[iPerformerID] != GagMenuMainType_GagGlobal) {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "#. Admin team chat (say_team @): %s^n", "Inactive")
		}
		else {
			iKeysBits |= MENU_KEY_3
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "3. Admin team chat (say_team @): %s^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY_ADMIN) ? "Active" : "Inactive")
		}
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "4. Micro (voice): %s^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_MICRO) ? "Active" : "Inactive")
	}
	else {
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "1. Global chat (say): \y%s\w^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY) ? "Active" : "Inactive")
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "2. Team chat (say_team): \y%s\w^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY_TEAM) ? "Active" : "Inactive")
		if(g_iGagMenuMainType[iPerformerID] != GagMenuMainType_GagGlobal) {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "\d3. Admin team chat (say_team @): %s\w^n", "Inactive")
		}
		else {
			iKeysBits |= MENU_KEY_3
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "3. Admin team chat (say_team @): \y%s\w^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_SAY_ADMIN) ? "Active" : "Inactive")
		}
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "4. Micro (voice): \y%s\w^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_MICRO) ? "Active" : "Inactive")

		if(g_bHasRadioSupport == true) {
			iKeysBits |= MENU_KEY_5
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "5. Radio: \y%s\w^n", (g_iGagMenuFlags[iPerformerID][iGlobal] & FLAG_GAG_RADIO) ? "Active" : "Inactive")
		}
	}

	new iTime = g_iGagMenuTime[iPerformerID][iGlobal]
	if(iTime > 0) {
		new szDuration[128]
		get_time_length(-1, iTime, timeunit_minutes, szDuration, charsmax(szDuration))

		if(g_bHasMenusColored == false) {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "^n%s. Time: %s^n^n", (iKeysBits & MENU_KEY_8) ? "8" : "#", szDuration)
		}
		else {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, (iKeysBits & MENU_KEY_8) ? "^n8. Time: \y%s\w^n^n" : "^n\d8. Time: %s\w^n^n", szDuration)
		}
	}
	else {
		if(g_bHasMenusColored == false) {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "^n%s. Time: %s^n^n", (iKeysBits & MENU_KEY_8) ? "8" : "#", "Permanent")
		}
		else {
			iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, (iKeysBits & MENU_KEY_8) ? "^n8. Time: \y%s\w^n^n" : "^n\d8. Time: %s\w^n^n", "Permanent")
		}
	}

	if(g_iGagMenuFlags[iPerformerID][iGlobal]
	&& !(g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle && g_iGagMenuFlags[iPerformerID][iGlobal] == FLAG_GAG_SAY_ADMIN)) {
		iKeysBits |= MENU_KEY_9
	}
	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s. %s^n", (!(iKeysBits & MENU_KEY_9)) ? ((g_bHasMenusColored == false) ? "#" : "\d9") : ((g_bHasMenusColored == false) ? "9" : "\w9"), "Next (select client)")

	iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%s0. %s^n", (g_bHasMenusColored == false) ? "" : "\w", "Return")

	show_menu(iPerformerID, iKeysBits, szMenuBody, -1, "GagUngagMenu_FlagsAndTime")
}

public ActionMenu_Gag_FlagsAndTime(iPerformerID, iKeyID) {
	switch(iKeyID) {
		case MENU_KEY_8_INT: {
			new iGlobal = (g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1

			++g_iGagMenuOption[iPerformerID]
			g_iGagMenuOption[iPerformerID] %= ((iGlobal == 0) ? sizeof(g_iGagMenuDefaultTimes_Single) : sizeof(g_iGagMenuDefaultTimes_Global))

			g_iGagMenuTime[iPerformerID][iGlobal] = (iGlobal == 0) ? g_iGagMenuDefaultTimes_Single[g_iGagMenuOption[iPerformerID]] : g_iGagMenuDefaultTimes_Global[g_iGagMenuOption[iPerformerID]]
		}
		case MENU_KEY_9_INT: {
			g_iGagMenuType[iPerformerID] = GagMenuType_Clients

			DisplayMenu_Gag_Clients(iPerformerID, g_iGagMenuOption[iPerformerID] = 0)
			return PLUGIN_HANDLED_MAIN
		}
		case MENU_KEY_0_INT: {
			g_iGagMenuType[iPerformerID]  = GagMenuType_Main
			//g_iGagMenuFlags[iPerformerID][(g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1] = 0

			DisplayMenu_Gag_Main(iPerformerID)
			return PLUGIN_HANDLED_MAIN
		}
		default: {
			g_iGagMenuFlags[iPerformerID][(g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1] ^= (1<<iKeyID)
		}
	}

	DisplayMenu_Gag_FlagsAndTime(iPerformerID)

	return PLUGIN_HANDLED_MAIN
}

DisplayMenu_Gag_Clients(iPerformerID, iPositionID) {
	if(iPositionID < 0)
		return

	get_players(g_iGagMenuClientsIDs[iPerformerID], g_iGagMenuClientsNum[iPerformerID])

	new bool:bHasPerformerSupreme = (get_user_flags(iPerformerID) & (ADMIN_SUPREME | ADMIN_RCON)) ? true : false

	new iKeysBits = MENU_KEY_0, iKeyID
	new iClientID, szClientName[32]

	new iStart = iPositionID * 8
	if(iStart >= g_iGagMenuClientsNum[iPerformerID]) {
		iStart = iPositionID = g_iGagMenuOption[iPerformerID] = 0
	}

	new iEnd = iStart + 8
	if(iEnd > g_iGagMenuClientsNum[iPerformerID]) {
		iEnd = g_iGagMenuClientsNum[iPerformerID]
	}

	new szMenuBody[512]
	new iMenuBodyLength = formatex(szMenuBody, charsmax(szMenuBody), (g_bHasMenusColored == false) ?
		"%s Menu (%s): Select Client %d/%d^n^n" :
		"\y%s Menu (%s): Select Client\R%d/%d\w^n^n",
		(g_iGagMenuMainType[iPerformerID] <= GagMenuMainType_GagGlobal) ? "Gag" : "Ungag",
		(g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle || g_iGagMenuMainType[iPerformerID] == GagMenuMainType_UngagSingle) ? "yourself" : ((g_iGagMenuMainType[iPerformerID] != GagMenuMainType_UngagComplete) ? "global" : "complete"),
		iPositionID + 1, (g_iGagMenuClientsNum[iPerformerID] / 8 + ((g_iGagMenuClientsNum[iPerformerID] % 8) ? 1 : 0)))

	for(new a = iStart; a < iEnd; a++) {
		iKeyID++
		iClientID = g_iGagMenuClientsIDs[iPerformerID][a]
		get_user_name(iClientID, szClientName, charsmax(szClientName))

		if(!GagMenu_CanGagClient(iPerformerID, iClientID, szClientName, bHasPerformerSupreme, false, false)) {
			if(g_bHasMenusColored == false) {
				iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "#. %s\w^n", szClientName)
			}
			else {
				iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "\d%d. %s\w^n", iKeyID, szClientName)
			}
		}
		else {
			iKeysBits |= (1<<(iKeyID - 1))
			if(g_bHasMenusColored == false) {
				iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%d. %s^n", iKeyID, szClientName)
			}
			else {
				iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "%d. %s%s\w^n", iKeyID, is_user_realadmin(iClientID, 1) ? "\r" : "", szClientName)
			}
		}
	}

	if(iEnd != g_iGagMenuClientsNum[iPerformerID]) {
		iKeysBits |= MENU_KEY_9
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "^n%s9. %s^n0. %s^n", (g_bHasMenusColored == false) ? "" : "\w", "More...", "Return")
	}
	else {
		iMenuBodyLength += formatex(szMenuBody[iMenuBodyLength], charsmax(szMenuBody) - iMenuBodyLength, "^n0. %s", "Return")
	}

	show_menu(iPerformerID, iKeysBits, szMenuBody, -1, "GagUngagMenu_Clients")
}

public ActionMenu_Gag_Clients(iPerformerID, iKeyID) {
	switch(iKeyID) {
		case MENU_KEY_9_INT: {
			DisplayMenu_Gag_Clients(iPerformerID, ++g_iGagMenuOption[iPerformerID])
		}
		case MENU_KEY_0_INT: {
			if(g_iGagMenuOption[iPerformerID]-- <= 0) {
				g_iGagMenuOption[iPerformerID] = 0

				if(g_iGagMenuMainType[iPerformerID] <= GagMenuMainType_GagGlobal) {
					new iGlobal = (g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1

					g_iGagMenuType[iPerformerID] = GagMenuType_FlagsAndTime
					//g_iGagMenuTime[iPerformerID][(g_iGagMenuMainType[iPerformerID] == GagMenuMainType_GagSingle) ? 0 : 1] = g_iGagMenuDefaultTimes[0]
					g_iGagMenuOption[iPerformerID] = ((iGlobal == 0) ? sizeof(g_iGagMenuDefaultTimes_Single) : sizeof(g_iGagMenuDefaultTimes_Global)) - 1 // So restart from the beginning since I reused this global variable.

					DisplayMenu_Gag_FlagsAndTime(iPerformerID)
				}
				else {
					g_iGagMenuType[iPerformerID] = GagMenuType_Main

					DisplayMenu_Gag_Main(iPerformerID)
				}
			}
			else {
				DisplayMenu_Gag_Clients(iPerformerID, g_iGagMenuOption[iPerformerID])
			}
		}
		default: {
			new iClientID = g_iGagMenuClientsIDs[iPerformerID][g_iGagMenuOption[iPerformerID] * 8 + iKeyID]

			new szClientName[32]
			get_user_name(iClientID, szClientName, charsmax(szClientName))

			if(GagMenu_CanGagClient(iPerformerID, iClientID, szClientName, (get_user_flags(iPerformerID) & (ADMIN_SUPREME | ADMIN_RCON)) ? true : false, true, true)) {
				new GagMenuMainType:iGagMenuMainType = g_iGagMenuMainType[iPerformerID]

				new szPerformerName[32]
				get_user_name(iPerformerID, szPerformerName, charsmax(szPerformerName))

				new szFlags[6]
				new iFlags = g_iGagMenuFlags[iPerformerID][(iGagMenuMainType == GagMenuMainType_GagSingle) ? 0 : 1]
				if(iGagMenuMainType == GagMenuMainType_GagSingle) {
					iFlags &= ~FLAG_GAG_SAY_ADMIN
				}
				get_flags(iFlags, szFlags, charsmax(szFlags))

				g_iGagMenuCommandCallerID = iPerformerID

				switch(iGagMenuMainType) {
					case GagMenuMainType_GagSingle, GagMenuMainType_GagGlobal: {
						server_cmd("amx_gag ^"%s^" ^"%s^" %s %d;", szClientName, (iGagMenuMainType == GagMenuMainType_GagSingle) ? szPerformerName : "@global", szFlags, g_iGagMenuTime[iPerformerID][(iGagMenuMainType == GagMenuMainType_GagSingle) ? 0 : 1])
					}
					case GagMenuMainType_UngagSingle, GagMenuMainType_UngagGlobal, GagMenuMainType_UngagComplete: {
						server_cmd("amx_ungag ^"%s^" ^"%s^";", szClientName, (iGagMenuMainType == GagMenuMainType_UngagSingle) ? szPerformerName : ((iGagMenuMainType != GagMenuMainType_UngagComplete) ? "@global" : "@complete"))
					}
				}
				server_exec()

				g_iGagMenuCommandCallerID = -1
			}

			DisplayMenu_Gag_Clients(iPerformerID, g_iGagMenuOption[iPerformerID])
		}
	}

	return PLUGIN_HANDLED_MAIN
}

GagMenu_CanGagClient(iPerformerID, iClientID, szClientName[32], bool:bHasPerformerSupreme, bool:bFromExecution, bool:bDisplayMessage = false) {
	if(iPerformerID == iClientID)
		return true

	if(bFromExecution == true) {
		if(!is_user_connected(iClientID)) {
			if(bDisplayMessage == true) {
				client_print(iPerformerID, print_chat, "The client ^"%s^" is not in-game.", szClientName)
			}
			return false
		}
	}

	if(is_user_hltv(iClientID) || is_user_bot(iClientID)) {
		if(bDisplayMessage == true) {
			client_print(iPerformerID, print_chat, "The client ^"%s^" is a HLTV or bot.", szClientName)
		}
		return false
	}

	if(bHasPerformerSupreme == false && access(iClientID, ADMIN_IMMUNITY)) {
		if(bDisplayMessage == true) {
			client_print(iPerformerID, print_chat, "The client ^"%s^" has immunity.", szClientName)
		}
		return false
	}

	switch(g_iGagMenuMainType[iPerformerID]) {
		case GagMenuMainType_GagSingle: {
			// Special case: Refuse non-admins to gag any admin.
			if(!is_user_realadmin(iPerformerID) && is_user_realadmin(iClientID)) {
				client_print(iPerformerID, print_chat, "The client ^"%s^" is an admin, you can not gag the admins for yourself.", szClientName)
				return false
			}
		}
	}

	return true
}

// Note: Only for global gag (say, say_team, radio).
HookCmd_GlobalGag(iPerformerID, iCommandType) {
	static szCommandLine[128]
	new iCommandLineLength = read_args(szCommandLine, charsmax(szCommandLine))
	new iPrintType         = ((iCommandType == 2) || szCommandLine[0] == '"' && szCommandLine[iCommandLineLength - 1] == '"') ? print_chat : print_console
	new iIsAMXCommand      = -1

	if(iCommandType <= 1) {
		iIsAMXCommand = IsAMXCommand(iPerformerID, (iCommandType == 0) ? false : true, szCommandLine)

		if(iIsAMXCommand == -1 || iIsAMXCommand == 1)
			return PLUGIN_CONTINUE
	}

	g_iCurrentCommandSenderID   = iPerformerID
	g_bCurrentCommandIsTeamChat = (iCommandType != 1) ? false : true
	g_flCurrentCommandTime      = get_gametime()

	if(!IsClientGagged(iPerformerID, 0, (iCommandType <= 1) ? ((iCommandType == 0) ? GAGMODE_SAY_GLOBAL : GAGMODE_SAY_TEAM_GLOBAL) : GAGMODE_RADIO_GLOBAL))
		return 0

	DisplayGagMessage(iPerformerID, iPrintType, g_iGaggedFlags_Global[iPerformerID])

	return (iIsAMXCommand == 2) ? PLUGIN_HANDLED : PLUGIN_HANDLED_MAIN
}

public Command_Say(iPerformerID) {
	return HookCmd_GlobalGag(iPerformerID, 0)
}

public Command_SayTeam(iPerformerID) {
	return HookCmd_GlobalGag(iPerformerID, 1)
}

public Command_Radio(iPerformerID) {
	return HookCmd_GlobalGag(iPerformerID, 2)
}

public Message_SayText(iMsgTypeID, iMsgDestID, iMsgTargetID) { // Target = Receiver.
	new iSenderID = get_msg_arg_int(1)

	// Make "sure" both target and sender are "clients".
	if(!is_playerid_valid(iMsgTargetID, 1) || !is_playerid_valid(iSenderID, 1))
		return PLUGIN_CONTINUE

	// Make "sure" it's not a message sent from somewhere else...
	if(iSenderID != g_iCurrentCommandSenderID || get_gametime() != g_flCurrentCommandTime)
		return PLUGIN_CONTINUE

	new szFormat[32]
	get_msg_arg_string(2, szFormat, charsmax(szFormat))
	new bool:bIsTeamChat = false

	if(g_iCSVersionType <= 1) {
		// Is this filter enough to handle all the other games? It should, but I should check game per game...
		// Note: Use case-insensitive for possible games which could have that term in lower case.
		//bIsTeamChat = (containi(szFormat, "(TEAM)") > -1) ? true : false
		bIsTeamChat = g_bCurrentCommandIsTeamChat
	}
	else {
		static const szCSChatPrefix[] = "#Cstrike_Chat_"

		if(!equal(szFormat, szCSChatPrefix, charsmax(szCSChatPrefix)))
			return PLUGIN_CONTINUE

		// A bit facultative, but I want to be almost fully sure it's a chat message, and since I can check, I do!
		bIsTeamChat = (szFormat[charsmax(szCSChatPrefix)] == 'T' || szFormat[charsmax(szCSChatPrefix)] == 'C' || szFormat[charsmax(szCSChatPrefix)] == 'S') ? true : false
	}

	if(!IsClientGagged(iMsgTargetID, iSenderID, (bIsTeamChat == false) ? GAGMODE_SAY_SINGLE : GAGMODE_SAY_TEAM_SINGLE))
		return PLUGIN_CONTINUE

	#if defined USE_AHPT_BEGINNING
	return PLUGIN_HANDLED
	#else
	return PLUGIN_HANDLED_MAIN
	#endif
}

public Message_SendAudio(iMsgTypeID, iMsgDestID, iMsgTargetID) { // Target = Receiver.
	new iSenderID = get_msg_arg_int(1)

	// Make "sure" both target and sender are "clients".
	if(!is_playerid_valid(iMsgTargetID, 1) || !is_playerid_valid(iSenderID, 1))
		return PLUGIN_CONTINUE

	// Make "sure" it's not a message send from somewhere else...
	// TO DO: Need hooking menu calls...
	/*if(iSenderID != g_iCurrentCommandSenderID || get_gametime() != g_flCurrentCommandTime)
		return PLUGIN_CONTINUE*/

	if(!IsClientGagged(iMsgTargetID, iSenderID, GAGMODE_RADIO_SINGLE))
		return PLUGIN_CONTINUE

	#if defined USE_AHPT_BEGINNING
	return PLUGIN_HANDLED
	#else
	return PLUGIN_HANDLED_MAIN
	#endif
}

public Message_TextMsg(iMsgTypeID, iMsgDestID, iMsgTargetID) { // Target = Receiver.
	if(get_msg_arg_int(1) != ((g_iCSVersionType <= 1) ? 3 : 5))
		return PLUGIN_CONTINUE

	new iSenderID = -1

	switch(g_iCSVersionType) {
		case 0: {
			new szRadioData[48]

			if(get_msg_arg_string(2, szRadioData, charsmax(szRadioData)) <= 0)
				return PLUGIN_CONTINUE

			new iRadioPos = contain(szRadioData, " (RADIO): ")

			if(iRadioPos <= -1)
				return PLUGIN_CONTINUE

			szRadioData[iRadioPos] = EOS
			iSenderID = find_player("a", szRadioData)
		}
		case 1: {
			new szSenderName[32]

			if(get_msg_arg_string(3, szSenderName, charsmax(szSenderName)) <= 0)
				return PLUGIN_CONTINUE

			iSenderID = find_player("a", szSenderName)
		}
		case 2: {
			new szSenderID[3]

			if(get_msg_arg_string(2, szSenderID, charsmax(szSenderID)) <= 0)
				return PLUGIN_CONTINUE

			iSenderID = str_to_num(szSenderID)
		}
	}

	// Make "sure" both target and sender are "clients".
	if(!is_playerid_valid(iMsgTargetID, 1) || !is_playerid_valid(iSenderID, 1))
		return PLUGIN_CONTINUE

	if(g_iCSVersionType >= 1) {
		static const szRadioPrefix[] = "#Game_radio"
		new szRadioText[sizeof(szRadioPrefix)]

		if(get_msg_arg_string((g_iCSVersionType == 1) ? 2 : 3, szRadioText, charsmax(szRadioText)) != charsmax(szRadioPrefix)
		|| !equal(szRadioText, szRadioPrefix))
			return PLUGIN_CONTINUE
	}

	if(!IsClientGagged(iMsgTargetID, iSenderID, GAGMODE_RADIO_SINGLE))
		return PLUGIN_CONTINUE

	#if defined USE_AHPT_BEGINNING
	return PLUGIN_HANDLED
	#else
	return PLUGIN_HANDLED_MAIN
	#endif
}

public Task_CheckGaggedTimes() {
	new iClientsIDs[32], iClientsNum
	get_players(iClientsIDs, iClientsNum, "ch")

	new bool:bHasClientsUngagged
	new bool:bHasStillGaggedWithTime

	if(iClientsNum > 0) {
		new iClient1ID, iClient2ID
		new a, b

		for(a = 0; a < iClientsNum; a++) {
			iClient1ID = iClientsIDs[a]

			if(IsClientGagged(iClient1ID, _, GAGMODE_ANY_GLOBAL)
			&& g_iGaggedTimes_Global[iClient1ID] > 0) {
				if(--g_iGaggedTimes_Global[iClient1ID] <= 0) {
					bHasClientsUngagged = true
					SetClientUngagged(iClient1ID, 0, true)

					client_print(iClient1ID, print_chat, "You are no longer gagged...")
				}
				else {
					bHasStillGaggedWithTime = true
				}
			}

			for(b = 0; b < iClientsNum; b++) {
				iClient2ID = iClientsIDs[b]

				/*if(iClient2ID == iClient1ID)
					continue*/

				if(IsClientGagged(iClient1ID, iClient2ID, GAGMODE_ANY_SINGLE)
				&& g_iGaggedTimes_Single[iClient1ID][iClient2ID] > 0) {
					if(--g_iGaggedTimes_Single[iClient1ID][iClient2ID] <= 0) {
						bHasClientsUngagged = true
						SetClientUngagged(iClient2ID, iClient1ID, false)

						new szClient2Name[32]
						get_user_name(iClient2ID, szClient2Name, charsmax(szClient2Name))

						client_print(iClient1ID, print_chat, "The client ^"%s^" is no longer gagged for you.", szClient2Name)
					}
					else {
						bHasStillGaggedWithTime = true
					}
				}
			}
		}
	}

	if(bHasStillGaggedWithTime == false) {
		remove_task(TASK_CheckGaggedTimes_ID)
	}
	if(bHasClientsUngagged == true) {
		CheckAMXHooksStatus(iClientsIDs, iClientsNum)
	}
}

public client_putinserver(iClientID) {
	if(is_user_hltv(iClientID) || is_user_bot(iClientID))
		return

	// Get menu flags and time from the CVar there, so the changes in the menu will persist for the client until he disconnects.
	new szCVarValue[32], szLocalValue[2][6]
	get_cvarptr_string(g_pCVar_AMXGagDefaultFlags, szCVarValue, charsmax(szCVarValue))
	parse(szCVarValue, szLocalValue[0], charsmax(szLocalValue[]), szLocalValue[1], charsmax(szLocalValue[]))

	g_iGagMenuFlags[iClientID][0] = szLocalValue[0] ? read_flags(szLocalValue[0]) : 0 // Or all?
	g_iGagMenuFlags[iClientID][1] = szLocalValue[1] ? read_flags(szLocalValue[1]) : 0 // Or all?
	if(g_bHasRadioSupport == false) {
		g_iGagMenuFlags[iClientID][0] &= ~FLAG_GAG_RADIO
		g_iGagMenuFlags[iClientID][1] &= ~FLAG_GAG_RADIO
	}

	get_cvarptr_string(g_pCVar_AMXGagDefaultTime, szCVarValue, charsmax(szCVarValue))
	parse(szCVarValue, szLocalValue[0], charsmax(szLocalValue[]), szLocalValue[1], charsmax(szLocalValue[]))
	g_iGagMenuTime[iClientID][0] = max(str_to_num(szLocalValue[0]), 0)
	g_iGagMenuTime[iClientID][1] = max(str_to_num(szLocalValue[1]), 0)

	g_iGaggedFlags_Global[iClientID] = g_iGaggedTimes_Global[iClientID] = 0
	arrayset(g_iGaggedFlags_Single[iClientID], 0, sizeof(g_iGaggedFlags_Single[]))
	arrayset(g_iGaggedTimes_Single[iClientID], 0, sizeof(g_iGaggedTimes_Single[]))

	new iLoopNum = 1, szTargetData[2][32]
	GetClientAuthIDOrIP(iClientID, szTargetData[0], charsmax(szTargetData[]))

	// If the target is an AuthID that means it is uncommon, however we will have an IP, so add IP as additionnal check.
	// Note: This is for adding support for both AuthID and IP of a target, because both files can exist, and when we have a target, we want everything to be checked.
	if(IsStringAuthIDOrIP(szTargetData[0], strlen(szTargetData[0])) == 1) {
		iLoopNum = 2
		get_user_ip(iClientID, szTargetData[1], charsmax(szTargetData[]), 1)
	}

	new iLocalFlags, iEndFlags, iLocalTime, iEndTime = -1
	new a

	for(a = 0; a < iLoopNum; a++) {
		if(!(ActionInGagFile(0, szTargetData[a], "", 0, 0, iLocalFlags, iLocalTime) & RESULTFLAG_LINE_FOUND)
		|| !iLocalFlags)
			continue

		iEndFlags |= iLocalFlags // Cumulate flags from AuthID and IP files.

		if(iEndTime != 0 && (iLocalTime == 0 || iLocalTime > iEndTime)) {
			iEndTime = iLocalTime
		}
	}

	if(iEndFlags) {
		SetClientGagged(iClientID, 0, iEndFlags, iEndTime, true)
	}

	new iClientsIDs[32], iClientsNum
	get_players(iClientsIDs, iClientsNum, "ch")

	// Check if the other clients (and himself) have gagged settings on this client (based on AuthID and IP).
	GagClientForOthers(iClientID, szTargetData, iLoopNum, is_user_realadmin(iClientID) ? true : false, iClientsIDs, iClientsNum)

	// Check if this client has gagged settings on the others (excluding himself since we checked it before).
	if(iClientsNum > 1) {
		new iRecipientID

		for(a = 0; a < iClientsNum; a++) {
			iRecipientID = iClientsIDs[a]

			if(iRecipientID == iClientID)
				continue

			iLoopNum = 1
			szTargetData[0][0] = szTargetData[1][0] = EOS
			GetClientAuthIDOrIP(iRecipientID, szTargetData[0], charsmax(szTargetData[]))

			if(IsStringAuthIDOrIP(szTargetData[0], strlen(szTargetData[0])) == 1) {
				iLoopNum = 2
				get_user_ip(iRecipientID, szTargetData[1], charsmax(szTargetData[]), 1)
			}

			GagClientForOthers(iRecipientID, szTargetData, iLoopNum, is_user_realadmin(iRecipientID) ? true : false, iClientsIDs, iClientsNum, iClientID)
		}
	}

	CheckAMXHooksStatus(iClientsIDs, iClientsNum)
}

GagClientForOthers(iClientID, szTargetData[2][32], iLoopNum, bool:bIsClientAdmin, iClientsIDs[32], iClientsNum, iTargetRecipientID = -1) {
	if(iClientsNum <= 0)
		return

	new a, b
	new iRecipientID
	new szRecipientAuthIDOrIP[32]

	new iLocalFlags, iEndFlags
	new iLocalTime, iEndTime

	for(a = 0; a < iClientsNum; a++) {
		iRecipientID = iClientsIDs[a]

		/*if(iRecipientID == iClientID)
			continue*/

		if(iTargetRecipientID != -1 && iRecipientID != iTargetRecipientID)
			continue

		if(iRecipientID != iClientID && bIsClientAdmin == true && !is_user_realadmin(iRecipientID))
			continue

		// Should I enforce AuthID + IP check here too?
		GetClientAuthIDOrIP(iRecipientID, szRecipientAuthIDOrIP, charsmax(szRecipientAuthIDOrIP))

		iEndFlags = 0
		iEndTime  = -1

		for(b = 0; b < iLoopNum; b++) {
			if(!(ActionInGagFile(0, szTargetData[b], szRecipientAuthIDOrIP, 0, 0, iLocalFlags, iLocalTime) & RESULTFLAG_LINE_FOUND)
			|| !iLocalFlags)
				continue

			iEndFlags |= iLocalFlags // Cumulate flags from AuthID and IP files.

			if(iEndTime != 0 && (iLocalTime == 0 || iLocalTime > iEndTime)) {
				iEndTime = iLocalTime
			}
		}

		// Non-admin other client can not gag an admin.
		if(iEndFlags) {
			SetClientGagged(iClientID, iRecipientID, iEndFlags, iEndTime, false)
		}
	}
}

public client_disconnect(iClientID) {
	if(is_user_hltv(iClientID) || is_user_bot(iClientID))
		return

	SetClientUngagged(iClientID, 0, true, true)

	new iClientsIDs[32], iClientsNum
	get_players(iClientsIDs, iClientsNum, "ch")
	if(iClientsNum > 0) {
		for(new a = 0; a < iClientsNum; a++) {
			SetClientUngagged(iClientID, iClientsIDs[a], false, true)
		}
	}

	CheckAMXHooksStatus(iClientsIDs, iClientsNum)
}

IsClientGagged(iTargetID, iSenderID = 0, iMode) {
	switch(iMode) {
		case GAGMODE_SAY_GLOBAL:      return (g_iGaggedFlags_Global[iTargetID] & FLAG_GAG_SAY)
		case GAGMODE_SAY_SINGLE:      return (g_iGaggedFlags_Single[iTargetID][iSenderID] & FLAG_GAG_SAY)

		case GAGMODE_SAY_TEAM_GLOBAL: return (g_iGaggedFlags_Global[iTargetID] & FLAG_GAG_SAY_TEAM)
		case GAGMODE_SAY_TEAM_SINGLE: return (g_iGaggedFlags_Single[iTargetID][iSenderID] & FLAG_GAG_SAY_TEAM)

		case GAGMODE_SAY_ADMIN_GLOBAL: return (g_iGaggedFlags_Global[iTargetID] & FLAG_GAG_SAY_ADMIN)
		case GAGMODE_SAY_ADMIN_SINGLE: return (g_iGaggedFlags_Single[iTargetID][iSenderID] & FLAG_GAG_SAY_ADMIN)

		case GAGMODE_MICRO_GLOBAL:    return (g_iGaggedFlags_Global[iTargetID] & FLAG_GAG_MICRO)
		case GAGMODE_MICRO_SINGLE:    return (g_iGaggedFlags_Single[iTargetID][iSenderID] & FLAG_GAG_MICRO)

		case GAGMODE_RADIO_GLOBAL:    return (g_iGaggedFlags_Global[iTargetID] & FLAG_GAG_RADIO)
		case GAGMODE_RADIO_SINGLE:    return (g_iGaggedFlags_Single[iTargetID][iSenderID] & FLAG_GAG_RADIO)

		case GAGMODE_ANY_GLOBAL:       return g_iGaggedFlags_Global[iTargetID]
		case GAGMODE_ANY_SINGLE:       return g_iGaggedFlags_Single[iTargetID][iSenderID]
	}

	return false
}

SetClientGagged(iTargetID, iRecipientID, iFlags, iTime, bool:bIsGlobalGag) {
	if(!iTargetID)
		return

	if(iFlags & FLAG_GAG_MICRO) {
		if(bIsGlobalGag == false) {
			if(iRecipientID && !IsClientGagged(iTargetID, _, GAGMODE_MICRO_GLOBAL)) {
				set_speak(iTargetID, SPEAK_MUTED, iRecipientID)
			}
		}
		else {
			set_speak(iTargetID, SPEAK_MUTED)
		}
	}

	if(bIsGlobalGag == false) {
		if(iRecipientID) {
			g_iGaggedFlags_Single[iRecipientID][iTargetID] = iFlags
			g_iGaggedTimes_Single[iRecipientID][iTargetID] = iTime
		}
	}
	else {
		g_iGaggedFlags_Global[iTargetID] = iFlags
		g_iGaggedTimes_Global[iTargetID] = iTime
	}
}

SetClientUngagged(iTargetID, iRecipientID, bool:bIsGlobalGag, bool:bFromDisconnect = false) {
	if(bIsGlobalGag == false) {
		if(IsClientGagged(iRecipientID, iTargetID, GAGMODE_MICRO_SINGLE)
		&& !IsClientGagged(iTargetID, _, GAGMODE_MICRO_GLOBAL)
		&& bFromDisconnect == false) {
			set_speak(iTargetID, SPEAK_NORMAL, iRecipientID)
		}

		g_iGaggedFlags_Single[iRecipientID][iTargetID] = 0
		g_iGaggedTimes_Single[iRecipientID][iTargetID] = 0
	}
	else {
		if(IsClientGagged(iTargetID, _, GAGMODE_MICRO_GLOBAL) && bFromDisconnect == false) {
			set_speak(iTargetID, SPEAK_NORMAL)

			new iClientsIDs[32], iClientsNum, iClientID, a
			get_players(iClientsIDs, iClientsNum, "ch")

			// Set back micro flag per user when they had.
			if(iClientsNum > 0) {
				for(a = 0; a < iClientsNum; a++) {
					iClientID = iClientsIDs[a]

					if(IsClientGagged(iClientID, iTargetID, GAGMODE_MICRO_SINGLE)) {
						set_speak(iTargetID, SPEAK_MUTED, iClientID)
					}
				}
			}
		}

		g_iGaggedFlags_Global[iTargetID] = 0
		g_iGaggedTimes_Global[iTargetID] = 0
	}
}

GetClientAuthIDOrIP(const iClientID, szOutput[], iOutputLength, iWhichTargetParamType = 0) {
	if(iClientID) {
		if(iWhichTargetParamType != 1) { // When found by name/UserID/IP.
			get_user_authid(iClientID, szOutput, iOutputLength)
		}

		// Force usage of IP for "<VALVE|STEAM>_ID_<PENDING|LAN>" or WONID.
		if(equal(szOutput[6], "ID_PENDING")
		|| equal(szOutput[6], "ID_LAN")
		|| equal(szOutput, "4294967295")) {
			get_user_ip(iClientID, szOutput, iOutputLength, 1)
		}
	}
	else {

	}
}

GetClientAuthIDOrIPSavePath(szAuthIDOrIP[32], szFilePath[], iFilePathLength) {
	if(szAuthIDOrIP[0] == EOS)
		return -1

	formatex(szFilePath, iFilePathLength, "%s/%s.ini", g_szDataDirectory, szAuthIDOrIP)
	replace_all(szFilePath[g_iDataDirectoryLength], iFilePathLength - g_iDataDirectoryLength, ":", "_")

	return file_exists(szFilePath)
}

// Action types: 0 - Read and get. 1 - Add and save. 2 - Remove and save.
// TO ADD: Delete file when no more lines.
ActionInGagFile(iActionType, szTarGetClientAuthIDOrIP[32], szRecipientAuthIDOrIP[32], iFlagsToSet, iTimeToSet, &iFlagsToReturn = 0, &iTimeToReturn = 0) {
	iFlagsToReturn = iTimeToReturn = 0

	new szUsableFilePath[128]
	new iSavePathResult = GetClientAuthIDOrIPSavePath(szRecipientAuthIDOrIP[0] ? szRecipientAuthIDOrIP : szTarGetClientAuthIDOrIP, szUsableFilePath, charsmax(szUsableFilePath))

	if(iSavePathResult == -1)
		return 0

	new iResultFlags

	new bool:bUseOtherGagged = szRecipientAuthIDOrIP[0] ? true : false
	new iSysTime             = get_systime()

	new szDataToWrite[128]
	new bool:bHasOtherLineType

	if(iSavePathResult >= 1) {
		new iLine, szText[128], iTextLength
		new szKeyName[32], szLocalAuthIDOrIP[32], szLocalFlags[6], szLocalTime[20]

		// Try editing existing line.
		while((iLine = read_file(szUsableFilePath, iLine, szText, charsmax(szText), iTextLength))) {
			if(!iTextLength || szText[0] == ';' || szText[0] == '#' || szText[0] == '/' && szText[1] == '/')
				continue

			szKeyName[0] = szLocalAuthIDOrIP[0] = szLocalFlags[0] = szLocalTime[0] = EOS

			if(bUseOtherGagged == false) {
				parse(szText, szKeyName, charsmax(szKeyName), szLocalFlags, charsmax(szLocalFlags), szLocalTime, charsmax(szLocalTime))

				if(!equal(szKeyName, g_szKey_IsHimSelfGagged)) {
					if(equal(szKeyName, g_szKey_HasOtherGagged)) {
						bHasOtherLineType = true
					}
					continue
				}
			}
			else {
				parse(szText, szKeyName, charsmax(szKeyName), szLocalAuthIDOrIP, charsmax(szLocalAuthIDOrIP), szLocalFlags, charsmax(szLocalFlags), szLocalTime, charsmax(szLocalTime))

				if(!equal(szKeyName, g_szKey_HasOtherGagged)) {
					if(equal(szKeyName, g_szKey_IsHimSelfGagged)) {
						bHasOtherLineType = true
					}
					continue
				}

				if(!equal(szLocalAuthIDOrIP, szTarGetClientAuthIDOrIP))
					continue
			}

			// Remove duplicated lines if there are...
			if(iResultFlags & RESULTFLAG_LINE_FOUND) {
				write_file(szUsableFilePath, "", iLine - 1)
				continue
			}

			iResultFlags |= RESULTFLAG_LINE_FOUND

			iFlagsToReturn = read_flags(szLocalFlags)
			iTimeToReturn  = max(str_to_num(szLocalTime), 0)
			if(iTimeToReturn > 0) {
				iTimeToReturn = iTimeToReturn - iSysTime

				// Read mode: Time not expired yet, do nothing.
				if(iActionType == 0 && iFlagsToReturn && iTimeToReturn > 0)
					continue
			}
			// Read mode: Permanent gag, do nothing.
			else if(iActionType == 0 && iFlagsToReturn)
				continue

			switch(iActionType) {
				case 0: { // Flags not set, or, has expired, remove the line in such case.
					iFlagsToReturn = iTimeToReturn = 0
				}
				case 1: { // Line to modify.
					if(bUseOtherGagged == false) {
						formatex(szDataToWrite, charsmax(szDataToWrite), "%s %s %d", g_szKey_IsHimSelfGagged, GetGagFlags(iFlagsToSet), (iTimeToSet > 0) ? (iSysTime + iTimeToSet) : 0)
					}
					else {
						formatex(szDataToWrite, charsmax(szDataToWrite), "%s %s %s %d", g_szKey_HasOtherGagged, szTarGetClientAuthIDOrIP, GetGagFlags(iFlagsToSet), (iTimeToSet > 0) ? (iSysTime + iTimeToSet) : 0)
					}
				}
				case 2: { // Remove.
					iFlagsToReturn = iTimeToReturn = 0
				}
			}

			if(write_file(szUsableFilePath, szDataToWrite, iLine - 1)) {
				iResultFlags |= RESULTFLAG_LINE_EDITED
			}
		}
	}

	// File not found, or, no line found or edited (read only?), so attempt to write a new line.
	if(iActionType == 1 && !(iResultFlags & RESULTFLAG_LINE_EDITED)) {
		if(bUseOtherGagged == false) {
			formatex(szDataToWrite, charsmax(szDataToWrite), "%s %s %d", g_szKey_IsHimSelfGagged, GetGagFlags(iFlagsToSet), (iTimeToSet > 0) ? (iSysTime + iTimeToSet) : 0)
		}
		else {
			formatex(szDataToWrite, charsmax(szDataToWrite), "%s %s %s %d", g_szKey_HasOtherGagged, szTarGetClientAuthIDOrIP, GetGagFlags(iFlagsToSet), (iTimeToSet > 0) ? (iSysTime + iTimeToSet) : 0)
		}

		if(write_file(szUsableFilePath, szDataToWrite)) {
			iResultFlags |= RESULTFLAG_LINE_ADDED
		}
	}

	// Basic attempt to remove the file when not anymore data.
	if((iActionType == 0 || iActionType == 2) && szDataToWrite[0] == EOS && (iResultFlags & RESULTFLAG_LINE_EDITED) && bHasOtherLineType == false) {
		delete_file(szUsableFilePath)
	}

	if((iFlagsToReturn & FLAG_GAG_RADIO) && g_bHasRadioSupport == false) {
		iFlagsToReturn &= ~FLAG_GAG_RADIO
	}

	return iResultFlags
}

IsStringIP(const szString[], const iLength) { // Basic code, next release will be shipped with a good native for this!
	#pragma unused iLength

	new iDots, i = 0
	while(isdigit(szString[i]) || szString[i] == '.') {
		if(szString[i++] == '.') {
			++iDots
		}
	}

	if(/*i == iLength && */iDots == 3)
		return true

	return false
}

// Note: Only handle normal AuthIDs or IPs, not special ones.
IsStringAuthIDOrIP(const szString[], const iLength) {
	if(iLength > 10 && (szString[0] == 'v' || szString[0] == 'V' || szString[0] == 's' || szString[0] == 'S') && szString[7] == ':' && szString[9] == ':' && isdigit(szString[10]))
		return 1

	if(iLength > 6 && IsStringIP(szString, iLength))
		return 2

	return 0
}

GetGagFlags(iFlags) {
	new szFlags[6]
	get_flags(iFlags, szFlags, charsmax(szFlags))
	return szFlags
}

BuildGagFlagsFormat(iFlags, szFormat[], iFormatLength) {
	new iTotalLength

	if(iFlags & FLAG_GAG_SAY) {
		iTotalLength += copy(szFormat[iTotalLength], iFormatLength - iTotalLength, "global chat (say)")
	}
	if(iFlags & FLAG_GAG_SAY_TEAM) {
		if(iTotalLength) {
			szFormat[iTotalLength++] = ','
			szFormat[iTotalLength++] = ' '
		}

		iTotalLength += copy(szFormat[iTotalLength], iFormatLength - iTotalLength, "team chat (say_team)")
	}
	if(iFlags & FLAG_GAG_SAY_ADMIN) {
		if(iTotalLength) {
			szFormat[iTotalLength++] = ','
			szFormat[iTotalLength++] = ' '
		}

		iTotalLength += copy(szFormat[iTotalLength], iFormatLength - iTotalLength, "admin team chat (say_team @)")
	}
	if(iFlags & FLAG_GAG_MICRO) {
		if(iTotalLength) {
			szFormat[iTotalLength++] = ','
			szFormat[iTotalLength++] = ' '
		}

		iTotalLength += copy(szFormat[iTotalLength], iFormatLength - iTotalLength, "micro")
	}
	if(iFlags & FLAG_GAG_RADIO) {
		if(iTotalLength) {
			szFormat[iTotalLength++] = ','
			szFormat[iTotalLength++] = ' '
		}

		iTotalLength += copy(szFormat[iTotalLength], iFormatLength - iTotalLength, "radio")
	}
}

DisplayGagMessage(iClientID, iPrintType, iFlags) {
	new szGagFlagsFormat[128]
	BuildGagFlagsFormat(iFlags, szGagFlagsFormat, charsmax(szGagFlagsFormat))

	new iExpireTime = g_iGaggedTimes_Global[iClientID]

	new szExpireTime[128]
	if(iExpireTime > 0) {
		get_time_length(-1, iExpireTime, timeunit_seconds, szExpireTime, charsmax(szExpireTime))
	}
	else {
		copy(szExpireTime, charsmax(szExpireTime), "Never")
	}

	client_print(iClientID, iPrintType, "You are gagged with the following flags: %s.", szGagFlagsFormat)
	client_print(iClientID, iPrintType, "The gag expire in: %s.", szExpireTime)
}

CheckAMXHooksStatus(iClientsIDs[32], iClientsNum) {
	new iTempFlags, iGlobalFlags, iSingleFlags
	new iMaxFlags = (g_bHasRadioSupport == false) ? FLAG_GAG_ALL1 : FLAG_GAG_ALL2
	new bool:bHasTimeToExpire

	new iClient1ID, iClient2ID
	new a, b

	for(a = 0; a < iClientsNum; a++) {
		if((((iGlobalFlags | iSingleFlags) & iMaxFlags) == iMaxFlags) && bHasTimeToExpire == true)
			break

		iClient1ID = iClientsIDs[a]

		iTempFlags = g_iGaggedFlags_Global[iClient1ID]

		if(iTempFlags) {
			iGlobalFlags |= iTempFlags

			if(g_iGaggedTimes_Global[iClient1ID] > 0) {
				bHasTimeToExpire = true
			}
		}

		for(b = 0; b < iClientsNum; b++) {
			iClient2ID = iClientsIDs[b]

			iTempFlags = g_iGaggedFlags_Single[iClient1ID][iClient2ID]

			if(iTempFlags) {
				iSingleFlags |= iTempFlags

				if(g_iGaggedTimes_Single[iClient1ID][iClient2ID] > 0) {
					bHasTimeToExpire = true
				}
			}
		}
	}

	#if !defined USE_AHPT_BEGINNING
	if(iSingleFlags & (FLAG_GAG_SAY | FLAG_GAG_SAY_TEAM)) {
		if(!g_pMsgHandle_SayText) {
			g_pMsgHandle_SayText = register_message(g_iMsgTypeID_SayText, "Message_SayText")
		}
	}
	else if(g_pMsgHandle_SayText) {
		unregister_message(g_iMsgTypeID_SayText, g_pMsgHandle_SayText)
		g_pMsgHandle_SayText = 0
	}

	if(g_bHasRadioSupport == true) {
		if(iSingleFlags & FLAG_GAG_RADIO) {
			if(!g_pMsgHandle_SendAudio) {
				g_pMsgHandle_SendAudio = register_message(g_iMsgTypeID_SendAudio, "Message_SendAudio")
			}
			if(!g_pMsgHandle_TextMsg) {
				g_pMsgHandle_TextMsg = register_message(g_iMsgTypeID_TextMsg, "Message_TextMsg")
			}
		}
		else {
			if(g_pMsgHandle_SendAudio) {
				unregister_message(g_iMsgTypeID_SendAudio, g_pMsgHandle_SendAudio)
				g_pMsgHandle_SendAudio = 0
			}
			if(g_pMsgHandle_TextMsg) {
				unregister_message(g_iMsgTypeID_TextMsg, g_pMsgHandle_TextMsg)
				g_pMsgHandle_TextMsg = 0
			}
		}
	}
	#endif

	if(bHasTimeToExpire == true) {
		if(!task_exists(TASK_CheckGaggedTimes_ID)) {
			set_task(TASK_CheckGaggedTimes_Delay, "Task_CheckGaggedTimes", TASK_CheckGaggedTimes_ID, _, _, "b")
		}
	}
	else {
		remove_task(TASK_CheckGaggedTimes_ID)
	}
}

// Return values: 0 - No AMX command. 1 - AMX command (ignore gag in such case). 2 - AMX command, but do not ignore gag (only for "say_team @").
IsAMXCommand(iPerformerID, bool:bIsTeamChat, szCommandLine[128]) {
	remove_quotes(szCommandLine)

	// No more quotes from chat, or, only spaces typed.
	if(szCommandLine[0] == EOS || trim(szCommandLine) == 0)
		return -1 // Consider it's an AMX command in order to do not display gag when empty message.

	if(is_plugin_running("adminchat.amx")) {
		if(bIsTeamChat == false) {
			// Check for AMX admin chat shortcuts.
			if(access(iPerformerID, ADMIN_CHAT) && (szCommandLine[0] == '@' || szCommandLine[0] == '#' || szCommandLine[0] == '$'))
				return 1
		}
		else {
			// Check for AMX client<->admin chat shortcut.
			// Note: The question is, should I also add a gag flag for this? I think I should!
			if(szCommandLine[0] == '@')
				return IsClientGagged(iPerformerID, 0, GAGMODE_SAY_ADMIN_GLOBAL) ? 2 : 1
		}
	}

	/* Parse usage reason: For new "say/say_team" commands support with additive parameters (via chat or console with quote(s) manually added). */
	parse(szCommandLine, szCommandLine, charsmax(szCommandLine))
	format(szCommandLine, charsmax(szCommandLine), "%s %s", (bIsTeamChat == false) ? "say" : "say_team", szCommandLine)

	/*new szAccessFlags[2]
	// Note: Very crappy/unreliable result with AMX Mod v2010.1!
	// But I'll modify the return value of this native in a few month, so this will be handled properly.
	if(!get_cmdaccess(szCommandName, szAccessFlags, charsmax(szAccessFlags)))
		return false*/

	// Non-efficient method, because "get_cmdaccess" is currently shit for this (except for the commands that have not the "ADMIN_ALL").
	new iPluginsNum = get_pluginsnum()

	if(iPluginsNum > 0) {
		new szFileName[64], szName[64], szUnused[2], szStatus[2], iJIT, szTempCommandName[64], szAccessFlags[32], szInfo[1]
		new iPluginCmdsNum

		for(new iCurrentPluginID = 0; iCurrentPluginID < iPluginsNum; iCurrentPluginID++) {
			get_plugin(iCurrentPluginID, szFileName, charsmax(szFileName), szName, charsmax(szName), szUnused, 0, szUnused, 0, szStatus, charsmax(szStatus), iJIT, iPerformerID)

			if(szStatus[0] != 'r')
				continue

			iPluginCmdsNum = get_plugincmdsnum(szFileName, 1)

			for(new iPluginCmdID = 0; iPluginCmdID < iPluginCmdsNum; iPluginCmdID++) {
				get_plugincmd(szFileName, iPluginCmdID, szTempCommandName, charsmax(szTempCommandName), szAccessFlags, charsmax(szAccessFlags), szInfo, 0, -1, 1)

				if(equal(szTempCommandName, szCommandLine))
					return 1
			}
		}
	}

	return 0
}

CmdTargetExtra(const id, const szArg[], const iFlags = 3, const bool:bExtraFeature = false) {
  new iPlayer = find_player("bl", szArg)
  if(iPlayer) {
    if(iPlayer != find_player("blj", szArg)) {
#if defined _translator_included
      console_print(id, _T("There are more players matching to your argument."))
#else
      console_print(id, "There are more players matching to your argument.")
#endif
      return bExtraFeature ? -1 : 0
    }
  }
  else if((iPlayer = find_player("c", szArg)) == 0 && (iPlayer = find_player("d", szArg)) == 0 && szArg[0] == '#' && szArg[1]) {
    iPlayer = find_player("k", strtonum(szArg[1]))
  }
  if(!iPlayer) {
#if defined _translator_included
    if(bExtraFeature == false) console_print(id, _T("Player with that name or userid not found."))
#else
    if(bExtraFeature == false) console_print(id, "Player with that name or userid not found.")
#endif
    return 0
  }
  if((iFlags & 2) == 0 && (iPlayer == id)) {
#if defined _translator_included
    console_print(id, _T("That action can't be performed on yourself."))
#else
    console_print(id, "That action can't be performed on yourself.")
#endif
    return bExtraFeature ? -1 : 0
  }
  if(iFlags & 1) {
    if((iPlayer != id) && (get_user_flags(iPlayer) & ADMIN_IMMUNITY) && !(get_user_flags(id) & ADMIN_SUPREME)) {
      new szPlayerName[32]
      get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
#if defined _translator_included
      console_print(id, _T("Player ^"%s^" has immunity."), szPlayerName)
#else
      console_print(id, "Player ^"%s^" has immunity.", szPlayerName)
#endif
      return bExtraFeature ? -1 : 0
    }
  }
  if(iFlags & 4) {
    if(!is_user_alive(iPlayer)) {
      new szPlayerName[32]
      get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
#if defined _translator_included
      console_print(id, _T("That action can't be performed on dead player ^"%s^"."), szPlayerName)
#else
      console_print(id, "That action can't be performed on dead player ^"%s^".", szPlayerName)
#endif
      return bExtraFeature ? -1 : 0
    }
  }
  if(iFlags & 8) {
    if(is_user_bot(iPlayer)) {
      new szPlayerName[32]
      get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
#if defined _translator_included
      console_print(id, _T("That action can't be performed on bot ^"%s^"."), szPlayerName)
#else
      console_print(id, "That action can't be performed on bot ^"%s^".", szPlayerName)
#endif
      return bExtraFeature ? -1 : 0
    }
  }
  if(iFlags & 16) {
    if(is_user_hltv(iPlayer)) {
      new szPlayerName[32]
      get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
#if defined _translator_included
      //console_print(id, _T("That action can't be performed on HLTV ^"%s^"."), szPlayerName)
      console_print(id, "That action can't be performed on HLTV ^"%s^".", szPlayerName)
#else
      console_print(id, "That action can't be performed on HLTV ^"%s^".", szPlayerName)
#endif
      return bExtraFeature ? -1 : 0
    }
  }
  return iPlayer
}


/* Stock by Brad */
stock get_time_length(id, unitCnt, type, output[], outputLen) {
// IMPORTANT: 	You must add register_dictionary("time.txt") in plugin_init()
// id:          The player whose language the length should be translated to (or 0 for server language).
// unitCnt:     The number of time units you want translated into verbose text.
// type:        The type of unit (i.e. seconds, minutes, hours, days, weeks) that you are passing in.
// output:      The variable you want the verbose text to be placed in.
// outputLen:	The length of the output variable.
// NOTE: Translation feature disabled on AMX Mod conversion.

  #pragma unused id

  if(unitCnt > 0) {
    // determine the number of each time unit there are
    new monthCnt = 0, weekCnt = 0, dayCnt = 0, hourCnt = 0, minuteCnt = 0, secondCnt = 0;

    switch(type) {
      case timeunit_seconds: secondCnt = unitCnt;
      case timeunit_minutes: secondCnt = unitCnt * SECONDS_IN_MINUTE;
      case timeunit_hours:   secondCnt = unitCnt * SECONDS_IN_HOUR;
      case timeunit_days:    secondCnt = unitCnt * SECONDS_IN_DAY;
      case timeunit_weeks:   secondCnt = unitCnt * SECONDS_IN_WEEK;
      case timeunit_months:  secondCnt = unitCnt * SECONDS_IN_MONTH;
    }

    monthCnt = secondCnt / SECONDS_IN_MONTH;
    secondCnt -= (monthCnt * SECONDS_IN_MONTH);

    weekCnt = secondCnt / SECONDS_IN_WEEK;
    secondCnt -= (weekCnt * SECONDS_IN_WEEK);

    dayCnt = secondCnt / SECONDS_IN_DAY;
    secondCnt -= (dayCnt * SECONDS_IN_DAY);

    hourCnt = secondCnt / SECONDS_IN_HOUR;
    secondCnt -= (hourCnt * SECONDS_IN_HOUR);

    minuteCnt = secondCnt / SECONDS_IN_MINUTE;
    secondCnt -= (minuteCnt * SECONDS_IN_MINUTE);

    // translate the unit counts into verbose text
    new maxElementIdx = -1;
    new timeElement[5][33];

    if(monthCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", monthCnt, (monthCnt == 1) ? "month" : "months");
    if(weekCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", weekCnt, (weekCnt == 1) ? "week" : "weeks");
    if(dayCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", dayCnt, (dayCnt == 1) ? "day" : "days");
    if(hourCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", hourCnt, (hourCnt == 1) ? "hour" : "hours");
    if(minuteCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", minuteCnt, (minuteCnt == 1) ? "minute" : "minutes");
    if(secondCnt > 0)
      format(timeElement[++maxElementIdx], 32, "%i %s", secondCnt, (secondCnt == 1) ? "second" : "seconds");

    switch(maxElementIdx) {
      case 0: format(output, outputLen, "%s", timeElement[0]);
      case 1: format(output, outputLen, "%s and %s", timeElement[0], timeElement[1]);
      case 2: format(output, outputLen, "%s, %s and %s", timeElement[0], timeElement[1], timeElement[2]);
      case 3: format(output, outputLen, "%s, %s, %s and %s", timeElement[0], timeElement[1], timeElement[2], timeElement[3]);
      case 4: format(output, outputLen, "%s, %s, %s, %s and %s", timeElement[0], timeElement[1], timeElement[2], timeElement[3], timeElement[4]);
    }
  }
}

