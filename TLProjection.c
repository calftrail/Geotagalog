/*
 *  TLProjection.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLProjection.h"

#include <CoreFoundation/CoreFoundation.h>
#include "lib_proj.h";

#include "TLProjectionParametersInternal.h"
#include "TLProjectionGeoidInternals.h"
#include "TLProjectionDataRepresentation.h"
#include "TLFloat.h"

#pragma mark Name definitions

TLProjectionName const TLProjectionNameMercator = "merc";
TLProjectionName const TLProjectionNameStereographic = "stere";
TLProjectionName const TLProjectionNameLambertConformalConic = "lcc";
TLProjectionName const TLProjectionNameOrthographic = "ortho";
TLProjectionName const TLProjectionNameRobinson = "robin";

typedef char* TLProjectionMutableName;

bool TLProjectionNamesEqual(TLProjectionName name1, TLProjectionName name2) {
	return !strcmp(name1, name2);
}

static TLProjectionName TLProjectionNameCreateCopy(TLProjectionName name) {
	size_t nameBufferLength = strlen(name) + 1;
	TLProjectionMutableName copiedName = (TLProjectionMutableName)malloc(nameBufferLength);
	if (copiedName) {
		memcpy(copiedName, name, nameBufferLength);
	}
	return copiedName;
}

static char* TLProjectionCreateASCIIFromString(CFStringRef string);

bool TLProjectionErrorGetString(TLProjectionError err, char* stringBuf, int bufLen) {
	return (bool)proj_strerror_r(err, stringBuf, bufLen);
}

typedef struct TL_Projection {
	tl_uint_t retainCount;
	PROJ* projPtr;
	TLProjectionName name;
	TLProjectionGeoidRef geoid;
	TLProjectionParametersRef params;
} TLProjection;

typedef struct TL_Projection* TLMutableProjectionRef;


#pragma mark Lifecycle

PROJ* TLProjectionCreateProjPtr(TLProjectionName name, TLProjectionGeoidRef planetModel, TLProjectionParametersRef parameters, TLProjectionError* err);

TLProjectionRef TLProjectionCreate(TLProjectionName name, TLProjectionGeoidRef planetModel, TLProjectionParametersRef userParameters, TLProjectionError* err) {
	TLProjectionParametersRef copiedParams = userParameters ? TLProjectionParametersCopy(userParameters) : TLProjectionParametersCreate();
	
	PROJ* projPtr = TLProjectionCreateProjPtr(name, planetModel, copiedParams, err);
	TLMutableProjectionRef proj = NULL;
	
	if (projPtr) proj = (TLMutableProjectionRef)malloc( sizeof(TLProjection) );
	if (proj) {
		proj->retainCount = 1;
		proj->projPtr = projPtr;
		proj->name = TLProjectionNameCreateCopy(name);
		proj->geoid = TLProjectionGeoidCopy(planetModel);
		proj->params = copiedParams;
	}
	else {
		TLProjectionParametersRelease(copiedParams);
	}
	
	return proj;
}

static void TLProjectionDestroy(TLMutableProjectionRef proj) {
	proj_free(proj->projPtr);
	free((TLProjectionMutableName)proj->name);
	TLProjectionGeoidRelease(proj->geoid);
	TLProjectionParametersRelease(proj->params);
	free(proj);
}

TLProjectionRef TLProjectionCopy(TLProjectionRef proj) {
	return TLProjectionRetain(proj);
}

TLProjectionRef TLProjectionRetain(TLProjectionRef proj) {
	TLMutableProjectionRef mutableProj = (TLMutableProjectionRef)proj;
	mutableProj->retainCount += 1;
	return proj;
}

void TLProjectionRelease(TLProjectionRef proj) {
	if (!proj) return;
	TLMutableProjectionRef mutableProj = (TLMutableProjectionRef)proj;
	mutableProj->retainCount -= 1;
	if (!proj->retainCount) TLProjectionDestroy(mutableProj);
}


#pragma mark Projection creation internals

static CFStringRef TLProjectionCreateNameParamValue(TLProjectionName name) {
	return CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
}

static CFDataRef TLProjectionNameCreateDataRepresentation(TLProjectionName name) {
	CFStringRef projNameValue = TLProjectionCreateNameParamValue(name);
	CFStringRef projNameParameter = TLProjectionParametersCreateStringWithKeyAndValue(TLProjectionParametersProjNameKey, projNameValue);
	CFRelease(projNameValue);
	CFDataRef nameData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, projNameParameter, kCFStringEncodingASCII, 0);
	CFRelease(projNameParameter);
	return nameData;
}

// caller must free() return value
static char* TLProjectionNameNewFromDataRepresentation(CFDataRef nameData) {
	CFStringRef projNameString = CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, nameData, kCFStringEncodingASCII);
	char* projName = TLProjectionCreateASCIIFromString(projNameString);
	CFRelease(projNameString);
	return projName;
}

static void TLProjectionAddLambertConfConicDefaults(TLMutableProjectionParametersRef combinedParams) {
	// Assume both parallels are set if one is, otherwise is flagrant caller error.
	bool parallelsSet = TLProjectionParametersKeyIsSet(combinedParams, TLProjectionParametersStandardParallel1Key);
	
	if (!parallelsSet) {
		// set parallels to standard parallel if nonzero, or 33/45 if is zero
		double projInternalToleranceEPS10 = 1.e-10;
		TLCoordinateDegrees standardParallel = TLProjectionParametersGetDegreesForKey(combinedParams, TLProjectionParametersStandardParallelKey, 0.0);
		bool standardParallelIsZero = TLFloatEqualTol(standardParallel, 0.0, projInternalToleranceEPS10);
		if (standardParallelIsZero) {
			TLProjectionParametersSetStandardParallels(combinedParams, 33.0, 45.0);
		}
		else {
			TLProjectionParametersSetStandardParallels(combinedParams, standardParallel, standardParallel);
		}
	}
}

static void TLProjectionAddDefaultsToParameters(TLProjectionName name,
												TLProjectionGeoidRef geoid,
												TLMutableProjectionParametersRef combinedParams)
{
	(void)geoid;
	if (TLProjectionNamesEqual(name, TLProjectionNameLambertConformalConic)) {
		TLProjectionAddLambertConfConicDefaults(combinedParams);
	}
}

static TLProjectionParametersRef TLProjectionCreateCombinedParameters(TLProjectionName name,
																	  TLProjectionGeoidRef geoid,
																	  TLProjectionParametersRef userParams)
{
	TLMutableProjectionParametersRef combinedParams = TLProjectionParametersMutableCopy(userParams);
	
	// Set projection name
	CFStringRef projNameValue = TLProjectionCreateNameParamValue(name);
	TLProjectionParametersSetValue(combinedParams, TLProjectionParametersProjNameKey, projNameValue);
	/* NOTE: the following is demo code for oblique projections, which need better support in TLProjectionInfo before use
	TLProjectionParametersSetValue(combinedParams, TLProjectionParametersProjNameKey, CFSTR("ob_tran"));
	TLProjectionParametersSetValue(combinedParams, CFSTR("o_proj"), projNameValue);
	TLProjectionParametersSetValue(combinedParams, CFSTR("o_lat_p"), CFSTR("65.0"));
	TLProjectionParametersSetValue(combinedParams, CFSTR("o_lon_p"), CFSTR("-180.0"));
	*/
	CFRelease(projNameValue);
	
	
	// Set geoid parameters
	TLProjectionGeoidAddInfoToParameters(geoid, combinedParams);
	
	// Set default parameters
	TLProjectionAddDefaultsToParameters(name, geoid, combinedParams);
	
	return combinedParams;
}

