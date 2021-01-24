#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>    

#pragma semicolon 1;
#define RADIUS        400.0 // Affect radius
#define STR_T 32
#define MAX_PLAYERS 32

#define V_MODEL_KNIFE1 "models/KnifeMod/v_katana.mdl"
#define P_MODEL_KNIFE1 "models/KnifeMod/p_katana.mdl"
#define V_MODEL_KNIFE2 "models/KnifeMod/v_hunter.mdl"
#define P_MODEL_KNIFE2 "models/KnifeMod/p_hunter.mdl"
#define V_MODEL_KNIFE3 "models/KnifeMod/v_suriu.mdl"
#define P_MODEL_KNIFE3 "models/KnifeMod/p_suriu.mdl"
#define V_MODEL_KNIFE4 "models/KnifeMod/v_flyer.mdl"
//#define P_MODEL_KNIFE4 "models/KnifeMod/p_flyer.mdl"
#define V_MODEL_KNIFE5 "models/KnifeMod/v_cloack.mdl"
#define P_MODEL_KNIFE5 "models/KnifeMod/p_cloack.mdl"
#define V_MODEL_KNIFE6 "models/KnifeMod/v_shock.mdl"
#define P_MODEL_KNIFE6 "models/KnifeMod/p_shock.mdl"
#define V_MODEL_KNIFE7 "models/KnifeMod/v_hookman.mdl"
//#define P_MODEL_KNIFE7 "models/KnifeMod/p_hookman.mdl"
#define V_MODEL_KNIFE8 "models/KnifeMod/v_night.mdl"
//#define P_MODEL_KNIFE8 "models/KnifeMod/p_night.mdl"
#define V_MODEL_KNIFE9 "models/v_knife.mdl"
#define P_MODEL_KNIFE9 "models/p_knife.mdl"
#define PRIMARY_WEAPONS_BIT_SUM ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)|(1<<CSW_ELITE)|(1<<CSW_P228)) // You can allways add more 

