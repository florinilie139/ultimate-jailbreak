/*
Plugin: Amx Ejaculate
Version: 0.1
Author: KRoTaL

0.1  Release


Commands: 

	To ejaculate on a dead body you have to bind a key to: ejaculate
	Open your console and type: bind "key" "ejaculate"
	ex: bind "x" "ejaculate"
	Then stand still above a dead player (cs/cz only), press your key and you'll ejaculate on them ! 
	You can control the direction of the stream with your mouse.

	Players can say "/ejaculate" in the chat to get some help.

Cvars:

	amx_maxejaculations 6		-	Maximum number of times a player is allowed to ejaculate per round.

	amx_ejaculate_admin 0		-	0 : All the players are allowed to ejaculate
							1 : Only admins with ADMIN_LEVEL_A flag are allowed to ejaculate

Setup:

	You need to put these files on your server:

	sound/ejaculate/ejaculate.wav
	addons/amx/lang/ejaculate.txt

*/

// UNCOMMENT IF YOU USE ANOTHER MOD THAN CS and CS-CZ
//#define NO_CS_CZ




/***************************************************************************************************/

#include <amxmodx> 
#include <ujbm>

new count_ejaculate[33]
new bool:EjaculateFlag[33]
new bool:aim[33]
new counter[33]
#if !defined NO_CS_CZ
new player_origins[33][3]
#endif

public ejaculate_on_player(id) 
{

if (get_cvar_num("amx_maxejaculations")==0) 
	return PLUGIN_HANDLED 
if (!is_user_alive(id)) 
	return PLUGIN_HANDLED 
if ( (get_cvar_num("amx_ejaculate_admin")==1) && !(get_user_flags(id) & ADMIN_LEVEL_A) && get_vip(id) == false)
{
	console_print(id,"[AMXX] N-ai frate access la comanda. PA")
	return PLUGIN_HANDLED
}
if(EjaculateFlag[id])
	return PLUGIN_HANDLED

#if !defined NO_CS_CZ
new player_origin[3], players[32], inum=0, dist, last_dist=99999, last_id 

get_user_origin(id,player_origin,0) 
get_players(players,inum,"b") 
if (inum>0) { 
	for (new i=0;i<inum;i++) { 
		if (players[i]!=id) { 
			dist = get_distance(player_origin,player_origins[players[i]]) 
			if (dist<last_dist) { 
				last_id = players[i] 
				last_dist = dist 
			} 
		} 
	} 
	if (last_dist<80) { 
#endif
		if (count_ejaculate[id] > get_cvar_num("amx_maxejaculations")) { 
			client_print(id,print_chat,"Poti ejacula pe un jucator doar de %d ori pe runda !", get_cvar_num("amx_maxejaculations")) 
			return PLUGIN_CONTINUE 
		}
		new player_name[32] 
		get_user_name(id, player_name, 31)
		#if !defined NO_CS_CZ
		new dead_name[32]
		get_user_name(last_id, dead_name, 31)
		client_print(0,print_chat,"%s ejaculeaza pe cadavrul lui %s ! BwHaHaHaHa!", player_name, dead_name)
		#else
		client_print(0,print_chat,"%s ejaculeaza!", player_name)
		#endif
		count_ejaculate[id]+=1
		new ids[1]
		ids[0]=id
		EjaculateFlag[id]=true
		aim[id]=false
		counter[id]=0
		emit_sound(id, CHAN_VOICE, "ejaculate/ejaculate.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
		set_task(1.0,"make_ejaculate",4210+id,ids,1,"a",10)
#if !defined NO_CS_CZ
	}
	else
	{
		client_print(id,print_chat,"Unde e ma cadavru?")
		return PLUGIN_HANDLED
	}
}
#endif

return PLUGIN_HANDLED
}

public sqrt(num) 
{ 
	new div = num 
	new result = 1 
	while (div > result) { 
		div = (div + result) / 2 
		result = num / div 
	} 
	return div 
} 

public make_ejaculate(ids[]) 
{ 
	new id=ids[0]
	new vec[3] 
	new aimvec[3] 
	new velocityvec[3] 
	new length 
	get_user_origin(id,vec) 
	get_user_origin(id,aimvec,3) 
	new distance = get_distance(vec,aimvec) 
	new speed = floatround(distance*1.9)

	velocityvec[0]=aimvec[0]-vec[0] 
	velocityvec[1]=aimvec[1]-vec[1] 
	velocityvec[2]=aimvec[2]-vec[2] 

	length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 

	velocityvec[0]=velocityvec[0]*speed/length 
	velocityvec[1]=velocityvec[1]*speed/length 
	velocityvec[2]=velocityvec[2]*speed/length 

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(101)
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2])
	write_coord(velocityvec[0]) 
	write_coord(velocityvec[1]) 
	write_coord(velocityvec[2]) 
	write_byte(6) // color
	write_byte(160) // speed
	message_end()

	counter[id]++
	if(counter[id]==10)
		EjaculateFlag[id]=false
} 

