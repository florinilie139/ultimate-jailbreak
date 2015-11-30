#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUG_NAME 		"HATS"
#define PLUG_AUTH 		"SgtBane"
#define PLUG_VERS 		"1.8"
#define PLUG_TAG 		"HATS"
#define PLUG_ADMIN		ADMIN_CHAT

#define modelpath		"models/player"

public plugin_precache() {
	new cfgDir[32]
	get_configsdir(cfgDir,31)
	formatex(ModelFile,63,"%s/ModelList.ini",cfgDir)
	command_load()
	new tmpfile [101]
	for (new i = 1; i < TotalHats; ++i) {
		format(tmpfile, 100, "%s/%s", modelpath, HATMDL[i])
		if (file_exists (tmpfile)) {
			precache_model(tmpfile)
			server_print("[%s] Precached %s", PLUG_TAG, HATMDL[i])
		} else {
			server_print("[%s] Failed to precache %s", PLUG_TAG, tmpfile)
		}
	}
}

public ShowMenu(id) {
	if ((get_pcvar_num(P_AdminOnly) == 1 && get_user_flags(id) & PLUG_ADMIN) || (get_pcvar_num(P_AdminOnly) == 0 && get_pcvar_num(P_ForceHat) == 0)) {
		CurrentMenu[id] = 1
		ShowHats(id)
	} else {
		client_print(id,print_chat,"[%s] Only admins may currently use this menu.",PLUG_TAG)
	}
	return PLUGIN_HANDLED
}

public ShowHats(id) {
	new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	
	new szMenuBody[menusize + 1], WpnID
	new nLen = format(szMenuBody, menusize, "\yHat Menu: [Page %i/%i]^n",CurrentMenu[id],MenuPages)
	
	new MnuClr[3]
	// Get Hat Names And Add Them To The List
	for (new hatid=0; hatid < 8; hatid++) {
		WpnID = ((CurrentMenu[id] * 8) + hatid - 8)
		if (WpnID < TotalHats) {
			menucolor(id, WpnID, MnuClr)
			nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w%i.%s %s", hatid + 1, MnuClr, HATNAME[WpnID])
		}
	}
	
	// Next Page And Previous/Close
	if (CurrentMenu[id] == MenuPages) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n^n\d9. Next Page")
	} else {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n^n\w9. Next Page")
	}
	
	if (CurrentMenu[id] > 1) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Previous Page")
	} else {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Close")
	}
	show_menu(id, keys, szMenuBody, -1)
	return PLUGIN_HANDLED
}

public MenuCommand(id, key) {
	switch(key)
	{
		case 8:		//9 - [Next Page]
		{
			if (CurrentMenu[id] < MenuPages) CurrentMenu[id]++
			ShowHats(id)
			return PLUGIN_HANDLED
		}
		case 9:		//0 - [Close]
		{
			CurrentMenu[id]--
			if (CurrentMenu[id] > 0) ShowHats(id)
			return PLUGIN_HANDLED
		}
		default:
		{
			new HatID = ((CurrentMenu[id] * 8) + key - 8)
			if (HatID < TotalHats) {
				if ((get_pcvar_num(P_AdminHats) == 0 && HATREST[HatID] == HAT_ADMIN) || (get_pcvar_num(P_AdminHats) == 1 && HATREST[HatID] == HAT_ADMIN && get_user_flags(id) & PLUG_ADMINB) || HATREST[HatID] == HAT_ALL || (HATREST[HatID] == get_user_team(id) + 1)) {
					Set_Hat(id,HatID,id)
				} else {
					if (HATREST[HatID] == HAT_TERROR && get_user_team(id) == 2) {
						client_print(id,print_chat,"[%s] This hat is currently set as a Terrorist Hat.",PLUG_TAG)
					} else if (HATREST[HatID] == HAT_COUNTER && get_user_team(id) == 1) {
						client_print(id,print_chat,"[%s] This hat is currently set as Counter Terrorist.",PLUG_TAG)
					} else {
						client_print(id,print_chat,"[%s] This hat is currently set as Admin Only.",PLUG_TAG)
					}
				}
			}
		}
	}
	return PLUGIN_HANDLED
}