new menu;
new knife_model[33];
new highspeed, health_add, health_max, damage, lowgravity, invislevel, health_add_time, gravity;
new beamSpr;
new dropdistance, dropcooldown;
new chance[33];
new msgScreenFade;
const FFADE_IN = 0x0000;
const FFADE_STAYOUT = 0x0004;
const UNIT_SECOND = (1<<12);
new is_cooldown_time[33] = 0;
new is_cooldown[33] = 0;
new bool:cd[33];    // Cooldown khi phong set
new Float:revenge_cooldown = 10; //cooldown time
new chance_to_cast = 0;  //chance in percent, where 10 = 1%, 235= 23.5% e t.c ( 1000 mean 100% ) .
new const sound_sleep[] = "KnifeMod/SleepImpact.wav"; //cast sound
new SndMiss[] = "KnifeMod/DragMiss.wav";
new SndDrag[] = "KnifeMod/DragHit.wav";
new Hooked[33], Unable2move[33], OvrDmg[33];
new Float:LastHook[33];
new bool: BindUse[33] = false, bool: Drag_I[33] = false;
new is_cooldown_time2[33] = 0;
new bool:cd2[33], bool:cda[33];
new dragspeed, dragcooldown, dragdmg2stop, dragmates, dragunb2move;
new Line, maxplayers;
new bool:regenerate[33];
new jumpznum[33] = 0;
new bool:dozjump[33] = false, bool:g_haschose[33];
new jumps;
public plugin_init() {
	register_plugin("KnifeMod", "1.0", "Aragon*");
	register_clcmd("knife","cmdknife");
	register_clcmd("say /knife","cmdknife");
	register_clcmd("say_team /knife","cmdknife");
	register_clcmd("say knife","cmdknife");
	register_clcmd("say_team knife","cmdknife");
	register_clcmd("+drag","drag_start", ADMIN_USER, "bind ^"key^" ^"+drag^"");
	register_clcmd("-drag","drag_end");
	register_event("Damage", "event_damage", "be" );
	register_event("CurWeapon","EventCurWeapon","be","1=1");
	register_event("ResetHUD", "newSpawn", "b");
	register_event("DeathMsg", "player_death", "a");
	register_logevent("roundStart", 2, "1=Round_Start");
	register_forward(FM_CmdStart, "fwd_cmd_start");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	damage = register_cvar("km_damage", "2");			// Damage la Katana Deffault: 2
	highspeed = register_cvar("km_highspeed","300");		// Viteza Suriu-lui deffault; 400
	lowgravity = register_cvar("km_lowgravity" , "0.69");		// Gravitatea la Flyer 0.4 inseamna sv_gravity 400
	invislevel = register_cvar("km_invis_level" , "0");		// Invizibilitate de la Cloack de la 0 complet inv si 255 complet vizibil
	health_add = register_cvar("km_addhealth", "10");		// Cat hp sai dea la fiecare interval de tmp jucatorului
	health_add_time = register_cvar("km_addhealth_time", "5.0");		// La cate secunde sai dea jucatorului HP
	health_max = register_cvar("km_maxhealth", "200");		// Maximum de HP pe care il poate primi un jucator
	dropdistance = register_cvar ( "km_drop_distzance", "5000" ); 	// Distanta maxima la care ajunge raza de aruncare a armei inamicului
	dropcooldown = register_cvar ( "km_drop_cooldown" , "10" );	// Timpul in care sa ii revina puterea inapoi la Shock
	dragspeed = register_cvar("km_dragspeed", "500");		// Viteza cu care este tras inamicuk
	dragcooldown = register_cvar("km_drag_cooldown", "10.0");	// Timpul in care sa ii revina puterea inapoi la Drag
	dragdmg2stop = register_cvar("km_drag_dmg2stop", "75");		// Damage to Stop
	dragmates = register_cvar("km_drag_mates", "0");			// Team Mates
	dragunb2move = register_cvar("km_drag_unable_move", "1");	// Unable Move
	jumps = register_cvar("km_multijump","1"); 			// De cate ori + 1 poate sari
	gravity = get_cvar_pointer("sv_gravity");
	msgScreenFade = get_user_msgid("ScreenFade");
	maxplayers = get_maxplayers();
	set_task(320.0, "kmodmsg", 0, _, _, "b");
	}
public plugin_precache() { 
	precache_model(V_MODEL_KNIFE1);
	precache_model(P_MODEL_KNIFE1);
	precache_model(V_MODEL_KNIFE2);
	precache_model(P_MODEL_KNIFE2);
	precache_model(V_MODEL_KNIFE3);
	precache_model(P_MODEL_KNIFE3);
	precache_model(V_MODEL_KNIFE4);
	//precache_model(P_MODEL_KNIFE4);
	precache_model(V_MODEL_KNIFE5);
	precache_model(P_MODEL_KNIFE5);
	precache_model(V_MODEL_KNIFE6);
	precache_model(P_MODEL_KNIFE6);
	precache_model(V_MODEL_KNIFE7);
	//precache_model(P_MODEL_KNIFE7);
	precache_model(V_MODEL_KNIFE8);
	//precache_model(P_MODEL_KNIFE8);
	precache_model(V_MODEL_KNIFE9);
	precache_model(P_MODEL_KNIFE9);
	precache_sound(SndDrag);
	precache_sound(SndMiss);
	precache_sound(sound_sleep);
	beamSpr = precache_model("sprites/lgtning.spr");
	Line = precache_model("sprites/zbeam4.spr");
	} 
