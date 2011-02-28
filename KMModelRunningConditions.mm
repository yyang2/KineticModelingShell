//
//  KMModelRunningConditions.mm
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMModelRunningConditions.h"
#import "KMBasicRunningConditions.h"

@implementation KMModelRunningConditions


@synthesize lowerbounds;
@synthesize upperbounds;
@synthesize initials;
@synthesize optimize;
@synthesize ParamCount;
@synthesize modelName;

-(id)initParametersForModel:(NSString *)presetName{
	self = [super init];
	
	//parameter defaults are stored here.
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"KMFDGParams"]){
		
		NSArray *lb = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0], [NSNumber numberWithDouble:0],[NSNumber numberWithDouble:0],
								[NSNumber numberWithDouble:0],[NSNumber numberWithDouble:0],[NSNumber numberWithDouble:0], nil];
		NSArray *ub = [NSArray arrayWithObjects:[NSNumber numberWithDouble:1], [NSNumber numberWithDouble:1],[NSNumber numberWithDouble:1],
								[NSNumber numberWithDouble:1],[NSNumber numberWithDouble:1],[NSNumber numberWithDouble:1], nil];
		NSArray *i	 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:.1], [NSNumber numberWithDouble:.1],[NSNumber numberWithDouble:.1],
								[NSNumber numberWithDouble:.1],[NSNumber numberWithDouble:.1], [NSNumber numberWithDouble:0],  nil];
		NSArray *o	= [NSArray arrayWithObjects:[NSNumber numberWithDouble:1], [NSNumber numberWithDouble:1],[NSNumber numberWithDouble:1],
							   [NSNumber numberWithDouble:1],[NSNumber numberWithDouble:1],[NSNumber numberWithDouble:0], nil];
		
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:lb, @"LowerBounds", ub, @"UpperBounds", 
									i, @"Initials", 
									o, @"OptimizeFor",
									[NSNumber numberWithInt:30], @"MaxIterations",
									[NSNumber numberWithDouble:.0001],@"MinTolerance", 
									[NSNumber numberWithInt:10], @"TotalRuns",
									nil];
		[[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"KMFDGParams"];
		NSLog(@"%@", dictionary);
	}
	
	if([presetName isEqualToString:@"FDG"]){
		NSDictionary *temp	=	[[NSUserDefaults standardUserDefaults] objectForKey:@"KMFDGParams"];
		self.lowerbounds	=	[temp objectForKey:@"LowerBounds"];
		self.upperbounds	=	[temp objectForKey:@"UpperBounds"];
		self.initials		=	[temp objectForKey:@"Initials"];
		self.optimize		=	[temp objectForKey:@"OptimizeFor"];
		self.maxIterations =	[[temp objectForKey:@"MaxIterations"] intValue];
		self.TotalRuns		=	[[temp objectForKey:@"TotalRuns"] intValue];
		self.tolerance		=	[[temp objectForKey:@"MinTolerance"] doubleValue];
		self.modelName		=	presetName;
		self.ParamCount		=	6;
	}
	else return nil;
	
	return self;
}
 
-(void)dealloc{
	NSLog(@"KMModelRunningConditions Dealloc");
	lowerbounds	=nil;
	upperbounds	=nil;
	initials	=nil;
	optimize	=nil;
	maxIterations=nil;
	TotalRuns	=nil;
	tolerance	=nil;
	modelName	=nil;
	ParamCount	=nil;
	[super dealloc];
}

-(id)initCustomModelWithCount:(int)count{
	self = [super init];
	return self;
}

-(int)saveDefaults{
	if(upperbounds.count != ParamCount	||
	   initials.count != ParamCount		||
	   optimize.count != ParamCount		||
	   lowerbounds.count != ParamCount
	   ) return 0;
	
	if(modelName == @"FDG"){
		   [[NSUserDefaults standardUserDefaults] 
		 setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					lowerbounds, @"LowerBounds",
					upperbounds, @"UpperBounds", 
					initials, @"Initials", 
					optimize, @"OptimizeFor",
					[NSNumber numberWithInt:maxIterations], @"MaxIterations",
					[NSNumber numberWithDouble:tolerance],@"MinTolerance", 
					[NSNumber numberWithInt:TotalRuns], @"TotalRuns",
					nil] forKey:@"KMFDGParams"];
		return 1;
	}
	else return 0;
}

@end
