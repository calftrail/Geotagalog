//
//  NSDateFormatter+TLAdditions.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSDateFormatter+TLAdditions.h"


@implementation NSDateFormatter (TLAdditions)

+ (NSDateFormatter*)tl_tiffDateFormatter {
	NSDateFormatter* tiffDateFormatter = [NSDateFormatter new];
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[tiffDateFormatter setCalendar:gregorian];
	[gregorian release];
	[tiffDateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
	return [tiffDateFormatter autorelease];
}

+ (NSDate*)tl_dateFromISO8601:(NSString*)xslDateTime {
	NSCParameterAssert(xslDateTime != nil);
	/* Parse xsd:dateTime http://www.w3.org/TR/xmlschema-2/#dateTime in an accepting manner.
	 '-'? yyyy '-' mm '-' dd 'T' hh ':' mm ':' ss ('.' s+)? ((('+' | '-') hh ':' mm) | 'Z')?
	 Note that yyyy may be negative, or more than 4 digits.
	 When a timezone is added to a UTC dateTime, the result is the date and time "in that timezone". */
	int year = 0;
	unsigned int month = 0, day = 0, hours = 0, minutes = 0;
	double seconds = 0.0;
	char timeZoneBuffer[7] = "";
	int numFieldsParsed = sscanf([xslDateTime UTF8String], "%d-%u-%u T %u:%u:%lf %6s",
								 &year, &month, &day, &hours, &minutes, &seconds, timeZoneBuffer);
	if (numFieldsParsed < 6) {
		return nil;
	}
	
	int timeZoneSeconds = 0;
	if (timeZoneBuffer[0] && timeZoneBuffer[0] != 'Z') {
		int tzHours = 0;
		unsigned int tzMinutes = 0;
		int numTimezoneFieldsParsed = sscanf(timeZoneBuffer, "%d:%ud", &tzHours, &tzMinutes);
		if (numTimezoneFieldsParsed < 2) {
			return nil;
		}
		timeZoneSeconds = 60 * (tzMinutes + (60 * abs(tzHours)));
		if (tzHours < 0) {
			timeZoneSeconds = -timeZoneSeconds;
		}
	}
	
	NSDateComponents* parsedComponents = [[NSDateComponents new] autorelease];
	[parsedComponents setYear:year];
	[parsedComponents setMonth:month];
	[parsedComponents setDay:day];
	[parsedComponents setHour:hours];
	[parsedComponents setMinute:minutes];
	
	// NOTE: I don't know how exactly this calendar deals with negative years, or the transition from Julian
	NSCalendar* gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:timeZoneSeconds]];
	NSDate* dateWithoutSeconds = [gregorian dateFromComponents:parsedComponents];
	NSDate* date = [dateWithoutSeconds addTimeInterval:seconds];
	//printf("'%s' yielded %s\n", [str UTF8String], [[date description] UTF8String]);
	return date;
}

@end
