//
//  TLFilePhotoSource.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLPhotoSource.h"


@interface TLFilePhotoSource : TLPhotoSource {
@private
	NSString* name;
	NSImage* icon;
	NSError* error;
	BOOL isCurrent;
	BOOL isWorking;
	NSMutableSet* mutableItems;
	NSOperationQueue* workQueue;
	NSOperation* finalOperation;
	NSMutableSet* directlyAddedPaths;
	NSMutableSet* allPaths;
}

- (void)addPaths:(NSSet*)filePaths;

@end
