//
//  TrackWaitWindowController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrackWaitWindowController : NSObject {
	IBOutlet NSWindow* window;
	__weak IBOutlet NSTextField* text;
	__weak IBOutlet NSProgressIndicator* progress;
@private
	NSString* filename;
	NSModalSession modalSession;
}

@property (nonatomic, copy) NSString* filename;
- (void)begin;
- (void)end;

@end
