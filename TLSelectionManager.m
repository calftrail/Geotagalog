//
//  TLSelectionManager.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLSelectionManager.h"

#import "TLGeometry.h"

static const NSUInteger TLSMContinuousSelectionMask = NSShiftKeyMask;
static const NSUInteger TLSMDiscontinuousSelectionMask = NSCommandKeyMask;
//static const NSUInteger TLSMBoxSelectionMask = NSAlternateKeyMask;
static const NSUInteger TLSMClickMultipleItemsMask = NSAlternateKeyMask;


@interface TLSelectionManager ()
- (void)deselectItems:(NSSet*)unwantedItems;
@property (nonatomic, retain) NSEvent* mouseDownEvent;
@property (nonatomic, copy) NSSet* deferredDeselection;
@property (nonatomic, copy) NSSet* anchorItems;
@property (nonatomic, copy) NSSet* previousHitItems;
@property (nonatomic, copy) NSSet* selectionBeforeDrag;
- (CGFloat)dragThreshold;
- (BOOL)shouldResetExistingSelection;
@end


enum {
	TLSMDragModeIgnore = 0,
	TLSMDragModeAttemptDrag,
	TLSMDragModeFlipSelection,
	TLSMDragModeExtendSelection
};
typedef NSUInteger TLSMDragMode;


@implementation TLSelectionManager

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		// ...
	}
	return self;
}

- (void)dealloc {
	[selectedItems release];
	
	[anchorItems release];
	[previousHitItems release];
	
	[selectionBeforeDrag release];
	[mouseDownEvent release];
	[deferredDeselection release];
	
	[super dealloc];
}


#pragma mark Basic accessors

@synthesize delegate;
@synthesize continuousSelectionModel;
@synthesize selectedItems;
@synthesize mouseDownEvent;
@synthesize deferredDeselection;
@synthesize anchorItems;
@synthesize previousHitItems;
@synthesize selectionBeforeDrag;

- (void)setSelectedItems:(NSSet*)newSelectedItems {
	if (!selectedItems && !newSelectedItems) return;
	else if ([selectedItems isEqualToSet:newSelectedItems]) return;
	[selectedItems autorelease];
	selectedItems = [newSelectedItems copy];
	if ([[self delegate] respondsToSelector:@selector(selectionManagerDidChangeSelection:)]) {
		[[self delegate] selectionManagerDidChangeSelection:self];
	}
}

- (void)selectItems:(NSSet*)items byExtendingSelection:(BOOL)shouldExtend {
	if (shouldExtend && [self selectedItems]) {
		NSSet* extendedSelection = [[self selectedItems] setByAddingObjectsFromSet:items];
		[self setSelectedItems:extendedSelection];
	}
	else {
		[self setSelectedItems:items];
	}
}

- (void)deselectItems:(NSSet*)unwantedItems {
	NSSet* previousSelection = [self selectedItems];
	if (!previousSelection) return;
	NSMutableSet* newSelection = [NSMutableSet setWithSet:previousSelection];
	[newSelection minusSet:unwantedItems];
	[self setSelectedItems:newSelection];
}

- (CGFloat)dragThreshold {
	/* NOTE: drag must move at least 3 pixels before initiated according to
	 http://developer.apple.com/documentation/UserExperience/Conceptual/AppleHIGuidelines/XHIGDragDrop/chapter_13_section_5.html */
	return 3.0f;
}

- (BOOL)shouldResetExistingSelection {
	return NO;
}


#pragma mark Mouse handling

