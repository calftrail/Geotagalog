//
//  FileMetadataInterface.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "FileMetadataInterface.h"

#import "NSDateFormatter+TLExtensions.h"
#import "NSTask+TLExtensions.h"


@implementation FileMetadataInterface

+ (id)interface {
	return [[[self class] new] autorelease];
}

- (BOOL)writeMetadata:(NSDictionary*)metadata
				toURL:(NSURL*)fileURL
				error:(NSError**)err
{
	NSString* toolPath = [[NSBundle mainBundle] pathForResource:@"exiftool" ofType:nil];
	NSMutableArray* args = [NSMutableArray array];
	
	NSNumber* latVal = [metadata objectForKey:@"latitude"];
	NSNumber* lonVal = [metadata objectForKey:@"longitude"];
	if (latVal && lonVal) {
		// delete any current tag to avoid merging two sets of values
		[args addObject:@"-GPS:all="];
		[args addObject:@"-GPSMapDatum=WGS-84"];
		
		double latitude = [latVal doubleValue];
		double longitude = [lonVal doubleValue];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSLatitude=%f", fabs(latitude)]];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSLatitudeRef=%c", (latitude < 0.0 ? 'S' : 'N')]];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSLongitude=%f", fabs(longitude)]];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSLongitudeRef=%c", (longitude < 0.0 ? 'W' : 'E')]];
	}
	
	NSNumber* altVal = [metadata objectForKey:@"altitude"];
	if (altVal) {
		double altitude = [altVal doubleValue];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSAltitude=%f", fabs(altitude)]];
		[args addObject:
		 [NSString stringWithFormat:@"-GPSAltitudeRef=%c", (altitude < 0.0 ? '1' : '0')]];
	}
	
	NSDate* timestamp = [metadata objectForKey:@"timestamp"];
	if (timestamp) {
		NSDateFormatter* format = [NSDateFormatter tl_tiffDateFormatter];
		NSString* dateString = [format stringFromDate:timestamp];
		[args addObject:
		 [NSString stringWithFormat:@"-DateTimeOriginal=%@", dateString]];
	}
	
	NSString* software = [metadata objectForKey:@"software"];
	if (software) {
		[args addObject:
		 [NSString stringWithFormat:@"-Software=%@", software]];
	}
	
	BOOL preserveAttributes = YES;		// slower, but better
	if (preserveAttributes) {
		[args addObject:@"-overwrite_original_in_place"];
	}
	else {
		[args addObject:@"-overwrite_original"];
	}
	
	[args addObject:@"-n"];		// disable print conversion (it affects writing)
	[args addObject:@"-fast"];	// this ignores metadata at end of file
	[args addObject:@"-ignoreMinorErrors"];
	[args addObject:@"-quiet"];
	//[args addObject:@"-quiet"];	// adding second quiet silences warnings as well
	[args addObject:[fileURL path]];
	
	//printf("Calling '%s' with %s\n", [toolPath UTF8String], [[args description] UTF8String]);
	NSTask* exifTool = [NSTask tl_completedTask:toolPath arguments:args error:err];
	if (!exifTool) return NO;
	if ([exifTool terminationStatus] != EXIT_SUCCESS) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Could not set image metadata", NSLocalizedDescriptionKey,
									 @"This is most likely to occur if your image was "
									 @"in an unsupported RAW format.", NSLocalizedRecoverySuggestionErrorKey,
									 fileURL, NSURLErrorKey,
									 [NSString stringWithFormat:
									  @"ExifTool at '%s' terminated with status %i given %@",
									  toolPath, [exifTool terminationStatus], args],
									 NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:-1 userInfo:errInfo];
		}
		return NO;
	}
	return YES;
}

