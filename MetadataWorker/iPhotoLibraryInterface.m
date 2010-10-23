//
//  iPhotoLibraryInterface.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 9/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "iPhotoLibraryInterface.h"

#import "NSURL+TLExtensions.h"
#import "NSArray+TLExtensions.h"
#import "NSDateFormatter+TLExtensions.h"
#import "NSString+TLExtensions.h"
#import "NSTask+TLExtensions.h"

#include <sqlite3.h>

@interface iPhotoItemID ()
- (id)initWithLibrary:(iPhotoLibraryInterface*)theLibrary databaseKey:(sqlite_int64)theKey;
@end


@interface iPhotoLibraryInterface ()
+ (NSDictionary*)mapImportResults:(NSArray*)importResults;
+ (NSDate*)iPhotoDateOfItemAtPath:(NSString*)itemPath;
@end


@implementation iPhotoLibraryInterface

@synthesize libraryPath;

- (id)initWithPath:(NSString*)theLibraryPath {
	self = [super init];
	if (self) {
		libraryPath = [theLibraryPath copy];
	}
	return self;
}

- (void)finalize {
	NSAssert(!dbHandle, @"Must be correctly closed.");
	[super finalize];
}

- (void)dealloc {
	NSAssert(!dbHandle, @"Must be correctly closed.");
	[libraryPath release];
	[super dealloc];
}

- (BOOL)open:(NSError**)err {
	if (!libraryPath) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"No iPhoto library found", NSLocalizedDescriptionKey,
									 @"You must first use iPhoto to create a library. "
									 @"If you have already done so, an internal error has "
									 @"prevented your default library from being found.",
									 NSLocalizedRecoverySuggestionErrorKey, nil];
			*err = [NSError errorWithDomain:NSCocoaErrorDomain
									   code:NSFileReadNoSuchFileError
								   userInfo:errInfo];
		}
		return NO;
	}
	
	NSString* dbPath = [libraryPath stringByAppendingPathComponent:@"iPhotoMain.db"];
	int sqErr = sqlite3_open([dbPath fileSystemRepresentation], (sqlite3**)&dbHandle);
	if (sqErr) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Could not open iPhoto library database. "
									 @"iPhoto's library format may have changed.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Opening database '%@' failed (%i) due to SQLite error %s (%i)",
									  dbPath, sqErr, sqlite3_errmsg(dbHandle), sqlite3_errcode(dbHandle)],
									 NSLocalizedFailureReasonErrorKey, dbPath, NSFilePathErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		[self close];
		return NO;
	}
	return YES;
}

- (void)close {
	if (itemQuery) sqlite3_finalize(itemQuery);
	int sqErr = sqlite3_close(dbHandle);
	NSAssert1(!sqErr, @"Database cannot be closed, likely due to unfinalized statements (err %i)", sqErr);
	dbHandle = NULL;
}

