//
//  TLPhotoLayout.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 12/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLPhotoLayout.h"

#import "TLPhoto.h"
#import "TLLocation.h"
#include "TLGeometry.h"
#include "TLFloat.h"
#import "TLCocoaToolbag.h"


@class TLItemLayoutBox;
static TLItemLayoutBox* TLItemLayoutBoxesFindBiggest(NSSet* layoutBoxes, CGFloat minSize);
static NSArray* TLItemLayoutBoxesSortMostFirst(NSSet* layoutBoxes);
static void TLPhotoLayoutSetFrameForPhoto(NSMapTable* frames, CGRect frame, TLPhoto* photo);
static TLPhoto* TLPhotoLayoutFindClosest(NSSet* photos, CGRect rect, TLProjectionRef proj);

@interface TLItemLayoutBox : NSObject {
@private
	CGRect box;
	NSUInteger itemCount;
}

+ (id)layoutBoxWithRect:(CGRect)theBox;

@property (nonatomic, readonly) NSUInteger itemCount;
- (CGRect)rectForItem:(NSUInteger)itemIdx;
- (void)addItem;
- (CGFloat)sizeAfterNextItem;
@end


@implementation TLPhotoLayout

#pragma mark Lifecycle

- (id)initWithFrames:(NSMapTable*)theFrames anchors:(NSMapTable*)theAnchors {
	self = [super init];
	if (self) {
		frames = [theFrames copy];
		anchors = [theAnchors copy];
	}
	return self;
}

- (void)dealloc {
	[frames release];
	[anchors release];
	[super dealloc];
}

#pragma mark Accessors

- (BOOL)photoHasLayout:(TLPhoto*)photo {
	return TLBooleanCast([frames objectForKey:photo]);
}

- (CGRect)frameForPhoto:(TLPhoto*)photo {
	NSValue* frameValue = [frames objectForKey:photo];
	CGRect photoFrame = CGRectNull;
	if (frameValue) {
		photoFrame = NSRectToCGRect([frameValue rectValue]);
	}
	return photoFrame;
}

- (CGPoint)anchorForPhoto:(TLPhoto*)photo {
	NSValue* anchorValue = [anchors objectForKey:photo];
	CGPoint photoAnchor = CGPointZero;
	if (anchorValue) {
		photoAnchor = NSPointToCGPoint([anchorValue pointValue]);
	}
	return photoAnchor;
}


#pragma mark Actual geometry

+ (NSSet*)layoutBoxesForPhotos:(NSSet*)photos
					  inBounds:(CGRect)bounds
				withProjection:(TLProjectionRef)proj
					 badPhotos:(NSSet**)outOfBoundsPhotosPtr
{
	CGRect anchorBounds = CGRectNull;
	NSMutableSet* outOfBoundsPhotos = [NSMutableSet set];
	for (TLPhoto* photo in photos) {
		TLProjectionError err = TLProjectionErrorNone;
		CGPoint photoPoint = TLProjectionProjectCoordinate(proj, [[photo location] coordinate], &err);
		if (err || !CGRectContainsPoint(bounds, photoPoint)) {
			[outOfBoundsPhotos addObject:photo];
		}
		else {
			anchorBounds = TLCGRectExpandToIncludePoint(anchorBounds, photoPoint);
		}
	}
	if (CGRectIsNull(anchorBounds)) {
		return nil;
	}
	CGFloat leftWidth = CGRectGetMinX(anchorBounds) - CGRectGetMinX(bounds);
	CGFloat rightWidth = CGRectGetMaxX(bounds) - CGRectGetMaxX(anchorBounds);
	CGFloat bottomHeight = CGRectGetMinY(anchorBounds) - CGRectGetMinY(bounds);
	CGFloat topHeight = CGRectGetMaxY(bounds) - CGRectGetMaxY(anchorBounds);
	
	enum { top = 0, bottom = 1, left = 2, right = 3 };
	CGRect frameArray[4] = { CGRectNull, CGRectNull, CGRectNull, CGRectNull };
	if (CGRectGetWidth(anchorBounds) > CGRectGetHeight(anchorBounds)) {
		frameArray[top] = CGRectMake(CGRectGetMinX(bounds), CGRectGetMaxY(anchorBounds),
									 CGRectGetWidth(bounds), topHeight);
		frameArray[bottom] = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds),
										CGRectGetWidth(bounds), bottomHeight);
		CGFloat sideBaseY = CGRectGetMinY(bounds) + bottomHeight;
		CGFloat sideHeight = CGRectGetHeight(bounds) - bottomHeight - topHeight;
		frameArray[left] = CGRectMake(CGRectGetMinX(bounds), sideBaseY,
									  leftWidth, sideHeight);
		frameArray[right] = CGRectMake(CGRectGetMaxX(bounds) - rightWidth, sideBaseY,
									   rightWidth, sideHeight);
	}
	else {
		frameArray[left] = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds),
									  leftWidth, CGRectGetHeight(bounds));
		frameArray[right] = CGRectMake(CGRectGetMaxX(bounds) - rightWidth, CGRectGetMinY(bounds),
									   rightWidth, CGRectGetHeight(bounds));
		CGFloat capBaseX = CGRectGetMinX(bounds) + leftWidth;
		CGFloat capWidth = CGRectGetWidth(bounds) - leftWidth - rightWidth;
		frameArray[top] = CGRectMake(capBaseX, CGRectGetMaxY(bounds) - topHeight,
									 capWidth, topHeight);
		frameArray[bottom] = CGRectMake(capBaseX, CGRectGetMinY(bounds),
										capWidth, bottomHeight);
	}
	
	NSUInteger numFrames = sizeof(frameArray) / sizeof(*frameArray);
	NSMutableSet* boxes = [NSMutableSet setWithCapacity:numFrames];
	for (NSUInteger frameIdx = 0; frameIdx < numFrames; ++frameIdx) {
		TLItemLayoutBox* box = [TLItemLayoutBox layoutBoxWithRect:frameArray[frameIdx]];
		[boxes addObject:box];
	}
	if (outOfBoundsPhotosPtr) *outOfBoundsPhotosPtr = outOfBoundsPhotos;
	return boxes;
}

