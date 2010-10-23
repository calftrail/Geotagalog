//
//  TLWaypoint.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 11/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLWaypoint.h"


@implementation TLWaypoint

#pragma mark Archiving

static NSString* const TLWaypointLocationKey = @"TLWaypoint_Location";
static NSString* const TLWaypointTimestampKey = @"TLWaypoint_Timestamp";

- (void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:location forKey:TLWaypointLocationKey];
	[encoder encodeObject:timestamp forKey:TLWaypointTimestampKey];
}

- (id)initWithCoder:(NSCoder*)coder {
	self = [super init];
	if (self) {
		location = [[coder decodeObjectForKey:TLWaypointLocationKey] retain];
		timestamp = [[coder decodeObjectForKey:TLWaypointTimestampKey] retain];
	}
	return self;
}


#pragma mark Lifecycle

- (id)initWithLocation:(TLLocation*)theLocation
			 timestamp:(TLTimestamp*)theTimestamp
{
	self = [super init];
	if (self) {
		location = [theLocation copy];
		timestamp = [theTimestamp copy];
	}
	return self;
}

- (void)dealloc {
	[location release];
	[timestamp release];
	[super dealloc];
}

+ (id)waypointWithLocation:(TLLocation*)theLocation
				 timestamp:(TLTimestamp*)theTimestamp
{
	TLWaypoint* waypoint = [[TLWaypoint alloc] initWithLocation:theLocation
													  timestamp:theTimestamp];
	return [waypoint autorelease];
}


#pragma mark Accessors

@synthesize location;
@synthesize timestamp;

@end
