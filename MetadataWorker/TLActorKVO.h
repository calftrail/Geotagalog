//
//  TLActorKVO.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLObserver : NSObject {
@private
	id object;
	NSString* keyPath;
	void (^block)(NSDictionary*);
}
- (id)initWithObject:(id)theObject keyPath:(NSString*)theKeyPath
			 options:(NSKeyValueObservingOptions)options
			   block:(void (^)(NSDictionary* change))theBlock;
- (void)remove;
@end

extern id TLWatch(id object, NSString* keyPath,
				  id target, void (^block)(NSDictionary* change));
