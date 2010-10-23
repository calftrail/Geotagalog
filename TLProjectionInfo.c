/*
 *  TLProjectionInfo.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/4/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLProjectionInfo.h"

#include "TLProjectionGeometry.h"

#include "TLFloat.h";

#pragma mark Projection-specific function prototypes

typedef TLMultiCoordPolygonRef (*TLProjectionInfo_DomainCreateFunction)(TLProjectionRef proj, TLCoordinateDegrees significantDistance);
typedef TLMultiPolygonRef (*TLProjectionInfo_RangeCreateFunction)(TLProjectionRef proj, CGFloat significantDistance);

static TLMultiCoordPolygonRef TLProjectionInfoCreateMercatorDomain(TLProjectionRef, TLCoordinateDegrees);
static TLMultiPolygonRef TLProjectionInfoCreateMercatorRange(TLProjectionRef, CGFloat);

static TLMultiCoordPolygonRef TLProjectionInfoCreateStereographicDomain(TLProjectionRef, TLCoordinateDegrees);
static TLMultiPolygonRef TLProjectionInfoCreateStereographicRange(TLProjectionRef, CGFloat);

static TLMultiCoordPolygonRef TLProjectionInfoCreateLambertConformalConicDomain(TLProjectionRef, TLCoordinateDegrees);
static TLMultiPolygonRef TLProjectionInfoCreateLambertConformalConicRange(TLProjectionRef, CGFloat);

static TLMultiCoordPolygonRef TLProjectionInfoCreateOrthographicDomain(TLProjectionRef, TLCoordinateDegrees);
static TLMultiPolygonRef TLProjectionInfoCreateOrthographicRange(TLProjectionRef, CGFloat);

static TLMultiCoordPolygonRef TLProjectionInfoCreateRobinsonDomain(TLProjectionRef, TLCoordinateDegrees);
static TLMultiPolygonRef TLProjectionInfoCreateRobinsonRange(TLProjectionRef, CGFloat);


#pragma mark Helper function definitions

static TLCoordinateDegrees TLProjectionInfoSignificantDomainDistance(TLProjectionRef proj);
static CGFloat TLProjectionInfoSignificantRangeDistance(TLProjectionRef proj);

static TLCoordinateDegrees TLProjectionInfoAntimeridianFromLongitudeOfOrigin(TLCoordinateDegrees);
static TLCoordinateDegrees TLProjectionInfoGetAntimeridian(TLProjectionRef proj);
static TLCoordinate TLProjectionInfoAntipodalCoordinate(TLCoordinate coord);
static TLCoordinate TLProjectionInfoGetAntipode(TLProjectionRef proj);

static inline TLCoordinateDegrees TLCentralAngleFromChordArcDistance(double radius, double distance);

static double TLProjectionInfoGetDegreeLength(TLProjectionRef proj);

static TLCoordinate TLCoordinateAtDistanceAlongAzimuth(TLCoordinate origin,
													   TLCoordinateDegrees distance,
													   TLCoordinateDegrees initialHeading);

static TLCoordPolygonRef TLCoordPolygonCreateBoxAroundCoord(TLCoordinate coord,
															TLCoordinateDegrees halfSize,
															bool reverseWinding);

static TLCoordPolygonRef TLCoordPolygonCreateCircleAroundCoord(TLCoordinate coord,
															   TLCoordinateDegrees radius,
															   TLCoordinateDegrees significantDistance,
															   bool reverseWinding);

static TLMultiPolygonRef TLProjectionInfoCreateRangeFromRawDomain(TLProjectionInfo_DomainCreateFunction domainCreateFunction,
																  TLProjectionRef proj,
																  TLCoordinateDegrees significantDegrees);

#pragma mark Other stuff

// TODO: THIS IS STILL WRONG. See proj_adjlon to diagnose?
#define TLProjectionInfoMeridianPadding (25.0 * M_PI * FLT_EPSILON * TLCoordinateRadiansToDegrees)

#define TLProjectionInfoParallelPadding TLProjectionInfoMeridianPadding

#pragma mark Routing functions

static const TLProjectionInfo_DomainCreateFunction TLProjectionInfoDefaultDomainCreateFunction = NULL;
static const TLProjectionInfo_RangeCreateFunction TLProjectionInfoDefaultRangeCreateFunction = NULL;

static TLProjectionInfo_DomainCreateFunction TLProjectionInfoDomainCreateFunctionForName(TLProjectionName projName) {
	//printf("Projection: '%s'\n", projName);
	TLProjectionInfo_DomainCreateFunction domainCreateFunction = NULL;
	if ( TLProjectionNamesEqual(TLProjectionNameMercator, projName) ) {
		domainCreateFunction = TLProjectionInfoCreateMercatorDomain;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameRobinson, projName) ) {
		domainCreateFunction = TLProjectionInfoCreateRobinsonDomain;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameStereographic, projName) ) {
		domainCreateFunction = TLProjectionInfoCreateStereographicDomain;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameOrthographic, projName) ) {
		domainCreateFunction = TLProjectionInfoCreateOrthographicDomain;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameLambertConformalConic, projName) ) {
		domainCreateFunction = TLProjectionInfoCreateLambertConformalConicDomain;
	}
	else {
		domainCreateFunction  = TLProjectionInfoDefaultDomainCreateFunction;
	}
	return domainCreateFunction;
}

static TLProjectionInfo_RangeCreateFunction TLProjectionInfoRangeCreateFunctionForName(TLProjectionName projName) {
	//printf("Projection: '%s'\n", projName);
	TLProjectionInfo_RangeCreateFunction rangeCreateFunction = NULL;
	if ( TLProjectionNamesEqual(TLProjectionNameMercator, projName) ) {
		rangeCreateFunction = TLProjectionInfoCreateMercatorRange;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameRobinson, projName) ) {
		rangeCreateFunction = TLProjectionInfoCreateRobinsonRange;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameStereographic, projName) ) {
		rangeCreateFunction = TLProjectionInfoCreateStereographicRange;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameOrthographic, projName) ) {
		rangeCreateFunction = TLProjectionInfoCreateOrthographicRange;
	}
	else if ( TLProjectionNamesEqual(TLProjectionNameLambertConformalConic, projName) ) {
		rangeCreateFunction = TLProjectionInfoCreateLambertConformalConicRange;
	}
	else {
		rangeCreateFunction  = TLProjectionInfoDefaultRangeCreateFunction;
	}
	return rangeCreateFunction;
}

TLMultiCoordPolygonRef TLProjectionInfoCreateDomain(TLProjectionRef proj, TLCoordinateDegrees significantDistance) {
	if (TLFloatEqual(significantDistance, 0.0)) {
		significantDistance = TLProjectionInfoSignificantDomainDistance(proj);
	}
	TLProjectionName projName = TLProjectionGetName(proj);
	TLProjectionInfo_DomainCreateFunction domainCreateFunction = TLProjectionInfoDomainCreateFunctionForName(projName);
	if (!domainCreateFunction) return NULL;
	return domainCreateFunction(proj, significantDistance);
}

TLMultiPolygonRef TLProjectionInfoCreateRange(TLProjectionRef proj, CGFloat significantDistance) {
	if (TLFloatEqual(significantDistance, 0.0)) {
		significantDistance = TLProjectionInfoSignificantRangeDistance(proj);
	}
	TLProjectionName projName = TLProjectionGetName(proj);
	TLProjectionInfo_RangeCreateFunction rangeCreateFunction = TLProjectionInfoRangeCreateFunctionForName(projName);
	if (!rangeCreateFunction) return NULL;
	return rangeCreateFunction(proj, significantDistance);
}

#pragma mark Helper functions

// TODO: calculate in a smarter way
static const CGFloat TLProjectionInfoDefaultSigDistance = 1000.0f;

TLCoordinateDegrees TLProjectionInfoSignificantDomainDistance(TLProjectionRef proj) {
	(void)proj;
	return TLProjectionInfoDefaultSigDistance;
}

CGFloat TLProjectionInfoSignificantRangeDistance(TLProjectionRef proj) {
	(void)proj;
	return TLProjectionInfoDefaultSigDistance;
}

TLCoordinateDegrees TLProjectionInfoAntimeridianFromLongitudeOfOrigin(TLCoordinateDegrees lon0) {
	TLCoordinateDegrees antimeridian = lon0 + TLProjectionInfoHemisphere;
	// make sure antimeridian is in [-180,180] 
	if (antimeridian > TLProjectionInfoMaxMeridian) antimeridian -= TLProjectionInfoFullCircle;	// assumes longitudeOfOrigin<180
	return antimeridian;
}

TLCoordinate TLProjectionInfoAntipodalCoordinate(TLCoordinate coord) {
	/* NOTE: According to http://en.wikipedia.org/w/index.php?title=Antipodes&oldid=227990540#Mathematical_description ,
	 this function should work for both spheres and ellipsoids. */
	TLCoordinateDegrees antiLat = -coord.lat;
	TLCoordinateDegrees antiLon = TLProjectionInfoAntimeridianFromLongitudeOfOrigin(coord.lon);
	return TLCoordinateMake(antiLat, antiLon);
}

