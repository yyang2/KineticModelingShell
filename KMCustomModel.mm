//
//  KMCustomModel.mm
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMCustomModel.h"
#import "KMCustomCompartment.h"
#import "KMBasicRunningConditions.h"
#import "KMCustomInput.h"
#import "KMCustomParameter.h"

@implementation KMCustomModel
@synthesize Inputs;
@synthesize Parameters;
@synthesize ModelName;
@synthesize TissueData;
@synthesize conditions;

-(void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject:conditions		forKey:@"Conditions"];
	[coder encodeObject:Inputs			forKey:@"Inputs"];
	[coder encodeObject:Compartments	forKey:@"Compartments"];
	[coder encodeObject:ModelName		forKey:@"ModelName"];
	[coder encodeObject:Parameters		forKey:@"Parameters"];
}


-(id) initWithCoder:(NSCoder *)coder{
	self = [super init];
	
	if (!self) return nil;
	conditions		= [[coder decodeObjectForKey:@"Conditions"] retain];
	Inputs			= [[coder decodeObjectForKey:@"Inputs"] retain];
	Compartments	= [[coder decodeObjectForKey:@"Compartments"] retain];
	self.ModelName  = [coder decodeObjectForKey:@"ModelName"];
	Parameters		= [[coder decodeObjectForKey:@"Parameters"] retain];
	
	return self;
}


-(id)initWithModelName:(NSString*) name{
	self=[super init];
	if(!self) return nil;

	self.ModelName=name;

	Inputs = [[NSMutableArray array] retain];
	Compartments = [[NSMutableArray array] retain];
	Parameters = [[NSMutableArray array] retain];
	return self;
}

-(id)loadModelFromPath:(NSString*)path
{
	self=[super init];
	if(!self) return nil;
	
	//self.ModelName = [coder decodeObjectForKey:@"ModelName"];
	//[self loadInputs:[coder decodeObjectForKey:@"ModelInputs"] andCompartments:[coder decodeObjectForKey:@"ModelCompartments"]];
	return self;
}

-(void)dealloc
{
	self.ModelName=nil;
	if(Inputs) [Inputs release];
	if(Compartments) [Compartments release];
	if(Parameters) [Parameters release];
	
	[super dealloc];
}
-(void)removeParameter:(KMCustomParameter*)p
{
	for(int i=0; i<Parameters.count;++i){
		KMCustomParameter *current = [Parameters objectAtIndex:i];
		if(current == p) {
			[Parameters removeObjectAtIndex:i];
			break;
		}
	}
}
-(void)addParameter:(KMCustomParameter*)p{
	
	for(int i=0; i<Parameters.count;++i){
		KMCustomParameter *current = [Parameters objectAtIndex:i];
		if (current.origin_comp == p.origin_comp && current.destin_comp == p.destin_comp) return;
	}	
	//only add if its a new connection
	
	[Parameters addObject:p];
}
-(void)loadInputs:(NSMutableArray *)inputs andCompartments:(NSMutableArray *)compartments{
	if(Inputs) [Inputs release]; if(Compartments) [Compartments release];
	Inputs = [inputs retain];	Compartments = [compartments retain];
}


-(BOOL)addCompartment:(KMCustomCompartment*)current{
	
	if(!Compartments) Compartments = [[NSMutableArray arrayWithCapacity:0] retain];
	
	for(int i=0;i<Compartments.count;i++){
		//can't have two compartments with the same name
		if([current.compartmentname isEqualToString:[[Compartments objectAtIndex:i] compartmentname]]){
			current.compartmentname = [NSString stringWithFormat:@"%@_1",current.compartmentname];
		}
	}
	
	[Compartments addObject:current];
	return YES;
}

-(NSMutableArray *)parametersForCompartment:(KMCustomCompartment*)comp
{
	NSMutableArray *returnValues = [NSMutableArray array];
	for(int i = 0; i< Parameters.count; i++){
		KMCustomParameter *cur = [Parameters objectAtIndex:i];
		
		if(cur.origin_comp == comp || cur.destin_comp == comp)
			[returnValues addObject:cur];
	}
	
	return returnValues;
}
-(BOOL)removeCompartment:(KMCustomCompartment*)current{
	
	
	//find and remove all connected parameters
	NSMutableArray *connectedParameters = [self parametersForCompartment:current];
	for(int k = 0; k<[connectedParameters count]; k++){
		KMCustomParameter *cur = [connectedParameters objectAtIndex:k];
		[self removeParameter:cur];
	}
	
	// find and remove input 
	
	for(int j = 0; j<[Inputs count]; j++){
		KMCustomInput *cur = [Inputs objectAtIndex:j];
		if(cur.destination == current) cur.destination = nil;
	}
	
	
	//delete the compartment
	for(int i = 0; i<[Compartments count]; i++){
		if(current == [Compartments objectAtIndex:i]){
			[Compartments removeObjectAtIndex:i];
			return YES;
		}
	}
	return NO;
}

-(BOOL)validateModel{
	
	if(!TissueData || [Inputs count] < 1 || [Parameters count] < 1)
		return NO;
	
	for(int k=0; k< [Inputs count]; k++)
	{
		KMCustomInput *cur = [Inputs objectAtIndex:k];
		if([cur hasData]) return NO;
	}

	return YES;
	
}
-(KMCustomCompartment*)compartment:(NSString*)name{
	for(int i =0; i< [Compartments count]; i++){
		if([[[Compartments objectAtIndex:i] compartmentname] isEqualToString:name])
			return  [Compartments objectAtIndex:i];
	}
	return nil;
}

-(NSMutableArray*)allCompartments{
	return Compartments;
}

-(BOOL)addInput:(KMCustomInput*)current{
	for(int i=0; i<Inputs.count;i++){
		KMCustomInput *current = [Inputs objectAtIndex:i];
		if([current.inputname isEqualToString: [[Inputs objectAtIndex:i] inputname]]){
			current.inputname = [NSString stringWithFormat:@"%@_a", current.inputname];
		}
	}
	[Inputs addObject:current];	
	return YES;
}

-(BOOL)removeInput:(KMCustomInput *)current
{
	for(int i=0; i<Inputs.count;i++){
		if(current == [Inputs objectAtIndex:i]){
			
			[Inputs removeObjectAtIndex:i];
			return YES;
		}
	}
	return NO;
}
-(NSString*)description{
	
	return [NSString stringWithFormat:@"%@\nInputs:%@\nCompartments:%@\nParameters:%@",ModelName, Inputs, Compartments, Parameters];

}


@end
