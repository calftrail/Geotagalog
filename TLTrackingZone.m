//
//  TLTrackingZone.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLTrackingZone.h"


@implementation TLTrackingZone

#pragma mark Lifecycle

- (id)initWithBounds:(CGRect)theBounds identity:(id)theIdentity userInfo:(NSDictionary*)theUserInfo {
	self = [super init];
	if (self) {
		bounds = theBounds;
		identity = [theIdentity retain];
		userInfo = [theUserInfo copy];
	}
	return self;
}

- (void)dealloc {
	[identity release];
	[userInfo release];
	[super dealloc];
}

#pragma mark Miscellaneous

+ (id)trackingZoneWithBounds:(CGRect)bounds identity:(id)uniqueObject userInfo:(NSDictionary*)userInfo {
	TLTrackingZone* trackingZone = [[TLTrackingZone alloc] initWithBounds:bounds
																 identity:uniqueObject
																 userInfo:userInfo];
	return [trackingZone autorelease];
}

@synthesize bounds;
@synthesize identity;
@synthesize userInfo;

@end
