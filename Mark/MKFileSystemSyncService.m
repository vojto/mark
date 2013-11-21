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

NSString * const kMKFileExtension = @"md";
NSString * const kMKNoteExtendedAttribute = @"com.apple.metadata:kMDItemFinderComment";
NSString * const kMKNoteTagsSeparator = @",";
NSString * const kMKNoteExtendedSectionSeparator = @"|";
NSString * const kMKFileSystemPathDefaultsKey = @"filesystemPath";

typedef void(^MKBlock)(id sender);

@implementation MKFileSystemSyncService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.basePath = nil;
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:self.context];

        [self setupDefaultsWatching];
        [self setupDirectoryWatching];

        [self updateBasePathFromDefaults];
    }
    
    return self;
}

#pragma mark - Watching defaults

- (void)setupDefaultsWatching {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self forKeyPath:kMKFileSystemPathDefaultsKey options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kMKFileSystemPathDefaultsKey]) {
        [self updateBasePathFromDefaults];
    }
}

- (void)updateBasePathFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:kMKFileSystemPathDefaultsKey];
    if (!self.basePath || ![self.basePath isEqualToString:path]) {
        self.basePath = path;
        [self storeToFileSystem];
        [self setupDirectoryWatching];
    }
}

#pragma mark - Storing to filesystem

- (void)didSave:(NSNotification *)notification {
    [self performSaveCallback];
}

- (void)performSaveCallback {
    [self storeToFileSystem];
}

- (void)storeToFileSystem {
    if (!self.basePath) {
        NSLog(@"Cancelling storing to filesystem - missing base path");
        return;
    }

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
    NSString *tagsString = [note.tagNames componentsJoinedByString:kMKNoteTagsSeparator];
    NSString *content = [NSString stringWithFormat:@"%@%@%@", note.uuid, kMKNoteExtendedSectionSeparator, tagsString];

    DTExtendedFileAttributes *attrs = [[DTExtendedFileAttributes alloc] initWithPath:notePath];
    [attrs setValue:content forAttribute:kMKNoteExtendedAttribute];
}

- (NSDictionary *)restoreExtendedAttributesFromFile:(NSString *)path {
    DTExtendedFileAttributes *attrs = [[DTExtendedFileAttributes alloc] initWithPath:path];
    NSString *content = [attrs valueForAttribute:kMKNoteExtendedAttribute];
    NSArray *components = [content componentsSeparatedByString:kMKNoteExtendedSectionSeparator];

    if (components.count != 2) {
        NSLog(@"Unexpected count of components in extended attribute.");
        return nil;
    }

    NSString *uuid = components[0];
    NSString *tagsString = components[1];
    NSArray *tagNames = [tagsString componentsSeparatedByString:kMKNoteTagsSeparator];
    return @{@"uuid": uuid, @"tagNames": tagNames};
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
    
    basePath = self.basePath;
    
    notePath = [basePath stringByAppendingPathComponent:filename];
    notePath = [notePath stringByAppendingPathExtension:kMKFileExtension];
    
    return notePath;
}

#pragma mark - Restoring from filesystem

- (void)restoreFromFileSystem {
    if (!self.basePath) {
        NSLog(@"Cancelling restore - missing base path");
        return;
    }

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
        NSString *path = [self.basePath stringByAppendingPathComponent:fileName];
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
    NSDictionary *attributes = [self restoreExtendedAttributesFromFile:path];
    NSString *uuid = attributes[@"uuid"];
    NSArray *tags = attributes[@"tagNames"];
    
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
    if (!self.basePath) {
        NSLog(@"Cancelling directory watching - missing base path");
        return;
    }


    NSURL *url = [NSURL URLWithString:self.basePath];
    self.events = [[CDEvents alloc] initWithURLs:@[url] block:^(CDEvents *watcher, CDEvent *event) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(restoreFromFileSystem) withObject:nil afterDelay:1];
    }];
}



@end
