//
//  TLMercatalogStyler.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLMercatalogStyler : NSObject {
@private
}

+ (id)defaultStyler;

@property (nonatomic, readonly) CGFloat selectionWidth;
@property (nonatomic, readonly) CGColorRef activeSelectionColor;
@property (nonatomic, readonly) CGColorRef inactiveSelectionColor;

@property (nonatomic, readonly) CGFloat dropHighlightWidth;
@property (nonatomic, readonly) CGColorRef dropHighlightColor;

@property (nonatomic, readonly) CGFloat zoomBoxWidth;
- (CGColorRef)zoomBoxStrokeColorWithHueDegrees:(CGFloat)hueDegrees;
- (CGColorRef)zoomBoxFillColorWithHueDegrees:(CGFloat)hueDegrees;

@property (nonatomic, readonly) CGFloat selectionBoxWidth;
@property (nonatomic, readonly) CGColorRef selectionBoxStrokeColor;
@property (nonatomic, readonly) CGColorRef selectionBoxFillColor;

@property (nonatomic, readonly) CGSize photoProxySize;
@property (nonatomic, readonly) CGColorRef photoProxyColor;
@property (nonatomic, readonly) CGSize photoDropPreviewProxySize;
@property (nonatomic, readonly) CGColorRef photoDropPreviewProxyColor;

@property (nonatomic, readonly) CGFloat trackWidth;
@property (nonatomic, readonly) CGColorRef trackColor;
@property (nonatomic, readonly) CGLineCap trackLineCap;

@end
