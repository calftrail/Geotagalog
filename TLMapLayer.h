//
//  TLMapLayer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLMapInfo.h"

@class TLMapView;


@interface TLMapLayer : NSObject {
@private
	BOOL active;
	BOOL hidden;
	TLMapView* host;
}

- (void)setNeedsDisplay;

//@property (nonatomic, assign) CGFloat opacity;
//@property (nonatomic, assign, getter=isOpaque) BOOL opaque;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;

@property (nonatomic, assign, getter=isActive) BOOL active;

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo;
// animation "notifications" would go here

- (void)removeFromHost;

@end

