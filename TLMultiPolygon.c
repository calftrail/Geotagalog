/*
 *  TLMultiPolygon.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/18/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLMultiPolygon.h"

#include "TLPointerArray.h"

static const void* TLMultiPolygonRetainCallback(const void* item) {
	return TLPolygonRetain((TLPolygonRef)item);
}

static void TLMultiPolygonReleaseCallback(const void* item) {
	return TLPolygonRelease((TLPolygonRef)item);
}

TLMutableMultiPolygonRef TLMultiPolygonCreateMutable(tl_uint_t countLimit) {
	return (TLMutableMultiPolygonRef)TLPointerArrayCreateMutable(countLimit,
																 TLMultiPolygonRetainCallback,
																 TLMultiPolygonReleaseCallback);
}

TLMultiPolygonRef TLMultiPolygonCreateFromPolygon(TLPolygonRef singlePolygon) {
	TLMutableMultiPolygonRef multiPolygon = TLMultiPolygonCreateMutable(1);
	TLMultiPolygonAppendPolygon(multiPolygon, singlePolygon);
	return multiPolygon;
}


TLMultiPolygonRef TLMultiPolygonRetain(TLMultiPolygonRef multiPoly) {
	return (TLMultiPolygonRef)TLPointerArrayRetain((TLPointerArrayRef)multiPoly);
}

void TLMultiPolygonRelease(TLMultiPolygonRef multiPoly) {
	TLPointerArrayRelease((TLPointerArrayRef)multiPoly);
}

tl_uint_t TLMultiPolygonGetCount(TLMultiPolygonRef multiPoly) {
	return TLPointerArrayGetCount((TLPointerArrayRef)multiPoly);
}

TLPolygonRef TLMultiPolygonGetPolygon(TLMultiPolygonRef multiPoly, tl_uint_t polygonIndex) {
	return (TLPolygonRef)TLPointerArrayGetItemAtIndex((TLPointerArrayRef)multiPoly, polygonIndex);
}

void TLMultiPolygonAppendPolygon(TLMutableMultiPolygonRef multiPoly, TLPolygonRef polygon) {
	TLPointerArrayAppendItem((TLMutablePointerArrayRef)multiPoly, polygon);
}
