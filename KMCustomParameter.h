//
//  KMCustomParameter.h
//  KineticModelingShell
//
//  Created by Yang Yang on 11/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMParameter.h"
@class KMCustomCompartment;

//class responsible for storing information on each parameter.

@interface KMCustomParameter : KMParameter <NSCoding> 

{
	KMCustomCompartment		*origin_comp, *destin_comp;
	NSPoint					originpt, destinpt;
	BOOL					isSelected;
}
@property	BOOL	isSelected;
@property (retain) KMCustomCompartment *origin_comp, *destin_comp;
@property	NSPoint originpt, destinpt;
-(NSBezierPath*)directPath;
-(NSBezierPath*)contour;
-(id)initAtComp:(KMCustomCompartment*)org pt:(NSPoint)orgpt endAtComp:(KMCustomCompartment*)end pt:(NSPoint)endpt;
@end
