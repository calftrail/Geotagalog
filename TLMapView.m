//
//  TLMapView.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLMapView.h"

#import "TLMapView+HostInternals.h"

#import "TLTrackingManager.h"

#import <QuartzCore/QuartzCore.h>

#import "TLCocoaToolbag.h"
#include "TLGeometry.h"
#include "TLProjectionInfo.h"

#import "TLMapLayer.h"
#import "TLInteractiveMapLayer.h"
#import "TLMapLayer+HostInternals.h"


@interface TLMapView ()
- (void)setMapLayersNeedDisplay;

- (CGAffineTransform)transformFromMapToBackingLayer;
- (CGAffineTransform)transformFromMapToView;
- (CGSize)screenPixelsPerMillimeter;
- (void)invalidateDisplaySizeCache;
- (void)unregisterLayerHosting:(TLMapLayer*)layer;

@property (nonatomic, retain) NSEvent* eventForDrag;

+ (TLCoordinate)defaultCenterCoordinate;
+ (TLProjectionRef)createDefaultProjectionWithCenter:(TLCoordinate)centerCoord;
+ (TLBounds)defaultBoundsForProjection:(TLProjectionRef)proj;
@end


// this class is to avoid retain cycle between MapView.layer.layoutManager<->MapView
@interface TLMapViewLayoutHelper : NSObject {
@private
	TLMapView* mapView;
}
@property (nonatomic, assign) TLMapView* mapView;
@end

@implementation TLMapViewLayoutHelper
@synthesize mapView;
- (void)layoutSublayersOfLayer:(CALayer*)layer {
	[[self mapView] layoutSublayersOfLayer:layer];
}
@end


@implementation TLMapView

#pragma mark Lifecycle

- (void)awakeFromNib {
	// Set up layer-hosting
	[self setLayer:[rootLayer autorelease]];
	[self setWantsLayer:YES];
	TLMapViewLayoutHelper* layoutHelper = [[TLMapViewLayoutHelper new] autorelease];
	[layoutHelper setMapView:self];
	[rootLayer setLayoutManager:layoutHelper];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		rootLayer = [[CALayer layer] retain];	// autoreleased in awakeFromNib
		[rootLayer setDelegate:self];
		mapLayers = [[NSMutableArray array] retain];
		mapLayerBackingInfo = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
		layerTrackingManagers = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
		
		TLCoordinate defaultCenter = [[self class] defaultCenterCoordinate];
		projection = [[self class] createDefaultProjectionWithCenter:defaultCenter];
		desiredBounds = [[self class] defaultBoundsForProjection:projection];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	TLProjectionRelease(projection);
	for (TLMapLayer* layer in mapLayers) {
		[self unregisterLayerHosting:layer];
	}
	[mapLayers release];
	[mapLayerBackingInfo release];
	[layerTrackingManagers release];
	[eventForDrag release];
	[super dealloc];
}


#pragma mark Defaults

+ (TLCoordinate)defaultCenterCoordinate {
	return TLCoordinateMake(0.0, 10.0);
}

+ (TLProjectionRef)createDefaultProjectionWithCenter:(TLCoordinate)centerCoord {
	TLProjectionName worldName = TLProjectionNameRobinson;
	TLProjectionGeoidRef worldGeoid = TLProjectionGeoidWGS84;
	TLMutableProjectionParametersRef worldParams = TLProjectionParametersCreateMutable();
	TLProjectionParametersSetLatitudeOfOrigin(worldParams, centerCoord.lat);
	TLProjectionParametersSetLongitudeOfOrigin(worldParams, centerCoord.lon);
	TLProjectionError err = TLProjectionErrorNone;
	TLProjectionRef proj = TLProjectionCreate(worldName, worldGeoid, worldParams, &err);
	TLProjectionParametersRelease(worldParams);
	if (err && proj) {
		TLProjectionRelease(proj);
		proj = NULL;
	}
	return proj;
}

+ (TLBounds)defaultBoundsForProjection:(TLProjectionRef)proj {
	return TLProjectionInfoDefaultBounds(proj);
}


