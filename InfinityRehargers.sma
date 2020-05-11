#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >

const m_iJuice = 75;

public plugin_init( ) {
	register_plugin( "Infinity Chargers", "1.0", "xPaw" );
	
	RegisterHam( Ham_Use, "func_healthcharger", "FwdHamChargerUse" );
	RegisterHam( Ham_Use, "func_recharge",      "FwdHamChargerUse" );
}

public FwdHamChargerUse( const iEntity, const iCaller ) {
	if( get_user_health( iCaller ) == 100 )
		return HAM_SUPERCEDE;
	
	if( get_pdata_int( iEntity, m_iJuice, 5 ) <= 1 )
		set_pdata_int( iEntity, m_iJuice, 500 ); // Default is 50 tho =D
	
	return HAM_IGNORED;
}