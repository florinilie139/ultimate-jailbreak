#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <ujbm>

#define MAX_NETS 10

new const PLUGIN_NAME[] = "Zones"
new const PLUGIN_AUTHOR[] = "(|EcLiPsE|)"
new const PLUGIN_VERSION[] = "1.0"
new const PLUGIN_PREFIX[] = "UTIL"

enum
{
	FIRST_POINT = 0,
	SECOND_POINT
}

enum _:type
{
    NOTDEFINE = 0,
    CTZONE,
    CANTEEN,
    CELLS,
    WORKOUT,
}

new g_szFile[128]
new g_szMapname[32]
new g_buildingstage[33]

new bool:g_buildingNet[33]

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
}

public plugin_precache()
{
    get_mapname(g_szMapname, 31)
	strtolower(g_szMapname )
    
    new szDatadir[64]
	get_localinfo("amxx_configsdir", szDatadir, charsmax(szDatadir))
    
    formatex(szDatadir, charsmax( szDatadir ), "%s/zones", szDatadir)
    
    if(!dir_exists( szDatadir))
        mkdir(szDatadir)
    
    formatex(g_szFile, charsmax(g_szFile), "%s/%s.ini", g_szMapname)
    
    if(!file_exists(g_szFile))
	{
		write_file(g_szFile, "// Soccerjam Ball/Nets Spawn Editor", -1)
		write_file(g_szFile, "// Credits to us ", -1)
        
		return
	}
    
    LoadAll(0)
}
public LoadAll(id)
{
	new szData[512]
	new szMap[32]
	new szOrigin[3][16]
	new szfPoint[2][3][16], szlPoint[2][3][16]
	new iFile = fopen(g_szFile, "rt")
    
	while(!feof(iFile))
	{
		fgets(iFile, szData, charsmax(szData))
        
		if(!szData[0] || szData[0] == ';' || szData[0] == ' ' || ( szData[0] == '/' && szData[1] == '/' ))
			continue

		parse(szData, szMap, 31, szOrigin[0], 15, szOrigin[1], 15, szOrigin[2], 15,\
			szfPoint[0][0], 15, szfPoint[0][1], 15, szfPoint[0][2], 15,\
			szlPoint[0][0], 15, szlPoint[0][1], 15, szlPoint[0][2], 15,\
			szfPoint[1][0], 15, szfPoint[1][1], 15, szfPoint[1][2], 15,\
			szlPoint[1][0], 15, szlPoint[1][1], 15, szlPoint[1][2], 15)
        
		if(equal(szMap, g_szMapname))
		{
			new Float:vOrigin[3]
			new Float:fPoint[2][3]
			new Float:lPoint[2][3]
            
			vOrigin[0] = str_to_float(szOrigin[0])
			vOrigin[1] = str_to_float(szOrigin[1])
			vOrigin[2] = str_to_float(szOrigin[2])
			
			for(new i = 0; i < 2; i++)
			{
				for(new j = 0; j < 3; j++)
				{
					fPoint[i][j] = str_to_float(szfPoint[i][j])
					lPoint[i][j] = str_to_float(szlPoint[i][j])
				}
			}
			
			CreateBall(0, vOrigin)
			
			CreateNet(fPoint[0], lPoint[0])
			CreateNet(fPoint[1], lPoint[1])
            
			g_vOrigin = vOrigin
			countnets = 2
            
			break
		}
	}
    
	fclose(iFile)
}

public SaveAll(id)
{
	new iBall, iNets[2], ent, i
	new Float:vOrigin[3]
	new Float:fMaxs[3]
	new Float:fOrigin[3]
	new Float:vfPoint[2][3]
	new Float:vlPoint[2][3]
	          
	while((ent = find_ent_by_class(ent, "JailNet")) > 0)
		iNets[i++] = ent
		
	if(iBall > 0 && iNets[0] > 0 && iNets[1] > 0 && countnets == 2)
	{
		entity_get_vector(iBall, EV_VEC_origin, vOrigin)
		
		for(new i = 0; i < 2; i++)
		{
			entity_get_vector(iNets[i], EV_VEC_origin, fOrigin)
			entity_get_vector(iNets[i], EV_VEC_maxs, fMaxs)
			
			for(new j = 0; j < 3; j++)
			{
				vfPoint[i][j] = fOrigin[j] + fMaxs[j]
				vlPoint[i][j] = fOrigin[j] - fMaxs[j]
			}
		}
	}
	else
		return PLUGIN_HANDLED
		
	new bool:bFound, iPos, szData[32], iFile = fopen(g_szFile, "r+")
            
	if(!iFile)
		return PLUGIN_HANDLED
            
	while(!feof(iFile)) {
		fgets(iFile, szData, 31)
		parse(szData, szData, 31)
                
		iPos++
                
		if(equal(szData, g_szMapname)) {
			bFound = true
                    
			new szString[512]
			formatex(szString, 511, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2],\
				vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2],\
				vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2])
                    
			write_file(g_szFile, szString, iPos - 1)
                    
			break
		}
	}
            
	if(!bFound)
		fprintf(iFile, "%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f^n", g_szMapname, vOrigin[0], vOrigin[1], vOrigin[2],\
			vfPoint[0][0], vfPoint[0][1], vfPoint[0][2], vlPoint[0][0], vlPoint[0][1], vlPoint[0][2],\
			vfPoint[1][0], vfPoint[1][1], vfPoint[1][2], vlPoint[1][0], vlPoint[1][1], vlPoint[1][2])
	fclose(iFile)
            
	ColorChat(id, "[AnNA]Salvare cu succes")
	
	return PLUGIN_HANDLED
}


