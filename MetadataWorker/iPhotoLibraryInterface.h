//
//  iPhotoLibraryInterface.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 9/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class iPhotoItemID;

@interface iPhotoLibraryInterface : NSObject {
@private
	NSString* libraryPath;
	void* dbHandle;
	void* itemQuery;
}
+ (id)interfaceWithCurrentLibrary;

@property (readonly) NSString* libraryPath;
- (BOOL)open:(NSError**)err;
- (void)close;

- (iPhotoItemID*)itemWithKey:(int64_t)databaseKey;

// existing items
- (NSSet*)existingItemsForURL:(NSURL*)imageURL error:(NSError**)err;
- (NSArray*)originalURLsForItem:(iPhotoItemID*)item error:(NSError**)err;
- (BOOL)setMetadata:(NSDictionary*)metadata
		   forItems:(NSSet*)items
			  error:(NSError**)err;

// new items
- (NSArray*)importURLs:(NSArray*)fileURLs
			   options:(NSDictionary*)options
				 error:(NSError**)err;

@end


@interface iPhotoItemID : NSObject <NSCopying> {
@private
	iPhotoLibraryInterface* library;
	int64_t databaseKey;
}
@property (nonatomic, readonly) iPhotoLibraryInterface* library;
@property (nonatomic, readonly) int64_t databaseKey;
- (NSString*)libraryName;
@end
