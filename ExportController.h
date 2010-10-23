//
//  ExportController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 5/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLPhotoSourceItem;

enum {
	iPhotoDatabase = 0,
	iPhotoOriginals = 1,
	justOriginals = 2
};


@interface ExportController : NSObject {
	IBOutlet NSWindow* exportSheet;
	__weak IBOutlet NSTextField* progressText;
	__weak IBOutlet NSProgressIndicator* progressMeter;
	__weak IBOutlet NSButton* cancelButton;
@private
	id delegate;
	NSWindow* projectWindow;
	NSSet* copiedItems;
	NSMapTable* itemsWithMetadata;
	NSUInteger workflow;
	BOOL shouldCancel;
	NSMutableSet* warnings;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSWindow* projectWindow;

@property (nonatomic, copy) NSMapTable* itemsWithMetadata;
@property (nonatomic, assign) NSUInteger workflow;

@property (nonatomic, readonly) NSSet* warnings;

- (void)export;
- (IBAction)cancel:(id)sender;

// for subclass implementation
- (BOOL)prepareForItems:(NSSet*)items
				  error:(NSError**)err;
- (BOOL)exportItem:(TLPhotoSourceItem*)item
	  withMetadata:(NSDictionary*)metadata
			 error:(NSError**)err;
- (void)cancelExport;
- (BOOL)finishExport:(NSError**)err;

@end

@interface NSObject (ExportControllerDelegate)
- (void)exportDidFinish:(ExportController*)theExportController;
- (void)exportDidCancel:(ExportController*)theExportController;
- (void)exportDidFail:(ExportController*)theExportController
			withError:(NSError*)err;
@end
