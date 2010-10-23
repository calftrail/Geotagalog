//
//  TaskMaster.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const TaskMasterDidUpdateNotification;
extern NSString* const TaskMasterCurrentTasks;


@class Photos, Files;

@interface TaskMaster : NSObject {
@private
	TaskMaster* me;
	NSURL* storeURL;
	NSManagedObjectContext* taskContext;
	Files* fileManager;
}

- (void)begin;
- (void)addTaskInfo:(NSDictionary*)taskInfo;

@end
