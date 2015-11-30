////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------| Furien Shop |----------------------------------------------------
//==========================================================================================================
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <nvault>
#include <csx>
#pragma semicolon 1;
//--| Icons |--//
#define ICON_HIDE 0
#define ICON_SHOW 1
//--| Sounds |--//
#define BUY_SND			"FrShop/Buy.wav"
#define SELL_SND		"FrShop/Sell.wav"
#define ERROR_SND		"FrShop/Error.wav"
#define ERROR2_SND		"FrShop/Error.wav"
#define LIFE_SND		"FrShop/Life.wav"
#define HP_SND			"FrShop/Health.wav"
#define NOCLIP_SND		"FrShop/NoClip.wav"
#define JP_SND			"FrShop/Jetpack.wav"
#define JP2_SND			"FrShop/Jetpack2.wav"
//--| Acces Level to VIP/Admin |--//
#define VIP_LEVEL		ADMIN_LEVEL_H
#define ADMIN_LEVEL		ADMIN_LEVEL_H

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// New Plugin |
//==========================================================================================================
//------| MENU |------//
new menu;
//------| JETPACK/Parachute |------//
new flame, smoke, bool:has_started, frame[33];
new bool:roundend;
//------| Weapon/Message |------//
new Mesaj;
//------| HAHE Items..etc. |------//
new g_hasSilentWalk[33],bool:has_jp[33];
//------| Prefix to message |------//
new const Prefix[] = "[Furien Shop]";
//------| Color to display vip online |------//
static const COLOR[] = "^x03"; // Green for display VIP
//--| Points Cvar |--//
new PlayerPoints[33], fr_save_points;
//--| Cvars Activate | Dezactivate |--//
new furienshop, furienshopmod, vip, life, awp, sg552, health, noclip, silentwalk, jetpack;
//--| Acces Items |--//
new acces_life, acces_health, acces_awp, acces_sg552, acces_noclip, acces_jetpack, acces_silentwalk;
//--| Cvars Set`s |--//
new maxhealth, nocliptime, jetpacktime, jetpackspeed, jetpacktrail;
//--| Cvars Give Money/Points to Kill |--//
new fr_points_kill, fr_points_hs, fr_points_knife, fr_points_he, fr_money_kill, fr_money_hs, fr_money_knife, fr_money_he;
//--------------| Money Cvars |--------------//
//--| Cvars Buy Cost |--//
new lifecost, awpcost, awpammocost, sg552cost, sg552ammocost, healthcost, noclipcost, silentwalkcost, jetpackcost;
//--| Cvars Sell Cost |--//
new sellsilentwalk;
//--| Cvars Vip Buy Cost |--//
new vip_lifecost, vip_awpcost, vip_awpammocost, vip_sg552cost, vip_sg552ammocost, vip_healthcost, vip_noclipcost, vip_silentwalkcost,
vip_jetpackcost;
//--| Cvars Vip Sell Cost |--//
new vip_sellsilentwalk;
//--------------| Points Cvars |--------------//
//--| Cvars Buy Cost |--//
new points_lifecost, points_awpcost, points_awpammocost, points_sg552cost,points_sg552ammocost, points_healthcost, 
points_noclipcost, points_silentwalkcost, points_jetpackcost;
//--| Cvars Sell Cost |--//
new points_sellsilentwalk;
//--| Cvars Vip Buy Cost |--//
new vip_points_lifecost,vip_points_healthcost, vip_points_awpcost, vip_points_awpammocost, vip_points_sg552cost,
vip_points_sg552ammocost, vip_points_noclipcost, vip_points_silentwalkcost, vip_points_jetpackcost;
//--| Cvars Vip Sell Cost |--//
new vip_points_sellsilentwalk;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Plugin Init |
//==========================================================================================================
public plugin_init() {
	register_plugin("Furien Shop", "1.0", "Aragon*");
	register_clcmd("shop","cmdShop");
	register_clcmd("frshop","cmdShop");
	register_clcmd("say /shop","cmdShop");
	register_clcmd("say /frshop","cmdShop");
	register_clcmd("say_team /shop","cmdShop");
	register_clcmd("say_team /frshop","cmdShop");
	register_clcmd("say shop","cmdShop");
	register_clcmd("say frshop","cmdShop");
	register_clcmd("say_team shop","cmdShop");
	register_clcmd("say_team frshop","cmdShop");
	register_clcmd("say /points", "ShowPoints");
	register_clcmd("say /pts", "ShowPoints");
	register_clcmd("say /mypoints", "ShowPoints");
	register_clcmd("say_team /points", "ShowPoints");
	register_clcmd("say_team /pts", "ShowPoints");
	register_clcmd("say_team /mypoints", "ShowPoints");
	register_clcmd("say", "handle_say");
	register_concmd("+hook","hook_on");
	register_concmd("-hook","hook_off");
	register_concmd("hook_toggle","hook_toggle");
	register_event("CurWeapon", "event_cur_weapon", "be", "1=1");
	register_event("DeathMsg", "death_event", "a");
	register_logevent("EventRoundStart", 2, "1=Round_Start");
	register_logevent("EventRandromize", 2, "1=Round_End");
	register_forward(FM_PlayerPreThink, "fw_PreThink");
	register_forward(FM_CmdStart, "forward_cmdstart");
	register_message(get_user_msgid("ScoreAttrib"),"vip_scoreboard");
	register_touch("jetpack" , "player" , "mmm_touchy");
	RegisterHam(Ham_Spawn, "player", "RoundStart", 1);
	Mesaj = register_cvar("fr_hudmessage_delay", "420");		//| Time interval to display the message |//
//------| Enable/Disable |------//
	furienshop = register_cvar("fr_shop_enabled", "1");		//| Plugin 0 Disable -> 1 Enable |//
	furienshopmod = register_cvar("fr_shop_mode", "0");		//| Money/Points 0 Money Tax -> 1 Points Tax |//
	vip = register_cvar("fr_vip_enabled", "1");			//| VIP 0 Disable -> 1 Enable |//
	fr_save_points = register_cvar("fr_save_points", "1");		//| 0 --> Save whith SteamId 1 --> Save whith Name |//
	life = register_cvar("fr_life", "1");				//| Life 0 Disable -> 1 Enable |//
	health = register_cvar("fr_health", "1");			//| Health 0 Disable -> 1 Enable |//
	awp = register_cvar("fr_awp", "1");				//| AWP 0 Disable -> 1 Enable |//
	sg552 = register_cvar("fr_sg552", "1");				//| SG552 0 Disable -> 1 Enable |//
	noclip = register_cvar("fr_noclip", "1");			//| NoClip 0 Disable -> 1 Enable |//
	silentwalk = register_cvar("fr_silentwalk", "1");		//| SilentWalk 0 Disable -> 1 Enable |//
	jetpack = register_cvar("fr_jetpack", "1");			//| Jetpack 0 Disable -> 1 Enable |//
	
//------| Only for T/Ct or All |------//
	acces_life = register_cvar("fr_acces_life", "3");		//| Life Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_health = register_cvar("fr_acces_hp", "3");		//| Health and Armor Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_awp = register_cvar("fr_acces_awp", "3");			//| AWP Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_sg552 = register_cvar("fr_acces_sg552", "3");		//| SG552 Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_noclip = register_cvar("fr_acces_noclip", "3");		//| NoClip Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_silentwalk = register_cvar("fr_acces_silentwalk", "3");	//| SilentWalk Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_jetpack = register_cvar("fr_acces_jetpack", "3");		//| Jetpack Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//

//------| Set Items |------//
	maxhealth = register_cvar("fr_max_health","200");		//| Max Health |//
	nocliptime = register_cvar("fr_noclip_time", "3.0");		//| Duration NoClip in Seconds |//
	jetpacktime = register_cvar("fr_jetpack_time", "5.0");		//| Duration Jetpack in Seconds |//
	jetpackspeed = register_cvar("fr_jetpack_speed", "500");		//| Speed to Jetpack |//
	jetpacktrail = register_cvar("fr_jetpack_trail", "2");		//| 0 None -> 1 Smoke -> 2 Flame |//
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MONEY |
//==========================================================================================================
//------| Money Bonus+ |------//
	fr_money_kill = register_cvar("fr_points_kill", "300");		//| + Money to kill |//
	fr_money_hs = register_cvar("fr_points_hs", "500");		//| + Money to kill with HeadShot |//
	fr_money_knife = register_cvar("fr_points_knife", "1000");	//| + Money to kill with knife |//
	fr_money_he = register_cvar("fr_points_he", "1500");		//| + Money to kill whit Grenade |//
	
//------| Buy Cost- |------//
	lifecost = register_cvar("fr_life_cost", "10000");		//| Life Cost in Money 0 -> 16000 |//
	healthcost = register_cvar("fr_health_cost", "40");		//| Health Cost in Money 0 -> 16000 |//
	awpcost = register_cvar("fr_awp_cost", "10000");			//| AWP Cost in Money 0 -> 16000 |//
	awpammocost = register_cvar("fr_awpammo_cost","6000");		//| Ammo AWP Cost in Money 0 -> 16000 |//
	sg552cost = register_cvar("fr_sg552_cost", "10000");		//| SG552 Cost in Money 0 -> 16000 |//
	sg552ammocost = register_cvar("fr_sg552ammo_cost","6000");	//| Ammo SG552 Cost in Money 0 -> 16000 |//
	noclipcost = register_cvar("fr_noclip_cost", "16000");		//| NoClip Cost in Money 0 -> 16000 |//
	silentwalkcost = register_cvar("fr_silentwalk_cost", "500");	//| SilentWalk Cost in Money 0 -> 16000 |//
	jetpackcost = register_cvar("fr_jetpack_cost", "5000");		//| Jetpack Cost in Money 0 -> 16000 |//
	
//------| Sell Cost+ |------//
	sellsilentwalk = register_cvar("fr_sell_silentwalk", "250");	//| SilentWalk Sell Bonus in Money 0 -> 16000 |//

//------| Vip Buy Cost- |------//
	vip_lifecost = register_cvar("vip_life_cost", "6000");			//| Life Cost in Money to VIP 0 -> 16000 |//
	vip_healthcost = register_cvar("vip_health_cost", "30");			//| Health Cost in Money to VIP 0 -> 16000 |//
	vip_awpcost = register_cvar("vip_awp_cost", "7000");			//| AWP Cost in Money to VIP 0 -> 16000 |//
	vip_awpammocost = register_cvar("vip_awpammo_cost","4000");		//| Ammo AWP Cost in Money to VIP 0 -> 16000 |//
	vip_sg552cost = register_cvar("vip_sg552_cost", "7000");			//| SG552 Cost in Money to VIP 0 -> 16000 |//
	vip_sg552ammocost = register_cvar("vip_sg552ammo_cost","4000");		//| Ammo SG552 Cost in Money to VIP 0 -> 16000 |//
	vip_noclipcost = register_cvar("vip_noclip_cost", "10000");		//| NoClip Cost in Money to VIP 0 -> 16000 |//
	vip_silentwalkcost = register_cvar("vip_silentwalk_cost", "100");	//| SilentWalk Cost in Money to VIP 0 -> 16000 |//
	vip_jetpackcost = register_cvar("vip_jetpack_cost", "3000");		//| Jetpack Cost in Money to VIP 0 -> 16000 |//

//------| Vip Sell Cost+ |------//
	vip_sellsilentwalk = register_cvar("vip_sell_silentwalk", "50");		//| SilentWalk Sell Bonus in Money to VIP 0 -> 16000 |//
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// POINTS |
//==========================================================================================================
//------| Points Bonus+ |------//
	fr_points_kill = register_cvar("fr_points_kill", "3");		//| + Points to kill |//
	fr_points_hs = register_cvar("fr_points_hs", "5");		//| + Points to kill with HeadShot |//
	fr_points_knife = register_cvar("fr_points_knife", "10");	//| + Points to kill with knife |//
	fr_points_he = register_cvar("fr_points_he", "15");		//| + Points to kill whit Grenade |//

//------| Buy Cost- |------//
	points_lifecost = register_cvar("fr_life_points", "25");			//| Life Cost in Points |//
	points_healthcost = register_cvar("fr_health_points", "25");		//| Health Cost in Points |//
	points_awpcost = register_cvar("fr_awp_points", "25");			//| AWP Cost in Points |//
	points_awpammocost = register_cvar("fr_awpammo_points","20");		//| Ammo AWP Cost in Points |//
	points_sg552cost = register_cvar("fr_sg552_points", "25");		//| SG552 Cost in Points |//
	points_sg552ammocost = register_cvar("fr_sg552ammo_points","20");	//| Ammo SG552 Cost in Points |//
	points_noclipcost = register_cvar("fr_noclip_points", "40");		//| NoClip Cost in Points |//
	points_silentwalkcost = register_cvar("fr_silentwalk_points", "5");	//| SilentWalk Cost in Points |//
	points_jetpackcost = register_cvar("fr_jetpack_points", "15");		//| Jetpack Cost in Points |//
	
//------| Sell Cost+ |------//
	points_sellsilentwalk = register_cvar("fr_sell_silentwalk_points", "3");	//| SilentWalk Sell Bonus in Points |//

//------| Vip Buy Cost- |------//
	vip_points_lifecost = register_cvar("vip_life_points", "15");		//| Life Cost VIP in Points |//
	vip_points_healthcost = register_cvar("vip_health_points", "15");	//| Health Cost VIP in Points |//
	vip_points_awpcost = register_cvar("vip_awp_points", "20");		//| AWP Cost VIP in Points |//
	vip_points_awpammocost = register_cvar("vip_awpammo_points","15");	//| Ammo AWP Cost VIP in Points |//
	vip_points_sg552cost = register_cvar("vip_sg552_points", "20");		//| SG552 Cost VIP in Points |//
	vip_points_sg552ammocost = register_cvar("vip_sg552ammo_points","15");	//| Ammo SG552 Cost VIP in Points |//
	vip_points_noclipcost = register_cvar("vip_noclip_points", "40");		//| NoClip Cost in Points |//
	vip_points_silentwalkcost = register_cvar("vip_silentwalk_points", "3");	//| SilentWalk Cost VIP in Points |//
	vip_points_jetpackcost = register_cvar("vip_jetpack_points", "10");	//| JetPack Cost VIP in Points |//

//------| Vip Sell Cost+ |------//
	vip_points_sellsilentwalk = register_cvar("vip_sell_silentwalk_points", "1");	//| SilentWalk Bonus VIP in Points |//

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMMANDS CONSOLE/CHAT |
//==========================================================================================================
//------| Admin Give/Take Items |------//
	register_concmd("amx_give_money", "Give_Money", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> 0-10000");
	register_concmd("amx_give_points", "Give_Points", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> Amount");
	register_concmd("amx_reset_points", "Reset_Points", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> Amount");
	register_concmd("amx_give_health", "give_health", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_hp", "give_health", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_awp", "give_awp", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_sg552", "give_sg552", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_noclip", "give_noclip", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_nc", "give_noclip", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_silentwalk", "give_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_sw", "give_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_silentwalk", "take_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_sw", "take_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	
//------| Life Commands |------//
	register_clcmd("life", "buy_life");
	register_clcmd("buy_life", "buy_life");
	register_clcmd("say /life", "buy_life");
	register_clcmd("say buy_life", "buy_life");
	register_clcmd("say_team /life", "buy_life");
	register_clcmd("say_team buy_life", "buy_life");
	
//------| AWP Commands |------//
	register_clcmd("buy_awp", "buy_awp");
	register_clcmd("say /awp", "buy_awp");
	register_clcmd("say buy_awp", "buy_awp");
	register_clcmd("say_team /awp", "buy_awp");
	register_clcmd("say_team buy_awp", "buy_awp");
	
//------| AWP AMMO Commands |------//
	register_clcmd("ammo_awp", "buy_ammo");
	register_clcmd("buy_ammo_awp", "buy_ammo_awp");
	register_clcmd("say /ammo_awp", "buy_ammo_awp");
	register_clcmd("say buy_ammo_awp", "buy_ammo_awp");
	register_clcmd("say_team /ammo_awp", "buy_ammo_awp");
	register_clcmd("say_team buy_ammo_awp", "buy_ammo_awp");

//------| SG552 Commands |------//
	register_clcmd("buy_awp", "buy_sg552");
	register_clcmd("say /awp", "buy_sg552");
	register_clcmd("say buy_awp", "buy_sg552");
	register_clcmd("say_team /awp", "buy_sg552");
	register_clcmd("say_team buy_awp", "buy_sg552");
	
//------| SG552 AMMO Commands |------//
	register_clcmd("ammo_sg552", "buy_ammo");
	register_clcmd("buy_ammo_sg552", "buy_ammo_sg552");
	register_clcmd("say /ammo_sg552", "buy_ammo_sg552");
	register_clcmd("say buy_ammo_sg552", "buy_ammo_sg552");
	register_clcmd("say_team /ammo_sg552", "buy_ammo_sg552");
	register_clcmd("say_team buy_ammo_sg552", "buy_ammo_sg552");
	
//------| NoClip Commands |------//
	register_clcmd("noclip", "buy_noclip");
	register_clcmd("buy_noclip", "buy_noclip");
	register_clcmd("nc", "buy_noclip");
	register_clcmd("buy_nc", "buy_noclip");
	register_clcmd("say /noclip", "buy_noclip");
	register_clcmd("say buy_noclip", "buy_noclip");
	register_clcmd("say /nc", "buy_noclip");
	register_clcmd("say buy_nc", "buy_noclip");
	register_clcmd("say_team /noclip", "buy_noclip");
	register_clcmd("say_team buy_noclip", "buy_noclip");
	register_clcmd("say_team /nc", "buy_noclip");
	register_clcmd("say_team buy_nc", "buy_noclip");
	
//------| Health Commands |------//
	register_clcmd("hp", "buy_health");
	register_clcmd("health", "buy_health");
	register_clcmd("buy_hp", "buy_health");
	register_clcmd("buy_health", "buy_health");
	register_clcmd("say /hp", "buy_health");
	register_clcmd("say buy_hp", "buy_health");
	register_clcmd("say /health", "buy_health");
	register_clcmd("say buy_health", "buy_health");
	register_clcmd("say_team /hp", "buy_health");
	register_clcmd("say_team buy_hp", "buy_health");
	register_clcmd("say_team /health", "buy_health");
	register_clcmd("say_team buy_health", "buy_health");
	
//------| SilentWalk Commands |------//;
	register_clcmd("sw", "buy_silentwalk");
	register_clcmd("silentwalk", "buy_silentwalk");
	register_clcmd("say /silentwalk", "buy_silentwalk");
	register_clcmd("say buy_silentwalk", "buy_silentwalk");
	register_clcmd("say /sw", "buy_silentwalk");
	register_clcmd("say buy_sw", "buy_silentwalk");
	register_clcmd("say_team /silentwalk", "buy_silentwalk");
	register_clcmd("say_team buy_silentwalk", "buy_silentwalk");
	register_clcmd("say_team /sw", "buy_silentwalk");
	register_clcmd("say_team buy_sw", "buy_silentwalk");
	register_clcmd("sellsilentwalkk", "sell_silentwalk");
	register_clcmd("sellsw", "sell_silentwalk");
	register_clcmd("sell_silentwalk", "sell_silentwalk");
	register_clcmd("sell_sw", "sell_silentwalk");
	register_clcmd("say /sellsilentwalk", "sell_silentwalk");
	register_clcmd("say sell_silentwalk", "sell_silentwalk");
	register_clcmd("say /sellsw", "sell_silentwalk");
	register_clcmd("say sell_sw", "sell_silentwalk");
	register_clcmd("say_team /sellsilentwalk", "sell_silentwalk");
	register_clcmd("say_team sell_silentwalk", "sell_silentwalk");
	register_clcmd("say_team /sellsw", "sell_silentwalk");
	register_clcmd("say_team sell_sw", "sell_silentwalk");
	
//------| JetPack Commands |------//
	register_clcmd("jetpack", "buy_jetpack");
	register_clcmd("buy_jetpack", "buy_jetpack");
	register_clcmd("jp", "buy_jetpack");
	register_clcmd("buy_jp", "buy_jetpack");
	register_clcmd("say /jetpack", "buy_jetpack");
	register_clcmd("say buy_jetpack", "buy_jetpack");
	register_clcmd("say /jp", "buy_jetpack");
	register_clcmd("say buy_jp", "buy_jetpack");
	register_clcmd("say_team /jp", "buy_jetpack");
	register_clcmd("say_team buy_jp", "buy_jetpack");
	register_clcmd("say_team /jetpack", "buy_jetpack");
	register_clcmd("say_team buy_jetpack", "buy_jetpack");
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Plugin CFG |
//==========================================================================================================
public plugin_cfg() {
	new iCfgDir[32], iFile[192];
	
	get_configsdir(iCfgDir, charsmax(iCfgDir));
	formatex(iFile, charsmax(iFile), "%s/FrShop.cfg", iCfgDir);
		
	if(!file_exists(iFile)) {
	server_print("[FrShop] FrShop.cfg nu exista. Se creeaza.", iFile);
	write_file(iFile, " ", -1);
	}
	
	else {		
	server_print("[FrShop] FrShop.cfg sa incarcat.", iFile);
	server_cmd("exec %s", iFile);
	}
	server_cmd("sv_maxspeed 99999999.0");
	server_cmd("sv_airaccelerate 99999999.0");
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Message Hud |
//==========================================================================================================
public MesajHud(id) {
	set_hudmessage(0, 100, 200, -1.0, 0.17, 0, 6.0, 12.0, 0.01, 0.1, 10);
	show_hudmessage(id, "Acest servar foloseste FrShop by Aragon*.^nScrie /frshop sau /shop in chat pentru a cumpara Item.");
	}
public client_putinserver(id) {
	if(get_pcvar_num(furienshop) != 0) {
	set_task(get_pcvar_float(Mesaj), "MesajHud", 0, _, _, "b");
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Furien Shop Menu |
//==========================================================================================================
public cmdShop(id) {
	new lcost, awcost, aawcost, sgcost, asgcost, hpcost, ncost, jpcost, swcost, sellsw;
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	if(get_pcvar_num(furienshopmod) == 0) {
	lcost = get_pcvar_num(vip_lifecost);
	awcost = get_pcvar_num(vip_awpcost);
	aawcost = get_pcvar_num(vip_awpammocost);
	sgcost = get_pcvar_num(vip_sg552cost);
	asgcost = get_pcvar_num(vip_sg552ammocost);
	hpcost = get_pcvar_num(vip_healthcost);
	ncost = get_pcvar_num(vip_noclipcost);
	swcost = get_pcvar_num(vip_silentwalkcost);
	jpcost = get_pcvar_num(vip_jetpackcost);
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	lcost = get_pcvar_num(vip_points_lifecost);
	awcost = get_pcvar_num(vip_points_awpcost);
	aawcost = get_pcvar_num(vip_points_awpammocost);
	sgcost = get_pcvar_num(vip_points_sg552cost);
	asgcost = get_pcvar_num(vip_points_sg552ammocost);
	hpcost = get_pcvar_num(healthcost);
	ncost = get_pcvar_num(vip_points_noclipcost);
	swcost = get_pcvar_num(vip_points_silentwalkcost);
	jpcost = get_pcvar_num(vip_points_jetpackcost);
	sellsw = get_pcvar_num(vip_points_sellsilentwalk);
	}
	}
	else {
	if(get_pcvar_num(furienshopmod) == 0) {
	lcost = get_pcvar_num(lifecost);
	awcost = get_pcvar_num(awpcost);
	aawcost = get_pcvar_num(awpammocost);
	sgcost = get_pcvar_num(sg552cost);
	asgcost = get_pcvar_num(sg552ammocost);
	hpcost = get_pcvar_num(vip_points_healthcost);
	ncost = get_pcvar_num(noclipcost);
	swcost = get_pcvar_num(silentwalkcost);
	jpcost = get_pcvar_num(jetpackcost);
	sellsw = get_pcvar_num(sellsilentwalk);
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	lcost = get_pcvar_num(points_lifecost);
	awcost = get_pcvar_num(points_awpcost);
	aawcost = get_pcvar_num(points_awpammocost);
	sgcost = get_pcvar_num(points_sg552cost);
	asgcost = get_pcvar_num(points_sg552ammocost);
	hpcost = get_pcvar_num(points_healthcost);
	ncost = get_pcvar_num(points_noclipcost);
	swcost = get_pcvar_num(points_silentwalkcost);
	jpcost = get_pcvar_num(points_jetpackcost);
	sellsw = get_pcvar_num(points_sellsilentwalk);
	}
	}
	new mh = get_pcvar_num(maxhealth);
	new nctime = get_pcvar_num(nocliptime);
	new jptime = get_pcvar_num(jetpacktime);
	new bani = cs_get_user_money(id);
	if(get_pcvar_num(furienshop) == 0) {
	ColorChat(id, "^x03%s FrShop^x04 este^x03 Dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti accesa^x03 FrShop^x04 cat timp esti ^x03 Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}	
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	new buffer2[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rFurien Shop\w \yVIP\w^n\rMoney:\w \y%i$\w \rPage\w\y",bani);
	menu = menu_create(buffer2, "frshop");
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rFurien Shop\w \yVIP\w^n\rPoints:\w \y%i\w \rPage\w\y",PlayerPoints[id]);
	menu = menu_create(buffer2, "frshop");
	}
	}
	else {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\rFurien Shop\w^n\rMoney:\w \y%i$\w \rPage\w\y",bani);
	menu = menu_create(buffer, "frshop");
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\rFurien Shop\w^n\rPoints:\w \y%i\w \rPage\w\y",PlayerPoints[id]);
	menu = menu_create(buffer, "frshop");
	}
	}
	//------| Life |------//
	if(!is_user_alive(id)) {
	if(get_pcvar_num(acces_life) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_life) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_life) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(life) == 0) { 
	}
	else if(!is_user_alive(id) && lcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wLife - \rFree\w");
	menu_additem(menu, buffer, "1", 0);
	}
	else if(!is_user_alive(id)) { 
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLife - \y%i$\w",lcost);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLife - \y%i Points\w",lcost);
	menu_additem(menu, buffer, "1", 0);
	}
	}
	}
	if(is_user_alive(id)) {
//------| AWP |------//
	if(get_pcvar_num(acces_awp) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_awp) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_awp) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(awp) == 0) { 
	}
	else if(!user_has_weapon (id, CSW_AWP) && awcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \rFree\w");
	menu_additem(menu, buffer, "2", 0);
	}
	else if(user_has_weapon(id, CSW_AWP) && cs_get_user_bpammo(id, CSW_AWP)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \rAlready Have\w");
	menu_additem(menu, buffer, "2", 0);
	}
	else if(!user_has_weapon (id, CSW_AWP)) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \y%i$\w",awcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \y%i Points\w",awcost);
	menu_additem(menu, buffer, "2", 0);
	}
	}
	else if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \y%i$\w",aawcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAWP - \y%i Points\w",aawcost);
	menu_additem(menu, buffer, "2", 0);
	}
	}
	
