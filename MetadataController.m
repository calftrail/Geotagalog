//
//  MetadataController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MetadataController.h"

#import "TLPhotoLayer.h"
#import "TLPhotoSource.h"
#import "TLPhotoSourceItem.h"
#import "TLPhoto.h"

#import "TLTrackLayer.h"

#import "TLLocator.h"
#import "TLLocation.h"
#import "TLTimestamp.h"
#import "TLWaypoint.h"

#import "TLCocoaToolbag.h"
#include "TLGeometry.h"

static const TLCoordinateAccuracy allowableInaccuracy = 50.0;

static NSString* const TLMercatalogInternalPhotosPboardType = @"com.calftrail.mercatalog.photo.pboard";
static BOOL TLMercatalogWriteItemsToPasteboard(NSArray* items, NSPasteboard* pboard, id owner);
static NSArray* TLMercatalogItemsFromPasteboard(NSPasteboard* pboard);
static NSArray* TLMercatalogFilesFromPasteboard(NSPasteboard* pboard);

@interface NSObject (TLTrackSourceDefinition)
@property (nonatomic, readonly) NSSet* tracks;
@property (nonatomic, readonly) NSSet* waypoints;
@end

@interface MetadataController ()
@property (nonatomic, retain) TLLocator* locator;
@property (nonatomic, readwrite) BOOL readyForExport;
- (void)updateExportReady;
- (void)relocatePhotos;
- (void)locatePhotos:(NSSet*)photos;
- (BOOL)shouldGeotag:(TLPhotoSourceItem*)item;
- (NSUInteger)countGeotagged;
@end


@implementation MetadataController

@synthesize itemLayer;
@synthesize itemSource;
@synthesize locationLayer;
@synthesize locationSource;
@synthesize cameraError;
@synthesize cameraTimeZone;
@synthesize locator;
@synthesize readyForExport;

- (id)init {
	self = [super init];
	if (self) {
		itemPhotos = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
		accurateItems = [NSMutableSet new];
		TLLocator* theLocator = [[TLLocator new] autorelease];
		[theLocator setDataSource:self];
		[self setLocator:theLocator];
		
		[self addObserver:self
			   forKeyPath:@"itemSource.items"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"itemSource.isCurrent"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"locationSource.tracks"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"locationSource.waypoints"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"cameraError"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"cameraTimeZone"
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.ExportAllItems"
																	 options:NSKeyValueObservingOptionNew
																	 context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.LimitInaccurateGeotagging"
																	 options:NSKeyValueObservingOptionNew
																	 context:NULL];
	}
	return self;
}

- (void)awakeFromNib {
	// ...
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"itemSource.items"];
	[self removeObserver:self forKeyPath:@"itemSource.isCurrent"];
	[self removeObserver:self forKeyPath:@"locationSource.tracks"];
	[self removeObserver:self forKeyPath:@"locationSource.waypoints"];
	[self removeObserver:self forKeyPath:@"cameraError"];
	[self removeObserver:self forKeyPath:@"cameraTimeZone"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ExportAllItems"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.LimitInaccurateGeotagging"];
	[self setItemLayer:nil];
	[self setItemSource:nil];
	[self setLocationLayer:nil];
	[self setLocationSource:nil];
	[self setCameraTimeZone:nil];
	[itemPhotos release];
	[accurateItems release];
	[[self locator] setDataSource:nil];
	[self setLocator:nil];
	[super dealloc];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	(void)object;
	(void)context;
	//NSLog(@"observed %@: %@", keyPath, change);
	
	BOOL shouldRelocateAll = NO;
	BOOL didLocatePhotos = NO;
	if ([keyPath isEqualToString:@"itemSource.items"]) {
		if ([[change objectForKey:NSKeyValueChangeKindKey]
			 unsignedIntegerValue] == NSKeyValueChangeInsertion)
		{
			// we optimize insertion to avoid O(n^2) behaviour during file source load
			NSSet* insertedPhotos = [change objectForKey:NSKeyValueChangeNewKey];
			[self locatePhotos:insertedPhotos];
			didLocatePhotos = YES;
		}
		else {
			[[self itemLayer] setSelectedPhotos:nil];
			[[self itemLayer] setDisplayedPhotos:nil];
			shouldRelocateAll = YES;
		}
	}
	else if ([keyPath isEqualToString:@"itemSource.isCurrent"] ||
			 [keyPath isEqualToString:@"values.ExportAllItems"])
	{
		[self updateExportReady];
	}
	else if ([keyPath isEqualToString:@"values.LimitInaccurateGeotagging"]) {
		didLocatePhotos = YES;
		[[self itemLayer] setMarkInaccuratePhotos:[[NSUserDefaults standardUserDefaults]
												   boolForKey:@"LimitInaccurateGeotagging"]];
		
	}
	else if ([keyPath isEqualToString:@"locationSource.tracks"]) {
		shouldRelocateAll = YES;
		[[self locator] reloadData];
		[[self locationLayer] reloadData];
	}
	else if ([keyPath isEqualToString:@"locationSource.waypoints"]) {
		[[self locationLayer] reloadData];
	}
	else if ([keyPath isEqualToString:@"cameraError"] ||
			 [keyPath isEqualToString:@"cameraTimeZone"])
	{
		shouldRelocateAll = YES;
	}
	
	if (shouldRelocateAll) {
		[self relocatePhotos];
		didLocatePhotos = YES;
	}
	
	if (didLocatePhotos) {
		BOOL inaccurates = [itemPhotos count] > [accurateItems count];
		[limitInaccuracyButton setEnabled:(inaccurates ? YES : NO)];
		
		BOOL ungeotaggables = [[[self itemSource] items] count] > [self countGeotagged];
		[exportAllButton setEnabled:(ungeotaggables ? YES : NO)];
		
		[self updateExportReady];
	}
}


