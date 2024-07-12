#include <amxmodx>
#include <amxmisc>
#define MAX_GROUPS 8
new g_groupNames[MAX_GROUPS][] = {
	"<<<*** Owner ***>>>",
	"<<<*** Lead ***>>>",
	"<<<*** Zeu ***>>>",
	"<<<*** Administrator Avansat ***>>>",
	"<<<*** Administrator ***>>>",
	"<<<*** Administrator Junior ***>>>",
	"<<<*** Helper ***>>>",
	"<<<*** Slot ***>>>"
}
new g_groupFlags[MAX_GROUPS][] = {
	"abcdefghijklmnopqrstu",
	"bcdefgijlmnopqrst",
	"bcdefgijmnopqr",
	"bcdefgijmnop",
	"bcdefijmn",
	"bcdefij",
	"bcefij",
	"b"
}
new g_groupFlagsValue[MAX_GROUPS]
public plugin_init() {
	register_plugin("Amx Who", "1.0", "BiKeeR")
	register_concmd("amx_who","cmdWho",ADMIN_RESERVATION,"arata admini online")
	for(new i = 0; i < MAX_GROUPS; i++) {
		g_groupFlagsValue[i] = read_flags(g_groupFlags[i])
	}
}
public cmdWho(id,level,cid) {
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
	new players[32], inum, player, name[32], i, a
	get_players(players, inum)
	console_print(id, "*** Gradele Server-ului JailBreak.Mevid.Ro ***")
	for(i = 0; i < MAX_GROUPS; i++) {
		console_print(id, "-----[%d]%s-----", i+1, g_groupNames[i])
		for(a = 0; a < inum; ++a) {
			player = players[a]
			get_user_name(player, name, 31)
			if(get_user_flags(player) == g_groupFlagsValue[i]) {
				console_print(id, "%s", name)
			}
		}
	}
	console_print(id, "*** Gradele Server-ului JailBreak.Mediv.Ro ***")
	return PLUGIN_HANDLED
}
