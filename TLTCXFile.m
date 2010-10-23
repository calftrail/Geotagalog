//
//  TLTCXFile.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLTCXFile.h"

#import "NSDateFormatter+TLAdditions.h"


@interface TLTCXFile ()
@property (nonatomic, retain) NSMutableArray* gatheredTrackPoints;
@property (nonatomic, retain) NSMutableDictionary* gatheredTrackPointInfo;
@property (nonatomic, retain) NSMutableString* gatheredCharacters;
@end


@implementation TLTCXFile

@synthesize tracks;
@synthesize gatheredTrackPoints;
@synthesize gatheredTrackPointInfo;
@synthesize gatheredCharacters;

#pragma mark Lifecycle

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err {
	self = [super init];
	if (self) {
		tracks = [[NSMutableArray array] retain];
		NSXMLParser* parser = [[[NSXMLParser alloc] initWithContentsOfURL:url] autorelease];
		[parser setDelegate:self];
		BOOL success = [parser parse];
		if (!success) {
			if (err) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 [parser parserError], NSUnderlyingErrorKey,
										 @"Not a valid Training Center file.", NSLocalizedDescriptionKey, nil];
				*err = [NSError errorWithDomain:NSCocoaErrorDomain
										   code:NSFileReadCorruptFileError
									   userInfo:errInfo];
			}
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	[tracks release];
	[self setGatheredTrackPoints:nil];
	[self setGatheredTrackPointInfo:nil];
	[self setGatheredCharacters:nil];
	[super dealloc];
}


#pragma mark Parsing

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
	attributes:(NSDictionary*)attributeDict
{
	(void)parser;
	(void)namespaceURI;		// TODO: check namespaceURI is correct?
	(void)qualifiedName;
	(void)attributeDict;
	if ([elementName isEqualToString:@"Track"]) {
		[self setGatheredTrackPoints:[NSMutableArray array]];
	}
	else if ([elementName isEqualToString:@"Trackpoint"]) {
		[self setGatheredTrackPointInfo:[NSMutableDictionary dictionary]];
	}
	else if ([elementName isEqualToString:@"Time"] ||
			 [elementName isEqualToString:@"LatitudeDegrees"] ||
			 [elementName isEqualToString:@"LongitudeDegrees"] ||
			 [elementName isEqualToString:@"AltitudeMeters"])
	{
		[self setGatheredCharacters:[NSMutableString string]];
	}
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string {
	(void)parser;
	[[self gatheredCharacters] appendString:string];
}

+ (NSNumber*)doubleNumberFromString:(NSString*)doubleString {
	NSNumber* number = nil;
	if ([doubleString length]) {
		const char* value = [doubleString UTF8String];
		char* checkPtr = NULL;
		double num = strtod(value, &checkPtr);
		if (checkPtr != value) {
			number = [NSNumber numberWithDouble:num];
		}
	}
	return number;
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
{
	(void)parser;
	(void)namespaceURI;
	(void)qualifiedName;
	if ([elementName isEqualToString:@"Track"]) {
		if ([[self gatheredTrackPoints] count]) {
			[tracks addObject:[self gatheredTrackPoints]];
		}
		[self setGatheredTrackPoints:nil];
	}
	else if ([elementName isEqualToString:@"Trackpoint"]) {
		NSDate* date = nil;
		NSString* timeString = [[self gatheredTrackPointInfo] objectForKey:@"Time"];
		if ([timeString length]) {
			date = [NSDateFormatter tl_dateFromISO8601:timeString];
		}
		
		NSString* latString = [[self gatheredTrackPointInfo] objectForKey:@"LatitudeDegrees"];
		NSNumber* latitude = [[self class] doubleNumberFromString:latString];
		
		NSString* lonString = [[self gatheredTrackPointInfo] objectForKey:@"LongitudeDegrees"];
		NSNumber* longitude = [[self class] doubleNumberFromString:lonString];
		
		NSString* altitudeString = [[self gatheredTrackPointInfo] objectForKey:@"AltitudeMeters"];
		NSNumber* altitude = [[self class] doubleNumberFromString:altitudeString];
		
		if (date && latitude && longitude) {
			NSMutableDictionary* trackPoint = [NSMutableDictionary dictionary];
			[trackPoint setObject:date forKey:@"Timestamp"];
			[trackPoint setObject:latitude forKey:@"Latitude"];
			[trackPoint setObject:longitude forKey:@"Longitude"];
			if (altitude) {
				[trackPoint setObject:longitude forKey:@"Altitude"];
			}
			[[self gatheredTrackPoints] addObject:trackPoint];
		}
		[self setGatheredTrackPointInfo:nil];
	}
	else if ([elementName isEqualToString:@"Time"] ||
			 [elementName isEqualToString:@"LatitudeDegrees"] ||
			 [elementName isEqualToString:@"LongitudeDegrees"] ||
			 [elementName isEqualToString:@"AltitudeMeters"])
	{
		if ([[self gatheredCharacters] length]) {
			[[self gatheredTrackPointInfo] setObject:[self gatheredCharacters]
											  forKey:elementName];
		}
		[self setGatheredCharacters:nil];
	}
}

@end