#pragma mark Custom accessors

- (void)setItemLayer:(TLPhotoLayer*)newItemLayer {
	if (newItemLayer == itemLayer) return;
	[itemLayer setDataSource:nil];
	[itemLayer setRegisteredDragTypes:nil];
	[itemLayer release];
	[newItemLayer setDataSource:self];
	[newItemLayer setRegisteredDragTypes:
	 [NSArray arrayWithObjects:TLMercatalogInternalPhotosPboardType, NSFilenamesPboardType, nil]];
	[newItemLayer setAccuracyThreshold:allowableInaccuracy];
	[newItemLayer setMarkInaccuratePhotos:[[NSUserDefaults standardUserDefaults]
										   boolForKey:@"LimitInaccurateGeotagging"]];
	itemLayer = [newItemLayer retain];
}

- (TLPhotoLayer*)itemLayer {
	if (!itemLayer) {
		[self setItemLayer:[[TLPhotoLayer new] autorelease]];
	}
	return itemLayer;
}

- (void)setLocationLayer:(TLTrackLayer*)newLocationLayer {
	if (newLocationLayer == locationLayer) return;
	[locationLayer setDataSource:nil];
	[locationLayer release];
	[newLocationLayer setDataSource:self];
	locationLayer = [newLocationLayer retain];
}

- (TLTrackLayer*)locationLayer {
	if (!locationLayer) {
		[self setLocationLayer:[[TLTrackLayer new] autorelease]];
	}
	return locationLayer;
}

- (NSUInteger)countGeotagged {
	BOOL rejectInaccurateLocations = [[NSUserDefaults standardUserDefaults]
									  boolForKey:@"LimitInaccurateGeotagging"];
	return rejectInaccurateLocations ? [accurateItems count] : [itemPhotos count];
}

- (NSMapTable*)exportMetadata {
	NSString* fullAppName = nil;
	{
		NSDictionary* appInfo = [[NSBundle mainBundle] infoDictionary];
		NSString* appName = [appInfo objectForKey:(id)kCFBundleNameKey];
		NSString* appVersion = [appInfo objectForKey:@"CFBundleShortVersionString"];
		fullAppName = [NSString stringWithFormat:@"%@ v%@", appName, appVersion];
	}
	
	bool adjustTimestamps = !([[NSUserDefaults standardUserDefaults] boolForKey:@"DontAdjustTimestamps"]);
	bool exportUngeotagged = ([exportAllButton isEnabled] && [exportAllButton intValue]);
	bool tagInaccurates = !([[NSUserDefaults standardUserDefaults] boolForKey:@"LimitInaccurateGeotagging"]);
	
	NSMapTable* itemMetadata = [NSMapTable mapTableWithStrongToStrongObjects];
	for (TLPhotoSourceItem* item in [[self itemSource] items]) {
		TLPhoto* photo = [itemPhotos objectForKey:item];
		if (!photo) {
			if (exportUngeotagged) [itemMetadata setObject:[NSNull null] forKey:item];
			continue;
		}
		
		NSMutableDictionary* metadata = [NSMutableDictionary dictionary];
		if ([accurateItems containsObject:item] || tagInaccurates) {
			[metadata setObject:[photo location] forKey:TLMetadataLocationKey];
		}
		else if (!exportUngeotagged) {
			continue;
		}
		
		if (adjustTimestamps) {
			[metadata setObject:[photo timestamp] forKey:TLMetadataTimestampKey];
			[metadata setObject:[photo timeZone] forKey:TLMetadataTimezoneKey];
		}
		
		if ([metadata count]) {
			[metadata setObject:fullAppName forKey:TLMetadataSoftwareNameKey];
		}
		else {
			metadata = (id)[NSNull null];
		}
		[itemMetadata setObject:metadata forKey:item];
	}
	return itemMetadata;
}


