//
//  TLPhotoSourceItem.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLPhotoSource;

@interface TLPhotoSourceItem : NSObject {
@private
	TLPhotoSource* source;
}

- (id)initWithSource:(TLPhotoSource*)theSource;

@property (nonatomic, readonly) TLPhotoSource* source;
@property (nonatomic, readonly) NSURL* originalURL;
@property (nonatomic, readonly) NSString* originalFilename;
@property (nonatomic, readonly) NSString* originalUTI;
@property (nonatomic, readonly) NSDictionary* metadata;

- (CGImageRef)newThumbnailForSize:(CGFloat)approximateSize
						  options:(NSDictionary*)options
							error:(NSError**)err;

- (NSURL*)exportToFolder:(NSURL*)targetDirectory
				   error:(NSError**)err;

@end

extern NSString* const TLMetadataTimestampKey;
extern NSString* const TLMetadataTimezoneKey;
extern NSString* const TLMetadataLocationKey;
extern NSString* const TLMetadataSoftwareNameKey;
