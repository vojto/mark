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
#import <DTFoundation/DTExtendedFileAttributes.h>

NSString * const kMKBasePath = @"/Users/vojto/Desktop/MARK_NOTES";
NSString * const kMKFileExtension = @"md";
NSString * const kMKNoteUUIDExtendedAttribute = @"net.rinik.Mark:noteUUID";
NSString * const kMKNoteTagsExtendedAttribute = @"net.rinik.Mark:noteTags";
NSString * const kMKNoteTagsSeparator = @",";

typedef void(^MKBlock)(id sender);

@implementation MKFileSystemSyncService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.basePath = kMKBasePath;
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:self.context];
        
        [self setupDirectoryWatching];
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
    notePath = [self notePathForTitle:noteFilename];
    
    NSString *content = note.content;
    NSLog(@"content: %@", content);
    if (!content) {
        content = @"";
    }
    result = [content writeToFile:notePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!result) {
        [NSException raise:@"Failed saving note to a file" format:@"%@", error];
        return;
    }
    
    // Saving to file succeeded, store the title.
    note.fs_filename = noteFilename;

    // Set extended attributes
    [self setExtendedAttributesForNote:note path:notePath];
    
    // Set tags (10.9)
    [self setTagsForNote:note path:notePath];
}

#pragma mark - Extended attributes

- (void)setExtendedAttributesForNote:(MKNote *)note path:(NSString *)notePath {
    // Set UUID
    DTExtendedFileAttributes *attrs = [[DTExtendedFileAttributes alloc] initWithPath:notePath];
    [attrs setValue:note.uuid forAttribute:kMKNoteUUIDExtendedAttribute];
    NSString *tagsString = [note.tagNames componentsJoinedByString:kMKNoteTagsSeparator];
    [attrs setValue:tagsString forAttribute:kMKNoteTagsExtendedAttribute];
}

#pragma mark - Tags

- (void)setTagsForNote:(MKNote *)note path:(NSString *)notePath {
    if (&NSURLTagNamesKey != NULL) {
        NSURL *url = [NSURL fileURLWithPath:notePath];
        NSError *error;
        [url setResourceValue:[note tagNames] forKey:NSURLTagNamesKey error:&error];
        if (error) {
            NSLog(@"Failed setting tags: %@", error);
        }
    }
}

#pragma mark - Getting filenames

- (NSString *)retrieveOrCreateNoteFilename:(MKNote *)note {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (note.fs_filename) {
        // Make sure the filename is up to date
        if (![note.fs_filename isEqualToString:[self filenameFromTitle:note.title]]) {
            // If the title has changed and the filename is not up to date, then rename
            // the file to the new filename.
            
            NSString *currentPath = [self notePathForTitle:note.fs_filename];
            NSString *newFilename = [self filenameFromTitle:note.title];
            NSString *newPath = [self notePathForTitle:newFilename];
            
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
    return title;
}

- (NSString *)notePathForTitle:(NSString *)filename {
    NSString *basePath, *notePath;
    
    basePath = kMKBasePath;
    
    notePath = [basePath stringByAppendingPathComponent:filename];
    notePath = [notePath stringByAppendingPathExtension:kMKFileExtension];
    
    return notePath;
}

#pragma mark - Restoring from filesystem

- (void)restoreFromFileSystem {
    NSLog(@"Restoring from file system");
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSString *path in [self noteFilesInDirectory:self.basePath]) {
            [self updateNoteFromFileSystemAtPath:path context:localContext];
        }
    }];
}

- (NSArray *)noteFilesInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:self.basePath];
    NSString *fileName;
    NSMutableArray *noteFiles = [NSMutableArray array];
    
    while (fileName = [enumerator nextObject]) {
        BOOL isDirectory = NO;
        NSString *path = [kMKBasePath stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        
        if (isDirectory) {
            continue;
        }
        
        if (![fileName hasSuffix:[NSString stringWithFormat:@".%@", kMKFileExtension]]) {
            continue;
        }
        
        [noteFiles addObject:[self.basePath stringByAppendingPathComponent:fileName]];
    }
    
    return noteFiles;
}

- (void)updateNoteFromFileSystemAtPath:(NSString *)path context:(NSManagedObjectContext *)context {
    NSString *fileName = [path lastPathComponent];
    NSString *title = [fileName stringByDeletingPathExtension];
    
    // Read metadata
    NSError *error;
    DTExtendedFileAttributes *attributes = [[DTExtendedFileAttributes alloc] initWithPath:path];
    NSString *uuid = [attributes valueForAttribute:kMKNoteUUIDExtendedAttribute];
    NSString *tagsString = [attributes valueForAttribute:kMKNoteTagsExtendedAttribute];
    NSArray *tags = [tagsString componentsSeparatedByString:kMKNoteTagsSeparator];
    
    if (!uuid) {
        NSLog(@"Skipping note file because UUID is missing: %@", path);
        return;
    }

    // Try to read Mavericks tags, if available
    NSURL *url = [NSURL fileURLWithPath:path];
    error = nil;
    if (&NSURLTagNamesKey != NULL) {
        NSArray *mavericksTags;
        [url getResourceValue:&mavericksTags forKey:NSURLTagNamesKey error:&error];
        if (error) {
            NSLog(@"Failed reading Mavericks tags: %@", error);
        }
        if (mavericksTags) {
            if (mavericksTags.count != tags.count) {
                NSLog(@"Warning: Mavericks tags differ from xattrs tags, using Mavericks tags.");
            }
            tags = mavericksTags;
        }
    }
    
    NSString *content = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Failed to read file for note: %@", path);
        return;
    }
    
    // Try to find the note
    MKNote *note = [MKNote findFirstByAttribute:@"uuid" withValue:uuid inContext:context];
    NSLog(@"Found note: %@", note);
    if (!note) {
        note = [MKNote createEntity];
        note.uuid = uuid;
    }
    
    note.title = title;
    note.content = content;
    NSLog(@"Setting tag names to: %@", tags);
    [note setTagNames:tags];
}

#pragma mark - Directory watching

- (void)setupDirectoryWatching {
    NSURL *url = [NSURL URLWithString:self.basePath];
    self.events = [[CDEvents alloc] initWithURLs:@[url] block:^(CDEvents *watcher, CDEvent *event) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(restoreFromFileSystem) withObject:nil afterDelay:1];
    }];
}



@end
