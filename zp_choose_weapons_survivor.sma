/*
[ZP] Choose the weapons survivor 1.6

===============================================================

Description:
When you are a survivor, will show you a menu where you can choose the weapon primary and secondary.

===============================================================

Cvars:
zp_cws_enable: Enables/disables the plugin
zp_cws_secondary: Enable/disable the menu to choose the weapon secondary.

=============================================================*/

#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <zombie_plague_advance>

#define PLUGIN "[ZP] Choose the weapons survivor"
#define VERSION "1.7"
#define AUTHOR "alan_el_more"

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

new const PRIMARY_NAMES[][] =
{
	"M249",
	"M4a1",
	"AK47"
}

new const SECONDARY_NAMES[][] =
{
	"USP",
	"Deagle",
	"Elite"
}

new const SECONDARY_ID[][] =
{
	"weapon_usp",
	"weapon_deagle",
	"weapon_elite"
}

new const PRIMARY_ID[][] =
{
	"weapon_m249",
	"weapon_m4a1",
	"weapon_ak47"
}

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }

new pcvar, pcvar_secondary, surv_unlimit_clip
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const PEV_ADDITIONAL_AMMO = pev_iuser1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("zp_cws_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY)
	pcvar = register_cvar("zp_cws_enable", "1")
	pcvar_secondary = register_cvar("zp_cws_secondary", "1")
	
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	
	register_dictionary("zp_choose_weapons_survivor.txt")
}

public mostrarmenu(id)
{
	static ml_random[20]
	formatex(ml_random, sizeof ml_random - 1, "\y%L", id, "RANDOM")
	
	new menu = menu_create("\rAlege arma \yprincipala \rsurvivor:", "mostrar_cliente")
	
	menu_additem(menu, "\yM249", "0", 0)
	menu_additem(menu, "\yM4a1", "1", 0)
	menu_additem(menu, "\yAK47", "2", 0)
	menu_additem(menu, ml_random, "3", 0)
	
	menu_display(id, menu, 0)
}

public mostrar_cliente(id, menu, item)
{
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	if(key == 4)
		key = random_num(0, 3)
	
	drop_weapons(id, 1)
	fm_give_item(id, PRIMARY_ID[key])
	client_print(id, print_chat, "[CWS] %L %s", id, "CHOOSE_WEAPON", PRIMARY_NAMES[key])
	
	if(get_pcvar_num(pcvar_secondary))
		mostrarmenu2(id)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public mostrarmenu2(id)
{
	static ml_random[20]
	formatex(ml_random, sizeof ml_random - 1, "\y%L", id, "RANDOM")
	
	new menu = menu_create("\rChoose the weapon \ysecundara \rsurvivor:", "mostrar_cliente2")
	
	menu_additem(menu, "\yUSP", "0", 0)
	menu_additem(menu, "\yDeagle", "1", 0)
	menu_additem(menu, "\yElite", "2", 0)
	menu_additem(menu, ml_random, "3", 0)
	
	menu_display(id, menu, 0)
}

public mostrar_cliente2(id, menu, item)
{
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	if(key == 4)
		key = random_num(0, 3)
	
	drop_weapons(id, 2)
	fm_give_item(id, SECONDARY_ID[key])
	client_print(id, print_chat, "[CWS] %L %s", id, "CHOOSE_WEAPON", SECONDARY_NAMES[key])
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public zp_user_humanized_post(id)
{
	if (zp_get_user_survivor(id) && get_pcvar_num(pcvar))
		set_task(1.0, "mostrarmenu", id)
}

public zp_round_started(gamemode, id)
{
	if(gamemode != MODE_SURVIVOR)
		return;
	
	surv_unlimit_clip = get_cvar_pointer("zp_surv_unlimited_ammo")
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	if (!(surv_unlimit_clip == 2))
		return;
	
	if (!zp_get_user_survivor(msg_entity))
		return;
		
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2)
	clip = get_msg_arg_int(3)
	
	if (MAXCLIP[weapon] > 2)
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon]) // HUD should show full clip all the time
		
		if (clip < 2)
		{
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)
			
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, id);
			
			set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponid))
			
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
