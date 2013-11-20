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
    NSString *noteFilename, *notePath;
    NSError *error;
    BOOL result;
    
    
    noteFilename = [self retrieveOrCreateNoteFilename:note];
    notePath = [self notePathForFilename:noteFilename];
    
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

- (NSString *)retrieveOrCreateNoteFilename:(MKNote *)note {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (note.fs_filename) {
        // Make sure the filename is up to date
        if (![note.fs_filename isEqualToString:[self filenameFromTitle:note.title]]) {
            // If the title has changed and the filename is not up to date, then rename
            // the file to the new filename.
            
            NSString *currentPath = [self notePathForFilename:note.fs_filename];
            NSString *newFilename = [self filenameFromTitle:note.title];
            NSString *newPath = [self notePathForFilename:newFilename];
            
            NSLog(@"Renaming note file because the note title has changed: %@ -> %@", currentPath, newPath);
            
            NSError *error;
            if (![manager moveItemAtPath:currentPath toPath:newPath error:&error]) {
                NSLog(@"Failed renaming file: %@", error);
                return newFilename;
            }
            
            return newFilename;
        } else {
            return note.fs_filename;
        }
    } else {
        return [self filenameFromTitle:note.title];
    }
}

- (NSString *)filenameFromTitle:(NSString *)title {
    return [title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

- (NSString *)notePathForFilename:(NSString *)filename {
    NSString *basePath, *notePath;
    
    basePath = @"/Users/vojto/Desktop/MARK_NOTES";
    
    notePath = [basePath stringByAppendingPathComponent:filename];
    notePath = [notePath stringByAppendingPathExtension:@"md"];
    
    return notePath;
}

@end
