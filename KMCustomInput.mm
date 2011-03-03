//
//  KMCustomInput.m
//  KineticModelingShell
//
//  Created by Yang Yang on 11/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "KMCustomInput.h"
#import "KMData.h"
#import "KMCustomCompartment.h"

@implementation KMCustomInput
@synthesize inputname;
@synthesize rect;
@synthesize destination;
@synthesize isSelected;
@synthesize inputData;
@synthesize initial;
@synthesize upperbound;
@synthesize lowerbound;
@synthesize optimize;

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init];
	if(!self) return nil;
	
	//do not save loaded data!
	self.inputname		= [aDecoder decodeObjectForKey:@"Name"];
	self.destination	= [aDecoder decodeObjectForKey:@"Destination"];
	self.rect			= NSRectFromString([aDecoder decodeObjectForKey:@"Rect"]);
	initial				= [[aDecoder decodeObjectForKey:@"Initial"] doubleValue];
	upperbound			= [[aDecoder decodeObjectForKey:@"Upperbound"] doubleValue];
	lowerbound			= [[aDecoder decodeObjectForKey:@"Lowerbound"] doubleValue];
	optimize			= [[aDecoder decodeObjectForKey:@"Optimize"]	boolValue];
	
	isSelected= FALSE;
	return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:[NSNumber numberWithDouble:upperbound] forKey:@"Upperbound"];
	[aCoder encodeObject:[NSNumber numberWithDouble:lowerbound] forKey:@"Lowerbound"];
	[aCoder encodeObject:[NSNumber numberWithDouble:initial]	forKey:@"Initial"];
	[aCoder encodeObject:[NSNumber numberWithBool:optimize]		forKey:@"Optimize"];
	[aCoder encodeObject:inputname forKey:@"Name"];
	[aCoder encodeObject:destination forKey:@"Destination"];
	[aCoder encodeObject:NSStringFromRect(rect) forKey:@"Rect"];
}


-(BOOL)validInput
{
	if(!inputData || !destination)
		return NO;
	else 
		return YES;
}


-(id)initWithName:(NSString*)name
{
	self = [super init];
	if(!self) return nil;
	
	self.inputname	 = name;
	destination  = nil;
	rect		 = NSMakeRect(0, 0, 1, 1);
	isSelected   = FALSE;
	self.initial = 0.1;
	self.upperbound = 1;
	self.lowerbound = 0;
	self.optimize = YES;
	return self;
}

-(void) dealloc
{
	self.inputname =nil;
	self.inputData = nil;
	self.destination = nil;
	self.inputData = nil;
	[super dealloc];
}


-(NSString*)description{
	if(destination)
		return [NSString stringWithFormat:@"Name: %@, destination:%@",inputname, [destination compartmentname]];
	else {
		return inputname;
	}

}

@end