TLCoordinateDegrees TLProjectionInfoGetAntimeridian(TLProjectionRef proj) {
	TLProjectionParametersRef params = TLProjectionGetParameters(proj);
	TLCoordinateDegrees lon0 = TLProjectionParametersGetLongitudeOfOrigin(params);
	return TLProjectionInfoAntimeridianFromLongitudeOfOrigin(lon0);
}

TLCoordinate TLProjectionInfoGetAntipode(TLProjectionRef proj) {
	TLProjectionParametersRef params = TLProjectionGetParameters(proj);
	TLCoordinateDegrees lon0 = TLProjectionParametersGetLongitudeOfOrigin(params);
	TLCoordinateDegrees lat0 = TLProjectionParametersGetLatitudeOfOrigin(params);
	TLCoordinate coordOfOrigin = TLCoordinateMake(lat0, lon0);
	return TLProjectionInfoAntipodalCoordinate(coordOfOrigin);
}

TLCoordinate TLProjectionInfoGetCenter(TLProjectionRef proj) {
	TLProjectionParametersRef params = TLProjectionGetParameters(proj);
	TLCoordinateDegrees lon0 = TLProjectionParametersGetLongitudeOfOrigin(params);
	TLCoordinateDegrees lat0 = TLProjectionParametersGetLatitudeOfOrigin(params);
	return TLCoordinateMake(lat0, lon0);
}

