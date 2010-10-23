/*
 *  TLGeoidGeometry.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLGEOIDGEOMETRY_H
#define TLGEOIDGEOMETRY_H

#include "TLProjectionGeoid.h"
#include "TLCoordinate.h"
#include "TLPlanetPoint.h"

TLPlanetPoint TLGeoidGetPlanetPoint(TLProjectionGeoidRef planetModel, TLCoordinate coord, TLCoordinateAltitude alt);
TLCoordinate TLGeoidGetCoordinate(TLProjectionGeoidRef planetModel, TLPlanetPoint planetPoint, TLCoordinateAltitude* alt);

TLMetersECEF TLPlanetPointDistance(TLPlanetPoint planetPoint1, TLPlanetPoint planetPoint2);
double TLPlanetPointDistanceSquared(TLPlanetPoint planetPoint1, TLPlanetPoint planetPoint2);

TLPlanetPoint TLPlanetPointWithTravel(TLPlanetPoint planetPointA, TLPlanetPoint planetPointB, double travel);
double TLPlanetClosestTravel(TLPlanetPoint target, TLPlanetPoint lineEndpointA, TLPlanetPoint lineEndpointB);

#endif /* TLGEOIDGEOMETRY_H */
