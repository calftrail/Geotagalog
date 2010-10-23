/*
 *  TLGeometry.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 2/29/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLGeometry.h"
#include "TLSegment.h"
#include "TLFloat.h"
#include "TLToolbag.h"

#include "TLArray.h"
#include "TLPointerArray.h"

CGFloat TLSizeGetAverageWidth(CGSize size) {
	return (CGFloat)sqrt(size.width * size.height);
}

CGFloat TLPointDistance(CGPoint a, CGPoint b) {
	double dx = a.x - b.x;
	double dy = a.y - b.y;
	return (CGFloat)hypot(dx, dy);
}

CGFloat TLPointDistanceSquared(CGPoint a, CGPoint b) {
	double dx = a.x - b.x;
	double dy = a.y - b.y;
	return (CGFloat)(dx*dx + dy*dy);
}

CGPoint TLCGRectGetCenter(CGRect rect) {
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGRect TLCGRectMakeFromPoints(CGPoint a, CGPoint b) {
	return TLBoundsMakeFromPoints(a, b);
}

TLBounds TLBoundsMakeFromPoints(CGPoint a, CGPoint b) {
	CGFloat origin_x, origin_y;
	CGFloat width, height;
	if (a.x < b.x) {
		origin_x = a.x;
		width = b.x - a.x;
	} else {
		origin_x = b.x;
		width = a.x - b.x;
	}
	if (a.y < b.y) {
		origin_y = a.y;
		height = b.y - a.y;
	} else {
		origin_y = b.y;
		height = a.y - b.y;
	}
	return CGRectMake(origin_x, origin_y, width, height);
}

CGRect TLCGRectMakeSquareAroundPoint(CGPoint center, CGFloat sideLength) {
	CGFloat halfSideSize = sideLength / 2.0f;
	CGRect square = CGRectMake(center.x, center.y, 0.0f, 0.0f);
	return CGRectInset(square, -halfSideSize, -halfSideSize);
}

CGRect TLCGRectMakeAroundPoint(CGPoint center, CGFloat width, CGFloat height) {
	CGRect centerRect = CGRectMake(center.x, center.y, 0.0f, 0.0f);
	return CGRectInset(centerRect, -width / 2.0f, -height / 2.0f);
}

CGRect TLCGRectInsetToAspect(CGRect rect, CGFloat width, CGFloat height) {
	CGFloat scaleToFitWidth = CGRectGetWidth(rect) / width;
	CGFloat scaleToFitHeight = CGRectGetHeight(rect) / height;
	CGFloat scaleToFit = (CGFloat)fmin(scaleToFitHeight, scaleToFitWidth);
	CGPoint center = TLCGRectGetCenter(rect);
	return TLCGRectMakeAroundPoint(center, width * scaleToFit, height * scaleToFit);
}

CGAffineTransform TLTransformFromRectToRect(CGRect source, CGRect destination, TLAspectPreservationType aspectOption) {
	CGFloat scaleToFitWidth = destination.size.width / source.size.width;
	CGFloat scaleToFitHeight = destination.size.height / source.size.height;
	CGAffineTransform transform = CGAffineTransformIdentity;
	transform = CGAffineTransformTranslate(transform, CGRectGetMidX(destination), CGRectGetMidY(destination));
	if (aspectOption == TLAspectPadToFit) {
		CGFloat scaleToFit = (CGFloat)fmin(scaleToFitHeight, scaleToFitWidth);
		transform = CGAffineTransformScale(transform, scaleToFit, scaleToFit);
	}
	else if (aspectOption == TLAspectIgnore) {
		transform = CGAffineTransformScale(transform, scaleToFitWidth, scaleToFitHeight);
	}
	transform = CGAffineTransformTranslate(transform, -CGRectGetMidX(source), -CGRectGetMidY(source));
	return transform;
}

#pragma mark Polygon simplification

static CGFloat CTSquaredDistanceBetweenPoints(CGPoint a, CGPoint b) {
	CGFloat xd = a.x - b.x;
	CGFloat yd = a.y - b.y;
	return xd*xd + yd*yd;
}

TLPolygonRef TLPolygonCreateByReducingVertices(TLPolygonRef sourcePolygon, CGFloat significantDistance) {
	tl_uint_t sourceVertexCount = TLPolygonGetCount(sourcePolygon);
	char* keepMask = calloc(sourceVertexCount, sizeof(char));
	tl_uint_t keepCount = 0;
	tl_uint_t lastKeptIdx = 0;
	CGFloat significantDistanceSquared = significantDistance * significantDistance;
	for (tl_uint_t currentIdx = 0; currentIdx < sourceVertexCount; ++currentIdx) {
		// mark first vertex, last vertex, or any vertex far enough away, as kept
		if ( !currentIdx ||
			currentIdx == sourceVertexCount-1 || 
			significantDistanceSquared < CTSquaredDistanceBetweenPoints(TLPolygonGetPoint(sourcePolygon, lastKeptIdx),
																		TLPolygonGetPoint(sourcePolygon, currentIdx)) )
		{
			keepMask[currentIdx] = 1;
			++keepCount;
			lastKeptIdx = currentIdx;
		}
	}
	
	TLMutablePolygonRef reducedPolygon = TLPolygonCreateMutable(keepCount);
	for (tl_uint_t sourceIdx = 0; sourceIdx < sourceVertexCount; ++sourceIdx) if ( keepMask[sourceIdx] ) {
		TLPolygonAppendPoint(reducedPolygon, TLPolygonGetPoint(sourcePolygon, sourceIdx) );
	}
	free(keepMask);
	return reducedPolygon;
}

TLPolygonRef TLPolygonCreateByDensifyingVertices(TLPolygonRef oldPolygon, tl_uint_t addFactor) {
	tl_uint_t oldVertexCount = TLPolygonGetCount(oldPolygon);
	if (!oldVertexCount) return NULL;
	tl_uint_t addScale = addFactor + 1;
	tl_uint_t newVertexCount = (oldVertexCount - 1) * addScale + 1;
	TLMutablePolygonRef densifiedPolygon = TLPolygonCreateMutable(newVertexCount);
	if (!densifiedPolygon) return NULL;
	tl_uint_t lastOldVertex = oldVertexCount - 1;
	for (tl_uint_t oldIdx = 0; oldIdx < lastOldVertex; ++oldIdx) {
		CGPoint basePoint = TLPolygonGetPoint(oldPolygon, oldIdx);
		// add original point
		TLPolygonAppendPoint(densifiedPolygon, basePoint);
		CGPoint nextPoint = TLPolygonGetPoint(oldPolygon, oldIdx + 1);
		// and the N=addFactor between points.
		for (tl_uint_t addIdx = 1; addIdx < addScale; ++addIdx) {
			CGFloat baseFactor = addScale - addIdx;
			CGFloat nextFactor = addIdx;
			CGPoint addPoint;
			addPoint.x = ( baseFactor * basePoint.x + nextFactor * nextPoint.x ) / addScale;
			addPoint.y = ( baseFactor * basePoint.y + nextFactor * nextPoint.y ) / addScale;
			TLPolygonAppendPoint(densifiedPolygon, addPoint);
		}
	}
	TLPolygonAppendPoint(densifiedPolygon, TLPolygonGetPoint(oldPolygon, lastOldVertex));
	return densifiedPolygon;
}

TLBounds TLBoundsFromPolygon(TLPolygonRef polygon) {
	TLBounds bbox = CGRectZero;
	tl_uint_t sourceVertexCount = TLPolygonGetCount(polygon);
	if (sourceVertexCount) {
		bbox.origin = TLPolygonGetPoint(polygon, 0);
		for (tl_uint_t vertexIdx = 1; vertexIdx < sourceVertexCount; ++vertexIdx) {
			bbox = TLBoundsExpandToIncludePoint(bbox, TLPolygonGetPoint(polygon, vertexIdx));
		}
	}
	return bbox;
}

TLBounds TLBoundsFromMultiPolygon(TLMultiPolygonRef multiPoly) {
	CGRect bounds = CGRectZero;
	tl_uint_t numRings = TLMultiPolygonGetCount(multiPoly);
	for (tl_uint_t ringIdx = 0; ringIdx < numRings; ++ringIdx) {
		TLPolygonRef polygon = TLMultiPolygonGetPolygon(multiPoly, ringIdx);
		CGRect polyBounds = TLBoundsFromPolygon(polygon);
		if (CGRectEqualToRect(bounds, CGRectZero)) {
			bounds = polyBounds;
		}
		else {
			bounds = CGRectUnion(bounds, polyBounds);
		}
	}
	return bounds;
}

TLPolygonRef TLPolygonCreateFromBounds(TLBounds bounds) {
	TLMutablePolygonRef boundsPoly = TLPolygonCreateMutable(5);
	// Traverse bounds in an anti-clockwise fashion.
	TLPolygonAppendPoint(boundsPoly, TLBoundsGetTopLeftPoint(bounds));
	TLPolygonAppendPoint(boundsPoly, TLBoundsGetTopRightPoint(bounds));
	TLPolygonAppendPoint(boundsPoly, TLBoundsGetBottomRightPoint(bounds));
	TLPolygonAppendPoint(boundsPoly, TLBoundsGetBottomLeftPoint(bounds));
	TLPolygonAppendPoint(boundsPoly, TLPolygonGetPoint(boundsPoly, 0));
	return boundsPoly;
}

TLBounds TLBoundsExpandToIncludeBounds(TLBounds bounds1, TLBounds bounds2) {
	if (CGRectEqualToRect(bounds1, TLBoundsZero)) return bounds2;
	if (CGRectEqualToRect(bounds2, TLBoundsZero)) return bounds1;
	return CGRectUnion(bounds1, bounds2);
}

CGRect TLCGRectExpandToIncludePoint(CGRect rect, CGPoint point) {
	if (CGRectIsNull(rect)) {
		return CGRectMake(point.x, point.y, 0.0f, 0.0f);
	}
	
	CGRect expandedRect = rect;
	if (point.x > CGRectGetMaxX(rect)) {
		CGFloat distance = point.x - CGRectGetMaxX(rect);
		expandedRect.size.width += distance;
	}
	else if (point.x < CGRectGetMinX(rect)) {
		CGFloat distance = CGRectGetMinX(rect) - point.x;
		expandedRect.size.width += distance;
		expandedRect.origin.x = point.x;
	}
	if (point.y > CGRectGetMaxY(rect)) {
		CGFloat distance = point.y - CGRectGetMaxY(rect);
		expandedRect.size.height += distance;
	}
	else if (point.y < CGRectGetMinY(rect)) {
		CGFloat distance = CGRectGetMinY(rect) - point.y;
		expandedRect.size.height += distance;
		expandedRect.origin.y = point.y;
	}
	return expandedRect;
}

TLBounds TLBoundsExpandToIncludePoint(TLBounds rect, CGPoint point) {
	CGRect expandedRect = rect;
	// NOTE: The following logic must properly handle NaN-valued points.
	// TODO: is this at all correct for CGRectZero/CGRectNull???
	if (point.x > CGRectGetMaxX(rect)) {
		CGFloat distance = point.x - CGRectGetMaxX(rect);
		expandedRect.size.width += distance;
	}
	if (point.x < CGRectGetMinX(rect)) {
		CGFloat distance = CGRectGetMinX(rect) - point.x;
		expandedRect.size.width += distance;
		expandedRect.origin.x = point.x;
	}
	if (point.y > CGRectGetMaxY(rect)) {
		CGFloat distance = point.y - CGRectGetMaxY(rect);
		expandedRect.size.height += distance;
	}
	if (point.y < CGRectGetMinY(rect)) {
		CGFloat distance = CGRectGetMinY(rect) - point.y;
		expandedRect.size.height += distance;
		expandedRect.origin.y = point.y;
	}
	return expandedRect;
}

bool TLBoundsContainsPoint(TLBounds bounds, CGPoint point) {
	return CGRectContainsPoint(bounds, point);
}


#pragma mark Point-in-polygon testing

bool TLMultiPolygonContainsPoint(TLMultiPolygonRef multiPoly, CGPoint point) {
	(void)multiPoly;
	(void)point;
	// TODO: implement point-in-polygon test
	return false;
}


#pragma mark Polygon clipping, structures

typedef struct {
	TLSegment segment;
	TLPolygonRef polygon;
	tl_uint_t indexOfEndpointA;
} TLAnnotatedSegment;

typedef const struct TL_Intersection* TLIntersectionRef;
typedef struct TL_Intersection* TLMutableIntersectionRef;

typedef const struct TL_PolygonPart* TLPolygonPartRef;
typedef struct TL_PolygonPart* TLMutablePolygonPartRef;

typedef struct TL_Intersection {
	tl_uint_t retainCount;
	TLSegmentIntersection intersection;
	TLAnnotatedSegment annotatedSegment1;
	TLAnnotatedSegment annotatedSegment2;
	TLPolygonPartRef partRefs[4];	// "weak" references
} TLIntersection;

enum {
	TLPartEndingWithSegment1 = 0,
	TLPartStartingWithSegment1 = 1,
	TLPartEndingWithSegment2 = 2,
	TLPartStartingWithSegment2 = 3
};
typedef tl_uint_t TLPartReferenceIndicator;

typedef struct TL_PolygonPart {
	tl_uint_t retainCount;
	TLPolygonRef polygon;
	TLPolygonPartRef firstPartOfPolygon;	// "weak" reference (though shouldn't need to be)
	TLIntersectionRef startIntersection;
	TLIntersectionRef endIntersection;
	bool isUsed;
} TLPolygonPart;

static inline TLAnnotatedSegment TLAnnotatedSegmentMake(TLSegment segment,
														TLPolygonRef polygon,
														tl_uint_t indexOfEndpointA)
{
	TLAnnotatedSegment annotatedSegment = {
		.segment = segment,
		.polygon = polygon,
		.indexOfEndpointA = indexOfEndpointA
	};
	return annotatedSegment;
}


#pragma mark Polygon clipping, intersection object

static TLIntersectionRef TLIntersectionCreate(TLSegmentIntersection segIntersection,
											  TLAnnotatedSegment annotatedSegment1,
											  TLAnnotatedSegment annotatedSegment2)
{
	TLMutableIntersectionRef intersection = (TLMutableIntersectionRef)malloc(sizeof(TLIntersection));
	if (intersection) {
		intersection->retainCount = 1;
		intersection->intersection = segIntersection;
		intersection->annotatedSegment1 = annotatedSegment1;
		intersection->annotatedSegment2 = annotatedSegment2;
		tl_uint_t numPartRefs = sizeof(intersection->partRefs) / sizeof(intersection->partRefs[0]);
		for (tl_uint_t partRefIdx = 0; partRefIdx < numPartRefs; ++partRefIdx) {
			intersection->partRefs[partRefIdx] = NULL;
		}
	}
	return intersection;
}

static void TLIntersectionDestroy(TLMutableIntersectionRef intersection) {
	free(intersection);
}

static TLIntersectionRef TLIntersectionRetain(TLIntersectionRef intersection) {
	if (intersection) {
		TLMutableIntersectionRef mutableIntersection = (TLMutableIntersectionRef)intersection;
		mutableIntersection->retainCount += 1;
	}
	return intersection;
}

static void TLIntersectionRelease(TLIntersectionRef intersection) {
	if (intersection) {
		TLMutableIntersectionRef mutableIntersection = (TLMutableIntersectionRef)intersection;
		mutableIntersection->retainCount -= 1;
		if (!mutableIntersection->retainCount) TLIntersectionDestroy(mutableIntersection);
	}
}

static TLMutablePointerArrayRef TLIntersectionsArrayCreateMutable(tl_uint_t countLimit) {
	return TLPointerArrayCreateMutable(countLimit, (void*)TLIntersectionRetain, (void*)TLIntersectionRelease);
}

static void TLIntersectionSetPartReference(TLIntersectionRef intersection, TLPartReferenceIndicator partIndicator, TLPolygonPartRef part) {
	TLMutableIntersectionRef mutableIntersection = (TLMutableIntersectionRef)intersection;
	mutableIntersection->partRefs[partIndicator] = part;
}


static bool TLIntersectionPolygonIsSegment1(TLIntersectionRef intersection, TLPolygonRef polygon) {
	return (polygon == intersection->annotatedSegment1.polygon);
}

#pragma mark Polygon clipping, polygon part object

static TLPolygonPartRef TLPolygonPartCreate(TLPolygonRef polygon,
											TLPolygonPartRef firstPartOfPolygon,
											TLIntersectionRef startIntersection,
											TLIntersectionRef endIntersection)
{
	TLMutablePolygonPartRef polygonPart = (TLMutablePolygonPartRef)malloc(sizeof(TLPolygonPart));
	if (polygonPart) {
		polygonPart->retainCount = 1;
		polygonPart->polygon = TLPolygonRetain(polygon);
		polygonPart->firstPartOfPolygon = firstPartOfPolygon;
		polygonPart->startIntersection = TLIntersectionRetain(startIntersection);
		polygonPart->endIntersection = TLIntersectionRetain(endIntersection);
		polygonPart->isUsed = false;
	}
	return polygonPart;
}

static void TLPolygonPartDestroy(TLMutablePolygonPartRef polygonPart) {
	TLPolygonRelease(polygonPart->polygon);
	TLIntersectionRelease(polygonPart->startIntersection);
	TLIntersectionRelease(polygonPart->endIntersection);
	free(polygonPart);
}

static TLPolygonPartRef TLPolygonPartRetain(TLPolygonPartRef polygonPart) {
	if (polygonPart) {
		TLMutablePolygonPartRef mutablePolygonPart = (TLMutablePolygonPartRef)polygonPart;
		mutablePolygonPart->retainCount += 1;
	}
	return polygonPart;
}

static void TLPolygonPartRelease(TLPolygonPartRef polygonPart) {
	if (polygonPart) {
		TLMutablePolygonPartRef mutablePolygonPart = (TLMutablePolygonPartRef)polygonPart;
		mutablePolygonPart->retainCount -= 1;
		if (!mutablePolygonPart->retainCount) TLPolygonPartDestroy(mutablePolygonPart);
	}
}

static TLMutablePointerArrayRef TLPartsArrayCreateMutable(tl_uint_t countLimit) {
	return TLPointerArrayCreateMutable(countLimit, (void*)TLPolygonPartRetain, (void*)TLPolygonPartRelease);
}


#pragma mark Polygon clipping, intersection finding

static TLPointerArrayRef TLCreateIntersectionsBetweenSegArraysSLOW(TLArrayRef segments1, TLArrayRef segments2) {
	// NOTE: This is a naïve implementation. A plane-sweep algorithm could be more efficient.
	TLMutablePointerArrayRef intersections = TLIntersectionsArrayCreateMutable(0);
	if (!intersections) {	// bail
		return NULL;
	}
	tl_uint_t numSegments1 = TLArrayGetCount(segments1);
	tl_uint_t numSegments2 = TLArrayGetCount(segments2);
	for (tl_uint_t idxSegment1 = 0; idxSegment1 < numSegments1; ++idxSegment1) {
		TLAnnotatedSegment segmentInfo1 = *(const TLAnnotatedSegment*)TLArrayGetItemAtIndex(segments1, idxSegment1);
		for (tl_uint_t idxSegment2 = 0; idxSegment2 < numSegments2; ++idxSegment2) {
			TLAnnotatedSegment segmentInfo2 = *(const TLAnnotatedSegment*)TLArrayGetItemAtIndex(segments2, idxSegment2);
			TLSegmentIntersection intersectionInfo;
			bool segmentsIntersect = TLSegmentsIntersect(segmentInfo1.segment, segmentInfo2.segment, &intersectionInfo);
			if (segmentsIntersect) {
				TLIntersectionRef polygonIntersection = TLIntersectionCreate(intersectionInfo, segmentInfo1, segmentInfo2);
				TLPointerArrayAppendItem(intersections, polygonIntersection);
				TLIntersectionRelease(polygonIntersection);
			}
		}
	}
	return intersections;
}

static inline TLPointerArrayRef TLCreateIntersectionsBetweenAnnotatedSegmentArrays(TLArrayRef segments1,
																				   TLArrayRef segments2)
{
	return TLCreateIntersectionsBetweenSegArraysSLOW(segments1, segments2);
}

static TLArrayRef TLCreateAnnotatedSegmentArrayForMultiPolygon(TLMultiPolygonRef multiPoly) {	
	TLMutableArrayRef annotatedSegments = TLArrayCreateMutable(sizeof(TLAnnotatedSegment), 0);
	tl_uint_t numRings = TLMultiPolygonGetCount(multiPoly);
	for (tl_uint_t ringIdx = 0; ringIdx < numRings; ++ringIdx) {
		TLPolygonRef polygon = TLMultiPolygonGetPolygon(multiPoly, ringIdx);
		tl_uint_t numVertices = TLPolygonGetCount(polygon);
		for (tl_uint_t idxVertB = 1; idxVertB < numVertices; ++idxVertB) {
			tl_uint_t idxVertA = idxVertB - 1;
			TLSegment segment = TLSegmentMake(TLPolygonGetPoint(polygon, idxVertA),
											  TLPolygonGetPoint(polygon, idxVertB));
			TLAnnotatedSegment annotatedSegment = TLAnnotatedSegmentMake(segment, polygon, idxVertA);
			TLArrayAppendItem(annotatedSegments, &annotatedSegment);
		}
	}
	return annotatedSegments;	
}

static TLPointerArrayRef TLCreateIntersectionsBetweenPolygons(TLMultiPolygonRef polygon, TLMultiPolygonRef clipPolygon) {
	TLArrayRef polygonSegments = TLCreateAnnotatedSegmentArrayForMultiPolygon(polygon);
	TLArrayRef clipSegments = TLCreateAnnotatedSegmentArrayForMultiPolygon(clipPolygon);
	
	TLPointerArrayRef intersections = TLCreateIntersectionsBetweenAnnotatedSegmentArrays(polygonSegments, clipSegments);
	TLArrayRelease(polygonSegments);
	TLArrayRelease(clipSegments);
	return intersections;
}


#pragma mark Polygon clipping, part manipulation

static void TLPolygonPartRegisterWithIntersections(TLPolygonPartRef part) {
	if (part->startIntersection) {
		TLIntersectionRef startIntersection = part->startIntersection;
		bool partPolygonIsSegment1 = TLIntersectionPolygonIsSegment1(startIntersection, part->polygon);
		TLPartReferenceIndicator partIndicator = partPolygonIsSegment1 ? TLPartStartingWithSegment1 : TLPartStartingWithSegment2;
		TLIntersectionSetPartReference(startIntersection, partIndicator, part);
	}
	
	if (part->endIntersection) {
		TLIntersectionRef endIntersection = part->endIntersection;
		bool partPolygonIsSegment1 = TLIntersectionPolygonIsSegment1(endIntersection, part->polygon);
		TLPartReferenceIndicator partIndicator = partPolygonIsSegment1 ? TLPartEndingWithSegment1 : TLPartEndingWithSegment2;
		TLIntersectionSetPartReference(endIntersection, partIndicator, part);
	}
}

static TLCompareResult TLUIntegerCompare(tl_uint_t a, tl_uint_t b) {
	if (a < b) return TLCompareLessThan;
	else if (a > b) return TLCompareGreaterThan;
	else return TLCompareEqual;
}

// Sorts by: vertex || travel
static TLCompareResult TLIntersectionsCompare(const void* item1, const void* item2, void* context) {
	TLPolygonRef polygon = (TLPolygonRef)context;
	TLIntersectionRef intersectionRef1 = (TLIntersectionRef)item1;
	TLIntersectionRef intersectionRef2 = (TLIntersectionRef)item2;
	
	bool polygonIsSegment1OfIntersection1 = TLIntersectionPolygonIsSegment1(intersectionRef1, polygon);
	bool polygonIsSegment1OfIntersection2 = TLIntersectionPolygonIsSegment1(intersectionRef2, polygon);
	
	tl_uint_t comparedVertex1 = (polygonIsSegment1OfIntersection1 ?
								 intersectionRef1->annotatedSegment1.indexOfEndpointA :
								 intersectionRef1->annotatedSegment2.indexOfEndpointA);
	tl_uint_t comparedVertex2 = (polygonIsSegment1OfIntersection2 ?
								 intersectionRef2->annotatedSegment1.indexOfEndpointA :
								 intersectionRef2->annotatedSegment2.indexOfEndpointA);
	TLCompareResult compareResult = TLUIntegerCompare(comparedVertex1, comparedVertex2);
	if (!compareResult) {
		// handle multiple intersections within a single segment
		double comparedTravel1 = (polygonIsSegment1OfIntersection1 ?
								  intersectionRef1->intersection.travelAlongSegment1 :
								  intersectionRef1->intersection.travelAlongSegment2);
		double comparedTravel2 = (polygonIsSegment1OfIntersection2 ?
								  intersectionRef2->intersection.travelAlongSegment1 :
								  intersectionRef2->intersection.travelAlongSegment2);
		compareResult = TLFloatCompare(comparedTravel1, comparedTravel2);
		if (!compareResult) {
			// handle intersection at vertex in other polygon
			comparedVertex1 = (polygonIsSegment1OfIntersection1 ?
							   intersectionRef1->annotatedSegment2.indexOfEndpointA :
							   intersectionRef1->annotatedSegment1.indexOfEndpointA);
			comparedVertex2 = (polygonIsSegment1OfIntersection2 ?
							   intersectionRef2->annotatedSegment2.indexOfEndpointA :
							   intersectionRef2->annotatedSegment1.indexOfEndpointA);
			compareResult = TLFloatCompare(comparedVertex1, comparedVertex2);
		}
	}
	return compareResult;
}

static TLPointerArrayRef TLPointerArrayCreatePolygonParts(TLPointerArrayRef intersections, TLPolygonRef polygon) {
	TLMutablePointerArrayRef polygonIntersectionRefs = TLIntersectionsArrayCreateMutable(0);
	if (!polygonIntersectionRefs) {	// bail
		return NULL;
	}
	tl_uint_t numAllIntersections = TLPointerArrayGetCount(intersections);
	for (tl_uint_t intersectionIdx = 0; intersectionIdx < numAllIntersections; ++intersectionIdx) {
		TLIntersectionRef intersectionRef = (TLIntersectionRef)TLPointerArrayGetItemAtIndex(intersections, intersectionIdx);
		if (intersectionRef->annotatedSegment1.polygon == polygon ||
			intersectionRef->annotatedSegment2.polygon == polygon)
		 {
			 TLPointerArrayAppendItem(polygonIntersectionRefs, intersectionRef);
		}
	}
	
	// sort polygonIntersections by vertex, travel
	void* sortContext = (void*)polygon;
	TLPointerArraySort(polygonIntersectionRefs, TLIntersectionsCompare, sortContext);
	
	// append a new part at every intersection
	tl_uint_t numPolygonIntersections = TLPointerArrayGetCount(polygonIntersectionRefs);
	TLMutablePointerArrayRef polygonParts = TLPointerArrayCreateMutable(numPolygonIntersections + 1,
																		(void*)TLPolygonPartRetain,
																		(void*)TLPolygonPartRelease);
	if (!polygonParts) {	// clean up and bail
		TLPointerArrayRelease(polygonIntersectionRefs);
		return NULL;
	}
	TLIntersectionRef currentStartIntersection = NULL;
	TLPolygonPartRef firstPartOfPolygon = NULL;
	bool previousIntersectionWasAtVertex = false;
	for (tl_uint_t polyIntersectionIdx = 0; polyIntersectionIdx < numPolygonIntersections; ++polyIntersectionIdx) {
		TLIntersectionRef endIntersection = (TLIntersectionRef)TLPointerArrayGetItemAtIndex(polygonIntersectionRefs,
																							polyIntersectionIdx);
		
		bool polygonIsSegment1 = TLIntersectionPolygonIsSegment1(endIntersection, polygon);
		double endIntersectionTravel = (polygonIsSegment1 ?
										endIntersection->intersection.travelAlongSegment1 :
										endIntersection->intersection.travelAlongSegment2);
		
		if (!currentStartIntersection && TLFloatEqual(endIntersectionTravel, 0.0)) {
			// TODO: handle intersection at very start of polygon by not emitting part with NULL startIntersection (?)
			
		}
		
		if (previousIntersectionWasAtVertex) {
			// TODO: something...
			previousIntersectionWasAtVertex = false;
		}
		
		if (TLFloatEqual(endIntersectionTravel, 1.0)) {
			/* NOTE: In this case, the next intersection(s) matters. It could:
			 - belong to the next segment with no travel difference, meaning intersection happened at this polygon's vertex
			 - belong to the same segment with no travel difference, if the other polygon also intersects this at a vertex of its own
			 - belong to another segment with a significant travel difference, meaning this polygon is collinear with the other for a time
			 
			 Intersections like this are ordered:
			   firstSegWithOtherSeg secondSegWithOtherSeg
			 or, if the other polygon also intersects at a vertex:
			   firstSegWithFirstOtherSeg firstSegWithSecondOtherSeg secondSegWithFirstOtherSeg secondSegWithSecondOtherSeg
			 
			 If either one is just a "ricochet" (e.g. >| or ><), no part is needed
			 */
			
			// TODO: handle intersections at vertex (which result in 2/4 intersections at same point)
			previousIntersectionWasAtVertex = true;
		}
		

		
		TLPolygonPartRef part = TLPolygonPartCreate(polygon, firstPartOfPolygon, currentStartIntersection, endIntersection);
		if (!part) {	// clean up and bail
			TLPointerArrayRelease(polygonIntersectionRefs);
			TLPointerArrayRelease(polygonParts);
			return NULL;
		}
		if (!firstPartOfPolygon) firstPartOfPolygon = part;
		TLPolygonPartRegisterWithIntersections(part);
		TLPointerArrayAppendItem(polygonParts, part);
		TLPolygonPartRelease(part);
		currentStartIntersection = endIntersection;
	}
	// TODO: what about currentStartIntersection at 1.0?
	TLPolygonPartRef lastPart = TLPolygonPartCreate(polygon, firstPartOfPolygon, currentStartIntersection, NULL);
	if (!lastPart) {	// clean up and bail
		TLPointerArrayRelease(polygonIntersectionRefs);
		TLPointerArrayRelease(polygonParts);
		return NULL;
	}
	TLPolygonPartRegisterWithIntersections(lastPart);
	TLPointerArrayAppendItem(polygonParts, lastPart);
	TLPolygonPartRelease(lastPart);
	
	TLPointerArrayRelease(polygonIntersectionRefs);
	return polygonParts;
}

