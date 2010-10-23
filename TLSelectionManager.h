//
//  TLSelectionManager.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
	TLSelectionManagerModelAddition = 0,
	TLSelectionManagerModelFixedPoint
};
typedef NSUInteger TLSelectionManagerModel;

@interface TLSelectionManager : NSObject {
@private
	id delegate;
	
	NSSet* selectedItems;
	
	TLSelectionManagerModel continuousSelectionModel;
	NSSet* anchorItems;
	NSSet* previousHitItems;
	
	NSUInteger dragMode;
	NSSet* selectionBeforeDrag;
	NSEvent* mouseDownEvent;
	NSSet* deferredDeselection;
}

@property (nonatomic, assign) id delegate;

@property (nonatomic, assign) TLSelectionManagerModel continuousSelectionModel;

@property (nonatomic, copy) NSSet* selectedItems;
- (void)selectItems:(NSSet*)items byExtendingSelection:(BOOL)shouldExtend;

- (void)mouseDown:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseDragged:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseUp:(NSEvent*)mouseEvent;

@end


@interface NSObject (TLSelectionManagerDelegate)

- (void)selectionManagerDidChangeSelection:(TLSelectionManager*)manager;

- (BOOL)selectionManagerShouldSelectMultipleItems:(TLSelectionManager*)manager
										withEvent:(NSEvent*)mouseDownEvent
										 userInfo:(void*)userInfo;

// may return nil
- (id)selectionManager:(TLSelectionManager*)manager
		itemUnderPoint:(NSPoint)windowPoint
			  userInfo:(void*)userInfo;

// may return nil or an empty set
- (NSSet*)selectionManager:(TLSelectionManager*)manager
		allItemsUnderPoint:(NSPoint)windowPoint
				  userInfo:(void*)userInfo;


- (NSSet*)selectionManager:(TLSelectionManager*)manager
		 itemsBetweenItems:(NSSet*)items1
				  andItems:(NSSet*)items2
				  userInfo:(void*)userInfo;


- (NSSet*)selectionManager:(TLSelectionManager*)manager
				itemsInBox:(NSRect)windowRect
				  userInfo:(void*)userInfo;


- (BOOL)selectionManagerShouldInitiateDragLater:(TLSelectionManager*)manager
									  dragEvent:(NSEvent*)dragEvent
								  originalEvent:(NSEvent*)mouseDownEvent
									   userInfo:(void*)userInfo;

@end
