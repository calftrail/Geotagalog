/*
 *  TLArrayTemplate.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/18/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */


/*
 
 This header file allows its user to create a typesafe "templated" specialized set of array wrapper functions. All that needs
 to be done on the user's part is to include any header necessary for the wrapped type, and define the following preprocessor macros:
   TLATCollectionName is the name the collection will have.
   TLATMutableCollectionName is SOMEWHAT OPTIONAL. If undefined, the user will not currently be able to create useful collections.
   TLATCollectedItemType is the typename of the wrapped item.
   TLATCollectedItemAlias is OPTIONAL. If defined, it replaces TLATCollectedItemType in function names.
 
 For example:
   #include "CGPoint.h"
   #define TLATCollectionName TLPolygon
   #define TLATCollectedItemType CGPoint
   #define TLATCollectedItemAlias Point
   #include "TLArrayTemplate.h"
 Will result in a complete set of array wrappers similar to the following examples:
   TLPolygonRef TLPolygonCreate(tl_nsuint_t countLimit);
   CGPoint TLPolygonGetPointAtIndex(TLPolygonRef collection, tl_nsuint_t itemIndex);
 Generated to wrap respectively (without loss of generality; all basic array functions are wrapped):
   TLArrayRef TLArrayCreate(tl_nsuint_t itemSize, tl_nsuint_t countLimit);
   const void* TLArrayGetItemAtIndex(TLArrayRef array, tl_nsuint_t itemIndex);
 
 This header may be used repeatedly, even within a single compilation unit:
   #define TLATCollectionName MyNumberArray
   #define TLATCollectedItemType double
   #include "TLArrayTemplate.h"
   #define TLATCollectionName MyPointerCollection
   #define TLATCollectedItemType void*
   #include "TLArrayTemplate.h"
 Will generate wrapper functions for both MyNumberArrayRef and MyPointerCollectionRef. Both generated collection types will be distinct.
 
 If you need to set up callbacks, define TLATSuppressCreateFunction, and provide your own wrapper around TLArrayCreate instead.
 */


#include "TLArray.h"

#pragma mark Macro setup

#ifndef TLATCollectionName
#  error TLATCollectionName must be defined for TLArrayTemplate header to expand correctly.
#endif

#ifndef TLATCollectedItemType
#  error TLATCollectedItemType must be defined for TLArrayTemplate header to expand correctly.
#endif

#define TLAT_REFTO(x) x ## Ref
#define TLAT_XREFTO(x) TLAT_REFTO(x)		// arguments are not macro expanded if they're concatenated, thus this
#define TLATCollectionRef TLAT_XREFTO(TLATCollectionName)

#ifdef TLATMutableCollectionName
#  define TLATMutableCollectionRef TLAT_XREFTO(TLATMutableCollectionName)
#endif

// Generate a typename like "struct _TLATCollectionName *" ("_TLATCollectionName*" is not a valid preprocessing token, thus the space)
#define TLAT_OPAQUETYPE(x) struct _ ## x *
#define TLAT_XOPAQUETYPE(x) TLAT_OPAQUETYPE(x)
#define TLATCollectionOpaqueType TLAT_XOPAQUETYPE(TLATCollectionName)

#define TLAT_UNX_COLLFUNCTION(collection, name) collection ## name
#define TLAT_XCOLLFUNCTION(collection, name) TLAT_UNX_COLLFUNCTION(collection, name)
#define TLAT_COLLFUNCTION(name) TLAT_XCOLLFUNCTION(TLATCollectionName, name)

#define TLAT_CONCAT(a, b)  a ## b
#define TLAT_XCONCAT(a, b) TLAT_CONCAT(a, b)

#define TLAT_UNX_COLLFUNCTION_ALIAS(collection, name) collection ## name
#define TLAT_XCOLLFUNCTION_ALIAS(collection, name) TLAT_UNX_COLLFUNCTION_ALIAS(collection, name)
#ifdef TLATCollectedItemAlias
#  define TLAT_COLLFUNCTION_ALIAS(name) TLAT_XCOLLFUNCTION_ALIAS(TLATCollectionName, TLAT_XCONCAT(name, TLATCollectedItemAlias))
#else
#  define TLAT_COLLFUNCTION_ALIAS(name) TLAT_XCOLLFUNCTION_ALIAS(TLATCollectionName, TLAT_XCONCAT(name, TLATCollectedItemType))
#endif


