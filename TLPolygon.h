/*
 *  TLPolygon.h
 *  Mercatalog
 *
 *  Created by Nathan Vander Wilt on 5/19/08.
 *  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
 *
 */

/*
 TLPolygons store an ordered set of Cartesian points. They represent both closed polygons and
 unclosed polylines, as some functions (eg simplification, densification) can work equally
 well with either. Closed polygons repeat their initial vertex as the last, thus distinguishing
 themselves from polylines as well as simplifying many of the algorithms' internal implementations.
 */


#ifndef TLPOLYGON_H
#define TLPOLYGON_H

#include "TLPrimitiveTypes.h"

#define TLATCollectionName TLPolygon
#define TLATMutableCollectionName TLMutablePolygon
#define TLATCollectedItemType CGPoint
#define TLATCollectedItemAlias Point
#include "TLArrayTemplate.h"

#endif /* TLPOLYGON_H */
