/*
 *  TLCoordinate.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLCOORDINATE_H
#define TLCOORDINATE_H

#include "TLPrimitiveTypes.h"

typedef double TLCoordinateDegrees;

static const double TLCoordinateDegreesToRadians = M_PI / 180.0;
static const double TLCoordinateRadiansToDegrees = 180.0 / M_PI;

static const TLCoordinateDegrees TLProjectionInfoMaxMeridian = 180.0;
static const TLCoordinateDegrees TLProjectionInfoMinMeridian = -180.0;
static const TLCoordinateDegrees TLProjectionInfoMaxParallel = 90.0;
static const TLCoordinateDegrees TLProjectionInfoMinParallel = -90.0;

static const TLCoordinateDegrees TLProjectionInfoFullCircle = 360.0;
static const TLCoordinateDegrees TLProjectionInfoHemisphere = 180.0;



typedef struct TL_Coordinate {
	TLCoordinateDegrees lat;
	TLCoordinateDegrees lon;
} TLCoordinate;

TL_INLINE TLCoordinate TLCoordinateMake(TLCoordinateDegrees latitude, TLCoordinateDegrees longitude);
TL_INLINE TLCoordinate TLCoordinateFromPoint(CGPoint point);

typedef double TLCoordinateAltitude;
static const TLCoordinateAltitude TLCoordinateAltitudeUnknown = -FLT_MAX;


typedef double TLCoordinateAccuracy;
static const TLCoordinateAccuracy TLCoordinateAccuracyUnknown = 0.0;



#pragma mark Inline implementations

TLCoordinate TLCoordinateMake(TLCoordinateDegrees latitude, TLCoordinateDegrees longitude) {
	TLCoordinate coordinate = { .lat = latitude, .lon = longitude };
	return coordinate;
}

TLCoordinate TLCoordinateFromPoint(CGPoint point) {
	return TLCoordinateMake(point.y, point.x);
}

#endif /* TLCOORDINATE_H */
