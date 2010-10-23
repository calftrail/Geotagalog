/*
 *  TLProjectionGeoid.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLProjectionGeoid.h"
#include "TLProjectionGeoidInternals.h"
#include "TLProjectionParametersInternal.h"
#include "TLProjectionDataRepresentation.h"

static const double TLProjectionGeoidSphereFlattening = 0.0;
/*
typedef struct TL_ProjectionGeoid {
	tl_uint_t retainCount;
	double a;
	double f;	// if f==0.0, is sphere
} TLProjectionGeoid;
 */

// NOTE: Only the WGS84 geoid is currently implemented. Many functions ignore the geoid parameter entirely.

TLProjectionGeoidRef const TLProjectionGeoidWGS84 = (TLProjectionGeoidRef)"Predefined WGS84 geoid";

TLProjectionGeoidRef TLProjectionGeoidCopy(TLProjectionGeoidRef geoid) {
	return geoid;
}

TLProjectionGeoidRef TLProjectionGeoidRetain(TLProjectionGeoidRef geoid) {
	return geoid;
}

void TLProjectionGeoidRelease(TLProjectionGeoidRef geoid) {
	(void)geoid;
}

static CFStringRef TLProjectionGeoidCreateEllipseValue(TLProjectionGeoidRef geoid) {
	(void)geoid;
	return CFSTR("WGS84");
}

void TLProjectionGeoidAddInfoToParameters(TLProjectionGeoidRef geoid, TLMutableProjectionParametersRef params) {
	CFStringRef ellipseValue = TLProjectionGeoidCreateEllipseValue(geoid);
	TLProjectionParametersSetValue(params, TLProjectionParametersEllipseNameKey, ellipseValue);
	CFRelease(ellipseValue);
}


#pragma mark Data representation

CFDataRef TLProjectionGeoidCreateDataRepresentation(TLProjectionGeoidRef projGeoid) {
	CFStringRef ellipseValue = TLProjectionGeoidCreateEllipseValue(projGeoid);
	CFStringRef geoidArgs = TLProjectionParametersCreateStringWithKeyAndValue(TLProjectionParametersEllipseNameKey, ellipseValue);
	CFRelease(ellipseValue);
	CFDataRef geoidAsData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, geoidArgs, kCFStringEncodingASCII, 0);
	CFRelease(geoidArgs);
	return geoidAsData;
}

TLProjectionGeoidRef TLProjectionGeoidCreateFromDataRepresentation(CFDataRef projGeoidData) {
	/*
	CFStringRef geoidArgs = CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, projGeoidData, kCFStringEncodingASCII);
	CFTypeRef ellipseKey = NULL;
	CFTypeRef ellipseValue = NULL;
	(void)TLProjectionParametersCreatePairFromString(geoidArgs, &ellipseKey, &ellipseValue);
	(void)ellipseKey;
	(void)ellipseValue;
	CFRelease(ellipseKey);
	CFRelease(ellipseValue);
	CFRelease(geoidArgs);
	*/
	(void)projGeoidData;
	return TLProjectionGeoidWGS84;
}


#pragma mark Geoid info accessors

TLProjectionGeoidMeters TLProjectionGeoidGetEquatorialRadius(TLProjectionGeoidRef geoid) {
	(void)geoid;
	
	const TLProjectionGeoidMeters wgs84semimajorAxis = 6378137.0;
	return wgs84semimajorAxis;
}

double TLProjectionGeoidGetFlattening(TLProjectionGeoidRef geoid) {
	(void)geoid;
	
	const double wgs84flattening = 1.0 / 298.257223563;
	return wgs84flattening;
}

bool TLProjectionGeoidIsSpherical(TLProjectionGeoidRef geoid) {
	double f = TLProjectionGeoidGetFlattening(geoid);
	return (f == TLProjectionGeoidSphereFlattening);
}

TLProjectionGeoidMeters TLProjectionGeoidGetPolarRadius(TLProjectionGeoidRef geoid) {
	TLProjectionGeoidMeters a = TLProjectionGeoidGetEquatorialRadius(geoid);
	double f = TLProjectionGeoidGetFlattening(geoid);
	return a * (1.0 - f);
}

double TLProjectionGeoidGetEccentricitySquared(TLProjectionGeoidRef geoid) {
	double f = TLProjectionGeoidGetFlattening(geoid);
	return f * (2.0 - f);
}