static char* TLProjectionCreateASCIIFromString(CFStringRef string) {
	if (!string) return NULL;
	CFIndex stringBufferSize = CFStringGetLength(string) + 1;		// NOTE: this is Unicode characters, which we assume match ASCII
	char* parameterAsCString = (char*)malloc(stringBufferSize);
	Boolean conversionSuccessful = CFStringGetCString(string, parameterAsCString, stringBufferSize, kCFStringEncodingASCII);
	if (!conversionSuccessful) {
		free(parameterAsCString);
		parameterAsCString = NULL;
	}
	return parameterAsCString;	
}

PROJ* TLProjectionCreateProjPtr(TLProjectionName name,
								TLProjectionGeoidRef geoid,
								TLProjectionParametersRef userParams,
								TLProjectionError* err)
{
	// Create full parameter set
	TLProjectionParametersRef combinedParams = TLProjectionCreateCombinedParameters(name, geoid, userParams);
	
	// Convert all the parameters to the argv[]-style array that proj_init expects
	bool argumentCreationSuccessful = true;
	CFIndex argumentCount = TLProjectionParametersGetCount(combinedParams);
	char** proj_args = (char**)calloc(argumentCount, sizeof(char*));
	CFArrayRef allParamKeys = TLProjectionParametersCreateAllKeysArray(combinedParams);
	for (CFIndex argIdx = 0; argIdx < argumentCount; ++argIdx) {
		CFTypeRef key = CFArrayGetValueAtIndex(allParamKeys, argIdx);
		
		CFStringRef parameterString = TLProjectionParametersCreateStringWithKey(combinedParams, key);
		char* parameterAsCString = TLProjectionCreateASCIIFromString(parameterString);
		if (parameterString) CFRelease(parameterString);
		
		if (!parameterAsCString) {
			if (err) *err = EINVAL;
			argumentCreationSuccessful = false;
			break;
		}

		
		proj_args[argIdx] = parameterAsCString;
	}
	CFRelease(allParamKeys);
	
	TLProjectionParametersRelease(combinedParams);
	
	
	// Initialize the actual projection with prepared arguments
	PROJ* initializedProjPtr = NULL;
	if (argumentCreationSuccessful) {
		initializedProjPtr = proj_init((int)argumentCount, proj_args);
	}
	
	// free each C string in the arguments and the array itself
	for (int argIdx=0; argIdx<argumentCount; ++argIdx) {
		char* parameterAsCString = proj_args[argIdx];
		if (parameterAsCString) free(parameterAsCString);
	}
	free(proj_args);
	
	if (err) *err = proj_errno;
	
	return initializedProjPtr;
}


