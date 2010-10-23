//
//  LaunchWindowController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LaunchWindowController : NSObject {
	__weak IBOutlet NSButton* cameraLaunch;
	__weak IBOutlet NSPopUpButton* openRecent;
@private
	IBOutlet NSWindow* window;
	NSMapTable* recentDocumentItems;
}

- (IBAction)openTracklog:(id)sender;
- (IBAction)openRecentTracklog:(id)sender;
- (IBAction)toggleCameraLaunch:(id)sender;

@property (nonatomic, retain) NSWindow* window;

@end
