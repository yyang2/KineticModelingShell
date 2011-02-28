//
//  KineticDataProcessor.h
//  KM
//
//  Created by Yang Yang on 9/5/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMData.h"
#import "KMResults.h"
#import "fitter.hpp"
#import "vec.hpp"
#import "model.hpp"
#import "KMResultDisplay.h"
#import "KMModelRunningConditions.h"

// Class that is responsible for actually running the C++ fitting routines for any model
// Only place where we use libKM

@interface KMDataProcessor : NSObject {
	NSArray			*inputs;
	KMData			*tissue;
	KMModelRunningConditions	*parameters;
	id				m;
}

-(void)RunFDG;
-(void)runCustomModel;
-(vector)changeArrayIntoVector:(NSArray *)target;
-(void) initWithModel: (id)model Parameters:(KMModelRunningConditions*)params Inputs:(NSArray *) arrayin andTissue: (KMData *)tiss;
-(NSMutableArray *)changeVectorIntoArray:(vector)input;
@end
