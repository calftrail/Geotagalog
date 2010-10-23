/*
 *  TLFloat.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLFloat.h"

bool TLFloatEqualTol(double a, double b, double tolerance) {
	double diff = a - b;
	return (fabs(diff) < tolerance);
}

bool TLFloatLessThanTol(double a, double b, double tolerance) {
	return (a < b) && !TLFloatEqualTol(a, b, tolerance);
}

bool TLFloatGreaterThanTol(double a, double b, double tolerance) {
	return (a > b) && !TLFloatEqualTol(a, b, tolerance);
}

bool TLFloatLessThanOrEqualTol(double a, double b, double tolerance) {
	return (a < b) || TLFloatEqualTol(a, b, tolerance);
}

bool TLFloatGreaterThanOrEqualTol(double a, double b, double tolerance) {
	return (a > b) || TLFloatEqualTol(a, b, tolerance);
}

bool TLFloatBetweenInclusiveTol(double n, double min, double max, double tolerance) {
	return TLFloatGreaterThanOrEqualTol(n, min, tolerance) && TLFloatLessThanOrEqualTol(n, max, tolerance);
}

bool TLFloatWithinExclusiveTol(double n, double min, double max, double tolerance) {
	return TLFloatGreaterThanTol(n, min, tolerance) && TLFloatLessThanTol(n, max, tolerance);
}

TLCompareResult TLFloatCompareTol(double a, double b, double tolerance) {
	if (TLFloatEqualTol(a, b, tolerance)) return TLCompareEqual;
	else return (a < b) ? TLCompareLessThan : TLCompareGreaterThan;
}
