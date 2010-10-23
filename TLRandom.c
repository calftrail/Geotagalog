/*
 *  TLRandom.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLRandom.h"

void TLRandomInit() {
	srandomdev();
}

CGFloat TLRandom() {
	static const double random_max = (CGFloat)0x7fffffff;
	return (CGFloat)(random() / random_max);
}

CGPoint TLRandomGaussian() {
	// based on http://www.taygeta.com/random/gaussian.html
	CGFloat x1, x2, w;
	do {
		CGFloat random1 = TLRandom();
		CGFloat random2 = TLRandom();
		x1 = (CGFloat)2.0 * random1 - (CGFloat)1.0;
		x2 = (CGFloat)2.0 * random2 - (CGFloat)1.0;
		w = x1 * x1 + x2 * x2;
	} while ( w >= 1.0 );
	
	w = (CGFloat)sqrt((-2.0 * log(w)) / w);
	CGFloat gauss1 = x1 * w;
	CGFloat gauss2 = x2 * w;
	
	return CGPointMake(gauss1, gauss2);
}