+ (id)interfaceWithCurrentLibrary {
	NSString* path = nil;
	CFArrayRef recentDatabases = CFPreferencesCopyValue(CFSTR("iPhotoRecentDatabases"), CFSTR("com.apple.iApps"),
														kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (recentDatabases) {
		if (CFArrayGetCount(recentDatabases)) {
			NSString* recentest = (NSString*)CFArrayGetValueAtIndex(recentDatabases, 0);
			NSURL* albumDataURL = [NSURL URLWithString:recentest];
			path = [[albumDataURL path] stringByDeletingLastPathComponent];
		}
		CFRelease(recentDatabases);
	}
	
	return [[[iPhotoLibraryInterface alloc] initWithPath:path] autorelease];
}

- (iPhotoItemID*)itemWithKey:(int64_t)databaseKey {
	id item = [[iPhotoItemID alloc] initWithLibrary:self databaseKey:databaseKey];
	return [item autorelease];
}

- (NSSet*)existingItemsForURL:(NSURL*)imageURL error:(NSError**)err {
	NSAssert([imageURL isFileURL], @"Must only search for file URL in library");
	NSAssert(dbHandle, @"Library must be open");
	
	// if imagePath is within library, we should query just the relative part
	NSString* imagePath = [imageURL path];
	if ([imagePath hasPrefix:libraryPath]) {
		NSRange libraryPart = [imagePath rangeOfString:libraryPath];
		// -[NSURL path] always strips trailing slash, so add it back
		libraryPart.length += 1;
		NSUInteger relativePartStart = libraryPart.location + libraryPart.length;
		imagePath = [imagePath substringFromIndex:relativePartStart];
	}
	//printf("Querying '%s'\n", [imagePath UTF8String]);
	
	NSMutableSet* items = [NSMutableSet set];
	if (!itemQuery) {
		const char* q = ("SELECT DISTINCT i.photoKey FROM SqFileImage AS i, SqFileInfo AS f "
						 "WHERE i.sqFileInfo = f.primaryKey AND f.relativePath = ?");
		int sqErr = sqlite3_prepare_v2(dbHandle, q, -1, (sqlite3_stmt**)&itemQuery, NULL);
		if (sqErr) {
			if (err) {
				NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										 @"Internal error", NSLocalizedDescriptionKey,
										 @"Could not create query for iPhoto library path search. "
										 @"Database format may have changed.",
										 NSLocalizedRecoverySuggestionErrorKey,
										 [NSString stringWithFormat:
										  @"Preparing itemQuery failed (%i) due to SQLite error %s (%i)",
										  sqErr, sqlite3_errmsg(dbHandle), sqlite3_errcode(dbHandle)],
										 NSLocalizedFailureReasonErrorKey, nil];
				*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
			}
			return nil;
		}
		// iPhoto may be writing while we read, so avoid spurious SQLITE_BUSY "errors"
		sqlite3_busy_timeout(dbHandle, 2500);
	}
	
	(void)sqlite3_bind_text(itemQuery, 1, [imagePath UTF8String], -1, SQLITE_TRANSIENT);
	while (sqlite3_step(itemQuery) == SQLITE_ROW) {
		sqlite_int64 photoKey = sqlite3_column_int64(itemQuery, 0);
		[items addObject:
		 [self itemWithKey:photoKey]];
	}
	(void)sqlite3_reset(itemQuery);
	(void)sqlite3_clear_bindings(itemQuery);
	
	if (![items count] && sqlite3_errcode(dbHandle) != SQLITE_DONE) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Could not search iPhoto library for file. "
									 @"Database may be too busy.", NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:
									  @"Could not find iPhoto IDs for '%@' due to SQLite error %s (%i)",
									  imagePath, sqlite3_errmsg(dbHandle), sqlite3_errcode(dbHandle)],
									 NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return nil;
	}
	
	//if ([items count]) printf("Found %s\n", [[items description] UTF8String]);
	
	return items;
}

- (NSArray*)originalURLsForItem:(iPhotoItemID*)item error:(NSError**)err {
	NSParameterAssert([item library] == self);
	NSMutableArray* args = [NSMutableArray array];
	[args addObject:
	 [[NSBundle mainBundle] pathForResource:@"iPhotoOriginals" ofType:@"scpt"]];
	[args addObject:
	 [NSString stringWithFormat:@"%llu", [item databaseKey]]];
	
	NSData* resultData = [NSTask tl_system:@"/usr/bin/osascript" arguments:args error:err];
	if (!resultData) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Find originals script failed to launch.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 @"OSAScript failed to launch.", NSLocalizedFailureReasonErrorKey,
									 *err, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return nil;
	}
	
	NSString* result = [NSString tl_stringAutodetectedFromData:resultData];
	NSArray* paths = [result componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableSet* urls = [NSMutableSet set];
	for (NSString* path in paths) {
		if ([path isEqualToString:@""]) continue;
		[urls addObject:
		 [NSURL tl_urlByResolvingAliasFile:[path tl_fileURL] error:NULL]];
	}
	if (![urls count]) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Found no original files for photo.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:@"No originals found for photo ID %llu. "
									  @"(Script result was: %@)", [item databaseKey], result],
									 NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return nil;
	}
	return [urls allObjects];
}

- (BOOL)setMetadata:(NSDictionary*)metadata
		   forItems:(NSSet*)items
			  error:(NSError**)err
{
	NSMutableArray* args = [NSMutableArray array];
	[args addObject:
	 [[NSBundle mainBundle] pathForResource:@"iPhotoMetadata" ofType:@"scpt"]];
	for (iPhotoItemID* item in items) {
		NSAssert([item library] == self, @"All items must be from this interface's iPhoto library");
		[args addObject:@"photo"];
		[args addObject:
		 [NSString stringWithFormat:@"%llu", [item databaseKey]]];
	}
	for (NSString* key in metadata) {
		[args addObject:key];
		id value = [metadata objectForKey:key];
		if ([value isKindOfClass:[NSString class]]) {
			[args addObject:value];
		}
		if ([value isKindOfClass:[NSDate class]]) {
			[args addObject:
			 [[NSDateFormatter tl_applescriptDateFormatter] stringFromDate:value]];
		}
		else if ([value isKindOfClass:[NSNumber class]]) {
			NSNumberFormatter* fmt = [[NSNumberFormatter new] autorelease];
			[fmt setNumberStyle:NSNumberFormatterDecimalStyle];
			[args addObject:
			 [fmt stringFromNumber:value]];
		}
		else {
			NSLog(@"Unknown type %@, formatting anyway...", [value class]);
			[args addObject:
			 [NSString stringWithFormat:@"%@", value]];
		}
	}
	//printf("Calling osascript with arguments: %s\n", [[args description] UTF8String]);
	NSTask* script = [NSTask tl_completedTask:@"/usr/bin/osascript" arguments:args error:err];
	if (!script) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Metadata script failed to launch.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 @"OSAScript failed to launch.", NSLocalizedFailureReasonErrorKey,
									 *err, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return NO;
	}
	return YES;
}

