//
//  TLProjectionGeometry.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 7/1/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLProjectionGeometry.h"

/*
 Points, Lines, Polygons and Bitmaps each need to be Projected, Unprojected and Reprojected, as well as Measured.
 (For our purposes, we need not yet worry about TIN features and Datum Conversion operations.)
 */



/* TODO: this function does not handle bounds that contain, but are themselves outside, the range of some
 (e.g. Orthographic and other whole-Earth) projections; nor is it within the scope of this function to do so.
 
 Another issue is that these unprojected bounds may have "ideal" areas on the sphere, but may be over- or under-
 densified if they are subsequently reprojected.
 
 A better architecture would:
 1) Create a polygon representing the ivertible region of the projected bounding box.
 The invertible region may actually be disjoint, meaning the following steps would be performed on each.
 2a) If geographic coordinates are what is desired, unproject iteratively as below.
 2b) If coordinates are to be re-projected, the source polygon should be densified according to the effect on the
 reprojected polygon(s!)' area.
 */
TLCoordPolygonRef TLCoordPolygonCreateFromProjectedBounds(TLBounds bounds, CTProjection* projection) {
	/*
	 This initial boundsPolygon is a bit oversimplified in the case that a pair of projected vertices could
	 represent points more than a hemisphere away, but when unprojected they will be considered to represent
	 the shorter great circle path instead of the longer.
	 
	 However, the iterative densification approach always results in at least 9 vertices. A properly-used
	 projection will never map the same coordinate to more than one position, so any bounds rectangle within
	 the range of the projection will represent at most one copy of the Earth, and the midpoints added during
	 the first iteration should be a hemisphere or less apart. So by the second iteration, all segments should
	 be properly interpreted.
	 */
	TLPolygonRef boundsPolygon = TLPolygonCreateFromBounds(bounds);
	
	TLCoordPolygonRef unprojectedPolygon = NULL;
	double previousUnprojectedArea = 0.0;
	tl_uint_t remainingIterations = 10;	// Remember that number of vertexes doubles each iteration.
	while (remainingIterations) {
		TLCoordPolygonRelease(unprojectedPolygon);
		unprojectedPolygon = TLCoordPolygonCreateByUnprojectingPolygon(boundsPolygon, projection, NO);
		double unprojectedArea = TLCoordPolygonGetArea(unprojectedPolygon);
		
		if (!unprojectedArea) break;
		double percentGainOrLoss = fabs((unprojectedArea - previousUnprojectedArea) / unprojectedArea);
		//printf("Area of selection = %f, gained/lost: %f (remaining: %u)\n", unprojectedArea, percentGainOrLoss, remainingIterations);
		previousUnprojectedArea = unprojectedArea;
		if (percentGainOrLoss < 0.001) break;
		
		TLPolygonRef densifiedBounds = TLPolygonCreateByDensifyingVertices(boundsPolygon, 1);
		TLPolygonRelease(boundsPolygon);
		boundsPolygon = densifiedBounds;
		
		--remainingIterations;
	}
	TLPolygonRelease(boundsPolygon);
	//printf("Done with %u remaining, an area of %f.\n\n", remainingIterations, previousUnprojectedArea);
	
	return unprojectedPolygon;
}

TLPolygonRef TLPolygonCreateByProjectingCoordPolygon(TLCoordPolygonRef unprojectedPolygon, CTProjection* projection, BOOL failOnError) {
	tl_uint_t vertexCount = TLCoordPolygonGetCount(unprojectedPolygon);
	TLMutablePolygonRef projectedOutput = TLPolygonCreateMutable(vertexCount);
	for (tl_uint_t vertexIdx = 0; vertexIdx < vertexCount; ++vertexIdx) {
		TLCoordinate unprojectedCoord = TLCoordPolygonGetCoordinate(unprojectedPolygon, vertexIdx);
		CGPoint projectedPoint = [projection projectCoordinate:unprojectedCoord];
		if (failOnError && [projection hadErrorResult]) {
			TLPolygonRelease(projectedOutput);
			return NULL;
		}
		TLPolygonAppendPoint(projectedOutput, projectedPoint);
	}
	return projectedOutput;
}

TLCoordPolygonRef TLCoordPolygonCreateByUnprojectingPolygon(TLPolygonRef projectedPolygon, CTProjection* projection, BOOL failOnError) {
	tl_uint_t vertexCount = TLPolygonGetCount(projectedPolygon);
	TLMutableCoordPolygonRef unprojectedOutput = TLCoordPolygonCreateMutable(vertexCount);
	for (tl_uint_t vertexIdx = 0; vertexIdx < vertexCount; ++vertexIdx) {
		CGPoint projectedPoint = TLPolygonGetPoint(projectedPolygon, vertexIdx);
		TLCoordinate unprojectedCoord = [projection unprojectPoint:projectedPoint];
		if (failOnError && [projection hadErrorResult]) {
			TLCoordPolygonRelease(unprojectedOutput);
			return NULL;
		}
		TLCoordPolygonAppendCoordinate(unprojectedOutput, unprojectedCoord);
	}
	return unprojectedOutput;
}


static const void* TLRetainPolygonCB(CFAllocatorRef allocator, const void* value) {
	(void)allocator;
	return TLPolygonRetain((TLPolygonRef)value);
}

static void TLReleasePolygonCB(CFAllocatorRef allocator, const void* value) {
	(void)allocator;
	TLPolygonRelease((TLPolygonRef)value);
}

static CFArrayCallBacks TLPolygonArrayCallbacks() {
	CFArrayCallBacks polygonArrayCallbacks;
	memset(&polygonArrayCallbacks, 0, sizeof(CFArrayCallBacks));
	polygonArrayCallbacks.retain = TLRetainPolygonCB;
	polygonArrayCallbacks.release = TLReleasePolygonCB;
	return polygonArrayCallbacks;
}

enum {
	TLLongitudeEastToWest = -1,
	TLLongitudeSame = 0,
	TLLongitudeWestToEast = 1
};
typedef NSInteger TLLongitudeOrdering;

