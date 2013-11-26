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
NSString * const kMKNoteTagsSeparator = @",";
NSString * const kMKNoteExtendedSectionSeparator = @"|";
NSString * const kMKFileSystemPathDefaultsKey = @"filesystemPath";
NSString * const kMKMetadataHeader = @"Mark: ";

typedef void(^MKBlock)(id sender);

@implementation MKFileSystemSyncService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.basePath = nil;
        self.context = context;
        self.changedUUIDs = [NSMutableSet set];
        self.deletedNotePaths = [NSMutableSet set];
        self.isWatching = YES;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:self.context];
        [center addObserver:self selector:@selector(didChangeObject:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.context];

        [self setupDefaultsWatching];

        [self updateBasePathFromDefaults]; // that will also start watching directory
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
//        [self storeAllObjectsToFileSystem];
        // TODO: Store objects at SOME point after changing the path
        // but doing it at the launch time collides with the restoring
        // routine.
        [self setupDirectoryWatching];
    }
}

#pragma mark - Storing to filesystem

- (void)didSave:(NSNotification *)notification {
    [self storeChangedObjectsToFilesystem];
}


- (void)didChangeObject:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    [self addUUIDsFromObjects:userInfo[NSInsertedObjectsKey] toSet:self.changedUUIDs];
    [self addUUIDsFromObjects:userInfo[NSUpdatedObjectsKey] toSet:self.changedUUIDs];
    
    for (NSManagedObject *object in userInfo[NSDeletedObjectsKey]) {
        if ([object isKindOfClass:[MKNote class]]) {
            MKNote *note = (MKNote *)object;
            [self.deletedNotePaths addObject:[self pathForNote:note]];
        }
    }
}

- (void)addUUIDsFromObjects:(NSArray *)objects toSet:(NSMutableSet *)set {
    for (NSManagedObject *object in objects) {
        // This is called after an object has been changed - so it can't
        // be a fault, unless it has been deleted, in which case we don't
        // want to add it ot our uuid queue.
        if (!object.isFault && [object isKindOfClass:[MKNote class]]) {
            MKNote *note = (MKNote *)object;
            [note ensureUUID];
            [set addObject:note.uuid];
        }
    }
}

- (void)storeChangedObjectsToFilesystem {
    if (!self.basePath) {
        NSLog(@"Cancelling storing to filesystem - missing base path");
        return;
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        // Sync changed
        NSArray *uuids = [self.changedUUIDs allObjects];
        for (NSString *uuid in uuids) {
            MKNote *note = [MKNote findFirstByAttribute:@"uuid" withValue:uuid inContext:localContext];
            [self syncNote:note];
        }
        
        // TODO: Delete deleted
        NSMutableSet *removedPaths = [NSMutableSet set];
        for (NSString *notePath in self.deletedNotePaths) {
            NSLog(@"Deleting note at path: %@", notePath);
            [self deleteNotePath:notePath];
            [removedPaths addObject:notePath];
        }
        for (NSString *notePath in removedPaths) {
            [self.deletedNotePaths removeObject:notePath];
        }
    }];
}

- (void)storeAllObjectsToFileSystem {
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
    
    if (note.isDeleted) {
        return;
    }
    
    
    noteFilename = [self retrieveOrCreateNoteFilename:note];
    notePath = [self notePathForTitle:noteFilename];
    
    NSString *content = note.content;
    if (!content) {
        content = @"";
    }
    content = [self appendMetadataToContent:content forNote:note];
    self.isWatching = NO;
    NSLog(@"Disabling watching");
    result = [content writeToFile:notePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    self.isWatching = YES;
    NSLog(@"Enabling watching");
    if (!result) {
        [NSException raise:@"Failed saving note to a file" format:@"%@", error];
        return;
    }
    
    // Saving to file succeeded, store the title.
    note.fs_filename = noteFilename;
    
    // Set tags (10.9)
    [self setTagsForNote:note path:notePath];
}

- (void)deleteNotePath:(NSString *)notePath {
    NSError *error;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:notePath error:&error];
    
    if (error) {
        NSLog(@"Failed removing note file from the fileysstem: %@", error);
    }
}

#pragma mark - Metadata

- (NSString *)appendMetadataToContent:(NSString *)content forNote:(MKNote *)note {
    NSString *metadataString = [self encodeNoteMetadata:note];
    NSString *wrappedMetadata = [NSString stringWithFormat:@"\n\n<!-- %@%@ -->", kMKMetadataHeader, metadataString];
    
    return [content stringByAppendingString:wrappedMetadata];
}

- (NSDictionary *)readMetadataAndStripFromContent:(NSString **)content {

    NSString *pattern = [NSString stringWithFormat:@"\\n\\n<!-- %@(.*) -->", kMKMetadataHeader];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *results = [expression matchesInString:*content options:0 range:NSMakeRange(0, (*content).length)];
    NSTextCheckingResult *result = [results lastObject];
    
    if (!result) {
        return nil;
    }
    
    NSRange metadataRange = [result rangeAtIndex:1];
    NSRange wrappedRange = [result rangeAtIndex:0];
    NSString *metadata = [*content substringWithRange:metadataRange];
    
    *content = [*content stringByReplacingCharactersInRange:wrappedRange withString:@""];
    
    return [self decodeNoteMetadata:metadata];
    
}

