//
//  FDGParamUI.m
//  KM
//
//  Created by Yang Yang on 9/6/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "FDGParamUI.h"

@implementation FDGParamUI

-(void) awakeFromNib {
	[max_iteration setIntValue:parameters.maxIterations];
	[randtotal	   setIntValue:parameters.TotalRuns];
	[min_tolerance setDoubleValue:parameters.tolerance];
	
	[upperk1 setDoubleValue:[[parameters.upperbounds objectAtIndex:0] doubleValue]];
	[upperk2 setDoubleValue:[[parameters.upperbounds objectAtIndex:1] doubleValue]];
	[upperk3 setDoubleValue:[[parameters.upperbounds objectAtIndex:2] doubleValue]];
	[upperk4 setDoubleValue:[[parameters.upperbounds objectAtIndex:3] doubleValue]];
	[upperk5 setDoubleValue:[[parameters.upperbounds objectAtIndex:4] doubleValue]];
	
	[lowerk1 setDoubleValue:[[parameters.lowerbounds objectAtIndex:0] doubleValue]];
	[lowerk2 setDoubleValue:[[parameters.lowerbounds objectAtIndex:1] doubleValue]];
	[lowerk3 setDoubleValue:[[parameters.lowerbounds objectAtIndex:2] doubleValue]];
	[lowerk4 setDoubleValue:[[parameters.lowerbounds objectAtIndex:3] doubleValue]];
	[lowerk5 setDoubleValue:[[parameters.lowerbounds objectAtIndex:4] doubleValue]];
	
	[initk1 setDoubleValue:[[parameters.initials objectAtIndex:0] doubleValue]];
	[initk2 setDoubleValue:[[parameters.initials objectAtIndex:1] doubleValue]];
	[initk3 setDoubleValue:[[parameters.initials objectAtIndex:2] doubleValue]];
	[initk4 setDoubleValue:[[parameters.initials objectAtIndex:3] doubleValue]];
	[initk5 setDoubleValue:[[parameters.initials objectAtIndex:4] doubleValue]];
	
	if([[parameters.optimize objectAtIndex:0] doubleValue]){
		[randk1 setState:NSOnState];
		[initk1 setEnabled:NO];
	}
	if([[parameters.optimize objectAtIndex:1] doubleValue]){
		[randk2 setState:NSOnState];
		[initk2 setEnabled:NO];
	}
	if([[parameters.optimize objectAtIndex:2] doubleValue]){
		[randk3 setState:NSOnState];
		[initk3 setEnabled:NO];
	}
	if([[parameters.optimize objectAtIndex:3] doubleValue]){
		[randk4 setState:NSOnState];
		[initk4 setEnabled:NO];
	}
	if([[parameters.optimize objectAtIndex:4] doubleValue]){
		[randk5 setState:NSOnState];
		[initk5 setEnabled:NO];
	}
}

-(id)initWithParameter:(KMModelRunningConditions*) k {
	if(parameters) parameters.release;
	parameters = [k retain];
	return self;
}

-(void)windowWillClose:(NSNotification *)notification{
	self.release;
}

-(void) dealloc{
	NSLog(@"FDGParamUI dealloc");
	if(parameters) [parameters release];
	[super dealloc];
}

-(IBAction)checkRandomButton:(id)sender
{
	if (sender == randk1) {
		if([sender state] == NSOnState) [initk1 setEnabled:NO];
		else [initk1 setEnabled:YES];
	}
	if (sender == randk2) {
		if([sender state] == NSOnState) [initk2 setEnabled:NO];
		else [initk2 setEnabled:YES];
	}

	if (sender == randk3) {
		if([sender state] == NSOnState) [initk3 setEnabled:NO];
		else [initk3 setEnabled:YES];
	}

	if (sender == randk4) {
		if([sender state] == NSOnState) [initk4 setEnabled:NO];
		else [initk4 setEnabled:YES];
	}

	if (sender == randk5) {
		if([sender state] == NSOnState) [initk5 setEnabled:NO];
		else [initk5 setEnabled:YES];
	}	
}

