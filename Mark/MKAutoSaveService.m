//
//  MKAutoSaveService.m
//  Mark
//
//  Created by Vojtech Rinik on 19/11/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKAutoSaveService.h"

@implementation MKAutoSaveService

- (id)initWithContext:(NSManagedObjectContext *)context {
    if ((self = [super init])) {
        self.context = context;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeObjects:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.context];
    }
    
    return self;
}

- (void)didChangeObjects:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(performSave) withObject:nil afterDelay:5];
}

- (void)performSave {
    [self.context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
    }];
}

@end
