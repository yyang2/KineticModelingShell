//
//  RegressionResults.m
//  KM
//
//  Created by Yang Yang on 9/6/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "KMResults.h"



@implementation KMResults
@synthesize ModelName;
-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init];
	if(!self) return nil;
	
	ModelName			= [aDecoder decodeObjectForKey:@"Name"];
	FittedParameters	= [aDecoder	decodeObjectForKey:@"Fitted"];
	
	return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder{
	
	[aCoder encodeObject:ModelName forKey:@"Name"];
	[aCoder encodeObject:FittedParameters forKey:@"Fitted"];

}
-(id)initWithModelName:(NSString *) model{
	self = [super init];
	if(!self) return nil;
	ModelName = model;
	[ModelName retain];
	return self;
}

-(void)dealloc{
	[ModelName release];
	if(FittedParameters) [FittedParameters release];
	[super dealloc];
}


-(BOOL)addResult:(NSMutableDictionary *)entry{
	
	//validate the entry before adding
	if(![[[entry objectForKey:@"YValues"] className] isEqualToString:@"NSMutableArray"] ||
	![[[entry objectForKey:@"XValues"] className] isEqualToString:@"NSMutableArray"] ||
	   ![entry objectForKey:@"WRSS"] || 
	   ![entry objectForKey:@"VB"]) 
		return NO;
	
	
	
	[entry retain];
	if(!FittedParameters)	FittedParameters = [[NSMutableArray array] retain];

	[FittedParameters addObject:entry];
	[entry release];
	return YES;
}

-(BOOL)deleteResult:(int)index{
	if(!FittedParameters) return NO;
	if(index > FittedParameters.count) return NO;
	
	[FittedParameters removeObjectAtIndex:index];
	return YES;
}
-(void)orderListBy:(NSString*)thiscategory{
	NSSortDescriptor *d = [[[NSSortDescriptor alloc] initWithKey:thiscategory ascending:YES selector:@selector(compare:)] autorelease];
	[FittedParameters sortUsingDescriptors: [NSArray arrayWithObject: d]];	
}

-(NSMutableDictionary*)entryForIndex:(int) i{
	if(i>-1){
	return [FittedParameters objectAtIndex:i];
	}
	else return nil;
}

-(NSArray *)orderedArrayFor:(NSString *) something{
	int i;
	NSMutableArray *selection = [NSMutableArray array];
	for (i=0; i<FittedParameters.count; i++) {
		[selection addObject:[[FittedParameters objectAtIndex:i] objectForKey:something]];
	}
	return [selection sortedArrayUsingSelector:@selector(compare:)];
}

-(NSString*)description{
	return [NSString stringWithFormat:@"%@\nFittedParamters:%@",ModelName, FittedParameters];
}

-(int)totalCount{
	if(FittedParameters) return FittedParameters.count;

	else return -1;
}
@end
