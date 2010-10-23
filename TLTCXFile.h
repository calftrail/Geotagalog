//
//  TLTCXFile.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLTCXFile : NSObject {
@private
	NSMutableArray* tracks;
	NSMutableArray* gatheredTrackPoints;
	NSMutableDictionary* gatheredTrackPointInfo;
	NSMutableString* gatheredCharacters;
}

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err;

@property (nonatomic, readonly) NSArray* tracks;

@end
