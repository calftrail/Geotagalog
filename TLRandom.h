/*
 *  TLRandom.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 10/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef TLRANDOM_H
#define TLRANDOM_H

#include "TLPrimitiveTypes.h"

// initializes the PRNG with a suitably random source
void TLRandomInit(void);

// returns random number in [0.0, 1.0]
CGFloat TLRandom(void);

// returns two random numbers from a distribution with a 0.0 mean and a 1.0 standardDeviation
CGPoint TLRandomGaussian(void);

#endif /* TLRANDOM_H */
