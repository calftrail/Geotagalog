//
//  TLIGCFile.h
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLLineParser;


@interface TLIGCFile : NSObject {
@private
	__weak TLLineParser* parser;
	NSMutableDictionary* header;
	NSMutableDictionary* headerSources;
	NSMutableArray* fixes;
}

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err;

@property (nonatomic, readonly) NSDictionary* header;
@property (nonatomic, readonly) NSDictionary* headerSources;
@property (nonatomic, readonly) NSMutableArray* fixes;

@end

extern NSString* const TLIGCHeaderSourceRecorder;
extern NSString* const TLIGCHeaderSourceRecorder;
extern NSString* const TLIGCHeaderSourceObserver;
extern NSString* const TLIGCHeaderSourcePilot;
extern NSString* const TLIGCDateKey;
extern NSString* const TLIGCDatumKey;
extern NSString* const TLIGCDatumWGS84;
extern NSString* const TLIGCDatumTextKey;
extern NSString* const TLIGCFixTimeKey;
extern NSString* const TLIGCFixLatitudeKey;
extern NSString* const TLIGCFixLongitudeKey;
extern NSString* const TLIGCFixPressureAltitudeKey;
extern NSString* const TLIGCFixValidityKey;
extern NSString* const TLIGCFixValidity2D;
extern NSString* const TLIGCFixValidity3D;
extern NSString* const TLIGCFixGeoidAltitudeKey;
extern NSString* const TLIGCFixAccuracyKey;
extern NSString* const TLIGCFixEngineNoiseKey;
