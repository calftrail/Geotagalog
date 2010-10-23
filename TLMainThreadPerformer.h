//
//  TLMainThreadPerformer.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 1/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (TLMainThreadProxy)
- (id)tlMainThreadProxy;
- (id)tlMainThreadWait;
@end
