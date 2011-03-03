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
	NSLog(@"%@",[m Parameters]);
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
	
	NSLog(@"SortedParameters:%@", sortedParameters);
	bool	paramOpt[sortedParameters.count];
	double	paramStart[sortedParameters.count];
	double	paramLow[sortedParameters.count];
	double	paramHigh[sortedParameters.count];
	
	for(i=0;i<sortedParameters.count; i++){
		KMCustomParameter *cur = [sortedParameters objectAtIndex:i];
		paramStart[i] = cur.initial;
		paramOpt[i]   = cur.optimize;
		paramLow[i]   = cur.lowerbound;
		paramHigh[i]  = cur.upperbound;
		NSLog(@"initial:%g, low %g, high %g", paramStart[i], paramLow[i], paramHigh[i]);
	}

	
	//setup input vector
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
	
						
	//set up adjacency matrix - aka map of connections, default all false
	bool adjMat[compNumber*compNumber];
	for(i=0; i<compNumber*compNumber;i++)
		adjMat[i]=false;

	
	KM::matrix lb(compNumber, compNumber);
	KM::matrix ub(compNumber, compNumber);
	i=0;j=0;
	for(int k=0; k<sortedParameters.count; k++){
		KMCustomParameter *cur = [sortedParameters objectAtIndex:k];
		//loop through parameters to set adjMat to true		
		//optimized since compList is already sorted
		for(; i< compNumber;i++)
			if([compList objectAtIndex:i] == [cur origin_comp]) {
				for(; j< compNumber;j++)
				{
					if([compList objectAtIndex:j] == [cur destin_comp]) 
					{
						adjMat[i*compNumber+j] = true;
						lb(i,j)=paramLow[k];
						ub(i,j)=paramHigh[k];
					}
					else lb(i,j)=-1.f; 
				}
			}
	}


	GenericGraphModel* model = new GenericGraphModel( compNumber, adjMat, input, tiss );
	
	KMData *inp = [[[m Inputs] objectAtIndex:0] inputData];
	
	model->add_input([inp times], [inp values]);
	
	
	
	ModelFitter::Target target;
	KM::ModelFitter fitter;
	
	fitter.max_iterations = customModel.conditions.maxIterations;
	target.ttac.copy( [tissue values]);		
	target.ttac_times.copy( [tissue times] );
	
	target.weights.copy( [tissue weights] );
	vector weight = [tissue weights];
	
//	NSLog(@"Weights:%@", [self changeVectorIntoArray:tissue.weights]);

	ModelFitter::Options options( sortedParameters.count );
    memcpy( options.parameters_to_optimize, paramOpt, 
		   sizeof( paramOpt ) );
	
	fitter.verbose = true;
    fitter.absolute_step_threshold = 0;
    fitter.relative_step_threshold = customModel.conditions.tolerance;
	NSLog(@"Conditions:%@", customModel.conditions);
	
	for (int k=0; k< (unsigned int)customModel.conditions.TotalRuns; k++){
		
		KM::matrix cc(compNumber, compNumber);
		KM::vector volume(1);
		volume[0] = 0.05;
		
		
		for (i = 0; i < compNumber; i++) {
			for(j = 0; j <compNumber; j++) {
				if(lb(i,j)>=0 && i!=j){
					cc(i,j) = ((double)rand()/(double)RAND_MAX)*(ub(i,j)-lb(i,j)) + lb(i,j);
					NSLog(@"object at %i,%i, %f",i,j, cc(i,j));

				}
			}
		}
		
		vector init_param = model->parameter_vector( cc, volume );
		
		NSMutableDictionary *currentiteration = [NSMutableDictionary dictionary];
		
		ModelFitter::Result* result = fitter.fit_model_to_tissue_curve( model, &target, init_param, &options );
		
		
		for(i=0; i<result->parameters.size(); i++) {
			[currentiteration setObject:[NSNumber numberWithDouble:result->parameters[i]] forKey:[[sortedParameters objectAtIndex:i] paramname]];
		}
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
