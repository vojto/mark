//
//  MKUUIDService.m
//  Mark
//
//  Created by Vojtech Rinik on 20/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKUUIDService.h"
#import "MKNote.h"

@implementation MKUUIDService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSave:) name:NSManagedObjectContextWillSaveNotification object:self.context];
    }
    
    return self;
}

- (void)willSave:(NSNotification *)notification {
    for (NSManagedObject *object in self.context.insertedObjects) {
        if ([object isKindOfClass:[MKNote class]]) {
            MKNote *note = (MKNote *)object;
            [note ensureUUID];
        }
    }
}

@end
