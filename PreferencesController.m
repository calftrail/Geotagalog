//
//  PreferencesController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController

@synthesize window;

- (IBAction)showWindow:(id)sender {
	if (!self.window) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
	}
	[self.window makeKeyAndOrderFront:sender];
}

- (IBAction)resetCameraFolder:(id)sender {
	(void)sender;
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"CameraExportFolder"];
}

- (BOOL)windowShouldClose:(id)sender {
	(void)sender;
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.window = nil;
	return YES;
}

@end
