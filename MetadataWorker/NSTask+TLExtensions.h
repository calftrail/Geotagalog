//
//  NSTask+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTask (TLExtensions)
+ (NSTask*)tl_launchedTask:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err;
+ (NSTask*)tl_completedTask:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err;
+ (NSData*)tl_system:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err;
- (BOOL)tl_launch:(NSError**)err;
@end
