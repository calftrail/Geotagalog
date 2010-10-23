//
//  TLFileSourceItem.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLFileSourceItem.h"

#import "TLFilePhotoSource.h"

#import "TLCocoaToolbag.h"
#import "TLTimestamp.h"
#import "NSFileManager+TLExtensions.h"
#import "NSDateFormatter+TLAdditions.h"


@interface TLFileSourceItem ()
@property (nonatomic, copy) NSDictionary* metadata;
@property (nonatomic, readonly) CGImageSourceRef imageSource;
- (void)updateWithProperties:(NSDictionary*)theProperties;
@end


@implementation TLFileSourceItem

@synthesize originalURL;
@synthesize originalUTI;
@synthesize metadata;
@synthesize imageSource;


- (id)initWithSource:(TLFilePhotoSource*)source
			originalURL:(NSURL*)theFileURL
			   error:(NSError**)err
{
	self = [super initWithSource:source];
	if (self) {
		originalURL = [theFileURL copy];
		originalUTI = [TLFileGetUTI(theFileURL) copy];
		
		if (UTTypeConformsTo((CFStringRef)originalUTI, kUTTypeImage)) {
			NSDictionary* sourceOptions = [NSDictionary dictionaryWithObjectsAndKeys:
										   originalUTI, (id)kCGImageSourceTypeIdentifierHint, nil];
			imageSource = CGImageSourceCreateWithURL((CFURLRef)theFileURL,
													 (CFDictionaryRef)sourceOptions);
		}
		
		if (imageSource && !CGImageSourceGetCount(imageSource)) {
			[self dealloc];
			if (err) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 theFileURL, NSURLErrorKey, nil];
				*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:errInfo];
			}
			return nil;
		}
		
		if (imageSource) {
			CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
			if (imgProperties) {
				[self updateWithProperties:(NSDictionary*)imgProperties];
				CFRelease(imgProperties);
			}
		}
		

	}
	return self;
}

- (void)dealloc {
	[originalURL release];
	[originalUTI release];
	[metadata release];
	if (imageSource) CFRelease(imageSource);
	[super dealloc];
}

- (NSString*)originalFilename {
	return [[[self originalURL] path] lastPathComponent];
}

- (void)updateWithProperties:(NSDictionary*)theProperties {
	//NSLog(@"%@", theProperties);
	NSMutableDictionary* theMetadata = [[[self metadata] mutableCopy] autorelease];
	if (!theMetadata) {
		theMetadata = [NSMutableDictionary dictionary];
	}
	
	NSString* timestampString = [[theProperties objectForKey:(id)kCGImagePropertyExifDictionary]
								 objectForKey:(id)kCGImagePropertyExifDateTimeOriginal];
	if (!timestampString) {
		timestampString = [[theProperties objectForKey:(id)kCGImagePropertyExifDictionary]
						   objectForKey:(id)kCGImagePropertyExifDateTimeDigitized];
		if (!timestampString) {
			timestampString = [[theProperties objectForKey:(id)kCGImagePropertyTIFFDictionary]
							   objectForKey:(id)kCGImagePropertyTIFFDateTime];
		}
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

+ (CFDictionaryRef)thumbnailOptionsForSize:(CGFloat)size {
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
							 [NSNumber numberWithDouble:size], (id)kCGImageSourceThumbnailMaxPixelSize,
							 (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform, nil];
	return (CFDictionaryRef)options;
}

- (CGImageRef)newThumbnailForSize:(CGFloat)approximateSize
						  options:(NSDictionary*)options
							error:(NSError**)err
{
	(void)approximateSize;
	(void)options;
	
	if (![self imageSource]) {
		if (err) {
			*err = [NSError errorWithDomain:NSCocoaErrorDomain
									   code:NSFileReadCorruptFileError
								   userInfo:nil];
		}
		return NULL;
	}
	
	CFDictionaryRef thumbnailOptions = [[self class] thumbnailOptionsForSize:approximateSize];
	CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex([self imageSource], 0, thumbnailOptions);
	if (!thumbnail && err) {
		*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
	}
	return thumbnail;
}

@end
