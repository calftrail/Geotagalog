/*
 *  TLGeoidGeometry.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLGeoidGeometry.h"

#include "TLFloat.h"

static TLProjectionGeoidMeters TLProjectionGeoidRadiusOfCurvatureForLatitude(TLProjectionGeoidRef geoid,
																			 TLCoordinateDegrees lat);
// assumes ellipsoidal model
static TLProjectionGeoidMeters TLProjectionGeoidRadiusOfCurvatureForPhi(TLProjectionGeoidRef geoid,
																		double phi);

#pragma mark LLA->ECEF

TLPlanetPoint TLGeoidGetPlanetPoint(TLProjectionGeoidRef planetModel, TLCoordinate coord, TLCoordinateAltitude alt) {
	bool spherical = TLProjectionGeoidIsSpherical(planetModel);
	double phi = coord.lat * TLCoordinateDegreesToRadians;
	double lam = coord.lon * TLCoordinateDegreesToRadians;
	
	// based on http://www.u-blox.com/customersupport/docs/GPS.G1-X-00006.pdf
	TLProjectionGeoidMeters radius = TLProjectionGeoidRadiusOfCurvatureForLatitude(planetModel, coord.lat);
	TLProjectionGeoidMeters adjustedRadius = radius;
	if (!spherical) {
		// simplification via http://mathforum.org/library/drmath/view/51832.html
		double oneMinusF = 1.0 - TLProjectionGeoidGetFlattening(planetModel);
		adjustedRadius = radius * oneMinusF * oneMinusF;
	}
	double cosPhi = cos(phi);
	TLMetersECEF x = (radius + alt) * cosPhi * cos(lam);
	TLMetersECEF y = (radius + alt) * cosPhi * sin(lam);
	TLMetersECEF z = (adjustedRadius + alt) * sin(phi);
	return TLPlanetPointMake(x, y, z);
}


#pragma mark ECEF->LLA

#define TL_ECEF_ITERATE

TLCoordinate TLGeoidGetCoordinate(TLProjectionGeoidRef geoid, TLPlanetPoint planetPoint, TLCoordinateAltitude* alt) {
	bool spherical = TLProjectionGeoidIsSpherical(geoid);
	
	double lam = atan2(planetPoint.y, planetPoint.x);
	double rho = hypot(planetPoint.x, planetPoint.y);
	
	double h, phi;
	if (TLFloatEqual(rho, 0.0)) {
		// point along polar axis of earth
		phi = planetPoint.z < 0.0 ? -M_PI_2 : M_PI_2;
		//double debug = TLProjectionGeoidGetPolarRadius(geoid) - TLProjectionGeoidRadiusOfCurvatureForPhi(geoid, phi);
		// TODO: is it correct to use polar radius? why is it 43km less than radius of curvature at poles?
		h = fabs(planetPoint.z) - TLProjectionGeoidGetPolarRadius(geoid);
	}
	else if (spherical) {
		phi = atan2(planetPoint.z, rho);
		h = rho / cos(phi) - TLProjectionGeoidGetEquatorialRadius(geoid);
	}
	else {
		// based on http://www.u-blox.com/customersupport/docs/GPS.G1-X-00006.pdf
		double eSqd = TLProjectionGeoidGetEccentricitySquared(geoid);
		phi = atan2(planetPoint.z, rho * (1.0 - eSqd));
		TLProjectionGeoidMeters radiusOfCurvature = TLProjectionGeoidRadiusOfCurvatureForPhi(geoid, phi);
#ifdef TL_ECEF_ITERATE
		tl_uint_t maxIterationsLeft = 5;
		TLProjectionGeoidMeters radiusTolerance = 0.000001;
		do {
#endif /* TL_ECEF_ITERATE */
			h = rho / cos(phi) - radiusOfCurvature;
			double adjustment = radiusOfCurvature / (radiusOfCurvature + h);
			phi = atan2(planetPoint.z, rho * (1.0 - eSqd * adjustment));
