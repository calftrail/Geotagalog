//
//  TLNMEASentenceDecoding.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLNMEASentenceDecoding.h"

NSString* const TLNMEASentenceTypeKey = @"Sentence Type";

@implementation TLNMEASentence (TLNMEASentenceDecoding)

- (NSDictionary*)decodeSentence {
	NSString* decodeSelectorName = [NSString stringWithFormat:
									@"decodeMessageOfType%@",
									[[self messageType] uppercaseString]];
	SEL decodeSelector = NSSelectorFromString(decodeSelectorName);
	NSDictionary* decodedSentence = nil;
	if ([self respondsToSelector:decodeSelector]) {
		decodedSentence = [self performSelector:decodeSelector];
		//NSLog(@"%@", decodedSentence);
	}
	//else NSLog(@"No decoder for %@", [[self messageType] uppercaseString]);
	return decodedSentence;
}


#pragma mark Conversion helpers

- (NSNumber*)readFieldAsDouble:(NSUInteger)fieldIdx {
	NSNumber* number = nil;
	if (fieldIdx < [[self dataFields] count]) {
		NSString* value = [[self dataFields] objectAtIndex:fieldIdx];
		if ([value length]) {
			const char* buffer = [value UTF8String];
			char* resultPtr = NULL;
			double x = strtod(buffer, &resultPtr);
			if (resultPtr != buffer) {
				number = [NSNumber numberWithDouble:x];
			}
		}
	}
	return number;
}

- (NSNumber*)readFieldAsUnsignedLong:(NSUInteger)fieldIdx {
	NSNumber* number = nil;
	if (fieldIdx < [[self dataFields] count]) {
		NSString* value = [[self dataFields] objectAtIndex:fieldIdx];
		if ([value length]) {
			const char* buffer = [value UTF8String];
			char* resultPtr = NULL;
			unsigned long x = strtoul(buffer, &resultPtr, 10);
			if (resultPtr != buffer) {
				number = [NSNumber numberWithUnsignedLong:x];
			}
		}
	}
	return number;
}

- (NSString*)readFieldAsString:(NSUInteger)fieldIdx {
	NSString* string = nil;
	if (fieldIdx < [[self dataFields] count]) {
		string = [[self dataFields] objectAtIndex:fieldIdx];
	}
	return string;
}

- (NSString*)readFieldAsUppercaseString:(NSUInteger)fieldIdx {
	NSString* string = nil;
	if (fieldIdx < [[self dataFields] count]) {
		string = [[[self dataFields] objectAtIndex:fieldIdx] uppercaseString];
	}
	return string;
}

- (NSNumber*)readFieldAsTimeInterval:(NSUInteger)fieldIdx {
	NSString* utcTime = [self readFieldAsString:fieldIdx];
	NSNumber* timeInterval = nil;
	if ([utcTime length]) {
		unsigned char utcHours = 0;
		unsigned char utcMinutes = 0;
		double utcSeconds = 0.0f;
		int argumentsFilled = sscanf([utcTime UTF8String], "%2hhu%2hhu%lf",
									 &utcHours, &utcMinutes, &utcSeconds);
		if (argumentsFilled == 3) {
			NSTimeInterval seconds = (utcHours * 60.0 * 60.0) + (utcMinutes * 60.0) + utcSeconds;
			timeInterval = [NSNumber numberWithDouble:seconds];
		}
	}
	return timeInterval;
}

- (NSNumber*)readFieldAsCoordinate:(NSUInteger)fieldIdx {
	NSString* coordValue = [self readFieldAsString:fieldIdx];
	NSNumber* coordinate = nil;
	if ([coordValue length]) {
		NSString* coordType = [self readFieldAsUppercaseString:(fieldIdx+1)];
		bool isLat = false;
		bool isLon = false;
		if ([coordType isEqualToString:@"N"] ||
			[coordType isEqualToString:@"S"])
		{
			isLat = true;
		}
		else if ([coordType isEqualToString:@"W"] ||
				 [coordType isEqualToString:@"E"])
		{
			isLon = true;
		}
		if (!isLat && !isLon) {
			return nil;
		}
		
		unsigned short degrees = 0;
		double minutes = 0.0;
		int argumentsFilled = sscanf([coordValue UTF8String],
									 (isLat ? "%2hu%lf" : "%3hu%lf"),
									 &degrees, &minutes);
		if (argumentsFilled == 2) {
			double absCoord = degrees + minutes / 60.0;
			if ([coordType isEqualToString:@"N"] ||
				[coordType isEqualToString:@"E"])
			{
				coordinate = [NSNumber numberWithDouble:absCoord];
			}
			else if ([coordType isEqualToString:@"S"] ||
					 [coordType isEqualToString:@"W"])
			{
				coordinate = [NSNumber numberWithDouble:(-absCoord)];
			}
		}
	}
	return coordinate;
}


