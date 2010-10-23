//
//  NSOperationQueue+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSOperationQueue+TLExtensions.h"


@interface TLOperationGrabber : NSProxy {
@private
	NSOperationQueue* queue;
	id target;
}
+ (id)operationGrabberForQueue:(NSOperationQueue*)theQueue
						target:(id)theTarget;
@end


@implementation NSOperationQueue (TLExtensions)

+ (id)tl_serialQueue {
	NSOperationQueue* q = [NSOperationQueue new];
	[q setMaxConcurrentOperationCount:1];
	return [q autorelease];
}

- (id)tl_prepareOperationWithTarget:(id)target {
	return [TLOperationGrabber operationGrabberForQueue:self target:target];
}

@end


@implementation TLOperationGrabber

- (id)initWithQueue:(NSOperationQueue*)theQueue
			 target:(id)theTarget
{
	queue = [theQueue retain];
	target = [theTarget retain];
	return self;
}

- (void)dealloc {
	[queue release];
	[target release];
	[super dealloc];
}

+ (id)operationGrabberForQueue:(NSOperationQueue*)theQueue
						target:(id)theTarget
{
	id grabber = [[TLOperationGrabber alloc] initWithQueue:theQueue
													target:theTarget];
	return [grabber autorelease];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
	return [target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation*)theInvocation {
	[theInvocation setTarget:target];
	NSOperation* op = [[NSInvocationOperation alloc] initWithInvocation:theInvocation];
	[queue addOperation:op];
	[op release];
}

@end
