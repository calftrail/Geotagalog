//
//  TLFileSourceItem.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLPhotoSourceItem.h"

@class TLFilePhotoSource;

@interface TLFileSourceItem : TLPhotoSourceItem {
@private
	NSURL* originalURL;
	NSString* originalUTI;
	NSDictionary* metadata;
	CGImageSourceRef imageSource;
}

- (id)initWithSource:(TLFilePhotoSource*)source
		 originalURL:(NSURL*)theFileURL
			   error:(NSError**)err;

@end
