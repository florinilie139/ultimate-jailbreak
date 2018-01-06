/* - - - - - - - - - - -

    AMX Mod X script.

    ﾂｦ Author  : Arkshine
    ﾂｦ Plugin  : SCU: Unlimited Money
    ﾂｦ Version : v1.1

    This plugin is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at
    your option) any later version.

    This plugin is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this plugin; if not, write to the Free Software Foundation,
    Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

- - - - - - - - - - -
*/

#include <amxmodx>
#include <orpheu>
#include <orpheu>
#include <orpheu_memory>
#include <orpheu_advanced>

const MinMoneyOriginalvalue = 800;
const MaxMoneyOriginalValue = 16000;

const MaxMemoryPatches = 20;

enum Patch
{
    PATCH_ADDRESS,
    PATCH_ORIGVALUE,
    PATCH_IS_FLOAT
};

new PatchedAddresses[ MaxMemoryPatches ][ Patch ];
new PatchesCount;

new LocalCount;
new LocalMaxPatches;

new MinNewMoneyValue;
new MaxNewMoneyValue;

new Debug;

public plugin_init()
{
    register_plugin( "SCU: Unlimited Money", "1.1", "Arkshine" );

    Debug = !!( plugin_flags() & AMX_FLAG_DEBUG );

    MaxNewMoneyValue = clamp( get_pcvar_num( register_cvar( "scu_max_money", string( cellmax - 64 ) ) ), 0, cellmax - 64 );
    MinNewMoneyValue = 0;

    if( MaxNewMoneyValue != MaxMoneyOriginalValue )
    {
        handleMemoryPatches();
    }
}

public plugin_end()
{
    removeAllPatches();
}

handleMemoryPatches()
{
    if( Debug )
    {
        log_amx( "" ); log_amx( "SCU: Unlimited Money v1.1 -- Applying memory patches..." );
    }

    new bool:isLinuxServer = bool:is_linux_server();
    new bool:newVersion    = 1 //isLinuxServer && (getEngineBuildVersion() / 100 >= 59 || getEngineBuildVersion() == 1306); // build 59xx or ReHLDS
    
    new address;
    new functionSize;
    new extraNumber;
    new displacement;

    address = initFunction( "AddAccount", "CBasePlayer", .numPatches = 2 );
    {
        functionSize = isLinuxServer ? ( newVersion ? 152 : 134 ) : 120;

        check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
        check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) ); // 0xb3d84ec5
    }

    address = initFunction( "JoiningThink", "CBasePlayer", .numPatches = 2 );
    {
        functionSize = isLinuxServer ? ( newVersion ? 2342 : 2438 ) : 1816;

        check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
        check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
    }

    address = initFunction( "Reset", "CBasePlayer", .numPatches = 2 );
    {
        functionSize = isLinuxServer ? ( newVersion ? 440 : 470 ) : 339;

        check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
        check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
    }

    address = initFunction( "PlayerThink", "CHalfLifeTraining", .numPatches = 2 );
    {
        functionSize = isLinuxServer ? ( newVersion ? 1347 : 1199 ) : 1005;
        extraNumber  = isLinuxServer ? 1 : 0;

        check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue - extraNumber, MaxNewMoneyValue - extraNumber ) );
        check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
    }

    address = initFunction( "CheckStartMoney", "", .numPatches = 4 );
    {
        if( !newVersion )
        {
            functionSize = isLinuxServer ? 100 : 65;
            extraNumber  = isLinuxServer ? 1   : 0;
            displacement = isLinuxServer ? 14  : 0;
            
            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue - extraNumber ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true, displacement, isLinuxServer ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true, displacement, isLinuxServer ) );
        }
        else
        {
            functionSize  = 88;
            extraNumber   = 1;
            
            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue - extraNumber ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true ) );
        }
    }

    address = initFunction( "ClientPutInServer", "", .numPatches = 4 );
    {
        if( !newVersion )
        {
            functionSize = isLinuxServer ? 1434 : 1342;
            extraNumber  = isLinuxServer ? 1    : 0;
            displacement = isLinuxServer ? 8    : 0;
            
            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true, displacement, isLinuxServer ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true, displacement, isLinuxServer ) );
        }
        else
        {
            functionSize = 1399;
            extraNumber  = 1;
            
            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true ) );
        }
    }

    address = initFunction( "HandleMenu_ChooseTeam", "", .numPatches = 4 );
    {
        if( !newVersion )
        {
            functionSize = isLinuxServer ? 3426 : 3009;
            extraNumber  = isLinuxServer ? 1    : 0;
            displacement = isLinuxServer ? 14   : 0;

            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true, displacement, bool:isLinuxServer ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true, displacement, bool:isLinuxServer ) );
        }
        else
        {
            functionSize = 3363;
            extraNumber  = 1;
            
            check( "Check max value", address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue ) );
            check( "Check min value", address = patchMemory( address, functionSize, MinMoneyOriginalvalue - extraNumber, MinNewMoneyValue ) );
            check( "Set min value"  , address = patchMemory( address, functionSize, MinMoneyOriginalvalue, MinNewMoneyValue, true ) );
            check( "Set max value"  , address = patchMemory( address, functionSize, MaxMoneyOriginalValue, MaxNewMoneyValue, true ) );
        }
    }
}

