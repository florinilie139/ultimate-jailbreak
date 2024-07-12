#include <amxmisc>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "Lightsaber"
#define VERSION "1.0.1"
#define AUTHOR "R3X"

#define KeysSabre (1<<0)|(1<<1)|(1<<2)|(1<<9) // Keys: 1230

#define KNIFE_RANGE_BONUS 50

//Sounds
new const gszOldSounds[][]={
    "weapons/knife_hit1.wav",
    "weapons/knife_hit2.wav",
    "weapons/knife_hit3.wav",
    "weapons/knife_hit4.wav",
    "weapons/knife_stab.wav",
    "weapons/knife_hitwall1.wav",
    "weapons/knife_slash1.wav",
    "weapons/knife_slash2.wav",
    "weapons/knife_deploy1.wav"
};
new const gszNewSounds[sizeof gszOldSounds][]={
    "weapons/ls_hitbod1.wav",
    "weapons/ls_hitbod2.wav",
    "weapons/ls_hitbod3.wav",
    "weapons/ls_hitbod3.wav",
    "weapons/ls_hit2.wav",
    "weapons/ls_hit1.wav",
    "weapons/ls_miss.wav",
    "weapons/ls_miss.wav",
    "weapons/ls_pullout.wav"
};

new const gszRedModelP[]="models/p_light_saber_red.mdl";
//new const gszBlueModelP[]="models/p_b_lightsabre.mdl";

new const gszRedModelV[]="models/v_light_saber_red.mdl";
//new const gszBlueModelV[]="models/v_b_lightsabre.mdl";



//Colors
enum{
    RED,
    GREEN,
    BLUE
}
new giColor[33]={BLUE,...};

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_menucmd(register_menuid("Saber"), KeysSabre, "PressedSaber")
    register_event("CurWeapon","eventKnife","be","1=1","2=29");
    
    register_forward(FM_EmitSound, "fwEmitSound",0);
    register_forward(FM_TraceHull, "fwTraceHull",0);
    
    register_clcmd("say /saber", "cmdChooseSabre");
}
public plugin_precache(){
    for(new i=0;i<sizeof gszNewSounds;i++)
        precache_sound(gszNewSounds[i]);
    precache_model(gszRedModelV);
    //precache_model(gszBlueModelV);
    
    precache_model(gszRedModelP);
    //precache_model(gszBlueModelP);
    
}

//Forwards
public fwEmitSound(ent, channel, const sample[], Float:volume, Float:attenuation, fFlags, pitch){
    if(is_user_alive(ent) && (channel==1 || channel==3)){
        for(new i=0;i<sizeof gszOldSounds;i++){
            if(equal(sample,gszOldSounds[i])){
                engfunc(EngFunc_EmitSound, ent, channel, gszNewSounds[i], volume, attenuation, fFlags, pitch);
                return FMRES_SUPERCEDE;
            }
        }
    }
    return FMRES_IGNORED;
}
public fwTraceHull(const Float:v1[], const Float:v2[3], fNoMonsters, hullNumber, pentToSkip, ptr){
    if(is_user_alive(pentToSkip)){
        new Float:fEnd[3], Float:fNormal[3];
        get_tr2(ptr, TR_vecEndPos, fEnd);
        get_tr2(ptr, TR_vecPlaneNormal, fNormal);
        for(new i=0;i<3;i++)
            fEnd[i]+=(fNormal[i]*KNIFE_RANGE_BONUS);
        set_tr2(ptr, TR_vecEndPos, fEnd);
        return FMRES_OVERRIDE;
    }
    return FMRES_IGNORED;
}
public eventKnife(id){
    new szVModel[32], szPModel[32];
    switch(giColor[id]){
        case RED:{
            copy(szVModel, 31, gszRedModelV);
            copy(szPModel, 31, gszRedModelP);
        }
        //case BLUE:{
            //copy(szVModel, 31, gszBlueModelV);
            //copy(szPModel, 31, gszBlueModelP);
        //}
        default:{
            return;
        }
    }

    set_pev(id, pev_viewmodel2, szVModel);
    set_pev(id, pev_weaponmodel2, szPModel);
}
//cmds
public cmdChooseSabre(id){
    if(get_user_flags(id) & ADMIN_LEVEL_E)
    {
        if(cs_get_user_team(id) == CS_TEAM_T)
        {
            giColor[id]=RED;
            set_user_info(id,"model", "vader")
			client_print(id, print_chat, "saber tero")
        }
        if(cs_get_user_team(id) == CS_TEAM_CT)
        {
            giColor[id]=BLUE;
        }
    }
    return PLUGIN_CONTINUE;
}