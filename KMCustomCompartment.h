//
//  KMCustomCompartment.h
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//
static const float KM_MIN_HEIGHT=20;
static const float KM_MIN_WIDTH =20;
@class KMCustomInput;

#import <Cocoa/Cocoa.h>

@interface KMCustomCompartment : NSObject <NSCoding> {
	NSString		*compartmentname, *compartmenttype;
	BOOL			isTissue, isSelected;
	NSRect			rect;
	NSPoint			upperleft;
	KMCustomInput	*input;
}

@property (retain) NSString *compartmentname;
@property (retain) NSString *compartmenttype;
@property (retain) KMCustomInput *input;
@property BOOL isTissue;
@property BOOL isSelected;
@property NSRect rect;
@property NSPoint upperleft;
-(void)moveCompartment:(NSPoint) offset;
-(id)initWithName:(NSString*)name type:(NSString*)d;
-(BOOL)isComplete;

@end
