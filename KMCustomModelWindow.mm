//
//  KMCostumModelWindow.m
//  KineticModelingShell
//
//  Created by Yang Yang on 9/20/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMCustomModelWindow.h"
#import "KMCustomModelView.h"
#import "KMCustomCompartment.h"
#import "KMCustomModel.h"
#import "KMCustomParameter.h"
#import "KMCustomInput.h"
#import "KMCustomInputInterface.h"
#import "KMCustomTissueInterface.h"
#import "KMDataProcessor.h"

@implementation KMCustomModelWindow


@synthesize model;
@synthesize selected;

#pragma mark -
#pragma mark Init and Dealloc

-(id)startWindow
{
	self = [super init];
	if(!self) return nil;
	stack = [[NSUndoManager alloc] init];
	[self initWithWindowNibName:@"CustomModelWindow"];
	[self window];
	return self;
}

-(id)initWithModel:(KMCustomModel*)m
{

	self = [super init];
	if(!self) return nil;

	[self initWithWindowNibName:@"CustomModelWindow"];
	self.model = m;
	[self window];
	
	stack = [[NSUndoManager alloc] init];
	[view startWithController:self];

	NSLog(@"View:%@",view);

	return self;
}


-(void)windowWillClose:(NSNotification *)notification{
	[self release];
}

