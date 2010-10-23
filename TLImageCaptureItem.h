//
//  TLImageCaptureItem.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLPhotoSourceItem.h"

@class TLImageCapturePhotoSource;

@interface TLImageCaptureItem : TLPhotoSourceItem {
@private
	UInt32 icao; /* TLICAObject */
	UInt32 fileType;
	NSString* originalFilename;
	NSDictionary* metadata;
}

-(id)initWithSource:(TLImageCapturePhotoSource*)theSource
			   info:(NSDictionary*)theInfo;

@end
