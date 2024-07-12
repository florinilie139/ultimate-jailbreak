/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 07-04-09
*
*  ============
*   Changelog:
*  ============
*
*  v2.2
*    -Added Off / Admin only capabilities
*
*  v2.1
*    -Added some pets
*    -Fixed death animations
*    -Fixed chat text bug
*
*  v2.0
*    -Added ML
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.2"

#include <amxmodx>
#include <amxmisc>
#include <chr_engine>
#include <vip_base>

#define PET_NUM	17

static const pet_name[PET_NUM][32] =
{
	"Headcrab",
	"Rat",
	"Bat",
	"Frog",
	"Floater",
	"Cockroach",
	"Hyper Bat",
	"Mom",
	"Grunt",
	"Fish",
	"Baby Headcrab",
	"Roach",
	"Gargantuan",
	"Bull Squid",
	"Hound Eye",
	"Loading Machine",
	"Controller"
}

static const pet_models[PET_NUM][32] =
{
	"models/headcrab.mdl",
	"models/bigrat.mdl",
	"models/boid.mdl",
	"models/chumtoad.mdl",
	"models/floater.mdl",
	"models/roach.mdl",
	"models/stukabat.mdl",
	"models/big_mom.mdl",
	"models/agrunt.mdl",
	"models/archer.mdl",
	"models/baby_headcrab.mdl",
	"models/roach.mdl",
	"models/garg.mdl",
	"models/bullsquid.mdl",
	"models/houndeye.mdl",
	"models/loader.mdl",
	"models/controller.mdl"
}

static const pet_idle[PET_NUM] =
{
	0,
	1,
	0,
	0,
	0,
	1,
	13,
	0,
	0,
	0,
	1,
	0,
	7,
	1,
	1,
	3,
	3
}

static const Float:pet_idle_speed[PET_NUM] =
{
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	0.5,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0
}

static const pet_run[PET_NUM] =
{
	4,
	4,
	0,
	5,
	0,
	0,
	13,
	3,
	3,
	6,
	4,
	0,
	4,
	0,
	3,
	2,
	9
}

static const Float:pet_run_speed[PET_NUM] =
{
	2.0,
	6.0,
	3.0,
	0.75,
	1.0,
	1.0,
	13.0,
	1.0,
	1.0,
	0.6,
	0.6,
	1.0,
	1.0,
	2.0,
	1.0,
	0.4,
	1.0
}

static const pet_die[PET_NUM] =
{
	7,
	7,
	0,
	12,
	0,
	0,
	5,
	4,
	22,
	9,
	7,
	1,
	14,
	16,
	6,
	5,
	18
}

static const Float:pet_die_length[PET_NUM] =
{
	2.4,
	2.4,
	0.1,
	3.0,
	0.1,
	0.1,
	3.0,
	5.0,
	5.0,
	3.0,
	3.0,
	1.0,
	6.0,
	2.5,
	2.5,
	7.0,
	7.0
}

static const Float:pet_minus_z_standing[PET_NUM] =
{
	36.0,
	36.0,
	5.0,
	36.0,
	5.0,
	36.0,
	10.0,
	36.0,
	36.0,
	20.0,
	36.0,
	36.0,
	36.0,
	36.0,
	36.0,
	36.0,
	0.0
}

static const Float:pet_minus_z_crouching[PET_NUM] =
{
	16.0,
	16.0,
	6.0,
	16.0,
	6.0,
	16.0,
	11.0,
	16.0,
	16.0,
	30.0,
	16.0,
	16.0,
	16.0,
	16.0,
	16.0,
	16.0,
	0.0
}

static const Float:pet_max_distance[PET_NUM] =
{
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	1000.0,
	600.0,
	300.0,
	300.0,
	300.0,
	800.0,
	400.0,
	400.0,
	1000.0,
	800.0
}

static const Float:pet_min_distance[PET_NUM] =
{
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	300.0,
	200.0,
	80.0,
	80.0,
	80.0,
	250.0,
	100.0,
	100.0,
	300.0,
	200.0
}

new pet[33]
new pettype[33]
new maxplayers
new pets_off_pcvar
new pets_adminonly_pcvar

//menu
new currently_on[33]

public plugin_init()
{
	register_plugin("GHW Pet Followers",VERSION,"GHW_Chronic")

	register_concmd("amx_pets","cmd_pets",ADMIN_SLAY," Brings up the menu to turn pets on/admin only/off")
	register_menu("PetsMenu",(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9),"menu_pressed")

	register_clcmd("say","say_hook")
	register_clcmd("say_team","say_hook")

	register_event("DeathMsg","DeathMsg","a")
	register_forward(FM_Think,"FM_Think_hook")

	pets_off_pcvar = register_cvar("pets_off","0")
	pets_adminonly_pcvar = register_cvar("pets_adminonly","0")

	maxplayers = get_maxplayers()

	register_dictionary("GHW_Pet_Followers.txt")
}

public plugin_precache()
{
	for(new i=0;i<PET_NUM;i++) precache_model(pet_models[i])
}

public cmd_pets(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}

	currently_on[id] = 0
	create_menu(id)

	return PLUGIN_HANDLED
}

