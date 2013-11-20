//
//  MKUUIDService.m
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKUUIDService.h"

@implementation MKUUIDService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSave:) name:NSManagedObjectContextWillSaveNotification object:self.context];
    }
    
    return self;
}

- (void)willSave:(NSNotification *)notification {
    NSLog(@"Will save: %@", notification.userInfo);
    NSLog(@"Inserted: %@", self.context.insertedObjects);
}

@end
