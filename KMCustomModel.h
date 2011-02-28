//
//  KMCustomModel.h
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class KMCustomCompartment;
@class KMData;
@class KMBasicRunningConditions;
@class KMCustomInput;
@class KMCustomParameter;
// Core Class representing a user created Kinetic Model


@interface KMCustomModel : NSObject  <NSCoding> {
	NSMutableArray	*Inputs, *Compartments, *Parameters;
	NSString		*ModelName;
	KMData		*TissueData;
	KMBasicRunningConditions *conditions;
}
@property (retain) KMBasicRunningConditions *conditions;
@property (retain) KMData   *TissueData;
@property (retain) NSString	*ModelName;
@property (retain) NSMutableArray *Parameters;
@property (retain) NSMutableArray *Inputs;
-(NSMutableArray*)allCompartments;
-(NSMutableArray *)parametersForCompartment:(KMCustomCompartment*)comp;
-(void)addParameter:(KMCustomParameter*)p;
-(id)initWithModelName:(NSString*) name;
-(id)loadModelFromPath:(NSString*)path;
-(void)loadInputs:(NSMutableArray*)inputs andCompartments:(NSMutableArray*)compartments;
-(BOOL)addCompartment:(KMCustomCompartment*)current;
-(BOOL)removeCompartment:(KMCustomCompartment*)current;
-(BOOL)addInput:(KMCustomInput*)current;
-(BOOL)removeInput:(KMCustomInput*)current;
-(BOOL)validateModel;
-(void)removeParameter:(KMCustomParameter*)p;

-(KMCustomCompartment*)compartment:(NSString*)name;

//save
//load
@end
