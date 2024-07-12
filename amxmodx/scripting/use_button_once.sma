/*
Manager of Buttons
for DeathRun

Licence: GPL
Description:
	Allow admin to define how many times every button could be used by Menu.
	Add to game (cvar controlled) FreeRun mode - during round with FR traps can`t 
	be used by defined teams (default Te).

*/
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <colorchat>

#define PLUGIN "Use button once"
#define VERSION "1.3"
#define AUTHOR "R3X"

#define MAX_BUTTONS 100
#define KeysButtonsMenu (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9) // Keys: 137890
#define KeysOptionsMenu (1<<0)|(1<<1)|(1<<8) //129

#define ANNOUNCE_TASK 10000

#define m_flWait 44

//Main

new gEnt[MAX_BUTTONS];
new gUsed[MAX_BUTTONS];
new giPointer=0;
new gOnStart[MAX_BUTTONS];
new Float:gDefaultDelay[MAX_BUTTONS];
new Float:gDelay[MAX_BUTTONS];

new gInMenu[33];

new gszFile[128];

new giSprite;

new gcvarDefault, gcvarTeam, gcvarFreeRun;
new gcvarLimit, gcvarLimitMode, gcvarPrivilege;
new gcvarMessage, gcvarRestore;

//VOTE

#define TASK_SHOWMENU 432
#define TASK_RES 123

#define MAX_ROUNDS 999

#define KeysFFVote (1<<0)|(1<<1) // Keys: 12

new gcvarFRVoteTime;

new giVoteStart, giVoteTime;

new bool:gbFreeRun=false;
new bool:gbVote=false;

#define VOTE_ON 0
#define VOTE_OFF 1

new giVotes[33][2];