#pragma mark Data representation

static const CFIndex TLCFIndexMaxCompatible = INT_MAX;

static CFDataRef TLProjectionCreateCombinedDataRepresentation(CFArrayRef dataRepresentations) {
	CFMutableDataRef combinedData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	
	CFIndex currentPointerOffset = 0;
	bool combinationSuccessful = true;
	CFIndex numDataReps = CFArrayGetCount(dataRepresentations);
	for (CFIndex dataRepIdx = 0; dataRepIdx < numDataReps; ++dataRepIdx) {
		CFDataRef dataRep = CFArrayGetValueAtIndex(dataRepresentations, dataRepIdx);
		if ( CFGetTypeID(dataRep) != CFDataGetTypeID() ) {
			combinationSuccessful = false;
			break;
		}
		
		CFIndex dataRepLength = CFDataGetLength(dataRep);
		if (dataRepLength > TLCFIndexMaxCompatible) {
			// don't write data too large for platforms with smaller CFIndex ranges
			combinationSuccessful = false;
			break;
		}
		
		CFIndex totalRepSize = dataRepLength + sizeof(uint64_t);
		CFDataIncreaseLength(combinedData, totalRepSize);
		
		UInt8* dataPointer = CFDataGetMutableBytePtr(combinedData);
		dataPointer += currentPointerOffset;
		*(uint64_t*)dataPointer = CFSwapInt64HostToLittle(dataRepLength);
		dataPointer += sizeof(uint64_t);
		CFDataGetBytes(dataRep, CFRangeMake(0, dataRepLength), dataPointer);
		
		// NOTE: currentPointerOffset could overflow
		currentPointerOffset += totalRepSize;
	}
	
	if (!combinationSuccessful) {
		CFRelease(combinedData);
		combinedData = NULL;
	}
	
	return combinedData;
}

static CFArrayRef TLProjectionCreateSeparateDataRepresentations(CFDataRef combinedData) {
	CFMutableArrayRef dataRepresentations = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	
	CFIndex currentPointerOffset = 0;
	bool separationSuccessful = true;
	size_t combinedDataLength = (size_t)CFDataGetLength(combinedData);
	while (currentPointerOffset + sizeof(uint64_t) <= combinedDataLength) {
		const UInt8* dataPointer = CFDataGetBytePtr(combinedData);
		dataPointer += currentPointerOffset;
		
		// read supposed data length
		uint64_t dataRepSizeIn = (CFIndex)CFSwapInt64LittleToHost(*(const uint64_t*)dataPointer);
		dataPointer += sizeof(uint64_t);
		if (dataRepSizeIn > (size_t)TLCFIndexMax) {
			// avoid truncated argument to CFDataCreate
			separationSuccessful = false;
			break;
		}
		CFIndex dataRepLength = (CFIndex)dataRepSizeIn;
		CFIndex totalRepSize = dataRepLength + sizeof(uint64_t);
		
		// ensure remaining data really contains dataRepLength more bytes
		size_t requiredLength = currentPointerOffset + totalRepSize;
		if (requiredLength > combinedDataLength) {
			separationSuccessful = false;
			break;
		}
		
		CFDataRef dataRep = CFDataCreate(kCFAllocatorDefault, dataPointer, (CFIndex)dataRepLength);
		CFArrayAppendValue(dataRepresentations, dataRep);
		CFRelease(dataRep);
		
		// this won't overflow because combinedDataLength is not more than TLCFIndexMax
		currentPointerOffset += totalRepSize;
	}
	
	if (!separationSuccessful) {
		CFRelease(dataRepresentations);
		dataRepresentations = NULL;
	}
	
	return dataRepresentations;
}

