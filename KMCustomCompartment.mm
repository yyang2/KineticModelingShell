//
//  KMCustomCompartment.mm
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMCustomCompartment.h"


@implementation KMCustomCompartment


@synthesize isTissue;
@synthesize compartmentname;
@synthesize compartmenttype;
@synthesize rect;
@synthesize isSelected;
@synthesize upperleft;

-(id)initWithCoder:(NSCoder *)coder{
	
	self = [super init];
	if(!self) return nil;
	
	self.compartmentname = [coder decodeObjectForKey:@"CompartmentName"];
	self.compartmenttype = [coder decodeObjectForKey:@"CompartmentType"];
	self.isTissue		 = [coder decodeBoolForKey:@"IsTissue"];
	self.upperleft		 = NSPointFromString([coder decodeObjectForKey:@"UpperLeft"]);
	self.rect			 = NSRectFromString([coder decodeObjectForKey:@"Rect"]);
	self.isSelected		 = NO;
	//everything loaded is going to be unselected
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject:compartmentname forKey:@"CompartmentName"];
	[coder encodeObject:compartmenttype forKey:@"CompartmentType"];
	[coder encodeObject:NSStringFromRect(rect) forKey:@"Rect"];
	[coder encodeObject:NSStringFromPoint(upperleft) forKey:@"UpperLeft"];
	[coder encodeBool:isTissue			forKey:@"IsTissue"];
	//Not saving selected state, when loading everything defaults to unselected
}

-(id)initWithName:(NSString*)name type:(NSString*)d{
	self = [super init];
	if(!self) return nil;
	
	self.compartmenttype = d;
	self.compartmentname = name;
	self.isTissue   = YES;
	self.rect = NSMakeRect(0.0, 0.0,
						   KM_MIN_WIDTH, KM_MIN_HEIGHT);
	isSelected		= NO;
	return self; 
}

-(void)dealloc{	
	NSLog(@"Compartment: %@ deallocating", compartmentname);
	self.compartmenttype = nil;
	self.compartmentname = nil;
	[super dealloc];
}


-(NSString*)description{
	
	return [NSString stringWithFormat:@"%@, type:%@, IsTissue:%i\nLocation:%f,%f, %@",
			compartmentname, compartmenttype, isTissue, upperleft.x, upperleft.y, 
			NSStringFromRect(rect)];

}

-(BOOL)isComplete{
	return TRUE;
}

-(void)moveCompartment:(NSPoint) offset{
	self.rect = NSOffsetRect(self.rect, offset.x, offset.y);
}
@end
