//
//  NSFileManager+TLExtensions.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (TLNSFileManagerExtensions)

+ (NSFileManager*)tl_threadManager;

- (NSString*)tl_moveItemAtPath:(NSString*)srcPath
				  toUniquePath:(NSString*)dstPath
						 error:(NSError **)error;

- (NSURL*)tl_createTemporaryDirectory:(NSError**)err;

// TODO: add ensureFolderExists, etc.

@end

NSString* TLMakeUUID(void);