- (NSSet*)continuousSelectionBasedOnHitItems:(NSSet*)hitItems userInfo:(void*)userInfo {
	/*
	 Continous selection seems to be the least consistently implemented selection method amongst all of AppKit's views.
	 There are two basic models: "fixed-point" and "addition". Fixed-point anchors the selection at the last "normally"
	 selected items and all continuous selection is between those items and the new items. Addition either "adds on" or
	 it "chops off" (as little as possible).
	 
	 (See http://developer.apple.com/documentation/UserExperience/Conceptual/AppleHIGuidelines/XHIGUserInput/chapter_12_section_4.html
	 #//apple_ref/doc/uid/TP30000361-TPXREF24 as well as http://daringfireball.net/2006/08/highly_selective for other discussion.)
	 
	 As far as implementation, there are three pertinent item sets:
	 - anchorItems
	 - previousHitItems
	 - hitItems (i.e. the current ones)
	 
	 The current hitItems should be always be recorded in previousHitItems. In any non-continous selection,
	 the anchorItems are set to nil which signals they are the same as previousHitItems. 
	 
	 If in "fixed-point" mode, the anchorItems are not updated except when nil.
	 If in "addition" mode, the current anchorItems and previousHitItems compete. Whichever yields the largest
	 selection vis-a-vis the current hitItems gets set as the anchorItems. Then in either continuous selection mode,
	 the new selection includes the hitItems, the achorItems and everything in between.
	 */
	
	// check to make sure we have enough information
	NSAssert([delegate respondsToSelector:@selector(selectionManager:itemsBetweenItems:andItems:userInfo:)],
			 @"Caller must verify continuous selection delegate support");
	BOOL anchorAndPreviousSame = NO;
	if (![[self previousHitItems] count]) {
		NSAssert(![self anchorItems], @"Selection anchor items left in unkempt state");
		return hitItems;
	}
	if (![[self anchorItems] count]) {
		[self setAnchorItems:[self previousHitItems]];
		anchorAndPreviousSame = YES;
	}
	
	NSSet* itemsBetween = nil;
	if (anchorAndPreviousSame || [self continuousSelectionModel] == TLSelectionManagerModelFixedPoint) {
		itemsBetween = [delegate selectionManager:self
								itemsBetweenItems:[self anchorItems]
										 andItems:hitItems
										 userInfo:userInfo];
	}
	else {	// assume ([self continuousSelectionModel] == TLSelectionManagerModelAddition)
		NSSet* anchorResult = [delegate selectionManager:self
									   itemsBetweenItems:[self anchorItems]
												andItems:hitItems
												userInfo:userInfo];
		NSSet* previousResult = [delegate selectionManager:self
										 itemsBetweenItems:[self previousHitItems]
												  andItems:hitItems
												  userInfo:userInfo];
		if ([previousResult count] > [anchorResult count]) {
			[self setAnchorItems:[self previousHitItems]];
			itemsBetween = previousResult;
		}
		else {
			itemsBetween = anchorResult;
		}
	}
	
	NSMutableSet* allItems = [NSMutableSet setWithSet:itemsBetween];
	[allItems unionSet:hitItems];
	[allItems unionSet:[self anchorItems]];
	return allItems;
}

- (void)mouseDown:(NSEvent*)mouseEvent userInfo:(void*)userInfo {
	[self setMouseDownEvent:mouseEvent];
	
	// see if multiple items should be requested from delegate
	BOOL attemptMultiple = TLBooleanCast([mouseEvent modifierFlags] & TLSMClickMultipleItemsMask);
	if ([delegate respondsToSelector:@selector(selectionManagerShouldSelectMultipleItems:withEvent:userInfo:)]) {
		attemptMultiple = [delegate selectionManagerShouldSelectMultipleItems:self withEvent:mouseEvent userInfo:userInfo];
	}
	
	// get hit item(s)
	NSSet* hitItems = nil;
	NSPoint windowPoint = [mouseEvent locationInWindow];
	if (attemptMultiple && [delegate respondsToSelector:@selector(selectionManager:allItemsUnderPoint:userInfo:)]) {
		hitItems = [delegate selectionManager:self allItemsUnderPoint:windowPoint userInfo:userInfo];
	}
	else if ([delegate respondsToSelector:@selector(selectionManager:itemUnderPoint:userInfo:)]) {
		id hitItem = [delegate selectionManager:self itemUnderPoint:windowPoint userInfo:userInfo];
		if (hitItem) hitItems = [NSSet setWithObject:hitItem];
	}
	
	BOOL isContinuousSelection = TLBooleanCast([mouseEvent modifierFlags] & TLSMContinuousSelectionMask);
	BOOL isDiscontinuousSelection = TLBooleanCast([mouseEvent modifierFlags] & TLSMDiscontinuousSelectionMask);
	if (isDiscontinuousSelection) {
		// discontinuous overrides continuous
		isContinuousSelection = NO;
	}
	if (isContinuousSelection && ![delegate respondsToSelector:@selector(selectionManager:itemsBetweenItems:andItems:userInfo:)]) {
		// treat as discontinuous if delegate doesn't provide support for continuous selection
		isContinuousSelection = NO;
		isDiscontinuousSelection = YES;
	}
	
	/* We never completely clear selection if an "extend selection" modifier is held.
	 This is not how table views do it, but it is how column views work.
	 Outline views never seem to clear their selection. */
	BOOL keepSelection = TLBooleanCast(isDiscontinuousSelection || isContinuousSelection);
	
	if ([hitItems count]) {
		/* Unless a brand new selection is being started, we deselect on mouse *up*.
		 Unlike column views, outline and table views don't defer deselection, but that seems broken. */
		NSSet* allHitItems = hitItems;
		if (!attemptMultiple && [selectedItems count] &&
			[delegate respondsToSelector:@selector(selectionManager:allItemsUnderPoint:userInfo:)])
		{
			allHitItems = [delegate selectionManager:self allItemsUnderPoint:windowPoint userInfo:userInfo];
		}
		BOOL itemsWereAlreadySelected = [[self selectedItems] intersectsSet:allHitItems];
		if (itemsWereAlreadySelected) {
			if (isContinuousSelection) {
				NSSet* resultingSelection = [self continuousSelectionBasedOnHitItems:hitItems userInfo:userInfo];
				NSMutableSet* unselectedItems = [NSMutableSet setWithSet:[self selectedItems]];
				[unselectedItems minusSet:resultingSelection];
				[self setDeferredDeselection:unselectedItems];
			}
			if (isDiscontinuousSelection) {
				[self setDeferredDeselection:hitItems];
			}
			else {
				if ([self shouldResetExistingSelection]) {
					NSMutableSet* missedItems = [NSMutableSet setWithSet:[self selectedItems]];
					[missedItems minusSet:hitItems];
					[self setDeferredDeselection:missedItems];
				}
			}
		}
		else {
			if (isContinuousSelection) {
				NSSet* resultingSelection = [self continuousSelectionBasedOnHitItems:hitItems userInfo:userInfo];
				[self selectItems:resultingSelection byExtendingSelection:NO];
			}
			else if (isDiscontinuousSelection) {
				[self selectItems:hitItems byExtendingSelection:YES];
			}
			else {
				[self selectItems:hitItems byExtendingSelection:NO];
			}
		}
		dragMode = TLSMDragModeAttemptDrag;
		[self setPreviousHitItems:hitItems];
		if (!isContinuousSelection) [self setAnchorItems:nil];
	}
	else {
		if ([mouseEvent modifierFlags] & NSCommandKeyMask) {
			dragMode = TLSMDragModeFlipSelection;
		}
		else {
			dragMode = TLSMDragModeExtendSelection;
		}
		
		if (!keepSelection) {
			[self setSelectedItems:nil];
			[self setPreviousHitItems:nil];
			[self setAnchorItems:nil];
		}
	}
}

