//
//  TLIGCFileConversion.h
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLIGCFile.h"


@interface TLIGCFile (TLIGCFileConversion)

- (NSArray*)extractTracks:(NSError**)err;
- (NSArray*)extractWaypoints:(NSError**)err;

@end
