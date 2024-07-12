
/* AMX Mod X
*   Snowballs
*
*     DESCRIPTION
*       This plugin is changing grenade view model and grenade world model
*	for snowball models. Also it is adding (optional) trail and glow
*
*     MODULES
*	fakemeta
*
*     CVARS
*	snowballs_on - turns snowballs on/off (default on)
*	snowballs_trail - turns on/off trail behind snowball (default on)
*	snowballs_rendering - turns on/off a glow for snowballs (default on)
*
*     VERSIONS
*	1.0 - first release
*	
*	1.1 - cleaned up the code (thanks to my friends for tips)
*
*/

#include <amxmodx>
#include <fakemeta>

new VERSION[] = "1.1"

new const model_nade_world[] = { "models/snowballs/w_snowball.mdl" }
new const model_nade_view[] = { "models/snowballs/v_snowball.mdl" }
new const model_trail[] = { "sprites/laserbeam.spr" }

//Cvars
new on
new rendering
new trail

//For snowball trail
new g_trail

public plugin_init()
{
	register_plugin("Snowballs", VERSION, "FragOwn")
	on = register_cvar("snowballs_on","1")
	if(get_pcvar_num(on))
	{
		rendering = register_cvar("snowballs_rendering","1")
		trail = register_cvar("snowballs_trail","1")
		
		register_forward(FM_SetModel,"forward_model")
		
		register_event("CurWeapon","func_modelchange_hook","be","1=1","2=4","2=9","2=25")
	}
	
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel,model_nade_world)
	
	engfunc(EngFunc_PrecacheModel,model_nade_view)
		
	engfunc(EngFunc_PrecacheModel,model_nade_view)
	
	g_trail = engfunc(EngFunc_PrecacheModel,model_trail)
}
public func_modelchange_hook(id)
{
	set_pev(id, pev_viewmodel2,model_nade_view)
}
public forward_model(entity,const model[])
{
	if(!pev_valid(entity))
	{
		return FMRES_IGNORED
	}
	new rend = get_pcvar_num(rendering)
	new tr = get_pcvar_num(trail)
	
	if ( model[ 0 ] == 'm' && model[ 7 ] == 'w' && model[ 8 ] == '_' )
	{
		switch ( model[ 9 ] )
		{
			case 'f' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(tr)
				{
					fm_set_trail(entity,255,255,255,255)
				}
				if(rend)
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 255 )
				}
		
			}
			case 'h' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(tr)
				{
					fm_set_trail(entity,255,0,0,255)
				}
				if(rend)
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 255 )
				}
			}
			case 's' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(tr)
				{
					fm_set_trail(entity,0,255,0,255)
				}
				if(rend)
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 255 )
				}
                
			}
			default:
			{
				return FMRES_IGNORED
			}
		}
		return FMRES_SUPERCEDE
	}
    
	return FMRES_IGNORED
}
stock fm_set_trail(id,r,g,b,bright)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)              
	write_short(id)         
	write_short(g_trail)        
	write_byte(25)              
	write_byte(5)               
	write_byte(r)             
	write_byte(g)               
	write_byte(b)                
	write_byte(bright)                
	message_end()
}
// teame06's function
stock fm_set_rendering(index, fx=kRenderFxNone, r=0, g=0, b=0, render=kRenderNormal, amount=16)
{
	set_pev(index, pev_renderfx, fx)
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)
	set_pev(index, pev_rendercolor, RenderColor)
	set_pev(index, pev_rendermode, render)
	set_pev(index, pev_renderamt, float(amount))
}
