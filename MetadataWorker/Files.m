//
//  Files.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "Files.h"

#import "Logger.h"
#import "FileMetadataInterface.h"

#import "TLActor.h"


@implementation Files

- (id)init {
	self = [super init];
	id me = nil;
	if (self) {
		me = [TLActor actorForTarget:self];
		writer = [FileMetadataInterface interface];
	}
	return me;
}

+ (id)sharedManager {
	static id m;
	TLOnce(^{
		m = [Files new];
	});
	return m;
}


- (BOOL)paranoidWriteMetadata:(NSDictionary*)metadata
					   toFile:(NSString*)originalFile
						error:(NSError**)err
{
	NSFileManager* fileManager = [NSFileManager new];
	
	NSString* folder = [originalFile stringByDeletingLastPathComponent];
	NSString* name = [[originalFile lastPathComponent] stringByDeletingPathExtension];
	NSString* extension = [originalFile pathExtension];
	NSString* backupName = [[name stringByAppendingPathExtension:@"geotagalogBackup"]
							stringByAppendingPathExtension:extension];
	NSString* backupFile = [folder stringByAppendingPathComponent:backupName];
	[Logger informativeLog:@"Backing up '%@' to '%@'\n", name, backupFile];
	BOOL backupCreated = [fileManager copyItemAtPath:originalFile
											  toPath:backupFile
											   error:err];
	if (!backupCreated) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Couldn't create backup", NSLocalizedDescriptionKey,
									 [NSString stringWithFormat:
									  @"For the safety of each photo, "
									  @"a backup must be created before the file is modified. "
									  @"Please check that '%@' is writeable and ensure that "
									  @"no previous backup named '%@' already exists there.",
									  folder, backupName],
									 NSLocalizedRecoverySuggestionErrorKey,
									 *err, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog"
									   code:99 userInfo:errInfo];
		}
		return NO;
	}
	
	NSURL* fileURL = [NSURL fileURLWithPath:originalFile isDirectory:NO];
	[Logger informativeLog:@"Writing metadata to '%@'\n", name];
	BOOL writeSuccess = [writer writeMetadata:metadata toURL:fileURL error:err];
	if (writeSuccess) {
		NSURL* backupURL = [NSURL fileURLWithPath:backupFile isDirectory:NO];
		[Logger informativeLog:@"Verifying metadata for '%@'\n", name];
		BOOL verified = [writer verifyMetadata:metadata
									  original:backupURL modified:fileURL
										 error:err];
		if (!verified && err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Image check failed", NSLocalizedDescriptionKey,
									 @"An issue was found while verifying the "
									 @"metadata modification to your photo. "
									 @"A backup had been made, and the original file "
									 @"may be restored from this.",
									 NSLocalizedRecoverySuggestionErrorKey,
									 *err, NSUnderlyingErrorKey, nil];
			*err = [NSError errorWithDomain:@"com.calftrail.geotagalog"
									   code:86 userInfo:errInfo];
		}
		if (verified) {
			[Logger informativeLog:@"Removing backup for '%@'.\n", name];
			[fileManager removeItemAtPath:backupFile error:NULL];
		} else goto restore_from_backup;
	} else goto restore_from_backup;
	return YES;
	
restore_from_backup:
	{
		NSString* modifiedName = [[name stringByAppendingPathExtension:@"geotagalogModified"]
								  stringByAppendingPathExtension:extension];
		NSString* modifiedFile = [folder stringByAppendingPathComponent:modifiedName];
		
		BOOL movedModified = [fileManager moveItemAtPath:originalFile
												  toPath:modifiedFile
												   error:NULL];
		if (movedModified) {
			BOOL restoredBackup = [fileManager moveItemAtPath:backupFile
													   toPath:originalFile
														error:NULL];
			if (restoredBackup) {
				[fileManager removeItemAtPath:modifiedFile error:NULL];
			}
		}
		return NO;
	}
}

- (void)applyMetadata:(NSDictionary*)metadata
			   toFile:(NSString*)originalFile
			  respond:(void (^)(void))block
{
	NSError* metadataError;
	BOOL success = [self paranoidWriteMetadata:metadata
										toFile:originalFile
										 error:&metadataError];
	if (!success) {
		[Logger logInfo:[metadataError userInfo] severity:LoggerError];
	}
	block();
}

@end
