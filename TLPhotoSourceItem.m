//
//  TLPhotoSourceItem.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLPhotoSourceItem.h"

NSString* const TLMetadataTimestampKey = @"timestamp";
NSString* const TLMetadataTimezoneKey = @"timezone";
NSString* const TLMetadataLocationKey = @"location";
NSString* const TLMetadataSoftwareNameKey = @"software";


@implementation TLPhotoSourceItem

@synthesize source;

- (id)initWithSource:(TLPhotoSource*)theSource {
	self = [super init];
	if (self) {
		source = theSource;
	}
	return self;
}

- (NSURL*)originalURL {
	return nil;
}

- (NSString*)originalFilename {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString*)originalUTI {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSDictionary*)metadata {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (CGImageRef)newThumbnailForSize:(CGFloat)approximateSize
						  options:(NSDictionary*)options
							error:(NSError**)err
{
	(void)approximateSize;
	(void)options;
	(void)err;
	[self doesNotRecognizeSelector:_cmd];
	return NULL;
}

- (NSURL*)exportToFolder:(NSURL*)targetDirectory
				   error:(NSError**)err
{
	(void)targetDirectory;
	(void)err;
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
