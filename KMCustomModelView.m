//
//  KMCustomModelView.m
//  KineticModelingShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMCustomModelView.h"
#import "KMCustomCompartment.h"
#import "KMCustomModel.h"
#import "KMCustomModelWindow.h"
#import "KMCustomParameter.h"
#import "KMCustomInput.h"

@implementation KMCustomModelView
@synthesize sidebar;
@synthesize model;
@synthesize state;
@synthesize selected;
@synthesize newCompartment;
@synthesize anchor;
@synthesize newInput;

NSString* const KMInputMoving			= @"KMInputMoving";
NSString* const KMCompartmentResizingX	= @"KMCompartmentResizingX";
NSString* const KMCompartmentResizingY	= @"KMCompartmentResizingY";
NSString* const KMCompartmentMoving		= @"KMCompartmentMoving";
NSString* const KMCompartmentNone		= @"KMNone";
NSString* const KMCompartmentDrawing	= @"KMDrawing";

-(void)dealloc{
	if(model) [model release];
	self.state = nil;
	self.selected = nil;
	controller = nil;
	[super dealloc];
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(!self) return nil;
	self.sidebar = frameRect;
	self.state = @"None";
	self.selected = nil;
	self.anchor = NSMakePoint(-100, -100);
	sidebar.size.width = frameRect.size.width*.25;
	sidebar.size.height = frameRect.size.height*.5;
	sidebar.origin.y = frameRect.size.height/2;
	
	self.newCompartment = [self replaceCompartment];
	self.newInput		= [self replaceInput];
	//other stuff
	
	return self;
}

-(id)startWithController:(KMCustomModelWindow*)c{
	if(controller) [controller release];
	controller = c;
	self.model = controller.model;
	[self setNeedsDisplay:YES];
	return self;
}

-(BOOL)willCollide:(NSRect)moved{
	//check if rect will collide with any object, whether its the sidebar, new compartment, or some other model
	KMCustomCompartment *selectedComp = self.selectedCompartment;
	if(selectedComp != newCompartment){
		if (!NSEqualRects(NSIntersectionRect(sidebar, moved), NSMakeRect(0, 0, 0, 0))) 
			return YES;
	}
	
	for(int i =0; i<[[model allCompartments] count]; i++){
		KMCustomCompartment *temp = [[model allCompartments] objectAtIndex:i];
		if(temp != selectedComp) {
			if (!NSEqualRects(NSIntersectionRect(temp.rect, moved), NSMakeRect(0, 0, 0, 0))) {
				return YES;
			}
		}
	}
	
	return NO;
}


-(KMCustomCompartment*)replaceCompartment{
	KMCustomCompartment *new = [[KMCustomCompartment alloc] initWithName:@"NewCompartment" type:@"Tissue"];
	new.rect = NSMakeRect(sidebar.origin.x+sidebar.size.width/8, sidebar.origin.y+sidebar.size.height/8, sidebar.size.width/2, sidebar.size.height/2);
	return new;
}

-(KMCustomInput*)replaceInput{
	KMCustomInput *new = [[KMCustomInput alloc] initWithName:@"NewInput"];
	
	new.rect = NSMakeRect(sidebar.origin.x + sidebar.size.width/8, sidebar.origin.y + sidebar.size.height*.75 , sidebar.size.width/2, 20);
	return new;
}


-(void)drawRect:(NSRect)dirtyRect{
	
	
    NSColor* backgroundColor = [NSColor blueColor];
    
    
    
    NSRect bounds = self.bounds;    
    [backgroundColor set];
    NSRectFill ( bounds );	
	
	[[NSColor orangeColor] set];
	NSRectFill(sidebar);
	
	
	
	if(state == KMCompartmentDrawing){
		
		KMCustomCompartment *selectedComp = self.selectedCompartment;
		
		NSBezierPath* aPath = [NSBezierPath bezierPath];
		
		[[NSColor blackColor] set];
		[aPath moveToPoint:NSMakePoint(selectedComp.rect.origin.x+anchor.x*selectedComp.rect.size.width,
									   selectedComp.rect.origin.y+anchor.y*selectedComp.rect.size.height)];
		[aPath lineToPoint:cursor];
		[aPath setLineWidth:5.0];
		[aPath stroke];
		
		[[NSColor redColor] set];
		[aPath setLineWidth:3.5];
		[aPath stroke];
	}
	
	//changing the order will change which objects appear on the bottom versus the top
	[self drawParameters];
	[self drawCompartments];
	[self drawInputs];
}