double TLProjectionInfoGetDegreeLength(TLProjectionRef proj) {
	TLProjectionGeoidRef projGeoid = TLProjectionGetPlanetModel(proj);
	TLProjectionGeoidMeters earthRadius = TLProjectionGeoidGetEquatorialRadius(projGeoid);
	// s=rθ (in radians)
	return earthRadius * TLCoordinateDegreesToRadians;
}

// Assumes coord.lat in (–180º, 180º); coord.lon in (-270º, 270º); halfSize in (0º, 90º)
TLCoordPolygonRef TLCoordPolygonCreateBoxAroundCoord(TLCoordinate coord,
													 TLCoordinateDegrees halfSize,
													 bool reverseWinding)
{
	// (-270º, 270º) = x ± (0º, 90º), so x = (-360º, 180º) int (-180º, 360º), so x = (-180º, 180º)
	TLCoordinateDegrees northEdge = coord.lat + halfSize;
	TLCoordinateDegrees southEdge = coord.lat - halfSize;
	// (-360º, 360º) = x ± (0º, 90º), so x = (-450º, 270º) int (-270º, 450º), so x = (-270º, 270º)
	TLCoordinateDegrees eastEdge = coord.lon + halfSize;
	TLCoordinateDegrees westEdge = coord.lon - halfSize;
	
	TLCoordinate nwVertex = TLCoordinateAdjustToRange( TLCoordinateMake(northEdge, westEdge) );
	TLCoordinate neVertex = TLCoordinateAdjustToRange( TLCoordinateMake(northEdge, eastEdge) );
	TLCoordinate seVertex = TLCoordinateAdjustToRange( TLCoordinateMake(southEdge, eastEdge) );
	TLCoordinate swVertex = TLCoordinateAdjustToRange( TLCoordinateMake(southEdge, westEdge) );
	
	TLMutableCoordPolygonRef boxPoly = TLCoordPolygonCreateMutable(5);
	if (!boxPoly) return NULL;
	TLCoordPolygonAppendCoordinate(boxPoly, nwVertex);
	TLCoordPolygonAppendCoordinate(boxPoly, (reverseWinding ? swVertex : neVertex));
	TLCoordPolygonAppendCoordinate(boxPoly, seVertex);
	TLCoordPolygonAppendCoordinate(boxPoly, (reverseWinding ? neVertex : swVertex));
	TLCoordPolygonAppendCoordinate(boxPoly, nwVertex);
	return boxPoly;
}

