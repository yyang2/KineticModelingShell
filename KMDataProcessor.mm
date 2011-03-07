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
#import "model.hpp"

@implementation KMDataProcessor
using namespace KM;


-(void) initWithModel: (id)model Parameters:(KMModelRunningConditions*)params Inputs:(NSArray *) arrayin andTissue: (KMData *)tiss
{
	self = [super init];
	inputs = [arrayin retain];
	tissue = [tiss retain];
	m = [model retain];
	parameters = [params retain];
	
	if([[m className] hasSuffix:@"Array"])
	{
		//something
	}
	else if( [[m className] hasSuffix:@"String"])
	{
		if(m == @"FDG") [self RunFDG];
	}
	else if( [[m className] isEqualToString:@"KMCustomModel"])
	{
		[self runCustomModel];
	}
	[self dealloc];
}

-(void)runCustomModel
{
	KMCustomModel *customModel = m;
	NSMutableArray *compList = [m allCompartments];
	int compNumber = [compList count];
	int i,j;
	KMResults *results = [[[KMResults alloc] autorelease] initWithModelName:[m ModelName]];
	
	tissue = [customModel.tissueData retain];
	
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
			for(i=0; i<[compList count];i++)
				if([param1 destin_comp] == [compList objectAtIndex:i]) break;
			for(j=0; j<[compList count];j++)
				if([param2 destin_comp] == [compList objectAtIndex:j]) break;		
			
			if(i<j) 
				return (NSComparisonResult)NSOrderedAscending;
			else if(i>j) 
				return (NSComparisonResult)NSOrderedDescending;
			else if(i==j) 
				printf("Two Parameters have same origin and destination, major fail in KMDataProcessor");
		}
		return (NSComparisonResult)NSOrderedSame;
	}];
	
	bool	paramOpt[sortedParameters.count+1];
	double	paramStart[sortedParameters.count+1];
	double	paramLow[sortedParameters.count+1];
	double	paramHigh[sortedParameters.count+1];
	
	for(i=0;i<sortedParameters.count; i++){
		KMCustomParameter *cur = [sortedParameters objectAtIndex:i];
		paramStart[i] = cur.initial;
		paramOpt[i]   = cur.optimize;
		paramLow[i]   = cur.lowerbound;
		paramHigh[i]  = cur.upperbound;
	}
	paramOpt[sortedParameters.count]=YES;
	paramLow[sortedParameters.count]=0;
	paramHigh[sortedParameters.count]=.5;
	paramStart[sortedParameters.count]=.1;
	//setup input and tissue vector
	
	bool	input[compNumber];
	bool	tiss[compNumber];
	for(i=0;i<compNumber;i++){
		tiss[i] = (bool)[[compList objectAtIndex:i] isTissue];
		input[i] = false;
		for(j=0; j<[[m Inputs] count]; j++){
			if ([[[m Inputs] objectAtIndex:j] destination] == [compList objectAtIndex:i])
				
				input[i]=true;
		}
	}
	NSLog(@"Inputs");
	for(i=0; i<compNumber; i++)
		NSLog(@"%@, input: %i, tissue: %i", [[compList objectAtIndex:i] compartmentname] ,input[i], tiss[i]);
	
	
	//set up adjacency matrix - aka map of connections, default all false
	bool adjMat[compNumber*compNumber];
	for(i=0; i<compNumber*compNumber;i++)
		adjMat[i]=false;
	
	for(int k=0; k<sortedParameters.count; k++){
		KMCustomParameter *cur = [sortedParameters objectAtIndex:k];
		//loop through parameters to set adjMat to true		
		//optimized since compList is already sorted
		for(i=0; i< compNumber;i++)
			if([compList objectAtIndex:i] == [cur origin_comp]) {
				for(j=0; j< compNumber;j++)
				{
					if([compList objectAtIndex:j] == [cur destin_comp]) 
					{
						adjMat[i*compNumber+j] = true;
						NSLog(@"%i,%i:%@ %f-%f",i,j, cur.paramname, paramLow[k], paramHigh[k]);
					}
					else {
						
					}

				}
			}
	}


	GenericGraphModel* model = new GenericGraphModel( compNumber, adjMat, input, tiss );
	
	NSLog(@"Current Model inputs, %i, connections:%i, num params%i", model->inputs(), model->num_connections(), model->num_parameters());
	
	KMData *inp = [[[m Inputs] objectAtIndex:0] inputData];
	vector times = [inp times];
	vector values = [inp values];
	
	
	
	model->add_input([inp times], [inp values]);
	NSLog(@"input added? %i", model->inputs());

	ModelFitter::Target target;
	KM::ModelFitter fitter;
	
	fitter.max_iterations = customModel.conditions.maxIterations;
	target.ttac.copy( [tissue values]);		
	target.ttac_times.copy( [tissue times] );
	
	target.weights.copy( [tissue weights] );
	
