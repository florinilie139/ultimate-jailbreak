#include <amxmodx>
#include <amxmisc>

new const PLUGIN [] = "Name Scan"
new const VERSION [] = "1.1";
new const AUTHOR [] = "LordOfNothing";


new Array:g_Stroke = Invalid_Array;

new xmsg;



public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	xmsg = register_cvar("namescan_msg", "[AMXX] Change your name !");
	
}

public client_connectex(id)
{
	if (!ArraySize(g_Stroke))
	{
		return PLUGIN_CONTINUE;
	}
	
	static Stroke[64], Size = 0;
	
	new name[32]
	new szMsg[50];
	get_pcvar_string(xmsg, szMsg, 49);
	get_user_name(id, name, 31)
	
	
	for (Size = 0; Size < ArraySize(g_Stroke); Size++)
	{
		ArrayGetString(g_Stroke, Size, Stroke, charsmax(Stroke));
		
		if (contain(name, Stroke))
		{
			//server_cmd("kick #%d %s",userid,szMsg)
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if (!ArraySize(g_Stroke))
	{
		return PLUGIN_CONTINUE;
	}
	
	static Stroke[64], Size = 0;
	
	new name[32]
	new szMsg[50];
	get_pcvar_string(xmsg, szMsg, 49);
	new userid = get_user_userid(id)
	get_user_info(id, "name", name,31) 
	
	
	for (Size = 0; Size < ArraySize(g_Stroke); Size++)
	{
		ArrayGetString(g_Stroke, Size, Stroke, charsmax(Stroke));
		
		if (contain(name, Stroke))
		{
			server_cmd("kick #%d %s",userid,szMsg)
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	static File = 0, Buffer[64], Location[256];
	
	g_Stroke = ArrayCreate(64 /* maximum length */);
	
	get_localinfo("amxx_configsdir", Location, charsmax(Location));
	
	add(Location, charsmax(Location), "/characters.ini ");
	
	if (!file_exists(Location))
	{
		File = fopen(Location, "w+" /* write file */);
		
		if (File)
		{
			fclose(File);
		}
	}
	
	File = fopen(Location, "rt" /* read file as text */);
	
	if (File)
	{
		while (!feof(File))
		{
			fgets(File, Buffer, charsmax(Buffer));
			
			trim(Buffer);
			
			if (!strlen(Buffer) || Buffer[0] == ';')
			{
				continue;
			}
			
			ArrayPushString(g_Stroke, Buffer);
		}
		
		fclose(File);
	}
}