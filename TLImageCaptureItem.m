//
//  TLImageCaptureItem.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLImageCaptureItem.h"

#include "TLImageCapture.h"
#import "TLImageCapturePhotoSource.h"

#import "TLTimestamp.h"

#import "NSURL+TLExtensions.h"
#import "NSFileManager+TLExtensions.h"
#import "NSDateFormatter+TLAdditions.h"

extern NSString* TLMakeUUID(void);

// denotes location of 0-th row, 0-th column
typedef enum {
	TLImageOrientationTopLeft = 1,		// default orientation
	UIImageOrientationTopRight,			// flip horizontally (across |)
	TLImageOrientationBottomRight,		// rotate 180 deg
	TLImageOrientationBottomLeft,		// flip vertically (across -)
	TLImageOrientationLeftTop,			// rotate right, then flip vertically
	TLImageOrientationRightTop,			// rotate right (90 deg CW)
	TLImageOrientationRightBottom,		// rotate left, then flip vertically
	TLImageOrientationLeftBottom		// rotate left (90 deg CCW)
} TLImageOrientation;

static CGImageRef TLCGImageCreateOriented(CGImageRef srcImg, TLImageOrientation orientation);


@interface TLImageCaptureItem ()
@property (nonatomic, assign) TLICAObject icao;
@property (nonatomic, assign) UInt32 fileType;
@property (nonatomic, copy) NSString* originalFilename;
@property (nonatomic, copy) NSDictionary* metadata;
- (void)updateWithInfo:(NSDictionary*)theInfo;
- (NSURL*)exportToFolder:(NSURL*)targetDirectory
				   error:(NSError**)err
			shouldRename:(BOOL)shouldRename;
@end


@implementation TLImageCaptureItem

@synthesize icao;
@synthesize fileType;
@synthesize metadata;
@synthesize originalFilename;

-(id)initWithSource:(TLImageCapturePhotoSource*)theSource
			   info:(NSDictionary*)theInfo
{
	self = [super initWithSource:theSource];
	if (self) {
		//NSLog(@"%@", theInfo);
		TLICAObject theIcao = [[theInfo objectForKey:(id)kTLICAObjectKey] intValue];
		[self setIcao:theIcao];
		[self updateWithInfo:theInfo];
	}
	return self;
}

- (void)dealloc {
	[self setOriginalFilename:nil];
	[self setMetadata:nil];
	[super dealloc];
}

- (void)updateWithInfo:(NSDictionary*)theInfo {
	NSString* theFilename = [theInfo objectForKey:(id)kTLICAObjectNameKey];
	if (theFilename) {
		[self setOriginalFilename:theFilename];
	}
	
	NSNumber* itemType = [theInfo objectForKey:(id)kTLICAFileTypeKey];
	if (itemType) {
		[self setFileType:[itemType intValue]];
	}
	
	NSMutableDictionary* theMetadata = [[[self metadata] mutableCopy] autorelease];
	if (!theMetadata) {
		theMetadata = [NSMutableDictionary dictionary];
	}
	
	NSString* timestampString = [theInfo objectForKey:(id)kTLICAImageDateOriginalKey];
	if (!timestampString) {
		timestampString = [theInfo objectForKey:(id)kTLICAImageDateDigitizedKey];
	}
	
	NSDate* itemDate = nil;
	NSTimeZone* itemTimeZone = [[self source] timeZone];
	if (timestampString) {
		NSDateFormatter* timestampParser = [NSDateFormatter tl_tiffDateFormatter];
		[timestampParser setTimeZone:itemTimeZone];
		itemDate = [timestampParser dateFromString:timestampString];
	}
	if (itemDate) {
		TLTimestamp* timestamp = [TLTimestamp timestampWithTime:itemDate
													   accuracy:TLTimestampAccuracyUnknown];
		[theMetadata setObject:timestamp forKey:TLMetadataTimestampKey];
		[theMetadata setObject:itemTimeZone forKey:TLMetadataTimezoneKey];
	}
	
	[self setMetadata:theMetadata];
}

