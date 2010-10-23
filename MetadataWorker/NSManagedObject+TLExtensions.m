//
//  NSManagedObject+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSManagedObject+TLExtensions.h"


@implementation NSManagedObject (TLExtensions)

- (NSDictionary*)tl_allAttributes {
	NSArray* keys = [[[self entity] attributesByName] allKeys];
	return [self dictionaryWithValuesForKeys:keys];
}

- (NSDictionary*)tl_setAttributes {
	NSArray* keys = [[[self entity] attributesByName] allKeys];
	NSMutableDictionary* a = [NSMutableDictionary dictionary];
	for (NSString* key in keys) {
		id value = [self valueForKey:key];
		if (value) [a setObject:value forKey:key];
	}
	return a;
}

@end