new giRounds=MAX_ROUNDS, giTime=0;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("adminvote.txt");
	register_dictionary("use_button_once.txt");
	
	register_menucmd(register_menuid("FRVote"), KeysFFVote, "PressedFRVote");
	register_menucmd(register_menuid("ButtonsMenu"), KeysButtonsMenu, "PressedButtonsMenu");
	register_menucmd(register_menuid("OptionsMenu"), KeysOptionsMenu, "PressedOptionsMenu");
	register_menucmd(register_menuid("DelayMenu"), KeysDelayMenu, "PressedDelayMenu");
	
	register_clcmd("amx_buttons","cmd_amx_buttons",ADMIN_CFG,": Buttons Menu");
	
	//Default count of uses
	gcvarDefault=register_cvar("amx_buttons_default","1");
	//Who plugin analyze
	//0 - anyone(plugin disabled?)
	//1 - Te
	//2 - Ct
	//3 - Te+Ct
	gcvarTeam=register_cvar("amx_buttons_team","1");
	//Enabled FreeRun mode?
	gcvarFreeRun=register_cvar("amx_buttons_freerun","1");
	//Vote time
	gcvarFRVoteTime=register_cvar("amx_freerun_votetime","10");
	
	//Type of limit
	//0 - enabled after 'amx_freerun_limit' rounds
	//1 - enabled after 'amx_freerun_limit' minutes
	gcvarLimitMode=register_cvar("amx_freerun_limit_mode","0");
	//Size of Limit
	gcvarLimit=register_cvar("amx_freerun_limit","5");
	
	//Interval of message
	gcvarMessage=register_cvar("amx_freerun_info","120.0",0,120.0);
	
	//Terrorist`s privilege
	//if he use /free FreeRun will start without vote, can he?
	gcvarPrivilege=register_cvar("amx_freerun_tt_privilege","1");
	
	//restore buttons on new round
	gcvarRestore=register_cvar("amx_restore_buttons","1");
	
	register_clcmd("say /free","cmdVoteFreeRun");
	register_clcmd("say_team /free","cmdVoteFreeRun");
	register_clcmd("say free","cmdVoteFreeRun");
	register_clcmd("say_team free","cmdVoteFreeRun");
	
	register_clcmd("say /freerun","cmdVoteFreeRun");
	register_clcmd("say_team /freerun","cmdVoteFreeRun");
	register_clcmd("say freerun","cmdVoteFreeRun");
	register_clcmd("say_team freerun","cmdVoteFreeRun");
	
	register_clcmd("say /fr","cmdVoteFreeRun");
	register_clcmd("say_team /fr","cmdVoteFreeRun");
	register_clcmd("say fr","cmdVoteFreeRun");
	register_clcmd("say_team fr","cmdVoteFreeRun");
	
	if( engfunc(EngFunc_FindEntityByString,-1 ,"classname", "func_button"))
		RegisterHam(Ham_Use, "func_button", "fwButtonUsed");

	if(engfunc(EngFunc_FindEntityByString,-1 ,"classname","func_rot_button"))
		RegisterHam(Ham_Use, "func_rot_button", "fwButtonUsed");
		
	if(engfunc(EngFunc_FindEntityByString,-1 ,"classname", "button_target"))
		RegisterHam(Ham_Use, "button_target", "fwButtonUsed");
		
	register_logevent( "ResetButtons", 2, "0=World triggered", "1=Round_Start");
	
	fillButtons("func_button");
	fillButtons("func_rot_button");
	fillButtons("button_target");
}
public plugin_cfg(){
	setButtons();
	
	new iLen=0, iMax=charsmax(gszFile);
	iLen=get_configsdir(gszFile, iMax );
	iLen+=copy(gszFile[iLen], iMax-iLen, "/jb_buttons/");
	
	if(!dir_exists(gszFile)){
		set_fail_state("Not found dir: configs/jb_buttons");
		return;
	}
	new szMap[32];
	get_mapname(szMap, 31);
	formatex(gszFile[iLen], charsmax(gszFile)-iLen, "%s.ini", szMap);
	if(!file_exists(gszFile)){
		return;
	}
	new szLine[51];
	new szButton[4], szTimes[3], szDelay[5];
	new Float:fDelay;
	for(new i=0;read_file(gszFile, i, szLine, 50, iLen);i++){
		if(iLen==0) continue;
		trim(szLine);
		if(szLine[0]==';') continue;
		parse(szLine, szButton, 3, szTimes, 2, szDelay, 4);
		fDelay=szDelay[0]?str_to_float(szDelay):-1.0;
		set_start_value(str_to_num(szButton), str_to_num(szTimes), fDelay);
	}
}
public plugin_precache(){
	giSprite=precache_model("sprites/laserbeam.spr");
}
public client_putinserver(id){
	if(!is_user_bot(id))
		eventInGame(id);
}
public client_connect(id){
	giVotes[id][VOTE_ON]=0;
	giVotes[id][VOTE_OFF]=0;
}

}
setButtons(){
	new iDef=get_pcvar_num(gcvarDefault);
	for(new i=0;i<giPointer;i++){
		gUsed[i]=iDef;
		gOnStart[i]=iDef;
		gDelay[i]=get_pdata_float(gEnt[i],m_flWait);
		gDefaultDelay[i]=gDelay[i];
	}
}
fillButtons(const szClass[]){
	new ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString,ent ,"classname", szClass)) != 0){
		gEnt[giPointer++]=ent;
		set_pev(ent, pev_iuser4, giPointer);
	}
}
set_start_value(ent, times, Float:delay){
	new index=get_ent_index(ent);
	if(index!=-1){
		gOnStart[index]=times;
		if(delay>=0.0)
			gDelay[index]=delay;
	}
}
get_ent_index(ent){
	/*
	for(new i=0;i<giPointer;i++)
		if(gEnt[i]==ent) return i;
	return -1;
	*/
	return pev(ent, pev_iuser4)-1;
}
restoreButton(ent){
	if(pev(ent, pev_frame) > 0.0){
		new Float:Life;
		pev(ent, pev_nextthink, Life);
		set_pev(ent, pev_ltime, Life-0.01);
	}
}
public ResetButtons(){
	gbFreeRun=false;
	gbVote=false;
	new bool:bRestore=get_pcvar_num(gcvarRestore)!=0;
	for(new i=0;i<MAX_BUTTONS;i++){
		gUsed[i]=gOnStart[i];
		if(bRestore){
			restoreButton(gEnt[i]);
		}
	}
	giRounds++;
}
public fwButtonUsed(this, idcaller, idactivator, use_type, Float:value){
	if(idcaller!=idactivator) return HAM_IGNORED;
	
	if(pev(this, pev_frame) > 0.0)
		 return HAM_IGNORED;
	new index=get_ent_index(this);
	if(index==-1) 
		return HAM_IGNORED;
	if(get_user_team(idcaller)&get_pcvar_num(gcvarTeam)){
		
		if(gbFreeRun){
			ColorChat(idcaller,GREEN, "[FreeRun]^x01 %L",idcaller, "BUTTON_FREERUN");
			return HAM_SUPERCEDE;
		}
		else if(gUsed[index]<=0 && gOnStart[index]!=-1){
			ColorChat(idcaller,GREEN, "[Info]^x01 %L",idcaller,"BUTTON_NOMORE");
			return HAM_SUPERCEDE;
		}
		else{
			if(gUsed[index]>0)
				if(--gUsed[index]){
					ColorChat(idcaller, GREEN, "[Info]^x01 %L", idcaller, "BUTTON_LEFT", gUsed[index]);
				}else
					ColorChat(idcaller, GREEN, "[Info]^x01 %L", idcaller, "BUTTON_ENDOFLIMIT");
		}
	}
	
	set_task(0.1,"setDelay",this);
	
	return HAM_IGNORED;
}
public setDelay(this){
	new index=get_ent_index(this);
	set_pev(this, pev_nextthink, pev(this, pev_ltime)+gDelay[index]+0.01);
}

