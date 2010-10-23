/*
 *  TLProjectionInfo.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/4/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLPROJECTIONINFO_H
#define TLPROJECTIONINFO_H

#include "TLProjection.h"
#include "TLMultiPolygon.h"
#include "TLMultiCoordPolygon.h"
#include "TLBounds.h"

TLMultiCoordPolygonRef TLProjectionInfoCreateDomain(TLProjectionRef proj, TLCoordinateAccuracy significantDistance);
TLMultiPolygonRef TLProjectionInfoCreateRange(TLProjectionRef proj, CGFloat significantDistance);

TLBounds TLProjectionInfoDefaultBounds(TLProjectionRef proj);


#pragma mark Helpful accessors
TLCoordinate TLProjectionInfoGetCenter(TLProjectionRef proj);
CGFloat TLProjectionInfoGetScalingFactor(TLProjectionRef proj);

#endif /* TLPROJECTIONINFO_H */
