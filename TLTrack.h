//
//  TLTrack.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 6/24/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLGPXTrackSegment;

@interface TLTrack : NSObject < NSCoding > {
@private
	NSArray* waypoints;
	__weak NSDate* startDate;
	__weak NSDate* endDate;
}

// designated initializer
- (id)initWithWaypoints:(NSArray*)theWaypoints;

@property (nonatomic, readonly) NSArray* waypoints;

@property (nonatomic, readonly) NSDate* startDate;
@property (nonatomic, readonly) NSDate* endDate;

@end
