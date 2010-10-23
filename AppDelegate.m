//
//  AppDelegate.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "ProjectController.h"
#import "PhotoSourceController.h"
#import "TLImageCaptureManager.h"
#import "TaskExport.h"


#import "LaunchWindowController.h"
#import "PreferencesController.h"
#import "TrackWaitWindowController.h"

#import "TLGPXFileConversion.h"
#import "TLNMEAFileConversion.h"
#import "TLIGCFile.h"
#import "TLTCXFileConversion.h"


@interface AppDelegate ()
@property (nonatomic, retain) id launchWindowController;
@property (nonatomic, retain) ProjectController* projectController;
- (BOOL)openTracklog:(NSString*)tracklogURL;
@end


@implementation AppDelegate

@synthesize launchWindowController;
@synthesize projectController;

#pragma mark Lifecycle

- (void)awakeFromNib {
	launchWindowController = [LaunchWindowController new];
	preferencesController = [PreferencesController new];
}

- (void)dealloc {
	[launchWindowController release];
	[preferencesController release];
	[projectController release];
	[super dealloc];
}


#pragma mark User interface events

- (IBAction)showAcknowledgements:(id)sender {
	(void)sender;
	NSString* ackPath = [[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"html"];
	if (ackPath) {
		(void)[[NSWorkspace sharedWorkspace] openFile:ackPath];
	}
	else {
		NSLog(@"Could not find Acknowledgments file");
	}
}

- (IBAction)showPreferences:(id)sender {
	[preferencesController showWindow:sender];
}

- (IBAction)relaunchMetadataWorker:(id)sender {
	(void)sender;
	[TaskExport relaunchWorker];
}

- (IBAction)openDocument:(id)sender {
	(void)sender;
	
	NSOpenPanel* tracklogChooser = [NSOpenPanel openPanel];
	[tracklogChooser setAllowsMultipleSelection:YES];
	[tracklogChooser setTitle:@"Open Tracklogs"];
	[tracklogChooser setMessage:@"Please choose GPX, NMEA, IGC or TCX tracklog(s) to use for geotagging photos."];
	
	// NOTE: extension necessary to work around rdar://problem/6590416
	// TODO: gather extensions from Info.plist instead
	NSArray* tracklogTypes = [NSArray arrayWithObjects:
							  @"gpx", @"nmea", @"nme", @"gps", @"log", @"txt", @"igc", @"tcx", nil];
	NSInteger button = [tracklogChooser runModalForTypes:tracklogTypes];
	if (button == NSOKButton) {
		NSArray* tracklogPaths = [tracklogChooser filenames];
		if ([tracklogPaths count] > 1 && [[NSApp delegate] respondsToSelector:@selector(application:openFiles:)]) {
			[[NSApp delegate] application:NSApp openFiles:tracklogPaths];
		}
		else if ([[NSApp delegate] respondsToSelector:@selector(application:openFile:)]) {
			for (NSString* tracklogPath in tracklogPaths) {
				[[NSApp delegate] application:NSApp openFile:tracklogPath];
			}
		}
	}
}

- (BOOL)openTracklog:(NSString*)tracklogPath {
	TrackWaitWindowController* trackWaitController = [[TrackWaitWindowController new] autorelease];
	[trackWaitController setFilename:[tracklogPath lastPathComponent]];
	[trackWaitController begin];
	
	NSString* extension = [[tracklogPath pathExtension] lowercaseString];
	// TODO: grab extensions from Info.plist instead
	//NSDictionary* infoPlist = [[NSBundle mainBundle] infoDictionary];
	id trackFile = nil;
	NSError* trackFileError;
	NSURL* tracklogURL = [NSURL fileURLWithPath:tracklogPath isDirectory:NO];
	if ([extension isEqualToString:@"gpx"]) {
		trackFile = [[TLGPXFile alloc] initGPXFileWithContentsOfURL:tracklogURL error:&trackFileError];
	}
	else if ([extension isEqualToString:@"nmea"] ||
			 [extension isEqualToString:@"nme"] ||
			 [extension isEqualToString:@"gps"] ||
			 [extension isEqualToString:@"log"] ||
			 [extension isEqualToString:@"txt"])
	{
		trackFile = [(TLNMEAFile*)[TLNMEAFile alloc] initWithContentsOfURL:tracklogURL error:&trackFileError];
	}
	else if ([extension isEqualToString:@"igc"]) {
		trackFile = [(TLIGCFile*)[TLIGCFile alloc] initWithContentsOfURL:tracklogURL error:&trackFileError];
	}
	else if ([extension isEqualToString:@"tcx"]) {
		trackFile = [(TLTCXFile*)[TLTCXFile alloc] initWithContentsOfURL:tracklogURL error:&trackFileError];
	}
	else {
		NSString* message = @"Could not read tracklog file. Its extension is not recognized.";
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 message, NSLocalizedDescriptionKey,
								 tracklogURL, NSURLErrorKey, nil];
		trackFileError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:errInfo];
	}
	[trackFile autorelease];
	
	if (!trackFile) {
		[trackWaitController end];
		[NSApp presentError:trackFileError];
		return NO;
	}
	
	NSError* extractionError;
	NSArray* tracks = [trackFile extractTracks:&extractionError];
	NSArray* waypoints = [trackFile extractWaypoints:NULL];
	
	if (!tracks) {
		[trackWaitController end];
		[NSApp presentError:extractionError];
		return NO;
	}
	else if (![tracks count]) {
		NSString* message = NSLocalizedString(@"No tracks were found in the selected file. "
											  @"Please make sure it is a valid format and contains tracklog data.",
											  @"No tracks found error");
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 message, NSLocalizedDescriptionKey,
								 tracklogURL, NSURLErrorKey, nil];
		NSError* noTracksError = [NSError errorWithDomain:NSCocoaErrorDomain
													 code:NSFileReadUnknownError
												 userInfo:errInfo];
		[trackWaitController end];
		[NSApp presentError:noTracksError];
		return NO;
	}
	
	[trackWaitController end];
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:tracklogURL];
	
	if ([self projectController]) {
		[[self projectController] addTracks:[NSSet setWithArray:tracks]];
		[[self projectController] addWaypoints:[NSSet setWithArray:waypoints]];
	}
	else {
		id newProject = [[ProjectController alloc] initWithTracks:tracks];
		[newProject addWaypoints:[NSSet setWithArray:waypoints]];
		[self setProjectController:newProject];
		[newProject release];
		
		NSWindow* launchWindow = [[self launchWindowController] window];
		[launchWindow orderOut:self];
	}
	return YES;
}


