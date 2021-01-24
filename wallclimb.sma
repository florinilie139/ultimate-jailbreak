// Remove or comment the line below and (re)compile the plugin to use it in mods other than Counter-Strike 1.6
#define use_cstrike



/* Check usage and everything else on http://forums.alliedmods.net/showthread.php?t=72867
** I can't be bothered to write it down here and update it every time


















------------------------
yes, begin of "the code"
------------------------ 




 No, not actually, first my own notes


Todo
- Climb-timelimit to stop players climbing forever (not done)
- Drop player if getting hit by bullets (pending)
- amx_givewallclimb or something similar (suggested by Zizor) (done, amx_climb_set)
- advanced user control, done
- New climbing code (partially done, removed.. sorry :P)
- Optimize old code (partially done, done)
- Create a new climbing video (guess...)
- User-side control
  - User restrictions
- Get some time to do all this (slow progress)


New credits:
v3x



ok, finally, the code begins now  */



#include <amxmodx>
#if defined use_cstrike
#include <cstrike>
#endif
#include <fakemeta>
#include <amxmisc>

#define STR_T           32

// Stock from fakemeta_util, ported by xPaw
#define fm_get_user_button(%1) pev(%1, pev_button)
#define fm_get_entity_flags(%1) pev(%1, pev_flags)

stock fm_set_user_velocity(entity, const Float:vector[3]) {
	set_pev(entity, pev_velocity, vector);
	return 1;
}


new bool:g_WallClimb[33]




#if defined use_cstrike
new bool:ftimeover
new bool:bought_WallClimb[33]
new p_climb_team
new p_climb_buy
new p_climb_cost
#endif

new Float:g_wallorigin[32][3]

new p_climb
new p_climb_mode

new p_climb_method
new p_climb_speed

new p_climb_default

public plugin_init() 
{
	register_plugin("WallClimb", "1.3 private beta", "Python1320")

	register_clcmd("say /climbon","Enable_Climb")
	register_concmd("climbon","Enable_Climb")
	register_clcmd("say /climboff","Disable_Climb")
	register_concmd("climboff","Disable_Climb")
	register_clcmd("say /buyclimb","climb_buy")
	#if defined use_cstrike
	register_concmd("buyclimb","climb_buy")
	register_concmd("amx_climb_set","climb_set",ADMIN_SLAY,"Give or take players climbing ability")
	#endif
	
	p_climb = register_cvar("amx_climb","0")
	p_climb_mode = register_cvar("amx_climb_mode","0")
	
	#if defined use_cstrike
	p_climb_team = register_cvar("amx_climb_team","2")
	#endif
	
	p_climb_method = register_cvar("amx_climb_method","0")
	
	p_climb_speed = register_cvar("amx_climb_speed", "240.0")
	
	p_climb_default = register_cvar("amx_climb_default", "1")
	
	#if defined use_cstrike
	p_climb_buy = register_cvar("amx_climb_buy","0")
	p_climb_cost = register_cvar("amx_climb_cost","5000") 		
	#endif
	
	#if defined use_cstrike
	register_logevent("LogEvent_RoundStart", 2, "0=World triggered", "1=Round_Start")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in") 
	register_event("SendAudio", "Event_RoundEnd", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
	register_event("DeathMsg","EventDeathMsg","a")
	#endif
	
	register_forward(FM_Touch, 		"fwd_touch")
	register_forward(FM_PlayerPreThink, 	"fwd_playerprethink")
	register_forward(FM_PlayerPostThink, 	"fwd_playerpostthink")
}

#if defined use_cstrike
public EventDeathMsg()	
{
	if (!(get_pcvar_num(p_climb_buy) == 2)) 
	{
		return PLUGIN_HANDLED	
	}
	new id = read_data(2)
	bought_WallClimb[id] = false

	return PLUGIN_HANDLED
}


public climb_buy(id) {
	
	if (get_pcvar_num(p_climb_buy) == 0) 
	{
		client_print(id, print_chat, "[AMXX] Sorry, buying WallClimb is disabled")
		return PLUGIN_HANDLED	
	}
		
	if (cs_get_user_money(id) >= get_pcvar_num(p_climb_cost) && !bought_WallClimb[id] ) 
	{
		cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(p_climb_cost), 1)	
		bought_WallClimb[id] = true
		client_print(id, print_chat, "[AMXX] You have bought WallClimb")
	} 
	else // no money
	{
		client_print(id, print_chat, "[AMXX] You don't have enough money to buy WallClimb or you already have one")
		return PLUGIN_HANDLED
	}

	return PLUGIN_HANDLED	
} 


public Event_RoundEnd() {
	ftimeover = false
}
	
public Event_GameRestart()
{
	new Float:fRestartCvar = get_cvar_float("sv_restart")
	set_task((fRestartCvar - 0.5), "Event_RoundEnd")	
}

public LogEvent_RoundStart(id) {
	ftimeover = true
}


// end of cs stuff
#endif

public Enable_Climb(id) {
	g_WallClimb[id] = true
}

public Disable_Climb(id) {
	g_WallClimb[id] = false
}

public client_connect(id) {
	g_WallClimb[id] = true
	#if defined use_cstrike
	bought_WallClimb[id] = false
	#endif

	if (get_pcvar_num(p_climb_default) == 1) {
		Enable_Climb(id)
	} else {
		Disable_Climb(id)
	}
	
	
} 

