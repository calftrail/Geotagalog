//
//  TLGPXNode.h
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLGPXNode : NSObject {
@protected
	__weak TLGPXNode* parent;
	NSString* hostElement;	// freed when didEnd
@private
	BOOL gatheringCharacters;
	NSString* currentCharacters;	// freed when didEnd and when not gathering
}

- (id)initWithParent:(TLGPXNode*)theParent
		  forElement:(NSString*)elementName
		namespaceURI:(NSString*)namespaceURI
	   qualifiedName:(NSString*)qualifiedName
		  attributes:(NSDictionary*)attributes;

- (void)setGatheringCharacters:(BOOL)gather;
- (BOOL)isGatheringCharacters;
- (NSString*)gatheredCharacters;

@end
