//
//  NSManagedObjectContext+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObjectContext (TLExtensions)

- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName;
- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName
								sort:(NSArray*)sortDescriptors;
- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName
								sort:(NSArray*)sortDescriptors
							   error:(NSError**)err;

@end

NSArray* TLSortBy(NSString* key);
NSArray* TLSort(NSString* firstKey, ...) NS_REQUIRES_NIL_TERMINATION;
