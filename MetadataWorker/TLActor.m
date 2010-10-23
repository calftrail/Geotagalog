//
//  TLActor.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "TLActor.h"

static inline void logMethod(id object, SEL selector) {
	(void)logMethod;
	printf("%c[%s %s]\n",
		   ([object class] != object) ? '-' : '+',
		   [NSStringFromClass([object class]) UTF8String],
		   [NSStringFromSelector(selector) UTF8String]);
}

static void logInvocation(NSInvocation* inv) {
	(void)logInvocation;
	NSMethodSignature* sig = [inv methodSignature];
	for (NSUInteger argIdx = 0; argIdx < [sig numberOfArguments]; ++argIdx) {
		if (argIdx) printf(" ");
		printf("%s", [sig getArgumentTypeAtIndex:argIdx]);
	}
	printf(" -> %s\n", [sig methodReturnType]);
}


@implementation TLActor

- (id)initWithTarget:(id)theTarget {
	target = [theTarget retain];
	queue = [NSOperationQueue new];
	[queue setMaxConcurrentOperationCount:1];
	return self;
}

- (void)dealloc {
	[target release];
	[queue release];
	[super dealloc];
}

+ (id)actorForTarget:(id)theTarget {
	id actor = [[TLActor alloc] initWithTarget:theTarget];
	return [actor autorelease];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
	return [target methodSignatureForSelector:aSelector];
}

+ (void)copyInvocationBlockArguments:(NSInvocation*)inv {
	NSMethodSignature* sig = [inv methodSignature];
	NSUInteger numArgs = [sig numberOfArguments];
	for (NSUInteger argIdx = 2; argIdx < numArgs; ++argIdx) {
		static const char* blockType = @encode(void (^)(void));
		const char* argType = [sig getArgumentTypeAtIndex:argIdx];
		if (!strcmp(argType, blockType)) {
			id blockArg;
			[inv getArgument:&blockArg atIndex:argIdx];
			blockArg = [blockArg copy];
			[inv setArgument:&blockArg atIndex:argIdx];
			[blockArg autorelease];
		}
	}
	[inv retainArguments];
}

+ (BOOL)mustWaitForInvocation:(NSInvocation*)inv {
	// NOTE: what about return-by-reference? should we pay attention to DO qualifiers?
	return ([[inv methodSignature] methodReturnLength]) ? YES : NO;
}

- (void)forwardInvocation:(NSInvocation*)theInvocation {
	//logInvocation(theInvocation);
	//logMethod(target, [theInvocation selector]);
	//printf("\n");
	
	[theInvocation setTarget:target];
	BOOL rethrowExceptions = YES;
	BOOL waitForReturn = [[self class] mustWaitForInvocation:theInvocation];
	if (!waitForReturn) {
		[[self class] copyInvocationBlockArguments:theInvocation];
	}
	NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithInvocation:theInvocation];
	[queue addOperation:op];
	if (waitForReturn) {
		//printf("\tSynchronous actor method: waiting.\n");
		[op waitUntilFinished];
	}
	if (rethrowExceptions) [op setCompletionBlock:^{
		NSException* eee = [op valueForKey:@"exception"];
		if (eee) {
			@throw eee;
		}
		
		return;
		@try {
			[op result];
		}
		@catch (NSException* e) {
			if (![[e name] isEqualToString:NSInvocationOperationVoidResultException]) {
				@throw;
			}
		}
	}];
	[op release];
}

- (NSOperationQueue*)queue {
	return queue;
}

- (id)self {
	return target;
}

@end


#define CHECK_ACTOR(target) \
	NSCAssert([target class] == [TLActor class], @"Target not an actor!");

static inline NSOperation* TLOp(void (^block)(void)) {
	return (block) ? [NSBlockOperation blockOperationWithBlock:block] : [[NSOperation new] autorelease];
}

void TLPerformBy(id target, NSOperation* op) {
	CHECK_ACTOR(target);
	[[(TLActor*)target queue] addOperation:op];
}

NSOperation* TLAs(id target, void (^block)(void)) {
	id op = TLOp(block);
	TLPerformBy(target, op);
	return op;
}

NSOperation* TLBefore(NSOperation* op, id target, void (^block)(void)) {
	id dep = TLOp(block);
	[op addDependency:dep];
	TLPerformBy(target, dep);
	return dep;
}

NSOperation* TLAfter(NSOperation* dep, id target, void (^block)(void)) {
	id op = TLOp(block);
	[op addDependency:dep];
	TLPerformBy(target, op);
	return op;
}

