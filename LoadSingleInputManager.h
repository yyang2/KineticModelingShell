//
//  LoadFilterManager.h
//  KM
//
//  Created by Yang Yang on 9/1/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <SM2DGraphView/SM2DGraphView.h>
#import "KMData.h"
#import "FDGParamUI.h"
#import "KMDataProcessor.h"
#import "KMModelRunningConditions.h"
#import "KMCustomModelWindow.h"

// UI for loading KMData in models with a single input


@interface LoadSingleInputManager : NSWindowController {
	id						modelparamsUI;
	KMModelRunningConditions			*parameters;
	NSString				*ModelName;
	IBOutlet SM2DGraphView	*InputTAC, *TissueTAC;
	IBOutlet NSTextField	*moleconvert, *InputTimeColumn, *InputDataColumn, *TissueDataColumn, *TissueStdColumn;
	IBOutlet NSMatrix		*TimeSelection;
	IBOutlet NSButton		*InputFileButton, *TissueFileButton, *SameScaleButton, *SameFileButton, *UseStdButton;
	IBOutlet NSPopUpButton	*InputTop, *InputBottom, *TissueTop, *TissueBottom, *MoleConvertTop, *MoleConvertBottom;
	KMData		*Input, *Tissue;
}

-(id) initWithModel:(NSString *)model;
-(id) initWithModel:(NSString*)model Input:(KMData *)input andTissue:(KMData *)tissue;
-(id) initWithModel:(NSString*)model Input:(KMData *)input andTissue:(KMData *)tissue andParameters:(KMModelRunningConditions *)params;
-(double)doubleforselection:(NSMenuItem *)item;
-(BOOL)InputIsPET;
-(void)setTissueFile:(NSString *)file;
-(IBAction)Finalize:		(id)sender;
-(void) closeParamWindow;
-(IBAction)ChangeTime:		(id)sender;
-(IBAction)UseStd:			(id)sender;
-(IBAction)ChangeUnits:		(id)sender;
-(IBAction)ClickSameFile:	(id)sender;
-(IBAction)ClickSameScale:	(id)sender;
-(IBAction)SelectInput:		(id)sender;
-(IBAction)SelectTissue:	(id)sender;
-(IBAction)OpenPrefPanel:	(id)sender;
-(IBAction)SetColumnRead:	(id)sender;
@end