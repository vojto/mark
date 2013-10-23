//
//  MKAppDelegate.m
//  Mark
//
//  Created by Vojtech Rinik on 22/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKAppDelegate.h"
#import "MKTag.h"
#import "MKNote.h"

@implementation MKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [MagicalRecord setupAutoMigratingCoreDataStack];
    
    self.managedContext = [NSManagedObjectContext defaultContext];
    
    [self buildDefaultTagsAndNotes];
    
    [self setupFilteringByTag];
}

#pragma mark - Building default tags

- (void)buildDefaultTagsAndNotes {
    if ([MKTag countOfEntities] == 0 && [MKNote countOfEntities] == 0) {
        MKTag *tag = [MKTag createEntity];
        tag.name = @"work";
        
        MKNote *note = [MKNote createEntity];
        note.title = @"journal - 23.10.2013";
        note.content = @"working on Mark today";
        note.tags = [NSSet setWithObjects:tag, nil];
        
        [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
    }
}

#pragma mark - Filtering by tag

- (void)setupFilteringByTag {
    [self.tagsController on:@"selectTag" block:^(id data) {
        MKTag *tag = (MKTag *)data;
        [self.notesController filterNotesByTag:tag];
    }];
}

#pragma mark - Adding tags

- (IBAction)newTagAction:(id)sender {
    // Ensure we have the controller
    if (!self.createTagViewController) {
        self.createTagViewController = [[MKNewTagViewController alloc] initWithNibName:@"MKNewTagViewController" bundle:nil];
        self.createTagViewController.context = self.managedContext;
    }
    if (!self.createTagPopover) {
        self.createTagPopover = [[NSPopover alloc] init];
        self.createTagPopover.contentViewController = self.createTagViewController;
        self.createTagPopover.behavior = NSPopoverBehaviorTransient;
        self.createTagViewController.popover = self.createTagPopover;
    }
    
    if ([self.createTagPopover isShown]) {
        return;
    }
    
    NSView *view = self.window.contentView;
    [self.createTagPopover showRelativeToRect:view.frame ofView:self.window.contentView preferredEdge:NSMaxYEdge];
    
    NSLog(@"Showing: %@", self.createTagPopover);
}


@end
