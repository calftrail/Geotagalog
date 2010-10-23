//
//  NSManagedObjectContext+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSManagedObjectContext+TLExtensions.h"


@implementation NSManagedObjectContext (TLExtensions)

- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName
								sort:(NSArray*)sortDescriptors
							   error:(NSError**)err
{
	NSFetchRequest* request = [NSFetchRequest new];
	request.entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
	request.sortDescriptors = sortDescriptors;
	NSArray* result = [self executeFetchRequest:request error:err];
	[request release];
	return result;
}

- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName
								sort:(NSArray*)sortDescriptors
{
	return [self tl_fetchAllEntitiesNamed:entityName sort:sortDescriptors error:NULL];
}

- (NSArray*)tl_fetchAllEntitiesNamed:(NSString*)entityName {
	return [self tl_fetchAllEntitiesNamed:entityName sort:nil error:NULL];
}

@end


NSArray* TLSortBy(NSString* key) {
	return [NSArray arrayWithObject:
			[NSSortDescriptor sortDescriptorWithKey:key ascending:YES]];
}

NSArray* TLSort(NSString* firstKey, ...) {
	va_list args;
	va_start(args, firstKey);
	
	NSMutableArray* sortDescriptors = [NSMutableArray array];
	NSString* key = firstKey;
	while (key) {
		[sortDescriptors addObject:
		 [NSSortDescriptor sortDescriptorWithKey:key ascending:YES]];
		key = va_arg(args, NSString*);
	}
	return sortDescriptors;
}
