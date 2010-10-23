//
//  TLTCXFileConversion.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLTCXFile.h"


@interface TLTCXFile (TLTCXFileConversion)

- (NSArray*)extractTracks:(NSError**)err;
- (NSArray*)extractWaypoints:(NSError**)err;

@end