#pragma mark Opaque type definition(s)

// These enable type safety warnings from the compiler. The opaque type is never defined, but makes the CollectionRef a distinct type.
typedef const TLATCollectionOpaqueType TLATCollectionRef;
#ifdef TLATMutableCollectionRef
  typedef TLATCollectionOpaqueType TLATMutableCollectionRef;
#endif


#pragma mark Immutable wrappers

TL_INLINE TLATCollectionRef TLAT_COLLFUNCTION(CreateCopy) (TLATCollectionRef collection) {
	return (TLATCollectionRef)TLArrayCreateCopy((TLArrayRef)collection);
}

TL_INLINE TLATCollectionRef TLAT_COLLFUNCTION(Retain) (TLATCollectionRef collection) {
	return (TLATCollectionRef)TLArrayRetain((TLArrayRef)collection);
}

TL_INLINE void TLAT_COLLFUNCTION(Release) (TLATCollectionRef collection) {
	TLArrayRelease((TLArrayRef)collection);
}

TL_INLINE tl_uint_t TLAT_COLLFUNCTION(GetCount) (TLATCollectionRef collection) {
	return TLArrayGetCount((TLArrayRef)collection);
}

TL_INLINE TLATCollectedItemType TLAT_COLLFUNCTION_ALIAS(Get) (TLATCollectionRef collection, tl_uint_t itemIndex) {
	return *(TLATCollectedItemType*)TLArrayGetItemAtIndex((TLArrayRef)collection, itemIndex);
}


#pragma mark Mutable wrappers

#ifndef TLATSuppressCreateFunction 
#  ifdef TLATMutableCollectionRef
    TL_INLINE TLATMutableCollectionRef TLAT_COLLFUNCTION(CreateMutable) (tl_uint_t sizeLimit) {
		return (TLATMutableCollectionRef)TLArrayCreateMutable(sizeof(TLATCollectedItemType), sizeLimit);
    }
#  endif
#else
#  undef TLATSuppressCreateFunction
#endif

#ifdef TLATMutableCollectionRef
  TL_INLINE TLATMutableCollectionRef TLAT_COLLFUNCTION(CreateMutableCopy) (TLATCollectionRef collection) {
	  return (TLATMutableCollectionRef)TLArrayCreateMutableCopy((TLArrayRef)collection);
  }
#endif

#ifdef TLATMutableCollectionRef
  TL_INLINE void TLAT_COLLFUNCTION_ALIAS(Append) (TLATMutableCollectionRef collection, TLATCollectedItemType item) {
	  TLArrayAppendItem((TLMutableArrayRef)collection, &item);
  }
#endif


#pragma mark Macro cleanup

// clean up user definitions
#undef TLATCollectionName
#ifdef TLATMutableCollectionName
#  undef TLATMutableCollectionName
#endif
#undef TLATCollectedItemType
#ifdef TLATCollectedItemAlias
#  undef TLATCollectedItemAlias
#endif

// clean up internal definitions
#undef TLATCollectionRef
#ifdef TLATMutableCollectionRef
#  undef TLATMutableCollectionRef
#endif
#undef TLATCollectionOpaqueType
#undef TLAT_REFTO
#undef TLAT_XREFTO
#undef TLAT_OPAQUETYPE
#undef TLAT_XOPAQUETYPE
#undef TLAT_UNX_COLLFUNCTION
#undef TLAT_XCOLLFUNCTION
#undef TLAT_COLLFUNCTION
#undef TLAT_CONCAT
#undef TLAT_XCONCAT
#undef TLAT_UNX_COLLFUNCTION_ALIAS
#undef TLAT_XCOLLFUNCTION_ALIAS
#undef TLAT_COLLFUNCTION_ALIAS
