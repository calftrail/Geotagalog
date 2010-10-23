//
//  Photos.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "Photos.h"

#import "Logger.h"
#import "iPhotoLibraryInterface.h"

#import "TLActor.h"
#import "NSOperationQueue+TLExtensions.h"
#import "NSArray+TLExtensions.h"
#import "NSString+TLExtensions.h"


@implementation Photos

- (id)init {
	self = [super init];
	id me = nil;
	if (self) {
		me = [TLActor actorForTarget:self];
		library = [iPhotoLibraryInterface interfaceWithCurrentLibrary];
		NSError* openError;
		BOOL opened = [library open:&openError];
		if (!opened) {
			[Logger logInfo:[openError userInfo] severity:LoggerError];
			library = nil;
			[super dealloc];
			return nil;
		}
	}
	return me;
}

+ (id)sharedManager {
	static id m;
	TLOnce(^{
		m = [Photos new];
	});
	return m;
}

- (void)getPhotoIDForIdentifier:(int64_t)identifier
					  inLibrary:(NSString*)libraryPath
						respond:(void (^)(id photoID))block
{
	if (![[library libraryPath] isEqualToString:libraryPath]) {
		block(nil);
	}
	block([library itemWithKey:identifier]);
}

+ (int64_t)identifierForPhotoID:(id)photoID {
	return [photoID databaseKey];
}

+ (NSString*)libraryForPhotoID:(id)photoID {
	return [[photoID library] libraryPath];
}

- (void)identifyFile:(NSString*)filePath
			 respond:(void (^)(NSSet* photoIDs))block;
{
	[Logger informativeLog:@"Finding photos for '%@'.", filePath];
	NSURL* fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
	block([library existingItemsForURL:fileURL error:NULL]);
}

- (void)findOriginals:(id)photoID
			  respond:(void (^)(NSArray* originalPaths))block
{
	[Logger informativeLog:@"Finding files for photo ID %llu.", [photoID databaseKey]];
	NSError* findError;
	NSArray* urls = [library originalURLsForItem:photoID error:&findError];
	if (!urls) {
		[Logger logInfo:[findError userInfo] severity:LoggerError];
	}
	block([urls valueForKey:@"path"]);
}

- (void)importFiles:(NSArray*)filePaths
		  forceCopy:(BOOL)forceCopy
		 hostFolder:(NSString*)hostFolder
			respond:(void (^)(NSArray* photoIDs))block
{
	[Logger informativeLog:@"Waiting for iPhoto to import %lu files.", (size_t)[filePaths count]];
	NSArray* fileURLs = [filePaths valueForKey:@"tl_fileURL"];
	NSDictionary* importOptions = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:forceCopy], @"forceCopy",
								   hostFolder, @"infoFolder", nil];
	NSError* importError;
	NSArray* photoIds = [library importURLs:fileURLs options:importOptions error:&importError];
	if (!photoIds) {
		[Logger logInfo:[importError userInfo] severity:LoggerError];
		photoIds = [fileURLs tl_arrayWithBlock:^(id val) {
			(void)val;
			return (id)[NSNull null];
		}];
	}
	block(photoIds);
}

- (void)applyMetadata:(NSDictionary*)metadata
			toPhotoID:(id)photoID
			  respond:(void (^)(void))block
{
	NSParameterAssert(metadata != nil);
	[Logger informativeLog:@"Adding metadata to photo ID %llu.", [photoID databaseKey]];
	NSSet* photoIDs = [NSSet setWithObject:photoID];
	NSError* metadataError;
	BOOL success = [library setMetadata:metadata forItems:photoIDs error:&metadataError];
	if (!success) {
		[Logger logInfo:[metadataError userInfo] severity:LoggerError];
	}
	block();
}

@end


typedef void (^beforeBlock_t)(NSOperation* importStarts);
typedef void (^afterBlock_t)(BOOL didImport, NSSet* photoIDs);


@implementation PhotosImport

@synthesize forceCopy;
@synthesize hostFolder;

- (id)init {
	self = [super init];
	if (self) {
		fileInfo = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)addFileToImport:(NSString*)path
				 before:(beforeBlock_t)beforeBlock
				  after:(afterBlock_t)afterBlock
{
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	if (beforeBlock) {
		[info setObject:[[beforeBlock copy] autorelease]
				 forKey:@"before"];
	}
	if (afterBlock) {
		[info setObject:[[afterBlock copy] autorelease]
				 forKey:@"after"];
	}
	[fileInfo setObject:info forKey:path];
}

- (void)main {
	if (![fileInfo count]) return;
	id me = [TLActor actorForTarget:self];
	NSOperation* importPrepared = TLOp(nil);
	[Logger informativeLog:@"Preparing for import."];
	NSMutableArray* importPaths = [NSMutableArray array];
	[fileInfo enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:
	 ^(id path, id info, BOOL* stop) { (void)stop;
		 NSOperation* addPath = TLOpBefore(importPrepared, ^{
			 [importPaths addObject:path];
		 });
		 [[Photos sharedManager] identifyFile:path respond:^(NSSet* photoIDs) {
			 if ([photoIDs count]) {
				 [addPath cancel];
				 afterBlock_t afterBlock = [info objectForKey:@"after"];
				 if (afterBlock) {
					 afterBlock(NO, photoIDs);
				 }
			 }
			 else {
				 beforeBlock_t beforeBlock = [info objectForKey:@"before"];
				 if (beforeBlock) {
					 beforeBlock(importPrepared);
				 }
			 }
			 TLPerformBy(me, addPath);
		 }];
	 }];
	TLPerformBy(me, importPrepared);
	
	NSOperation* importDone = TLOp(nil);
	TLAfter(importPrepared, me, ^{
		if (![importPaths count]) {
			[importDone start];
			return;
		}
		NSDictionary* threadsafeFileInfo = [fileInfo copy];
		[[Photos sharedManager] importFiles:importPaths forceCopy:forceCopy hostFolder:hostFolder respond:
		 ^(NSArray* photoIDs) {
			 [Logger informativeLog:@"Doing import post-processing."];
			 NSDictionary* mappedIDs = [NSDictionary dictionaryWithObjects:photoIDs forKeys:importPaths];
			 [mappedIDs enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:
			  ^(id path, id photoID, BOOL* stop) { (void)stop;
				  afterBlock_t afterBlock = [[threadsafeFileInfo objectForKey:path] objectForKey:@"after"];
				  if (afterBlock) afterBlock(YES, [NSSet setWithObject:photoID]);
			  }];
			 [importDone start];
		 }];
	});
	[importDone waitUntilFinished];
	[Logger informativeLog:
	 ([importPaths count]) ? @"Import complete." : @"No import necessary."];
}

@end