public cmdknife(id) { 
	if(g_haschose[id]) {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales deja un^x03  Knife^x04 runda aceasta.");
	return PLUGIN_HANDLED;
	}
	menu = menu_create("\rKnifeMod\w \yby MzU*\w", "knifes");
	menu_additem(menu, "\wKatana - \y(More Damage)\w", "1", 0);
	menu_additem(menu, "\wHunter - \y(Silent Walk)\w", "2", 0);
	menu_additem(menu, "\wSuriu - \y(Speed)\w", "3", 0);
	menu_additem(menu, "\wFlyer - \y(Gravity)\w", "4", 0);	
	menu_additem(menu, "\wCloack - \y(Invizibility)\w", "5", 0);
	menu_additem(menu, "\wShock - \y(Drop Enemy Weapon)\w \rAdmin Only\w", "6", 0);
	menu_additem(menu, "\wHookMan - \y(Drag the Enemy)\w \rAdmin Only\w", "7", 0);
	menu_additem(menu, "\wJumper - \y(Multi Jump)\w \rAdmin Only\w", "8", 0);
	menu_additem(menu, "\wDeffault - \y(Regeneration)\w", "9", 0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
	}
public knifes(id, menu, item) {

	if (item == MENU_EXIT) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key) {
	case 1: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Katana Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 More Damage.");
	Knife(id, 1);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	case 2: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Hunter Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Silent Walk.");
	Knife(id, 2);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	case 3: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Suriu Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Speed.");
	Knife(id, 3);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	case 4: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Flyer Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Gravity.");
	Knife(id, 4);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	case 5: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Cloack Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Invizibility.");
	Knife(id, 5);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	case 6: {
	if(!is_user_admin(id)) {
	ColorChat(id,"^x03[Knife Mod]^x04 Doar^x03 Adminii^x04 pot alege acest quest.");
	}
	else {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Shock Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Drop Enemy Weapon.");
	ColorChat(id,"^x03[Knife Mod]^x04 Pentru a aruna armele inamicului apasa^x03 Click Dreapta.");
	if(is_cooldown_time[id]) {
	ShowHUD(id);
	}
	Knife(id, 6);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	}
	case 7: {
	if(!is_user_admin(id)) {
	ColorChat(id,"^x03[Knife Mod]^x04 Doar^x03 Adminii^x04 pot alege acest quest.");
	}
	else {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 HookMan.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Drag the Enemy.");
	ColorChat(id,"^x03[Knife Mod]^x04 Pentru a trage inamicul apasa tasta^x03 X.");
	client_cmd(id, "bind x +drag");
	if(is_cooldown_time2[id]) {
	ShowHUD(id);
	}
	Knife(id, 7);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	}
	case 8: {
	if(!is_user_admin(id)) {
	ColorChat(id,"^x03[Knife Mod]^x04 Doar^x03 Adminii^x04 pot alege acest quest.");
	}
	else {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Jumper.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Multi Jump.");
	Knife(id, 8);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	}
	case 9: {
	ColorChat(id,"^x03[Knife Mod]^x04 Ai ales^x03 Deffault Knife.");
	ColorChat(id,"^x03[Knife Mod]^x04 Power:^x03 Regenerate.");
	Knife(id, 9);
	EventCurWeapon(id);
	g_haschose[id] = true;
	}
	}
	SaveData(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
public Knife(id , Knife) {
	knife_model[id] = Knife;
	
	new Clip, Ammo, Weapon = get_user_weapon(id, Clip, Ammo) ;
	if ( Weapon != CSW_KNIFE )
	return PLUGIN_HANDLED;
	
	new vModel[56],pModel[56];
	
	switch(Knife) {
case 1: {
	format(vModel,55,V_MODEL_KNIFE1);
	format(pModel,55,P_MODEL_KNIFE1);
	}
case 2: {
	format(vModel,55,V_MODEL_KNIFE2);
	format(pModel,55,P_MODEL_KNIFE2);
	}
case 3: {
	format(vModel,55,V_MODEL_KNIFE3);
	format(pModel,55,P_MODEL_KNIFE3);
	}
case 4: {
	format(vModel,55,V_MODEL_KNIFE4);
	//format(vModel,55,P_MODEL_KNIFE4);
	}
case 5: {
	format(vModel,55,V_MODEL_KNIFE5);
	format(pModel,55,P_MODEL_KNIFE5);
	}
case 6: {
	if(is_user_admin(id)) {
	format(vModel,55,V_MODEL_KNIFE6);
	format(pModel,55,P_MODEL_KNIFE6);
	}
	}
case 7: {
	if(is_user_admin(id)) {
	format(vModel,55,V_MODEL_KNIFE7);
	//format(vModel,55,P_MODEL_KNIFE7);
	}
	}
case 8: {
	if(is_user_admin(id)) {
	format(vModel,55,V_MODEL_KNIFE8);
	//format(vModel,55,P_MODEL_KNIFE8);
	}
	}
case 9: {
	format(vModel,55,V_MODEL_KNIFE9);
	format(pModel,55,P_MODEL_KNIFE9);
	}
	}
	entity_set_string(id, EV_SZ_viewmodel, vModel);
	entity_set_string(id, EV_SZ_weaponmodel, pModel);
	return PLUGIN_HANDLED;  
	}
public event_damage(id) {
	new victim_id = id;
	if( !is_user_connected( victim_id ) ) return PLUGIN_CONTINUE;
	new dmg_take = read_data(2);
	new dmgtype = read_data( 3 );
	new Float:multiplier = get_pcvar_float(damage);
	new Float:damage = dmg_take * multiplier;
	new health = get_user_health( victim_id );
	new iWeapID, attacker_id = get_user_attacker( victim_id, iWeapID );
	
	if( !is_user_connected( attacker_id ) || !is_user_alive( victim_id ) ) {
	return PLUGIN_HANDLED;
	}
	if( iWeapID == CSW_KNIFE && knife_model[attacker_id] == 1 ) {
	if( floatround(damage) >= health ) {
	if( victim_id == attacker_id ) {
	return PLUGIN_CONTINUE;
	}
	else {
	log_kill( attacker_id, victim_id, "knife", 0 );
	}	
	return PLUGIN_CONTINUE;
	}
	else {
	if( victim_id == attacker_id ) return PLUGIN_CONTINUE;
	fakedamage( victim_id, "weapon_knife", damage, dmgtype );
	}
	}
	return PLUGIN_CONTINUE;
	}

public EventCurWeapon(id) {
	new Weapon = read_data(2);
	
	Knife(id, knife_model[id]);
	//2.Hunter
	if(knife_model[id] == 2 && Weapon == CSW_KNIFE) {
	set_user_footsteps(id , ((knife_model[id] == 2 && Weapon == CSW_KNIFE) ? 1 : 0));
	}
	//3.Suriu
	if(knife_model[id] == 3 && Weapon == CSW_KNIFE) {
	new Float:Speed;
	Speed = get_pcvar_float(highspeed);
	set_user_maxspeed(id, Speed);
	}
	//4.Man
	if (knife_model[id] == 4 && Weapon == CSW_KNIFE) {
	set_user_gravity(id, get_pcvar_float(lowgravity));
	}
	else {
	set_user_gravity(id , get_pcvar_float(gravity) / 800.0);
	}
	//5.Cloack
	if (knife_model[id] == 5 && Weapon == CSW_KNIFE) {
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, invislevel); 
	}
	else {
	set_user_rendering(id);
	}
	//8.Normal
	if (knife_model[id] == 9 && !task_exists(id) && Weapon == CSW_KNIFE && !regenerate[id]) {
	set_task(get_pcvar_float(health_add_time) , "task_healing",id,_,_,"b");
	regenerate[id] = true;
	}
	else {
	remove_task(id);
	regenerate[id] = false;
	}
	return PLUGIN_HANDLED;
	}

stock log_kill(killer, victim, weapon[],headshot) {
	user_silentkill( victim );
	message_begin( MSG_ALL, get_user_msgid( "DeathMsg" ), {0,0,0}, 0 );
	write_byte( killer );
	write_byte( victim );
	write_byte( headshot );
	write_string( weapon );
	message_end();
	new kfrags = get_user_frags( killer );
	set_user_frags( killer, kfrags++ );
	new vfrags = get_user_frags( victim );
	set_user_frags( victim, vfrags++ );
	return  PLUGIN_CONTINUE;
	} 


public task_healing(id) {  
	new addhealth = get_pcvar_num(health_add);
	if (!addhealth) {
	remove_task(id);
	return;
	}
	
	new maxhealth = get_pcvar_num(health_max);
	new health = get_user_health(id);
	if (health > maxhealth) { 
	health = health_max;
	remove_task(id);
	}  
	if (is_user_alive(id) && (health < maxhealth)) { 
	set_user_health(id, health + addhealth);
	set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.1, 4);
	show_hudmessage(id,"<< !!HEAL IN PROGRESS!! >>");
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(0);
	write_byte(200);
	write_byte(0);
	write_byte(75);
	message_end();
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id);
	write_string("cross");
	message_end();
	}
	} 

//----------| 6.Shock |----------//
public fwd_cmd_start(id, uc_handle, seed) {
	if (!is_user_alive(id) || !is_user_admin(id))
	return FMRES_IGNORED;
	if (knife_model[id] != 6)
	return FMRES_IGNORED;
	if (cd[id]) 
	return FMRES_IGNORED;
	new szClip,szAmmo, szWeapID = get_user_weapon(id, szClip, szAmmo);
	if(szWeapID != CSW_KNIFE)
	return FMRES_IGNORED;
	static buttons;
	buttons = get_uc(uc_handle, UC_Buttons);
	
	if(buttons & IN_ATTACK2) {
	dopukeA(id);
	cd[id] = true;
	}
	
	buttons &= ~IN_ATTACK2;
	set_uc(uc_handle, UC_Buttons, buttons);
	
	return FMRES_HANDLED;
	}

public dopukeA(id)  {
	new target, body;
	static Float:start[3];
	static Float:aim[3];

	pev(id, pev_origin, start);
	fm_get_aim_origin(id, aim);

	start[2] += 16.0; // raise
	aim[2] += 16.0; // raise
	get_user_aiming ( id, target, body, dropdistance );
	if( is_user_alive( target ) && cs_get_user_team(target) != cs_get_user_team(id)) {
	drop(target);
	}	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(0);
	engfunc(EngFunc_WriteCoord,start[0]);
	engfunc(EngFunc_WriteCoord,start[1]);
	engfunc(EngFunc_WriteCoord,start[2]);
	engfunc(EngFunc_WriteCoord,aim[0]);
	engfunc(EngFunc_WriteCoord,aim[1]);
	engfunc(EngFunc_WriteCoord,aim[2]);
	write_short(beamSpr); // sprite index
	write_byte(0); // start frame
	write_byte(30); // frame rate in 0.1's
	write_byte(20); // life in 0.1's
	write_byte(50); // line width in 0.1's
	write_byte(50); // noise amplititude in 0.01's
	write_byte(0); // red
	write_byte(100); // green
	write_byte(0); // blue
	write_byte(100); // brightness
	write_byte(50); // scroll speed in 0.1's
	message_end();
	is_cooldown_time[id] = get_pcvar_num(dropcooldown);
	ShowHUD(id);	
	return PLUGIN_CONTINUE;
	}

public client_damage(attacker,victim) {
	if ((knife_model[attacker] == 6) && (is_cooldown[victim] == 0)) {
	chance[victim] = random_num(0,999);
	if (chance[victim] < chance_to_cast) {
	message_begin(MSG_ONE, msgScreenFade, _, attacker);
	write_short(UNIT_SECOND); // duration
	write_short(0); // hold time
	write_short(FFADE_IN); // fade type
	write_byte(0); // red
	write_byte(0); // green
	write_byte(0); // blue
	write_byte(255); // alpha
	message_end();
		
	set_user_health(victim, get_user_health(victim) + ( get_user_health(victim) / 10 ) );
		
	set_task(4.0,"wake_up",attacker);
	emit_sound(attacker, CHAN_STREAM, sound_sleep, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
	is_cooldown[victim] = 1;
	}
	}
	}

public ShowHUD(id) {
	set_hudmessage(0, 100, 200, 0.05, 0.60, 0, 1.0, 1.1, 0.0, 0.0,-11);
	if (!is_user_alive(id)) {
	remove_task(id);
	return PLUGIN_HANDLED;
	}
	else if(knife_model[id] == 6 && cd[id]) {
	if(is_cooldown_time[id] <= 0) {
	show_hudmessage(id, "Ti-a revenit puterea");
	ColorChat(id,"^x03[Knife Mod]^x04 Iti poti folosi din nou puterea.");
	remove_task(id);
	is_cooldown[id] = 0;
	is_cooldown_time[id] = 0;
	cd[id] = false;
	}
	else {
	is_cooldown_time[id] --;
	show_hudmessage(id, "Puterea iti va reveni in: %d secunda/e",is_cooldown_time[id]);
	set_task(1.0, "ShowHUD", id);
	}
	}
	else if(knife_model[id] == 7 && cd2[id]) {
	if(is_cooldown_time2[id] <= 0) {
	show_hudmessage(id, "Ti-a revenit puterea");
	ColorChat(id,"^x03[Knife Mod]^x04 Iti poti folosi din nou puterea.");
	remove_task(id);
	cd2[id] = false;
	is_cooldown_time2[id] = 0;
	cda[id] = false;
	Drag_I[id] = false;
	}
	else {
	is_cooldown_time2[id] --;
	show_hudmessage(id, "Puterea iti va reveni in: %d secunda/e",is_cooldown_time2[id]);
	set_task(1.0, "ShowHUD", id);
	}
	}
	else {
	remove_task(id);
	}
	return PLUGIN_HANDLED;
	}
	
public wake_up(id) {
	message_begin(MSG_ONE, msgScreenFade, _, id);
	write_short(UNIT_SECOND); // duration
	write_short(0); // hold time
	write_short(FFADE_IN); // fade type
	write_byte(0); // red
	write_byte(0); // green
	write_byte(0); // blue
	write_byte(255); // alpha
	message_end();
	}

public roundStart() {
	for (new i = 1; i <= maxplayers; i++) {

	is_cooldown[i] = 0;
	cd[i] = false;
	is_cooldown_time[i] = 0;
	remove_task(i);
	}
	}
stock drop(id)  {
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++) {
	if (PRIMARY_WEAPONS_BIT_SUM & (1<<weapons[i]))  {
	static wname[32];
	get_weaponname(weapons[i], wname, sizeof wname - 1);
	engclient_cmd(id, "drop", wname);
	}
	}
	} 
	
//----------| 8.Predator |----------//
public newSpawn(id) {
	drag_end(id);
	cd2[id] = false;
	is_cooldown_time2[id] = 0;
	cda[id] = false;
	is_cooldown[id] = 0;
	cd[id] = false;
	is_cooldown_time[id] = 0;
	remove_task(id);
	g_haschose[id] = false;
	regenerate[id] = false;
	}
	
public drag_start(id) { // starts drag, checks if player is alive, checks cvars
	new szClip,szAmmo, szWeapID = get_user_weapon(id, szClip, szAmmo);
	if (knife_model[id] == 7 && !Drag_I[id] 	&& szWeapID == CSW_KNIFE && is_user_admin(id)) {

	if (!is_user_alive(id)) {
	return PLUGIN_HANDLED;
	}
	if (cd2[id]) {
	return PLUGIN_HANDLED;
	}
	new hooktarget, body;
	get_user_aiming(id, hooktarget, body);
		
	if (is_user_alive(hooktarget)) {
	if (cs_get_user_team(hooktarget) != cs_get_user_team(id)) {				
	Hooked[id] = hooktarget;
	emit_sound(hooktarget, CHAN_BODY, SndDrag, 1.0, ATTN_NORM, 0, PITCH_HIGH);
	}
	else {
	if (get_pcvar_num(dragmates) == 1)
	{
	Hooked[id] = hooktarget;
	emit_sound(hooktarget, CHAN_BODY, SndDrag, 1.0, ATTN_NORM, 0, PITCH_HIGH);
	}
	else {
	return PLUGIN_HANDLED;
	}
	}

	if (get_pcvar_float(dragspeed) <= 0.0)
	dragspeed = 1;
			
	new parm[2];
	parm[0] = id;
	parm[1] = hooktarget;
			
	set_task(0.1, "player_reelin", id, parm, 2, "b");
	harpoon_target(parm);
	Drag_I[id] = true;
	cd2[id] = true;
	cda[id] = false;
	if(get_pcvar_num(dragunb2move) == 1)
	Unable2move[hooktarget] = true;
				
	if(get_pcvar_num(dragunb2move) == 2)
	Unable2move[id] = true;
				
	if(get_pcvar_num(dragunb2move) == 3) {
	Unable2move[hooktarget] = true;
	Unable2move[id] = true;
	}
	} 
	else {
	Hooked[id] = 33;
	noTarget(id);
	cd2[id] = true;
	cda[id] = false;
	set_task(1.0,"drag_end",id);
	emit_sound(hooktarget, CHAN_BODY, SndMiss, 1.0, ATTN_NORM, 0, PITCH_HIGH);
	Drag_I[id] = true;
	}
	}
	else
	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
	}
	
public player_reelin(parm[]) { // dragging player
	new id = parm[0];
	new victim = parm[1];

	if (!Hooked[id] || !is_user_alive(victim)) {
	drag_end(id);
	return;
	}

	new Float:fl_Velocity[3];
	new idOrigin[3], vicOrigin[3];

	get_user_origin(victim, vicOrigin);
	get_user_origin(id, idOrigin);

	new distance = get_distance(idOrigin, vicOrigin);

	if (distance > 1) {
	new Float:fl_Time = distance / get_pcvar_float(dragspeed);

	fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time;
	fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time;
	fl_Velocity[2] = (idOrigin[2] - vicOrigin[2]) / fl_Time;
	}
	else {
	fl_Velocity[0] = 0.0;
	fl_Velocity[1] = 0.0;
	fl_Velocity[2] = 0.0;
	}

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity); //<- rewritten. now uses engine
	}

public drag_end(id) { // drags end function
	LastHook[id] = get_gametime();
	Hooked[id] = 0;
	beam_remove(id);
	Drag_I[id] = false;
	Unable2move[id] = false;
	if(cd2[id] && !cda[id]) {
	is_cooldown_time2[id] = get_pcvar_num(dragcooldown);
	ShowHUD(id);
	cda[id] = true;
	}
	}

public player_death() { // if player dies drag off
	new id = read_data(2);
	
	beam_remove(id);
	cd2[id] = false;
	cd[id] = false;
	is_cooldown_time2[id] = 0;
	cda[id] = false;
	LastHook[id] = get_gametime();
	Hooked[id] = 0;
	Drag_I[id] = false;
	Unable2move[id] = false;
	remove_task(id);
	if (Hooked[id])
	drag_end(id);
	}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage) { // if take damage drag off

	if (is_user_alive(attacker) && (get_pcvar_num(dragdmg2stop) > 0)) {
	OvrDmg[victim] = OvrDmg[victim] + floatround(damage);
	if (OvrDmg[victim] >= get_pcvar_num(dragdmg2stop)) {
	OvrDmg[victim] = 0;
	drag_end(victim);
	return HAM_IGNORED;
	}
	}

	return HAM_IGNORED;
	}
