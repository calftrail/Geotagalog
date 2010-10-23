/*
 *  TLSegment.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/18/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLSegment.h"

#include "TLFloat.h"

static inline TLSegmentIntersection TLSegmentIntersectionMake(CGPoint pointOfIntersection, double travel1, double travel2) {
	TLSegmentIntersection segmentIntersection = {
		.pointOfIntersection = pointOfIntersection,
		.travelAlongSegment1 = travel1,
		.travelAlongSegment2 = travel2
	};
	return segmentIntersection;
}

bool TLSegmentsIntersect(TLSegment segment1, TLSegment segment2, TLSegmentIntersection* intersectionInfo) {
	/* Based on the discussion at http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/ with attention given to the
	 special cases at http://www.geometryalgorithms.com/Archive/algorithm_0104/algorithm_0104B.htm#intersect2D_SegSeg() */
	/* The vector equation {Point = Segment.A + travelScalar * (Segment.B - Segment.A)} yields points along
	 an infinite line extending along the course set by Segment. When travelScalar falls between 0 and 1,
	 the points fall along Segment itself. */
	/* On a plane, all non-parallel lines intersect. The point of intersection can be found for a pair of segments
	 by finding travelScalar1 and travelScalar2 satisfying {Point(Segment1, travelScalar1) = Point(Segment2, travelScalar2)}.
	 If both travelScalars are between 0 and 1, the segments themselves intersect. */
	
	// find the denominator shared by both the travel scalar solutions
	double segment1DiffX = (segment1.b.x - segment1.a.x);
	double segment1DiffY = (segment1.b.y - segment1.a.y);
	double segment2DiffX = (segment2.b.x - segment2.a.x);
	double segment2DiffY = (segment2.b.y - segment2.a.y);
	double scalarsDenominator = (segment2DiffY * segment1DiffX) - (segment2DiffX * segment1DiffY);
	
	// find the numerator for each line vector
	double segmentsStartDiffX = segment1.a.x - segment2.a.x;
	double segmentsStartDiffY = segment1.a.y - segment2.a.y;
	double scalarNumerator1 = (segment2DiffX * segmentsStartDiffY) - (segment2DiffY * segmentsStartDiffX);
	double scalarNumerator2 = (segment1DiffX * segmentsStartDiffY) - (segment1DiffY * segmentsStartDiffX);
	
	// If the denominator is 0, the lines do not intersect normally. One or both segments have zero length, or they are parallel.
	if (TLFloatEqual(scalarsDenominator, 0.0)) return false;
	
	double travelScalar1 = scalarNumerator1 / scalarsDenominator;
	double travelScalar2 = scalarNumerator2 / scalarsDenominator;
	
	bool segmentsIntersect = (TLFloatBetweenInclusive(travelScalar1, 0.0, 1.0) &&
							  TLFloatBetweenInclusive(travelScalar2, 0.0, 1.0));
	
	if (!segmentsIntersect) return false;
	
	if (intersectionInfo) {
		double intersectX = segment1.a.x + (travelScalar1 * segment1DiffX);
		double intersectY = segment1.a.y + (travelScalar1 * segment1DiffY);
		CGPoint pointOfIntersection = CGPointMake((CGFloat)intersectX, (CGFloat)intersectY);
		*intersectionInfo = TLSegmentIntersectionMake(pointOfIntersection, travelScalar1, travelScalar2);
	}
	return true;
}

TLSegmentPointRelation TLSegmentCompareToPoint(TLSegment segment, CGPoint point) {
	double segmentDiffX = segment.b.x - segment.a.x;
	double segmentDiffY = segment.b.y - segment.a.y;
	
	if (TLFloatEqual(segmentDiffX, 0.0)) {
		if (TLFloatLessThan(segmentDiffY, 0.0)) {
			// vertical line pointing down (endpointA higher than endpointB)
			// if segment is farther left than point, point is on its left
			return TLFloatCompare(segment.a.x, point.x);
		}
		else if (TLFloatGreaterThan(segmentDiffY, 0.0)) {
			// vertical line pointing up
			// if point is farther left than segment, it is on left
			return TLFloatCompare(point.x, segment.a.x);
		}
		else {
			return TLSegmentHasNoDirection;
		}
	}
	else {
		// find travel such that point.x = segment.a.x + travel * segmentDiffX
		double travelX = (point.x - segment.a.x) / segmentDiffX;
		double segmentYAlignedWithPoint = segment.a.y + (travelX * segmentDiffY);
		if (segmentDiffX < 0.0) {	// already checked FloatEqual to 0.0
			// segment runs from right-to-left (endpointA more right than endpointB)
			// if point is further down than segment, it is on left
			return TLFloatCompare(point.y, segmentYAlignedWithPoint);
		}
		else {
			// segment runs from left-to-right
			// if segment is further down than point, point is on left
			return TLFloatCompare(segmentYAlignedWithPoint, point.y);
		}
	}
}
