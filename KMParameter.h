//
//  KMParameter.h
//  KineticModelingShell
//
//  Created by Yang Yang on 11/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KMParameter : NSObject <NSCoding> {
	NSString	*paramname;
	double		initial, upperbound, lowerbound;
	BOOL		optimize;
}



@property (retain) NSString *paramname;
@property BOOL	optimize;
@property double initial;
@property double lowerbound;
@property double upperbound;


@end