public death_event() 
{ 
   	new victim = read_data(2)
 	#if !defined NO_CS_CZ  	
	get_user_origin(victim,player_origins[victim],0) 
	#endif

	if(EjaculateFlag[victim]) 
		reset_ejaculate(victim)

   	return PLUGIN_CONTINUE 
}

public reset_ejaculate(id) 
{
	if(task_exists(4210+id))
		remove_task(4210+id)
	emit_sound(id,CHAN_VOICE,"ejaculate/ejaculate.wav", 0.0, ATTN_NORM, 0, PITCH_NORM) 
	EjaculateFlag[id]=false

	return PLUGIN_CONTINUE 
}

public reset_hud(id)
{
	if(task_exists(4210+id))
		remove_task(4210+id)
	emit_sound(id,CHAN_VOICE,"ejaculate/ejaculate.wav", 0.0, ATTN_NORM, 0, PITCH_NORM) 
	EjaculateFlag[id]=false

	count_ejaculate[id]=1

	return PLUGIN_CONTINUE 
} 

public ejaculate_help(id) 
{
	client_print(id, print_chat, "Pentru a ejacula pe un cadavru trebuie sa dati bind la ejaculare")
	client_print(id, print_chat, "Deschide consola si tasteaza: bind ^"key^" ^"ejaculate^"")
	client_print(id, print_chat, "exemplu: bind ^"x^" ^"ejaculate^"")

	return PLUGIN_CONTINUE
}

public handle_say(id) 
{
	new said[192]
	read_args(said,192)
	remove_quotes(said)

	if( ((containi(said, "ejaculate") != -1) && !(containi(said, "/ejaculate") != -1))
	|| ((containi(said, "ejaculer") != -1) && !(containi(said, "/ejaculer") != -1)) ) 
	{
		client_print(id, print_chat, "[AMX] Pentru ejaculare scrie /ejaculate")
	}

	return PLUGIN_CONTINUE
}

public plugin_precache() 
{ 
	if (file_exists("sound/ejaculate/ejaculate.wav"))
		precache_sound("ejaculate/ejaculate.wav")    

   	return PLUGIN_CONTINUE 
}

public client_connect(id)
{
	EjaculateFlag[id]=false
	count_ejaculate[id]=1
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	reset_hud(id)

	return PLUGIN_CONTINUE
}

public plugin_init() 
{ 
	register_plugin("AMX Ejaculate","0.1","KRoTaL") 
	register_clcmd("ejaculate","ejaculate_on_player",0,"- Ejaculate on a dead player") 
	register_clcmd("ejaculer","ejaculate_on_player",0,"- Ejaculate on a dead player")
	register_clcmd("say /ejaculate","ejaculate_help",0,"- Displays Ejaculate help") 
	register_clcmd("say /ejaculer","ejaculate_help",0,"- Displays Ejaculate help")
	register_clcmd("say","handle_say")
	register_cvar("amx_maxejaculations","6")
	register_cvar("amx_ejaculate_admin","0")
	register_event("DeathMsg","death_event","a") 
	register_event("ResetHUD", "reset_hud", "be")

	return PLUGIN_CONTINUE
}
