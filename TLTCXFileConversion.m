//
//  TLTCXFileConversion.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLTCXFileConversion.h"

#import "TLTrack.h"
#import "TLWaypoint.h"
#import "TLLocation.h"
#import "TLTimestamp.h"

@implementation TLTCXFile (TLTCXFileConversion)

static NSComparisonResult TLTCXFileSortTrackpoints(id trackpointA, id trackpointB, void* ctx) {
	(void)ctx;
	NSDate* dateA = [(NSDictionary*)trackpointA objectForKey:@"Timestamp"];
	NSDate* dateB = [(NSDictionary*)trackpointB objectForKey:@"Timestamp"];
	return [dateA compare:dateB];
}

- (NSArray*)extractTracks:(NSError**)err {
	(void)err;
	NSMutableArray* extractedTracks = [NSMutableArray array];
	for (NSArray* tcxTrack in [self tracks]) {
		NSAutoreleasePool* looPPool = [NSAutoreleasePool new];
		
		NSArray* sortedTrackPoints = [tcxTrack sortedArrayUsingFunction:TLTCXFileSortTrackpoints
																context:NULL];
		
		NSMutableArray* waypoints = [NSMutableArray array];
		NSDate* prevDate = nil;
		for (NSDictionary* tcxTrackpoint in sortedTrackPoints) {
			NSDate* date = [tcxTrackpoint objectForKey:@"Timestamp"];
			NSAssert(date, @"Required timestamp not found");
			if (prevDate && [date timeIntervalSinceDate:prevDate] == 0.0) {
				// silently skip trackpoints with identical times
				continue;
			}
			TLTimestamp* timestamp = [TLTimestamp timestampWithTime:date
														   accuracy:TLTimestampAccuracyUnknown];
			
			NSNumber* latitude = [tcxTrackpoint objectForKey:@"Latitude"];
			NSNumber* longitude = [tcxTrackpoint objectForKey:@"Longitude"];
			NSAssert(latitude && longitude, @"Required coordinates not found");
			TLCoordinate coord = TLCoordinateMake([latitude doubleValue],
												  [longitude doubleValue]);
			double alt = TLCoordinateAltitudeUnknown;
			NSNumber* altitude = [tcxTrackpoint objectForKey:@"Altitude"];
			if (altitude) {
				alt = [altitude doubleValue];
			}
			TLLocation* location = [TLLocation locationWithCoordinate:coord
												   horizontalAccuracy:TLCoordinateAccuracyUnknown
															 altitude:alt
													 verticalAccuracy:TLCoordinateAccuracyUnknown];
			
			TLWaypoint* waypoint = [TLWaypoint waypointWithLocation:location
														  timestamp:timestamp];
			[waypoints addObject:waypoint];
			prevDate = date;
		}
		if ([waypoints count]) {
			TLTrack* track = [[TLTrack alloc] initWithWaypoints:waypoints];
			[extractedTracks addObject:track];
			[track release];
		}
		
		[looPPool drain];
	}
	return extractedTracks;
}

- (NSArray*)extractWaypoints:(NSError**)err {
	(void)err;
	return [NSArray array];
}

@end
