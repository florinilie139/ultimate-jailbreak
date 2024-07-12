/* 
				     _                      _
				    | |                    | |
			       _.__ | | __ _ _   _  ___  __| |
			      | `_ \| |/ _` | | | |/ _ \/ _` |
			      | |_) | | (_| | \ / |  __/ (_| |
			      | ,__/|_|\__,_|\__, |\___|\__,_|
			      | |             __/ |
			      |_|            |___/  	
			      
			      
      
							       _   _
							      | | (_)
							      | |_ _ _ __  __   ___
							      | __| | '_ \/_ \ / _ \
							      | | | | | | | | |  __/
							      \__||_|_| |_| |_|\___|
      
      

(c)2011 www.godplay.ro 


Plugin: Played Time
Version: 0.5.5
Author: sPuf ? 

Changelog:

		
v 0.0.5 - prima publicare a pluginului.
v 0.1.0 - acum orele si minutele sunt salvate.
v 0.1.5 - poti vedea primii 10 jucatori cu cele mai multe ore jucate,/topore.
v 0.2.0 - poti sa iti vezi orele, /ore
v 0.2.5 - detalii despre un jucator, /ore <nume>.
v 0.3.0 - numele nu poate fi schimbat pe server.
v 0.3.5 - numele nu poate avea mai mult sau mai putin de 15 si respectiv 3 litere<minim 3,maxim 15>.
v 0.4.0 - editarea motd`ului si restructurarea pluginului.
v 0.4.5 - stergerea unui jucator din top acum este posibila,amx_removetop <pozitie>.
v 0.5.0 - editarea mesajelor din chat si rezolvarea unui bug la amx_removetop.
v 0.5.5 - adaugarea cvarului pt_prefix pentru prefixul mesajelor din chat si consola.( ideea lui Rap^)
	- schimbarea numarului de litere minime si respectiv maxime(20 si 2).
Credite:
kNOWLEDGE,Simple,STORIES,VeNoM
diabolykul,ahonen,Ch1o  			  - multe teste..

nescafezalau                                      - pentru cateva idei.
Ex3cuTioN aka Arion                               - pentru sprijinul acordat

Rap^ - pentru ca a gasit bug-ul de la amx_removetop si pentru multe teste ( v0.5.0- v0.5.5)
*/
#include <amxmodx>
#include <amxmisc>

#include <nvault>
#include <fakemeta>

#include <ColorChat>

#pragma semicolon 1

#define INFO_ZERO 0
#define NTOP 10
#define TIME 60.0

static const PLUGIN_NAME[] 	= "Played Time";
static const PLUGIN_AUTHOR[] 	= "sPuf ?";
static const PLUGIN_VERSION[]	= "0.5.5";

new tophours[33],topminutes[33];
new topnames[33][33],topauth[33][33];

new Data[64],g_vault;
new gHours[33],gMinutes[33];

new cvar_tag,TAG[64];

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_clcmd( "say", "hook_say" );

	register_concmd("amx_removetop", "remove_info");
	register_concmd("amx_ore", "show_info");
	register_concmd("amx_topore", "show_top");
	
	cvar_tag = register_cvar("pt_prefix","[D/C]");
	
	register_forward(FM_ClientUserInfoChanged, "fwClientUserInfoChanged");
	g_vault = nvault_open("played_time");
	
	if(g_vault == INVALID_HANDLE){
		set_fail_state("nValut returned invalid handle");
	}
	get_datadir(Data, 63);
	read_top();
	
}

