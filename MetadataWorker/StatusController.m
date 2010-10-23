//
//  StatusController.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/24/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "StatusController.h"

#import "Logger.h"
#import "TaskMaster.h"
#import "SendController.h"

#import "TLActorKVO.h"
#import "NSOperationQueue+TLExtensions.h"
#import "NSArray+TLExtensions.h"


@interface StatusController ()
@property (nonatomic) BOOL maySendLog;
@property (nonatomic) BOOL mayClearLog;
@property (nonatomic, copy) NSArray* allMessages;
@property (nonatomic, copy) NSArray* messages;
@property (nonatomic, copy) NSArray* tasks;
- (void)logSent:(NSNotification*)notification;
- (void)loggerUpdated:(NSNotification*)notification;
- (void)tasksUpdated:(NSNotification*)notification;
@end


@implementation StatusController

@synthesize maySendLog;
@synthesize mayClearLog;
@synthesize allMessages;
@synthesize messages;
@synthesize tasks;

- (id)initWithWindow:(NSWindow*)window {
	self = [super initWithWindow:window];
	if (self) {
		logSender = [[SendController alloc] initWithWindowNibName:@"SendLog"];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self selector:@selector(loggerUpdated:)
		 name:LoggerDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self selector:@selector(tasksUpdated:)
		 name:TaskMasterDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self selector:@selector(logSent:)
		 name:SendControllerDidSendLogNotification object:logSender];
	}
	return self;
}

- (void)awakeFromNib {
	[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
}

- (IBAction)toggleWindow:(id)sender {
	if (![self isWindowLoaded] || ![[self window] isVisible]) {
		[NSApp activateIgnoringOtherApps:YES];
		[self showWindow:sender];
	}
	else {
		[[self window] performClose:sender];
	}
}

- (IBAction)clearLog:(id)sender {
	(void)sender;
	[[Logger sharedLogger] clearAll];
}

- (IBAction)sendLog:(id)sender {
	(void)sender;
	
	NSMutableString* logInfo = [NSMutableString string];
	for (NSError* message in self.allMessages) {
		NSString* type = @"Unknown message";
		switch ([message code]) {
		case LoggerDebugging:
			type = @"Debug info"; break;
		case LoggerInformative:
			type = @"Information"; break;
		case LoggerWarning:
			type = @"Warning"; break;
		case LoggerError:
			type = @"Error"; break;
		case LoggerInternalError:
			type = @"Internal error"; break;
		}
		NSDate* timestamp = [[message userInfo] objectForKey:@"Timestamp"];
		[logInfo appendFormat:@"%@ @ %@:\n", type, timestamp];
		if ([message code] > LoggerInformative) {
			[logInfo appendFormat:@"%@ (%@)\n",
			 [message localizedDescription], [message localizedRecoverySuggestion]];
			[logInfo appendFormat:@"%@\n\n", [message localizedFailureReason]];
		}
		else {
			[logInfo appendFormat:@"%@\n\n", [message localizedDescription]];
		}
	}
	logSender.logMessage = logInfo;
	[logSender showWindow:sender];
}

- (void)logSent:(NSNotification*)notification {
	(void)notification;
	self.maySendLog = NO;
}

- (void)loggerUpdated:(NSNotification*)notification {
	self.allMessages = [[notification userInfo] objectForKey:LoggerMessageErrors];
	NSArray* filteredMessages = [self.allMessages filteredArrayUsingPredicate:
								 [NSPredicate predicateWithFormat:@"code >= 0"]];
	self.messages = [filteredMessages tl_reversedArray];
	self.maySendLog = self.mayClearLog = ([self.messages count]) ? YES : NO;
}

- (void)tasksUpdated:(NSNotification*)notification {
	self.tasks = [[notification userInfo] objectForKey:TaskMasterCurrentTasks];
}

@end
