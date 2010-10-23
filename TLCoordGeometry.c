//
//  TLCoordGeometry.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 4/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLCoordGeometry.h"

/*
 See "Computing the Area of a Spherical Polygon" (Graphics Gems IV pp. 132ff) as well as the correction to this
 (and alternate method) in "Point in Polyhedron Testing Using Spherical Polygons" (Graphics Gems V pp. 45-46).
 
 http://mathworld.wolfram.com/SphericalPolygon.html gives the simple formula.
 
 http://www.mathworks.com/access/helpdesk/help/toolbox/map/areaint.html talks about Green's Theorem
 and notes that ellipsoidal areas are calculated by pre-converting coordinates using authalic latitudes.
 
 http://mathworld.wolfram.com/SphericalTrigonometry.html many spherical triangle equations.
 */

/*  Haversine function: hav(x)= (1-cos(x))/2.  */
static inline double TLHaversine(double x) {
    return (1.0-cos(x))/2.0;
}

TLCoordinateDegrees TLCoordPolygonGetArea(TLCoordPolygonRef coordPoly) {
	tl_uint_t vertexCount = TLCoordPolygonGetCount(coordPoly);
	if (!vertexCount) return 0.0;
	
	static const double polePhi = M_PI_2;
	static const double fullCircle = 2.0*M_PI;
	static const double hemisphere = M_PI;
	static const double areaOfCompleteSphere = 4.0*M_PI;
	
	double areaRadians = 0.0;
	
	// set up fake "previous coordinate" for first time through loop
	TLCoordinate vertex2 = TLCoordPolygonGetCoordinate(coordPoly, 0);
	double lam2 = vertex2.lon * TLCoordinateDegreesToRadians;
	double phi2 = vertex2.lat * TLCoordinateDegreesToRadians;
	double cosineOfPhi2 = cos(phi2);
	
	// note: this loop assumes the 0th vertex is repeated as the (vertexCount-1)th vertex
	for (tl_uint_t vertexIdx = 1; vertexIdx < vertexCount; ++vertexIdx) {
		// Use previous second values for the first vertex...
		double lam1 = lam2;
		double phi1 = phi2;
		double cosineOfPhi1 = cosineOfPhi2;
		// ...and calculate the new second values.
		vertex2 = TLCoordPolygonGetCoordinate(coordPoly, vertexIdx);
		lam2 = vertex2.lon * TLCoordinateDegreesToRadians;
		phi2 = vertex2.lat * TLCoordinateDegreesToRadians;
		cosineOfPhi2 = cos(phi2);
		
		if (lam1 != lam2) {
			/* Calculate the angles and resulting spherical excess made by the triangle vertex1->NorthPole->vertex.
			 This uses the Haversine Formula to find angleA, and basic trig for angles B and C.
			 See "Computing the Area of a Spherical Polygon" by Robert D. Miller (Graphics Gems IV, page 133)
			 for a diagram and derivation of the angles represented by the following variables below.
			 [Note: sideA is the side opposite the polar vertex, sideB is opposite(n.b.) vertex1 and sideC opposite vertex2.]
			 
			 Besides the Graphics Gems V fix, one other change was made to the Miller algorithm: Since the Haversine
			 Formula is ill-conditioned for nearly anti-podal points, the sqrHavA step was added to mitigate this.
			 This technique was found/explained at http://www.movable-type.co.uk/scripts/gis-faq-5.1.html
			 */
			double havA = TLHaversine(phi2-phi1) + cosineOfPhi1*cosineOfPhi2*TLHaversine(lam2-lam1);
			double sqrHavA = fmin(1.0, sqrt(havA));	// deal with ill-conditioned Haversine Formula ranges
			double sideA = 2.0 * asin(sqrHavA);
			double sideB = polePhi - phi2;
			double sideC = polePhi - phi1;
			double calcS = 0.5 * (sideA + sideB + sideC);
			double calcT = tan(calcS/2.0) * tan((calcS-sideA)/2.0) * tan((calcS-sideB)/2.0) * tan((calcS-sideC)/2.0);
			double excessRadians = fabs(4*atan(sqrt(fabs(calcT))));
			
			//if (lam2 < lam1) excessRadians = -excessRadians;			// original code, ingores antimeridian
			// The logic below follows the convention that, between two points, the shorter great circle path is assumed.
			double lamDifference = lam2 - lam1;
			if (lamDifference <= 0.0) lamDifference += fullCircle;			// lam2 is always considered east of lam1...
			if (lamDifference > hemisphere) excessRadians = -excessRadians;	// ...unless it's more than a hemisphere east.
			
			//printf("Going from (%f, %f) to (%f, %f), the excess is %f.\n", phi1, lam1, phi2, lam2, excessRadians);
			areaRadians += excessRadians;
		}
	}
	
	/*
	 Note that every polygon on a sphere encloses *two* areas which together equal the area of the whole sphere. The above algorithm
	 finds the area enclosed to the left of an observer walking along the polygon's vertices. However, if the polygon encloses the
	 pole opposite the "base" pole from which each triangle is formed -- in this case, when the polygon encloses the South Pole --
	 the polygon looks like it is enclosing the base pole in the opposite direction instead. Because of this, the "wrong" area is found,
	 but it is "correctly" negative. Naturally no area is negative but even (/especially) on a plane, such areas are a handy convention.
	 
	 The surface area of an ideal plane is infinite, yet it is possible to think of a plane polygon as also enclosing two regions which
	 together form the entire plane. One region's area will be finite, and the other will be the (infinite) difference of the surface's
	 area and the finite area. The finite area is essentially the result of subtracting the "unenclosed" area from the area of the surface,
	 and this is the "area" that is used as the signed area for polygons in a plane. Thus polygons with "negative areas" are indeed holes.
	 
	 Take a plane and join all the points which are an infinite distance from its center, and the result is the surface of a sphere. Every
	 spherical polygon has two imaginable enclosed areas. To always find the area enclosed to the left, the algorithm above would need to
	 pick a reference pole such that the antipodal point was not inside the polygon. However, since the algorithm does find a correct
	 "negative area" when the antipodal point is included, and since on a sphere we do know the total surface area, it's a lot harder
	 to deal with finding a suitable base point than it is just to say:	*/
	if (areaRadians < 0.0) areaRadians += areaOfCompleteSphere;
	
	
	/* And because we actually want the area on the *right* hand, we do this: */
	// TODO: adjust algorithm above to make this unnecessary
	areaRadians = areaOfCompleteSphere - areaRadians;
	
	/*
	 Thus, all areas returned by this function are positive, as all earthly areas should be. Holes enclose more area than the polygons
	 that enclose them! (The intersection of the two is still the expected region, of course.)
	 
	 Another interesting topic would be to explain why, when conversion factors must usually be squared when used with areas, the following
	 line is correct. Is it related to the fact that the area of a spherical triangle is determined by addition, not multiplication?
	 */
	return areaRadians * TLCoordinateRadiansToDegrees;
}

