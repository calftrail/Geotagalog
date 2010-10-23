//
//  TLNMEAFile.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLNMEAFile : NSObject {
@private
	NSMutableArray* sentences;
	NSMutableArray* warnings;
}

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err;

@property (nonatomic, readonly) NSArray* sentences;
@property (nonatomic, readonly) NSArray* warnings;

@end
