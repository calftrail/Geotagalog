//
//  TLActor.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLActor : NSProxy {
@private
	id target;
	NSOperationQueue* queue;
	void* obsInfo;
}
+ (id)actorForTarget:(id)theTarget;
@end

extern void TLPerformBy(id target, NSOperation* op);
extern NSOperation* TLAs(id target, void (^block)(void));
extern NSOperation* TLBefore(NSOperation* op, id target, void (^block)(void));
extern NSOperation* TLAfter(NSOperation* dep, id target, void (^block)(void));

// NOTE: nesting would work but triggers -Wshadow
#define TLOnce(block) \
	do { static dispatch_once_t tl1_pred; dispatch_once(&tl1_pred, block); } while (0)
