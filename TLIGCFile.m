//
//  TLIGCFile.m
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLIGCFile.h"

#import "TLLineParser.h"

/* http://www.fai.org/gliding/system/files/tech_spec_gnss.pdf */


@interface TLIGCFile () <TLLineParserDelegate>
@end

@interface NSData (TLAdditions)
- (const char*)tl_readRange:(NSRange)range;
@end

@interface NSString (TLAdditions)
+ (id)tl_stringWithData:(NSData*)data
				  range:(NSRange)range
			   encoding:(NSStringEncoding)encoding;
@end

@interface NSDate (TLAdditions)
+ (id)tl_baseDateFromDDMMYY:(const char[6])datePtr;
+ (NSNumber*)tl_timeIntervalFromHHMMSS:(const char[6])timePtr;
@end

@interface NSNumber (TLAdditions)
+ (id)tl_numberFromData:(NSData*)data
				  range:(NSRange)range;
@end


@implementation TLIGCFile

@synthesize header;
@synthesize headerSources;
@synthesize fixes;

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err {
	self = [super init];
	if (self) {
		header = [NSMutableDictionary new];
		//headerSources = [NSMutableDictionary new];	// NOTE: not currently used by clients
		fixes = [NSMutableArray new];
		
		TLLineParser* theParser = [[[TLLineParser alloc]
									initWithContentsOfURL:url] autorelease];
		[theParser setDelegate:self];
		parser = theParser;
		[theParser parse];
		parser = nil;
		if ([theParser parserError]) {
			if (err) *err = [theParser parserError];
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	[header release];
	[headerSources release];
	[fixes release];
	[super dealloc];
}

NSString* const TLIGCHeaderSourceRecorder = @"Flight recorder";
NSString* const TLIGCHeaderSourceObserver = @"Official observer";
NSString* const TLIGCHeaderSourcePilot = @"Pilot";

NSString* const TLIGCDateKey = @"Date";
// value is NSDate* representing 0Z on date

NSString* const TLIGCDatumKey = @"Geodetic datum";
NSString* const TLIGCDatumWGS84 = @"WGS-84";

NSString* const TLIGCDatumTextKey = @"Geodetic datum text";
// value is NSString* with datum text

static NSString* const TLIGCFixExtensionsKey = @"Fix extensions";


/* "Header prefix length" - part that foundHeader reads (HSCCC)
 Kept cryptic to fit nicely in NSMakeRange() lines */
static const size_t hpl = 5;	

- (NSDictionary*)readHeaderDTE:(NSData*)lineData {
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	
	const char* datePtr = [lineData tl_readRange:NSMakeRange(hpl, 6)];
	if (datePtr) {
		NSDate* flightDate = [NSDate tl_baseDateFromDDMMYY:datePtr];
		if (flightDate) {
			[info setObject:flightDate forKey:TLIGCDateKey];
		}
	}
	
	return info;
}

- (NSDictionary*)readHeaderDTM:(NSData*)lineData {
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	
	NSNumber* datumCodeValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(hpl, 3)];
	if (datumCodeValue)	switch ([datumCodeValue intValue]) {
		case 100:
			[info setObject:TLIGCDatumWGS84 forKey:TLIGCDatumKey];
			break;
		default:
			[info setObject:
			 [NSString stringWithFormat:@"Unknown (%i)", (int)[datumCodeValue intValue]]
					 forKey:TLIGCDatumKey];
	}
	
	const size_t datumTextIdx = hpl + 3 + 9;	// 9 == strlen("GPSDATUM:");
	if (datumTextIdx < [lineData length]) {
		size_t datumTextLength = [lineData length] - datumTextIdx;
		NSString* datumText = [NSString tl_stringWithData:lineData
													range:NSMakeRange(datumTextIdx, datumTextLength)
												 encoding:NSASCIIStringEncoding];
		[info setObject:datumText forKey:TLIGCDatumTextKey];
	}
	
	return info;
}

- (void)foundHeader:(NSData*)lineData {
	NSString* source = nil;
	const char* sourcePtr = [lineData tl_readRange:NSMakeRange(1, 1)];
	if (sourcePtr) switch (*sourcePtr) {
		case 'F':
			source = TLIGCHeaderSourceRecorder;
			break;
		case 'O':
			source = TLIGCHeaderSourceObserver;
			break;
		case 'P':
			source = TLIGCHeaderSourcePilot;
			break;
		default:
			source = [NSString stringWithFormat:@"Unknown (%c)", *sourcePtr];
	}
	
	NSDictionary* subInfo = nil;
	const char* subtypePtr = [lineData tl_readRange:NSMakeRange(2, 3)];
	if (subtypePtr) {
		NSString* headerParserName = [NSString stringWithFormat:@"readHeader%c%c%c:",
									  subtypePtr[0], subtypePtr[1], subtypePtr[2]];
		SEL headerParser = NSSelectorFromString(headerParserName);
		if ([self respondsToSelector:headerParser]) {
			subInfo = [self performSelector:headerParser withObject:lineData];
		}
	}
	
	if (subInfo) {
		[header addEntriesFromDictionary:subInfo];
		if (source) {
			for (NSString* key in subInfo) {
				[headerSources setObject:source forKey:key];
			}
		}
	}
	//NSLog(@"header: %@", subInfo);
}

- (void)foundFixFormatting:(NSData*)lineData {
	NSMutableDictionary* fixExtensions = [NSMutableDictionary dictionary];
	
	NSNumber* countValue = [NSNumber tl_numberFromData:lineData
												 range:NSMakeRange(1, 2)];
	size_t s = 3;
	NSUInteger fieldsFound = 0;
	do {
		NSNumber* startIdxValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(s, 2)];
		NSNumber* finishIdxValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(s+2, 2)];
		NSString* code = [NSString tl_stringWithData:lineData range:NSMakeRange(s+4, 3)
											encoding:NSASCIIStringEncoding];
		
		if (!code) break;
		
		if (startIdxValue && finishIdxValue) {
			NSUInteger startIdx = [startIdxValue unsignedIntegerValue];
			NSUInteger finishIdx = [finishIdxValue unsignedIntegerValue];
			if (startIdx < finishIdx) {
				NSRange extensionRange = NSMakeRange(startIdx, finishIdx - startIdx);
				[fixExtensions setObject:[NSValue valueWithRange:extensionRange] forKey:code];
			}
		}
		
		fieldsFound++;
		s += 7;
	} while (s < [lineData length]);
	
	if (fieldsFound != [countValue unsignedIntegerValue]) {
		// TODO: turn into stored NSError warning
		NSLog(@"Incorrect number of fields found in fix format information (line %lu)",
			  [parser lineNumber]);
	}
	
	[header setObject:fixExtensions forKey:TLIGCFixExtensionsKey];
	//NSLog(@"fixExtensions: %@", fixExtensions);
}