+ (NSMapTable*)framePhotos:(NSSet*)photos
					 inBox:(TLItemLayoutBox*)layoutBox
				projection:(TLProjectionRef)proj
{
	NSMapTable* boxFrames = [NSMapTable mapTableWithStrongToStrongObjects];
	NSMutableSet* remainingPhotos = [NSMutableSet setWithSet:photos];
	NSUInteger numItems = [layoutBox itemCount];
	for (NSUInteger itemIdx = 0; itemIdx < numItems; ++itemIdx) {
		CGRect photoFrame = [layoutBox rectForItem:itemIdx];
		TLPhoto* closestPhoto = TLPhotoLayoutFindClosest(remainingPhotos, photoFrame, proj);
		TLPhotoLayoutSetFrameForPhoto(boxFrames, photoFrame, closestPhoto);
		[remainingPhotos removeObject:closestPhoto];
	}
	return boxFrames;
}

+ (id)photoLayoutForPhotos:(NSSet*)photos
				  inBounds:(CGRect)bounds
			  minDimension:(CGFloat)minSize
				projection:(TLProjectionRef)proj

{
	NSSet* outOfBoundsPhotos = nil;
	NSSet* layoutBoxes = [self layoutBoxesForPhotos:photos
										   inBounds:bounds
									 withProjection:proj
										  badPhotos:&outOfBoundsPhotos];
	
	// add each photo to the "biggest" box in turn, until min size is reached
	NSUInteger numPhotosRemaining = [photos count] - [outOfBoundsPhotos count];
	while (numPhotosRemaining) {
		TLItemLayoutBox* bestBox = TLItemLayoutBoxesFindBiggest(layoutBoxes, minSize);
		if (!bestBox) break;
		[bestBox addItem];
		--numPhotosRemaining;
	}
	
	// add nearest photos to each box
	NSMapTable* photoFrames = [NSMapTable mapTableWithStrongToStrongObjects];
	NSArray* orderedBoxes = TLItemLayoutBoxesSortMostFirst(layoutBoxes);
	NSMutableSet* leftoverPhotos = [NSMutableSet setWithSet:photos];
	[leftoverPhotos minusSet:outOfBoundsPhotos];
	for (TLItemLayoutBox* box in orderedBoxes) {
		NSMapTable* boxFrames = [self framePhotos:leftoverPhotos inBox:box projection:proj];
		TLNSMapTableSetWithMapTable(photoFrames, boxFrames);
		[leftoverPhotos minusSet:TLNSMapTableAllKeys(boxFrames)];
	}
	
	// put leftover photos at minSize on anchor
	[leftoverPhotos unionSet:outOfBoundsPhotos];
	for (TLPhoto* photo in leftoverPhotos) {
		TLProjectionError err = TLProjectionErrorNone;
		CGPoint photoPoint = TLProjectionProjectCoordinate(proj, [[photo location] coordinate], &err);
		if (err) continue;
		CGRect photoRect = TLCGRectMakeAroundPoint(photoPoint, minSize, minSize);
		TLPhotoLayoutSetFrameForPhoto(photoFrames, photoRect, photo);
	}
	
	NSMapTable* photoAnchors = [NSMapTable mapTableWithStrongToStrongObjects];
	for (TLPhoto* photo in photos) {
		TLProjectionError err = TLProjectionErrorNone;
		CGPoint photoPoint = TLProjectionProjectCoordinate(proj, [[photo location] coordinate], &err);
		if (err) continue;
		NSValue* pointValue = [NSValue valueWithPoint:NSPointFromCGPoint(photoPoint)];
		[photoAnchors setObject:pointValue forKey:photo];
	}
	
	TLPhotoLayout* photoLayout = [[self alloc] initWithFrames:photoFrames
													  anchors:photoAnchors];
	return [photoLayout autorelease];
}

