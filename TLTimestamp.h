//
//  TLTimestamp.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static const NSTimeInterval TLTimestampAccuracyUnknown = 0.0;

@interface TLTimestamp : NSObject < NSCopying, NSCoding > {
@private
	NSDate* time;
	NSTimeInterval accuracy;
}

// Designated initializer
- (id)initWithTime:(NSDate*)theTime
		  accuracy:(NSTimeInterval)theAccuracy;

// Helper initializers
+ (id)timestampWithTime:(NSDate*)theTime
			   accuracy:(NSTimeInterval)theAccuracy;

// Properties
@property (readonly, nonatomic) NSDate* time;
@property (readonly, nonatomic) NSTimeInterval accuracy;

@end
