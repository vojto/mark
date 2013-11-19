//
//  MKNotesController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNotesController.h"
#import "MKNote.h"

@implementation MKNotesController

- (id)init {
    if ((self = [super init])) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        NSLog(@"context: %@", context);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"Array controller: %@", self.notesArrayController);
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    self.notesArrayController.sortDescriptors = @[sort];
}

- (void)filterNotesByTag:(MKTag *)tag {
    if ((id)tag == [NSNull null]) {
        self.notesArrayController.filterPredicate = nil;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY(tags.name) == %@", tag.name];
        NSLog(@"Predicate: %@", predicate);
        self.notesArrayController.filterPredicate = predicate;
    }
}

#pragma mark - Catching changes to notes

- (void)objectsDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSArray *updated = userInfo[NSUpdatedObjectsKey];
    NSArray *inserted = userInfo[NSInsertedObjectsKey];
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
    
    // Select the newly added note
    [self performBlock:^(id sender) {
            [self.notesArrayController setSelectionIndex:0];
    } afterDelay:0.1];

}

@end