- (NSString*)originalUTI {
	NSString* uti = nil;
	switch ([self fileType]) {
		case kICAFileImage:
			uti = (id)kUTTypeImage;
			break;
		case kICAFileMovie:
			uti = (id)kUTTypeMovie;
			break;
		case kICAFileAudio:
			uti = (id)kUTTypeAudio;
			break;
		default:
			uti = (id)kUTTypeData;
			break;
	}
	return uti;
}

- (CGImageRef)newThumbnailForSize:(CGFloat)approximateSize
						  options:(NSDictionary*)options
							error:(NSError**)err
{
	(void)approximateSize;
	(void)options;
	(void)err;
	
	CFDataRef thumbnailData = NULL;
	ICACopyObjectThumbnailPB copyThumbnailPB = {};
	copyThumbnailPB.object = [self icao];
	copyThumbnailPB.thumbnailFormat = kICAThumbnailFormatJPEG;
	copyThumbnailPB.thumbnailData = &thumbnailData;
	ICAError internalErrCode = TLICACopyObjectThumbnail(&copyThumbnailPB, NULL);
	if (internalErrCode) {
		if (err) {
			*err = [NSError errorWithDomain:NSOSStatusErrorDomain code:internalErrCode userInfo:nil];
		}
		return NULL;
	}
	
	// fetch the object's properties so we can display thumbnails properly (see note below)
	CFDictionaryRef objectProperties = NULL;
	ICACopyObjectPropertyDictionaryPB copyPropertiesPB = {};
	copyPropertiesPB.object = [self icao];
	copyPropertiesPB.theDict = &objectProperties;
	internalErrCode = TLICACopyObjectPropertyDictionary(&copyPropertiesPB, NULL);
	if (internalErrCode) {
		if (err) {
			*err = [NSError errorWithDomain:NSOSStatusErrorDomain code:internalErrCode userInfo:nil];
		}
		return NULL;
	}
	NSNumber* orientationValue = (id)CFDictionaryGetValue(objectProperties, kTLICAImageOrientationKey);
	CFRelease(objectProperties);
	
	CGImageRef thumbnail = NULL;
	CGImageSourceRef thumbnailSource = CGImageSourceCreateWithData(thumbnailData, NULL);
	CFRelease(thumbnailData);
	if (thumbnailSource) {
		if (CGImageSourceGetCount(thumbnailSource)) {
			thumbnail = CGImageSourceCreateImageAtIndex(thumbnailSource, 0, NULL);
			/* NOTE: ICA does not autorotate thumbnail rdar://problem/6959922
			 So we must rotate it ourselves. */
			if (orientationValue) {
				TLImageOrientation orientation = [orientationValue unsignedIntValue];
				CGImageRef orientedThumbnail = TLCGImageCreateOriented(thumbnail, orientation);
				CGImageRelease(thumbnail);
				thumbnail = orientedThumbnail;
			}
		}
		CFRelease(thumbnailSource);
	}
	if (!thumbnail && err) {
		*err = [NSError errorWithDomain:NSOSStatusErrorDomain code:readErr userInfo:nil];
	}
	return thumbnail;
}

- (NSURL*)exportUniquedIntoFolder:(NSURL*)targetDirectory
						  error:(NSError**)err
{
	NSFileManager* fileManager = [NSFileManager tl_threadManager];
	NSString* uniqueFolder = [NSString stringWithFormat:@".com.calftrail-%@", TLMakeUUID()];
	NSURL* subfolder = [targetDirectory tl_URLByAppendingPathComponent:uniqueFolder];
	BOOL createdTempDir = [fileManager createDirectoryAtPath:[subfolder path]
								 withIntermediateDirectories:NO
												  attributes:nil
													   error:err];
	if (!createdTempDir) return nil;
	
	NSURL* uniquedExport = nil;
	NSURL* temporaryDownloadedURL = [self exportToFolder:subfolder
												   error:err
											shouldRename:NO];
	if (temporaryDownloadedURL) {
		NSURL* desiredTarget = [targetDirectory tl_URLByAppendingPathComponent:
								[temporaryDownloadedURL tl_lastPathComponent]];
		NSString* finalPath = [fileManager tl_moveItemAtPath:[temporaryDownloadedURL path]
												toUniquePath:[desiredTarget path]
													   error:err];
		if (finalPath) {
			uniquedExport = [NSURL fileURLWithPath:finalPath isDirectory:NO];
		}
	}
	(void)[fileManager removeItemAtPath:[subfolder path]
								  error:NULL];
	return uniquedExport;
}

