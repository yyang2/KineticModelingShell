//
//  CustomModelInputInterface.h
//  KMShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMData.h"
#import	<SM2DGraphView/SM2DGraphView.h>
@class KMCustomInput;
@class KMData;
// UI for loading an input for a KMCustomModel
@interface KMCustomInputInterface : NSWindowController {
	KMCustomInput				*input;
	KMData						*currentdata;
	
	IBOutlet	SM2DGraphView	*Graph;
	IBOutlet	NSTextField		*SpecificActivityBox, *InputColumnBox, *TimeColumnBox;
	IBOutlet	NSPopUpButton	*InputTop, *InputBottom, *SpecificActivityTop, *SpecificActivityBottom;
	IBOutlet	NSMatrix		*TimeSelection;
}

@property (retain) KMData *currentdata;
@property (retain) KMCustomInput *input;

-(IBAction)ChangeUnits:(id)sender;
-(IBAction)Okay:(id)sender;
-(IBAction)LoadFile:(id)sender;
-(id)initWithInput:(KMCustomInput*)k;
-(double)doubleforselection:(NSMenuItem *)item;
-(BOOL)InputIsPET;

@end
