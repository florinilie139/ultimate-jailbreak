#if defined _ujbm_included
#endinput
#endif
#define _ujbm_included

native get_simon(); //returns simon ID

native get_gamemode(); // returning values: 0 - Freeday; 1 - Usual day; 2 - Zombie Day; 
//3 - hide'n'seek; 4 - Fog Alien; 5 - -invisible Alien; 6 - hidden rpg game with gordon freeman (hidden, unfinished)

native get_duel() //2 freegun //3 box ....

native bool:get_fd(id); // returns true if id has a freeday

native bool:get_wanted(id);// returns true if id is wanted

native set_wanted(id);// set wanted on a prisoner

native get_last();// returns ID of the last prisoner.

native bool:get_vip(id) 
