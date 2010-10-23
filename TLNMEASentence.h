//
//  TLNMEASentence.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLNMEASentence : NSObject {
@private
	NSString* talkerID;
	NSString* messageType;
	NSArray* dataFields;
}

// designated initializer
- (id)initWithTalkerID:(NSString*)theTalkerID
		   messageType:(NSString*)theMessageType
			dataFields:(NSArray*)theDataFields;

- (id)initWithBytes:(const void*)bytes length:(NSUInteger)len error:(NSError**)err;
- (id)initWithLine:(NSString*)logLine error:(NSError**)err;

@property (nonatomic, copy, readonly) NSString* talkerID;
@property (nonatomic, copy, readonly) NSString* messageType;
@property (nonatomic, retain, readonly) NSArray* dataFields;

@end

