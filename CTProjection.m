//
//  CTProjection.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/6/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "CTProjection.h"
#import "TLCoordGeometry.h"


@implementation CTProjection

#pragma mark Lifecycle

// designated initializer
- (id)initWithWrappedProjection:(TLProjectionRef)theWrappedProjection {
	self = [super init];
	if (self) {
		wrappedProjection = TLProjectionCopy(theWrappedProjection);
	}
	return self;
}

- (void)dealloc {
	TLProjectionRelease([self wrappedProjection]);
	[super dealloc];
}

- (id)copyWithZone:(NSZone*)zone {
	id copy = [[self class] allocWithZone:zone];
	return [copy initWithWrappedProjection:[self wrappedProjection]];
}


#pragma mark Convenience creators

+ (id)projectionWithCodename:(NSString*)projectionName {
	TLMutableProjectionParametersRef projParams = TLProjectionParametersCreateMutable();
	TLProjectionParametersSetLongitudeOfOrigin(projParams, -98.0);
	TLProjectionParametersSetLatitudeOfOrigin(projParams, 45.0);
	if ([projectionName isEqualToString:@"lcc"]) {
		TLProjectionParametersSetStandardParallels(projParams, 37.0, 65.0);
		//TLProjectionParametersSetStandardParallels(projParams, 0.0, 5.0);
	}
	TLProjectionError err = 0;
	TLProjectionRef wrappedProj = TLProjectionCreate([projectionName cStringUsingEncoding:NSASCIIStringEncoding], TLProjectionGeoidWGS84, projParams, &err);
	(void)err;
	TLProjectionParametersRelease(projParams);
	if (!wrappedProj) return nil;
	CTProjection* projection = [[CTProjection alloc] initWithWrappedProjection:wrappedProj];
	TLProjectionRelease(wrappedProj);
	return [projection autorelease];
}


#pragma mark Accessors

-(TLCoordinateDegrees)antimeridian {
	TLProjectionParametersRef projParams = TLProjectionGetParameters([self wrappedProjection]);
	TLCoordinateDegrees longitudeOfOrigin = TLProjectionParametersGetLongitudeOfOrigin(projParams);
	// the antimeridian is opposite the meridian on the spheroid
	TLCoordinateDegrees antimeridian = longitudeOfOrigin + 180.0;
	// make sure antimeridian is in [-180,180] 
	antimeridian = TLCoordinateLongitudeAdjustToRange(antimeridian);
	//printf("antimeridian: %f\n", antimeridian);
	return antimeridian;
}

- (TLProjectionRef)wrappedProjection {
	return (TLProjectionRef)wrappedProjection;
}

- (CGPoint)projectCoordinate:(TLCoordinate)coord {
	TLProjectionError err = 0;
	CGPoint point = TLProjectionProjectCoordinate([self wrappedProjection], coord, &err);
	errorFromOperation = err;
	return point;
}

- (TLCoordinate)unprojectPoint:(CGPoint)aPoint {
	TLProjectionError err = 0;
	TLCoordinate coord = TLProjectionUnprojectPoint([self wrappedProjection], aPoint, &err);
	errorFromOperation = err;
	return coord;
}

-(BOOL)hadErrorResult {
	//NSAssert(!errorFromOperation, @"Debug helper used to check if any errors are received");
	return (BOOL)errorFromOperation;
}

-(NSString*)stringForError {
	if (!errorFromOperation) return nil;
	char errorMessage[255];
	(void)TLProjectionErrorGetString(errorFromOperation, errorMessage, 255);
	return [NSString stringWithCString:errorMessage encoding:NSASCIIStringEncoding];
}

@end
