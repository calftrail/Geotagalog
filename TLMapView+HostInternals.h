/*
 *  TLMapView+HostInternals.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 9/6/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

@class TLMapLayer;
@class TLInteractiveMapLayer;
@class TLSublayerHostingMapLayer;
@protocol TLMapInfo;

@interface TLMapView (TLMapViewHostInternals)

- (void)removeLayer:(TLMapLayer*)layer;

- (void)setLayerNeedsDisplay:(TLMapLayer*)layer;

- (NSArray*)activeTrackingZonesForLayer:(TLInteractiveMapLayer*)layer;
- (void)setActiveTrackingZones:(NSArray*)trackingZones forLayer:(TLInteractiveMapLayer*)layer;

- (NSPasteboard*)dragPasteboardForLayer:(TLInteractiveMapLayer*)layer;
- (void)dragFromLayer:(TLInteractiveMapLayer*)layer
			withImage:(CGImageRef)dragImage
			   anchor:(CGPoint)imagePoint
			slideBack:(BOOL)shouldSlideBack;


- (void)updateDragTypesForLayer:(TLInteractiveMapLayer*)layer;

@end
