//
//  TLTrackingZone.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLTrackingZone : NSObject {
@private
	CGRect bounds;
	id identity;
	NSDictionary* userInfo;
}

+ (id)trackingZoneWithBounds:(CGRect)bounds identity:(id)uniqueObject userInfo:(NSDictionary*)userInfo;

@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) id identity;
@property (nonatomic, readonly) NSDictionary* userInfo;

@end
