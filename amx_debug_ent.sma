#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define DEBUG_PREFIX "[AMXX DEBUG]"

new gDebugEnt = 0

new iTaskEnt = 99921001

public plugin_init()
{
	register_plugin("Test Plugin", "0.1", "Piegtas")
	register_concmd("amx_debug_ent", "DebugEnt")
}

public DebugEnt()
{
	if(gDebugEnt)
	{
		remove_task(iTaskEnt)
		gDebugEnt = 0
		return
	}

	gDebugEnt = 1
	set_task(2.0, "ShowEntStats", iTaskEnt, "", 0, "b")
	return
}

public ShowEntStats()
{
	new iEntCount = entity_count()
	new iEntMax = global_get(glb_maxEntities)
	log_to_file( "Rapoarte.log","%s %d entities in world (%d max!)", DEBUG_PREFIX, iEntCount, iEntMax );
}