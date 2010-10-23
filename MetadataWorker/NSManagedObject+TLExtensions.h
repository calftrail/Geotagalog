//
//  NSManagedObject+TLExtensions.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/16/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObject (TLExtensions)

- (NSDictionary*)tl_allAttributes;
- (NSDictionary*)tl_setAttributes;

@end
