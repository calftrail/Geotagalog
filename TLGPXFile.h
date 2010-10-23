//
//  TLGPXFile.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLGPXNode.h"
#import "TLGPXWaypoint.h"
#import "TLGPXTracklog.h"

@interface TLGPXFile : TLGPXNode {
@private
	NSMutableArray* tracks;
	NSMutableArray* waypoints;
}

- (id)initGPXFileWithContentsOfURL:(NSURL*)url error:(NSError**)error;

- (NSArray*)tracks;
- (NSArray*)waypoints;

@end
