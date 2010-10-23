/*
 *  TLMultiPolygon.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/18/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLMULTIPOLYGON_H
#define TLMULTIPOLYGON_H

#include "TLPolygon.h"

typedef const struct TL_MultiPolygon* TLMultiPolygonRef;

TLMultiPolygonRef TLMultiPolygonRetain(TLMultiPolygonRef multiPoly);
void TLMultiPolygonRelease(TLMultiPolygonRef multiPoly);

TLMultiPolygonRef TLMultiPolygonCreateFromPolygon(TLPolygonRef singlePolygon);

tl_uint_t TLMultiPolygonGetCount(TLMultiPolygonRef multiPoly);
TLPolygonRef TLMultiPolygonGetPolygon(TLMultiPolygonRef multiPoly, tl_uint_t polygonIndex);


typedef struct TL_MultiPolygon* TLMutableMultiPolygonRef;

TLMutableMultiPolygonRef TLMultiPolygonCreateMutable(tl_uint_t countLimit);
void TLMultiPolygonAppendPolygon(TLMutableMultiPolygonRef multiPoly, TLPolygonRef polygon);

#endif /* TLMULTIPOLYGON_H */
