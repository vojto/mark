//
//  MKFileSystemSyncService.m
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKFileSystemSyncService.h"
#import "MKNote.h"
#import "MKAppDelegate.h"

@implementation MKFileSystemSyncService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:self.context];
    }
    
    return self;
}

- (void)didSave:(NSNotification *)notification {
    NSLog(@"Did save - syncing");
    NSBeep();
    NSLog(@"inserted: %@", self.context.insertedObjects);
    NSLog(@"updated: %@", self.context.updatedObjects);
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSaveCallback) object:nil];
//    [self performSelector:@selector(performSaveCallback) withObject:nil afterDelay:1];
    [self performSaveCallback];
}

- (void)performSaveCallback {
    [self performInitialSync];
}

- (void)performInitialSync {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *notes = [MKNote findAllInContext:localContext];
        for (MKNote *note in notes) {
            [self syncNote:note];
        }
    }];
}

- (void)syncNote:(MKNote *)note {
    NSString *title = note.title;
    NSError *error;
    BOOL result;
    
    NSString *basePath = @"/Users/vojto/Desktop/MARK_NOTES";
    NSString *noteFilename = title;
    NSString *notePath = [basePath stringByAppendingPathComponent:noteFilename];
    notePath = [notePath stringByAppendingPathExtension:@"md"];
    
    result = [note.content writeToFile:notePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!result) {
        [NSException raise:@"Failed saving note to a file" format:@"%@", error];
        return;
    }
    
    // Saving to file succeeded, store the title.
    note.fs_filename = noteFilename;

    // Set tags
    NSURL *url = [NSURL fileURLWithPath:notePath];
    result = [url setResourceValue:[note tagNames] forKey:NSURLTagNamesKey error:&error];
//    NSLog(@"Reasult: %d", result);
    if (error) {
        NSLog(@"Failed setting tags: %@", error);
    }
    
    NSLog(@"Path: %@", notePath);
}


@end
