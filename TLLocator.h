//
//  TLLocator.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLLocation;
@class TLTimestamp;


@interface TLLocator : NSObject {
@private
	id dataSource;
	NSArray* sortedTracks;
}

@property (nonatomic, assign) id dataSource;
- (void)reloadData;

- (TLLocation*)locationAtTimestamp:(TLTimestamp*)targetTimestamp;
- (NSMapTable*)locateTimestamps:(NSMapTable*)timestampObjects;
- (NSSet*)trackTimestampsAtLocation:(TLLocation*)targetLocation;

@end


@interface NSObject (TLLocatorDataSource)
- (NSSet*)locatorNeedsTracks:(TLLocator*)aLocator;
@end