//MENU--------------
public cmd_amx_buttons(id, level, cid){
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	if(giPointer==0)
		client_print(id, print_chat, "%L", id,"NO_BUTTONS");
	else
		ShowButtonsMenu(id);
	return PLUGIN_HANDLED;
}
ShowButtonsMenu(id, trace=1){
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id, "MUST_B_ALIVE");
		return;
	}
	new iNow=gInMenu[id];
	new iKeys=(1<<0)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<9);
	new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
	new szNoLimit[32];
	formatex(szNoLimit,31,"(%L)",id,"NOLIMIT");
	iLen=copy(szMenu, iMax,"\yButtons Menu^n");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"\wEnt#%d^n^n",gEnt[iNow]);
	iLen+=formatex(szMenu[iLen], iMax-iLen,"%L: %d %s^n\y1\w. %L ",id, "USAGE",gOnStart[iNow],(gOnStart[iNow]==-1)?szNoLimit:"", id, "MORE");
	
	if(gOnStart[iNow]>=0){
		iLen+=formatex(szMenu[iLen], iMax-iLen,"\y2\w. %L",id, "WORD_LESS");
		iKeys|=(1<<1);
	}else
		iLen+=formatex(szMenu[iLen], iMax-iLen,"\d2. %L\w",id,"WORD_LESS");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"^n^n3. %L^n^n4. %L^n^n",id, "DELAY_EDITOR",id,"OPTIONS");
	
	iLen+=formatex(szMenu[iLen], iMax-iLen,"5. %sNo Clip\w^n",isNoClip(id)?"\r":"");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"6. %sGodMode\w^n",isGodMode(id)?"\r":"");
	
	iLen+=formatex(szMenu[iLen], iMax-iLen,"^n7. \r%L^n\w",id, "WORD_SAVE");
	
	if(iNow>0){
		iLen+=formatex(szMenu[iLen], iMax-iLen,"^n8. %L",id, "BACK");
		iKeys|=(1<<7);
	}
	if(iNow<giPointer-1){
		iLen+=formatex(szMenu[iLen], iMax-iLen,"^n9. %L",id, "WORD_NEXT");
		iKeys|=(1<<8);
	}
	iLen+=formatex(szMenu[iLen], iMax-iLen,"^n0. %L", id, "EXIT");
	show_menu(id, iKeys, szMenu, -1, "ButtonsMenu");
	if(trace){
		new Float:fOrigin[3], Float:fOrigin2[3];
		fm_get_brush_entity_origin(gEnt[gInMenu[id]], fOrigin);
		pev(id, pev_origin, fOrigin2);
		Create_TE_BEAMPOINTS(fOrigin, fOrigin2, giSprite, 0, 10, 20, 5, 1, 255, 0, 0, 100, 50);
	}
}
bool:isNoClip(id)
	return pev(id, pev_movetype)==MOVETYPE_NOCLIP;
	
