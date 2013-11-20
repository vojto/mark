//
//  MKFileSystemSyncService.h
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

@interface MKFileSystemSyncService : NSObject

@property (strong) NSManagedObjectContext *context;

- (id)initWithContext:(NSManagedObjectContext *)context;

- (void)restoreFromFileSystem;

@end
