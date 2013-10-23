//
//  MKNotesController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNotesController.h"

@implementation MKNotesController

- (void)awakeFromNib {
    NSLog(@"Array controller: %@", self.notesArrayController);
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

@end
