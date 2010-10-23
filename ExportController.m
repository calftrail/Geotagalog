//
//  ExportController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ExportController.h"

#import "TLMainThreadPerformer.h"


@interface ExportController ()
@property (nonatomic, assign) BOOL shouldCancel;
- (void)backgroundExport;
@end

@interface NSMapTable (TLExtensions)
- (NSSet*)tl_allKeys;
@end


@implementation ExportController

@synthesize delegate;
@synthesize projectWindow;
@synthesize itemsWithMetadata;
@synthesize workflow;
@synthesize warnings;
@synthesize shouldCancel;

- (id)init {
	self = [super init];
	if (self) {
		warnings = [NSMutableSet new];
	}
	return self;
}

- (void)dealloc {
	NSAssert(!exportSheet, @"Export controller should not be deallocated with sheet still set");
	[self setItemsWithMetadata:nil];
	[warnings release];
	[super dealloc];
}

- (void)loadSheet {
	if (![self projectWindow]) return;
	BOOL sheetLoaded = [NSBundle loadNibNamed:@"Export" owner:self];
	if (!sheetLoaded) return;
	
	[NSApp beginSheet:exportSheet
	   modalForWindow:[self projectWindow]
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	/* NOTE: while the use of 0 is not documented, it does help the
	 app keep from getting too antsy. This is corroborated by
	 http://www.cocoabuilder.com/archive/message/cocoa/2006/2/3/155978 */
	[NSApp cancelUserAttentionRequest:0];
}

- (void)unloadSheet {
	if (!exportSheet) return;
	[NSApp endSheet:exportSheet];
	[exportSheet orderOut:self];
	[exportSheet release];
	exportSheet = nil;
}

- (void)export {
	[self loadSheet];
	[progressMeter setUsesThreadedAnimation:YES];
	[progressMeter setIndeterminate:YES];
	[progressMeter startAnimation:self];
	[self performSelectorInBackground:@selector(backgroundExport) withObject:nil];
}

- (IBAction)cancel:(id)sender {
	(void)sender;
	[self setShouldCancel:YES];
	[progressText setStringValue:@"Cancelling export."];
	[cancelButton setEnabled:NO];
	[progressMeter setIndeterminate:YES];
	[progressMeter startAnimation:self];
}


#pragma mark Internal export implementation

- (void)notifyCancel {
	if ([[self delegate] respondsToSelector:@selector(exportDidCancel:)]) {
		[[[self delegate] tlMainThreadWait] exportDidCancel:self];
	}
	[[self tlMainThreadWait] unloadSheet];
}

- (void)notifyFail:(NSError*)err {
	if ([[self delegate] respondsToSelector:@selector(exportDidFail:withError:)]) {
		[[[self delegate] tlMainThreadWait] exportDidFail:self withError:err];
	}
	[[self tlMainThreadWait] unloadSheet];
}

- (void)notifyFinish {
	if ([[self delegate] respondsToSelector:@selector(exportDidFinish:)]) {
		[[[self delegate] tlMainThreadWait] exportDidFinish:self];
	}
	[[self tlMainThreadWait] unloadSheet];
}

- (void)backgroundExportMain {
	NSProgressIndicator* progressMeterMT = [progressMeter tlMainThreadProxy];
	NSTextField* progressTextMT = [progressText tlMainThreadProxy];
	
	[progressTextMT setStringValue:@"Preparing to geotag."];
	NSError* internalError;
	BOOL prepared = [self prepareForItems:[[self itemsWithMetadata] tl_allKeys]
									error:&internalError];
	if ([self shouldCancel]) {
		[self cancelExport];
		[self notifyCancel];
		return;
	}
	if (!prepared) {
		[self notifyFail:internalError];
		return;
	}
	
	[progressTextMT setStringValue:@"Exporting items."];
	[progressMeterMT setIndeterminate:NO];
	NSUInteger numTotalExport = [[self itemsWithMetadata] count];
	NSUInteger geotaggedIdx = 0;
	for (TLPhotoSourceItem* item in [self itemsWithMetadata]) {
		NSDictionary* metadata = [[self itemsWithMetadata] objectForKey:item];
		if ((id)metadata == [NSNull null]) {
			metadata = nil;
		}
		BOOL exported = [self exportItem:item
							withMetadata:metadata
								   error:&internalError];
		if (!exported) {
			[warnings addObject:internalError];
		}
		if ([self shouldCancel]) {
			break;
		}
		++geotaggedIdx;
		double exportPercent = geotaggedIdx / (double)numTotalExport;
		[progressMeterMT setDoubleValue:exportPercent];
	}
	
	if ([self shouldCancel]) {
		[self cancelExport];
		[self notifyCancel];
		return;
	}
	
	// prevent future cancellation, as we're about to finish export
	[[cancelButton tlMainThreadWait] setEnabled:NO];
	// user may have already cancelled, though
	if ([self shouldCancel]) {
		[self cancelExport];
		[self notifyCancel];
		return;
	}
	
	[progressTextMT setStringValue:@"Finishing export."];
	[progressMeterMT setIndeterminate:YES];
	[progressMeterMT startAnimation:self];
	BOOL finished = [self finishExport:&internalError];
	if (!finished) {
		[self notifyFail:internalError];
		return;
	}
	
	[self notifyFinish];
}

- (void)backgroundExport {
	NSAutoreleasePool* threadPool = [NSAutoreleasePool new];
	[self backgroundExportMain];
	[threadPool drain];
}


#pragma mark Export implementation stubs

- (BOOL)prepareForItems:(NSSet*)items
				  error:(NSError**)err
{
	(void)items;
	(void)err;
	return YES;
}

- (BOOL)exportItem:(TLPhotoSourceItem*)item
	  withMetadata:(NSDictionary*)metadata
			 error:(NSError**)err
{
	(void)item;
	(void)metadata;
	(void)err;
	return YES;
}

- (void)cancelExport {}

- (BOOL)finishExport:(NSError**)err {
	(void)err;
	return YES;
}

@end


@implementation NSMapTable (TLExtensions)

- (NSSet*)tl_allKeys {
	return [NSSet setWithArray:NSAllMapTableKeys(self)];
}

@end

