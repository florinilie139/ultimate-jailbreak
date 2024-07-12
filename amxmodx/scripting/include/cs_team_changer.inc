/*
	CS Team Changer Functions
	
	by Hattrick @ www.CsRedDevil.com
	
	For: Counter-Strike and Counter-Strike: Condition Zero
*/

#if defined cs_team_changer_included
	#endinput
#endif
#define cs_team_changer_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_team_changer
	
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_team_changer
	#endif
#else
	#pragma library cs_team_changer
#endif // AMXX_VERSION_NUM

/*
	The teams you can use
*/
enum
{
	TEAM_UNASSIGNED = 0,
	TEAM_TERRORIST,		// This will be defined as 1
	TEAM_CT,		// This will be defined as 2
	TEAM_SPECTATOR		// This will be defined as 3
};

/*
	ATTENTION:
		You can change the team at 32 players in same time (using the 'while' and the 'for') for get all players and change the teams at all
		The server won't crash
		
		But if you are trying to change the teams at 32 players in same time with the cstrike module the server will crash!
*/

/*
	Player model update -
	Tablescore update +
	Team ID update +
	Team offset update +
	
	// This will change the player team, will send the TeamInfo message and will update the team id in AMXX API
*/
native cs_set_team( _index, _team );

/*
	Player model update -
	Tablescore update -
	Team ID update +
	Team offset update -
	
	// This will update the team ID in AMXX API
*/
native cs_set_team_id( _index, _team );

/*
	Player model update -
	Tablescore update -
	Team ID update -
	Team offset update +
	
	This will update the player team for example from TERRORIST to CT
*/
native cs_set_team_offset( _index, _team );

/*
	Player model update -
	Tablescore update +
	Team ID update -
	Team offset update -
	
	This will send the TeamInfo message from engine!
*/
native cs_set_team_tablescore( _index, _team );

