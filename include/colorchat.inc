/*
 * Fun functions
 *
 * by Numb
 *
 * This file is provided as is (no warranties).
 *
 */

#if defined _colorchat_included
	#endinput
#endif
#define _colorchat_included
#define ColorChat_Version 1.6

#if !defined _fakemeta_included
	#include <fakemeta>
#endif


enum
{
	proprint_console = 0,
	proprint_center,
	proprint_chat,
};

stock ProPrint(id, type, const msg[], {Float,Sql,Result,_}:...)
{
	if( (id!=0 && !is_user_connected(id)) || (!get_playersnum() && !id) )
		return 0;
	
	new message[192];
	vformat(message, 192, msg, 4);
	
	if( id )
		engfunc(EngFunc_ClientPrintf, id, clamp(type, 0, 2), message);
	else
	{
		static maxclients;
		if( !maxclients )
			maxclients = get_maxplayers();
		
		for( new i=1; i<=maxclients; i++ )
		{
			if( is_user_connected(i) )
				engfunc(EngFunc_ClientPrintf, i, clamp(type, 0, 2), message);
		}
	}
	
	return 1;
}

enum ColorChatType
{
	NORMAL = 1, // clients con_color cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

stock ColorChat(id, ColorChatType:type, const msg[], {Float,Sql,Result,_}:...)
{
	if( (id!=0 && !is_user_connected(id)) || (!get_playersnum() && !id) )
		return 0;
	
	new message[192], TeamName[4][] = 
	{
		"",
		"TERRORIST",
		"CT",
		"SPECTATOR"
	}
	
	vformat(message[1], 191, msg, 4);
	if( message[1]==0x01 || message[1]==0x03 || message[1]==0x04 )
		vformat(message, 192, msg, 4);
	else
	{
		switch( type )
		{
			case NORMAL: message[0] = 0x01; // clients con_color cvar color
			case GREEN: message[0] = 0x04; // Green
			default: message[0] = 0x03; // White, Red, Blue
		}
	}
	//replace_all(message, 192, "%", "%%");
	// Make sure message is not longer than 192 character. Will crash the server.
	//message[192] = '^0'; // max len is 192 anyway
	
	static get_user_msgid_saytext;
	if( !get_user_msgid_saytext )
		get_user_msgid_saytext = get_user_msgid("SayText");
	
	if( id )
	{
	
		new ColorChange, team = get_user_team(id);
		switch( type )
		{
			case RED: ColorChange = Team_Info(id, MSG_ONE_UNRELIABLE, TeamName[1]);
			case BLUE: ColorChange = Team_Info(id, MSG_ONE_UNRELIABLE, TeamName[2]);
			case GREY: ColorChange = Team_Info(id, MSG_ONE_UNRELIABLE, TeamName[0]);
			//default: ColorChange = 0;
		}
	
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid_saytext, _, id);
		write_byte(id);
		write_string(message);
		message_end();
		
		if( ColorChange )
			Team_Info(id, MSG_ONE_UNRELIABLE, TeamName[team]);
		
		return 1;
	}
	else
	{
		static maxclients;
		if( !maxclients )
			maxclients = get_maxplayers();
		
		if( type!=GREY && type!=RED && type!=BLUE )
		{
			for( new i=1; i<=maxclients; i++ )
			{
				if( is_user_connected(i) )
				{
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid_saytext, _, i);
					write_byte(i);
					write_string(message);
					message_end();
				}
			}
			
			return 1;
		}
		
		for( new i=1; i<=maxclients; i++ )
		{
			if( is_user_connected(i) )
			{
				new ColorChange, team = get_user_team(i);
				switch( type )
				{
					case RED: ColorChange = Team_Info(i, MSG_ALL, TeamName[1]);
					case BLUE: ColorChange = Team_Info(i, MSG_ALL, TeamName[2]);
					case GREY: ColorChange = Team_Info(i, MSG_ALL, TeamName[0]);
					//default: ColorChange = 0;
				}
				
				message_begin(MSG_ALL, get_user_msgid_saytext, _, i);
				write_byte(i);
				write_string(message);
				message_end();
				
				if( ColorChange )
					Team_Info(i, MSG_ALL, TeamName[team]);
				
				return 1;
			}
		}
	}
	
	return 0;
}

stock Team_Info(id, type, team[])
{
	static get_user_msgid_teaminfo;
	if( !get_user_msgid_teaminfo )
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
	
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();
	
	return 1;
}