- (BOOL)verifyMetadata:(NSDictionary*)metadata
			  original:(NSURL*)originalURL
			  modified:(NSURL*)modifiedURL
				 error:(NSError**)err
{
	NSError* internalError;
	CGImageSourceRef originalSource = CGImageSourceCreateWithURL((CFURLRef)originalURL, NULL);
	CGImageSourceRef modifiedSource = CGImageSourceCreateWithURL((CFURLRef)modifiedURL, NULL);
	if (!originalSource || !modifiedSource) {
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"Could not open images", NSLocalizedDescriptionKey,
								 @"At least one file cannot be read.", NSLocalizedRecoverySuggestionErrorKey,
								 [NSString stringWithFormat:
								  @"Couldn't create original (%p) or modified (%p) image source",
								  originalSource, modifiedSource], NSLocalizedFailureReasonErrorKey, nil];
		internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:1 userInfo:errInfo];
		goto files_differ;
	}
	
	size_t originalCount = CGImageSourceGetCount(originalSource);
	size_t modifiedCount = CGImageSourceGetCount(modifiedSource);
	if (modifiedCount != originalCount) {
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"Could not compare images", NSLocalizedDescriptionKey,
								 @"Files must contain the same number of images.",
								 NSLocalizedRecoverySuggestionErrorKey,
								 [NSString stringWithFormat:
								  @"Original image count (%lu) is not equal to modified (%lu).",
								  originalCount, modifiedCount], NSLocalizedFailureReasonErrorKey, nil];
		internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:2 userInfo:errInfo];
		goto files_differ;
	}
	
	for (size_t imgIdx = 0; imgIdx < originalCount; ++imgIdx) {
		CGImageRef originalImage = CGImageSourceCreateImageAtIndex(originalSource, imgIdx, NULL);
		CGImageRef modifiedImage = CGImageSourceCreateImageAtIndex(modifiedSource, imgIdx, NULL);
		if (!originalImage || !modifiedImage) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Could not read image", NSLocalizedDescriptionKey,
									 @"At least one image could not be read from file.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Couldn't create original (%p) or modified (%p) image "
									  @"representation %lu of %lu.", originalImage, modifiedImage,
									  (imgIdx + 1), originalCount], NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:3 userInfo:errInfo];
			goto images_differ;
		}
		
		size_t origWidth = CGImageGetWidth(originalImage);
		size_t origHeight = CGImageGetHeight(originalImage);
		size_t modifiedWidth = CGImageGetWidth(modifiedImage);
		size_t modifiedHeight = CGImageGetHeight(modifiedImage);
		if ((origWidth != modifiedWidth) || (origHeight != modifiedHeight)) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Image sizes differ", NSLocalizedDescriptionKey,
									 @"At least one image size has changed.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Original (%lu x %lu) and modified (%lu x %lu) image sizes differ "
									  @"for representation %lu of %lu.", origWidth, origHeight,
									  modifiedWidth, modifiedHeight, (imgIdx + 1), originalCount],
									 NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:4 userInfo:errInfo];
			goto images_differ;
		}
		
		size_t dataSize = origWidth * origHeight * 4;
		char* imgData = malloc(dataSize);
		if (!imgData) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Insufficient memory to continue.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Could not allocate %lu byte buffer for representation %lu of %lu.",
									  dataSize, (imgIdx + 1), originalCount],
									 NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
			goto images_differ;
		}
		CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
		CGContextRef ctx = CGBitmapContextCreate(imgData, origWidth, origHeight, 8, origWidth * 4, cs,
												 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
		CFRelease(cs);
		if (!ctx) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Could not create requisite image buffer.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"CGBitmapContextCreate(mem = %p, w=%lu, h=%lu, cs=%p) failed.",
									  imgData, origWidth, origHeight, cs],
									 NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
			goto images_differ;
		}
		
		CGRect drawRect = CGRectMake(0.0f, 0.0f, origWidth, origHeight);
		CGContextDrawImage(ctx, drawRect, originalImage);
		CFRelease(originalImage), originalImage = NULL;
		
		CGContextSetBlendMode(ctx, kCGBlendModeDifference);
		CGContextDrawImage(ctx, drawRect, modifiedImage);
		CFRelease(modifiedImage), modifiedImage = NULL;
		CFRelease(ctx);
		
		for (size_t dataIdx = 0; dataIdx < dataSize; ++dataIdx) {
			if (imgData[dataIdx] && ((dataIdx + 1) % 4)) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 @"Images differ", NSLocalizedDescriptionKey,
										 @"At least one pixel is a different color.",
										 NSLocalizedRecoverySuggestionErrorKey,
										 [NSString stringWithFormat:
										  @"Difference of %hhu at byte %lu of representation %lu of %lu.",
										  imgData[dataIdx], dataIdx, (imgIdx + 1), originalCount],
										 NSLocalizedFailureReasonErrorKey, nil];
				internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:5 userInfo:errInfo];
				free(imgData);
				goto images_differ;
			}
		}
		free(imgData);
		continue;
		
	images_differ:
		if (originalImage) CFRelease(originalImage);
		if (modifiedImage) CFRelease(modifiedImage);
		goto files_differ;
	}
	
	/* NOTE: this currently just makes sure no metadata was modified/removed where not expected.
	 It does not check that metadata was set correctly, or for unexpectedly added metadata. */
	BOOL setTimestamp = ([metadata objectForKey:@"timestamp"]) ? YES : NO;
	BOOL setLocation = ([metadata objectForKey:@"latitude"] ||
						[metadata objectForKey:@"longitude"] ||
						[metadata objectForKey:@"altitude"]) ? YES : NO;
	for (size_t imgIdx = 0; imgIdx < originalCount; ++imgIdx) {
		CFDictionaryRef originalProperties = CGImageSourceCopyPropertiesAtIndex(originalSource, imgIdx, NULL);
		CFDictionaryRef modifiedProperties = CGImageSourceCopyPropertiesAtIndex(modifiedSource, imgIdx, NULL);
		if (!originalProperties || !modifiedProperties) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Metadata not readable", NSLocalizedDescriptionKey,
									 @"At least one image's metadata can not be read.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Could not copy original (%p) or modified (%p) properties "
									  @"for representation %lu of %lu.",
									  originalProperties, modifiedProperties, (imgIdx + 1), originalCount],
									 NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:6 userInfo:errInfo];
			goto metadata_differs;
		}
		
		for (NSString* metadataType in (id)originalProperties) {
			NSDictionary* originalInfo = [(NSDictionary*)originalProperties objectForKey:metadataType];
			NSDictionary* modifiedInfo = [(NSDictionary*)modifiedProperties objectForKey:metadataType];
			if (!modifiedInfo) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 @"Metadata missing", NSLocalizedDescriptionKey,
										 @"At least one set of image metadata is no longer present.",
										 NSLocalizedRecoverySuggestionErrorKey,
										 [NSString stringWithFormat:
										  @"Modified image is missing %@ for representation %lu of %lu.",
										  metadataType, (imgIdx + 1), originalCount],
										 NSLocalizedFailureReasonErrorKey, nil];
				internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:7 userInfo:errInfo];
				goto metadata_differs;
			}
			
			if (![originalInfo isKindOfClass:[NSDictionary class]]) {
				if (![modifiedInfo isEqual:originalInfo]) {
					NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"Metadata differs", NSLocalizedDescriptionKey,
											 @"At least one image metadata value has changed unexpectedly.",
											 NSLocalizedRecoverySuggestionErrorKey,
											 [NSString stringWithFormat:
											  @"For %@ in representation %lu of %lu, "
											  @"original has '%@' but modified has '%@'.",
											  metadataType, (imgIdx + 1), originalCount,
											  originalInfo, modifiedInfo], NSLocalizedFailureReasonErrorKey, nil];
					internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:8 userInfo:errInfo];
					goto metadata_differs;
				}
			}
			else for (NSString* metadataKey in originalInfo) {
				id originalMetadataValue = [originalInfo objectForKey:metadataKey];
				id modifiedMetadataValue = [originalInfo objectForKey:metadataKey];
				
				if (setTimestamp && [metadataType isEqual:(id)kCGImagePropertyExifDictionary] &&
					[metadataKey isEqual:(id)kCGImagePropertyExifDateTimeOriginal]) continue;
				else if (setLocation && [metadataType isEqual:(id)kCGImagePropertyGPSDictionary]) continue;
				else if ([metadataType isEqual:(id)kCGImagePropertyTIFFDictionary] &&
						 [metadataKey isEqual:(id)kCGImagePropertyTIFFSoftware]) continue;
				
				if (![modifiedMetadataValue isEqual:originalMetadataValue]) {
					NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"Metadata differs", NSLocalizedDescriptionKey,
											 @"Found image metadata difference where not expected.",
											 NSLocalizedRecoverySuggestionErrorKey,
											 [NSString stringWithFormat:
											  @"For %@ in %@ of representation %lu of %lu, "
											  @"original has '%@' but modified has '%@'.",
											  metadataKey, metadataType, (imgIdx + 1), originalCount,
											  originalMetadataValue, modifiedMetadataValue],
											 NSLocalizedFailureReasonErrorKey, nil];
					internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:9 userInfo:errInfo];
					goto metadata_differs;
				}
			}
		}
		
		CFRelease(originalProperties);
		CFRelease(modifiedProperties);
		continue;
		
	metadata_differs:
		//NSLog(@"Metadata differs.");
		if (originalProperties) CFRelease(originalProperties);
		if (modifiedProperties) CFRelease(modifiedProperties);
		goto files_differ;
	}
	
	CFRelease(originalSource);
	CFRelease(modifiedSource);
	return YES;
	
files_differ:
	//NSLog(@"Files differ.");
	if (originalSource) CFRelease(originalSource);
	if (modifiedSource) CFRelease(modifiedSource);
	if (err) {
		if (!internalError) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"File comparision failed, but no specific error was given.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 @"At files_differ cleanup with internalError not set.",
									 NSLocalizedFailureReasonErrorKey, nil];
			internalError = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		*err = internalError;
	}
	return NO;
}

@end
