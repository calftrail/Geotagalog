/*
 *  TLProjectionParameters.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLPROJECTIONPARAMETERS_H
#define TLPROJECTIONPARAMETERS_H

#include "TLCoordinate.h"


#pragma mark Parameters functions

typedef const struct TL_ProjectionParameters* TLProjectionParametersRef;

TLProjectionParametersRef TLProjectionParametersCreate(void);
TLProjectionParametersRef TLProjectionParametersCopy(TLProjectionParametersRef projParams);
TLProjectionParametersRef TLProjectionParametersRetain(TLProjectionParametersRef projParams);
void TLProjectionParametersRelease(TLProjectionParametersRef projParams);

TLCoordinateDegrees TLProjectionParametersGetLongitudeOfOrigin(TLProjectionParametersRef projParams);
TLCoordinateDegrees TLProjectionParametersGetLatitudeOfOrigin(TLProjectionParametersRef projParams);
TLCoordinateDegrees TLProjectionParametersGetStandardParallel(TLProjectionParametersRef projParams);
TLCoordinateDegrees TLProjectionParametersGetStandardParallel1(TLProjectionParametersRef projParams);
TLCoordinateDegrees TLProjectionParametersGetStandardParallel2(TLProjectionParametersRef projParams);
//TLCoordinate TLProjectionParametersGetObliqueNorthPole(TLProjectionParametersRef projParams);

#pragma mark Mutable parameters functions

typedef struct TL_ProjectionParameters* TLMutableProjectionParametersRef;

TLMutableProjectionParametersRef TLProjectionParametersCreateMutable(void);
TLMutableProjectionParametersRef TLProjectionParametersMutableCopy(TLProjectionParametersRef projParams);

void TLProjectionParametersSetLongitudeOfOrigin(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lon0);
void TLProjectionParametersSetLatitudeOfOrigin(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat0);
void TLProjectionParametersSetStandardParallel(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat0);
void TLProjectionParametersSetStandardParallels(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat1, TLCoordinateDegrees lat2);
//void TLProjectionParametersSetObliqueNorthPole(TLMutableProjectionParametersRef projParams, TLCoordinate northPole);

#endif /* TLPROJECTIONPARAMETERS_H */
