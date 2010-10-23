//
//  NSTask+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSTask+TLExtensions.h"


@implementation NSTask (TLExtensions)

+ (NSTask*)tl_launchedTask:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err {
	NSParameterAssert(launchPath != nil);
	if (!arguments) arguments = [NSArray array];
	
	NSTask* task = [[NSTask new] autorelease];
	[task setLaunchPath:launchPath];
	[task setArguments:arguments];
	@try {
		[task launch];
	}
	@catch (NSException* e) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Could not launch task", NSLocalizedDescriptionKey,
									 @"The launch path was invalid or failed to create a process.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 launchPath, NSFilePathErrorKey,
									 [e reason], NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:NSCocoaErrorDomain
									   code:NSExecutableNotLoadableError userInfo:errInfo];
		}
		return nil;
	}
	return task;
}

+ (NSTask*)tl_completedTask:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err {
	NSTask* task = [self tl_launchedTask:launchPath arguments:arguments error:err];
	[task waitUntilExit];
	return task;
}

- (BOOL)tl_launch:(NSError**)err {
	@try {
		[self launch];
	}
	@catch (NSException* e) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Could not launch task", NSLocalizedDescriptionKey,
									 @"The launch path was invalid or failed to create a process.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [self launchPath], NSFilePathErrorKey,
									 [e reason], NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:NSCocoaErrorDomain
									   code:NSExecutableNotLoadableError userInfo:errInfo];
		}
		return NO;
	}
	return YES;
}

+ (NSData*)tl_system:(NSString*)launchPath arguments:(NSArray*)arguments error:(NSError**)err {
	NSTask* script = [[NSTask new] autorelease];
	[script setLaunchPath:launchPath];
	[script setArguments:arguments];
	NSPipe* resultPipe = [NSPipe pipe];
	[script setStandardOutput:resultPipe];
	BOOL launched = [script tl_launch:err];
	if (!launched) return nil;
	
	NSMutableData* resultData = [NSMutableData data];
	NSFileHandle* results = [resultPipe fileHandleForReading];
	NSData* resultBuffer;
	while ((resultBuffer = [results availableData]) && [resultBuffer length]) {
		[resultData appendData:resultBuffer];
    }
	return resultData;
}


@end
