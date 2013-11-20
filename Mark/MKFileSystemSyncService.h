//
//  MKFileSystemSyncService.h
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import <CDEvents/CDEvents.h>

@interface MKFileSystemSyncService : NSObject

@property (strong) NSString *basePath;
@property (strong) NSManagedObjectContext *context;
@property (strong) CDEvents *events;

- (id)initWithContext:(NSManagedObjectContext *)context;

- (void)restoreFromFileSystem;

@end
