//
//  Logger.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "Logger.h"

#import "TLActor.h"
#import "NSManagedObjectContext+TLExtensions.h"
#import "NSArray+TLExtensions.h"


NSString* const LoggerDomain = @"com.calftrail.geotagalog.logged_error";
NSString* const LoggerDidUpdateNotification = @"LoggerDidUpdate";
NSString* const LoggerMessageErrors = @"Message error objects";


@implementation Logger

- (id)init {
	self = [super init];
	id me = nil;
	if (self) {
		me = [TLActor actorForTarget:self];
	}
	return me;
}

+ (id)sharedLogger {
	static id m;
	TLOnce(^{
		m = [Logger new];
	});
	return m;
}


#pragma mark Convenience helpers

+ (void)debugLog:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	NSDictionary* errInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
	NSError* err = [NSError errorWithDomain:LoggerDomain code:LoggerDebugging userInfo:errInfo];
	[[self sharedLogger] logError:err];
}

+ (void)informativeLog:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	NSDictionary* errInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
	NSError* err = [NSError errorWithDomain:LoggerDomain code:LoggerInformative userInfo:errInfo];
	[[self sharedLogger] logError:err];
}

+ (void)logInfo:(NSDictionary*)errInfo severity:(LoggerSeverity)severity {
	NSError* err = [NSError errorWithDomain:LoggerDomain code:severity userInfo:errInfo];
	[[self sharedLogger] logError:err];
}


#pragma mark Core routines

- (void)notifyUpdate {
	NSDictionary* info = [NSDictionary dictionaryWithObject:[self errors] forKey:LoggerMessageErrors];
	NSNotification* n = [NSNotification notificationWithName:LoggerDidUpdateNotification
													  object:[Logger sharedLogger] userInfo:info];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
														   withObject:n waitUntilDone:NO];
}

- (void)beginLoggingToURL:(NSURL*)storeURL {
	NSString* momPath = [[NSBundle mainBundle] pathForResource:@"LogStore" ofType:@"mom"];
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
	}
	
	logContext = [NSManagedObjectContext new];
	[logContext setPersistentStoreCoordinator:storeCoordinator];
	[self notifyUpdate];
}

- (void)saveLog {
	NSError* saveError;
	BOOL saved = [logContext save:&saveError];
	if (!saved) {
		NSLog(@"Could not save error log (%@)", saveError);
	}
	[self notifyUpdate];
}

- (NSArray*)errors {
	NSArray* messages = [logContext tl_fetchAllEntitiesNamed:@"Message" sort:TLSortBy(@"timestamp")];
	return [messages tl_arrayWithBlock:^(id message) {
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  [message valueForKey:@"timestamp"], @"Timestamp",
							  [message valueForKey:@"summary"], NSLocalizedDescriptionKey, 
							  [message valueForKey:@"details"], NSLocalizedRecoverySuggestionErrorKey,
							  [message valueForKey:@"reason"], NSLocalizedFailureReasonErrorKey, nil];
		NSInteger code = [[message valueForKey:@"severity"] intValue];
		return (id)[NSError errorWithDomain:LoggerDomain code:code userInfo:info];
	}];
}

- (void)logError:(NSError*)error {
	NSParameterAssert([[error domain] isEqualToString:LoggerDomain]);
	NSParameterAssert([[error userInfo] objectForKey:NSLocalizedDescriptionKey] != nil);
	
#if 0
	if ([error code] == LoggerDebugging) {
		printf("DEBUG: %s\n", [[error localizedDescription] UTF8String]);
	}
	else if ([error code] == LoggerInformative) {
		printf("%s\n", [[error localizedDescription] UTF8String]);
	}
	else NSLog(@"%@: %@ (%@)", [error localizedDescription],
			   [error localizedRecoverySuggestion], [error localizedFailureReason]);
#endif
	
	if (!logContext) return;
	id entry = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
											 inManagedObjectContext:logContext];
	[entry setValue:[NSDate date]
			 forKey:@"timestamp"];
	[entry setValue:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]
			 forKey:@"summary"];
	[entry setValue:[[error userInfo] objectForKey:NSLocalizedRecoverySuggestionErrorKey]
			 forKey:@"details"];
	[entry setValue:[[error userInfo] objectForKey:NSLocalizedFailureReasonErrorKey]
			 forKey:@"reason"];
	[entry setValue:[NSNumber numberWithInt:(int)[error code]]
			 forKey:@"severity"];
	[self saveLog];
}

- (void)clearAll {
	NSArray* messages = [logContext tl_fetchAllEntitiesNamed:@"Message"];
	[messages tl_enumerate:^(id message) {
		[logContext deleteObject:message];
	}];
	[self saveLog];
}

- (void)clearOld {
	NSTimeInterval oldAge = 3 * 24 * 60 * 60;
	NSDate* cutoffDate = [[NSDate date] dateByAddingTimeInterval:-oldAge];
	NSArray* messages = [logContext tl_fetchAllEntitiesNamed:@"Message"];
	[messages tl_enumerate:^(id message) {
		NSDate* messageDate = [message valueForKey:@"timestamp"];
		if ([messageDate compare:cutoffDate] < NSOrderedSame) {
			[logContext deleteObject:message];
		}
	}];
	[self saveLog];
}

@end
