//
//  AppDelegate.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TaskMaster, StatusMenuController, StatusController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
@private
	TaskMaster* taskHandler;
	StatusMenuController* statusMenu;
	StatusController* status;
}

- (IBAction)showLogWindow:(id)sender;

@end