enum {
	TLSegmentIntersectsFromLeft = -1,
	TLSegmentIndeterminate = 0,
	TLSegmentIntersectsFromRight = 1
};
typedef tl_int_t TLIntersectionClassification;

static TLIntersectionClassification TLIntersectionClassify(TLIntersectionRef intersection, bool classifySegment1) {
	TLSegment crossingSegment = (classifySegment1 ?
								 intersection->annotatedSegment1.segment :
								 intersection->annotatedSegment2.segment);
	TLSegment intersectedSegment = (classifySegment1 ?
									intersection->annotatedSegment2.segment :
									intersection->annotatedSegment1.segment);
	
	TLSegmentPointRelation directionOfPointA = TLSegmentCompareToPoint(intersectedSegment, crossingSegment.a);
	if (directionOfPointA == TLSegmentPointToRight) {
		return TLSegmentIntersectsFromRight;
	}
	else if (directionOfPointA == TLSegmentPointToLeft) {
		return TLSegmentIntersectsFromLeft;
	}
	else if (directionOfPointA == TLSegmentPointOnLine) {
		TLSegmentPointRelation directionOfPointB = TLSegmentCompareToPoint(intersectedSegment, crossingSegment.b);
		if (directionOfPointB == TLSegmentPointToRight) {
			return TLSegmentIntersectsFromLeft;
		}
		else if (directionOfPointB == TLSegmentPointToLeft) {
			return TLSegmentIntersectsFromRight;
		}
		else {	// TLSegmentPointOnLine (TLSegmentHasNoDirection would be handled in outer scope)
			return TLSegmentIndeterminate;
		}
	}
	else {	// TLSegmentHasNoDirection
		return TLSegmentIndeterminate;
	}
}