public create_menu(id)
{
	new Menu[1024]
	format(Menu,1023,"GHW Pet Mod^n^n")

	new keys

	new current_setting[32]
	for(new i=currently_on[id];i<PET_NUM && i<currently_on[id] + 7;i++)
	{
		if(get_pcvar_num(pets_off_pcvar) & power(2,i))
		{
			format(current_setting,31,"Off")
		}
		else if(get_pcvar_num(pets_adminonly_pcvar) & power(2,i))
		{
			format(current_setting,31,"Admin")
		}
		else
		{
			format(current_setting,31,"On")
		}
		format(Menu,1023,"%s%d. %s \R%s^n",Menu,i - currently_on[id] + 1,pet_name[i],current_setting)

		keys |= (1<<i - currently_on[id])
	}

	if(currently_on[id] > 0)
	{
		format(Menu,1023,"%s^n8. Back",Menu)
		keys |= (1<<7)
	}
	if(currently_on[id] + 7 < PET_NUM)
	{
		format(Menu,1023,"%s^n9. Next",Menu)
		keys |= (1<<8)
	}

	format(Menu,1023,"%s^n^n0. Exit",Menu)
	keys |= (1<<9)

	show_menu(id,keys,Menu,-1,"PetsMenu")
}

public menu_pressed(id,key)
{
	switch(key)
	{
		case 7:
		{
			//Back
			currently_on[id] -= 7
		}
		case 8:
		{
			//Next
			currently_on[id] += 7
		}
		case 9:
		{
			//Nothing - Exit
			return PLUGIN_HANDLED
		}
		default:
		{
			//Selected a Pet
			if(get_pcvar_num(pets_off_pcvar) & power(2,key + currently_on[id]))
			{
				set_pcvar_num(pets_off_pcvar,get_pcvar_num(pets_off_pcvar) - power(2,key + currently_on[id]))//Out of Off list
			}
			else if(get_pcvar_num(pets_adminonly_pcvar) & power(2,key + currently_on[id]))
			{
				set_pcvar_num(pets_adminonly_pcvar,get_pcvar_num(pets_adminonly_pcvar) - power(2,key + currently_on[id]))//Out of Admin list
				set_pcvar_num(pets_off_pcvar,get_pcvar_num(pets_off_pcvar) + power(2,key + currently_on[id]))//Into Off list
			}
			else
			{
				set_pcvar_num(pets_adminonly_pcvar,get_pcvar_num(pets_adminonly_pcvar) + power(2,key + currently_on[id]))//Into Admin list
			}
		}
	}

	create_menu(id)

	return PLUGIN_HANDLED
}

public client_disconnect(id) handle_DeathMsg(id)

public DeathMsg() handle_DeathMsg(read_data(2))

public handle_DeathMsg(id)
{
	if(pet[id] && pev_valid(pet[id]))
	{
		set_pev(pet[id],pev_animtime,100.0)
		set_pev(pet[id],pev_framerate,1.0)
		set_pev(pet[id],pev_sequence,pet_die[pettype[id]])
		set_pev(pet[id],pev_gaitsequence,pet_die[pettype[id]])
		set_task(pet_die_length[pettype[id]],"remove_pet",pet[id])
	}
	pet[id]=0
}

public remove_pet(ent) if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity,ent)

public say_hook(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_E)
	{
		new arg[32]
		read_argv(1,arg,31)
		if(equali(arg,"/pet Headcrab")) pet_cmd_handle(id,0)
		else if(equali(arg,"/pet Rat")) pet_cmd_handle(id,1)
		else if(equali(arg,"/pet Bat")) pet_cmd_handle(id,2)
		else if(equali(arg,"/pet Frog")) pet_cmd_handle(id,3)
		else if(equali(arg,"/pet Floater")) pet_cmd_handle(id,4)
		else if(equali(arg,"/pet Cockroach")) pet_cmd_handle(id,5)
		else if(equali(arg,"/pet Hyper") || equali(arg,"/pet Hyper Bat")) pet_cmd_handle(id,6)
		else if(equali(arg,"/pet Mom")) pet_cmd_handle(id,7)
		else if(equali(arg,"/pet Grunt")) pet_cmd_handle(id,8)
		else if(equali(arg,"/pet Fish")) pet_cmd_handle(id,9)
		else if(equali(arg,"/pet Baby Headcrab") || equali(arg,"/pet Baby")) pet_cmd_handle(id,10)
		else if(equali(arg,"/pet Roach") || equali(arg,"/pet Cockroach")) pet_cmd_handle(id,11)
		else if(equali(arg,"/pet Garg") || equali(arg,"/pet Gargantuan")) pet_cmd_handle(id,12)
		else if(equali(arg,"/pet Bull") || equali(arg,"/pet Bull Squid") || equali(arg,"/pet BullSquid") || equali(arg,"/pet Squid")) pet_cmd_handle(id,13)
		else if(equali(arg,"/pet Hound") || equali(arg,"/pet Hound Eye") || equali(arg,"/pet HoundEye") || equali(arg,"/pet Eye")) pet_cmd_handle(id,14)
		else if(equali(arg,"/pet Loader") || equali(arg,"/pet Loading") || equali(arg,"/pet Machine") || equali(arg,"/pet Loading Machine")) pet_cmd_handle(id,15)
		else if(equali(arg,"/pet Boss") || equali(arg,"/pet Controller")) pet_cmd_handle(id,16)
		else if(containi(arg,"/pet")==0) pet_cmd_handle(id,random_pet(id))
		else if(containi(arg,"/nopet")==0)
		{
			if(pet[id]) client_print(id,print_chat,"[AMXX] %L",id,"MSG_REMOVEPET")
			else client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOREMOVEPET")
			handle_DeathMsg(id)
		}
	}
}

