//
//  TLGPXTrackSegment.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLGPXWaypoint.h"
#import "TLGPXNode.h"

@interface TLGPXTrackSegment : TLGPXNode {
@protected
	NSMutableArray* trackpoints;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;
- (NSArray*)trackpoints;

@end