- (NSURL*)exportToFolder:(NSURL*)targetDirectory
				   error:(NSError**)err
			shouldRename:(BOOL)shouldRename
{
	FSRef downloadHostFolder = {};
	Boolean success = CFURLGetFSRef((CFURLRef)targetDirectory, &downloadHostFolder);
	if (!success) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 targetDirectory, NSURLErrorKey, nil];
			*err = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:errInfo];
		}
		return nil;
	}
	
	FSRef downloadedFile = {};
	ICADownloadFilePB downloadFilePB = {};
	downloadFilePB.object = [self icao];
	downloadFilePB.flags = kAdjustCreationDate;
	downloadFilePB.dirFSRef = &downloadHostFolder;
	downloadFilePB.fileFSRef = &downloadedFile;
	/* NOTE: if large file cancellation is desired in the future,
	 or finer control of output location, check out ICACopyObjectData() */
	ICAError internalErrCode = TLICADownloadFile(&downloadFilePB, NULL);
	if (internalErrCode == dupFNErr && shouldRename) {
		/* NOTE: Image Capture will fail if a file with the same name already exists.
		 So we have to do our own conflict avoidance. */
		return [self exportUniquedIntoFolder:targetDirectory error:err];
	}
	else if (internalErrCode) {
		if (err) {
			*err = [NSError errorWithDomain:NSOSStatusErrorDomain code:internalErrCode userInfo:nil];
		}
		return NO;
	}
	
	NSURL* downloadedURL = (id)CFURLCreateFromFSRef(kCFAllocatorDefault, &downloadedFile);
	return [downloadedURL autorelease];
}

- (NSURL*)exportToFolder:(NSURL*)targetDirectory
				   error:(NSError**)err
{
	return [self exportToFolder:targetDirectory error:err shouldRename:YES];
}
	

@end


CGImageRef TLCGImageCreateOriented(CGImageRef srcImg, TLImageOrientation orientation) {
	// Only handle common rotations (for now). See http://www.gotow.net/creative/wordpress/?p=64
	CGSize srcSize = CGSizeMake(CGImageGetWidth(srcImg), CGImageGetHeight(srcImg));
	CGAffineTransform drawTransform = CGAffineTransformIdentity;
	BOOL flipAspect = NO;
	switch (orientation) {
		default:
		case TLImageOrientationTopLeft:
			return CGImageRetain(srcImg);
		case TLImageOrientationBottomRight:
			drawTransform = CGAffineTransformMakeTranslation(srcSize.width, srcSize.height);
			drawTransform = CGAffineTransformRotate(drawTransform, (CGFloat)M_PI);
			break;
		case TLImageOrientationRightTop:
			drawTransform = CGAffineTransformMakeTranslation(0.0f, srcSize.width);
			drawTransform = CGAffineTransformRotate(drawTransform, (CGFloat)-M_PI_2);
			flipAspect = YES;
			break;
		case TLImageOrientationLeftBottom:
			drawTransform = CGAffineTransformMakeTranslation(srcSize.height, 0.0f);
			drawTransform = CGAffineTransformRotate(drawTransform, (CGFloat)M_PI_2);
			flipAspect = YES;
			break;
	}
	
	CGSize targetSize = (flipAspect ?
						  CGSizeMake(CGImageGetHeight(srcImg), CGImageGetWidth(srcImg)) :
						  CGSizeMake(CGImageGetWidth(srcImg), CGImageGetHeight(srcImg)));
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL, targetSize.width, targetSize.height,
											 8, (size_t)targetSize.width * 4,
											 space, kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(space);
	NSCAssert(ctx, @"Couldn't create image flipping context");
	
	CGContextConcatCTM(ctx, drawTransform);
	CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size = srcSize}, srcImg);
	CGImageRef img = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return img;
}
