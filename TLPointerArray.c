/*
 *  TLPointerArray.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/26/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLPointerArray.h"



#pragma mark Custom allocator for callback wrapping

static void* TLArrayAllocateCB(CFIndex allocSize, CFOptionFlags hint, void *info) {
	(void)hint;
	(void)info;
	return malloc(allocSize);
}

static void* TLArrayReallocateCB(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info) {
	(void)hint;
	(void)info;
	if (!ptr || !(newsize>0)) return NULL;
	return realloc(ptr, newsize);
}

static void TLArrayDeallocateCB(void *ptr, void *info) {
	(void)info;
	free(ptr);
}

typedef struct {
	TLPointerArrayItemRetainCallback retainItem;
	TLPointerArrayItemReleaseCallback releaseItem;
} TLPointerArrayAllocatorInfo;

static TLPointerArrayAllocatorInfo* TLPointerArrayCreateAllocatorInfoRef(TLPointerArrayItemRetainCallback retainCallback,
																		 TLPointerArrayItemReleaseCallback releaseCallback)
{
	TLPointerArrayAllocatorInfo* allocatorInfoRef = (TLPointerArrayAllocatorInfo*)malloc(sizeof(TLPointerArrayAllocatorInfo));
	allocatorInfoRef->retainItem = retainCallback;
	allocatorInfoRef->releaseItem = releaseCallback;
	return allocatorInfoRef;
}

static void TLPointerArrayDestroyAllocatorInfoRef(const void* context) {
	free((TLPointerArrayAllocatorInfo*)context);
}

static CFAllocatorRef TLPointerArrayCreateAllocatorForCallbacks(TLPointerArrayItemRetainCallback retainCallback,
																TLPointerArrayItemReleaseCallback releaseCallback)
{
	TLPointerArrayAllocatorInfo* allocatorInfo = TLPointerArrayCreateAllocatorInfoRef(retainCallback, releaseCallback);
	CFAllocatorContext context =
	{
		.version = 0,
		.info = allocatorInfo,
		.retain = NULL,
		.release = TLPointerArrayDestroyAllocatorInfoRef,
		.copyDescription = NULL,
		.allocate = TLArrayAllocateCB,
		.reallocate = TLArrayReallocateCB,
		.deallocate = TLArrayDeallocateCB,
		.preferredSize = NULL
	};
	return CFAllocatorCreate(kCFAllocatorDefault, &context);
}


#pragma mark Array callback wrappers

static TLPointerItem TLPointerArrayRetainCallbackWrapper(CFAllocatorRef allocator, TLPointerItem item) {
	CFAllocatorContext context;
	CFAllocatorGetContext(allocator, &context);
	TLPointerArrayAllocatorInfo* allocatorInfoRef = (TLPointerArrayAllocatorInfo*)context.info;
	return allocatorInfoRef->retainItem(item);
}

static void TLPointerArrayReleaseCallbackWrapper(CFAllocatorRef allocator, TLPointerItem item) {
	CFAllocatorContext context;
	CFAllocatorGetContext(allocator, &context);
	TLPointerArrayAllocatorInfo* allocatorInfoRef = (TLPointerArrayAllocatorInfo*)context.info;
	allocatorInfoRef->releaseItem(item);
}

static inline CFArrayCallBacks TLPointerArrayGetCallbacks() {
	CFArrayCallBacks callbacks = {
		.version = 0,
		.retain = TLPointerArrayRetainCallbackWrapper,
		.release = TLPointerArrayReleaseCallbackWrapper,
		.copyDescription = NULL,
		.equal = NULL
	};
	return callbacks;
}


#pragma mark Array wrappers

TLPointerArrayRef TLPointerArrayRetain(TLPointerArrayRef array) {
	return (TLPointerArrayRef)CFRetain((CFArrayRef)array);
}

void TLPointerArrayRelease(TLPointerArrayRef array) {
	if (!array) return;
	CFRelease((CFArrayRef)array);
}

TLPointerArrayRef TLPointerArrayCreateCopy(TLPointerArrayRef pointerArray) {
	CFAllocatorRef arrayAllocator = CFGetAllocator((CFArrayRef)pointerArray);
	return (TLPointerArrayRef)CFArrayCreateCopy(arrayAllocator, (CFArrayRef)pointerArray);
}

tl_uint_t TLPointerArrayGetCount(TLPointerArrayRef pointerArray) {
	return CFArrayGetCount((CFArrayRef)pointerArray);
}

TLPointerItem TLPointerArrayGetItemAtIndex(TLPointerArrayRef pointerArray, tl_uint_t itemIndex) {
	return CFArrayGetValueAtIndex((CFArrayRef)pointerArray, itemIndex);
}


#pragma mark Mutable array wrappers

TLMutablePointerArrayRef TLPointerArrayCreateMutable(tl_uint_t countLimit,
													 TLPointerArrayItemRetainCallback retainCallback,
													 TLPointerArrayItemReleaseCallback releaseCallback)
{
	if (countLimit > TLCFIndexMax) return NULL;
	CFAllocatorRef arrayAllocator = TLPointerArrayCreateAllocatorForCallbacks(retainCallback, releaseCallback);
	CFArrayCallBacks callbacks = TLPointerArrayGetCallbacks();
	CFMutableArrayRef mutableArray = CFArrayCreateMutable(arrayAllocator, countLimit, &callbacks);
	CFRelease(arrayAllocator);
	return (TLMutablePointerArrayRef)mutableArray;
}

TLMutablePointerArrayRef TLPointerArrayCreateMutableCopy(TLPointerArrayRef pointerArray, tl_uint_t countLimit) {
	if (countLimit > TLCFIndexMax) return NULL;
	CFAllocatorRef arrayAllocator = CFGetAllocator((CFArrayRef)pointerArray);
	return (TLMutablePointerArrayRef)CFArrayCreateMutableCopy(arrayAllocator, countLimit, (CFArrayRef)pointerArray);
}

void TLPointerArrayAppendItem(TLMutablePointerArrayRef pointerArray, TLPointerItem item) {
	CFArrayAppendValue((CFMutableArrayRef)pointerArray, item);
}

void TLPointerArrayAppendArray(TLMutablePointerArrayRef pointerArray, TLPointerArrayRef otherArray) {
	CFRange otherRange = CFRangeMake(0, TLPointerArrayGetCount(otherArray));
	CFArrayAppendArray((CFMutableArrayRef)pointerArray, (CFArrayRef)otherArray, otherRange);
}

void TLPointerArrayRemoveItemAtIndex(TLMutablePointerArrayRef pointerArray, tl_uint_t itemIndex) {
	CFArrayRemoveValueAtIndex((CFMutableArrayRef)pointerArray, itemIndex);
}

typedef struct {
	TLPointerArraySortCallback realCallback;
	void* realContext;
} TLPointerArrayCompareContext;

static CFIndex TLPointerArraySortCallbackWrapper(TLPointerItem item1, TLPointerItem item2, void* context) {
	TLPointerArrayCompareContext* wrappedContext = (TLPointerArrayCompareContext*)context;
	TLPointerArraySortCallback compareFunction = wrappedContext->realCallback;
	void* compareContext = wrappedContext->realContext;
	return (CFIndex)compareFunction(item1, item2, compareContext);
}

void TLPointerArraySort(TLMutablePointerArrayRef pointerArray, TLPointerArraySortCallback compareFunction, void* context) {
	CFRange sortRange = CFRangeMake(0, TLPointerArrayGetCount(pointerArray));
	TLPointerArrayCompareContext wrappedContext = {
		.realCallback = compareFunction,
		.realContext = context
	};
	CFArraySortValues((CFMutableArrayRef)pointerArray, sortRange, TLPointerArraySortCallbackWrapper, &wrappedContext);
}
