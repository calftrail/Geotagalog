//
//  TLMercatalogStyler.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TLMercatalogStyler.h"

#import "TLCocoaToolbag.h"
#import "TLFloat.h"

static TLMercatalogStyler* TLMercatalogStylerDefaultObject;

static CGFloat TLMercatalogStylerSelectionWidth;
static CGColorRef TLMercatalogStylerInactiveSelectionColor;

static CGFloat TLMercatalogStylerDropHighlightWidth;

static CGFloat TLMercatalogStylerZoomBoxWidth;

static CGFloat TLMercatalogStylerSelectionBoxWidth;
static CGColorRef TLMercatalogStylerSelectionBoxStrokeColor;

static CGSize TLMercatalogStylerPhotoProxySize;
static CGColorRef TLMercatalogStylerPhotoProxyColor;
static CGSize TLMercatalogStylerPhotoDropPreviewProxySize;
static CGColorRef TLMercatalogStylerPhotoDropPreviewProxyColor;

static CGFloat TLMercatalogStylerTrackWidth;
static CGColorRef TLMercatalogStylerTrackColor;
static CGLineCap TLMercatalogStylerTrackLineCap;


@implementation TLMercatalogStyler

+ (void)initialize {
	if (self != [TLMercatalogStyler class]) return;
	
	TLMercatalogStylerDefaultObject = [TLMercatalogStyler new];
	
	TLMercatalogStylerSelectionWidth = 0.3f;
	TLMercatalogStylerInactiveSelectionColor = CGColorCreateGenericRGB(0.3f, 0.3f, 0.3f, 0.9f);
	
	TLMercatalogStylerDropHighlightWidth = 0.9f;
	
	TLMercatalogStylerZoomBoxWidth = 0.35f;
	
	TLMercatalogStylerSelectionBoxWidth = 0.1f;
	TLMercatalogStylerSelectionBoxStrokeColor = TLCGColorCreateGenericHSB(0.0f, 0.0f, 1.0f, 1.0f);
	
	TLMercatalogStylerPhotoProxySize = CGSizeMake(1.0f, 1.0f);
	TLMercatalogStylerPhotoProxyColor = CGColorCreateGenericGray(0.2f, 0.75f);
	TLMercatalogStylerPhotoDropPreviewProxySize = CGSizeMake(1.0f, 1.0f);
	TLMercatalogStylerPhotoDropPreviewProxyColor = CGColorCreateGenericRGB(1.0f, 0.0f, 1.0f, 1.0f);
	
	TLMercatalogStylerTrackWidth = 0.7f;
	TLMercatalogStylerTrackColor = CGColorCreateGenericRGB(0.0f, 0.5f, 1.0f, 1.0f);
	TLMercatalogStylerTrackLineCap = kCGLineCapRound;
}

+ (id)defaultStyler {
	return TLMercatalogStylerDefaultObject;
}

- (CGFloat)selectionWidth {
	return TLMercatalogStylerSelectionWidth;
}

- (NSColor*)cocoaSelectionColor {
	NSColor* systemSelectionColor = [NSColor selectedTextBackgroundColor];
	return [systemSelectionColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

- (CGColorRef)activeSelectionColor {
	NSColor* cocoaSelectionColor = [self cocoaSelectionColor];
	CGFloat selectionHue = [cocoaSelectionColor hueComponent];
	CGFloat saturation = [cocoaSelectionColor saturationComponent];
	CGFloat alpha = 0.95f;
	CGColorRef selectionColor = NULL;
	if (TLFloatEqual(saturation, 0.0)) {
		CGFloat brightness = 0.2f * [cocoaSelectionColor brightnessComponent];
		selectionColor = TLCGColorCreateGenericHSB(selectionHue, 0.0f, brightness, alpha);
	}
	else {
		selectionColor = TLCGColorCreateGenericHSB(selectionHue, 1.0f, 0.6f, alpha);
	}
	[(id)selectionColor autorelease];
	return selectionColor;
}

- (CGColorRef)inactiveSelectionColor {
	return TLMercatalogStylerInactiveSelectionColor;
}

- (CGFloat)dropHighlightWidth {
	return TLMercatalogStylerDropHighlightWidth;
}

- (CGColorRef)dropHighlightColor {
	NSColor* controlTintColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	NSColor* cocoaControlColor = [controlTintColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	CGFloat hue = [cocoaControlColor hueComponent];
	CGFloat saturation = 1.5f * [cocoaControlColor saturationComponent];
	saturation = (CGFloat)TLFloatClampNaive(saturation, 0.0, 1.0f);
	CGFloat brightness = 0.5f * [cocoaControlColor brightnessComponent];
	CGColorRef highlightColor = TLCGColorCreateGenericHSB(hue, saturation, brightness, 1.0f);
	[(id)highlightColor autorelease];
	return highlightColor;
}


- (CGFloat)zoomBoxWidth {
	return TLMercatalogStylerZoomBoxWidth;
}

- (CGColorRef)zoomBoxStrokeColorWithHueDegrees:(CGFloat)hueDegrees {
	CGColorRef zoomStrokeColor = TLCGColorCreateGenericHSB(hueDegrees/360.0f, 0.5f, 0.5f, 0.9f);
	return (CGColorRef)[(id)zoomStrokeColor autorelease];
}

- (CGColorRef)zoomBoxFillColorWithHueDegrees:(CGFloat)hueDegrees {
	CGColorRef zoomStrokeColor = TLCGColorCreateGenericHSB(hueDegrees/360.0f, 0.05f, 0.4f, 0.15f);
	return (CGColorRef)[(id)zoomStrokeColor autorelease];
}


- (CGFloat)selectionBoxWidth {
	return TLMercatalogStylerSelectionBoxWidth;
}

- (CGColorRef)selectionBoxStrokeColor {
	return TLMercatalogStylerSelectionBoxStrokeColor;
}

- (CGColorRef)selectionBoxFillColor {
	NSColor* cocoaSelectionColor = [self cocoaSelectionColor];
	CGFloat hue = [cocoaSelectionColor hueComponent];
	CGFloat saturation = [cocoaSelectionColor saturationComponent];
	CGFloat brightness = [cocoaSelectionColor brightnessComponent];
	CGColorRef selectionFillColor = TLCGColorCreateGenericHSB(hue, saturation, brightness, 0.1f);
	[(id)selectionFillColor autorelease];
	return selectionFillColor;
}


- (CGSize)photoProxySize {
	return TLMercatalogStylerPhotoProxySize;
}

- (CGColorRef)photoProxyColor {
	return TLMercatalogStylerPhotoProxyColor;
}

- (CGSize)photoDropPreviewProxySize {
	return TLMercatalogStylerPhotoDropPreviewProxySize;
}

- (CGColorRef)photoDropPreviewProxyColor {
	return TLMercatalogStylerPhotoDropPreviewProxyColor;
}

- (CGFloat)trackWidth {
	return TLMercatalogStylerTrackWidth;
}

- (CGColorRef)trackColor {
	return TLMercatalogStylerTrackColor;
}

- (CGLineCap)trackLineCap {
	return TLMercatalogStylerTrackLineCap;
}

@end
