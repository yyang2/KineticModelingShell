//
//  KMResults.h
//  KM
//
//  Created by Yang Yang on 9/6/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SM2DGraphView/SM2DGraphView.h>
#import "KMResults.h"


// Main UI For Displaying KMResults

@interface KMResultDisplay : NSWindowController {
	IBOutlet	SM2DGraphView	*singleResult, *histogram;
	IBOutlet	NSTableView		*results;
	IBOutlet	NSNumberFormatter *formatter;
	IBOutlet	NSSlider		*histogramSlider;
	IBOutlet	NSTextField		*binSize;
	IBOutlet	NSPopUpButton	*singleResultDropButton, *histogramDropButton;
	KMResults					*source;
	NSMutableArray				*tableColumns;
	
}

@property (retain) KMResults*	source;
-(id)initWithResults:(KMResults *)passedin;
-(IBAction)SaveResults:(id)sender;
-(BOOL)setTableColumn;
-(IBAction)LoadResults:(id)sender;
-(IBAction)ChangeGraph:(id)sender;
-(double)maxHistogramValue:(NSArray*) points;
-(IBAction)ChangeHistogram:(id)sender;
-(NSArray *)histogramPlots;
@end
