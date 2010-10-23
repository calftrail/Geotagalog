//
//  TLNMEASentence.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLNMEASentence.h"
#import "TLNMEAErrors.h"

@interface TLNMEASentence ()
@property (nonatomic, copy, readwrite) NSString* talkerID;
@property (nonatomic, copy, readwrite) NSString* messageType;
@property (nonatomic, retain, readwrite) NSArray* dataFields;

+ (BOOL)scanBytes:(const void*)bytes length:(NSUInteger)len
	  forTalkerID:(NSString**)theTalkerID
	  messageType:(NSString**)theMessageType
	   dataFields:(NSArray**)theDataFields
			error:(NSError**)err;
@end


@implementation TLNMEASentence

@synthesize talkerID;
@synthesize messageType;
@synthesize dataFields;

#pragma mark Lifecycle

// designated initializer
- (id)initWithTalkerID:(NSString*)theTalkerID
		   messageType:(NSString*)theMessageType
			dataFields:(NSArray*)theDataFields
{
	self = [super init];
	if (self) {
		[self setTalkerID:theTalkerID];
		[self setMessageType:theMessageType];
		[self setDataFields:theDataFields];
	}
	return self;
}

- (void)dealloc {
	[self setTalkerID:nil];
	[self setMessageType:nil];
	[self setDataFields:nil];
	[super dealloc];
}


#pragma mark Helper initializers

- (id)initWithBytes:(const void*)bytes length:(NSUInteger)len error:(NSError**)err {
	NSString* theTalkerID = nil;
	NSString* theMessageType = nil;
	NSArray* theDataFields = nil;
	BOOL success = [[self class] scanBytes:bytes length:len
							   forTalkerID:&theTalkerID messageType:&theMessageType dataFields:&theDataFields
									 error:err];
	if (!success) {
		[self release];
		return nil;
	}
	return [self initWithTalkerID:theTalkerID messageType:theMessageType dataFields:theDataFields];
}

- (id)initWithLine:(NSString*)logLine error:(NSError**)err {
	NSData* lineData = [logLine dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
	if (!lineData) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceBadCharactersError
								   userInfo:nil];
		}
		[self release];
		return nil;
	}
	return [self initWithBytes:[lineData bytes] length:[lineData length] error:err];
}


#pragma mark Parsing code

+ (BOOL)getTalkerID:(NSString**)theTalkerID
		messageType:(NSString**)theMessageType
		  fromBytes:(const void*)bytes
			 length:(NSUInteger)len
			  error:(NSError**)err
{
	if (len != 5) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceInvalidHeaderError
								   userInfo:nil];
		}
		return NO;
	}
	NSString* talker = [[[NSString alloc] initWithBytes:bytes
												 length:2
											   encoding:NSASCIIStringEncoding] autorelease];	
	NSString* type = [[[NSString alloc] initWithBytes:(bytes+2)
											   length:3
											 encoding:NSASCIIStringEncoding] autorelease];
	if (!talker || !type) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceBadCharactersError
								   userInfo:nil];
		}
		return NO;
	}
	
	if (theTalkerID) {
		*theTalkerID = talker;
	}
	if (theMessageType) {
		*theMessageType = type;
	}
	return YES;
}

+ (NSString*)dataFieldFromBytes:(const void*)bytes length:(NSUInteger)len
						  error:(NSError**)err
{
	NSString* field = [[[NSString alloc] initWithBytes:bytes
												length:len
											  encoding:NSASCIIStringEncoding] autorelease];
	if (!field) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceBadCharactersError
								   userInfo:nil];
		}
	}
	return field;
}

