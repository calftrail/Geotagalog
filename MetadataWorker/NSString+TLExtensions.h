//
//  NSString+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/25/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (TLExtensions)
+ (id)tl_stringAutodetectedFromData:(NSData*)data;
- (NSURL*)tl_fileURL;
@end
