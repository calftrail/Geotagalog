/*
 *  TLProjectionParametersInternal.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/31/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */


extern CFStringRef const TLProjectionParametersLatOriginKey;
extern CFStringRef const TLProjectionParametersLonOriginKey;
extern CFStringRef const TLProjectionParametersStandardParallelKey;
extern CFStringRef const TLProjectionParametersStandardParallel1Key;
extern CFStringRef const TLProjectionParametersStandardParallel2Key;
extern CFStringRef const TLProjectionParametersProjNameKey;
extern CFStringRef const TLProjectionParametersEllipseNameKey;

CFIndex TLProjectionParametersGetCount(TLProjectionParametersRef projParams);
CFArrayRef TLProjectionParametersCreateAllKeysArray(TLProjectionParametersRef projParams);
CFTypeRef TLProjectionParametersGetValue(TLProjectionParametersRef projParams, CFTypeRef key);
void TLProjectionParametersSetValue(TLMutableProjectionParametersRef projParams, CFTypeRef key, CFTypeRef value);
TLCoordinateDegrees TLProjectionParametersGetDegreesForKey(TLProjectionParametersRef projParams, CFStringRef key, TLCoordinateDegrees defaultDegrees);
void TLProjectionParametersSetDegreesForKey(TLMutableProjectionParametersRef projParams, CFStringRef key, TLCoordinateDegrees degrees);
bool TLProjectionParametersKeyIsSet(TLMutableProjectionParametersRef projParams, CFStringRef key);

CFStringRef TLProjectionParametersCreateStringWithKey(TLProjectionParametersRef projParams, CFTypeRef key);
CFStringRef TLProjectionParametersCreateStringWithKeyAndValue(CFTypeRef key, CFTypeRef value);

bool TLProjectionParametersCreatePairFromString(CFStringRef formattedString, CFTypeRef* key, CFTypeRef* value);
