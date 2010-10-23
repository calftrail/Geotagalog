//
//  TLNMEAFile.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLNMEAFile.h"

#import "TLNMEASentence.h"
#import "TLNMEAErrors.h"

#import "TLLineParser.h"
@interface TLNMEAFile () <TLLineParserDelegate> @end


@implementation TLNMEAFile

@synthesize sentences;
@synthesize warnings;

#pragma mark Lifecycle

- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)err {
	self = [super init];
	if (self) {
		sentences = [NSMutableArray new];
		warnings = [NSMutableArray new];
		
		
		TLLineParser* theParser = [[[TLLineParser alloc]
									initWithContentsOfURL:url] autorelease];
		[theParser setDelegate:self];
		[theParser parse];
		if ([theParser parserError]) {
			if (err) *err = [theParser parserError];
			[self release];
			return nil;
		}
		
		if (![sentences count]) {
			if (err) {
				*err = [NSError errorWithDomain:TLNMEAErrorDomain
										   code:TLNMEAFileNoSentences
									   userInfo:nil];
			}
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)lineParser:(TLLineParser*)theParser foundLine:(NSData*)lineData {
	(void)theParser;
	NSError* internalError;
	TLNMEASentence* sentence = [[TLNMEASentence alloc] initWithBytes:[lineData bytes]
															  length:[lineData length]
															   error:&internalError];
	if (!sentence) {
		//NSLog(@"Skipped line %lu reading NMEA file (%@)", (long unsigned)[theParser lineNumber], internalError);
		[warnings addObject:internalError];
		return;
	}
	
	[sentences addObject:sentence];
	[sentence release];
}


- (void)dealloc {
	[sentences release];
	[warnings release];
	[super dealloc];
}

@end