-(IBAction)checkSideOptions:(id)sender{
	BOOL ison = NO;
	if([sender state] == NSOnState) ison = YES;
	if(sender == uballones){
		[upperk1 setDoubleValue:1];
		[upperk2 setDoubleValue:1];
		[upperk3 setDoubleValue:1];
		[upperk4 setDoubleValue:1];
		[upperk5 setDoubleValue:1];
		
		[upperk1 setEnabled:ison];
		[upperk2 setEnabled:ison];
		[upperk3 setEnabled:ison];
		[upperk4 setEnabled:ison];
		[upperk5 setEnabled:ison];
	}
	else if (sender == lballzeros){
		[lowerk1 setDoubleValue:0];
		[lowerk2 setDoubleValue:0];
		[lowerk3 setDoubleValue:0];
		[lowerk4 setDoubleValue:0];
		[lowerk5 setDoubleValue:0];
		
		[lowerk1 setEnabled:ison];
		[lowerk2 setEnabled:ison];
		[lowerk3 setEnabled:ison];
		[lowerk4 setEnabled:ison];
		[lowerk5 setEnabled:ison];
	}
	else if (sender == randall && [sender state] == NSOnState){		
		randk1.state = randk2.state = randk3.state = randk4.state = randk5.state = randall.state;
		[self checkRandomButton:randk1];
		[self checkRandomButton:randk2];
		[self checkRandomButton:randk3];
		[self checkRandomButton:randk4];
		[self checkRandomButton:randk5];
	}
}

-(IBAction)setParameters:(id)sender{
	
	parameters.lowerbounds = [NSArray arrayWithObjects:
							[NSNumber numberWithDouble:[lowerk1 doubleValue]], 
							[NSNumber numberWithDouble:[lowerk2 doubleValue]],
							[NSNumber numberWithDouble:[lowerk3 doubleValue]],
							[NSNumber numberWithDouble:[lowerk4 doubleValue]],
							[NSNumber numberWithDouble:[lowerk5 doubleValue]],
							[NSNumber numberWithDouble:(double)0],
							nil];
	
	parameters.upperbounds = [NSArray arrayWithObjects:
							[NSNumber numberWithDouble:[upperk1 doubleValue]], 
							[NSNumber numberWithDouble:[upperk2 doubleValue]],
							[NSNumber numberWithDouble:[upperk3 doubleValue]],
							[NSNumber numberWithDouble:[upperk4 doubleValue]],
							[NSNumber numberWithDouble:[upperk5 doubleValue]], 
							[NSNumber numberWithDouble:(double)1],
							nil];
	parameters.initials	 = [NSArray arrayWithObjects:
							[NSNumber numberWithDouble:[initk1 doubleValue]], 
							[NSNumber numberWithDouble:[initk2 doubleValue]],
							[NSNumber numberWithDouble:[initk3 doubleValue]],
							[NSNumber numberWithDouble:[initk4 doubleValue]],
							[NSNumber numberWithDouble:[initk5 doubleValue]],
							[NSNumber numberWithInt:0]
							, nil];
	
	parameters.optimize	= [NSArray arrayWithObjects:[NSNumber numberWithInt:randk1.state], 
						   [NSNumber numberWithInt:randk2.state],
						   [NSNumber numberWithInt:randk3.state],
						   [NSNumber numberWithInt:randk4.state],
						   [NSNumber numberWithInt:randk5.state],
						   [NSNumber numberWithInt:0],
						   nil];

	
	parameters.maxIterations=max_iteration.intValue;
	parameters.tolerance=min_tolerance.doubleValue;
	parameters.TotalRuns=randtotal.intValue;
	if(!parameters.saveDefaults) {
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"Invalid Parameters" 
										   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
		[myAlert runModal];
	};
	
}


@end