public HandleMainMenu(id, key)
{
	if((key == 2 || key == 3 || key == 4) && !((get_user_flags(id) & ADMIN_RCON) || id==get_simon())) {
		ShowMainMenu(id)
		return PLUGIN_HANDLED
	}
	
	switch(key)
	{
		case 0:
		{
			ShowBallMenu(id)
			return PLUGIN_HANDLED

		}
		case 1:
		{
			ShowNetMenu(id)
			return PLUGIN_HANDLED
		}
		case 2:
		{
			if(is_valid_ent(gBall)) {
				entity_set_vector(gBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 })
				entity_set_origin(gBall, g_vOrigin )
                
				entity_set_int(gBall, EV_INT_movetype, MOVETYPE_BOUNCE)
				entity_set_size(gBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 })
				entity_set_int(gBall, EV_INT_iuser1, 0)
				
				ColorChat(id, "[AnNA]Inarcare cu succes")
			}
		}
		case 3:
		{
			new ent
			new ball, net
			while((ent = find_ent_by_class(ent, g_szBallName)) > 0)
			{
				remove_entity(ent)
				ball++
			}
				
			while((ent = find_ent_by_class(ent, "JailNet")) > 0)
			{
				remove_entity(ent)
				countnets--
				net++
			}
				
			ColorChat(id, "[AnNA]Stergere cu succes a ^x03 %d^x01 mingi si a ^x03 %d^x01 plase", ball, net)
		}
		case 4: SaveAll(id)
		case 9: return PLUGIN_HANDLED
	}
    
	ShowMainMenu(id)

	return PLUGIN_HANDLED
}


public HandleNetMenu(id, key)
{
	if(key != 9 && !((get_user_flags(id) & ADMIN_RCON) || id==get_simon())) {
		ShowNetMenu(id)
		return PLUGIN_HANDLED
	}
	
	switch(key)
	{
		case 0:
		{
			if(g_buildingNet[id])
			{
				ColorChat(id, "[AnNA]Deja in modul de creare a plasei")
				ShowNetMenu(id)
				
				return PLUGIN_HANDLED
			}
			if(countnets >= MAX_NETS)
			{
				ColorChat(id, "[AnNA]Scuze, sa atins limita de plase (%d).", countnets)
				ShowNetMenu(id)
				
				return PLUGIN_HANDLED
			}
			
			g_buildingNet[id] = true
			
			ColorChat(id, "[AnNA]Seteaza originea din dreapta sus a cutitei")
		}
		case 1:
		{
			if(!g_bHighlight[id][0])
			{
				set_task(1.0, "taskShowNet", 1000 + id, "", 0, "b", 0)
				g_bHighlight[id][0] = true
				
				ColorChat(id, "[AnNA]Net highlight has been^x04 Enabled^x01.")
			} else {
				remove_task(1000+id)
				g_bHighlight[id][0] = false
				
				ColorChat(id, "[AnNA]Net highlight has been^x03 Disabled^x01.")
			}
		}
		case 2:
		{
			new ent, body
			new bool:bFound
			static classname[32]
	    
			get_user_aiming(id, ent, body, 9999)
			entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname))
			
			if(is_valid_ent(ent) && equal(classname, "JailNet"))
			{
				remove_entity(ent)
				countnets--
					
				bFound = true
			} else {
				new Float:fPlrOrigin[3], Float:fNearestDist = 9999.0, iNearestEnt
				new Float:fOrigin[3], Float:fCurDist
	
				pev(id, pev_origin, fPlrOrigin)
	
				new ent = -1
				while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "JailNet")) != 0)
				{
					pev(ent, pev_origin, fOrigin)
		
					fCurDist = vector_distance(fPlrOrigin, fOrigin)
		
					if(fCurDist < fNearestDist)
					{
						iNearestEnt = ent
						fNearestDist = fCurDist
					}
				}
				if(iNearestEnt > 0 && is_valid_ent(iNearestEnt))
				{
					remove_entity(iNearestEnt)
					countnets--
				}
				
				bFound = true
			}
			if(bFound)
				ColorChat(id, "[AnNA]Plasa stearsa cu succes")
			else
				ColorChat(id, "[AnNA]Plasa nu a fost gasita")
		}
		case 9:
		{
			ShowMainMenu(id)
			return PLUGIN_HANDLED
		}
	}
	
	ShowNetMenu(id)
	return PLUGIN_HANDLED
}