static TLLongitudeOrdering TLLongitudeCompare(double lon1, double lon2) {
	static const double fullCircleDeg = 360.0;
	static const double hemisphereDeg = 180.0;
	const double meridianPadding = M_PI * FLT_EPSILON * TLCoordinateRadiansToDegrees;
	double lonDifference = lon2 - lon1;
	if (fabs(lonDifference) < meridianPadding) return TLLongitudeSame;
	// lonDifference is the amount lon2 is east of lon1...
	if (lonDifference < 0.0) lonDifference += fullCircleDeg;
	// ...unless that's more than a hemisphere, in which case lon2 is actually west of lon1.
	return (lonDifference > hemisphereDeg) ? TLLongitudeEastToWest : TLLongitudeWestToEast;
}

// Does the shortest route between lon1 and lon2 cross meridian? If so, in which direction?
static TLLongitudeOrdering TLMeridianGetCrossDirection(double meridian, double lon1, double lon2) {
	static const double fullCircleDeg = 360.0;
	static const double hemisphereDeg = 180.0;
	// -FLT_EPSILON replaces 0.0 below because if meridian is basically equal to lonBase, meridianDistance can be slightly negative
	static const double zeroThreshold = -FLT_EPSILON;
	
	double lonDifference = lon2 - lon1;
	if (lonDifference < 0.0) lonDifference += fullCircleDeg;
	TLLongitudeOrdering potentialDirection = TLLongitudeWestToEast;
	double lonBase = lon1;
	double lonLen = lonDifference;			// lonDifference is the amount lon2 is east of lon1...
	if (lonDifference > hemisphereDeg) {	// ...unless that's more than a hemisphere...
		//...in which case lon2 is actually west of lon1.
		potentialDirection = TLLongitudeEastToWest;
		lonBase = lon2;
		lonLen = fullCircleDeg - lonDifference;
	}
	
	// Is meridian within lonLen east of lonBase?
	double meridianDistance = meridian - lonBase;
	if (meridianDistance < zeroThreshold) meridianDistance += fullCircleDeg;	// make sure we're measuring distance to the east
	if (meridianDistance <= lonLen) return potentialDirection;
	else return TLLongitudeSame;
}

#define TL_MERIDIAN_PADDING (M_PI * FLT_EPSILON * TLCoordinateRadiansToDegrees)

static inline double TLMeridianSurrogateOnEast(double meridian) {
	return meridian + TL_MERIDIAN_PADDING;
}

static inline double TLMeridianSurrogateOnWest(double meridian) {
	return meridian - TL_MERIDIAN_PADDING;	
}

static TLCoordinate TLCoordinateSurrogateAtMeridian(double meridian, TLCoordinate coordinate1, TLCoordinate coordinate2) {
	/* TODO: this is incorrect, and can lead to latitudes outside the [-90, 90] range, as well as NaNs and Infs which 
	 can explode some projection functions if allowed through!!! */
	/*
	 Desired equivalence:
	 (surrogateCoordinate.lon - coordinate1.lon) / (coordinate2.lon - coordinate1.lon) =
	 (surrogateCoordinate.lat - coordinate1.lat) / (coordinate2.lat - coordinate1.lat)
	 
	 If (surrogateCoordinate.lon - coordinate1.lon) / (coordinate2.lon - coordinate1.lon) is
	 taken to be blendRatio, then:
	 surrogateCoordinate.lat = blendRatio * (coordinate2.lat - coordinate1.lat) + coordinate1.lat
	 
	 surrogateCoordinate.lon is just the "meridian", the caller is responsible for picking a suitable value.
	 */
	double blendRatio = (meridian - coordinate1.lon) / (coordinate2.lon - coordinate1.lon);
	double surrogateLat = coordinate1.lat + blendRatio * (coordinate2.lat - coordinate1.lat);
	if (!isnormal(surrogateLat) && surrogateLat != 0.0) {
		//printf("bad surrogateLat, replacing with something just as wrong!\n");
		surrogateLat = coordinate1.lat;
	}
	return TLCoordinateMake(surrogateLat, meridian);
}

static inline double TLLongitudeSignedDistance(double lon1, double lon2) {
	double distance = lon2 - lon1;
	if (distance < -180.0) distance += 360.0;
	return distance;
}

