//
//  MKNote.m
//  Mark
//
//  Created by Vojtech Rinik on 23/10/13.
//  Copyright (c) 2013 Vojtech Rinik. All rights reserved.
//

#import "MKNote.h"
#import "MKTag.h"


@implementation MKNote

@dynamic title;
@dynamic content;
@dynamic tags;
@dynamic updatedAt;

+ (NSString *)MR_entityName {
    return @"Note";
}

- (NSString *)tagsString {
    return [self.tagNames componentsJoinedByString:@", "];
}

- (NSArray *)tagNames {
    return [self.tags.allObjects map:^id(MKTag *tag) {
        return tag.name;
    }];
}

- (void)setTagNames:(NSArray *)tagNames {
    NSMutableSet *tagsToRemove = [self.tags mutableCopy];
    
    for (NSString *tagName in tagNames) {
        MKTag *tag = [MKTag MR_findFirstByAttribute:@"name" withValue:tagName];
        if (!tag) {
            tag = [MKTag createEntity];
            tag.name = tagName;
        }
        [tagsToRemove removeObject:tag];
        [self addTagsObject:tag];
    }
    
    for (MKTag *tag in tagsToRemove) {
        [self removeTagsObject:tag];
    }
}

@end
