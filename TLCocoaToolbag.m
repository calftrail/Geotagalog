//
//  TLCocoaToolbag.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 7/22/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLCocoaToolbag.h"

#import <objc/runtime.h>

static const NSUInteger TLFileCollisionTries = 9999;

BOOL TLEqualSelectors(SEL a, SEL b) {
	return sel_isEqual(a, b);
}

// based on http://www.cocoabuilder.com/archive/message/cocoa/2006/11/12/174339
CGColorRef TLCGColorCreateFromNSColor(NSColor* cocoaColor) {
	NSColor* deviceColor = [cocoaColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	if (!deviceColor) return NULL;
	
	CGFloat components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (!colorSpace) return NULL;
	CGColorRef quartzColor = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease(colorSpace);
	return quartzColor;
}

CGColorRef TLCGColorCreateGenericHSB(CGFloat hue, CGFloat saturation, CGFloat brightness, CGFloat alpha) {
	NSColor* cocoaColor = [NSColor colorWithDeviceHue:hue saturation:saturation brightness:brightness alpha:alpha];
	CGColorRef quartzColor = TLCGColorCreateFromNSColor(cocoaColor);
	return quartzColor;
}

static double TLGaussianPDF(double x, double sigma) {
	// from http://en.wikipedia.org/w/index.php?title=Normal_distribution&oldid=251373017
	const double sqrtTwoPi = sqrt(2.0 * M_PI);
	return (1.0 / (sigma * sqrtTwoPi)) * exp(-(x * x) / (2.0 * sigma * sigma));
}

CGGradientRef TLCGGradientCreateGaussian(CGColorRef color,
										 CGFloat standardDeviation,
										 CGFloat width)
{
	const tl_uint_t numDivisions = 10;
	double maxDensity = TLGaussianPDF(0.0, standardDeviation);
	CGFloat maxAlpha = CGColorGetAlpha(color);
	CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
	CFMutableArrayRef colors = CFArrayCreateMutable(kCFAllocatorDefault,
													numDivisions,
													&kCFTypeArrayCallBacks);
	if (!colors) return NULL;
	TLCFAutorelease(colors);
	for (tl_uint_t stepIdx = 0; stepIdx <= numDivisions; ++stepIdx) {
		double x = width * ((double)stepIdx / (double)numDivisions);
		double density = TLGaussianPDF(x, standardDeviation);
		double alpha = maxAlpha * (density / maxDensity);
		CGColorRef stepColor = CGColorCreateCopyWithAlpha(color, (CGFloat)alpha);
		if (!stepColor) {
			CFRelease(colors);
			return NULL;
		}
		CFArrayAppendValue(colors, stepColor);
		CGColorRelease(stepColor);
	}
	return CGGradientCreateWithColors(colorSpace, colors, NULL);
}

NSImage* TLNSImageFromCGImage(CGImageRef quartzImage, CGFloat alpha) {
	NSCParameterAssert(quartzImage);
	size_t width = CGImageGetWidth(quartzImage);
	size_t height = CGImageGetHeight(quartzImage);
	NSImage* cocoaImage = [[[NSImage alloc] initWithSize:NSMakeSize(width,  height)] autorelease];
	[cocoaImage lockFocus];
	CGContextRef quartzContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGRect imageRectangle = CGRectMake(0.0f, 0.0f, width, height);
	CGContextClearRect(quartzContext, imageRectangle);
	CGContextSetAlpha(quartzContext, alpha);
	CGContextDrawImage(quartzContext, imageRectangle, quartzImage);
	[cocoaImage unlockFocus];
	return cocoaImage;
}

static CTLineRef TLTextCreateDefaultLine(CGFloat pointSize, NSString* string) {
	NSFont* font = [NSFont systemFontOfSize:pointSize];
	NSDictionary* attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	NSAttributedString* attribString = [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
	return CTLineCreateWithAttributedString((CFAttributedStringRef)attribString);
}

void TLTextDrawString(CGContextRef ctx, CGPoint position, CGFloat pointSize, NSString* string, CGRect* measure) {
	CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
	CGContextSetTextPosition(ctx, position.x, position.y);
	CTLineRef line = TLTextCreateDefaultLine(pointSize, string);
	if (measure) *measure = CTLineGetImageBounds(line, ctx);
	else CTLineDraw(line, ctx);
	CFRelease(line);
}

NSSet* TLNSMapTableAllKeys(NSMapTable* mapTable) {
	NSMutableSet* allKeys = [NSMutableSet setWithCapacity:[mapTable count]];
	for (id key in mapTable) {
		[allKeys addObject:key];
	}
	return allKeys;
}

NSArray* TLNSMapTableAllObjects(NSMapTable* mapTable) {
	NSMutableArray* allObjects = [NSMutableArray arrayWithCapacity:[mapTable count]];
	for (id key in mapTable) {
		id object = [mapTable objectForKey:key];
		[allObjects addObject:object];
	}
	return allObjects;
}

void TLNSMapTableSetWithMapTable(NSMapTable* mapTable, NSMapTable* additions) {
	for (id key in additions) {
		[mapTable setObject:[additions objectForKey:key] forKey:key];
	}
}

static NSString* const TLNSScreenNumber = @"NSScreenNumber";
static const double TLDefaultDPI = 72.0;
static const double TLMillimetersPerInch = 25.4;

CGSize TLScreenPixelsPerMillimeter(NSScreen* screen) {
	NSDictionary* deviceInfo = [screen deviceDescription];
	/* NOTE: It would theoretically be easier to use the following:
	 NSSize deviceDPI = [[deviceInfo objectForKey:NSDeviceResolution] sizeValue];
	 double pixelsPerMillimeterX = deviceDPI.width * TLMillimetersPerInch;
	 double pixelsPerMillimeterY = deviceDPI.height * TLMillimetersPerInch;
	 but NSDeviceResolution is just 72.0 * scaleFactor regardless of actual screen resolution.
	 See discussion at http://boredzo.org/blog/archives/2007-02-04/whats-the-resolution-of-your-screen
	 */
	NSNumber* screenNumber = [deviceInfo objectForKey:TLNSScreenNumber];
	CGDirectDisplayID displayID = [screenNumber unsignedIntValue];
	/* NOTE: CGDisplayScreenSize() is an expensive function, up to 0.03 seconds on 2.16GHz C2D iMac */
	CGSize screenSizeInMillimeters = CGDisplayScreenSize(displayID);
	
	double pixelsPerMillimeterX = TLDefaultDPI / TLMillimetersPerInch;
	double pixelsPerMillimeterY = TLDefaultDPI / TLMillimetersPerInch;
	if (!CGSizeEqualToSize(screenSizeInMillimeters, CGSizeZero)) {
		pixelsPerMillimeterX = CGDisplayPixelsWide(displayID) / screenSizeInMillimeters.width;
		pixelsPerMillimeterY = CGDisplayPixelsHigh(displayID) / screenSizeInMillimeters.height;
	}
	return CGSizeMake((CGFloat)pixelsPerMillimeterX, (CGFloat)pixelsPerMillimeterY);
}

/*
NSNumber* TLNumberWithObjCTypeSlow(const void* value, const char* type) {
	NSNumber* number = nil;
	if (!strcmp(type, @encode(double))) {
		number = [NSNumber numberWithDouble:*(double*)value];
	}
	else if (!strcmp(type, @encode(int))) {
		number = [NSNumber numberWithInt:*(int*)value];
	}
	else if (!strcmp(type, @encode(float))) {
		number = [NSNumber numberWithFloat:*(float*)value];
	}
	else if (!strcmp(type, @encode(unsigned int))) {
		number = [NSNumber numberWithUnsignedInt:*(unsigned int*)value];
	}
	else if (!strcmp(type, @encode(long))) {
		number = [NSNumber numberWithLong:*(long*)value];
	}
	else if (!strcmp(type, @encode(unsigned long))) {
		number = [NSNumber numberWithUnsignedLong:*(unsigned long*)value];
	}
	else if (!strcmp(type, @encode(char))) {
		number = [NSNumber numberWithChar:*(char*)value];
	}
	else if (!strcmp(type, @encode(unsigned char))) {
		number = [NSNumber numberWithUnsignedChar:*(unsigned char*)value];
	}
	else if (!strcmp(type, @encode(short))) {
		number = [NSNumber numberWithShort:*(short*)value];
	}
	else if (!strcmp(type, @encode(unsigned short))) {
		number = [NSNumber numberWithUnsignedShort:*(unsigned short*)value];
	}
	else if (!strcmp(type, @encode(long long))) {
		number = [NSNumber numberWithLongLong:*(long long*)value];
	}
	else if (!strcmp(type, @encode(unsigned long long))) {
		number = [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)value];
	}
	else if (!strcmp(type, @encode(_Bool))) {
		number = [NSNumber numberWithBool:*(_Bool*)value];
	}
	return number;
}
*/

NSNumber* TLNumberWithObjCType(const void* value, const char* type) {
	const char t = *type;
	NSNumber* number = nil;
	if (t == 'd') {
		number = [NSNumber numberWithDouble:*(double*)value];
	}
	else if (t == 'i') {
		number = [NSNumber numberWithInt:*(int*)value];
	}
	else if (t == 'f') {
		number = [NSNumber numberWithFloat:*(float*)value];
	}
	else if (t == 'I') {
		number = [NSNumber numberWithUnsignedInt:*(unsigned int*)value];
	}
	else if (t == 'l') {
		number = [NSNumber numberWithLong:*(long*)value];
	}
	else if (t == 'L') {
		number = [NSNumber numberWithUnsignedLong:*(unsigned long*)value];
	}
	else if (t == 'c') {
		number = [NSNumber numberWithChar:*(char*)value];
	}
	else if (t == 'C') {
		number = [NSNumber numberWithUnsignedChar:*(unsigned char*)value];
	}	
	else if (t == 's') {
		number = [NSNumber numberWithShort:*(short*)value];
	}
	else if (t == 'S') {
		number = [NSNumber numberWithUnsignedShort:*(unsigned short*)value];
	}
	else if (t == 'q') {
		number = [NSNumber numberWithLongLong:*(long long*)value];
	}
	else if (t == 'Q') {
		number = [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)value];
	}
	else if (t == 'B') {
		number = [NSNumber numberWithBool:*(_Bool*)value];
	}
	return number;
}

NSString* TLFileGetUTI(NSURL* file) {
	FSRef carbonRef;
	Boolean success = CFURLGetFSRef((CFURLRef)file, &carbonRef);
	if (!success) return nil;
	
	// See http://lists.apple.com/archives/Carbon-dev/2005/Nov/msg00851.html
	CFTypeRef utiString = NULL;
	OSStatus err = LSCopyItemAttribute(&carbonRef, kLSRolesViewer, kLSItemContentType, &utiString);
	if (err) return nil;
	NSCAssert(CFGetTypeID(utiString)==CFStringGetTypeID(), @"Expected string result getting file UTI");
	TLCFAutorelease(utiString);
	return (NSString*)utiString;
}

BOOL TLFileUTIConformsToAny(NSString* uti, NSArray* targetUTIs) {
	NSCParameterAssert(uti);
	BOOL conforms = NO;
	for (NSString* targetUTI in targetUTIs) {
		conforms = UTTypeConformsTo((CFStringRef)uti, (CFStringRef)targetUTI);
		if (conforms) break;
	}
	return conforms;
}

NSURL* TLFileResolveFinderAlias(NSURL* finderAliasFile) {
	FSRef aliasFileRef;
	Boolean gotRef = CFURLGetFSRef((CFURLRef)finderAliasFile, &aliasFileRef);
	if (!gotRef) return nil;
	Boolean isFolder = FALSE;
	Boolean wasAliased = FALSE;
	OSErr err = FSResolveAliasFileWithMountFlags(&aliasFileRef, TRUE, &isFolder, &wasAliased, kResolveAliasFileNoUI);
	if (err) return nil;
	(void)isFolder;
	(void)wasAliased;
	CFURLRef resolvedURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasFileRef);
	return [(NSURL*)resolvedURL autorelease];
}

