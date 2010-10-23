//
//  NSDateFormatter+TLAdditions.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDateFormatter (TLAdditions)

+ (NSDateFormatter*)tl_tiffDateFormatter;
+ (NSDate*)tl_dateFromISO8601:(NSString*)xslDateTime;

@end
