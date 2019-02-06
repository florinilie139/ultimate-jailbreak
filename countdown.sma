#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <ujbm>

#define TASK_COUNTDOWN 21900

new g_Countdown

public plugin_init()
{
	register_plugin("Countdown","1","Dumnezeu")
	
	register_clcmd("say", "cmd_say")

	return PLUGIN_CONTINUE 
}

public cmd_say(id)
{
	new g_Simon = get_simon()
	if (g_Simon == id || (get_user_flags(id) & ADMIN_SLAY))
	{
		new Args[64], sName[32]
		read_args(Args, charsmax(Args))
		remove_quotes(Args)
	
		get_user_name(id, sName, charsmax(sName))
	
		new sLeft[16], sRight[16];
		strtok(Args, sLeft, charsmax(sLeft), sRight, charsmax(sRight))
	
		if(equali(sLeft, "/cd") || equali(sLeft, "/count"))
		{
	
			if(task_exists(TASK_COUNTDOWN))
			{
				client_print(id, print_chat, "Deja exista o numaratoare.")
				return 1;
			}
		
			new cd;
		
			switch( (cd = str_to_num(sRight)) )
			{
				case 1..15:
				{
					g_Countdown = cd;
					client_print(0, print_chat, "%s a dat o numaratoare inversa incepand de la %d.", sName, g_Countdown)
					set_task(1.0, "task_countdown", TASK_COUNTDOWN, _, _, "b")
				}
				default: client_print(id, print_chat, "Alege un numar intre 1 si 15!")
			}
		}
	}
	return PLUGIN_CONTINUE
}

public task_countdown(taskid)
{
	if(g_Countdown)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.7, 1, 2.0, 0.9, _, _, -1)
		show_hudmessage(0, "< %d >", g_Countdown)
		
		new strWord[16];
		num_to_word(g_Countdown, strWord, charsmax(strWord))
		
		client_cmd(0, "spk ^"%s^"", strWord);
		
		g_Countdown--;
	}
	else
	{
		remove_task(taskid);
		client_cmd(0, "spk jbextreme/start_.wav");
		
		set_hudmessage(0, 255, 0, -1.0, 0.7, 1, 2.0, 1.0, _, _, -1)
		show_hudmessage(0, "< START >")
	}
	return PLUGIN_CONTINUE
}