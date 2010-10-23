//
//  TaskMaster.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "TaskMaster.h"

#import "Photos.h"
#import "Files.h"
#import "Logger.h"

#import "TLActor.h"
#import "TLActorKVO.h"
#import "NSOperationQueue+TLExtensions.h"
#import "NSManagedObject+TLExtensions.h"
#import "NSManagedObjectContext+TLExtensions.h"
#import "NSArray+TLExtensions.h"


NSString* const TaskMasterDidUpdateNotification = @"TaskMasterDidUpdate";
NSString* const TaskMasterCurrentTasks = @"Current tasks";


@implementation TaskMaster

- (id)initWithURL:(NSURL*)theStoreURL {
	self = [super init];
	if (self) {
		me = [TLActor actorForTarget:self];
		fileManager = [Files new];
		storeURL = [theStoreURL copy];
	}
	return me;
}


- (NSArray*)tasks {
	if (!taskContext) {
		[self begin];
	}
	NSMutableArray* taskDescriptions = [NSMutableArray array];
	[[taskContext tl_fetchAllEntitiesNamed:@"FileTask"] tl_enumerate:^(id task) {
		NSString* description = [NSString stringWithFormat:@"File '%@' needs metadata.",
								 [task valueForKey:@"path"]];
		[taskDescriptions addObject:description];
	}];
	[[taskContext tl_fetchAllEntitiesNamed:@"PhotoTask"]  tl_enumerate:^(id task) {
		NSString* description = [NSString stringWithFormat:@"Photo ID %@ needs metadata.",
								 [task valueForKey:@"identifier"]];
		[taskDescriptions addObject:description];
	}];
	[[taskContext tl_fetchAllEntitiesNamed:@"GroupTask"]  tl_enumerate:^(id task) {
		NSMutableString* workflow = [NSMutableString string];
		if ([[task valueForKey:@"copyFiles"] boolValue]) {
			[workflow appendString:@"copy files"];
		}
		if ([[task valueForKey:@"importFiles"] boolValue]) {
			if ([workflow length]) [workflow appendString:@", "];
			[workflow appendString:@"use iPhoto"];
		}
		if ([[task valueForKey:@"modifyOriginals"] boolValue]) {
			if ([workflow length]) [workflow appendString:@", "];
			[workflow appendString:@"modify originals"];
		}
		[taskDescriptions addObject:
		 [NSString stringWithFormat:@"Task set (%@) must be completed.", workflow]];
	}];
	return taskDescriptions;
}

- (void)notifyUpdate {
	NSDictionary* info = [NSDictionary dictionaryWithObject:[self tasks] forKey:TaskMasterCurrentTasks];
	NSNotification* n = [NSNotification notificationWithName:TaskMasterDidUpdateNotification 
													  object:me userInfo:info];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
														   withObject:n waitUntilDone:NO];
}

- (void)saveTasks {
	[Logger debugLog:@"--- Saving tasks file ---"];
	NSError* saveError;
	BOOL saved = [taskContext save:&saveError];
	if (!saved) {
		NSMutableString* failureLog = [NSMutableString stringWithFormat:@"saveTasks failed: %@", saveError];
		NSArray* details = [[saveError userInfo] objectForKey:NSDetailedErrorsKey];
		for (NSError* detail in details) {
			[failureLog appendFormat:@"\n\t%@", detail];
		}
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"Internal error", NSLocalizedDescriptionKey,
							  @"Tasks database could not be saved.",
							  NSLocalizedRecoverySuggestionErrorKey,
							  failureLog, NSLocalizedFailureReasonErrorKey, 
							  saveError, NSUnderlyingErrorKey, nil];
		[Logger logInfo:info severity:LoggerInternalError];
	}
	[self notifyUpdate];
}

- (void)prepareModel {
	NSString* momPath = [[NSBundle mainBundle] pathForResource:@"TaskStore" ofType:@"mom"];
	NSManagedObjectModel* mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:
								 [NSURL fileURLWithPath:momPath isDirectory:NO]];
	NSPersistentStoreCoordinator* storeCoordinator = [[NSPersistentStoreCoordinator alloc]
													  initWithManagedObjectModel:mom];
	
	NSError* internalError;
	id store = [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
											  configuration:nil
														URL:storeURL
													options:nil
													  error:&internalError];
	if (!store) {
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"Internal error", NSLocalizedDescriptionKey,
							  @"Could not create tasks database.",
							  NSLocalizedRecoverySuggestionErrorKey,
							  [NSString stringWithFormat:@"addPersistentStore at '%@' failed: %@",
							   [storeURL path], internalError], NSLocalizedFailureReasonErrorKey,
							  internalError, NSUnderlyingErrorKey, nil];
		[Logger logInfo:info severity:LoggerInternalError];
		return;
	}
	
	taskContext = [NSManagedObjectContext new];
	[taskContext setPersistentStoreCoordinator:storeCoordinator];
	[self notifyUpdate];
}

