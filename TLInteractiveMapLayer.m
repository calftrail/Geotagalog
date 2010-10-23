//
//  TLInteractiveMapLayer.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLInteractiveMapLayer.h"
#import "TLMapLayer+HostInternals.h"

#import "TLMapView.h"
#import "TLMapView+HostInternals.h"

#import "TLTrackingZone.h"

#import <QuartzCore/QuartzCore.h>

@implementation TLInteractiveMapLayer

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		// ...
	}
	return self;
}

- (void)dealloc {
	[registeredDragTypes release];
	[super dealloc];
}


#pragma mark Tracking zone event methods

- (NSArray*)activeTrackingZones {
	return [[self host] activeTrackingZonesForLayer:self];
}

- (void)setActiveTrackingZones:(NSArray*)newTrackingZones {
	[[self host] setActiveTrackingZones:newTrackingZones forLayer:self];
}

- (void)mouseEntered:(id < TLMapInfo >)mapInfo trackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEvent {
	(void)mapInfo;
	(void)zone;
	(void)mouseEvent;
	// (default implementation does nothing)
}

/*
- (void)mouseMoved:(id < TLMapInfo >)mapInfo inTrackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEvent {
	(void)mapInfo;
	(void)zone;
	(void)mouseEvent;
	// (default implementation does nothing)
}
 */

- (void)mouseExited:(id < TLMapInfo >)mapInfo trackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEvent {
	(void)mapInfo;
	(void)zone;
	(void)mouseEvent;
	// (default implementation does nothing)
}


#pragma mark Event responder methods

- (BOOL)hitTest:(NSPoint)windowPoint
	  withEvent:(NSEvent*)mouseEventOrNil
	   withInfo:(id < TLMapInfo >)mapInfo
{
	(void)windowPoint;
	(void)mouseEventOrNil;
	(void)mapInfo;
	return NO;
}

- (void)mouseDown:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	(void)mapInfo;
}

- (void)mouseDragged:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	(void)mapInfo;
}

- (void)mouseUp:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	(void)mapInfo;
}

- (void)flagsChanged:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)event {
	(void)event;
	(void)mapInfo;
}

- (BOOL)wantsScrollEvents {
	return NO;
}

- (void)scrollWheel:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	(void)mapInfo;
}


#pragma mark Drag source methods (internal)

- (NSPasteboard*)dragPasteboard {
	return [[self host] dragPasteboardForLayer:self];
}

- (void)dragWithImage:(CGImageRef)image anchor:(CGPoint)imagePoint slideBack:(BOOL)shouldSlideBack {
	[[self host] dragFromLayer:self withImage:image anchor:imagePoint slideBack:shouldSlideBack];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	// wrap renamed layer method
	return [self dragSourceOperationMaskForLocal:isLocal];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	(void)anImage;
	(void)aPoint;
	// wrap refactored layer method
	[self dragEndedWithOperation:operation];
}


#pragma mark Drag source methods (default implementations)

- (NSDragOperation)dragSourceOperationMaskForLocal:(BOOL)isLocal {
	(void)isLocal;
	return NSDragOperationNone;
}

- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination {
	// NOTE: subclass *must* override if promise drag possible
	[self doesNotRecognizeSelector:_cmd];
	
	// suppress compiler warnings
	(void)dropDestination;
	return nil;
}

- (void)dragEndedWithOperation:(NSDragOperation)operation {
	(void)operation;
}


#pragma mark Drag destination methods

@synthesize registeredDragTypes;

- (void)setRegisteredDragTypes:(NSArray*)newRegisteredDragTypes {
	[registeredDragTypes autorelease];
	registeredDragTypes = [newRegisteredDragTypes copy];
	[[self host] updateDragTypesForLayer:self];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	return NSDragOperationNone;
}

- (BOOL)wantsPeriodicDraggingUpdates:(id < TLMapInfo >)mapInfo {
	(void)mapInfo;
	// NOTE: when animation is enabled for map layers, this should be YES instead
	return NO;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	// default implementation does nothing
}

- (BOOL)prepareForDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	return NO;
}

- (BOOL)performDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	return NO;
}

- (void)concludeDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo{
	(void)dropInfo;
	(void)mapInfo;
	// default implementation does nothing
}

- (void)draggingEnded:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo {
	(void)dropInfo;
	(void)mapInfo;
	// default implementation does nothing
}

@end