#ifdef TL_ECEF_ITERATE
			TLProjectionGeoidMeters newRadius = TLProjectionGeoidRadiusOfCurvatureForPhi(geoid, phi);
			TLProjectionGeoidMeters radiusChange = newRadius - radiusOfCurvature;
			//printf("Change was %f on with %lu iterations remaining\n", radiusChange, (long unsigned)maxIterationsLeft);
			if (TLFloatEqualTol(radiusChange, 0.0, radiusTolerance)) break;
			else radiusOfCurvature = newRadius;
			--maxIterationsLeft;
		} while (maxIterationsLeft);
#endif /* TL_ECEF_ITERATE */
	}
	
	if (alt) *alt = h;
	return TLCoordinateMake(phi * TLCoordinateRadiansToDegrees, lam * TLCoordinateRadiansToDegrees);
}


#pragma mark Extra geoid info

TLProjectionGeoidMeters TLProjectionGeoidRadiusOfCurvatureForPhi(TLProjectionGeoidRef geoid, double phi) {
	double sinPhi = sin(phi);
	double eSqd = TLProjectionGeoidGetEccentricitySquared(geoid);
	TLProjectionGeoidMeters a = TLProjectionGeoidGetEquatorialRadius(geoid);
	return a / sqrt(1.0 - eSqd * sinPhi * sinPhi);
}

TLProjectionGeoidMeters TLProjectionGeoidRadiusOfCurvatureForLatitude(TLProjectionGeoidRef geoid, TLCoordinateDegrees lat) {
	TLProjectionGeoidMeters a = TLProjectionGeoidGetEquatorialRadius(geoid);
	if (TLProjectionGeoidIsSpherical(geoid)) return a;
	double eSqd = TLProjectionGeoidGetEccentricitySquared(geoid);
	double phi = lat * TLCoordinateDegreesToRadians;
	double sinPhi = sin(phi);
	return a / sqrt(1.0 - eSqd * sinPhi * sinPhi);
}


#pragma mark Basic ECEF point geometry

typedef TLPlanetPoint TLPlanetSize;

static TLPlanetSize TLPlanetPointDifference(TLPlanetPoint p1, TLPlanetPoint p2) {
	TLMetersECEF dX = p2.x - p1.x;
	TLMetersECEF dY = p2.y - p1.y;
	TLMetersECEF dZ = p2.z - p1.z;
	return TLPlanetPointMake(dX, dY, dZ);
}

static double TLPlanetSizeDotProduct(TLPlanetSize p1, TLPlanetSize p2) {
	return ((p1.x * p2.x) + (p1.y * p2.y) + (p1.z * p2.z));
}

double TLPlanetPointDistanceSquared(TLPlanetPoint planetPoint1, TLPlanetPoint planetPoint2) {
	TLPlanetSize d = TLPlanetPointDifference(planetPoint1, planetPoint2);
	return TLPlanetSizeDotProduct(d,d);
}

TLMetersECEF TLPlanetPointDistance(TLPlanetPoint planetPoint1, TLPlanetPoint planetPoint2) {
	double distSqd = TLPlanetPointDistanceSquared(planetPoint1, planetPoint2);
	return (TLMetersECEF)sqrt(distSqd);
}

TLPlanetPoint TLPlanetPointWithTravel(TLPlanetPoint planetPointA, TLPlanetPoint planetPointB, double travel) {
	TLPlanetSize d = TLPlanetPointDifference(planetPointA, planetPointB);
	return TLPlanetPointMake(planetPointA.x + travel * d.x,
							 planetPointA.y + travel * d.y,
							 planetPointA.z + travel * d.z);
}

double TLPlanetClosestTravel(TLPlanetPoint target, TLPlanetPoint lineEndpointA, TLPlanetPoint lineEndpointB) {
	/* From lineEndpointA, we take two vectors: one to target and one to lineEndpointB.
	 We find the magnitude of the targetVector when projected onto the lineVector divided by
	 the magnitude of the lineVector.
	 See http://www.softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm for derivation/diagram. */
	TLPlanetSize targetVector = TLPlanetPointDifference(lineEndpointA, target);
	TLPlanetSize lineVector = TLPlanetPointDifference(lineEndpointA, lineEndpointB);
	return TLPlanetSizeDotProduct(targetVector, lineVector) / TLPlanetSizeDotProduct(lineVector, lineVector);
}