public fw_PlayerPreThink(id) {
	if (!is_user_alive(id))
	return FMRES_IGNORED;
	
	new button = get_user_button(id);
	new oldbutton = get_user_oldbutton(id);
	
	if (BindUse[id] && knife_model[id] == 7) {
	if (!(oldbutton & IN_USE) && (button & IN_USE))
	drag_start(id);
		
	if ((oldbutton & IN_USE) && !(button & IN_USE))
	drag_end(id);
	}
	
	if (!Drag_I[id]) {
	Unable2move[id] = false;
	}
		
	if (Unable2move[id] && get_pcvar_num(dragunb2move) > 0) {
	set_pev(id, pev_maxspeed, 1.0);
	}
	
	return PLUGIN_CONTINUE;
	}
public harpoon_target(parm[]) { // set beam (ex. tongue:) if target is player

	new id = parm[0];
	new hooktarget = parm[1];

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(8);	// TE_BEAMENTS
	write_short(id);
	write_short(hooktarget);
	write_short(Line);	// sprite index
	write_byte(0);	// start frame
	write_byte(0);	// framerate
	write_byte(200);	// life
	write_byte(8);	// width
	write_byte(1);	// noise
	write_byte(155);	// r, g, b
	write_byte(155);	// r, g, b
	write_byte(55);	// r, g, b
	write_byte(90);	// brightness
	write_byte(10);	// speed
	message_end();
	}

