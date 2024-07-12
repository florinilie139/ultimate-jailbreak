#if defined _zones_included
#endinput
#endif
#define _zones_included

enum _:typeZn
{
    CTZONE = 0,
    CANTEEN,
    CELLS,
    WORKOUT
}

native whatzoneisin(id) //return the number of the zone