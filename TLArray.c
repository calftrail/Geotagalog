/*
 *  TLArray.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 5/19/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLArray.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "TLToolbag.h"

struct TL_Array {
	tl_uint_t retainCount;
	void* items;
	tl_uint_t itemSize;
	tl_uint_t itemCount;
	tl_uint_t currentAllocatedLimit;
	tl_uint_t hardItemCountLimit;
};

typedef enum {
	TLArrayInternalSuccess = 0,
	TLArrayInternalLimitReached,
	TLArrayInternalNoMemory
} TLArrayInternalError;

TLMutableArrayRef TLArrayCreateMutable(tl_uint_t itemSize, tl_uint_t countLimit) {
	TLMutableArrayRef newArray = (TLMutableArrayRef)malloc( sizeof(struct TL_Array) );
	if (newArray) {
		newArray->retainCount = 1;
		
		// Set up item storage and parameters
		newArray->itemSize = itemSize;
		newArray->itemCount = 0;
		newArray->hardItemCountLimit = countLimit;
		// If there's no hard limit, begin with a reasonable initial size
		tl_uint_t itemsToAllocate = countLimit ? countLimit : 4;
		newArray->currentAllocatedLimit = itemsToAllocate;
		newArray->items = malloc(itemsToAllocate*itemSize);
	}
	if (newArray && !newArray->items) {
		free(newArray);
		newArray = NULL;
	}
	return newArray;
}

TLMutableArrayRef TLArrayCreateMutableCopy(TLArrayRef oldArray) {
	TLMutableArrayRef newArray = TLArrayCreateMutable(oldArray->itemSize, oldArray->hardItemCountLimit);
	if (newArray) {
		TLArrayAppendArray(newArray, oldArray);
	}
	return newArray;
}

TLArrayRef TLArrayCreateCopy(TLArrayRef oldArray) {
	return TLArrayCreateMutableCopy(oldArray);
}

static TLArrayInternalError TLArrayCanEnsureAdditionalSpace(TLMutableArrayRef array, tl_uint_t extraItemCount) {
	tl_uint_t necessaryLimit = array->itemCount + extraItemCount;
	if (array->hardItemCountLimit && (necessaryLimit > array->hardItemCountLimit)) {
		return TLArrayInternalLimitReached;
	}
	if (array->currentAllocatedLimit < necessaryLimit) {
		tl_uint_t paddedLimit = TLNextPowerOfTwo(necessaryLimit);
		void* newItems = realloc(array->items, paddedLimit*(array->itemSize));
		if (!newItems) {		// try again with just necessaryLimit
			paddedLimit = necessaryLimit;
			newItems = realloc(array->items, paddedLimit*(array->itemSize));
		}
		if (!newItems) return TLArrayInternalNoMemory;
		array->currentAllocatedLimit = paddedLimit;
		array->items = newItems;
	}
	return TLArrayInternalSuccess;
}

static void TLArrayVacuumExtraSpace(TLMutableArrayRef array) {
	if (array->hardItemCountLimit) return;
	tl_uint_t acceptablePaddedSize = TLNextPowerOfTwo(array->itemCount);
	if (array->currentAllocatedLimit > acceptablePaddedSize) {
		void* shrunkItems = realloc(array->items, acceptablePaddedSize*(array->itemSize));
		if (shrunkItems) {
			array->currentAllocatedLimit = acceptablePaddedSize;
			array->items = shrunkItems;
		}
	}
}

static void TLArrayDestroy(TLMutableArrayRef array) {
	free(array->items);
	free(array);
}

TLArrayRef TLArrayRetain(TLArrayRef array) {
	TLMutableArrayRef mutableArray = (TLMutableArrayRef)array;
	mutableArray->retainCount += 1;
	return array;
}

void TLArrayRelease(TLArrayRef array) {
	if (!array) return;
	TLMutableArrayRef mutableArray = (TLMutableArrayRef)array;
	mutableArray->retainCount -= 1;
	if (!mutableArray->retainCount) TLArrayDestroy(mutableArray);
}

tl_uint_t TLArrayGetCount(TLArrayRef array) {
	return array->itemCount;
}

TL_INLINE tl_uint_t TLArrayGetItemSize(TLArrayRef array) {
	return array->itemSize;
}

static inline void* TLArrayGetItemPointer(TLArrayRef array, tl_uint_t itemIndex) {
	tl_uint_t itemOffset = itemIndex * TLArrayGetItemSize(array);
	return array->items + itemOffset;
}

const void* TLArrayGetItemAtIndex(TLArrayRef array, tl_uint_t itemIndex) {
	return TLArrayGetItemPointer(array, itemIndex);
}

static void TLArraySetExistingItem(TLMutableArrayRef mutableArray, tl_uint_t itemIdx, const void* itemPtr) {
	void* targetItemLocation = TLArrayGetItemPointer(mutableArray, itemIdx);
	memmove(targetItemLocation, itemPtr, TLArrayGetItemSize(mutableArray));
}

static void TLFailIfError(TLArrayInternalError status) {
	TLAssert(status != TLArrayInternalLimitReached, "Too many items for fixed-size array!");
	if (status == TLArrayInternalNoMemory) {
		TLOutOfMemoryBail();
	}
	TLAssert(status == TLArrayInternalSuccess, "Unknown internal array error '%i'.", status);
}

static bool TLArraysAreCompatible(TLArrayRef array1, TLArrayRef array2) {
	bool arrayItemsCompatible = (TLArrayGetItemSize(array1) == TLArrayGetItemSize(array2));
	return arrayItemsCompatible;
}

// Append an item, assuming that there is enough space
TL_INLINE void TLArrayDoAppending(TLMutableArrayRef mutableArray, const void* item) {
	tl_uint_t newIdx = mutableArray->itemCount;
	mutableArray->itemCount += 1;
	TLArraySetExistingItem(mutableArray, newIdx, item);
}

void TLArrayAppendItem(TLMutableArrayRef mutableArray, const void* item) {
	TLArrayInternalError canAdd = TLArrayCanEnsureAdditionalSpace(mutableArray, 1);
	TLFailIfError(canAdd);
	TLArrayDoAppending(mutableArray, item);
}

void TLArrayAppendArray(TLMutableArrayRef mutableArray, TLArrayRef otherArray) {
	bool canAppendCompatibly = TLArraysAreCompatible(mutableArray, otherArray);
	TLAssert(canAppendCompatibly, "Appended array must be compatible.");
	tl_uint_t otherArraySize = TLArrayGetCount(otherArray);
	TLArrayInternalError canAdd = TLArrayCanEnsureAdditionalSpace(mutableArray, otherArraySize);
	TLFailIfError(canAdd);
	
	// copy the items in bulk
	tl_uint_t firstDestinationIdx = TLArrayGetCount(mutableArray);
	void* destLocation = TLArrayGetItemPointer(mutableArray, firstDestinationIdx);
	const void* sourceLocation = TLArrayGetItemPointer(otherArray, 0);
	memmove(destLocation, sourceLocation, otherArraySize * TLArrayGetItemSize(mutableArray));
	mutableArray->itemCount += otherArraySize;
}

void TLArrayRemoveItemAtIndex(TLMutableArrayRef array, tl_uint_t removedItemIdx) {
	void* removedItemLocation = TLArrayGetItemPointer(array, removedItemIdx);
	
	// shift items down
	tl_uint_t nextItemIdx = removedItemIdx + 1;
	tl_uint_t originalCount = TLArrayGetCount(array);
	if (nextItemIdx < originalCount) {
		const void* nextItemLocation = TLArrayGetItemPointer(array, nextItemIdx);
		tl_uint_t numItemsPastMovedItem = originalCount - nextItemIdx;
		memmove(removedItemLocation, nextItemLocation, numItemsPastMovedItem * TLArrayGetItemSize(array));
	}
	
	// update bookkeeping
	array->itemCount -= 1;
	TLArrayVacuumExtraSpace(array);
}


typedef struct {
	TLArraySortCallback realCallback;
	void* realContext;
} TLArrayCompareContext;

static TLCompareResult TLArraySortCallbackWrapper(void* context, const void* item1, const void* item2) {
	TLArrayCompareContext* wrappedContext = (TLArrayCompareContext*)context;
	TLArraySortCallback compareFunction = wrappedContext->realCallback;
	void* compareContext = wrappedContext->realContext;
	return compareFunction(item1, item2, compareContext);
}

void TLArraySort(TLMutableArrayRef array, TLArraySortCallback compareFunction, void* compareContext) {
	TLArrayCompareContext wrappedContext = {
		.realCallback = compareFunction,
		.realContext = compareContext
	};
	qsort_r(array->items, array->itemCount, array->itemSize, &wrappedContext, TLArraySortCallbackWrapper);
}
