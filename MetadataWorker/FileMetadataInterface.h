//
//  FileMetadataInterface.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FileMetadataInterface : NSObject {
@private
}

+ (id)interface;

- (BOOL)writeMetadata:(NSDictionary*)metadata
				toURL:(NSURL*)fileURL
				error:(NSError**)err;

- (BOOL)verifyMetadata:(NSDictionary*)metadata
			  original:(NSURL*)originalFileURL
			  modified:(NSURL*)modifiedFileURL
				 error:(NSError**)err;

@end
