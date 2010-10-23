//
//  NSString+TLExtensions.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/25/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "NSString+TLExtensions.h"


@implementation NSString (TLExtensions)

+ (id)tl_stringAutodetectedFromData:(NSData*)data {
	// from http://www.mikeash.com/pyblog/friday-qa-2010-02-19-character-encodings.html
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string) {
        string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	}
    if (!string) {
        string = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
	}
	return [string autorelease];
}

- (NSURL*)tl_fileURL {
	return [NSURL fileURLWithPath:self];
}

@end