bool:isGodMode(id)
	return pev(id, pev_takedamage)==0.0;
	
public PressedButtonsMenu(id, key) {
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
		return;
	}
	/* Menu:
	* Buttons Menu
	* Ent#<ent>
	* 
	* Uzyc: <ile>
	* 1. Wiecej 2. Mniej
	* 
	* 3. Editor
	*
	* 4. Options
	*
	* 5. NoClip
	* 6. GodMode
	* 
	* 7. Zapisz
	* 
	* 8. Poprzedni
	* 9. Nastepny
	* 0. Wyjdz
	*/
	new trace=0;
	switch (key) {
		case 0: { // 1
			gOnStart[gInMenu[id]]++;
		}
		case 1: { // 2
			gOnStart[gInMenu[id]]--;
		}
		case 2: { // 3
			ShowDelayMenu(id);
			return;
		}
		case 3:{ //4
			ShowOptionsMenu(id);
			return;
		}
		case 4:{ //5
			set_pev(id, pev_movetype, isNoClip(id)?MOVETYPE_WALK:MOVETYPE_NOCLIP);	
		}
		case 5:{ //6
			set_pev(id, pev_takedamage, isGodMode(id)?1.0:0.0);
		}
		case 6: { // 7
			save2File(id);
		}
		case 7: { // 8
			gInMenu[id]--;
			trace=1;
		}
		case 8: { // 9
			gInMenu[id]++;
			trace=1;
		}
		case 9: { // 0
			return;
		}
	}
	ShowButtonsMenu(id, trace);
}
//--------------
ShowOptionsMenu(id){
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
		return;
	}
	new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
	iLen+=formatex(szMenu[iLen], iMax-iLen,"\yOptions^n^n");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"\w1. %L^n",id, "GOTO");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"2. %L^n^n",id, "NEAREST");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"9. %L",id, "BACK");
	show_menu(id, KeysOptionsMenu, szMenu, -1, "OptionsMenu");
}
public PressedOptionsMenu(id, key){
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
		return;
	}
	new trace=0;
	switch (key) {
		case 0: { // 1
			go2Button(id);
		}
		case 1: { // 2
			gInMenu[id]=findTheClosest(id);
			trace=1;
		}
	}
	ShowButtonsMenu(id, trace);
}
//-------------
ShowDelayMenu(id){
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id,"MUST_B_ALIVE");
		return;
	}
	new iNow=gInMenu[id];
	new iKeys=(1<<0)|(1<<2)|(1<<8);
	new szMenu[196], iLen, iMax=(sizeof szMenu) - 1;
	iLen=copy(szMenu, iMax,"\yDelay Menu^n");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"\wEnt#%d^n^n",gEnt[iNow]);
	iLen+=formatex(szMenu[iLen], iMax-iLen,"%L: %.1f^n",id, "CURRENT_DELAY", gDelay[iNow]);
	iLen+=formatex(szMenu[iLen], iMax-iLen,"\y1\w. %L ",id, "MORE");
	if(gDelay[iNow]>0.0){
		iLen+=formatex(szMenu[iLen], iMax-iLen,"\y2\w. %L",id, "WORD_LESS");
		iKeys|=(1<<1);
	}else
		iLen+=formatex(szMenu[iLen], iMax-iLen,"\d2. %L\w",id,"WORD_LESS");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"^n3. %L",id, "DEFAULT");
	iLen+=formatex(szMenu[iLen], iMax-iLen,"^n^n9. %L",id, "BACK");
	show_menu(id, iKeys, szMenu, -1, "DelayMenu");
}
public PressedDelayMenu(id, key){
	new iNow=gInMenu[id];
	switch(key){
		case 0:{
			gDelay[iNow]+=1.0;
		}
		case 1:{
			gDelay[iNow]-=1.0;
			if(gDelay[iNow] < 0.0)
				gDelay[iNow]=0.0;
		}
		case 2:{
			gDelay[iNow]=gDefaultDelay[iNow];
		}
		case 8:{
			ShowButtonsMenu(id, 0);
			return;
		}
	}
	ShowDelayMenu(id);
}
//-------------
save2File(id){
	if(file_exists(gszFile))
		delete_file(gszFile);
	write_file(gszFile, ";<ent> <count> <delay>");
	new szLine[35];
	for(new i=0;i<giPointer;i++){
		formatex(szLine, 34, "%d %d %.1f",gEnt[i], gOnStart[i], gDelay[i]);
		write_file(gszFile, szLine);
	}
	client_print(id, print_center, "%L!",id,"WORD_SAVED");
}
findTheClosest(id){
	new Float:fPlayerOrig[3];
	pev(id, pev_origin, fPlayerOrig);
	new Float:fOrigin[3];
	fm_get_brush_entity_origin(gEnt[0], fOrigin);
	
	new Float:fRange=get_distance_f(fOrigin, fPlayerOrig), index=0;
	new Float:fNewRange;
	for(new i=1;i<giPointer;i++){
		fm_get_brush_entity_origin(gEnt[i], fOrigin);
		fNewRange=get_distance_f( fOrigin,  fPlayerOrig);
		if(fNewRange < fRange){
			fRange=fNewRange;
			index=i;
		}
	}
	return index;
}
go2Button(id, ent=-1){
	if(ent==-1)
		ent=gInMenu[id];
	ent=gEnt[ent];
	if(!pev_valid(ent)){
		client_print(id, print_center, "%L",id,"NOTARGET");
		return;
	}
	new Float:fOrigin[3];
	fm_get_brush_entity_origin(ent, fOrigin);
	set_pev(id, pev_origin, fOrigin);
	client_print(id, print_chat, "PS. No Clip :)");
}
//FreeRun
public cmdVoteFreeRun(id){
	if(get_pcvar_num(gcvarFreeRun)==0){
		ColorChat(id, GREEN, "[FreeRun]^x01 %L",id,"FREERUN_DISABLED");
		return PLUGIN_HANDLED;
	}
	if(gbVote){
		ColorChat(id, GREEN, "[FreeRun]^x01 %L",id,"FREERUN_VOTE_IS_NOW");
		return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)){
		client_print(id, print_center, "%L",id, "MUST_B_ALIVE");
		return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(gcvarPrivilege)!=0 && !gbFreeRun && get_user_team(id)==1){
		ColorChat(id, GREEN, "[FreeRun]^x01 %L",id,"FREERUN_TT_DECIDED");
		makeFreeRun(true);
		return PLUGIN_HANDLED;
	}
	new iLimit=get_pcvar_num(gcvarLimit);
	new iOffset=0;
	if(get_pcvar_num(gcvarLimitMode)){
		iOffset = ( giTime + iLimit * 60 )  - get_systime();
		if( iOffset > 0 ){
		 	ColorChat(id, GREEN, "[FreeRun]^x01 %L",id,"FREERUN_NEXT_VOTE_TIME", iOffset/60, iOffset%60);
			return PLUGIN_HANDLED;
		}
	}
	else{
		iOffset =  min(MAX_ROUNDS, iLimit) - giRounds;
		if( iOffset > 0 ){
		 	ColorChat(id, GREEN, "[FreeRun]^x01 %L",id,"FREERUN_NEXT_VOTE_ROUNDS", iOffset);
			return PLUGIN_HANDLED;
		}
	}
	
	makeVote();
	return PLUGIN_CONTINUE;
}
//FREERUN
public makeVote(){
	giVoteTime=get_pcvar_num(gcvarFRVoteTime);
	gbVote=true;
	giVoteStart=get_systime();
	set_task(float(giVoteTime), "resultsOfVote", TASK_RES);
	new Players[32], playerCount;
	new id;
	get_players(Players, playerCount);
	for (new i=0; i<playerCount; i++){
		id = Players[i]; 
		eventInGame(id);
	}
	
}
public resultsOfVote(tid){
	gbVote=false;
	
	new giVotesOn=count(VOTE_ON);
	new giVotesOff=count(VOTE_OFF);
	
	ColorChat(0,GREEN, "[FreeRun]^x01 %L %L(%d) vs %L(%d)",LANG_SERVER,"FREERUN_RESULTS",LANG_SERVER,"YES",giVotesOn,LANG_SERVER,"NO", giVotesOff);
	
	if( giVotesOn == giVotesOff ){
		ColorChat(0,GREEN, "[FreeRun]^x01 %L",LANG_SERVER,"FREERUN_TIE");
		return;
	}
	makeFreeRun((giVotesOn > giVotesOff));
	ColorChat(0,GREEN, "[FreeRun]^x01 %L ^x03%L",LANG_SERVER,"FREERUN_WINOPTION",LANG_SERVER, gbFreeRun?"YES":"NO");
}
makeFreeRun(bool:bFR=true){
	gbFreeRun=bFR;
	reset();
	giRounds=0;
	giTime=get_systime();
	
	if(gbFreeRun){
		set_hudmessage(0, 255, 255, 0.02, -1.0);
		show_hudmessage(0, "FreeRun!");
	}
	
}
count(VOTE_STATE){
	new iCounter=0;
	for(new i=1;i<33;i++)
		if(giVotes[i][VOTE_STATE])
			iCounter++;
	return iCounter;
}
reset(){
	for(new i=1;i<33;i++){
		giVotes[i][VOTE_ON]=0;
		giVotes[i][VOTE_OFF]=0;
	}
}
public show_menu_(tid){
	new id=tid-TASK_SHOWMENU;
	new iTeam=get_user_team(id);
	new menu_id, keys;
	new menuUp = player_menu_info( id, menu_id, keys );
	// Only display menu if another isn't shown
	if ( iTeam && (menuUp <= 0 || menu_id < 0) ){
		new iTime=get_pcvar_num(gcvarFRVoteTime);
		new iOffset=get_systime()-giVoteStart;
		iTime-=iOffset;
		new szMenu[128];
		formatex(szMenu, 127, "\y%L^n^n\w1. %L^n2. %L",id,"FREERUN_VOTEMENU",id,"YES",id,"NO");
		show_menu(id, KeysFFVote, szMenu, iTime, "FRVote");
	}else
		set_task(1.0, "show_menu_", tid);
}
public eventInGame(id){
	if(giVotes[id][VOTE_ON] || giVotes[id][VOTE_OFF])
		return;
	if(gbVote)
		set_task(1.0, "show_menu_", id+TASK_SHOWMENU);
}
public PressedFRVote(id, key) {
	if(gbVote==false) return;
	switch (key) {
		case VOTE_ON: { // 1
			giVotes[id][VOTE_ON]=1;
		}
		case VOTE_OFF: { // 2
			giVotes[id][VOTE_OFF]=1;
		}
		default:{
			return;
		}
	}
	new szName[32];
	get_user_name(id, szName, 31);
	
	client_print(0, print_chat, "* %L",LANG_PLAYER,(key==VOTE_ON)?"VOTED_FOR":"VOTED_AGAINST", szName);
}

stock Create_TE_BEAMPOINTS(Float:start[3], Float:end[3], iSprite, startFrame, frameRate, life, width, noise, red, green, blue, alpha, speed){
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMPOINTS )
	write_coord( floatround(start[0]) )
	write_coord( floatround(start[1]) )
	write_coord( floatround(start[2]) )
	write_coord( floatround(end[0]) )
	write_coord( floatround(end[1]) )
	write_coord( floatround(end[2]) )
	write_short( iSprite )			// model
	write_byte( startFrame )		// start frame
	write_byte( frameRate )			// framerate
	write_byte( life )				// life
	write_byte( width )				// width
	write_byte( noise )				// noise
	write_byte( red)				// red
	write_byte( green )				// green
	write_byte( blue )				// blue
	write_byte( alpha )				// brightness
	write_byte( speed )				// speed
	message_end()
}
stock fm_get_brush_entity_origin(ent, Float:fOrigin[3]){
	new Float:fMins[3], Float:fMaxs[3];
	pev(ent, pev_mins, fMins);
	pev(ent, pev_maxs, fMaxs);
	
	for(new i=0;i<3;i++)
		fOrigin[i]=(fMins[i]+fMaxs[i])/2;
}