+ (BOOL)scanBytes:(const void*)bytes length:(NSUInteger)len
	  forTalkerID:(NSString**)theTalkerID
	  messageType:(NSString**)theMessageType
	   dataFields:(NSArray**)theDataFields
			error:(NSError**)err
{
	/* Available NMEA documentation states "A sentence may contain up to 80 characters plus '$' and CR/LF."
	 We allow this to be a little longer, but still check it to ensure sanity.
	 Documentation where constraint found: http://www.tronico.fi/OH6NT/docs/NMEA0183.pdf */
	static const size_t maximumSentenceLength = 100;
	if (len > maximumSentenceLength) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceTooLong
								   userInfo:nil];
		}
		return NO;
	}
	
	const char* currentPosition = bytes;
	const char* const endPosition = currentPosition + len;
	
	// scan to sentence start
	while (currentPosition < endPosition) {
		if (*currentPosition == '$') {
			break;
		}
		++currentPosition;
	}
	if (currentPosition == endPosition) {
		if (err) {
			*err = [NSError errorWithDomain:TLNMEAErrorDomain
									   code:TLNMEASentenceNotFoundError
								   userInfo:nil];
		}
		return NO;
	}
	++currentPosition;
	
	// scan fields
	unsigned char checksum = 0;
	bool checksumStarted = false;
	bool firstField = true;
	NSString* internalTalkerID = nil;
	NSString* internalMessageType = nil;
	NSMutableArray* internalDataFields = theDataFields ? [NSMutableArray array] : nil;
	while (currentPosition < endPosition) {
		const char* fieldStart = currentPosition;
		bool lineEndReached = false;
		while (currentPosition < endPosition) {
			char byte = *currentPosition;
			if (byte == '*') {
				checksumStarted = true;
				break;
			}
			else if (byte == '\n' || byte == '\r') {
				lineEndReached = true;
				break;
			}
			
			checksum ^= byte;
			if (byte == ',') {
				break;
			}
			++currentPosition;
		}
		if (currentPosition == endPosition) {
			lineEndReached = true;
		}
		
		size_t fieldLen = currentPosition - fieldStart;
		BOOL success = NO;
		NSError* internalError;
		if (firstField) {
			success = [self getTalkerID:&internalTalkerID messageType:&internalMessageType
							  fromBytes:fieldStart length:fieldLen
								  error:&internalError];
			firstField = false;
		}
		else {
			NSString* dataField = [self dataFieldFromBytes:fieldStart length:fieldLen
													 error:&internalError];
			if (dataField) {
				[internalDataFields addObject:dataField];
				success = YES;
			}
		}
		if (!success) {
			if (err) {
				*err = internalError;
			}
			return NO;
		}
		
		if (checksumStarted || lineEndReached) {
			break;
		}
		++currentPosition;
	}
	
	// check optional checksum
	if (checksumStarted) {
		++currentPosition;
		if (currentPosition + 2 > endPosition) {
			if (err) {
				*err = [NSError errorWithDomain:TLNMEAErrorDomain
										   code:TLNMEASentenceInvalidChecksumError
									   userInfo:nil];
			}
			return NO;
		}
		
		char buffer[3] = {0};
		buffer[0] = currentPosition[0];
		buffer[1] = currentPosition[1];
		char* checkPtr = NULL;
		char lineChecksum = (char)strtoul(buffer, &checkPtr, 16);
		if (checkPtr == buffer) {
			if (err) {
				*err = [NSError errorWithDomain:TLNMEAErrorDomain
										   code:TLNMEASentenceInvalidChecksumError
									   userInfo:nil];
			}
			return NO;
		}
		
		if (lineChecksum != checksum) {
			if (err) {
				*err = [NSError errorWithDomain:TLNMEAErrorDomain
										   code:TLNMEASentenceCorruptError
									   userInfo:nil];
			}
			return NO;
		}
	}
	
	//NSLog(@"'%@', '%@': %@", internalTalkerID, internalMessageType, internalDataFields);
	
	if (theTalkerID) *theTalkerID = internalTalkerID;
	if (theMessageType) *theMessageType = internalMessageType;
	if (theDataFields) *theDataFields = internalDataFields;
	return YES;
}

@end
