//
//  MKNotesController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNotesController.h"
#import "MKNote.h"
#import "MKAppDelegate.h"

@implementation MKNotesController

- (id)init {
    if ((self = [super init])) {
        self.isSetup = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunching:) name:kMKAppDidFinishLaunchingNotification object:nil];
    }
    return self;
}

- (void)didFinishLaunching:(NSNotification *)notification {
    NSLog(@"App did finish launching");
    
    // Setup notification for managed object context
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (void)awakeFromNib {
    if (self.isSetup) return;
    
    
    // Setup sorting of notes
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    self.notesArrayController.sortDescriptors = @[sort];
    
    self.notesTable.sortDescriptors = @[sort];
    
    // Setup selection persisting
    self.selectionPersisting = [[MKTableViewSelectionPersisting alloc] initWithKey:@"selectedNote" arrayController:self.notesArrayController];

    
    // Update isSetup flag    
    self.isSetup = YES;

}

#pragma mark - Filtering

- (void)filterNotesByTag:(MKTag *)tag {
    if ((id)tag == [NSNull null]) {
        self.notesArrayController.filterPredicate = nil;
        self.currentTag = nil;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY(tags.name) == %@", tag.name];
        self.notesArrayController.filterPredicate = predicate;
        self.currentTag = tag;
    }
    [self.notesArrayController rearrangeObjects];
}

#pragma mark - Catching changes to notes

- (void)objectsDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSArray *updated = userInfo[NSUpdatedObjectsKey];
//    NSArray *inserted = userInfo[NSInsertedObjectsKey];
    for (NSManagedObject *object in updated) {
        if ([object isKindOfClass:[MKNote class]]) {
            MKNote *note = (MKNote *)object;
            if ([note.changedValues.allKeys containsObject:@"content"] &&
                ![note.changedValues.allKeys containsObject:@"updatedAt"]) {
                note.updatedAt = [NSDate date];
            }
        }
    }
//    [self updateTimestamps:updated];
//    [self updateTimestamps:inserted];
}

- (void)updateTimestamps:(NSArray *)objects {
    for (NSManagedObject *object in objects) {
        if ([object isKindOfClass:[MKNote class]]) {
            [self performSelector:@selector(updateTimestamp:) withObject:object afterDelay:0];
//            [self updateTimestamp:(MKNote *)object];
        }
    }
}

- (void)updateTimestamp:(MKNote *)note {
    NSLog(@"Updating timestamp on: %@", note);
    note.updatedAt = [NSDate date];
}

#pragma mark - Creating notes

- (void)newNoteAction:(id)sender {
    MKNote *note = [MKNote createEntity];
    note.title = @"New note...";
    note.updatedAt = [NSDate date];
    
    if (self.currentTag) {
        [note addTagsObject:self.currentTag];
    }
    
    // Select the newly added note
    [self.notesArrayController insertObject:note atArrangedObjectIndex:0];
    
    [APP_DELEGATE trigger:@"newNote"];
    
}

#pragma mark - Deleting notes

- (void)deleteNoteAction:(id)sender {
    MKNote *note = [[self.notesArrayController selectedObjects] lastObject];
    [note deleteEntity];
}

@end