static CFArrayRef TLArrayCreateBySplittingLineAcrossMeridian(TLCoordPolygonRef inputLine, double meridian) {
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef splitLines = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	/* Points floating "on" the meridian itself can cause trouble. The meridianPadding avoids this.
	 FYI: proj_adjlon() is where libproj4 does this, and that doesn't seem to purposely adjust either +/- 180deg,
	 rather only if slighty over/under, however due to its units/method/tolerance we compensate significantly.
	 Note also that TLCoordinates can get stored in CGPoints which use floats on 32-bit, so we use float factors. */
	const double kludgeFactor = 30.0;		// TODO: if this code is kept, don't use this fudge factor
	const double meridianPadding = kludgeFactor * M_PI * FLT_EPSILON * TLCoordinateRadiansToDegrees;
	const double eastSideSurrogateMeridian = meridian + meridianPadding;
	const double westSideSurrogateMeridian = meridian - meridianPadding;

	tl_uint_t inputCount = TLCoordPolygonGetCount(inputLine);
	if (!inputCount) return splitLines;
	
	TLCoordinate previousCoordinate = TLCoordPolygonGetCoordinate(inputLine, 0);
	TLMutableCoordPolygonRef currentSegment = TLCoordPolygonCreateMutable(0);
	TLCoordPolygonAppendCoordinate(currentSegment, previousCoordinate);
	tl_uint_t inputIdx = 1;
	
	while (inputIdx < inputCount) {
		TLCoordinate currentCoordinate = TLCoordPolygonGetCoordinate(inputLine, inputIdx);
		TLLongitudeOrdering crossDirection = TLMeridianGetCrossDirection(meridian, previousCoordinate.lon, currentCoordinate.lon);
		if (crossDirection == TLLongitudeSame) {
			TLCoordPolygonAppendCoordinate(currentSegment, currentCoordinate);
		}
		else {
			//printf("Coordinates (%f, %f) and (%f, %f) cross meridian %f from %s.\n", previousCoordinate.lat, previousCoordinate.lon, currentCoordinate.lat, currentCoordinate.lon, meridian, crossDirection == TLLongitudeEastToWest ? "e->w" : "w->e");
			TLCoordinate surrogateCoordinate1 = previousCoordinate;
			TLCoordinate surrogateCoordinate2 = currentCoordinate;
			if (crossDirection == TLLongitudeEastToWest) {
				surrogateCoordinate1 = TLCoordinateSurrogateAtMeridian(eastSideSurrogateMeridian, previousCoordinate, currentCoordinate);
				surrogateCoordinate2 = TLCoordinateSurrogateAtMeridian(westSideSurrogateMeridian, previousCoordinate, currentCoordinate);
			}
			else if (crossDirection == TLLongitudeWestToEast) {
				surrogateCoordinate1 = TLCoordinateSurrogateAtMeridian(westSideSurrogateMeridian, previousCoordinate, currentCoordinate);
				surrogateCoordinate2 = TLCoordinateSurrogateAtMeridian(eastSideSurrogateMeridian, previousCoordinate, currentCoordinate);
			}
			
			TLCoordPolygonAppendCoordinate(currentSegment, surrogateCoordinate1);
			CFArrayAppendValue(splitLines, currentSegment);
			TLCoordPolygonRelease(currentSegment);
			
			currentSegment = TLCoordPolygonCreateMutable(0);
			TLCoordPolygonAppendCoordinate(currentSegment, surrogateCoordinate2);
			
			/*
			 If currentCoordinate is on the meridian, it should be discarded. We take "on the meridian" to mean closer to the
			 meridian than surrogateCoordinate2, which should already be as close to the meridian as practical.
			 */
			double surrogate2FromMeridian = fabs(TLLongitudeSignedDistance(meridian, surrogateCoordinate2.lon));
			double currentFromMeridian = fabs(TLLongitudeSignedDistance(meridian, currentCoordinate.lon));
			if (currentFromMeridian > surrogate2FromMeridian) {
				TLCoordPolygonAppendCoordinate(currentSegment, currentCoordinate);
			}
			else currentCoordinate = surrogateCoordinate2;
		}
		previousCoordinate = currentCoordinate;
		++inputIdx;
	}
	CFArrayAppendValue(splitLines, currentSegment);
	TLCoordPolygonRelease(currentSegment);
	
	return splitLines;
}

static CGPoint TLProjectablePointBetween(TLCoordinate projectableCoordinate,
										 TLCoordinate unprojectableCoordinate,
										 CTProjection* projection)
{
	(void)unprojectableCoordinate;
	// TODO: find a point closer to unprojectableCoordinate
	return [projection projectCoordinate:projectableCoordinate];
}

static BOOL TLPointIsInvalid(CGPoint p) {
	BOOL xIsValid = isnormal(p.x) || (p.x == 0.0);
	BOOL yIsValid = isnormal(p.y) || (p.y == 0.0);
	return !(xIsValid && yIsValid);
}

static CFArrayRef TLArrayCreateFromProjectablePartsOfCoordLine(TLCoordPolygonRef inputPolygon, CTProjection* projection) {
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef lineSegments = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	tl_uint_t inputCount = TLCoordPolygonGetCount(inputPolygon);
	if (!inputCount) return lineSegments;
	
	TLMutablePolygonRef currentSegment = TLPolygonCreateMutable(0);
	bool needsRestart = false;
	TLCoordinate previousCoordinate = TLCoordPolygonGetCoordinate(inputPolygon, 0);
	CGPoint firstProjectedPoint = [projection projectCoordinate:previousCoordinate];
	if ([projection hadErrorResult]) needsRestart = true;
	else TLPolygonAppendPoint(currentSegment, firstProjectedPoint);
	
	tl_uint_t inputIdx = 1;
	while (inputIdx < inputCount) {
		TLCoordinate currentCoordinate = TLCoordPolygonGetCoordinate(inputPolygon, inputIdx);
		CGPoint projectedPoint = [projection projectCoordinate:currentCoordinate];
		BOOL wasError = [projection hadErrorResult] || TLPointIsInvalid(projectedPoint);
		if (wasError && !needsRestart) {
			CGPoint endingPoint = TLProjectablePointBetween(previousCoordinate, currentCoordinate, projection);
			TLPolygonAppendPoint(currentSegment, endingPoint);
			CFArrayAppendValue(lineSegments, currentSegment);
			TLPolygonRelease(currentSegment);
			currentSegment = TLPolygonCreateMutable(0);
			needsRestart = true;
		}
		else if (!wasError) {
			if (needsRestart) {
				CGPoint startingPoint = TLProjectablePointBetween(currentCoordinate, previousCoordinate, projection);
				TLPolygonAppendPoint(currentSegment, startingPoint);
				needsRestart = false;
			}
			TLPolygonAppendPoint(currentSegment, projectedPoint);
		}
		
		previousCoordinate = currentCoordinate;
		++inputIdx;
	}
	CFArrayAppendValue(lineSegments, currentSegment);
	TLPolygonRelease(currentSegment);
	
	return lineSegments;
}

CFArrayRef TLArrayCreateByProjectingCoordLineForDrawing(TLCoordPolygonRef inputPolygon, CTProjection* projection) {
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef allProjectedSegments = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	
	CFArrayRef splitLines = TLArrayCreateBySplittingLineAcrossMeridian(inputPolygon, [projection antimeridian]);
	
	CFIndex lineCount = CFArrayGetCount(splitLines);
	for (CFIndex lineIdx = 0; lineIdx < lineCount; ++lineIdx) {
		TLCoordPolygonRef line = (TLCoordPolygonRef)CFArrayGetValueAtIndex(splitLines, lineIdx);
		CFArrayRef projectedSegments = TLArrayCreateFromProjectablePartsOfCoordLine(line, projection);
		CFIndex projectedCount = CFArrayGetCount(projectedSegments);
		CFArrayAppendArray(allProjectedSegments, projectedSegments, CFRangeMake(0, projectedCount));
		CFRelease(projectedSegments);
	}
	CFRelease(splitLines);
	return allProjectedSegments;
}

