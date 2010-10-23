//
//  TLLocator.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLLocator.h"

#import "TLTrack.h"
#import "TLPhoto.h"

#import "TLWaypoint.h"
#import "TLLocation.h"
#import "TLTimestamp.h"

#import "TLCocoaToolbag.h"
#include "TLFloat.h"
#include "TLGeoidGeometry.h"

#include <Accelerate/Accelerate.h>


//#define LOCATOR_LOGGING

/* Aptera v2 */
@interface TLWaypointInterpolator : NSObject {
@private
	NSArray* waypoints;
	NSIndexSet* splits;
	double* polynomials;
}
- (id)initWithWaypoints:(NSArray*)theWaypoints splits:(NSIndexSet*)theSplits;
- (TLLocation*)locationAtTimestamp:(TLTimestamp*)timestamp;
@end


@interface TLLocator ()
+ (TLProjectionGeoidRef)interpolationGeoid;
@end


#pragma mark Main implementation

@implementation TLLocator

+ (TLProjectionGeoidRef)interpolationGeoid { return TLProjectionGeoidWGS84; }

@synthesize dataSource;

- (void)dealloc {
	[sortedTracks release];
	[super dealloc];
}


static NSComparisonResult TLCompareTrackStartTimes(TLTrack* track1,
												   TLTrack* track2,
												   void* info)
{
	(void)info;
	NSDate* date1 = [track1 startDate];
	NSDate* date2 = [track2 startDate];
	return [date1 compare:date2];
}

- (NSArray*)evidenceTracks {
	if (!sortedTracks &&
		[[self dataSource] respondsToSelector:@selector(locatorNeedsTracks:)])
	{
		NSSet* tracks = [[self dataSource] locatorNeedsTracks:self];
		sortedTracks = [[tracks allObjects]
							  sortedArrayUsingFunction:TLCompareTrackStartTimes context:NULL];
		[sortedTracks retain];
	}
	return sortedTracks;
}

- (void)reloadData {
	[sortedTracks release], sortedTracks = nil;
}


// NOTE: this may return value equal to array count, use with caution!
+ (NSUInteger)trackInsertionIndex:(NSArray*)activeTracks
					 forStartDate:(NSDate*)targetDate
{
	NSTimeInterval targetTime = [targetDate timeIntervalSinceReferenceDate];
	NSUInteger firstLaterTrackIdx = 0;
	for (TLTrack* track in activeTracks) {
		// update scan position and break if found
		NSTimeInterval trackTime = [[track startDate] timeIntervalSinceReferenceDate];
		if (trackTime > targetTime) break;
		++firstLaterTrackIdx;
	}
	return firstLaterTrackIdx;
}

+ (NSUInteger)waypointInsertionIndex:(NSArray*)waypoints
							 forDate:(NSDate*)targetDate
{
	NSTimeInterval targetTime = [targetDate timeIntervalSinceReferenceDate];
	NSUInteger firstLaterWaypointIdx = 0;
	for (TLWaypoint* waypoint in waypoints) {
		NSDate* waypointDate = [[waypoint timestamp] time];
		NSTimeInterval waypointTime = [waypointDate timeIntervalSinceReferenceDate];
		if (waypointTime > targetTime) break;
		++firstLaterWaypointIdx;
	}
	return firstLaterWaypointIdx;	
}

- (NSMapTable*)locateTimestamps:(NSMapTable*)timestampObjects {
	NSMapTable* locations = [NSMapTable mapTableWithStrongToStrongObjects];
	for (id key in timestampObjects) {
		TLTimestamp* timestamp = [timestampObjects objectForKey:key];
		TLLocation* location = [self locationAtTimestamp:timestamp];
		if (!location) {
			NSLog(@"No location found for object");
			continue;
		}
		[locations setObject:location forKey:key];
	}
	return locations;
}

