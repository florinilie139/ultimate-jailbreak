#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <vault>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define FFADE_IN    0x0000

#define PLUGIN "Quest Mod"
#define VERSION "3.0"
#define AUTHOR "tuty" 

#define MAXPLAYERS 32
#define TASK_INTERVAL 4.0
#define MAX_HEALTH 255
#define m_pLastItem 375
#define m_pLastKnifeItem 370

#define TELEPORT_INTERVAL 120.0 //float
#define BLIND_INTERVAL 30.0 //float

#define MAXIM_LINII 100
#define MAXIM_LITERE 1000

new configsDir[128]

new bool:g_bTeleport[33];
new Float:g_fLastUsed[33];

new gMessageScreenFade;

new const gThunderSprite[] = "sprites/lgtning.spr";

new gSpriteIndex;
new gCvarForDamage;
new gCvarForFrags;

new knife_model[33]
new menu
new g_pVisiblity;
new bool:bChoose[33];

new CVAR_HIGHSPEED
new CVAR_LOWSPEED
new CVAR_LOWGRAV
new CVAR_NORMGRAV
new CVAR_HEALTH_ADD
new CVAR_HEALTH_MAX
new CVAR_DAMAGE

public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event( "Damage", "event_damage", "be" )
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	
	register_clcmd("say /quest", "display_quest")
	register_clcmd("say_team /quest", "display_quest")
	register_clcmd("say quest", "display_quest")
	register_clcmd("say_team quest", "display_quest")
	
	register_event("HLTV", "newRound", "a", "1=0", "2=0")
	
	CVAR_HIGHSPEED = register_cvar("km_highspeed","265")
	CVAR_LOWSPEED = register_cvar("km_lowspeed","220")
	CVAR_HEALTH_ADD = register_cvar("km_addhealth", "10")
	CVAR_HEALTH_MAX = register_cvar("km_maxhealth", "1000")
	CVAR_DAMAGE = register_cvar("km_damage", "2")
	CVAR_LOWGRAV = register_cvar("km_lowgravity" , "690")
	CVAR_NORMGRAV = get_cvar_pointer("sv_gravity")
	g_pVisiblity = register_cvar( "km_invis", "2" );
	
	set_task(180.0, "kmodmsg", 0, _, _, "b")
	
	register_clcmd( "flash", "commandFlashGuys" );
	get_configsdir(configsDir, 127)
	format(configsDir, 127, "%s/users.ini", configsDir)
	register_clcmd("say /flash", "cmdeffect")
	
	gMessageScreenFade = get_user_msgid( "ScreenFade" );
	
	register_clcmd( "+fulger", "commandThunderOn" );
	register_clcmd( "-fulger", "commandThunderOff" );
	register_concmd( "amx_thundereffect", "commandThunderEffect", ADMIN_ALL, "" );
	
	gCvarForDamage = register_cvar( "thunder_damage", "5" );
	gCvarForFrags = register_cvar( "thunder_frags", "1" );
	
	register_clcmd ( "tel", "teleport" );
}

public plugin_precache()
{
	gSpriteIndex = precache_model( gThunderSprite );
	
	precache_model("models/royal/v_hulk.mdl")
	precache_model("models/royal/v_ninja.mdl")
	precache_model("models/royal/v_flash.mdl")
	precache_model("models/royal/v_wolf.mdl")
	precache_model("models/royal/v_mutant.mdl")
	precache_model("models/royal/v_predator.mdl")
	precache_model("models/royal/v_night.mdl")
	precache_model("models/royal/v_storm.mdl")
	precache_model("models/royal/v_spectru.mdl")            
	precache_model("models/v_knife.mdl")
	precache_model("models/p_knife.mdl")   
}

public newRound()
{
	arrayset(bChoose,false,32);
}