#pragma mark Application events

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification {
	(void)aNotification;
	
#if (0)
	NSAlert* singleDocumentAlert = [[NSAlert new] autorelease];
	[singleDocumentAlert setAlertStyle:NSWarningAlertStyle];
	[singleDocumentAlert setMessageText:@"Pre-release version: BACKUPS REQUIRED!"];
	NSString* information = (@"Thank you for testing this pre-release version of Geotagalog.\n\n"
							 @"Make sure you have backups of your photos and iPhoto library! "
							 @"Many significant changes are being tested; if you find any issues, "
							 @"please email support@calftrail.com to let us know.");
	[singleDocumentAlert setInformativeText:information];
	(void)[singleDocumentAlert addButtonWithTitle:@"I have working backups"];
	(void)[singleDocumentAlert addButtonWithTitle:@"Cancel"];
	NSInteger button = [singleDocumentAlert runModal];
	if (button != NSAlertFirstButtonReturn) exit(0);
#endif
	
	[[TLImageCaptureManager sharedImageCaptureManager] updateImageCaptureEntry];
}


- (NSApplicationDelegateReply)openFiles:(NSArray*)filenames {
	if ([[self projectController] isExporting]) {
		NSBeep();
		return NSApplicationDelegateReplyFailure;
	}
	
	// we look for tracklogs only in the top level of filenames
	NSMutableSet* tracklogFiles = [NSMutableSet set];
	NSMutableSet* otherFiles = [NSMutableSet set];
	// TODO: grab extensions from Info.plist instead
	NSSet* tracklogExtensions = [NSSet setWithObjects:
								 @"gpx", @"nmea", @"nme", @"gps", @"log", @"txt", @"igc", @"tcx", nil];
	for (NSString* file in filenames) {
		NSString* fileExtension = [[file pathExtension] lowercaseString];
		if ([tracklogExtensions containsObject:fileExtension]) {
			[tracklogFiles addObject:file];
		}
		else {
			[otherFiles addObject:file];
		}
	}
	
	if ([tracklogFiles count] && [self projectController]) {
		NSAlert* singleDocumentAlert = [[NSAlert new] autorelease];
		[singleDocumentAlert setAlertStyle:NSWarningAlertStyle];
		[singleDocumentAlert setMessageText:@"A tracklog is already open."];
		NSString* information = (@"A geotagging session is already in progress. "
								 @"You may add to the available tracks, or start a new session using only these tracks.");
		[singleDocumentAlert setInformativeText:information];
		(void)[singleDocumentAlert addButtonWithTitle:@"Add tracks"];
		(void)[singleDocumentAlert addButtonWithTitle:@"Cancel"];
		(void)[singleDocumentAlert addButtonWithTitle:@"Start over"];
		NSInteger choice = [singleDocumentAlert runModal];
		
		if (choice == NSAlertSecondButtonReturn) {
			return NSApplicationDelegateReplyCancel;
		}
		
		if (choice == NSAlertThirdButtonReturn) {
			NSWindow* projectWindow = [[self projectController] window];
			[projectWindow close];
			[self setProjectController:nil];
		}
	}
	
	BOOL success = NO;
	for (NSString* tracklogFile in tracklogFiles) {
		success |= [self openTracklog:tracklogFile];
	}
	if ([otherFiles count]) {
		success |= [[[self projectController] sourceController] addItems:otherFiles];
	}
	return (success) ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure;
}

- (void)application:(NSApplication*)theApplication openFiles:(NSArray*)filenames {
	(void)theApplication;
	NSApplicationDelegateReply reply = [self openFiles:filenames];
	[NSApp replyToOpenOrPrint:reply];
}

- (BOOL)application:(NSApplication*)theApplication openFile:(NSString*)filename {
	(void)theApplication;
	NSApplicationDelegateReply reply = [self openFiles:[NSArray arrayWithObject:filename]];
	return (reply == NSApplicationDelegateReplySuccess);
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	(void)aNotification;
	
	if (![self projectController]) {
		NSWindow* launchWindow = [[self launchWindowController] window];
		[launchWindow makeKeyAndOrderFront:self];
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication {
	(void)theApplication;
	
	/* This method happens to be called when the project window is closed, so we use
	 it to clean up our project instance variable and show the launch window. */
	[self setProjectController:nil];
	NSWindow* launchWindow = [[self launchWindowController] window];
	[launchWindow makeKeyAndOrderFront:self];
	return NO;
}

@end