TLCoordinate TLCoordinateAtDistanceAlongAzimuth(TLCoordinate origin,
												TLCoordinateDegrees distance,
												TLCoordinateDegrees initialHeading)
{
	/* From http://mathforum.org/library/drmath/view/51816.html which is based on the
	 "Lat/lon given radial and distance" section in http://williams.best.vwh.net/avform.htm
	 See also Synder p. 31. */
	
	double phi1 = origin.lat * TLCoordinateDegreesToRadians;
	double lam1 = origin.lon * TLCoordinateDegreesToRadians;
	double distanceRad = distance * TLCoordinateDegreesToRadians;
	double headingRad = initialHeading * TLCoordinateDegreesToRadians;
	
	double phi = asin(sin(phi1) * cos(distanceRad) +
					  cos(phi1) * sin(distanceRad) * cos(headingRad));
	
	/* NOTE: the first case is a less complicated form for "distances such that dlon <pi/2,
	 i.e those that extend around less than one quarter of the circumference of the earth in longitude".
	 However, the simplified case is called whenever an arbitrary heading *could* result in too much of a
	 longitude difference, since calculating this difference is most of the general case work anyway. */
	double lamDifference = NAN;		// this "lamDifference" is the dlon referred to in note above
	bool noLonWrappingDirectly = distance < TLProjectionInfoFullCircle / 4.0;
	bool noLonWrappingOverPole = origin.lat + distance < TLProjectionInfoMaxParallel;
	if (noLonWrappingDirectly && noLonWrappingOverPole) {
		double cosPhi = cos(phi);
		bool endpointIsPole = TLFloatEqual(cosPhi, 0.0);
		if (endpointIsPole) {
			lamDifference = 0;
		}
		else {
			lamDifference = asin(sin(headingRad) * sin(distanceRad) / cosPhi);
		}
	}
	else {
		lamDifference = atan2(sin(headingRad) * sin(distanceRad) * cos(phi1),
							  cos(distanceRad) - sin(phi1) * sin(phi));
	}
	double unrangedLam = lam1 + lamDifference;
	double lam = fmod(unrangedLam + M_PI, 2.0*M_PI) - M_PI;
	
	return TLCoordinateMake(phi * TLCoordinateRadiansToDegrees, lam * TLCoordinateRadiansToDegrees);
}

// expects distance <= radius
TLCoordinateDegrees TLCentralAngleFromChordArcDistance(double radius, double distance) {
	/* The central angle is the "top" angle of an isosceles triangle with the chord as its base and two radii as legs.
	 This top angle can be found via the height (centerToChord) and leg length (radius). The isosceles triangle is bisected
	 to form a right triangle whose hypoteneuse shares a radius and adjacent side shares the height. */
	double centerToChord = radius - distance;
	double centralAngleRad = 2.0 * acos( centerToChord / radius );
	return centralAngleRad * TLCoordinateRadiansToDegrees;
}

TLCoordPolygonRef TLCoordPolygonCreateCircleAroundCoord(TLCoordinate coord,
														TLCoordinateDegrees radius,
														TLCoordinateDegrees significantDistance,
														bool reverseWinding)
{
	// Find central angle spacing so that chords will be significantDistance from the arc they represent
	// force actual significantDistance to be no more than the radius
	significantDistance = fmin(radius, significantDistance);
	TLCoordinateDegrees anglePerHeading = TLCentralAngleFromChordArcDistance(radius, significantDistance);
	tl_uint_t numberOfUniqueVertexes = (tl_uint_t)round(TLProjectionInfoFullCircle / anglePerHeading);
	const tl_uint_t minimumNumberOfUniqueVertexes = 3;
	if (numberOfUniqueVertexes < minimumNumberOfUniqueVertexes) {
		numberOfUniqueVertexes = minimumNumberOfUniqueVertexes;
	}
	// adjust final angle spacing to fit integer number of vertices
	anglePerHeading = TLProjectionInfoFullCircle / numberOfUniqueVertexes;
	
	TLMutableCoordPolygonRef circle = TLCoordPolygonCreateMutable(numberOfUniqueVertexes + 1);
	if (!circle) return NULL;
	for (tl_uint_t vertIdx = 0; vertIdx < numberOfUniqueVertexes; ++vertIdx) {
		TLCoordinateDegrees currentHeading = vertIdx * anglePerHeading;
		if (reverseWinding && vertIdx) {
			currentHeading  = TLProjectionInfoFullCircle - currentHeading;
		}
		TLCoordinate vertex = TLCoordinateAtDistanceAlongAzimuth(coord, radius, currentHeading);
		TLCoordPolygonAppendCoordinate(circle, vertex);
	}
	TLCoordinate firstCoordinate = TLCoordPolygonGetCoordinate(circle, 0);
	TLCoordPolygonAppendCoordinate(circle, firstCoordinate);
	
	return circle;
}

