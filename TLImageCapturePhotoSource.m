//
//  TLImageCapturePhotoSource.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLImageCapturePhotoSource.h"

#import "TLImageCaptureItem.h"

#include "TLImageCapture.h"
#import "TLPhoto.h"
#import "TLCocoaToolbag.h"
#import "TLMainThreadPerformer.h"

#import "TLLocation.h"
#import "TLTimestamp.h"


extern NSString* TLFileUniqueCachePath(void);

@interface TLImageCapturePhotoSource ()
@property (nonatomic, readonly) NSString* cacheFolder;
@property (nonatomic, assign) ICASessionID sessionID;
@end


@implementation TLImageCapturePhotoSource

@synthesize icao;
@synthesize sessionID;
@synthesize name;
@synthesize icon;
@synthesize cacheFolder;
@synthesize items = mutableItems;

#pragma mark Lifecycle

// this method must be background-thread safe
- (id)initWithICAO:(ICAObject)theICAO {
	self = [super init];
	if (self) {
		icao = theICAO;
		
		ICAOpenSessionPB openPB = {};
		openPB.deviceObject = theICAO;
		ICAError err = TLICAOpenSession(&openPB, NULL);
		if (err || openPB.header.err) {
			NSLog(@"Could not open session with Image Capture source. "
				  @"Error %i or %i from TLICAOpenSession.",
				  (int)err, (int)openPB.header.err);
			[super dealloc];
			return nil;
		}
		sessionID = openPB.sessionID;
		
		CFDictionaryRef deviceProperties = NULL;
		ICACopyObjectPropertyDictionaryPB copyPropertiesPB = {};
		copyPropertiesPB.object = theICAO;
		copyPropertiesPB.theDict = &deviceProperties;
		err = TLICACopyObjectPropertyDictionary(&copyPropertiesPB, NULL);
		if (err || copyPropertiesPB.header.err) {
			NSLog(@"Could not get Image Capture source information. "
				  @"Error %i or %i from TLICACopyObjectPropertyDictionary.",
				  (int)err, (int)copyPropertiesPB.header.err);
			[super dealloc];
			return nil;
		}
		TLCFAutorelease(deviceProperties);
		
		//NSLog(@"%@", (id)deviceProperties);
		
		name = [(id)CFDictionaryGetValue(deviceProperties, kTLICAObjectNameKey) copy];
		
		CFDataRef thumbnailData = NULL;
		ICACopyObjectThumbnailPB copyThumbnailPB = {};
		copyThumbnailPB.object = theICAO;
		/* NOTE: using TIFF is important, as PNG (and obviously not JPEG) does not contain
		 alpha channel. Discovered via http://developer.apple.com/samplecode/MyPhoto/listing11.html */
		copyThumbnailPB.thumbnailFormat = kICAThumbnailFormatTIFF; //kICAThumbnailFormatPNG;
		copyThumbnailPB.thumbnailData = &thumbnailData;
		err = TLICACopyObjectThumbnail(&copyThumbnailPB, NULL);
		if (err || copyThumbnailPB.header.err) {
			/* NOTE: will return paramErr if no thumbnail is available
			 See http://openradar.appspot.com/6399474 for a filed bug. */
			if (err != paramErr) {
				NSLog(@"Could not get Image Capture source thumbnail icon. "
					  @"Error %i or %i from TLICACopyObjectThumbnail.",
					  (int)err, (int)copyThumbnailPB.header.err);
			}
		}
		else {
			icon = [[NSImage alloc] initWithData:(NSData*)thumbnailData];
			CFRelease(thumbnailData);
		}
		
		mutableItems = [NSMutableSet new];
		NSArray* mediaFiles = (id)CFDictionaryGetValue(deviceProperties, kTLICAMediaFilesKey);
		for (NSDictionary* fileInfo in mediaFiles) {
			TLImageCaptureItem* item = [[TLImageCaptureItem alloc]
										initWithSource:self info:fileInfo];
			[mutableItems addObject:item];
			[item release];
		}
	}
	return self;
}

- (void)dealloc {
	[name release];
	[icon release];
	[cacheFolder release];
	[mutableItems release];
	[super dealloc];
}

@end
