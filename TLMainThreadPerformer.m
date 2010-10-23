//
//  TLMainThreadPerformer.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 1/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLMainThreadPerformer.h"

// based on http://nifty-box.com/blog/2006/12/nsinvocation-cleans-code.html

@interface TLMainThreadPerformer : NSObject {
@private
	id target;
	BOOL wait;
}
@end

@implementation TLMainThreadPerformer

- (id)initWithTarget:(id)theTarget shouldWait:(BOOL)shouldWait {
	self = [super init];
	if (self) {
		target = [theTarget retain];
		wait = shouldWait;
	}
	return self;
}

- (void)dealloc {
	[target release];
	[super dealloc];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	BOOL responds = [super respondsToSelector:aSelector];
	if (!responds) {
		responds = [target respondsToSelector:aSelector];
	}
	return responds;
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
	if (!signature) {
		signature = [target methodSignatureForSelector:aSelector];
	}
	return signature;
}

- (void)mainThreadInvoke:(NSInvocation*)theInvocation {
	[theInvocation invokeWithTarget:target];
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
	if ([[NSThread currentThread] isMainThread]) {
		[anInvocation invokeWithTarget:target];
	}
	else {
		[anInvocation retainArguments];
		[self performSelectorOnMainThread:@selector(mainThreadInvoke:)
							   withObject:anInvocation
							waitUntilDone:wait];
	}
}

@end


@implementation NSObject (TLMainThreadProxy)

- (id)tlMainThreadProxy {
	TLMainThreadPerformer* proxy = [[TLMainThreadPerformer alloc] initWithTarget:self
																	  shouldWait:NO];
	return [proxy autorelease];
}

- (id)tlMainThreadWait {
		TLMainThreadPerformer* proxy = [[TLMainThreadPerformer alloc] initWithTarget:self
																		  shouldWait:YES];
		return [proxy autorelease];
}

@end
