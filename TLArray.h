/*
 *  TLArray.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 5/19/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TLARRAY_H
#define TLARRAY_H

#include "TLPrimitiveTypes.h"

typedef TLCompareResult (*TLArraySortCallback)(const void* item1, const void* item2, void* context);

#pragma mark Basic array methods

typedef const struct TL_Array* TLArrayRef;

TLArrayRef TLArrayCreateCopy(TLArrayRef array);
TLArrayRef TLArrayRetain(TLArrayRef array);
void TLArrayRelease(TLArrayRef array);

tl_uint_t TLArrayGetCount(TLArrayRef array);
const void* TLArrayGetItemAtIndex(TLArrayRef array, tl_uint_t itemIndex);


#pragma mark Mutable array methods

typedef struct TL_Array* TLMutableArrayRef;

TLMutableArrayRef TLArrayCreateMutable(tl_uint_t itemSize, tl_uint_t countLimit);

TLMutableArrayRef TLArrayCreateMutableCopy(TLArrayRef array);

void TLArrayAppendItem(TLMutableArrayRef array, const void* item);
void TLArrayAppendArray(TLMutableArrayRef array, TLArrayRef otherArray);

void TLArrayRemoveItemAtIndex(TLMutableArrayRef array, tl_uint_t itemIndex);

void TLArraySort(TLMutableArrayRef array, TLArraySortCallback compareFunction, void* context);

#endif /* TLARRAY_H */
