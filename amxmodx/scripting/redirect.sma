#include <amxmodx>

public plugin_init ()
{
	register_plugin("Redirect", "1.0", "Eclipse")
}

public client_connect (id)
{
	client_cmd(id,"connect 82.79.60.100")
}