- (NSString *)encodeNoteMetadata:(MKNote *)note {
    NSString *tagsString = [note.tagNames componentsJoinedByString:kMKNoteTagsSeparator];
    NSString *metadataString = [NSString stringWithFormat:@"%@%@%@", note.uuid, kMKNoteExtendedSectionSeparator, tagsString];
    return metadataString;
}

- (NSDictionary *)decodeNoteMetadata:(NSString *)metadata {
    NSArray *components = [metadata componentsSeparatedByString:kMKNoteExtendedSectionSeparator];
    
    if (components.count != 2) {
        NSLog(@"Unexpected count of components in metadata.");
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

- (NSString *)pathForNote:(MKNote *)note {
    return [self notePathForTitle:[self filenameFromTitle:note.title]];
}

#pragma mark - Restoring from filesystem

- (void)restoreFromFileSystemIncrementally:(BOOL)isIncremental {
    if (!self.basePath) {
        NSLog(@"Cancelling restore - missing base path");
        return;
    }

    NSLog(@"Restoring from file system");
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *files = [self noteFilesInDirectory:self.basePath];
        if (files.count == 0) {
            NSLog(@"No files found in directory.");
            return;
        }
        
        // Filter only files recently changed
        if (isIncremental && self.lastRestore) {
            files = [self filterFilesToChangedRecently:files];
            NSLog(@"Recently changed files: %@", files);
        }
        
        NSMutableSet *updatedUUIDs = [NSMutableSet set];
        for (NSString *path in files) {
            MKNote *updatedNote = [self updateNoteFromFileSystemAtPath:path context:localContext];
            if (updatedNote) {
                [updatedUUIDs addObject:updatedNote.uuid];
            }
        }
        // Inspect local notes, and delete those that weren't updated during the restore
        // operation.
        if (!isIncremental) {
            NSArray *notes = [MKNote findAllInContext:localContext];
            for (MKNote *note in notes) {
                if (![updatedUUIDs containsObject:note.uuid]) {
                    [note deleteEntity];
                }
            }
        }
        
        self.lastRestore = [NSDate date];
    }];
}

- (NSArray *)filterFilesToChangedRecently:(NSArray *)files {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (!self.lastRestore) {
        return files;
    }
    return [files select:^BOOL(NSString *file) {
        NSDictionary *attributes = [manager attributesOfItemAtPath:file error:NULL];
        NSDate *date = attributes[NSFileModificationDate];
        NSLog(@"Modification date: %@", date);
        if ([date isGreaterThanOrEqualTo:self.lastRestore]) {
            return YES;
        } else {
            return NO;
        }
    }];
}

- (void)restoreFromFileSystem {
    [self restoreFromFileSystemIncrementally:NO];
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

- (MKNote *)updateNoteFromFileSystemAtPath:(NSString *)path context:(NSManagedObjectContext *)context {
    NSString *fileName = [path lastPathComponent];
    NSString *title = [fileName stringByDeletingPathExtension];
    
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&error];
    NSDictionary *metadata = [self readMetadataAndStripFromContent:&content];
    
    // Read metadata
    NSString *uuid = metadata[@"uuid"];
    NSArray *tags = metadata[@"tagNames"];
    
    if (!uuid) {
        NSLog(@"Skipping note file because UUID is missing: %@", path);
        return nil;
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
    
    if (error) {
        NSLog(@"Failed to read file for note: %@", path);
        return nil;
    }
    
    // Try to find the note
    MKNote *note = [MKNote findFirstByAttribute:@"uuid" withValue:uuid inContext:context];
    if (!note) {
        note = [MKNote createInContext:context];
        note.uuid = uuid;
    }

    
    note.title = title;
    note.content = content;
    [note setTagNames:tags];
    
    return note;
}

#pragma mark - Directory watching

- (void)setupDirectoryWatching {
    if (!self.basePath) {
        NSLog(@"Cancelling directory watching - missing base path");
        return;
    }
    
    void(^eventBlock)(CDEvents *watcher, CDEvent *event) = ^void(CDEvents *watcher, CDEvent *event) {
        NSLog(@"Event: %@", event);
        NSLog(@"Created = %d\nModified = %d\nRemoved = %d\nisFile = %d", event.isCreated, event.isModified, event.isRemoved, event.isFile);
        NSLog(@"Self = %@", self);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didChangeFiles) object:nil];
        [self performSelector:@selector(didChangeFiles) withObject:nil afterDelay:1];
    };
    
    NSURL *url = [NSURL URLWithString:self.basePath];
    self.events = [[CDEvents alloc] initWithURLs:@[url]
                                           block:eventBlock
                                       onRunLoop:[NSRunLoop currentRunLoop]
                            sinceEventIdentifier:kCDEventsSinceEventNow
                            notificationLantency:0.0
                         ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                     excludeURLs:@[]
                             streamCreationFlags:kCDEventsDefaultEventStreamFlags];
    
    /*
     
     [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didChangeFiles) object:nil];
     [self performSelector:@selector(didChangeFiles) withObject:nil afterDelay:1];
     
     */
}

- (void)stopWatching {
    [self.events performSelector:@selector(disposeEventStream) withObject:nil];
    self.events = nil;
}


- (void)didChangeFiles {
    NSLog(@"didChangeFiles");
    [self restoreFromFileSystemIncrementally:YES];
}

#pragma mark - Lifecycle

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kMKFileSystemPathDefaultsKey];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    [self stopWatching];
}

@end
