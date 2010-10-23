/*
 *  TLPlanetPoint.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLPLANETPOINT_H
#define TLPLANETPOINT_H

#include "TLPrimitiveTypes.h"

typedef double TLMetersECEF;

typedef struct TL_PlanetPoint {
	TLMetersECEF x;
	TLMetersECEF y;
	TLMetersECEF z;
} TLPlanetPoint;

static const TLPlanetPoint TLPlanetPointZero = { .x = 0.0, .y = 0.0, .z = 0.0 };

TL_INLINE TLPlanetPoint TLPlanetPointMake(TLMetersECEF x, TLMetersECEF y, TLMetersECEF z);



#pragma mark Inline implementations

TLPlanetPoint TLPlanetPointMake(TLMetersECEF x, TLMetersECEF y, TLMetersECEF z) {
	TLPlanetPoint planetPoint = { .x = x, .y = y, .z = z };
	return planetPoint;
}

#endif /* TLPLANETPOINT_H */
