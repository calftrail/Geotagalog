//
//  TLGPXNode.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLGPXNode.h"


@implementation TLGPXNode

- (id)initWithParent:(TLGPXNode*)theParent
		  forElement:(NSString*)elementName
		namespaceURI:(NSString*)namespaceURI
	   qualifiedName:(NSString*)qualifiedName
		  attributes:(NSDictionary*)attributes
{
	(void)namespaceURI;
	(void)qualifiedName;
	(void)attributes;
	self = [super init];
	if (self) {
		parent = theParent;
		hostElement = [elementName retain];
	}
	return self;
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
{
	(void)namespaceURI;
	(void)qualifiedName;
	if ([elementName isEqualToString:hostElement]) {
		[hostElement release];
		hostElement = nil;
		[currentCharacters release];
		currentCharacters = nil;
		[parser setDelegate:parent];
	}
}

- (void)setGatheringCharacters:(BOOL)gather {
	gatheringCharacters = gather;
	if (!gather) {
		[currentCharacters release];
		currentCharacters = nil;
	}
}

- (BOOL)isGatheringCharacters {
	return gatheringCharacters;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	(void)parser;
	if (!gatheringCharacters) return;
	if (currentCharacters) {
		NSString* oldString = currentCharacters;
		currentCharacters = [[currentCharacters stringByAppendingString:string] retain];
		[oldString release];
	}
	else {
		currentCharacters = [[NSString stringWithString:string] retain];
	}
}

- (NSString*)gatheredCharacters {
	return currentCharacters;
}

@end