- (TLLocation*)locationAtTimestamp:(TLTimestamp*)targetTimestamp {
	TLWaypoint* interpolationWaypoints[6] = { nil };
	BOOL targetBetweenTracks = YES;
	
	// find waypoints surrounding timestamp
	NSArray* activeTracks = [self evidenceTracks];
	NSDate* targetDate = [targetTimestamp time];
	NSUInteger laterTrackIdx = [[self class] trackInsertionIndex:activeTracks
													forStartDate:targetDate];
	if (laterTrackIdx > 0) {
		TLTrack* earlierTrack = [activeTracks objectAtIndex:(laterTrackIdx - 1)];
		NSArray* waypoints = [earlierTrack waypoints];
		NSUInteger laterWaypointIdx = [[self class] waypointInsertionIndex:waypoints
																   forDate:targetDate];
#ifdef LOCATOR_LOGGING
		NSLog(@"waypoint %i of %i, from track %i of %i",
			  (int)laterWaypointIdx, (int)[waypoints count],
			  (int)laterTrackIdx, (int)[activeTracks count]);
#endif
		// try to get "before" points from earlierTrack
		if (laterWaypointIdx > 0) {
			interpolationWaypoints[2] = [waypoints objectAtIndex:(laterWaypointIdx-1)];
			if (laterWaypointIdx > 1) {
				interpolationWaypoints[1] = [waypoints objectAtIndex:(laterWaypointIdx-2)];
				if (laterWaypointIdx > 2) {
					interpolationWaypoints[0] = [waypoints objectAtIndex:(laterWaypointIdx-3)];
				}
			}
		}
		// try to get "after" points from earlierTrack
		if (laterWaypointIdx < [waypoints count]) {
			targetBetweenTracks = NO;
			interpolationWaypoints[3] = [waypoints objectAtIndex:laterWaypointIdx];
			if (laterWaypointIdx + 1 < [waypoints count]) {
				interpolationWaypoints[4] = [waypoints objectAtIndex:(laterWaypointIdx+1)];
				if (laterWaypointIdx + 2 < [waypoints count]) {
					interpolationWaypoints[5] = [waypoints objectAtIndex:(laterWaypointIdx+2)];
				}
			}
		}
	}
	// if no "after" points from earlierTrack, try to get them from laterTrack
	if (!interpolationWaypoints[3] && laterTrackIdx < [activeTracks count]) {
		TLTrack* laterTrack = [activeTracks objectAtIndex:laterTrackIdx];
#ifdef LOCATOR_LOGGING
		NSLog(@"first waypoints of track %i of %i",
			  (int)laterTrackIdx + 1, (int)[activeTracks count]);
#endif
		NSArray* waypoints = [laterTrack waypoints];
		if ([waypoints count]) {
			interpolationWaypoints[3] = [waypoints objectAtIndex:0];
			if ([waypoints count] > 1) {
				interpolationWaypoints[4] = [waypoints objectAtIndex:1];
				if ([waypoints count] > 2) {
					interpolationWaypoints[5] = [waypoints objectAtIndex:2];
				}
			}
		}
	}
	
	// find and center available waypoint range
	int minFound = 6;
	int maxFound = 0;
	for (int i = 0; i < 6; ++i) {
		if (interpolationWaypoints[i]) {
			minFound = MIN(minFound, i);
			maxFound = MAX(maxFound, i);
		}
	}
	if (maxFound < minFound) return nil;
#ifdef LOCATOR_LOGGING
	NSLog(@"Interpolation range: %i – %i", minFound, maxFound);
#endif
	
	// don't interpolate at ends of evidence
	if (minFound == 3) {
		maxFound = 3;
	}
	else if (maxFound == 2) {
		minFound = 2;
	}
	
	// limit interpolation polynomial order
	const int maxInterpolation = 4;
	if (maxInterpolation < 3 && minFound < 2 && maxFound > 3) {
		minFound = 2; maxFound = 3;
	}
	else if (maxInterpolation < 5 && minFound < 1 && maxFound > 4) {
		minFound = 1; maxFound = 4;
	}
	
	// interpolate based on found waypoints
	int range = MIN(maxInterpolation, 1+maxFound-minFound);
	NSArray* waypoints = [NSArray arrayWithObjects:(interpolationWaypoints+minFound) count:range];
	NSIndexSet* splits = nil;
	if (targetBetweenTracks && minFound < 3) {
		NSUInteger adjustedSplit = 3 - minFound;
		if (adjustedSplit < [waypoints count]) {
			splits = [NSIndexSet indexSetWithIndex:adjustedSplit];
		}
	}
	TLWaypointInterpolator* wi = [[[TLWaypointInterpolator alloc]
								   initWithWaypoints:waypoints splits:splits] autorelease];
	return [wi locationAtTimestamp:targetTimestamp];
}

