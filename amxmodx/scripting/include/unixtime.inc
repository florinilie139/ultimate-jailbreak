/*
	Unix Time Conversion
	by bugsy
	
	www.amxmodx.org
*/

#if defined _file_unixtime_included
	#endinput
#endif

#define _file_unixtime_included

#include <amxmodx>

stock const YearSeconds[2] = 
{ 
	31536000,	//Normal year
	31622400 	//Leap year
};

stock const MonthSeconds[12] = 
{ 
	2678400, //January	31 
	2419200, //February	28
	2678400, //March	31
	2592000, //April	30
	2678400, //May		31
	2592000, //June		30
	2678400, //July		31
	2678400, //August	31
	2592000, //September	30
	2678400, //October	31
	2592000, //November	30
	2678400  //December	31
};

stock const DaySeconds = 86400;
stock const HourSeconds = 3600;
stock const MinuteSeconds = 60;

stock UnixToTime( iTimeStamp , &iYear , &iMonth , &iDay , &iHour , &iMinute , &iSecond )
{
	new iTemp;
	
	iYear = 1970;
	iMonth = 1;
	iDay = 1;
	iHour = 0;

	while ( iTimeStamp > 0 )
	{
		iTemp = IsLeapYear(iYear);

		if ( ( iTimeStamp - YearSeconds[iTemp] ) >= 0 )
		{
			iTimeStamp -= YearSeconds[iTemp];
			iYear++;
		}
		else
		{
			break;
		}
	}

	while ( iTimeStamp > 0 )
	{
		iTemp = SecondsInMonth( iYear , iMonth );

		if ( ( iTimeStamp - iTemp ) >= 0 ) 
		{
			iTimeStamp -= iTemp;
			iMonth++;
		}
		else
		{
			break;
		}
	}

	while ( iTimeStamp > 0)
	{
		if ( ( iTimeStamp - DaySeconds ) >= 0 )
		{
			iTimeStamp -= DaySeconds;
			iDay++;
		}
		else
		{
			break;
		}
	}
	
	while ( iTimeStamp > 0 )
	{
		if ( ( iTimeStamp - HourSeconds ) >= 0 )
		{
			iTimeStamp -= HourSeconds;
			iHour++;
		}
		else
		{
			break;
		}
	}
	
	iMinute = ( iTimeStamp / 60 );
	iSecond = ( iTimeStamp % 60 );
}

stock TimeToUnix( const iYear , const iMonth , const iDay , const iHour , const iMinute , const iSecond )
{
	new i;
	new iTimeStamp;

	for ( i = 1970 ; i < iYear ; i++ )
		iTimeStamp += YearSeconds[ IsLeapYear(i) ];

	for ( i = 1 ; i < iMonth ; i++ )
		iTimeStamp += SecondsInMonth( iYear , i );

	iTimeStamp += ( ( iDay - 1 ) * DaySeconds );
	iTimeStamp += ( iHour * HourSeconds );
	iTimeStamp += ( iMinute * MinuteSeconds );
	iTimeStamp += iSecond;

	return iTimeStamp;
}

stock SecondsInMonth( const iYear , const iMonth ) 
{
	return ( ( IsLeapYear( iYear ) && ( iMonth == 2 ) ) ? ( MonthSeconds[iMonth - 1] + DaySeconds ) : MonthSeconds[iMonth - 1] );
}

stock IsLeapYear( const iYear ) 
{
	return ( ( (iYear % 4) == 0) && ( ( (iYear % 100) != 0) || ( (iYear % 400) == 0 ) ) );
}
