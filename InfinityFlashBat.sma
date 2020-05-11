#include < amxmodx >
#include < fakemeta >

const m_iFlashBattery = 244;

public plugin_init( ) {
	register_plugin( "Infinity Flash Bat", "1.0", "xPaw" );
	
	register_message( get_user_msgid( "FlashBat" ),   "MsgFlashBat" );
	register_message( get_user_msgid( "Flashlight" ), "MsgFlashLight" );
}

public MsgFlashLight( const MsgId, const MsgType, const id )
	set_msg_arg_int( 2, ARG_BYTE, 100 );

public MsgFlashBat( const MsgId, const MsgType, const id ) {
	if( get_msg_arg_int( 1 ) < 100 ) {
		set_msg_arg_int( 1, ARG_BYTE, 100 );
		
		set_pdata_int( id, m_iFlashBattery, 100, 5 );
	}
}