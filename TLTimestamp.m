//
//  TLTimestamp.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLTimestamp.h"


@implementation TLTimestamp

#pragma mark Archiving

static NSString* const TLTimestampWrappedDataKey = @"TLTimestamp_WrappedData";

enum {
	TLTimestampSecondsSince010101Index = 0,
	TLTimestampAccuracyIndex = 1,
	TLTimestampDataCount = 2
};

- (void)encodeWithCoder:(NSCoder*)encoder {
	const size_t dataSize = TLTimestampDataCount * sizeof(CFSwappedFloat64);
	CFSwappedFloat64* dataArray = (CFSwappedFloat64*)malloc(dataSize);
	dataArray[TLTimestampSecondsSince010101Index] = CFConvertFloat64HostToSwapped([time timeIntervalSinceReferenceDate]);
	dataArray[TLTimestampAccuracyIndex] = CFConvertFloat64HostToSwapped(accuracy);
	// NOTE: this avoids autorelease to reduce memory pressure
	NSData* data = [[NSData alloc] initWithBytesNoCopy:dataArray length:dataSize freeWhenDone:YES];
	[encoder encodeObject:data forKey:TLTimestampWrappedDataKey];
	[data release];
}

- (id)initWithCoder:(NSCoder*)coder {
	self = [super init];
	if (self) {
		NSData* data = [coder decodeObjectForKey:TLTimestampWrappedDataKey];
		const CFSwappedFloat64* dataArray = (CFSwappedFloat64*)[data bytes];
		NSAssert1([data length] == TLTimestampDataCount * sizeof(CFSwappedFloat64),
				  @"Bad timestamp data length (%lu)", (long unsigned)[data length]);
		double secondsSince010101 = CFConvertFloat64SwappedToHost(dataArray[TLTimestampSecondsSince010101Index]);
		time = [[NSDate dateWithTimeIntervalSinceReferenceDate:secondsSince010101] retain];
		accuracy = CFConvertFloat64SwappedToHost(dataArray[TLTimestampAccuracyIndex]);
	}
    return self;
}


#pragma mark Lifecycle

- (id)initWithTime:(NSDate*)theTime
		  accuracy:(NSTimeInterval)theAccuracy
{
	self = [super init];
	if (self) {
		time = [theTime copy];
		accuracy = theAccuracy;
	}
	return self;
}

- (void)dealloc {
	[time release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone*)zone {
	return [[TLTimestamp allocWithZone:zone] initWithTime:[self time]
												 accuracy:[self accuracy]];
}


#pragma mark Convenience creators

+ (id)timestampWithTime:(NSDate*)theTime
			   accuracy:(NSTimeInterval)theAccuracy
{
	TLTimestamp* timestamp = [[TLTimestamp alloc] initWithTime:theTime
													  accuracy:theAccuracy];
	return [timestamp autorelease];
}


#pragma mark Accessors

@synthesize time;
@synthesize accuracy;

@end
