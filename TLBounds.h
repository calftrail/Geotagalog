/*
 *  TLBounds.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLBOUNDS_H
#define TLBOUNDS_H

#include "TLPrimitiveTypes.h"

typedef CGRect TLBounds;

#define TLBoundsZero CGRectZero

TL_INLINE CGPoint TLBoundsGetTopLeftPoint(TLBounds bounds);
TL_INLINE CGPoint TLBoundsGetTopRightPoint(TLBounds bounds);
TL_INLINE CGPoint TLBoundsGetBottomRightPoint(TLBounds bounds);
TL_INLINE CGPoint TLBoundsGetBottomLeftPoint(TLBounds bounds);
TL_INLINE bool TLBoundsEqualToBounds(TLBounds bounds1, TLBounds bounds2);


#pragma mark Inline definitions

CGPoint TLBoundsGetTopLeftPoint(TLBounds bounds) {
	return CGPointMake(bounds.origin.x, bounds.origin.y + bounds.size.height);
}

CGPoint TLBoundsGetTopRightPoint(TLBounds bounds) {
	return CGPointMake(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
}

CGPoint TLBoundsGetBottomRightPoint(TLBounds bounds) {
	return CGPointMake(bounds.origin.x + bounds.size.width, bounds.origin.y);
}

CGPoint TLBoundsGetBottomLeftPoint(TLBounds bounds) {
	return CGPointMake(bounds.origin.x, bounds.origin.y);
}

bool TLBoundsEqualToBounds(TLBounds bounds1, TLBounds bounds2) {
	return (bool)CGRectEqualToRect(bounds1, bounds2);
}

#endif /* TLBOUNDS_H */
