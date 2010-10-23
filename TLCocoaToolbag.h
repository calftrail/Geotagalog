//
//  TLCocoaToolbag.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 7/22/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLPrimitiveTypes.h"

BOOL TLEqualSelectors(SEL a, SEL b);

CGColorRef TLCGColorCreateFromNSColor(NSColor* color);

#define TL_HueScale 360.0f
static const CGFloat TLHueRed = 0.0f / TL_HueScale;
static const CGFloat TLHueOrange = 30.0f / TL_HueScale;
static const CGFloat TLHueYellow = 60.0f / TL_HueScale;
static const CGFloat TLHueGreen = 120.0f / TL_HueScale;
static const CGFloat TLHueBlue = 240.0f / TL_HueScale;
#undef TL_HueScale

static const CGFloat TLSaturationDefault = 1.0f;
static const CGFloat TLSaturationNone = 0.0f;

static const CGFloat TLBrightnessDefault = 1.0f;
static const CGFloat TLBrightnessBlack = 0.0f;
static const CGFloat TLBrightnessWhite = 1.0f;

static const CGFloat TLAlphaDefault = 1.0f;

CGColorRef TLCGColorCreateGenericHSB(CGFloat hue, CGFloat saturation, CGFloat brightness, CGFloat alpha);

CGGradientRef TLCGGradientCreateGaussian(CGColorRef color,
										 CGFloat standardDeviation,
										 CGFloat width);

void TLTextDrawString(CGContextRef ctx, CGPoint position, CGFloat pointSize, NSString* string, CGRect* measure);

static const CGFloat TLDragTransparencyDefault = 0.5f;

NSImage* TLNSImageFromCGImage(CGImageRef quartzImage, CGFloat alpha);

NSSet* TLNSMapTableAllKeys(NSMapTable* mapTable);
NSArray* TLNSMapTableAllObjects(NSMapTable* mapTable);
void TLNSMapTableSetWithMapTable(NSMapTable* mapTable, NSMapTable* additions);

CGSize TLScreenPixelsPerMillimeter(NSScreen* screen);

NSNumber* TLNumberWithObjCType(const void* value, const char* type);

NSString* TLFileGetUTI(NSURL* file);
BOOL TLFileUTIConformsToAny(NSString* uti, NSArray* targetUTIs);

NSURL* TLFileResolveFinderAlias(NSURL* finderAliasFile);

NSString* TLFileGetUniqueNameInFolder(NSString* originalName, NSString* folder);

NSString* TLFileTemporaryPathFromPattern(NSString* patternWithTrailingXs);

BOOL TLFileZip(NSString* source, NSString* destination, NSError** err);

#ifdef __STRICT_ANSI__
#define tlfloatarg(x) ( (x) ? ((x) / (2 * (x))) : (((x) + 1) / 2) )
//#define tlfloatarg(x) ( ((x) > 0) ? ((x) / ((x) + 1)) : ( (x) ? ((x) / ((x) - 1)) : (((x) + 1) / ((x) + 2)) ) )
#define tlnum(x) (tlfloatarg(x) ? [NSNumber numberWithDouble:(x)] : [NSNumber numberWithLong:(x)])
#else
#define tlnum(x) ({ typeof(x) _x = (x); TLNumberWithObjCType(&_x, @encode(typeof(_x))); })
#endif


/* The following macros allow one to mark uses of declared instance variables
 that could be replaced by automatic property storage when only the modern ObjC
 runtime needs to be supported.
 
 TL_SYNTHESIZABLE_IVAR_DECL is used to declare the instance variable.
 TL_SYNTHESIZABLE_IVAR_SET should be used only in init/awake implementations.
 TL_SYNTHESIZABLE_IVAR_RELEASE should be used only in dealloc implementation. */
#ifdef __OBJC2__	// See http://lists.apple.com/archives/objc-language/2008/Apr/msg00055.html
#define TL_SYNTHESIZABLE_IVAR_DECL(type, name)
#define TL_SYNTHESIZABLE_IVAR_SET(name, value) ([self setName:value])
#define TL_SYNTHESIZABLE_IVAR_RELEASE(name) ([self setName:nil])
#else
#define TL_SYNTHESIZABLE_IVAR_DECL(type, name) type name
#define TL_SYNTHESIZABLE_IVAR_SET(name, value) (name = value)
#define TL_SYNTHESIZABLE_IVAR_RELEASE(name) ([name release])
#endif /* __OBJC2__ */


TL_INLINE CFTypeRef TLCFAutorelease(CFTypeRef obj);


#pragma mark Inline implementations

CFTypeRef TLCFAutorelease(CFTypeRef obj) { return (CFTypeRef)[(id)obj autorelease]; }
