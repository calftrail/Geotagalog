//
//  StatusController.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/24/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SendController;


@interface StatusController : NSWindowController {
@private
	NSArray* allMessages;
	NSArray* messages;
	NSArray* tasks;
	SendController* logSender;
	BOOL maySendLog;
	BOOL mayClearLog;
}

- (IBAction)toggleWindow:(id)sender;
- (IBAction)clearLog:(id)sender;
- (IBAction)sendLog:(id)sender;

@end
