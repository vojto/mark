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
#import "DMSplitView.h"

NSString * const kMKAppDidFinishLaunchingNotification = @"applicationDidFinishLaunching";

@implementation MKAppDelegate

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (void)awakeFromNib {
    // Setup Core Data stack

}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [MagicalRecord setupAutoMigratingCoreDataStack];
    self.managedContext = [NSManagedObjectContext defaultContext];
    self.autoSaveService = [[MKAutoSaveService alloc] initWithContext:self.managedContext];
    self.fileSystemSyncService = [[MKFileSystemSyncService alloc] initWithContext:self.managedContext];
    self.uuidService = [[MKUUIDService alloc] initWithContext:self.managedContext];
    
    [self.fileSystemSyncService restoreFromFileSystem];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kMKAppDidFinishLaunchingNotification object:nil]];

    [self buildDefaultTagsAndNotes];
    
    [self setupFilteringByTag];
    
//    - (void) setPriority:(NSInteger) priorityIndex ofSubviewAtIndex:(NSInteger) subviewIndex;
//
    [self.splitView setPriority:1 ofSubviewAtIndex:0];
    [self.splitView setPriority:2 ofSubviewAtIndex:1];
    [self.splitView setPriority:3 ofSubviewAtIndex:2];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)saveDocument:(id)sender {
    [self.managedContext MR_saveToPersistentStoreAndWait];
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

#pragma mark - Restoring from filesystem

- (void)restoreFromFilesystemAction:(id)sender {
    [self.fileSystemSyncService restoreFromFileSystem];
}

#pragma mark - Changing notes folder

- (void)changeNotesFolderAction:(id)sender {
    if (!self.filesystemSettingsWindowController) {
        self.filesystemSettingsWindowController = [[MKFilesystemSettingsWindowController alloc] initWithWindowNibName:@"MKFilesystemSettingsWindowController"];
    }
    [self.filesystemSettingsWindowController showWindow:self];
}

@end
