//
//  Photos.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class iPhotoLibraryInterface;

@interface Photos : NSObject {
@private
	iPhotoLibraryInterface* library;
}

+ (id)sharedManager;

+ (int64_t)identifierForPhotoID:(id)photoID;
+ (NSString*)libraryForPhotoID:(id)photoID;


- (void)getPhotoIDForIdentifier:(int64_t)identifier
					  inLibrary:(NSString*)libraryPath
						respond:(void (^)(id photoID))block;
- (void)applyMetadata:(NSDictionary*)metadata
			toPhotoID:(id)photoID
			  respond:(void (^)(void))block;
- (void)findOriginals:(id)photoID
			  respond:(void (^)(NSArray* originalPaths))block;
@end


@interface PhotosImport : NSOperation {
@private
	NSMutableDictionary* fileInfo;
	BOOL forceCopy;
	NSString* hostFolder;
}
@property BOOL forceCopy;
@property (copy) NSString* hostFolder;
- (void)addFileToImport:(NSString*)path
				 before:(void (^)(NSOperation* importStarts))beforeBlock
				  after:(void (^)(BOOL didImport, NSSet* photoIDs))afterBlock;
@end
