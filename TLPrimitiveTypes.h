/*
 *  TLPrimitiveTypes.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 5/19/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef TL_PRIMITIVE_TYPES
#define TL_PRIMITIVE_TYPES


typedef long tl_int_t;
typedef unsigned long tl_uint_t;

enum {
	TLCompareLessThan = -1,
	TLCompareEqual = 0,
	TLCompareGreaterThan = 1
};
typedef int TLCompareResult;

// inline macros (tidied from Apple's CGBase.h)
#if !defined(TL_INLINE)
#  if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#    define TL_INLINE static inline
#  elif defined(__cplusplus)
#    define TL_INLINE static inline
#  elif defined(__GNUC__)
#    define TL_INLINE static __inline__
#  else
#    define TL_INLINE static    
#  endif
#endif

TL_INLINE tl_uint_t TLTableIndex(tl_uint_t x, tl_uint_t y, tl_uint_t rowWidth);
TL_INLINE tl_uint_t TLNextPowerOfTwo(tl_uint_t number);

/* Use Cocoa definition for CGFloat, CGPoint, CGRect and CGAffineTransform. The structure
 types could optionally be forward declared as structs of the same name.
 
 NOTE: For maximum portability, all of these types could wrap/typedef a changeable base.
 Example: TLAffineTransform would be a typedef, and inline wrappers would be provided
 for all CGAffineTransform functions used.
 */
#import <ApplicationServices/ApplicationServices.h>

static const tl_uint_t TLCFIndexMax = LONG_MAX;

#define TLBooleanCast !!

tl_uint_t TLTableIndex(tl_uint_t x, tl_uint_t y, tl_uint_t rowWidth) {
    return (y * rowWidth) + x;
}

/*
 Returns the closest power-of-two number greater or equal to n for the given (unsigned) integer n.
 Will return 0 when n = 0 and 1 when n = 1.
 
 See thread: http://lists.freebsd.org/pipermail/freebsd-current/2007-February/069088.html
 ( this implementation based on http://osdir.com/ml/audio.devel/2003-09/msg00199.html )
 */
tl_uint_t TLNextPowerOfTwo(tl_uint_t number) {
	uint64_t n = number;
	--n;
	n |= n >> 32;
	n |= n >> 16;
	n |= n >> 8;
	n |= n >> 4;
	n |= n >> 2;
	n |= n >> 1;
	++n;
	return (tl_uint_t)n;
}

#endif // TL_PRIMITIVE_TYPES