static bool TLPolygonPartIsInside(TLPolygonPartRef part, TLMultiPolygonRef multiPoly) {
	// either end of the part should work; clip rings are assumed to properly nest
	if (part->startIntersection) {
		TLIntersectionRef startIntersection = part->startIntersection;
		// part is inside if next point is to the right or on the intersected segment
		bool partPolygonIsSegment1 = TLIntersectionPolygonIsSegment1(startIntersection, part->polygon);
		TLIntersectionClassification direction = TLIntersectionClassify(startIntersection, partPolygonIsSegment1);
		if (direction == TLSegmentIntersectsFromLeft) return true;
		else return false;
	}
	else if (part->endIntersection) {
		TLIntersectionRef endIntersection = part->endIntersection;
		// part is inside if previous point is to the right or on the intersected segment
		bool partPolygonIsSegment1 = TLIntersectionPolygonIsSegment1(endIntersection, part->polygon);
		TLIntersectionClassification direction = TLIntersectionClassify(endIntersection, partPolygonIsSegment1);
		if (direction == TLSegmentIntersectsFromRight) return true;
		else return false;
	}
	else {
		// just see if any point of part.polygon is inside multiPoly
		(void)multiPoly;
		tl_uint_t numVertices = TLPolygonGetCount(part->polygon);
		if (numVertices) {
			CGPoint testPoint = TLPolygonGetPoint(part->polygon, 0);
			return TLMultiPolygonContainsPoint(multiPoly, testPoint);
		}
		else return false;
	}
}