#pragma mark locationLayer/locator data source

- (NSArray*)trackLayer:(TLTrackLayer*)layer
		tracksInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj
{
	(void)layer;
	(void)bounds;
	(void)proj;
	return [[[self locationSource] tracks] allObjects];
}

- (NSArray*)trackLayer:(TLTrackLayer*)layer
	 waypointsInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj
{
	(void)layer;
	(void)bounds;
	(void)proj;
	return [[[self locationSource] waypoints] allObjects];
}

- (NSSet*)locatorNeedsTracks:(TLLocator*)aLocator {
	(void)aLocator;
	return [[self locationSource] tracks];
}


#pragma mark itemLayer data source

- (NSArray*)photoLayer:(TLPhotoLayer*)layer
		photosInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj
{
	(void)layer;
	(void)bounds;
	(void)proj;
	
	NSMutableArray* photos = [NSMutableArray array];
	for (TLPhotoSourceItem* item in itemPhotos) {
		TLPhoto* photo = [itemPhotos objectForKey:item];
		[photos addObject:photo];
	}
	return photos;
}


#pragma mark mapLayer delegate methods

- (BOOL)photoLayer:(TLPhotoLayer*)layer
	   writePhotos:(NSArray*)photos
	  toPasteboard:(NSPasteboard*)pasteboard
{
	(void)layer;
	
	NSArray* items = [photos valueForKeyPath:@"self.item"];
	NSAssert([items count] == [photos count], @"Did not properly extract items from dragged photos!");
	return TLMercatalogWriteItemsToPasteboard(items, pasteboard, self);
}

- (TLLocation*)locationForMouseInMap:(CGPoint)targetPoint withInfo:(id < TLMapInfo >)mapInfo {
	TLProjectionError err = TLProjectionErrorNone;
	TLCoordinate mouseCoord = TLProjectionUnprojectPoint([mapInfo projection], targetPoint, &err);
	if (err) return nil;
	CGSize interactiveSize = [mapInfo significantInteractiveSize];
	CGFloat interactiveDistance = TLSizeGetAverageWidth(interactiveSize);
	TLCoordinateAccuracy mouseAccuracy = interactiveDistance / 2.0f;
	return [TLLocation locationWithCoordinate:mouseCoord
						   horizontalAccuracy:mouseAccuracy];
}

- (NSSet*)timestampsForMouseInMap:(CGPoint)targetPoint withInfo:(id < TLMapInfo >)mapInfo {
	TLLocation* mouseLocation = [self locationForMouseInMap:targetPoint withInfo:mapInfo];
	if (!mouseLocation) return nil;
	const double trackSnapFactor = 20.0f;
	TLCoordinateAccuracy searchDistance = trackSnapFactor * [mouseLocation horizontalAccuracy];
	TLLocation* searchLocation = [TLLocation locationWithCoordinate:[mouseLocation coordinate]
												 horizontalAccuracy:searchDistance];
	return [[self locator] trackTimestampsAtLocation:searchLocation];
}

- (TLTimestamp*)timestampNearestPhoto:(TLPhoto*)firstPhoto inTimestamps:(NSSet*)timestamps {
	NSDate* targetDate = [[firstPhoto timestamp] time];
	
	TLTimestamp* closestTimestamp = nil;
	NSTimeInterval closestInterval = 0.0;
	for (TLTimestamp* timestamp in timestamps) {
		NSTimeInterval interval = fabs([targetDate timeIntervalSinceDate:[timestamp time]]);
		if (!closestTimestamp || interval < closestInterval) {
			closestTimestamp = timestamp;
			closestInterval = interval;
		}
	}
	return closestTimestamp;
}