- (void)removeTask:(id)task {
	[Logger debugLog:@"Removing %@", [[task entity] name]];
	if ([[[task entity] name] isEqualToString:@"FileTask"]) {
		id metadata = [task valueForKey:@"metadata"];
		NSMutableSet* metadataOwners = [metadata mutableSetValueForKey:@"fileOwners"];
		[metadataOwners removeObject:task];
		if (![metadataOwners count]) {
			[taskContext deleteObject:metadata];
		}
	}
	else if ([[[task entity] name] isEqualToString:@"GroupTask"]) {
		NSString* taskFile = [task valueForKey:@"taskFile"];
		[Logger debugLog:@"Removing task file: %@", taskFile];
		[[NSFileManager new] removeItemAtPath:taskFile error:NULL];
	}
	[taskContext deleteObject:task];
	[self saveTasks];
}


#pragma mark File tasks

- (void)processFileTask:(id)task {
	NSString* path = [task valueForKey:@"path"];
	NSString* software = [task valueForKey:@"software"];
	NSDictionary* metadata = [[task valueForKey:@"metadata"] tl_setAttributes];
	if (software) {
		NSMutableDictionary* fileMetadata = [[metadata mutableCopy] autorelease];
		[fileMetadata setObject:software forKey:@"software"];
		metadata = fileMetadata;
	}
	[fileManager applyMetadata:metadata toFile:path respond:^{ 
		[me removeTask:task];
	}];
}

- (id)addFileTask:(NSString*)path metadata:(id)metadata software:(NSString*)software {
	[Logger debugLog:@"Adding FileTask"];
	id fileTask = [NSEntityDescription insertNewObjectForEntityForName:@"FileTask"
												inManagedObjectContext:taskContext];
	[fileTask setValue:path forKey:@"path"];
	[fileTask setValue:metadata forKey:@"metadata"];
	[fileTask setValue:software forKey:@"software"];
	[me processFileTask:fileTask];
	// save will happen when group file is removed
	return fileTask;
}


#pragma mark Photo tasks

- (void)processPhotoTask:(id)task {
	NSDictionary* metadata = [[task valueForKey:@"metadata"] tl_setAttributes];
	if (!metadata) metadata = [NSDictionary dictionary];
	NSString* album = [task valueForKey:@"album"];
	if (album) {
		NSMutableDictionary* photoMetadata = [[metadata mutableCopy] autorelease];
		[photoMetadata setObject:album forKey:@"album"];
		metadata = photoMetadata;
	}
	
	int64_t i = [[task valueForKey:@"identifier"] longLongValue];
	NSString* l = [task valueForKey:@"library"];
	[[Photos sharedManager] getPhotoIDForIdentifier:i inLibrary:l respond:^(id photoID) {
		if (photoID) {
			[[Photos sharedManager] applyMetadata:metadata toPhotoID:photoID respond:^{
				[me removeTask:task];
			}];
		}
		else {
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSString stringWithFormat:
								   @"Couldn't access Photo ID %llu via current iPhoto library", i],
								  NSLocalizedDescriptionKey,
								  [NSString stringWithFormat:
								   @"The library at '%@' must be open in iPhoto to set metadata.", l],
								  NSLocalizedRecoverySuggestionErrorKey,
								  [NSString stringWithFormat:
								   @"Received nil photoID for identifier %llu in library %@", i, l],
								  NSLocalizedFailureReasonErrorKey, nil];
			[Logger logInfo:info severity:LoggerWarning];
			[me removeTask:task];
		}
	}];
}

- (id)addPhotoTask:(id)photoID metadata:(id)metadata album:(NSString*)album {
	[Logger debugLog:@"Adding PhotoTask"];
	id photoTask = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoTask"
												 inManagedObjectContext:taskContext];
	int64_t i = [Photos identifierForPhotoID:photoID];
	[photoTask setValue:[NSNumber numberWithLongLong:i] forKey:@"identifier"];
	NSString* l = [Photos libraryForPhotoID:photoID];
	[photoTask setValue:l forKey:@"library"];
	[photoTask setValue:metadata forKey:@"metadata"];
	[photoTask setValue:album forKey:@"album"];
	// save will happen when group file is removed
	[me processPhotoTask:photoTask];
	return photoTask;
}