@end


@implementation TLItemLayoutBox

#pragma mark Lifecycle

- (id)initWithRect:(CGRect)theBox {
	self = [super init];
	if (self) {
		box = theBox;
	}
	return self;
}

+ (id)layoutBoxWithRect:(CGRect)theBox {
	TLItemLayoutBox* layoutBox = [[[self class] alloc] initWithRect:theBox];
	return [layoutBox autorelease];
}

@synthesize itemCount;

- (void)addItem {
	++itemCount;
}

- (CGFloat)sizeWithCount:(NSUInteger)theItemCount {
	CGFloat maxDimension = (CGFloat)fmax(CGRectGetWidth(box), CGRectGetHeight(box));
	CGFloat minDimension = (CGFloat)fmin(CGRectGetWidth(box), CGRectGetHeight(box));
	return (CGFloat)fmin(maxDimension / theItemCount, minDimension);
}

- (CGRect)rectForItem:(NSUInteger)itemIdx {
	CGFloat size = [self sizeWithCount:[self itemCount]];
	CGFloat boxWidth = CGRectGetWidth(box);
	CGFloat boxHeight = CGRectGetHeight(box);
	if (boxWidth > boxHeight) {
		// center height
		CGFloat frameBaseY = CGRectGetMinY(box) + (boxHeight - size) / 2.0f;
		// pad width
		CGFloat paddedWidth = boxWidth / [self itemCount];
		CGFloat frameBaseX = CGRectGetMinX(box) + (paddedWidth - size) / 2.0f;
		return CGRectMake(frameBaseX + itemIdx * paddedWidth, frameBaseY, size, size);
	}
	else {
		// center width
		CGFloat frameBaseX = CGRectGetMinX(box) + (boxWidth - size) / 2.0f;
		// pad height
		CGFloat paddedHeight = boxHeight / [self itemCount];
		CGFloat frameBaseY = CGRectGetMinY(box) + (paddedHeight - size) / 2.0f;
		return CGRectMake(frameBaseX, frameBaseY + itemIdx * paddedHeight, size, size);
	}
}

- (CGFloat)sizeAfterNextItem {
	return [self sizeWithCount:([self itemCount] + 1)];
}

@end


NSArray* TLItemLayoutBoxesSortMostFirst(NSSet* layoutBoxes) {
	NSSortDescriptor* countSort = [[NSSortDescriptor alloc] initWithKey:@"itemCount" ascending:NO];
	NSArray* descriptors = [NSArray arrayWithObject:countSort];
	[countSort release];
	return [[layoutBoxes allObjects] sortedArrayUsingDescriptors:descriptors];
}

TLItemLayoutBox* TLItemLayoutBoxesFindBiggest(NSSet* layoutBoxes, CGFloat minSize) {
	TLItemLayoutBox* bestBox = nil;
	CGFloat bestSize = NAN;
	for (TLItemLayoutBox* box in layoutBoxes) {
		CGFloat boxSize = [box sizeAfterNextItem];
		if (boxSize < minSize) continue;
		if (!bestBox || boxSize > bestSize) {
			bestBox = box;
			bestSize = boxSize;
		}
	}
	return bestBox;
}

void TLPhotoLayoutSetFrameForPhoto(NSMapTable* frames, CGRect frame, TLPhoto* photo) {
	NSValue* frameValue = [NSValue valueWithRect:NSRectFromCGRect(frame)];
	[frames setObject:frameValue forKey:photo];
}

TLPhoto* TLPhotoLayoutFindClosest(NSSet* photos, CGRect rect, TLProjectionRef proj) {
	CGPoint targetPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	TLPhoto* closestPhoto = nil;
	CGFloat closestDistanceSqd = NAN;
	for (TLPhoto* photo in photos) {
		TLProjectionError err = TLProjectionErrorNone;
		CGPoint photoPoint = TLProjectionProjectCoordinate(proj, [[photo location] coordinate], &err);
		if (err) continue;
		CGFloat photoDistanceSqd = TLPointDistanceSquared(photoPoint, targetPoint);
		if (!closestPhoto || photoDistanceSqd < closestDistanceSqd) {
			closestPhoto = photo;
			closestDistanceSqd = photoDistanceSqd;
		}
	}
	return closestPhoto;
}