- (NSArray*)importURLs:(NSArray*)fileURLs
			   options:(NSDictionary*)options
				 error:(NSError**)err
{
	NSArray* importPaths = [fileURLs valueForKey:@"path"];
	
	NSString* importInfoFolder = [options valueForKey:@"infoFolder"];
	if (!importInfoFolder) {
		importInfoFolder = NSTemporaryDirectory();
	}
	NSString* infoPath = [importInfoFolder stringByAppendingPathComponent:@"geotagalogImportRecord.plist"];
	
	BOOL shouldForceCopy = [[options valueForKey:@"forceCopy"] boolValue];
	
	NSMutableArray* args = [NSMutableArray array];
	[args addObject:[[NSBundle mainBundle] pathForResource:@"iPhotoImport" ofType:@"scpt"]];
	[args addObject:infoPath];
	[args addObject:(shouldForceCopy ? @"copy" : @"import")];
	[args addObjectsFromArray:importPaths];
	//printf("Calling osascript with arguments: %s\n", [[args description] UTF8String]);
	NSTask* script = [NSTask tl_completedTask:@"/usr/bin/osascript" arguments:args error:err];
	if (!script) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Import script failed to launch.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 @"OSAScript failed to launch.", NSLocalizedFailureReasonErrorKey,
									 *err, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return nil;
	}
	
	NSDictionary* importInfo = [NSDictionary dictionaryWithContentsOfFile:infoPath];
	NSArray* importResults = [importInfo objectForKey:@"importResults"];
	//printf("Got import results: %s", [[importResults description] UTF8String]);
	if (!importResults) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Internal error", NSLocalizedDescriptionKey,
									 @"Import script did not create valid results information.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 [NSString stringWithFormat:@"Import info at '%@' is %@",
									  infoPath, importInfo], NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog" code:0 userInfo:errInfo];
		}
		return nil;
	}
	
	NSDictionary* mappedResults = [[self class] mapImportResults:importResults];
	//printf("Mapped import info: %s", [[mappedResults description] UTF8String]);
	
	NSMutableArray* photoIDs = [NSMutableArray arrayWithCapacity:[importPaths count]];
	for (NSString* importPath in importPaths) {
		NSString* filename = [[importPath lastPathComponent] lowercaseString];
		NSArray* matchingInfo = [mappedResults objectForKey:filename];
		
		NSDictionary* matchedItem = nil;
		if ([matchingInfo count] == 1) {
			matchedItem = [matchingInfo lastObject];
		}
		else if ([matchingInfo count] > 1) {
			NSDate* targetDate = [[self class] iPhotoDateOfItemAtPath:importPath];
			for (NSDictionary* info in matchingInfo) {
				NSString* resultPath = [info valueForKey:@"originalPath"];
				NSDate* resultDate = [[self class] iPhotoDateOfItemAtPath:resultPath];
				if ([resultDate isEqualToDate:targetDate]) {
					matchedItem = info;
					break;
				}
			}
		}
		
		if (matchedItem) {
			int64_t dbKey = [[matchedItem objectForKey:@"photoID"] longLongValue];
			[photoIDs addObject:[self itemWithKey:dbKey]];
		}
		else {
			[photoIDs addObject:[NSNull null]];
		}
	}
	return photoIDs;
}

