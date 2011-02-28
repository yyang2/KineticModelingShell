//  KMShellAppDelegate.m
//  KMShell
//
//  Created by Yang Yang on 9/8/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "KMShellAppDelegate.h"
#import "LoadSingleInputManager.h"
#import "KMData.h"
#import "KMCustomCompartment.h"
#import "KMCustomModel.h"

@implementation KMShellAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"This is init");

	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"KMTimeColumn"]) {
		//these are not indexes, but column numbers, inside the program they are converted into indexes
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"KMTimeColumn"];
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"KMInputColumn"];
		[[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"KMTissueColumn"];
		[[NSUserDefaults standardUserDefaults] setInteger:4 forKey:@"KMStdColumn"];
		[[NSUserDefaults standardUserDefaults] setObject:@"Bq" forKey:@"KMInputTop"];
		[[NSUserDefaults standardUserDefaults] setObject:@"ml" forKey:@"KMInputBottom"];
		[[NSUserDefaults standardUserDefaults] setObject:@"Bq" forKey:@"KMTissueTop"];
		[[NSUserDefaults standardUserDefaults] setObject:@"ml" forKey:@"KMTissueBottom"];
	}
//	[[LoadSingleInputManager alloc] initWithModel:@"FDG" Input:[[KMData alloc] autorelease] andTissue:[[KMData alloc]autorelease]];
	id dam = [KMCustomModelWindow alloc];
	
		
	
	KMCustomModel *model = [[KMCustomModel alloc] initWithModelName:@"TestModel"];
	id compartment = [[KMCustomCompartment alloc] initWithName:@"Test" type:@"Something"];
	
	[model addCompartment:compartment];
	
	[dam initWithModel:model];

	
	
	
	
	
	//
//	NSLog(@"Model Before Saving:%@", model);
//	
	NSMutableData *data;
//	
//	NSString *archivePath = @"/Users/yangyang/Documents/ModelSave.test";
//	
//	NSKeyedArchiver *archiver;
//	
//	data = [NSMutableData data];
//	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//	
//	[archiver encodeObject:model forKey:@"First"];
//	
//	[archiver finishEncoding];
//	
//	[data writeToFile:archivePath atomically:YES];
//	
//	[archiver release];
//	
//	NSLog(@"Finished Writing");
//	
//	KMCustomModel *newmodel;
//	
//	NSData *loaded;
//	NSKeyedUnarchiver *unarchiver;
//	
//	loaded = [NSData dataWithContentsOfFile:archivePath];
//	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:loaded];
//	
//	newmodel = [unarchiver decodeObjectForKey:@"First"];
//	
//	[unarchiver finishDecoding];
//	NSLog(@"NEWModel:%@", newmodel);
}

@end