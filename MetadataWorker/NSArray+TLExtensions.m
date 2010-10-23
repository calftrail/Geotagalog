//
//  NSArray+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSArray+TLExtensions.h"


@implementation NSArray (TLExtensions)

+ (id)tl_arrayWithCount:(NSUInteger)count block:(id (^)(NSUInteger idx))block {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
	for (NSUInteger idx = 0; idx < count; ++idx) {
		id val = block(idx);
		if (!val) break;
		[array addObject:val];
	}
	return array;
}

- (id)tl_arrayWithBlock:(id (^)(id val))block {
	NSUInteger count = [self count];
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
	for (id obj in self) {
		id val = block(obj);
		if (!val) break;
		[array addObject:val];
	}
	return array;
}

- (void)tl_enumerate:(void (^)(id val))block {
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
		(void)idx;
		(void)stop;
		block(obj);
	}];
}

- (void)tl_enumerateConcurrently:(void (^)(id val))block {
	[self enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
		(void)idx;
		(void)stop;
		block(obj);
	}];
}

- (NSArray*)tl_reversedArray {
	NSMutableArray* reversed = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator* reverseEnum = [self reverseObjectEnumerator];
    for (id obj in reverseEnum) {
        [reversed addObject:obj];
    }
    return reversed;
}

@end
