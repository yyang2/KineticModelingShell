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
-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init];
	if(!self) return nil;
	
	//do not save loaded data!
	self.inputname	 = [aDecoder decodeObjectForKey:@"Name"];
	self.destination  = [aDecoder decodeObjectForKey:@"Destination"];
	self.rect		 = NSRectFromString([aDecoder decodeObjectForKey:@"Rect"]);
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


-(id)initWithName:(NSString*)name
{
	self = [super init];
	if(!self) return nil;
	
	self.inputname	 = name;
	destination  = nil;
	rect		 = NSMakeRect(0, 0, 1, 1);
	isSelected   = FALSE;
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
-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:inputname forKey:@"Name"];
	[aCoder encodeObject:destination forKey:@"Destination"];
	[aCoder encodeObject:NSStringFromRect(rect) forKey:@"Rect"];
}

@end