- (NSDragOperation)photoLayer:(TLPhotoLayer*)layer
				 validateDrop:(id < NSDraggingInfo >)dropInfo
				  withMapInfo:(id < TLMapInfo >)mapInfo
{
	(void)layer;
	
	NSPasteboard* pasteboard = [dropInfo draggingPasteboard];
	NSArray* draggedItems = TLMercatalogItemsFromPasteboard(pasteboard);
	if (![draggedItems count]) {
		// check if files are being dropped
		NSArray* filenames = TLMercatalogFilesFromPasteboard(pasteboard);
		return [filenames count] ? NSDragOperationLink : NSDragOperationNone;
	}
	
	CGPoint mouseOnMap = [mapInfo convertWindowPointToMap:[dropInfo draggingLocation]];
	NSSet* mouseTimestamps = [self timestampsForMouseInMap:mouseOnMap withInfo:mapInfo];
	if ([mouseTimestamps count]) {
		TLPhotoSourceItem* draggedItem = [draggedItems objectAtIndex:0];
		TLPhoto* draggedPhoto = [itemPhotos objectForKey:draggedItem];
		TLTimestamp* mouseTimestamp = [self timestampNearestPhoto:draggedPhoto
													 inTimestamps:mouseTimestamps];
		
		/* Find which necessaryCameraError will make draggedPhoto have mouseTimestamp,
		 assuming: timestamp = timezone + error */
		NSTimeInterval timestampOffset = [[mouseTimestamp time]
										  timeIntervalSinceDate:[[draggedPhoto timestamp] time]];
		NSTimeInterval currentCameraError = [self cameraError];
		NSTimeInterval necessaryCameraError = currentCameraError + timestampOffset;
		[self setCameraError:necessaryCameraError];
	}
	
	return NSDragOperationPrivate;
}

- (void)delayedOpenFilenames:(NSArray*)filenames {
	[[NSApp delegate] application:NSApp openFiles:filenames];
}

- (BOOL)photoLayer:(TLPhotoLayer*)layer
		acceptDrop:(id < NSDraggingInfo >)dropInfo
	   withMapInfo:(id < TLMapInfo >)mapInfo
{
	(void)layer;
	(void)mapInfo;
	
	NSPasteboard* pasteboard = [dropInfo draggingPasteboard];
	NSArray* draggedItems = TLMercatalogItemsFromPasteboard(pasteboard);
	if ([draggedItems count]) {
		return YES;
	}
	else {
		NSArray* filenames = TLMercatalogFilesFromPasteboard(pasteboard);
		if ([filenames count] &&
			[[NSApp delegate] respondsToSelector:@selector(application:openFiles:)])
		{
			/* NOTE: opening files can cause window to be closed, but Cocoa's drag infrastructure
			 still wants to send the zombie an -[NSWindow enableCursorRects:] message.
			 Delaying the open lets the drag complete before any dialogs might appear. */
			//[[NSApp delegate] application:NSApp openFiles:filenames];
			[self performSelector:@selector(delayedOpenFilenames:) withObject:filenames afterDelay:0.1];
			return YES;
		}
	}
	return NO;
}

#pragma mark Tagging helpers/accessors

- (BOOL)shouldGeotag:(TLPhotoSourceItem*)item {
	NSSet* validExtensions = [TLPhotoSource geotaggableExtensions];
	NSString* itemExtension = [[[item originalFilename] pathExtension] lowercaseString];
	return ([validExtensions containsObject:itemExtension] &&
			[[item metadata] objectForKey:TLMetadataTimestampKey]);
}

