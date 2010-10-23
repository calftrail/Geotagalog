//
//  TLTrack.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 6/24/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLTrack.h"

#import "TLWaypoint.h"
#import "TLTimestamp.h"


@implementation TLTrack

@synthesize waypoints;
@synthesize startDate;
@synthesize endDate;

#pragma mark Archiving

static NSString* const TLTrackWaypointsKey = @"TLTrack_Waypoints";
static NSString* const TLTrackWrappedDataKey = @"TLTrack_WrappedData";

- (void)encodeWithCoder:(NSCoder*)encoder {
	// NOTE: this avoids autorelease to reduce memory pressure (could optionally use pool)
	NSMutableData* data = [NSMutableData new];
	NSKeyedArchiver* subEncoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[subEncoder encodeObject:waypoints forKey:TLTrackWaypointsKey];
	[subEncoder finishEncoding];
	[subEncoder release];
	[encoder encodeObject:data forKey:TLTrackWrappedDataKey];
	[data release];
}

- (id)initWithCoder:(NSCoder*)coder {
	self = [super init];
	if (self) {
		NSData* data = [coder decodeObjectForKey:TLTrackWrappedDataKey];
		// NOTE: this avoids autorelease to reduce memory pressure (could optionally use pool)
		NSKeyedUnarchiver* subCoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		waypoints = [[subCoder decodeObjectForKey:TLTrackWaypointsKey] retain];
		[subCoder finishDecoding];
		[subCoder release];
	}
    return self;
}


#pragma mark Lifecycle

- (id)initWithWaypoints:(NSArray*)theWaypoints {
	self = [super init];
	if (self) {
		NSAssert([theWaypoints count], @"Must have at least one waypoint in track");
		waypoints = [theWaypoints retain];
		// NOTE: we assume that the waypoints are sorted
		startDate = [[(TLWaypoint*)[theWaypoints objectAtIndex:0] timestamp] time];
		endDate = [[(TLWaypoint*)[theWaypoints lastObject] timestamp] time];
	}
	return self;
}

- (void)dealloc {
	[waypoints release];
	[super dealloc];
}

@end
