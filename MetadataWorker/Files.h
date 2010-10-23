//
//  Files.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class FileMetadataInterface;

@interface Files : NSObject {
@private
	FileMetadataInterface* writer;
}

+ (id)sharedManager;

- (void)applyMetadata:(NSDictionary*)metadata
			   toFile:(NSString*)theFile
			  respond:(void (^)(void))block;

@end
