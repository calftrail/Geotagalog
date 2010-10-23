//
//  TLGPXFileConversion.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLGPXFile.h"


@interface TLGPXFile (TLGPXFileConversion)

- (NSArray*)extractTracks:(NSError**)err;
- (NSArray*)extractWaypoints:(NSError**)err;

@end
