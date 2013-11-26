//
//  MKTableViewSelectionPersisting.m
//  Mark
//
//  Created by Vojtech Rinik on 26/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTableViewSelectionPersisting.h"

@implementation MKTableViewSelectionPersisting

- (id)initWithArrayController:(NSArrayController *)arrayController {
    if ((self = [super init])) {
        self.arrayController = arrayController;
        [self.arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
        [self.arrayController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];
        [self restoreSelectionFromPreferences];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"arrangedObjects"]) {
        if (self.selectionToLoad) {
            self.arrayController.selectionIndexes = self.selectionToLoad;
            self.selectionToLoad = nil;
            //            [self.tagsArrayController removeObserver:self forKeyPath:@"arrangedObjects"];
        }
    } else if ([keyPath isEqualToString:@"selection"]) {
        [self storeSelectionToPreferences];
    }
}

#pragma mark - Storing selection to preferences

- (void)storeSelectionToPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.arrayController.selectionIndexes];
    [defaults setObject:data forKey:@"MKSelectedTags"];
}

- (void)restoreSelectionFromPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"MKSelectedTags"];
    id selection = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (selection) {
        // Being a little defensive here.
        self.arrayController.selectionIndexes = selection;
        self.selectionToLoad = selection;
    }
}

@end