NSString* TLFileGetUniqueNameInFolder(NSString* originalName, NSString* folder) {
	NSArray* existingNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:NULL];
	if (!existingNames) return nil;
	
	NSString* originalNameOnly = [originalName stringByDeletingPathExtension];
	NSString* originalExtension = [originalName pathExtension];
	
	NSUInteger suffixIdx = 0;
	NSString* uniqueName = nil;
	while (!uniqueName && suffixIdx < TLFileCollisionTries) {
		NSString* proposedName = originalName;
		if (suffixIdx) {
			NSString* suffix = [NSString stringWithFormat:@"-%lu", (long unsigned)suffixIdx];
			NSString* nameWithSuffix = [originalNameOnly stringByAppendingString:suffix];
			proposedName = [nameWithSuffix stringByAppendingPathExtension:originalExtension];
		}
		
		BOOL collided = NO;
		for (NSString* existingName in existingNames) {
			if ([proposedName isEqualToString:existingName]) {
				collided = YES;
				break;
			}
		}
		
		if (!collided) {
			uniqueName = proposedName;
			break;
		}
		++suffixIdx;
	}
	return uniqueName;
}

NSString* TLFileTemporaryPathFromPattern(NSString* patternWithTrailingXs) {
	NSString* tempDirectory = NSTemporaryDirectory();
	NSString* patternPath = [tempDirectory stringByAppendingPathComponent:patternWithTrailingXs];
	const char* patternCString = [patternPath fileSystemRepresentation];
	if (!patternCString) return nil;
	
	// copy pattern into own buffer
	size_t pathSize = 1 + strlen(patternCString);
	char* pathBuffer = (char*)malloc(pathSize);
	if (!pathBuffer) return nil;
	memcpy(pathBuffer, patternCString, pathSize);
	
	// use system-provided temporary name
	char* success = mktemp(pathBuffer);
	NSString* temporaryPath = nil;
	if (success) {
		temporaryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathBuffer
																					length:(pathSize-1)];
	}
	free(pathBuffer);
	return temporaryPath;
}

