//
//  TLPhotoLayout.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 12/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLPhoto;
#include "TLProjection.h"


@interface TLPhotoLayout : NSObject {
@private
	NSMapTable* frames;
	NSMapTable* anchors;
}

+ (id)photoLayoutForPhotos:(NSSet*)photos
				  inBounds:(CGRect)bounds
			  minDimension:(CGFloat)minDimension
				projection:(TLProjectionRef)proj;

- (BOOL)photoHasLayout:(TLPhoto*)photo;
- (CGRect)frameForPhoto:(TLPhoto*)photo;
- (CGPoint)anchorForPhoto:(TLPhoto*)photo;

@end