check( const comment[], const address )
{
    if( address )
    {
        if( Debug )
        {
            log_amx( "^t^t[OK] - %d/%d (%02d/%d) - patched at 0x%x. // %s", LocalCount, LocalMaxPatches, PatchesCount, MaxMemoryPatches, address, comment );

            if( PatchesCount == MaxMemoryPatches )
            {
                log_amx( "" ); log_amx( "All the %d patches have been applied successfully !", MaxMemoryPatches ); log_amx( "" );
            }
        }
    }
    else
    {
        Debug && log_amx( "^t^t[:(] - %d/%d (%02d/%d) - failed to find value inside the function // %s", LocalCount + 1 , LocalMaxPatches, PatchesCount + 1, MaxMemoryPatches, comment );

        plugin_end();
        set_fail_state( "Memory patch problem - Could not replace a value inside a function." );
    }
}

initFunction( const libFuncName[], const className[], const numPatches )
{
    if( Debug )
    {
        log_amx( "" ); log_amx( "^t%s%s%s()", className, className[0] ? "::" : "", libFuncName ); log_amx( "" );
    }

    LocalCount = 0;
    LocalMaxPatches = numPatches;

    return OrpheuGetFunctionAddress( OrpheuGetFunction( libFuncName, className ) );
}

patchMemory( const startAddress, const functionSize, const originalValue, const newValue, const bool:isFloat = false, const displacement = 0, const bool:useGOT = false )
{
    if( !startAddress )
    {
        return 0;
    }

    new address = startAddress + displacement;
    new endAddress = startAddress + functionSize;

    new type[5]; type = "long";

    if( useGOT )
    {
        endAddress = address = getBaseAddress() + OrpheuMemoryGetAtAddress( address, type ) + getGOTOffset();
        
        new value;
        
        if( isFloat )
        {
            value = floatround( Float:OrpheuMemoryGetAtAddress( address, type ) ); 
        }
        else
        {
            value = OrpheuMemoryGetAtAddress( address, type ); 
        }

        if( value != originalValue ) 
        {
            return 0;
        }
    } 
    
    isFloat ? OrpheuMemoryReplaceAtAddress( address, type, 1, float( originalValue ), float( newValue ), address ) :
              OrpheuMemoryReplaceAtAddress( address, type, 1, originalValue, newValue, address );
	  
    LocalCount++;

    if( ( useGOT && address != endAddress ) || address > endAddress )
    {
        isFloat ? OrpheuMemorySetAtAddress( address, type, 1, float( originalValue ) ) :
                  OrpheuMemorySetAtAddress( address, type, 1, originalValue );

        return 0;
    }

    PatchedAddresses[ PatchesCount ][ PATCH_ADDRESS   ] = address;
    PatchedAddresses[ PatchesCount ][ PATCH_ORIGVALUE ] = originalValue;
    PatchedAddresses[ PatchesCount ][ PATCH_IS_FLOAT  ] = isFloat;

    PatchesCount++;

    return useGOT ? startAddress + displacement + 4 : address;
}

removeAllPatches()
{
    new address;
    new value;

    for( new i = 0; i < PatchesCount; i++ )
    {
        address = PatchedAddresses[ i ][ PATCH_ADDRESS ];
        value   = PatchedAddresses[ i ][ PATCH_ORIGVALUE ];

        PatchedAddresses[ i ][ PATCH_IS_FLOAT ] ?

            OrpheuMemorySetAtAddress( address, "long" , 1, float( value ) ) :
            OrpheuMemorySetAtAddress( address, "int", 1, value );
    }
}

getGOTOffset()
{
    static offset; offset || ( offset = OrpheuGetFunctionOffset( OrpheuGetFunction( "_GLOBAL_OFFSET_TABLE_" ) ) );
    return offset;
}

getBaseAddress()
{
    static baseAddress; baseAddress || ( baseAddress = OrpheuGetLibraryAddress( "mod" ) );
    return baseAddress;
}

string( const value )
{
    const bufferSize = 64;

    new string[ bufferSize ];
    formatex( string, charsmax( string ), "%u", value );

    return string;
} 

getEngineBuildVersion()
{
    static buildVersion;

    if( !buildVersion )
    {
        new version[ 32 ];
        get_cvar_string( "sv_version", version, charsmax( version ) );

        new length = strlen( version );
        while( version[ --length ] != ',' ) {}

        buildVersion = str_to_num( version[ length + 1 ] );
    }

    return buildVersion;
}