NSString* const TLIGCFixTimeKey = @"Timestamp";
NSString* const TLIGCFixLatitudeKey = @"Latitude";
NSString* const TLIGCFixLongitudeKey = @"Longitude";
NSString* const TLIGCFixPressureAltitudeKey = @"Pressure alitude";
NSString* const TLIGCFixValidityKey = @"Fix validity";
NSString* const TLIGCFixValidity2D = @"2D or invalid fix";
NSString* const TLIGCFixValidity3D = @"3D fix";
NSString* const TLIGCFixGeoidAltitudeKey = @"Height above geoid";
NSString* const TLIGCFixAccuracyKey = @"Accuracy (2-sigma EPE)";
NSString* const TLIGCFixEngineNoiseKey = @"Engine noise level";

- (void)foundFix:(NSData*)lineData {
	NSMutableDictionary* fix = [NSMutableDictionary dictionary];
	
	const char* timePtr = [lineData tl_readRange:NSMakeRange(1, 6)];
	if (timePtr) {
		NSNumber* timeValue = [NSDate tl_timeIntervalFromHHMMSS:timePtr];
		if (timeValue) {
			[fix setObject:timeValue forKey:TLIGCFixTimeKey];
		}
	}
	
	NSNumber* latDegValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(7, 2)];
	NSNumber* latMinValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(9, 5)];
	const char* latDirectionValuePtr = [lineData tl_readRange:NSMakeRange(14, 1)];
	if (latDegValue && latMinValue && latDirectionValuePtr) {
		double latitude = [latDegValue doubleValue] + [latMinValue integerValue] / 1000.0 / 60.0;
		if (*latDirectionValuePtr == 'S') {
			latitude = -latitude;
		}
		[fix setObject:[NSNumber numberWithDouble:latitude] forKey:TLIGCFixLatitudeKey];
	}
	
	NSNumber* lonDegValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(15, 3)];
	NSNumber* lonMinValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(18, 5)];
	const char* lonDirectionValuePtr = [lineData tl_readRange:NSMakeRange(23, 1)];
	if (lonDegValue && lonMinValue && lonDirectionValuePtr) {
		double longitude = [lonDegValue doubleValue] + [lonMinValue integerValue] / 1000.0 / 60.0;
		if (*lonDirectionValuePtr == 'W') {
			longitude = -longitude;
		}
		[fix setObject:[NSNumber numberWithDouble:longitude] forKey:TLIGCFixLongitudeKey];
	}
	
	const char* fixValidityPtr = [lineData tl_readRange:NSMakeRange(24, 1)];
	if (fixValidityPtr) {
		NSString* fixValidity = nil;
		switch (*fixValidityPtr) {
			case 'A':
				fixValidity = TLIGCFixValidity3D;
				break;
			case 'V':
				fixValidity = TLIGCFixValidity2D;
				break;
			default:
				fixValidity = [NSString stringWithFormat:@"Unknown (%c)", *fixValidityPtr];
		}
		[fix setObject:fixValidity forKey:TLIGCFixValidityKey];
	}
	
	NSNumber* pressureAltValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(25, 5)];
	if (pressureAltValue) {
		// http://en.wikipedia.org/wiki/International_Standard_Atmosphere
		[fix setObject:pressureAltValue forKey:TLIGCFixGeoidAltitudeKey];
	}
	
	NSNumber* geoidAltValue = [NSNumber tl_numberFromData:lineData range:NSMakeRange(30, 5)];
	if (geoidAltValue) {
		[fix setObject:geoidAltValue forKey:TLIGCFixPressureAltitudeKey];
	}
	
	NSDictionary* fixExtensions = [header objectForKey:TLIGCFixExtensionsKey];
	for (NSString* extension in fixExtensions) {
		NSRange extensionRange = [[fixExtensions objectForKey:extension] rangeValue];
		NSString* extensionKey = nil;
		id extensionValue = nil;
		if ([extension isEqualToString:@"FXA"]) {
			extensionKey = TLIGCFixAccuracyKey;
			extensionValue = [NSNumber tl_numberFromData:lineData range:extensionRange];
		}
		else if ([extension isEqualToString:@"ENL"]) {
			extensionKey = TLIGCFixEngineNoiseKey;
			extensionValue = [NSNumber tl_numberFromData:lineData range:extensionRange];
		}
		else {
			extensionKey = extension;
			extensionValue = [NSString tl_stringWithData:lineData
												   range:extensionRange
												encoding:NSASCIIStringEncoding];
			[fix setObject:extensionValue forKey:extension];
		}
		// LAD, LOD, TDS, VXA
		
		if (extensionValue) {
			[fix setObject:extensionValue forKey:extensionKey];
		}
	}
	[fixes addObject:fix];
	//NSLog(@"fix: %@", fix);
}

