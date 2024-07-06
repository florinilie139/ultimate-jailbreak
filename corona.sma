#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <ujbm.inc>

#define PLUGIN_NAME    "Corona Virus"
#define PLUGIN_AUTHOR    "Florin Ilie aka (|Eclipse|)"
#define PLUGIN_VERSION    "1.0"

#define MAX_CLIENTS 32

#define COUGH_SOUND "jbdobs/corona_cough2.wav"
#define PRICE_MASK 500
#define PRICE_USED_PAPER 5000


new bool:g_HasCorona[33];
new bool:g_HasMask[33];
new g_CoronaTime[33];
new gmsgDamage;
new bool:g_HealedCorona;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    
    register_logevent("round_start", 2, "0=World triggered", "1=Round_Start");
    RegisterHam(Ham_TakeDamage, "player", "player_damage");
    RegisterHam(Ham_Killed, "player", "player_killed");
    register_clcmd("say /buymask", "cmd_buy_mask");
    register_clcmd("say /buyusedpaper", "cmd_used_paper_handkerchief");

    gmsgDamage = get_user_msgid("Damage")
}

public plugin_precache() 
{
    precache_sound(COUGH_SOUND);
}

public reset_corona()
{
    for (new player = 1; player <= MAX_CLIENTS; player++) {
        g_HasCorona[player] = false;
        g_HasMask[player] = false;
        g_CoronaTime[player] = 0;
    }
    g_HealedCorona = false;
}

public cmd_buy_mask(id)
{
    if (is_user_alive(id))
    {
        new player_money = cs_get_user_money(id);
        if (player_money >= PRICE_MASK)
        {
            cs_set_user_money(id, player_money - PRICE_MASK);
            g_HasMask[id] = true;
        }
        else
        {
            client_print(id, print_center, "Nu ai destui bani pentru masca");
        }
    }
    return PLUGIN_CONTINUE;
}

public give_corona_to_id(id)
{
    new skIndex[2];

    g_HasCorona[id] = true;
    skIndex[0] = id;
    set_task(15.0, "give_flu_player", 0, skIndex, 2);
    set_task(10.0, "flu_effects", 0, skIndex, 2);
}

public cmd_used_paper_handkerchief(id)
{
    if (is_user_alive(id))
    {
        new player_money = cs_get_user_money(id);
        if (player_money >= PRICE_USED_PAPER)
        {

            cs_set_user_money(id, player_money - PRICE_USED_PAPER);

            /*new kName[32];
            get_user_name(id, kName, 31);
            client_print(0, print_chat, "%s a luat corona !", kName);*/
            give_corona_to_id(id)
            
        }
        else
        {
            client_print(id, print_center, "Nu ai destui bani pentru servetel folosit");
        }
    }
    return PLUGIN_CONTINUE;
}

public give_random_corona()
{
    new RndNum = random_num(1, MAX_CLIENTS);

    while (!is_user_alive(RndNum) || cs_get_user_team(RndNum) == CS_TEAM_CT)
    {
        RndNum = random_num(1, MAX_CLIENTS);
    }
    /*new kName[32];
    get_user_name(RndNum, kName, 31);
    client_print(0, print_chat, "%s a luat corona!", kName);*/
    client_print(RndNum, print_center, "Te-ai trezit cu o durere de gat");
    give_corona_to_id(RndNum);
}

public round_start()
{
    new day = get_day();

    reset_corona();

    switch (day % 7)
    {
        case 3, 6:
        {
            //we skip
        }
        default:
        {
            if (random_num(1, 4) == 1)
            {
                give_random_corona();
            }
        }
    }
}
// after 15 seconds, starts infecting, 
#define TIME_TO_INFECT 20
// after 45 seconds, starts coughing
#define TIME_TO_COUGH 30
// after 1 minute, starts dealing less damage
#define TIME_TO_SHRINK_POWER 90
// after 1:15 minutes, starts moving slowly
#define TIME_TO_MOVE_SLOWLY 120
// after 2 minutes, starts dealing damage
#define TIME_TO_DEAL_DAMAGE 180
// after 3 minutes, you can die
#define TIME_TO_DIE 240