#pragma mark Accessors

@synthesize eventForDrag;

- (void)setProjection:(TLProjectionRef)newMapProjection {
	if (newMapProjection == projection) return;
	TLProjectionRelease(projection);
	projection = TLProjectionCopy(newMapProjection);
	[self setMapLayersNeedDisplay];
}

- (TLBounds)desiredBounds {
	return desiredBounds;
}

- (void)setDesiredBounds:(TLBounds)newDesiredBounds {
	desiredBounds = newDesiredBounds;
	[self setMapLayersNeedDisplay];
}

- (id < TLMapInfo >)currentMapInfo {
	return self;
}


#pragma mark Map info accessors

- (TLProjectionRef)projection {
	return projection;
}

- (TLBounds)visibleBounds {
	CGAffineTransform viewToMap = CGAffineTransformInvert([self transformFromMapToView]);
	return CGRectApplyAffineTransform(NSRectToCGRect([self bounds]), viewToMap);
}

- (CGSize)millimeterSize {
	CGFloat userScale = [[self window] userSpaceScaleFactor];
	CGSize unscaledMillimeterSize = [self unscaledMillimeterSize];
	return CGSizeMake(unscaledMillimeterSize.width * userScale,
					  unscaledMillimeterSize.height * userScale);
}

- (CGSize)unscaledMillimeterSize {
	CGSize mapUnitSize = CGSizeMake(1.0f, 1.0f);
	CGAffineTransform mapToBackingLayer = [self transformFromMapToBackingLayer];
	CGSize pixelsPerUnit = CGSizeApplyAffineTransform(mapUnitSize, mapToBackingLayer);
	CGSize pixelsPerMillimeter = [self screenPixelsPerMillimeter];
	
	double unitsPerMillimeterWidth = pixelsPerMillimeter.width / pixelsPerUnit.width;
	double unitsPerMillimeterHeight = pixelsPerMillimeter.height / pixelsPerUnit.height;
	return CGSizeMake((CGFloat)unitsPerMillimeterWidth, (CGFloat)unitsPerMillimeterHeight);
}

- (CGSize)significantVisualSize {
	NSSize basePixelSize = NSMakeSize(1.0f, 1.0f);
	CGSize viewPixelSize = NSSizeToCGSize([self convertSizeFromBase:basePixelSize]);
	CGAffineTransform viewToMap = CGAffineTransformInvert([self transformFromMapToView]);
	return CGSizeApplyAffineTransform(viewPixelSize, viewToMap);
}

- (CGSize)significantInteractiveSize {
	return [self significantVisualSize];
}

- (CGPoint)convertWindowPointToMap:(NSPoint)windowPoint {
	NSPoint pointInView = [self convertPoint:windowPoint fromView:nil];
	CGAffineTransform viewToMap = CGAffineTransformInvert([self transformFromMapToView]);
	return CGPointApplyAffineTransform(NSPointToCGPoint(pointInView), viewToMap);
}

- (NSPoint)convertMapPointToWindow:(CGPoint)mapPoint {
	CGPoint pointInView = CGPointApplyAffineTransform(mapPoint, [self transformFromMapToView]);
	return [self convertPoint:NSPointFromCGPoint(pointInView) toView:nil];
}


#pragma mark Notification handling

- (void)viewWillMoveToWindow:(NSWindow*)newWindow {
	NSWindow* oldWindow = [self window];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidChangeScreenNotification
												  object:oldWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowScreenChanged:)
												 name:NSWindowDidChangeScreenNotification
											   object:newWindow];
	[self invalidateDisplaySizeCache];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidBecomeKeyNotification
												  object:oldWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateActive:)
												 name:NSWindowDidBecomeKeyNotification
											   object:newWindow];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidResignKeyNotification
												  object:oldWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateActive:)
												 name:NSWindowDidResignKeyNotification
											   object:newWindow];
}

- (void)windowScreenChanged:(NSNotification*)notification {
	(void)notification;
	[self invalidateDisplaySizeCache];
	[self setMapLayersNeedDisplay];
}

