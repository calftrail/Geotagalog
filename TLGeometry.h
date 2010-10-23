/*
 *  TLGeometry.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 2/29/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */


#ifndef TLGEOMETRY_H
#define TLGEOMETRY_H

#import "TLBounds.h"
#import "TLPolygon.h"
#import "TLMultiPolygon.h"

CGFloat TLSizeGetAverageWidth(CGSize size);

CGFloat TLPointDistance(CGPoint a, CGPoint b);
CGFloat TLPointDistanceSquared(CGPoint a, CGPoint b);

CGRect TLCGRectMakeFromPoints(CGPoint a, CGPoint b);
CGRect TLCGRectMakeSquareAroundPoint(CGPoint center, CGFloat sideLength);
CGRect TLCGRectMakeAroundPoint(CGPoint center, CGFloat width, CGFloat height);

CGRect TLCGRectInsetToAspect(CGRect rect, CGFloat width, CGFloat height);

CGRect TLCGRectExpandToIncludePoint(CGRect rect, CGPoint point);

CGPoint TLCGRectGetCenter(CGRect rect);

enum {
	TLAspectIgnore = 0,
	TLAspectPadToFit = 1
};
typedef unsigned int TLAspectPreservationType;

CGAffineTransform TLTransformFromRectToRect(CGRect source, CGRect destination, TLAspectPreservationType aspectOption);

// keeps first and last vertex, but eliminates all vertices within significantDistance from kept vertices
TLPolygonRef TLPolygonCreateByReducingVertices(TLPolygonRef polygon, CGFloat significantDistance);

// densifies a polygon by adding 'factor' vertexes evenly spaced between each existing vertex
TLPolygonRef TLPolygonCreateByDensifyingVertices(TLPolygonRef polygon, tl_uint_t factor);

TLBounds TLBoundsFromPolygon(TLPolygonRef polygon);
TLBounds TLBoundsFromMultiPolygon(TLMultiPolygonRef multiPoly);
TLPolygonRef TLPolygonCreateFromBounds(TLBounds bounds);

TLBounds TLBoundsExpandToIncludeBounds(TLBounds bounds1, TLBounds bounds2);
TLBounds TLBoundsExpandToIncludePoint(TLBounds bounds, CGPoint point);

TLBounds TLBoundsMakeFromPoints(CGPoint a, CGPoint b);

bool TLBoundsContainsPoint(TLBounds bounds, CGPoint point);

TLMultiPolygonRef TLMultiPolygonCreateFromClippedMultiPolygon(TLMultiPolygonRef multiPoly, TLMultiPolygonRef clipPoly);
TLMultiPolygonRef TLMultiPolygonCreateFromClippedMultiPolyline(TLMultiPolygonRef multiLines, TLMultiPolygonRef clipPoly);

bool TLMultiPolygonContainsPoint(TLMultiPolygonRef multiPoly, CGPoint point);

#endif /* TLGEOMETRY_H */