static void TLPolygonAppendPart(TLMutablePolygonRef outputPolygon,
								TLPolygonPartRef part,
								bool includeEndIntersection)
{
	// TODO: something is causing bad intersection point to be used in some cases (visible with box around LCC projection "wedge")
	tl_uint_t startVertexIdx = 0;
	if (part->startIntersection) {
		TLIntersectionRef startIntersection = part->startIntersection;
		CGPoint firstPoint = startIntersection->intersection.pointOfIntersection;
		TLPolygonAppendPoint(outputPolygon, firstPoint);
		
		bool polygonIsSegment1 = TLIntersectionPolygonIsSegment1(startIntersection, part->polygon);
		startVertexIdx = 1 + (polygonIsSegment1 ?
							  startIntersection->annotatedSegment1.indexOfEndpointA :
							  startIntersection->annotatedSegment2.indexOfEndpointA);
	}
	
	tl_uint_t endVertexLimit = TLPolygonGetCount(part->polygon);
	if (part->endIntersection) {
		TLIntersectionRef endIntersection = part->endIntersection;
		bool polygonIsSegment1 = TLIntersectionPolygonIsSegment1(endIntersection, part->polygon);
		endVertexLimit = 1 + (polygonIsSegment1 ?
							  endIntersection->annotatedSegment1.indexOfEndpointA :
							  endIntersection->annotatedSegment2.indexOfEndpointA);
	}
	
	for (tl_uint_t vertexIdx = startVertexIdx; vertexIdx < endVertexLimit; ++vertexIdx) {
		CGPoint polygonPoint = TLPolygonGetPoint(part->polygon, vertexIdx);
		TLPolygonAppendPoint(outputPolygon, polygonPoint);
	}
	
	if (includeEndIntersection && part->endIntersection) {
		CGPoint lastPoint = part->endIntersection->intersection.pointOfIntersection;
		TLPolygonAppendPoint(outputPolygon, lastPoint);
	}
}