- (void)lineParser:(TLLineParser*)theParser foundLine:(NSData*)lineData {
	(void)theParser;
	
	const char* lineTypePtr = [lineData tl_readRange:NSMakeRange(0, 1)];
	if (lineTypePtr) switch (*lineTypePtr) {
		case 'H':
			[self foundHeader:lineData];
			break;
		case 'I':
			[self foundFixFormatting:lineData];
			break;
		case 'B':
			[self foundFix:lineData];
			break;
		default:
			; // ignore
	}
}

@end


@implementation NSString (TLAdditions)

+ (id)tl_stringWithData:(NSData*)data
				  range:(NSRange)range
			   encoding:(NSStringEncoding)encoding
{
	const char* stringPtr = [data tl_readRange:range];
	if (!stringPtr) return nil;
	NSString* string = [[NSString alloc] initWithBytes:stringPtr
												length:range.length
											  encoding:encoding];
	return [string autorelease];
}

@end

@implementation NSData (TLAdditions)

- (const char*)tl_readRange:(NSRange)range {
	return ((range.location + range.length <= [self length]) ?
			[self bytes] + range.location : NULL);
}

@end


@implementation NSDate (TLAdditions)

+ (id)tl_baseDateFromDDMMYY:(const char[6])datePtr {
	if (!datePtr) return nil;
	
	// text will be interpreted as if in this timezone
	NSTimeZone* const theTimezone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	// timestamps will be this many years or less into the future
	const char windowYears = 1;
	
	unsigned char twoDigitYear = 0;
	unsigned char month = 0;
	unsigned char day = 0;
	int numArgumentsFilled = sscanf(datePtr, "%2hhu%2hhu%2hhu",
									&day, &month, &twoDigitYear);
	if (numArgumentsFilled != 3) return nil;
	
	NSDate* now = [NSDate date];
	NSCalendar* gregorian = [[[NSCalendar alloc]
							  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[gregorian setTimeZone:theTimezone];
	NSDateComponents* components = [gregorian components:kCFCalendarUnitYear fromDate:now];
	NSInteger yearNow = [components year];
	NSInteger hundredsNow = 100 * (yearNow / 100);
	
	// window timestamp
	NSInteger year = hundredsNow + twoDigitYear;
	if (year > yearNow + windowYears) {
		year -= 100;
	}
	
	NSDateComponents* dayComponents = [[NSDateComponents new] autorelease];
	[dayComponents setYear:year];
	[dayComponents setMonth:month];
	[dayComponents setDay:day];
	return [gregorian dateFromComponents:dayComponents];
}

+ (NSNumber*)tl_timeIntervalFromHHMMSS:(const char[6])timePtr {
	unsigned char hours = 0;
	unsigned char minutes = 0;
	unsigned char seconds = 0;
	int argumentsFilled = sscanf(timePtr, "%2hhu%2hhu%2hhu",
								 &hours, &minutes, &seconds);
	
	NSNumber* timeInterval = nil;
	if (argumentsFilled == 3) {
		NSTimeInterval interval = (hours * 60.0 * 60.0) + (minutes * 60.0) + seconds;
		timeInterval = [NSNumber numberWithDouble:interval];
	}
	return timeInterval;
}

@end

@implementation NSNumber (TLAdditions)

+ (id)tl_numberFromData:(NSData*)data
				  range:(NSRange)range
{
	NSAssert1(range.length < 325,
			  @"Unsupported width (%lu) for number string.", (long unsigned)range.length);
	const char* numberPtr = [data tl_readRange:range];
	if (!numberPtr || !range.length) return nil;
	
	// NOTE: currently only integer values supported
	
#define maxFormatLength 7	// NNN%li0
	char formatBuffer[maxFormatLength] = {};
	int len = snprintf(formatBuffer, maxFormatLength, "%%%luld", (long unsigned)range.length);
	NSAssert(len < maxFormatLength, @"Couldn't create parse format string.");
#undef maxFormatLength
	
	long number = 0;
	int numArgumentsFilled = sscanf(numberPtr, formatBuffer, &number);
	
	NSNumber* numberValue = nil;
	if (numArgumentsFilled == 1) {
		numberValue = [NSNumber numberWithLong:number];
	}
	return numberValue;
}

@end
