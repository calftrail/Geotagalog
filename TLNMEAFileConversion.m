//
//  TLNMEAFileConversion.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLNMEAFileConversion.h"

#import "TLNMEASentenceDecoding.h"

#import "TLTrack.h"
#import "TLWaypoint.h"
#import "TLLocation.h"
#import "TLTimestamp.h"

static NSComparisonResult TLTrackSortWaypoints(id waypointA, id waypointB, void* ctx);
extern TLCoordinateAccuracy TLCoordinateHorizontalAccuracy(double horizontalDOP, double positionDOP);
extern TLCoordinateAccuracy TLCoordinateVerticalAccuracy(double verticalDOP, double positionDOP);


@implementation TLNMEAFile (TLNMEAFileConversion)

- (NSArray*)extractTrackWaypoints {
	NSMutableArray* waypoints = [NSMutableArray array];
	NSUInteger sentenceIdx = 0;
	const NSUInteger numSentences = [[self sentences] count];
	while (sentenceIdx < numSentences) {
		NSAutoreleasePool* looPPool = [NSAutoreleasePool new];
		
		// gather data until an old value conflicts with a new
		NSMutableDictionary* gatheredInfo = [NSMutableDictionary dictionary];
		while (sentenceIdx < numSentences) {
			TLNMEASentence* sentence = [[self sentences] objectAtIndex:sentenceIdx];
			NSDictionary* sentenceInfo = [sentence decodeSentence];
			//NSLog(@"%@", sentenceInfo);
			
			NSArray* fields = [NSArray arrayWithObjects:
							   TLNMEABaseDateKey, TLNMEASecondsSinceMidnightUTCKey,
							   TLNMEALatitudeKey, TLNMEALongitudeKey, TLNMEAMeanSeaLevelAltitudeKey,
							   TLNMEAPositionDOPKey, TLNMEAHorizontalDOPKey, TLNMEAVerticalDOPKey, nil];
			
			bool conflictingData = false;
			for (NSString* field in fields) {
				id oldValue = [gatheredInfo valueForKey:field];
				id newValue = [sentenceInfo valueForKey:field];
				if (!oldValue && newValue) {
					[gatheredInfo setObject:newValue forKey:field];
				}
				else if (oldValue && newValue && ![oldValue isEqualTo:newValue]) {
					conflictingData = true;
					break;
				}
			}
			
			if (conflictingData) {
				break;
			}
			++sentenceIdx;
		}
		//NSLog(@"%@", gatheredInfo);
		
		TLTimestamp* timestamp = nil;
		NSDate* baseDay = [gatheredInfo objectForKey:TLNMEABaseDateKey];
		NSNumber* daySecondsValue = [gatheredInfo objectForKey:TLNMEASecondsSinceMidnightUTCKey];
		if (baseDay && daySecondsValue) {
			NSTimeInterval daySeconds = [daySecondsValue doubleValue];
			NSDate* timestampDate = [baseDay addTimeInterval:daySeconds];
			timestamp = [TLTimestamp timestampWithTime:timestampDate
											  accuracy:TLTimestampAccuracyUnknown];
		}
		
		TLLocation* location = nil;
		NSNumber* latitude = [gatheredInfo objectForKey:TLNMEALatitudeKey];
		NSNumber* longitude = [gatheredInfo objectForKey:TLNMEALongitudeKey];
		if (latitude && longitude) {
			TLCoordinate coord = TLCoordinateMake([latitude doubleValue],
												  [longitude doubleValue]);
			
			TLCoordinateAltitude altitude = TLCoordinateAltitudeUnknown;
			NSNumber* elevation = [gatheredInfo objectForKey:TLNMEAMeanSeaLevelAltitudeKey];
			if (elevation) {
				altitude = [elevation doubleValue];
			}
			
			double hdop = [[gatheredInfo objectForKey:TLNMEAHorizontalDOPKey] doubleValue];
			double vdop = [[gatheredInfo objectForKey:TLNMEAVerticalDOPKey] doubleValue];
			double pdop = [[gatheredInfo objectForKey:TLNMEAPositionDOPKey] doubleValue];
			
			TLCoordinateAccuracy hAcc = TLCoordinateHorizontalAccuracy(hdop, pdop);
			TLCoordinateAccuracy vAcc = TLCoordinateVerticalAccuracy(vdop, pdop);
			//printf("h - %f, v - %f (%f, %f, %f)\n", hAcc, vAcc, hdop, vdop, pdop);
			location = [TLLocation locationWithCoordinate:coord horizontalAccuracy:hAcc
												 altitude:altitude verticalAccuracy:vAcc];
		}
		
		if (location && timestamp) {
			TLWaypoint* waypoint = [TLWaypoint waypointWithLocation:location timestamp:timestamp];
			[waypoints addObject:waypoint];
		}
		
		[looPPool drain];
	}
	return waypoints;
}

