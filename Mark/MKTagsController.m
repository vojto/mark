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
    if (!self.isSetup) {
        [self.tagsArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
        self.isSetup = YES;
        self.selectionPersisting = [[MKTableViewSelectionPersisting alloc] initWithKey:@"selectedTag" arrayController:self.tagsArrayController];
        self.tagsTableView.target = self;
        self.tagsTableView.doubleAction = @selector(editTagAction:);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]) {
        NSLog(@"Observing");
        // Get the selected tag from array controller
        MKTag *selectedTag = [[self.tagsArrayController selectedObjects] lastObject];
        if (!selectedTag) {
            selectedTag = (id)[NSNull null];
        }
        [self trigger:@"selectTag" data:selectedTag];
    }
}



- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    return YES;
}


#pragma mark - Deleting tags

- (void)deleteTagAction:(id)sender {
    MKTag *tag = [self clickedTag];
    [self confirmWithUserAndDeleteTag:tag];
}

- (void)confirmWithUserAndDeleteTag:(MKTag *)tag {
    NSInteger notesCount = tag.notes.count;
    if (notesCount > 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Delete %@?", tag.name]];
        [alert setInformativeText:[NSString stringWithFormat:@"Do you want to untag %ld notes tagged with %@?", (long)notesCount, tag.name]];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Delete"];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(deleteWarningDidEnd:returnCode:contextInfo:) contextInfo:(void *)tag];
    } else {
        [self deleteTag:tag];
    }
}

- (void)deleteWarningDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    MKTag *tag = (__bridge MKTag *)contextInfo;
    if (returnCode == NSAlertSecondButtonReturn) {
        [self deleteTag:tag];
    }
}

- (void)deleteTag:(MKTag *)tag {
    [tag deleteEntity];
}

#pragma mark - Editing tags

- (void)editTagAction:(id)sender {
    MKTag *tag = [self clickedTag];
    NSLog(@"Editing tag: %@", tag);
    NSRect rect = [self.tagsTableView frameOfCellAtColumn:self.tagsTableView.clickedColumn row:self.tagsTableView.clickedRow];
}

#pragma mark - Table helpers

- (MKTag *)clickedTag {
    return self.tagsArrayController.arrangedObjects[self.tagsTableView.clickedRow];
}

@end