- (void)updateActive:(NSNotification*)notification {
	(void)notification;
	BOOL isActive = ([[self window] isKeyWindow] && [[self window] firstResponder] == self);
	for (TLMapLayer* layer in mapLayers) {
		[layer setActive:isActive];
	}
}

- (BOOL)becomeFirstResponder {
	[self updateActive:nil];
	return YES;
}

- (BOOL)resignFirstResponder {
	[self performSelector:@selector(updateActive:) withObject:nil afterDelay:0.0];
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}


#pragma mark Coordinate transform helpers

- (CGAffineTransform)transformFromMapToBackingLayer {
	CGRect mapLayerBounds = [rootLayer bounds];
	return TLTransformFromRectToRect(desiredBounds, mapLayerBounds, TLAspectPadToFit);
}

- (CGAffineTransform)transformFromMapToView {
	return TLTransformFromRectToRect(desiredBounds, NSRectToCGRect([self bounds]), TLAspectPadToFit);
}

- (CGSize)screenPixelsPerMillimeter {
	/* NOTE: TLScreenPixelsPerMillimeter() is an expensive function, so we prefer to use a cached result */
	if (CGSizeEqualToSize(cachedScreenSizeInMillimeters, CGSizeZero)) {
		cachedScreenSizeInMillimeters = TLScreenPixelsPerMillimeter([[self window] screen]);
	}
	return cachedScreenSizeInMillimeters;
}

- (void)invalidateDisplaySizeCache {
	cachedScreenSizeInMillimeters = CGSizeZero;
}


#pragma mark Backing layer management

- (CALayer*)backingLayerForMapLayer:(TLMapLayer*)mapLayer {
	return [mapLayerBackingInfo objectForKey:mapLayer];
}

- (TLMapLayer*)mapLayerForBackingLayer:(CALayer*)layer {
	return [mapLayerBackingInfo objectForKey:layer];
}

- (void)layoutSublayersOfLayer:(CALayer*)layer {
	//printf("layoutSublayersOfLayer: %p\n", layer);
	if (layer == rootLayer) {
		for (CALayer* sublayer in [layer sublayers]) {
			[sublayer setFrame:[layer frame]];
		}
	}
}

- (void)setMapLayersNeedDisplay {
	for (TLMapLayer* mapLayer in mapLayers) {
		[self setLayerNeedsDisplay:mapLayer];
	}
}

- (CALayer*)makeBackingLayerForLayer:(TLMapLayer*)mapLayer {
	CALayer* maplayerBacking = [CALayer layer];
	[maplayerBacking setDelegate:self];
	[maplayerBacking setNeedsDisplayOnBoundsChange:YES];
	[maplayerBacking setNeedsDisplay];
	[mapLayerBackingInfo setObject:maplayerBacking forKey:mapLayer];
	[mapLayerBackingInfo setObject:mapLayer forKey:maplayerBacking];
	return maplayerBacking;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	(void)context;
	
	if ([keyPath isEqualToString:@"hidden"]) {
		TLMapLayer* mapLayer = (TLMapLayer*)object;
		NSNumber* newHidden = [change objectForKey:NSKeyValueChangeNewKey];
		NSAssert(newHidden, @"Layer value observation improperly configured");
		CALayer* backingLayer = [self backingLayerForMapLayer:mapLayer];
		[backingLayer setHidden:[newHidden boolValue]];
	}
}

- (void)registerLayerHosting:(TLMapLayer*)layer {
	[layer setHost:self];
	NSKeyValueObservingOptions kvoOptions= (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew);
	[layer addObserver:self forKeyPath:@"hidden" options:kvoOptions context:NULL];
	if ([layer isKindOfClass:[TLInteractiveMapLayer class]]) {
		[self updateDragTypesForLayer:(TLInteractiveMapLayer*)layer];
	}
}

