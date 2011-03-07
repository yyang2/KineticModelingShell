//
//  LoadFilterManager.m
//  KM
//
//  Created by Yang Yang on 9/1/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "LoadSingleInputManager.h"	
#import "model.hpp"
#import <SM2DGraphView/SM2DGraphView.h>

@implementation LoadSingleInputManager

#pragma mark -
#pragma mark Init and Dealloc

-(void)awakeFromNib{
	if(UseStdButton.state){
		[TissueStdColumn setEnabled:YES];
	}
	else [TissueStdColumn setEnabled:NO];
}

-(id) initWithModel:(NSString *)model;
{
	return [self initWithModel:model Input:[KMData alloc] andTissue:[KMData alloc]];

}
-(id) initWithModel:(NSString*)model Input:(KMData *)input andTissue:(KMData *)tissue{
	return [self initWithModel:(NSString*)model Input:(KMData *)input andTissue:(KMData *)tissue andParameters:[[[KMModelRunningConditions alloc] autorelease]initParametersForModel:model]];
}

-(id) initWithModel:(NSString*)model Input:(KMData *)input andTissue:(KMData *)tissue andParameters:(KMModelRunningConditions*)params
{
	if(![super init]) return nil;
	
	ModelName = [model retain]; 
	Input = [input retain];
	Tissue = [tissue retain];
	parameters = [params retain];
	[self initWithWindowNibName:@"LoadData"];
	
	//	[[self window] setFrameAutosaveName:@"LoadSingleData"];
	[[self window] makeKeyAndOrderFront:self];
	
	//read default values
	[InputTimeColumn setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMTimeColumn"]];
	[InputDataColumn setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMInputColumn"]];
	[TissueDataColumn setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMTissueColumn"]];
	[TissueStdColumn setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"KMStdColumn"]];
	
	[InputTop selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMInputTop"]];
	[InputBottom selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMInputBottom"]];
	[TissueTop selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMTissueTop"]];
	[TissueBottom selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"KMTissueBottom"]];
	
	
	
	return self;
}
- (void)windowWillClose:(NSNotification *)notification
{
	//return to previous window
	[InputTAC setDataSource:nil];
	[TissueTAC setDataSource:nil];
	[self release];
}


-(void) dealloc{
	//release modelname, input, tissue
	if(modelparamsUI){
		[[modelparamsUI window] close];
		[modelparamsUI release];
	}
	[parameters release];
	[ModelName release];
	[Input release];
	[Tissue release];
	
	[super dealloc];
}
#pragma mark -
#pragma mark Parameters
-(IBAction)OpenPrefPanel:	(id)sender{
	//Open Panel
	if(ModelName == @"FDG"){
		if(modelparamsUI == nil){
			modelparamsUI = [FDGParamUI alloc];
			[modelparamsUI initWithWindowNibName:@"FDGParameters"];
			[modelparamsUI initWithParameter:parameters :self];
			[modelparamsUI window];
		}
		[[modelparamsUI window] makeKeyAndOrderFront:self];
	}
}

-(void) closeParamWindow 
{
	//releasing pointer
	modelparamsUI = nil;
}
#pragma mark -
#pragma mark Buttons

-(IBAction)Finalize:		(id)sender{
	
	//set defaults
	[[NSUserDefaults standardUserDefaults] setInteger:[InputTimeColumn intValue] forKey:@"KMTimeColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[InputDataColumn intValue] forKey:@"KMInputColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[TissueDataColumn intValue] forKey:@"KMTissueColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[TissueStdColumn intValue] forKey:@"KMStdColumn"];

	[[NSUserDefaults standardUserDefaults] setObject:[InputTop.selectedItem title]forKey:@"KMInputTop"];
	[[NSUserDefaults standardUserDefaults] setObject:[InputBottom.selectedItem title]forKey:@"KMInputBottom"];
	[[NSUserDefaults standardUserDefaults] setObject:[TissueTop.selectedItem title]forKey:@"KMTissueTop"];
	[[NSUserDefaults standardUserDefaults] setObject:[TissueBottom.selectedItem title]forKey:@"KMTissueBottom"];
	
	//check for valid files on both
	
	if([[Input allpoints] count] == 0 || [[Tissue allpoints] count] ==0 ){
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"Missing Necessary Files" 
										   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
		[myAlert runModal];
		return;
	}
	

	
	//close window
	
	NSArray *inputs = [NSArray arrayWithObject:Input];

	[[KMDataProcessor alloc] initWithModel:ModelName Parameters:parameters Inputs:inputs andTissue:Tissue];	
	
}
-(IBAction)ChangeTime:		(id)sender{
	
	if ([Input hasFile]) 	[Input setTimePoint:[[sender selectedCell] title]];
	
	if ([Tissue hasFile])	[Tissue setTimePoint:[[sender selectedCell] title]];
	
}


-(IBAction)ChangeUnits:		(id)sender{
	double conversion;

	if(sender == InputTop && SameScaleButton.state == NSOnState){
		if(![self InputIsPET]){
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"Input units cannot be in moles!" 
											   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
			[myAlert runModal];
			return;			
		}
		[TissueTop selectItemWithTitle:[InputTop.selectedItem title]];
	}
	else if(sender == InputBottom && SameScaleButton.state == NSOnState){
		[TissueBottom selectItemWithTitle:[InputBottom.selectedItem title]];
	} 
	
	if([self InputIsPET]){

		//should be (inputtop/inputbottom)/(tissuetop/tissuebottom)
		NSLog(@"%f/%f / %f/%f",[self doubleforselection:InputTop.selectedItem], [self doubleforselection:InputBottom.selectedItem], 
			  [self doubleforselection:TissueTop.selectedItem],	[self doubleforselection:TissueBottom.selectedItem]  );
		conversion = ([self doubleforselection:InputTop.selectedItem]/[self doubleforselection:InputBottom.selectedItem])/
		([self doubleforselection:TissueTop.selectedItem]/[self doubleforselection:TissueBottom.selectedItem]);
	}
	else {
		//if input top has moles, activate specific activity box
		//it should be (inputtop/inputbottom)*(molestop/molesbottom)/(tissuetop/tissuebottom)
		conversion = ([self doubleforselection:InputTop.selectedItem]/[self doubleforselection:InputBottom.selectedItem])*[moleconvert floatValue]*
		([self doubleforselection:MoleConvertTop.selectedItem]/[self doubleforselection:MoleConvertBottom.selectedItem])
		/([self doubleforselection:TissueTop.selectedItem]/[self doubleforselection:TissueBottom.selectedItem]);

	}
	
	if([Tissue hasFile]){
		Tissue.conversion=conversion;
	}
	
}
-(IBAction)ClickSameFile:	(id)sender{
	//check if there is an input file
	//if so, use that for the tissue
	if(SameFileButton.state == NSOnState &&[Input hasFile] ) {
		[self setTissueFile:[Input fileName]];
	}	
}
-(IBAction)ClickSameScale:	(id)sender{

	if(SameScaleButton.state == NSOnState) {
	//make sure the first units are not concentration
		if(![self InputIsPET] ){
			//run modal
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"Input units cannot be in moles!" 
										   defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
			[myAlert runModal];
			[SameScaleButton setState:NSOffState];
			return;
		}
	
		//disable moles convert
		[moleconvert setEnabled:NO];
		[MoleConvertTop setEnabled:NO];
		[MoleConvertBottom setEnabled:NO];	
		//duplicate top and bottom]
	
		[TissueTop selectItemWithTitle:[InputTop.selectedItem title]];
		[TissueBottom selectItemWithTitle:[InputBottom.selectedItem title]];
		//disable tissue top and bottom
		[TissueTop setEnabled:NO];
		[TissueBottom setEnabled:NO];
	}
	else {
		//reenable units button
		[TissueTop setEnabled:YES];
		[TissueBottom setEnabled:YES];
	}
	[self ChangeUnits:nil];
	
}

-(IBAction)SelectInput:		(id)sender{
	//NSOpenPanel
	NSString *source;
	NSOpenPanel *choosePanel = [NSOpenPanel openPanel];
	[choosePanel setCanChooseDirectories:NO];
	[choosePanel setAllowsMultipleSelection:NO];
	[choosePanel setCanChooseFiles:YES];
	[choosePanel setTitle:NSLocalizedString(@"Input File", nil)];
	[choosePanel setMessage:NSLocalizedString(@"Choose the folder with your input file", nil)];

	if([choosePanel runModal] == NSOKButton)
	{	source = [[choosePanel filenames] objectAtIndex:0]; 
	
		if(![Input hasFile]){
			[Input initWithFile:source isInput:YES andTimePoint:[TimeSelection.selectedCell title]  useWeights:NO];
		}
		else [Input loadfile:source withTimePoint:[TimeSelection.selectedCell title]];
		
		[InputTAC refreshDisplay:self];
		
		//check if same file is on
		if([SameFileButton state] == NSOnState){
			[self setTissueFile:source];
		}
	}
}

-(IBAction)UseStd:			(id)sender{

	if(UseStdButton.state){
		[TissueStdColumn setEnabled:YES];
	}
	else [TissueStdColumn setEnabled:NO];
	
	[Tissue setUseWeights:UseStdButton.state];
	if(Tissue.hasFile)
		[Tissue loadfile:Tissue.fileName withTimePoint:[TimeSelection.selectedCell title]];

}

-(IBAction)SelectTissue:	(id)sender{
	NSString *source;
	NSOpenPanel *choosePanel = [NSOpenPanel openPanel];
	[choosePanel setCanChooseDirectories:NO];
	[choosePanel setAllowsMultipleSelection:NO];
	[choosePanel setCanChooseFiles:YES];
	[choosePanel setTitle:NSLocalizedString(@"Input Files", nil)];
	[choosePanel setMessage:NSLocalizedString(@"Choose the folder with your tissue files", nil)];
	
	if([choosePanel runModal] == NSOKButton)
	{	source = [[choosePanel filenames] objectAtIndex:0]; 
		[self setTissueFile:source];
	}
	
	
}



	

-(IBAction)SetColumnRead:	(id)sender{
	//if everything is kosher

	[[NSUserDefaults standardUserDefaults] setInteger:[InputTimeColumn intValue] forKey:@"KMTimeColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[InputDataColumn intValue] forKey:@"KMInputColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[TissueDataColumn intValue] forKey:@"KMTissueColumn"];
	[[NSUserDefaults standardUserDefaults] setInteger:[TissueStdColumn intValue] forKey:@"KMStdColumn"];

}

#pragma mark -
#pragma mark GraphView
- (NSUInteger)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{ 
	return 1;
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(NSUInteger)inLineIndex
{
	if(inGraphView == InputTAC){
		return [Input allpoints];
	}
	else if(inGraphView == TissueTAC){
		return [Tissue allpoints];
	}
	return nil;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis
{
	if(inGraphView == InputTAC){
		if (inAxis == kSM2DGraph_Axis_X) {
			NSPoint something = [Input timerange];
			return something.y;
		}
		else if (inAxis == kSM2DGraph_Axis_Y) {
			NSPoint something = [Input valuerange];
			return something.y;
		}
		
	}
	else if(inGraphView == TissueTAC){
		if (inAxis == kSM2DGraph_Axis_X) {
			NSPoint something = [Tissue timerange];
			return something.y;
		}
		else if (inAxis == kSM2DGraph_Axis_Y) {
			NSPoint something = [Tissue valuerange];
			return something.y;
		}
		
	}
	return 0;
}


- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis;
{
	if(inGraphView == InputTAC){
		if (inAxis == kSM2DGraph_Axis_X) {
			NSPoint something = [Input timerange];
			return something.x;
		}
		else if (inAxis == kSM2DGraph_Axis_Y) {
			NSPoint something = [Input valuerange];	
			return something.x;
		}
	}
	else if(inGraphView == TissueTAC){
		if (inAxis == kSM2DGraph_Axis_X) {
			NSPoint something = [Tissue timerange];
			return something.x;
		}
		else if (inAxis == kSM2DGraph_Axis_Y) {
			NSPoint something = [Tissue valuerange];
			return something.x;
		}
	}
	return 0;
}

#pragma mark -
#pragma mark Utility Functions

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

-(void)setTissueFile:(NSString *)file {
	if(![Tissue hasFile]){
		[Tissue initWithFile:file isInput:NO andTimePoint:[TimeSelection.selectedCell title] useWeights:UseStdButton.state];
	}
	else [Tissue loadfile:file withTimePoint:[TimeSelection.selectedCell title]];
	
	[self ChangeUnits:nil];//set conversion factor
	[TissueTAC refreshDisplay:self];
}
@end
