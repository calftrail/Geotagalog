//
//  PreferencesController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreferencesController : NSObject {
@private
	NSWindow* window;
}

@property (nonatomic, assign) IBOutlet NSWindow* window;
- (IBAction)showWindow:(id)sender;

- (IBAction)resetCameraFolder:(id)sender;

@end
