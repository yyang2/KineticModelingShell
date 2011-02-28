//
//  KineticDataProcessor.m
//  KM
//
//  Created by Yang Yang on 9/5/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "KMDataProcessor.h"
#import "KMCustomModel.h"
#import "KMCustomParameter.h"
#import "KMCustomCompartment.h"
#import "KMCustomInput.h"


@implementation KMDataProcessor
using namespace KM;


-(void) initWithModel: (id)model Parameters:(KMModelRunningConditions*)params Inputs:(NSArray *) arrayin andTissue: (KMData *)tiss {
	self = [super init];
	inputs = [arrayin retain];
	tissue = [tiss retain];
	m = [model retain];
	parameters = [params retain];
	
	if([[m className] hasSuffix:@"Array"]){
		//something
	}
	
	
	else if( [[m className] hasSuffix:@"String"]){
		
		if(m == @"FDG") [self RunFDG];
	}
	
	else if( [[m className] isEqualToString:@"KMCustomModel"]){
		//do shit
	}
	[self dealloc];
}

NSInteger sortParameter(id param1, id param2, id allCompartments){
	int i,j;

	for(i=0; i<[allCompartments count];i++)
		if([param1 origin_comp] == [allCompartments objectAtIndex:i]) break;
	
	for(j=0; j<[ allCompartments count];j++)
		if([param2 origin_comp] == [allCompartments objectAtIndex:j]) break;
	
	if(i<j) 
		return (NSComparisonResult)NSOrderedAscending;
	
	else if(i>j) 
		return (NSComparisonResult)NSOrderedDescending;
	
	else if(i==j){
		for(i=0; i<[ allCompartments count];i++)
			if([param1 destin_comp] == [allCompartments objectAtIndex:i]) break;

		for(j=0; j<[ allCompartments count];j++)
			if([param2 destin_comp] == [allCompartments objectAtIndex:j]) break;		
		if(i<j) return (NSComparisonResult)NSOrderedAscending;
		
		else if(i>j) return (NSComparisonResult)NSOrderedDescending;
	}
	
}
-(void)runCustomModel{
	NSMutableArray *compList = [m allCompartments];
	int compNumber = [compList count];
	int i,j;
	KMResults *results = [[[KMResults alloc] autorelease] initWithModelName:[m ModelName]];
	
	
	//set up parameters
	NSArray *sortedParameters = [[m Parameters] sortedArrayUsingComparator:^(id param1, id param2){
		int i,j;
		for(i=0; i<[compList count];i++)
			if([param1 origin_comp] == [compList objectAtIndex:i]) break;
		
		for(j=0; j<[compList count];j++)
			if([param2 origin_comp] == [compList objectAtIndex:j]) break;
		
		if(i<j) 
			return (NSComparisonResult)NSOrderedAscending;
		
		else if(i>j) 
			return (NSComparisonResult)NSOrderedDescending;
		
		else if(i==j){
			for(i=0; i<[ compList count];i++)
				if([param1 destin_comp] == [compList objectAtIndex:i]) break;
			
			for(j=0; j<[ compList count];j++)
				if([param2 destin_comp] == [compList objectAtIndex:j]) break;		
			if(i<j) return (NSComparisonResult)NSOrderedAscending;
			
			else if(i>j) return (NSComparisonResult)NSOrderedDescending;
			else if(i==j) {
				printf("Two Parameters have same origin and destination, major fail in KMDataProcessor");
				return (NSComparisonResult)NSOrderedSame;
			}
		}
		return (NSComparisonResult)NSOrderedSame;
	}];
	
	bool	paramOpt[[sortedParameters count]+1];
	double	paramStart[[sortedParameters count]+1];
	double	paramLow[[sortedParameters count]+1];
	double	paramHigh[[sortedParameters count]+1];
	
	for(i=0;i<[sortedParameters count]; i++){
		paramStart[i] = [[sortedParameters objectAtIndex:i] initial];
		paramOpt[i]   = [[sortedParameters objectAtIndex:i] optimize];
		paramLow[i]   = [[sortedParameters objectAtIndex:i] lowerbound];
		paramHigh[i]  = [[sortedParameters objectAtIndex:i] upperbound];
	}

	
	//setup compartments
	bool	input[compNumber];
	bool	tiss[compNumber];
	for(i=0;i<compNumber;i++){
		tiss[i] = [[compList objectAtIndex:i] isTissue];
		input[i] = false;
		for(j=0; j<[[m Inputs] count]; j++){
			if ([[[m Inputs] objectAtIndex:j] destination] == [compList objectAtIndex:i])
				input[i]=true;
		}
 	}
	
	
	//set up adjacency matrix - aka map of connections
	bool adjMat[compNumber*compNumber];
	for(i=0; i<compNumber*compNumber;i++)
		adjMat[i]=false;

	for(int k=0; k<[sortedParameters count]; k++){
		KMCustomParameter *cur = [sortedParameters objectAtIndex:k];
		for(i=0; i< compNumber;i++)
			if([compList objectAtIndex:i] == [cur origin_comp]) break;
		for(j=0; j< compNumber;j++)
			if([compList objectAtIndex:j] == [cur destin_comp]) break;
		adjMat[i*compNumber+j] = true;
	}

  GenericGraphModel* model = new GenericGraphModel( compNumber, adjMat, input, tiss );
	
	
}
-(void)RunFDG
{
	KMResults	*results	= [[[KMResults alloc] autorelease] initWithModelName:@"FDG"];
	KMData		*input		= [inputs objectAtIndex:0];
	FDGModel	*fdg		= new FDGModel();
	
	
	fdg->add_input([input times], [input values]);
	
	ModelFitter fitter;
	
	fitter.verbose=FALSE;
	
	fitter.max_iterations = (double)parameters.maxIterations;
	if(!fitter.max_iterations) fitter.max_iterations=100;
	fitter.absolute_step_threshold = (double)parameters.tolerance;
	
	ModelFitter::Target target;
	target.ttac.copy( [tissue values]);		
	target.ttac_times.copy( [tissue times] );
	
	target.weights.copy( [tissue weights] );
	vector weight = [tissue weights];
	
	NSLog(@"Weights:%@", [self changeVectorIntoArray:tissue.weights]);
	
	ModelFitter::Options options( 6 );
	options.lower_bounds.copy([self changeArrayIntoVector:parameters.lowerbounds]);
	options.upper_bounds.copy([self changeArrayIntoVector:parameters.upperbounds]);
	options.use_lower_bounds=TRUE;
	options.use_upper_bounds=TRUE;
	
	
	double ip [6];
	for (int i = 0; i < 5; ++i ){
		if([[parameters.optimize objectAtIndex:i] intValue]) {
			options.parameters_to_optimize[i] = TRUE;}
		else{
			options.parameters_to_optimize[i] = FALSE;
			ip[i] = [[parameters.initials objectAtIndex:i] doubleValue];
		}
	}
	
	options.parameters_to_optimize[5] = FALSE;	ip[5] = (double)0.f;
	srand ( time(NULL) );
	
	for(int k=0; k<parameters.TotalRuns; ++k){
		
		for (int j = 0; j<6; j++) {
			if(options.parameters_to_optimize[j]){
				double min = [[parameters.lowerbounds objectAtIndex:j] doubleValue];
				double max = [[parameters.upperbounds objectAtIndex:j] doubleValue];
				ip[j] = ((double)rand()/(double)RAND_MAX)*(max-min) + min;
			}
		}
		
		vector init_param( ip, 6 );
		ModelFitter::Result* result = fitter.fit_model_to_tissue_curve( fdg, &target, init_param, &options );
		NSMutableDictionary *currentiteration = [NSMutableDictionary dictionary];
		
		NSLog(@"Size:%i",result->parameters.size());
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[0]] forKey:@"K1"];
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[1]] forKey:@"K2"];
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[2]] forKey:@"K3"];
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[3]] forKey:@"K4"];
		
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[4]] forKey:@"VB"];
		[currentiteration setObject:[NSNumber numberWithDouble:result->wrss] forKey:@"WRSS"];
		vector yvalues = result->func_value;
		NSLog(@"YValues: %@",[self changeVectorIntoArray:yvalues]);
		[currentiteration setObject:[self changeVectorIntoArray:yvalues] forKey:@"YValues"];
		[currentiteration setObject:[self changeVectorIntoArray:tissue.times] forKey:@"XValues"];
		[results addResult:currentiteration];
		
	}
	[results orderListBy:@"WRSS"];
	NSLog(@"Results:%@", results);
	[[KMResultDisplay alloc] initWithResults:results];	
	
}

-(NSMutableArray *)changeVectorIntoArray:(vector)input{
	NSMutableArray *temp = [NSMutableArray array];
	for(int i=0;i<input.size(); ++i){
		[temp addObject: [NSNumber numberWithDouble:input[i]]];
	}
	return temp;
}
-(vector)changeArrayIntoVector:(NSArray *)target{
	vector temp = vector(target.count);
	int x;
	for(x=0;x<(int)target.count;++x){
		temp[x] = [[target objectAtIndex:x] doubleValue];
	}
	return temp;
}

-(void) dealloc {
	if(parameters) [parameters release];
	if(inputs) [inputs release];
	if(tissue) [tissue release];
	if(m) [m release];
	
	[super dealloc];
}
@end