- (void)addTimestamps:(NSMutableSet*)timestamps
		  forLocation:(TLLocation*)targetLocation
			  inTrack:(TLTrack*)track
{
	TLCoordinateAltitude targetAltitude = [targetLocation altitude];
	bool useAltitudes = (targetAltitude != TLCoordinateAltitudeUnknown);
	if (!useAltitudes) {
		targetAltitude = 0.0;
	}
	TLCoordinate targetCoord = [targetLocation coordinate];
	TLPlanetPoint targetPoint = TLGeoidGetPlanetPoint(TLProjectionGeoidWGS84, targetCoord, targetAltitude);
	TLMetersECEF targetDistance = [targetLocation horizontalAccuracy];
	TLMetersECEF targetDistanceSqd = targetDistance * targetDistance;
	
	TLPlanetPoint prevPoint = TLPlanetPointZero;
	NSDate* prevDate = nil;
	TLTimestamp* closestGroupTimestamp = nil;	// reset to nil if not in group
	TLMetersECEF closestGroupDistanceSqd = 0.0;
	for (TLWaypoint* waypoint in [track waypoints]) {
		TLCoordinate currentCoord = [[waypoint location] coordinate];
		TLCoordinateAltitude currentAltitude = 0.0;
		if (useAltitudes) {
			currentAltitude = [[waypoint location] altitude];
		}
		TLPlanetPoint currentPoint = TLGeoidGetPlanetPoint(TLProjectionGeoidWGS84,
														   currentCoord, currentAltitude);
		NSDate* currentDate = [[waypoint timestamp] time];
		if (!prevDate) {
			prevPoint = currentPoint;
			prevDate = currentDate;
			TLMetersECEF distanceSqd = TLPlanetPointDistanceSquared(targetPoint, currentPoint);
			if (TLFloatLessThanOrEqual(distanceSqd, targetDistanceSqd)) {
				closestGroupTimestamp = [TLTimestamp timestampWithTime:currentDate
															  accuracy:TLTimestampAccuracyUnknown];
			}
			continue;
		}
		
		double lineTravel = TLPlanetClosestTravel(targetPoint, prevPoint, currentPoint);
		double segmentTravel = TLFloatClampNaive(lineTravel, 0.0, 1.0);
		TLPlanetPoint segmentPoint = TLPlanetPointWithTravel(prevPoint, currentPoint, segmentTravel);
		TLMetersECEF distanceSqd = TLPlanetPointDistanceSquared(targetPoint, segmentPoint);
		
		if (TLFloatLessThanOrEqual(distanceSqd, targetDistanceSqd)) {
			NSTimeInterval timeDifference = [currentDate timeIntervalSinceDate:prevDate];
			NSTimeInterval timeTravel = segmentTravel * timeDifference;
			NSDate* targetDate = [prevDate addTimeInterval:timeTravel];
			// TODO: calculate accuracy
			TLTimestamp* targetTimestamp = [TLTimestamp timestampWithTime:targetDate
																 accuracy:TLTimestampAccuracyUnknown];
			
			// find closest timestmp in contiguous run of "hit" segments
			if (!closestGroupTimestamp || distanceSqd < closestGroupDistanceSqd) {
				closestGroupTimestamp = targetTimestamp;
				closestGroupDistanceSqd = distanceSqd;
			}
		}
		else if (closestGroupTimestamp) {
			// emit timestamp once we know it's the closest in a group
			[timestamps addObject:closestGroupTimestamp];
			closestGroupTimestamp = nil;
		}
		
		prevPoint = currentPoint;
		prevDate = currentDate;
	}
	if (closestGroupTimestamp) {
		[timestamps addObject:closestGroupTimestamp];
	}
}

- (NSSet*)trackTimestampsAtLocation:(TLLocation*)targetLocation {
	NSMutableSet* timestamps = [NSMutableSet set];
	for (TLTrack* track in [self evidenceTracks]) {
		[self addTimestamps:timestamps forLocation:targetLocation inTrack:track];
	}
	return timestamps;
}

@end


static int solveDoubleMatrix(int n, double* matrix, int numResults, double* results);

@interface TLWaypointInterpolator ()
+ (double*)createPolynomialsFromWaypoints:(NSArray*)theWaypoints;
@end


@implementation TLWaypointInterpolator

- (id)initWithWaypoints:(NSArray*)theWaypoints splits:(NSIndexSet*)theSplits {
	self = [super init];
	if (self) {
		NSAssert([theWaypoints count] && [theWaypoints count] < 5,
				 @"Must provide 1 to 4 waypoints to interpolator");
		waypoints = [theWaypoints copy];
		splits = [theSplits copy];
		polynomials = [[self class] createPolynomialsFromWaypoints:waypoints];
		NSAssert(polynomials, @"Could not create interpolation system for waypoints.");
		// TODO: add splits to polynomial errors
	}
	return self;
}

- (void)dealloc {
	[waypoints release];
	[splits release];
	free(polynomials);
	[super dealloc];
}