- (void)unregisterLayerHosting:(TLMapLayer*)layer {
	[layer setHost:nil];
	[layer removeObserver:self forKeyPath:@"hidden"];
	TLTrackingManager* layerTrackingManager = [layerTrackingManagers objectForKey:layer];
	if (layerTrackingManager) {
		[layerTrackingManager performSelector:@selector(actualSetActiveTrackingZones:) withObject:nil];
		[layerTrackingManager setDelegate:nil];
		[layerTrackingManagers removeObjectForKey:layer];
		[layerTrackingManagers removeObjectForKey:layerTrackingManager];
	}
	if ([layer isKindOfClass:[TLInteractiveMapLayer class]]) {
		[self updateDragTypesForLayer:nil];
	}
}

- (void)insertLayer:(TLMapLayer*)layer atIndex:(NSUInteger)idx {
	if ([layer host] == self) {
		// adjust idx if layer will be removed from beneath
		NSUInteger prevIdx = [mapLayers indexOfObjectIdenticalTo:layer];
		if (idx > prevIdx) {
			idx -= 1;
		}
	}
	[[[layer retain] autorelease] removeFromHost];
	[mapLayers insertObject:layer atIndex:idx];
	CALayer* mapLayerBacking = [self makeBackingLayerForLayer:layer];
	[rootLayer insertSublayer:mapLayerBacking atIndex:(unsigned)idx];
	[self registerLayerHosting:layer];
}

- (void)replaceLayer:(TLMapLayer*)oldLayer withLayer:(TLMapLayer*)newLayer {
	CALayer* oldMapLayerBacking = [self backingLayerForMapLayer:oldLayer];
	NSAssert(oldMapLayerBacking, @"Replaced layer must exist");
	CALayer* newMapLayerBacking = [self makeBackingLayerForLayer:newLayer];
	[rootLayer replaceSublayer:oldMapLayerBacking with:newMapLayerBacking];
	NSUInteger oldMapLayerIndex = [mapLayers indexOfObjectIdenticalTo:oldLayer];
	[mapLayers replaceObjectAtIndex:oldMapLayerIndex withObject:newLayer];
	[self unregisterLayerHosting:oldLayer];
	[self registerLayerHosting:newLayer];
}

- (void)mainRemoveLayer:(TLMapLayer*)layer {
	[self unregisterLayerHosting:layer];
	CALayer* layerBacking = [self backingLayerForMapLayer:layer];
	[layerBacking removeFromSuperlayer];
	[mapLayerBackingInfo removeObjectForKey:layer];
	[mapLayerBackingInfo removeObjectForKey:layerBacking];
	[mapLayers removeObject:layer];
}

- (void)insertLayer:(TLMapLayer*)layer aboveLayer:(TLMapLayer*)existingLayer {
	NSUInteger existingIndex = [mapLayers indexOfObjectIdenticalTo:existingLayer];
	NSAssert(existingIndex != NSNotFound, @"Reference layer must exist");
	[self insertLayer:layer atIndex:(existingIndex+1)];
}

- (void)insertLayer:(TLMapLayer*)layer belowLayer:(TLMapLayer*)existingLayer {
	NSUInteger existingIndex = [mapLayers indexOfObjectIdenticalTo:existingLayer];
	NSAssert(existingIndex != NSNotFound, @"Reference layer must exist");
	[self insertLayer:layer atIndex:existingIndex];
}

- (void)addLayer:(TLMapLayer*)layer {
	[self insertLayer:layer atIndex:[mapLayers count]];
}

- (id < CAAction >)actionForLayer:(CALayer*)layer forKey:(NSString*)key {
	(void)layer;
	
	/* NOTE: implementing this method seems to *add* a fade transition effect
	 on the @"contents" key that is otherwise not present in redraws. (Not sure
	 why.) We explicitly block it for now, though it may be desirable. */
	if ([key isEqualToString:@"bounds"] ||
		[key isEqualToString:@"position"] ||
		[key isEqualToString:@"contents"])
	{
		// don't animate frame change
		return (id < CAAction >)[NSNull null];
	}
	else return nil;
}


#pragma mark Drawing