#pragma mark Polygon functions

enum {
	TLSplitArrowFlagVisited = 1 << 0,
	TLSplitArrowFlagInpointing = 1 << 1,
	TLSplitArrowFlagEastSide = 1 << 2
};
typedef unsigned char TLSplitArrowFlags;

@interface TLSplitArrow : NSObject {
@private
	double latitudeNearMeridian;
	double longitudeNearMeridian;
	TLSplitArrowFlags flags;
	NSUInteger nextVertexIdx;	// NSNotFound if in-pointing?
	//TLCoordPolygonRef nextVertexPolygon;
}

- (double)comparisonLatitude;
- (NSComparisonResult)compare:(TLSplitArrow*)otherArrow;
- (NSUInteger)indexOfNextPolygonVertex;
- (TLCoordinate)meridianCoordinate;
- (BOOL)isInpointing;
- (BOOL)isEastSide;
- (void)setMarkedUsed;
- (BOOL)isMarkedUsed;

+ (id)arrowToVertex:(NSUInteger)vertexIdx ofPolygon:(TLCoordPolygonRef)polygon fromMeridian:(double)meridian;	// an out-pointing arrow
+ (id)arrowFromVertex:(NSUInteger)vertexIdx ofPolygon:(TLCoordPolygonRef)polygon toMeridian:(double)meridian;	// an in-pointing arrow
@end

@implementation TLSplitArrow

- (double)comparisonLatitude {
	return [self isEastSide] ? -(latitudeNearMeridian + 90.0) : (latitudeNearMeridian + 90.0);
}

static inline NSComparisonResult TLCompareDoubles(double a, double b) {
	if (a > b) return NSOrderedDescending;
	else if (b > a) return NSOrderedAscending;
	else return NSOrderedSame;
}

static inline NSComparisonResult TLCompareDirections(BOOL aIsInpointing, BOOL bIsInpointing) {
	if (aIsInpointing == bIsInpointing) return NSOrderedSame;
	else return aIsInpointing ? NSOrderedAscending : NSOrderedDescending;
}

- (NSComparisonResult)compare:(TLSplitArrow*)otherArrow {
	double selfComparisonLatitude = [self comparisonLatitude];
	double otherComparisonLatitude = [otherArrow comparisonLatitude];
	NSComparisonResult latitudeCompare = TLCompareDoubles(selfComparisonLatitude, otherComparisonLatitude);
	if (latitudeCompare) return latitudeCompare;
	else return TLCompareDirections([self isInpointing], [otherArrow isInpointing]);
	// NOTE: compare polygon refs here as well if tracked
}

- (NSUInteger)indexOfNextPolygonVertex { return nextVertexIdx; }

- (TLCoordinate)meridianCoordinate {
	return TLCoordinateMake(latitudeNearMeridian, longitudeNearMeridian);
}

- (BOOL)isInpointing { return flags & TLSplitArrowFlagInpointing; }
- (BOOL)isEastSide { return flags & TLSplitArrowFlagEastSide; }

- (void)setMarkedUsed { flags |= TLSplitArrowFlagVisited; }
- (BOOL)isMarkedUsed { return flags & TLSplitArrowFlagVisited; }

- (id)initWithVertex:(NSUInteger)vertexIdx
		   andVertex:(NSUInteger)secondaryVertexIdx
		   ofPolygon:(TLCoordPolygonRef)polygon
		withMeridian:(double)meridian
		asInpointing:(BOOL)inpointing
{
	self = [super init];
	if (self) {
		nextVertexIdx = vertexIdx;
		if (inpointing) flags |= TLSplitArrowFlagInpointing;
		
		// determine which side of meridian this arrow is
		TLCoordinate mainCoordinate = TLCoordPolygonGetCoordinate(polygon, vertexIdx);
		TLLongitudeOrdering travelToMeridian = TLLongitudeCompare(mainCoordinate.lon, meridian);
		assert(travelToMeridian != TLLongitudeSame);
		
		// find coordinate at meridian
		double surrogateMeridian = meridian;
		TLCoordinate otherCoordinate = TLCoordPolygonGetCoordinate(polygon, secondaryVertexIdx);
		if (travelToMeridian == TLLongitudeEastToWest) {
			flags |= TLSplitArrowFlagEastSide;
			surrogateMeridian = TLMeridianSurrogateOnEast(meridian);
		}
		else {
			surrogateMeridian = TLMeridianSurrogateOnWest(meridian);
		}
		TLCoordinate meridianCoordinate = TLCoordinateSurrogateAtMeridian(surrogateMeridian, mainCoordinate, otherCoordinate);
		latitudeNearMeridian = meridianCoordinate.lat;
		assert(latitudeNearMeridian < 90.0 && latitudeNearMeridian > -90.0);
		longitudeNearMeridian = meridianCoordinate.lon;
	}
	return self;
}

+ (id)arrowToVertex:(NSUInteger)vertexIdx ofPolygon:(TLCoordPolygonRef)polygon fromMeridian:(double)meridian {
	NSUInteger secondaryVertexIdx = vertexIdx ? vertexIdx - 1 : TLCoordPolygonGetCount(polygon) - 1;
	TLSplitArrow* newArrow = [[TLSplitArrow alloc] initWithVertex:vertexIdx
														andVertex:secondaryVertexIdx
														ofPolygon:polygon
													 withMeridian:meridian
													 asInpointing:NO];
	return [newArrow autorelease];
}

