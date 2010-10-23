/*
 *  TLProjectionGeoid.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */


#ifndef TLPROJECTIONGEOID_H
#define TLPROJECTIONGEOID_H

#include "TLCoordinate.h"

typedef const struct TL_ProjectionGeoid* TLProjectionGeoidRef;
typedef double TLProjectionGeoidMeters;

#pragma mark Pre-defined geoids

extern TLProjectionGeoidRef const TLProjectionGeoidWGS84;


#pragma mark Geoid functions

TLProjectionGeoidRef TLProjectionGeoidCopy(TLProjectionGeoidRef geoid);
TLProjectionGeoidRef TLProjectionGeoidRetain(TLProjectionGeoidRef geoid);
void TLProjectionGeoidRelease(TLProjectionGeoidRef geoid);


#pragma mark Geoid information

// this is semi-major axis "a"
TLProjectionGeoidMeters TLProjectionGeoidGetEquatorialRadius(TLProjectionGeoidRef geoid);

// this is "f"
double TLProjectionGeoidGetFlattening(TLProjectionGeoidRef geoid);

bool TLProjectionGeoidIsSpherical(TLProjectionGeoidRef geoid);

// this is semi-minor axis "b"
TLProjectionGeoidMeters TLProjectionGeoidGetPolarRadius(TLProjectionGeoidRef geoid);

// this is "e²"
double TLProjectionGeoidGetEccentricitySquared(TLProjectionGeoidRef geoid);

#endif /* TLPROJECTIONGEOID_H */