static TLPointerArrayRef TLCreateAllPartsForMultiPolygon(TLPointerArrayRef intersections, TLMultiPolygonRef multiPoly) {
	TLMutablePointerArrayRef multiPolyParts = TLPartsArrayCreateMutable(0);
	if (!multiPolyParts) return NULL;
	
	tl_uint_t numPolygonRings = TLMultiPolygonGetCount(multiPoly);
	for (tl_uint_t polygonRingIdx = 0; polygonRingIdx < numPolygonRings; ++polygonRingIdx) {
		TLPolygonRef polygonRing = TLMultiPolygonGetPolygon(multiPoly, polygonRingIdx);
		TLPointerArrayRef ringParts = TLPointerArrayCreatePolygonParts(intersections, polygonRing);
		if (!ringParts) {	// clean up and bail
			TLPointerArrayRelease(multiPolyParts);
			return NULL;
		}
		TLPointerArrayAppendArray(multiPolyParts, ringParts);
		TLPointerArrayRelease(ringParts);
	}
	return multiPolyParts;
}


#pragma mark Polygon clipping, main

TLMultiPolygonRef TLMultiPolygonCreateFromClippedMultiPolyline(TLMultiPolygonRef multiLine, TLMultiPolygonRef clipPoly) {
	// get intersections
	TLPointerArrayRef intersections = TLCreateIntersectionsBetweenPolygons(multiLine, clipPoly);
	if (!intersections) {
		return NULL;
	}
	
	// intersections -> parts
	TLPointerArrayRef allParts = TLCreateAllPartsForMultiPolygon(intersections, multiLine);
	if (!allParts) {
		TLPointerArrayRelease(intersections);
		return NULL;
	}
	
	// parts -> clipped lines
	TLMutableMultiPolygonRef clippedLines = TLMultiPolygonCreateMutable(0);
	if (!clippedLines) {
		TLPointerArrayRelease(intersections);
		TLPointerArrayRelease(allParts);
		return NULL;
	}
	tl_uint_t numParts = TLPointerArrayGetCount(allParts);
	for (tl_uint_t partIdx = 0; partIdx < numParts; ++partIdx) {
		TLPolygonPartRef part = (TLPolygonPartRef)TLPointerArrayGetItemAtIndex(allParts, partIdx);
		if (TLPolygonPartIsInside(part, clipPoly)) {
			// generate line for part
			TLMutablePolygonRef clippedLine = TLPolygonCreateMutable(0);
			if (!clippedLine) {
				TLPointerArrayRelease(intersections);
				TLPointerArrayRelease(allParts);
				TLMultiPolygonRelease(clippedLines);
				return NULL;
			}
			TLPolygonAppendPart(clippedLine, part, true);
			TLMultiPolygonAppendPolygon(clippedLines, clippedLine);
			TLPolygonRelease(clippedLine);
		}
	}
	TLPointerArrayRelease(intersections);
	TLPointerArrayRelease(allParts);
	return clippedLines;
}

