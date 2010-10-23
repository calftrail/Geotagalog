//
//  TLImageCapturePhotoSource.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLPhotoSource.h"

// this avoids exposing all of carbon to the rest of the app
typedef UInt32 TLICAObject;
typedef UInt32 TLICASessionID;

@interface TLImageCapturePhotoSource : TLPhotoSource {
@private
	TLICAObject icao;
	TLICASessionID sessionID;
	NSString* name;
	NSImage* icon;
	NSString* cacheFolder;
	NSMutableSet* mutableItems;
}

- (id)initWithICAO:(TLICAObject)icao;
@property (nonatomic, readonly) TLICAObject icao;


@end
