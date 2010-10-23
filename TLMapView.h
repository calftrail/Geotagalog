//
//  TLMapView.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLProjection.h"
#import "TLBounds.h"

@class TLMapLayer;
@class TLInteractiveMapLayer;

#define CHECKPROTOCOL
#ifdef CHECKPROTOCOL
// NOTE: this is to get protocol check despite compiler bug rdar://problem/6284845
#import "TLMapInfo.h"
@interface TLMapView : NSView < TLMapInfo > {
#undef CHECKPROTOCOL
#else
@interface TLMapView : NSView {
#endif /* CHECKPROTOCOL */
@private
	// cartographic parameters
	TLProjectionRef projection;
	TLBounds desiredBounds;
	
	// layer hosting
	NSMutableArray* mapLayers;
	NSMapTable* mapLayerBackingInfo;
	__weak CALayer* rootLayer;
	
	// tracking zone management
	NSMapTable* layerTrackingManagers;
	
	// other stuff
	CGSize cachedScreenSizeInMillimeters;
	__weak TLInteractiveMapLayer* currentMouseLayer;
	NSEvent* eventForDrag;
}

@property (nonatomic, assign) TLProjectionRef projection;		// "copy"
@property (nonatomic, assign) TLBounds desiredBounds;

@property (nonatomic, readonly) TLBounds visibleBounds;

- (void)addLayer:(TLMapLayer*)layer;
- (void)replaceLayer:(TLMapLayer*)oldLayer withLayer:(TLMapLayer*)newLayer;
- (void)insertLayer:(TLMapLayer*)layer aboveLayer:(TLMapLayer*)existingLayer;
- (void)insertLayer:(TLMapLayer*)layer belowLayer:(TLMapLayer*)existingLayer;

@end
