////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------| Deathrun Shop |----------------------------------------------------
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
//--| NightVision |--//
#define OFFSET_NVGOGGLES 129
#define LINUX_OFFSET_DIFF 5
#define HAS_NVGS (1<<0)
#define USES_NVGS (1<<8)
#define get_user_nvg(%1)    	(get_pdata_int(%1,OFFSET_NVGOGGLES) & HAS_NVGS)
//--| Sounds |--//
#define BUY_SND			"DrShop/Buy.wav"
#define SELL_SND		"DrShop/Sell.wav"
#define ERROR_SND		"DrShop/Error.wav"
#define ERROR2_SND		"DrShop/Error.wav"
#define PARACHUTE_SND		"DrShop/Parachute.wav"
#define LJ_SND			"DrShop/LongJump.wav"
#define LIFE_SND		"DrShop/Life.wav"
#define HP_SND			"DrShop/Health.wav"
#define AP_SND			"DrShop/Armor.wav"
#define GRAVTIY_SND		"DrShop/Gravity.wav"
#define SPEED_SND		"DrShop/Speed.wav"
#define NOCLIP_SND		"DrShop/NoClip.wav"
#define NVG_SND			"DrShop/NightVision.wav"
#define SHIELD_SND		"DrShop/Shield.wav"
#define JP_SND			"DrShop/Jetpack.wav"
#define JP2_SND			"DrShop/Jetpack2.wav"
#define HOOK_FIRE		"DrShop/HookFire.wav"
#define HOOK_HIT		"DrShop/HookHit.wav"
#define INVIS_SND		"DrShop/Invizibility.wav"
#define GODMODE_SND		"DrShop/GodMode.wav"
#define GLOW_SND		"DrShop/Glow.wav"
//--| Acces Level to VIP/Admin |--//
#define VIP_LEVEL		ADMIN_LEVEL_H
#define ADMIN_LEVEL		ADMIN_LEVEL_H

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// New Plugin |
//==========================================================================================================
//------| MENU |------//
new menu;
//------| HOOK |------//
new hook_to[33][3], hooksprite, bool:hookenable[33];
//------| JETPACK/Parachute |------//
new flame, smoke, maxplayers, bool:has_started, frame[33], para_ent[33];
new bool:roundend;
//------| Weapon/Message |------//
new szClip, szAmmo, Mesaj;
//------| HAHE Items..etc. |------//
new bool:has_parachute[33], g_hasLongJump[33], g_hasGravity[33], hasGravity[33], hasSpeed[33],
g_hasSpeed[33], g_hasInvizibility[33], g_hasNightVision[33], g_hasSilentWalk[33],g_hasZoom[33],
hasZoom[33], g_hasHook[33],bool:has_jp[33];
//------| Parachute Model |------//
new const parachute_model[] = "models/DrShop/parachute.mdl";
//------| Deagle Models |------//
new DEAGLE_MODEL_V[64] = "models/DrShop/v_deagle.mdl";
new DEAGLE_MODEL_P[64] = "models/DrShop/p_deagle.mdl";
new DEAGLE_SHIELD_V[64] = "models/DrShop/v_shield_deagle.mdl";
new DEAGLE_SHIELD_P[64] = "models/DrShop/p_shield_deagle.mdl";
//------| Prefix to message |------//
new const Prefix[] = "[DrShop]";
//------| Color to display vip online |------//
static const COLOR[] = "^x04"; // Green for display VIP
//--| Points Cvar |--//
new PlayerPoints[33], dr_save_points;
//--| Cvars Activate | Dezactivate |--//
new deathrunshop, deathrunshopmod, vip, parachute, longjump, life, grenades, health, armor, gravity, speed,
deagle, noclip, nightvision, silentwalk, shield, jetpack, hook, invizibility, godmode, glow, icon_lj;
//--| Acces Items |--//
new acces_parachute, acces_longjump, acces_life, acces_grenades, acces_healtharmor, acces_deagle,
acces_gravityspeed, acces_shield, acces_invizibility, acces_noclip, acces_godmode, acces_jetpack,
acces_nightvision, acces_hook, acces_silentwalk, acces_glow;
//--| Cvars Set`s |--//
new parachutespeed, maxhealth, maxarmor, lowgravity, highspeed, deaglemodel, deaglezoom, deaglezoomstyle, nocliptime,
jetpacktime, jetpackspeed, jetpacktrail, hookspeed, hookamount, invislevel, invisknifelevel, godmodetime;
//--| Cvars Give Money/Points to Kill |--//
new dr_points_kill, dr_points_hs, dr_points_knife, dr_points_he, dr_money_kill, dr_money_hs, dr_money_knife, dr_money_he;
//--------------| Money Cvars |--------------//
//--| Cvars Buy Cost |--//
new parachutecost, longjumpcost, lifecost, hegrenadecost, flashbangcost, smokegrenadecost, healthcost, armorcost,
gravitycost, speedcost, dglcost, deagleammocost, noclipcost, nightvisioncost, silentwalkcost, shieldcost, jetpackcost,
hookcost, invizibilitycost, godmodecost, glowcost;
//--| Cvars Sell Cost |--//
new sellparachute, selllongjump, sellnightvision, sellsilentwalk;
//--| Cvars Vip Buy Cost |--//
new vip_parachutecost, vip_longjumpcost, vip_lifecost, vip_hegrenadecost, vip_flashbangcost, vip_smokegrenadecost,
vip_healthcost, vip_armorcost, vip_gravitycost, vip_speedcost, vip_dglcost, vip_deagleammocost, vip_noclipcost,
vip_nightvisioncost, vip_silentwalkcost, vip_shieldcost, vip_jetpackcost, vip_hookcost, vip_invizibilitycost,
vip_godmodecost, vip_glowcost;
//--| Cvars Vip Sell Cost |--//
new vip_sellparachute, vip_selllongjump, vip_sellnightvision, vip_sellsilentwalk;
//--------------| Points Cvars |--------------//
//--| Cvars Buy Cost |--//
new points_parachutecost, points_longjumpcost, points_lifecost, points_hegrenadecost, points_flashbangcost,
points_smokegrenadecost, points_healthcost, points_armorcost, points_gravitycost, points_speedcost, points_dglcost,
points_deagleammocost, points_noclipcost, points_nightvisioncost, points_silentwalkcost, points_shieldcost,
points_jetpackcost, points_hookcost, points_invizibilitycost, points_godmodecost, points_glowcost;
//--| Cvars Sell Cost |--//
new points_sellparachute, points_selllongjump, points_sellnightvision, points_sellsilentwalk;
//--| Cvars Vip Buy Cost |--//
new vip_points_parachutecost, vip_points_longjumpcost, vip_points_lifecost, vip_points_hegrenadecost,
vip_points_flashbangcost, vip_points_smokegrenadecost, vip_points_healthcost, vip_points_armorcost,
vip_points_gravitycost, vip_points_speedcost, vip_points_dglcost, vip_points_deagleammocost, vip_points_noclipcost,
vip_points_nightvisioncost, vip_points_silentwalkcost, vip_points_shieldcost, vip_points_jetpackcost,
vip_points_hookcost, vip_points_invizibilitycost, vip_points_godmodecost, vip_points_glowcost;
//--| Cvars Vip Sell Cost |--//
new vip_points_sellparachute, vip_points_selllongjump, vip_points_sellnightvision, vip_points_sellsilentwalk;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Plugin Init |
//==========================================================================================================
public plugin_init() {
	register_plugin("DrShop", "1.2", "Aragon*");
	register_clcmd("shop","cmdShop");
	register_clcmd("drshop","cmdShop");
	register_clcmd("say /shop","cmdShop");
	register_clcmd("say /drshop","cmdShop");
	register_clcmd("say_team /shop","cmdShop");
	register_clcmd("say_team /drshop","cmdShop");
	register_clcmd("say shop","cmdShop");
	register_clcmd("say drshop","cmdShop");
	register_clcmd("say_team shop","cmdShop");
	register_clcmd("say_team drshop","cmdShop");
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
	maxplayers = get_maxplayers();
	Mesaj = register_cvar("dr_hudmessage_delay", "420");		//| Time interval to display the message |//
//------| Enable/Disable |------//
	deathrunshop = register_cvar("dr_shop_enabled", "1");		//| Plugin 0 Disable -> 1 Enable |//
	deathrunshopmod = register_cvar("dr_shop_mode", "0");		//| Money/Points 0 Money Tax -> 1 Points Tax |//
	vip = register_cvar("dr_vip_enabled", "1");			//| VIP 0 Disable -> 1 Enable |//
	dr_save_points = register_cvar("dr_save_points", "1");		//| 0 --> Save whith SteamId 1 --> Save whith Name |//
	parachute = register_cvar("dr_parachute", "1");			//| Parachute 0 Disable -> 1 Enable |//
	longjump = register_cvar("dr_longjump", "1");			//| LongJump 0 Disable -> 1 Enable |//
	life = register_cvar("dr_life", "1");				//| Life 0 Disable -> 1 Enable |//
	grenades = register_cvar("dr_grenades", "1");			//| Grenades 0 Disable -> 1 Enable |//
	health = register_cvar("dr_health", "1");			//| Health 0 Disable -> 1 Enable |//
	armor = register_cvar("dr_armor", "1");				//| Armor 0 Disable -> 1 Enable |//
	gravity = register_cvar("dr_gravity", "1");			//| Gravity 0 Disable -> 1 Enable |//
	speed = register_cvar("dr_speed", "1");				//| Speed 0 Disable -> 1 Enable |//
	deagle = register_cvar("dr_deagle", "1");			//| Deagle 0 Disable -> 1 Enable |//
	noclip = register_cvar("dr_noclip", "1");			//| NoClip 0 Disable -> 1 Enable |//
	nightvision = register_cvar("dr_nightvision", "1");		//| NightVision 0 Disable -> 1 Enable |//
	silentwalk = register_cvar("dr_silentwalk", "1");		//| SilentWalk 0 Disable -> 1 Enable |//
	shield = register_cvar("dr_shield", "1");			//| Shield 0 Disable -> 1 Enable |//
	jetpack = register_cvar("dr_jetpack", "1");			//| Jetpack 0 Disable -> 1 Enable |//
	hook = register_cvar("dr_hook", "1");				//| Hook 0 Disable -> 1 Enable |//
	invizibility = register_cvar("dr_invizibility", "1");		//| Invizibility 0 Disable -> 1 Enable |//
	godmode = register_cvar("dr_godmode", "1");			//| GodMode 0 Disable -> 1 Enable |//
	glow = register_cvar("dr_glow", "1");				//| Glow 0 Disable -> 1 Enable |//
	deaglemodel = register_cvar("dr_deagle_model", "1");		//| Model to Deagle 0 Disable -> 1 Enable |//
	deaglezoom = register_cvar("dr_deagle_zoom", "1");		//| Zoom to Deagle 0 Disable -> 1 Enable |//
	icon_lj = register_cvar("dr_icon lj", "1");			//| Icon to LongJump 0 Disable -> 1 Enable |//
	
//------| Only for T/Ct or All |------//
	acces_parachute = register_cvar("dr_acces_parachute", "3");	 //| Parachute Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_longjump = register_cvar("dr_acces_longjump", "3");	 //| LongJump Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_life = register_cvar("dr_acces_life", "3");		 //| Life Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_grenades = register_cvar("dr_acces_grenades", "3");	 //| Grenades Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_healtharmor = register_cvar("dr_acces_hp_ap", "3");	 //| Health and Armor Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_gravityspeed = register_cvar("dr_acces_gravity_speed","3");//| Gravity and Speed Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_deagle = register_cvar("dr_acces_deagle", "3");		 //| Deagle Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_noclip = register_cvar("dr_acces_noclip", "3");		 //| NoClip Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_nightvision = register_cvar("dr_acces_nightvision", "3");	 //| NightVision Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_silentwalk = register_cvar("dr_acces_silentwalk", "3");	 //| SilentWalk Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_shield = register_cvar("dr_acces_shield", "2");		 //| Shield Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_jetpack = register_cvar("dr_acces_jetpack", "3");		 //| Jetpack Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_hook = register_cvar("dr_acces_hook", "1");		 //| Hook Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_invizibility = register_cvar("dr_acces_invis", "2");	 //| Invizibility Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_godmode = register_cvar("dr_acces_godmode", "2");		 //| GodMode Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//
	acces_glow = register_cvar("dr_acces_glow", "1");		 //| Glow Only for 0 Admin -> 1 Cts -> 2 Ts -> 3 All |//

//------| Set Items |------//
	parachutespeed = register_cvar("dr_parachute_speed", "75");	//| Parachute Speed |//
	maxhealth = register_cvar("dr_max_health","200");		//| Max Health |//
	maxarmor = register_cvar("dr_max_armor","200");			//| Max Armor |//
	lowgravity = register_cvar("dr_gravity_power","0.4");		//| Low Gravity 0.4 is "sv_gravity 400" |//
	highspeed = register_cvar("dr_speed_power", "400");		//| High Speed |//
	deaglezoomstyle = register_cvar("dr_deagle_zoom_style", "1");	//| 0 -> Zoom AWP 1 -> Zoom AUG/SG552 |//
	nocliptime = register_cvar("dr_noclip_time", "3.0");		//| Duration NoClip in Seconds |//
	jetpacktime = register_cvar("dr_jetpack_time", "5.0");		//| Duration Jetpack in Seconds |//
	jetpackspeed = register_cvar("dr_jetpack_speed", "500");		//| Speed to Jetpack |//
	jetpacktrail = register_cvar("dr_jetpack_trail", "2");		//| 0 None -> 1 Smoke -> 2 Flame |//
	hookspeed = register_cvar("dr_hook_speed", "600");		//| Speed to Hook |//
	hookamount = register_cvar("dr_hook_amount", "2");		//| Amount Hook to buy |//
	invislevel = register_cvar("dr_invis_level","40");		//| 0 Total Invizibility -> 255 Total Vizibility |//
	invisknifelevel = register_cvar("dr_invis_knife_level","10");	//| 0 Total Invizibility -> 255 Total Vizibility white Knife |//
	godmodetime = register_cvar("dr_godmode_time", "4.0");		//| Duration Godmoed in Seconds |//
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MONEY |
//==========================================================================================================
//------| Money Bonus+ |------//
	dr_money_kill = register_cvar("dr_points_kill", "300");		//| + Money to kill |//
	dr_money_hs = register_cvar("dr_points_hs", "500");		//| + Money to kill with HeadShot |//
	dr_money_knife = register_cvar("dr_points_knife", "1000");	//| + Money to kill with knife |//
	dr_money_he = register_cvar("dr_points_he", "1500");		//| + Money to kill whit Grenade |//
	
//------| Buy Cost- |------//
	parachutecost = register_cvar("dr_parachute_cost", "100");	//| Parachute Cost in Money 0 -> 16000 |//
	longjumpcost = register_cvar("dr_longjump_cost", "3000");	//| LongJump Cost in Money 0 -> 16000 |//
	lifecost = register_cvar("dr_life_cost", "10000");		//| Life Cost in Money 0 -> 16000 |//
	hegrenadecost = register_cvar("dr_he_cost", "2000");		//| HE Cost in Money 0 -> 16000 |//
	flashbangcost = register_cvar("dr_flash_cost", "1000");		//| Flash Cost in Money 0 -> 16000 |//
	smokegrenadecost = register_cvar("dr_smoke_cost", "1000");	//| Smoke Cost in Money 0 -> 16000 |//
	healthcost = register_cvar("dr_health_cost", "40");		//| Health Cost in Money 0 -> 16000 |//
	armorcost = register_cvar("dr_armor_cost", "20");		//| Armor Cost in Money 0 -> 16000 |//
	gravitycost = register_cvar("dr_gravity_cost", "6000");		//| Gravity Cost in Money 0 -> 16000 |//
	speedcost = register_cvar("dr_speed_cost", "6000");		//| Speed Cost in Money 0 -> 16000 |//
	dglcost = register_cvar("dr_deagle_cost", "10000");		//| Deagle Cost in Money 0 -> 16000 |//
	deagleammocost = register_cvar("dr_deagleammo_cost","6000");	//| Ammo Deagle Cost in Money 0 -> 16000 |//
	noclipcost = register_cvar("dr_noclip_cost", "16000");		//| NoClip Cost in Money 0 -> 16000 |//
	nightvisioncost = register_cvar("dr_nightvision_cost", "500");	//| NoClip Cost in Money 0 -> 16000 |//
	silentwalkcost = register_cvar("dr_silentwalk_cost", "500");	//| SilentWalk Cost in Money 0 -> 16000 |//
	shieldcost = register_cvar("dr_shield_cost", "100");		//| Shield Cost in Money 0 -> 16000 |//
	jetpackcost = register_cvar("dr_jetpack_cost", "5000");		//| Jetpack Cost in Money 0 -> 16000 |//
	hookcost = register_cvar("dr_hook_cost", "6000");		//| Hook Cost in Money 0 -> 16000 |//
	invizibilitycost = register_cvar("dr_invis_cost", "6000");	//| Invizibility Cost in Money 0 -> 16000 |//
	godmodecost = register_cvar("dr_godmode_cost", "8000");		//| GodMode Cost in Money 0 -> 16000 |//
	glowcost = register_cvar("dr_glow_cost", "0");			//| Glow Cost in Money 0 -> 16000 |//
	
//------| Sell Cost+ |------//
	sellparachute = register_cvar("dr_sell_parachute", "50");	//| Parachute Sell Bonus in Money 0 -> 16000 |//
	selllongjump = register_cvar("dr_sell_longjump", "2000");	//| LongJump Sell Bonus in Money 0 -> 16000 |//
	sellnightvision = register_cvar("dr_sell_nightvision", "250");	//| NightVision Sell Bonus in Money 0 -> 16000 |//
	sellsilentwalk = register_cvar("dr_sell_silentwalk", "250");	//| SilentWalk Sell Bonus in Money 0 -> 16000 |//

//------| Vip Buy Cost- |------//
	vip_parachutecost = register_cvar("vip_parachute_cost", "0");		//| Parachute Cost in Money to VIP 0 -> 16000 |//
	vip_longjumpcost = register_cvar("vip_longjump_cost", "2000");		//| LongJump Cost in Money to VIP 0 -> 16000 |//
	vip_lifecost = register_cvar("vip_life_cost", "6000");			//| Life Cost in Money to VIP 0 -> 16000 |//
	vip_hegrenadecost = register_cvar("vip_he_cost", "1000");		//| HE Cost in Money to VIP 0 -> 16000 |//
	vip_flashbangcost = register_cvar("vip_flash_cost", "500");		//| Flash Cost in Money to VIP 0 -> 16000 |//
	vip_smokegrenadecost = register_cvar("vip_smoke_cost", "500");		//| Smoke Cost in Money to VIP 0 -> 16000 |//
	vip_healthcost = register_cvar("vip_health_cost", "30");			//| Health Cost in Money to VIP 0 -> 16000 |//
	vip_armorcost = register_cvar("vip_armor_cost", "10");			//| Armor Cost in Money to VIP 0 -> 16000 |//
	vip_gravitycost = register_cvar("vip_gravity_cost", "3000");		//| Gravity Cost in Money to VIP 0 -> 16000 |//
	vip_speedcost = register_cvar("vip_speed_cost", "3000");			//| Speed Cost in Money to VIP 0 -> 16000 |//
	vip_dglcost = register_cvar("vip_deagle_cost", "7000");			//| Deagle Cost in Money to VIP 0 -> 16000 |//
	vip_deagleammocost = register_cvar("vip_deagleammo_cost","4000");	//| Ammo Deagle Cost in Money to VIP 0 -> 16000 |//
	vip_noclipcost = register_cvar("vip_noclip_cost", "10000");		//| NoClip Cost in Money to VIP 0 -> 16000 |//
	vip_nightvisioncost = register_cvar("vip_nightvision_cost", "100");	//| NightVision Cost in Money to VIP 0 -> 16000 |//
	vip_silentwalkcost = register_cvar("vip_silentwalk_cost", "100");	//| SilentWalk Cost in Money to VIP 0 -> 16000 |//
	vip_shieldcost = register_cvar("vip_shield_cost", "0");			//| Shield Cost in Money to VIP 0 -> 16000 |//
	vip_jetpackcost = register_cvar("vip_jetpack_cost", "3000");		//| Jetpack Cost in Money to VIP 0 -> 16000 |//
	vip_hookcost = register_cvar("vip_hook_cost", "4000");			//| Hook Cost in Money to VIP 0 -> 16000 |//
	vip_invizibilitycost = register_cvar("vip_invis_cost", "4000");		//| Invizibility Cost in Money to VIP 0 -> 16000 |//
	vip_godmodecost = register_cvar("vip_godmode_cost", "6000");		//| GodMode Cost in Money to VIP 0 -> 16000 |//
	vip_glowcost = register_cvar("vip_glow_cost", "0");			//| Glow Cost in Money to VIP 0 -> 16000 |//

//------| Vip Sell Cost+ |------//
	vip_sellparachute = register_cvar("vip_sell_parachute", "0");		//| Parachute Sell Bonus in Money to VIP 0 -> 16000 |//
	vip_selllongjump = register_cvar("vip_sell_longjump", "1000");		//| LongJump Sell Bonus in Money to VIP 0 -> 16000 |//
	vip_sellnightvision = register_cvar("vip_sell_nightvision", "50");	//| NightVision Sell Bonus in Money to VIP 0 -> 16000 |//
	vip_sellsilentwalk = register_cvar("vip_sell_silentwalk", "50");		//| SilentWalk Sell Bonus in Money to VIP 0 -> 16000 |//
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// POINTS |
//==========================================================================================================
//------| Points Bonus+ |------//
	dr_points_kill = register_cvar("dr_points_kill", "3");		//| + Points to kill |//
	dr_points_hs = register_cvar("dr_points_hs", "5");		//| + Points to kill with HeadShot |//
	dr_points_knife = register_cvar("dr_points_knife", "10");	//| + Points to kill with knife |//
	dr_points_he = register_cvar("dr_points_he", "15");		//| + Points to kill whit Grenade |//

//------| Buy Cost- |------//
	points_parachutecost = register_cvar("dr_parachute_points", "5");	//| Parachute Cost in Points |//
	points_longjumpcost = register_cvar("dr_longjump_points", "10");		//| LongJump Cost in Points |//
	points_lifecost = register_cvar("dr_life_points", "25");			//| Life Cost in Points |//
	points_hegrenadecost = register_cvar("dr_he_points", "3");		//| HE Cost in Points |//
	points_flashbangcost = register_cvar("dr_flash_points", "2");		//| Flash Cost in Points |//
	points_smokegrenadecost = register_cvar("dr_smoke_points", "2");		//| Smoke Cost in Points |//
	points_healthcost = register_cvar("dr_health_points", "25");		//| Health Cost in Points |//
	points_armorcost = register_cvar("dr_armor_points", "15");		//| Armor Cost in Points |//
	points_gravitycost = register_cvar("dr_gravity_points", "15");		//| Gravity Cost in Points |//
	points_speedcost = register_cvar("dr_speed_points", "15");		//| Speed Cost in Points |//
	points_dglcost = register_cvar("dr_deagle_points", "25");		//| Deagle Cost in Points |//
	points_deagleammocost = register_cvar("dr_deagleammo_points","20");	//| Ammo Deagle Cost in Points |//
	points_noclipcost = register_cvar("dr_noclip_points", "40");		//| NoClip Cost in Points |//
	points_nightvisioncost = register_cvar("dr_nightvision_points", "5");	//| NightVision Cost in Points |//
	points_silentwalkcost = register_cvar("dr_silentwalk_points", "5");	//| SilentWalk Cost in Points |//
	points_shieldcost = register_cvar("dr_shield_points", "5");		//| Shield Cost in Points |//
	points_jetpackcost = register_cvar("dr_jetpack_points", "15");		//| Jetpack Cost in Points |//
	points_hookcost = register_cvar("dr_hook_points", "20");			//| Hook Cost in Points |//
	points_invizibilitycost = register_cvar("dr_invis_pointst", "20");	//| Invizibility Cost in Points |//
	points_godmodecost = register_cvar("dr_godmode_points", "25");		//| GodMode Cost in Points |//
	points_glowcost = register_cvar("dr_glow_points", "0");			//| Glow Cost in Points |//
	
//------| Sell Cost+ |------//
	points_sellparachute = register_cvar("dr_sell_parachute_points", "3");		//| Parachute Sell Bonus in Points |//
	points_selllongjump = register_cvar("dr_sell_longjump_points", "5");		//| LongJump Sell Bonus in Points |//
	points_sellnightvision = register_cvar("dr_sell_nightvision_points", "3");	//| NightVision Sell Bonus in Points |//
	points_sellsilentwalk = register_cvar("dr_sell_silentwalk_points", "3");		//| SilentWalk Sell Bonus in Points |//

//------| Vip Buy Cost- |------//
	vip_points_parachutecost = register_cvar("vip_parachute_points", "0");		//| Parachute Cost VIP in Points |//
	vip_points_longjumpcost = register_cvar("vip_longjump_points", "5");		//| LongJump Cost VIP in Points |//
	vip_points_lifecost = register_cvar("vip_life_points", "15");			//| Life Cost VIP in Points |//
	vip_points_hegrenadecost = register_cvar("vip_he_points", "2");		//| He Cost VIP in Points |//
	vip_points_flashbangcost = register_cvar("vip_flash_points", "1");		//| Flash Cost VIP in Points |//
	vip_points_smokegrenadecost = register_cvar("vip_smoke_points", "1");		//| Smoke Cost VIP in Points |//
	vip_points_healthcost = register_cvar("vip_health_points", "15");		//| Health Cost VIP in Points |//
	vip_points_armorcost = register_cvar("vip_armor_points", "10");			//| Armor Cost VIP in Points |//
	vip_points_gravitycost = register_cvar("vip_gravity_points", "10");		//| Gravity Cost VIP in Points |//
	vip_points_speedcost = register_cvar("vip_speed_points", "10");			//| Speed Cost VIP in Points |//
	vip_points_dglcost = register_cvar("vip_deagle_points", "20");			//| Deagle Cost VIP in Points |//
	vip_points_deagleammocost = register_cvar("vip_deagleammo_points","15");	//| Ammo Deagle Cost VIP in Points |//
	vip_points_noclipcost = register_cvar("vip_noclip_points", "30");		//| NoClip Cost VIP in Points |//
	vip_points_nightvisioncost = register_cvar("vip_nightvision_points", "3");	//| NightVision Cost VIP in Points |//
	vip_points_silentwalkcost = register_cvar("vip_silentwalk_points", "3");		//| SilentWalk Cost VIP in Points |//
	vip_points_shieldcost = register_cvar("vip_shield_points", "0");			//| Shield Cost VIP in Points |//
	vip_points_jetpackcost = register_cvar("vip_jetpack_points", "10");		//| JetPack Cost VIP in Points |//
	vip_points_hookcost = register_cvar("vip_hook_points", "15");			//| Hook Cost VIP in Points |//
	vip_points_invizibilitycost = register_cvar("vip_invis_points", "15");		//| Invizibility Cost VIP in Points |//
	vip_points_godmodecost = register_cvar("vip_godmode_points", "20");		//| GodMode Cost VIP in Points |//
	vip_points_glowcost = register_cvar("vip_glow_points", "0");			//| Glow Cost VIP in Points |//

//------| Vip Sell Cost+ |------//
	vip_points_sellparachute = register_cvar("vip_sell_parachute_points", "0");	//| Parachute Bonus VIP in Points |//
	vip_points_selllongjump = register_cvar("vip_sell_longjump_points", "3");	//| LongJump Bonus VIP in Points |//
	vip_points_sellnightvision = register_cvar("vip_sell_nightvision_points", "1");	//| NightVision Bonus VIP in Points |//
	vip_points_sellsilentwalk = register_cvar("vip_sell_silentwalk_points", "1");	//| SilentWalk Bonus VIP in Points |//

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMMANDS CONSOLE/CHAT |
//==========================================================================================================
//------| Admin Give/Take Items |------//
	register_concmd("amx_give_money", "Give_Money", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> 0-10000");
	register_concmd("amx_give_points", "Give_Points", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> Amount");
	register_concmd("amx_reset_points", "Reset_Points", ADMIN_IMMUNITY, "Name/@T/@CT/@All -> Amount");
	register_concmd("amx_give_parachute", "give_parachute", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_parachute", "take_parachute", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_longjump", "give_longjump", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_lj", "give_longjump", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_longjump", "take_longjump", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_lj", "take_longjump", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_grenade", "give_grenade", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_grenades", "give_grenade", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_health", "give_health", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_hp", "give_health", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_armor", "give_armor", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_ap", "give_armor", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_deagle", "give_dgl", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_dgl", "give_dgl", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_gravity", "give_gravity", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_speed", "give_speed", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_noclip", "give_noclip", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_nc", "give_noclip", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_nightvision", "give_nvg", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_nvg", "give_nvg", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_nightvision", "take_nvg", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_nvg", "take_nvg", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_silentwalk", "give_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_sw", "give_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_silentwalk", "take_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_take_sw", "take_silentwalk", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_shield", "give_shield", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_jetpack", "give_jetpack", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_jp", "give_jetpack", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_hook", "give_hook", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_invizibility", "give_invizibility", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_inv", "give_invizibility", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_godmode", "give_godmode", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_gm", "give_godmode", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	register_concmd("amx_give_glow", "give_glow", ADMIN_IMMUNITY, "Name/@T/@CT/@All");
	
//------| Parachuet Commands |------//
	register_clcmd("buy_parachute", "buy_parachute");
	register_clcmd("parachute", "buy_parachute");
	register_clcmd("say buy_parachute", "buy_parachute");
	register_clcmd("say /parachute", "buy_parachute");
	register_clcmd("say /buy_parachute", "buy_parachute");
	register_clcmd("say_team buy_parachute", "buy_parachute");
	register_clcmd("say_team /parachute", "buy_parachute");
	register_clcmd("say_team /buy_parachute", "buy_parachute");
	register_clcmd("sell_parachute", "sell_parachute");
	register_clcmd("sellparachute", "sell_parachute");
	register_clcmd("say sell_parachute", "sell_parachute");
	register_clcmd("say sellparachute", "sell_parachute");
	register_clcmd("say /sell_parachute", "sell_parachute");
	register_clcmd("say /sellparachute", "sell_parachute");
	register_clcmd("say_team sell_parachute", "sell_parachute");
	register_clcmd("say_team sellparachute", "sell_parachute");
	register_clcmd("say_team /sell_parachute", "sell_parachute");
	register_clcmd("say_team /sellparachute", "sell_parachute");
	
//------| LongJump Commands |------//
	register_clcmd("buy_longjump", "buy_longjump");
	register_clcmd("buy_lj", "buy_longjump");
	register_clcmd("longjump", "buy_longjump");
	register_clcmd("lj", "buy_longjump");
	register_clcmd("say buy_longjump", "buy_longjump");
	register_clcmd("say buy_lj", "buy_longjump");
	register_clcmd("say /longjump", "buy_longjump");
	register_clcmd("say /lj", "buy_longjump");
	register_clcmd("say /buy_longjump", "buy_longjump");
	register_clcmd("say /buy_lj", "buy_longjump");
	register_clcmd("say_team buy_longjump", "buy_longjump");
	register_clcmd("say_team buy_lj", "buy_longjump");
	register_clcmd("say_team /longjump", "buy_longjump");
	register_clcmd("say_team /lj", "buy_longjump");
	register_clcmd("say_team /buy_longjump", "buy_longjump");
	register_clcmd("say_team /buy_lj", "buy_longjump");
	register_clcmd("sell_longjump", "sell_longjump");
	register_clcmd("sell_lj", "sell_longjump");
	register_clcmd("selllj", "sell_longjump");
	register_clcmd("selllongjump", "sell_longjump");
	register_clcmd("say sell_longjump", "sell_longjump");
	register_clcmd("say sell_lj", "sell_longjump");
	register_clcmd("say /selllj", "sell_longjump");
	register_clcmd("say /selllongjump", "sell_longjump");
	register_clcmd("say_team sell_longjump", "sell_longjump");
	register_clcmd("say_team sell_lj", "sell_longjump");
	register_clcmd("say_team /selllj", "sell_longjump");
	register_clcmd("say_team /selllongjump", "sell_longjump");
	
//------| Life Commands |------//
	register_clcmd("life", "buy_life");
	register_clcmd("buy_life", "buy_life");
	register_clcmd("say /life", "buy_life");
	register_clcmd("say buy_life", "buy_life");
	register_clcmd("say_team /life", "buy_life");
	register_clcmd("say_team buy_life", "buy_life");
	
//------| Grenades Commands |------//
	register_clcmd("buy_grenade", "buy_grenade");
	register_clcmd("grenade", "buy_grenade");
	register_clcmd("buy_grenades", "buy_grenade");
	register_clcmd("grenades", "buy_grenade");
	register_clcmd("say buy_grenade", "buy_grenade");
	register_clcmd("say /grenade", "buy_grenade");
	register_clcmd("say buy_grenades", "buy_grenade");
	register_clcmd("say /grenades", "buy_grenade");
	register_clcmd("say_team buy_grenade", "buy_grenade");
	register_clcmd("say_team /grenade", "buy_grenade");
	register_clcmd("say_team buy_grenades", "buy_grenade");
	register_clcmd("say_team /grenades", "buy_grenade");
	
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
	
//------| Armor Commands |------//
	register_clcmd("ap", "buy_armor");
	register_clcmd("armor", "buy_armor");
	register_clcmd("buy_ap", "buy_armor");
	register_clcmd("buy_armor", "buy_armor");
	register_clcmd("say /ap", "buy_armor");
	register_clcmd("say buy_ap", "buy_armor");
	register_clcmd("say /armor", "buy_armor");
	register_clcmd("say buy_armor", "buy_armor");
	register_clcmd("say_team /ap", "buy_armor");
	register_clcmd("say_team buy_ap", "buy_armor");
	register_clcmd("say_team /armor", "buy_armor");
	register_clcmd("say_team buy_armor", "buy_armor");
	
//------| Gravity Commands |------//
	register_clcmd("gravity", "buy_gravity");
	register_clcmd("buy_gravity", "buy_gravity");
	register_clcmd("say /gravity", "buy_gravity");
	register_clcmd("say buy_gravity", "buy_gravity");
	register_clcmd("say_team /gravity", "buy_gravity");
	register_clcmd("say_team buy_gravity", "buy_gravity");
	
//------| Speed Commands |------//
	register_clcmd("speed", "buy_speed");
	register_clcmd("buy_speed", "buy_speed");
	register_clcmd("say /speed", "buy_speed");
	register_clcmd("say buy_speed", "buy_speed");
	register_clcmd("say_team /speed", "buy_speed");
	register_clcmd("say_team buy_speed", "buy_speed");
	
//------| Deagle Commands |------//
	register_clcmd("dgl", "buy_superdeagle");
	register_clcmd("buy_deagle", "buy_superdeagle");
	register_clcmd("buy_dgl", "buy_superdeagle");
	register_clcmd("say /deagle", "buy_superdeagle");
	register_clcmd("say /dgl", "buy_superdeagle");
	register_clcmd("say buy_dgl", "buy_superdeagle");
	register_clcmd("say buy_deagle", "buy_superdeagle");
	register_clcmd("say_team /deagle", "buy_superdeagle");
	register_clcmd("say_team /dgl", "buy_superdeagle");
	register_clcmd("say_team buy_dgl", "buy_superdeagle");
	register_clcmd("say_team buy_deagle", "buy_superdeagle");
	
//------| Deagle AMMO Commands |------//
	register_clcmd("ammo", "buy_ammo");
	register_clcmd("buy_ammo", "buy_ammo");
	register_clcmd("say /ammo", "buy_ammo");
	register_clcmd("say buy_ammo", "buy_ammo");
	register_clcmd("say_team /ammo", "buy_ammo");
	register_clcmd("say_team buy_ammo", "buy_ammo");

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
	
//------| NightVision Commands |------//
	register_clcmd("nvg","buy_nightvision");
	register_clcmd("buy_nightvision","buy_nightvision");
	register_clcmd("buy_nvg","buy_nightvision");
	register_clcmd("say /nightvision","buy_nightvision");
	register_clcmd("say buy_nightvision","buy_nightvision");
	register_clcmd("say /nvg","buy_nightvision");
	register_clcmd("say buy_nvg","buy_nightvision");
	register_clcmd("say_team /nightvision","buy_nightvision");
	register_clcmd("say_teambuy_nightvision","buy_nightvision");
	register_clcmd("say_team /nvg","buy_nightvision");
	register_clcmd("say_team buy_nvg","buy_nightvision");
	register_clcmd("sell_nvg", "sell_nvg");
	register_clcmd("sell_nightvision", "sell_nvg");
	register_clcmd("say sell_nvg", "sell_nvg");
	register_clcmd("say sell_nightvision", "sell_nvg");
	register_clcmd("say /sellnvg", "sell_nvg");
	register_clcmd("say /sellnightvision", "sell_nvg");
	register_clcmd("say_team /sellnvg", "sell_nvg");
	register_clcmd("say_team /sellnightvision", "sell_nvg");
	register_clcmd("say_team sell_nvg", "sell_nvg");
	register_clcmd("say_team sell_nightvision", "sell_nvg");
	
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
	
//------| Hook Commands |------//
	register_clcmd("hook", "buy_hook");
	register_clcmd("buy_hook", "buy_hook");
	register_clcmd("say /hook", "buy_hook");
	register_clcmd("say buy_hook", "buy_hook");
	register_clcmd("say_team /hook", "buy_hook");
	register_clcmd("say_team buy_hook", "buy_hook");

//------| Shield Commands |------//
	register_clcmd("buy_shield", "buy_shield");
	register_clcmd("say /shield", "buy_shield");
	register_clcmd("say buy_shield", "buy_shield");
	register_clcmd("say_team /shield", "buy_shield");
	register_clcmd("say_team buy_shield", "buy_shield");
	
//------| Invizibility Commands |------//
	register_clcmd("invizibility", "buy_invizibility");
	register_clcmd("buy_invizibility", "buy_invizibility");
	register_clcmd("inv", "buy_invizibility");
	register_clcmd("buy_inv", "buy_invizibility");
	register_clcmd("say /invizibility", "buy_invizibility");
	register_clcmd("say buy_invizibility", "buy_invizibility");
	register_clcmd("say /inv", "buy_invizibility");
	register_clcmd("say buy_inv", "buy_invizibility");
	register_clcmd("say_team /inv", "buy_invizibility");
	register_clcmd("say_team buy_inv", "buy_invizibility");
	register_clcmd("say_team /invizibility", "buy_invizibility");
	register_clcmd("say_team buy_invizibility", "buy_invizibility");
	
//------| GodMode Commands |------//
	register_clcmd("godmode", "buy_godmode");
	register_clcmd("buy_godmode", "buy_godmode");
	register_clcmd("gm", "buy_godmode");
	register_clcmd("buy_gm", "buy_godmode");
	register_clcmd("say /godmode", "buy_godmode");
	register_clcmd("say buy_godmode", "buy_godmode");
	register_clcmd("say /gm", "buy_godmode");
	register_clcmd("say buy_gm", "buy_godmode");
	register_clcmd("say_team /gm", "buy_godmode");
	register_clcmd("say_team buy_gm", "buy_godmode");
	register_clcmd("say_team /godmode", "buy_godmode");
	register_clcmd("say_team buy_godmode", "buy_godmode");
	
//------| Glow Commands |------//
	register_clcmd("glow", "buy_glow");
	register_clcmd("buy_glow", "buy_glow");
	register_clcmd("say /glow", "buy_glow");
	register_clcmd("say buy_glow", "buy_glow");
	register_clcmd("say_team /glow", "buy_glow");
	register_clcmd("say_team buy_glow", "buy_glow");
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Plugin CFG |
//==========================================================================================================
public plugin_cfg() {
	new iCfgDir[32], iFile[192];
	
	get_configsdir(iCfgDir, charsmax(iCfgDir));
	formatex(iFile, charsmax(iFile), "%s/DrShop.cfg", iCfgDir);
		
	if(!file_exists(iFile)) {
	server_print("[DrShop] DrShop.cfg nu exista. Se creeaza.", iFile);
	write_file(iFile, " ", -1);
	}
	
	else {		
	server_print("[DrShop] DrShop.cfg sa incarcat.", iFile);
	server_cmd("exec %s", iFile);
	}
	server_cmd("sv_maxspeed 99999999.0");
	server_cmd("sv_gravity 700");
	server_cmd("sv_airaccelerate 99999999.0");
	server_cmd("deathrun_blockmoney 0");
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Message Hud |
//==========================================================================================================
public MesajHud(id) {
	set_hudmessage(0, 100, 200, -1.0, 0.17, 0, 6.0, 12.0, 0.01, 0.1, 10);
	show_hudmessage(id, "Acest servar foloseste DrShop by Aragon*.^nScrie /drshop sau /shop in chat pentru a cumpara Item.");
	}
public client_putinserver(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	set_task(get_pcvar_float(Mesaj), "MesajHud", 0, _, _, "b");
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deathrun Shop Menu |
//==========================================================================================================
public cmdShop(id) {
	new pcost, ljcost, lcost, hecost, flashcost, smokecost, dcost, adcost,
	ncost, jpcost, nvcost, swcost, hkcost, gcost, sellp, selllj, sellnvg, sellsw,
	shcost, invcost, gmcost;
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	if(get_pcvar_num(deathrunshopmod) == 0) {
	pcost = get_pcvar_num(vip_parachutecost);
	ljcost = get_pcvar_num(vip_longjumpcost);
	lcost = get_pcvar_num(vip_lifecost);
	hecost = get_pcvar_num(vip_hegrenadecost);
	flashcost = get_pcvar_num(vip_flashbangcost);
	smokecost = get_pcvar_num(vip_smokegrenadecost);
	dcost = get_pcvar_num(vip_dglcost);
	adcost = get_pcvar_num(vip_deagleammocost);
	ncost = get_pcvar_num(vip_noclipcost);
	nvcost = get_pcvar_num(vip_nightvisioncost);
	swcost = get_pcvar_num(vip_silentwalkcost);
	shcost = get_pcvar_num(vip_shieldcost);
	jpcost = get_pcvar_num(vip_jetpackcost);
	hkcost = get_pcvar_num(vip_hookcost);
	invcost = get_pcvar_num(vip_invizibilitycost);
	gmcost = get_pcvar_num(vip_godmodecost);
	gcost = get_pcvar_num(vip_glowcost);
	sellp = get_pcvar_num(vip_sellparachute);
	selllj = get_pcvar_num(vip_selllongjump);
	sellnvg = get_pcvar_num(vip_sellnightvision);
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	pcost = get_pcvar_num(vip_points_parachutecost);
	ljcost = get_pcvar_num(vip_points_longjumpcost);
	lcost = get_pcvar_num(vip_points_lifecost);
	hecost = get_pcvar_num(vip_points_hegrenadecost);
	flashcost = get_pcvar_num(vip_points_flashbangcost);
	smokecost = get_pcvar_num(vip_points_smokegrenadecost);
	dcost = get_pcvar_num(vip_points_dglcost);
	adcost = get_pcvar_num(vip_points_deagleammocost);
	ncost = get_pcvar_num(vip_points_noclipcost);
	nvcost = get_pcvar_num(vip_points_nightvisioncost);
	swcost = get_pcvar_num(vip_points_silentwalkcost);
	shcost = get_pcvar_num(vip_points_shieldcost);
	jpcost = get_pcvar_num(vip_points_jetpackcost);
	hkcost = get_pcvar_num(vip_points_hookcost);
	invcost = get_pcvar_num(vip_points_invizibilitycost);
	gmcost = get_pcvar_num(vip_points_godmodecost);
	gcost = get_pcvar_num(vip_points_glowcost);
	sellp = get_pcvar_num(vip_points_sellparachute);
	selllj = get_pcvar_num(vip_points_selllongjump);
	sellnvg = get_pcvar_num(vip_points_sellnightvision);
	sellsw = get_pcvar_num(vip_points_sellsilentwalk);
	}
	}
	else {
	if(get_pcvar_num(deathrunshopmod) == 0) {
	pcost = get_pcvar_num(parachutecost);
	ljcost = get_pcvar_num(longjumpcost);
	lcost = get_pcvar_num(lifecost);
	hecost = get_pcvar_num(hegrenadecost);
	flashcost = get_pcvar_num(flashbangcost);
	smokecost = get_pcvar_num(smokegrenadecost);
	dcost = get_pcvar_num(dglcost);
	adcost = get_pcvar_num(deagleammocost);
	ncost = get_pcvar_num(noclipcost);
	nvcost = get_pcvar_num(nightvisioncost);
	swcost = get_pcvar_num(silentwalkcost);
	shcost = get_pcvar_num(shieldcost);
	jpcost = get_pcvar_num(jetpackcost);
	hkcost = get_pcvar_num(hookcost);
	invcost = get_pcvar_num(invizibilitycost);
	gmcost = get_pcvar_num(godmodecost);
	gcost = get_pcvar_num(glowcost);
	sellp = get_pcvar_num(sellparachute);
	selllj = get_pcvar_num(selllongjump);
	sellnvg = get_pcvar_num(sellnightvision);
	sellsw = get_pcvar_num(sellsilentwalk);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	pcost = get_pcvar_num(points_parachutecost);
	ljcost = get_pcvar_num(points_longjumpcost);
	lcost = get_pcvar_num(points_lifecost);
	hecost = get_pcvar_num(points_hegrenadecost);
	flashcost = get_pcvar_num(points_flashbangcost);
	smokecost = get_pcvar_num(points_smokegrenadecost);
	dcost = get_pcvar_num(points_dglcost);
	adcost = get_pcvar_num(points_deagleammocost);
	ncost = get_pcvar_num(points_noclipcost);
	nvcost = get_pcvar_num(points_nightvisioncost);
	swcost = get_pcvar_num(points_silentwalkcost);
	shcost = get_pcvar_num(points_shieldcost);
	jpcost = get_pcvar_num(points_jetpackcost);
	hkcost = get_pcvar_num(points_hookcost);
	invcost = get_pcvar_num(points_invizibilitycost);
	gmcost = get_pcvar_num(points_godmodecost);
	gcost = get_pcvar_num(points_glowcost);
	sellp = get_pcvar_num(points_sellparachute);
	selllj = get_pcvar_num(points_selllongjump);
	sellnvg = get_pcvar_num(points_sellnightvision);
	sellsw = get_pcvar_num(points_sellsilentwalk);
	}
	}
	new nctime = get_pcvar_num(nocliptime);
	new jptime = get_pcvar_num(jetpacktime);
	new hkamount = get_pcvar_num(hookamount);
	new gmtime = get_pcvar_num(godmodetime);
	new bani = cs_get_user_money(id);
	if(get_pcvar_num(deathrunshop) == 0) {
	ColorChat(id, "^x03%s DrShop^x04 este^x03 Dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti accesa^x03 DrShop^x04 cat timp esti ^x03 Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}	
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	new buffer2[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rDeathRun Shop\w \yVIP\w^n\rMoney:\w \y%i$\w \rPage\w\y",bani);
	menu = menu_create(buffer2, "drshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rDeathRun Shop\w \yVIP\w^n\rPoints:\w \y%i\w \rPage\w\y",PlayerPoints[id]);
	menu = menu_create(buffer2, "drshop");
	}
	}
	else {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\rDeathRun Shop\w^n\rMoney:\w \y%i$\w \rPage\w\y",bani);
	menu = menu_create(buffer, "drshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\rDeathRun Shop\w^n\rPoints:\w \y%i\w \rPage\w\y",PlayerPoints[id]);
	menu = menu_create(buffer, "drshop");
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
	menu_additem(menu, buffer, "3", 0);
	}
	else if(!is_user_alive(id)) { 
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLife - \y%i$\w",lcost);
	menu_additem(menu, buffer, "3", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLife - \y%i Points\w",lcost);
	menu_additem(menu, buffer, "3", 0);
	}
	}
	}
	if(is_user_alive(id)) {
	//------| Parachute |------//
	if(get_pcvar_num(acces_parachute) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_parachute) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_parachute) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(parachute) == 0) { 
	} 
	else if(!has_parachute[id] && pcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wParachute - \rFree\w");
	menu_additem(menu, buffer, "1", 0);
	}
	else if(!has_parachute[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wParachute - \y%i$\w",pcost);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wParachute - \y%i Points\w",pcost);
	menu_additem(menu, buffer, "1", 0);
	}		
	}
	else if(has_parachute[id]) {
	new buffer[256]; 
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Parachute - \r+%i$\w",sellp);
	menu_additem(menu, buffer, "1", 0);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Parachute - \r+%i Points\w",sellp);
	menu_additem(menu, buffer, "1", 0);
	}
	}
	
//------| LongJump |------//
	if(get_pcvar_num(acces_longjump) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_longjump) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_longjump) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(longjump) == 0) { 
	}
	else if(!g_hasLongJump[id] && ljcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wLongjump - \rFree\w");
	menu_additem(menu, buffer, "2", 0);
	}
	else if(!g_hasLongJump[id]) { 
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLongjump - \y%i$\w",ljcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wLongjump - \y%i Points\w",ljcost);
	menu_additem(menu, buffer, "2", 0);
	}
	}
	else if(g_hasLongJump[id]) { 
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Longjump - \r+%i$\w",selllj);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(g_hasLongJump[id]) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Longjump - \r+%i Points\w",selllj);
	menu_additem(menu, buffer, "2", 0);
	}
	}
	