+ (double*)createPolynomialsFromWaypoints:(NSArray*)theWaypoints {
	const int numResultDimensions = 4;
	const int numWaypoints = (int)[theWaypoints count];
	double* resultMatrix = malloc((numWaypoints * numResultDimensions + 1) * sizeof(double));
	double* times = malloc(numWaypoints * sizeof(double));
	
	bool useAltitudes = true;
	bool useAccuracy = true;
	double baseTime = 0.0;
	for (TLWaypoint* waypoint in theWaypoints) {
		useAltitudes &= ([[waypoint location] altitude] != TLCoordinateAltitudeUnknown);
		useAccuracy &= ([[waypoint location] horizontalAccuracy] != TLCoordinateAccuracyUnknown);
		baseTime += [[[waypoint timestamp] time] timeIntervalSinceReferenceDate];
	}
	baseTime /= numWaypoints;
	//printf("using altitudes: %s, accuracy: %s\n", useAltitudes ? "yes" : "no", useAccuracy ? "yes" : "no");
	
	int timeRowIdx = 0;
	for (TLWaypoint* waypoint in theWaypoints) {
		TLPlanetPoint p = TLGeoidGetPlanetPoint([TLLocator interpolationGeoid],
												[[waypoint location] coordinate],
												useAltitudes ? [[waypoint location] altitude] : 0.0);
#ifdef LOCATOR_LOGGING
		printf("p(%f, %f, %f) <- (%f, %f)\n", p.x, p.y, p.z,
			   [[waypoint location] coordinate].lat, [[waypoint location] coordinate].lon);
#endif
		resultMatrix[0 * numWaypoints + timeRowIdx] = p.x;
		resultMatrix[1 * numWaypoints + timeRowIdx] = p.y;
		resultMatrix[2 * numWaypoints + timeRowIdx] = p.z;
		resultMatrix[3 * numWaypoints + timeRowIdx] = [[waypoint location] horizontalAccuracy];
		times[timeRowIdx] = [[[waypoint timestamp] time] timeIntervalSinceReferenceDate] - baseTime;
		++timeRowIdx;
	}
	
	double* timesMatrix = malloc(numWaypoints * numWaypoints * sizeof(double));
	for (int power = 0; power < numWaypoints; ++power) {
		for (int timeIdx = 0; timeIdx < numWaypoints; ++timeIdx) {
			timesMatrix[power * numWaypoints + timeIdx] = pow(times[timeIdx], power);
#ifdef LOCATOR_LOGGING
			//printf("time %i^%i = %f\n", timeIdx, power, pow(times[timeIdx], power));
#endif
		}
	}
	
	int err = solveDoubleMatrix(numWaypoints, timesMatrix, numResultDimensions, resultMatrix);
	
	free(times);
	free(timesMatrix);
	
	if (err) {
		free(resultMatrix);
		return NULL;
	}
	
	resultMatrix[numWaypoints * numResultDimensions] = baseTime;
	return resultMatrix;
}

+ (TLLocation*)resultAtTimestamp:(TLTimestamp*)timestamp
				 fromPolynomials:(const double*)thePolynomials
						 ofOrder:(NSUInteger)numWaypoints
					  extraError:(double)additionalInaccuracy
{
	const size_t polynomialOrder = numWaypoints;
	const size_t numPolynomials = 4;
	double results[numPolynomials];
	
#ifdef LOCATOR_LOGGING
	int n = (int)numWaypoints;
	printf("%25c %25c %25c %25c\n", 'x', 'y', 'z', 'm');
	for (int r = 0; r < n; ++r) {
		for (int c = 0; c < (int)numPolynomials; ++c) {
			if (c) printf(" ");
			printf("%25.2f", thePolynomials[c * n + r]);
		}
		printf("\n");
	}
	printf("\n");
#endif
	
	double baseTime = thePolynomials[polynomialOrder * numPolynomials];
	double theValue = [[timestamp time] timeIntervalSinceReferenceDate] - baseTime;
#ifdef LOCATOR_LOGGING
	printf("time value - %f\n", theValue);
#endif
	for (size_t polyIdx = 0; polyIdx < numPolynomials; ++polyIdx) {
		double result = 0.0;
		for (size_t orderIdx = polynomialOrder; orderIdx > 0; --orderIdx) {
			double constant = thePolynomials[polyIdx * polynomialOrder + (orderIdx - 1)];
			//result += constant * pow(theValue, orderIdx - 1);
#ifdef LOCATOR_LOGGING
			printf("result[%lu] : %f * t^%lu = %f\n", polyIdx, constant, orderIdx-1,
				   constant * pow(theValue, orderIdx - 1));
#endif
			result = fma(result, theValue, constant);	// (result * theValue) + constant;
		}
		results[polyIdx] = result;
	}
	
	TLPlanetPoint p = TLPlanetPointMake(results[0], results[1], results[2]);
	TLCoordinateAltitude alt = TLCoordinateAltitudeUnknown;
	TLCoordinate coord = TLGeoidGetCoordinate([TLLocator interpolationGeoid], p, &alt);
#ifdef LOCATOR_LOGGING
	printf("p(%f, %f, %f)±%f -> (%f, %f)\n\n", results[0], results[1], results[2], results[3], coord.lat, coord.lon);
#endif
	TLCoordinateAccuracy acc = results[3] + additionalInaccuracy;
	return [TLLocation locationWithCoordinate:coord horizontalAccuracy:acc
									 altitude:alt verticalAccuracy:acc];
}