- (void)drawLayer:(CALayer*)backingLayer inContext:(CGContextRef)ctx {
	TLMapLayer* mapLayer = [self mapLayerForBackingLayer:backingLayer];
	
	// set context's transformation matrix so that projected points fall in view
	CGContextSaveGState(ctx);
	CGAffineTransform mapToLayer = [self transformFromMapToBackingLayer];
	CGContextConcatCTM(ctx, mapToLayer);
	
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	[mapLayer drawInContext:ctx withInfo:mapInfo];
	
	CGContextRestoreGState(ctx);
}


#pragma mark Mouse dispatch

- (TLInteractiveMapLayer*)layerHitByEvent:(NSEvent*)mouseEvent withInfo:(id < TLMapInfo >)mapInfo {
	BOOL scrollEvent = ([mouseEvent type] == NSScrollWheel);
	TLInteractiveMapLayer* hitLayer = nil;
	NSPoint mouseInWindow = [mouseEvent locationInWindow];
	for (TLMapLayer* layer in [mapLayers reverseObjectEnumerator]) {
		if ([layer isKindOfClass:[TLInteractiveMapLayer class]]) {
			TLInteractiveMapLayer* interactiveLayer = (TLInteractiveMapLayer*)layer;
			BOOL layerHit = (scrollEvent ?
							 [interactiveLayer wantsScrollEvents] :
							 [interactiveLayer hitTest:mouseInWindow withEvent:mouseEvent withInfo:mapInfo]);
			if (layerHit) {
				hitLayer = interactiveLayer;
				break;
			}
		}
	}
	return hitLayer;
}

- (BOOL)mouseDownCanMoveWindow {
	// see http://www.cocoabuilder.com/archive/message/cocoa/2007/11/28/194080	
	return NO;
}

- (void)mouseDown:(NSEvent*)mouseEvent {
	[self setEventForDrag:mouseEvent];
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	currentMouseLayer = [self layerHitByEvent:mouseEvent withInfo:mapInfo];
	[currentMouseLayer mouseDown:mapInfo withEvent:mouseEvent];
}

- (void)mouseDragged:(NSEvent*)mouseEvent {
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	[currentMouseLayer mouseDragged:mapInfo withEvent:mouseEvent];
}

- (void)mouseUp:(NSEvent*)mouseEvent {
	[self setEventForDrag:nil];
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	[currentMouseLayer mouseUp:mapInfo withEvent:mouseEvent];
	currentMouseLayer = nil;
}

- (void)flagsChanged:(NSEvent*)event {
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	[currentMouseLayer flagsChanged:mapInfo withEvent:event];
}

- (void)scrollWheel:(NSEvent*)mouseEvent {
	id < TLMapInfo > mapInfo = [self currentMapInfo];
	TLInteractiveMapLayer* hitLayer = [self layerHitByEvent:mouseEvent withInfo:mapInfo];
	[hitLayer scrollWheel:mapInfo withEvent:mouseEvent];
}

-(void)magnifyWithEvent:(NSEvent *)gestureEvent {
	(void)gestureEvent;
	
	/* see http://www.cocoadev.com/index.pl?MultiTouchTrackpad and
	 http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html */
}


#pragma mark Layer drag destination handling

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
	if (currentMouseLayer) {
		// skip search below if the mouse is re-entering in the same session
		id < TLMapInfo > mapInfo= [self currentMapInfo];
		return [currentMouseLayer draggingEntered:sender withInfo:mapInfo];
	}
	
	// topmost layer with type matching pasteboard will handle this drop
	NSPasteboard* dragPasteboard = [sender draggingPasteboard];
	NSEnumerator* layerEnum = [mapLayers reverseObjectEnumerator];
	TLInteractiveMapLayer* targetLayer = nil;
	for (TLMapLayer* mapLayer in layerEnum) {
		if (![mapLayer isKindOfClass:[TLInteractiveMapLayer class]]) continue;
		TLInteractiveMapLayer* interactiveLayer = (TLInteractiveMapLayer*)mapLayer;
		NSArray* layerTypes = [interactiveLayer registeredDragTypes];
		if ([dragPasteboard availableTypeFromArray:layerTypes]) {
			targetLayer = interactiveLayer;
			break;
		}
	}
	currentMouseLayer = targetLayer;
	
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	return [currentMouseLayer draggingEntered:sender withInfo:mapInfo];
}