//------| Grenades |------//
	if(get_pcvar_num(acces_grenades) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_grenades) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_grenades) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(grenades) == 0) { 
	}
	else if(user_has_weapon (id, CSW_HEGRENADE) && user_has_weapon (id, CSW_FLASHBANG) && user_has_weapon (id, CSW_SMOKEGRENADE)) {
	menu_additem(menu, "\wHE|FLASH|SMOKE - \rAlready Have\w", "4", 0);
	}
	else if(hecost == 0 && flashcost == 0 && smokecost == 0 && !user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH|SMOKE - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(hecost == 0 && flashcost == 0 && !user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(hecost == 0 && smokecost == 0 && !user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHE|SMOKE - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(flashcost == 0 && smokecost == 0 && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wFLASH|SMOKE - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(smokecost == 0 && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSMOKE Grenade - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(flashcost == 0 && !user_has_weapon (id, CSW_FLASHBANG)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wFLASH Grenade - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(hecost == 0 && !user_has_weapon (id, CSW_HEGRENADE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHE Grenade - \rFree\w");
	menu_additem(menu, buffer, "4", 0);
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH|SMOKE - \y%i$\w",hecost + flashcost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH|SMOKE - \y%i Points\w",hecost + flashcost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH - \y%i$\w",hecost + flashcost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|FLASH - \y%i Points\w",hecost + flashcost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|SMOKE - \y%i$\w",hecost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE|SMOKE - \y%i Points\w",hecost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wFLASH|SMOKE - \y%i$\w",flashcost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wFLASH|SMOKE - \y%i Points\w",flashcost + smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id, CSW_SMOKEGRENADE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSMOKE Grenade - \y%i$\w",smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSMOKE Grenade - \y%i Points\w",smokecost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id,CSW_FLASHBANG)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wFLASH Grenade - \y%i$\w",flashcost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wFLASH Grenade - \y%i Points\w",flashcost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE Grenade - \y%i$\w",hecost);
	menu_additem(menu, buffer, "4", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHE Grenade - \y%i Points\w",hecost);
	menu_additem(menu, buffer, "4", 0);
	}
	}
	
//------| Health & Armor |------//
	if(get_pcvar_num(acces_healtharmor) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_healtharmor) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_healtharmor) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else {
	hpapcmdShop2(id);
	}
	
//------| Gravity & Speed |------//
	if(get_pcvar_num(acces_gravityspeed) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_gravityspeed) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_gravityspeed) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else {
	grspcmdShop2(id);
	}

//------| Deagle |------//
	if(get_pcvar_num(acces_deagle) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_deagle) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_deagle) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(deagle) == 0) { 
	}
	else if(!user_has_weapon (id, CSW_DEAGLE) && dcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wDesert Eagle - \rFree\w");
	menu_additem(menu, buffer, "7", 0);
	}
	else if(user_has_weapon(id, CSW_DEAGLE) && cs_get_user_bpammo(id, CSW_DEAGLE)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wDesert Eagle - \rAlready Have\w",adcost);
	menu_additem(menu, buffer, "7", 0);
	}
	else if(!user_has_weapon (id, CSW_DEAGLE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wDesert Eagle - \y%i$\w",dcost);
	menu_additem(menu, buffer, "7", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wDesert Eagle - \y%i Points\w",dcost);
	menu_additem(menu, buffer, "7", 0);
	}
	}
	else if(user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAmmo Deagle - \y%i$\w",adcost);
	menu_additem(menu, buffer, "7", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wAmmo Deagle - \y%i Points\w",adcost);
	menu_additem(menu, buffer, "7", 0);
	}
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
	menu_additem(menu, buffer, "8", 0);
	}
	else if(!get_user_noclip(id)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNo Clip - \y%i$\w \r(%d Secunde)\w",ncost,nctime);
	menu_additem(menu, buffer, "8", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNo Clip - \y%i Points\w \r(%d Secunde)\w",ncost,nctime);
	menu_additem(menu, buffer, "8", 0);
	}
	}
	else if(get_user_noclip(id)) {
	menu_additem(menu, "\wNo Clip - \rAlready Have\w", "8", 0);
	}
	
//------| NightVision |------//	
	if(get_pcvar_num(acces_nightvision) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_nightvision) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_nightvision) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(nightvision) == 0) { 
	}
	else if(!cs_get_user_nvg (id) && nvcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wNightvision - \rFree\w");
	menu_additem(menu, buffer, "9", 0);
	}
	else if(cs_get_user_nvg(id) && !g_hasNightVision[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wNightvision - \rAlready Have\w",sellnvg);
	menu_additem(menu, buffer, "9", 0);
	}
	else if(!cs_get_user_nvg (id)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNightvision - \y%i$\w",nvcost);
	menu_additem(menu, buffer, "9", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wNightvision - \y%i Points\w",nvcost);
	menu_additem(menu, buffer, "9", 0);
	}
	}
	else if(cs_get_user_nvg (id)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Nightvision - \r+%i$\w",sellnvg);
	menu_additem(menu, buffer, "9", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Nightvision - \r+%i Points\w",sellnvg);
	menu_additem(menu, buffer, "9", 0);
	}
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
	menu_additem(menu, buffer, "10", 0);
	}
	else if(get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \rAlready Have\w",sellsw);
	menu_additem(menu, buffer, "10", 0);
	}
	else if(!get_user_footsteps(id) && !g_hasSilentWalk[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \y%i$\w",swcost);
	menu_additem(menu, buffer, "10", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSilent Walk - \y%i Points\w",swcost);
	menu_additem(menu, buffer, "10", 0);
	}
	}
	else if(get_user_footsteps(id) && g_hasSilentWalk[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSell Silent Walk - \r+%i$\w",sellsw);
	menu_additem(menu, buffer, "10", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSell Silent Walk - \r+%i Points\w",sellsw);
	menu_additem(menu, buffer, "10", 0);
	}
	}
	
//------| Shield |------//
	if(get_pcvar_num(acces_shield) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_shield) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_shield) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(shield) == 0) {
	}
	else if(!cs_get_user_shield(id) && shcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wShield - \rFree\w");
	menu_additem(menu, buffer, "11", 0);
	}
	else if(!cs_get_user_shield(id)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wShield - \y%i$\w",shcost);
	menu_additem(menu, buffer, "11", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wShield - \y%i Points\w",shcost);
	menu_additem(menu, buffer, "11", 0);
	}
	}
	else if(cs_get_user_shield(id)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wShield - \rAlready Have\w");
	menu_additem(menu, buffer, "11", 0);
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
	menu_additem(menu, buffer, "12", 0);
	}
	else if(!has_jp[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wJetPack - \y%i$\w \r(%d Secunde)\w",jpcost, jptime);
	menu_additem(menu, buffer, "12", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wJetPack - \y%i Points\w \r(%d Secunde)\w",jpcost, jptime);
	menu_additem(menu, buffer, "12", 0);
	}
	}
	else if(has_jp[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wJetpack - \rAlready Have\w");
	menu_additem(menu, buffer, "12", 0);
	}
	
//------| Hook |------//
	if(get_pcvar_num(acces_hook) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_hook) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_hook) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(hook) == 0) { 
	}
	else if(!g_hasHook[id] && hkcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHook - \rFree\w");
	menu_additem(menu, buffer, "13", 0);
	}
	else if(!g_hasHook[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHook \r(%d Hits)\w - \y%i$\w", hkamount, hkcost);
	menu_additem(menu, buffer, "13", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wHook \r(%d Hits)\w - \y%i Points\w", hkamount, hkcost);
	menu_additem(menu, buffer, "13", 0);
	}
	}
	else if(g_hasHook[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHook - \rAlready Have\w");
	menu_additem(menu, buffer, "13", 0);
	}
//------| Invizibility |------//
	if(get_pcvar_num(acces_invizibility) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_invizibility) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_invizibility) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(invizibility) == 0) { 
	}
	else if(!g_hasInvizibility[id] && invcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wInvizibility - \rFree\w");
	menu_additem(menu, buffer, "14", 0);
	}
	else if(!g_hasInvizibility[id]) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wInvizibility - \y%i$\w",invcost);
	menu_additem(menu, buffer, "14", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wInvizibility - \y%i Points\w",invcost);
	menu_additem(menu, buffer, "14", 0);
	}
	}
	else if(g_hasInvizibility[id]) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wInvizibility - \rAlready Have\w");
	menu_additem(menu, buffer, "14", 0);
	}
	
