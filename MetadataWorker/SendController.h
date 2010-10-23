//
//  SendController.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/26/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const SendControllerDidSendLogNotification;

@interface SendController : NSWindowController <NSWindowDelegate> {
@private
	BOOL readyToSend;
	NSString* userMessage;
	NSString* logMessage;
}

+ (void)submitReport:(NSString*)description details:(NSString*)details;

@property (nonatomic) BOOL readyToSend;
@property (nonatomic, copy) NSString* userMessage;
@property (nonatomic, copy) NSString* logMessage;

- (IBAction)sendLog:(id)sender;

@end
