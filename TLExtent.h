/*
 *  TLExtent.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLEXTENT_H
#define TLEXTENT_H

#include "TLCoordinate.h"

typedef struct TL_Extent {
	TLCoordinateDegrees west;
	TLCoordinateDegrees east;
	TLCoordinateDegrees south;
	TLCoordinateDegrees north;
} TLExtent;

TL_INLINE TLExtent TLExtentMake(TLCoordinateDegrees west, TLCoordinateDegrees east, TLCoordinateDegrees south, TLCoordinateDegrees north);
TL_INLINE TLCoordinateDegrees TLExtentGetCenterLongitude(TLExtent extent);
TL_INLINE TLCoordinateDegrees TLExtentGetCenterLatitude(TLExtent extent);
TL_INLINE TLCoordinate TLExtentGetNorthwestCoordinate(TLExtent extent);
TL_INLINE TLCoordinate TLExtentGetNortheastCoordinate(TLExtent extent);
TL_INLINE TLCoordinate TLExtentGetSoutheastCoordinate(TLExtent extent);
TL_INLINE TLCoordinate TLExtentGetSouthwestCoordinate(TLExtent extent);

TL_INLINE TLCoordinate TLExtentGetNorthCentralCoordinate(TLExtent extent);
TL_INLINE TLCoordinate TLExtentGetSouthCentralCoordinate(TLExtent extent);

TL_INLINE TLCoordinateDegrees TLExtentGetLatitudeRange(TLExtent extent);
TL_INLINE TLCoordinateDegrees TLExtentGetLongitudeRange(TLExtent extent);

#pragma mark Inline implementations

// expects north>south, as "meridian pinching" makes extents usesless over the poles anyway. however, east may be less than west.
TLExtent TLExtentMake(TLCoordinateDegrees west, TLCoordinateDegrees east, TLCoordinateDegrees south, TLCoordinateDegrees north) {
	TLExtent extent = {
		.west = west,
		.east = east,
		.south = south,
		.north = north
	};
	return extent;
}

TLCoordinateDegrees TLExtentGetCenterLatitude(TLExtent extent) {
	return (extent.south + extent.north) / 2.0;
}

extern TLCoordinateDegrees TL_ExtentLongitudeClip(TLCoordinateDegrees lon);

TLCoordinateDegrees TLExtentGetCenterLongitude(TLExtent extent) {
	/* TODO: Double check this, it could be somewhat wrong still
	 Note however, that we are not looking for the geodesic midpoint. */
	TLCoordinateDegrees averageLongitude = (extent.west + extent.east) / 2.0;
	return (extent.west < extent.east) ? averageLongitude : TL_ExtentLongitudeClip(averageLongitude + 180.0);
}

TLCoordinate TLExtentGetNorthwestCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.north, extent.west);
}

TLCoordinate TLExtentGetNortheastCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.north, extent.east);
}

TLCoordinate TLExtentGetSoutheastCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.south, extent.east);
}

TLCoordinate TLExtentGetSouthwestCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.south, extent.west);
}

TLCoordinate TLExtentGetNorthCentralCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.north, TLExtentGetCenterLongitude(extent));
}

TLCoordinate TLExtentGetSouthCentralCoordinate(TLExtent extent) {
	return TLCoordinateMake(extent.south, TLExtentGetCenterLongitude(extent));
}

TLCoordinateDegrees TLExtentGetLatitudeRange(TLExtent extent) {
	return extent.north - extent.south;
}

TLCoordinateDegrees TLExtentGetLongitudeRange(TLExtent extent) {
	TLCoordinateDegrees distance = NAN;
	if (extent.east > extent.west) {
		distance = extent.east - extent.west;
	}
	else {
		distance = 0.0;
		distance += 180.0 - extent.west;
		distance += extent.east - -180.0;
	}
	return distance;
}

#endif /* TLEXTENT_H */
