//
//  NSOperationQueue+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOperationQueue (TLExtensions)
+ (id)tl_serialQueue;
- (id)tl_prepareOperationWithTarget:(id)target;
@end


static inline void TLOnMain(void (^block)(void)) {
	[[NSOperationQueue mainQueue] addOperationWithBlock:block];
}

static inline void TLOnQueue(NSOperationQueue* q, void (^block)(void)) {
	[q addOperationWithBlock:block];
}

static inline NSOperation* TLOp(void (^block)(void)) {
	return (block) ? [NSBlockOperation blockOperationWithBlock:block] : [[NSOperation new] autorelease];
}

static inline NSOperation* TLOpBefore(NSOperation* op, void (^block)(void)) {
	NSOperation* dep = TLOp(block);
	[op addDependency:dep];
	return dep;
}

static inline NSOperation* TLOpAfter(NSOperation* dep, void (^block)(void)) {
	NSOperation* op = TLOp(block);
	[op addDependency:dep];
	return op;
}

