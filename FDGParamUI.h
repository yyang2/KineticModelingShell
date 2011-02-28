//
//  FDGParamUI.h
//  KM
//
//  Created by Yang Yang on 9/6/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMModelRunningConditions.h"

//This is the UI for running three-compartment FDG model

@interface FDGParamUI : NSWindowController {
	KMModelRunningConditions				*parameters;
	IBOutlet NSTextField		*upperk1, *upperk2, *upperk3, *upperk4, *upperk5,
								*lowerk1, *lowerk2, *lowerk3, *lowerk4, *lowerk5,
								*initk1,  *initk2,  *initk3,  *initk4,  *initk5,
								*randtotal, *max_iteration, *min_tolerance;
	IBOutlet NSButton			*randk1,  *randk2,  *randk3,  *randk4,  *randk5,
								*uballones, *lballzeros, *randall;
}

-(id)initWithParameter:(KMModelRunningConditions*) k;
-(IBAction)checkRandomButton:(id)sender;
-(IBAction)checkSideOptions:(id)sender;
-(IBAction)setParameters:(id)sender;

@end
