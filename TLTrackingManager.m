//
//  TLTrackingManager.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLTrackingManager.h"
#import "TLTrackingZone.h"


@interface TLTrackingManager ()
@property (nonatomic, retain) NSMutableSet* enteredIdentities;
- (BOOL)getZonePoint:(CGPoint*)zonePointPtr forEvent:(NSEvent*)eventOrNil;
- (NSArray*)filterZones:(NSArray*)zones containingPoint:(CGPoint)point;
- (void)setCurrentlyEnteredZones:(NSArray*)newEnteredZones withEvent:(NSEvent*)eventOrNil;
- (void)performExitsBeforeActiveZones:(NSArray*)incomingActiveZones;
- (void)updateTrackingAreas;
@end

@implementation TLTrackingManager

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		enteredIdentities = [NSMutableSet new];
	}
	return self;
}

- (void)dealloc {
	[trackingAreas release];
	[activeTrackingZones release];
	[enteredIdentities release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize delegate;
@synthesize activeTrackingZones;
@synthesize enteredIdentities;

- (void)actualSetActiveTrackingZones:(NSArray*)newActiveTrackingZones {
	CGPoint zonePoint = CGPointZero;
	BOOL haveZonePoint = [self getZonePoint:&zonePoint forEvent:nil];
	if (haveZonePoint) {
		NSArray* newEnteredZones = [self filterZones:newActiveTrackingZones containingPoint:zonePoint];
		[self setCurrentlyEnteredZones:newEnteredZones withEvent:nil];
	}
	else {
		[self performExitsBeforeActiveZones:newActiveTrackingZones];
		// remaining entered zones wait until later event for update
	}
	
	[activeTrackingZones autorelease];
	activeTrackingZones = [newActiveTrackingZones copy];
	[self updateTrackingAreas];
}

- (void)setActiveTrackingZones:(NSArray*)newActiveTrackingZones {
	// NOTE: this is necessary lest the changes while drawing and cause ignored display requests
	[self performSelector:@selector(actualSetActiveTrackingZones:)
			   withObject:newActiveTrackingZones
			   afterDelay:0.0];
}

- (void)setTrackingAreas:(NSArray*)newTrackingAreas {
	if ([[self delegate] respondsToSelector:@selector(trackingManager:replaceTrackingAreas:withTrackingAreas:)]) {
		[[self delegate] trackingManager:self replaceTrackingAreas:trackingAreas withTrackingAreas:newTrackingAreas];
	}
	[trackingAreas autorelease];
	trackingAreas = [newTrackingAreas copy];
}

+ (NSTrackingAreaOptions)defaultTrackingAreaFlags {
	NSTrackingAreaOptions whichEvents = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
	NSTrackingAreaOptions whatTimes = NSTrackingActiveInActiveApp;
	return (whichEvents | whatTimes);
}


#pragma mark Delegate helpers

- (void)notifyZoneEntered:(TLTrackingZone*)zone withEvent:(NSEvent*)eventOrNil {
	if ([[self delegate] respondsToSelector:@selector(trackingManager:mouseDidEnterZone:withEvent:)]) {
		[[self delegate] trackingManager:self mouseDidEnterZone:zone withEvent:eventOrNil];
	}
}

- (void)notifyZoneMoved:(TLTrackingZone*)zone withEvent:(NSEvent*)eventOrNil {
	if ([[self delegate] respondsToSelector:@selector(trackingManager:mouseDidMoveInZone:withEvent:)]) {
		[[self delegate] trackingManager:self mouseDidMoveInZone:zone withEvent:eventOrNil];
	}
}

- (void)notifyZoneExited:(TLTrackingZone*)zone withEvent:(NSEvent*)eventOrNil {
	if ([[self delegate] respondsToSelector:@selector(trackingManager:mouseDidExitZone:withEvent:)]) {
		[[self delegate] trackingManager:self mouseDidExitZone:zone withEvent:eventOrNil];
	}
}

- (BOOL)getZonePoint:(CGPoint*)zonePointPtr forEvent:(NSEvent*)eventOrNil {
	if (!zonePointPtr) return NO;
	
	NSPoint windowPoint = NSZeroPoint;
	BOOL haveWindowPoint = NO;
	if (eventOrNil) {
		windowPoint = [eventOrNil locationInWindow];
		haveWindowPoint = YES;
	}
	else if ([[self delegate] respondsToSelector:@selector(trackingManager:shouldUseWindowPoint:)]) {
		haveWindowPoint = [[self delegate] trackingManager:self shouldUseWindowPoint:&windowPoint];
	}
	else if ([[self delegate] respondsToSelector:@selector(window)]) {
		id delegateWindow = [[self delegate] window];
		if ([delegateWindow respondsToSelector:@selector(mouseLocationOutsideOfEventStream)]) {
			windowPoint = [delegateWindow mouseLocationOutsideOfEventStream];
			haveWindowPoint = YES;
		}
	}
	
	if (!haveWindowPoint) return NO;
	
	BOOL haveZonePoint = NO;
	if ([[self delegate] respondsToSelector:@selector(trackingManager:shouldUsePoint:forWindowPoint:)]) {
		haveZonePoint = [[self delegate] trackingManager:self
										  shouldUsePoint:zonePointPtr
										  forWindowPoint:windowPoint];
	}
	else if ([[self delegate] respondsToSelector:@selector(convertPoint:fromView:)]) {
		*zonePointPtr = NSPointToCGPoint([[self delegate] convertPoint:windowPoint fromView:nil]);
		haveZonePoint = YES;
	}
	return haveZonePoint;
}

- (NSRect)trackingRectConvertedFromZoneBounds:(CGRect)zoneBounds {
	NSRect trackingRect = NSRectFromCGRect(zoneBounds);
	if ([[self delegate] respondsToSelector:@selector(trackingManager:clippedRectForBounds:)]) {
		trackingRect = [[self delegate] trackingManager:self clippedRectForBounds:zoneBounds];
	}
	else if ([[self delegate] isKindOfClass:[NSView class]]) {
		NSRect viewBounds = [[self delegate] bounds];
		NSIntersectionRect(trackingRect, viewBounds);
	}
	return trackingRect;
}


#pragma mark Zone management

- (void)updateTrackingAreas {
	CGRect unifiedTrackingArea = CGRectNull;
	for (TLTrackingZone* zone in [self activeTrackingZones]) {
		if (CGRectIsNull(unifiedTrackingArea)) {
			unifiedTrackingArea = [zone bounds];
		}
		else {
			unifiedTrackingArea = CGRectUnion(unifiedTrackingArea, [zone bounds]);
		}
	}
	if (CGRectIsNull(unifiedTrackingArea)) {
		[self setTrackingAreas:nil];
	}
	else {
		NSRect trackingRect = [self trackingRectConvertedFromZoneBounds:unifiedTrackingArea];
		NSTrackingAreaOptions options = [[self class] defaultTrackingAreaFlags];
		NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
																	options:options
																	  owner:self
																   userInfo:nil];
		[self setTrackingAreas:[NSArray arrayWithObject:trackingArea]];
		[trackingArea release];
	}
}

- (void)setCurrentlyEnteredZones:(NSArray*)newEnteredZones withEvent:(NSEvent*)eventOrNil {
	NSMutableSet* previousEnteredIdentities = [self enteredIdentities];
	NSMutableSet* currentEnteredIdentities = [NSMutableSet set];
	
	// process newEnteredZones, sending mouseEntered for any zone not previously entered
	for (TLTrackingZone* enteredZone in newEnteredZones) {
		id zoneIdentity = [enteredZone identity];
		[currentEnteredIdentities addObject:zoneIdentity];
		BOOL zonePreviouslyEntered = [previousEnteredIdentities containsObject:zoneIdentity];
		if (zonePreviouslyEntered) {
			// NOTE: any update is currently considered "movement"
			[self notifyZoneMoved:enteredZone withEvent:eventOrNil];
			// zones remaining in previous set will be "exited"
			[previousEnteredIdentities removeObject:zoneIdentity];
		}
		else {
			[self notifyZoneEntered:enteredZone withEvent:eventOrNil];
		}
	}
	
	// process all zones, sending mouseExited for any zone remaining in previously entered list
	NSArray* allZones = [self activeTrackingZones];
	for (TLTrackingZone* zone in allZones) {
		if (![previousEnteredIdentities count]) break;
		BOOL zonePreviouslyEntered = [previousEnteredIdentities containsObject:[zone identity]];
		if (zonePreviouslyEntered) {
			[self notifyZoneExited:zone withEvent:eventOrNil];
			[previousEnteredIdentities removeObject:[zone identity]];
		}
	}
	NSAssert1(![previousEnteredIdentities count],
			  @"Lost track of %lu tracking zone(s)",
			  (unsigned long)[previousEnteredIdentities count]);
	
	[self setEnteredIdentities:currentEnteredIdentities];
}

- (void)performExitsBeforeActiveZones:(NSArray*)incomingActiveZones {
	// for any previously entered zone, notify exit if not in new set or "moved" if is
	NSMutableSet* exitedIdentities = [[[self enteredIdentities] mutableCopy] autorelease];
	for (TLTrackingZone* incomingZone in incomingActiveZones) {
		id zoneIdentity = [incomingZone identity];
		BOOL zonePreviouslyEntered = [exitedIdentities containsObject:zoneIdentity];
		if (zonePreviouslyEntered) {
			[self notifyZoneMoved:incomingZone withEvent:nil];
			[exitedIdentities removeObject:[incomingZone identity]];
		}
	}
	
	for (TLTrackingZone* currentZone in [self activeTrackingZones]) {
		if (![exitedIdentities count]) break;
		id zoneIdentity = [currentZone identity];
		if ([exitedIdentities containsObject:[currentZone identity]]) {
			[self notifyZoneExited:currentZone withEvent:nil];
			// remove so we can stop scanning as soon as all exited zones found
			[exitedIdentities removeObject:zoneIdentity];
		}
	}
	NSAssert1(![exitedIdentities count],
			  @"Lost track of %lu tracking zone(s)",
			  (unsigned long)[exitedIdentities count]);
}

- (NSArray*)filterZones:(NSArray*)zones containingPoint:(CGPoint)point {
	NSMutableArray* zonesContainingPoint = [NSMutableArray array];
	for (TLTrackingZone* zone in zones) {
		if (CGRectContainsPoint([zone bounds], point)) {
			[zonesContainingPoint addObject:zone];
		}
	}
	return zonesContainingPoint;
}


#pragma mark Mouse handling

- (void)mouseEntered:(NSEvent*)trackingEvent {
	CGPoint zonePoint = CGPointZero;
	BOOL haveZonePoint = [self getZonePoint:&zonePoint forEvent:trackingEvent];
	if (haveZonePoint) {
		NSArray* enteredZones = [self filterZones:[self activeTrackingZones]
								  containingPoint:zonePoint];
		[self setCurrentlyEnteredZones:enteredZones withEvent:trackingEvent];
	}
}

- (void)mouseMoved:(NSEvent*)trackingEvent {
	CGPoint zonePoint = CGPointZero;
	BOOL haveZonePoint = [self getZonePoint:&zonePoint forEvent:trackingEvent];
	if (haveZonePoint) {
		NSArray* enteredZones = [self filterZones:[self activeTrackingZones]
								  containingPoint:zonePoint];
		[self setCurrentlyEnteredZones:enteredZones withEvent:trackingEvent];
	}
}

- (void)mouseExited:(NSEvent*)trackingEvent {
	[self setCurrentlyEnteredZones:nil withEvent:trackingEvent];
}

@end