//------| SG552 |------//
	if(get_pcvar_num(acces_sg552) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_sg552) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_sg552) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(awp) == 0) { 
	}
	else if(!user_has_weapon (id, CSW_SG552) && sgcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \rFree\w");
	menu_additem(menu, buffer, "3", 0);
	}
	else if(user_has_weapon(id, CSW_SG552) && cs_get_user_bpammo(id, CSW_SG552)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \rAlready Have\w");
	menu_additem(menu, buffer, "3", 0);
	}
	else if(!user_has_weapon (id, CSW_SG552)) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \y%i$\w",sgcost);
	menu_additem(menu, buffer, "3", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \y%i Points\w",sgcost);
	menu_additem(menu, buffer, "3", 0);
	}
	}
	else if(user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \y%i$\w",asgcost);
	menu_additem(menu, buffer, "3", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSG552 - \y%i Points\w",asgcost);
	menu_additem(menu, buffer, "3", 0);
	}
	}

//------| Health |------//
	if(get_pcvar_num(acces_health) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_health) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_health) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	if(get_pcvar_num(health) == 0) { 
	}
	else if(get_user_health(id) == mh) {
	menu_additem(menu, "\wHealth - \rMax Health\w", "4", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \y(%d)\w - \rFree\w ",mh ,hpcost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(furienshopmod) == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(%d)\w - \y%i$\w ",mh ,hpcost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(%d)\w - \y%i Points\w ",mh ,hpcost);
	menu_additem(menu, buffer, "4", 0);
	}
	
//------| NoClip |------//
	if(get_pcvar_num(acces_noclip) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_noclip) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_noclip) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(noclip) == 0) { 
	}
	else if(!get_user_noclip(id) && ncost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wNo Clip - \rFree\w \y(%d Secunde)\w",nctime);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(!get_user_noclip(id)) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNo Clip - \y%i$\w \r(%d Secunde)\w",ncost,nctime);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNo Clip - \y%i Points\w \r(%d Secunde)\w",ncost,nctime);
	menu_additem(menu, buffer, "5", 0);
	}
	}
	else if(get_user_noclip(id)) {
	menu_additem(menu, "\wNo Clip - \rAlready Have\w", "8", 0);
	}