#pragma mark Group task juggernaut

- (void)removeGroupFileInfo:(id)info {
	[Logger debugLog:@"Removing group file info for %@", [info valueForKey:@"path"]];
	NSMutableSet* groupFiles = [[info valueForKey:@"group"] mutableSetValueForKey:@"files"];
	[groupFiles removeObject:info];
	[taskContext deleteObject:info];
	[self saveTasks];
}

- (void)processGroupTask:(id)task {
	BOOL copyFiles = [[task valueForKey:@"copyFiles"] boolValue];
	BOOL importFiles = [[task valueForKey:@"importFiles"] boolValue];
	BOOL modifyOriginals = [[task valueForKey:@"modifyOriginals"] boolValue];
	if (copyFiles) importFiles = YES;
	if (!modifyOriginals) importFiles = YES;
	
	NSSet* files = [task valueForKey:@"files"];
	NSString* software = nil;
	if (modifyOriginals) {
		software = [task valueForKey:@"software"];
	}
	
	PhotosImport* import = [PhotosImport new];
	import.forceCopy = copyFiles;
	import.hostFolder = [task valueForKey:@"taskFile"];
	NSOperation* subtasksCreated = TLAfter(import, me, nil);
	for (id fileInfo in files) {
		NSString* path = [fileInfo valueForKey:@"path"];
		id metadata = [fileInfo valueForKey:@"metadata"];
		if (!importFiles) {
			TLBefore(subtasksCreated, me, ^{
				[self addFileTask:path metadata:metadata software:software];
				[self removeGroupFileInfo:fileInfo];
			});
		}
		else if (modifyOriginals) {
			[import addFileToImport:path
							 before:
			 ^(NSOperation* importStarts) {
				 NSOperation* fileTaskCompleted = TLOpBefore(importStarts, nil);
				 TLBefore(subtasksCreated, me, ^{
					 id fileTask = [self addFileTask:path metadata:metadata software:software];
					 [self removeGroupFileInfo:fileInfo];
					 
					 // this lets import continue after file task completes
					 NSString* watchName = NSManagedObjectContextObjectsDidChangeNotification;
					 id taskWatcher = [[NSNotificationCenter defaultCenter] addObserverForName:watchName
																						object:taskContext
																						 queue:nil usingBlock:
									   ^(NSNotification* notification) {
										   NSSet* deletedObjects = [[notification userInfo]
																	objectForKey:NSDeletedObjectsKey];
										   if ([deletedObjects containsObject:fileTask]) {
											   [fileTaskCompleted start];
										   }
									   }];
					 CFRetain(taskWatcher);
					 [fileTaskCompleted setCompletionBlock:^{ CFRelease(taskWatcher); }];
				 });
			 }
							  after:
			 ^(BOOL neededImport, NSSet* photoIDs) {
				 if (neededImport) return;
				 NSOperation* allOriginalsFound = TLOpBefore(subtasksCreated, nil);
				 for (id photoID in photoIDs) {
					 NSOperation* originalsFound = TLOpBefore(allOriginalsFound, nil);
					 [[Photos sharedManager] findOriginals:photoID respond:
					  ^(NSArray* originalPaths) {
						  TLAs(me, ^{
							  for (NSString* originalPath in originalPaths) {
								  [self addFileTask:originalPath metadata:metadata software:software];
							  }
							  // NOTE: more correct only *after* file tasks complete, but...
							  [self addPhotoTask:photoID metadata:nil album:@"Rescan for Geotagalog"];
							  [originalsFound start];
						  });
					  }];
				 }
				 TLPerformBy(me, allOriginalsFound);
				 TLAfter(allOriginalsFound, me, ^{
					 [self removeGroupFileInfo:fileInfo];
				 });
			 }];
		}
		else {
			[import addFileToImport:path
							 before:nil
							  after:
			 ^(BOOL neededImport, NSSet* photoIDs) {
				 (void)neededImport;
				 TLBefore(subtasksCreated, me, ^{
					 for (id photoID in photoIDs) {
						 if (photoID == [NSNull null]) {
							 NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
												   @"Can't set photo metadata", NSLocalizedDescriptionKey,
												   [NSString stringWithFormat:
													@"Item information for '%@' was not found in "
													@"the iPhoto library after import.", path],
												   NSLocalizedRecoverySuggestionErrorKey,
												   @"Null photoID given after file import.",
												   NSLocalizedFailureReasonErrorKey, nil];
							 [Logger logInfo:info severity:LoggerWarning];
						 }
						 else [self addPhotoTask:photoID metadata:metadata album:nil];
					 }
					 [self removeGroupFileInfo:fileInfo];
				 });
			 }];
		}
	}
	[import performSelectorInBackground:@selector(start) withObject:nil];
	TLAfter(subtasksCreated, me, ^{
		[self removeTask:task];
	});
}

