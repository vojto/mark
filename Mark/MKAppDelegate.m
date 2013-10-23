//
//  MKAppDelegate.m
//  Mark
//
//  Created by Vojtech Rinik on 22/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKAppDelegate.h"
#import "MKTag.h"

@implementation MKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [MagicalRecord setupAutoMigratingCoreDataStack];
    
    self.managedContext = [NSManagedObjectContext defaultContext];
    
    if ([MKTag countOfEntities] == 0) {
        MKTag *tag = [MKTag createEntity];
        tag.name = @"work";
        
        [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
    }

}

@end