TLMultiPolygonRef TLProjectionInfoCreateRangeFromRawDomain(TLProjectionInfo_DomainCreateFunction domainCreateFunction,
														   TLProjectionRef proj,
														   TLCoordinateDegrees significantDegrees)
{
	TLMultiCoordPolygonRef domain = domainCreateFunction(proj, significantDegrees);
	if (!domain) return NULL;
	TLMultiPolygonRef range = TLMultiPolygonCreateByProjectingNaively(domain, proj);
	TLMultiCoordPolygonRelease(domain);
	return range;
}


#pragma mark Mercator

TLMultiCoordPolygonRef TLProjectionInfoCreateMercatorDomain(TLProjectionRef mercatorProj,
															TLCoordinateDegrees significantDistance)
{
	(void)significantDistance;
	TLCoordinateDegrees antimeridian = TLProjectionInfoGetAntimeridian(mercatorProj);
	TLCoordinateDegrees eastMeridian = TLCoordinateLongitudeAdjustToRange(antimeridian - TLProjectionInfoMeridianPadding);
	TLCoordinateDegrees westMeridian = TLCoordinateLongitudeAdjustToRange(antimeridian + TLProjectionInfoMeridianPadding);
	TLCoordinateDegrees northParallel = TLProjectionInfoMaxParallel - TLProjectionInfoParallelPadding;
	TLCoordinateDegrees southParallel = TLProjectionInfoMinParallel + TLProjectionInfoParallelPadding;
	TLExtent domainExtent = TLExtentMake(westMeridian, eastMeridian, southParallel, northParallel);
	
	TLCoordPolygonRef domain = TLCoordPolygonCreateFromExtent(domainExtent);
	if (!domain) return NULL;
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(domain);
	TLCoordPolygonRelease(domain);
	return multiCoordPoly;
}

TLMultiPolygonRef TLProjectionInfoCreateMercatorRange(TLProjectionRef mercatorProj, CGFloat significantDistance) {
	(void)significantDistance;
	return TLProjectionInfoCreateRangeFromRawDomain(TLProjectionInfoCreateMercatorDomain, mercatorProj, NAN);
}


#pragma mark Stereographic

TLMultiCoordPolygonRef TLProjectionInfoCreateStereographicDomain(TLProjectionRef stereoProj,
																 TLCoordinateDegrees significantDistance)
{
	(void)significantDistance;
	TLCoordinate antipode = TLProjectionInfoGetAntipode(stereoProj);
	TLCoordPolygonRef antipodeCircle = TLCoordPolygonCreateBoxAroundCoord(antipode,
																		  TLProjectionInfoMeridianPadding,
																		  true);
	if (!antipodeCircle) return NULL;
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(antipodeCircle);
	TLCoordPolygonRelease(antipodeCircle);
	return multiCoordPoly;
}

TLMultiPolygonRef TLProjectionInfoCreateStereographicRange(TLProjectionRef stereoProj, CGFloat significantDistance) {
	(void)significantDistance;
	return TLProjectionInfoCreateRangeFromRawDomain(TLProjectionInfoCreateStereographicDomain, stereoProj, NAN);
}


#pragma mark Robinson

static TLExtent TLProjectionInfoMakeRobinsonDomainExtent(TLProjectionRef robinsonProj) {
	TLCoordinateDegrees antimeridian = TLProjectionInfoGetAntimeridian(robinsonProj);
	TLCoordinateDegrees eastMeridian = antimeridian - TLProjectionInfoMeridianPadding;
	TLCoordinateDegrees westMeridian = antimeridian + TLProjectionInfoMeridianPadding;
	// unlike Mercator, can project all the way to the poles
	TLCoordinateDegrees northParallel = TLProjectionInfoMaxParallel;
	TLCoordinateDegrees southParallel = TLProjectionInfoMinParallel;
	return TLExtentMake(westMeridian, eastMeridian, southParallel, northParallel);
}

