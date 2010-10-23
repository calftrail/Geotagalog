//
//  TLGraticuleMapLayer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 2/25/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLMapLayer.h"


@interface TLGraticuleMapLayer : TLMapLayer {
@private
	const void* gridlines;
}

@end
