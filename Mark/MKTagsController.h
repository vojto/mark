//
//  MKTagsController.h
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsArrayController.h"
#import "MKTag.h"
#import "MKTableViewSelectionPersisting.h"
#import "MKTagFormViewController.h"

@interface MKTagsController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

// Controllers
@property (assign) IBOutlet NSTableView *tagsTableView;
@property (assign) IBOutlet MKTagsArrayController *tagsArrayController;
@property (strong) MKTagFormViewController *tagFormViewController;
@property (strong) NSPopover *tagFormPopover;

// Models
@property (assign) BOOL isSetup;
@property (strong) MKTableViewSelectionPersisting *selectionPersisting;
@property (strong) MKTag *selectedTag;

// Views
@property (assign) IBOutlet NSWindow *window;

- (IBAction)deleteTagAction:(id)sender;
- (IBAction)editTagAction:(id)sender;

@end
