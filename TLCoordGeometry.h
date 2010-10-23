//
//  TLCoordGeometry.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 4/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#ifndef TLCOORDGEOMETRY_H
#define TLCOORDGEOMETRY_H

#import "TLExtent.h"
#import "TLCoordPolygon.h"


TLCoordinateDegrees TLCoordPolygonGetArea(TLCoordPolygonRef coordPoly);

/* TODO: implement these clipping functions
 TLMultiCoordPolygonRef TLMultiCoordPolygonCreateFromClippedPolygons(TLMultiCoordPolygon multiCoordPoly, TLMultiCoordPolygon clipCoordPoly);
 TLMultiCoordPolygonRef TLMultiCoordPolygonCreateFromClippedPolylines(TLMultiCoordPolygon multiCoordLines, TLMultiCoordPolygon clipCoordPoly);
 */

TLCoordPolygonRef TLCoordPolygonCreateFromExtent(TLExtent extent);

TLCoordinate TLCoordinateAdjustToRange(TLCoordinate inCoord);
TL_INLINE TLCoordinateDegrees TLCoordinateLongitudeAdjustToRange(TLCoordinateDegrees inLon);
TL_INLINE TLCoordinateDegrees TLCoordinateLatitudeClampToRange(TLCoordinateDegrees inLat);



#pragma mark Inline definitions

// Assumes that longitude in (-540º, 540º), ie within 360º of proper range 
TLCoordinateDegrees TLCoordinateLongitudeAdjustToRange(TLCoordinateDegrees inLon) {
	TLCoordinateDegrees outLon = inLon;
	if (outLon > TLProjectionInfoMaxMeridian) {
		// (-180º, 180º) = x - 360º, so x = (180º, 540º)
		outLon -= TLProjectionInfoFullCircle;
	}
	else if (outLon < TLProjectionInfoMinMeridian) {
		// (-180º, 180º) = x + 360º, so x = (-540º, -180º)
		outLon += TLProjectionInfoFullCircle;
	}
	return outLon;
}

TLCoordinateDegrees TLCoordinateLatitudeClampToRange(TLCoordinateDegrees inLat) {
	TLCoordinateDegrees outLat = inLat;
	if (outLat > TLProjectionInfoMaxParallel) {
		outLat = TLProjectionInfoMaxParallel;
	}
	else if (outLat < TLProjectionInfoMinParallel) {
		outLat = TLProjectionInfoMinParallel;
	}
	return outLat;
}

#endif /* TLCOORDGEOMETRY_H */
