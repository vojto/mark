//
//  MKTagsController.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKTagsController.h"
#import "MKTag.h"

@implementation MKTagsController


- (void)awakeFromNib {
    [self.tagsArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.tagsArrayController && [keyPath isEqualToString:@"selection"]) {
        [self didChangeSelection];
    }
}

- (void)didChangeSelection {
    NSLog(@"Selection changed");
    id selectedObject = [[self.tagsArrayController selectedObjectsExceptExtraItems] lastObject];
    
    if (![selectedObject isKindOfClass:[MKTag class]]) {
        [self trigger:@"selectTag" data:[NSNull null]];
        return;
    }
    
    MKTag *selectedTag = (MKTag *)selectedObject;
    NSLog(@"Selected tag: %@", selectedTag);
    
    [self trigger:@"selectTag" data:selectedTag];
}


@end
