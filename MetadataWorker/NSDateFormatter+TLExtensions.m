//
//  NSDateFormatter+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/20/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSDateFormatter+TLExtensions.h"


@implementation NSDateFormatter (TLExtensions)

+ (NSDateFormatter*)tl_tiffDateFormatter {
	NSDateFormatter* tiffDateFormatter = [NSDateFormatter new];
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[tiffDateFormatter setCalendar:gregorian];
	[gregorian release];
	[tiffDateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
	return [tiffDateFormatter autorelease];
}

+ (NSDateFormatter*)tl_applescriptDateFormatter {
	NSDateFormatter* asDateFormatter = [NSDateFormatter new];
	[asDateFormatter setDateStyle:NSDateFormatterShortStyle];
	[asDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	return [asDateFormatter autorelease];
}

@end