/*
 TLExtent TLExtentBoundingCoordPolygon(TLCoordPolygonRef polygon) {
 
 }
 */

TLCoordPolygonRef TLCoordPolygonCreateFromExtent(TLExtent extent) {
	/* A naïve geodesic connecting NW->NE or SE->SW may go around globe in the wrong direction,
	 but adding points at the east/west midpoints should always cause the intended winding. */
	TLMutableCoordPolygonRef extentPoly = TLCoordPolygonCreateMutable(7);
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetNorthwestCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetNorthCentralCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetNortheastCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetSoutheastCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetSouthCentralCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetSouthwestCoordinate(extent));
	TLCoordPolygonAppendCoordinate(extentPoly, TLExtentGetNorthwestCoordinate(extent));
	return extentPoly;
}


// Assumes latitude in (-270º, 270º), ie within 180º of proper range
// Assumes longitude in (-360º, 360º), ie within 180º of proper range
TLCoordinate TLCoordinateAdjustToRange(TLCoordinate inCoord) {
	TLCoordinate outCoord = inCoord;
	
	// fit latitude to range
	if (outCoord.lat > TLProjectionInfoMaxParallel) {
		// [overshoot from below] (0º, 180º) = x - 90º, so x = (90º, 270º)
		TLCoordinateDegrees overshoot = outCoord.lat - TLProjectionInfoMaxParallel;
		// (-90º, 90º) = 90º - overshoot, so -overshoot = (-180º, 0º), so overshoot = (0º, 180º)
		outCoord.lat = TLProjectionInfoMaxParallel - overshoot;
		
		// (-540º, 540º) = x + 180º, so x = (-720º, 360º)*
		outCoord.lon += TLProjectionInfoHemisphere;
	}
	else if (outCoord.lat < TLProjectionInfoMinParallel) {
		// [overshoot from below] (0º, 180º) = - 90º - x , so -x = (90º, 270º), so x = (-270º, -90º)
		TLCoordinateDegrees overshoot = TLProjectionInfoMinParallel - outCoord.lat;
		// (-90º, 90º) = -90º + overshoot, so overshoot = (0º, 180º)
		outCoord.lat = TLProjectionInfoMinParallel + overshoot;
		
		// (-540º, 540º) = x + 180º, so x = (-720º, 360º)*
		outCoord.lon += TLProjectionInfoHemisphere;
	}
	
	// fit longitude to range
	/* (*)note from possible adjustments above that inCoord.lon may actually be in the range
	 (-720º, 360º). Our stated contract tightens bottom range just to make symetrical. */
	outCoord.lon = TLCoordinateLongitudeAdjustToRange(outCoord.lon);
	
	return outCoord;
}

