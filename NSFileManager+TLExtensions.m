//
//  NSFileManager+TLExtensions.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+TLExtensions.h"

#include <uuid/uuid.h>

static NSString* const TLNSFileManagerExtensionsThreadManagerKey = @"TLNSFileManagerExtensions_ThreadManager";
NSString* TLMakeUUID(void);

@implementation NSFileManager (TLNSFileManagerExtensions)

+ (NSFileManager*)tl_threadManager {
	return [[NSFileManager new] autorelease];
}

- (NSString*)tl_moveItemAtPath:(NSString*)srcPath
				  toUniquePath:(NSString*)dstPath
						 error:(NSError **)err
{
	BOOL moved = NO;
	NSUInteger uniqueFileSuffix = 0;
	const NSUInteger uniqueFileSuffixLimit = 1000000;
	NSString* finalDstPath = dstPath;
	do {
		if (uniqueFileSuffix) {
			NSString* fullFileName = [dstPath lastPathComponent];
			NSString* fileName = [fullFileName stringByDeletingPathExtension];
			NSString* dstFileName = [NSString stringWithFormat:@"%@-%lu", fileName, uniqueFileSuffix];
			
			NSString* dstFolder = [dstPath stringByDeletingLastPathComponent];
			NSString* dstExtension = [fullFileName pathExtension];
			finalDstPath = [[dstFolder stringByAppendingPathComponent:dstFileName]
							stringByAppendingPathExtension:dstExtension];
		}
		moved = [self moveItemAtPath:srcPath
							  toPath:finalDstPath
							   error:err];
		/* NOTE: we want to break unless the error was due to file already existing.
		 Unfortunately, the specific error when the file exists is undocumented, and was
		 seen to just be NSCocoaErrorDomain/NSFileWriteUnknownError, so that's not useful.
		 Instead we just break if the file doesn't exist *now*. This is not strictly correct,
		 but should work alright enough in practice. */
		if (!moved && ![self fileExistsAtPath:finalDstPath]) {
			break;
		}
	} while (!moved && ++uniqueFileSuffix < uniqueFileSuffixLimit);
	return moved ? finalDstPath : nil;
}

- (NSURL*)tl_createTemporaryDirectory:(NSError**)err {
	NSString* appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	NSString* uniqueFolder = [NSString stringWithFormat:@"%@-%@", appIdentifier, TLMakeUUID()];
	NSString* temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFolder];
	BOOL success =  [self createDirectoryAtPath:temporaryPath
					withIntermediateDirectories:NO
									 attributes:nil
										  error:err];
	if (!success) return nil;
	return [NSURL fileURLWithPath:temporaryPath isDirectory:YES];
}

@end


NSString* TLMakeUUID() {
	uuid_t uniqueIdentifier;
	uuid_generate(uniqueIdentifier);
	char stringBuffer[36+1];
	uuid_unparse(uniqueIdentifier, stringBuffer);
	return [NSString stringWithUTF8String:stringBuffer];
}
