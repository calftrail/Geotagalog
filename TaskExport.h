//
//  TaskExport.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ExportController.h"


@interface TaskExport : ExportController {
@private
	NSMutableDictionary* taskInfo;
	NSURL* exportURL;
}
+ (void)relaunchWorker;
@end
