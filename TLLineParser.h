//
//  TLLineParser.h
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol TLLineParserDelegate;

@interface TLLineParser : NSObject {
@private
	NSURL* fileURL;
	id<TLLineParserDelegate> delegate;
	BOOL preserveEndings;
	BOOL shouldAbort;
	NSUInteger lineNumber;
	NSError* parserError;
}

- (id)initWithContentsOfURL:(NSURL*)theFileURL;
@property (nonatomic, assign) id<TLLineParserDelegate> delegate;
@property (nonatomic, assign) BOOL preserveEndings;

- (BOOL)parse;
- (void)abortParsing;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, readonly) NSError* parserError;

@end


@protocol TLLineParserDelegate <NSObject>
@optional
- (void)lineParser:(TLLineParser*)theParser foundLine:(NSData*)lineData;
@end