//------| Silent Walk |------//
	if(get_pcvar_num(acces_silentwalk) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_silentwalk) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_silentwalk) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(silentwalk) == 0) { 
	}
	else if(!get_user_footsteps(id) && swcost == 0 && !g_hasSilentWalk[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \rFree\w");
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \rAlready Have\w",sellsw);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(!get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \y%i$\w",swcost);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \y%i Points\w",swcost);
	menu_additem(menu, buffer, "6", 0);
	}
	}
	else if(get_user_footsteps(id) && g_hasSilentWalk[id]) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Silent Walk - \r+%i$\w",sellsw);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSell Silent Walk - \r+%i Points\w",sellsw);
	menu_additem(menu, buffer, "6", 0);
	}
	}
	
//------| JetPack |------//
	if(get_pcvar_num(acces_jetpack) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_jetpack) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_jetpack) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(jetpack) == 0) { 
	}
	else if(!has_jp[id] && jpcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wJetPack - \rFree\w \y(%d Secunde)\w",jptime);
	menu_additem(menu, buffer, "7", 0);
	}
	else if(!has_jp[id]) {
	new buffer[256];
	if(get_pcvar_num(furienshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wJetPack - \y%i$\w \r(%d Secunde)\w",jpcost, jptime);
	menu_additem(menu, buffer, "7", 0);
	}
	else if(get_pcvar_num(furienshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wJetPack - \y%i Points\w \r(%d Secunde)\w",jpcost, jptime);
	menu_additem(menu, buffer, "7", 0);
	}
	}
	else if(has_jp[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wJetpack - \rAlready Have\w");
	menu_additem(menu, buffer, "7", 0);
	}
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Furien Shop Case |
//==========================================================================================================
public frshop(id, menu, item) {

	if(item == MENU_EXIT) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key) {
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life |
//==========================================================================================================
case 1: buy_life(id);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// AWP Case |
//==========================================================================================================
case 2: {
	new bani = cs_get_user_money(id);
	new awcost, aawcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	awcost = get_pcvar_num(vip_awpcost);
	aawcost = get_pcvar_num(vip_awpammocost);
	}
	else {
	awcost = get_pcvar_num(awpcost);
	aawcost = get_pcvar_num(awpammocost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	awcost = get_pcvar_num(vip_points_awpcost);
	aawcost = get_pcvar_num(vip_points_awpammocost);
	}
	else {
	awcost = get_pcvar_num(points_awpcost);
	aawcost = get_pcvar_num(points_awpammocost);
	}
	}
	if(get_pcvar_num(awp) == 0) { 
	ColorChat(id, "^x03%s AWP^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && cs_get_user_bpammo(id, CSW_AWP)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < aawcost && user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,aawcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	cs_set_user_money(id, bani - aawcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 AWP.",Prefix);
	cs_set_user_bpammo(id, CSW_AWP, cs_get_user_bpammo(id, CSW_AWP) + 10);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(bani < awcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara un^x03 AWP^x04. Necesari:^x03 %i$",Prefix,awcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_AWP)) {
	cs_set_user_money(id, bani - awcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_awp");
	Screen1(id);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < aawcost && user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,aawcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	PlayerPoints[id] -= aawcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 AWP.",Prefix);
	cs_set_user_bpammo(id, CSW_AWP, cs_get_user_bpammo(id, CSW_AWP) + 10);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < awcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara un^x03 AWP^x04. Necesare:^x03 %i Puncte",Prefix,awcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_AWP)) {
	PlayerPoints[id] -= awcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_awp");
	Screen1(id);
	}
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SG552 Case |
//==========================================================================================================
case 3: {
	new bani = cs_get_user_money(id);
	new sgcost, asgcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sgcost = get_pcvar_num(vip_sg552cost);
	asgcost = get_pcvar_num(vip_sg552ammocost);
	}
	else {
	sgcost = get_pcvar_num(sg552cost);
	asgcost = get_pcvar_num(sg552ammocost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sgcost = get_pcvar_num(vip_points_sg552cost);
	asgcost = get_pcvar_num(vip_points_sg552ammocost);
	}
	else {
	sgcost = get_pcvar_num(points_sg552cost);
	asgcost = get_pcvar_num(points_sg552ammocost);
	}
	}
	if(get_pcvar_num(sg552) == 0) { 
	ColorChat(id, "^x03%s SG552^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552) && cs_get_user_bpammo(id, CSW_SG552)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < asgcost && user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,asgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	cs_set_user_money(id, bani - sgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 SG552.",Prefix);
	cs_set_user_bpammo(id, CSW_AWP, cs_get_user_bpammo(id, CSW_SG552) + 30);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(bani < sgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara un^x03 SG552^x04. Necesari:^x03 %i$",Prefix,sgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_SG552)) {
	cs_set_user_money(id, bani - sgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_sg552");
	Screen1(id);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < asgcost && user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,asgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	PlayerPoints[id] -= asgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 SG552.",Prefix);
	cs_set_user_bpammo(id, CSW_SG552, cs_get_user_bpammo(id, CSW_SG552) + 30);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < sgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara un^x03 SG552^x04. Necesare:^x03 %i Puncte",Prefix,sgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_SG552)) {
	PlayerPoints[id] -= sgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_sg552");
	Screen1(id);
	}
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Heatlh |
//==========================================================================================================
case 4: buy_health(id);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NoClip |
//==========================================================================================================
case 5: buy_noclip(id);
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Silent Walk Case |
//==========================================================================================================
case 6: {
	new bani = cs_get_user_money(id);
	new swcost, sellsw;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_silentwalkcost);
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	else {
	swcost = get_pcvar_num(silentwalkcost);
	sellsw = get_pcvar_num(sellsilentwalk);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_points_silentwalkcost);
	sellsw = get_pcvar_num(vip_points_sellsilentwalk);
	}
	else {
	swcost = get_pcvar_num(points_silentwalkcost);
	sellsw = get_pcvar_num(points_sellsilentwalk);
	}
	}
	if(get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	ColorChat(id, "^x03%s^x04 Detii deja^x03 Silent Walk^x04 din alte surse.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(silentwalk) == 0) { 
	ColorChat(id, "^x03%s Silent Walk^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Silent Walk^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Silent Walk^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_user_footsteps(id) && g_hasSilentWalk[id]) {
	cs_set_user_money(id, bani + sellsw);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Silent Walk^x04,ai primit^x03 %i$.",Prefix,sellsw);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 0);
	g_hasSilentWalk[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(bani < swcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Silent Walk^x04. Necesari:^x03 %i$",Prefix,swcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	cs_set_user_money(id, bani - swcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 1);
	g_hasSilentWalk[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_user_footsteps(id) && g_hasSilentWalk[id]) {
	PlayerPoints[id] += sellsw;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Silent Walk^x04,ai primit^x03 %i Puncte.",Prefix,sellsw);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 0);
	g_hasSilentWalk[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < swcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Silent Walk^x04. Necesare:^x03 %i Puncte",Prefix,swcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	PlayerPoints[id] -= swcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 1);
	g_hasSilentWalk[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Jetpack |
//==========================================================================================================
case 7: buy_jetpack(id);

	default: return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Chat and Console Commands |
//==========================================================================================================
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// AWP Commands |
//==========================================================================================================
//------| Buy AWP |------//
public buy_awp(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new awcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	awcost = get_pcvar_num(vip_awpcost);
	}
	else {
	awcost = get_pcvar_num(awpcost);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	awcost = get_pcvar_num(vip_points_awpcost);
	}
	else {
	awcost = get_pcvar_num(points_awpcost);	
	}
	}
	if(get_pcvar_num(awp) == 0) { 
	ColorChat(id, "^x03%s AWP^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 AWP^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < awcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 AWP^x04. Necesari:^x03 %i$",Prefix,awcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - awcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_awp");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < awcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 AWP^x04. Necesare:^x03 %i Puncte",Prefix,awcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= awcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_awp");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give AWP |------//
public give_awp(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_AWP)) {
	give_item(players, "weapon_awp");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 AWP^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 AWP^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_AWP)) {
	give_item(players, "weapon_awp");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 AWP^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 AWP^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_AWP)) {
	give_item(players, "weapon_awp");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 AWP^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 AWP^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(player, CSW_AWP)) {
	give_item(player, "weapon_awp");
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 AWP.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 AWP.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Buy AWP AMMO |------//
public buy_ammo_awp(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new adcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	adcost = get_pcvar_num(vip_awpammocost);
	}	
	else {
	adcost = get_pcvar_num(awpammocost);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	adcost = get_pcvar_num(vip_points_awpammocost);
	}	
	else {
	adcost = get_pcvar_num(points_awpammocost);	
	}
	}
	if(get_pcvar_num(awp) == 0) { 
	ColorChat(id, "^x03%s AWP Ammo^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_awp) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gloante^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gloante^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Glonte^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && cs_get_user_bpammo(id, CSW_AWP)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < adcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	cs_set_user_money(id, bani - adcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_AWP, 10);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < adcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_AWP)) {
	PlayerPoints[id] -= adcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_AWP, 10);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SG552 Commands |
//==========================================================================================================
//------| Buy SG552 |------//
public buy_sg552(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new sgcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sgcost = get_pcvar_num(vip_sg552cost);
	}
	else {
	sgcost = get_pcvar_num(sg552cost);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sgcost = get_pcvar_num(vip_points_sg552cost);
	}
	else {
	sgcost = get_pcvar_num(points_sg552cost);	
	}
	}
	if(get_pcvar_num(sg552) == 0) { 
	ColorChat(id, "^x03%s SG552^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 SG552^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < sgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 SG552^x04. Necesari:^x03 %i$",Prefix,sgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - sgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_sg552");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < sgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 SG552^x04. Necesare:^x03 %i Puncte",Prefix,sgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= sgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_sg552");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give AWP |------//
public give_sg552(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_SG552)) {
	give_item(players, "weapon_sg552");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 SG552^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 SG552^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_SG552)) {
	give_item(players, "weapon_sg552");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 SG552^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 SG552^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_SG552)) {
	give_item(players, "weapon_sg552");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 SG552^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 SG552^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(player, CSW_SG552)) {
	give_item(player, "weapon_sg552");
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 SG552.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 SG552.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Buy AWP AMMO |------//
public buy_ammo_sg552(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new asgcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	asgcost = get_pcvar_num(vip_sg552ammocost);
	}	
	else {
	asgcost = get_pcvar_num(sg552ammocost);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	asgcost = get_pcvar_num(vip_points_sg552ammocost);
	}	
	else {
	asgcost = get_pcvar_num(points_sg552ammocost);	
	}
	}
	if(get_pcvar_num(sg552) == 0) { 
	ColorChat(id, "^x03%s SG552 Ammo^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_sg552) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gloante^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gloante^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Glonte^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552) && cs_get_user_bpammo(id, CSW_SG552)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < asgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,asgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_SG552) && !cs_get_user_bpammo(id, CSW_SG552)) {
	cs_set_user_money(id, bani - asgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 AWP.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_SG552, 30);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < asgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,asgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_AWP) && !cs_get_user_bpammo(id, CSW_SG552)) {
	PlayerPoints[id] -= asgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 SG552.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_SG552, 30);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life Commands |
//==========================================================================================================
//------| Buy Life |------//
public buy_life(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new lcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_lifecost);
	}
	else {
	lcost = get_pcvar_num(lifecost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_points_lifecost);
	}
	else {
	lcost = get_pcvar_num(points_lifecost);
	}
	}
	if(get_pcvar_num(life) == 0) { 
	ColorChat(id, "^x03%s Life^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_life) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Life.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_life) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Life.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_life) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Life.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Life^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Life^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Esti deja in^x03 viata.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < lcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Viata^x04. Necesari:^x03 %i$",Prefix,lcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	cs_set_user_money(id, cs_get_user_money(id) - lcost);
	ColorChat(id, "^x03%s^x04 Vei renvia in^x03 3^x04 secunde.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_team(id, CS_TEAM_CT);
	set_task(3.2,"spawnagain",id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < lcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 Viata^x04. Necesari:^x03 %i Puncte",Prefix,lcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	PlayerPoints[id] -= lcost;
	ColorChat(id, "^x03%s^x04 Vei renvia in^x03 3^x04 secunde.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_team(id, CS_TEAM_CT);
	set_task(3.2,"spawnagain",id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Health Commands |
//==========================================================================================================
//------| Buy Health |------//
public buy_health(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new mh = get_pcvar_num(maxhealth);
	new hpcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_healthcost);
	}
	else {
	hpcost = get_pcvar_num(healthcost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_points_healthcost);
	}
	else {
	hpcost = get_pcvar_num(points_healthcost);
	}
	}
	if(get_pcvar_num(health) == 0) { 
	ColorChat(id, "^x03%s Health^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_health) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Health.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_health) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Health.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_health) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Health.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Health^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Health^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Health^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_user_health(id) == mh) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 %d HP.",Prefix, mh);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < hpcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Health^x04. Necesari:^x03 %i$",Prefix,hpcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - hpcost);
	ColorChat(id, "^x03%s^x04 Ai^x03 %d HP.",Prefix, mh);
	set_user_health(id, mh);
	emit_sound(id,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < hpcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Health^x04. Necesare:^x03 %i Puncte",Prefix,hpcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= hpcost;
	ColorChat(id, "^x03%s^x04 Ai^x03 %d HP.",Prefix, mh);
	set_user_health(id, mh);
	emit_sound(id,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Health |------//
public give_health(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	new mh = get_pcvar_num(maxhealth);
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_health(players) < mh) {
	set_user_health(players, get_pcvar_num(maxhealth));
	emit_sound(players,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d HP^x04 to all^x03 Ts.",mh);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d HP^x04 to all^x03 Ts.", name ,mh);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_health(players) < mh) {
	set_user_health(players, get_pcvar_num(maxhealth));
	emit_sound(players,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d HP^x04 to all^x03 CTs.",mh);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d HP^x04 to all^x03 CTs.", name ,mh);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_health(players) < mh) {
	set_user_health(players, get_pcvar_num(maxhealth));
	emit_sound(players,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d HP^x04 to all^x03 Players.",mh);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d HP^x04 to all^x03 Players.", name ,mh);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(get_user_health(player) < mh) {
	set_user_health(player, get_pcvar_num(maxhealth));
	emit_sound(player,CHAN_ITEM,HP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, player);
	write_string("cross");
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 %d HP.",mh);
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 %d HP.", name ,mh);
	}
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NoClip Commands |
//==========================================================================================================
//------| Buy NoClip |------//
public buy_noclip(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new nctime = get_pcvar_num(nocliptime);
	new ncost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ncost = get_pcvar_num(vip_noclipcost);
	}
	else {
	ncost = get_pcvar_num(noclipcost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ncost = get_pcvar_num(vip_points_noclipcost);
	}
	else {
	ncost = get_pcvar_num(points_noclipcost);
	}
	}
	if(get_pcvar_num(noclip) == 0) { 
	ColorChat(id, "^x03%s NoClip^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_noclip) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 NoClip.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_noclip) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 NoClip.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_noclip) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 NoClip.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NoClip^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NoClip^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NoClip^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_user_noclip(id)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 No Clip.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < ncost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 No Clip^x04. Necesari:^x03 %i$",Prefix,ncost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_noclip(id)) {
	cs_set_user_money(id, bani - ncost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 No Clip^x04 pentru^x03 %d^x04 secunde.",Prefix ,nctime);
	emit_sound(id,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_noclip(id,1);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < ncost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 No Clip^x04. Necesare:^x03 %i Puncte",Prefix,ncost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_noclip(id)) {
	PlayerPoints[id] -= ncost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 No Clip^x04 pentru^x03 %d^x04 secunde.",Prefix ,nctime);
	emit_sound(id,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_noclip(id,1);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give NoClip |------//
public give_noclip(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_noclip(players)) {
	set_user_noclip(players,1);
	emit_sound(players,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NoClip^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NoClip^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_noclip(players)) {
	set_user_noclip(players,1);
	emit_sound(players,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NoClip^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NoClip^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_noclip(players)) {
	set_user_noclip(players,1);
	emit_sound(players,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NoClip^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NoClip^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!get_user_noclip(player)) {
	set_user_noclip(player,1);
	emit_sound(player,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(nocliptime)),"removeNoClip",player);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 NoClip.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 NoClip.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Silent Walk Commands |
//==========================================================================================================
//------| Buy Silent Walk |------//
public buy_silentwalk(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new swcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_silentwalkcost);
	}
	else {
	swcost = get_pcvar_num(silentwalkcost);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_silentwalkcost);
	}
	else {
	swcost = get_pcvar_num(silentwalkcost);	
	}
	}
	if(get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(silentwalkcost));
	ColorChat(id, "^x03%s^x04 Detii deja^x03 Silent Walk^x04 din alet surse.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(silentwalk) == 0) { 
	ColorChat(id, "^x03%s Silent Walk^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_silentwalk) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Silent Walk^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Silent Walk^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_user_footsteps(id)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < swcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Silent Walk^x04. Necesari:^x03 %i$",Prefix,swcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_footsteps(id) && g_hasSilentWalk[id]) {
	cs_set_user_money(id, bani - swcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 1);
	g_hasSilentWalk[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < swcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Silent Walk^x04. Necesare:^x03 %i Puncte",Prefix,swcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_footsteps(id) && g_hasSilentWalk[id]) {
	PlayerPoints[id] -= swcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 1);
	g_hasSilentWalk[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Sell Silent Walk |------//
public sell_silentwalk(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new sellsw;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	else {
	sellsw = get_pcvar_num(sellsilentwalk);	
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellsw = get_pcvar_num(vip_points_sellsilentwalk);
	}
	else {
	sellsw = get_pcvar_num(points_sellsilentwalk);	
	}
	}
	if(!get_user_footsteps(id)) {
	ColorChat(id, "^x03%s^x04 Nu ai^x03 Silent Walk.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_user_footsteps(id)) {
	cs_set_user_money(id, cs_get_user_money(id) + sellsw);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Silent Walk^x04,ai primit^x03 %i$.",Prefix,sellsw);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 0);
	g_hasSilentWalk[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_user_footsteps(id)) {
	PlayerPoints[id] += sellsw;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Silent Walk^x04,ai primit^x03 %i Puncte.",Prefix,sellsw);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_footsteps(id, 0);
	g_hasSilentWalk[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Silent Walk |------//
public give_silentwalk(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_footsteps(players)) {
	set_user_footsteps(players, 1);
	g_hasSilentWalk[players] = 1;
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Silent Walk^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Silent Walk^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_footsteps(players)) {
	set_user_footsteps(players, 1);
	g_hasSilentWalk[players] = 1;
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Silent Walk^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Silent Walk^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_footsteps(players)) {
	set_user_footsteps(players, 1);
	g_hasSilentWalk[players] = 1;
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Silent Walk^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Silent Walk^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!get_user_footsteps(player)) {
	set_user_footsteps(player, 1);
	g_hasSilentWalk[player] = 1;
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Silent Walk.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Silent Walk.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Take Silent Walk |------//
public take_silentwalk(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_footsteps(players)) {
	set_user_footsteps(players, 0);
	g_hasSilentWalk[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Silent Walk^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Silent Walk^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_footsteps(players)) {
	set_user_footsteps(players, 0);
	g_hasSilentWalk[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Silent Walk^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Silent Walk^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_footsteps(players)) {
	set_user_footsteps(players, 0);
	g_hasSilentWalk[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Silent Walk^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Silent Walk^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(get_user_footsteps(player)) {
	set_user_footsteps(player, 0);
	g_hasSilentWalk[player] = 0;
	emit_sound(player,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 take your^x03 Silent Walk.");
	case 2: ColorChat(player, "^x03%s^x04 take your^x03 Silent Walk.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// JetPack Commands |
//==========================================================================================================
//------| Buy JetPack |------//
public buy_jetpack(id) {
	if(get_pcvar_num(furienshop) != 0) {
	new bani = cs_get_user_money(id);
	new jptime = get_pcvar_num(jetpacktime);
	new jpcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	jpcost = get_pcvar_num(vip_jetpackcost);
	}
	else {
	jpcost = get_pcvar_num(jetpackcost);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	jpcost = get_pcvar_num(vip_points_jetpackcost);
	}
	else {
	jpcost = get_pcvar_num(points_jetpackcost);
	}
	}
	if(get_pcvar_num(jetpack) == 0) { 
	ColorChat(id, "^x03%s Jetpack^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_jetpack) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Jetpack.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_jetpack) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Jetpack.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_jetpack) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Jetpack.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Jetpack^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Jetpack^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 JetPack^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(has_jp[id]) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Jetpack.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(bani < jpcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Jetpack^x04. Necesari:^x03 %i$",Prefix ,jpcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_jp[id]) {
	cs_set_user_money(id, bani - jpcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Jetpack^x04 pentru^x03 %d^x04 secunde.", Prefix, jptime);
	ColorChat(id, "^x03%s^x04 Pentru utilizare apasa tasta^x03 Space.", Prefix);
	emit_sound(id,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_jp[id] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(PlayerPoints[id] < jpcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Jetpack^x04. Necesare:^x03 %i Puncte",Prefix ,jpcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_jp[id]) {
	PlayerPoints[id] -= jpcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Jetpack^x04 pentru^x03 %d^x04 secunde.", Prefix, jptime);
	ColorChat(id, "^x03%s^x04 Pentru utilizare apasa tasta^x03 Space.", Prefix);
	emit_sound(id,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_jp[id] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give JetPack |------//
public give_jetpack(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!has_jp[players]) {
	has_jp[players] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",players);
	emit_sound(players,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Jetpack^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Jetpack^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!has_jp[players]) {
	has_jp[players] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",players);
	emit_sound(players,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Jetpack^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Jetpack^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!has_jp[players]) {
	has_jp[players] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",players);
	emit_sound(players,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Jetpack^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Jetpack^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!has_jp[player]) {
	has_jp[player] = true;
	set_task(float(get_pcvar_num(jetpacktime)),"removeJetpack",player);
	emit_sound(player,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Jetpack.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Jetpack.", name);
	}
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Give Money |
//==========================================================================================================
//------| Give Money |------//
public Give_Money(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	new give_money[10];
	read_argv(2, give_money, charsmax(give_money));
	new Money = str_to_num(give_money);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	cs_set_user_money(players, cs_get_user_money(players) + Money);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i $^x04 to all^x03 Ts.", Money);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i $^x04 to all^x03 Ts.", name, Money);
	}
	}
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	cs_set_user_money(players, cs_get_user_money(players) + Money);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i $ Money^x04 to all^x03 CTs.", Money);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i $ Money^x04 to all^x03 CTs.", name, Money);
	}
	}
	if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	cs_set_user_money(players, cs_get_user_money(players) + Money);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i $^x04 to all^x03 Players.", Money);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i $^x04 to all^x03 Players.", name, Money);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(player, cs_get_user_money(player) + Money);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 %i $.", Money);
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 %i $.", name, Money);
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Give/Reset Points |
//==========================================================================================================
//------| Give Points |------//
public Give_Points(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	new give_points[5];
	read_argv(2, give_points, charsmax(give_points));
	new Points = str_to_num(give_points);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] += Points;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i Points^x04 to all^x03 Ts.", Points);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i Points^x04 to all^x03 Ts.", name, Points);
	}
	}
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] += Points;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i Points^x04 to all^x03 CTs.", Points);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i Points^x04 to all^x03 CTs.", name, Points);
	}
	}
	if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] += Points;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 %i Points^x04 to all^x03 Players.", Points);
	case 2: ColorChat(0, "^x03%s^x04 give^x03 %i Points^x04 to all^x03 Players.", name, Points);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	PlayerPoints[player] += Points;
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 %i Points.", Points);
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 %i Points.", name, Points);
	}
	return PLUGIN_HANDLED;
	}
	
//------| Reset Points |------//
public Reset_Points(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] = 0;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 reset^x03 Points^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 reset^x03 Points^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] = 0;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 reset^x03 %i Points^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 reset^x03 %i Points^x04 to all^x03 CTs.", name);
	}
	}
	if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	PlayerPoints[players] = 0;
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 reset^x03 Points^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 resetx03 Points^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[FrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[FrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	PlayerPoints[player] = 0;
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 reset your^x03 Points.");
	case 2: ColorChat(player, "^x03%s^x04 reset your^x03 Points.", name);
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Client |
//==========================================================================================================
//------| Round Start |------//
public EventRoundStart() {
	roundend = false;
	has_started = true;
	}
	
//------| Round End |------//
public EventRandromize() {
	roundend = true;
	}
//------| Clien Connect |------//
	
public client_connect(id) {
	LoadPoints(id);
	g_hasSilentWalk[id] = 0;
	}
	
//------| Client Disconecct |------//
public client_disconnect(id) {
	if(get_pcvar_num(furienshopmod) == 1) {
	SavePoints(id);
	}
	g_hasSilentWalk[id] = 0;
	}
	
//------| Give Noney/Points to killer |------//
public client_death(killer,victim,wpnindex,hitplace,TK) {
	//------| Give Money/Points to Kill the enemy |------//
	if (killer != victim) {
	if(get_pcvar_num(furienshopmod) != 0) {
	PlayerPoints[killer] += get_pcvar_num(fr_points_kill);
	if(hitplace == HIT_HEAD) {
 	PlayerPoints[killer] += get_pcvar_num(fr_points_hs);
	}
 	if(wpnindex == CSW_KNIFE) {
 	PlayerPoints[killer] += get_pcvar_num(fr_points_knife);
	}
 	if(wpnindex == CSW_HEGRENADE) {
 	PlayerPoints[killer] += get_pcvar_num(fr_points_he);
	}
	SavePoints(killer);
	}
	if(get_pcvar_num(furienshopmod) != 1) {
	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(fr_money_kill));
	if(hitplace == HIT_HEAD) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(fr_money_hs));
	}
 	if(wpnindex == CSW_KNIFE) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(fr_money_knife));
	}
 	if(wpnindex == CSW_HEGRENADE) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(fr_money_he));
	}
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, killer);
	write_string("dollar");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	}
	}
	}
	
//------| Deatch MSG |------//
public death_event() {
	new Victim = read_data(2);
	g_hasSilentWalk[Victim] = 0;
	set_user_footsteps(Victim, 0);
	return PLUGIN_CONTINUE;
	}
	
//------| Cur Weapon |------//
public event_cur_weapon(id) {
	if(get_pcvar_num(furienshop) != 0) {
	if(g_hasSilentWalk[id] && !get_user_footsteps(id)) {
	set_user_footsteps(id,1);
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	SavePoints(id);
	}
	}
	}
	
//---| Round Start |---//
public RoundStart(id) {
	if(get_pcvar_num(furienshop) != 0) {
	if(g_hasSilentWalk[id] && !get_user_footsteps(id)) {
	set_user_footsteps(id,1);
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	SavePoints(id);
	}
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life Stock |
//==========================================================================================================
//------| Spawn Players |------//
public spawnagain(id) {
	new lcost;
	if(get_pcvar_num(furienshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_lifecost);	
	}
	else {
	lcost = get_pcvar_num(lifecost);	 
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_points_lifecost);	
	}
	else {
	lcost = get_pcvar_num(points_lifecost);	 
	}
	}
	if(get_pcvar_num(furienshopmod) == 0) {
	if(roundend) {
	cs_set_user_money(id, cs_get_user_money(id) + lcost);
	ColorChat(id, "^x03%s^x04 Nu poti^x03 Renvia^x04.Jocul sa terminat.",Prefix);
	ColorChat(id, "^x03%s^x04 Ai primit bani inapoi.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	}
	else if(is_user_alive(id)) {
	cs_set_user_money(id, cs_get_user_money(id) + lcost);
	ColorChat(id, "^x03%s^x04 Esti deja viu, ai primit bani inapoi.",Prefix);	
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	}
	else if(!is_user_alive(id)) {
	cs_set_user_team(id, CS_TEAM_CT);
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	emit_sound(id,CHAN_ITEM,LIFE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	ColorChat(id, "^x03%s^x04 Ai Renviat cu succes.",Prefix);
	give_item(id, "weapon_knife");
	give_item(id, "weapon_usp");
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	Screen3(id);
	}
	}
	if(get_pcvar_num(furienshopmod) != 0) {
	if(roundend) {
	PlayerPoints[id] += lcost;
	ColorChat(id, "^x03%s^x04 Nu poti^x03 Renvia^x04.Jocul sa terminat.",Prefix);
	ColorChat(id, "^x03%s^x04 Ai primit Punctele inapoi.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	}
	else if(is_user_alive(id)) {
	PlayerPoints[id] += lcost;
	ColorChat(id, "^x03%s^x04 Esti deja viu, ai primit Punctele inapoi.",Prefix);	
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	}
	else if(!is_user_alive(id)) {
	cs_set_user_team(id, CS_TEAM_CT);
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	emit_sound(id,CHAN_ITEM,LIFE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_knife");
	give_item(id, "weapon_usp");
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	Screen3(id);
	}
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NoClip Stock |
//==========================================================================================================
//------| Remove NoClip |------//
public removeNoClip(id) {
	new nctime = get_pcvar_num(nocliptime);
	set_user_noclip(id,0);
	emit_sound(id,CHAN_ITEM,NOCLIP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	ColorChat(id, "^x03%s^x04 Au trecut cele^x03 %d^x04 secunde, nu mai ai ^x03NoClip^x04.", Prefix, nctime);
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// JetPack Stock |
//==========================================================================================================
//------| Remove JetPack |------//
public removeJetpack(id) {
	new jptime = get_pcvar_num(jetpacktime);
	has_jp[id] = false;
	emit_sound(id,CHAN_ITEM,JP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	ColorChat(id, "^x03%s^x04 Au trecut cele^x03 %d^x04 secunde, nu mai ai ^x03Jetpack^x04.", Prefix, jptime);
	}
	
//------| JetPack Stock |------//
public client_PreThink(id) {
	if(!is_user_connected(id) || !is_user_alive(id)) {
	return PLUGIN_CONTINUE;
	}
	if(!(get_user_button(id) & IN_JUMP)) {
	return PLUGIN_CONTINUE;
	}
	if(!has_started || !has_jp[id]) {
	return PLUGIN_CONTINUE;
	}
	new Float:fAim[3] , Float:fVelocity[3];
	VelocityByAim(id , get_pcvar_num(jetpackspeed) , fAim);

	fVelocity[0] = fAim[0];
	fVelocity[1] = fAim[1];
	fVelocity[2] = fAim[2];

	set_user_velocity(id , fVelocity);

	entity_set_int(id , EV_INT_gaitsequence , 6);
	emit_sound(id,CHAN_VOICE,JP2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	if(frame[id] >= 3) {
	frame[id] = 0;
	if(get_pcvar_num(jetpacktrail)) {
	smoke_effect(id);
	}
	}
	frame[id]++;

	return PLUGIN_CONTINUE;
	}

//------| Smoke Effect |------//
public smoke_effect(id) {
	new origin[3];
	get_user_origin(id, origin, 0);
	origin[2] = origin[2] - 10;

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(17);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short((get_pcvar_num(jetpacktrail) == 1) ? smoke : flame);
	write_byte(10);
	write_byte(115);
	message_end();
	}
public mmm_touchy(jp , id) {
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	if(has_jp[id]) return PLUGIN_CONTINUE;

	has_jp[id] = true;

	remove_entity(jp);

	return PLUGIN_CONTINUE;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP Online/List | VIP ScoreBoard
//==========================================================================================================
public print_adminlist(user) {
	new adminnames[33][32];
	new message[256];
	new id, count, x, len;
	
	for(id = 1 ; id <= get_maxplayers() ; id++)
	if(is_user_connected(id))
	if(get_user_flags(id) & VIP_LEVEL)
	get_user_name(id, adminnames[count++], 31);

	len = format(message, 255, "%s VIP ONLINE: ",COLOR);
	if(count > 0) {
	for(x = 0 ; x < count ; x++) {
	len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"");
	if(len > 96) {
	print_message(user, message);
	len = format(message, 255, "%s ",COLOR);
	}
	}
	print_message(user, message);
	}
	else {
	len += format(message[len], 255-len, "No VIP online.");
	print_message(user, message);
	}
	}
print_message(id, msg[]) {
	message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id);
	write_byte(id);
	write_string(msg);
	message_end();
	}
public handle_say(id) {
	new said[192];
	read_args(said,192);
	if(contain(said, "/vips") != -1)
	set_task(0.1,"print_adminlist",id);
	return PLUGIN_CONTINUE;
	}
public vip_scoreboard(const MsgId, const MsgType, const MsgDest) {
	static id;
	id = get_msg_arg_int(1);
	if(get_user_flags(id) & VIP_LEVEL)
	set_msg_arg_int(2, ARG_BYTE, (1 << 2 ));
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Points |
//==========================================================================================================
//------| Save Points |------//
stock SavePoints(id) {
	new SteamID[32];
	new Name[32];
	new Key[64];
	new Data[64];
	new Vault, Vault2;
	Vault = nvault_open("FrShopPoints-Name");

	if(Vault == INVALID_HANDLE) {
	set_fail_state("[FrShop] nValut ERROR: =-> Invalid-Handle");
	}
	Vault2 = nvault_open("FrShopPoints-SteamID");
	if(Vault2 == INVALID_HANDLE) {
	set_fail_state("[FrShop] nValut ERROR: =-> Invalid-Handle");
	}
	//------| Save Whith SteamID |------//
	get_user_authid(id, SteamID, charsmax(SteamID));
	if(get_pcvar_num(fr_save_points) == 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", SteamID);
	formatex(Data, charsmax(Data), "%d", PlayerPoints[id]);
	nvault_set(Vault2, Key,Data);
	nvault_close(Vault2 );
	}
	//------| Save Whith Name |------//
	get_user_name(id, Name, 31);
	if(get_pcvar_num(fr_save_points) != 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", Name);
	formatex(Data, charsmax(Data), "%d", PlayerPoints[id]);
	nvault_set(Vault, Key, Data);
	nvault_close(Vault);
	}
	}

	
//------| Loading Points |------//
stock LoadPoints(id) {
	new SteamID[32];
	new Name[32];
	new Key[64];
	new Vault, Vault2;
	Vault = nvault_open("FrShopPoints-Name");
	Vault2 = nvault_open("FrShopPoints-SteamID");
	if(Vault == INVALID_HANDLE) {
	set_fail_state("[FrShop] nValut ERROR: =-> Invalid-Handle");
	}
	if(Vault2 == INVALID_HANDLE) {
	set_fail_state("[FrShop] nValut ERROR: =-> Invalid-Handle");
	}
	//------| Load Whith SteamID |------//
	get_user_authid(id, SteamID, charsmax(SteamID));
	if(get_pcvar_num(fr_save_points) == 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", Name);
	PlayerPoints[id] = nvault_get(Vault2, Key);
	nvault_close(Vault2);
	}
	//------| Load Whith Name |------//
	get_user_name (id, Name, 31);
	if(get_pcvar_num(fr_save_points) != 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", Name);
	PlayerPoints[id] = nvault_get(Vault, Key);
	nvault_close(Vault);
	}
	}

//------| Show Points |------//
public ShowPoints(id) {
	set_hudmessage(0, 128, 0, 0.03, 0.86, 2, 6.0, 5.0);
	show_hudmessage(id, "Ai %d puncte.", PlayerPoints[id]);
	ColorChat(id, "^x03%s^x04 Ai^x03 %d^x04 puncte.", Prefix, PlayerPoints[id]);
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ColorChat && Color Screen to buy item |
//==========================================================================================================
stock ColorChat(const id, const input[], any:...) {
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
 
	replace_all(msg, 190, "^x04", "^4");
	replace_all(msg, 190, "^x01", "^1");
	replace_all(msg, 190, "^x03", "^3");
 
	if(id) players[0] = id;
	else get_players(players, count, "ch"); {
	for(new i = 0; i < count; i++) {
	if(is_user_connected(players[i])) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
	write_byte(players[i]);
	write_string(msg);
	message_end();
	}
	}
	} 
	}
	
public Screen1(id) {
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(0);
	write_byte(255);
	write_byte(0);
	write_byte(150);
	message_end();
	}
public Screen2(id) {
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(230);
	write_byte(0);
	write_byte(0);
	write_byte(150);
	message_end();
	}
public Screen3(id) {
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(0);
	write_byte(0);
	write_byte(255);
	write_byte(150);
	message_end();
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Plugin Precache |
//==========================================================================================================
//------| Parecache Sounds and Models |------//
public plugin_precache() {
	smoke = precache_model("sprites/FrShop/Jetpack1.spr");
	flame = precache_model("sprites/FrShop/Jetpack2.spr");
	precache_model("models/rpgrocket.mdl");
	precache_sound(BUY_SND);
	precache_sound(SELL_SND);
	precache_sound(ERROR_SND);
	precache_sound(ERROR2_SND);
	precache_sound(HP_SND);
	precache_sound(NOCLIP_SND);
	precache_sound(JP_SND);
	precache_sound(JP2_SND);
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------| End Plugin |-----------------------------------------------------
//=========================================================================================================
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
