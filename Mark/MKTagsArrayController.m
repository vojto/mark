//
//  MKTagsArrayController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsArrayController.h"

@implementation MKTagsArrayController

/*

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.extraItem = @{@"name": @"All tags"};
    }
    return self;
}

- (id)arrangedObjects {
    NSArray *extraObjects = @[self.extraItem];
    NSArray *objects = [super arrangedObjects];
    return [extraObjects arrayByAddingObjectsFromArray:objects];
}

- (NSArray *)selectedObjectsExceptExtraItems {
    NSMutableArray *objects = [NSMutableArray array];
    
    [self.selectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [objects addObject:[self.arrangedObjects objectAtIndex:idx]];
    }];
    
    return objects;
}
 
 */

@end
