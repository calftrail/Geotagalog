//
//  TLTrackLayer.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLTrackLayer.h"

#import "TLTrack.h"
#import "TLWaypoint.h"
#import "TLLocation.h"
#include "TLProjectionGeometry.h"
#import "TLMercatalogStyler.h"

@implementation TLTrackLayer

@synthesize dataSource;

- (void)reloadData {
	[self setNeedsDisplay];
}

- (CGPathRef)newPathForTrack:(TLTrack*)track
			  withProjection:(TLProjectionRef)proj
		 significantDistance:(CGFloat)sigDist
{
	
	TLMutableCoordPolygonRef trackCoordPolyline = TLCoordPolygonCreateMutable([[track waypoints] count]);
	if (!trackCoordPolyline) return NULL;
	for (TLWaypoint* waypoint in [track waypoints]) {
		TLCoordinate coord = [[waypoint location] coordinate];
		TLCoordPolygonAppendCoordinate(trackCoordPolyline, coord);
	}
	TLMultiCoordPolygonRef trackMultiPoly = TLMultiCoordPolygonCreateFromPolygon(trackCoordPolyline);
	TLCoordPolygonRelease(trackCoordPolyline);
	if (!trackMultiPoly) return NULL;
	TLMultiPolygonRef projectedTrack = TLProjectedPolylineCreate(trackMultiPoly, proj, sigDist);
	TLMultiCoordPolygonRelease(trackMultiPoly);
	if (!projectedTrack) return NULL;
	
	// make path from projected segments
	tl_uint_t segmentsCount = TLMultiPolygonGetCount(projectedTrack);
	CGMutablePathRef path = CGPathCreateMutable();
	for (tl_uint_t segmentIdx = 0; segmentIdx < segmentsCount; ++segmentIdx) {
		TLPolygonRef segment = TLMultiPolygonGetPolygon(projectedTrack, segmentIdx);
		tl_uint_t numSegmentVertices = TLPolygonGetCount(segment);
		if (!numSegmentVertices) continue;
		CGPoint currentPoint = TLPolygonGetPoint(segment, 0);
		CGPathMoveToPoint(path, NULL, currentPoint.x, currentPoint.y);
		for (tl_uint_t ptIdx = 1; ptIdx < numSegmentVertices; ++ptIdx) {
			currentPoint = TLPolygonGetPoint(segment, ptIdx);
			CGPathAddLineToPoint(path, NULL, currentPoint.x, currentPoint.y);
		}
	}
	TLMultiPolygonRelease(projectedTrack);
	
	return path;
}

- (CGPathRef)newPathForWaypoint:(TLLocation*)waypoint
				 withProjection:(TLProjectionRef)proj
						   size:(CGSize)markerSize
{
	TLProjectionError err = TLProjectionErrorNone;
	CGPoint point = TLProjectionProjectCoordinate(proj, [waypoint coordinate], &err);
	if (err) return NULL;
	CGRect markerRect = TLCGRectMakeAroundPoint(point, markerSize.width, markerSize.height);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, CGRectGetMinX(markerRect), CGRectGetMinY(markerRect));
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(markerRect), CGRectGetMaxY(markerRect));
	CGPathMoveToPoint(path, NULL, CGRectGetMinX(markerRect), CGRectGetMaxY(markerRect));
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(markerRect), CGRectGetMinY(markerRect));
	return path;
}

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo {
	TLProjectionRef proj = [mapInfo projection];
	CGRect boundsToDraw = CGContextGetClipBoundingBox(ctx);
	
	// setup context for drawing tracks
	TLMercatalogStyler* styler = [TLMercatalogStyler defaultStyler];
	CGContextSetStrokeColorWithColor(ctx, [styler trackColor]);
	CGFloat sigDist = TLSizeGetAverageWidth([mapInfo significantVisualSize]);
	CGFloat millimeterFactor = TLSizeGetAverageWidth([mapInfo millimeterSize]);
	CGContextSetLineWidth(ctx, [styler trackWidth] * millimeterFactor);
	CGContextSetMiterLimit(ctx, 2.0f);
	CGContextSetLineCap(ctx, [styler trackLineCap]);
	
	NSArray* tracks = nil;
	if ([dataSource respondsToSelector:@selector(trackLayer:tracksInBounds:underProjection:)]) {
		tracks = [dataSource trackLayer:self
						 tracksInBounds:boundsToDraw
						underProjection:proj];
	}
	for (TLTrack* track in tracks) {
		CGPathRef path = [self newPathForTrack:track
								withProjection:proj
						   significantDistance:sigDist];
		if (!path) continue;
		CGContextAddPath(ctx, path);
		CGPathRelease(path);
		CGContextStrokePath(ctx);
	}
	
	// setup context for drawing waypoints
	CGSize waypointSize = [mapInfo millimeterSize];
	CGColorRef waypointColor = CGColorCreateGenericRGB(0.0f, 0.1216f, 0.2471f, 1.0f);
	CGContextSetStrokeColorWithColor(ctx, waypointColor);
	CGColorRelease(waypointColor);
	CGContextSetLineWidth(ctx, 0.25f * millimeterFactor);
	
	NSArray* waypoints = nil;
	if ([dataSource respondsToSelector:@selector(trackLayer:waypointsInBounds:underProjection:)]) {
		waypoints = [dataSource trackLayer:self
						 waypointsInBounds:boundsToDraw
						   underProjection:proj];
	}
	
	for (TLLocation* waypoint in waypoints) {
		CGPathRef path = [self newPathForWaypoint:waypoint
								   withProjection:proj
											 size:waypointSize];
		if (!path) continue;
		CGContextAddPath(ctx, path);
		CGPathRelease(path);
		CGContextStrokePath(ctx);
	}
}

@end
