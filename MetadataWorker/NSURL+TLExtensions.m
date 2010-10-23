//
//  NSURL+TLExtensions.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 9/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSURL+TLExtensions.h"


@implementation NSURL (TLAliasAdditions)

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5

+ (NSURL*)tl_urlByResolvingAliasFile:(NSURL*)aliasFileURL error:(NSError**)err {
	FSRef aliasFileRef = {};
	Boolean success = CFURLGetFSRef((CFURLRef)aliasFileURL, &aliasFileRef);
	if (!success) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 aliasFileURL, NSURLErrorKey, nil];
			*err = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:errInfo];
		}
		return nil;
	}
	
	Boolean wasAliased = false;
	Boolean targetIsFolder = false;
	OSErr resolveErr = FSResolveAliasFileWithMountFlags(&aliasFileRef,
														true, &targetIsFolder, &wasAliased,
														kResolveAliasFileNoUI);
	(void)targetIsFolder;
	if (resolveErr) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 aliasFileURL, NSURLErrorKey, nil];
			*err = [NSError errorWithDomain:NSOSStatusErrorDomain code:resolveErr userInfo:errInfo];
		}
		return nil;
	}
	
	if (wasAliased) {
		CFURLRef resolvedAlias = CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasFileRef);
		return [(NSURL*)resolvedAlias autorelease];
	}
	else {
		return aliasFileURL;
	}
}

#else

+ (NSURL*)tl_urlByResolvingAliasFile:(NSURL*)aliasFileURL error:(NSError**)err {
	NSData* bookmark = [NSURL bookmarkDataWithContentsOfURL:aliasFileURL error:err];
	if (!bookmark) return aliasFileURL;
	return [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithoutUI
							   relativeToURL:nil bookmarkDataIsStale:NULL error:err];
}


#endif

@end
