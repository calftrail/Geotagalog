//
//  TLGPXTrackSegment.m
//  Mercatalog
//
//  Created by Nathan Vander Wilt on 3/17/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLGPXTrackSegment.h"
#import "TLGPXWaypoint.h"

@implementation TLGPXTrackSegment

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
		trackpoints = [[NSMutableArray array] retain];
	}
	return self;
}

- (void)dealloc {
	[trackpoints release];
	[super dealloc];
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
	attributes:(NSDictionary*)attributeDict
{
	(void)namespaceURI;
	(void)qualifiedName;
	(void)attributeDict;
	if ([elementName isEqualToString:@"trkpt"]) {
		TLGPXWaypoint* newTrackpoint = [[TLGPXWaypoint alloc] initWithParent:self
																forElement:elementName
															  namespaceURI:namespaceURI
															 qualifiedName:qualifiedName
																attributes:attributeDict];
		[parser setDelegate:newTrackpoint];
		[trackpoints addObject:[newTrackpoint autorelease]];
	}
}

#pragma mark Accessors

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	return [trackpoints countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSArray*)trackpoints {
	return trackpoints;
}

@end
