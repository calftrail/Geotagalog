//
//  TaskExport.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TaskExport.h"

#import "TLPhotoSource.h"
#import "TLPhotoSourceItem.h"

#import "TLLocation.h"
#import "TLTimestamp.h"

#import "NSFileManager+TLExtensions.h"

@implementation TaskExport

- (id)init {
	self = [super init];
	if (self) {
		taskInfo = [NSMutableDictionary new];
	}
	return self;
}

- (void)dealloc {
	[taskInfo release];
	[exportURL release];
	[super dealloc];
}

+ (NSString*)softwareName {
	NSDictionary* appInfo = [[NSBundle mainBundle] infoDictionary];
	NSString* appName = [appInfo objectForKey:(id)kCFBundleNameKey];
	NSString* appVersion = [appInfo objectForKey:@"CFBundleShortVersionString"];
	return [NSString stringWithFormat:@"%@ v%@", appName, appVersion];
}

- (BOOL)prepareForItems:(NSSet*)items
				  error:(NSError**)err
{
	BOOL containsNonFileItems = NO;
	for (TLPhotoSourceItem* item in items) {
		if (![[item originalURL] isFileURL]) {
			containsNonFileItems = YES;
			break;
		}
	}
	
	NSArray* appSupports = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
															   NSUserDomainMask, YES);
	NSAssert([appSupports count], @"Application Support folder must be available");
	NSString* appDir = [[appSupports objectAtIndex:0] stringByAppendingPathComponent:@"Geotagalog"];
	NSString* taskName = [NSString stringWithFormat:@"Task-%@.geotagalogTask", TLMakeUUID()];
	NSString* taskBundle = [appDir stringByAppendingPathComponent:taskName];
	[taskInfo setObject:taskBundle forKey:@"taskBundle"];
	
	NSError* folderError;
	BOOL created = [[NSFileManager tl_threadManager] createDirectoryAtPath:taskBundle
											   withIntermediateDirectories:YES
										   attributes:nil error:&folderError];
	if (!created) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Can't create task", NSLocalizedDescriptionKey,
									 @"An error occurred while creating the metadata task "
									 @"in Geotagalog's Application Support folder.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 folderError, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:412 userInfo:errInfo];
		}
		return NO;
	}
	
	if (containsNonFileItems) {
		NSString* exportPath = [taskBundle stringByAppendingPathComponent:@"items"]; 
		created = [[NSFileManager tl_threadManager] createDirectoryAtPath:exportPath
											  withIntermediateDirectories:NO
															   attributes:nil error:&folderError];
		if (!created) {
			if (err) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 @"Can't create export folder", NSLocalizedDescriptionKey,
										 @"An error occurred while creating a folder to store "
										 @"items downloaded from the camera.",
										 NSLocalizedRecoverySuggestionErrorKey,
										 folderError, NSUnderlyingErrorKey, nil];
				*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:413 userInfo:errInfo];
			}
			return NO;
		}
		exportURL = [[NSURL fileURLWithPath:exportPath isDirectory:YES] copy];
	}
	
	NSUInteger theWorkflow = [self workflow];
	if (theWorkflow == justOriginals && containsNonFileItems) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Can't modify originals on camera", NSLocalizedDescriptionKey,
									 @"Your photos are still stored in a camera or memory card, but "
									 @"you have chosen to geotag without iPhoto import.\n"
									 @"Please download files before using Geotagalog, "
									 @"or select a different workflow preference.",
									 NSLocalizedRecoverySuggestionErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:411 userInfo:errInfo];
		}
		return NO;
	}
	
	if (containsNonFileItems) {
		[taskInfo setObject:(id)kCFBooleanTrue forKey:@"forceCopy"];
	}
	[taskInfo setObject:[NSNumber numberWithInteger:theWorkflow] forKey:@"workflow"];
	[taskInfo setObject:[NSMutableDictionary dictionary] forKey:@"files"];
	
	NSString* software = [[self class] softwareName];
	if (software) {
		[taskInfo setObject:software forKey:@"software"];
	}
	
	return YES;
}

- (BOOL)exportItem:(TLPhotoSourceItem*)item
	  withMetadata:(NSDictionary*)metadata
			 error:(NSError**)err
{
	NSURL* localURL = [item originalURL];
	if (!localURL) {
		localURL = [item exportToFolder:exportURL error:err];
		if (!localURL) return NO;
	}
	
	NSMutableDictionary* taskMetadata = [NSMutableDictionary dictionary];
	
	TLLocation* location = [metadata objectForKey:TLMetadataLocationKey];
	if (location) {
		TLCoordinate coord = [location coordinate];
		[taskMetadata setObject:[NSNumber numberWithDouble:coord.lat] forKey:@"latitude"];
		[taskMetadata setObject:[NSNumber numberWithDouble:coord.lon] forKey:@"longitude"];
		TLCoordinateAltitude altitude = [location altitude];
		if (altitude != TLCoordinateAltitudeUnknown) {
			[taskMetadata setObject:[NSNumber numberWithDouble:altitude] forKey:@"altitude"];
		}
	}
	
	TLTimestamp* timestamp = [metadata objectForKey:TLMetadataTimestampKey];
	if (timestamp) {
		[taskMetadata setObject:[timestamp time] forKey:@"timestamp"];
	}
	
	[[taskInfo objectForKey:@"files"] setObject:taskMetadata forKey:[localURL path]];
	return YES;
}

- (void)cancelExport {
	NSString* taskBundle = [taskInfo objectForKey:@"taskBundle"];
	[[NSFileManager tl_threadManager] removeItemAtPath:taskBundle error:NULL];
}

+ (void)relaunchWorker {
	NSString* launcher = [[NSBundle mainBundle] pathForResource:@"LaunchHelper" ofType:@"scpt"];
	NSString* helper = [[NSBundle mainBundle] pathForResource:@"MetadataWorker" ofType:@"app"];
	NSArray* osaArguments = [NSArray arrayWithObjects:launcher, helper, nil];
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:osaArguments];
}

- (void)openTask:(NSString*)theTask {
	NSString* helper = [[NSBundle mainBundle] pathForResource:@"MetadataWorker" ofType:@"app"];
	BOOL success = [[NSWorkspace sharedWorkspace] openFile:theTask withApplication:helper];
	if (!success) {
		NSLog(@"Couldn't open task file at '%@' in '%@'!", theTask, helper);
	}
}

- (BOOL)finishExport:(NSError**)err {
	NSString* taskBundle = [taskInfo objectForKey:@"taskBundle"];
	NSString* infoPath = [taskBundle stringByAppendingPathComponent:@"taskInfo.plist"];
	BOOL success = [taskInfo writeToFile:infoPath atomically:NO];
	if (!success) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Couldn't write task information", NSLocalizedDescriptionKey,
									 @"An error occurred while writing metadata task information.",
									 NSLocalizedRecoverySuggestionErrorKey, infoPath, NSFilePathErrorKey, nil];
			*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:errInfo];
		}
		return NO;
	}
	[self performSelectorOnMainThread:@selector(openTask:) withObject:taskBundle waitUntilDone:YES];
	return YES;
}

@end
