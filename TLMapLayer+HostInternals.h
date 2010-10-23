//
//  TLMapLayer+HostInternals.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 9/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLMapView;

@interface TLMapLayer (TLMapLayerHostInternals)

@property (nonatomic, assign) TLMapView* host;

@end