//------| GodMode |------//
	if(get_pcvar_num(acces_godmode) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_godmode) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_godmode) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(godmode) == 0) { 
	}
	else if(!get_user_godmode(id) && gmcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGodMode - \rFree\w \y(%d Secunde)\w",gmtime);
	menu_additem(menu, buffer, "15", 0);
	}
	else if(!get_user_godmode(id)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wGodMode - \y%i$\w \r(%d Secunde)\w",gmcost, gmtime);
	menu_additem(menu, buffer, "15", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wGodMode - \y%i Points\w \r(%d Secunde)\w",gmcost, gmtime);
	menu_additem(menu, buffer, "15", 0);
	}
	}
	else if(get_user_godmode(id)) {
	menu_additem(menu, "\wGodMode - \rAlready Have\w", "15", 0);
	}
	
//------| Glow |------//
	if(get_pcvar_num(acces_glow) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	}
	else if(get_pcvar_num(acces_glow) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	}
	else if(get_pcvar_num(acces_glow) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	}
	else if(get_pcvar_num(glow) == 0) { 
	}
	else if(gcost == 0) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSwitch Glow - \rFree\w");
	menu_additem(menu, buffer, "16", 0);
	}
	else if(gcost > 0) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSwitch Glow - \y%i$\w",gcost);
	menu_additem(menu, buffer, "16", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wSwitch Glow - \y%i Points\w",gcost);
	menu_additem(menu, buffer, "16", 0);
	}
	}
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deathrun Shop Case |
//==========================================================================================================
public drshop(id, menu, item) {

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
// Parachuet Case |
//==========================================================================================================
case 1: {
	new pcost, sellp;
	new bani = cs_get_user_money(id);
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	pcost = get_pcvar_num(vip_parachutecost);
	sellp = get_pcvar_num(vip_sellparachute);
	}
	else {
	pcost = get_pcvar_num(parachutecost);
	sellp = get_pcvar_num(sellparachute);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	pcost = get_pcvar_num(vip_points_parachutecost);
	sellp = get_pcvar_num(vip_points_sellparachute);
	}
	else {
	pcost = get_pcvar_num(points_parachutecost);
	sellp = get_pcvar_num(points_sellparachute);
	}
	}
	if(get_pcvar_num(parachute) == 0) { 
	ColorChat(id, "^x03%s Parachuta^x04 este Dezactivata.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Parachuta^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Parachuta^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(has_parachute[id]) {
	cs_set_user_money(id, bani + sellp);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Parachute^x04,ai primit^x03 %i$.",Prefix ,sellp);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = false;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(bani < pcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Parachuta^x04. Necesari:^x03 %i$",Prefix ,pcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_parachute[id]) {
	cs_set_user_money(id, bani - pcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o^x03 Parachuta^x04.Pentru utilizare apasa tasta^x03 E.", Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = true;
	Screen1(id);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(has_parachute[id]) {
	PlayerPoints[id] += sellp;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Parachute^x04,ai primit^x03 %i Puncte.",Prefix ,sellp);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = false;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < pcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Parachuta^x04. Necesare:^x03 %i Puncte",Prefix ,pcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_parachute[id]) {
	PlayerPoints[id] -= pcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat o^x03 Parachuta^x04.Pentru utilizare apasa tasta^x03 E.", Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = true;
	Screen1(id);
	}
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LongJump Case |
//==========================================================================================================
case 2: {
	new ljcost, selllj;
	new bani = cs_get_user_money(id);
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ljcost = get_pcvar_num(vip_longjumpcost);
	selllj = get_pcvar_num(vip_selllongjump);
	}
	else {
	ljcost = get_pcvar_num(longjumpcost);
	selllj = get_pcvar_num(selllongjump);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ljcost = get_pcvar_num(vip_points_longjumpcost);
	selllj = get_pcvar_num(vip_points_selllongjump);
	}
	else {
	ljcost = get_pcvar_num(points_longjumpcost);
	selllj = get_pcvar_num(points_selllongjump);
	}
	}
	if(get_pcvar_num(longjump) == 0) {
	ColorChat(id, "^x03%s LongJump^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 LongJump^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 LongJump^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(g_hasLongJump[id]) {
	cs_set_user_money(id,bani + selllj);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 LongJump^x04,ai primit^x03 %i$",Prefix,selllj);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 0);
	g_hasLongJump[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(bani < ljcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 LongJump^x04. Necesari:^x03 %i$",Prefix,ljcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasLongJump[id]) {
	cs_set_user_money(id,bani - ljcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 LongJump^x04.Pentru utilizare apasa^x03 Ctrl+Space.",Prefix);
	emit_sound(id,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 1);
	g_hasLongJump[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(g_hasLongJump[id]) {
	PlayerPoints[id] += selllj;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 LongJump^x04,ai primit^x03 %i Puncte",Prefix,selllj);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 0);
	g_hasLongJump[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < ljcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 LongJump^x04. Necesare:^x03 %i Puncte",Prefix,ljcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasLongJump[id]) {
	PlayerPoints[id] -= ljcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 LongJump^x04.Pentru utilizare apasa^x03 Ctrl+Space.",Prefix);
	emit_sound(id,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 1);
	g_hasLongJump[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life | Grenade | Heatlh & Armor | Gravity & Speed |
//==========================================================================================================
case 3: buy_life(id);
case 4: buy_grenade(id);
case 5: {
	if(get_pcvar_num(armor) == 0) {
	buy_health(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(health) == 0) {
	buy_armor(id);	
	return PLUGIN_HANDLED;
	}
	else {
	hpapcmdShop(id);
	return PLUGIN_HANDLED;
	}
	}
case 6: {
	if(get_pcvar_num(speed) == 0) {
	buy_gravity(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(gravity) == 0) {
	buy_speed(id);	
	return PLUGIN_HANDLED;
	}
	else {
	grspcmdShop(id);
	return PLUGIN_HANDLED;
	}
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deagle Case |
//==========================================================================================================
case 7: {
	new bani = cs_get_user_money(id);
	new dgcost, adcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	dgcost = get_pcvar_num(vip_dglcost);
	adcost = get_pcvar_num(vip_deagleammocost);
	}
	else {
	dgcost = get_pcvar_num(dglcost);
	adcost = get_pcvar_num(deagleammocost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	dgcost = get_pcvar_num(vip_points_dglcost);
	adcost = get_pcvar_num(vip_points_deagleammocost);
	}
	else {
	dgcost = get_pcvar_num(points_dglcost);
	adcost = get_pcvar_num(points_deagleammocost);
	}
	}
	if(get_pcvar_num(deagle) == 0) { 
	ColorChat(id, "^x03%s Deagle^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE) && cs_get_user_bpammo(id, CSW_DEAGLE)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < adcost && user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	cs_set_user_money(id, bani - adcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 Deagle.",Prefix);
	cs_set_user_bpammo(id, CSW_DEAGLE, cs_get_user_bpammo(id, CSW_DEAGLE) + 7);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(bani < dgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara un^x03 Deagle^x04. Necesari:^x03 %i$",Prefix,dgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_DEAGLE)) {
	cs_set_user_money(id, bani - dgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < adcost && user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	PlayerPoints[id] -= adcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 Deagle.",Prefix);
	cs_set_user_bpammo(id, CSW_DEAGLE, cs_get_user_bpammo(id, CSW_DEAGLE) + 7);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < dgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara un^x03 Deagle^x04. Necesare:^x03 %i Puncte",Prefix,dgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(id, CSW_DEAGLE)) {
	PlayerPoints[id] -= dgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id,"weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	}
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NoClip |
//==========================================================================================================
case 8: buy_noclip(id);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NightVision Case |
//==========================================================================================================
case 9: {
	new bani = cs_get_user_money(id);
	new nvcost, sellnvg;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	nvcost = get_pcvar_num(vip_nightvisioncost);
	sellnvg = get_pcvar_num(vip_sellnightvision);	
	}
	else {
	nvcost = get_pcvar_num(nightvisioncost);
	sellnvg = get_pcvar_num(sellnightvision);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	nvcost = get_pcvar_num(vip_points_nightvisioncost);
	sellnvg = get_pcvar_num(vip_points_sellnightvision);	
	}
	else {
	nvcost = get_pcvar_num(points_nightvisioncost);
	sellnvg = get_pcvar_num(points_sellnightvision);
	}
	}
	if(cs_get_user_nvg(id) && !g_hasNightVision[id]) {
	ColorChat(id, "^x03%s^x04 Detii deja^x03 NightVision^x04 din alte surse.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(nightvision) == 0) { 
	ColorChat(id, "^x03%s NightVision^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	} 
	if(get_pcvar_num(acces_nightvision) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_nightvision) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_nightvision) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NightVision^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NightVision^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(cs_get_user_nvg(id)) {
	cs_set_user_money(id, bani + sellnvg);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 NightVision^x04,ai primit^x03 %i$.",Prefix,sellnvg);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 0);
	g_hasNightVision[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(bani < nvcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 NightVision^x04. Necesari:^x03 %i$",Prefix,nvcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - nvcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 NightVision^x04.Pentru utilizare apasa tasta^x03 N.",Prefix);
	emit_sound(id,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 1);
	g_hasNightVision[id] = 1;
	Screen1(id);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(cs_get_user_nvg(id)) {
	PlayerPoints[id] += sellnvg;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 NightVision^x04,ai primit^x03 %i Puncte.",Prefix,sellnvg);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 0);
	g_hasNightVision[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	if(PlayerPoints[id] < nvcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 NightVision^x04. Necesare:^x03 %i Puncte",Prefix,nvcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= nvcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 NightVision^x04.Pentru utilizare apasa tasta^x03 N.",Prefix);
	emit_sound(id,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 1);
	g_hasNightVision[id] = 1;
	Screen1(id);
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Silent Walk Case |
//==========================================================================================================
case 10: {
	new bani = cs_get_user_money(id);
	new swcost, sellsw;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_silentwalkcost);
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	else {
	swcost = get_pcvar_num(silentwalkcost);
	sellsw = get_pcvar_num(sellsilentwalk);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
// Shield | Jetpack | Invizibility | GodMode | Glow |
//==========================================================================================================
case 11: buy_shield(id);
case 12: buy_jetpack(id);
case 13: buy_hook(id);
case 14: buy_invizibility(id);
case 15: buy_godmode(id);
case 16: buy_glow(id);
	default: return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Health & Armor Menu |
//==========================================================================================================
public hpapcmdShop(id) { 
	new hpcost, apcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_healthcost);
	apcost = get_pcvar_num(vip_armorcost);
	}
	else {
	hpcost = get_pcvar_num(healthcost);
	apcost = get_pcvar_num(armorcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_points_healthcost);
	apcost = get_pcvar_num(vip_points_armorcost);
	}
	else {
	hpcost = get_pcvar_num(points_healthcost);
	apcost = get_pcvar_num(points_armorcost);
	}
	}
	new bani = cs_get_user_money(id);
	new mh = get_pcvar_num(maxhealth);
	new ma = get_pcvar_num(maxarmor);
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	new buffer2[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rHealth and Armor\w \yVIP\w^n\rMoney:\w \y%i$\w",bani);
	menu = menu_create(buffer2, "hpapshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rHealth and Armor\w \yVIP\w^n\rPoints:\w \y%i\w",PlayerPoints[id]);
	menu = menu_create(buffer2, "hpapshop");
	}
	}
	else {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\rHealth and Armor\w^n\rMoney:\w \y%i$\w",bani);
	menu = menu_create(buffer, "hpapshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\rHealth and Armor\w^n\rPoints:\w \y%i\w",PlayerPoints[id]);
	menu = menu_create(buffer, "hpapshop");
	}
	}
	if(get_pcvar_num(health) == 0 && get_pcvar_num(armor) == 0) {
	ColorChat(id, "^x03%s^x03 Health and Armor^x04 sunt^x03 Dezactivate.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
//------| Health |------//
	if(get_pcvar_num(health) == 0) { 
	}
	else if(get_user_health(id) == mh) {
	menu_additem(menu, "\wHealth - \rMax Health\w", "1", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) == 0) {
	if(hpcost == 0 && get_user_health(id) <= mh - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+50\w - \rFree\w \r(Max: %d)\w",hpcost * 50 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+49\w - \rFree\w \r(Max: %d)\w",hpcost * 49 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+48\w - \rFree\w \r(Max: %d)\w",hpcost * 48 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+47\w - \rFree\w \r(Max: %d)\w",hpcost * 47 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+46\w - \rFree\w \r(Max: %d)\w",hpcost * 46 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+45\w - \rFree\w \r(Max: %d)\w",hpcost * 45 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+44\w - \rFree\w \r(Max: %d)\w",hpcost * 44 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+43\w - \rFree\w \r(Max: %d)\w",hpcost * 43 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+42\w - \rFree\w \r(Max: %d)\w",hpcost * 42 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+41\w - \rFree\w \r(Max: %d)\w",hpcost * 41 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+40\w - \rFree\w \r(Max: %d)\w",hpcost * 40 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+39\w - \rFree\w \r(Max: %d)\w",hpcost * 39 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+38\w - \rFree\w \r(Max: %d)\w",hpcost * 38 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+37\w - \rFree\w \r(Max: %d)\w",hpcost * 37 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+36\w - \rFree\w \r(Max: %d)\w",hpcost * 36 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+35\w - \rFree\w \r(Max: %d)\w",hpcost * 35 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+34\w - \rFree\w \r(Max: %d)\w",hpcost * 34 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+33\w - \rFree\w \r(Max: %d)\w",hpcost * 33 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+32\w - \rFree\w \r(Max: %d)\w",hpcost * 32 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+31\w - \rFree\w \r(Max: %d)\w",hpcost * 31 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+30\w - \rFree\w \r(Max: %d)\w",hpcost * 30 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+29\w - \rFree\w \r(Max: %d)\w",hpcost * 29 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+28\w - \rFree\w \r(Max: %d)\w",hpcost * 28 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+27\w - \rFree\w \r(Max: %d)\w",hpcost * 27 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+26\w - \rFree\w \r(Max: %d)\w",hpcost * 26 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+25\w - \rFree\w \r(Max: %d)\w",hpcost * 25 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+24\w - \rFree\w \r(Max: %d)\w",hpcost * 24 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+23\w - \rFree\w \r(Max: %d)\w",hpcost * 23 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+22\w - \rFree\w \r(Max: %d)\w",hpcost * 22 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+21\w - \rFree\w \r(Max: %d)\w",hpcost * 21 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+20\w - \rFree\w \r(Max: %d)\w",hpcost * 20 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+19\w - \rFree\w \r(Max: %d)\w",hpcost * 19 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+18\w - \rFree\w \r(Max: %d)\w",hpcost * 18 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+17\w - \rFree\w \r(Max: %d)\w",hpcost * 17 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+16\w - \rFree\w \r(Max: %d)\w",hpcost * 16 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+15\w - \rFree\w \r(Max: %d)\w",hpcost * 15 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+14\w - \rFree\w \r(Max: %d)\w",hpcost * 14 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+13\w - \rFree\w \r(Max: %d)\w",hpcost * 13 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+12\w - \rFree\w \r(Max: %d)\w",hpcost * 12 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+11\w - \rFree\w \r(Max: %d)\w",hpcost * 11 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+10\w - r%i$\w \r(Max: %d)\w",hpcost * 10 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+9\w - \rFree\w \r(Max: %d)\w",hpcost * 9 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+8\w - \rFree\w \r(Max: %d)\w",hpcost * 8 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+7\w - \rFree\w \r(Max: %d)\w",hpcost * 7 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+6\w - \rFree\w \r(Max: %d)\w",hpcost * 6 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+5\w - \rFree\w \r(Max: %d)\w",hpcost * 5 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+4\w - \rFree\w \r(Max: %d)\w",hpcost * 4 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+3\w - \rFree\w \r(Max: %d)\w",hpcost * 3 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+2\w - \rFree\w \r(Max: %d)\w",hpcost * 2 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(hpcost == 0 && get_user_health(id) <= mh - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+1\w - \rFree\w \r(Max: %d)\w",hpcost ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 50 && get_user_health(id) <= mh - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+50\w - \y%i$\w \r(Max: %d)\w",hpcost * 50 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 49 && get_user_health(id) <= mh - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+49\w - \y%i$\w \r(Max: %d)\w",hpcost * 49 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 48 && get_user_health(id) <= mh - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+48\w - \y%i$\w \r(Max: %d)\w",hpcost * 48 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 47 && get_user_health(id) <= mh - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+47\w - \y%i$\w \r(Max: %d)\w",hpcost * 47 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 46 && get_user_health(id) <= mh - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+46\w - \y%i$\w \r(Max: %d)\w",hpcost * 46 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 45 && get_user_health(id) <= mh - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+45\w - \y%i$\w \r(Max: %d)\w",hpcost * 45 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 44 && get_user_health(id) <= mh - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+44\w - \y%i$\w \r(Max: %d)\w",hpcost * 44 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 43 && get_user_health(id) <= mh - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+43\w - \y%i$\w \r(Max: %d)\w",hpcost * 43 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 42 && get_user_health(id) <= mh - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+42\w - \y%i$\w \r(Max: %d)\w",hpcost * 42 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 41 && get_user_health(id) <= mh - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+41\w - \y%i$\w \r(Max: %d)\w",hpcost * 41 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 40 && get_user_health(id) <= mh - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+40\w - \y%i$\w \r(Max: %d)\w",hpcost * 40 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 39 && get_user_health(id) <= mh - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+39\w - \y%i$\w \r(Max: %d)\w",hpcost * 39 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 38 && get_user_health(id) <= mh - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+38\w - \y%i$\w \r(Max: %d)\w",hpcost * 38 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 37 && get_user_health(id) <= mh - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+37\w - \y%i$\w \r(Max: %d)\w",hpcost * 37 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 36 && get_user_health(id) <= mh - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+36\w - \y%i$\w \r(Max: %d)\w",hpcost * 36 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 35 && get_user_health(id) <= mh - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+35\w - \y%i$\w \r(Max: %d)\w",hpcost * 35 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 34 && get_user_health(id) <= mh - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \w+34\w - \y%i$\w \r(Max: %d)\w",hpcost * 34 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 33 && get_user_health(id) <= mh - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+33\w - \y%i$\w \r(Max: %d)\w",hpcost * 33 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 32 && get_user_health(id) <= mh - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+32\w - \y%i$\w \r(Max: %d)\w",hpcost * 32 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 31 && get_user_health(id) <= mh - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+31\w - \y%i$\w \r(Max: %d)\w",hpcost * 31 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 30 && get_user_health(id) <= mh - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+30\w - \y%i$\w \r(Max: %d)\w",hpcost * 30 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 29 && get_user_health(id) <= mh - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+29\w - \y%i$\w \r(Max: %d)\w",hpcost * 29 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 28 && get_user_health(id) <= mh - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+28\w - \y%i$\w \r(Max: %d)\w",hpcost * 28 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 27 && get_user_health(id) <= mh - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+27\w - \y%i$\w \r(Max: %d)\w",hpcost * 27 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 26 && get_user_health(id) <= mh - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+26\w - \y%i$\w \r(Max: %d)\w",hpcost * 26 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 25 && get_user_health(id) <= mh - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+25\w - \y%i$\w \r(Max: %d)\w",hpcost * 25 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 24 && get_user_health(id) <= mh - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+24\w - \y%i$\w \r(Max: %d)\w",hpcost * 24 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 23 && get_user_health(id) <= mh - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+23\w - \y%i$\w \r(Max: %d)\w",hpcost * 23 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 22 && get_user_health(id) <= mh - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+22\w - \y%i$\w \r(Max: %d)\w",hpcost * 22 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 21 && get_user_health(id) <= mh - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+21\w - \y%i$\w \r(Max: %d)\w",hpcost * 21 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 20 && get_user_health(id) <= mh - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+20\w - \y%i$\w \r(Max: %d)\w",hpcost * 20 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 19 && get_user_health(id) <= mh - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+19\w - \y%i$\w \r(Max: %d)\w",hpcost * 19 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 18 && get_user_health(id) <= mh - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+18\w - \y%i$\w \r(Max: %d)\w",hpcost * 18 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 17 && get_user_health(id) <= mh - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+17\w - \y%i$\w \r(Max: %d)\w",hpcost * 17 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 16 && get_user_health(id) <= mh - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+16\w - \y%i$\w \r(Max: %d)\w",hpcost * 16 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 15 && get_user_health(id) <= mh - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+15\w - \y%i$\w \r(Max: %d)\w",hpcost * 15 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 14 && get_user_health(id) <= mh - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+14\w - \y%i$\w \r(Max: %d)\w",hpcost * 14 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 13 && get_user_health(id) <= mh - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+13\w - \y%i$\w \r(Max: %d)\w",hpcost * 13 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 12 && get_user_health(id) <= mh - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+12\w - \y%i$\w \r(Max: %d)\w",hpcost * 12 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 11 && get_user_health(id) <= mh - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+11\w - \y%i$\w \r(Max: %d)\w",hpcost * 11 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 10 && get_user_health(id) <= mh - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+10\w - \y%i$\w \r(Max: %d)\w",hpcost * 10 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 9 && get_user_health(id) <= mh - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+9\w - \y%i$\w \r(Max: %d)\w",hpcost * 9 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 8 && get_user_health(id) <= mh - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+8\w - \y%i$\w \r(Max: %d)\w",hpcost * 8 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 7 && get_user_health(id) <= mh - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+7\w - \y%i$\w \r(Max: %d)\w",hpcost * 7 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 6 && get_user_health(id) <= mh - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+6\w - \y%i$\w \r(Max: %d)\w",hpcost * 6 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 5 && get_user_health(id) <= mh - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+5\w - \y%i$\w \r(Max: %d)\w",hpcost * 5 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 4 && get_user_health(id) <= mh - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+4\w - \y%i$\w \r(Max: %d)\w",hpcost * 4 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 3 && get_user_health(id) <= mh - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+3\w - \y%i$\w \r(Max: %d)\w",hpcost * 3 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost * 2 && get_user_health(id) <= mh - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+2\w - \y%i$\w \r(Max: %d)\w",hpcost * 2 ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) >= hpcost && get_user_health(id) <= mh - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+1\w - \y%i$\w \r(Max: %d)\w",hpcost ,mh);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(cs_get_user_money(id) < hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(Max: %d)\w - \y%i$\w ",mh ,hpcost * 50);
	menu_additem(menu, buffer, "1", 0);
	}
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \y(%d)\w - \r%i Points\w ",mh ,hpcost);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(PlayerPoints[id] >= hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(%d)\w - \y%i Points\w ",mh ,hpcost);
	menu_additem(menu, buffer, "1", 0);
	}
	}
	
//------| Armor|------//
	if(get_pcvar_num(armor) == 0) { 
	}
	else if(get_user_armor(id) == ma) {
	menu_additem(menu, "\wArmor - \rMax Armor\w", "2", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) == 0) {
	if(apcost == 0 && get_user_armor(id) <= ma - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+50\w - \rFree\w \r(Max: %d)\w",apcost * 50 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+49\w - \rFree\w \r(Max: %d)\w",apcost * 49 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+48\w - \rFree\w \r(Max: %d)\w",apcost * 48 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+47\w - \rFree\w \r(Max: %d)\w",apcost * 47 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+46\w - \rFree\w \r(Max: %d)\w",apcost * 46 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+45\w - \rFree\w \r(Max: %d)\w",apcost * 45 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+44\w - \rFree\w \r(Max: %d)\w",apcost * 44 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+43\w - \rFree\w \r(Max: %d)\w",apcost * 43 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+42\w - \rFree\w \r(Max: %d)\w",apcost * 42 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+41\w - \rFree\w \r(Max: %d)\w",apcost * 41 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+40\w - \rFree\w \r(Max: %d)\w",apcost * 40 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+39\w - \rFree\w \r(Max: %d)\w",apcost * 39 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+38\w - \rFree\w \r(Max: %d)\w",apcost * 38 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+37\w - \rFree\w \r(Max: %d)\w",apcost * 37 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+36\w - \rFree\w \r(Max: %d)\w",apcost * 36 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+35\w - \rFree\w \r(Max: %d)\w",apcost * 35 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+34\w - \rFree\w \r(Max: %d)\w",apcost * 34 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+33\w - \rFree\w \r(Max: %d)\w",apcost * 33 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+32\w - \rFree\w \r(Max: %d)\w",apcost * 32 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+31\w - \rFree\w \r(Max: %d)\w",apcost * 31 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+30\w - \rFree\w \r(Max: %d)\w",apcost * 30 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+29\w - \rFree\w \r(Max: %d)\w",apcost * 29 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+28\w - \rFree\w \r(Max: %d)\w",apcost * 28 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+27\w - \rFree\w \r(Max: %d)\w",apcost * 27 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+26\w - \rFree\w \r(Max: %d)\w",apcost * 26 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+25\w - \rFree\w \r(Max: %d)\w",apcost * 25 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+24\w - \rFree\w \r(Max: %d)\w",apcost * 24 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+23\w - \rFree\w \r(Max: %d)\w",apcost * 23 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+22\w - \rFree\w \r(Max: %d)\w",apcost * 22 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+21\w - \rFree\w \r(Max: %d)\w",apcost * 21 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+20\w - \rFree\w \r(Max: %d)\w",apcost * 20 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+19\w - \rFree\w \r(Max: %d)\w",apcost * 19 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+18\w - \rFree\w \r(Max: %d)\w",apcost * 18 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+17\w - \rFree\w \r(Max: %d)\w",apcost * 17 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+16\w - \rFree\w \r(Max: %d)\w",apcost * 16 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+15\w - \rFree\w \r(Max: %d)\w",apcost * 15 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+14\w - \rFree\w \r(Max: %d)\w",apcost * 14 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+13\w - \rFree\w \r(Max: %d)\w",apcost * 13 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+12\w - \rFree\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+11\w - \rFree\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+10\w - \rFree\w \r(Max: %d)\w",apcost * 10 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+9\w - \rFree\w \r(Max: %d)\w",apcost * 9 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+8\w - \rFree\w \r(Max: %d)\w",apcost * 8 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+7\w - \rFree\w \r(Max: %d)\w",apcost * 7 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+6\w - \rFree\w \r(Max: %d)\w",apcost * 6 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+5\w - \rFree\w \r(Max: %d)\w",apcost * 5 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+4\w - \rFree\w \r(Max: %d)\w",apcost * 4 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+3\w - \rFree\w \r(Max: %d)\w",apcost * 3 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+2\w - \rFree\w \r(Max: %d)\w",apcost * 2 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(apcost == 0 && get_user_armor(id) <= ma - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+1\w - \rFree\w \r(Max: %d)\w",apcost ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 50 && get_user_armor(id) <= ma - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+50\w - \y%i$\w \r(Max: %d)\w",apcost * 50 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 49 && get_user_armor(id) <= ma - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+49\w - \y%i$\w \r(Max: %d)\w",apcost * 49 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 48 && get_user_armor(id) <= ma - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+48\w - \y%i$\w \r(Max: %d)\w",apcost * 48 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 47 && get_user_armor(id) <= ma - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+47\w - \y%i$\w \r(Max: %d)\w",apcost * 47 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 46 && get_user_armor(id) <= ma - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+46\w - \y%i$\w \r(Max: %d)\w",apcost * 46 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 45 && get_user_armor(id) <= ma - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+45\w - \y%i$\w \r(Max: %d)\w",apcost * 45 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 44 && get_user_armor(id) <= ma - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+44\w - \y%i$\w \r(Max: %d)\w",apcost * 44 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 43 && get_user_armor(id) <= ma - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+43\w - \y%i$\w \r(Max: %d)\w",apcost * 43 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 42 && get_user_armor(id) <= ma - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+42\w - \y%i$\w \r(Max: %d)\w",apcost * 42 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 41 && get_user_armor(id) <= ma - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+41\w - \y%i$\w \r(Max: %d)\w",apcost * 41 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 40 && get_user_armor(id) <= ma - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+40\w - \y%i$\w \r(Max: %d)\w",apcost * 40 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 39 && get_user_armor(id) <= ma - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+39\w - \y%i$\w \r(Max: %d)\w",apcost * 39 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 38 && get_user_armor(id) <= ma - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+38\w - \y%i$\w \r(Max: %d)\w",apcost * 38 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 37 && get_user_armor(id) <= ma - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+37\w - \y%i$\w \r(Max: %d)\w",apcost * 37 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 36 && get_user_armor(id) <= ma - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+36\w - \y%i$\w \r(Max: %d)\w",apcost * 36 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 35 && get_user_armor(id) <= ma - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+35\w - \y%i$\w \r(Max: %d)\w",apcost * 35 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 34 && get_user_armor(id) <= ma - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+34\w - \y%i$\w \r(Max: %d)\w",apcost * 34 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 33 && get_user_armor(id) <= ma - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+33\w - \y%i$\w \r(Max: %d)\w",apcost * 33 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 32 && get_user_armor(id) <= ma - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+32\w - \y%i$\w \r(Max: %d)\w",apcost * 32 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 31 && get_user_armor(id) <= ma - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+31\w - \y%i$\w \r(Max: %d)\w",apcost * 31 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 30 && get_user_armor(id) <= ma - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+30\w - \y%i$\w \r(Max: %d)\w",apcost * 30 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 29 && get_user_armor(id) <= ma - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+29\w - \y%i$\w \r(Max: %d)\w",apcost * 29 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 28 && get_user_armor(id) <= ma - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+28\w - \y%i$\w \r(Max: %d)\w",apcost * 28 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 27 && get_user_armor(id) <= ma - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+27\w - \y%i$\w \r(Max: %d)\w",apcost * 27 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 26 && get_user_armor(id) <= ma - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+26\w - \y%i$\w \r(Max: %d)\w",apcost * 26 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 25 && get_user_armor(id) <= ma - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+25\w - \y%i$\w \r(Max: %d)\w",apcost * 25 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 24 && get_user_armor(id) <= ma - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+24\w - \y%i$\w \r(Max: %d)\w",apcost * 24 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 23 && get_user_armor(id) <= ma - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+23\w - \y%i$\w \r(Max: %d)\w",apcost * 23 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 22 && get_user_armor(id) <= ma - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+22\w - \y%i$\w \r(Max: %d)\w",apcost * 22 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 21 && get_user_armor(id) <= ma - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+21\w - \y%i$\w \r(Max: %d)\w",apcost * 21 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 20 && get_user_armor(id) <= ma - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+20\w - \y%i$\w \r(Max: %d)\w",apcost * 20 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 19 && get_user_armor(id) <= ma - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+19\w - \y%i$\w \r(Max: %d)\w",apcost * 19 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 18 && get_user_armor(id) <= ma - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+18\w - \y%i$\w \r(Max: %d)\w",apcost * 18 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 17 && get_user_armor(id) <= ma - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+17\w - \y%i$\w \r(Max: %d)\w",apcost * 17 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 16 && get_user_armor(id) <= ma - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+16\w - \y%i$\w \r(Max: %d)\w",apcost * 16 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 15 && get_user_armor(id) <= ma - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+15\w - \y%i$\w \r(Max: %d)\w",apcost * 15 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 14 && get_user_armor(id) <= ma - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+14\w - \y%i$\w \r(Max: %d)\w",apcost * 14 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 13 && get_user_armor(id) <= ma - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+13\w - \y%i$\w \r(Max: %d)\w",apcost * 13 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 12 && get_user_armor(id) <= ma - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+12\w - \y%i$\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 11 && get_user_armor(id) <= ma - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+11\w - \y%i$\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 10 && get_user_armor(id) <= ma - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+10\w - \y%i$\w \r(Max: %d)\w",apcost * 10 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 9 && get_user_armor(id) <= ma - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+9\w - \y%i$\w \r(Max: %d)\w",apcost * 9 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 8 && get_user_armor(id) <= ma - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+8\w - \y%i$\w \r(Max: %d)\w",apcost * 8 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 7 && get_user_armor(id) <= ma - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+7\w - \y%i$\w \r(Max: %d)\w",apcost * 7 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 6 && get_user_armor(id) <= ma - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+6\w - \y%i$\w \r(Max: %d)\w",apcost * 6 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 5 && get_user_armor(id) <= ma - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+5\w - \y%i$\w \r(Max: %d)\w",apcost * 5 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 4 && get_user_armor(id) <= ma - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+4\w - \y%i$\w \r(Max: %d)\w",apcost * 4 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 3 && get_user_armor(id) <= ma - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+3\w - \y%i$\w \r(Max: %d)\w",apcost * 3 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost * 2 && get_user_armor(id) <= ma - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+2\w - \y%i$\w \r(Max: %d)\w",apcost * 2 ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) >= apcost && get_user_armor(id) <= ma - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+1\w - \y%i$\w \r(Max: %d)\w",apcost ,ma);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(cs_get_user_money(id) < apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r(Max: %d)\w - \y%i$\w ",ma ,apcost * 50);
	menu_additem(menu, buffer, "2", 0);
	}
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \y(%d)\w - \r%i Points\w ",ma ,apcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(PlayerPoints[id] >= apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r(%d)\w - \y%i Points\w ",ma ,apcost);
	menu_additem(menu, buffer, "2", 0);
	}		
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
	}
public hpapshop(id, menu, item) {

	if(item == MENU_EXIT) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key) {
		
//------| Health & Armor |------//
case 1: buy_health(id);
case 2: buy_armor(id);
	default: return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	
//------| Hp & Ap Shop 2 |------//
public hpapcmdShop2(id) {
	new hpcost, apcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_healthcost);
	apcost = get_pcvar_num(vip_armorcost);
	}
	else {
	hpcost = get_pcvar_num(healthcost);
	apcost = get_pcvar_num(armorcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_points_healthcost);
	apcost = get_pcvar_num(vip_points_armorcost);
	}
	else {
	hpcost = get_pcvar_num(points_healthcost);
	apcost = get_pcvar_num(points_armorcost);
	}
	}
	new mh = get_pcvar_num(maxhealth);
	new ma = get_pcvar_num(maxarmor);
	if(get_pcvar_num(armor) == 0 && get_pcvar_num(health) == 0) { 
	}
	else if(get_pcvar_num(armor) == 0 && get_user_health(id) == mh) {
	menu_additem(menu, "\wHealth - \rMax Health\w", "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && get_user_armor(id) == ma) {
	menu_additem(menu, "\wArmor - \rMax Armor\w", "5", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+50\w - \rFree\w \r(Max: %d)\w",hpcost * 50 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+49\w - \rFree\w \r(Max: %d)\w",hpcost * 49 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+48\w - \rFree\w \r(Max: %d)\w",hpcost * 48 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+47\w - \rFree\w \r(Max: %d)\w",hpcost * 47 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+46\w - \rFree\w \r(Max: %d)\w",hpcost * 46 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+45\w - \rFree\w \r(Max: %d)\w",hpcost * 45 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+44\w - \rFree\w \r(Max: %d)\w",hpcost * 44 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+43\w - \rFree\w \r(Max: %d)\w",hpcost * 43 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+42\w - \rFree\w \r(Max: %d)\w",hpcost * 42 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+41\w - \rFree\w \r(Max: %d)\w",hpcost * 41 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+40\w - \rFree\w \r(Max: %d)\w",hpcost * 40 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+39\w - \rFree\w \r(Max: %d)\w",hpcost * 39 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+38\w - \rFree\w \r(Max: %d)\w",hpcost * 38 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+37\w - \rFree\w \r(Max: %d)\w",hpcost * 37 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+36\w - \rFree\w \r(Max: %d)\w",hpcost * 36 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+35\w - \rFree\w \r(Max: %d)\w",hpcost * 35 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+34\w - \rFree\w \r(Max: %d)\w",hpcost * 34 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+33\w - \rFree\w \r(Max: %d)\w",hpcost * 33 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+32\w - \rFree\w \r(Max: %d)\w",hpcost * 32 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+31\w - \rFree\w \r(Max: %d)\w",hpcost * 31 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+30\w - \rFree\w \r(Max: %d)\w",hpcost * 30 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+29\w - \rFree\w \r(Max: %d)\w",hpcost * 29 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+28\w - \rFree\w \r(Max: %d)\w",hpcost * 28 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+27\w - \rFree\w \r(Max: %d)\w",hpcost * 27 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+26\w - \rFree\w \r(Max: %d)\w",hpcost * 26 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+25\w - \rFree\w \r(Max: %d)\w",hpcost * 25 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+24\w - \rFree\w \r(Max: %d)\w",hpcost * 24 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+23\w - \rFree\w \r(Max: %d)\w",hpcost * 23 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+22\w - \rFree\w \r(Max: %d)\w",hpcost * 22 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+21\w - \rFree\w \r(Max: %d)\w",hpcost * 21 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+20\w - \rFree\w \r(Max: %d)\w",hpcost * 20 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+19\w - \rFree\w \r(Max: %d)\w",hpcost * 19 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+18\w - \rFree\w \r(Max: %d)\w",hpcost * 18 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+17\w - \rFree\w \r(Max: %d)\w",hpcost * 17 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+16\w - \rFree\w \r(Max: %d)\w",hpcost * 16 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+15\w - \rFree\w \r(Max: %d)\w",hpcost * 15 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+14\w - \rFree\w \r(Max: %d)\w",hpcost * 14 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+13\w - \rFree\w \r(Max: %d)\w",hpcost * 13 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+12\w - \rFree\w \r(Max: %d)\w",hpcost * 12 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+11\w - \rFree\w \r(Max: %d)\w",hpcost * 11 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+10\w - r%i$\w \r(Max: %d)\w",hpcost * 10 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+9\w - \rFree\w \r(Max: %d)\w",hpcost * 9 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+8\w - \rFree\w \r(Max: %d)\w",hpcost * 8 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+7\w - \rFree\w \r(Max: %d)\w",hpcost * 7 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+6\w - \rFree\w \r(Max: %d)\w",hpcost * 6 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+5\w - \rFree\w \r(Max: %d)\w",hpcost * 5 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+4\w - \rFree\w \r(Max: %d)\w",hpcost * 4 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+3\w - \rFree\w \r(Max: %d)\w",hpcost * 3 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+2\w - \rFree\w \r(Max: %d)\w",hpcost * 2 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && hpcost == 0 && get_user_health(id) <= mh - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+1\w - \rFree\w \r(Max: %d)\w",hpcost ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 50 && get_user_health(id) <= mh - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+50\w - \y%i$\w \r(Max: %d)\w",hpcost * 50 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 49 && get_user_health(id) <= mh - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+49\w - \y%i$\w \r(Max: %d)\w",hpcost * 49 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 48 && get_user_health(id) <= mh - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+48\w - \y%i$\w \r(Max: %d)\w",hpcost * 48 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 47 && get_user_health(id) <= mh - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+47\w - \y%i$\w \r(Max: %d)\w",hpcost * 47 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 46 && get_user_health(id) <= mh - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+46\w - \y%i$\w \r(Max: %d)\w",hpcost * 46 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 45 && get_user_health(id) <= mh - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+45\w - \y%i$\w \r(Max: %d)\w",hpcost * 45 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 44 && get_user_health(id) <= mh - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+44\w - \y%i$\w \r(Max: %d)\w",hpcost * 44 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 43 && get_user_health(id) <= mh - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+43\w - \y%i$\w \r(Max: %d)\w",hpcost * 43 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 42 && get_user_health(id) <= mh - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+42\w - \y%i$\w \r(Max: %d)\w",hpcost * 42 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 41 && get_user_health(id) <= mh - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+41\w - \y%i$\w \r(Max: %d)\w",hpcost * 41 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 40 && get_user_health(id) <= mh - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+40\w - \y%i$\w \r(Max: %d)\w",hpcost * 40 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 39 && get_user_health(id) <= mh - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+39\w - \y%i$\w \r(Max: %d)\w",hpcost * 39 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 38 && get_user_health(id) <= mh - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+38\w - \y%i$\w \r(Max: %d)\w",hpcost * 38 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 37 && get_user_health(id) <= mh - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+37\w - \y%i$\w \r(Max: %d)\w",hpcost * 37 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 36 && get_user_health(id) <= mh - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+36\w - \y%i$\w \r(Max: %d)\w",hpcost * 36 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 35 && get_user_health(id) <= mh - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+35\w - \y%i$\w \r(Max: %d)\w",hpcost * 35 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 34 && get_user_health(id) <= mh - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \w+34\w - \y%i$\w \r(Max: %d)\w",hpcost * 34 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 33 && get_user_health(id) <= mh - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+33\w - \y%i$\w \r(Max: %d)\w",hpcost * 33 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 32 && get_user_health(id) <= mh - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+32\w - \y%i$\w \r(Max: %d)\w",hpcost * 32 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 31 && get_user_health(id) <= mh - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+31\w - \y%i$\w \r(Max: %d)\w",hpcost * 31 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 30 && get_user_health(id) <= mh - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+30\w - \y%i$\w \r(Max: %d)\w",hpcost * 30 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 29 && get_user_health(id) <= mh - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+29\w - \y%i$\w \r(Max: %d)\w",hpcost * 29 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 28 && get_user_health(id) <= mh - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+28\w - \y%i$\w \r(Max: %d)\w",hpcost * 28 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 27 && get_user_health(id) <= mh - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+27\w - \y%i$\w \r(Max: %d)\w",hpcost * 27 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 26 && get_user_health(id) <= mh - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+26\w - \y%i$\w \r(Max: %d)\w",hpcost * 26 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 25 && get_user_health(id) <= mh - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+25\w - \y%i$\w \r(Max: %d)\w",hpcost * 25 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 24 && get_user_health(id) <= mh - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+24\w - \y%i$\w \r(Max: %d)\w",hpcost * 24 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 23 && get_user_health(id) <= mh - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+23\w - \y%i$\w \r(Max: %d)\w",hpcost * 23 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 22 && get_user_health(id) <= mh - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+22\w - \y%i$\w \r(Max: %d)\w",hpcost * 22 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 21 && get_user_health(id) <= mh - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+21\w - \y%i$\w \r(Max: %d)\w",hpcost * 21 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 20 && get_user_health(id) <= mh - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+20\w - \y%i$\w \r(Max: %d)\w",hpcost * 20 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 19 && get_user_health(id) <= mh - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+19\w - \y%i$\w \r(Max: %d)\w",hpcost * 19 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 18 && get_user_health(id) <= mh - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+18\w - \y%i$\w \r(Max: %d)\w",hpcost * 18 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 17 && get_user_health(id) <= mh - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+17\w - \y%i$\w \r(Max: %d)\w",hpcost * 17 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 16 && get_user_health(id) <= mh - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+16\w - \y%i$\w \r(Max: %d)\w",hpcost * 16 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 15 && get_user_health(id) <= mh - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+15\w - \y%i$\w \r(Max: %d)\w",hpcost * 15 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 14 && get_user_health(id) <= mh - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+14\w - \y%i$\w \r(Max: %d)\w",hpcost * 14 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 13 && get_user_health(id) <= mh - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+13\w - \y%i$\w \r(Max: %d)\w",hpcost * 13 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 12 && get_user_health(id) <= mh - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+12\w - \y%i$\w \r(Max: %d)\w",hpcost * 12 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 11 && get_user_health(id) <= mh - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+11\w - \y%i$\w \r(Max: %d)\w",hpcost * 11 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 10 && get_user_health(id) <= mh - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+10\w - \y%i$\w \r(Max: %d)\w",hpcost * 10 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 9 && get_user_health(id) <= mh - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+9\w - \y%i$\w \r(Max: %d)\w",hpcost * 9 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 8 && get_user_health(id) <= mh - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+8\w - \y%i$\w \r(Max: %d)\w",hpcost * 8 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 7 && get_user_health(id) <= mh - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+7\w - \y%i$\w \r(Max: %d)\w",hpcost * 7 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 6 && get_user_health(id) <= mh - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+6\w - \y%i$\w \r(Max: %d)\w",hpcost * 6 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 5 && get_user_health(id) <= mh - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+5\w - \y%i$\w \r(Max: %d)\w",hpcost * 5 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 4 && get_user_health(id) <= mh - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+4\w - \y%i$\w \r(Max: %d)\w",hpcost * 4 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 3 && get_user_health(id) <= mh - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+3\w - \y%i$\w \r(Max: %d)\w",hpcost * 3 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost * 2 && get_user_health(id) <= mh - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+2\w - \y%i$\w \r(Max: %d)\w",hpcost * 2 ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) >= hpcost && get_user_health(id) <= mh - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r+1\w - \y%i$\w \r(Max: %d)\w",hpcost ,mh);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && cs_get_user_money(id) < hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(Max: %d)\w - \y%i$\w ",mh ,hpcost * 50);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+50\w - \rFree\w \r(Max: %d)\w",apcost * 50 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+49\w - \rFree\w \r(Max: %d)\w",apcost * 49 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+48\w - \rFree\w \r(Max: %d)\w",apcost * 48 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+47\w - \rFree\w \r(Max: %d)\w",apcost * 47 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+46\w - \rFree\w \r(Max: %d)\w",apcost * 46 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+45\w - \rFree\w \r(Max: %d)\w",apcost * 45 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+44\w - \rFree\w \r(Max: %d)\w",apcost * 44 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+43\w - \rFree\w \r(Max: %d)\w",apcost * 43 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+42\w - \rFree\w \r(Max: %d)\w",apcost * 42 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+41\w - \rFree\w \r(Max: %d)\w",apcost * 41 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+40\w - \rFree\w \r(Max: %d)\w",apcost * 40 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+39\w - \rFree\w \r(Max: %d)\w",apcost * 39 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+38\w - \rFree\w \r(Max: %d)\w",apcost * 38 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+37\w - \rFree\w \r(Max: %d)\w",apcost * 37 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+36\w - \rFree\w \r(Max: %d)\w",apcost * 36 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+35\w - \rFree\w \r(Max: %d)\w",apcost * 35 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+34\w - \rFree\w \r(Max: %d)\w",apcost * 34 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+33\w - \rFree\w \r(Max: %d)\w",apcost * 33 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+32\w - \rFree\w \r(Max: %d)\w",apcost * 32 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+31\w - \rFree\w \r(Max: %d)\w",apcost * 31 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+30\w - \rFree\w \r(Max: %d)\w",apcost * 30 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+29\w - \rFree\w \r(Max: %d)\w",apcost * 29 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+28\w - \rFree\w \r(Max: %d)\w",apcost * 28 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+27\w - \rFree\w \r(Max: %d)\w",apcost * 27 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+26\w - \rFree\w \r(Max: %d)\w",apcost * 26 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+25\w - \rFree\w \r(Max: %d)\w",apcost * 25 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+24\w - \rFree\w \r(Max: %d)\w",apcost * 24 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+23\w - \rFree\w \r(Max: %d)\w",apcost * 23 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+22\w - \rFree\w \r(Max: %d)\w",apcost * 22 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+21\w - \rFree\w \r(Max: %d)\w",apcost * 21 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+20\w - \rFree\w \r(Max: %d)\w",apcost * 20 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+19\w - \rFree\w \r(Max: %d)\w",apcost * 19 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+18\w - \rFree\w \r(Max: %d)\w",apcost * 18 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+17\w - \rFree\w \r(Max: %d)\w",apcost * 17 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+16\w - \rFree\w \r(Max: %d)\w",apcost * 16 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+15\w - \rFree\w \r(Max: %d)\w",apcost * 15 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+14\w - \rFree\w \r(Max: %d)\w",apcost * 14 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+13\w - \rFree\w \r(Max: %d)\w",apcost * 13 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+12\w - \rFree\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+11\w - \rFree\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+10\w - \rFree\w \r(Max: %d)\w",apcost * 10 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+9\w - \rFree\w \r(Max: %d)\w",apcost * 9 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+8\w - \rFree\w \r(Max: %d)\w",apcost * 8 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+7\w - \rFree\w \r(Max: %d)\w",apcost * 7 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+6\w - \rFree\w \r(Max: %d)\w",apcost * 6 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+5\w - \rFree\w \r(Max: %d)\w",apcost * 5 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+4\w - \rFree\w \r(Max: %d)\w",apcost * 4 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+3\w - \rFree\w \r(Max: %d)\w",apcost * 3 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+2\w - \rFree\w \r(Max: %d)\w",apcost * 2 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && apcost == 0 && get_user_armor(id) <= ma - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+1\w - \rFree\w \r(Max: %d)\w",apcost ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 50 && get_user_armor(id) <= ma - 50) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+50\w - \y%i$\w \r(Max: %d)\w",apcost * 50 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 49 && get_user_armor(id) <= ma - 49) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+49\w - \y%i$\w \r(Max: %d)\w",apcost * 49 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 48 && get_user_armor(id) <= ma - 48) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+48\w - \y%i$\w \r(Max: %d)\w",apcost * 48 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 47 && get_user_armor(id) <= ma - 47) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+47\w - \y%i$\w \r(Max: %d)\w",apcost * 47 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 46 && get_user_armor(id) <= ma - 46) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+46\w - \y%i$\w \r(Max: %d)\w",apcost * 46 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 45 && get_user_armor(id) <= ma - 45) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+45\w - \y%i$\w \r(Max: %d)\w",apcost * 45 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 44 && get_user_armor(id) <= ma - 44) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+44\w - \y%i$\w \r(Max: %d)\w",apcost * 44 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 43 && get_user_armor(id) <= ma - 43) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+43\w - \y%i$\w \r(Max: %d)\w",apcost * 43 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 42 && get_user_armor(id) <= ma - 42) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+42\w - \y%i$\w \r(Max: %d)\w",apcost * 42 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 41 && get_user_armor(id) <= ma - 41) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+41\w - \y%i$\w \r(Max: %d)\w",apcost * 41 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 40 && get_user_armor(id) <= ma - 40) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+40\w - \y%i$\w \r(Max: %d)\w",apcost * 40 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 39 && get_user_armor(id) <= ma - 39) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+39\w - \y%i$\w \r(Max: %d)\w",apcost * 39 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 38 && get_user_armor(id) <= ma - 38) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+38\w - \y%i$\w \r(Max: %d)\w",apcost * 38 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 37 && get_user_armor(id) <= ma - 37) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+37\w - \y%i$\w \r(Max: %d)\w",apcost * 37 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 36 && get_user_armor(id) <= ma - 36) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+36\w - \y%i$\w \r(Max: %d)\w",apcost * 36 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 35 && get_user_armor(id) <= ma - 35) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+35\w - \y%i$\w \r(Max: %d)\w",apcost * 35 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 34 && get_user_armor(id) <= ma - 34) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+34\w - \y%i$\w \r(Max: %d)\w",apcost * 34 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 33 && get_user_armor(id) <= ma - 33) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+33\w - \y%i$\w \r(Max: %d)\w",apcost * 33 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 32 && get_user_armor(id) <= ma - 32) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+32\w - \y%i$\w \r(Max: %d)\w",apcost * 32 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 31 && get_user_armor(id) <= ma - 31) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+31\w - \y%i$\w \r(Max: %d)\w",apcost * 31 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 30 && get_user_armor(id) <= ma - 30) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+30\w - \y%i$\w \r(Max: %d)\w",apcost * 30 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 29 && get_user_armor(id) <= ma - 29) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+29\w - \y%i$\w \r(Max: %d)\w",apcost * 29 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 28 && get_user_armor(id) <= ma - 28) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+28\w - \y%i$\w \r(Max: %d)\w",apcost * 28 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 27 && get_user_armor(id) <= ma - 27) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+27\w - \y%i$\w \r(Max: %d)\w",apcost * 27 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 26 && get_user_armor(id) <= ma - 26) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+26\w - \y%i$\w \r(Max: %d)\w",apcost * 26 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 25 && get_user_armor(id) <= ma - 25) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+25\w - \y%i$\w \r(Max: %d)\w",apcost * 25 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 24 && get_user_armor(id) <= ma - 24) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+24\w - \y%i$\w \r(Max: %d)\w",apcost * 24 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 23 && get_user_armor(id) <= ma - 23) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+23\w - \y%i$\w \r(Max: %d)\w",apcost * 23 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 22 && get_user_armor(id) <= ma - 22) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+22\w - \y%i$\w \r(Max: %d)\w",apcost * 22 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 21 && get_user_armor(id) <= ma - 21) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+21\w - \y%i$\w \r(Max: %d)\w",apcost * 21 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 20 && get_user_armor(id) <= ma - 20) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+20\w - \y%i$\w \r(Max: %d)\w",apcost * 20 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 19 && get_user_armor(id) <= ma - 19) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+19\w - \y%i$\w \r(Max: %d)\w",apcost * 19 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 18 && get_user_armor(id) <= ma - 18) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+18\w - \y%i$\w \r(Max: %d)\w",apcost * 18 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 17 && get_user_armor(id) <= ma - 17) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+17\w - \y%i$\w \r(Max: %d)\w",apcost * 17 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 16 && get_user_armor(id) <= ma - 16) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+16\w - \y%i$\w \r(Max: %d)\w",apcost * 16 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 15 && get_user_armor(id) <= ma - 15) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+15\w - \y%i$\w \r(Max: %d)\w",apcost * 15 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 14 && get_user_armor(id) <= ma - 14) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+14\w - \y%i$\w \r(Max: %d)\w",apcost * 14 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 13 && get_user_armor(id) <= ma - 13) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+13\w - \y%i$\w \r(Max: %d)\w",apcost * 13 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 12 && get_user_armor(id) <= ma - 12) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+12\w - \y%i$\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 11 && get_user_armor(id) <= ma - 11) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+11\w - \y%i$\w \r(Max: %d)\w",apcost * 11 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 10 && get_user_armor(id) <= ma - 10) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+10\w - \y%i$\w \r(Max: %d)\w",apcost * 10 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 9 && get_user_armor(id) <= ma - 9) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+9\w - \y%i$\w \r(Max: %d)\w",apcost * 9 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 8 && get_user_armor(id) <= ma - 8) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+8\w - \y%i$\w \r(Max: %d)\w",apcost * 8 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 7 && get_user_armor(id) <= ma - 7) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+7\w - \y%i$\w \r(Max: %d)\w",apcost * 7 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 6 && get_user_armor(id) <= ma - 6) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+6\w - \y%i$\w \r(Max: %d)\w",apcost * 6 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 5 && get_user_armor(id) <= ma - 5) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+5\w - \y%i$\w \r(Max: %d)\w",apcost * 5 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 4 && get_user_armor(id) <= ma - 4) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+4\w - \y%i$\w \r(Max: %d)\w",apcost * 4 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 3 && get_user_armor(id) <= ma - 3) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+3\w - \y%i$\w \r(Max: %d)\w",apcost * 3 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost * 2 && get_user_armor(id) <= ma - 2) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+2\w - \y%i$\w \r(Max: %d)\w",apcost * 2 ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) >= apcost && get_user_armor(id) <= ma - 1) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r+1\w - \y%i$\w \r(Max: %d)\w",apcost ,ma);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && cs_get_user_money(id) < apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r(Max: %d)\w - \y%i$\w ",ma ,apcost * 50);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_user_health(id) == get_pcvar_num(maxhealth) && get_user_armor(id) == get_pcvar_num(maxarmor)) {
	menu_additem(menu, "\wHealth and Armor - \rFull HP/AP\w", "5", 0);
	}
	else { 
	menu_additem(menu, "\wHealth and Armor - \rSubMenu\w", "5", 0);
	}
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(armor) == 0 && PlayerPoints[id] < hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \y(%d)\w - \r%i Points\w ",mh ,hpcost * 50);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(armor) == 0 && PlayerPoints[id] >= hpcost && get_user_health(id) <= mh) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wHealth \r(%d)\w - \y%i Points\w ",mh ,hpcost);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && PlayerPoints[id] < apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \y(%d)\w - \r%i Points\w ",ma ,apcost * 50);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_pcvar_num(health) == 0 && PlayerPoints[id] >= apcost && get_user_armor(id) < ma) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wArmor \r(%d)\w - \y%i Points\w ",ma ,apcost);
	menu_additem(menu, buffer, "5", 0);
	}
	else if(get_user_health(id) == get_pcvar_num(maxhealth) && get_user_armor(id) == get_pcvar_num(maxarmor)) {
	menu_additem(menu, "\wHealth and Armor - \rFull HP/AP\w", "5", 0);
	}
	else { 
	menu_additem(menu, "\wHealth and Armor - \rSubMenu\w", "5", 0);
	}
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gravity & Speed Menu |
//==========================================================================================================
public grspcmdShop(id) { 
	new grcost, spcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_gravitycost);
	spcost = get_pcvar_num(vip_speedcost);
	}
	else {
	grcost = get_pcvar_num(gravitycost);
	spcost = get_pcvar_num(speedcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_points_gravitycost);
	spcost = get_pcvar_num(vip_points_speedcost);
	}
	else {
	grcost = get_pcvar_num(points_gravitycost);
	spcost = get_pcvar_num(points_speedcost);
	}
	}
	new bani = cs_get_user_money(id);
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	new buffer2[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rGravity and Speed\w \yVIP\w^n\rMoney:\w \y%i$\w",bani);
	menu = menu_create(buffer2, "grspshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer2,sizeof(buffer2)-1,"\rGravity and Speed\w \yVIP\w^n\rPoints:\w \y%i\w",PlayerPoints[id]);
	menu = menu_create(buffer2, "grspshop");
	}
	}
	else {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\rGravity and Speed\w^n\rMoney:\w \y%i$\w",bani);
	menu = menu_create(buffer, "grspshop");
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\rGravity and Speed\w^n\rPoints:\w \y%i\w",PlayerPoints[id]);
	menu = menu_create(buffer, "grspshop");
	}
	}
	if(get_pcvar_num(gravity) == 0 && get_pcvar_num(speed) == 0) {
	ColorChat(id, "^x03%s^x03 Gravity & Speed^x04 este^x03 Dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
//------| Gravity |------//
	if(get_pcvar_num(gravity) == 0) { 
	}
	else if(!g_hasGravity[id] && grcost == 0 && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \rFree\w");
	menu_additem(menu, buffer, "1", 0);
	}
	else if(!g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wGravity - \rAlready Have\w", "1", 0);
	}
	else if(!g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	if(get_pcvar_num(deathrunshopmod) == 0) {
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \y%i$\w",grcost);
	menu_additem(menu, buffer, "1", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \y%i Points\w",grcost);
	menu_additem(menu, buffer, "1", 0);
	}
	}
	else if(g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wStop Gravity - \rSwitch\w", "1", 0);
	}
	else if(g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wPlay Gravity - \rSwitch\w", "1", 0);
	}
	
//------| Speed |------//
	if(get_pcvar_num(speed) == 0) { 
	}
	else if(!g_hasSpeed[id] && spcost == 0 && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSpeed - \rFree\w",spcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(!g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wSpeed - \rAlready Have\w", "2", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) == 0) {
	if(!g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSpeed - \y%i$\w",spcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wStop Speed - \rSwitch\w", "2", 0);
	}
	else if(g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wPlay Speed - \rSwitch\w", "2", 0);
	}
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	if(!g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSpeed - \y%i Points\w",spcost);
	menu_additem(menu, buffer, "2", 0);
	}
	else if(g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wStop Speed - \rSwitch\w", "2", 0);
	}
	else if(g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wPlay Speed - \rSwitch\w", "2", 0);
	}
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
	}
public grspshop(id, menu, item) {

	if(item == MENU_EXIT) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key) {
		
//------| Gravity & Speed |------//
case 1: buy_gravity(id);
case 2: buy_speed(id);
	default: return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}

public grspcmdShop2(id) {
	new grcost, spcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_gravitycost);
	spcost = get_pcvar_num(vip_speedcost);
	}
	else {
	grcost = get_pcvar_num(gravitycost);
	spcost = get_pcvar_num(speedcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_points_gravitycost);
	spcost = get_pcvar_num(vip_points_speedcost);
	}
	else {
	grcost = get_pcvar_num(points_gravitycost);
	spcost = get_pcvar_num(points_speedcost);
	}
	}
	if(get_pcvar_num(gravity) == 0 && get_pcvar_num(speed) == 0) { 
	}
	else if(get_pcvar_num(speed) == 0 && !g_hasGravity[id] && grcost == 0 && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \rFree\w");
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&!g_hasGravity[id] && grcost == 0 && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \rFree\w");
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&!g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wSpeed - \rAlready Have\w", "6", 0);
	}
	else if(get_pcvar_num(speed) == 0 && !g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wGravity - \rAlready Have\w", "6", 0);
	}
	else if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(speed) == 0 && !g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \y%i$\w",grcost);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(speed) == 0 && g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wStop Gravity - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(speed) == 0 && g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wPlay Gravity - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&!g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSpeed - \y%i$\w",spcost);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wStop Speed - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wPlay Speed - \rSwitch\w", "6", 0);
	}
	else { 
	menu_additem(menu, "\wGravity and Speed - \rSubMenu\w", "6", 0);
	}
	}
	else if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(speed) == 0 && !g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wGravity - \y%i Points\w",grcost);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(speed) == 0 && g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wStop Gravity - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(speed) == 0 && g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	menu_additem(menu, "\wPlay Gravity - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&!g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	new buffer[256];
	formatex(buffer,sizeof(buffer)-1,"\wSpeed - \y%i Points\w",spcost);
	menu_additem(menu, buffer, "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wStop Speed - \rSwitch\w", "6", 0);
	}
	else if(get_pcvar_num(gravity) == 0 &&g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	menu_additem(menu, "\wPlay Speed - \rSwitch\w", "6", 0);
	}
	else { 
	menu_additem(menu, "\wGravity and Speed - \rSubMenu\w", "6", 0);
	}
	}
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Chat and Console Commands |
//==========================================================================================================
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Parachute Commands |
//==========================================================================================================
//------| Buy Parachute |------//
public buy_parachute(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new pcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	pcost = get_pcvar_num(vip_parachutecost);
	}
	else {
	pcost = get_pcvar_num(parachutecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	pcost = get_pcvar_num(vip_points_parachutecost);
	}
	else {
	pcost = get_pcvar_num(points_parachutecost);
	}
	}
	if(get_pcvar_num(parachute) == 0) { 
	ColorChat(id, "^x03%s Parachuta^x04 este Dezactivata.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_parachute) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Paracuhte^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Parachuta^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(has_parachute[id]) {
	ColorChat(id, "^x03%s^x04 Ai deja o^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < pcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Parachuta^x04. Necesari:^x03 %i$",Prefix,pcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_parachute[id]) {
	cs_set_user_money(id, bani - pcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o^x03 Parachuta^x04.Pentru utilizare apasa tasta^x03 E.",Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = true;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < pcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Parachuta^x04. Necesare:^x03 %i Puncte",Prefix,pcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!has_parachute[id]) {
	PlayerPoints[id] -= pcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat o^x03 Parachuta^x04.Pentru utilizare apasa tasta^x03 E.",Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = true;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Sell Parachute |------//
public sell_parachute(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new sellp;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellp = get_pcvar_num(vip_sellparachute);
	}
	else { 
	sellp = get_pcvar_num(sellparachute);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellp = get_pcvar_num(vip_points_sellparachute);
	}
	else { 
	sellp = get_pcvar_num(points_sellparachute);
	}
	}
	if(!has_parachute[id]) {
	ColorChat(id, "^x03%s^x04 Nu ai o^x03 Parachuta.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(has_parachute[id]) {
	cs_set_user_money(id, cs_get_user_money(id) + sellp);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Parachuta^x04,ai primit^x03 %i$.",Prefix,sellp);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = false;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(has_parachute[id]) {
	PlayerPoints[id] += sellp;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 Parachuta^x04,ai primit^x03 %i Puncte.",Prefix,sellp);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	has_parachute[id] = false;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Parachute |------//
public give_parachute(id, level, cid) {
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
	if(!has_parachute[players]) {
	has_parachute[players] = true;
	emit_sound(players,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Parachute^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Parachute^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!has_parachute[players]) {
	has_parachute[players] = true;
	emit_sound(players,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Parachute^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Parachute^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!has_parachute[players]) {
	has_parachute[players] = true;
	emit_sound(players,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Parachute^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Parachute^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!has_parachute[player]) {
	has_parachute[player] = true;
	emit_sound(player,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you ^x03 Parachute.");
	case 2: ColorChat(player, "^x03%s^x04 give you ^x03 Parachute.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Take Parachute |------//
public take_parachute(id, level, cid) {
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
	if(has_parachute[players]) {
	has_parachute[players] = false;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Parachute^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Parachute^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(has_parachute[players]) {
	has_parachute[players] = false;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Parachute^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Parachute^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(has_parachute[players]) {
	has_parachute[players] = false;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 Parachute^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 Parachute^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(has_parachute[player]) {
	has_parachute[player] = false;
	emit_sound(player,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 take your ^x03 Parachute.");
	case 2: ColorChat(player, "^x03%s^x04 take your ^x03 Parachute.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LongJump Commands |
//==========================================================================================================
//------| Buy LongJump |------//
public buy_longjump(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new ljcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ljcost = get_pcvar_num(vip_longjumpcost);
	}
	else {
	ljcost = get_pcvar_num(longjumpcost);	
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ljcost = get_pcvar_num(vip_points_longjumpcost);
	}
	else {
	ljcost = get_pcvar_num(points_longjumpcost);	
	}
	}
	if(get_pcvar_num(longjump) == 0) {
	ColorChat(id, "^x03%s LongJump^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_longjump) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 LongJump^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 LongJump^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasLongJump[id]) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < ljcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 LongJump^x04. Necesari:^x03 %i$",Prefix,ljcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasLongJump[id]) {
	cs_set_user_money(id,bani - ljcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 LongJump^x04.Pentru utilizare apasa^x03 Ctrl+Space.",Prefix);
	emit_sound(id,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 1);
	g_hasLongJump[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < ljcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 LongJump^x04. Necesari:^x03 %i$",Prefix,ljcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasLongJump[id]) {
	PlayerPoints[id] -= ljcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 LongJump^x04.Pentru utilizare apasa^x03 Ctrl+Space.",Prefix);
	emit_sound(id,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_longjump(id, 1);
	g_hasLongJump[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Sell Longjump |------//
public sell_longjump(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new selllj;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	selllj = get_pcvar_num(vip_selllongjump);
	}
	else {
	selllj = get_pcvar_num(selllongjump);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	selllj = get_pcvar_num(vip_points_selllongjump);
	}
	else {
	selllj = get_pcvar_num(points_selllongjump);
	}
	}
	if(!g_hasLongJump[id]) {
	ColorChat(id, "^x03%s^x04 Nu ai^x03 LongJump.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(g_hasLongJump[id]) {
	cs_set_user_money(id, cs_get_user_money(id) + selllj);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 LongJump^x04,ai primit^x03 %i$.",Prefix,selllj);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasLongJump[id] = 0;
	set_user_longjump(id, 0);
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(g_hasLongJump[id]) {
	PlayerPoints[id] += selllj;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 LongJump^x04,ai primit^x03 %i Puncte.",Prefix,selllj);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasLongJump[id] = 0;
	set_user_longjump(id, 0);
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give LongJump |------//
public give_longjump(id, level, cid) {
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
	if(!g_hasLongJump[players]) {
	set_user_longjump(players, 1);
	g_hasLongJump[players] = 1;
	emit_sound(players,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 LongJump^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 LongJump^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasLongJump[players]) {
	set_user_longjump(players, 1);
	g_hasLongJump[players] = 1;
	emit_sound(players,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 LongJump^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 LongJump^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasLongJump[players]) {
	set_user_longjump(players, 1);
	g_hasLongJump[players] = 1;
	emit_sound(players,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 LongJump^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 LongJump^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasLongJump[player]) {
	set_user_longjump(player, 1);
	g_hasLongJump[player] = 1;
	emit_sound(player,CHAN_ITEM,LJ_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 LongJump.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 LongJump.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Take LongJump |------//
public take_longjump(id, level, cid) {
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
	if(g_hasLongJump[players]) {
	set_user_longjump(players, 0);
	g_hasLongJump[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 LongJump^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 LongJump^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(g_hasLongJump[players]) {
	set_user_longjump(players, 0);
	g_hasLongJump[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 LongJump^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 LongJump^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(g_hasLongJump[players]) {
	set_user_longjump(players, 0);
	g_hasLongJump[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 LongJump^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 ^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(g_hasLongJump[player]) {
	set_user_longjump(player, 0);
	g_hasLongJump[player] = 0;
	emit_sound(player,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 take your^x03 LongJump.");
	case 2: ColorChat(player, "^x03%s^x04 take your^x03 LongJump.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life Commands |
//==========================================================================================================
//------| Buy Life |------//
public buy_life(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new lcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_lifecost);
	}
	else {
	lcost = get_pcvar_num(lifecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
// Grenades Commands |
//==========================================================================================================
//------| Buy Grenades |------//
public buy_grenade(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new hecost, flashcost, smokecost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hecost = get_pcvar_num(vip_hegrenadecost);
	flashcost = get_pcvar_num(vip_flashbangcost);
	smokecost = get_pcvar_num(vip_smokegrenadecost);
	}
	else{ 
	hecost = get_pcvar_num(hegrenadecost);
	flashcost = get_pcvar_num(flashbangcost);
	smokecost = get_pcvar_num(smokegrenadecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hecost = get_pcvar_num(vip_points_hegrenadecost);
	flashcost = get_pcvar_num(vip_points_flashbangcost);
	smokecost = get_pcvar_num(vip_points_smokegrenadecost);
	}
	else{ 
	hecost = get_pcvar_num(points_hegrenadecost);
	flashcost = get_pcvar_num(points_flashbangcost);
	smokecost = get_pcvar_num(points_smokegrenadecost);
	}
	}
	if(get_pcvar_num(grenades) == 0) { 
	ColorChat(id, "^x03%s Grenazi^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_grenades) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Grenazi.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_grenades) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Grenazi.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_grenades) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Grenazi.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Grenazi^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Grenazi^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Grenazi^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon (id, CSW_HEGRENADE) && user_has_weapon (id, CSW_FLASHBANG) && user_has_weapon (id, CSW_SMOKEGRENADE)) {
	ColorChat(id, "^x03%s^x04 Ai deja toate^x03 Grenazile.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE) && bani < hecost + flashcost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Grenazi^x04. Necesari:^x03 %i$",Prefix,hecost + flashcost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && bani < hecost + flashcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Grenazi^x04. Necesari:^x03 %i$",Prefix,hecost + flashcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE) && bani < hecost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Grenazi^x04. Necesari:^x03 %i$",Prefix,hecost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE) && bani < flashcost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 3Grenazi^x04. Necesari:^x03 %i$",Prefix,flashcost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && bani < hecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 HE^x04. Necesari:^x03 %i$",Prefix,hecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_FLASHBANG) && bani < flashcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Flash^x04. Necesari:^x03 %i$",Prefix,flashcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_SMOKEGRENADE) && bani < smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Smoke^x04. Necesari:^x03 %i$",Prefix,smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	grenadetask(id);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE) && PlayerPoints[id] < hecost + flashcost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 Grenazi^x04. Necesare:^x03 %i Puncte",Prefix,hecost + flashcost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && PlayerPoints[id] < hecost + flashcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 Grenazi^x04. Necesare:^x03 %i Puncte",Prefix,hecost + flashcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE) && PlayerPoints[id] < hecost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 Grenazi^x04. Necesare:^x03 %i Puncte",Prefix,hecost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE) && PlayerPoints[id] < flashcost + smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 3Grenazi^x04. Necesare:^x03 %i Puncte",Prefix,flashcost + smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_HEGRENADE) && PlayerPoints[id] < hecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 HE^x04. Necesare:^x03 %i Puncte",Prefix,hecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_FLASHBANG) && PlayerPoints[id] < flashcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru^x03 Flash^x04. Necesare:^x03 %i Puncte",Prefix,flashcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon (id, CSW_SMOKEGRENADE) && PlayerPoints[id] < smokecost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru^x03 Smoke^x04. Necesare:^x03 %i Puncte",Prefix,smokecost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	grenadetask(id);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}

//------| Give Grenades |------//
public give_grenade(id, level, cid) {
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
	give_item(players,"weapon_hegrenade");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_smokegrenade");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 Ts");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 Ts", name);
	}
	}
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	give_item(players,"weapon_hegrenade");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_smokegrenade");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	give_item(players,"weapon_hegrenade");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_flashbang");
	give_item(players,"weapon_smokegrenade");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 HE|Flash|Smoke^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	give_item(player,"weapon_hegrenade");
	give_item(player,"weapon_flashbang");
	give_item(player,"weapon_flashbang");
	give_item(player,"weapon_smokegrenade");
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 HE|Flash|Smoke.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 HE|Flash|Smoke.", name);
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Health Commands |
//==========================================================================================================
//------| Buy Health |------//
public buy_health(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new mh = get_pcvar_num(maxhealth);
	new hpcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_healthcost);
	}
	else {
	hpcost = get_pcvar_num(healthcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(acces_healtharmor) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Health.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_healtharmor) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Health.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_healtharmor) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < hpcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Health^x04. Necesari:^x03 %i$",Prefix,hpcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	healthtask(id);
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
// Armor Commands |
//==========================================================================================================
//------| Buy Armor |------//
public buy_armor(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new ma = get_pcvar_num(maxarmor);
	new apcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	apcost = get_pcvar_num(vip_armorcost);
	}
	else {
	apcost = get_pcvar_num(armorcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	apcost = get_pcvar_num(vip_points_armorcost);
	}
	else {
	apcost = get_pcvar_num(points_armorcost);
	}
	}
	if(get_pcvar_num(armor) == 0) { 
	ColorChat(id, "^x03%s Armura^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_healtharmor) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Armura.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_healtharmor) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Armura.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_healtharmor) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Armura.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Armura^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Armura^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Armura^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_user_armor(id) == ma) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 %d AP.",Prefix, ma);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < apcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Armura^x04. Necesari:^x03 %i$",Prefix,apcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	armortask(id);
	emit_sound(id,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < apcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Armura^x04. Necesari:^x03 %i$",Prefix,apcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= apcost;
	ColorChat(id, "^x03%s^x04 Ai^x03 %d AP.",Prefix, ma);
	cs_set_user_armor(id, ma, CS_ARMOR_VESTHELM);
	emit_sound(id,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Armor |------//
public give_armor(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
	return PLUGIN_HANDLED;
	}
	new ma = get_pcvar_num(maxarmor);
	new arg[23], gplayers[32], num, i, players, name[32];
	get_user_name(id, name, 31);
	read_argv(1, arg, 23);
	if(equali(arg, "@T")) {
	get_players(gplayers, num, "e", "TERRORIST");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_armor(players) < ma) {
	cs_set_user_armor(players, get_pcvar_num(maxarmor), CS_ARMOR_VESTHELM);
	emit_sound(players,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d AP^x04 to all^x03 Ts.",ma);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d AP^x04 to all^x03 Ts.", name ,ma);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_armor(players) < ma) {
	cs_set_user_armor(players, get_pcvar_num(maxarmor), CS_ARMOR_VESTHELM);
	emit_sound(players,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d AP^x04 to all^x03 CTs.",ma);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d AP^x04 to all^x03 CTs.", name ,ma);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(get_user_armor(players) < ma) {
	cs_set_user_armor(players, get_pcvar_num(maxarmor), CS_ARMOR_VESTHELM);
	emit_sound(players,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, players);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 set^x03 %d AP^x04 to all^x03 Players.",ma);
	case 2: ColorChat(0, "^x03%s^x04 set^x03 %d AP^x04 to all^x03 Players.", name ,ma);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(get_user_armor(player) < ma) {
	cs_set_user_armor(player, get_pcvar_num(maxarmor), CS_ARMOR_VESTHELM);
	emit_sound(player,CHAN_ITEM,AP_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, player);
	write_string("suithelmet_full");
	write_byte(0);
	write_byte(200);
	write_byte(200);
	message_end();
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 %d AP.",ma);
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 %d AP.", name ,ma);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gravity Commands |
//==========================================================================================================
//------| Buy Gravity |------//
public buy_gravity(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new grcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_gravitycost);
	}
	else {
	grcost = get_pcvar_num(gravitycost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	grcost = get_pcvar_num(vip_points_gravitycost);
	}
	else {
	grcost = get_pcvar_num(points_gravitycost);
	}
	}
	if(get_pcvar_num(gravity) == 0) { 
	ColorChat(id, "^x03%s Gravity^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasGravity[id] && !hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	ColorChat(id, "^x03%s^x04 Detii deja^x03 Gravity^x04 din alte surse.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gravity^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Gravity^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasGravity[id] && get_user_gravity(id) <= get_pcvar_float(lowgravity)) {
	ColorChat(id, "^x03%s^x04 Ai oprit^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_gravity(id, 0.7);
	remove_task(id);
	hasGravity[id] = 0;
	Screen3(id);
	return PLUGIN_HANDLED;
	}
	if(g_hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	ColorChat(id, "^x03%s^x04 Ai pornit^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_gravity(id, get_pcvar_float(lowgravity));
	hasGravity[id] = 1;
	Screen3(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < grcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gravity^x04. Necesari:^x03 %i$",Prefix,grcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasGravity[id] && !hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	cs_set_user_money(id, bani - grcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_gravity(id, get_pcvar_float(lowgravity));
	g_hasGravity[id] = 1;
	hasGravity[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < grcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gravity^x04. Necesare:^x03 %i Puncte",Prefix,grcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasGravity[id] && !hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	PlayerPoints[id] -= grcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Gravity.",Prefix);
	emit_sound(id,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_gravity(id, get_pcvar_float(lowgravity));
	g_hasGravity[id] = 1;
	hasGravity[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Gravity |------//
public give_gravity(id, level, cid) {
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
	if(!g_hasGravity[players]) {
	set_user_gravity(players, get_pcvar_float(lowgravity));
	g_hasGravity[players] = 1;
	hasGravity[players] = 1;
	emit_sound(players,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Gravity^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Gravity^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasGravity[players]) {
	set_user_gravity(players, get_pcvar_float(lowgravity));
	g_hasGravity[players] = 1;
	hasGravity[players] = 1;
	emit_sound(players,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Gravity^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Gravity^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasGravity[players]) {
	set_user_gravity(players, get_pcvar_float(lowgravity));
	g_hasGravity[players] = 1;
	hasGravity[players] = 1;
	emit_sound(players,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Gravity^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Gravity^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasGravity[player]) {
	set_user_gravity(player, get_pcvar_float(lowgravity));
	g_hasGravity[player] = 1;
	hasGravity[player] = 1;
	emit_sound(player,CHAN_ITEM,GRAVTIY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Gravity.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Gravity.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Speed Commands |
//==========================================================================================================
//------| Buy Speed |------//
public buy_speed(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new spcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	spcost = get_pcvar_num(vip_speedcost);
	}
	else {
	spcost = get_pcvar_num(speedcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	spcost = get_pcvar_num(vip_points_speedcost);
	}
	else {
	spcost = get_pcvar_num(points_speedcost);
	}
	}
	if(get_pcvar_num(speed) == 0) { 
	ColorChat(id, "^x03%s Speed^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasSpeed[id] && !hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_float(highspeed)) {
	ColorChat(id, "^x03%s^x04 Detii deja^x03 Speed^x04 din alte surse.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_gravityspeed) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id,  "^x03%s^x04 Nu poti cumpara^x03 Speed^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Speed^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasSpeed[id] && get_user_maxspeed(id) >= get_pcvar_num(highspeed)) {
	ColorChat(id, "^x03%s^x04 Ai oprit^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_maxspeed(id, (get_user_maxspeed(id) / get_user_maxspeed(id) * 250));
	hasSpeed[id] = 0;
	Screen3(id);
	return PLUGIN_HANDLED;
	}
	if(g_hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_num(highspeed)) {
	ColorChat(id, "^x03%s^x04 Ai pornit^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	hasSpeed[id] = 1;
	Screen3(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < spcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Speed^x04. Necesari:^x03 %i$",Prefix,spcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasSpeed[id] && !hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	cs_set_user_money(id, bani - spcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	g_hasSpeed[id] = 1;
	hasSpeed[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < spcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Speed^x04. Necesare:^x03 %i Puncte",Prefix,spcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasSpeed[id] && !hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	PlayerPoints[id] -= spcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Speed.",Prefix);
	emit_sound(id,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	g_hasSpeed[id] = 1;
	hasSpeed[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Speed |------//
public give_speed(id, level, cid) {
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
	if(!g_hasSpeed[players]) {
	set_user_maxspeed(players, get_pcvar_float(highspeed));
	g_hasSpeed[players] = 1;
	hasSpeed[players] = 1;
	emit_sound(players,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Speed^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Speed^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasSpeed[players]) {
	set_user_maxspeed(players, get_pcvar_float(highspeed));
	g_hasSpeed[players] = 1;
	hasSpeed[players] = 1;
	emit_sound(players,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Speed^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Speed^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasSpeed[players]) {
	set_user_maxspeed(players, get_pcvar_float(highspeed));
	g_hasSpeed[players] = 1;
	hasSpeed[players] = 1;
	emit_sound(players,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Speed^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Speed^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasSpeed[player]) {
	set_user_maxspeed(player, get_pcvar_float(highspeed));
	g_hasSpeed[player] = 1;
	hasSpeed[player] = 1;
	emit_sound(player,CHAN_ITEM,SPEED_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Speed.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Speed.", name);
	}
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deagle Commands |
//==========================================================================================================
//------| Buy Deagle |------//
public buy_superdeagle(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new dgcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	dgcost = get_pcvar_num(vip_dglcost);
	}
	else {
	dgcost = get_pcvar_num(dglcost);	
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	dgcost = get_pcvar_num(vip_points_dglcost);
	}
	else {
	dgcost = get_pcvar_num(points_dglcost);	
	}
	}
	if(get_pcvar_num(deagle) == 0) { 
	ColorChat(id, "^x03%s Deagle^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Deagle^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < dgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Deagle^x04. Necesari:^x03 %i$",Prefix,dgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - dgcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < dgcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Deagle^x04. Necesare:^x03 %i Puncte",Prefix,dgcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	PlayerPoints[id] -= dgcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat un^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	give_item(id, "weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Deagle |------//
public give_dgl(id, level, cid) {
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
	if(!user_has_weapon(players, CSW_DEAGLE)) {
	give_item(players, "weapon_deagle");
	cs_set_user_bpammo(players, CSW_DEAGLE, 7);
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Desert Eagle^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Desert Eagle^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_DEAGLE)) {
	give_item(players, "weapon_deagle");
	cs_set_user_bpammo(players, CSW_DEAGLE, 7);
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Desert Eagle^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Desert Eagle^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!user_has_weapon(players, CSW_DEAGLE)) {
	give_item(players, "weapon_deagle");
	cs_set_user_bpammo(players, CSW_DEAGLE, 7);
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Desert Eagle^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Desert Eagle^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!user_has_weapon(player, CSW_DEAGLE)) {
	give_item(player, "weapon_deagle");
	cs_set_user_bpammo(player, CSW_DEAGLE, 7);
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Desert Eagle.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Desert Eagle.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Buy Deagle AMMO |------//
public buy_ammo(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new adcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	adcost = get_pcvar_num(vip_deagleammocost);
	}	
	else {
	adcost = get_pcvar_num(deagleammocost);	
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	adcost = get_pcvar_num(vip_points_deagleammocost);
	}	
	else {
	adcost = get_pcvar_num(points_deagleammocost);	
	}
	}
	if(get_pcvar_num(deagle) == 0) { 
	ColorChat(id, "^x03%s Deagle Ammo^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_deagle) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
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
	if(user_has_weapon(id, CSW_DEAGLE) && cs_get_user_bpammo(id, CSW_DEAGLE)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Gloante.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < adcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Gloante^x04. Necesari:^x03 %i$",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	cs_set_user_money(id, bani - adcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < adcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Gloante^x04. Necesare:^x03 %i Puncte",Prefix,adcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(user_has_weapon(id, CSW_DEAGLE) && !cs_get_user_bpammo(id, CSW_DEAGLE)) {
	PlayerPoints[id] -= adcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 gloante^x04 la^x03 Deagle.",Prefix);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	cs_set_user_bpammo(id, CSW_DEAGLE, 7);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NoClip Commands |
//==========================================================================================================
//------| Buy NoClip |------//
public buy_noclip(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new nctime = get_pcvar_num(nocliptime);
	new ncost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	ncost = get_pcvar_num(vip_noclipcost);
	}
	else {
	ncost = get_pcvar_num(noclipcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
// NightVision Commands |
//==========================================================================================================
//------| Buy NightVision |------//
public buy_nightvision(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new nvcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	nvcost = get_pcvar_num(vip_nightvisioncost);
	}
	else {
	nvcost = get_pcvar_num(nightvisioncost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	nvcost = get_pcvar_num(vip_points_nightvisioncost);
	}
	else {
	nvcost = get_pcvar_num(points_nightvisioncost);
	}
	}
	if(cs_get_user_nvg(id) && !g_hasNightVision[id]) {
	ColorChat(id, "^x03%s^x04 Detii deja^x03 NightVision^x04 din alte surse.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(nightvision) == 0) { 
	ColorChat(id, "^x03%s NightVision^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_nightvision) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_nightvision) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_nightvision) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NightVision^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 NightVision^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_nvg (id)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < nvcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 NightVision^x04. Necesari:^x03 %i$",Prefix,nvcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_nvg(id) && !g_hasNightVision[id]) {
	cs_set_user_money(id, bani - nvcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 NightVision^x04.Pentru utilizare apasa tasta^x03 N.",Prefix);
	emit_sound(id,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 1);
	g_hasNightVision[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < nvcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 NightVision^x04. Necesare:^x03 %i Puncte",Prefix,nvcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_nvg(id) && !g_hasNightVision[id]) {
	PlayerPoints[id] -= nvcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 NightVision^x04.Pentru utilizare apasa tasta^x03 N.",Prefix);
	emit_sound(id,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 1);
	g_hasNightVision[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Sell NightVision |------//
public sell_nvg(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new sellnvg;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellnvg = get_pcvar_num(vip_sellnightvision);
	}
	else {
	sellnvg = get_pcvar_num(sellnightvision);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellnvg = get_pcvar_num(vip_points_sellnightvision);
	}
	else {
	sellnvg = get_pcvar_num(points_sellnightvision);
	}
	}
	if(!cs_get_user_nvg (id)) {
	ColorChat(id, "^x03%s^x04 Nu ai^x03 NightVision.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(cs_get_user_nvg (id)) {
	cs_set_user_money(id, cs_get_user_money(id) + sellnvg);
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 NightVision^x04,ai primit^x03 %i$.",Prefix,sellnvg);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 0);
	g_hasNightVision[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(cs_get_user_nvg (id)) {
	PlayerPoints[id] += sellnvg;
	ColorChat(id, "^x03%s^x04 Ai vandut^x03 NightVision^x04,ai primit^x03 %i Puncte.",Prefix,sellnvg);
	emit_sound(id,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_nvg(id, 0);
	g_hasNightVision[id] = 0;
	Screen2(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give NightVision |------//
public give_nvg(id, level, cid) {
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
	if(!cs_get_user_nvg (players)) {
	set_user_nvg(players, 1);
	g_hasNightVision[players] = 1;
	emit_sound(players,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NightVision^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NightVision^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!cs_get_user_nvg (players)) {
	set_user_nvg(players, 1);
	g_hasNightVision[players] = 1;
	emit_sound(players,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NightVision^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NightVision^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!cs_get_user_nvg (players)) {
	set_user_nvg(players, 1);
	g_hasNightVision[players] = 1;
	emit_sound(players,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 NightVision^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 NightVision^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_nvg (player)) {
	set_user_nvg(player, 1);
	g_hasNightVision[player] = 1;
	emit_sound(player,CHAN_ITEM,NVG_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 NightVision.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 NightVision.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
//------| Take NightVision |------//
public take_nvg(id, level, cid) {
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
	if(cs_get_user_nvg (players)) {
	set_user_nvg(players, 0);
	g_hasNightVision[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 NightVision^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 NightVision^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(cs_get_user_nvg (players)) {
	set_user_nvg(players, 0);
	g_hasNightVision[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 NightVision^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 NightVision^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(cs_get_user_nvg (players)) {
	set_user_nvg(players, 0);
	g_hasNightVision[players] = 0;
	emit_sound(players,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 take^x03 NightVision^x04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 take^x03 NightVision^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_nvg (player)) {
	set_user_nvg(player, 0);
	g_hasNightVision[player] = 0;
	emit_sound(player,CHAN_ITEM,SELL_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen2(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 take your^x03 NightVision.");
	case 2: ColorChat(player, "^x03%s^x04 take your^x03 NightVision.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Silent Walk Commands |
//==========================================================================================================
//------| Buy Silent Walk |------//
public buy_silentwalk(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new swcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	swcost = get_pcvar_num(vip_silentwalkcost);
	}
	else {
	swcost = get_pcvar_num(silentwalkcost);	
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshop) != 0) {
	new sellsw;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	sellsw = get_pcvar_num(vip_sellsilentwalk);
	}
	else {
	sellsw = get_pcvar_num(sellsilentwalk);	
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
// Shield Commands |
//==========================================================================================================
//------| Buy Shield |------//
public buy_shield(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new shcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	shcost = get_pcvar_num(vip_shieldcost);
	}
	else {
	shcost = get_pcvar_num(shieldcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	shcost = get_pcvar_num(vip_points_shieldcost);
	}
	else {
	shcost = get_pcvar_num(points_shieldcost);
	}
	}
	if(get_pcvar_num(shield) == 0) { 
	ColorChat(id, "^x03%s Shield^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_shield) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_shield) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_shield) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Shield^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Shield^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Shield^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_shield(id)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < shcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Shield^x04. Necesari:^x03 %i$",Prefix,shcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_shield(id)) {
	if(user_has_weapon(id,CSW_AK47)) { client_cmd(id,"weapon_ak47"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_AUG)) { client_cmd(id,"weapon_aug"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_AWP)) { client_cmd(id,"weapon_awp"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_ELITE)) { client_cmd(id,"weapon_elite"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_FAMAS)) { client_cmd(id,"weapon_famas"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_G3SG1)) { client_cmd(id,"weapon_g3sg1"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_GALIL)) { client_cmd(id,"weapon_galil"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M249)) { client_cmd(id,"weapon_m249"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M3)) { client_cmd(id,"weapon_m3"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M4A1)) { client_cmd(id,"weapon_m4a1"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_MAC10)) { client_cmd(id,"weapon_mac10"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_MP5NAVY)) { client_cmd(id,"weapon_mp5navy"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_P90)) { client_cmd(id,"weapon_p90"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SCOUT)) { client_cmd(id,"weapon_scout"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SG550)) { client_cmd(id,"weapon_sg550"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SG552)) { client_cmd(id,"weapon_sg552"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_TMP)) { client_cmd(id,"weapon_tmp"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_UMP45)) { client_cmd(id,"weapon_ump45"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_XM1014)) { client_cmd(id,"weapon_xm1014"); set_task(0.1,"DROP",id);
	}
	cs_set_user_money(id, bani - shcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(0.3,"SHIELD",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < shcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Shield^x04. Necesare:^x03 %i Puncte",Prefix,shcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_shield(id)) {
	if(user_has_weapon(id,CSW_AK47)) { client_cmd(id,"weapon_ak47"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_AUG)) { client_cmd(id,"weapon_aug"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_AWP)) { client_cmd(id,"weapon_awp"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_ELITE)) { client_cmd(id,"weapon_elite"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_FAMAS)) { client_cmd(id,"weapon_famas"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_G3SG1)) { client_cmd(id,"weapon_g3sg1"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_GALIL)) { client_cmd(id,"weapon_galil"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M249)) { client_cmd(id,"weapon_m249"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M3)) { client_cmd(id,"weapon_m3"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_M4A1)) { client_cmd(id,"weapon_m4a1"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_MAC10)) { client_cmd(id,"weapon_mac10"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_MP5NAVY)) { client_cmd(id,"weapon_mp5navy"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_P90)) { client_cmd(id,"weapon_p90"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SCOUT)) { client_cmd(id,"weapon_scout"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SG550)) { client_cmd(id,"weapon_sg550"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_SG552)) { client_cmd(id,"weapon_sg552"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_TMP)) { client_cmd(id,"weapon_tmp"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_UMP45)) { client_cmd(id,"weapon_ump45"); set_task(0.1,"DROP",id);
	}
	if(user_has_weapon(id,CSW_XM1014)) { client_cmd(id,"weapon_xm1014"); set_task(0.1,"DROP",id);
	}
	PlayerPoints[id] -= shcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Shield.",Prefix);
	emit_sound(id,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(0.3,"SHIELD",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Shield |------//
public give_shield(id, level, cid) {
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
	if(!cs_get_user_shield(players)) {
	if(user_has_weapon(players,CSW_AK47)) { client_cmd(players,"weapon_ak47"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AUG)) { client_cmd(players,"weapon_aug"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AWP)) { client_cmd(players,"weapon_awp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_ELITE)) { client_cmd(players,"weapon_elite"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_FAMAS)) { client_cmd(players,"weapon_famas"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_G3SG1)) { client_cmd(players,"weapon_g3sg1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_GALIL)) { client_cmd(players,"weapon_galil"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M249)) { client_cmd(players,"weapon_m249"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M3)) { client_cmd(players,"weapon_m3"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M4A1)) { client_cmd(players,"weapon_m4a1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MAC10)) { client_cmd(players,"weapon_mac10"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MP5NAVY)) { client_cmd(players,"weapon_mp5navy"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_P90)) { client_cmd(players,"weapon_p90"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SCOUT)) { client_cmd(players,"weapon_scout"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG550)) { client_cmd(players,"weapon_sg550"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG552)) { client_cmd(players,"weapon_sg552"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_TMP)) { client_cmd(players,"weapon_tmp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_UMP45)) { client_cmd(players,"weapon_ump45"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_XM1014)) { client_cmd(players,"weapon_xm1014"); set_task(0.1,"DROP",players);
	}
	set_task(0.3,"SHIELD",players);
	emit_sound(players,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Shield^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Shield^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!cs_get_user_shield(players)) {
	if(user_has_weapon(players,CSW_AK47)) { client_cmd(players,"weapon_ak47"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AUG)) { client_cmd(players,"weapon_aug"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AWP)) { client_cmd(players,"weapon_awp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_ELITE)) { client_cmd(players,"weapon_elite"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_FAMAS)) { client_cmd(players,"weapon_famas"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_G3SG1)) { client_cmd(players,"weapon_g3sg1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_GALIL)) { client_cmd(players,"weapon_galil"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M249)) { client_cmd(players,"weapon_m249"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M3)) { client_cmd(players,"weapon_m3"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M4A1)) { client_cmd(players,"weapon_m4a1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MAC10)) { client_cmd(players,"weapon_mac10"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MP5NAVY)) { client_cmd(players,"weapon_mp5navy"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_P90)) { client_cmd(players,"weapon_p90"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SCOUT)) { client_cmd(players,"weapon_scout"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG550)) { client_cmd(players,"weapon_sg550"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG552)) { client_cmd(players,"weapon_sg552"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_TMP)) { client_cmd(players,"weapon_tmp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_UMP45)) { client_cmd(players,"weapon_ump45"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_XM1014)) { client_cmd(players,"weapon_xm1014"); set_task(0.1,"DROP",players);
	}
	set_task(0.3,"SHIELD",players);
	emit_sound(players,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Shield^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Shield^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!cs_get_user_shield(players)) {
	if(user_has_weapon(players,CSW_AK47)) { client_cmd(players,"weapon_ak47"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AUG)) { client_cmd(players,"weapon_aug"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_AWP)) { client_cmd(players,"weapon_awp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_ELITE)) { client_cmd(players,"weapon_elite"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_FAMAS)) { client_cmd(players,"weapon_famas"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_G3SG1)) { client_cmd(players,"weapon_g3sg1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_GALIL)) { client_cmd(players,"weapon_galil"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M249)) { client_cmd(players,"weapon_m249"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M3)) { client_cmd(players,"weapon_m3"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_M4A1)) { client_cmd(players,"weapon_m4a1"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MAC10)) { client_cmd(players,"weapon_mac10"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_MP5NAVY)) { client_cmd(players,"weapon_mp5navy"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_P90)) { client_cmd(players,"weapon_p90"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SCOUT)) { client_cmd(players,"weapon_scout"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG550)) { client_cmd(players,"weapon_sg550"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_SG552)) { client_cmd(players,"weapon_sg552"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_TMP)) { client_cmd(players,"weapon_tmp"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_UMP45)) { client_cmd(players,"weapon_ump45"); set_task(0.1,"DROP",players);
	}
	if(user_has_weapon(players,CSW_XM1014)) { client_cmd(players,"weapon_xm1014"); set_task(0.1,"DROP",players);
	}
	set_task(0.3,"SHIELD",players);
	emit_sound(players,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Shield^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Shield^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!cs_get_user_shield(player)) {
	if(user_has_weapon(player,CSW_AK47)) { client_cmd(player,"weapon_ak47"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_AUG)) { client_cmd(player,"weapon_aug"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_AWP)) { client_cmd(player,"weapon_awp"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_ELITE)) { client_cmd(player,"weapon_elite"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_FAMAS)) { client_cmd(player,"weapon_famas"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_G3SG1)) { client_cmd(player,"weapon_g3sg1"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_GALIL)) { client_cmd(player,"weapon_galil"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_M249)) { client_cmd(player,"weapon_m249"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_M3)) { client_cmd(player,"weapon_m3"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_M4A1)) { client_cmd(player,"weapon_m4a1"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_MAC10)) { client_cmd(player,"weapon_mac10"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_MP5NAVY)) { client_cmd(player,"weapon_mp5navy"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_P90)) { client_cmd(player,"weapon_p90"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_SCOUT)) { client_cmd(player,"weapon_scout"); set_task(0.1,"DROP",player); 
	}
	if(user_has_weapon(player,CSW_SG550)) { client_cmd(player,"weapon_sg550"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_SG552)) { client_cmd(player,"weapon_sg552"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_TMP)) { client_cmd(player,"weapon_tmp"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_UMP45)) { client_cmd(player,"weapon_ump45"); set_task(0.1,"DROP",player);
	}
	if(user_has_weapon(player,CSW_XM1014)) { client_cmd(player,"weapon_xm1014"); set_task(0.1,"DROP",player);
	}
	set_task(0.3,"SHIELD",player);
	emit_sound(player,CHAN_ITEM,SHIELD_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Shield.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Shield.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// JetPack Commands |
//==========================================================================================================
//------| Buy JetPack |------//
public buy_jetpack(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new jptime = get_pcvar_num(jetpacktime);
	new jpcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	jpcost = get_pcvar_num(vip_jetpackcost);
	}
	else {
	jpcost = get_pcvar_num(jetpackcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
// Hook Commands |
//==========================================================================================================
//------| Buy Hook |------//
public buy_hook(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new hkcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hkcost = get_pcvar_num(vip_hookcost);
	}
	else {
	hkcost = get_pcvar_num(hookcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hkcost = get_pcvar_num(vip_points_hookcost);
	}
	else {
	hkcost = get_pcvar_num(points_hookcost);
	}
	}
	if(get_pcvar_num(hook) == 0) { 
	ColorChat(id, "^x03%s Hook^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_hook) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Hook.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_hook) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Hook.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_hook) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Hook.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Hook^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Hook^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasHook[id]) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Hook.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < hkcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Hook^x04. Necesari:^x03 %i$",Prefix,hkcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasHook[id]) {
	cs_set_user_money(id, bani - hkcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Hook^x04.Pentru utilizare apasa tasta^x03 V.",Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasHook[id] = get_pcvar_num(hookamount);
	client_cmd(id,"bind v +hook");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < hkcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Hook^x04. Necesare:^x03 %i Puncte",Prefix,hkcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasHook[id]) {
	PlayerPoints[id] -= hkcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Hook^x04.Pentru utilizare apasa tasta^x03 V.",Prefix);
	emit_sound(id,CHAN_ITEM,PARACHUTE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasHook[id] = get_pcvar_num(hookamount);
	client_cmd(id,"bind v +hook");
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	
//------| Give Hook |------//
public give_hook(id, level, cid) {
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
	if(!g_hasHook[players]) {
	g_hasHook[players] = get_pcvar_num(hookamount);
	client_cmd(players,"bind v +hook");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Hook^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Hook^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasHook[players]) {
	g_hasHook[players] = get_pcvar_num(hookamount);
	client_cmd(players,"bind v +hook");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Hook^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Hook^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasHook[players]) {
	g_hasHook[players] = get_pcvar_num(hookamount);
	client_cmd(players,"bind v +hook");
	emit_sound(players,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Hook^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Hook^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasHook[player]) {
	g_hasHook[player] = get_pcvar_num(hookamount);
	client_cmd(player,"bind v +hook");
	emit_sound(player,CHAN_ITEM,BUY_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Hook.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Hook.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Invizibility Commands |
//==========================================================================================================
//------| Buy Invizibility |------//
public buy_invizibility(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new invcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	invcost = get_pcvar_num(vip_invizibilitycost);
	}
	else {
	invcost = get_pcvar_num(invizibilitycost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	invcost = get_pcvar_num(vip_points_invizibilitycost);
	}
	else {
	invcost = get_pcvar_num(points_invizibilitycost);
	}
	}
	if(get_pcvar_num(invizibility) == 0) { 
	ColorChat(id, "^x03%s Invizibility^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_invizibility) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_invizibility) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_invizibility) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Invizibility^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Invizibility^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Invizibility^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasInvizibility[id]) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < invcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Invizibility^x04. Necesari:^x03 %i$",Prefix,invcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasInvizibility[id]) {
	cs_set_user_money(id, bani - invcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,INVIS_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_invizibility(id, 1);
	g_hasInvizibility[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < invcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Invizibility^x04. Necesare:^x03 %i Puncte",Prefix,invcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasInvizibility[id]) {
	PlayerPoints[id] -= invcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,INVIS_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_invizibility(id, 1);
	g_hasInvizibility[id] = 1;
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Invizbiility |------//
public give_invizibility(id, level, cid) {
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
	if(!g_hasInvizibility[players]) {
	set_user_invizibility(players, 1);
	g_hasInvizibility[id] = 1;
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Invizibility^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Invizibility^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasInvizibility[players]) {
	set_user_invizibility(players, 1);
	g_hasInvizibility[id] = 1;
	emit_sound(players,CHAN_ITEM,INVIS_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Invizibility^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Invizibility^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasInvizibility[players]) {
	set_user_invizibility(players, 1);
	g_hasInvizibility[id] = 1;
	emit_sound(players,CHAN_ITEM,INVIS_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 Invizibility^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 Invizibility^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasInvizibility[player]) {
	set_user_invizibility(player, 1);
	g_hasInvizibility[id] = 1;
	emit_sound(player,CHAN_ITEM,INVIS_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 Invizibility.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 Invizibility.", name);
	}
	}
	return PLUGIN_HANDLED;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GodMode Commands |
//==========================================================================================================
//------| Buy GodMode |------//
public buy_godmode(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new gmtime = get_pcvar_num(godmodetime);
	new gmcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	gmcost = get_pcvar_num(vip_godmodecost);
	}
	else {
	gmcost = get_pcvar_num(godmodecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	gmcost = get_pcvar_num(vip_points_godmodecost);
	}
	else {
	gmcost = get_pcvar_num(points_godmodecost);
	}
	}
	if(get_pcvar_num(godmode) == 0) { 
	ColorChat(id, "^x03%s GodMode^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_godmode) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 GodMode.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_godmode) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 GodMode.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_godmode) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 GodMode.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 GodMode^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 GodMode^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(roundend) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 GodMode^x04.Jocul sa terminat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_user_godmode(id)) {
	ColorChat(id, "^x03%s^x04 Ai deja^x03 GodMode.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < gmcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 GodMode^x04. Necesari:^x03 %i$",Prefix,gmcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_godmode(id)) {
	cs_set_user_money(id, bani - gmcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 GodMode^x04 pentru^x03 %d^x04 secunde.",Prefix ,gmtime);
	emit_sound(id,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_godmode(id,1);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < gmcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 GodMode^x04. Necesare:^x03 %i Puncte",Prefix,gmcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!get_user_godmode(id)) {
	PlayerPoints[id] -= gmcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 GodMode^x04 pentru^x03 %d^x04 secunde.",Prefix ,gmtime);
	emit_sound(id,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_godmode(id,1);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",id);
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give GodMode |------//
public give_godmode(id, level, cid) {
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
	if(!get_user_godmode(players)) {
	set_user_godmode(players,1);
	emit_sound(players,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 GodMode^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 GodMode^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_godmode(players)) {
	set_user_godmode(players,1);
	emit_sound(players,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 GodMode^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 GodMode^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!get_user_godmode(players)) {
	set_user_godmode(players,1);
	emit_sound(players,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",players);
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 give^x03 GodMode^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 give^x03 GodMode^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!get_user_godmode(player)) {
	set_user_godmode(player,1);
	emit_sound(player,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(float(get_pcvar_num(godmodetime)),"removeGodMode",player);
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 give you^x03 GodMode.");
	case 2: ColorChat(player, "^x03%s^x04 give you^x03 GodMode.", name);
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Glow Commands |
//==========================================================================================================
//------| Buy Glow |------//
public buy_glow(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new bani = cs_get_user_money(id);
	new gcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	gcost = get_pcvar_num(vip_glowcost);
	}
	else {
	gcost = get_pcvar_num(glowcost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	gcost = get_pcvar_num(vip_points_glowcost);
	}
	else {
	gcost = get_pcvar_num(points_glowcost);
	}
	}
	if(get_pcvar_num(glow) == 0) { 
	ColorChat(id, "^x03%s Glow^x04 este dezactivat.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_glow) == 0 && !(get_user_flags(id) & ADMIN_LEVEL)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Admini^x04 pot cumpara^x03 Glow.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_glow) == 1 && !(cs_get_user_team(id) == CS_TEAM_CT)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 CTs^x04 pot cumpara^x03 Glow.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(acces_glow) == 2 && !(cs_get_user_team(id) == CS_TEAM_T)) {
	ColorChat(id, "^x03%s^x04 Doar^x03 Teroristi^x04 pot cumpara^x03 Glow.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Glow^x04 cat timp esti Spectator.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Glow^x04 cat timp esti mort.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(g_hasInvizibility[id]) {
	ColorChat(id, "^x03%s^x04 Nu poti cumpara^x03 Glow^x04 cat timp ai^x03 Invizibility.",Prefix);
	emit_sound(id,CHAN_ITEM,ERROR_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(bani < gcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficienti bani pentru a cumpara^x03 Glow^x04. Necesari:^x03 %i$",Prefix,gcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, bani - gcost);
	ColorChat(id, "^x03%s^x04 Ai schimbat culoarea la^x03 Glow.",Prefix);
	emit_sound(id,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasInvizibility[id] = 0;
	set_user_rendering(id, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(PlayerPoints[id] < gcost) {
	ColorChat(id, "^x03%s^x04 Nu ai suficiente Puncte pentru a cumpara^x03 Glow^x04. Necesare:^x03 %i Puncte",Prefix,gcost);
	emit_sound(id,CHAN_ITEM,ERROR2_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	return PLUGIN_HANDLED;
	}
	if(!g_hasInvizibility[id]) {
	PlayerPoints[id] -= gcost;
	ColorChat(id, "^x03%s^x04 Ai schimbat culoarea la^x03 Glow.",Prefix);
	emit_sound(id,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	g_hasInvizibility[id] = 0;
	set_user_rendering(id, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Give Glow |------//
public give_glow(id, level, cid) {
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
	if(!g_hasInvizibility[players]) {
	emit_sound(players,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_rendering(players, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 switch^x03 Glow^x04 to all^x03 Ts.");
	case 2: ColorChat(0, "^x03%s^x04 switch^x03 Glow^x04 to all^x03 Ts.", name);
	}
	}
	
	else if(equali(arg, "@CT")) {
	get_players(gplayers, num, "e", "CT");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasInvizibility[players]) {
	emit_sound(players,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_rendering(players, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 switch^x03 Glow^x04 to all^x03 CTs.");
	case 2: ColorChat(0, "^x03%s^x04 switch^x03 Glow^x04 to all^x03 CTs.", name);
	}
	}
	
	else if(equali(arg, "@All")) {
	get_players(gplayers, num, "a");
	for(i = 0; i < num; i++) {
	players = gplayers[i];
	if(!is_user_connected(players))
	continue;
	if(!g_hasInvizibility[players]) {
	emit_sound(players,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_rendering(players, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(players);
	}
	}
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(0, "^x03ADMIN^x04 switch^x03 Glow^04 to all^x03 Players.");
	case 2: ColorChat(0, "^x03%s^x04 switch^x03 Glow^x04 to all^x03 Players.", name);
	}
	}
	new player = cmd_target(id, arg, 11);
	if(!player) {
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
	return PLUGIN_HANDLED;
	}
	if(!g_hasInvizibility[player]) {
	emit_sound(player,CHAN_ITEM,GLOW_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_user_rendering(player, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, random(256));
	Screen1(player);
	switch(get_cvar_num("amx_show_activity")) {
	case 1: ColorChat(player, "^x03ADMIN^x04 switch your^x03 Glow.");
	case 2: ColorChat(player, "^x03%s^x04 switch your^x03 Glow.", name);
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
	console_print(id, "[DrShop] Juctorul cu acel nume nu exista.");
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(player)) {
	console_print(id, "[DrShop] Nu poti da acest Item unui jucator mort.");
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
	parachute_reset(id);
	has_parachute[id] = false;
	g_hasLongJump[id] = 0;
	g_hasGravity[id] = 0;
	hasGravity[id] = 0;
	g_hasSpeed[id] = 0;
	hasSpeed[id] = 0;
	g_hasNightVision[id] = 0;
	g_hasSilentWalk[id] = 0;
	has_jp[id] = false;
	hookenable[id] = false;
	g_hasHook[id] = 0;
	g_hasInvizibility[id] = 0;
	}
	
//------| Client Disconecct |------//
public client_disconnect(id) {
	if(get_pcvar_num(deathrunshopmod) == 1) {
	SavePoints(id);
	}
	parachute_reset(id);
	has_parachute[id] = false;
	g_hasLongJump[id] = 0;
	g_hasGravity[id] = 0;
	hasGravity[id] = 0;
	g_hasSpeed[id] = 0;
	hasSpeed[id] = 0;
	g_hasNightVision[id] = 0;
	g_hasSilentWalk[id] = 0;
	has_jp[id] = false;
	hookenable[id] = false;
	g_hasHook[id] = 0;
	g_hasInvizibility[id] = 0;
	}
	
//------| Give Noney/Points to killer |------//
public client_death(killer,victim,wpnindex,hitplace,TK) {
	//------| Give Money/Points to Kill the enemy |------//
	if (killer != victim) {
	if(get_pcvar_num(deathrunshopmod) != 0) {
	PlayerPoints[killer] += get_pcvar_num(dr_points_kill);
	if(hitplace == HIT_HEAD) {
 	PlayerPoints[killer] += get_pcvar_num(dr_points_hs);
	}
 	if(wpnindex == CSW_KNIFE) {
 	PlayerPoints[killer] += get_pcvar_num(dr_points_knife);
	}
 	if(wpnindex == CSW_HEGRENADE) {
 	PlayerPoints[killer] += get_pcvar_num(dr_points_he);
	}
	SavePoints(killer);
	}
	if(get_pcvar_num(deathrunshopmod) != 1) {
	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(dr_money_kill));
	if(hitplace == HIT_HEAD) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(dr_money_hs));
	}
 	if(wpnindex == CSW_KNIFE) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(dr_money_knife));
	}
 	if(wpnindex == CSW_HEGRENADE) {
 	cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(dr_money_he));
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
	parachute_reset(Victim);
	has_parachute[Victim] = false;
	g_hasLongJump[Victim] = 0;
	set_user_longjump(Victim, 0);
	g_hasGravity[Victim] = 0;
	hasGravity[Victim] = 0;
	g_hasSpeed[Victim] = 0;
	hasSpeed[Victim] = 0;
	has_jp[Victim] = false;
	hookenable[Victim] = false;
	g_hasHook[Victim] = 0;
	g_hasNightVision[Victim] = 0;
	set_user_nvg(Victim, 0);
	g_hasSilentWalk[Victim] = 0;
	set_user_footsteps(Victim, 0);
	g_hasInvizibility[Victim] = 0;
	set_user_invizibility(Victim, 0);
	return PLUGIN_CONTINUE;
	}
	
//------| Cur Weapon |------//
public event_cur_weapon(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new szWeapID = get_user_weapon(id, szClip, szAmmo);
	static iInvisLevel;
	if(!IsHoldingKnife(id) && g_hasInvizibility[id]) {
	iInvisLevel = get_pcvar_num(invislevel);
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, iInvisLevel);
	}
	else if(IsHoldingKnife(id) && g_hasInvizibility[id]) {
	InvKnife(id);
	}
	if(g_hasGravity[id] && hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	set_user_gravity(id, get_pcvar_float(lowgravity));
	}
	if(g_hasSpeed[id] && hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	}
	if(szWeapID == CSW_DEAGLE && cs_get_user_shield(id) && get_pcvar_num(deaglemodel) != 0) {
	set_pev(id,pev_viewmodel2, DEAGLE_SHIELD_V);
	set_pev(id,pev_weaponmodel2, DEAGLE_SHIELD_P);
	}
	else if(szWeapID == CSW_DEAGLE && !cs_get_user_shield(id) && get_pcvar_num(deaglemodel) != 0) {
	set_pev(id,pev_viewmodel2, DEAGLE_MODEL_V);
	set_pev(id,pev_weaponmodel2, DEAGLE_MODEL_P);
	}
	if(g_hasLongJump[id] && !get_user_longjump(id)) {
	set_user_longjump(id, 1);
	}
	if(g_hasInvizibility[id]) {
	set_user_invizibility(id, 1);
	}
	if(g_hasNightVision[id] && !cs_get_user_nvg(id)) {
	set_user_nvg(id, 1);
	}
	if(g_hasSilentWalk[id] && !get_user_footsteps(id)) {
	set_user_footsteps(id,1);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	SavePoints(id);
	}
	}
	}
	
//---| Round Start |---//
public RoundStart(id) {
	if(get_pcvar_num(deathrunshop) != 0) {
	new szWeapID = get_user_weapon(id, szClip, szAmmo);
	if(szWeapID == CSW_DEAGLE && cs_get_user_shield(id) && get_pcvar_num(deaglemodel) != 0) {
	set_pev(id,pev_viewmodel2, DEAGLE_SHIELD_V);
	set_pev(id,pev_weaponmodel2, DEAGLE_SHIELD_P);
	}
	else if(szWeapID == CSW_DEAGLE && !cs_get_user_shield(id) && get_pcvar_num(deaglemodel) != 0) {
	set_pev(id,pev_viewmodel2, DEAGLE_MODEL_V);
	set_pev(id,pev_weaponmodel2, DEAGLE_MODEL_P);
	}
	if(g_hasLongJump[id] && !get_user_longjump(id)) {
	set_user_longjump(id, 1);
	}
	if(g_hasGravity[id] && hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	set_user_gravity(id, get_pcvar_float(lowgravity));
	}
	if(g_hasSpeed[id] && hasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(highspeed)) {
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	}
	if(g_hasNightVision[id] && !cs_get_user_nvg(id)) {
	set_user_nvg(id, 1);
	}
	if(g_hasSilentWalk[id] && !get_user_footsteps(id)) {
	set_user_footsteps(id,1);
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	SavePoints(id);
	}
	}
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Parachute Stock |
//==========================================================================================================
//------| Reset Paracuhte |------//
parachute_reset(id) {
	if(para_ent[id] > 0) {
	if(pev_valid(para_ent[id])) 
	engfunc(EngFunc_RemoveEntity, para_ent[id]);
	}
	
	has_parachute[id] = false;
	para_ent[id] = 0;
	}
	
//------| Parachute Stock |------//
public fw_PreThink(id) {
	if(!is_user_alive(id) || !has_parachute[id])
	return;
	
	new Float:fallspeed = get_pcvar_float(parachutespeed) * -1.0;
	new Float:frame;
	
	new button = pev(id, pev_button);
	new oldbutton = pev(id, pev_oldbuttons);
	new flags = pev(id, pev_flags);
	
	if(para_ent[id] > 0 && (flags & FL_ONGROUND)) {
	
	if(pev(para_ent[id],pev_sequence) != 2) {
	set_pev(para_ent[id], pev_sequence, 2);
	set_pev(para_ent[id], pev_gaitsequence, 1);
	set_pev(para_ent[id], pev_frame, 0.0);
	set_pev(para_ent[id], pev_fuser1, 0.0);
	set_pev(para_ent[id], pev_animtime, 0.0);
	return;
	}
	
	pev(para_ent[id],pev_fuser1, frame);
	frame += 2.0;
	set_pev(para_ent[id],pev_fuser1,frame);
	set_pev(para_ent[id],pev_frame,frame);
	
	if(frame > 254.0) {
	engfunc(EngFunc_RemoveEntity, para_ent[id]);
	para_ent[id] = 0;
	}
	else {
	engfunc(EngFunc_RemoveEntity, para_ent[id]);
	para_ent[id] = 0;
	}
	return;
	}
	
	if(button & IN_USE) {
	new Float:velocity[3];
	pev(id, pev_velocity, velocity);

	if(velocity[2] < 0.0) {
	if(para_ent[id] <= 0) {
	para_ent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
	if(para_ent[id] > 0) {
	set_pev(para_ent[id],pev_classname,"parachute");
	set_pev(para_ent[id], pev_aiment, id);
	set_pev(para_ent[id], pev_owner, id);
	set_pev(para_ent[id], pev_movetype, MOVETYPE_FOLLOW);
	engfunc(EngFunc_SetModel, para_ent[id], parachute_model);
	set_pev(para_ent[id], pev_sequence, 0);
	set_pev(para_ent[id], pev_gaitsequence, 1);
	set_pev(para_ent[id], pev_frame, 0.0);
	set_pev(para_ent[id], pev_fuser1, 0.0);
	}
	}
	if(para_ent[id] > 0) {
	set_pev(id, pev_sequence, 3);
	set_pev(id, pev_gaitsequence, 1);
	set_pev(id, pev_frame, 1.0);
	set_pev(id, pev_framerate, 1.0);
	
	velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed;
	set_pev(id, pev_velocity, velocity);
	
	if(pev(para_ent[id],pev_sequence) == 0) {
	pev(para_ent[id],pev_fuser1, frame);
	frame += 1.0;
	set_pev(para_ent[id],pev_fuser1,frame);
	set_pev(para_ent[id],pev_frame,frame);
	
	if(frame > 100.0) {
	set_pev(para_ent[id], pev_animtime, 0.0);
	set_pev(para_ent[id], pev_framerate, 0.4);
	set_pev(para_ent[id], pev_sequence, 1);
	set_pev(para_ent[id], pev_gaitsequence, 1);
	set_pev(para_ent[id], pev_frame, 0.0);
	set_pev(para_ent[id], pev_fuser1, 0.0);
	}
	}
	}
	}
	
	else if(para_ent[id] > 0) {
	engfunc(EngFunc_RemoveEntity, para_ent[id]);
	para_ent[id] = 0;
	}
	}
	
	else if((oldbutton & IN_USE) && para_ent[id] > 0) {
	engfunc(EngFunc_RemoveEntity, para_ent[id]);
	para_ent[id] = 0;
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LongJump Stock |
//==========================================================================================================
stock bool:get_user_longjump(index) {
	new value[2];
	engfunc(EngFunc_GetPhysicsKeyValue, index, "slj", value, 1);
	switch (value[0]) {
	case '1': return true;
	}

	return false;
	}

stock set_user_longjump(index, longjump = 1) {
	if(longjump) {
	engfunc(EngFunc_SetPhysicsKeyValue, index, "slj", "1");
	if(get_pcvar_num(icon_lj) != 0) {
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, index);
	write_string("item_longjump");
	message_end();
	}
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, index);
	write_byte(ICON_SHOW);
	write_string("item_longjump");
	write_byte(0);
	write_byte(148);
	write_byte(255);
	message_end();

	}
	else {
	engfunc(EngFunc_SetPhysicsKeyValue, index, "slj", "0");
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, index);
	write_byte(ICON_HIDE);
	write_string("item_longjump");
	message_end();
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Life Stock |
//==========================================================================================================
//------| Spawn Players |------//
public spawnagain(id) {
	new lcost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_lifecost);	
	}
	else {
	lcost = get_pcvar_num(lifecost);	 
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	lcost = get_pcvar_num(vip_points_lifecost);	
	}
	else {
	lcost = get_pcvar_num(points_lifecost);	 
	}
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
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
	if(get_pcvar_num(deathrunshopmod) != 0) {
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
// Grenades Stock |
//==========================================================================================================
//------| Give Grenades |------//
public grenadetask (id) {
	new hecost, flashcost, smokecost;
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hecost = get_pcvar_num(vip_hegrenadecost);
	flashcost = get_pcvar_num(vip_flashbangcost);
	smokecost = get_pcvar_num(vip_smokegrenadecost);
	}
	else {
	hecost = get_pcvar_num(hegrenadecost);
	flashcost = get_pcvar_num(flashbangcost);
	smokecost = get_pcvar_num(smokegrenadecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hecost = get_pcvar_num(vip_points_hegrenadecost);
	flashcost = get_pcvar_num(vip_points_flashbangcost);
	smokecost = get_pcvar_num(vip_points_smokegrenadecost);
	}
	else {
	hecost = get_pcvar_num(points_hegrenadecost);
	flashcost = get_pcvar_num(points_flashbangcost);
	smokecost = get_pcvar_num(points_smokegrenadecost);
	}
	}
	if(get_pcvar_num(deathrunshopmod) == 0) {
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	cs_set_user_money(id,cs_get_user_money(id) - (hecost + flashcost + smokecost));
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Flash/Smoke.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	cs_set_user_money(id,cs_get_user_money(id) - (flashcost + smokecost));
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Flash/Smoke.",Prefix);
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	cs_set_user_money(id,cs_get_user_money(id) - (hecost + smokecost));
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Smoke.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG)) {
	cs_set_user_money(id,cs_get_user_money(id) - (hecost + flashcost));
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Flash.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	}
	else if(!user_has_weapon (id, CSW_SMOKEGRENADE)) {
	cs_set_user_money(id,cs_get_user_money(id) - smokecost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Smoke.",Prefix);
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_FLASHBANG)) {
	cs_set_user_money(id,cs_get_user_money(id) - flashcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Flash.",Prefix);
	give_item(id, "weapon_flashbang");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE)) {
	cs_set_user_money(id,cs_get_user_money(id) - hecost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE.",Prefix);
	give_item(id, "weapon_hegrenade");
	}
	}
	if(get_pcvar_num(deathrunshopmod) != 0) {
	if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	PlayerPoints[id] -= (hecost + flashcost + smokecost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Flash/Smoke.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_FLASHBANG) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	PlayerPoints[id] -= (flashcost + smokecost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Flash/Smoke.",Prefix);
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_SMOKEGRENADE)) {
	PlayerPoints[id] -= (hecost + smokecost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Smoke.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE) && !user_has_weapon (id, CSW_FLASHBANG)) {
	PlayerPoints[id] -= (hecost + flashcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE/Flash.",Prefix);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	}
	else if(!user_has_weapon (id, CSW_SMOKEGRENADE)) {
	PlayerPoints[id] -= smokecost;
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Smoke.",Prefix);
	give_item(id, "weapon_smokegrenade");
	}
	else if(!user_has_weapon (id, CSW_FLASHBANG)) {
	PlayerPoints[id] -=  flashcost;
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 Flash.",Prefix);
	give_item(id, "weapon_flashbang");
	}
	else if(!user_has_weapon (id, CSW_HEGRENADE)) {
	PlayerPoints[id] -= hecost;
	ColorChat(id, "^x03%s^x04 Ai cumparat o grenada^x03 HE.",Prefix);
	give_item(id, "weapon_hegrenade");
	}
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Health Stock |
//==========================================================================================================
//------| Give Health |------//
public healthtask (id) {
	new mh = get_pcvar_num(maxhealth);
	new hpcost;
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	hpcost = get_pcvar_num(vip_healthcost);
	}
	else {
	hpcost = get_pcvar_num(healthcost);
	}
	if(cs_get_user_money(id) >= hpcost * 50 && get_user_health(id) <= mh - 50) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 50);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 50 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 50);
	}
	else if(cs_get_user_money(id) >= hpcost * 49 && get_user_health(id) <= mh - 49) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 49);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 49 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 49);
	}
	else if(cs_get_user_money(id) >= hpcost * 48 && get_user_health(id) <= mh - 48) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 48);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 48 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 48);
	}
	else if(cs_get_user_money(id) >= hpcost * 47 && get_user_health(id) <= mh - 47) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 47);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 47 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 47);
	}
	else if(cs_get_user_money(id) >= hpcost * 46 && get_user_health(id) <= mh - 46) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 46);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 46 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 46);
	}
	else if(cs_get_user_money(id) >= hpcost * 45 && get_user_health(id) <= mh - 45) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 45);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 45 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 45);
	}
	else if(cs_get_user_money(id) >= hpcost * 44 && get_user_health(id) <= mh - 44) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 44);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 44 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 44);
	}
	else if(cs_get_user_money(id) >= hpcost * 43 && get_user_health(id) <= mh - 43) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 43);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 43 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 43);
	}
	else if(cs_get_user_money(id) >= hpcost * 42 && get_user_health(id) <= mh - 42) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 42);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 42 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 42);
	}
	else if(cs_get_user_money(id) >= hpcost * 41 && get_user_health(id) <= mh - 41) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 41);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 41 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 41);
	}
	else if(cs_get_user_money(id) >= hpcost * 40 && get_user_health(id) <= mh - 40) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 40);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 40 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 40);
	}
	else if(cs_get_user_money(id) >= hpcost * 39 && get_user_health(id) <= mh - 39) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 39);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 39 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 39);
	}
	else if(cs_get_user_money(id) >= hpcost * 38 && get_user_health(id) <= mh - 38) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 38);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 38 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 38);
	}
	else if(cs_get_user_money(id) >= hpcost * 37 && get_user_health(id) <= mh - 37) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 37);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 37 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 37);
	}
	else if(cs_get_user_money(id) >= hpcost * 36 && get_user_health(id) <= mh - 36) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 36);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 36 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 36);
	}
	else if(cs_get_user_money(id) >= hpcost * 35 && get_user_health(id) <= mh - 35) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 35);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 35 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 35);
	}
	else if(cs_get_user_money(id) >= hpcost * 34 && get_user_health(id) <= mh - 34) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 34);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 34 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 34);
	}
	else if(cs_get_user_money(id) >= hpcost * 33 && get_user_health(id) <= mh - 33) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 33);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 33 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 33);
	}
	else if(cs_get_user_money(id) >= hpcost * 32 && get_user_health(id) <= mh - 32) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 32);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 32 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 32);
	}
	else if(cs_get_user_money(id) >= hpcost * 31 && get_user_health(id) <= mh - 31) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 31);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 31 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 31);
	}
	else if(cs_get_user_money(id) >= hpcost * 30 && get_user_health(id) <= mh - 30) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 30);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 30 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 30);
	}
	else if(cs_get_user_money(id) >= hpcost * 29 && get_user_health(id) <= mh - 29) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 29);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 29 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 29);
	}
	else if(cs_get_user_money(id) >= hpcost * 28 && get_user_health(id) <= mh - 28) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 28);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 28 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 28);
	}
	else if(cs_get_user_money(id) >= hpcost * 27 && get_user_health(id) <= mh - 27) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 27);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 27 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 27);
	}
	else if(cs_get_user_money(id) >= hpcost * 26 && get_user_health(id) <= mh - 26) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 26);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 26 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 26);
	}
	else if(cs_get_user_money(id) >= hpcost * 25 && get_user_health(id) <= mh - 25) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 25);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 25 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 25);
	}
	else if(cs_get_user_money(id) >= hpcost * 24 && get_user_health(id) <= mh - 24) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 24);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 24 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 24);
	}
	else if(cs_get_user_money(id) >= hpcost * 23 && get_user_health(id) <= mh - 23) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 23);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 23 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 23);
	}
	else if(cs_get_user_money(id) >= hpcost * 22 && get_user_health(id) <= mh - 22) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 22);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 22 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 22);
	}
	else if(cs_get_user_money(id) >= hpcost * 21 && get_user_health(id) <= mh - 21) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 21);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 21 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 21);
	}
	else if(cs_get_user_money(id) >= hpcost * 20 && get_user_health(id) <= mh - 20) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 20);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 20 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 20);
	}
	else if(cs_get_user_money(id) >= hpcost * 19 && get_user_health(id) <= mh - 19) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 19);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 19 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 19);
	}
	else if(cs_get_user_money(id) >= hpcost * 18 && get_user_health(id) <= mh - 18) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 18);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 18 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 18);
	}
	else if(cs_get_user_money(id) >= hpcost * 17 && get_user_health(id) <= mh - 17) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 17);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 17 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 17);
	}
	else if(cs_get_user_money(id) >= hpcost * 16 && get_user_health(id) <= mh - 16) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 16);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 16 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 16);
	}
	else if(cs_get_user_money(id) >= hpcost * 15 && get_user_health(id) <= mh - 15) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 15);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 15 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 15);
	}
	else if(cs_get_user_money(id) >= hpcost * 14 && get_user_health(id) <= mh - 14) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 14);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 14 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 14);
	}
	else if(cs_get_user_money(id) >= hpcost * 13 && get_user_health(id) <= mh - 13) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 13);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 13 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 13);
	}
	else if(cs_get_user_money(id) >= hpcost * 12 && get_user_health(id) <= mh - 12) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 12);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 12 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 12);
	}
	else if(cs_get_user_money(id) >= hpcost * 11 && get_user_health(id) <= mh - 11) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 11);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 11 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 11);
	}
	else if(cs_get_user_money(id) >= hpcost * 10 && get_user_health(id) <= mh - 10) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 10);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 10 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 10);
	}
	else if(cs_get_user_money(id) >= hpcost * 9 && get_user_health(id) <= mh - 9) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 9);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 9 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 9);
	}
	else if(cs_get_user_money(id) >= hpcost * 8 && get_user_health(id) <= mh - 8) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 8);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 8 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 8);
	}
	else if(cs_get_user_money(id) >= hpcost * 7 && get_user_health(id) <= mh - 7) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 7);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 7 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 7);
	}
	else if(cs_get_user_money(id) >= hpcost * 6 && get_user_health(id) <= mh - 6) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 6);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 6 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 6);
	}
	else if(cs_get_user_money(id) >= hpcost * 5 && get_user_health(id) <= mh - 5) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 5);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 5 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 5);
	}
	else if(cs_get_user_money(id) >= hpcost * 4 && get_user_health(id) <= mh - 4) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 4);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 4 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 4);
	}
	else if(cs_get_user_money(id) >= hpcost * 3 && get_user_health(id) <= mh - 3) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 3);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 3 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 3);
	}
	else if(cs_get_user_money(id) >= hpcost * 2 && get_user_health(id) <= mh - 2) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost * 2);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 2 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 2);
	}
	else if(cs_get_user_money(id) >= hpcost && get_user_health(id) <= mh - 1) {
	cs_set_user_money(id, cs_get_user_money(id) - hpcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 1 HP.",Prefix);
	set_user_health(id, get_user_health(id) + 1);
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Armor Stock |
//==========================================================================================================
//------| Give Armor |------//
public armortask (id) {
	new ma = get_pcvar_num(maxarmor);
	new apcost;
	if(get_pcvar_num(vip) != 0 && get_user_flags(id) & VIP_LEVEL) {
	apcost = get_pcvar_num(vip_armorcost);
	}
	else {
	apcost = get_pcvar_num(armorcost);	
	}
	if(cs_get_user_money(id) >= apcost * 50 && get_user_armor(id) <= ma - 50) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 50);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 50 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 50, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 49 && get_user_armor(id) <= ma - 49) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 49);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 49 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 49, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 48 && get_user_armor(id) <= ma - 48) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 48);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 48 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 48, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 47 && get_user_armor(id) <= ma - 47) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 47);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 47 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 47, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 46 && get_user_armor(id) <= ma - 46) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 46);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 46 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 46, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 45 && get_user_armor(id) <= ma - 45) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 45);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 45 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 45, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 44 && get_user_armor(id) <= ma - 44) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 44);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 44 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 44, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 43 && get_user_armor(id) <= ma - 43) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 43);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 43 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 43, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 42 && get_user_armor(id) <= ma - 42) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 42);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 42 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 42, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 41 && get_user_armor(id) <= ma - 41) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 41);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 41 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 41, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 40 && get_user_armor(id) <= ma - 40) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 40);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 40 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 40, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 39 && get_user_armor(id) <= ma - 39) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 39);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 39 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 39, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 38 && get_user_armor(id) <= ma - 38) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 38);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 38 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 38, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 37 && get_user_armor(id) <= ma - 37) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 37);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 37 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 37, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 36 && get_user_armor(id) <= ma - 36) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 36);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 36 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 36, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 35 && get_user_armor(id) <= ma - 35) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 35);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 35 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 35, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 34 && get_user_armor(id) <= ma - 34) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 34);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 34 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 34, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 33 && get_user_armor(id) <= ma - 33) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 33);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 33 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 33, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 32 && get_user_armor(id) <= ma - 32) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 32);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 32 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 32, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 31 && get_user_armor(id) <= ma - 31) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 31);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 31 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 31, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 30 && get_user_armor(id) <= ma - 30) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 30);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 30 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 30, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 29 && get_user_armor(id) <= ma - 29) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 29);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 29 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 29, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 28 && get_user_armor(id) <= ma - 28) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 28);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 28 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 28, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 27 && get_user_armor(id) <= ma - 27) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 27);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 27 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 27, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 26 && get_user_armor(id) <= ma - 26) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 26);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 26 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 26, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 25 && get_user_armor(id) <= ma - 25) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 25);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 25 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 25, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 24 && get_user_armor(id) <= ma - 24) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 24);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 24 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 24, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 23 && get_user_armor(id) <= ma - 23) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 23);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 23 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 23, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 22 && get_user_armor(id) <= ma - 22) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 22);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 22 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 22, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 21 && get_user_armor(id) <= ma - 21) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 21);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 21 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 21, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 20 && get_user_armor(id) <= ma - 20) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 20);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 20 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 20, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 19 && get_user_armor(id) <= ma - 19) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 19);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 19 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 19, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 18 && get_user_armor(id) <= ma - 18) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 18);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 18 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 18, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 17 && get_user_armor(id) <= ma - 17) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 17);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 17 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 17, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 16 && get_user_armor(id) <= ma - 16) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 16);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 16 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 16, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 15 && get_user_armor(id) <= ma - 15) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 15);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 15 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 15, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 14 && get_user_armor(id) <= ma - 14) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 14);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 14 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 14, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 13 && get_user_armor(id) <= ma - 13) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 13);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 13 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 13, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 12 && get_user_armor(id) <= ma - 12) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 12);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 12 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 12, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 11 && get_user_armor(id) <= ma - 11) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 11);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 11 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 11, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 10 && get_user_armor(id) <= ma - 10) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 10);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 10 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 10, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 9 && get_user_armor(id) <= ma - 9) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 9);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 9 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 9, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 8 && get_user_armor(id) <= ma - 8) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 8);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 8 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 8, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 7 && get_user_armor(id) <= ma - 7) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 7);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 7 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 7, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 6 && get_user_armor(id) <= ma - 6) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 6);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 6 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 6, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 5 && get_user_armor(id) <= ma - 5) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 5);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 5 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 5, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 4 && get_user_armor(id) <= ma - 4) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 4);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 4 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 4, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 3 && get_user_armor(id) <= ma - 3) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 3);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 3 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 3, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost * 2 && get_user_armor(id) <= ma - 2) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost * 2);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 2 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 2, CS_ARMOR_VESTHELM);
	}
	else if(cs_get_user_money(id) >= apcost && get_user_armor(id) <= ma - 1) {
	cs_set_user_money(id, cs_get_user_money(id) - apcost);
	ColorChat(id, "^x03%s^x04 Ai cumparat^x03 1 AP.",Prefix);
	cs_set_user_armor(id, get_user_armor(id) + 1, CS_ARMOR_VESTHELM);
	}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deagle Stock |
