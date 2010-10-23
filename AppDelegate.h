//
//  AppDelegate.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject {
@private
	id launchWindowController;
	id preferencesController;
	id projectController;
}

- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)relaunchMetadataWorker:(id)sender;
- (IBAction)openDocument:(id)sender;

@end
