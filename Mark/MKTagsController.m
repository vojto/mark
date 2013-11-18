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
    NSLog(@"Here's the tag table view: %@", self.tagsTableView);
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    [self didChangeSelection];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    return YES;
}


- (void)didChangeSelection {
    NSIndexSet *selection = [self.tagsTableView selectedRowIndexes];
    NSInteger index = [selection firstIndex];
    
    id selectedObject = [self.tagsArrayController arrangedObjects][index];
    
    if (![selectedObject isKindOfClass:[MKTag class]]) {
        [self trigger:@"selectTag" data:[NSNull null]];
        return;
    }
    
    MKTag *selectedTag = (MKTag *)selectedObject;
    NSLog(@"Selected tag: %@", selectedTag);
    
    [self trigger:@"selectTag" data:selectedTag];
}


@end