+ (id)arrowFromVertex:(NSUInteger)vertexIdx ofPolygon:(TLCoordPolygonRef)polygon toMeridian:(double)meridian {
	NSUInteger secondaryVertexIdx = vertexIdx + 1;
	if (secondaryVertexIdx == TLCoordPolygonGetCount(polygon)) secondaryVertexIdx = 0;
	TLSplitArrow* newArrow = [[TLSplitArrow alloc] initWithVertex:vertexIdx
														andVertex:secondaryVertexIdx
														ofPolygon:polygon
													 withMeridian:meridian
													 asInpointing:YES];
	return [newArrow autorelease];
}

@end





@interface TLSplitRemove : NSObject {
	
}
+ (TLSplitRemove*)remove;
@end

@implementation TLSplitRemove

+ (TLSplitRemove*)remove {
	static TLSplitRemove* singletonRemove = nil;
	if (!singletonRemove) {
		singletonRemove = [TLSplitRemove new];
	}
	return singletonRemove;
}

@end

static inline bool TLMeridianSameDistinctSide(TLLongitudeOrdering previousCompare, TLLongitudeOrdering currentCompare) {
	return (previousCompare != TLLongitudeSame && previousCompare == currentCompare);
}

static inline bool TLMeridianBothWithin(TLLongitudeOrdering previousCompare, TLLongitudeOrdering currentCompare) {
	return (previousCompare == TLLongitudeSame && previousCompare == currentCompare);
}

static NSUInteger TLIndexOfNextStartArrow(NSArray* arrowArray, NSUInteger hintIdx) {
	NSUInteger arrowsCount = [arrowArray count];
	for (NSUInteger arrowIdx = hintIdx; arrowIdx < arrowsCount; ++arrowIdx) {
		TLSplitArrow* currentArrow = [arrowArray objectAtIndex:arrowIdx];
		if ([currentArrow isInpointing] && ![currentArrow isMarkedUsed]) return arrowIdx;
	}
	return NSNotFound;
}

static TLSplitArrow* TLSplitArrowPairedToArrow(NSArray* arrowArray, TLSplitArrow* inpointingArrow) {
	// NOTE: this only handles inpointing arrows, and those naïvely.
	NSUInteger inpointingIdx = [arrowArray indexOfObject:inpointingArrow];
	if (inpointingIdx == NSNotFound) return nil;
	NSUInteger pairedArrowIndex = inpointingIdx + 1;
	if (pairedArrowIndex == [arrowArray count]) pairedArrowIndex = 0;
	return [arrowArray objectAtIndex:pairedArrowIndex];
}

static inline double TLLongitudeProperlyRanged(double longitude) {
	if (longitude > 180.0) longitude -= 360.0;
	if (longitude < -180.0) longitude += 360.0;
	return longitude;
}