- (void)setLocationsForItems:(NSSet*)items
			 withCameraError:(NSTimeInterval)error
					timeZone:(NSTimeZone*)timeZone
{
	NSMapTable* photoTimestamps = [NSMapTable mapTableWithStrongToStrongObjects];
	for (TLPhotoSourceItem* photoItem in items) {
		if (![self shouldGeotag:photoItem]) {
			[itemPhotos removeObjectForKey:photoItem];
			[accurateItems removeObject:photoItem];
			continue;
		}
		
		NSDate* originalDate = [[[photoItem metadata] objectForKey:TLMetadataTimestampKey] time];
		NSTimeZone* originalTimeZone = [[photoItem metadata] objectForKey:TLMetadataTimezoneKey];
		NSInteger tzDifference = ([timeZone secondsFromGMTForDate:originalDate] -
								  [originalTimeZone secondsFromGMTForDate:originalDate]);
		NSTimeInterval totalError = error - tzDifference;
		NSDate* correctedDate = [originalDate addTimeInterval:totalError];
		TLTimestamp* timestamp = [TLTimestamp timestampWithTime:correctedDate
													   accuracy:TLTimestampAccuracyUnknown];
		[photoTimestamps setObject:timestamp forKey:photoItem];
	}
	//if ([photoTimestamps count] > 1) NSLog(@"Geotagging %lu items.", (long unsigned)[photoTimestamps count]);
	
	NSTimeZone* exportTimezone = [NSTimeZone systemTimeZone];
	NSMapTable* photoLocations = [[self locator] locateTimestamps:photoTimestamps];
	for (TLPhotoSourceItem* photoItem in photoLocations) {
		TLPhoto* photo = [itemPhotos objectForKey:photoItem];
		if (!photo) {
			photo = [[[TLPhoto alloc] initWithItem:photoItem] autorelease];
			[itemPhotos setObject:photo forKey:photoItem];
		}
		[photo setLocation:[photoLocations objectForKey:photoItem]];
		[photo setTimestamp:[photoTimestamps objectForKey:photoItem]];
		[photo setTimeZone:exportTimezone];
		
		if ([[photo location] horizontalAccuracy] > allowableInaccuracy) {
			[accurateItems removeObject:photoItem];
		}
		else {
			[accurateItems addObject:photoItem];
		}
	}
}

- (void)locatePhotos:(NSSet*)photos {
	// TODO: improve architecture so this isn't necessary
	[[self itemLayer] setSelectedPhotos:nil];
	[[self itemLayer] setDisplayedPhotos:nil];
	
	[self setLocationsForItems:photos
			   withCameraError:[self cameraError]
					  timeZone:[self cameraTimeZone]];
	[[self itemLayer] reloadData];
}

- (void)relocatePhotos {
	// TODO: improve architecture so this isn't necessary
	[[self itemLayer] setSelectedPhotos:nil];
	[[self itemLayer] setDisplayedPhotos:nil];
	
	[itemPhotos removeAllObjects];
	[accurateItems removeAllObjects];
	[self setLocationsForItems:[[self itemSource] items]
			   withCameraError:[self cameraError]
					  timeZone:[self cameraTimeZone]];
	[[self itemLayer] reloadData];
}

- (void)updateExportReady {
	BOOL sourceIsCurrent = [[self itemSource] isCurrent];
	BOOL haveItemsForExport = ([self countGeotagged] ||
							   ([exportAllButton isEnabled] && [exportAllButton intValue]));
	[self setReadyForExport:(sourceIsCurrent && haveItemsForExport)];
}

@end




BOOL TLMercatalogWriteItemsToPasteboard(NSArray* items, NSPasteboard* pboard, id owner) {
	NSArray* supportedDragTypes = [NSArray arrayWithObject:TLMercatalogInternalPhotosPboardType];
	(void)[pboard declareTypes:supportedDragTypes owner:owner];
	
	NSMutableArray* itemsPropertyList = [NSMutableArray arrayWithCapacity:[items count]];
	for (id item in items) {
		NSData* itemPtrData = [NSData dataWithBytes:&item length:sizeof(id)];
		[itemsPropertyList addObject:itemPtrData];
	}
	return [pboard setPropertyList:itemsPropertyList
						   forType:TLMercatalogInternalPhotosPboardType];
}

NSArray* TLMercatalogItemsFromPasteboard(NSPasteboard* pboard) {
	NSArray* internalDropTypes = [NSArray arrayWithObject:TLMercatalogInternalPhotosPboardType];
	NSString* internalType = [pboard availableTypeFromArray:internalDropTypes];
	if (!internalType) return nil;
	
	NSArray* itemPointers= [pboard propertyListForType:internalType];
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[itemPointers count]];
	for (NSData* itemPtrData in itemPointers) {
		id item = *(id*)[itemPtrData bytes];
		[items addObject:item];
	}
	return items;
}

NSArray* TLMercatalogFilesFromPasteboard(NSPasteboard* pboard) {
	NSArray* externalDropTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
	NSString* externalType = [pboard availableTypeFromArray:externalDropTypes];
	if (!externalType) return nil;
	return [pboard propertyListForType:externalType];
}