TLMultiCoordPolygonRef TLProjectionInfoCreateRobinsonDomain(TLProjectionRef robinsonProj,
															TLCoordinateDegrees significantDistance)
{
	(void)significantDistance;
	TLExtent domainExtent = TLProjectionInfoMakeRobinsonDomainExtent(robinsonProj);
	
	TLCoordPolygonRef domain = TLCoordPolygonCreateFromExtent(domainExtent);
	if (!domain) return NULL;
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(domain);
	TLCoordPolygonRelease(domain);
	return multiCoordPoly;
}

TLMultiPolygonRef TLProjectionInfoCreateRobinsonRange(TLProjectionRef robinsonProj, CGFloat significantDistance) {
	// figure out how much to densify, by approximating chord-arc separation along the sides
	TLCoordinateDegrees approximateSideRadius = 90.0;
	double distancePerDegree = TLProjectionInfoGetDegreeLength(robinsonProj);
	TLCoordinateDegrees significantDegreeDistance = significantDistance / distancePerDegree;
	significantDegreeDistance = fmin(approximateSideRadius, significantDegreeDistance);
	TLCoordinateDegrees densifiedParallelSpacing = TLCentralAngleFromChordArcDistance(approximateSideRadius, significantDegreeDistance);
	
	// divide side "curve" of extent to densify evenly
	TLExtent domainExtent = TLProjectionInfoMakeRobinsonDomainExtent(robinsonProj);
	TLCoordinateDegrees parallelRange = TLExtentGetLatitudeRange(domainExtent);
	/* Calculate how many divisions are needed to fill in densified edge curves. */
	tl_uint_t numDensifiedCurveDivisions = (tl_uint_t)round(parallelRange / densifiedParallelSpacing);
	// adjust final spacing to fit integer number of divisions
	densifiedParallelSpacing = parallelRange / numDensifiedCurveDivisions;
	
	TLMutableCoordPolygonRef densifiedDomain = TLCoordPolygonCreateMutable(3 + numDensifiedCurveDivisions - 1 +
																		   3 + numDensifiedCurveDivisions - 1 + 1);
	if (!densifiedDomain) return NULL;
	
	// top line
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthwestCoordinate(domainExtent));
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthCentralCoordinate(domainExtent));
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNortheastCoordinate(domainExtent));	
	
	// densified right "curve"
	TLCoordinateDegrees rightLongitude = domainExtent.east;
	/* Normally this would start at zero and end *with* numDensifiedCurveDivisions, but as the endpoints of each curve are
	 provided by the top/bottom lines, we need two less vertices to begin with, for the net loss of one used above. */
	for (tl_uint_t latIdx = 1; latIdx < numDensifiedCurveDivisions; ++latIdx) {
		TLCoordinateDegrees latitude = TLProjectionInfoMaxParallel - (latIdx * densifiedParallelSpacing);
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLCoordinateMake(latitude, rightLongitude));
	}
	
	// bottom line
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSoutheastCoordinate(domainExtent));
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSouthCentralCoordinate(domainExtent));
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSouthwestCoordinate(domainExtent));
	
	// densified left "curve"
	TLCoordinateDegrees leftLongitude = domainExtent.west;
	/* see note on loop above about index range */
	for (tl_uint_t latIdx = 1; latIdx < numDensifiedCurveDivisions; ++latIdx) {
		TLCoordinateDegrees latitude = TLProjectionInfoMinParallel + (latIdx * densifiedParallelSpacing);
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLCoordinateMake(latitude, leftLongitude));
	}
	
	// close polygon
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthwestCoordinate(domainExtent));
	
	// project
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(densifiedDomain);
	TLCoordPolygonRelease(densifiedDomain);
	TLMultiPolygonRef projectionRange = TLMultiPolygonCreateByProjectingNaively(multiCoordPoly, robinsonProj);
	TLMultiCoordPolygonRelease(multiCoordPoly);
	return projectionRange;
}

#pragma mark Orthographic

TLMultiCoordPolygonRef TLProjectionInfoCreateOrthographicDomain(TLProjectionRef orthoProj,
																TLCoordinateDegrees significantDistance)
{
	TLCoordinateDegrees allowableRadiusFromCenter = 90.0;
	TLCoordinate center = TLProjectionInfoGetCenter(orthoProj);
	TLCoordPolygonRef domain = TLCoordPolygonCreateCircleAroundCoord(center,
																	 allowableRadiusFromCenter,
																	 significantDistance,
																	 false);
	if (!domain) return NULL;
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(domain);
	TLCoordPolygonRelease(domain);
	return multiCoordPoly;
}

