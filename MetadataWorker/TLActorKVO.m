//
//  TLActorKVO.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "TLActorKVO.h"

#import "TLActor.h"

typedef void (^observeBlock_t)(NSDictionary* change);

id TLWatch(id object, NSString* keyPath,
		   id target, observeBlock_t block)
{
	NSKeyValueObservingOptions options = (NSKeyValueObservingOptionInitial |
										  NSKeyValueObservingOptionNew);
	id watcher = [[TLObserver alloc]
				  initWithObject:object keyPath:keyPath
				  options:options block:
				  ^(NSDictionary* change) {
					  TLAs(target, ^{
						  block(change);
					  });
				  }];
	return [watcher autorelease];
}


@implementation TLObserver

- (id)initWithObject:(id)theObject keyPath:(NSString*)theKeyPath
			   options:(NSKeyValueObservingOptions)options block:(observeBlock_t)theBlock
{
	self = [super init];
	if (self) {
		object = [theObject retain];
		keyPath = [theKeyPath copy];
		block = [theBlock copy];
		[[object self] addObserver:self forKeyPath:keyPath
					options:options context:self];
	}
	return self;
}

- (void)dealloc {
	[self remove];
	[object release];
	[keyPath release];
	[block release];
	[super dealloc];
}

- (void)finalize {
	[self remove];
	[super finalize];
}

- (void)remove {
	[[object self] removeObserver:self forKeyPath:keyPath];
	[object release], object = nil;
}

- (void)observeValueForKeyPath:(NSString*)kp ofObject:(id)obj
						change:(NSDictionary*)change context:(void*)ctx
{
    if (ctx == self) {
		block(change);
	}
	else {
		[super observeValueForKeyPath:kp ofObject:obj change:change context:ctx];
	}
}

@end
