//
//  TLProjectionGeometry.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 7/1/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#ifndef TLPROJECTIONGEOMETRY_H
#define TLPROJECTIONGEOMETRY_H

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#include "CTProjection.h"
#endif

#include "TLGeometry.h"
#include "TLCoordGeometry.h"
#include "TLMultiCoordPolygon.h"

#ifdef __OBJC__
/* TODO: deprecate the following group of functions, and replace with MultiCoordPolygon functions below. */
TLCoordPolygonRef TLCoordPolygonCreateFromProjectedBounds(TLBounds bounds, CTProjection* projection);
TLPolygonRef TLPolygonCreateByProjectingCoordPolygon(TLCoordPolygonRef unprojectedPolygon, CTProjection* projection, BOOL failOnError);
TLCoordPolygonRef TLCoordPolygonCreateByUnprojectingPolygon(TLPolygonRef projectedPolygon, CTProjection* projection, BOOL failOnError);
CFArrayRef TLArrayCreateByProjectingCoordLineForDrawing(TLCoordPolygonRef coordLine, CTProjection* projection);
CFArrayRef TLArrayCreateByProjectingCoordPolygonForDrawing(TLCoordPolygonRef coordPoly, CTProjection* projection);
#endif

TLMultiPolygonRef TLMultiPolygonCreateByProjectingNaively(TLMultiCoordPolygonRef multiCoordPoly, TLProjectionRef proj);
TLMultiCoordPolygonRef TLMultiCoordPolygonCreateByUnprojectingNaively(TLMultiPolygonRef multiPoly, TLProjectionRef proj);

TLMultiPolygonRef TLProjectedPolylineCreate(TLMultiCoordPolygonRef multiCoordLine, TLProjectionRef proj, CGFloat sigDist);

#endif /* TLPROJECTIONGEOMETRY_H */