static CFArrayRef TLArrayCreateBySplittingCoordPolygonAcrossMeridian(TLCoordPolygonRef inputPolygon, double meridian) {
	tl_uint_t vertexCount = TLCoordPolygonGetCount(inputPolygon);
	if (!vertexCount) return NULL;
	
	/*
	 The notableVertices array keeps track of which vertices have associated events:
	 - If a vertex pair crosses the meridian, the first vertex gets an in-pointing arrow. An out-pointing arrow
	 is generated for the second vertex, but it is only stored elsewhere and is not referenced from this array.
	 - If a vertex pair enters the meridian, the first gets an in-pointing arrow.
	 - If a vertex pair is within the meridian, the first gets flagged for deletion. 
	 - If a vertex pair exits the meridian, an unreferenced out-pointing arrow is generated for the second vertex.
	 */
	const id removedCoordinate = [TLSplitRemove remove];
	const id normalCoordinate = [NSNull null];
	const id internalCoordinate = [NSNull null];	// these will get removed or ignored automatically
	const id exitingCoordinate = normalCoordinate;
	const id unknownNotability = nil;
	
	NSMutableArray* notableVertices = [NSMutableArray arrayWithCapacity:vertexCount];
	NSMutableArray* allArrows = [NSMutableArray array];
	
	TLCoordinate previousCoordinate = TLCoordPolygonGetCoordinate(inputPolygon, 0);
	TLLongitudeOrdering previousCompare = TLLongitudeCompare(meridian, previousCoordinate.lon);
	id previousNotability = (previousCompare == TLLongitudeSame) ? internalCoordinate : normalCoordinate;
	for (tl_uint_t vertexIdx = 1; vertexIdx < vertexCount; ++vertexIdx) {
		TLCoordinate currentCoordinate = TLCoordPolygonGetCoordinate(inputPolygon, vertexIdx);
		TLLongitudeOrdering currentCompare = TLLongitudeCompare(meridian, currentCoordinate.lon);
		id currentNotability = unknownNotability;
		
		if (TLMeridianSameDistinctSide(previousCompare, currentCompare)) {
			currentNotability = normalCoordinate;
		}
		else if (TLMeridianBothWithin(previousCompare, currentCompare)) {
			// the previousCoordinate is a disregardable vertex
			previousNotability = removedCoordinate;
			currentNotability = internalCoordinate;
		}
		else if (previousCompare == TLLongitudeSame) {	// exiting, since both aren't within
			// create an out-pointing arrow for the currentCoordinate
			TLSplitArrow* outArrow = [TLSplitArrow arrowToVertex:vertexIdx ofPolygon:inputPolygon fromMeridian:meridian];
			[allArrows addObject:outArrow];
			currentNotability = exitingCoordinate;
		}
		else if (currentCompare == TLLongitudeSame) {	// entering, since both aren't within
			// create an in-pointing arrow for the previousCoordinate
			TLSplitArrow* inArrow = [TLSplitArrow arrowFromVertex:(vertexIdx-1) ofPolygon:inputPolygon toMeridian:meridian];
			[allArrows addObject:inArrow];
			previousNotability = inArrow;
			currentNotability = internalCoordinate;
		}
		else {	// might be a crossing, unless points are straddling the other side of the globe
			double distanceToMeridian = TLLongitudeSignedDistance(meridian, currentCoordinate.lon);
			double distanceApart = TLLongitudeSignedDistance(previousCoordinate.lon, currentCoordinate.lon);
			if ( fabs(distanceApart) < fabs(distanceToMeridian) ) {
				/*
				 If either point is closer to the other than it is to the meridian, they must not cross despite being on
				 opposite sides of the meridian. They are straddling the meridian's antimeridian, which needn't bother us.
				 */
				currentNotability = normalCoordinate;
			}
			else {	// the points do cross the meridian
				// create an in-pointing arrow for the previousCoordinate
				TLSplitArrow* inArrow = [TLSplitArrow arrowFromVertex:(vertexIdx-1) ofPolygon:inputPolygon toMeridian:meridian];
				[allArrows addObject:inArrow];
				previousNotability = inArrow;
				// and an out-pointing arrow for the currentCoordinate
				TLSplitArrow* outArrow = [TLSplitArrow arrowToVertex:vertexIdx ofPolygon:inputPolygon fromMeridian:meridian];
				[allArrows addObject:outArrow];
				currentNotability = exitingCoordinate;
			}
		}
		
		[notableVertices addObject:previousNotability];		// we didn't know previousNotability until now
		assert(currentNotability != unknownNotability);
		previousNotability = currentNotability;
		previousCoordinate = currentCoordinate;
		previousCompare = currentCompare;
	}
	[notableVertices addObject:previousNotability];
	
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef outputPolygonArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	
	// If no arrows were generated, we can return the input polygon verbatim as it did not touch the meridian
	if (![allArrows count]) {
		CFArrayAppendValue(outputPolygonArray, inputPolygon);
		return outputPolygonArray;
	}
	
	/*
	 Sort the allArrows array so that the east-side arrows are ordered from 90deg to -90deg followed by the west-side arrows ordered
	 from -90deg to 90deg. Make sure any arrow pairs that have the same latitude (and belong to the same polygon) are ordered so that
	 the out-pointing arrow follows the in-pointing one.
	 
	 This sort does not need to be stable, otherwise we would use the POSIX/C mergesort() as the NSArray methods, according to the
	 discussion at http://www.cocoabuilder.com/archive/message/cocoa/2002/12/8/52304 are not guaranteed to be stable sorts.
	 */
	[allArrows sortUsingSelector:@selector(compare:)];
	
	/*
	 Now the output polygons may be assembled by repeatedly finding the first unused in-pointing arrow. This arrow should be marked
	 as used, and then connected to the next arrow (which will be an out-pointing one) by an appropriate set of vertices. If the
	 out-pointing arrow is on the opposite side of its in-pointing partner, the vertices must wrap around the outside of the corresponding
	 pole. The out-pointing arrow is then followed around the original polygon (removing vertices so marked) until the next in-pointing
	 arrow is found. If this arrow is marked as used, it is the one we started with and the current polygon should be finished. Otherwise,
	 mark it as used and continue on as before (connecting to next out-pointing, and so on).
	 
	 Note that this algorithm could be trivially extended to support polygon sets and polygons with holes, just by keeping track of
	 notableVertices for an array of related polygons and storing the correct polygon with each out-pointing arrow. The results would
	 be fairly ideal, in the sense that holes around the poles would be elimated as the containing polygon is "unraveled".
	 */
	NSUInteger startArrowIdx = TLIndexOfNextStartArrow(allArrows, 0);
	while (startArrowIdx != NSNotFound) {		// this loop generates each output polygon
		TLMutableCoordPolygonRef currentOutputPolygon = TLCoordPolygonCreateMutable(0);
		TLSplitArrow* startArrow = [allArrows objectAtIndex:startArrowIdx];
		TLSplitArrow* inArrow = startArrow;
		while (inArrow) {						// this loop walks from inArrow back to an in-pointing arrow
			[inArrow setMarkedUsed];
			// Generate points along the meridian
			double coordinateDensity = 1.0;
			TLCoordinate inCoord = [inArrow meridianCoordinate];
			TLSplitArrow* outArrow = TLSplitArrowPairedToArrow(allArrows, inArrow);
			TLCoordinate outCoord = [outArrow meridianCoordinate];
			if ([inArrow isEastSide] && ![outArrow isEastSide]) {	// wraps from east to west
				// walk to South Pole
				double southPoleLatitude = -90.0 + TL_MERIDIAN_PADDING;
				double currentLatitude = inCoord.lat;
				while (currentLatitude > southPoleLatitude) {
					TLCoordinate currentPoint = TLCoordinateMake(currentLatitude, inCoord.lon);
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentPoint);
					currentLatitude -= coordinateDensity;
				}
				// walk across the long way
				double currentLongitude = inCoord.lon;
				double targetLongitude = (outCoord.lon > inCoord.lon) ? outCoord.lon : outCoord.lon + 360.0;
				while (currentLongitude < targetLongitude) {
					TLCoordinate currentPoint = TLCoordinateMake(southPoleLatitude,
																 TLLongitudeProperlyRanged(currentLongitude));
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentPoint);
					currentLongitude += coordinateDensity;
				}
				// walk to outArrow
				currentLatitude = southPoleLatitude;
				double targetLatitude = outCoord.lat;
				while (currentLatitude < targetLatitude) {
					TLCoordinate currentCoordinate = TLCoordinateMake(currentLatitude, outCoord.lon);
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentCoordinate);
					currentLatitude += coordinateDensity;
				}
			}
			else if (![inArrow isEastSide] && [outArrow isEastSide]) {	// wraps from west to east
				// walk to North Pole
				double northPoleLatitude = 90.0 - TL_MERIDIAN_PADDING;
				double currentLatitude = inCoord.lat;
				while (currentLatitude < northPoleLatitude) {
					TLCoordinate currentPoint = TLCoordinateMake(currentLatitude, inCoord.lon);
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentPoint);
					currentLatitude += coordinateDensity;
				}
				// walk across the long way
				double currentLongitude = inCoord.lon;
				double targetLongitude = (outCoord.lon < inCoord.lon) ? outCoord.lon : outCoord.lon - 360.0;
				while (currentLongitude > targetLongitude) {
					TLCoordinate currentPoint = TLCoordinateMake(northPoleLatitude,
																 TLLongitudeProperlyRanged(currentLongitude));
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentPoint);
					currentLongitude -= coordinateDensity;
				}
				// walk to outArrow
				currentLatitude = northPoleLatitude;
				double targetLatitude = outCoord.lat;
				while (currentLatitude > targetLatitude) {
					TLCoordinate currentCoordinate = TLCoordinateMake(currentLatitude, outCoord.lon);
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentCoordinate);
					currentLatitude -= coordinateDensity;
				}
			}
			else {	// densify between same-sided coordinates
				double signedDistance = (outCoord.lat - inCoord.lat);
				double approximateSteps = signedDistance / coordinateDensity;
				tl_uint_t numberOfSteps = (tl_uint_t)fabs(approximateSteps);
				if (numberOfSteps > 1) {
					double signedStepAmount = signedDistance / numberOfSteps;
					for (tl_uint_t currentStep = 0; currentStep < numberOfSteps; ++currentStep) {
						double currentLatitude = inCoord.lat + signedStepAmount * currentStep;
						TLCoordinate currentCoordinate = TLCoordinateMake(currentLatitude, inCoord.lon);
						TLCoordPolygonAppendCoordinate(currentOutputPolygon, currentCoordinate);
					}
				}
				else {
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, inCoord);
				}
				TLCoordPolygonAppendCoordinate(currentOutputPolygon, outCoord);
			}
			
			// Do some basic sanity checks before continuing.
			assert([inArrow isInpointing]);
			assert(![outArrow isInpointing]);
			
			// Generate points around inputPolygon
			NSUInteger sourceIdx = [outArrow indexOfNextPolygonVertex];
			NSUInteger lastSourceIdx = vertexCount - 1;
			
			BOOL loopedThroughSourceOnceAlready = NO;
			while (sourceIdx < lastSourceIdx) {	// this loop walks the source polygon looking for an arrow
				id sourceVertexType = [notableVertices objectAtIndex:sourceIdx];
				if (sourceVertexType != removedCoordinate) {
					TLCoordPolygonAppendCoordinate(currentOutputPolygon, TLCoordPolygonGetCoordinate(inputPolygon, sourceIdx));
				}
				// stop looping through source vertices upon reaching an in-arrow
				if ([sourceVertexType isKindOfClass:[TLSplitArrow class]]) break;
				
				++sourceIdx;
				if (sourceIdx == lastSourceIdx && !loopedThroughSourceOnceAlready) {
					sourceIdx = 0;	// wrap one vertex early, since the last vertex is equal to the first
					loopedThroughSourceOnceAlready = YES;
				}
			}
			
			id arrivedVertexArrow = [notableVertices objectAtIndex:sourceIdx];
			/*
			 The source polygon loop should "working-theory"etically only ever break on an in-pointing arrow.
			 We check here that it didn't break on account of an other-wise infinite loop, or on account of an out-pointing arrow.
			 */
			assert([arrivedVertexArrow isKindOfClass:[TLSplitArrow class]] && [arrivedVertexArrow isInpointing]);
			
			// we could have looped to the end of the currentOutputPolygon, or a new in-pointing arrow
			if ([arrivedVertexArrow isMarkedUsed]) {
				// If the arrow is used, it should "working-theory"etically always be the one we at which we started.
				assert(arrivedVertexArrow==startArrow);
				// So long as things are sane, add the final point and let the enclosing loop finish the polygon.
				TLCoordPolygonAppendCoordinate(currentOutputPolygon, [arrivedVertexArrow meridianCoordinate]);
				inArrow = nil;
			}
			else inArrow = arrivedVertexArrow;
		}
		CFArrayAppendValue(outputPolygonArray, currentOutputPolygon);
		TLCoordPolygonRelease(currentOutputPolygon);
		startArrowIdx = TLIndexOfNextStartArrow(allArrows, startArrowIdx);
	}
	
	return outputPolygonArray;
}

