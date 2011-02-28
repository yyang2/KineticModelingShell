//
//  KMCustomModelView.h
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class KMCustomModel;
@class KMCustomCompartment;
@class KMCustomModelWindow;
@class KMCustomParameter;
@class KMCustomInput;
extern NSString* const KMCompartmentResizingX;
extern NSString* const KMCompartmentResizingY;
extern NSString* const KMCompartmentMoving;
extern NSString* const KMCompartmentNone;
extern NSString* const KMCompartmentDrawing;

// Custom NSView class that visually displays the KMCustomModel the user has created.
// Is an element in KMCustomModelWindow class
@interface KMCustomModelView : NSView {
	
	KMCustomModel	*model;
	KMCustomModelWindow *controller;
	NSRect			sidebar;			//palette of new compartments to drag onto the view. contains newCompartment and newInput
	KMCustomCompartment *newCompartment;// both newCompartment and newInput are on the sidebar and can be dragged onto the main view.
	KMCustomInput		*newInput;		// this would then add the compartment onto the 

	NSString		*state;		//stores current state of the view: resizing, redrawing, etc.
	NSPoint			anchor,		//anchor point for creating new connections between compartments
	cursor;						//current cursor position;
	NSDictionary	*selected;	//current selected element, can be compartment or connection
	NSRect			previousrect; // holder for pre-moving compartment rect size
}

@property NSPoint	anchor;
@property (retain) NSString*	state;
@property NSRect sidebar;
@property (retain) KMCustomCompartment* newCompartment;
@property (retain) KMCustomModel* model;
@property (retain) NSDictionary *selected;
@property (retain) KMCustomInput* newInput;
-(BOOL)selectionIsCompartment;
-(KMCustomCompartment*)selectedCompartment;
-(KMCustomParameter*)selectedParameter;
-(KMCustomInput*)selectedInput;
-(KMCustomParameter*)pointInParameter:(NSPoint)pt;
-(KMCustomInput *)pointInInput:(NSPoint)pt;

-(id)startWithController:(KMCustomModelWindow*)c;
-(KMCustomCompartment*)pointInCompartment:(NSPoint)pt;
-(KMCustomCompartment*)replaceCompartment;
-(KMCustomInput*)replaceInput;
-(void)setModel:(KMCustomModel*)m;
-(void)clearModel;
-(BOOL)willCollide:(NSRect)moved;
-(id)initWithFrame:(NSRect)frameRect;
-(void)drawCompartments;
-(void)drawParameters;
-(void)drawInputs;
//draw compartment
//draw connections


@end
