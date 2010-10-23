//
//  TLGPXFileConversion.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLGPXFileConversion.h"

#import "TLTrack.h"
#import "TLWaypoint.h"
#import "TLLocation.h"
#import "TLTimestamp.h"


static const NSTimeInterval TLTimestampBaseGPSAccuracy = 0.5;
static const TLCoordinateAccuracy TLCoordinateBaseGPSAccuracy = 1.2;
TLCoordinateAccuracy TLCoordinateHorizontalAccuracy(double horizontalDOP, double positionDOP);
TLCoordinateAccuracy TLCoordinateVerticalAccuracy(double verticalDOP, double positionDOP);


@implementation TLGPXFile (TLGPXFileConversion)

static NSComparisonResult TLTrackSortTrackpoints(id trackpointA, id trackpointB, void* ctx) {
	(void)ctx;
	return [[(TLGPXWaypoint*)trackpointA time] compare:[(TLGPXWaypoint*)trackpointB time]];
}

+ (NSArray*)waypointsFromTrackSegment:(TLGPXTrackSegment*)trackSegment error:(NSError**)err {
	NSUInteger numTrackpoints = [[trackSegment trackpoints] count];
	if (!numTrackpoints) {
		if (err) {
			NSString* errorString = NSLocalizedString(@"GPX track segment must have at least one point",
													  @"Error message when track segment contains no points");
			NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:errorString
																  forKey:NSLocalizedDescriptionKey];
			*err = [NSError errorWithDomain:@"com.calftrail.mercatalog" code:42 userInfo:errorInfo];
		}
		return nil;
	}
	
	// some sources do not have "properly" ordered trackpoints
	NSArray* sortedTrackpoints = [[trackSegment trackpoints]
								  sortedArrayUsingFunction:TLTrackSortTrackpoints context:NULL];
	NSMutableArray* mutableWaypoints = [NSMutableArray array];
	NSDate* previousDate = nil;
	for (TLGPXWaypoint* trackpoint in sortedTrackpoints) {
		// some sources have imprecise timestamps yielding identical times
		NSDate* date = [trackpoint time];
		if (!date) {
			continue;
		}
		if (previousDate && ![date isGreaterThan:previousDate]) {
			continue;
		}
		previousDate = date;
		
		TLCoordinateAccuracy hAcc = TLCoordinateHorizontalAccuracy([trackpoint horizontalDOP],
																   [trackpoint positionDOP]);
		TLCoordinateAccuracy vAcc = TLCoordinateVerticalAccuracy([trackpoint verticalDOP],
																 [trackpoint positionDOP]);
		TLLocation* location = [TLLocation locationWithCoordinate:[trackpoint coordinate]
											   horizontalAccuracy:hAcc
														 altitude:[trackpoint elevation]
												 verticalAccuracy:vAcc];
		TLTimestamp* timestamp = [TLTimestamp timestampWithTime:[trackpoint time]
													   accuracy:TLTimestampBaseGPSAccuracy];
		TLWaypoint* waypoint = [TLWaypoint waypointWithLocation:location timestamp:timestamp];
		[mutableWaypoints addObject:waypoint];
	}
	
	if ([mutableWaypoints count] < [sortedTrackpoints count] && [mutableWaypoints count] < 2) {
		if (err) {
			NSString* errorString = NSLocalizedString(@"Track segment does not contain enough valid points. "
													  @"This can happen when the original timestamps have been discarded.",
													  @"Error message when GPX trackpoints have been discarded");
			NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:errorString
																  forKey:NSLocalizedDescriptionKey];
			*err = [NSError errorWithDomain:@"com.calftrail.mercatalog" code:42 userInfo:errorInfo];
		}
		return nil;
	}
	
	return mutableWaypoints;
}

- (NSArray*)extractTracks:(NSError**)err {
	NSMutableArray* errors = [NSMutableArray array];
	NSMutableArray* extractedTracks = [NSMutableArray array];
	for (TLGPXTracklog* gpxTracklog in [self tracks]) {
		for (TLGPXTrackSegment* segment in gpxTracklog) {
			NSError* internalError;
			NSArray* extractedWaypoints = [[self class] waypointsFromTrackSegment:segment error:&internalError];
			if (!extractedWaypoints) {
				[errors addObject:internalError];
				continue;
			}
			
			TLTrack* track = [[TLTrack alloc] initWithWaypoints:extractedWaypoints];
			[extractedTracks addObject:track];
			[track release];
		}
	}
	
	if ([errors count]) {
		NSLog(@"Errors loading track: %@\n", errors);
	}
	if (![extractedTracks count]) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObject:
									 @"No valid tracks were found in the tracklog."
																forKey:NSLocalizedDescriptionKey];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:-41 userInfo:errInfo];
		}
		return nil;
	}
	return extractedTracks;
}

- (NSArray*)extractWaypoints:(NSError**)err {
	(void)err;
	NSMutableArray* extractedWaypoints = [NSMutableArray array];
	for (TLGPXWaypoint* gpxWaypoint in [self waypoints]) {
		TLLocation* location = [TLLocation locationWithCoordinate:[gpxWaypoint coordinate]
											   horizontalAccuracy:TLCoordinateAccuracyUnknown];
		[extractedWaypoints addObject:location];
	}
	return extractedWaypoints;
}

@end


TLCoordinateAccuracy TLCoordinateHorizontalAccuracy(double horizontalDOP, double positionDOP) {
	TLCoordinateAccuracy horizontalAccuracy = TLCoordinateAccuracyUnknown;
	if (horizontalDOP) {
		horizontalAccuracy = TLCoordinateBaseGPSAccuracy * horizontalDOP;
	}
	else if (positionDOP) {
		/* Horizontal typically contributes significantly less dilution.
		 This factor is based on values from AMOD tracker where hdop=1.2, vdop=1.7 and pdop=2.1 */
		const double horizontalComponentFactor = 0.33;
		double presumedHorizontalDOP = sqrt(horizontalComponentFactor * (positionDOP * positionDOP));
		horizontalAccuracy = TLCoordinateBaseGPSAccuracy * presumedHorizontalDOP;
	}
	return horizontalAccuracy;
}

TLCoordinateAccuracy TLCoordinateVerticalAccuracy(double verticalDOP, double positionDOP) {
	TLCoordinateAccuracy verticalAccuracy = TLCoordinateAccuracyUnknown;
	if (verticalDOP) {
		verticalAccuracy = TLCoordinateBaseGPSAccuracy * verticalDOP;
	}
	else if (positionDOP) {
		// see note in TLCoordinateHorizontalAccuracy regarding this factor
		const double verticalComponentFactor = 0.66;
		double presumedVerticalDOP = sqrt(verticalComponentFactor * (positionDOP * positionDOP));
		verticalAccuracy = TLCoordinateBaseGPSAccuracy * presumedVerticalDOP;
	}
	return verticalAccuracy;
}
