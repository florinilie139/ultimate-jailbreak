#include <amxmodx>
#include <amxmisc>

#define OLD_CONNECTION_QUEUE 10

public plugin_init()
{
register_plugin("Amx_last","1.0", "M@$t3r_@dy")
register_concmd("amx_last", "cmdLast", ADMIN_BAN, " - arata informatii despre userii care au iesi recent de pe server");
}

new g_Names[OLD_CONNECTION_QUEUE][32];
new g_SteamIDs[OLD_CONNECTION_QUEUE][32];
new g_IPs[OLD_CONNECTION_QUEUE][32];
new g_Access[OLD_CONNECTION_QUEUE];
new g_Tracker;
new g_Size;

stock InsertInfo(id)
{

if (g_Size > 0)
{
new ip[32]
new auth[32];

get_user_authid(id, auth, 31);
get_user_ip(id, ip, 31, 1);

new last = 0;

if (g_Size < sizeof(g_SteamIDs))
{
last = g_Size - 1;
}
else
{
last = g_Tracker - 1;

if (last < 0)
{
last = g_Size - 1;
}
}

if (equal(auth, g_SteamIDs[last]) &&
equal(ip, g_IPs[last]))
{
get_user_name(id, g_Names[last], 31);
g_Access[last] = get_user_flags(id);

return;
}
}

new target = 0; // the slot to save the info at

if (g_Size < sizeof(g_SteamIDs))
{
target = g_Size;

++g_Size;

}
else
{
target = g_Tracker;

++g_Tracker;
if (g_Tracker == sizeof(g_SteamIDs))
{
g_Tracker = 0;
}
}

get_user_authid(id, g_SteamIDs[target], 31);
get_user_name(id, g_Names[target], 31);
get_user_ip(id, g_IPs[target], 31, 1);

g_Access[target] = get_user_flags(id);

}
stock GetInfo(i, name[], namesize, auth[], authsize, ip[], ipsize, &access)
{
if (i >= g_Size)
{
abort(AMX_ERR_NATIVE, "GetInfo: Out of bounds (%d:%d)", i, g_Size);
}

new target = (g_Tracker + i) % sizeof(g_SteamIDs);

copy(name, namesize, g_Names[target]);
copy(auth, authsize, g_SteamIDs[target]);
copy(ip, ipsize, g_IPs[target]);
access = g_Access[target];

}
public client_disconnect(id)
{
if (!is_user_bot(id))
{
InsertInfo(id);
}
}


public cmdLast(id, level, cid)
{
if (!cmd_access(id, level, cid, 1))
{
return PLUGIN_HANDLED;
}

new name[32];
new authid[32];
new ip[32];
new flags[32];
new access;

console_print(id, "%19s %20s %15s %s", "name", "authid", "ip", "access");

for (new i = 0; i < g_Size; i++)
{
GetInfo(i, name, 31, authid, 31, ip, 31, access);

get_flags(access, flags, 31);

console_print(id, "%19s %20s %15s %s", name, authid, ip, flags);
}

console_print(id, "%d old connections saved.", g_Size);

return PLUGIN_HANDLED;
}