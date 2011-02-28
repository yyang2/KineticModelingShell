//
//  KMResults.m
//  KM
//
//  Created by Yang Yang on 9/6/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "KMResultDisplay.h"
#import <SM2DGraphView/SM2DGraphView.h>

@implementation KMResultDisplay
#pragma mark -
#pragma mark Init + Dealloc

@synthesize source;

-(void)awakeFromNib
{
	//Before the window loads, set up the interface:
	
	[self setTableColumn];
	[binSize setIntValue:histogramSlider.intValue];
	[histogram refreshDisplay:self];
}

-(BOOL)setTableColumn{
	if(tableColumns){
		//remove all tablecolumns and release
		for (int i = 0; i<tableColumns.count; ++i) 	[results removeTableColumn:[tableColumns objectAtIndex:i]];
		[histogramDropButton removeAllItems];
		[tableColumns release];
	}
	
	tableColumns=[[NSMutableArray array] retain];
	
	NSArray *allkeys = [[[source entryForIndex:0] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	for(int i=0;i<[allkeys count];++i){
		
		//Find every parameter in results (this excludes YValues and XValues) and add a column to our display table for them.
		
		if(![[allkeys objectAtIndex:i] isEqualToString:@"YValues"] && ![[allkeys objectAtIndex:i] isEqualToString:@"XValues"]){
			
			NSTableColumn *column = [[[NSTableColumn alloc] autorelease] initWithIdentifier:[allkeys objectAtIndex:i]];
			
			[[column headerCell] setTitle:[allkeys objectAtIndex:i]];
			[column setEditable:NO];
			[tableColumns addObject:column];
			[histogramDropButton addItemWithTitle:[allkeys objectAtIndex:i]];
			[results addTableColumn:column];
		}
	}
	return YES;
	
}
-(id)initWithResults:(KMResults *)passedin
{
	self = [super init];
	source = passedin;
	[self initWithWindowNibName:@"DisplayResults"];
	[self window];
	[[self window] makeKeyAndOrderFront:self];
	return self;
}

-(void)windowWillClose:(NSNotification *)notification{
	
	[singleResult setDataSource:nil];
	[histogram setDataSource:nil];
	[results	setDataSource:nil];
	[self dealloc];
}

-(void) dealloc{
	
	NSLog(@"Results Display Window Dealloc");

	source = nil;
	[super dealloc];
	
}
#pragma mark -
#pragma mark Histograms

-(IBAction)ChangeHistogram:(id)sender{
	//updates bin size for the histograms when the slider value changes
	if(sender == histogramSlider) {
		[binSize setIntValue:histogramSlider.intValue];
	}
	[histogram refreshDisplay:self];
}


-(NSArray *)histogramPlots{
	
	NSString *plotParameter;
	
	//which Parameter are we displaying the histogram for? Defaults to WRSS
	if(![histogramDropButton selectedItem]) plotParameter = @"WRSS";
	else plotParameter = [histogramDropButton.selectedItem title];
	

	//Grab already ordered values for that parameter, determine min and max
	NSArray *allpoints = [source orderedArrayFor:plotParameter];	
	double rangemin = [[allpoints objectAtIndex:0] doubleValue]; double rangemax = [[allpoints lastObject] doubleValue];
	int bins = [histogramSlider intValue];
	double stepsize = (rangemax-rangemin)/(double)bins;
	NSMutableArray *returnvalues = [NSMutableArray arrayWithCapacity:bins];
	
	
	//fill each bin of the histogram
	int runningcount=0;
	for(int i=0; i<bins;++i){
		int numberofcounts=0;
		for(int k=runningcount; k<allpoints.count; ++k){
			if (rangemin+stepsize*i >= [[allpoints objectAtIndex:k] doubleValue]) { ++runningcount; ++numberofcounts;}
			else break;
		}
		NSPoint currentpoint = NSMakePoint((double)i, (double)numberofcounts);
		[returnvalues addObject:NSStringFromPoint(currentpoint)];
	}
	return returnvalues;
}

-(double)maxHistogramValue:(NSArray*) points{
	//takes in all the points on the plot, finds maximum y value.
	//needed for SM2DGraphView
	
	NSPoint	firstpoint = NSPointFromString([points objectAtIndex:0]);
	double max=firstpoint.y;
	for (int i=0; i<points.count; ++i) {
		NSPoint	temp = NSPointFromString([points objectAtIndex:i]);
		if(temp.y>max) max=temp.y;
	}
	return max+0.5f;
}

#pragma mark -
#pragma mark GraphView

-(IBAction)ChangeGraph:(id)sender{
	[singleResult refreshDisplay:self];
}

- (NSUInteger)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{
	if(inGraphView == singleResult){
		return 1;
	}
	else if(inGraphView == histogram)
	{
		return 1;
	}
	return 0;
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(NSUInteger)inLineIndex{
	if(inGraphView == histogram){
		return [NSDictionary dictionaryWithObjectsAndKeys: [ NSNumber numberWithBool:YES ], @"SM2DGraphBarStyleAttributeName",
				nil];
		}
	else if (inGraphView == singleResult) {
		return[ NSDictionary dictionaryWithObjectsAndKeys:
				  [ NSNumber numberWithInt:kSM2DGraph_Symbol_Diamond ], @"SM2DGraphLineSymbolAttributeName",
				  [ NSColor redColor ], NSForegroundColorAttributeName,
				  [ NSNumber numberWithInt:kSM2DGraph_Width_None ], @"SM2DGraphLineWidthAttributeName",
				  nil ];
		
	}
	return nil;
}
- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(NSUInteger)inLineIndex
{
	if(inGraphView == singleResult){
		NSArray *xvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"XValues"];
		NSArray *yvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"YValues"];
		NSMutableArray *values = [NSMutableArray array];
		for(int i=0;i<xvalues.count;++i){
			NSPoint currentpoint = NSMakePoint([[xvalues objectAtIndex:i] doubleValue], [[yvalues objectAtIndex:i] doubleValue]);
			[values addObject:NSStringFromPoint(currentpoint)];
		}
		return values;
	}
	else if(inGraphView == histogram){
		return [self histogramPlots];
	}
	
	return nil;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis
{
	if(inGraphView == singleResult){
		if(inAxis == kSM2DGraph_Axis_X){
			NSArray *xvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"XValues"];
			return [[xvalues lastObject] doubleValue]+.5;
		}
		else if(inAxis == kSM2DGraph_Axis_Y){
			
			NSArray *yvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"YValues"];
			double max = [[[yvalues sortedArrayUsingSelector:@selector(compare:)] lastObject] doubleValue];
			return max;
		}
		
	}
	else if(inGraphView == histogram){
		if(inAxis == kSM2DGraph_Axis_X){
			return [histogramSlider doubleValue];
		}
		else if(inAxis == kSM2DGraph_Axis_Y){
			return [self maxHistogramValue:[self histogramPlots]];
		}
	}
	return 0;
}

