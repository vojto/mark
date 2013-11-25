//
//  MKFileSystemSyncService.h
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <VDKQueue/VDKQueue.h>

NSString * const kMKFileSystemPathDefaultsKey;

@interface MKFileSystemSyncService : NSObject <VDKQueueDelegate>

@property (strong) NSString *basePath;
@property (strong) NSManagedObjectContext *context;
@property (strong) VDKQueue *queue;

@property (strong) NSMutableSet *changedUUIDs;
@property (strong) NSMutableSet *deletedNotePaths; // Store referenced files, since note objects aren't available anymore

- (id)initWithContext:(NSManagedObjectContext *)context;

- (void)restoreFromFileSystem;

@end
