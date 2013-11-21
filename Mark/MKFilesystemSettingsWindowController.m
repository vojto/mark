//
//  MKFilesystemSettingsWindowController.m
//  Mark
//
//  Created by Vojtech Rinik on 11/21/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKFilesystemSettingsWindowController.h"

@interface MKFilesystemSettingsWindowController ()

@end

@implementation MKFilesystemSettingsWindowController

- (IBAction)choosePathAction:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose Path"];
	[openPanel setDelegate:self];
	[openPanel runModal];
}

- (void)panel:(id)sender didChangeToDirectoryURL:(NSURL *)url {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *path = [url path];
	[defaults setObject:path forKey:kMKFileSystemPathDefaultsKey];
}

@end