- (BOOL)wantsPeriodicDraggingUpdates {
	// note that this returns NO if dragDestinationLayer is nil
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	return [currentMouseLayer wantsPeriodicDraggingUpdates:mapInfo];
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender {
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	// returns NSDragOperationNone if no destination layer
	return [currentMouseLayer draggingUpdated:sender withInfo:mapInfo];
}

- (void)draggingExited:(id < NSDraggingInfo >)sender {
	/* NOTE: this method is not called just when the mouse leaves, but essentially,
	 whenever performDragOperation will not be called instead. */
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	[currentMouseLayer draggingExited:sender withInfo:mapInfo];
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	// returns NO if no destination layer
	return [currentMouseLayer prepareForDropOperation:sender withInfo:mapInfo];
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	// return NO if no destination layer
	return [currentMouseLayer performDropOperation:sender withInfo:mapInfo];
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	[currentMouseLayer concludeDropOperation:sender withInfo:mapInfo];
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender {
	/* NOTE: The Leopard release notes indicate this is implemented despite other
	 documentation to the contrary. Testing on 10.5.4, this message is always received
	 for every drag session initiated via draggingEntered:, and is always the last
	 message received. See rdar://6250983 for notes about this documentation discrepancy.
	 Given this behaviour, this is the only place we should unset dragDestinationLayer. */
	id < TLMapInfo > mapInfo= [self currentMapInfo];
	[currentMouseLayer draggingEnded:sender withInfo:mapInfo];
	currentMouseLayer = nil;
}

@end


@implementation TLMapView (TLMapViewHostInternals)

- (void)removeLayer:(TLMapLayer*)layer {
	[self mainRemoveLayer:layer];
}

- (void)setLayerNeedsDisplay:(TLMapLayer*)layer {
	CALayer* backingLayer = [self backingLayerForMapLayer:layer];
	[backingLayer setNeedsDisplay];
}


#pragma mark Track zone management

- (void)trackingManager:(TLTrackingManager*)manager
   replaceTrackingAreas:(NSArray*)oldTrackingAreas
	  withTrackingAreas:(NSArray*)newTrackingAreas
{
	(void)manager;
	
	// NOTE: this is to try work around cursor reset issues when adding trackingAreas
	[[NSCursor currentCursor] push];
	for (NSTrackingArea* oldArea in oldTrackingAreas) {
		[self removeTrackingArea:oldArea];
	}
	for (NSTrackingArea* newArea in newTrackingAreas) {
		[self addTrackingArea:newArea];
	}
	[NSCursor pop];
}

- (void)trackingManager:(TLTrackingManager*)manager
	  mouseDidEnterZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil
{
	TLInteractiveMapLayer* layer = [layerTrackingManagers objectForKey:manager];
	[layer mouseEntered:[self currentMapInfo] trackingZone:trackZone withEvent:eventOrNil];
}

/*
- (void)trackingManager:(TLTrackingManager*)manager
	 mouseDidMoveInZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil
{
	TLInteractiveMapLayer* layer = [layerTrackingManagers objectForKey:manager];
	[layer mouseMoved:[self currentMapInfo] trackingZone:trackZone withEvent:eventOrNil];
}
 */

- (void)trackingManager:(TLTrackingManager*)manager
	   mouseDidExitZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil
{
	TLInteractiveMapLayer* layer = [layerTrackingManagers objectForKey:manager];
	[layer mouseExited:[self currentMapInfo] trackingZone:trackZone withEvent:eventOrNil];
}


- (BOOL)trackingManager:(TLTrackingManager*)manager
		 shouldUsePoint:(CGPoint*)zonePointPtr
		 forWindowPoint:(NSPoint)windowPoint
{
	(void)manager;
	
	CGAffineTransform viewToMap = CGAffineTransformInvert([self transformFromMapToView]);
	NSPoint viewPoint = [self convertPoint:windowPoint fromView:nil];
	*zonePointPtr = CGPointApplyAffineTransform(NSPointToCGPoint(viewPoint), viewToMap);
	return YES;
}

- (BOOL)trackingManager:(TLTrackingManager*)manager
   shouldUseWindowPoint:(NSPoint*)windowPointPtr
{
	(void)manager;
	
	*windowPointPtr = [[self window] mouseLocationOutsideOfEventStream];
	return YES;
}

- (NSRect)trackingManager:(TLTrackingManager*)manager
	 clippedRectForBounds:(CGRect)zoneBounds
{
	(void)manager;
	
	CGAffineTransform mapToView = [self transformFromMapToView];
	CGRect boundsInView = CGRectApplyAffineTransform(zoneBounds, mapToView);
	return NSIntersectionRect(NSRectFromCGRect(boundsInView), [self bounds]);
}

- (NSArray*)activeTrackingZonesForLayer:(TLInteractiveMapLayer*)layer {
	return [layerTrackingManagers objectForKey:layer];
}

- (void)setActiveTrackingZones:(NSArray*)trackingZones forLayer:(TLInteractiveMapLayer*)layer {
	TLTrackingManager* layerManager = [layerTrackingManagers objectForKey:layer];
	if (!layerManager) {
		layerManager = [[TLTrackingManager new] autorelease];
		[layerManager setDelegate:self];
		[layerTrackingManagers setObject:layerManager forKey:layer];
		[layerTrackingManagers setObject:layer forKey:layerManager];
	}
	[layerManager setActiveTrackingZones:trackingZones];
}


#pragma mark Layer drag destination

- (void)updateDragTypesForLayer:(TLInteractiveMapLayer*)layer {
	(void)layer;
	
	// walk all interactive layers collecting drag types
	NSMutableSet* combinedTypes = [NSMutableSet set];
	for (TLMapLayer* mapLayer in mapLayers) {
		if (![mapLayer isKindOfClass:[TLInteractiveMapLayer class]]) continue;
		TLInteractiveMapLayer* interactiveLayer = (TLInteractiveMapLayer*)mapLayer;
		NSArray* layerTypes = [interactiveLayer registeredDragTypes];
		[combinedTypes addObjectsFromArray:layerTypes];
	}
	
	[self unregisterDraggedTypes];	// this may not be necessary?
	NSArray* viewDragTypes = [combinedTypes allObjects];
	[self registerForDraggedTypes:viewDragTypes];
}

#pragma mark Layer drag source handling

- (NSPasteboard*)dragPasteboardForLayer:(TLInteractiveMapLayer*)layer {
	(void)layer;
	if (![self eventForDrag]) {
		return nil;
	}
	return [NSPasteboard pasteboardWithName:NSDragPboard];
}

- (void)dragFromLayer:(TLInteractiveMapLayer*)layer
			withImage:(CGImageRef)dragImage
			   anchor:(CGPoint)imagePoint
			slideBack:(BOOL)shouldSlideBack
{
	NSAssert([self eventForDrag], @"Layer initiated drag at improper time");
	NSImage* cocoaImage = TLNSImageFromCGImage(dragImage, TLDragTransparencyDefault);
	
	// calculate image lower-left location in view
	NSPoint mouseDownInWindow = [[self eventForDrag] locationInWindow];
	NSPoint imageCornerInWindow = NSMakePoint((mouseDownInWindow.x - imagePoint.x),
											  (mouseDownInWindow.y - imagePoint.y));
	NSPoint imageCornerInView = [self convertPoint:imageCornerInWindow fromView:nil];
	
	NSPasteboard* dragPasteboard = [self dragPasteboardForLayer:layer];
	[self dragImage:cocoaImage
				 at:imageCornerInView
			 offset:NSZeroSize
			  event:[self eventForDrag]
		 pasteboard:dragPasteboard
			 source:layer
		  slideBack:shouldSlideBack];
}

@end