-(void)dealloc{
	if(stack)	[stack release];
	if(model) self.model = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Buttons and Textboxes


-(void)changeSelected:(NSDictionary*)d{
	self.selected = d;
	[self updateBoxes];
}


-(void)resetBoxes
{
	
	//default items are all enabled, each type will disable the non-related items

	//set blank if no selected item;
	[box1 setStringValue:@""];
	[box2 setStringValue:@""];

	[loadData setTitle:@"View Tissue Data"];
	//numberformatter?
	[box3 setStringValue:@""];
	[box4 setStringValue:@""];
	[des1 setStringValue:@""];
	[des2 setStringValue:@""];
	[des3 setStringValue:@""];
	[des4 setStringValue:@""];
	[loadData setEnabled:YES];
	[check1 setState:NSOffState];
	[check1 setEnabled:YES];
	[check1 setTitle:@""];
}

-(void)updateBoxesParam
{
	[self resetBoxes];
	//set textboxes for Parameter
	KMCustomParameter *param = [selected objectForKey:@"KMCustomParameter"];
	
	[loadData setEnabled:YES];
	[loadData setTitle:@"Load Tissue Data"];
	[check1 setState:param.optimize];
	[check1 setTitle:@"Optimize"];
	[des1 setStringValue:@"Name"];
	[des2 setStringValue:@"Upperbound"];
	[des3 setStringValue:@"Lowerbound"];
	[des4 setStringValue:@"Initial"];
	[box1 setStringValue:param.paramname];
	[box2 setStringValue:[NSString stringWithFormat:@"%f", param.upperbound]];
	[box3 setStringValue:[NSString stringWithFormat:@"%f", param.lowerbound]];
	[box4 setStringValue:[NSString stringWithFormat:@"%f", param.initial]];	

}

-(void)updateBoxesComp
{
	[self resetBoxes];
	KMCustomCompartment *comp = [selected objectForKey:@"KMCustomCompartment"];
	[box1 setStringValue:comp.compartmentname];
	[des1 setStringValue:@"Name"];
	[check1 setState:comp.isTissue];
	[check1 setTitle:@"Tissue"];
	[loadData setEnabled:NO];

}

-(void)updateBoxesInput
{
	[self resetBoxes];
	
	[loadData setTitle:@"View Input Data"];
	KMCustomInput *input = [selected objectForKey:@"KMCustomInput"];
	[box1 setStringValue:input.inputname];
	[des1 setStringValue:@"Name"];
	
	NSLog(@"destination compartment for selected input:%@", input.destination.compartmentname);
	
	[box2 setStringValue:[NSString stringWithFormat:@"%f", input.upperbound]];
	[des2 setStringValue:@"Input Upperbound"];
	
	[box3 setStringValue:[NSString stringWithFormat:@"%f", input.lowerbound]];
	[des3 setStringValue:@"Input Lowerbound"];
	
	[box4 setStringValue:[NSString stringWithFormat:@"%f", input.initial]];
	[des4 setStringValue:@"Input Initial"];
	
	[check1 setEnabled:input.optimize];
	[check1 setTitle:@"Optimize"];

	if(input.inputData) [check1 setState:NSOnState];
	else [check1 setState:NSOffState];

}
-(void)updateBoxes{
	NSLog(@"Current Selected:%@",selected);
	if(!selected){
		[self resetBoxes];
	}
	else if([[[selected allKeys] lastObject] isEqualToString:@"KMCustomParameter"]){
		[self updateBoxesParam];
	}
	else if([[[selected allKeys] lastObject] isEqualToString:@"KMCustomCompartment"]){
		//set textboxes for
		[self updateBoxesComp];		
	}
	else if([[[selected allKeys] lastObject] isEqualToString:@"KMCustomInput"]){
		[self updateBoxesInput];
	}
	else {
		NSLog(@"WTF are you doing here? Selected object needs to be either Parameter or Compartment!");
	}
	
}

#pragma mark -
#pragma mark Changing Model Objects
-(IBAction)propertyChange:(id)sender
{
	if(!selected) return;
	
	if([[[selected allKeys] lastObject] isEqualToString:@"KMCustomParameter"]){
		if(sender == box1) 
			[self changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomParameter"] , @"Parameter", [sender stringValue], @"Name", nil]];
		else if(sender == box2)
			[self changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomParameter"], @"Parameter", [NSNumber numberWithFloat:[sender floatValue]], @"Upperbound",nil]];
		else if(sender == box3)
			[self changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomParameter"], @"Parameter", [NSNumber numberWithFloat:[sender floatValue]], @"Lowerbound",nil]];
		else if(sender == box4)
			[self changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomParameter"], @"Parameter", [NSNumber numberWithFloat:[sender floatValue]], @"Initial",nil]];
		else if(sender == check1)
			[self changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomParameter"], @"Parameter", [NSNumber numberWithInt:check1.state], @"Optimize", nil]];
		else return;
	}
	else if ([[[selected allKeys] lastObject] isEqualToString:@"KMCustomCompartment"]){
		if(sender == box1){
			NSLog(@"New Name %@",[sender stringValue]);
			[self changeCompartment:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomCompartment"], @"Compartment", [sender stringValue], @"Name", nil]];
			
		}
		else if(sender == check1)
			[self changeCompartment:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomCompartment"], @"Compartment", [NSNumber numberWithInt:check1.state], @"Tissue", nil]];
		else return;
	}
	else if ([[[selected allKeys] lastObject] isEqualToString:@"KMCustomInput"]){
		if(sender == box1) 
			[self changeInput:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomInput"] , @"Input", [sender stringValue], @"Name", nil]];
		else if(sender == box2)
			[self changeInput:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomInput"], @"Input", [NSNumber numberWithFloat:[sender floatValue]], @"Upperbound",nil]];
		else if(sender == box3)
			[self changeInput:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomInput"], @"Input", [NSNumber numberWithFloat:[sender floatValue]], @"Lowerbound",nil]];
		else if(sender == box4)
			[self changeInput:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomInput"], @"Input", [NSNumber numberWithFloat:[sender floatValue]], @"Initial",nil]];
		else if(sender == check1)
			[self changeInput:[NSDictionary dictionaryWithObjectsAndKeys:[selected objectForKey:@"KMCustomInput"], @"Input", [NSNumber numberWithInt:check1.state], @"Optimize", nil]];
		
	}
	else {
		NSLog(@"Unrecognized selected object passed to KMCustomModelWindow:%@", selected);
	}

}

-(void)changeParameter:(NSDictionary*)d
{
	if(!selected) 
		NSLog(@"changeParameter called without selected model");
	
	if(![d objectForKey:@"Parameter"]) {
		NSLog(@"changeParameter called without valid parameter");
		return;
	}
	
	// following provides support for undo by finding the current state of the object and adding it to undoqueue
	KMCustomParameter *p = [d objectForKey:@"Parameter"];
	NSString *restoreKey; id restoreobj;
	if([d objectForKey:@"Name"]) {
		restoreobj = p.paramname;
		restoreKey = @"Name";
		if ([restoreobj isEqualToString: [d objectForKey:@"Name"]])
			return;
		else
			p.paramname = [d objectForKey:@"Name"];
		
	}
	else if([d objectForKey:@"Upperbound"]) {
		restoreKey = @"Upperbound";
		restoreobj =  [NSNumber numberWithFloat:p.upperbound];
		if ([restoreobj floatValue] == p.upperbound) 
			return;
		else 
			p.upperbound = [[d objectForKey:@"Upperbound"] doubleValue];
	}
	else if([d objectForKey:@"Lowerbound"]) {
		restoreKey = @"Lowerbound";
		restoreobj = [NSNumber numberWithFloat:p.lowerbound];
		if ([restoreobj floatValue] == p.lowerbound) 
			return;
		else 
			p.lowerbound = [[d objectForKey:@"Lowerbound"] doubleValue];
	} 
	else if([d objectForKey:@"Initial"]){
		restoreKey = @"Initial";
		restoreobj = [NSNumber numberWithFloat:p.initial];
		if ([restoreobj floatValue] == p.initial) 
			return;
		else 
			p.initial = [[d objectForKey:@"Initial"] doubleValue];
	}
	else if([d objectForKey:@"Optimize"]){
		restoreKey = @"Optimize";
		restoreobj = [NSNumber numberWithBool:p.optimize];
		if ([restoreobj boolValue] == p.optimize) 
			return;
		else
			p.optimize = [[d objectForKey:@"Optimize"] boolValue];
	}
	
	[[stack prepareWithInvocationTarget:self] changeParameter:[NSDictionary dictionaryWithObjectsAndKeys:
																	 p, @"Parameter", restoreobj, restoreKey,nil]];
}


-(void)changeCompartment:(NSDictionary*)d
{
	if (!selected) NSLog(@"changeCompartment called without selection");
	
	if(![d objectForKey:@"Compartment"]){
		NSLog(@"changeCompartment caleld without valid compartment");
		return;
	}
	
	KMCustomCompartment *comp	= [d objectForKey:@"Compartment"];
	NSString *restorekey; id restoreobj;
	if([d objectForKey:@"Name"]){
		restoreobj = comp.compartmentname;
		restorekey = @"Name";
		if ([[d objectForKey:@"Name"] isEqualToString:restoreobj]) 
			return;
		else
			comp.compartmentname = [d objectForKey:@"Name"];
	}
	else if ([d objectForKey:@"Tissue"]){
		restoreobj = [NSNumber numberWithBool:comp.isTissue];
		restorekey = @"Tissue";
		
		if( [[d objectForKey:@"Tissue"] boolValue] == comp.isTissue)
			return;
		else
			comp.isTissue = [[d objectForKey:@"Tissue"] boolValue];
	}
	else if([d objectForKey:@"Compartment"]){
		restoreobj = NSStringFromRect(comp.rect);
		restorekey = @"Rect";
		
		comp.rect = NSRectFromString([d objectForKey:@"Rect"]);		
	}
	else return;
	
	[[stack prepareWithInvocationTarget:self] changeCompartment:[NSDictionary dictionaryWithObjectsAndKeys:
																	 comp, @"Compartment", restoreobj, restorekey, nil]];
	
	[view setNeedsDisplay:YES];
}
//
//-(void)changeCompartmentRect:(NSDictionary*)d
//{
//	
//	KMCustomCompartment *comp = [d objectForKey:@"Compartment"];
//	
//	[[stack prepareWithInvocationTarget:self] changeCompartmentRect:[NSDictionary dictionaryWithObjectsAndKeys:
//																 comp, @"Compartment", NSStringFromRect(comp.rect), @"Rect",nil]];
//	
//	NSRect r				  = NSRectFromString([d objectForKey:@"Rect"]);
//	
//	comp.rect = r;
//	[view setNeedsDisplay:YES];
//}
//

-(void)changeInput:(NSDictionary*)d{
	if(![d objectForKey:@"Input"]) return;
	
	KMCustomInput *input = [d objectForKey:@"Input"];
	NSString *restoreKey; id restoreobj;
	if([d objectForKey:@"Name"]){
		restoreKey = @"Name";
		restoreobj = input.inputname;
		
		if([restoreobj isEqualToString:[d objectForKey:restoreKey]])
			return;
		else
			input.inputname = [d objectForKey:restoreKey];
	}
	else if([d objectForKey:@"Rect"]){
		restoreKey = @"Rect";
		restoreobj = NSStringFromRect(input.rect);
		
		input.rect = NSRectFromString([d objectForKey:restoreKey]);
		
		//SET Destination
//		input.destination.input = nil;
//		input.destination = nil;
		for(int j =0; j<[[model allCompartments] count]; j++){
			KMCustomCompartment *current = [[model allCompartments] objectAtIndex:j];
			if(! NSEqualRects(NSIntersectionRect(current.rect, input.rect), NSMakeRect(0, 0, 0, 0)) ){
				input.destination = current;
				current.input = input;
			}
		}
		
	}
	else if([d objectForKey:@"Upperbound"]) {
		restoreKey = @"Upperbound";
		restoreobj =  [NSNumber numberWithFloat:input.upperbound];
		if ([restoreobj floatValue] == input.upperbound) 
			return;
		else 
			input.upperbound = [[d objectForKey:@"Upperbound"] doubleValue];
	}
	else if([d objectForKey:@"Lowerbound"]) {
		restoreKey = @"Lowerbound";
		restoreobj = [NSNumber numberWithFloat:input.lowerbound];
		if ([restoreobj floatValue] == input.lowerbound) 
			return;
		else 
			input.lowerbound = [[d objectForKey:@"Lowerbound"] doubleValue];
	} 
	else if([d objectForKey:@"Initial"]){
		restoreKey = @"Initial";
		restoreobj = [NSNumber numberWithFloat:input.initial];
		if ([restoreobj floatValue] == input.initial) 
			return;
		else 
			input.initial = [[d objectForKey:@"Initial"] doubleValue];
	}
	else if([d objectForKey:@"Optimize"]){
		restoreKey = @"Optimize";
		restoreobj = [NSNumber numberWithBool:input.optimize];
		if ([restoreobj boolValue] == input.optimize) 
			return;
		else
			input.optimize = [[d objectForKey:@"Optimize"] boolValue];
	}	
	else 
		return;
	
	[view setNeedsDisplay:YES];
	[[stack prepareWithInvocationTarget:self] changeInput:[NSDictionary dictionaryWithObjectsAndKeys:input, @"KMCustomInput", restoreobj, restoreKey, nil]];
}

-(void)addElement:(id)obj
{

	if([[obj className] isEqualToString: @"KMCustomCompartment"]){
		[model addCompartment:obj];
	}
	else if ([[obj className] isEqualToString: @"KMCustomParameter"]){
		[model addParameter:obj];
	}
	else if ([[obj className] isEqualToString: @"KMCustomInput"]){
		[model addInput:obj];
	}
	else {
		return;
	}
	
	[[stack prepareWithInvocationTarget:self] removeElement:obj];
	[view setNeedsDisplay:YES];
}

-(IBAction)closePrefs:(id)sender{
//	model.conditions

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:maxIt.intValue] forKey:@"CustomMaxIt"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:minTol.floatValue] forKey:@"CustomMinTol"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:totRuns.intValue] forKey:@"CustomTotRuns"];
	
	[prefPanel performClose:self];
	[NSApp stopModal];
}

-(IBAction)showPrefs:(id)sender
{
	if(![model validateModel]){
		//throw errors
		NSLog(@"Error, your model is incomplete");
	}
	else {
		if(![[NSUserDefaults standardUserDefaults] objectForKey:@"CustomMaxIt"])
		{
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:100] forKey:@"CustomMaxIt"];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:.00001f] forKey:@"CustomMinTol"];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:30] forKey:@"CustomTotRuns"];
		}
		
		[maxIt setIntValue:[[[NSUserDefaults standardUserDefaults] objectForKey:@"CustomMaxIt"] intValue]];
		[minTol setFloatValue:[[[NSUserDefaults standardUserDefaults] objectForKey:@"CustomMinTol"] floatValue]];
		[totRuns setIntValue:[[[NSUserDefaults standardUserDefaults] objectForKey:@"CustomTotRuns"] intValue]];
		[NSApp runModalForWindow:prefPanel];
	}
}
-(void)removeElement:(id)obj{
	if([[obj className] isEqualToString: @"KMCustomCompartment"]){
		
		
		//find connected parameters first and remove them
		NSMutableArray *connectedParams = [model parametersForCompartment:obj];
		int i=0;
		for(;i<connectedParams.count;i++) 
			[self removeElement:[connectedParams objectAtIndex:i]];
		
		
		[model removeCompartment:obj];
	}
	else if ([[obj className] isEqualToString: @"KMCustomParameter"]){
		[model removeParameter:obj];
	}
	else if ([[obj className] isEqualToString: @"KMCustomInput"]){
		[model removeInput:obj];
	}
	
	else {
		return;
	}
	
	[[stack prepareWithInvocationTarget:self] addElement:obj];
	[view setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Event Handling

-(IBAction)save:(id)sender{
	[self saveModel];
}

-(IBAction)load:(id)sender{
	[self loadModel];
}

-(IBAction)loadData:(id)sender{

	if (!selected) {
		[[KMCustomTissueInterface alloc] initWithModel:model];
	}
	else if([selected objectForKey:@"KMCustomInput"]){
		KMCustomInput *current = [selected objectForKey:@"KMCustomInput"];
		[[KMCustomInputInterface alloc] initWithInput:current];
		
	}
}

-(void)keyDown:(NSEvent *)theEvent
{
	unichar c = [[theEvent characters] characterAtIndex:0];
	
	if(c == 'z' && ([theEvent modifierFlags] & NSCommandKeyMask))
	{
		NSLog(@"UndoQueue:%@", stack);
		if ([theEvent modifierFlags] & NSShiftKeyMask) 
		{
			NSLog(@"Redo!");
			[stack redo];
			[self updateBoxes];
		}
		else {
			NSLog(@"Undo!");
			[stack undo];
			[self updateBoxes];
		}

	}
	else [super keyDown:theEvent];
}

-(void)loadModel{
	
	//initialize and run open panel
 	NSOpenPanel *choosePanel = [NSOpenPanel openPanel];
	NSArray *fileTypes = [NSArray arrayWithObject:@"KMModel"];
	[choosePanel setCanChooseDirectories:YES];
	[choosePanel setAllowsMultipleSelection:NO];
	[choosePanel setCanChooseFiles:YES];
	[choosePanel setAllowedFileTypes:fileTypes];
	[choosePanel setTitle:NSLocalizedString(@"Find Custom Model", nil)];
	[choosePanel setMessage:NSLocalizedString(@"Choose Previously Saved Custom Model", nil)];
	
	if([choosePanel runModal] == NSOKButton)
	{
		// unarchive data
		NSKeyedUnarchiver *unarchiver;
			
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:
					  [NSData dataWithContentsOfFile:choosePanel.filename] ];

		[stack release];
		stack = [[NSUndoManager alloc] init];
		
		self.model = [unarchiver decodeObjectForKey:@"Model"];
		view.model = self.model;
		[unarchiver finishDecoding];
	}
	
	[view setNeedsDisplay:YES];
}

-(void)saveModel {
	
	if(!model) //no model, can't save
	{
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"No Custom Model Currently loaded" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[myAlert runModal];	
		return;
	}
	
	// initialize and run save panel
	NSSavePanel* save= [NSSavePanel savePanel];
	[save setTitle:@"Save Current Custom Model"];
	[save setPrompt:@"Export"];
	[save setCanCreateDirectories:1];
	[save setAllowedFileTypes:[NSMutableArray arrayWithObject:@"KMModel"]];
	
	
	if(![save runModal] == NSOKButton) return;
	
		
	//save data
	NSMutableData *data			= [NSMutableData data];
	NSString *archivePath		= [save filename];
	NSKeyedArchiver *archiver	= [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	
	[archiver encodeObject:model forKey:@"Model"];
	[archiver finishEncoding];
	[data writeToFile:archivePath atomically:YES];
	[archiver release];
	
	[view setNeedsDisplay:YES];
}

-(IBAction)runModel:(id)sender{
	model.conditions = [[KMBasicRunningConditions alloc] init];
	model.conditions.maxIterations =	maxIt.intValue;
	model.conditions.tolerance	 =  minTol.floatValue;
	model.conditions.TotalRuns	 =  totRuns.intValue;
	
	[self closePrefs:self];
	NSLog(@"Great!");
	
	[[KMDataProcessor alloc] initWithModel:model Parameters:nil Inputs:nil andTissue:nil];	
	
}

@end