- (void)mouseDraggedItems:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	NSEvent* downEvent = [self mouseDownEvent];
	
	if (![[self selectedItems] count]) return;
	
	CGFloat dragDistance = TLPointDistance(NSPointToCGPoint([dragEvent locationInWindow]),
										   NSPointToCGPoint([downEvent locationInWindow]));
	if (dragDistance < [self dragThreshold]) return;
	
	// NOTE: must initiate only once, otherwise a drag cancelled via escape will be restarted
	BOOL initiateLater = NO;
	if ([[self delegate] respondsToSelector:@selector(selectionManagerShouldInitiateDragLater:dragEvent:originalEvent:userInfo:)]) {
		initiateLater = [[self delegate] selectionManagerShouldInitiateDragLater:self
																	   dragEvent:dragEvent
																   originalEvent:downEvent
																		userInfo:userInfo];
	}
	
	if (!initiateLater) {
		// signals that a drag is "done"
		dragMode = TLSMDragModeIgnore;
	}
}

- (void)mouseDraggedSelection:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	(void)userInfo;
	
	NSSet* originalSelection = [self selectionBeforeDrag];
	if (!originalSelection) {
		// remember original selection at beginning of drag
		originalSelection = [self selectedItems] ? [self selectedItems] : [NSSet set];
		[self setSelectionBeforeDrag:originalSelection];
	}
	
	NSPoint point1 = [[self mouseDownEvent] locationInWindow];
	NSPoint point2 = [dragEvent locationInWindow];
	NSRect selectionBox = NSMakeRect((CGFloat)fmin(point1.x, point2.x),
									 (CGFloat)fmin(point1.y, point2.y),
									 (CGFloat)fabs(point2.x - point1.x),
									 (CGFloat)fabs(point2.y - point1.y));
	
	NSSet* itemsInBox = nil;
	if ([[self delegate] respondsToSelector:@selector(selectionManager:itemsInBox:userInfo:)]) {
		itemsInBox = [[self delegate] selectionManager:self itemsInBox:selectionBox userInfo:userInfo];
	}
	else {
		itemsInBox = [NSSet set];
	}
	
	NSSet* newSelection = nil;
	if (dragMode == TLSMDragModeFlipSelection) {
		NSMutableSet* addedItems = [NSMutableSet setWithSet:itemsInBox];
		[addedItems minusSet:originalSelection];
		newSelection = [NSMutableSet setWithSet:originalSelection];
		[(NSMutableSet*)newSelection minusSet:itemsInBox];
		[(NSMutableSet*)newSelection unionSet:addedItems];
	}
	else if	(dragMode == TLSMDragModeExtendSelection) {
		newSelection = [originalSelection setByAddingObjectsFromSet:itemsInBox];
	}
	NSAssert1(newSelection, @"Bad drag mode (%lu)", (long unsigned)dragMode);
	[self setSelectedItems:newSelection];
}

- (void)mouseDragged:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	if (!dragMode) return;
	NSAssert([self mouseDownEvent], @"No mouse down event stored for drag");
	
	if (dragMode == TLSMDragModeAttemptDrag) {
		[self mouseDraggedItems:dragEvent userInfo:userInfo];
	}
	else {
		[self mouseDraggedSelection:dragEvent userInfo:userInfo];
	}
}

- (void)mouseUp:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	
	if ([self mouseDownEvent]) {
		[self deselectItems:[self deferredDeselection]];
		[self setDeferredDeselection:nil];
		[self setMouseDownEvent:nil];
		[self setSelectionBeforeDrag:nil];
	}
}

@end
