/*
 *  TLExtent.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLExtent.h"

// Assumes longitude within 360º of proper range.
TLCoordinateDegrees TL_ExtentLongitudeClip(TLCoordinateDegrees lon) {
	TLCoordinateDegrees clippedLon = lon;
	if (lon > 180.0) {
		clippedLon -= 360.0;
	}
	else if (lon < 180.0) {
		clippedLon += 360.0;
	}
	return clippedLon;
}