//	NSLog(@"Weights:%@", [self changeVectorIntoArray:tissue.weights]);

	ModelFitter::Options options( sortedParameters.count);
    memcpy( options.parameters_to_optimize, paramOpt,
		   sizeof( paramOpt ) );
	
	fitter.verbose = true;
    fitter.absolute_step_threshold = 0;
    fitter.relative_step_threshold = customModel.conditions.tolerance;
//	NSLog(@"Conditions:%@", customModel.conditions);
	
	NSLog(@"Current Model inputs, %i, connections:%i, num params%i", model->inputs(), model->num_connections(), model->num_parameters());
	
	srand ( time(NULL) );
	
	for (int k=0; k< (unsigned int)customModel.conditions.TotalRuns; k++){
		
		
		KM::matrix cc(compNumber, compNumber);
		KM::vector volume(1);
		volume[0] = 0.1;
		

		for(int k=0; k<sortedParameters.count; k++){
			KMCustomParameter *cur = [sortedParameters objectAtIndex:k];
			NSLog(@"Current parameter:%@", cur.paramname);
			//loop through parameters to set adjMat to true		
			//optimized since compList is already sorted
			for(i=0; i< compNumber;i++)
				if([compList objectAtIndex:i] == [cur origin_comp]) {
					for(j=0; j< compNumber;j++)
					{
						if([compList objectAtIndex:j] == [cur destin_comp]) 
						{
							NSLog(@"Location:%i,%i",i,j);
							cc(i,j) = ((double)rand()/(double)RAND_MAX)*(paramHigh[k]-paramLow[k]) + paramLow[k];						
						}
					}
				}
		}
		
		vector init_param = model->parameter_vector( cc, volume );
		
		NSMutableDictionary *currentiteration = [NSMutableDictionary dictionary];
		
		ModelFitter::Result* result = fitter.fit_model_to_tissue_curve( model, &target, init_param, &options );
		
		
		for(i=0; i<result->parameters.size()-1; i++) {
			NSLog(@"parameter %i: %g",i,result->parameters[i]);
			[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[i]] forKey:[[sortedParameters objectAtIndex:i] paramname]];
		}
		NSLog(@"parameter %i: %g",i,result->parameters[i]);
		[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[i]] forKey:@"VB"];
		
		NSLog(@"Size:%i",result->parameters.size());
		[currentiteration setObject:[NSNumber numberWithDouble:result->wrss] forKey:@"WRSS"];
		vector yvalues = result->func_value;
		NSLog(@"YValues: %@",[self changeVectorIntoArray:yvalues]);
		[currentiteration setObject:[self changeVectorIntoArray:yvalues] forKey:@"YValues"];
		[currentiteration setObject:[self changeVectorIntoArray:tissue.times] forKey:@"XValues"];
		NSLog(@"Current iteration:%@", currentiteration);
		[results addResult:currentiteration];
	}
	
	[results orderListBy:@"WRSS"];
	NSLog(@"Results:%@", results);
	[[KMResultDisplay alloc] initWithResults:results];
	
}
-(void)RunFDG
{
	KMResults	*results	= [[[KMResults alloc] autorelease] initWithModelName:@"FDG"];
	KMData		*input		= [inputs objectAtIndex:0];
	FDGModel	*fdg		= new FDGModel();
	
	
	fdg->add_input([input times], [input values]);
	
	ModelFitter fitter;
	
	fitter.verbose=TRUE;
	
	fitter.max_iterations = (double)parameters.maxIterations;
	if(!fitter.max_iterations) fitter.max_iterations=100;
	fitter.absolute_step_threshold = (double)parameters.tolerance;
	
	ModelFitter::Target target;
	target.ttac.copy( [tissue values]);		
	target.ttac_times.copy( [tissue times] );
	
	target.weights.copy( [tissue weights] );
	vector weight = [tissue weights];
	
//	NSLog(@"Weights:%@", [self changeVectorIntoArray:tissue.weights]);
	
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