static CFArrayRef TLArrayCreateFromProjectablePartsOfPolygon(TLCoordPolygonRef inputPolygon, CTProjection* projection) {
	// TODO: clip inputPolygon to projection domain, this just fails completely on account of any point
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef projectedPolygons = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	tl_uint_t inputCount = TLCoordPolygonGetCount(inputPolygon);
	TLMutablePolygonRef currentPolygon = TLPolygonCreateMutable(inputCount);
	for (tl_uint_t inputIdx = 0; inputIdx < inputCount; ++inputIdx) {
		TLCoordinate currentCoordinate = TLCoordPolygonGetCoordinate(inputPolygon, inputIdx);
		CGPoint projectedPoint = [projection projectCoordinate:currentCoordinate];
		if ([projection hadErrorResult]) goto end;
		else TLPolygonAppendPoint(currentPolygon, projectedPoint);
	}
	CFArrayAppendValue(projectedPolygons, currentPolygon);
end:
	TLPolygonRelease(currentPolygon);
	return projectedPolygons;
}

CFArrayRef TLArrayCreateByProjectingCoordPolygonForDrawing(TLCoordPolygonRef inputPolygon, CTProjection* projection) {
	CFArrayCallBacks polygonArrayCallbacks = TLPolygonArrayCallbacks();
	CFMutableArrayRef allProjectedPolygons = CFArrayCreateMutable(kCFAllocatorDefault, 0, &polygonArrayCallbacks);
	
	CFArrayRef splitPolygons = TLArrayCreateBySplittingCoordPolygonAcrossMeridian(inputPolygon, [projection antimeridian]);
	
	CFIndex polygonCount = CFArrayGetCount(splitPolygons);
	for (CFIndex polygonIdx = 0; polygonIdx < polygonCount; ++polygonIdx) {
		TLCoordPolygonRef polygon = (TLCoordPolygonRef)CFArrayGetValueAtIndex(splitPolygons, polygonIdx);
		CFArrayRef projectedPolygons = TLArrayCreateFromProjectablePartsOfPolygon(polygon, projection);
		CFIndex projectedCount = CFArrayGetCount(projectedPolygons);
		CFArrayAppendArray(allProjectedPolygons, projectedPolygons, CFRangeMake(0, projectedCount));
		CFRelease(projectedPolygons);
	}
	CFRelease(splitPolygons);
	return allProjectedPolygons;
}