static bool TLPolygonPartIsUsed(TLPolygonPartRef partRef) {
	return partRef->isUsed;
}

static void TLPolygonPartMarkUsed(TLPolygonPartRef partRef) {
	TLPolygonPart* mutablePartRef = (TLPolygonPart*)partRef;
	mutablePartRef->isUsed = true;
}

static TLPolygonPartRef TLPolygonPartGetNext(TLPolygonPartRef previousPart) {
	TLPolygonPartMarkUsed(previousPart);
	TLPolygonPartRef nextPart = NULL;
	if (previousPart->endIntersection) {
		TLIntersectionRef endIntersection = previousPart->endIntersection;
		bool polygonIsSegment1 = TLIntersectionPolygonIsSegment1(endIntersection, previousPart->polygon);
		// parts should only be emitted when crossing, so take the opposite segment leaving the intersection
		TLPartReferenceIndicator otherPolygonIndicator = (polygonIsSegment1 ?
														  TLPartStartingWithSegment2 :
														  TLPartStartingWithSegment1);
		nextPart = endIntersection->partRefs[otherPolygonIndicator];
	}
	else {
		nextPart = previousPart->firstPartOfPolygon;
	}
	return nextPart;
}

static TLPolygonPartRef TLArrayFindNextUnusedPart(TLPointerArrayRef parts, tl_uint_t* searchPlaceholderIdx) {
	tl_uint_t numParts = TLPointerArrayGetCount(parts);
	for (tl_uint_t partIdx = *searchPlaceholderIdx; partIdx < numParts; ++partIdx) {
		TLPolygonPartRef partRef = (TLPolygonPartRef)TLPointerArrayGetItemAtIndex(parts, partIdx);
		bool partIsUsed = TLPolygonPartIsUsed(partRef);
		if (!partIsUsed) {
			*searchPlaceholderIdx = partIdx + 1;
			TLPolygonPartMarkUsed(partRef);
			return partRef;
		}
	}
	return NULL;
}