CreateNet(Float:firstPoint[3], Float:lastPoint[3])
{
	new ent
	new Float:fCenter[3], Float:fSize[3]
	new Float:fMins[3], Float:fMaxs[3]
		
	for ( new i = 0; i < 3; i++ )
	{
		fCenter[i] = (firstPoint[i] + lastPoint[i]) / 2.0
				
		fSize[i] = get_float_difference(firstPoint[i], lastPoint[i])
				
		fMins[i] = fSize[i] / -2.0
		fMaxs[i] = fSize[i] / 2.0
	}
	
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if (ent) {
		engfunc(EngFunc_SetOrigin, ent, fCenter)
		
		set_pev(ent, pev_classname, "JailNet")
	
		dllfunc(DLLFunc_Spawn, ent)
	
		set_pev(ent, pev_movetype, MOVETYPE_FLY)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
	
		engfunc(EngFunc_SetSize, ent, fMins, fMaxs)
	}
}

stock Float:get_float_difference(Float:num1, Float:num2)
{
	if(num1 > num2)
		return (num1-num2)
	else if(num2 > num1)
		return (num2-num1)
	
	return 0.0
}


public taskShowNet(id)
{
	id -= 1000
	
	if(!is_user_connected(id))
	{
		remove_task(1000 + id)
		return
	}
	
	new ent
	new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3]
	new vMaxs[3], vMins[3]
	new iColor[3] = { 255, 0, 0 }
	
	while((ent = find_ent_by_class(ent, "JailNet")) > 0)
	{
		pev(ent, pev_mins, fMins)
		pev(ent, pev_maxs, fMaxs)
		pev(ent, pev_origin, fOrigin)
	
		fMins[0] += fOrigin[0]
		fMins[1] += fOrigin[1]
		fMins[2] += fOrigin[2]
		fMaxs[0] += fOrigin[0]
		fMaxs[1] += fOrigin[1]
		fMaxs[2] += fOrigin[2]
		
		FVecIVec(fMins, vMins)
		FVecIVec(fMaxs, vMaxs)

		fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
		fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(id, vMaxs[0], vMaxs[1], vMaxs[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
		fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(id, vMins[0], vMins[1], vMins[2], vMins[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(id, vMins[0], vMaxs[1], vMaxs[2], vMins[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(id, vMins[0], vMaxs[1], vMins[2], vMaxs[0], vMaxs[1], vMins[2], iColor)
		fm_draw_line(id, vMaxs[0], vMaxs[1], vMins[2], vMaxs[0], vMins[1], vMins[2], iColor)
		fm_draw_line(id, vMaxs[0], vMins[1], vMins[2], vMaxs[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(id, vMaxs[0], vMins[1], vMaxs[2], vMins[0], vMins[1], vMaxs[2], iColor)
		fm_draw_line(id, vMins[0], vMins[1], vMaxs[2], vMins[0], vMaxs[1], vMaxs[2], iColor)
	}
}

stock fm_draw_line(id, x1, y1, z1, x2, y2, z2, g_iColor[3])
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id ? id : 0)
	
	write_byte(TE_BEAMPOINTS)
	
	write_coord(x1)
	write_coord(y1)
	write_coord(z1)
	
	write_coord(x2)
	write_coord(y2)
	write_coord(z2)
	
	write_short(g_iTrailSprite)
	write_byte(1)
	write_byte(1)
	write_byte(10)
	write_byte(5)
	write_byte(0)
	
	write_byte(g_iColor[0])
	write_byte(g_iColor[1])
	write_byte(g_iColor[2])
	
	write_byte(200)
	write_byte(0)
	
	message_end()
}
