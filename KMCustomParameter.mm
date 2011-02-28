//
//  KMCustomParameter.mm
//  KineticModelingShell
//
//  Created by Yang Yang on 11/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "KMCustomParameter.h"
#import "KMCustomCompartment.h"

@implementation KMCustomParameter

@synthesize originpt,destinpt;
@synthesize origin_comp, destin_comp;
@synthesize isSelected;

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super init]; if(!self) return nil;
	self.origin_comp = [aDecoder decodeObjectForKey:@"OriginComp"];
	self.destin_comp = [aDecoder decodeObjectForKey:@"DestinComp"];
	self.originpt =	NSPointFromString([aDecoder decodeObjectForKey:@"OriginPt"]);
	self.destinpt = NSPointFromString([aDecoder decodeObjectForKey:@"DestinPt"]);
	
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:origin_comp forKey:@"OriginComp"];
	[aCoder encodeObject:destin_comp forKey:@"DestinComp"];
	[aCoder encodeObject:NSStringFromPoint(originpt) forKey:@"OriginPt"];
	[aCoder encodeObject:NSStringFromPoint(destinpt) forKey:@"DestinPt"];
	
}
-(id)initAtComp:(KMCustomCompartment*)org pt:(NSPoint)orgpt endAtComp:(KMCustomCompartment*)end pt:(NSPoint)endpt{
	
	self = [super init];
	
	if(!self) return nil;
	
	self.origin_comp = org; originpt = orgpt;
	self.destin_comp = end; destinpt = endpt;
	
	self.paramname = [NSString stringWithFormat:@"%@-%@", origin_comp.compartmentname, destin_comp.compartmentname];

	return self;
}

-(NSBezierPath*)directPath{
	
	NSBezierPath* aPath = [NSBezierPath bezierPath];
	NSPoint	start,end;
	
	start		= NSMakePoint(origin_comp.rect.origin.x+originpt.x*origin_comp.rect.size.width, 
								  origin_comp.rect.origin.y+originpt.y*origin_comp.rect.size.height);
	
	end	= NSMakePoint(destin_comp.rect.origin.x+destinpt.x*destin_comp.rect.size.width, 
								  destin_comp.rect.origin.y+destinpt.y*destin_comp.rect.size.height);
	[aPath moveToPoint:start];
	[aPath lineToPoint:end];
	return aPath;
}

-(NSBezierPath*)contour{

	NSBezierPath* aPath = [NSBezierPath bezierPath];
	
	NSPoint originfirst, originsecond, destinfirst, destinsecond;
	if(originpt.x == 1 || originpt.x == 0){
		originfirst		= NSMakePoint(origin_comp.rect.origin.x+originpt.x*origin_comp.rect.size.width, 
									  origin_comp.rect.origin.y+originpt.y*origin_comp.rect.size.height-3);
		originsecond	= NSMakePoint(origin_comp.rect.origin.x+originpt.x*origin_comp.rect.size.width, 
									  origin_comp.rect.origin.y+originpt.y*origin_comp.rect.size.height+3);
	}
	else {
		originfirst		= NSMakePoint(origin_comp.rect.origin.x+originpt.x*origin_comp.rect.size.width-3, 
									  origin_comp.rect.origin.y+originpt.y*origin_comp.rect.size.height);
		originsecond	= NSMakePoint(origin_comp.rect.origin.x+originpt.x*origin_comp.rect.size.width+3, 
									  origin_comp.rect.origin.y+originpt.y*origin_comp.rect.size.height);

	}

	if(destinpt.x == 1 || destinpt.x == 0){
		destinfirst		= NSMakePoint(destin_comp.rect.origin.x+destinpt.x*destin_comp.rect.size.width, 
									  destin_comp.rect.origin.y+destinpt.y*destin_comp.rect.size.height-3);
		destinsecond	= NSMakePoint(destin_comp.rect.origin.x+destinpt.x*destin_comp.rect.size.width, 
									  destin_comp.rect.origin.y+destinpt.y*destin_comp.rect.size.height+3);
	}
	else {
		destinfirst		= NSMakePoint(destin_comp.rect.origin.x+destinpt.x*destin_comp.rect.size.width-3, 
									  destin_comp.rect.origin.y+destinpt.y*destin_comp.rect.size.height);
		destinsecond	= NSMakePoint(destin_comp.rect.origin.x+destinpt.x*destin_comp.rect.size.width+3, 
									  destin_comp.rect.origin.y+destinpt.y*destin_comp.rect.size.height);
	}
	
	[aPath moveToPoint:originfirst];
	[aPath lineToPoint:originsecond];
	[aPath lineToPoint:destinsecond];
	[aPath lineToPoint:destinfirst];
	[aPath closePath];
	[aPath setLineWidth:1.0];
	
	return aPath;
	
}
@end
