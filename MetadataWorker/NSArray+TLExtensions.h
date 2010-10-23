//
//  NSArray+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (TLExtensions)
+ (id)tl_arrayWithCount:(NSUInteger)count block:(id (^)(NSUInteger idx))block;
- (id)tl_arrayWithBlock:(id (^)(id val))block;
- (void)tl_enumerate:(void (^)(id val))block;
- (void)tl_enumerateConcurrently:(void (^)(id val))block;
- (NSArray*)tl_reversedArray;
@end
