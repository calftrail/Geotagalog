/*
 *  TLPointerArray.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/26/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLPOINTERARRAY_H
#define TLPOINTERARRAY_H

#include "TLPrimitiveTypes.h"

typedef const void* TLPointerItem;
typedef TLPointerItem (*TLPointerArrayItemRetainCallback)(TLPointerItem item);
typedef void (*TLPointerArrayItemReleaseCallback)(TLPointerItem item);
typedef TLCompareResult (*TLPointerArraySortCallback)(TLPointerItem item1, TLPointerItem item2, void* context);

#pragma mark Basic pointer array methods

typedef const struct TL_PointerArray* TLPointerArrayRef;

TLPointerArrayRef TLPointerArrayRetain(TLPointerArrayRef pointerArray);
void TLPointerArrayRelease(TLPointerArrayRef pointerArray);
TLPointerArrayRef TLPointerArrayCreateCopy(TLPointerArrayRef pointerArray);

tl_uint_t TLPointerArrayGetCount(TLPointerArrayRef pointerArray);
TLPointerItem TLPointerArrayGetItemAtIndex(TLPointerArrayRef pointerArray, tl_uint_t itemIndex);


#pragma mark Mutable array methods

typedef struct TL_PointerArray* TLMutablePointerArrayRef;

/* Both callbacks must be defined. */
TLMutablePointerArrayRef TLPointerArrayCreateMutable(tl_uint_t countLimit,
													 TLPointerArrayItemRetainCallback retainCallback,
													 TLPointerArrayItemReleaseCallback releaseCallback);

TLMutablePointerArrayRef TLPointerArrayCreateMutableCopy(TLPointerArrayRef pointerArray, tl_uint_t countLimit);

void TLPointerArrayAppendItem(TLMutablePointerArrayRef pointerArray, TLPointerItem item);
void TLPointerArrayAppendArray(TLMutablePointerArrayRef pointerArray, TLPointerArrayRef otherArray);

void TLPointerArrayRemoveItemAtIndex(TLMutablePointerArrayRef pointerArray, tl_uint_t itemIndex);

void TLPointerArraySort(TLMutablePointerArrayRef pointerArray, TLPointerArraySortCallback compareFunction, void* context);

#endif /* TLPOINTERARRAY_H */
