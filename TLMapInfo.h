/*
 *  TLMapInfo.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/23/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#include "TLProjection.h"
#include "TLBounds.h"

@protocol TLMapInfo

@property (nonatomic, readonly) TLProjectionRef projection;
@property (nonatomic, readonly) TLBounds visibleBounds;

@property (nonatomic, readonly) CGSize millimeterSize;
@property (nonatomic, readonly) CGSize unscaledMillimeterSize;
@property (nonatomic, readonly) CGSize significantVisualSize;
@property (nonatomic, readonly) CGSize significantInteractiveSize;

- (CGPoint)convertWindowPointToMap:(NSPoint)windowPoint;
- (NSPoint)convertMapPointToWindow:(CGPoint)mapPoint;

@end

