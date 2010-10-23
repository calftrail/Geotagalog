//
//  TLInteractiveMapLayer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLMapLayer.h"

#import "TLTrackingZone.h"

@interface TLInteractiveMapLayer : TLMapLayer {
@private
	NSArray* registeredDragTypes;
}

// mouse events
- (BOOL)hitTest:(NSPoint)windowPoint withEvent:(NSEvent*)mouseEventOrNil withInfo:(id < TLMapInfo >)mapInfo;
- (void)mouseDown:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent;
- (void)mouseDragged:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent;
- (void)mouseUp:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent;

- (void)flagsChanged:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)event;

- (BOOL)wantsScrollEvents;
- (void)scrollWheel:(id < TLMapInfo >)mapInfo withEvent:(NSEvent*)mouseEvent;

// tracking zone events
@property (nonatomic, copy) NSArray* activeTrackingZones;
- (void)mouseEntered:(id < TLMapInfo >)mapInfo trackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEventOrNil;
//- (void)mouseMoved:(id < TLMapInfo >)mapInfo inTrackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEventOrNil;
- (void)mouseExited:(id < TLMapInfo >)mapInfo trackingZone:(TLTrackingZone*)zone withEvent:(NSEvent*)mouseEventOrNil;

// drag and drop source
- (NSPasteboard*)dragPasteboard;
- (void)dragWithImage:(CGImageRef)image anchor:(CGPoint)imagePoint slideBack:(BOOL)shouldSlideBack;
- (NSDragOperation)dragSourceOperationMaskForLocal:(BOOL)isLocal;
- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination;
- (void)dragEndedWithOperation:(NSDragOperation)operation;

// drag and drop destination
@property (nonatomic, copy) NSArray* registeredDragTypes;
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (BOOL)wantsPeriodicDraggingUpdates:(id < TLMapInfo >)mapInfo;
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (void)draggingExited:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (BOOL)prepareForDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (BOOL)performDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (void)concludeDropOperation:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;
- (void)draggingEnded:(id < NSDraggingInfo >)dropInfo withInfo:(id < TLMapInfo >)mapInfo;

@end
