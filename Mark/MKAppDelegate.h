//
//  MKAppDelegate.h
//  Mark
//
//  Created by Vojtech Rinik on 22/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MKNewTagViewController.h"
#import "MKTagsArrayController.h"

@interface MKAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSManagedObjectContext *managedContext;

// Siebar
@property (strong) IBOutlet MKTagsArrayController *tagArraycontroller;

// New tag
@property (strong) NSPopover *createTagPopover;
@property (strong) MKNewTagViewController *createTagViewController;

- (IBAction)newTagAction:(id)sender;


@end