-(void)drawInputs{
	
	
	NSBezierPath* thePath = [NSBezierPath bezierPath];
	
	[thePath appendBezierPathWithRoundedRect:newInput.rect xRadius:newInput.rect.size.width*.1 yRadius:newInput.rect.size.height*.1];
	[thePath fill];
	[[NSColor grayColor] set];
	[thePath stroke];
	
	for(int i=0; i<[model.Inputs count]; i++){
		KMCustomInput *cur = [model.Inputs objectAtIndex:i];
		
		NSBezierPath* thePath = [NSBezierPath bezierPath];
		
		[thePath appendBezierPathWithRoundedRect:cur.rect xRadius:cur.rect.size.width*.1 yRadius:cur.rect.size.height*.1];
		[thePath fill];
		[[NSColor grayColor] set];
		[thePath stroke];

	}
}

-(void)drawParameters{
	
	//drawing all connections first
	for(int i=0;i<[model.Parameters count]; i++){
		KMCustomParameter *cur = [model.Parameters objectAtIndex:i];
		NSBezierPath* aPath = [cur directPath];
		
		[aPath setLineWidth:5.0];
		[[NSColor blackColor] set];
		[aPath stroke];
		
		[[NSColor redColor] set];
		
		[aPath setLineWidth:4.0];
		[aPath stroke];
	}
	
}

#pragma mark -
#pragma mark Drawing Objects

-(void)drawCompartments{

	NSColor* foregroundColor;
	
	for(int i=0;i<[[model allCompartments] count]; i++){
		KMCustomCompartment *cur = [[model allCompartments] objectAtIndex:i];
		
		
		
		
		if(cur.isSelected) foregroundColor = [NSColor greenColor];
		else foregroundColor = [NSColor yellowColor];
		[foregroundColor set];
		
		
		NSBezierPath* thePath = [NSBezierPath bezierPath];
		
		[thePath appendBezierPathWithRoundedRect:cur.rect xRadius:cur.rect.size.width*.1 yRadius:cur.rect.size.height*.1];
		[thePath fill];
		[[NSColor grayColor] set];
		[thePath stroke];
		
	}
	
	if(newCompartment.isSelected) foregroundColor = [NSColor greenColor];
	else foregroundColor = [NSColor yellowColor];
	[foregroundColor set];
	NSBezierPath* thePath = [NSBezierPath bezierPath];
	
	[thePath appendBezierPathWithRoundedRect:newCompartment.rect xRadius:newCompartment.rect.size.width*.1 yRadius:newCompartment.rect.size.height*.1];
	[thePath fill];
	[[NSColor grayColor] set];
	[thePath stroke];
}

-(void)setModel:(KMCustomModel*)m{
	model = [m retain];
}

-(void)clearModel{
	[model release];
	model = nil;
}


#pragma mark -
#pragma mark Identifying Objects

-(KMCustomInput*)selectedInput{
	return [selected objectForKey:@"KMCustomInput"];
}
-(KMCustomParameter*)selectedParameter{
	return [selected objectForKey:@"KMCustomParameter"];
}

-(KMCustomCompartment*)selectedCompartment{
	
	return [selected objectForKey:@"KMCustomCompartment"];
}

-(BOOL)selectionIsCompartment{
	if(!selected) return NO;
	
	id compOrParam = [selected.allValues lastObject];
	if([[compOrParam className] isEqualToString:@"KMCustomCompartment"]) return YES;
	
	return NO;
}

