//
//  TLPhoto.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLPhoto.h"

#import "TLPhotoSourceItem.h"

@interface TLPhoto ()
@property (nonatomic, retain, readwrite) TLPhotoSourceItem* item;
@end


@implementation TLPhoto

@synthesize item;
@synthesize location;
@synthesize timestamp;
@synthesize timeZone;

- (id)initWithItem:(TLPhotoSourceItem*)theItem {
	self = [super init];
	if (self) {
		[self setItem:theItem];
	}
	return self;
}

- (void)dealloc {
	[self setItem:nil];
	[super dealloc];
}

- (CGImageRef)newThumbnailForSize:(CGFloat)pixelWidth {
	return [[self item] newThumbnailForSize:pixelWidth options:nil error:NULL];
}

@end