public client_putinserver(id) {
	if(!is_user_bot(id)) {
		LoadTime(id);
		set_task(TIME,"RefreshTime",id,_,_,"b",0);
		set_task(0.1,"CheckName",id);
	}
}
public client_disconnect(id) {
	if(!is_user_bot(id)) {
		SaveTime(id);
		remove_task(id);
	}
}
public plugin_end() {
	nvault_close( g_vault );
}
public hook_say(id) {
	
	static args[192], command[192];
	read_args(args,charsmax(args));
	
	if(!args[0]) {
		return PLUGIN_CONTINUE;
	}	
	remove_quotes(args[0]);
	if( equal(args, "/ore", strlen("/ore") )) {
		replace(args,charsmax(args), "/", "" );
		formatex( command, charsmax(command) , "amx_%s", args );
		client_cmd(id, command);
		return PLUGIN_HANDLED;
	}
	if( equal(args, "/topore", strlen("/topore") )) {
		replace(args,charsmax(args), "/", "" );
		formatex( command, charsmax(command) , "amx_%s", args );
		client_cmd(id, command);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public RefreshTime(id) {
	gMinutes[id] += 1;
	
	if(gMinutes[id] >= 60) {
		gHours[id] += 1;
		gMinutes[id] -= 60;
	}
	checkandupdatetop(id,gHours[id],gMinutes[id]);
	return PLUGIN_HANDLED;
}
public CheckName(id) {
	static name[32];
	get_user_name(id, name, 31);
	get_pcvar_string(cvar_tag, TAG, 63);
	
	new iLen;
	while(!equali(name[iLen], "^0")) {
		iLen++;
	}
	if(iLen < 2) {
		new userid;
		userid = get_user_userid(id);
		ColorChat(0, RED, "^x04%s^x01 Jucatorul^x03 %s^x01 a primit kick datorita nick-ului prea scurt !", TAG, name);
		server_cmd("kick #%d ^"Nick prea scurt, minim 2 litere^"", userid);
		client_print(id,print_console,"Nick prea scurt, minim 2 litere");
		
	} else if(iLen > 20) {
		new userid;
		userid = get_user_userid(id);
		ColorChat(0, RED, "^x04%s^x01 Jucatorul^x03 %s^x01 a primit kick datorita nick-ului prea lung !", TAG, name);
		server_cmd("kick #%d ^"Nick prea lung, maxim 20 litere^"", userid);
		client_print(id,print_console,"Nick prea lung, maxim 20 litere");
	}
	return PLUGIN_HANDLED;
}
public fwClientUserInfoChanged(id, buffer) {
	if (!is_user_connected(id)) {
		return FMRES_IGNORED;
	}
	static val[32];
	static name[32];
	get_user_name(id, name, 31);
	engfunc(EngFunc_InfoKeyValue, buffer, "name", val, sizeof val- 1);
	if (equal(val, name)) {
		return FMRES_IGNORED;
	}
	engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", name);
	get_pcvar_string(cvar_tag, TAG, 63);
	ColorChat(id, RED, "^x04%s^x03 NU este permisa schimbarea nick-ului pe server !", TAG);
	console_print(id,"NU este permisa schimbarea nick-ului pe server !");
	return FMRES_SUPERCEDE;
}
public show_info(id)  {
	get_pcvar_string(cvar_tag, TAG, 63);
	
	new target[32];
    	read_argv(1, target, 31);

	if(equali(target,"")) {
		new ptime,Steamid[35];
		get_user_authid(id, Steamid, 34);
		ptime = get_user_time(id, 1) / 60;
		ColorChat(id, BLUE, "^x04%s^x01 Statisticile tale:", TAG);
		ColorChat(id, BLUE, "^x04%s^x01 Ai acumulat pana acum^x03 %d^x01 or%s si^x03 %d^x01 minut%s", TAG,gHours[id],gHours[id] == 1 ? "a" : "e",gMinutes[id],gMinutes[id] == 1 ? "" : "e");
		ColorChat(id, BLUE, "^x04%s^x01 Te-ai conectat pe server de^x03 %d^x01 minut%s", TAG, ptime, ptime == 1 ? "" : "e");
		ColorChat(id, RED, "^x04%s^x01 SteamID tau este:^x03 %s", TAG, Steamid);
		return PLUGIN_HANDLED;
	}

    	new player = cmd_target(id, target, 8);
    	if(!player || player == id) {
		return PLUGIN_HANDLED;
	}
	else {

		new name[32];
		get_user_name(player, name, 31);
	
		new ptime,Steamid[35];
		get_user_authid(player, Steamid, 34);
		ptime = get_user_time(player, 1) / 60;
	
		ColorChat(id, BLUE, "^x04%s^x01 Statisticile lui^x03 %s^x01:", TAG, name);
		ColorChat(id, BLUE, "^x04%s^x01 A acumulat pana acum^x03 %d^x01 or%s si^x03 %d^x01 minut%s", TAG, gHours[player],gHours[player] == 1 ? "a" : "e",gMinutes[player],gMinutes[player] == 1 ? "" : "e");
		ColorChat(id, BLUE, "^x04%s^x01 S-a conectat pe server de^x03 %d^x01 minut%s", TAG, ptime, ptime == 1 ? "" : "e");
		ColorChat(id, RED, "^x04%s^x01 SteamID lui^x03 %s^x01 :^x03 %s", TAG,name, Steamid);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public remove_info(id)  {
	if( !(get_user_flags(id) == read_flags("abcdefghijklmnopqrstu"))) {
       		return PLUGIN_HANDLED;
	}
	get_pcvar_string(cvar_tag, TAG, 63);
	new target[32];
    	read_argv(1, target, 31);
	new poz = str_to_num(target);
	if( !poz|| poz > 10 || poz < 1) {
		console_print(id,"%s Foloseste amx_removetop <pozitie>, de la 1 la 10 !",TAG);
       		return PLUGIN_HANDLED;
	}
	new aname[32],Steamid[35];
	get_user_name(id, aname, 31);
	get_user_authid(id, Steamid, 34);
	
	if(equal(topnames[poz-1],"")) {
		console_print(id,"%s Nu se afla nimeni pe aceasta pozitie !",TAG);
		ColorChat(id, RED,"^x04%s^x01 Nu se afla nimeni pe aceasta pozitie !", TAG);
		return PLUGIN_HANDLED;
	}
	ColorChat(0, BLUE,"^x04%s^x01 Adminul^x03 %s^x01 il sterge din top ore pe^x03 %s^x01 !", TAG, aname,topnames[poz-1]);
	static i;
	
	for (i= poz-1;i<NTOP;i++) {
		formatex(topauth[i], 31, topauth[i+1]);
		formatex(topnames[i], 31, topnames[i+1]);	
		tophours[i] = tophours[i+1];
		topminutes[i] = topminutes[i+1];
		
		save_top();
	}
	
	return PLUGIN_HANDLED;
}
public SaveTime(id) {
 	new Name[32];
	get_user_name(id, Name, 32);

 	new vaultkey[64],vaultdata[256];
 	format(vaultkey,63,"%s",Name);
 	format(vaultdata,255," ^"%i^" ^"%i^"",gHours[id],gMinutes[id]);
 	nvault_set(g_vault,vaultkey,vaultdata);
	
 	return PLUGIN_HANDLED;
}
public LoadTime(id) {
 	new Name[32];
	get_user_name(id, Name, 32);

 	new vaultkey[64],vaultdata[256];
 	format(vaultkey,63,"%s",Name);
 	format(vaultdata,255," ^"%i^" ^"%i^"",gHours[id],gMinutes[id]);
 	nvault_get(g_vault, vaultkey, vaultdata, 255);

 	new phours[32], pmins[32] ;

 	parse(vaultdata, phours, sizeof(phours) - 1, pmins, sizeof(pmins) - 1);

 	gHours[id] = str_to_num(phours);
 	gMinutes[id] = str_to_num(pmins);

 	return PLUGIN_HANDLED;
}
public save_top() {
	new path[128];
	formatex(path, 127, "%s/TopOre.dat", Data);
	if( file_exists(path) ) {
		delete_file(path);
	}
	new Buffer[256];
	new f = fopen(path, "at");
	for(new i = INFO_ZERO; i < NTOP; i++)
	{
		formatex(Buffer, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^"^n",topnames[i],topauth[i], tophours[i],topminutes[i] );
		fputs(f, Buffer);
	}
	fclose(f);
}
public checkandupdatetop(id, hours, minutes) {	

	new authid[35],name[32];
	get_user_name(id, name, 31);
	get_user_authid(id, authid ,34);
	for (new i = INFO_ZERO; i < NTOP; i++)
	{
		if( hours > tophours[i] || hours == tophours[i] && minutes > topminutes[i])
		{
			new pos = i;	
			while( !equal(topnames[pos],name) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(topauth[j], 31, topauth[j-1]);
				formatex(topnames[j], 31, topnames[j-1]);
				tophours[j] = tophours[j-1];
				topminutes[j] = topminutes[j-1];
				
			}
			formatex(topauth[i], 31, authid);
			formatex(topnames[i], 31, name);
			
			tophours[i]= hours;
			topminutes[i] = minutes;
			//ColorChat(0, BLUE,"^x04%s^x03 %s^x01 este pe locul^x04 %i^x01 in top ore cu^x03 %d^x01 or%s^x03 %d^x01 minut%s. ", TAG, name,(i+1),hours,hours == 1 ? "a" : "e",minutes,minutes == 1 ? "" : "e");
			save_top();
			break;
		}
		else if( equal(topnames[i], name)) 
		break;	
	}
}
public read_top() {
	new Buffer[256],path[128];
	formatex(path, 127, "%s/TopOre.dat", Data);
	
	new f = fopen(path, "rt" );
	new i = INFO_ZERO;
	while( !feof(f) && i < NTOP+1)
	{
		fgets(f, Buffer, 255);
		new hours[25], minutes[25];
		parse(Buffer, topnames[i], 31, topauth[i], 31,  hours, 25, minutes, 25);
		tophours[i]= str_to_num(hours);
		topminutes[i]= str_to_num(minutes);
		
		i++;
	}
	fclose(f);
}
public show_top(id) {	
	static buffer[2368], name[131], len, i;
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{border-style:solid;border-width:1px;border-color:#FFFFFF;font-size:13px}</STYLE><table align=center width=100%% cellpadding=2 cellspacing=0");
	len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#52697B><th width=4%% > # <th width=24%%> Nume Jucator <th width=24%%>SteamID <th width=24%%> Ore Jucate <th  width=24%%> Minute Jucate");	
	for( i = INFO_ZERO; i < NTOP; i++ ) {		
			if( tophours[i] == 0 && topminutes[i] == 0) {
				len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %s<td> %s <td> %s", (i+1), "-", "-", "-","-");
				//i = NTOP
			}
			else {
				name = topnames[i];
				while( containi(name, "<") != -1 )
					replace(name, 129, "<", "&lt;");
				while( containi(name, ">") != -1 )
					replace(name, 129, ">", "&gt;");
				new plname[32];
				get_user_name(id, plname ,32);
				if(equal(topnames[i],plname)) {
					len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#2D2D2D><td> %d <td> %s <td> %s<td> %d <td> %d", (i+1), name,topauth[i], tophours[i],topminutes[i]);
				}
				else {
					len += format(buffer[len], 2367-len, "<tr align=center bgcolor=#232323><td> %d <td> %s <td> %s<td> %d <td> %d", (i+1), name,topauth[i], tophours[i],topminutes[i]);
				}
			}
		}
	len += format(buffer[len], 2367-len, "</table>");
	len += formatex(buffer[len], 2367-len, "<tr align=bottom font-size:11px><Center><br><br><br><br>Primii 10 Jucatori Cu Cele Mai Multe Ore Acumulate</body>");
	static strin[20];
	format(strin,33, "Top 10 ore jucate");
	show_motd(id, buffer, strin);
}