#if defined _furien
  #endinput
#endif
#define _furien

#pragma reqlib furien

#define FURIEN_VERSION	"0.7.3 Ultimate"

enum _:ItemRestriction {
	Furien,
	AntiFurien
}

forward furien_team_change(id);
forward furien_round_restart(id);
native furien_get_user_team(id);