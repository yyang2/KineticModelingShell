//
//  KMParameter.mm
//  KineticModelingShell
//
//  Created by Yang Yang on 11/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "KMParameter.h"


@implementation KMParameter

@synthesize paramname;
@synthesize optimize;
@synthesize initial;
@synthesize lowerbound;
@synthesize upperbound;

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init]; if (!self) return nil;
	self.paramname	= [aDecoder decodeObjectForKey:@"ParamName"];
	self.optimize	= [aDecoder decodeBoolForKey:@"Optimize"];
	self.initial	= [aDecoder decodeDoubleForKey:@"Initial"];
	self.lowerbound = [aDecoder decodeDoubleForKey:@"Lowerbound"];
	self.upperbound = [aDecoder decodeDoubleForKey:@"Upperbound"];
	
	return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{

	[aCoder encodeObject:paramname forKey:@"ParamName"];
	[aCoder encodeDouble:initial forKey:@"Initial"];
	[aCoder encodeDouble:upperbound forKey:@"Upperbound"];
	[aCoder encodeDouble:lowerbound forKey:@"Lowerbound"];
	[aCoder encodeBool:optimize forKey:@"Optimize"];
	
}
-(id)init{
	self = [super init];
	if(!self) return nil;
	
	paramname	=	@"NewBasicParameter";
	optimize	=	TRUE;
	initial		=	0.1f;
	lowerbound	=	0;
	upperbound	=	1.0f;
	return self;
}
@end