static TLPolygonRef TLPolygonCreateByFollowingParts(TLPolygonPartRef partOfOrigin, tl_uint_t maxNumPartsExpected) {
	TLMutablePolygonRef clippedRing = TLPolygonCreateMutable(0);
	if (!clippedRing) {
		return NULL;
	}
	
	tl_uint_t numFollowedParts = 0;
	TLPolygonPartRef currentPart = partOfOrigin;
	do {
		TLAssert(numFollowedParts <= maxNumPartsExpected, "Unexpected number of loops through clipped polygon parts");
		TLPolygonAppendPart(clippedRing, currentPart, false);	// TODO: make sure polygon will always be properly closed
		currentPart = TLPolygonPartGetNext(currentPart);
		TLAssert(currentPart, "Bad part fetched for next step");
		++numFollowedParts;
	} while (currentPart != partOfOrigin);
	
	return clippedRing;
}

// Neighborhood to right of clipPolygon is inside, and therefore kept
TLMultiPolygonRef TLMultiPolygonCreateFromClippedMultiPolygon(TLMultiPolygonRef multiPoly, TLMultiPolygonRef clipPoly) {
	// get intersections
	TLPointerArrayRef intersections = TLCreateIntersectionsBetweenPolygons(multiPoly, clipPoly);
	if (!intersections) {	// bail
		return NULL;
	}
	
	// intersections->parts
	TLPointerArrayRef multiPolyParts = TLCreateAllPartsForMultiPolygon(intersections, multiPoly);
	if (!multiPolyParts) {	// clean up and bail
		TLPointerArrayRelease(intersections);
		return NULL;
	}
	TLPointerArrayRef clipPolyParts = TLCreateAllPartsForMultiPolygon(intersections, clipPoly);
	if (!clipPolyParts) {		// clean up and bail
		TLPointerArrayRelease(intersections);
		TLPointerArrayRelease(multiPolyParts);
		return NULL;
	}
	
	// parts -> clipped polygon
	TLMutableMultiPolygonRef clippedPolygon = TLMultiPolygonCreateMutable(0);
	if (!clippedPolygon) {	// clean up and bail
		TLPointerArrayRelease(intersections);
		TLPointerArrayRelease(multiPolyParts);
		TLPointerArrayRelease(clipPolyParts);
		return NULL;
	}
	tl_uint_t searchPlaceholderIdx = 0;
	TLPolygonPartRef partOfOrigin = TLArrayFindNextUnusedPart(multiPolyParts, &searchPlaceholderIdx);
	while (partOfOrigin) {
		bool partIsInside = TLPolygonPartIsInside(partOfOrigin, clipPoly);
		if (partIsInside) {
			tl_uint_t maxSaneNumberOfFollowedParts = TLPointerArrayGetCount(multiPolyParts) + TLPointerArrayGetCount(clipPolyParts) + 1;
			TLPolygonRef clippedRing = TLPolygonCreateByFollowingParts(partOfOrigin, maxSaneNumberOfFollowedParts);
			if (!clippedRing) {		// clean up and bail
				TLMultiPolygonRelease(clippedPolygon);
				TLPointerArrayRelease(intersections);
				TLPointerArrayRelease(multiPolyParts);
				TLPointerArrayRelease(clipPolyParts);
				return NULL;
			}
			TLMultiPolygonAppendPolygon(clippedPolygon, clippedRing);
			TLPolygonRelease(clippedRing);
		}
		partOfOrigin = TLArrayFindNextUnusedPart(multiPolyParts, &searchPlaceholderIdx);
	}
	
	TLPointerArrayRelease(intersections);
	TLPointerArrayRelease(multiPolyParts);
	TLPointerArrayRelease(clipPolyParts);
	return clippedPolygon;	
}