- (id)addGroupTask:(NSDictionary*)taskInfo {
	[Logger debugLog:@"Adding GroupTask"];
	id groupTask = [NSEntityDescription insertNewObjectForEntityForName:@"GroupTask"
												 inManagedObjectContext:taskContext];
	
	NSString* taskFile = [taskInfo objectForKey:@"taskBundle"];
	[groupTask setValue:taskFile forKey:@"taskFile"];
	
	NSUInteger workflow = [[taskInfo objectForKey:@"workflow"] integerValue];
	switch (workflow) {
		case 0:		// iPhoto database only
			[groupTask setValue:(id)kCFBooleanTrue forKey:@"importFiles"];
			[groupTask setValue:(id)kCFBooleanFalse forKey:@"modifyOriginals"];
			break;
		case 1:		// iPhoto originals 
			[groupTask setValue:(id)kCFBooleanTrue forKey:@"importFiles"];
			[groupTask setValue:(id)kCFBooleanTrue forKey:@"modifyOriginals"];
			break;
		case 2:		// files only
			[groupTask setValue:(id)kCFBooleanFalse forKey:@"importFiles"];
			[groupTask setValue:(id)kCFBooleanTrue forKey:@"modifyOriginals"];
			break;
	}
	
	BOOL copyFiles = [[taskInfo objectForKey:@"forceCopy"] boolValue];
	if (copyFiles) [groupTask setValue:(id)kCFBooleanTrue forKey:@"copyFiles"];
	else [groupTask setValue:(id)kCFBooleanFalse forKey:@"copyFiles"];
	
	NSString* software = [taskInfo objectForKey:@"software"];
	[groupTask setValue:software forKey:@"software"];
	
	NSDictionary* fileInfo = [taskInfo objectForKey:@"files"];
	NSMutableSet* groupFiles = [groupTask mutableSetValueForKey:@"files"];
	[fileInfo enumerateKeysAndObjectsUsingBlock:^(id path, id metadata, BOOL* stop) { (void)stop;
		id groupFile = [NSEntityDescription insertNewObjectForEntityForName:@"GroupFile"
													 inManagedObjectContext:taskContext];
		[groupFile setValue:path forKey:@"path"];
		[groupFiles addObject:groupFile];
		
		id fileMetadata = [NSEntityDescription insertNewObjectForEntityForName:@"Metadata"
														inManagedObjectContext:taskContext];
		[fileMetadata setValuesForKeysWithDictionary:metadata];
		[groupFile setValue:fileMetadata forKey:@"metadata"];
	}];
	
	[self saveTasks];
	[me processGroupTask:groupTask];
	return groupTask;
}

- (void)beginTasks {
	[Logger debugLog:@"Beginning tasks"];
	[[taskContext tl_fetchAllEntitiesNamed:@"FileTask"]  tl_enumerateConcurrently:^(id task) {
		[me processFileTask:task];
	}];
	[[taskContext tl_fetchAllEntitiesNamed:@"PhotoTask"] tl_enumerateConcurrently:^(id task) {
		[me processPhotoTask:task];
	}];
	[[taskContext tl_fetchAllEntitiesNamed:@"GroupTask"] tl_enumerateConcurrently:^(id task) {
		[me processGroupTask:task];
	}];
}

#pragma mark Public methods

- (void)begin {
	if (taskContext) return;
	[self prepareModel];
	[self beginTasks];
}

- (void)addTaskInfo:(NSDictionary*)taskInfo {
	if (!taskContext) {
		[self begin];
	}
	if (!taskContext) {
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"Can't continue without valid tasks database.", NSLocalizedDescriptionKey,
							  @"The task database failed to open, likely because it is in an old format or "
							  @"has become corrupt.", NSLocalizedRecoverySuggestionErrorKey,
							  @"No taskContext after begin/prepareModel",
							  NSLocalizedFailureReasonErrorKey, nil];
		[Logger logInfo:info severity:LoggerError];
		return;
	}
	
	// wrapped to avoid waiting for group task return value
	[self addGroupTask:taskInfo];
}

@end