public noTarget(id) { // set beam if target isn't player
	new endorigin[3];

	get_user_origin(id, endorigin, 3);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_BEAMENTPOINT ); // TE_BEAMENTPOINT
	write_short(id);
	write_coord(endorigin[0]);
	write_coord(endorigin[1]);
	write_coord(endorigin[2]);
	write_short(Line); // sprite index
	write_byte(0);	// start frame
	write_byte(0);	// framerate
	write_byte(200);	// life
	write_byte(8);	// width
	write_byte(1);	// noise
	write_byte(155);	// r, g, b
	write_byte(155);	// r, g, b
	write_byte(55);	// r, g, b
	write_byte(75);	// brightness
	write_byte(0);	// speed
	message_end();
	}

public beam_remove(id) { // remove beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(99);	//TE_KILLBEAM
	write_short(id);	//entity
	message_end();
	}
	
//-----------| MultiJump |----------//
public client_PreThink(id) {
	new szClip,szAmmo, szWeapID = get_user_weapon(id, szClip, szAmmo);
	if (knife_model[id] != 8  || !is_user_alive(id) || szWeapID != CSW_KNIFE || !is_user_admin(id)) return PLUGIN_CONTINUE;
    
	new nzbut = get_user_button(id);
	new ozbut = get_user_oldbutton(id);
	if((nzbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(ozbut & IN_JUMP)) {
	if (jumpznum[id] < get_pcvar_num(jumps)) {
	dozjump[id] = true;
	jumpznum[id]++;
	return PLUGIN_CONTINUE;
	}
	}
	if((nzbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND)) {
	jumpznum[id] = 0;
	return PLUGIN_CONTINUE;
	}    
	return PLUGIN_CONTINUE;
	}

public client_PostThink(id) {
	new szClip,szAmmo, szWeapID = get_user_weapon(id, szClip, szAmmo);
	if (knife_model[id] != 8  || !is_user_alive(id) || szWeapID != CSW_KNIFE || !is_user_admin(id)) return PLUGIN_CONTINUE;
    
	if(dozjump[id] == true) {
	new Float:vezlocityz[3];  
	entity_get_vector(id,EV_VEC_velocity,vezlocityz);
	vezlocityz[2] = random_float(265.0,285.0);
	entity_set_vector(id,EV_VEC_velocity,vezlocityz);
	dozjump[id] = false;
	return PLUGIN_CONTINUE;
	}    
	return PLUGIN_CONTINUE;
	}  
	
public client_putinserver(id) {
	if(task_exists(id)) remove_task(id);
	is_cooldown[id] = 0;
	is_cooldown_time2[id] = 0;
	is_cooldown_time[id] = floatround(revenge_cooldown);
	cd2[id] = false;
	cd[id] = false;
	jumpznum[id] = 0;
	dozjump[id] = false;
	}
	
public client_disconnect(id) {  
	if(task_exists(id)) remove_task(id);
	is_cooldown[id] = 0;
	is_cooldown_time2[id] = 0;
	is_cooldown_time[id] = floatround(revenge_cooldown);
	cd2[id] = false;
	cd[id] = false;
	jumpznum[id] = 0;
	dozjump[id] = false;
	}
	
public client_authorized(id) {
	LoadData(id);
	}
	
SaveData(id) { 
	new authid[32];
	get_user_authid(id, authid, 31);
	new vaultkey[64];
	new vaultdata[64];
	format(vaultkey, 63, "KMOD_%s", authid);
	format(vaultdata, 63, "%d", knife_model[id]);
	set_vaultdata(vaultkey, vaultdata);
	}

LoadData(id) { 
	new authid[32];
	get_user_authid(id,authid,31);
	new vaultkey[64], vaultdata[64];
	format(vaultkey, 63, "KMOD_%s", authid);
	get_vaultdata(vaultkey, vaultdata, 63);
	knife_model[id] = str_to_num(vaultdata);
	}
public kmodmsg() { 
	ColorChat(0, "^x04Scrie^x03 /knife^x04 in chat pentru ati alege un cutit..");
	}  
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