-(KMCustomCompartment*)pointInCompartment:(NSPoint)pt{
	//function that scrolls through all the compartments in the model to determine if point is in that compartment's drawn rect
	
	for(int i=0;i<[[model allCompartments] count]; ++i ){
		KMCustomCompartment *cur = [[model allCompartments] objectAtIndex:i];
		if(NSPointInRect(pt, cur.rect)){
			return cur;
		}
	}
	if(NSPointInRect(pt, newCompartment.rect)) return newCompartment;

	return nil;
}


-(KMCustomInput*)pointInInput:(NSPoint)pt{
	for(int i=0; i<[model.Inputs count]; i++){
		KMCustomInput *cur = [model.Inputs objectAtIndex:i];
		if(NSPointInRect(pt, cur.rect)) 
			return cur;
	}
	
	if(NSPointInRect(pt,newInput.rect))
	   return newInput;
	else
		return nil;

}
-(KMCustomParameter*)pointInParameter:(NSPoint)pt{
	
	for(int i=0; i<[model.Parameters count]; i++){
		NSBezierPath *cur = [[model.Parameters objectAtIndex:i] contour];
		if([cur containsPoint:pt]) return [model.Parameters objectAtIndex:i];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Event Handling

// The events handled here are just moving objects
// the views only handle geometry!

// The object positions are updated in real time - the rect positions change in our model according to the mouse positions
// at every mouse up, we send a message to the controller to "move" the rect so the position could be added to the undoqueue.
// advanced things like detection of destination compartments in our KMCustomInput are handled by the controller.


-(void)keyDown:(NSEvent *)theEvent
{
	
	unichar c = [[theEvent characters] characterAtIndex:0];

	if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		if(!selected) return;
		else if([selected objectForKey:@"KMCustomParameter"]){
			[controller removeElement:[selected objectForKey:@"KMCustomParameter"]];
			NSLog(@"Deleting Parameter");
		}
		else if([selected objectForKey:@"KMCustomCompartment"]){
			[controller removeElement:[selected objectForKey:@"KMCustomCompartment"]];
			NSLog(@"Deleting Compartment");
		}

		self.selected = nil;
		[controller setSelected:nil];
		

	}
	else {
		//pass keystrokes to the controller
		NSLog(@"Passing Keystrokes on%@", theEvent);
		[controller keyDown:theEvent];
	}

}

-(void)mouseDown:(NSEvent*)theEvent{
	NSDictionary *previous;
	NSPoint clicked = theEvent.locationInWindow;
	if(selected) { previous = [selected retain];}
	
	
	//clicked in compartment? Parameter? Or nowhere?
	if([self pointInCompartment:clicked])
		self.selected = [NSDictionary dictionaryWithObject:[self pointInCompartment:clicked] forKey:@"KMCustomCompartment"];
	
	else if([self pointInParameter:clicked])
		self.selected = [NSDictionary dictionaryWithObject:[self pointInParameter:clicked] forKey:@"KMCustomParameter"];
	else if([self pointInInput:clicked])
		self.selected = [NSDictionary dictionaryWithObject:[self pointInInput:clicked] forKey:@"KMCustomInput"];
	else 
		self.selected = nil;
	
	//	NSLog(@"Selected:%@",selected);
	[controller changeSelected:selected];

	if(selected != previous) { //update selection state
		[[previous.allValues lastObject] setIsSelected:NO];
		[[selected.allValues lastObject] setIsSelected:YES];
		[self setNeedsDisplay:YES];	
	}
	
	if(!selected) return;
	
	id compOrParam = [selected.allValues lastObject];
	
	if([[compOrParam className] isEqualToString:@"KMCustomCompartment"]){
		
		KMCustomCompartment *selectedComp = compOrParam;
			previousrect = selectedComp.rect;
		if(fabs(clicked.x-selectedComp.rect.origin.x-selectedComp.rect.size.width)<2)	
			self.state = KMCompartmentResizingX;
		else if(fabs(clicked.y-selectedComp.rect.origin.y)<2)						
			self.state = KMCompartmentResizingY;
		else 
			self.state = KMCompartmentMoving;
		
	}
	else if([[compOrParam className] isEqualToString:@"KMCustomParameter"]){
		NSLog(@"From View, Parameter Selected");
	}
	else if([[compOrParam className] isEqualToString:@"KMCustomInput"]){
		self.state = KMInputMoving;
		previousrect = [compOrParam rect];
 	}
	
	if(previous) [previous release];
	
}

-(void)mouseDragged:(NSEvent *)theEvent{
	
	if(!selected) return;
	
	if([self.state hasPrefix:@"KMCompartment"]){
		KMCustomCompartment *selectedComp = [selected objectForKey:@"KMCustomCompartment"];
		NSRect newrect;
		
		//		NSLog(@"Selected:%@", selected);
		if(self.state == KMCompartmentResizingX){
			if(selectedComp == newCompartment) return;
			else if(selectedComp.rect.size.width+theEvent.deltaX<KM_MIN_WIDTH) return;
			newrect=NSMakeRect(selectedComp.rect.origin.x, selectedComp.rect.origin.y,
							   selectedComp.rect.size.width+theEvent.deltaX, selectedComp.rect.size.height);
		}
		else if(self.state == KMCompartmentResizingY){
			NSLog(@"ResizingY");
			if(selectedComp == newCompartment) return;
			else if (selectedComp.rect.size.height+theEvent.deltaY<KM_MIN_HEIGHT) return;
			
			newrect=NSMakeRect(selectedComp.rect.origin.x, selectedComp.rect.origin.y-theEvent.deltaY,
							   selectedComp.rect.size.width, selectedComp.rect.size.height+theEvent.deltaY);
		}
		else if(self.state == KMCompartmentMoving){
			newrect=NSMakeRect(selectedComp.rect.origin.x+theEvent.deltaX, selectedComp.rect.origin.y-theEvent.deltaY,
							   selectedComp.rect.size.width, selectedComp.rect.size.height);
		}
		
		
		if([self willCollide:newrect]) return;// collision detection
		selectedComp.rect = newrect;
		[self setNeedsDisplay:YES];
	}
	
	if([self.state hasPrefix:@"KMInput"]){
		KMCustomInput *selectedInput = [selected objectForKey:@"KMCustomInput"];
		NSRect newrect;
		if(self.state == KMInputMoving){
			newrect=NSMakeRect(selectedInput.rect.origin.x+theEvent.deltaX, selectedInput.rect.origin.y-theEvent.deltaY,
							   selectedInput.rect.size.width, selectedInput.rect.size.height);
		}

		selectedInput.rect = newrect;
		[self setNeedsDisplay:YES];
	}
	//KM
}

-(void)mouseUp:(NSEvent *)theEvent{
	if([self.state hasPrefix:@"KMCompartment"]){
		KMCustomCompartment *selectedComp = [selected objectForKey:@"KMCustomCompartment"];

		if(selectedComp == newCompartment){
			if( NSEqualRects(NSIntersectionRect(selectedComp.rect, sidebar), NSMakeRect(0, 0, 0, 0)) ){
				//if newCompartment is out of
				newCompartment.isSelected=NO;
				
				[controller addElement: newCompartment];
				[controller changeCompartment:[NSDictionary dictionaryWithObjectsAndKeys:newCompartment, @"Compartment", NSStringFromRect(newCompartment.rect), @"Rect",nil]];
				
				
				self.newCompartment = self.replaceCompartment;
				self.selected=nil;
			}	
		}
		else {
			if (NSStringFromRect(previousrect) == NSStringFromRect(selectedComp.rect)) {
				// do nothing!
			}
			else {
				[controller changeCompartment:[NSDictionary dictionaryWithObjectsAndKeys:selectedComp, @"Compartment",
											   NSStringFromRect(selectedComp.rect), @"Rect", nil]];
			}
		}

	}
	if([self.state hasPrefix:@"KMInput"]){
		KMCustomInput *selectedInput = [selected objectForKey:@"KMCustomInput"];
		
		if(selectedInput == newInput){
			if( NSEqualRects(NSIntersectionRect(selectedInput.rect, sidebar), NSMakeRect(0, 0, 0, 0)) ){
				//if newCompartment is out of
				newInput.isSelected=NO;
				
				[controller addElement: newInput];
				[controller changeInput:[NSDictionary dictionaryWithObjectsAndKeys:newInput, @"KMCustomInput", NSStringFromRect(newInput.rect), @"Rect", nil]];
				self.newInput = self.replaceInput;
				self.selected=nil;
			}	
		}
		else {
			if (NSStringFromRect(previousrect) == NSStringFromRect(newInput.rect)) {
				// do nothing!
			}
			else {
				[controller changeInput:[NSDictionary dictionaryWithObjectsAndKeys:selectedInput, @"KMCustomInput",
												   NSStringFromRect(selectedInput.rect), @"Rect", nil]];
			}
		}
		
		
	}
	
	self.state=KMCompartmentNone;
	[self setNeedsDisplay:YES];
	//	NSLog(@"Back To None %@", self.state);
}


// The right mouse button is used to handle drawing parameters between compartments

-(void)rightMouseDown:(NSEvent *)theEvent{
	NSPoint clicked = theEvent.locationInWindow;
	
	NSLog(@"Right clicked Point, %@", NSStringFromPoint(clicked));
	if(![self selectionIsCompartment])return;
	
	KMCustomCompartment *selectedComp = self.selectedCompartment;
	
	if(selectedComp == newCompartment) return;
	
	if(NSPointInRect(clicked, selectedComp.rect)){
		self.state = KMCompartmentDrawing;
		cursor = theEvent.locationInWindow;
	}
}

-(void)rightMouseDragged:(NSEvent *)theEvent{
	cursor = theEvent.locationInWindow;

	
	if (state!= KMCompartmentDrawing) return;
	else if(NSEqualPoints(NSMakePoint(-100, -100), anchor)){
		KMCustomCompartment *selectedComp = [self selectedCompartment];
		if(!NSPointInRect(cursor, selectedComp.rect)){
			
			self.anchor = NSMakePoint((cursor.x-selectedComp.rect.origin.x)/selectedComp.rect.size.width
									  ,(cursor.y-selectedComp.rect.origin.y)/selectedComp.rect.size.height);
			if(anchor.x >1) anchor.x =1;
			else if(anchor.x <0) anchor.x=0;
			if(anchor.y >1) anchor.y =1;
			else if(anchor.y <0) anchor.y=0;
		}
	}

	
	
	[self setNeedsDisplay:YES];
	
	
}

-(void)rightMouseUp:(NSEvent *)theEvent{
	if(state != KMCompartmentDrawing || NSEqualPoints(NSMakePoint(-100, -100), anchor)) return;
	
	KMCustomCompartment *selectedComp = [selected objectForKey:@"KMCustomCompartment"];
	NSPoint endpt = theEvent.locationInWindow;
	
	KMCustomCompartment *end = [self pointInCompartment:endpt];
	
	if(end && (end != selectedComp)){
		
		NSPoint endpoint = NSMakePoint((cursor.x-end.rect.origin.x)/end.rect.size.width
								  ,(cursor.y-end.rect.origin.y)/end.rect.size.height);
		if(endpoint.x >1) endpoint.x =1;
		else if(endpoint.x <0) endpoint.x=0;
		if(endpoint.y >1) endpoint.y =1;
		else if(endpoint.y <0) endpoint.y=0;
		
		NSLog(@"Starting Pt; %@, ending point:%@", NSStringFromPoint(anchor), NSStringFromPoint(endpoint));
		
		KMCustomParameter *newparameter = [[KMCustomParameter alloc] initAtComp:selectedComp pt:anchor endAtComp:end pt:endpoint];	
		[controller addElement:newparameter];
	}
	
	state = KMCompartmentNone;
	[self setNeedsDisplay:YES];
	self.anchor = NSMakePoint(-100, -100);
	
}




@end
