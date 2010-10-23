//
//  TLSolidMapLayer.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 11/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLSolidMapLayer.h"

#import "TLCocoaToolbag.h"


@implementation TLSolidMapLayer

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo {
	(void)mapInfo;
	CGColorRef c = TLCGColorCreateGenericHSB(80.0f / 360.0f, 0.6f, 0.6f, 1.0f);
	CGContextSetFillColorWithColor(ctx, c);
	CGColorRelease(c);
	CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
}

@end
