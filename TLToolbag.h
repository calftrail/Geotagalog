/*
 *  TLToolbag.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/20/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include <stdbool.h>

// used to check for programmer exception
void TLAssert(bool isTrue, const char* errorMessage, ...);

// used to warn of runtime error
void TLWarn(const char* warningMessage, ...);

// used for other, non-error, notifications
void TLLog(const char* logMessage, ...);

// used in case of fatal error
void TLBailOut(void);	// the void parameter kills a "no previous prototype" warning from gcc

// used as TLBailOut, but to mark out-of-memory bails for future improvement
void TLOutOfMemoryBail(void);
