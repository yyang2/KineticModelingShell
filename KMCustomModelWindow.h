//
//  KMCostumModelWindow.h
//  KineticModelingShell
//
//  Created by Yang Yang on 9/20/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class KMCustomModelView;
@class KMCustomModel;
@class KMCustomCompartment;
@class KMCustomInput;
// Main Interface controller responsible for loading, saving, and running
// any user made model.
// Displays statistics on currently selected elements, allows users to change names
// posesses NSUndoMananger, allowing actions to be undone.

@interface KMCustomModelWindow : NSWindowController 
{
	IBOutlet KMCustomModelView	*view;
	IBOutlet NSTextField	*box1, *box2, *box3, *box4;
	IBOutlet NSTextField	*des1, *des2, *des3, *des4;
	IBOutlet NSTextField	*maxIt, *minTol, *totRuns;
	IBOutlet NSButton		*check1, *loadData;
	IBOutlet NSPanel		*prefPanel;
	IBOutlet NSNumberFormatter *floatformatter;

	KMCustomModel		*model;
	NSDictionary		*selected;
	NSUndoManager		*stack;
}

@property (retain) NSDictionary *selected;

@property (retain) KMCustomModel *model;

-(void)loadModel;
-(void)changeSelected:(NSDictionary*)d;
-(void)addElement:(id)obj;
-(void)updateBoxes;
-(void)updateBoxesComp;
-(void)updateBoxesParam;
-(void)updateBoxesInput;
-(void)resetBoxes;
-(void)changeInput:(NSDictionary*)d;
-(void)changeParameter:(NSDictionary*)d;
-(void)changeCompartment:(NSDictionary*)d;
-(void)removeElement:(id)obj;
-(IBAction)propertyChange:(id)sender;
-(IBAction)savePrefs:(id)sender;
-(IBAction)showPrefs:(id)sender;
-(IBAction)save:(id)sender;
-(IBAction)load:(id)sender;
-(IBAction)loadData:(id)sender;
-(IBAction)runModel:(id)sender;
-(void)saveModel;
@end