TLMultiPolygonRef TLProjectionInfoCreateOrthographicRange(TLProjectionRef orthoProj, CGFloat significantDistance) {
	double distancePerDegree = TLProjectionInfoGetDegreeLength(orthoProj);
	TLCoordinateDegrees significantDistanceDegree = significantDistance / distancePerDegree;
	return TLProjectionInfoCreateRangeFromRawDomain(TLProjectionInfoCreateOrthographicDomain, orthoProj, significantDistanceDegree);
}

#pragma mark Lambert Conformal Conic

static bool TLProjectionInfoLamberConformalConicNorthPoleConverges(TLProjectionRef lccProj) {
	// get standard parallel values
	TLProjectionParametersRef projParams = TLProjectionGetParameters(lccProj);
	TLCoordinateDegrees singleStandardParallel = TLProjectionParametersGetStandardParallel(projParams);
	TLCoordinateDegrees standardParallel1 = TLProjectionParametersGetStandardParallel1(projParams);
	TLCoordinateDegrees standardParallel2 = TLProjectionParametersGetStandardParallel2(projParams);
	
	// ensure single parallel is 0.0 if either of the pair is set
	double projInternalToleranceEPS10 = 1.e-10;
	if (!TLFloatEqualTol(standardParallel1, 0.0, projInternalToleranceEPS10) ||
		!TLFloatEqualTol(standardParallel2, 0.0, projInternalToleranceEPS10))
	{
		singleStandardParallel = 0.0;
	}
	
	// ...so now at least one of the three parallels is non-zero and will win the superlative(s) below
	TLCoordinateDegrees mostNorthParallel = fmax(singleStandardParallel, fmax(standardParallel1, standardParallel2));
	TLCoordinateDegrees mostSouthParallel = fmin(singleStandardParallel, fmin(standardParallel1, standardParallel2));
	TLCoordinateDegrees northDistance = fabs(TLProjectionInfoMaxParallel - mostNorthParallel);
	TLCoordinateDegrees southDistance = fabs(TLProjectionInfoMinParallel - mostSouthParallel);
	
	// the meridians converge at the north pole if it is closer to the most extreme of the parallel(s)
	return (northDistance < southDistance);
}

static TLExtent TLProjectionInfoMakeLambertConformalConicDomainExtent(TLProjectionRef lccProj) {
	TLCoordinateDegrees antimeridian = TLProjectionInfoGetAntimeridian(lccProj);
	TLCoordinateDegrees eastMeridian = antimeridian - TLProjectionInfoMeridianPadding;
	TLCoordinateDegrees westMeridian = antimeridian + TLProjectionInfoMeridianPadding;
	// set initial top/bottom before further adjustment below
	TLCoordinateDegrees northParallel = TLProjectionInfoMaxParallel;
	TLCoordinateDegrees southParallel = TLProjectionInfoMinParallel;
	// Can project all the way to the pole in the hemisphere where the meridians converge, not where they diverge
	bool northPoleConverges = TLProjectionInfoLamberConformalConicNorthPoleConverges(lccProj);
	if (northPoleConverges) {
		southParallel += TLProjectionInfoParallelPadding;
	}
	else {	// southPoleConverges
		northParallel -= TLProjectionInfoParallelPadding;
	}
	return TLExtentMake(westMeridian, eastMeridian, southParallel, northParallel);	
}

TLMultiCoordPolygonRef TLProjectionInfoCreateLambertConformalConicDomain(TLProjectionRef lccProj, TLCoordinateDegrees significantDistance) {
	(void)significantDistance;
	TLExtent domainExtent = TLProjectionInfoMakeLambertConformalConicDomainExtent(lccProj);
	TLCoordPolygonRef domain = TLCoordPolygonCreateFromExtent(domainExtent);
	if (!domain) return NULL;
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(domain);
	TLCoordPolygonRelease(domain);
	return multiCoordPoly;
}

