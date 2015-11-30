/* UFPS Anti Advertising 

	НАЗНАЧЕНИЕ:
		- Плагин предназначен для блокировки любых повторяющихся рекламных сообщений от игроков в чате сервера, а также для очистки конфигов игроков от рекламного флуда.

	ОПИСАНИЕ РАБОТЫ:
		- Сообщения администраторов не проверяются.
		- Сообщения от игроков, содержащие: точку или двоеточие и длиной боее 8 (в исходнике MIN_SAYALERT) знаков, а также все сообщения более 32 (в исходнике MAX_SAYALERT) знаков - объявляются подозрительными и повторное появление таких одинаковых сообщений блокируется.
		- Когда счетчик подозрительных сообщений превышает определенное значение (по-умолчанию 3 в исходнике MIN_VERIFY) игроку после смерти выводится меню, приведенное на скриншоте.
		- При выборе 1 пукнта игроку принудительно отправляются все строки antiadvert.ini начинающиеся на unbindall либо bind.
		- При выборе 2 пункта игроку отправляется команда disconnect.

Обратите внимание: 
	- Первое сообщение, определенное как подозрительное и отличное от других подозрительных пропускается в чат!
	- Плагин практически не создает нагрузку на сервер.
	- Рекомендуется этот плагин располагать в pluins.ini выше плагинов, работающих с чатом, таких как например translate.amxx.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define MIN_SAYALERT		8		// Минимальная длина сообщения для проверки, содержащая точку или двоеточие
#define MAX_SAYALERT		32		// Минимальная длина сообщения для проверки
#define MIN_VERIFY			3		// Количество подозрений на рекламу, перед выводом меню
#define MAX_RECORDS			32		// Количество записей в базе для мониторинга пользователя
#define LEN_RECORDS			127
#define DEF_CONFIG			16
#define OFFSET_CSMENUCODE	205

new pcv_menu

new rec_verify[33]
new rec_counter[33]
new rec_database[33][MAX_RECORDS][LEN_RECORDS+1]

new def_counter
new def_database[DEF_CONFIG][LEN_RECORDS+1]

public plugin_init( )
{
	register_plugin( "UFPS Anti Advertising","2.8","UFPS.Team" )
	register_dictionary( "antiadvert.txt" )

	register_event( "DeathMsg",		"event_user_death", "a" )

	register_concmd( "adv_user", "cmd_advremove", ADMIN_KICK, "<name or #userid>")

	register_clcmd( "say",      "cmd_handle_say" )
	register_clcmd( "say_team", "cmd_handle_say" )
}

public plugin_cfg()
{
	new configsdir[64], filename[64], string[LEN_RECORDS+1], pos, len

	get_configsdir( configsdir, charsmax( configsdir ) )
	formatex( filename, charsmax( filename ), "%s/antiadvert.ini", configsdir )

	if( file_exists( filename ) )
	{
		while( ( def_counter < DEF_CONFIG ) && read_file( filename, pos++, string, LEN_RECORDS, len ) ) {
			replace_all( string, LEN_RECORDS, ";", "^n" )
			copy( def_database[def_counter++], LEN_RECORDS, string )
		}
	} else {
		log_amx( "%s not found", filename )
	}

	pcv_menu = menu_create( "ADV_CLEAR_MENU", "_handle_menu", 1 )

	menu_additem( pcv_menu, "", "1" )
	menu_additem( pcv_menu, "", "2" )
	menu_setprop( pcv_menu, MPROP_NUMBER_COLOR, "\r" )
	menu_setprop( pcv_menu, MPROP_EXIT, MEXIT_NEVER )
}

public cmd_advremove(id, level, cid)
{
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED

	new arg[32]
	read_argv( 1, arg, charsmax( arg ) )
	new player = cmd_target( id, arg, 1 )

	if( !player ) {
		return PLUGIN_HANDLED
	}
	
	cmd_bindall( player )

	if( id )
	{
		static name[32], authid[44]
		get_user_name( player, name, charsmax( name ) )
		get_user_authid( player, authid, charsmax( authid ) )

		console_print( id, "%L", id, "UAA_PLAYER", name, get_user_userid( player ), authid )
	}

	return PLUGIN_HANDLED
}

public cmd_handle_say( id )
{
	if( is_user_admin( id ) ) {
		return PLUGIN_CONTINUE
	}

	static arg[LEN_RECORDS+1]
	read_args( arg, LEN_RECORDS )

	if( ( ( contain( arg, "." ) != -1 || contain( arg, ":" ) != -1 ) && strlen( arg ) > MIN_SAYALERT ) || strlen( arg ) > MAX_SAYALERT ) {
		if( !add_record( id, arg ) ) {
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

stock bool:add_record( id, const arg[] )
{
	if( !find_record( id, arg ) )
	{
		if( rec_counter[id] >= MAX_RECORDS ) {
			rec_counter[id] = 0
		}

		copy( rec_database[id][rec_counter[id]], LEN_RECORDS, arg )
		rec_counter[id]++
	}

	else
	{
		rec_verify[id]++

		return false
	}

	return true
}

stock bool:find_record( id, const arg[] )
{
	static i

	for( i = 0; i < rec_counter[id]; i++ ) {
		if( equal( rec_database[id][i], arg ) ) return true
	}

	return false
}

public event_user_death()
{
	static id
	id = read_data( 2 )

	if( rec_verify[id] > MIN_VERIFY )
	{
		if( task_exists( id ) ) {
			remove_task( id )
		}

		set_task( 1.0, "_print_menu", id )
	}
}

public _print_menu( id )
{
	if( !is_user_connected( id ) )
		return PLUGIN_HANDLED

	new m_title[256], m_clear[128], m_quit[128]

	formatex( m_title, charsmax( m_title ), "%L", id, "UAA_TITLE" )
	formatex( m_clear, charsmax( m_clear ), "%L", id, "UAA_CLEAR" )
	formatex( m_quit, charsmax( m_quit ), "%L", id, "UAA_QUIT" )

	menu_item_setname( pcv_menu, 0, m_clear )
	menu_item_setname( pcv_menu, 1, m_quit )

	menu_setprop( pcv_menu, MPROP_TITLE, m_title )
	
	set_pdata_int( id, OFFSET_CSMENUCODE, 0 )

	menu_display( id, pcv_menu )

	return PLUGIN_CONTINUE
}

public _handle_menu( id, menu, item )
{
	if( item == MENU_EXIT ) {
		return PLUGIN_HANDLED
	}

	new _access, info[3], callback
	menu_item_getinfo( menu, item, _access, info, charsmax( info ), _, _, callback )

	new key = str_to_num( info )

	switch( key )
	{
		case 1: {
			cmd_bindall( id )
		}

		case 2: 
		{
			new reason[128]
			formatex( reason, charsmax( reason ), "%L", id, "UAA_REASON" )

			client_cmd( id, ";^"DisConnect^"" )
			server_cmd( "kick #%d ^"%s^"", get_user_userid( id ), reason )
		}
	}

	return PLUGIN_HANDLED
}

stock cmd_bindall( id )
{
	for( new i; i < def_counter; ++i ) {
		client_cmd( id, def_database[i] )
	}

	rec_verify[id] = 0

	static name[32], authid[44]
	get_user_name( id, name, charsmax( name ) )
	get_user_authid( id, authid, charsmax( authid ) )

	log_amx( "Clear config: ^"%s^" <%d> [%s]", name, get_user_userid( id ), authid )
}

public client_disconnect( id )
{
	rec_verify[id] = 0

	if( task_exists( id ) ) remove_task( id )
}

public plugin_end() {
	menu_destroy( pcv_menu )
}