public fwd_touch(id, world)
{
	if(!is_user_alive(id) || !g_WallClimb[id] || !pev_valid(world))
		return FMRES_IGNORED
	
	new classname[STR_T]
	pev(world, pev_classname, classname, (STR_T-1))
	
	if(equal(classname, "worldspawn") || equal(classname, "func_wall") || equal(classname, "func_breakable"))
		pev(id, pev_origin, g_wallorigin[id])

	return FMRES_IGNORED
}


public fwd_playerprethink(id) 
{

	if(!get_pcvar_num(p_climb) || !g_WallClimb[id] ) 		
		return FMRES_IGNORED
	
	#if defined use_cstrike
	if(!ftimeover)
		return FMRES_IGNORED

	// Team blocker
	// new CsTeams:Team = cs_get_user_team(id)		
	switch (cs_get_user_team(id)) {
		case CS_TEAM_T:	{
			if(get_pcvar_num(p_climb_team) == 1)	
				return FMRES_IGNORED		
		}
	
		case CS_TEAM_CT:	{
			if(get_pcvar_num(p_climb_team) == 0)		
				return FMRES_IGNORED			
		}
	}
	
	// Buysystem check
	if(!bought_WallClimb[id] && (get_pcvar_num(p_climb_buy) == 1 || get_pcvar_num(p_climb_buy) == 2))	 	
		return FMRES_IGNORED
	#endif
	
	
	switch (get_pcvar_num(p_climb_method)) {
	case 1: 	{  // new method
		new button = fm_get_user_button(id)
		
		if (get_pcvar_num(p_climb_mode) == 0 && button & IN_USE && !(button & IN_JUMP)) {
			return FMRES_IGNORED
		}
		else if (get_pcvar_num(p_climb_mode) == 1 && button & IN_JUMP && !(button & IN_USE)) {
			return FMRES_IGNORED
		}		
		
		if((button & IN_JUMP || button & IN_USE) ) 	{
			static Float:origin[3]
			pev(id, pev_origin, origin)
			if(get_distance_f(origin, g_wallorigin[id]) > 10.0)
				return FMRES_IGNORED  // if not near wall
		
			if(fm_get_entity_flags(id) & FL_ONGROUND) {
			// (works but is buggy)	client_cmd(id,"+jump;wait;-jump")  //workaround for +use climbing
				return FMRES_IGNORED
			}
		
		
		
			if(button & IN_FORWARD)	{
				static Float:velocity[3]
				velocity_by_aim(id, get_pcvar_num(p_climb_speed), velocity)
				fm_set_user_velocity(id, velocity)
			}
			else if(button & IN_BACK) {
				static Float:velocity[3]
				velocity_by_aim(id, -get_pcvar_num(p_climb_speed), velocity)
				fm_set_user_velocity(id, velocity)
			}
			
		}    // buttons check
			
			
	
	} // end of new method

	// memo to self: reversed number order, guess why :)
		case 0: 	{ 
			new Float: fVelocity[3]
			new Float:pcvar_speed = get_pcvar_float( p_climb_speed )
			pev(id,pev_velocity,fVelocity)
			new Buttons = pev(id,pev_button)	
			

			switch (get_pcvar_num(p_climb_mode)) {
				case 1:	{
					if(Buttons & IN_JUMP && (Buttons & IN_FORWARD || Buttons & IN_BACK) ) 
					{
						if(fVelocity[0] == 0.0 || fVelocity[1] == 0.0)
						{
							fVelocity[1] = 10.0
							fVelocity[2] = pcvar_speed
							set_pev(id,pev_velocity, fVelocity)
						}
					}
				}
				
				case 0:	{
						if(Buttons & IN_USE && (Buttons & IN_FORWARD || Buttons & IN_BACK) ) 
						{
							if(fVelocity[0] == 0.0 || fVelocity[1] == 0.0)
							{
								fVelocity[1] = 10.0
								fVelocity[2] = pcvar_speed
								set_pev(id,pev_velocity, fVelocity)
							}
						} 
					}
			}
		}
		case 3: 	{ // new method :P
		
		}
	
	}
	
	return FMRES_IGNORED
} 

public climb_set(id,level,cid) 
{
     if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED
 
     new Arg1[32]; read_argv(1, Arg1, 32)
     new Arg2[4];   read_argv(2, Arg2, 3)
     

     if (Arg1[0] == '@')
     {
          new players[32], num
          get_players(players, num)
          new i
   
   #if defined use_cstrike
	new Team = 0
	switch (Arg1[1]) {
		case 'C': Team = 2
		case 'T': Team = 1
	}
	#endif
	
	
          for (i=0; i<num; i++)
          {
		#if defined use_cstrike
	   if (!Team)
               {
		#endif
		switch (Arg2[1]) {
		    case 'n':	    Enable_Climb(players[i])
		    case 'f','i': Disable_Climb(players[i])
		
		}
	    #if defined use_cstrike  
	   } else { 
	      
                    if (get_user_team(players[i]) == Team)
                    {
		 
                          switch (Arg2[1]) {
		    case 'n':	    Enable_Climb(players[i])
		    case 'f','i': Disable_Climb(players[i])
		
					}
                }
			}
	  #endif
        }
     } else {
          new player = cmd_target(id, Arg1, 2)
          if (!player)
          {
               console_print(id, "Sorry, player %s could not be found or targetted!", Arg1)
               return PLUGIN_HANDLED
          } else {
                                  switch (Arg2[1]) {
		    case 'n':	    Enable_Climb(id)
		    case 'f','d':      Disable_Climb(id)
	      }
          }
     }
 
     return PLUGIN_HANDLED
}


