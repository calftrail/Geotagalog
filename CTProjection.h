//
//  CTProjection.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/6/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "TLCoordinate.h"
#include "TLProjection.h"


@interface CTProjection : NSObject {
@private
	TLProjectionRef wrappedProjection;
	int errorFromOperation;
}

// These are exposed to aid transition to pure TLProjectionRef use
- (id)initWithWrappedProjection:(TLProjectionRef)theWrappedProjection;
- (TLProjectionRef)wrappedProjection;


- (CGPoint)projectCoordinate:(TLCoordinate)coord;
- (TLCoordinate)unprojectPoint:(CGPoint)aPoint;
- (BOOL)hadErrorResult;
- (NSString*)stringForError;
- (TLCoordinateDegrees)antimeridian;

@end