+ (NSDate*)iPhotoDateOfItemAtPath:(NSString*)itemPath {
	NSURL* aliasURL = [NSURL fileURLWithPath:itemPath isDirectory:NO];
	NSURL* itemURL = [NSURL tl_urlByResolvingAliasFile:aliasURL error:NULL] ?: aliasURL;
	NSDate* date = nil;
	
	CGImageSourceRef isrc = CGImageSourceCreateWithURL((CFURLRef)itemURL, NULL);
	if (!isrc) goto file_fallback;
	if (!CGImageSourceGetCount(isrc)) {
		CFRelease(isrc);
		goto file_fallback;
	}
	
	NSDictionary* props = (id)CGImageSourceCopyPropertiesAtIndex(isrc, 0, NULL);
	CFRelease(isrc);
	[(id)CFMakeCollectable(props) autorelease];
	
	NSString* dateStr = [[props valueForKey:(id)kCGImagePropertyExifDictionary]
						 valueForKey:(id)kCGImagePropertyExifDateTimeOriginal];
	if (!dateStr) {
		dateStr = [[props valueForKey:(id)kCGImagePropertyTIFFDictionary]
				   valueForKey:(id)kCGImagePropertyTIFFDateTime];
	}
	
	if (dateStr) {
		NSDateFormatter* dateParser = [NSDateFormatter tl_tiffDateFormatter];
		date = [dateParser dateFromString:dateStr];
	}
	
file_fallback:
	if (!date) {
		// get file modification time
		[itemURL getResourceValue:&date forKey:NSURLContentModificationDateKey error:NULL];
	}
	return date;
}

+ (NSString*)nonuniquedFilename:(NSString*)iPhotoFilename {
	/* NOTE: iPhoto may have uniqued photo names (to comine them in an event folder)
	 by adding _N before the extension. It's easy to just chop off the last _ component. */
	NSString* originalExtension = [iPhotoFilename pathExtension];
	NSString* originalName = [iPhotoFilename stringByDeletingPathExtension];
	
	/* NOTE: this, however, checks to see if a file name roughly matches the DCF specification
	 http://en.wikipedia.org/wiki/Design_rule_for_Camera_File_system to avoid non-uniquing
	 filenames like IMG_1234.jpg. */
	if ([originalName length] == 8) {
		BOOL allNumbers = YES;
		NSCharacterSet* nums = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
		for (NSUInteger charIdx = 4; charIdx < 8; ++charIdx) {
			if (![nums characterIsMember:[originalName characterAtIndex:charIdx]]) {
				allNumbers = NO;
				break;
			}
		}
		if (allNumbers) return nil;
	}
	
	NSString* choppedName = nil;
	NSString* sep = @"_";
	NSArray* separatedComponents = [originalName componentsSeparatedByString:sep];
	if ([separatedComponents count] > 1) {
		NSMutableArray* choppedComponents = [[separatedComponents mutableCopy] autorelease];
		[choppedComponents removeLastObject];
		choppedName = [choppedComponents componentsJoinedByString:sep];
	}
	return [choppedName stringByAppendingPathExtension:originalExtension];
}

+ (NSDictionary*)mapImportResults:(NSArray*)importResults {
	NSMutableDictionary* mappedResults = [NSMutableDictionary dictionary];
	for (NSDictionary* importResult in importResults) {
		NSString* importPath = [importResult valueForKey:@"originalPath"];
		NSString* baseName =  [[importPath lastPathComponent] lowercaseString];
		NSArray* filenames = [NSArray arrayWithObjects:
							  baseName, [self nonuniquedFilename:baseName], nil];
		for (NSArray* filename in filenames) {
			NSMutableArray* infos = [mappedResults objectForKey:filename];
			if (!infos) {
				infos = [NSMutableArray array];
				[mappedResults setObject:infos forKey:filename];
			}
			[infos addObject:importResult];
		}
	}
	return mappedResults;
}

@end


@implementation iPhotoItemID

@synthesize library;
@synthesize databaseKey;

- (id)initWithLibrary:(iPhotoLibraryInterface*)theLibrary databaseKey:(sqlite_int64)theKey {
	self = [super init];
	if (self) {
		library = theLibrary;
		databaseKey = theKey;
	}
	return self;
}

- (id)copyWithZone:(NSZone*)zone {
	(void)zone;
	return [self retain];
}

- (NSString*)libraryName {
	return [[library libraryPath] lastPathComponent];
}

- (BOOL)isEqual:(id)other {
	return [[self library] isEqual:[other library]] && ([self databaseKey] == [other databaseKey]);
}

- (NSString*)description {
	return [NSString stringWithFormat:@"iPhotoItemID (%llu in %@)", databaseKey, [self libraryName]];
}

- (NSUInteger)hash {
#if __LP64__ || NS_BUILD_32_LIKE_64
	return [[self library] hash] ^ [self databaseKey];
#else
	return [[self library] hash] ^ (NSUInteger)[self databaseKey] ^ (NSUInteger)([self databaseKey] >> 32);
#endif
}

@end
