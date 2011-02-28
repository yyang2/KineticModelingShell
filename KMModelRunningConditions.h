//
//  KMModelRunningConditions.h
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMBasicRunningConditions.h"

// Class that stores the initial values, upper and lower bounds for each parameter
// as well as whether this will be optimized or not
// inherits general options from KMBasicRunningConditions

@interface KMModelRunningConditions : KMBasicRunningConditions <NSCoding>{
	NSMutableArray	*lowerbounds, *upperbounds, *initials, *optimize;
	int		ParamCount;
	NSString		*modelName;
}

@property (retain) NSMutableArray *lowerbounds;
@property (retain) NSMutableArray *upperbounds;
@property (retain) NSMutableArray *initials;
@property (retain) NSMutableArray *optimize;
@property int ParamCount;
@property (retain) NSString *modelName;

-(id)initParametersForModel:(NSString *)presetName;
-(id)initCustomModelWithCount:(int)count;
-(int)saveDefaults;
@end