public flu_effects(skIndex[]) {
    new kIndex = skIndex[0];

    if (g_HasCorona[kIndex])
    {
        if (is_user_alive(kIndex)) {
            new korigin[3];
            new kHealth = get_user_health(kIndex);
            get_user_origin(kIndex, korigin);

            g_CoronaTime[kIndex] += 10;
            

            //create some sound
            if (g_CoronaTime[kIndex] >= TIME_TO_COUGH)
            {
                emit_sound(kIndex, CHAN_VOICE, COUGH_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
            }

            //create some damage
            if (g_CoronaTime[kIndex] >= TIME_TO_DEAL_DAMAGE && get_user_health(kIndex) > 10)
            {
                set_user_health(kIndex, kHealth - 10);
                message_begin(MSG_ONE, gmsgDamage, { 0,0,0 }, kIndex);
                write_byte(10); // dmg_save
                write_byte(10); // dmg_take
                write_long(1 << 18); // visibleDamageBits
                write_coord(korigin[0]); // damageOrigin.x
                write_coord(korigin[1]); // damageOrigin.y
                write_coord(korigin[2]); // damageOrigin.z
                message_end();
            }
            if (g_CoronaTime[kIndex] >= TIME_TO_DIE)
            {
                if (random_num(1, 4) == 1)
                {
                    set_user_health(kIndex, 0);
                    message_begin(MSG_ONE, gmsgDamage, { 0,0,0 }, kIndex);
                    write_byte(10); // dmg_save
                    write_byte(10); // dmg_take
                    write_long(1 << 18); // visibleDamageBits
                    write_coord(korigin[0]); // damageOrigin.x
                    write_coord(korigin[1]); // damageOrigin.y
                    write_coord(korigin[2]); // damageOrigin.z
                    message_end();
                }
            }
            set_task(10.0, "flu_effects", 0, skIndex, 2);
        }
        else {

            emit_sound(kIndex, CHAN_AUTO, "scientist/scream21.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH);
            g_HasCorona[kIndex] = false;
        }
    }
    return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
    if (is_user_alive(id))
    {
        if (g_CoronaTime[id] >= TIME_TO_MOVE_SLOWLY)
        {
            set_user_maxspeed(id, 180.0);
        }
    }
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
    if (is_user_alive(attacker) && get_user_weapon(attacker) == CSW_KNIFE && g_CoronaTime[attacker] > TIME_TO_SHRINK_POWER)
    {
        damage = damage / 2;
        SetHamParamFloat(4, damage);
        return HAM_OVERRIDE;
    }
    return HAM_IGNORED;
}

public player_killed(victim, attacker, Float:damage)
{
    if (cs_get_user_team(victim) == CS_TEAM_T && g_HealedCorona == false)
    {
        new teroCount = 0;
        for (new player = 1; player <= MAX_CLIENTS; player++) {
            if (is_user_alive(player) && cs_get_user_team(player) == CS_TEAM_T)
            {
                teroCount++;
            }
        }
        if (teroCount < 3)
        {
            client_print(0, print_chat, "Toti au fost vindecatit de catre gardieni");
            reset_corona();
            g_HealedCorona = true;
        }
    }
}

public give_flu_player(skIndex[]) {
    new kIndex = skIndex[0];

    if (is_user_alive(kIndex) && g_HasCorona[kIndex] == true) {
        if (g_CoronaTime[kIndex] >= TIME_TO_INFECT)
        {
            new korigin[3];
            new pOrigin[3];

            get_user_origin(kIndex, korigin);

            for (new player = 1; player <= MAX_CLIENTS; player++) {
                if (!is_user_alive(player) || player == kIndex)
                    continue;

                get_user_origin(player, pOrigin);

                if (get_distance(korigin, pOrigin) < 128 && !g_HasCorona[player] && !g_HasMask[player]) {
                    
                    give_corona_to_id(player);

                    new pName[32],kName[32];
                    get_user_name(kIndex, kName, 31);
                    get_user_name(player, pName, 31);
                    client_print(0, print_chat, "%s i-a dat corona lui %s !", kName, pName);

                    emit_sound(kIndex, CHAN_VOICE, COUGH_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
                }
            }
            pOrigin[0] = 0;
            korigin[0] = 0;
        }
        //Call Again in 5 seconds     
        set_task(2.0, "give_flu_player", 0, skIndex, 2);
    }
    return PLUGIN_CONTINUE
}