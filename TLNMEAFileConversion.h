//
//  TLNMEAFileConversion.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLNMEAFile.h"


@interface TLNMEAFile (TLNMEAFileConversion)

- (NSArray*)extractTracks:(NSError**)err;
- (NSArray*)extractWaypoints:(NSError**)err;

@end
