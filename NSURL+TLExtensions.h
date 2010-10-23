//
//  NSURL+TLExtensions.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 9/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (TLStringFeatures)
- (NSString*)tl_pathExtension;
- (NSURL*)tl_URLByDeletingPathExtension;
- (NSString*)tl_lastPathComponent;
- (NSURL*)tl_URLByDeletingLastPathComponent;
- (NSURL*)tl_URLByAppendingPathComponent:(NSString*)pathComponent;
- (const char*)tl_fileSystemRepresentation;
@end

@interface NSURL (TLAliasAdditions)
+ (NSURL*)tl_urlByResolvingAliasFile:(NSURL*)aliasFile error:(NSError**)err;
@end
