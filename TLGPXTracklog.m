//
//  TLGPXTracklog.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLGPXTracklog.h"


@implementation TLGPXTracklog

#pragma mark Initialization from XML

- (id)initWithParent:(TLGPXNode*)theParent
		  forElement:(NSString*)elementName
		namespaceURI:(NSString*)namespaceURI
	   qualifiedName:(NSString*)qualifiedName
		  attributes:(NSDictionary*)attributes
{
	self = [super initWithParent:theParent
					  forElement:elementName
					namespaceURI:namespaceURI
				   qualifiedName:qualifiedName
					  attributes:attributes];
	if (self) {
		segments = [[NSMutableArray array] retain];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[segments release];
	[super dealloc];
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
	attributes:(NSDictionary*)attributeDict
{
	(void)namespaceURI;
	(void)qualifiedName;
	if ([elementName isEqualToString:@"trkseg"]) {
		TLGPXTrackSegment* newSegment = [[TLGPXTrackSegment alloc] initWithParent:self
																	 forElement:elementName
																   namespaceURI:namespaceURI
																  qualifiedName:qualifiedName
																	 attributes:attributeDict];
		[parser setDelegate:newSegment];
		[segments addObject:[newSegment autorelease]];
	}
	else if ([elementName isEqualToString:@"name"]) {
		[self setGatheringCharacters:YES];
	}
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
{
	if ([elementName isEqualToString:@"name"]) {
		name = [[NSString stringWithString:[self gatheredCharacters]] retain];
		[self setGatheringCharacters:NO];
	}
	else {
		[super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName];
	}
}

#pragma mark Accessors

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	return [segments countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
