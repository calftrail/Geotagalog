//
//  LaunchWindowController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LaunchWindowController.h"

#import "TLImageCaptureManager.h"


@implementation LaunchWindowController

@synthesize window;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[self window] setDelegate:nil];
	[self setWindow:nil];
	[recentDocumentItems release];
	[super dealloc];
}

/* NOTE: Fontin font must be installed on build machine, or a default font name gets saved to compiled NIB */
- (void)loadLocalFonts {
	// Based on http://www.cocoabuilder.com/archive/message/cocoa/2005/1/16/125883
	// see also http://www.cocoabuilder.com/archive/message/cocoa/2007/1/24/177638
	NSString* fontsFolder = [[NSBundle mainBundle] resourcePath];
	if (fontsFolder) {
		NSURL* fontsURL = [NSURL fileURLWithPath:fontsFolder isDirectory:YES];
		if (fontsURL) {
			FSRef fsRef;
			Boolean success = CFURLGetFSRef((CFURLRef)fontsURL, &fsRef);
			if (success) {
				ATSFontActivateFromFileReference(&fsRef, kATSFontContextLocal, kATSFontFormatUnspecified,
												 NULL, kATSOptionFlagsProcessSubdirectories, NULL);
			}
		}
	}
}

- (void)loadWindow {
	[self loadLocalFonts];
	BOOL loaded = [NSBundle loadNibNamed:@"Launch" owner:self];
	if (!loaded) {
		NSLog(@"Couldn't load launch window");
	}
	
	[[self window] setDelegate:self];
	
	if ([[TLImageCaptureManager sharedImageCaptureManager] shouldAutoLaunch]) {
		[cameraLaunch setState:NSOnState];
	}
	else {
		[cameraLaunch setState:NSOffState];
	}
}

- (NSWindow*)window {
	if (!window) {
		[self loadWindow];
	}
	return window;
}

- (IBAction)toggleCameraLaunch:(id)sender {
	(void)sender;
	
	BOOL newAutoLaunch = ([cameraLaunch state] == NSOnState);
	[[TLImageCaptureManager sharedImageCaptureManager] setShouldAutoLaunch:newAutoLaunch];
}

- (IBAction)openTracklog:(id)sender {
	if ([[NSApp delegate] respondsToSelector:@selector(openDocument:)]) {
		(void)[[NSApp delegate] openDocument:sender];
	}
}

- (IBAction)openRecentTracklog:(id)sender {
	(void)sender;
	if ([[NSApp delegate] respondsToSelector:@selector(application:openFile:)]) {
		NSMenuItem* item = [openRecent selectedItem];
		NSString* filename = [recentDocumentItems objectForKey:item];
		(void)[[NSApp delegate] application:NSApp openFile:filename];
	}
}

- (void)windowDidBecomeKey:(NSNotification*)notification {
	(void)notification;
	
	[recentDocumentItems release];
	recentDocumentItems = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
	NSArray* recentFileURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	NSMenu* newRecentMenu = [[NSMenu new] autorelease];
	NSMenuItem* newTitleItem = [[NSMenuItem new] autorelease];
	NSMenuItem* oldTitleItem = [[openRecent menu] itemAtIndex:0];
	[newTitleItem setTitle:[oldTitleItem title]];
	[newRecentMenu addItem:newTitleItem];
	for (NSURL* recentURL in recentFileURLs) {
		NSString* filename = [recentURL path];
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:[filename lastPathComponent]];
		[newRecentMenu addItem:item];
		[recentDocumentItems setObject:filename forKey:item];
	}
	[openRecent setMenu:newRecentMenu];
	[openRecent setEnabled:([recentFileURLs count] ? YES : NO)];
}

@end
