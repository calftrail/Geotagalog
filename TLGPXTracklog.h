//
//  TLGPXTracklog.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLGPXNode.h"
#import "TLGPXTrackSegment.h"

@interface TLGPXTracklog : TLGPXNode {
@protected
	NSMutableArray* segments;
	NSString* name;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;

@end
