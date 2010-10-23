/*
 *  TLProjectionParameters.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLProjectionParameters.h"

#include "TLProjectionParametersInternal.h"
#include "TLProjectionDataRepresentation.h"

#include <CoreFoundation/CFDictionary.h>

typedef struct TL_ProjectionParameters {
	tl_uint_t retainCount;
	CFMutableDictionaryRef params;
} TLProjectionParameters;


#pragma mark Key definitions

CFStringRef const TLProjectionParametersLonOriginKey = CFSTR("lon_0");
CFStringRef const TLProjectionParametersLatOriginKey = CFSTR("lat_0");
CFStringRef const TLProjectionParametersStandardParallelKey = CFSTR("lat_0");	// same as TLProjectionParametersLatOriginKey
CFStringRef const TLProjectionParametersStandardParallel1Key = CFSTR("lat_1");
CFStringRef const TLProjectionParametersStandardParallel2Key = CFSTR("lat_2");
CFStringRef const TLProjectionParametersProjNameKey = CFSTR("proj");
CFStringRef const TLProjectionParametersEllipseNameKey = CFSTR("ellps");

#pragma mark Lifecycle

// Designated initializer
static TLMutableProjectionParametersRef TLProjectionParametersCreateMutableWithDictionary(CFMutableDictionaryRef paramsDict) {
	TLMutableProjectionParametersRef projParams = (TLMutableProjectionParametersRef)malloc( sizeof(TLProjectionParameters) );
	if (projParams) {
		projParams->retainCount = 1;
		CFRetain(paramsDict);
		projParams->params = paramsDict;
	}
	return projParams;	
}

TLMutableProjectionParametersRef TLProjectionParametersCreateMutable() {
	CFMutableDictionaryRef paramsDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	TLMutableProjectionParametersRef projParams = TLProjectionParametersCreateMutableWithDictionary(paramsDict);
	CFRelease(paramsDict);
	return projParams;
}

TLProjectionParametersRef TLProjectionParametersCreate() {
	return TLProjectionParametersCreateMutable();
}

static void TLProjectionParametersDestroy(TLMutableProjectionParametersRef projParams) {
	CFRelease(projParams->params);
	free(projParams);
}

TLMutableProjectionParametersRef TLProjectionParametersMutableCopy(TLProjectionParametersRef otherProjParams) {
	TLMutableProjectionParametersRef projParams = (TLMutableProjectionParametersRef)malloc( sizeof(TLProjectionParameters) );
	if (projParams) {
		projParams->retainCount = 1;
		projParams->params = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, otherProjParams->params);
	}
	return projParams;
}

TLProjectionParametersRef TLProjectionParametersCopy(TLProjectionParametersRef projParams) {
	return TLProjectionParametersMutableCopy(projParams);
}

TLProjectionParametersRef TLProjectionParametersRetain(TLProjectionParametersRef projParams) {
	TLMutableProjectionParametersRef mutableProjParams = (TLMutableProjectionParametersRef)projParams;
	mutableProjParams->retainCount += 1;
	return projParams;
}

void TLProjectionParametersRelease(TLProjectionParametersRef projParams) {
	if (!projParams) return;
	TLMutableProjectionParametersRef mutableProjParams = (TLMutableProjectionParametersRef)projParams;
	mutableProjParams->retainCount -= 1;
	if (!projParams->retainCount) TLProjectionParametersDestroy(mutableProjParams);
}


#pragma mark Data representation

static CFStringRef const TLProjectionParametersParameterSeparator = CFSTR(" ");

CFDataRef TLProjectionParametersCreateDataRepresentation(TLProjectionParametersRef projParams) {
	CFMutableStringRef allParametersString = CFStringCreateMutable(kCFAllocatorDefault, 0);
	
	CFIndex keyCount = TLProjectionParametersGetCount(projParams);
	CFArrayRef allParamKeys = TLProjectionParametersCreateAllKeysArray(projParams);
	for (CFIndex keyIdx = 0; keyIdx < keyCount; ++keyIdx) {
		CFTypeRef key = CFArrayGetValueAtIndex(allParamKeys, keyIdx);
		CFStringRef parameterString = TLProjectionParametersCreateStringWithKey(projParams, key);
		if (keyIdx) CFStringAppend(allParametersString, TLProjectionParametersParameterSeparator);
		CFStringAppend(allParametersString, parameterString);
		CFRelease(parameterString);
	}
	CFRelease(allParamKeys);
	
	CFDataRef projParamsData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, allParametersString, kCFStringEncodingASCII, 0);
	CFRelease(allParametersString);
	return projParamsData;
}

TLProjectionParametersRef TLProjectionParametersCreateFromDataRepresentation(CFDataRef projParamsData) {
	// split combined parameters string into array of individual parameter key/value pairs
	CFStringRef allParametersString = CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, projParamsData, kCFStringEncodingASCII);
	CFArrayRef allParameters = CFStringCreateArrayBySeparatingStrings(kCFAllocatorDefault, allParametersString, TLProjectionParametersParameterSeparator);
	CFRelease(allParametersString);
	
	// split each pair into its parts and add to new projParams object
	TLMutableProjectionParametersRef projParams = TLProjectionParametersCreateMutable();
	CFIndex paramCount = CFArrayGetCount(allParameters);
	for (CFIndex paramIdx = 0; paramIdx < paramCount; ++paramIdx) {
		CFStringRef parameterString = CFArrayGetValueAtIndex(allParameters, paramIdx);
		CFTypeRef* key = NULL;
		CFTypeRef* value = NULL;
		(void)TLProjectionParametersCreatePairFromString(parameterString, key, value);
		TLProjectionParametersSetValue(projParams, key, value);
		CFRelease(key);
		CFRelease(value);
	}
	CFRelease(allParameters);
	
	return projParams;
}


#pragma mark Parameter dictionary helpers

CFTypeRef TLProjectionParametersGetValue(TLProjectionParametersRef projParams, CFTypeRef key) {
	CFDictionaryRef paramDict = projParams->params;
	return CFDictionaryGetValue(paramDict, key);
}

void TLProjectionParametersSetValue(TLMutableProjectionParametersRef projParams, CFTypeRef key, CFTypeRef value) {
	CFMutableDictionaryRef paramDict = projParams->params;
	Boolean keyExists = CFDictionaryContainsKey(paramDict, key);
	if (keyExists) {
		CFDictionaryReplaceValue(paramDict, key, value);
	}
	else {
		CFDictionaryAddValue(paramDict, key, value);
	}
}

CFIndex TLProjectionParametersGetCount(TLProjectionParametersRef projParams) {
	return CFDictionaryGetCount(projParams->params);
}

CFArrayRef TLProjectionParametersCreateAllKeysArray(TLProjectionParametersRef projParams) {
	CFDictionaryRef paramDict = projParams->params;
	
	// prepare buffer
	CFIndex keysCount = CFDictionaryGetCount(paramDict);
	CFTypeRef* keysBuffer = (CFTypeRef*)malloc(keysCount * sizeof(CFTypeRef));
	if (!keysBuffer) return NULL;
	
	// fill buffer with just keys
	CFDictionaryGetKeysAndValues(paramDict, keysBuffer, NULL);
	
	// convert buffer to new array
	CFArrayRef keysArray = CFArrayCreate(kCFAllocatorDefault, keysBuffer, keysCount, &kCFTypeArrayCallBacks);
	free(keysBuffer);
	
	return keysArray;
}

TLCoordinateDegrees TLProjectionParametersGetDegreesForKey(TLProjectionParametersRef projParams, CFStringRef key, TLCoordinateDegrees defaultDegrees) {
	CFNumberRef degreesNumber = TLProjectionParametersGetValue(projParams, key);
	double dDegrees = defaultDegrees;
	if (degreesNumber) {
		(void)CFNumberGetValue(degreesNumber, kCFNumberDoubleType, &dDegrees);
	}
	return (TLCoordinateDegrees)dDegrees;	
}

void TLProjectionParametersSetDegreesForKey(TLMutableProjectionParametersRef projParams, CFStringRef key, TLCoordinateDegrees degrees) {
	double dDegrees = (double)degrees;
	CFNumberRef degreesNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &dDegrees);
	TLProjectionParametersSetValue(projParams, key, degreesNumber);
	CFRelease(degreesNumber);
}

bool TLProjectionParametersKeyIsSet(TLMutableProjectionParametersRef projParams, CFStringRef key) {
	return CFDictionaryContainsKey(projParams->params, key);
}


#pragma mark Parameter accessors

TLCoordinateDegrees TLProjectionParametersGetLongitudeOfOrigin(TLProjectionParametersRef projParams) {
	return TLProjectionParametersGetDegreesForKey(projParams, TLProjectionParametersLonOriginKey, 0.0);
}

void TLProjectionParametersSetLongitudeOfOrigin(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lon0) {
	TLProjectionParametersSetDegreesForKey(projParams, TLProjectionParametersLonOriginKey, lon0);
}

TLCoordinateDegrees TLProjectionParametersGetLatitudeOfOrigin(TLProjectionParametersRef projParams) {
	return TLProjectionParametersGetDegreesForKey(projParams, TLProjectionParametersLatOriginKey, 0.0);
}

void TLProjectionParametersSetLatitudeOfOrigin(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat0) {
	TLProjectionParametersSetDegreesForKey(projParams, TLProjectionParametersLatOriginKey, lat0);
}


TLCoordinateDegrees TLProjectionParametersGetStandardParallel(TLProjectionParametersRef projParams) {
	return TLProjectionParametersGetDegreesForKey(projParams, TLProjectionParametersStandardParallelKey, 0.0);
}

TLCoordinateDegrees TLProjectionParametersGetStandardParallel1(TLProjectionParametersRef projParams) {
	return TLProjectionParametersGetDegreesForKey(projParams, TLProjectionParametersStandardParallel1Key, 0.0);
}

TLCoordinateDegrees TLProjectionParametersGetStandardParallel2(TLProjectionParametersRef projParams) {
	return TLProjectionParametersGetDegreesForKey(projParams, TLProjectionParametersStandardParallel2Key, 0.0);
}

void TLProjectionParametersSetStandardParallel(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat0) {
	TLProjectionParametersSetDegreesForKey(projParams, TLProjectionParametersStandardParallelKey, lat0);
}

void TLProjectionParametersSetStandardParallels(TLMutableProjectionParametersRef projParams, TLCoordinateDegrees lat1, TLCoordinateDegrees lat2) {
	TLProjectionParametersSetDegreesForKey(projParams, TLProjectionParametersStandardParallel1Key, lat1);
	TLProjectionParametersSetDegreesForKey(projParams, TLProjectionParametersStandardParallel2Key, lat2);
}


#pragma mark Conversion to and from lib_proj parameter format

static CFNumberFormatterRef TLProjectionParametersCreateNumberFormatter() {
	return CFNumberFormatterCreate(kCFAllocatorDefault, NULL, kCFNumberFormatterDecimalStyle);
}

static CFStringRef const TLProjectionParametersPrefix = CFSTR("+");
static CFStringRef const TLProjectionParametersSeparator = CFSTR("=");

CFStringRef TLProjectionParametersCreateStringWithKeyAndValue(CFTypeRef paramKey, CFTypeRef paramValue) {
	// key must already be a string
	if ( CFGetTypeID(paramKey) != CFStringGetTypeID() ) return NULL;
	CFStringRef keyString = (CFStringRef)paramKey;
	
	// value must be a string or a number which we convert to a string
	CFStringRef valueString = NULL;
	if ( CFGetTypeID(paramValue) == CFNumberGetTypeID() ) {
		CFNumberFormatterRef numberFormatter = TLProjectionParametersCreateNumberFormatter();
		valueString = CFNumberFormatterCreateStringWithNumber(kCFAllocatorDefault, numberFormatter, (CFNumberRef)paramValue);
		CFRelease(numberFormatter);
	}
	else if ( CFGetTypeID(paramValue) == CFStringGetTypeID() ) {
		valueString = CFStringCreateCopy(kCFAllocatorDefault, (CFStringRef)paramValue);
	}
	else {
		return NULL;
	}
	
	// Build a string of "<prefix><key><separator><value>" format
	CFStringRef prefix = TLProjectionParametersPrefix;
	CFStringRef separator = TLProjectionParametersSeparator;
	CFIndex combinedLength = CFStringGetLength(prefix) + CFStringGetLength(keyString) + CFStringGetLength(separator) + CFStringGetLength(valueString);
	CFMutableStringRef formattedString = CFStringCreateMutable(kCFAllocatorDefault, combinedLength);
	CFStringAppend(formattedString, prefix);
	CFStringAppend(formattedString, keyString);
	CFStringAppend(formattedString, separator);
	CFStringAppend(formattedString, valueString);
	CFRelease(valueString);
	
	return formattedString;
}

CFStringRef TLProjectionParametersCreateStringWithKey(TLProjectionParametersRef projParams, CFTypeRef key) {
	CFTypeRef paramValue = TLProjectionParametersGetValue(projParams, key);
	return TLProjectionParametersCreateStringWithKeyAndValue(key, paramValue);
}

bool TLProjectionParametersCreatePairFromString(CFStringRef formattedString, CFTypeRef* key, CFTypeRef* value) {
	*key = NULL;
	*value = NULL;
	
	// find prefix
	CFRange prefixRange = CFStringFind(formattedString, TLProjectionParametersPrefix, 0);
	if (prefixRange.location == kCFNotFound) prefixRange.location = 0;
	
	// find separator
	CFRange separatorRange = CFStringFind(formattedString, TLProjectionParametersSeparator, 0);
	if (separatorRange.location == kCFNotFound) return false;
	
	// create key range
	CFIndex keyStart = prefixRange.location + prefixRange.length;
	CFIndex keyLength = separatorRange.location - keyStart;
	CFRange keyRange = CFRangeMake(keyStart, keyLength);
	
	// extract key
	*key = CFStringCreateWithSubstring(kCFAllocatorDefault, formattedString, keyRange);
	
	// create value range
	CFIndex valueStart = separatorRange.location + separatorRange.length;
	CFIndex valueLength = CFStringGetLength(formattedString) - valueStart;
	CFRange valueRange = CFRangeMake(valueStart, valueLength);
	
	// try to turn value into a CFNumber, otherwise just extract as string
	CFNumberFormatterRef numberFormatter = TLProjectionParametersCreateNumberFormatter();
	CFNumberRef numberValue = CFNumberFormatterCreateNumberFromString(kCFAllocatorDefault, numberFormatter, formattedString, &valueRange, 0);
	CFRelease(numberFormatter);
	if (numberValue) {
		*value = numberValue;
	}
	else {
		*value = CFStringCreateWithSubstring(kCFAllocatorDefault, formattedString, valueRange);
	}
	
	return true;
}
