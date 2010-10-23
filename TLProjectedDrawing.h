/*
 *  TLProjectedDrawing.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 11/26/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLPROJECTEDDRAWING_H
#define TLPROJECTEDDRAWING_H

#include <ApplicationServices/ApplicationServices.h>
#include "TLMultiPolygon.h"

CGPathRef TLCGPathCreateFromMultiPolygon(TLMultiPolygonRef multiPoly, bool isClosed,
										 CGFloat significantDistance);


#endif /* TLPROJECTEDDRAWING_H */
