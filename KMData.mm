//
//  KMData.m
//  KM
//
//  Created by Yang Yang on 9/2/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "KMData.h"


@implementation KMData

using namespace KM;
#pragma mark -
#pragma mark Init and Dealloc

@synthesize useWeights;
@synthesize inputfile;

-(id)initWithFile:(NSString *)address isInput:(BOOL)input andTimePoint:(NSString *) type useWeights:(BOOL) flag{
	if (![super init]) return nil;
	inputfile	=	input;
	useWeights	=	flag;
	location	=	address;
	timepoint	=	type;
	
	[location retain];
	[timepoint retain];

	if([self loadfile:address withTimePoint:type])
	return self;
	else return nil;
}

-(int)loadfile:(NSString *)address withTimePoint:(NSString *) type{
	if(std) [std release];
	if(xvalues) [xvalues release];
	if(yvalues) [yvalues release];
	
	//	location = address;
	//	timepoint = type;
	
	conversion = 1.f;
	
	BOOL firstlinelabel = NO;
	
	NSArray *lines = [[NSString stringWithContentsOfFile:address encoding:NSASCIIStringEncoding error:nil] componentsSeparatedByString:@"\n"];
	NSArray *elements = [[lines objectAtIndex:0] componentsSeparatedByString:@"\t"];
	int i, xcolumn = 999, ycolumn = 999, stdcolumn =999, maxcolumns = [elements count], firstline;
	
	
	//check to make sure its a table
	for(i=0;i< (int)[lines count];i++){
		if (maxcolumns != (int)[[[lines objectAtIndex:i] componentsSeparatedByString:@"\t"] count]) {
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"Input File needs to be in table format!" 
											   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
			[myAlert runModal];
			
			
			return 0; 
			
		}
	}
	
	//automatically read column header for 
	for(i=0;i<maxcolumns;i++){
		if ([[elements objectAtIndex:i] doubleValue]) {
			break;
		}
		if([[elements objectAtIndex:i] isEqualToString:@"Time"]) {
			xcolumn = i; firstlinelabel = YES;
		}
		if([[elements objectAtIndex:i] isEqualToString:@"Concentration"]) {
			firstlinelabel = YES;
			ycolumn = i;
		}
		if([[elements objectAtIndex:i] isEqualToString:@"Standard Deviation"] && useWeights){
			firstlinelabel = YES;
			stdcolumn = i;
		}
		if([[elements objectAtIndex:i] isEqualToString:@"Input"] && inputfile) {
			firstlinelabel = YES;
			ycolumn = i;
		}
		
		if([[elements objectAtIndex:i] isEqualToString:@"Tissue"] && !inputfile) {
			firstlinelabel = YES;
			ycolumn = i;
		}
	}
	if(firstlinelabel) firstline = 1;
	else  firstline = 0;
	if(stdcolumn = 999 && useWeights)		stdcolumn = [[NSUserDefaults standardUserDefaults] integerForKey:@"KMStdColumn"]-1;
	if(xcolumn = 999) 		xcolumn = [[NSUserDefaults standardUserDefaults] integerForKey:@"KMTimeColumn"]-1;
	if(ycolumn = 999 && inputfile){
		ycolumn = [[NSUserDefaults standardUserDefaults] integerForKey:@"KMInputColumn"]-1;
	}
	else if (ycolumn = 999){
		ycolumn = [[NSUserDefaults standardUserDefaults] integerForKey:@"KMTissueColumn"]-1;
	}
	
	if (xcolumn > maxcolumns || ycolumn > maxcolumns || stdcolumn > maxcolumns) {
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"Defined columns out of bounds!"
										   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
		[myAlert runModal];
		return 0;
	}
	
	else {
		xvalues = [NSMutableArray array];
		yvalues = [NSMutableArray array];
		if (useWeights) std     = [NSMutableArray array];
		
 		for(i=firstline; i<(int)[lines count] - firstline; i++){
			NSArray *currentline = [[lines objectAtIndex:i] componentsSeparatedByString:@"\t"];
			[xvalues addObject:
			 [NSNumber numberWithDouble:[[currentline objectAtIndex:xcolumn] doubleValue]]];
			[yvalues addObject:
			 [NSNumber numberWithDouble:[[currentline objectAtIndex:ycolumn] doubleValue]]];
			if(useWeights){
				[std	 addObject:
				 [NSNumber numberWithDouble:[[currentline objectAtIndex:stdcolumn] doubleValue]]];}
		}
		
		for(i=1; i<(int)[xvalues count]; i++){ //time must be strictly increasing
			if([[xvalues objectAtIndex:i-1] doubleValue] >= [[xvalues objectAtIndex:i]doubleValue]) {
				NSAlert *myAlert = [NSAlert alertWithMessageText:@"Time must be increasing!" 
												   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
				[myAlert runModal];
				
				return 0;
				
			}
		}
		
		[xvalues retain];
		[yvalues retain];
		if(useWeights) [std retain];
	}
	
	return 1;
}

-(void) dealloc {
	if(inputfile) NSLog(@"InputData Dealloc");
	else		  NSLog(@"TissueData Dealloc");
	if(std)		[std     release];
	if(xvalues) [xvalues release];
	if(yvalues) [yvalues release];
	if(location) [location release];
	if(timepoint) [timepoint release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark settors

-(void)setTimePoint:(NSString*)type{
	timepoint = type;
}

-(void)setUseWeights:(BOOL)flag{
	useWeights = flag;
}

-(void)setconversion:(double)conv{
	if(inputfile) return;
	conversion = conv;
}


-(BOOL)setSTD:(NSArray*)weights{
	if(xvalues.count == weights.count){
		if(std) [std release];
		std = [weights retain];
		return TRUE;
	}
	return FALSE;
}
-(BOOL)setTimes:(NSArray*)timesarray values:(NSArray*)values withTimePoint:(NSString *)type{
	if(timesarray.count == values.count && 
	   ( [type isEqualToString:@"Start"] || [type isEqualToString:@"Mid"] || [type isEqualToString:@"End"])){
		if(xvalues) [xvalues release];
		if(yvalues) [yvalues release];
		if(timepoint) [timepoint release];
		
		xvalues = [timesarray retain];
		yvalues = [values retain];
		timepoint = [type retain];
		[self setconversion:1.f];
		return TRUE;
	}
	return FALSE;	
}

#pragma mark -
#pragma mark accessors
-(NSPoint)timerange{
 	if(!xvalues)	return NSMakePoint(0, 0);
	
	NSPoint currentpoint = NSMakePoint([[xvalues objectAtIndex:0] doubleValue], [[xvalues lastObject] doubleValue]);
	return currentpoint;
}

-(NSPoint)valuerange{
	if (!yvalues) return NSMakePoint(0, 0);
	
	NSMutableArray *temparray = yvalues;
	double min = [[[temparray sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0] doubleValue];
	double max = [[[temparray sortedArrayUsingSelector:@selector(compare:)] lastObject] doubleValue];
	NSPoint currentpoint = NSMakePoint(min,max);
	return currentpoint;
}

-(int)totalpoints {
	if(xvalues) return xvalues.count;
	else return 0;
}

-(NSArray*)allpoints {
	
	
	NSMutableArray *values = [NSMutableArray array];
	
	for(int i=0; i<(int)[xvalues count]; i++){
		NSPoint currentpoint = NSMakePoint([[xvalues objectAtIndex:i] doubleValue], conversion*[[yvalues objectAtIndex:i] doubleValue]);
		[values addObject:NSStringFromPoint(currentpoint)];
	}
	
	return values;
}

-(BOOL)hasFile{
	if(location) return YES;
	else return NO;
}

-(NSString*) fileName{
	return location;
}
-(vector)times{
	return [self changeArrayIntoVector:xvalues];
}
-(vector)values{
	return (double)conversion*[self changeArrayIntoVector:yvalues];
}
-(vector)weights{
	if(inputfile || !useWeights){
		return vector((int)xvalues.count,(double)1);
	}
	
	NSMutableArray *duration = [NSMutableArray arrayWithCapacity:xvalues.count];
	if ([timepoint isEqualToString:@"Start"]){
		
		for(int i=0; i<(int)xvalues.count-1;++i){			
			double current = [[xvalues objectAtIndex:i] doubleValue];
			double next = [[xvalues objectAtIndex:i+1] doubleValue];
			[duration addObject:[NSNumber numberWithDouble:next-current]];
		}
		[duration addObject:[duration lastObject]];
	}	
	else if	([timepoint isEqualToString:@"Mid"])  {
		for(int i=0; i<(int)xvalues.count-1;++i){			
			double current = [[xvalues objectAtIndex:i] doubleValue];
			double next = [[xvalues objectAtIndex:i] doubleValue];
			[duration addObject:[NSNumber numberWithDouble:next-current]];
		}
		[duration addObject:[duration lastObject]];
	}
	else if ([timepoint isEqualToString:@"End"])  {
		
		for(int i=1; i<(int)xvalues.count;++i){			
			double current = [[xvalues objectAtIndex:i] doubleValue];
			double previous = [[xvalues objectAtIndex:i-1] doubleValue];
			[duration addObject:[NSNumber numberWithDouble:current-previous]];
		}
		[duration addObject:[duration lastObject]];
	}
	
	NSLog(@"Duration:%@",duration);
	
	
	vector weights = vector(xvalues.count);
	int x;
	for(x=0;x<(int)std.count;++x){
		weights[x] = [[duration objectAtIndex:x] doubleValue]/[[std objectAtIndex:x] doubleValue];
	}
	return weights;
}


-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ %@ %@ %f",xvalues, yvalues, timepoint, conversion];
}

-(vector)changeArrayIntoVector:(NSMutableArray *)target{
	vector temp = vector(target.count);
	int x;
	for(x=0;x<(int)target.count;++x){
		temp[x] = [[target objectAtIndex:x] doubleValue];
	}
	return temp;
}










@end