#pragma mark Known sentences

/*
 RMC - Recommended Minimum Navigation Information
															12
        1         2 3       4 5        6  7   8   9    10 11|  13
        |         | |       | |        |  |   |   |    |  | |   |
 $--RMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,xxxx,x.x,a,m,*hh<CR><LF>
 
 Field Number: 
 1) UTC Time
 2) Status, V=Navigation receiver warning A=Valid
 3) Latitude
 4) N or S
 5) Longitude
 6) E or W
 7) Speed over ground, knots
 8) Track made good, degrees true
 9) Date, ddmmyy
 10) Magnetic Variation, degrees
 11) E or W
 12) FAA mode indicator (NMEA 2.3 and later)
 13) Checksum
 
 A status of V means the GPS has a valid fix that is below an internal
 quality threshold, e.g. because the dilution of precision is too high 
 or an elevation mask test failed.
 */

NSString* const TLNMEARecommendedMinimumSentence = @"Recommended minimum navigation information";
NSString* const TLNMEATimestampKey = @"Timestamp";
NSString* const TLNMEABaseDateKey = @"Midnight (UTC) on date";
NSString* const TLNMEASecondsSinceMidnightUTCKey = @"Seconds since midnight (UTC)";
NSString* const TLNMEALatitudeKey = @"Latitude (degrees)";
NSString* const TLNMEALongitudeKey = @"Longitude (degrees)";
NSString* const TLNMEAGroundSpeedKnotsKey = @"Speed over ground (knots)";
NSString* const TLNMEATrackMadeGoodKey = @"Track made good (true degrees)";
NSString* const TLNMEAMagneticVariationKey = @"Magnetic declination (degrees)";

NSString* const TLNMEAReceiverStatusKey = @"Receiver status";
NSString* const TLNMEAReceiverStatusValid = @"A";
NSString* const TLNMEAReceiverStatusInvalid = @"V";

/*
 FAA Mode Indicator
 A = Autonomous mode
 D = Differential Mode
 E = Estimated (dead-reckoning) mode
 M = Manual Input Mode
 S = Simulated Mode
 N = Data Not Valid
 */
NSString* const TLNMEAModeIndicatorKey = @"FAA mode indicator";
NSString* const TLNMEAModeIndicatorAutonomous = @"A";
NSString* const TLNMEAModeIndicatorDifferential = @"D";
NSString* const TLNMEAModeIndicatorEstimated = @"E";
NSString* const TLNMEAModeIndicatorManualInput = @"M";
NSString* const TLNMEAModeIndicatorSimulated = @"S";
NSString* const TLNMEAModeIndicatorInvalid = @"N";

