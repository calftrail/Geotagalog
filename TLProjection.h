/*
 *  TLProjection.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLPROJECTION_H
#define TLPROJECTION_H

#include "TLProjectionParameters.h"
#include "TLProjectionGeoid.h"

#include "TLPrimitiveTypes.h"
#include "TLCoordinate.h"


#pragma mark Names for supported projections

typedef const char* TLProjectionName;
extern TLProjectionName const TLProjectionNameMercator;
extern TLProjectionName const TLProjectionNameStereographic;
extern TLProjectionName const TLProjectionNameLambertConformalConic;
extern TLProjectionName const TLProjectionNameOrthographic;
extern TLProjectionName const TLProjectionNameRobinson;

bool TLProjectionNamesEqual(TLProjectionName name1, TLProjectionName name2);

#pragma mark Error information

typedef int TLProjectionError;
static const TLProjectionError TLProjectionErrorNone = 0;
bool TLProjectionErrorGetString(TLProjectionError err, char* stringBuf, int bufLen);


#pragma mark Projection functions

typedef const struct TL_Projection* TLProjectionRef;

TLProjectionRef TLProjectionCreate(TLProjectionName name,
								   TLProjectionGeoidRef planetModel,
								   TLProjectionParametersRef parameters,
								   TLProjectionError* err);

TLProjectionRef TLProjectionCopy(TLProjectionRef proj);
TLProjectionRef TLProjectionRetain(TLProjectionRef proj);
void TLProjectionRelease(TLProjectionRef proj);


CGPoint TLProjectionProjectCoordinate(TLProjectionRef proj, TLCoordinate coord, TLProjectionError* err);
TLCoordinate TLProjectionUnprojectPoint(TLProjectionRef proj, CGPoint point, TLProjectionError* err);

TLProjectionName TLProjectionGetName(TLProjectionRef proj);
TLProjectionGeoidRef TLProjectionGetPlanetModel(TLProjectionRef proj);
TLProjectionParametersRef TLProjectionGetParameters(TLProjectionRef proj);

#endif /* TLPROJECTION_H */
