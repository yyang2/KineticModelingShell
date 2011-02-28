//  KMData.h
//  KM
//
//  Created by Yang Yang on 9/2/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.

#import <Cocoa/Cocoa.h>
#import "vec.hpp"

using namespace KM;

// Class that stores the information of a time activity curve
// can be either tissue or input data.
// has conversion factors if input and tissue are in different units.


@interface KMData : NSObject {
	NSMutableArray	*xvalues, *yvalues, *std;
	NSString		*location, *timepoint;
	double			conversion;
	BOOL			useWeights,inputfile;
}

@property BOOL useWeights, inputfile;

-(vector)changeArrayIntoVector:(NSMutableArray *)target;
-(vector)values;
-(vector)times;
-(vector)weights;

-(void)setUseWeights:(BOOL)flag;
- (id)initWithFile:(NSString *)address isInput:(BOOL)input andTimePoint:(NSString *) type useWeights:(BOOL) flag;
-(BOOL)hasFile;
-(int)totalpoints;
-(BOOL)setTimes:(NSArray*)timesarray values:(NSArray*)values withTimePoint:(NSString *)type;
-(BOOL)setSTD:(NSArray*)weights;
-(NSString*)fileName;
-(void)setconversion:(double)conv;
-(int)loadfile:(NSString *)address withTimePoint:(NSString *) type;
-(NSPoint)timerange;
-(NSPoint)valuerange;
-(NSArray*)allpoints;
-(void)setTimePoint:(NSString*)type;

@end