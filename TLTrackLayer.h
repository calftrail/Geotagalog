//
//  TLTrackLayer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLMapLayer.h"

@interface TLTrackLayer : TLMapLayer {
@private
	id dataSource;
}

@property (nonatomic, assign) id dataSource;
- (void)reloadData;

@end


@interface NSObject (TLTrackLayerDataSource)

- (NSArray*)trackLayer:(TLTrackLayer*)layer
		tracksInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj;

- (NSArray*)trackLayer:(TLTrackLayer*)layer
	 waypointsInBounds:(TLBounds)bounds
	   underProjection:(TLProjectionRef)proj;


@end
