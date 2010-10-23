//
//  TLTrackingManager.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLTrackingZone;


@interface TLTrackingManager : NSObject {
@private
	id delegate;
	NSArray* trackingAreas;
	NSArray* activeTrackingZones;
	NSMutableSet* enteredIdentities;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) NSArray* activeTrackingZones;

@end


@interface NSObject (TLTrackingManagerDelegate)

- (void)trackingManager:(TLTrackingManager*)manager
   replaceTrackingAreas:(NSArray*)oldTrackingAreas
	  withTrackingAreas:(NSArray*)newTrackingAreas;


- (void)trackingManager:(TLTrackingManager*)manager
	  mouseDidEnterZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil;
- (void)trackingManager:(TLTrackingManager*)manager
	 mouseDidMoveInZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil;
- (void)trackingManager:(TLTrackingManager*)manager
	   mouseDidExitZone:(TLTrackingZone*)trackZone
			  withEvent:(NSEvent*)eventOrNil;


- (BOOL)trackingManager:(TLTrackingManager*)manager
		 shouldUsePoint:(CGPoint*)zonePointPtr
		 forWindowPoint:(NSPoint)windowPoint;

- (BOOL)trackingManager:(TLTrackingManager*)manager
   shouldUseWindowPoint:(NSPoint*)windowPointPtr;

- (NSRect)trackingManager:(TLTrackingManager*)manager
	 clippedRectForBounds:(CGRect)zoneBounds;

@end