+ (double)distanceInDuration:(NSTimeInterval)duration {
	/* Aptera 2e can go 0 to 97 km/h in less than 10 seconds according to
	 http://en.wikipedia.org/w/index.php?title=Aptera_2_Series&oldid=312065832 */
	static const double milesAnHourToMetersPerSecond = 0.44704;
	const double maxApteraAcceleration = (60.0 * milesAnHourToMetersPerSecond) / 10.0;
	const double topApteraSpeed = 85.0 * milesAnHourToMetersPerSecond;
	const double acceleration = 0.25 * maxApteraAcceleration;
	const double maxAccelerationDuration = topApteraSpeed / acceleration;
	
	if (duration < 0.0) duration = -duration;
	double accelerationDuration = MIN(duration, maxAccelerationDuration);
	double distanceAccelerating = acceleration * accelerationDuration * accelerationDuration;
	double distanceAtCruise = topApteraSpeed * (duration - accelerationDuration);
	return distanceAccelerating + distanceAtCruise;
}

+ (double)potentialErrorAtTimestamp:(TLTimestamp*)timestamp
						 atPosition:(NSUInteger)laterWaypointIdx
						inWaypoints:(NSArray*)theWaypoints
{
	TLWaypoint* prevWaypoint = nil;
	if (laterWaypointIdx > 0) {
		prevWaypoint = [theWaypoints objectAtIndex:(laterWaypointIdx-1)];
	}
	TLWaypoint* nextWaypoint = nil;
	if (laterWaypointIdx < [theWaypoints count]) {
		nextWaypoint = [theWaypoints objectAtIndex:laterWaypointIdx];
	}
	
	NSTimeInterval duration = 0.0;
	NSDate* targetDate = [timestamp time];
	if (prevWaypoint && nextWaypoint) {
		NSDate* prevDate = [[prevWaypoint timestamp] time];
		NSDate* nextDate = [[nextWaypoint timestamp] time];
		duration = MIN([targetDate timeIntervalSinceDate:prevDate],
					   [nextDate timeIntervalSinceDate:targetDate]);
	}
	else if (prevWaypoint) {
		NSDate* prevDate = [[prevWaypoint timestamp] time];
		duration = [targetDate timeIntervalSinceDate:prevDate];
	}
	else if (nextWaypoint) {
		NSDate* nextDate = [[nextWaypoint timestamp] time];
		duration = [nextDate timeIntervalSinceDate:targetDate];
	}
	
	double apteraError = [self distanceInDuration:duration];
#ifdef LOCATOR_LOGGING
	printf("apteraError: %f meters in %f seconds\n", apteraError, duration);
#endif	
	return apteraError;
}

- (TLLocation*)locationAtTimestamp:(TLTimestamp*)timestamp {
	double apteraError = 0.0;
	NSUInteger followingWaypointIdx = [TLLocator waypointInsertionIndex:waypoints
																forDate:[timestamp time]];
	if (followingWaypointIdx == 0 || followingWaypointIdx == [waypoints count] ||
		[splits containsIndex:followingWaypointIdx])
	{
		apteraError = [[self class] potentialErrorAtTimestamp:timestamp
												   atPosition:followingWaypointIdx
												  inWaypoints:waypoints];
	}
	return [[self class] resultAtTimestamp:timestamp
						   fromPolynomials:polynomials
								   ofOrder:[waypoints count]
								extraError:apteraError];
}

@end


int solveDoubleMatrix(int n, double* matrix, int numResults, double* results) {
	// http://www.physics.oregonstate.edu/~rubin/nacphy/lapack/codes/linear-c.html
	__CLPK_integer pivots[n];
	__CLPK_integer err;
	__CLPK_integer clpkN = n;
	__CLPK_integer clpkNumResults = numResults;
	(void)dgesv_(&clpkN, &clpkNumResults, matrix, &clpkN, pivots, results, &clpkN, &err);
	if (err) NSLog(@"Got error %i when solving interpolation system.", err);
	return err;
}
