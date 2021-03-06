//
//  CustomModelInputInterface.m
//  KMShell
//
//  Created by Yang Yang on 9/19/10.
//  Copyright 2010  . All rights reserved.
//

#import "KMCustomInputInterface.h"
#import "KMCustomInput.h"
#import "KMData.h"
#import	<SM2DGraphView/SM2DGraphView.h>

@implementation KMCustomInputInterface
@synthesize currentdata;
@synthesize input;

-(void)awakeFromNib
{
	[InputTop selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMInputTop"]];
	[InputBottom selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMInputBottom"]];
	[InputColumnBox setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMInputColumn"]];
	[TimeColumnBox setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMTimeColumn"]];

}


-(id)initWithInput:(KMCustomInput*)k
{
	self = [super init];
	if(!self) return nil;
	
	self.input = k;
	
	if(input.inputData){
		self.currentdata = input.inputData;
	}
	else{
		currentdata = [KMData alloc];
		currentdata.inputfile = TRUE;
		currentdata.useWeights = FALSE;
	}
	[self initWithWindowNibName:@"CustomModelLoadInput"];
	[self window];
	[[self window] makeKeyAndOrderFront:self];
	[Graph refreshDisplay:self];
	return self;
}

-(void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"LoadInput Window Close");
	self.release;
}

-(void) dealloc{
	NSLog(@"LoadInput dealloc");
	self.input = nil;
	currentdata.release;
	[super dealloc];
}

-(IBAction)LoadFile:(id)sender{
	
//	[[NSUserDefaults standardUserDefaults] setInteger: [InputColumnBox intValue] forKey:@"KMInputColumn"];
//	[[NSUserDefaults standardUserDefaults] setInteger:[TimeColumnBox intValue] forKey:@"KMTimeColumn"];
	
	NSOpenPanel *choosePanel = [NSOpenPanel openPanel];
	[choosePanel setCanChooseDirectories:NO];
	[choosePanel setAllowsMultipleSelection:NO];
	[choosePanel setCanChooseFiles:YES];
	[choosePanel setTitle:NSLocalizedString(@"Input File", nil)];
	[choosePanel setMessage:NSLocalizedString(@"Choose Saved Input File Data", nil)];
	
	if([choosePanel runModal] == NSOKButton)
	{
		currentdata.location = choosePanel.filename;
		[currentdata loadfile:choosePanel.filename withTimePoint:[TimeSelection.selectedCell title]:InputColumnBox.intValue:TimeColumnBox.intValue:-1:NO];
	}

	[Graph refreshDisplay:self];
}

-(IBAction)Okay:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger: [InputColumnBox intValue] forKey:@"KMInputColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[TimeColumnBox intValue] forKey:@"KMTimeColumn"];
	
	NSLog(@"Current Data:%@", currentdata);
	if([currentdata hasFile]){
		input.inputData =currentdata;
		[[self window] close];
	}

}


-(IBAction)ChangeUnits:		(id)sender{
	
	float conversion;
	if([self InputIsPET]){
		[SpecificActivityBottom setEnabled:NO];
		[SpecificActivityTop	setEnabled:NO];
		conversion = ([self doubleforselection:InputTop.selectedItem]/[self doubleforselection:InputBottom.selectedItem]);
	}
	else {
		[SpecificActivityBottom setEnabled:YES];
		[SpecificActivityTop	setEnabled:YES];
		
		conversion = ([self doubleforselection:InputTop.selectedItem]/[self doubleforselection:InputBottom.selectedItem])*[SpecificActivityBox floatValue]*
		([self doubleforselection:SpecificActivityTop.selectedItem]/[self doubleforselection:SpecificActivityBottom.selectedItem]);
	}
	
	if([currentdata hasFile] && [SpecificActivityBox floatValue] != 0.f) currentdata.conversion=conversion;

	[Graph refreshDisplay:self];
}

-(double)doubleforselection:(NSMenuItem *)item{
	NSString *name = [item title];
	NSLog(@"Name of selected:%@", name);
	
	if([name isEqualToString:@"Bq"]){
		return 1.f;
	}
	else if([name isEqualToString:@"KBq"]) {
		return 1000.f;
	}
	else if([name isEqualToString:@"MBq"]) {
		return 1000000.f;
	}
	else if([name isEqualToString:@"Ci"]) {
		return 37000000000.f;
	}
	else if([name isEqualToString:@"mCi"]) {
		return 37000000.f;
	}
	else if([name isEqualToString:@"uCi"]) {
		return 37000.f;
	}
	else if([name isEqualToString:@"nCi"]) {
		return 37.f;
	}
	else if([name isEqualToString:@"Moles"]) {
		return 1.f;
	}
	else if([name isEqualToString:@"mMoles"]) {
		return 1.f/1000.f;
	}
	else if([name isEqualToString:@"uMoles"]) {
		return 1.f/1000000.f;
	}
	else if([name isEqualToString:@"nMoles"]) {
		return 1.f/1000000000.f;
	}
	else if([name isEqualToString:@"pMoles"]) {
		return 1.f/1000000000000.f;
	}
	else if([name isEqualToString:@"l"]) {
		return 1.f;
	}
	else if([name isEqualToString:@"ml"]) {
		return 1.f/1000.f;
	}
	else if([name isEqualToString:@"ul"]) {
		return 1.f/1000000.f;
	}
	
	return 1.f;
}

-(BOOL)InputIsPET {
	NSString *name =  [[InputTop selectedItem] title];
	if([name hasSuffix:@"Bq"] || [name hasSuffix:@"Ci"])	return YES;
	else return NO;
}

#pragma mark -
#pragma mark GraphView
- (NSUInteger)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{ 
	return 1;
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(NSUInteger)inLineIndex
{
	if([currentdata hasFile])
		return [currentdata allpoints];
	
	else return nil;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis
{
	
	if(![currentdata hasFile]) return 0;
	
	if (inAxis == kSM2DGraph_Axis_X) {
		NSPoint something = [currentdata timerange];
		NSLog(@"Max:%f", something.y);
		return something.y;
	}
	else if (inAxis == kSM2DGraph_Axis_Y) {
		NSPoint something = [currentdata valuerange];
		return something.y;
		NSLog(@"Max:%f", something.y);
	}
	
	return 0;
}


- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis;
{
	if(![currentdata hasFile]) return 0;
	if (inAxis == kSM2DGraph_Axis_X) {
		NSPoint something = [currentdata timerange];
		return something.x;
		NSLog(@"Min:%f", something.x);
	}
	else if (inAxis == kSM2DGraph_Axis_Y) {
		NSPoint something = [currentdata valuerange];
		return something.x;
		
		NSLog(@"Min:%f", something.x);
	}
	return 0;
}


@end