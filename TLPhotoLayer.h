//
//  TLPhotoLayer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLInteractiveMapLayer.h"

@class TLPhoto;
@class TLSelectionManager;


@interface TLPhotoLayer : TLInteractiveMapLayer {
@private
	id delegate;
	id dataSource;
	
	NSMutableArray* pendingTrackingSet;
	TLSelectionManager* selectionManager;
	CGRect selectionBox;
	
	BOOL dragTarget;
	NSArray* previewLocations;
	NSArray* draggedPhotos;
	
	NSSet* potentialDisplayedPhotos;
	NSSet* displayedPhotos;
	NSOperationQueue* thumbnailQueue;
	NSMapTable* cachedThumbnails;
	CGLayerRef cachedErrorImage;
	
	double accuracyThreshold;
	BOOL markInaccuratePhotos;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) id dataSource;
- (void)reloadData;

@property (nonatomic, copy) NSSet* displayedPhotos;

@property (nonatomic, copy) NSArray* previewLocations;

@property (nonatomic, copy) NSSet* selectedPhotos;
- (void)selectPhotos:(NSArray*)photos byExtendingSelection:(BOOL)shouldExtend;

@property (nonatomic, assign) double accuracyThreshold;
@property (nonatomic, assign) BOOL markInaccuratePhotos;

@end


// Notifications posted
extern NSString* const TLPhotoMapLayerSelectionDidChangeNotification;


@interface NSObject (TLPhotoMapLayerDelegate)
- (void)photoMapLayerSelectionDidChange:(NSNotification*)notification;
@end


@interface NSObject (TLPhotoMapLayerDataSource)

- (NSArray*)photoLayer:(TLPhotoLayer*)layer
		photosInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj;


// drag source
- (BOOL)photoLayer:(TLPhotoLayer*)layer
	   writePhotos:(NSArray*)photos
	  toPasteboard:(NSPasteboard*)pasteboard;

- (NSDragOperation)photoLayer:(TLPhotoLayer*)layer
	  dragSourceMaskForPhotos:(NSArray*)photosDragging
		   destinationIsLocal:(BOOL)isLocal;

- (NSArray*)photoLayer:(TLPhotoLayer*)layer
	filenamesForPhotos:(NSArray*)photosDropped
 promisedAtDestination:(NSURL*)dropDestination;

- (void)photoLayer:(TLPhotoLayer*)layer
	 concludedDrag:(NSArray*)photosDragged
	 withOperation:(NSDragOperation)operation;


// drag destination
- (NSDragOperation)photoLayer:(TLPhotoLayer*)layer
				 validateDrop:(id < NSDraggingInfo >)dropInfo
				  withMapInfo:(id < TLMapInfo >)mapInfo;

- (BOOL)photoLayer:(TLPhotoLayer*)layer
		acceptDrop:(id < NSDraggingInfo >)dropInfo
	   withMapInfo:(id < TLMapInfo >)mapInfo;

- (void)photoLayerDropDidCancel:(TLPhotoLayer*)layer;

@end
