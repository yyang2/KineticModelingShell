//
//  KMBasicRunningConditions.h
//  KineticModelingShell
//
//  Created by Yang Yang on 11/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// Stores values for basic parameters that any model will require
// maximum number of iterations, number of times to fit, minimum step size before terminating (tolerance)


@interface KMBasicRunningConditions : NSObject <NSCoding>{
	int		maxIterations, TotalRuns;
	double	tolerance;
}

-(id)init;
@property double tolerance;
@property int maxIterations;
@property int TotalRuns;


@end
