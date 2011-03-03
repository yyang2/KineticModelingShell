//
//  KMCustomInput.h
//  KineticModelingShell
//
//  Created by Yang Yang on 11/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class KMData;
@class KMCustomCompartment;

@interface KMCustomInput : NSObject <NSCoding>{
	NSString		*inputname;
	KMCustomCompartment *destination;
	KMData			*inputData;
	NSRect			rect;
	BOOL isSelected;
	
}

@property BOOL isSelected, optimize;
@property double initial, lowerbound, upperbound;
@property(retain) KMCustomCompartment * destination;
@property NSRect rect;
@property(retain) NSString *inputname;
@property (retain) KMData *inputData;
@end
