#if defined _ujbm_included
#endinput
#endif
#define _ujbm_included

native get_simon(); //returns simon ID

native get_gamemode(); // returning values: 0 - Freeday; 1 - Usual day; 2 - Zombie Day; 
//3 - hide'n'seek; 4 - Fog Alien; 5 - -invisible Alien; 6 - hidden rpg game with gordon freeman (hidden, unfinished)

enum _:days{
    AlienDayT =-2,
    ZombieDayT,       //-1
    Freeday,          //0
    NormalDay,        //1
    ZombieDay,        //2
    HnsDay,           //3
    AlienDay,         //4
    AlienHiddenDay,   //5
    GunDay,           //6
    ColaDay,          //7
    GravityDay,       //8
    FireDay,          //9
    BugsDay,          //10
    NightDay,         //11
    SpartaDay,        //12
    SpiderManDay,     //13
    CowboyDay,        //14
    SpartaTeroDay,    //15
    FreezeTagDay,     //16
    StarWarsDay,      //17
    RipperDay,        //18
    FunDay,           //19
    //AscunseleaDay,  //20
    //PrinseleaDay,   //21
    OneBullet         //22
}


native get_duel() //2 freegun //3 box ....

native bool:get_fd(id); // returns true if id has a freeday

native bool:get_wanted(id);// returns true if id is wanted

native set_wanted(id);// set wanted on a prisoner

native get_last();// returns ID of the last prisoner.

native get_model(buffer[], lenght)

native get_day();
