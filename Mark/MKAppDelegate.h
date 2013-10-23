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
#import "MKNotesController.h"
#import "MKTagsController.h"
#import "DMSplitView.h"

@interface MKAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSManagedObjectContext *managedContext;

@property (assign) IBOutlet DMSplitView *splitView;


// New tag
@property (strong) NSPopover *createTagPopover;
@property (strong) MKNewTagViewController *createTagViewController;

// Tags
@property (strong) IBOutlet MKTagsController *tagsController;
@property (strong) IBOutlet MKTagsArrayController *tagArraycontroller;

// Notes
@property (strong) IBOutlet MKNotesController *notesController;

- (IBAction)newTagAction:(id)sender;


@end
