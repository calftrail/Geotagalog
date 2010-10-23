//
//  StatusMenuController.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 4/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusMenuController : NSObject {
	IBOutlet NSMenu* menu;
@private
	NSStatusItem* menuIcon;
	
	BOOL hadPreviousTaskUpdate;
	NSUInteger numTasks;
	NSUInteger numMessages;
	NSUInteger numErrors;
	NSAnimation* pulse;
}

- (id)initWithMenuNibName:(NSString*)nibName;

- (IBAction)showLog:(id)sender;
- (IBAction)quit:(id)sender;

@end
