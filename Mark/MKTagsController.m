//
//  MKTagsController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsController.h"
#import "MKTag.h"

@implementation MKTagsController

- (id)init {
    if ((self = [super init])) {
        NSLog(@"initializing tags controller");
    }
    return self;
}

- (void)awakeFromNib {
    [self.tagsArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]) {
        // Get the selected tag from array controller
        MKTag *selectedTag = [[self.tagsArrayController selectedObjects] lastObject];
        if (!selectedTag) {
            selectedTag = (id)[NSNull null];
        }
        [self trigger:@"selectTag" data:selectedTag];
    }
}

/*
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    [self didChangeSelection];
}
 */


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    return YES;
}

/*

- (void)didChangeSelection {
    NSIndexSet *selection = [self.tagsTableView selectedRowIndexes];
    NSInteger index = [selection firstIndex];
    
    id selectedObject = [self.tagsArrayController arrangedObjects][index];

    MKTag *selectedTag;
    
    if ([selectedObject isKindOfClass:[MKTag class]]) {
        selectedTag = (MKTag *)selectedObject;
    } else {
        selectedTag = (id)[NSNull null];
    }
    
    [self trigger:@"selectTag" data:selectedTag];
}
 
 */


@end