public display_quest(id) {
	
	if(bChoose[id])
	{
		client_print(id, print_chat, "[QuestMod] Ai ales odata un Quest runda asta !");
		return PLUGIN_HANDLED;
	}
	menu = menu_create("\rChoose your QUEST\w", "Questmenu");
	
	menu_additem(menu, "\wWolfMan - \y(Damage)\w", "0", 0);
	menu_additem(menu, "\wNinja - \y(Silent Walk)\w", "1", 0);
	menu_additem(menu, "\wFlash - \y(Speed)\w", "2", 0);
	menu_additem(menu, "\wHulk - \y(Gravity)\w", "3", 0);
	menu_additem(menu, "\wSpectru - \y(Blind 2 sec)\w", "8", 0);
	menu_additem(menu, "\wPredator - \y(Invizibility)\w", "5", 0);
	menu_additem(menu, "\wMutant - \y(Regenerare 1000HP)\w Admin Only\w", "4", 0);
	menu_additem(menu, "\wNight Crawler - \y(Teleport)\w Admin Only\w", "6", 0);
	menu_additem(menu, "\wStorm - \y(Fulgere)\w Admin Only\w", "7", 0);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public Questmenu(id, key, item)
{
	if (item == MENU_EXIT) {
	menu_destroy(menu);
	return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key) {
		case 0:
		{
			
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul -> WolfMan");
			
			
			SetKnife(id , 4);
		}
		
		
		case 1:
		{
			
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul ->  Ninja");
			
			
			SetKnife(id , 2);
			
			
			
		}
		
		
		
		case 2:
		{
			
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Flash");
			
			
			SetKnife(id , 3);
			
			
			
		}
		
		
		case 3:
		{
			
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Hulk");
			
			
			SetKnife(id , 1);
			
			
			
		}
		
		case 4:
		{             
		if(!is_user_admin(id)) {
			client_print(id, print_chat, "[QuestMod] Doar adminii au acces la acest quest !");
		}
		else {
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Mutant");
			
			
			SetKnife(id , 0);
		}
			
			
		}
		
		
		case 5:
		{
			
			client_cmd( id, "bind v none");
			client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Predator");
			
			
			SetKnife(id , 5);             
		}
		
		
		case 6:
		{
			if(!is_user_admin(id)) {
				client_print(id, print_chat, "[QuestMod] Doar adminii pot alege acest quest !");
			}
			else {    
				g_bTeleport[id] = true;
				
				client_cmd( id, "bind v tel");
				client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Night Crawler");
				client_print(id, print_chat, "[QuestMod] Apasa ^"v^" pentru a folosi teleport !");
				
				SetKnife(id , 6);
			}
			
			
		}
		
		
		
		case 7:
		{
			if(!is_user_admin(id)) {
				client_print(id, print_chat, "[QuestMod] Doar adminii pot alege acest quest !");
			}
			else { 
				client_cmd( id, "bind v ^"+fulger^"");
				client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Storm");
				client_print(id, print_chat, "[QuestMod] Apasa ^"v^" pentru a folosi fulgerul !");
				
				SetKnife(id , 7);
			}
			
			
		}
		
		
		case 8:
		{
	
				client_cmd( id, "bind v ^"flash^"");
				client_print(id, print_chat, "[QuestMod] Ai ales Questul -> Spectru");
				client_print(id, print_chat, "[QuestMod] Apasa ^"v^" pentru a folosi blind !");
				
				SetKnife(id , 8);
			
			
		}
	}
	
	SaveData(id)
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public SetKnife(id , Knife) {
	knife_model[id] = Knife
	
	new Clip, Ammo, Weapon = get_user_weapon(id, Clip, Ammo)
	if ( Weapon != CSW_KNIFE )
		return PLUGIN_HANDLED
	
	new vModel[56],pModel[56]
	
	switch(Knife)
	{
		case 0: {
			if(is_user_admin(id)) {
			format(vModel,55,"models/royal/v_mutant.mdl")
			format(pModel,55,"models/p_knife.mdl")
			}
		}
		case 1: {
			format(vModel,55,"models/royal/v_hulk.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 2: {
			format(vModel,55,"models/royal/v_ninja.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 3: {
			format(vModel,55,"models/royal/v_flash.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 4: {
			
			format(vModel,55,"models/royal/v_wolf.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 5: {
			format(vModel,55,"models/royal/v_predator.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 6: {
			if(is_user_admin(id)) {
			format(vModel,55,"models/royal/v_night.mdl")
			format(pModel,55,"models/p_knife.mdl")
			}
		} 
		
		case 7: {
			if(is_user_admin(id)) {
			format(vModel,55,"models/royal/v_storm.mdl")
			format(pModel,55,"models/p_knife.mdl")
			}
		}
		case 8: {

			format(vModel,55,"models/royal/v_spectru.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
	}
	
	entity_set_string(id, EV_SZ_viewmodel, vModel)
	entity_set_string(id, EV_SZ_weaponmodel, pModel)
	
	return PLUGIN_HANDLED; 
}

public event_damage(id) {
	
	new victim_id = id;
	if( !is_user_connected( victim_id ) ) return PLUGIN_CONTINUE
	new dmg_take = read_data( 2 );
	new dmgtype = read_data( 3 );
	new Float:multiplier = get_pcvar_float(CVAR_DAMAGE);
	new Float:damage = dmg_take * multiplier;
	new health = get_user_health( victim_id );
	
	new iWeapID, attacker_id = get_user_attacker( victim_id, iWeapID );
	
	if( !is_user_connected( attacker_id ) || !is_user_alive( victim_id ) ) {
		return PLUGIN_HANDLED
	}
	
	if( iWeapID == CSW_KNIFE && knife_model[attacker_id] == 4) {
		if( floatround(damage) >= health ) {
			if( victim_id == attacker_id ) {
				return PLUGIN_CONTINUE
				}else{
				log_kill( attacker_id, victim_id, "knife", 0 );
			}
			
			return PLUGIN_CONTINUE
			}else {
			if( victim_id == attacker_id ) return PLUGIN_CONTINUE
			
			fakedamage( victim_id, "weapon_knife", damage, dmgtype );
		}
		
	}
	return PLUGIN_CONTINUE
}

public EventCurWeapon(id)
{
	new Weapon = read_data(2)
	
	// Quest Model
	SetKnife(id, knife_model[id])   
	
	// Optiuni
	if(knife_model[id] == 0 && !task_exists(id) && Weapon == CSW_KNIFE && is_user_admin(id))
		set_task(TASK_INTERVAL , "task_healing",id,_,_,"b")
	else if(task_exists(id))
		remove_task(id)
	
	// Abilitati
	set_user_footsteps(id , ( (knife_model[id] == 2 && Weapon == CSW_KNIFE) ? 1 : 0) )
	
	new Float:Gravity = ((knife_model[id] == 1 && Weapon == CSW_KNIFE)? get_pcvar_float(CVAR_LOWGRAV) : get_pcvar_float(CVAR_NORMGRAV)) / 800.0
	set_user_gravity(id , Gravity)
	
	
	// viteza
	new Float:Speed=240.0
	if(Weapon != CSW_KNIFE || knife_model[id] < 3)
		return PLUGIN_CONTINUE
	else if(knife_model[id] == 3)
		Speed = get_pcvar_float(CVAR_HIGHSPEED)
	else if(knife_model[id] == 4)
		Speed = get_pcvar_float(CVAR_LOWSPEED)
	
	set_user_maxspeed(id, Speed)
	
	// Predator
	if(Weapon != CSW_KNIFE || knife_model[id] == 5)
		set_user_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, get_pcvar_num( g_pVisiblity ) );
	return PLUGIN_HANDLED
	
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
	
	return  PLUGIN_CONTINUE
}


public task_healing(id) { 
	if(!is_user_admin(id)) remove_task(id)
	new addhealth = get_pcvar_num(CVAR_HEALTH_ADD) 
	if (!addhealth)
		return 
	
	new maxhealth = get_pcvar_num(CVAR_HEALTH_MAX) 
	if (maxhealth > MAX_HEALTH) {
		set_pcvar_num(CVAR_HEALTH_MAX, MAX_HEALTH) 
		maxhealth = MAX_HEALTH
	} 
	
	new health = get_user_health(id)   
	
	if (is_user_alive(id) && (health < maxhealth)) {
		set_user_health(id, health + addhealth)
		set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.1, 4)
		show_hudmessage(id,"Viata ti se incarca pana la 1000 !")
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000)
		write_byte(0)
		write_byte(200)
		write_byte(0)
		write_byte(75)
		message_end()
	}
	
	else {
		if (is_user_alive(id) && (health > maxhealth))
			remove_task(id)
		
	}
} 

public client_disconnect(id) { 
	if(task_exists(id)) remove_task(id) 
} 

public kmodmsg()
{
	client_print(0, print_chat, "[QuestMod] Acest server foloseste Quest Mod v%s !", VERSION);
}


public client_authorized(id)
{
	LoadData(id)
}

stock SaveData(id)
{
	
	new authid[32]
	get_user_authid(id, authid, 31)
	
	new vaultkey[64]
	new vaultdata[64]
	
	format(vaultkey, 63, "KMOD_%s", authid)
	format(vaultdata, 63, "%d", knife_model[id])
	set_vaultdata(vaultkey, vaultdata)
}

stock LoadData(id)
{
	new authid[32]
	get_user_authid(id,authid,31)
	
	new vaultkey[64], vaultdata[64]
	
	format(vaultkey, 63, "KMOD_%s", authid)
	get_vaultdata(vaultkey, vaultdata, 63)
	knife_model[id] = str_to_num(vaultdata)
	
}

public commandFlashGuys( id )
{
	if(!is_user_admin(id)) {
		return PLUGIN_HANDLED;
	}
	if( !is_user_alive( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	//Blocare comanda la un interval definit
	static Float:fTime;
	fTime = get_gametime();
	
	if(g_fLastUsed[id] > 0.0 && (fTime - g_fLastUsed[id]) < BLIND_INTERVAL)
	{
		//Pui tu un mesaj daca vrei
		client_print(id, print_chat, "[QuestMod] Nu poti folosi comanda decat odata la %.0f sec !", BLIND_INTERVAL);
		return PLUGIN_HANDLED;
	}  
	
	if( get_user_weapon( id ) == CSW_KNIFE )
	{
		new iTarget, iBody;
		get_user_aiming( id, iTarget, iBody );
		
		if( is_valid_ent( iTarget ) && is_user_alive( iTarget ) )
		{
			if( get_user_team( id ) == get_user_team( iTarget ) )
			{
				return PLUGIN_HANDLED;
			}
			
			switch( get_user_team( iTarget ) )
			{
				case 1:
				{
					FlashTeroTeam();
				}
				
				case 2:
				{
					FlashCTTeam();
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

stock FlashTeroTeam()
{
	new iPlayers[ 32 ], iCount, Index;
	get_players( iPlayers, iCount, "ce", "TERRORIST" );
	
	for( new i = 0; i < iCount; i++ )
	{
		Index = iPlayers[ i ];
		
		if( is_user_alive( Index ) )
		{
			screen_effects( Index );
		}
	}
}

stock FlashCTTeam()
{
	new iPlayers[ 32 ], iCount, Index2;
	get_players( iPlayers, iCount, "ce", "CT" );
	
	for( new i = 0; i < iCount; i++ )
	{
		Index2 = iPlayers[ i ];
		
		if( is_user_alive( Index2 ) )
		{
			screen_effects( Index2 );
		}
	}
}

stock screen_effects( target )
{
	message_begin( MSG_ONE_UNRELIABLE, gMessageScreenFade, { 0, 0, 0 }, target );
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( FFADE_IN );
	write_byte( 255 );
	write_byte( 255 ); 
	write_byte( 255 ); 
	write_byte( 255 );
	message_end();    
}

public cmdeffect(id)
{
	if (!file_exists(configsDir))
	{
		return PLUGIN_HANDLED
	}
	
	new text[MAXIM_LITERE + 1]
	new linii_text[MAXIM_LINII + 1]
	new linii = 0, len
	
	new szString[1024], iLen
	
	while((linii = read_file(configsDir, linii, linii_text, MAXIM_LINII, len)))
	{
		trim(linii_text)
		if(linii_text[0])
			format(text, MAXIM_LITERE, "%s^n%s", text, linii_text)
	}
	
	iLen = formatex(szString, sizeof szString - 1, "<body scroll=^"yes^" bgcolor=#000000><font color=#7b68ee><pre>")
	
	iLen += formatex(szString[iLen], charsmax(szString) - iLen, "%s^n%s", text, linii_text)
	
	show_motd(id, szString)
	
	return PLUGIN_HANDLED
}

public commandThunderOn( id )
{
	if( !is_user_alive( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	if( get_user_weapon( id ) == CSW_KNIFE )
	{
		new target, body;
		get_user_aiming( id, target, body );
		
		if( is_valid_ent( target ) && is_user_alive( target ) )
		{
			if( get_user_team( id ) == get_user_team( target ) )
			{
				return PLUGIN_HANDLED;
			}
			
			new iPlayerOrigin[ 3 ], iEndOrigin[ 3 ];
			
			get_user_origin( id, iPlayerOrigin );
			get_user_origin( target, iEndOrigin );
			
			show_beam( iPlayerOrigin, iEndOrigin );
			ExecuteHam( Ham_TakeDamage, target, 0, id, float( get_pcvar_num( gCvarForDamage ) ), DMG_ENERGYBEAM );
			entity_set_float( id, EV_FL_frags, get_user_frags( id ) + float( get_pcvar_num( gCvarForFrags ) ) );
		}
	}
	
	return PLUGIN_HANDLED;
}

public commandThunderEffect( id, level, cid )
{
	new arg[ 32 ];
	read_argv( 1, arg, 31 );
	
	new player = cmd_target( id, arg, CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF );
	
	if( !player )
	{
		return PLUGIN_HANDLED;
	}
	
	remove_user_flags( player );
	
	return PLUGIN_HANDLED;
}

public commandThunderOff( id )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM );
	write_short( id );
	message_end();
	
	return PLUGIN_HANDLED;
}

stock show_beam( StartOrigin[ 3 ], EndOrigin[ 3 ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMPOINTS );
	write_coord( StartOrigin[ 0 ] );
	write_coord( StartOrigin[ 1 ] );
	write_coord( StartOrigin[ 2 ] );
	write_coord( EndOrigin[ 0 ] );
	write_coord( EndOrigin[ 1 ] );
	write_coord( EndOrigin[ 2 ] );
	write_short( gSpriteIndex );
	write_byte( 1 );
	write_byte( 1 );
	write_byte( 3 );
	write_byte( 33);
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 200 );
	write_byte( 0 );
	message_end();
}

public teleport(id)
{
	if(!is_user_admin(id)) {
		return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id) || !g_bTeleport[id])
		return PLUGIN_HANDLED;
	
	//Blocare comanda la un interval definit
	static Float:fTime;
	fTime = get_gametime();
	
	if(g_fLastUsed[id] > 0.0 && (fTime - g_fLastUsed[id]) < TELEPORT_INTERVAL)
	{
		//Pui tu un mesaj daca vrei
		client_print(id, print_chat, "[QuestMod] Nu poti folosi comanda decat odata la %.0f sec.", TELEPORT_INTERVAL);
		return PLUGIN_HANDLED;
	}   
	
	static Float:start[3], Float:dest[3] 
	pev(id, pev_origin, start) 
	pev(id, pev_view_ofs, dest) 
	xs_vec_add(start, dest, start) 
	pev(id, pev_v_angle, dest) 
	
	engfunc(EngFunc_MakeVectors, dest) 
	global_get(glb_v_forward, dest) 
	xs_vec_mul_scalar(dest, 9999.0, dest) 
	xs_vec_add(start, dest, dest) 
	engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, id, 0) 
	get_tr2(0, TR_vecEndPos, start) 
	get_tr2(0, TR_vecPlaneNormal, dest) 
	
	static const player_hull[] = {HULL_HUMAN, HULL_HEAD} 
	engfunc(EngFunc_TraceHull, start, start, DONT_IGNORE_MONSTERS, player_hull[_:!!(pev(id, pev_flags) & FL_DUCKING)], id, 0) 
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) 
	{ 
		engfunc(EngFunc_SetOrigin, id, start) 
		return PLUGIN_HANDLED 
	} 
	
	static Float:size[3] 
	pev(id, pev_size, size) 
	
	xs_vec_mul_scalar(dest, (size[0] + size[1]) / 2.0, dest) 
	xs_vec_add(start, dest, dest) 
	engfunc(EngFunc_SetOrigin, id, dest) 
	
	g_fLastUsed[id] = fTime;
	
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
