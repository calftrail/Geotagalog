//
//  TLPhotoSource.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLPhotoSource.h"

#import "TLPhotoSourceItem.h"

#import "TLLocation.h"
#import "TLTimestamp.h"
#import "NSFileManager+TLExtensions.h"
#import "NSURL+TLExtensions.h"


NSString* const TLImageCaptureSourceDidUpdateNotification = @"TLImageCapture_SourceDidUpdate";

@interface TLPhotoSource ()
- (void)engage;
- (void)disengage;
@property (nonatomic, assign) NSUInteger leashCount;
@end


@implementation TLPhotoSource

@synthesize leashCount;

- (id)init {
	self = [super init];
	if (self) {
		stableTZ = [[NSTimeZone systemTimeZone] copy];
	}
	return self;
}

- (BOOL)isEngaged {
	return [self leashCount] ? YES : NO;
}

- (id)leash {
	// retain ourselves to encourage proper usage
	[self retain];
	NSUInteger oldCount = [self leashCount];
	[self setLeashCount:(oldCount+1)];
	if (!oldCount) {
		[self engage];
	}
	return self;
}

- (void)unleash {
	NSUInteger oldCount = [self leashCount];
	NSAssert(oldCount, @"Photo source was over-unleashed.");
	[self setLeashCount:(oldCount-1)];
	if (oldCount == 1) {
		[self disengage];
	}
	[self release];
}

- (void)engage {
	//NSLog(@"engaging source %p", self);
}
- (void)disengage {
	//NSLog(@"disengaged source %p", self);
}

- (NSString*)name {
	return nil;
}

- (NSImage*)icon {
	return nil;
}

- (NSSet*)items {
	return [NSSet set];
}

- (NSError*)error {
	return nil;
}

- (BOOL)isWorking {
	return NO;
}

- (BOOL)isCurrent {
	return YES;
}

@end


@implementation TLPhotoSource (TLPhotoSourceItemHelpers)

- (NSTimeZone*)timeZone {
	return stableTZ;
}

@end



@implementation TLPhotoSource (ExifToolAdditions)

+ (NSSet*)geotaggableExtensions {
	// culled from 'exiftool -listwf'
	NSString* extensionList = [@"CR2 CS1 DNG ERF EXIF HDP JNG JP2 JPEG JPG JPX MEF MIE MNG MOS MRW NEF NRW ORF "
							   @"PEF PNG RAF RAW RW2 RWL THM TIF TIFF WDP XMP" lowercaseString];
	NSArray* extensions = [extensionList componentsSeparatedByString:@" "];
	return [NSSet setWithArray:extensions];
}

@end