TLMultiPolygonRef TLProjectionInfoCreateLambertConformalConicRange(TLProjectionRef lccProj, CGFloat significantDistance) {
	// figure out how much to densify by approximating chord-arc separation along the diverging "base"
	TLCoordinateDegrees approximateBaseRadius = 180.0;
	double distancePerDegree = TLProjectionInfoGetDegreeLength(lccProj);
	TLCoordinateDegrees significantDegreeDistance = significantDistance / distancePerDegree;
	significantDegreeDistance = fmin(approximateBaseRadius, significantDegreeDistance);
	TLCoordinateDegrees densifiedMeridianSpacing = TLCentralAngleFromChordArcDistance(approximateBaseRadius, significantDegreeDistance);
	
	// divide base of extent to densify evenly
	TLExtent domainExtent = TLProjectionInfoMakeLambertConformalConicDomainExtent(lccProj);
	TLCoordinateDegrees meridianRange = TLExtentGetLongitudeRange(domainExtent);
	// calculate how many divisions are needed to fill in densified base curve.
	tl_uint_t numDensifiedBaseDivisions = (tl_uint_t)round(meridianRange / densifiedMeridianSpacing);
	// adjust final spacing to fit integer number of vertices
	densifiedMeridianSpacing = meridianRange / numDensifiedBaseDivisions;
	
	TLMutableCoordPolygonRef densifiedDomain = TLCoordPolygonCreateMutable(3 + numDensifiedBaseDivisions + 1 + 1);
	if (!densifiedDomain) return NULL;
	
	bool northPoleConverges = TLProjectionInfoLamberConformalConicNorthPoleConverges(lccProj);
	
	// north line
	if (northPoleConverges) {
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthwestCoordinate(domainExtent));
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthCentralCoordinate(domainExtent));
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNortheastCoordinate(domainExtent));
	}
	else {
		TLCoordinateDegrees latitude = domainExtent.north;
		for (tl_uint_t lonIdx = 0; lonIdx <= numDensifiedBaseDivisions; ++lonIdx) {
			TLCoordinateDegrees unrangedLongitude = domainExtent.west + (lonIdx * densifiedMeridianSpacing);
			TLCoordinateDegrees longitude = TLCoordinateLongitudeAdjustToRange(unrangedLongitude);
			TLCoordinate coord = TLCoordinateMake(latitude, longitude);
			TLCoordPolygonAppendCoordinate(densifiedDomain, coord);
		}
	}
	
	// south line
	if (northPoleConverges) {
		TLCoordinateDegrees latitude = domainExtent.south;
		for (tl_uint_t lonIdx = 0; lonIdx <= numDensifiedBaseDivisions; ++lonIdx) {
			TLCoordinateDegrees unrangedLongitude = domainExtent.east - (lonIdx * densifiedMeridianSpacing);
			TLCoordinateDegrees longitude = TLCoordinateLongitudeAdjustToRange(unrangedLongitude);
			TLCoordinate coord = TLCoordinateMake(latitude, longitude);
			TLCoordPolygonAppendCoordinate(densifiedDomain, coord);
		}
	}
	else {
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSoutheastCoordinate(domainExtent));
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSouthCentralCoordinate(domainExtent));
		TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetSouthwestCoordinate(domainExtent));
	}
	
	// close polygon
	TLCoordPolygonAppendCoordinate(densifiedDomain, TLExtentGetNorthwestCoordinate(domainExtent));
	
	// project
	TLMultiCoordPolygonRef multiCoordPoly = TLMultiCoordPolygonCreateFromPolygon(densifiedDomain);
	TLCoordPolygonRelease(densifiedDomain);
	TLMultiPolygonRef projectionRange = TLMultiPolygonCreateByProjectingNaively(multiCoordPoly, lccProj);
	TLMultiCoordPolygonRelease(multiCoordPoly);
	return projectionRange;
}


#pragma mark Default bounds

TLBounds TLProjectionInfoDefaultBounds(TLProjectionRef proj) {
	// TODO: for some projections, bounds calculated in this fashion will not be ideal
	TLMultiPolygonRef rangePolygon = TLProjectionInfoCreateRange(proj, 0.0f);
	if (!rangePolygon) return CGRectZero;
	
	TLBounds defaultBounds = TLBoundsFromMultiPolygon(rangePolygon);
	TLMultiPolygonRelease(rangePolygon);
	return defaultBounds;
}

CGFloat TLProjectionInfoGetScalingFactor(TLProjectionRef proj) {
	(void)proj;
	// NOTE: the follow code assumes projection scale cannot be changed
	return 1.0f;
}
