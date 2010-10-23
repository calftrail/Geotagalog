/*
 *  TLSegment.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/18/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLSEGMENT_H
#define TLSEGMENT_H

#include "TLPrimitiveTypes.h"

#include "TLArray.h"

typedef struct _TLSegment {
	CGPoint a;
	CGPoint b;
} TLSegment;

TL_INLINE TLSegment TLSegmentMake(CGPoint a, CGPoint b);

typedef struct TLSegment_Intersection {
	CGPoint pointOfIntersection;
	double travelAlongSegment1;
	double travelAlongSegment2;
} TLSegmentIntersection;

bool TLSegmentsIntersect(TLSegment segment1, TLSegment segment2, TLSegmentIntersection* intersectionInfo);

enum {
	TLSegmentHasNoDirection = TLCompareLessThan - 1,
	TLSegmentPointToLeft = TLCompareLessThan,
	TLSegmentPointOnLine = TLCompareEqual,
	TLSegmentPointToRight = TLCompareGreaterThan
};
typedef tl_int_t TLSegmentPointRelation;

TLSegmentPointRelation TLSegmentCompareToPoint(TLSegment segment, CGPoint point);

#pragma mark Inline function definitions

TLSegment TLSegmentMake(CGPoint a, CGPoint b) {	TLSegment segment; segment.a = a; segment.b = b; return segment; }

#endif /* TLSEGMENT_H */