NSComparisonResult TLTrackSortWaypoints(id waypointA, id waypointB, void* ctx) {
	(void)ctx;
	TLTimestamp* timestampA = [(TLWaypoint*)waypointA timestamp];
	TLTimestamp* timestampB = [(TLWaypoint*)waypointB timestamp];
	return [[timestampA time] compare:[timestampB time]];
}

+ (NSArray*)splitTrackWaypointsIntoSegments:(NSArray*)waypoints {
	NSArray* sortedWaypoints = [waypoints sortedArrayUsingFunction:TLTrackSortWaypoints context:NULL];
	
	/* Calculate "online" a running standard deviation of the interval between waypoints,
	 and start a new track segment if an interval exceeds two standard deviations.
	 See http://www.citidel.org/bitstream/10117/1294/1/OnePassAlgorithmToComputeSampleVariance.html
	 and http://en.wikipedia.org/w/index.php?title=Algorithms_for_calculating_variance&oldid=285440230
	 as well as Knuth TAOCP, vol 2, p. 232 */
	NSMutableArray* trackSegments = [NSMutableArray array];
	NSUInteger waypointIdx = 0;
	NSUInteger numWaypoints = [sortedWaypoints count];
	while (waypointIdx < numWaypoints) {
		//printf("\nseg\n");
		NSAutoreleasePool* looPPool = [NSAutoreleasePool new];
		
		NSMutableArray* segmentWaypoints = [NSMutableArray array];
		NSUInteger numberOfSamples = 0;
		NSTimeInterval averageInterval = 0.0;
		double sumOfSqdResiduals = 0.0625;		// allow for some expected deviation
		NSDate* prevTime = nil;
		while (waypointIdx < numWaypoints) {
			TLWaypoint* currentWaypoint = [sortedWaypoints objectAtIndex:waypointIdx];
			NSDate* currentTime = [[currentWaypoint timestamp] time];
			if (prevTime) {
				++numberOfSamples;
				NSTimeInterval currentInterval = [currentTime timeIntervalSinceDate:prevTime];
				
				// split if currentInterval is over a generous threshold
				const NSTimeInterval maxUnbrokenInterval = 2.5 * 60.0;
				if (currentInterval > maxUnbrokenInterval) {
					//printf("cI: %f\n", currentInterval);
					break;
				}
				
				double currentVariance = sumOfSqdResiduals / numberOfSamples;
				NSTimeInterval currentStandardDeviation = sqrt(currentVariance);
				//printf("cI: %f, aI: %f, cSD: %f\n", currentInterval, averageInterval, currentStandardDeviation);
				//printf("%s\n", [[currentTime description] UTF8String]);
				
				// also split if currentInterval significantly differs from averageInterval (if enough samples)
				if (numberOfSamples > 3 && currentInterval > 1.0 + averageInterval + 2.0 * currentStandardDeviation) {
					//printf("split due to interval\n");
					break;
				}
				
				// add waypoint unless identical timestamp as previous
				if (currentInterval > 0.0) {
					[segmentWaypoints addObject:currentWaypoint];
				}
				
				// update running averageInterval and standardDeviation
				NSTimeInterval delta = currentInterval - averageInterval;
				averageInterval += (delta / numberOfSamples);
				sumOfSqdResiduals += delta * (currentInterval - averageInterval);	// blend old delta with new
			}
			else {
				[segmentWaypoints addObject:currentWaypoint];
			}
			++waypointIdx;
			prevTime = currentTime;
		}
		
		if ([segmentWaypoints count]) {
			TLTrack* track = [[TLTrack alloc] initWithWaypoints:segmentWaypoints];
			[trackSegments addObject:track];
			[track release];
		}
		
		[looPPool drain];
	}
	return trackSegments;
}

- (NSArray*)extractTracks:(NSError**)err {
	(void)err;
	NSArray* waypoints = [self extractTrackWaypoints];
	return [[self class] splitTrackWaypointsIntoSegments:waypoints];
}

- (NSArray*)extractWaypoints:(NSError**)err {
	(void)err;
	NSMutableArray* extractedWaypoints = [NSMutableArray array];
	for (TLNMEASentence* sentence in [self sentences]) {
		/* NOTE: checking message type is an optimization to avoid re-decoding all sentences.
		 Since tracks already decode all sentences, this could be improved. */
		if (![[[sentence messageType] uppercaseString] isEqualToString:@"WPL"]) continue;
		
		NSDictionary* sentenceInfo = [sentence decodeSentence];
		NSNumber* latitudeValue = [sentenceInfo objectForKey:TLNMEALatitudeKey];
		NSNumber* longitudeValue = [sentenceInfo objectForKey:TLNMEALongitudeKey];
		if (latitudeValue && longitudeValue) {
			TLCoordinate coord = TLCoordinateMake([latitudeValue doubleValue],
												  [longitudeValue doubleValue]);
			TLLocation* location = [TLLocation locationWithCoordinate:coord
												   horizontalAccuracy:TLCoordinateAccuracyUnknown];
			[extractedWaypoints addObject:location];
		}
	}
	return extractedWaypoints;
}

@end