#pragma mark Naïve projection functions

static TLPolygonRef TLPolygonCreateByProjectingNaively(TLCoordPolygonRef coordPoly,
													   TLProjectionRef proj)
{
	tl_uint_t vertexCount = TLCoordPolygonGetCount(coordPoly);
	TLMutablePolygonRef polygon = TLPolygonCreateMutable(vertexCount);
	if (!polygon) return NULL;
	TLProjectionError err = 0;
	for (tl_uint_t vertexIdx = 0; vertexIdx < vertexCount; ++vertexIdx) {
		TLCoordinate unprojectedCoord = TLCoordPolygonGetCoordinate(coordPoly, vertexIdx);
		CGPoint projectedPoint = TLProjectionProjectCoordinate(proj, unprojectedCoord, &err);
		if (err) {
			TLPolygonRelease(polygon);
			return NULL;
		}
		TLPolygonAppendPoint(polygon, projectedPoint);
	}
	return polygon;
}

TLMultiPolygonRef TLMultiPolygonCreateByProjectingNaively(TLMultiCoordPolygonRef multiCoordPoly,
														  TLProjectionRef proj)
{
	tl_uint_t polygonCount = TLMultiCoordPolygonGetCount(multiCoordPoly);
	TLMutableMultiPolygonRef multiPoly = TLMultiPolygonCreateMutable(polygonCount);
	if (!multiPoly) return NULL;
	for (tl_uint_t polygonIdx = 0; polygonIdx < polygonCount; ++polygonIdx) {
		TLCoordPolygonRef coordPoly = TLMultiCoordPolygonGetPolygon(multiCoordPoly, polygonIdx);
		TLPolygonRef polygon = TLPolygonCreateByProjectingNaively(coordPoly, proj);
		if (!polygon) {
			TLMultiPolygonRelease(multiPoly);
			return NULL;
		}
		TLMultiPolygonAppendPolygon(multiPoly, polygon);
		TLPolygonRelease(polygon);
	}
	return multiPoly;
}

static TLCoordPolygonRef TLCoordPolygonCreateByUnprojectingNaively(TLPolygonRef poly, TLProjectionRef proj) {
	tl_uint_t vertexCount = TLPolygonGetCount(poly);
	TLMutableCoordPolygonRef coordPoly = TLCoordPolygonCreateMutable(vertexCount);
	if (!coordPoly) return NULL;
	TLProjectionError err = 0;
	for (tl_uint_t vertexIdx = 0; vertexIdx < vertexCount; ++vertexIdx) {
		CGPoint projectedPoint = TLPolygonGetPoint(poly, vertexIdx);
		TLCoordinate unprojectedCoord = TLProjectionUnprojectPoint(proj, projectedPoint, &err);
		if (err) {
			TLCoordPolygonRelease(coordPoly);
			return NULL;
		}
		TLCoordPolygonAppendCoordinate(coordPoly, unprojectedCoord);
	}
	return coordPoly;
}

TLMultiCoordPolygonRef TLMultiCoordPolygonCreateByUnprojectingNaively(TLMultiPolygonRef multiPoly,
																	  TLProjectionRef proj)
{
	tl_uint_t polygonCount = TLMultiPolygonGetCount(multiPoly);
	TLMutableMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateMutable(polygonCount);
	if (!multiCoordPoly) return NULL;
	for (tl_uint_t polygonIdx = 0; polygonIdx < polygonCount; ++polygonIdx) {
		TLPolygonRef poly = TLMultiPolygonGetPolygon(multiPoly, polygonIdx);
		TLCoordPolygonRef coordPoly = TLCoordPolygonCreateByUnprojectingNaively(poly, proj);
		if (!coordPoly) {
			TLMultiCoordPolygonRelease(multiCoordPoly);
			return NULL;
		}
		TLMultiCoordPolygonAppendPolygon(multiCoordPoly, coordPoly);
		TLCoordPolygonRelease(coordPoly);
	}
	return multiCoordPoly;
}


TLMultiPolygonRef TLProjectedPolylineCreate(TLMultiCoordPolygonRef multiCoordLine, TLProjectionRef proj, CGFloat sigDist) {
	// TODO: This should simplify multiCoordLine, clip to projection range, then project naïvely. Without using CTProjection.
	
	CTProjection* wrappedProj = [[[CTProjection alloc] initWithWrappedProjection:proj] autorelease];
	TLMutableMultiPolygonRef projectedPolyline = TLMultiPolygonCreateMutable(0);
	if (!projectedPolyline) return NULL;
	tl_uint_t segmentsCount = TLMultiCoordPolygonGetCount(multiCoordLine);
	for (tl_uint_t segmentIdx = 0; segmentIdx < segmentsCount; ++segmentIdx) {
		TLCoordPolygonRef coordSegment = TLMultiCoordPolygonGetPolygon(multiCoordLine, segmentIdx);
		CFArrayRef projectedSegments = TLArrayCreateByProjectingCoordLineForDrawing(coordSegment, wrappedProj);
		if (!projectedSegments) {
			TLMultiPolygonRelease(projectedPolyline);
			return NULL;
		}
		CFIndex projectedSegmentsCount = CFArrayGetCount(projectedSegments);
		for (CFIndex projectedSegmentIdx = 0; projectedSegmentIdx < projectedSegmentsCount; ++projectedSegmentIdx) {
			TLPolygonRef segment = (TLPolygonRef)CFArrayGetValueAtIndex(projectedSegments, projectedSegmentIdx);
			// simplify
			TLPolygonRef simplifiedSegment = TLPolygonCreateByReducingVertices(segment, sigDist);
			TLMultiPolygonAppendPolygon(projectedPolyline, simplifiedSegment);
			TLPolygonRelease(simplifiedSegment);
		}
		CFRelease(projectedSegments);		
	}
	return projectedPolyline;
}
