#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define PLUGIN_NAME	"Tero powers"
#define PLUGIN_AUTHOR	"(|EcLiPsE|)"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"Tero powers"

enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
// HudSync: 0=ttinfo / 1=info / 2=ctinfo / 3=player / 4=center / 5=help / 6=timer
new const g_HudSync[][_hud] =
{
	{0,  0.46, 0.18,  5.0},
	{0, -1.0,  0.7,  5.0},
	{0,  0.1,  0.3,  2.0},
	{0, -1.0,  0.9,  3.0},
	{0, -1.0,  0.4,  5.0},
	{0, -1.0,  0.35,  5.0},
	{0, -1.0,  0.3,  5.0}
}

new teroskill = 0

static origins[33][3], tmp_origin[3], counter[33]

public plugin_init ()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	register_logevent("round_end", 2, "1=Round_End")
	
	for(new i = 0; i < sizeof(g_HudSync); i++)
		g_HudSync[i][_hudsync] = CreateHudSyncObj()
	set_task(1.0, "check_players", _, _, _, "b")
	return PLUGIN_CONTINUE
}

public check_players ()
{

	for(new i=1; i<=32; i++)
	{
        if(!is_user_alive(i) || cs_get_user_team(i) == CS_TEAM_CT)
			continue
		else{
			if(teroskill == 3 ){
				get_user_origin(i, tmp_origin)
				if(tmp_origin[0] == origins[i][0] &&  tmp_origin[1] == origins[i][1] && tmp_origin[2] == origins[i][2]){
					counter[i]++ //player has not moved since last check
					if(counter[i] >= 3 && get_user_weapon(i) == CSW_KNIFE ){  //player was not moving during last HEAL_INTERVAL seconds
						if(counter[i] == 3)
							set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 40);
						player_hudmessage(i, 0, 1.0, {255, 255, 0}, "Esti camuflat");	
					}
				}else{
					counter[i] = 0 //player has moved since last check
					set_user_rendering(i)
					origins[i][0] = tmp_origin[0]
					origins[i][1] = tmp_origin[1]
					origins[i][2] = tmp_origin[2]
				}
			}
			if(teroskill == 2)
				set_user_maxspeed(i, 340.0 )
		}
    }
	return PLUGIN_CONTINUE
}

public player_spawn(id)
{
	if(is_user_connected(id) && is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
		cmd_player_skill(id)
	return HAM_IGNORED
}

public round_end()
{
	teroskill = 0
}
public player_damage(victim, ent, attacker, Float:damage, bits)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker))
		return HAM_IGNORED
	
	if(cs_get_user_team(attacker) == CS_TEAM_T && teroskill == 1)
	{
		SetHamParamFloat(4, damage * 2)
		return HAM_OVERRIDE
	}
	return HAM_IGNORED
}

public cmd_player_skill (id)
{
	static menu, menuname[32], option[64]
	formatex(menuname, charsmax(menuname), "Alegeti puterea")
	menu = menu_create(menuname, "skills_shop")
	
	formatex(option, charsmax(option), "Putere")
	menu_additem(menu, option, "1", 0)	

	formatex(option, charsmax(option), "Viteza")
	menu_additem(menu, option, "2", 0)

	formatex(option, charsmax(option), "Camulfaj")
	menu_additem(menu, option, "3", 0)
	
	menu_display(id, menu)
	return PLUGIN_HANDLED
}
public skills_shop(id, menu, item)
{
	if(item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	static dst[32], data[5], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	
	new skil = 0
	if(data[0]>='0' && data[0]<='9')
		skil = data[0] - '0'
	else
		skil = data[0] - 'a' + 9
		
	teroskill = skil
	switch(skil)
	{
		case(1):
			player_hudmessage(id, 5, 5.0, {0, 255, 0}, "Ai ales putere")
		case(2):
			player_hudmessage(id, 5, 5.0, {0, 255, 0}, "Ai ales viteza")
		case(3):
			player_hudmessage(id, 5, 5.0, {0, 255, 0}, "Stai nemiscat pentru camuflaj")
	}
	return PLUGIN_HANDLED
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
	static text[512], Float:x, Float:y
	x = g_HudSync[hudid][_x]
	y = g_HudSync[hudid][_y]

	if(time > 0)
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
	else
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)
		
	vformat(text, charsmax(text), msg, 6)
	ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)
}
