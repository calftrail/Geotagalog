/*
 *  TLMultiCoordPolygon.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 7/1/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLMultiCoordPolygon.h"

#include "TLPointerArray.h"

static const void* TLMultiCoordPolygonRetainCallback(const void* item) {
	return TLCoordPolygonRetain((TLCoordPolygonRef)item);
}

static void TLMultiCoordPolygonReleaseCallback(const void* item) {
	return TLCoordPolygonRelease((TLCoordPolygonRef)item);
}

TLMutableMultiCoordPolygonRef TLMultiCoordPolygonCreateMutable(tl_uint_t countLimit) {
	return (TLMutableMultiCoordPolygonRef)TLPointerArrayCreateMutable(countLimit,
																	  TLMultiCoordPolygonRetainCallback,
																	  TLMultiCoordPolygonReleaseCallback);
}

TLMultiCoordPolygonRef TLMultiCoordPolygonCreateFromPolygon(TLCoordPolygonRef singleCoordPolygon) {
	TLMutableMultiCoordPolygonRef multiCoordPolygon = TLMultiCoordPolygonCreateMutable(1);
	TLMultiCoordPolygonAppendPolygon(multiCoordPolygon, singleCoordPolygon);
	return multiCoordPolygon;
}

TLMultiCoordPolygonRef TLMultiCoordPolygonRetain(TLMultiCoordPolygonRef multiCoordPoly) {
	return (TLMultiCoordPolygonRef)TLPointerArrayRetain((TLPointerArrayRef)multiCoordPoly);
}

void TLMultiCoordPolygonRelease(TLMultiCoordPolygonRef multiCoordPoly) {
	TLPointerArrayRelease((TLPointerArrayRef)multiCoordPoly);
}

TLMultiCoordPolygonRef TLMultiCoordPolygonCreateCopy(TLMultiCoordPolygonRef multiCoordPoly) {
	return (TLMultiCoordPolygonRef)TLPointerArrayCreateCopy((TLPointerArrayRef)multiCoordPoly);
}

tl_uint_t TLMultiCoordPolygonGetCount(TLMultiCoordPolygonRef multiCoordPoly) {
	return TLPointerArrayGetCount((TLPointerArrayRef)multiCoordPoly);
}

TLCoordPolygonRef TLMultiCoordPolygonGetPolygon(TLMultiCoordPolygonRef multiCoordPoly, tl_uint_t polygonIndex) {
	return (TLCoordPolygonRef)TLPointerArrayGetItemAtIndex((TLPointerArrayRef)multiCoordPoly, polygonIndex);
}

void TLMultiCoordPolygonAppendPolygon(TLMutableMultiCoordPolygonRef multiCoordPoly, TLCoordPolygonRef coordPoly) {
	TLPointerArrayAppendItem((TLMutablePointerArrayRef)multiCoordPoly, coordPoly);
}