public random_pet(id)
{
	new num = random_num(0,PET_NUM-1);

	if((get_pcvar_num(pets_off_pcvar) & power(2,num)) || ((get_pcvar_num(pets_adminonly_pcvar) & power(2,num)) && !is_user_admin(id)))
		num = random_pet(id)

	return num;
}

public pet_cmd_handle(id,num)
{
	if(pet[id])
	{
		handle_DeathMsg(id)
		//client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOGIVEPET_HAVE")
	}
	else if(!is_user_alive(id))
	{
		client_print(id,print_chat,"[AMXX] %L",id,"MSG_NOGIVEPET_DEAD")
	}
	else
	{
		if(get_pcvar_num(pets_off_pcvar) & power(2,num))
		{
			client_print(id,print_chat,"[AMXX] %L",id,"MSG_DISABLED")
		}
		else if((get_pcvar_num(pets_adminonly_pcvar) & power(2,num)) && !is_user_admin(id))
		{
			client_print(id,print_chat,"[AMXX] %L",id,"MSG_ADMINONLY")
		}
		else
		{
			pet[id] = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
			set_pev(pet[id],pev_classname,"GHW_Pet")
			pettype[id] = num
			engfunc(EngFunc_SetModel,pet[id],pet_models[pettype[id]])
			new Float:origin[3]
			pev(id,pev_origin,origin)
			if(is_user_crouching(id)) origin[2] -= pet_minus_z_crouching[pettype[id]]
			else origin[2] -= pet_minus_z_standing[pettype[id]]
			set_pev(pet[id],pev_origin,origin)
			set_pev(pet[id],pev_solid,SOLID_NOT)
			set_pev(pet[id],pev_movetype,MOVETYPE_FLY)
			set_pev(pet[id],pev_owner,33)
			set_pev(pet[id],pev_nextthink,1.0)
			set_pev(pet[id],pev_sequence,0)
			set_pev(pet[id],pev_gaitsequence,0)
			set_pev(pet[id],pev_framerate,1.0)
			client_print(id,print_chat,"[AMXX] %L",id,"MSG_GIVEPET",pet_name[pettype[id]])
		}
	}
}

public FM_Think_hook(ent)
{
	for(new i=0;i<=maxplayers;i++)
	{
		if(ent==pet[i])
		{
			static Float:origin[3]
			static Float:origin2[3]
			static Float:velocity[3]
			pev(ent,pev_origin,origin2)
			get_offset_origin_body(i,Float:{50.0,0.0,0.0},origin)
			if(is_user_crouching(i)) origin[2] -= pet_minus_z_crouching[pettype[i]]
			else origin[2] -= pet_minus_z_standing[pettype[i]]

			if(get_distance_f(origin,origin2)>pet_max_distance[pettype[i]])
			{
				set_pev(ent,pev_origin,origin)
			}
			else if(get_distance_f(origin,origin2)>pet_min_distance[pettype[i]])
			{
				get_speed_vector(origin2,origin,250.0,velocity)
				set_pev(ent,pev_velocity,velocity)
				if(pev(ent,pev_sequence)!=pet_run[pettype[i]] || pev(ent,pev_framerate)!=pet_run_speed[pettype[i]])
				{
					set_pev(ent,pev_frame,1)
					set_pev(ent,pev_sequence,pet_run[pettype[i]])
					set_pev(ent,pev_gaitsequence,pet_run[pettype[i]])
					set_pev(ent,pev_framerate,pet_run_speed[pettype[i]])
				}
			}
			else if(get_distance_f(origin,origin2)<pet_min_distance[pettype[i]] - 5.0)
			{
				if(pev(ent,pev_sequence)!=pet_idle[pettype[i]] || pev(ent,pev_framerate)!=pet_idle_speed[pettype[i]])
				{
					set_pev(ent,pev_frame,1)
					set_pev(ent,pev_sequence,pet_idle[pettype[i]])
					set_pev(ent,pev_gaitsequence,pet_idle[pettype[i]])
					set_pev(ent,pev_framerate,pet_idle_speed[pettype[i]])
				}
				set_pev(ent,pev_velocity,Float:{0.0,0.0,0.0})
			}
			pev(i,pev_origin,origin)
			origin[2] = origin2[2]
			entity_set_aim(ent,origin)

			set_pev(ent,pev_nextthink,1.0)
			break;
		}
	}
}
