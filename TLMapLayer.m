//
//  TLMapLayer.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLMapLayer.h"
#import "TLMapView.h"

#import "TLMapLayer+HostInternals.h"
#import "TLMapView+HostInternals.h"


@implementation TLMapLayer

#pragma mark Lifecylce

- (id)init {
	self = [super init];
	if (self) {
		// ...
	}
	return self;
}

- (void)dealloc {
	// ...
	[super dealloc];
}


#pragma mark "Stuff"

@synthesize active;
@synthesize hidden;

- (void)removeFromHost {
	[host removeLayer:self];
}

- (void)setNeedsDisplay {
	[[self host] setLayerNeedsDisplay:self];
}


#pragma mark Old map layer subclass compatibility

- (void)drawInContext:(CGContextRef)ctx withInfo:(id < TLMapInfo >)mapInfo {
	(void)ctx;
	(void)mapInfo;
}

@end


@implementation TLMapLayer (TLMapLayerHostInternals)

- (TLMapView*)host {
	return host;
}

- (void)setHost:(TLMapView*)aHost {
	host = aHost;
}

@end


