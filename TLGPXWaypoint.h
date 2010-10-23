//
//  TLGPXWaypoint.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLGPXNode.h"
#import "TLCoordinate.h"

@interface TLGPXWaypoint : TLGPXNode {
@protected
	TLCoordinate coordinate;
	TLCoordinateAltitude elevation;
	double horizontalDOP;
	double verticalDOP;
	double positionDOP;
	NSDate* time;
	NSString* name;
}

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSDate* time;
@property (nonatomic, readonly) TLCoordinate coordinate;
@property (nonatomic, readonly) TLCoordinateAltitude elevation;
@property (nonatomic, readonly) double horizontalDOP;
@property (nonatomic, readonly) double verticalDOP;
@property (nonatomic, readonly) double positionDOP;

@end
