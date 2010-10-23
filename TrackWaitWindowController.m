//
//  TrackWaitWindowController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TrackWaitWindowController.h"


@implementation TrackWaitWindowController

@synthesize filename;

- (id)init {
	self = [super init];
	if (self) {
		(void)[NSBundle loadNibNamed:@"TracklogWait" owner:self];
	}
	return self;
}

- (void)dealloc {
	[window release];
	[self setFilename:nil];
	[super dealloc];
}

- (void)awakeFromNib {
	[progress setUsesThreadedAnimation:YES];
}

- (void)begin {
	NSString* loadString = [NSString stringWithFormat:@"Loading tracks from '%@'.", [self filename]];
	[text setStringValue:loadString];
	[progress startAnimation:nil];
	modalSession = [NSApp beginModalSessionForWindow:window];
}

- (void)end {
	[NSApp endModalSession:modalSession];
	[progress stopAnimation:nil];
	[window close];
}

@end