//==========================================================================================================
//------| Zoom to Deagle |------//
public forward_cmdstart(id, uc_handle, seed) {
	if(get_pcvar_num(deaglezoom) == 0) {
	return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) {
	return PLUGIN_HANDLED;
	}
	new szWeapID = get_user_weapon(id, szClip, szAmmo);
	if(szWeapID != CSW_DEAGLE && hasZoom[id]) {
	hasZoom[id] = false;
	g_hasZoom[id] = true;
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
	}
	if((get_uc(uc_handle, UC_Buttons) & IN_RELOAD) && !(pev(id, pev_oldbuttons) & IN_RELOAD)) {
	g_hasZoom[id] = false;
	hasZoom[id] = false;
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
	}
	if(cs_get_user_shield(id)) {
	return PLUGIN_HANDLED;
	}
	else if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)) {
	new szWeapID = get_user_weapon(id, szClip, szAmmo);
	if(get_pcvar_num(deaglezoomstyle) == 0) {
	if(szWeapID == CSW_DEAGLE && hasZoom[id]) {
	hasZoom[id] = false;
	g_hasZoom[id] = true;
	cs_set_user_zoom(id, CS_SET_SECOND_ZOOM, 1);
	emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);
	}
	else if(szWeapID == CSW_DEAGLE && !g_hasZoom[id]) {
	hasZoom[id] = true;
	cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1);
	emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);
	}
	else if(g_hasZoom[id]) {
	g_hasZoom[id] = false;
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
	}
	}
	if(get_pcvar_num(deaglezoomstyle) != 0) {
	if(szWeapID == CSW_DEAGLE && !g_hasZoom[id]) {
	g_hasZoom[id] = true;
	cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
	emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);
	}
	else if(g_hasZoom[id]) {
	g_hasZoom[id] = false;
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
	}
	}
	}
	return PLUGIN_HANDLED;
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
// NightVision Stock |
//==========================================================================================================
//------| Give NightVision |------//
stock set_user_nvg(index, nvgoggles = 1) {
	new iNvgs = get_pdata_int(index, OFFSET_NVGOGGLES, 5);
	if(nvgoggles) {
	set_pdata_int(index, OFFSET_NVGOGGLES, get_pdata_int(index, OFFSET_NVGOGGLES) | HAS_NVGS);
	}
	else {
	if(iNvgs & USES_NVGS) {
	emit_sound(index, CHAN_ITEM, "items/nvg_off.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	emessage_begin(MSG_ONE, get_user_msgid("NVGToggle"), _, index);
	ewrite_byte(0);
	emessage_end();
	}
	set_pdata_int(index, OFFSET_NVGOGGLES, 0, 5);
	}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Invizibility Stock |
//==========================================================================================================
//------| Set Invizibility |------//
stock set_user_invizibility(id, invizibility = 1) {
	static iInvisLevel;
	if(invizibility){
	if(IsHoldingKnife(id)) {
	InvKnife(id);
	}
	if(is_user_alive(id)) {
	iInvisLevel = get_pcvar_num(invislevel);
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, iInvisLevel);
	g_hasInvizibility[id] = true;
	}
	}
	else {
	set_user_rendering(id);
	g_hasInvizibility[id] = false;
	}
	}
//------| Is Holding whith Knife |------//
// Function will return true if their active weapon is a knife
public IsHoldingKnife(id) {
	new iClip, iAmmo, iWeapon;
	iWeapon = get_user_weapon(id, iClip, iAmmo);
	if(iWeapon == CSW_KNIFE) {
	return true;
	}
	return false;
	}
public InvKnife(id) {
	static iInvisLevel;
	if(IsHoldingKnife(id)) {
	iInvisLevel = get_pcvar_num(invisknifelevel);
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, iInvisLevel);
	}
	else {
	iInvisLevel = get_pcvar_num(invislevel);
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, iInvisLevel);
	g_hasInvizibility[id] = true;
	}
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
// Hook Stock |
//==========================================================================================================
//------| Torgle Hook |------//
public hook_toggle(id,level,cid) {
	if(hookenable[id]) { 
	hook_off(id);
	return PLUGIN_HANDLED;
	}
	else {
	hook_on(id);
	return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
	}
//------| Start Hook |------//
public hook_on(id) {
	if(hookenable[id]) {
	return PLUGIN_HANDLED;
	}
	if(g_hasHook[id] <= 0) {
	ColorChat(id, "^x03%s^x04 Nu mai ai^x03 Hook.",Prefix);
	client_cmd(id,"unbind v");
	return PLUGIN_HANDLED;
	}
	set_user_gravity(id,0.0);
	set_task(0.1,"hook_prethink",id+10000,"",0,"b");
	hookenable[id] = true;
	g_hasHook[id] -= 1;
	hook_to[id][0]=999999;
	hook_prethink(id+10000);
	emit_sound(id,CHAN_ITEM,HOOK_FIRE,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	set_task(0.2,"HOOK_HT",id);
	return PLUGIN_HANDLED;
	}
//------| Stop Hook |------//
public hook_off(id) {
	if(is_user_alive(id)) {
	if(g_hasGravity[id] && hasGravity[id] && get_user_gravity(id) > get_pcvar_float(lowgravity)) {
	set_user_gravity(id, get_pcvar_float(lowgravity));
	}
	else {
	set_user_gravity(id);
	}
	if(g_hasSpeed[id] && hasSpeed[id] && get_user_maxspeed(id) > get_pcvar_float(highspeed)) {
	set_user_maxspeed(id, get_pcvar_float(highspeed));
	}
	else {
	set_user_maxspeed(id);
	}
	hookenable[id] = false;
	}
	return PLUGIN_HANDLED;
	}

//------| Effect Hook |------//
public hook_prethink(id) {
	id -= 10000;
	if(!is_user_alive(id)) {
	hookenable[id]=false;
	}
	if(!hookenable[id]) {
	remove_task(id+10000);
	return PLUGIN_HANDLED;
	}

	//Get Id's origin
	static origin1[3];
	get_user_origin(id,origin1);
	
	if(hook_to[id][0]==999999) {
	static origin2[3];
	get_user_origin(id,origin2,3);
	hook_to[id][0]=origin2[0];
	hook_to[id][1]=origin2[1];
	hook_to[id][2]=origin2[2];
	}
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(1);		//TE_BEAMENTPOINT
	write_short(id);	// start entity
	write_coord(hook_to[id][0]);
	write_coord(hook_to[id][1]);
	write_coord(hook_to[id][2]);
	write_short(hooksprite);
	write_byte(1);		// framestart
	write_byte(1);		// framerate
	write_byte(2);		// life in 0.1's
	write_byte(5);		// width
	write_byte(0);		// noise
	write_byte(0);		// red
	write_byte(200);	// green
	write_byte(0);		// blue
	write_byte(200);	// brightness
	write_byte(0);		// speed
	message_end();
	
	//Calculate Velocity
	static Float:velocity[3];
	velocity[0] = (float(hook_to[id][0]) - float(origin1[0])) * 3.0;
	velocity[1] = (float(hook_to[id][1]) - float(origin1[1])) * 3.0;
	velocity[2] = (float(hook_to[id][2]) - float(origin1[2])) * 3.0;
	
	static Float:y;
	y = velocity[0]*velocity[0] + velocity[1]*velocity[1] + velocity[2]*velocity[2];
	static Float:x;
	x = (get_pcvar_float(hookspeed) * 1.0) / floatsqroot(y);
	
	velocity[0] *= x;
	velocity[1] *= x;
	velocity[2] *= x;
	
	set_velo(id,velocity);
	return PLUGIN_CONTINUE;
	}

public get_origin(ent,Float:origin[3]) {
	#if defined engine
	return entity_get_vector(id,EV_VEC_origin,origin);
	#else
	return pev(ent,pev_origin,origin);
	#endif
	}

public set_velo(id,Float:velocity[3]) {
	#if defined engine
	return set_user_velocity(id,velocity);
	#else
	return set_pev(id,pev_velocity,velocity);
	#endif
	}
public HOOK_HT(id) {
	emit_sound(id,CHAN_ITEM,HOOK_HIT,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	}
	
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GodMode Stock |
//==========================================================================================================
//------| Remove GodMode |------//
public removeGodMode(id) {
	new gmtime = get_pcvar_num(godmodetime);
	set_user_godmode(id,0);
	emit_sound(id,CHAN_ITEM,GODMODE_SND,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	ColorChat(id, "^x03%s^x04 Au trecut cele^x03 %d^x04 secunde, nu mai ai ^x03GodMode^x04.", Prefix, gmtime);
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIP Online/List | VIP ScoreBoard
//==========================================================================================================
public print_adminlist(user) {
	new adminnames[33][32];
	new message[256];
	new id, count, x, len;
	
	for(id = 1 ; id <= maxplayers ; id++)
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
	Vault = nvault_open("DrShopPoints-Name");

	if(Vault == INVALID_HANDLE) {
	set_fail_state("[DrShop] nValut ERROR: =-> Invalid-Handle");
	}
	Vault2 = nvault_open("DrShopPoints-SteamID");
	if(Vault2 == INVALID_HANDLE) {
	set_fail_state("[DrShop] nValut ERROR: =-> Invalid-Handle");
	}
	//------| Save Whith SteamID |------//
	get_user_authid(id, SteamID, charsmax(SteamID));
	if(get_pcvar_num(dr_save_points) == 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", SteamID);
	formatex(Data, charsmax(Data), "%d", PlayerPoints[id]);
	nvault_set(Vault2, Key,Data);
	nvault_close(Vault2 );
	}
	//------| Save Whith Name |------//
	get_user_name(id, Name, 31);
	if(get_pcvar_num(dr_save_points) != 0) {
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
	Vault = nvault_open("DrShopPoints-Name");
	Vault2 = nvault_open("DrShopPoints-SteamID");
	if(Vault == INVALID_HANDLE) {
	set_fail_state("[DrShop] nValut ERROR: =-> Invalid-Handle");
	}
	if(Vault2 == INVALID_HANDLE) {
	set_fail_state("[DrShop] nValut ERROR: =-> Invalid-Handle");
	}
	//------| Load Whith SteamID |------//
	get_user_authid(id, SteamID, charsmax(SteamID));
	if(get_pcvar_num(dr_save_points) == 0) {
	formatex(Key, charsmax(Key), "%sPOINTS", Name);
	PlayerPoints[id] = nvault_get(Vault2, Key);
	nvault_close(Vault2);
	}
	//------| Load Whith Name |------//
	get_user_name (id, Name, 31);
	if(get_pcvar_num(dr_save_points) != 0) {
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
// Give Shield/Drop |
//==========================================================================================================
public DROP(id) {
	client_cmd(id,"drop");
	}
public SHIELD(id) {
	give_item(id, "weapon_shield");
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
	smoke = precache_model("sprites/DrShop/Jetpack1.spr");
	flame = precache_model("sprites/DrShop/Jetpack2.spr");
	hooksprite = precache_model("sprites/DrShop/Hook.spr");
	precache_model("models/rpgrocket.mdl");
	precache_model(parachute_model);
	precache_model(DEAGLE_MODEL_V);
	precache_model(DEAGLE_MODEL_P);
	precache_model(DEAGLE_SHIELD_V);
	precache_model(DEAGLE_SHIELD_P);
	precache_sound(BUY_SND);
	precache_sound(SELL_SND);
	precache_sound(ERROR_SND);
	precache_sound(ERROR2_SND);
	precache_sound(PARACHUTE_SND);
	precache_sound(LJ_SND);
	precache_sound(HP_SND);
	precache_sound(AP_SND);
	precache_sound(GRAVTIY_SND);
	precache_sound(SPEED_SND);
	precache_sound(NOCLIP_SND);
	precache_sound(NVG_SND);
	precache_sound(SHIELD_SND);
	precache_sound(JP_SND);
	precache_sound(JP2_SND);
	precache_sound(HOOK_FIRE);
	precache_sound(HOOK_HIT);
	precache_sound(INVIS_SND);
	precache_sound(GODMODE_SND);
	precache_sound(GLOW_SND);
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------| End Plugin |-----------------------------------------------------
//=========================================================================================================
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
