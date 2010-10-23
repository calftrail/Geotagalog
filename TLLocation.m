//
//  TLLocation.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 7/1/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLLocation.h"

#include "TLRandom.h"
#include "TLProjectionInfo.h"
#include "TLCoordGeometry.h"

static CGSize TLProjectionInfoMetersPerDegree(TLCoordinate targetCoord);
static TLCoordinate TLCoordinatePerturb(TLCoordinate origCoord, TLCoordinateAccuracy accuracy);


@implementation TLLocation

#pragma mark Lifecycle

+ (void)initialize {
	if (self != [TLLocation class]) return;
	TLRandomInit();
}

- (id)initWithCoordinate:(TLCoordinate)coord
	  horizontalAccuracy:(TLCoordinateAccuracy)hAccuracy
				altitude:(TLCoordinateAltitude)alt
		verticalAccuracy:(TLCoordinateAccuracy)vAccuracy
{
	self = [super init];
	if (self) {
		coordinate = coord;
		horizontalAccuracy = hAccuracy;
		altitude = alt;
		verticalAccuracy = vAccuracy;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (id)copyWithZone:(NSZone*)zone {
	return [[TLLocation allocWithZone:zone] initWithCoordinate:[self coordinate]
											horizontalAccuracy:[self horizontalAccuracy]
													  altitude:[self altitude]
											  verticalAccuracy:[self verticalAccuracy]];
}


#pragma mark Convenience creators

+ (id)locationWithCoordinate:(TLCoordinate)coord
		  horizontalAccuracy:(TLCoordinateAccuracy)hAccuracy
					altitude:(TLCoordinateAltitude)alt
			verticalAccuracy:(TLCoordinateAccuracy)vAccuracy
{
	TLLocation* location = [[TLLocation alloc] initWithCoordinate:coord
											   horizontalAccuracy:hAccuracy
														 altitude:alt
												 verticalAccuracy:vAccuracy];
	return [location autorelease];
}

+ (id)locationWithCoordinate:(TLCoordinate)coord
		  horizontalAccuracy:(TLCoordinateAccuracy)hAccuracy
{
	TLLocation* location = [[TLLocation alloc] initWithCoordinate:coord
											   horizontalAccuracy:hAccuracy
														 altitude:TLCoordinateAltitudeUnknown
												 verticalAccuracy:TLCoordinateAccuracyUnknown];
	return [location autorelease];
}

- (id)perturbedLocation {
	TLLocation* location = [self copy];
	location->coordinate = TLCoordinatePerturb([self coordinate],
											   [self horizontalAccuracy]);
	return [location autorelease];
}

#pragma mark Accessors

@synthesize coordinate;
@synthesize horizontalAccuracy;
@synthesize altitude;
@synthesize verticalAccuracy;

@end


TLCoordinate TLCoordinatePerturb(TLCoordinate origCoord, TLCoordinateAccuracy accuracy) {
	if (accuracy <= 0.0) return origCoord;
	CGPoint randoms = TLRandomGaussian();
	CGSize degreeSize = TLProjectionInfoMetersPerDegree(origCoord);
	// two standardDeviations is 95.45% certainty
	const double standardDeviations = 2.0;
	double lonAdjustment = (randoms.x * accuracy) / (standardDeviations * degreeSize.width);
	double latAdjustment = (randoms.y * accuracy) / (standardDeviations * degreeSize.height);
	TLCoordinate unclampedCoordinate = TLCoordinateMake(origCoord.lat + latAdjustment,
														origCoord.lon + lonAdjustment);
	return TLCoordinateAdjustToRange(unclampedCoordinate);
}

// use this size only for approximations
CGSize TLProjectionInfoMetersPerDegree(TLCoordinate targetCoord) {
	TLProjectionGeoidMeters equatorCircumference = 2.0 * M_PI * TLProjectionGeoidGetEquatorialRadius(TLProjectionGeoidWGS84);
	TLProjectionGeoidMeters parallelCircumference = cos(targetCoord.lat * TLCoordinateDegreesToRadians) * equatorCircumference;
	double meridianSpacing = parallelCircumference / TLProjectionInfoFullCircle;
	double parallelSpacing = equatorCircumference / TLProjectionInfoFullCircle;		// NOTE: this assumes a spherical earth
	return CGSizeMake((CGFloat)meridianSpacing, (CGFloat)parallelSpacing);
}
