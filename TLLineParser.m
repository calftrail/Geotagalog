//
//  TLLineParser.m
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLLineParser.h"


@interface TLLineParser ()
- (void)setParserError:(NSError*)newParserError;
@end

@implementation TLLineParser

@synthesize delegate;
@synthesize preserveEndings;
@synthesize lineNumber;
@synthesize parserError;


- (void)setParserError:(NSError*)newParserError {
	[parserError autorelease];
	parserError = [newParserError retain];
}

- (id)initWithContentsOfURL:(NSURL*)theFileURL {
	self = [super init];
	if (self) {
		fileURL = [theFileURL copy];
	}
	return self;
}

- (void)dealloc {
	[fileURL release];
	delegate = nil;
	[parserError release];
	[super dealloc];
}


- (BOOL)parse {
	NSError* internalError;
	NSData* fileData = [NSData dataWithContentsOfURL:fileURL
											 options:NSMappedRead
											   error:&internalError];
	if (!fileData) {
		parserError = [internalError retain];
		return NO;
	}
	
	const char* currentPosition = [fileData bytes];
	const char* endPosition = currentPosition + [fileData length];
	
	// process each line
	lineNumber = 1;
	const char* lineStart = currentPosition;
	while (lineStart < endPosition) {
		// scan to beginning of next line
		const char* lineEnd = NULL;
		while (currentPosition < endPosition) {
			char byte = *currentPosition;
			++currentPosition;
			if (byte == '\n' || byte == '\r') {
				// previous line is ending, set signal
				if (!lineEnd) lineEnd = (currentPosition-1);
			}
			else if (lineEnd) {
				// a new line has now begun, "push back" its first character
				--currentPosition;
				break;
			}
		}
		
		ptrdiff_t lineLength = (lineEnd && ![self preserveEndings] ?
								lineEnd : currentPosition) - lineStart;
		NSData* lineData = [NSData dataWithBytesNoCopy:(void*)lineStart
												length:lineLength
										  freeWhenDone:NO];
		
		NSAutoreleasePool* pool = [NSAutoreleasePool new];
		if ([[self delegate] respondsToSelector:@selector(lineParser:foundLine:)]) {
			[[self delegate] lineParser:self foundLine:lineData];
		}
		[pool drain];
		
		if (shouldAbort) {
			// TODO: set error?
			break;
		}
		
		if (!lineEnd) {
			// if the line scan loop ended without newline, we break because it's EOF
			break;
		}
		++lineNumber;
		lineStart = currentPosition;
	}
	return YES;
}

- (void)abortParsing {
	shouldAbort = YES;
}

@end
