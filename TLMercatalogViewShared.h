/*
 *  TLMercatalogViewShared.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 11/24/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

extern const NSUInteger TLPhotoLayerAcceptedEventFlags;
extern const NSTimeInterval TLNavigationDragDelay;


@class TLPhoto;

extern bool TLNavigationIsReverseZoom(CGPoint startPoint, CGPoint endPoint);

extern CGImageRef TLPhotoCreateDragImageForPhotos(NSArray* photos);