//labels for each tick mark
- (NSString *)twoDGraphView:(SM2DGraphView *)inGraphView labelForTickMarkIndex:(NSUInteger)inTickMarkIndex
					forAxis:(SM2DGraphAxisEnum)inAxis defaultLabel:(NSString *)inDefault
{
    NSString	*result = inDefault;
	
    if ( inGraphView == histogram && inAxis == kSM2DGraph_Axis_X )
    {
		NSString *plotParameter;
		if(![histogramDropButton selectedItem]) plotParameter = @"WRSS";
		else plotParameter = [histogramDropButton.selectedItem title];
		NSArray *allpoints = [source orderedArrayFor:plotParameter];
		
		double rangemin = [[allpoints objectAtIndex:0] doubleValue]; double rangemax = [[allpoints lastObject] doubleValue];
		int bins = [histogramSlider intValue];
		double stepsize = (rangemax-rangemin)/(double)bins;
		
		NSString *displayString = [NSString stringWithFormat:@"%2.4f",rangemin+stepsize*(double)inTickMarkIndex];
		result = NSLocalizedString( displayString, @"User visible graph label" );
    }
	
    return result;
}

- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(NSUInteger)inBarIndex forLineIndex:(NSUInteger)inLineIndex withAttributes:(NSMutableDictionary *)attr
{
    if ( inGraphView == histogram )
    {
        if ((inBarIndex % 4)==0 )

            [ attr setObject:[ NSColor blueColor ] forKey:NSForegroundColorAttributeName ];
        else if ((inBarIndex % 4)==1 )

            [ attr setObject:[ NSColor yellowColor ] forKey:NSForegroundColorAttributeName ];
		else if ((inBarIndex % 4)==2 )

            [ attr setObject:[ NSColor redColor ] forKey:NSForegroundColorAttributeName ];
        
		else if ((inBarIndex % 4)==3 )

            [ attr setObject:[ NSColor greenColor ] forKey:NSForegroundColorAttributeName ];
    }
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(NSUInteger)inLineIndex
				forAxis:(SM2DGraphAxisEnum)inAxis;
{
	if(inGraphView == singleResult){
		if(inAxis == kSM2DGraph_Axis_X){
			NSArray *xvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"XValues"];
			return [[xvalues objectAtIndex:0] doubleValue];}

		else if(inAxis == kSM2DGraph_Axis_Y){
			NSArray *yvalues = [[source entryForIndex:results.selectedRow] objectForKey:@"YValues"];
			double min = [[[yvalues sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0] doubleValue];
			return min;
		}
	}
	else if(inGraphView == histogram){
		if (inAxis == kSM2DGraph_Axis_Y) {
			return -0.5;
		}
		else return -0.5;
	}	
	return 0;
}


#pragma mark -
#pragma mark TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return source.totalCount;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [formatter stringFromNumber:[[source entryForIndex:rowIndex] objectForKey:[aTableColumn identifier]]];
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[singleResult refreshDisplay:self];
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
	[source orderListBy:[tableColumn.headerCell title]];
	[tableView reloadData];
}

#pragma mark -
#pragma mark Save and Load

-(IBAction)SaveResults:(id)sender{
	
}

-(IBAction)LoadResults:(id)sender{
	
}
@end
