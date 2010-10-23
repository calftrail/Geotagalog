/*
 *  TLFloat.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLFLOAT_H
#define TLFLOAT_H

#include "TLPrimitiveTypes.h"

// a == b
TL_INLINE bool TLFloatEqual(double a, double b);
bool TLFloatEqualTol(double a, double b, double tolerance);

// a < b
TL_INLINE bool TLFloatLessThan(double a, double b);
bool TLFloatLessThanTol(double a, double b, double tolerance);

// a > b
TL_INLINE bool TLFloatGreaterThan(double a, double b);
bool TLFloatGreaterThanTol(double a, double b, double tolerance);

// a <= b
TL_INLINE bool TLFloatLessThanOrEqual(double a, double b);
bool TLFloatLessThanOrEqualTol(double a, double b, double tolerance);

// a >= b
TL_INLINE bool TLFloatGreaterThanOrEqual(double a, double b);
bool TLFloatGreaterThanOrEqualTol(double a, double b, double tolerance);

// min <= n <= max
TL_INLINE bool TLFloatBetweenInclusive(double n, double min, double max);
bool TLFloatBetweenInclusiveTol(double n, double min, double max, double tolerance);

// min < n < max
TL_INLINE bool TLFloatWithinExclusive(double n, double min, double max);
bool TLFloatWithinExclusiveTol(double n, double min, double max, double tolerance);

// compatible with CFComparisonResult: -1 if a<b, 0 if a==b, 1 if a>b
TL_INLINE TLCompareResult TLFloatCompareNaive(double a, double b);
TL_INLINE TLCompareResult TLFloatCompare(double a, double b);
TLCompareResult TLFloatCompareTol(double a, double b, double tolerance);

TL_INLINE double TLFloatClampNaive(double n, double min, double max);


#pragma mark Inline definitions

static const double TLFloatDefaultTolerance = 2.0 * FLT_MIN;

bool TLFloatEqual(double a, double b) {
	return TLFloatEqualTol(a, b, TLFloatDefaultTolerance);
}

bool TLFloatLessThan(double a, double b) {
	return TLFloatLessThanTol(a, b, TLFloatDefaultTolerance);
}

bool TLFloatGreaterThan(double a, double b) {
	return TLFloatGreaterThanTol(a, b, TLFloatDefaultTolerance);
}

bool TLFloatLessThanOrEqual(double a, double b) {
	return TLFloatLessThanOrEqualTol(a, b, TLFloatDefaultTolerance);
}

bool TLFloatGreaterThanOrEqual(double a, double b) {
	return TLFloatGreaterThanOrEqualTol(a, b, TLFloatDefaultTolerance);
}

bool TLFloatBetweenInclusive(double n, double min, double max) {
	return TLFloatBetweenInclusiveTol(n, min, max, TLFloatDefaultTolerance);
}

bool TLFloatWithinExclusive(double n, double min, double max) {
	return TLFloatWithinExclusiveTol(n, min, max, TLFloatDefaultTolerance);
}

TLCompareResult TLFloatCompare(double a, double b) {
	return TLFloatCompareTol(a, b, TLFloatDefaultTolerance);
}

TLCompareResult TLFloatCompareNaive(double a, double b) {
	if (a < b) return TLCompareLessThan;
	else if (a > b) return TLCompareGreaterThan;
	else return TLCompareEqual;
}

double TLFloatClampNaive(double n, double min, double max) {
	if (n > max) return max;
	else if (n < min) return min;
	else return n;
}

#endif /* TLFLOAT_H */
