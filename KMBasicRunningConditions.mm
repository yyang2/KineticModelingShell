//
//  KMBasicRunningConditions.m
//  KineticModelingShell
//
//  Created by Yang Yang on 11/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "KMBasicRunningConditions.h"


@implementation KMBasicRunningConditions

@synthesize maxIterations;
@synthesize TotalRuns;
@synthesize tolerance;

-(id)init{
	self = [super init];
	if(!self) return nil;
	
	self.maxIterations = 100;
	self.TotalRuns = 1;
	self.tolerance = .000001;
	
	return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeInt:maxIterations forKey:@"MaxIterations"];
	[aCoder encodeInt:TotalRuns forKey:@"TotalRuns"];
	[aCoder encodeDouble:tolerance forKey:@"Tolerance"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init];
	self.maxIterations = [aDecoder decodeIntForKey:@"MaxIterations"];
	self.TotalRuns = [aDecoder decodeIntForKey:@"TotalRuns"];
	self.tolerance = [aDecoder decodeDoubleForKey:@"Tolerance"];
	return self;
}

-(NSString*)description{
	return [NSString stringWithFormat:@"Iterations: %i, Total Runs %i, Tolerance %f,", self.maxIterations, self.TotalRuns, self.tolerance]; 
}
@end
