/*
 *  TLProjectedDrawing.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 11/26/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLProjectedDrawing.h"

#include "TLGeometry.h"

CGPathRef TLCGPathCreateFromMultiPolygon(TLMultiPolygonRef multiPoly, bool isClosed,
										 CGFloat significantDistance)
{
	bool shouldSimplifyPolygon = (significantDistance > 0.0f) ? true : false;
	CGMutablePathRef path = CGPathCreateMutable();
	tl_uint_t polygonCount = TLMultiPolygonGetCount(multiPoly);
	(void)isClosed;
	for (tl_uint_t polygonIdx = 0; polygonIdx < polygonCount; ++polygonIdx) {
		TLPolygonRef polygon = TLMultiPolygonGetPolygon(multiPoly, polygonIdx);
		TLPolygonRef simplifiedPolygon = polygon;
		if (shouldSimplifyPolygon) {
			simplifiedPolygon = TLPolygonCreateByReducingVertices(polygon, significantDistance);
		}
		tl_uint_t simplifiedVertexCount = TLPolygonGetCount(simplifiedPolygon);
		if (!simplifiedVertexCount) continue;
		CGPoint currentPoint = TLPolygonGetPoint(simplifiedPolygon, 0);
		CGPathMoveToPoint(path, NULL, currentPoint.x, currentPoint.y);
		for (tl_uint_t ptIdx = 1; ptIdx < simplifiedVertexCount; ++ptIdx) {
			currentPoint = TLPolygonGetPoint(simplifiedPolygon, ptIdx);
			CGPathAddLineToPoint(path, NULL, currentPoint.x, currentPoint.y);
		}
		if (isClosed) CGPathCloseSubpath(path);
		if (shouldSimplifyPolygon) TLPolygonRelease(simplifiedPolygon);
	}
	return path;
}
