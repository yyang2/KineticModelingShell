//
//  KMCustomTissueInterface.h
//  KMShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KMData.h"
#import	<SM2DGraphView/SM2DGraphView.h>
@class KMCustomModel;
@class KMData;
// UI for loading an input for a KMCustomModel
@interface KMCustomTissueInterface : NSWindowController {
	KMCustomModel				*model;
	KMData						*currentdata;
	IBOutlet	SM2DGraphView	*Graph;
	IBOutlet	NSTextField		*InputColumnBox, *TimeColumnBox;
	IBOutlet	NSPopUpButton	*TissueTop, *TissueBottom;
	IBOutlet	NSMatrix		*TimeSelection;
}

@property (retain) KMData *currentdata;
@property (retain) KMCustomModel *currentmodel;

-(IBAction)ChangeUnits:(id)sender;
-(IBAction)Okay:(id)sender;
-(IBAction)LoadFile:(id)sender;
-(id)initWithModel:(KMCustomModel*)m;
-(double)doubleforselection:(NSMenuItem *)item;

@end
