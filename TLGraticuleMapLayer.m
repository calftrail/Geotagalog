//
//  TLGraticuleMapLayer.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLGraticuleMapLayer.h"

#import "TLProjectionGeometry.h"
#import "TLCoordPolygon.h"
#import "TLCocoaToolbag.h"
#import "TLProjectedDrawing.h"

@implementation TLGraticuleMapLayer

+ (TLMultiCoordPolygonRef)createGridlinesWithSpacing:(TLCoordinateDegrees)requestedSpacing
										 polePadding:(TLCoordinateDegrees)polePadding
{
	const TLCoordinateDegrees requestedResolution = 1.0;
	const tl_uint_t numFullMeridians = 4;
	
	TLCoordinateDegrees maxLat = 90.0 - polePadding;
	tl_uint_t parallelPairs = lround(maxLat / requestedSpacing);
	tl_uint_t meridianPairs = lround(180.0 / requestedSpacing);
	
	tl_uint_t fullMeridianFactor = (2 * meridianPairs) / numFullMeridians;
	
	tl_uint_t numGridlines = (2 * parallelPairs) + (2 * meridianPairs);
	TLMutableMultiCoordPolygonRef gridlineSet = TLMultiCoordPolygonCreateMutable(numGridlines);
	
	TLCoordinateDegrees parallelSpacing = maxLat / parallelPairs;
	tl_uint_t numUniquePointsPerParallel = lround(2 * 180.0 / requestedResolution);
	TLCoordinateDegrees parallelPointSpacing = 2 * 180.0 / numUniquePointsPerParallel;
	for (tl_uint_t parallelIdx = 0; parallelIdx <= parallelPairs; ++parallelIdx) {
		TLCoordinateDegrees lat = parallelIdx * parallelSpacing;
		TLMutableCoordPolygonRef parallelPolyN = TLCoordPolygonCreateMutable(numUniquePointsPerParallel + 1);
		TLMutableCoordPolygonRef parallelPolyS = TLCoordPolygonCreateMutable(numUniquePointsPerParallel + 1);
		for (tl_uint_t parallelPointIdx = 0; parallelPointIdx <= numUniquePointsPerParallel; ++parallelPointIdx) {
			TLCoordinateDegrees lon = -180.0 + (parallelPointIdx * parallelPointSpacing);
			TLCoordPolygonAppendCoordinate(parallelPolyN, TLCoordinateMake(lat, lon));
			TLCoordPolygonAppendCoordinate(parallelPolyS, TLCoordinateMake(-lat, lon));
		}
		TLMultiCoordPolygonAppendPolygon(gridlineSet, parallelPolyN);
		TLCoordPolygonRelease(parallelPolyN);
		if (parallelIdx) TLMultiCoordPolygonAppendPolygon(gridlineSet, parallelPolyS);
		TLCoordPolygonRelease(parallelPolyS);
	}
	
	TLCoordinateDegrees meridianSpacing = 180.0 / meridianPairs;
	for (tl_uint_t meridianIdx = 0; meridianIdx <= meridianPairs; ++meridianIdx) {
		TLCoordinateDegrees lon = meridianIdx * meridianSpacing;
		
		TLCoordinateDegrees baseLat = maxLat;
		tl_uint_t numUniquePointsPerMeridian = lround(2 * baseLat / requestedResolution);
		TLCoordinateDegrees meridianPointSpacing = 2 * baseLat / numUniquePointsPerMeridian;
		if ( !(meridianIdx % fullMeridianFactor) ) {
			baseLat = 90.0;
			numUniquePointsPerMeridian = lround(2 * baseLat / requestedResolution);
			meridianPointSpacing = 2 * baseLat / numUniquePointsPerMeridian;
		}
		TLMutableCoordPolygonRef meridianPolyE = TLCoordPolygonCreateMutable(numUniquePointsPerMeridian + 1);
		TLMutableCoordPolygonRef meridianPolyW = TLCoordPolygonCreateMutable(numUniquePointsPerMeridian + 1);
		for (tl_uint_t meridianPointIdx = 0; meridianPointIdx <= numUniquePointsPerMeridian; ++meridianPointIdx) {
			TLCoordinateDegrees lat = -baseLat + (meridianPointIdx * meridianPointSpacing);
			TLCoordPolygonAppendCoordinate(meridianPolyE, TLCoordinateMake(lat, lon));
			TLCoordPolygonAppendCoordinate(meridianPolyW, TLCoordinateMake(lat, -lon));
		}
		if (meridianIdx && meridianIdx != meridianPairs) TLMultiCoordPolygonAppendPolygon(gridlineSet, meridianPolyE);
		TLCoordPolygonRelease(meridianPolyE);
		TLMultiCoordPolygonAppendPolygon(gridlineSet, meridianPolyW);
		TLCoordPolygonRelease(meridianPolyW);
	}
	return gridlineSet;
}

- (id)init {
	self = [super init];
	if (self) {
		gridlines = [[self class] createGridlinesWithSpacing:1.0 polePadding:5.0];
	}
	return self;
}

- (void)dealloc {
	TLMultiCoordPolygonRelease((TLMultiCoordPolygonRef)gridlines);
	[super dealloc];
}


#pragma mark Drawing

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo {
	TLMultiPolygonRef projectedGridlines = TLProjectedPolylineCreate((TLMultiCoordPolygonRef)gridlines,
																	 [mapInfo projection], 0.0f);
	CGPathRef graticulePath = TLCGPathCreateFromMultiPolygon(projectedGridlines, false,
															 TLSizeGetAverageWidth([mapInfo significantVisualSize]));
	TLMultiPolygonRelease(projectedGridlines);
	CGContextAddPath(ctx, graticulePath);
	CGPathRelease(graticulePath);
	
	CGColorRef graticuleColor = TLCGColorCreateGenericHSB(0.76f, 0.5f, 0.5f, 0.5f);	
	CGContextSetStrokeColorWithColor(ctx, graticuleColor);
	CGColorRelease(graticuleColor);
	CGFloat graticuleWidth = 0.05f * TLSizeGetAverageWidth([mapInfo millimeterSize]);
	CGContextSetLineWidth(ctx, graticuleWidth);
	
	CGContextStrokePath(ctx);
}

@end
