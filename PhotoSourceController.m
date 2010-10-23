//
//  PhotoSourceController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoSourceController.h"

#import "TLImageCaptureManager.h"
#import "TLImageCapturePhotoSource.h"
#import "TLFilePhotoSource.h"

@interface PhotoSourceController ()
- (void)refreshSources;
@end


@implementation PhotoSourceController

@synthesize source;

- (void)setSource:(TLPhotoSource*)newSource {
	if (newSource == source) return;
	[source unleash];
	source = [newSource leash];
}

- (void)awakeFromNib {
	[loadingSpinner setUsesThreadedAnimation:YES];
	
	[[TLImageCaptureManager sharedImageCaptureManager] addObserver:self
														forKeyPath:@"sources"
														   options:(NSKeyValueObservingOptionNew |
																	// need old to get removed sources
																	NSKeyValueObservingOptionOld |
																	NSKeyValueObservingOptionInitial)
														   context:NULL];
	[self addObserver:self
		   forKeyPath:@"source.name"
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	[self addObserver:self
		   forKeyPath:@"source.isWorking"
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	
}

- (void)dealloc {
	[[TLImageCaptureManager sharedImageCaptureManager] removeObserver:self forKeyPath:@"sources"];
	[self removeObserver:self forKeyPath:@"source.name"];
	[self removeObserver:self forKeyPath:@"source.isWorking"];
	[self setSource:nil];
	[menuItemSources release], menuItemSources = nil;
	[super dealloc];
}

- (void)refreshSources {
	NSMenu* newSourceMenu = [[NSMenu new] autorelease];
	NSMenuItem* titleItem = [[NSMenuItem new] autorelease];
	if ([self source]) {
		[titleItem setTitle:[[self source] name]];
	}
	else {
		[titleItem setTitle:@"Choose photo source..."];
	}
	[newSourceMenu addItem:titleItem];
	
	NSSet* newSources = [[TLImageCaptureManager sharedImageCaptureManager] sources];
	[menuItemSources release];
	menuItemSources = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
	for (TLPhotoSource* newSource in newSources) {
		if (newSource == [self source]) continue;
		NSMenuItem* item = [[NSMenuItem new] autorelease];
		[item setTitle:[newSource name]];
		/* TODO: re-enable when generic ICA and folder sources get icons
		NSImage* icon = [[[newSource icon] copy] autorelease];
		CGFloat textSize = 1.5f * [[NSFont menuFontOfSize:0] pointSize];
		[icon setSize:NSMakeSize(textSize, textSize)];
		[item setImage:icon]; */
		[newSourceMenu addItem:item];
		[menuItemSources setObject:newSource forKey:item];
	}
	NSMenuItem* folderItem = [[NSMenuItem new] autorelease];
	[folderItem setTitle:@"Choose files or folders..."];
	[newSourceMenu addItem:folderItem];
	[sourcePicker setMenu:newSourceMenu];
}

- (void)automaticallySetSourceIfDesirable {
	if (![self source]) {
		NSSet* currentSources = [[TLImageCaptureManager sharedImageCaptureManager] sources];
		if ([currentSources count] == 1) {
			[self setSource:[currentSources anyObject]];
		}
	}
	[self refreshSources];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	(void)object;
	(void)change;
	(void)context;
	//NSLog(@"Observed %@: %@", keyPath, change);
	if ([keyPath isEqualToString:@"sources"]) {
		if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval) {
			NSSet* removedSources = [change objectForKey:NSKeyValueChangeOldKey];
			if ([removedSources containsObject:[self source]]) {
				[self setSource:nil];
			}
		}
		[self performSelector:@selector(automaticallySetSourceIfDesirable)
				   withObject:nil
				   afterDelay:0.5];
		[self refreshSources];
	}
	else if ([keyPath isEqualToString:@"source.name"]) {
		[self refreshSources];
	}
	else if ([keyPath isEqualToString:@"source.isWorking"]) {
		NSError* anError = [[self source] isWorking] ? nil : [[self source] error];
		if (anError) {
			[NSApp presentError:anError];
		}
	}
}

- (IBAction)sourceChanged:(id)sender {
	(void)sender;
	
	NSMenuItem* item = [sourcePicker selectedItem];
	TLPhotoSource* pickedSource = [menuItemSources objectForKey:item];
	if (pickedSource) {
		[self setSource:pickedSource];
		[self refreshSources];
	}
	else {
		NSOpenPanel* filePicker = [NSOpenPanel openPanel];
		[filePicker setCanChooseFiles:YES];
		[filePicker setCanChooseDirectories:YES];
		[filePicker setAllowsMultipleSelection:YES];
		// NOTE: by including extensions instead of just UTIs, rdar://6410673 workaround is easier
		NSInteger button = [filePicker runModalForTypes:
							[NSArray arrayWithObjects:(id)kUTTypeImage, (id)kUTTypeJPEG, @"jpg",  nil]];
		if (button == NSOKButton) {
			NSArray* files = [filePicker filenames];
			TLFilePhotoSource* newSource = [[TLFilePhotoSource new] autorelease];
			[newSource addPaths:[NSSet setWithArray:files]];
			[self setSource:newSource];
			[self refreshSources];
		}
	}
}

- (BOOL)readyForExport {
	return [[self source] isCurrent];
}

- (BOOL)addItems:(NSSet*)itemPaths {
	if ([[self source] isKindOfClass:[TLImageCapturePhotoSource class]]) {
		NSAlert* singleDocumentAlert = [[NSAlert new] autorelease];
		[singleDocumentAlert setAlertStyle:NSWarningAlertStyle];
		[singleDocumentAlert setMessageText:@"Cannot add items to current photo source."];
		NSString* information = (@"A non-file source is selected. "
								 @"Would you like to switch sources?");
		[singleDocumentAlert setInformativeText:information];
		(void)[singleDocumentAlert addButtonWithTitle:@"Use files"];
		(void)[singleDocumentAlert addButtonWithTitle:@"Cancel"];
		NSInteger choice = [singleDocumentAlert runModal];
		if (choice == NSAlertSecondButtonReturn) {
			return NO;
		}
		else {
			[self setSource:nil];
		}
	}
	if (![self source]) {
		TLFilePhotoSource* newSource = [[TLFilePhotoSource new] autorelease];
		[self setSource:newSource];
		[self refreshSources];
	}
	//NSLog(@"Adding paths: %@\n", itemPaths);
	[(TLFilePhotoSource*)[self source] addPaths:itemPaths];
	return YES;
}

@end
