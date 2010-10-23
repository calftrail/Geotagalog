//
//  TLImageCaptureManager.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLImageCaptureManager : NSObject {
@private
	NSMutableSet* mutableSources;
	BOOL begun;
}

+ (id)sharedImageCaptureManager;

@property (nonatomic, readonly) NSSet* sources;

- (void)updateImageCaptureEntry;
@property (nonatomic, assign) BOOL shouldAutoLaunch;

@end

extern NSString* const TLImageCaptureManagerSourcesDidUpdateNotification;
