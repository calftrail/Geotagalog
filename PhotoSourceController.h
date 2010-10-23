//
//  PhotoSourceController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLPhotoSource;

@interface PhotoSourceController : NSObject {
	__weak IBOutlet NSPopUpButton* sourcePicker;
	__weak IBOutlet NSProgressIndicator* loadingSpinner;
@private
	TLPhotoSource* source;
	NSMapTable* menuItemSources;
}

@property (nonatomic, retain) TLPhotoSource* source;

- (BOOL)addItems:(NSSet*)itemPaths;

- (IBAction)sourceChanged:(id)sender;

@end
