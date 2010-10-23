/*
 *  TLToolbag.c
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 6/20/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "TLToolbag.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "TLPrimitiveTypes.h"

TL_INLINE void TLWarnVA(const char* warningMessage, va_list args) {
	vfprintf(stderr, warningMessage, args);
	fprintf(stderr, "\n");
}

void TLWarn(const char* warningMessage, ...) {
	va_list args;
	va_start(args, warningMessage);
	TLWarnVA(warningMessage, args);
	va_end(args);
}

void TLAssert(bool isTrue, const char* errorMessage, ...) {
	if (!isTrue) {
		va_list args;
		va_start(args, errorMessage);
		TLWarnVA(errorMessage, args);
		va_end(args);
		TLBailOut();
	}
}

void TLLog(const char* logMessage, ...) {
	va_list args;
	va_start(args, logMessage);
	vprintf(logMessage, args);
	va_end(args);
}

void TLBailOut() {
	TLWarn("Bailing out.\n");
	exit(1);
}

void TLOutOfMemoryBail() {
	TLWarn("Out of memory.\n");
	TLBailOut();
}
