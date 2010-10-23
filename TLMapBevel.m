//
//  TLMapBevel.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 2/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLMapBevel.h"

#import "TLGeometry.h"

@implementation TLMapBevel

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo {
	const CGFloat frameWidth = 0.75f * TLSizeGetAverageWidth([mapInfo significantVisualSize]);
	CGContextSetLineWidth(ctx, frameWidth);
	CGColorRef frameColor = CGColorCreateGenericGray(0.3f, 0.95f);
	CGContextSetStrokeColorWithColor(ctx, frameColor);
	CGColorRelease(frameColor);
	CGRect frameRect = CGRectInset([mapInfo visibleBounds], frameWidth / 2.0f, frameWidth / 2.0f);
	CGContextStrokeRect(ctx, frameRect);
}

@end
