//
//  TLPhoto.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TLPhotoSourceItem;
@class TLLocation, TLTimestamp;

@interface TLPhoto : NSObject {
@private
	TLPhotoSourceItem* item;
	TLLocation* location;
	TLTimestamp* timestamp;
	NSTimeZone* timeZone;
}

- (id)initWithItem:(TLPhotoSourceItem*)theItem;

@property (nonatomic, retain, readonly) TLPhotoSourceItem* item;

@property (nonatomic, copy) TLLocation* location;
@property (nonatomic, copy) TLTimestamp* timestamp;
@property (nonatomic, copy) NSTimeZone* timeZone;

- (CGImageRef)newThumbnailForSize:(CGFloat)pixelWidth;

@end
