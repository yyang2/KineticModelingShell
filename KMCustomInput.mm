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

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init];
	if(!self) return nil;
	
	// do not save loaded data!
	inputname	 = [aDecoder decodeObjectForKey:@"Name"];
	destination  = [aDecoder decodeObjectForKey:@"Destination"];
	rect		 = NSRectFromString([aDecoder decodeObjectForKey:@"Rect"]);
	isSelected	 = FALSE;
	return self;
}

-(BOOL)validInput
{
	if(!inputData || !destination)
		return NO;
	else 
		return YES;
}

-(BOOL)setData:(KMData*)d
{
	if(inputData) [inputData release];
	inputData = [d retain];
	return YES;
}

-(id)initWithName:(NSString*)name
{
	self = [super init];
	if(!self) return nil;
	
	inputname	 = [name retain];
	destination  = nil;
	rect		 = NSMakeRect(0, 0, 1, 1);
	isSelected   = FALSE;
	return self;
}

-(KMData*)hasData{
	if(inputData) return inputData;
	
	else return nil;
}

-(void) dealloc
{
	[inputname release];
	if(inputData) [inputData release];
	if(destination) [destination release];
	[super dealloc];
}


-(NSString*)description{
	if(destination)
		return [NSString stringWithFormat:@"Name: %@, destination:%@",inputname, [destination compartmentname]];
	else {
		return inputname;
	}

}
-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:inputname forKey:@"Name"];
	[aCoder encodeObject:destination forKey:@"Destination"];
	[aCoder encodeObject:NSStringFromRect(rect) forKey:@"Rect"];
}

@end
