/*
 *  TLMultiCoordPolygon.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLMULTICOORDPOLYGON_H
#define TLMULTICOORDPOLYGON_H

#include "TLCoordPolygon.h"

typedef const struct TL_CoordPolygon* TLMultiCoordPolygonRef;

TLMultiCoordPolygonRef TLMultiCoordPolygonRetain(TLMultiCoordPolygonRef multiCoordPoly);
void TLMultiCoordPolygonRelease(TLMultiCoordPolygonRef multiCoordPoly);

TLMultiCoordPolygonRef TLMultiCoordPolygonCreateFromPolygon(TLCoordPolygonRef coordPoly);
TLMultiCoordPolygonRef TLMultiCoordPolygonCreateCopy(TLMultiCoordPolygonRef multiCoordPoly);

tl_uint_t TLMultiCoordPolygonGetCount(TLMultiCoordPolygonRef multiCoordPoly);
TLCoordPolygonRef TLMultiCoordPolygonGetPolygon(TLMultiCoordPolygonRef multiCoordPoly, tl_uint_t polygonIndex);


typedef const struct TL_CoordPolygon* TLMutableMultiCoordPolygonRef;

TLMutableMultiCoordPolygonRef TLMultiCoordPolygonCreateMutable(tl_uint_t countLimit);
void TLMultiCoordPolygonAppendPolygon(TLMutableMultiCoordPolygonRef multiCoordPoly, TLCoordPolygonRef coordPoly);

#endif /* TLMULTICOORDPOLYGON_H */
