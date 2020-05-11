#include <amxmodx>
#include <amxmisc>

new name[32],namet[32],tname[33];
new evoy;
public plugin_init()
{
	register_plugin("SuperSlap","1.3","anakin_cstrike");
	register_concmd("amx_superslap","superslap_cmd",ADMIN_SLAY, "- <target> <power> <interval> <times>");
	evoy = register_cvar("superslap_admin","0");
}
public superslap_cmd(id,level,cid)
{
	if(!cmd_access(id,level,cid,5))
		return PLUGIN_HANDLED;
	if(read_argc() < 4)
	{
		console_print(id,"amx_superslap <target> <power> <interval> <times>");
		return PLUGIN_HANDLED;
	}
	new arg[32],arg2[4],arg3[4],arg4[4];
	read_argv(1,arg,31);
	read_argv(2,arg2,3);
	read_argv(3,arg3,3);
	read_argv(4,arg4,3);
	get_user_name(id,name,31);
	
	new slappower = str_to_num(arg2);
	new times = str_to_num(arg4);
	new Float:interval = str_to_float(arg3);
	new array[2];
	array[1] = slappower;
	
	if(arg[0] == '@')
	{
		new teamname[11],players[32],num,index,i;
		if(arg[1])
		{
			if(arg[1] == 'T')
			{
				copy(teamname,sizeof teamname - 1,"TERRORIST");
				copy(tname,sizeof tname - 1,"Terrorists");
			} else if(arg[1] == 'C' && arg[2] == 'T') {
				copy(teamname,sizeof teamname - 1,"CT");
				copy(tname,sizeof tname - 1,"Counter-Terrorists");
			}
			get_players(players,num,"ae",teamname);
		} else {
			copy(tname,sizeof tname - 1,"All");
			get_players(players,num,"a");
		}
		for(i = 0;i < num;i++)
		{
			index = players[i];
			if(!is_user_alive(index)) continue;
			if(index == id && get_pcvar_num(evoy) == 0) continue;
			array[0] = index;
			set_task(interval,"superslap",index,array,2,"a",times);
		}
		log_amx("ADMIN %s: SuperSlap %s. Power: %d. Number of Slaps: %d. Interval: %f",name,tname,slappower,times,interval);
	} else {
		new target = cmd_target(id,arg,7);
		if(!target)
			return PLUGIN_HANDLED;
		array[0] = target;
		get_user_name(target,namet,31);
		
		set_task(interval, "superslap",0,array,2,"a", times);
		log_amx("ADMIN %s: SuperSlap %s. Power: %d. Number of Slaps: %d. Interval: %f",name,namet,slappower,times,interval);
	}
	return PLUGIN_HANDLED;
}
public superslap(array[2])
{
	new target = array[0];
	new powerslap = array[1];
	new alive = is_user_alive(target);
	
	alive ? user_slap(target,powerslap,1) : remove_task(target);
}
