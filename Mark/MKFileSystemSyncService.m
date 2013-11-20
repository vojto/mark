//
//  MKFileSystemSyncService.m
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKFileSystemSyncService.h"
#import "MKNote.h"

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
    [self performInitialSync];
}

- (void)performInitialSync {
    NSArray *notes = [MKNote findAll];
    for (MKNote *note in notes) {
        [self syncNote:note];
    }
}

- (void)syncNote:(MKNote *)note {
//    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *title = note.title;
    
    NSString *basePath = @"/Users/vojto/Desktop/MARK_NOTES";
    NSString *notePath = [basePath stringByAppendingPathComponent:title];
    notePath = [notePath stringByAppendingPathExtension:@"md"];
    
    [note.content writeToFile:notePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    NSURL *url = [NSURL fileURLWithPath:notePath];
    NSError *error;
    BOOL result = [url setResourceValue:[note tagNames] forKey:NSURLTagNamesKey error:&error];
    NSLog(@"Reasult: %d", result);
    if (error) {
        NSLog(@"Failed setting tags: %@", error);
    }
    
    NSLog(@"Path: %@", notePath);
}


@end
