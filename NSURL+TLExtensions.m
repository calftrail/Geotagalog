//
//  NSURL+TLExtensions.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 9/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSURL+TLExtensions.h"


@implementation NSURL (TLStringFeatures)

- (NSString*)tl_pathExtension {
	return [[self path] pathExtension];
}

- (NSURL*)tl_URLByDeletingPathExtension {
	NSString* newPath = [[self path] stringByDeletingPathExtension];
	NSURL* newURL = [[NSURL alloc] initWithScheme:[self scheme]
											 host:[self host]
											 path:newPath];
	return [newURL autorelease];
}

- (NSString*)tl_lastPathComponent {
	return [[self path] lastPathComponent];
}

- (NSURL*)tl_URLByDeletingLastPathComponent {
	NSString* newPath = [[self path] stringByDeletingLastPathComponent];
	NSURL* newURL = [[NSURL alloc] initWithScheme:[self scheme]
											 host:[self host]
											 path:newPath];
	return [newURL autorelease];
}

- (NSURL*)tl_URLByAppendingPathComponent:(NSString*)pathComponent {
	NSString* newPath = [[self path] stringByAppendingPathComponent:pathComponent];
	NSURL* newURL = [[NSURL alloc] initWithScheme:[self scheme]
											 host:[self host]
											 path:newPath];
	return [newURL autorelease];
}

- (const char*)tl_fileSystemRepresentation {
	return [[self path] fileSystemRepresentation];
}

@end

@implementation NSURL (TLAliasAdditions)

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

@end
