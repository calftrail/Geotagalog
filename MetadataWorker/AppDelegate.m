//
//  AppDelegate.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "StatusMenuController.h"
#import "StatusController.h"
#import "TaskMaster.h"
#import "Logger.h"


@interface AppDelegate ()
- (void)prepareHelpers;
@end


@implementation AppDelegate

- (id)init {
	self = [super init];
	if (self) {
		statusMenu = [[StatusMenuController alloc] initWithMenuNibName:@"StatusMenu"];
		status = [[StatusController alloc] initWithWindowNibName:@"Status"];
		[self prepareHelpers];
	}
	return self;
}

- (void)prepareHelpers {
	NSArray* appSupports = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
															   NSUserDomainMask, YES);
	NSAssert([appSupports count], @"Application Support folder must be available");
	NSString* appDir = [[appSupports objectAtIndex:0]
						stringByAppendingPathComponent:@"Geotagalog"];
	NSURL* appURL = [NSURL fileURLWithPath:appDir isDirectory:YES];
	
	NSURL* tasksURL = [appURL URLByAppendingPathComponent:@"MetadataTasks.coredata"];
	taskHandler = [[TaskMaster alloc] initWithURL:tasksURL];
	[taskHandler begin];
	
	NSURL* logURL = [appURL URLByAppendingPathComponent:@"MetadataLog.coredata"];
	[[Logger sharedLogger] beginLoggingToURL:logURL];
	[[Logger sharedLogger] clearOld];
}

- (BOOL)application:(NSApplication*)sender openFile:(NSString*)path {
	(void)sender;
	//[status showWindow:self];
	NSString* infoPath = [path stringByAppendingPathComponent:@"taskInfo.plist"];
	NSDictionary* info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
	if (info) [taskHandler addTaskInfo:info];
	if (!info) {
		[Logger informativeLog:@"Failed to read tasks from '%@'.", infoPath];
	}
	return info ? YES : NO;
}

- (IBAction)showLogWindow:(id)sender {
	[status showWindow:sender];
}

@end
