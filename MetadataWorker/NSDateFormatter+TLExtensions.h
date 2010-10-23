//
//  NSDateFormatter+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/20/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDateFormatter (TLExtensions)
+ (NSDateFormatter*)tl_tiffDateFormatter;
+ (NSDateFormatter*)tl_applescriptDateFormatter;
@end
