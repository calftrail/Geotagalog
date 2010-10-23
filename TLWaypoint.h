//
//  TLWaypoint.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 11/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLLocation;
@class TLTimestamp;

@interface TLWaypoint : NSObject < NSCoding > {
@private
	TLLocation* location;
	TLTimestamp* timestamp;
}

+ (id)waypointWithLocation:(TLLocation*)theLocation
				 timestamp:(TLTimestamp*)theTimestamp;

@property (nonatomic, readonly) TLLocation* location;
@property (nonatomic, readonly) TLTimestamp* timestamp;

@end
