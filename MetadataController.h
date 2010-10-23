//
//  MetadataController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLTrackLayer;

@class TLPhotoLayer;
@class TLPhotoSource;
@class TLLocator;


@interface MetadataController : NSObject {
	__weak IBOutlet NSButton* exportAllButton;
	__weak IBOutlet NSButton* limitInaccuracyButton;
@private
	TLPhotoLayer* itemLayer;
	TLPhotoSource* itemSource;
	
	TLTrackLayer* locationLayer; 
	id locationSource;
	
	NSTimeInterval cameraError;
	NSTimeZone* cameraTimeZone;
	
	NSMapTable* itemPhotos;
	NSMutableSet* accurateItems;
	TLLocator* locator;
	BOOL readyForExport;
}

@property (nonatomic, retain) TLPhotoLayer* itemLayer;
@property (nonatomic, retain) TLPhotoSource* itemSource;

@property (nonatomic, retain) TLTrackLayer* locationLayer; 
@property (nonatomic, retain) id locationSource;

@property (nonatomic, assign) NSTimeInterval cameraError;
@property (nonatomic, copy) NSTimeZone* cameraTimeZone;

@property (nonatomic, readonly, assign, getter=isReadyForExport) BOOL readyForExport;
@property (nonatomic, readonly) NSMapTable* exportMetadata;

@end