CFDataRef TLProjectionCreateDataRepresentation(TLProjectionRef proj) {
	CFDataRef geoidData = TLProjectionGeoidCreateDataRepresentation(proj->geoid);
	CFDataRef paramsData = TLProjectionParametersCreateDataRepresentation(proj->params);
	CFDataRef nameData = TLProjectionNameCreateDataRepresentation(proj->name);
	
	CFMutableArrayRef dataRepresentations = CFArrayCreateMutable(kCFAllocatorDefault, 3, &kCFTypeArrayCallBacks);
	CFArrayAppendValue(dataRepresentations, nameData);
	CFArrayAppendValue(dataRepresentations, geoidData);
	CFArrayAppendValue(dataRepresentations, paramsData);
	CFRelease(geoidData);
	CFRelease(paramsData);
	CFRelease(nameData);
	
	CFDataRef combinedData = TLProjectionCreateCombinedDataRepresentation(dataRepresentations);
	CFRelease(dataRepresentations);
	return combinedData;
}

TLProjectionRef TLProjectionCreateFromDataRepresentation(CFDataRef projData) {
	CFArrayRef dataRepresentations = TLProjectionCreateSeparateDataRepresentations(projData);
	CFDataRef nameData = CFArrayGetValueAtIndex(dataRepresentations, 0);
	CFDataRef geoidData = CFArrayGetValueAtIndex(dataRepresentations, 1);
	CFDataRef paramsData = CFArrayGetValueAtIndex(dataRepresentations, 2);
	
	char* name = TLProjectionNameNewFromDataRepresentation(nameData);
	TLProjectionGeoidRef geoid = TLProjectionGeoidCreateFromDataRepresentation(geoidData);
	TLProjectionParametersRef params = TLProjectionParametersCreateFromDataRepresentation(paramsData);
	CFRelease(dataRepresentations);
	
	TLProjectionRef proj = TLProjectionCreate(name, geoid, params, NULL);
	TLProjectionGeoidRelease(geoid);
	TLProjectionParametersRelease(params);
	free(name);
	
	return proj;
}


#pragma mark Accessors

TLProjectionName TLProjectionGetName(TLProjectionRef proj) {
	return proj->name;
}

TLProjectionGeoidRef TLProjectionGetPlanetModel(TLProjectionRef proj) {
	return proj->geoid;
}

TLProjectionParametersRef TLProjectionGetParameters(TLProjectionRef proj) {
	return proj->params;
}


#pragma mark Projecting

CGPoint TLProjectionProjectCoordinate(TLProjectionRef proj, TLCoordinate coord, TLProjectionError* err) {
	//NSAssert2( isnormal(coord.lat) || coord.lat == 0.0, @"Can't project coordinate (%f, %f)\n", coord.lat, coord.lon);
	PROJ_LP coordToProject = { .lam = coord.lon * DEG_TO_RAD, .phi = coord.lat * DEG_TO_RAD };
	PROJ_XY projectedPoint = proj_fwd(coordToProject, proj->projPtr);
	if (err) *err = proj_errno;
	return CGPointMake((CGFloat)projectedPoint.x, (CGFloat)projectedPoint.y);
}

TLCoordinate TLProjectionUnprojectPoint(TLProjectionRef proj, CGPoint point, TLProjectionError* err) {
	//NSAssert(*proj->projPtr->inv, @"Projection must have an inverse!");
	PROJ_XY pointToUnproject = { .x = point.x, .y = point.y };
	PROJ_LP unprojectedCoordinate = proj_inv(pointToUnproject, proj->projPtr);
	if (err) *err = proj_errno;
	return TLCoordinateMake(unprojectedCoordinate.phi * RAD_TO_DEG, unprojectedCoordinate.lam * RAD_TO_DEG);
}
