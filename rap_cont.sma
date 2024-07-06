#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME	"Rapoarte/Contacte"
#define PLUGIN_AUTHOR	"Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION	"1.0"

public plugin_init(){
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_clcmd("say /raport", "cmd_raport");
	register_clcmd("say /contacte", "cmd_contacte");
}

public cmd_raport(id){
	if(is_user_connected(id)){
		new Args[256];
		read_argv(1, Args, 255);
		new name[ 32 ];
		get_user_name( id, name, 32 );
		log_to_file( "Rapoarte.log", "%s:%s", name,Args );
	}
}
public cmd_contacte(id){
	show_motd(id, "<html><head><meta http-equiv=^"content-type^" content=^"text/html; charset=windows-1252^"/></head><body lang=^"en-US^" dir=^"ltr^" style=^"background: transparent^"><p style=^"margin-bottom: 0in^">Contacte owner:</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">(|EcLiPsE|):</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">Skype: ieclipsei95</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">David:</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">Skype: reif_wiz </p><p style=^"margin-bottom: 0in^">Yahoo Mail: davidmihai7@yahoo.com </p><p style=^"margin-bottom: 0in^">Steam: reif_wiz</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">Mascatul:</p><p style=^"margin-bottom: 0in^"><br/></p><p style=^"margin-bottom: 0in^">Skype: mascatul21 </p><p style=^"margin-bottom: 0in^"><br/></p></body></html>", "Contacte");
}