BOOL TLFileZip(NSString* source, NSString* destination, NSError** err) {
	NSCAssert(source && destination, @"Invalid argument, source and destination both required");
	BOOL sourceExists = [[NSFileManager defaultManager] fileExistsAtPath:source];
	if (!sourceExists) {
		if (err) {
			NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:source forKey:NSFilePathErrorKey];
			*err = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:errorInfo];
		}
		return NO;
	}
	BOOL destinationExists = [[NSFileManager defaultManager] fileExistsAtPath:destination];
	if (0 && destinationExists) {
		if (err) {
			NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:source forKey:NSFilePathErrorKey];
			*err = [NSError errorWithDomain:NSPOSIXErrorDomain code:EEXIST userInfo:errorInfo];
		}
		return NO;
	}
	
	// http://twitter.com/ccgus/statuses/963137508
	NSMutableArray* dittoArgs = [NSMutableArray arrayWithObjects:@"-c", @"-k",
								 @"--sequesterRsrc",
								 source, destination,
								 nil];
	NSTask* zipTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/ditto" arguments:dittoArgs];
	//NSTask* zipTask = [NSTask launchedTaskWithLaunchPath:@"/bin/echo" arguments:dittoArgs];
	[zipTask waitUntilExit];
	int zipError = [zipTask terminationStatus];
	if (zipError) {
		(void)[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
		if (err) {
			*err = [NSError errorWithDomain:NSPOSIXErrorDomain code:EIO userInfo:nil];
		}
		return NO;
	}
	return YES;
}
