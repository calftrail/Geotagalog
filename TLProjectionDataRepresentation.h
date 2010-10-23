/*
 *  TLProjectionDataRepresentation.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLPROJECTIONDATAREPRESENTATION_H
#define TLPROJECTIONDATAREPRESENTATION_H

#include <CoreFoundation/CFData.h>

#include "TLProjection.h"


CFDataRef TLProjectionCreateDataRepresentation(TLProjectionRef proj);
TLProjectionRef TLProjectionCreateFromDataRepresentation(CFDataRef projData);

CFDataRef TLProjectionGeoidCreateDataRepresentation(TLProjectionGeoidRef projGeoid);
TLProjectionGeoidRef TLProjectionGeoidCreateFromDataRepresentation(CFDataRef projGeoidData);

CFDataRef TLProjectionParametersCreateDataRepresentation(TLProjectionParametersRef projParams);
TLProjectionParametersRef TLProjectionParametersCreateFromDataRepresentation(CFDataRef projParamsData);

#endif /* TLPROJECTIONDATAREPRESENTATION_H */