- (NSDictionary*)decodeMessageOfTypeRMC {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEARecommendedMinimumSentence
					   forKey:TLNMEASentenceTypeKey];
	
	/* This timestamp can be used to form a complete date, 
	 but we also store it separately to facilitate comparison
	 with other sentences that include no date. */
	NSNumber* timestamp = [self readFieldAsTimeInterval:0];
	if (timestamp) {
		[decodedMessage setObject:timestamp
						   forKey:TLNMEASecondsSinceMidnightUTCKey];
	}
	
	bool validDate = false;
	unsigned char utcTwoDigitYear = 0;
	unsigned char utcMonth = 0;
	unsigned char utcDay = 0;
	NSString* utcDate = [self readFieldAsString:8];
	if ([utcDate length]) {
		int argumentsFilled = sscanf([utcDate UTF8String], "%2hhu%2hhu%2hhu",
									 &utcDay, &utcMonth, &utcTwoDigitYear);
		if (argumentsFilled == 3) {
			validDate = true;
		}
	}
	
	if (timestamp && validDate) {
		NSDate* now = [NSDate date];
		NSCalendar* gregorian = [[[NSCalendar alloc]
								  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		[gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents* components = [gregorian components:kCFCalendarUnitYear fromDate:now];
		NSInteger yearNow = [components year];
		NSInteger hundredsNow = 100 * (yearNow / 100);
		
		// window timestamps to be a year or less into the future
		NSInteger utcYear = hundredsNow + utcTwoDigitYear;
		if (utcYear > yearNow + 1) {
			utcYear -= 100;
		}
		
		NSDateComponents* dayComponents = [[NSDateComponents new] autorelease];
		[dayComponents setYear:utcYear];
		[dayComponents setMonth:utcMonth];
		[dayComponents setDay:utcDay];
		NSTimeInterval secondsSinceMidnight = [timestamp doubleValue];
		NSDate* baseDate = [gregorian dateFromComponents:dayComponents];
		if (baseDate) {
			[decodedMessage setObject:baseDate
							   forKey:TLNMEABaseDateKey];
			NSDate* fullTimestamp = [baseDate addTimeInterval:secondsSinceMidnight];
			[decodedMessage setObject:fullTimestamp
							   forKey:TLNMEATimestampKey];
		}
	}
	
	NSString* receiverStatus = [self readFieldAsUppercaseString:1];
	if ([receiverStatus length]) {
		[decodedMessage setObject:receiverStatus
						   forKey:TLNMEAReceiverStatusKey];
	}
	
	NSNumber* latitude = [self readFieldAsCoordinate:2];
	if (latitude) {
		[decodedMessage setObject:latitude
						   forKey:TLNMEALatitudeKey];
	}
	
	NSNumber* longitude = [self readFieldAsCoordinate:4];
	if (longitude) {
		[decodedMessage setObject:longitude
						   forKey:TLNMEALongitudeKey];
	}
	
	NSNumber* groundSpeed = [self readFieldAsDouble:6];
	if (groundSpeed) {
		[decodedMessage setObject:groundSpeed
						   forKey:TLNMEAGroundSpeedKnotsKey];
	}
	
	NSNumber* trackMadeGood = [self readFieldAsDouble:7];
	if (trackMadeGood) {
		[decodedMessage setObject:trackMadeGood
						   forKey:TLNMEATrackMadeGoodKey];
	}
		
	NSNumber* magneticVariation = [self readFieldAsDouble:9];
	if (magneticVariation) {
		NSString* variationDirection = [self readFieldAsUppercaseString:10];
		if ([variationDirection isEqualToString:@"E"]) {
			[decodedMessage setObject:magneticVariation
							   forKey:TLNMEAMagneticVariationKey];
		}
		else if ([variationDirection isEqualToString:@"W"]) {
			double negVariation = -[magneticVariation doubleValue];
			[decodedMessage setObject:[NSNumber numberWithDouble:negVariation]
							   forKey:TLNMEAMagneticVariationKey];
		}			
	}
	
	NSString* modeIndicatorValue = [self readFieldAsUppercaseString:11];
	if ([modeIndicatorValue length]) {
		[decodedMessage setObject:modeIndicatorValue
						   forKey:TLNMEAModeIndicatorKey];
	}
	
	return decodedMessage;
}

/*
 GSA - GPS DOP and active satellites
 
        1 2 3                        14 15  16  17  18
        | | |                         |  |   |   |   |
 $--GSA,a,a,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x.x,x.x,x.x*hh<CR><LF>
 
 Field Number: 
 1) Selection mode
 M=Manual, forced to operate in 2D or 3D
 A=Automatic, 3D/2D
 2) Mode (1 = no fix, 2 = 2D fix, 3 = 3D fix)
 3) ID of 1st satellite used for fix
 4) ID of 2nd satellite used for fix
 ...
 14) ID of 12th satellite used for fix
 15) PDOP
 16) HDOP
 17) VDOP
 18) checksum
 */

NSString* const TLNMEASatellitesActiveSentence = @"Degree Of Precision and Active Satellites";
NSString* const TLNMEAPositionDOPKey = @"Position Dilution of Precision";
NSString* const TLNMEAHorizontalDOPKey = @"Horizontal Dilution of Precision";
NSString* const TLNMEAVerticalDOPKey = @"Vertical Dilution of Precision";
NSString* const TLNMEASatellitesUsedArrayKey = @"Satellites used for fix";

NSString* const TLNMEASelectionModeKey = @"Selected mode";
NSString* const TLNMEASelectionModeManual = @"M";
NSString* const TLNMEASelectionModeAutomatic = @"A";

NSString* const TLNMEAFixModeKey = @"Fix mode";
NSString* const TLNMEAFixModeFixNotAvailable = @"1";
NSString* const TLNMEAFixMode2D = @"2";
NSString* const TLNMEAFixMode3D = @"3";

- (NSDictionary*)decodeMessageOfTypeGSA {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEASatellitesActiveSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSString* selectionModeValue = [self readFieldAsUppercaseString:0];
	if ([selectionModeValue length]) {
		[decodedMessage setObject:selectionModeValue
						   forKey:TLNMEASelectionModeKey];
	}
	
	NSString* fixModeValue = [self readFieldAsString:1];
	if ([fixModeValue length]) {
		[decodedMessage setObject:fixModeValue
						   forKey:TLNMEAFixModeKey];
	}
	
	NSNumber* pdop = [self readFieldAsDouble:14];
	if (pdop) {
		[decodedMessage setObject:pdop
						   forKey:TLNMEAPositionDOPKey];
	}
	
	NSNumber* hdop = [self readFieldAsDouble:15];
	if (hdop) {
		[decodedMessage setObject:hdop
						   forKey:TLNMEAHorizontalDOPKey];
	}
	
	NSNumber* vdop = [self readFieldAsDouble:16];
	if (vdop) {
		[decodedMessage setObject:vdop
						   forKey:TLNMEAVerticalDOPKey];
	}
	
	NSMutableArray* satellitesUsed = [NSMutableArray array];
	for (NSUInteger satelliteIdx = 2; satelliteIdx < 14; ++satelliteIdx) {
		NSNumber* satellite = [self readFieldAsUnsignedLong:satelliteIdx];
		if (satellite) {
			[satellitesUsed addObject:satellite];
		}
	}
	if ([satellitesUsed count]) {
		[decodedMessage setObject:[NSArray arrayWithArray:satellitesUsed]
						   forKey:TLNMEASatellitesUsedArrayKey];
	}
	
	return decodedMessage;
}


/*
 GSV - Satellites in view
 
 These sentences describe the sky position of a UPS satellite in view.
 Typically they're shipped in a group of 2 or 3.
 
        1 2 3 4 5 6 7     n
        | | | | | | |     |
 $--GSV,x,x,x,x,x,x,x,...*hh<CR><LF>
 
 Field Number: 
 1) total number of GSV messages to be transmitted in this group
 2) 1-origin number of this GSV message  within current group
 3) total number of satellites in view (leading zeros sent)
 4) satellite PRN number (leading zeros sent)
 5) elevation in degrees (00-90) (leading zeros sent)
 6) azimuth in degrees to true north (000-359) (leading zeros sent)
 7) SNR in dB (00-99) (leading zeros sent)
 more satellite info quadruples like 4-7
 n) checksum
 
 Some GPS receivers may emit more than 12 quadruples (more than three
 GPGSV sentences), even though NMEA-0813 doesn't allow this.  (The
 extras might be WAAS satellites, for example.) Receivers may also
 report quads for satellites they aren't tracking, in which case the
 SNR field will be null; we don't know whether this is formally allowed
 or not.
 */

NSString* const TLNMEASatellitesInViewSentence = @"Satellites in View";

NSString* const TLNMEAGroupedMessagesTotalKey = @"Total messages in this group";
NSString* const TLNMEAGroupedMessageNumberKey = @"Number of this message";
NSString* const TLNMEATotalSatellitesInViewKey = @"Total number of satellites in view";

NSString* const TLNMEASatelliteInformationArrayKey = @"Satellite information";
NSString* const TLNMEASatelliteIDKey = @"Satellite number";
NSString* const TLNMEASatelliteElevationKey = @"Satellite elevation (degrees)";
NSString* const TLNMEASatelliteAzimuthKey = @"Satellite azimuth (degrees to true north)";
NSString* const TLNMEASatelliteSignalToNoiseKey = @"Satellite signal-to-noise ratio (dB-Hz)";

- (NSDictionary*)decodeMessageOfTypeGSV {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEASatellitesInViewSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSNumber* totalMessages = [self readFieldAsUnsignedLong:0];
	if (totalMessages) {
		[decodedMessage setObject:totalMessages
						   forKey:TLNMEAGroupedMessagesTotalKey];
	}
	
	NSNumber* messageNumber = [self readFieldAsUnsignedLong:1];
	if (messageNumber) {
		[decodedMessage setObject:messageNumber
						   forKey:TLNMEAGroupedMessageNumberKey];
	}
	
	NSNumber* totalSatellites = [self readFieldAsUnsignedLong:2];
	if (totalSatellites) {
		[decodedMessage setObject:totalSatellites
						   forKey:TLNMEATotalSatellitesInViewKey];
	}
	
	NSMutableArray* satellitesArray = [NSMutableArray array];
	for (NSUInteger satelliteIdx = 3; satelliteIdx + 3 < [[self dataFields] count]; satelliteIdx += 4) {
		NSMutableDictionary* satelliteInfo = [NSMutableDictionary dictionary];
		
		NSNumber* satelliteNumber = [self readFieldAsUnsignedLong:satelliteIdx];
		if (satelliteNumber) {
			[satelliteInfo setObject:satelliteNumber
							  forKey:TLNMEASatelliteIDKey];
		}
		
		// this is defined to be an integer, but we read as float just in case
		NSNumber* satelliteElevation = [self readFieldAsDouble:(satelliteIdx+1)];
		if (satelliteElevation) {
			[satelliteInfo setObject:satelliteElevation
							  forKey:TLNMEASatelliteElevationKey];
		}
		
		// this is defined to be an integer, but we read as float just in case
		NSNumber* satelliteAzimuth = [self readFieldAsDouble:(satelliteIdx+2)];
		if (satelliteAzimuth) {
			[satelliteInfo setObject:satelliteAzimuth
							  forKey:TLNMEASatelliteAzimuthKey];
		}
		
		// this is defined to be an integer, but we read as float just in case
		NSNumber* signalToNoise = [self readFieldAsDouble:(satelliteIdx+3)];
		if (signalToNoise) {
			[satelliteInfo setObject:signalToNoise
							  forKey:TLNMEASatelliteSignalToNoiseKey];
		}
		
		if ([satelliteInfo count]) {
			[satellitesArray addObject:satelliteInfo];
		}
	}
	
	if ([satellitesArray count]) {
		[decodedMessage setObject:satellitesArray
						   forKey:TLNMEASatelliteInformationArrayKey];
	}
	
	return decodedMessage;
}

/*
 GLL - Geographic Position - Latitude/Longitude
 
        1       2 3        4 5         6 7   8
        |       | |        | |         | |   |
 $--GLL,llll.ll,a,yyyyy.yy,a,hhmmss.ss,a,m,*hh<CR><LF>
 
 Field Number: 
 1) Latitude
 2) N or S (North or South)
 3) Longitude
 4) E or W (East or West)
 5) Universal Time Coordinated (UTC)
 6) Status A - Data Valid, V - Data Invalid
 7) FAA mode indicator (NMEA 2.3 and later)
 8) Checksum
 
 Introduced in NMEA 3.0.
 */

NSString* const TLNMEAGeographicPositionSentence = @"Geographic position";

- (NSDictionary*)decodeMessageOfTypeGLL {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEAGeographicPositionSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSNumber* latitude = [self readFieldAsCoordinate:0];
	if (latitude) {
		[decodedMessage setObject:latitude
						   forKey:TLNMEALatitudeKey];
	}
	
	NSNumber* longitude = [self readFieldAsCoordinate:2];
	if (longitude) {
		[decodedMessage setObject:longitude
						   forKey:TLNMEALongitudeKey];
	}
	
	NSNumber* timestamp = [self readFieldAsTimeInterval:4];
	if (timestamp) {
		[decodedMessage setObject:timestamp
						   forKey:TLNMEASecondsSinceMidnightUTCKey];
	}
	
	NSString* receiverStatus = [self readFieldAsUppercaseString:5];
	if ([receiverStatus length]) {
		[decodedMessage setObject:receiverStatus
						   forKey:TLNMEAReceiverStatusKey];
	}	
	
	NSString* modeIndicatorValue = [self readFieldAsUppercaseString:6];
	if ([modeIndicatorValue length]) {
		[decodedMessage setObject:modeIndicatorValue
						   forKey:TLNMEAModeIndicatorKey];
	}
	
	return decodedMessage;
}

/*
 VTG - Track made good and Ground speed
 
         1  2  3  4  5	6  7  8 9   10
         |  |  |  |  |	|  |  | |   |
 $--VTG,x.x,T,x.x,M,x.x,N,x.x,K,m,*hh<CR><LF>
 
 Field Number: 
 1) Track Degrees
 2) T = True
 3) Track Degrees
 4) M = Magnetic
 5) Speed Knots
 6) N = Knots
 7) Speed Kilometers Per Hour
 8) K = Kilometers Per Hour
 9) FAA mode indicator (NMEA 2.3 and later)
 10) Checksum
 
 Note: in some older versions of NMEA 0183, the sentence looks like this:
 
         1  2  3   4  5
         |  |  |   |  |
 $--VTG,x.x,x,x.x,x.x,*hh<CR><LF>
 
 Field Number: 
 1) True course over ground (degrees) 000 to 359
 2) Magnetic course over ground 000 to 359
 3) Speed over ground (knots) 00.0 to 99.9
 4) Speed over ground (kilometers) 00.0 to 99.9
 5) Checksum
 
 The two forms can be distinguished by field 2, which will be
 the fixed text 'T' in the newer form.  The new form appears
 to have been introduced with NMEA 3.01 in 2002.
 
 Some devices, such as those described in [GLOBALSAT], leave the
 magnetic-bearing fields 3 and 4 empty.
 */


NSString* const TLNMEAGroundCourseAndSpeedSentence = @"Course Over Ground and Ground Speed";
NSString* const TLNMEATrackMadeGoodMagneticKey = @"Track made good (magnetic degrees)";
NSString* const TLNMEAGroundSpeedKilometersKey = @"Speed over ground (kilometers/hour)";

- (NSDictionary*)decodeMessageOfTypeVTG {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEAGroundCourseAndSpeedSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSNumber* trueDegrees = [self readFieldAsDouble:0];
	if (trueDegrees) {
		[decodedMessage setObject:trueDegrees
						   forKey:TLNMEATrackMadeGoodKey];
	}
	
	BOOL isNewFormat = [[self readFieldAsUppercaseString:1] isEqualToString:@"T"];
	
	NSNumber* magneticDegrees = nil;
	if (isNewFormat && [[self readFieldAsUppercaseString:3] isEqualToString:@"M"]) {
		magneticDegrees = [self readFieldAsDouble:2];
	}
	else if (!isNewFormat) {
		magneticDegrees = [self readFieldAsDouble:1];
	}
	if (magneticDegrees) {
		[decodedMessage setObject:magneticDegrees
						   forKey:TLNMEATrackMadeGoodMagneticKey];
	}
	
	NSNumber* groundSpeedKnots = nil;
	if (isNewFormat && [[self readFieldAsUppercaseString:5] isEqualToString:@"N"]) {
		groundSpeedKnots = [self readFieldAsDouble:4];
	}
	else if (!isNewFormat) {
		groundSpeedKnots = [self readFieldAsDouble:2];
	}
	if (groundSpeedKnots) {
		[decodedMessage setObject:groundSpeedKnots
						   forKey:TLNMEAGroundSpeedKnotsKey];
	}
	
	NSNumber* groundSpeedKilometers = nil;
	if (isNewFormat && [[self readFieldAsUppercaseString:7] isEqualToString:@"K"]) {
		groundSpeedKilometers = [self readFieldAsDouble:6];
	}
	else if (!isNewFormat) {
		groundSpeedKilometers = [self readFieldAsDouble:3];
	}
	if (groundSpeedKilometers) {
		[decodedMessage setObject:groundSpeedKilometers
						   forKey:TLNMEAGroundSpeedKilometersKey];
	}
	
	NSString* modeIndicatorValue = [self readFieldAsUppercaseString:8];
	if ([modeIndicatorValue length]) {
		[decodedMessage setObject:modeIndicatorValue
						   forKey:TLNMEAModeIndicatorKey];
	}
	
	return decodedMessage;
}


/*
 GGA - Global Positioning System Fix Data
 Time, Position and fix related data for a GPS receiver.
 
		1         2       3 4        5 6 7  8   9  10 |  12 13  14   15
        |         |       | |        | | |  |   |   | |   | |   |    |
 $--GGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh<CR><LF>
 
 Field Number: 
 1) Universal Time Coordinated (UTC)
 2) Latitude
 3) N or S (North or South)
 4) Longitude
 5) E or W (East or West)
 6) GPS Quality Indicator,
 0 - fix not available,
 1 - GPS fix,
 2 - Differential GPS fix
 (values above 2 are 2.3 features)
 3 = PPS fix
 4 = Real Time Kinematic
 5 = Float RTK
 6 = estimated (dead reckoning)
 7 = Manual input mode
 8 = Simulation mode
 7) Number of satellites in view, 00 - 12	 [satellites *used*, according to SiRF documentation. -nvw]
 8) Horizontal Dilution of precision (meters)	[*not* in meters, just normal HDOP. -nvw]
 9) Antenna Altitude above/below mean-sea-level (geoid) (in meters)
 10) Units of antenna altitude, meters
 11) Geoidal separation, the difference between the WGS-84 earth
 ellipsoid and mean-sea-level (geoid), "-" means mean-sea-level
 below ellipsoid
 12) Units of geoidal separation, meters
 13) Age of differential GPS data, time in seconds since last SC104
 type 1 or 9 update, null field when DGPS is not used
 14) Differential reference station ID, 0000-1023
 15) Checksum 
 */

NSString* const TLNMEAFixDataSentence = @"Time, Position and Fix data";
NSString* const TLNMEANumericModeKey = @"Numeric position fix indicator";
NSString* const TLNMEASatellitesUsedCountKey = @"Number of satellites used";
NSString* const TLNMEAMeanSeaLevelAltitudeKey = @"Height of antenna relative to Mean Sea Level (meters)";
NSString* const TLNMEAGeoidSeparationKey = @"Height of WGS-84 geoid relative to Mean Sea Level (meters)";
NSString* const TLNMEADifferentialCorrectionAge = @"Seconds since last differential update";
NSString* const TLNMEADifferentialReferenceID = @"Differential reference station identifier";

- (NSDictionary*)decodeMessageOfTypeGGA {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEAGroundCourseAndSpeedSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSNumber* timestamp = [self readFieldAsTimeInterval:0];
	if (timestamp) {
		[decodedMessage setObject:timestamp
						   forKey:TLNMEASecondsSinceMidnightUTCKey];
	}
	
	NSNumber* latitude = [self readFieldAsCoordinate:1];
	if (latitude) {
		[decodedMessage setObject:latitude
						   forKey:TLNMEALatitudeKey];
	}
	
	NSNumber* longitude = [self readFieldAsCoordinate:3];
	if (longitude) {
		[decodedMessage setObject:longitude
						   forKey:TLNMEALongitudeKey];
	}
	
	NSNumber* numericQuality = [self readFieldAsUnsignedLong:5];
	if (numericQuality) {
		[decodedMessage setObject:numericQuality
						   forKey:TLNMEANumericModeKey];
		
		// translate numeric quality to FAA code
		NSString* quality = nil;
		switch ([numericQuality unsignedLongValue]) {
			case 0:
				quality = TLNMEAModeIndicatorInvalid;
				break;
			case 1:
				/* SPS mode, see note below */
				quality = TLNMEAModeIndicatorAutonomous;
				break;
			case 2:
				quality = TLNMEAModeIndicatorDifferential;
				break;
			case 3:
				/* PPS mode. For the difference between SPS and PPS,
				 see http://www.gpsworld.com/gpsworld/article/articleDetail.jsp?id=283874 */
			case 4:
				/* Real Time Kinematic, aka CPGPS.
				 See http://en.wikipedia.org/wiki/Real_Time_Kinematic */
			case 5:
				/* Float RTK */
				// just call this and the previous two fancy fixes "differential"
				quality = TLNMEAModeIndicatorDifferential;
				break;
			case 6:
				/* Dead reckoning */
				quality = TLNMEAModeIndicatorEstimated;
				break;
			case 7:
				quality = TLNMEAModeIndicatorManualInput;
				break;
			case 8:
				quality = TLNMEAModeIndicatorSimulated;
				break;
		}
		if (quality) {
			[decodedMessage setObject:quality
							   forKey:TLNMEAModeIndicatorKey];
		}
	}
	
	NSNumber* numberSatellitesUsed = [self readFieldAsUnsignedLong:6];
	if (numberSatellitesUsed) {
		[decodedMessage setObject:numberSatellitesUsed
						   forKey:TLNMEASatellitesUsedCountKey];
	}
	
	NSNumber* hdop = [self readFieldAsDouble:7];
	if (hdop) {
		[decodedMessage setObject:hdop
						   forKey:TLNMEAHorizontalDOPKey];
	}
	
	NSNumber* antennaAltitude = [self readFieldAsDouble:8];
	if (antennaAltitude && [[self readFieldAsUppercaseString:9] isEqualToString:@"M"]) {
		[decodedMessage setObject:antennaAltitude
						   forKey:TLNMEAMeanSeaLevelAltitudeKey];
	}
	
	NSNumber* geoidAltitude = [self readFieldAsDouble:10];
	if (geoidAltitude && [[self readFieldAsUppercaseString:11] isEqualToString:@"M"]) {
		[decodedMessage setObject:geoidAltitude
						   forKey:TLNMEAGeoidSeparationKey];
	}
	
	NSNumber* differentialAge = [self readFieldAsDouble:12];
	if (differentialAge) {
		[decodedMessage setObject:differentialAge
						   forKey:TLNMEADifferentialCorrectionAge];
	}
	
	/* NOTE: this is purported to be a 10-bit integer, but since
	 we haven't seen many examples and since NSString implements
	 -intValue, it seemed best to leave as a string. */
	NSString* differentialStation = [self readFieldAsString:13];
	if ([differentialStation length]) {
		[decodedMessage setObject:differentialStation
						   forKey:TLNMEADifferentialReferenceID];
	}
	
	return decodedMessage;
}


/*
 WPL - Waypoint Location
 
 1       2 3        4 5    6
 |       | |        | |    |
 $--WPL,llll.ll,a,yyyyy.yy,a,c--c*hh<CR><LF>
 
 Field Number: 
 1) Latitude
 2) N or S (North or South)
 3) Longitude
 4) E or W (East or West)
 5) Waypoint name
 6) Checksum
 */

NSString* const TLNMEAWaypointSentence = @"Waypoint location marker";
NSString* const TLNMEANameKey = @"Name";

- (NSDictionary*)decodeMessageOfTypeWPL {
	NSMutableDictionary* decodedMessage = [NSMutableDictionary dictionary];
	[decodedMessage setObject:TLNMEAWaypointSentence
					   forKey:TLNMEASentenceTypeKey];
	
	NSNumber* latitude = [self readFieldAsCoordinate:0];
	if (latitude) {
		[decodedMessage setObject:latitude
						   forKey:TLNMEALatitudeKey];
	}
	
	NSNumber* longitude = [self readFieldAsCoordinate:2];
	if (longitude) {
		[decodedMessage setObject:longitude
						   forKey:TLNMEALongitudeKey];
	}
	
	NSString* name = [self readFieldAsString:4];
	if (name) {
		[decodedMessage setObject:name
						   forKey:TLNMEANameKey];
	}
	
	return decodedMessage;
}

@end
